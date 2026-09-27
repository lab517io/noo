/// On-device transcription of voice memos.
///
/// Wraps `whisper_ggml` in the three things the app actually needs: knowing
/// whether a model is on disk, fetching one when the user asks, and running a
/// live session over PCM we already have in memory.
///
/// Two deliberate constraints, both from `AUDIO_MEMO.md`:
///
/// * **Only the live-session API is used.** `whisper_ggml`'s file API converts
///   non-WAV input through *system* ffmpeg on Windows and Linux and returns
///   null — no exception, no message — when it is missing, and writes its
///   converted copy next to the input as a second decrypted file. Feeding raw
///   PCM to a live session avoids the hidden dependency and keeps everything
///   in memory.
/// * **Nothing downloads implicitly.** An app that is otherwise offline and
///   zero-knowledge must not quietly pull 148 MB; [downloadModel] runs only
///   when the user presses the button in Preferences.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:voice_audio/voice_audio.dart' as va;
import 'package:whisper_ggml/whisper_ggml.dart';

/// The models offered in Preferences.
///
/// A deliberately short list: `medium` and `large` are gigabytes and far too
/// slow for a desktop note-taking app, and the English-only variants are not
/// worth the extra choice when `base` handles dictation well.
enum VoiceMemoModel {
  /// Transcription off. No model, no download, memos are stored as audio only.
  none('Off', null, 0),

  tiny('Tiny', WhisperModel.tiny, 77691713),

  /// The one to start with. On the same clip `tiny` garbled every clause and
  /// this got half of them exactly right, for well under a second per second
  /// of audio — see the accuracy table in AUDIO_MEMO.md §12.
  base('Base', WhisperModel.base, 147951465, recommended: true),

  small('Small', WhisperModel.small, 487601967);

  const VoiceMemoModel(
    this.label,
    this.model,
    this.downloadBytes, {
    this.recommended = false,
  });

  final String label;
  final WhisperModel? model;

  /// Shown in the Preferences dropdown, so the choice is not a blind one
  /// between three sizes.
  final bool recommended;

  /// Size of the download, for the Preferences label. Measured, not guessed —
  /// the user deserves to know what a button is about to fetch.
  final int downloadBytes;

  bool get isNone => model == null;

  static VoiceMemoModel fromName(String? name) => values.firstWhere(
        (value) => value.name == name,
        orElse: () => VoiceMemoModel.none,
      );
}

/// Progress of a model download.
class ModelDownloadProgress {
  const ModelDownloadProgress(this.received, this.total);

  final int received;

  /// Bytes the server promised, or null when it sent no Content-Length.
  final int? total;

  /// 0..1, or null when the total is unknown.
  double? get fraction =>
      (total == null || total == 0) ? null : (received / total!).clamp(0.0, 1.0);
}

/// How far through a transcription we are.
///
/// Real progress, not an estimate: [block] blocks of [total] have been decoded
/// and their text is in [text]. It can be reported this precisely only because
/// the audio is split into blocks that are decoded one at a time — see
/// [WhisperService.kTranscribeBlockSeconds].
class TranscriptionProgress {
  const TranscriptionProgress({
    required this.block,
    required this.total,
    required this.text,
  });

  /// Blocks finished.
  final int block;

  /// Blocks in the whole recording.
  final int total;

  /// Everything decoded so far, so a caller can show the text building up
  /// rather than only a bar.
  final String text;

  double get fraction => total == 0 ? 0 : (block / total).clamp(0.0, 1.0);

  /// Whether a percentage is worth showing.
  ///
  /// A recording shorter than one block decodes in a single step, so its
  /// "progress" is 0% and then done — a number that tells the user less than
  /// the plain word does. Callers show the bare "Transcribing…" for those.
  bool get isGranular => total > 1;
}

/// Raised when a download is stopped by [WhisperService.cancelDownload].
class DownloadCancelled implements Exception {
  const DownloadCancelled();
  @override
  String toString() => 'DownloadCancelled';
}

/// Raised when a transcription is stopped by its caller.
///
/// Thrown rather than returned as null because the two mean different things
/// to the user: null is "whisper found no speech in this", and a caller that
/// treated a cancellation the same way would report an empty memo to someone
/// who simply changed their mind.
class TranscriptionCancelled implements Exception {
  const TranscriptionCancelled();
  @override
  String toString() => 'TranscriptionCancelled';
}

/// Model files, downloads and live sessions.
class WhisperService {
  WhisperService({
    Future<String> Function()? directory,
    HttpClient Function()? httpClient,
    Uri Function(WhisperModel)? modelUri,
  })  : _directory = directory ?? WhisperController.getModelDir,
        _httpClient = httpClient ?? HttpClient.new,
        _modelUri = modelUri ?? _huggingFaceUri;

  static Uri _huggingFaceUri(WhisperModel model) => model.modelUri;

  /// The energy gate below which the native side treats audio as silence.
  ///
  /// Exposed as a constant rather than left at the call site because it is
  /// tuned for live microphone input: replaying a stored memo through it works
  /// at the default, but a very quiet recording could be gated out entirely,
  /// and this is the number to lower when that is reported.
  static const double kGateRmsMin = 0.0015;

  /// Whisper wants 16 kHz mono, which is also what memos are recorded at, so
  /// nothing in the chain resamples.
  static const int kSampleRate = 16000;

  /// How much audio is decoded at a time.
  ///
  /// 25 s because that is the native side's own commit window
  /// (`STREAM_COMMIT_SAMPLES`), and matching it is worth more than it sounds.
  /// A live session re-decodes its *whole* accumulated window every time
  /// ~1.5 s of new audio arrives, so feeding a stored memo in small pieces
  /// decodes the same audio over and over: at one second per feed the window
  /// is decoded at 2 s, 4 s, 6 s … up to the 25 s commit, which is about
  /// eleven times the work of decoding it once.
  ///
  /// Measured on a 4:57 memo with `tiny`: **85.1 s** fed a second at a time
  /// against **8.0 s** fed a block at a time, for a byte-identical transcript
  /// (`tool/transcribe_chunk_probe.dart`). The same 11x held for `base` and
  /// on a 1:06 memo. Blocks also make progress reportable at all, since one
  /// block is one awaited decode.
  static const int kTranscribeBlockSeconds = 25;

  final Future<String> Function() _directory;
  final HttpClient Function() _httpClient;

  /// Where a model is fetched from. Overridden in tests so the download path —
  /// progress, the `.part` rename, cancellation — can be exercised against a
  /// local server instead of pulling 78 MB from HuggingFace.
  final Uri Function(WhisperModel) _modelUri;
  final WhisperController _controller = WhisperController();

  HttpClient? _activeDownload;
  bool _cancelRequested = false;

  /// Where models are kept — the app-support directory.
  Future<String> modelDirectory() => _directory();

  /// Full path of [model]'s file, whether or not it exists.
  Future<String?> pathFor(VoiceMemoModel model) async {
    final whisper = model.model;
    if (whisper == null) return null;
    return '${await _directory()}/ggml-${whisper.modelName}.bin';
  }

  /// Whether [model] has been downloaded.
  Future<bool> isPresent(VoiceMemoModel model) async {
    final path = await pathFor(model);
    if (path == null) return false;
    return File(path).exists();
  }

  /// Size of [model] on disk, or null when it is not there.
  Future<int?> sizeOnDisk(VoiceMemoModel model) async {
    final path = await pathFor(model);
    if (path == null) return null;
    final file = File(path);
    return await file.exists() ? file.length() : null;
  }

  /// Fetch [model] from HuggingFace, reporting progress.
  ///
  /// Streamed to a `.part` file and renamed on completion, so an interrupted
  /// download never leaves a truncated file that [isPresent] would call a
  /// model — whisper would then fail to load it with no hint why. (The
  /// package's own `downloadModel` does neither: it buffers the whole file in
  /// memory and reports nothing.)
  ///
  /// Throws [DownloadCancelled] if [cancelDownload] is called meanwhile.
  Future<void> downloadModel(
    VoiceMemoModel model, {
    void Function(ModelDownloadProgress)? onProgress,
  }) async {
    final whisper = model.model;
    final path = await pathFor(model);
    if (whisper == null || path == null) {
      throw ArgumentError.value(model, 'model', 'has no file to download');
    }
    if (await File(path).exists()) return;

    _cancelRequested = false;
    final client = _httpClient();
    _activeDownload = client;

    final partial = File('$path.part');
    IOSink? sink;
    try {
      await partial.parent.create(recursive: true);
      final uri = _modelUri(whisper);
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'HuggingFace answered ${response.statusCode} for ${whisper.modelName}',
          uri: uri,
        );
      }

      final total =
          response.contentLength >= 0 ? response.contentLength : null;
      var received = 0;
      sink = partial.openWrite();
      onProgress?.call(ModelDownloadProgress(0, total));

      await for (final chunk in response) {
        if (_cancelRequested) throw const DownloadCancelled();
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(ModelDownloadProgress(received, total));
      }
      await sink.flush();
      await sink.close();
      sink = null;

      if (total != null && received != total) {
        throw HttpException(
          'download ended early: $received of $total bytes',
          uri: uri,
        );
      }
      await partial.rename(path);
    } catch (_) {
      await sink?.close();
      if (await partial.exists()) await partial.delete();
      rethrow;
    } finally {
      _activeDownload = null;
      _cancelRequested = false;
      client.close(force: true);
    }
  }

  /// Stop the download in progress, if any.
  void cancelDownload() {
    if (_activeDownload == null) return;
    _cancelRequested = true;
    _activeDownload?.close(force: true);
  }

  bool get isDownloading => _activeDownload != null;

  /// Delete [model]'s file, freeing the disk it takes.
  Future<void> deleteModel(VoiceMemoModel model) async {
    final path = await pathFor(model);
    if (path == null) return;
    for (final file in [File(path), File('$path.part')]) {
      if (await file.exists()) await file.delete();
    }
  }

  /// Open a live session against [model], or null when it is not downloaded.
  ///
  /// [keepModelLoaded] parks the model in native memory so a second memo in
  /// the same sitting skips the multi-second load; [release] gives it back.
  Future<WhisperLiveSession?> startSession(
    VoiceMemoModel model, {
    String language = 'en',
    bool keepModelLoaded = true,
  }) async {
    final path = await pathFor(model);
    if (path == null || !await File(path).exists()) return null;

    return startWhisperLiveSession(
      modelPath: path,
      lang: language,
      keepModelLoaded: keepModelLoaded,
      gateRmsMin: kGateRmsMin,
    );
  }

  /// Transcribe PCM16 that is already in memory.
  ///
  /// Used for re-transcribing a stored memo: no microphone, no temp file, no
  /// ffmpeg — the packets are replayed through our own decoder and fed
  /// straight in.
  ///
  /// One session per [kTranscribeBlockSeconds] block, awaited in turn. That is
  /// what makes [onProgress] exact — a finished block is a decode that has
  /// actually happened, not a guess from the clock — and it is also what keeps
  /// the whole thing eleven times faster than feeding the memo in second-long
  /// pieces; the reasoning and the measurements are on the constant.
  ///
  /// [keepModelLoaded] is what stops the per-block sessions from costing
  /// anything: the model is parked in native memory between them and the next
  /// session borrows it, so a block is a decode and nothing else. Measured at
  /// 8.2 s of per-block sessions against 8.0 s for one long session over the
  /// same 4:57 memo.
  ///
  /// [isCancelled] is polled at each block boundary; when it answers true this
  /// throws [TranscriptionCancelled] and the blocks decoded so far are
  /// dropped. It is a callback rather than a token object because every caller
  /// already holds the state that decides — the notifier's run number, the
  /// recording's status, a flag set by a snack bar's action — and a second
  /// piece of cancellation state would only be one more thing to keep in step.
  Future<String?> transcribePcm(
    Uint8List pcm16, {
    required VoiceMemoModel model,
    String language = 'en',
    bool keepModelLoaded = true,
    void Function(TranscriptionProgress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final block = kSampleRate * 2 * kTranscribeBlockSeconds;
    final total = (pcm16.length / block).ceil();
    if (total == 0) return null;

    final parts = <String>[];
    onProgress?.call(
        TranscriptionProgress(block: 0, total: total, text: ''));

    for (var index = 0; index < total; index++) {
      // Between blocks, not within one: a native decode runs to completion and
      // there is no hook to interrupt it. A block is at most
      // [kTranscribeBlockSeconds] of audio, which is a second or two of
      // decoding, so this is as fine-grained as cancelling can be.
      if (isCancelled?.call() ?? false) throw const TranscriptionCancelled();

      final offset = index * block;
      final end =
          offset + block < pcm16.length ? offset + block : pcm16.length;

      final text = await transcribeBlock(
        Uint8List.sublistView(pcm16, offset, end),
        model: model,
        language: language,
        keepModelLoaded: keepModelLoaded,
      );
      // Null means there was no session to decode in — the model went missing
      // between blocks, deleted from Preferences mid-run. Keep what was
      // already decoded rather than throwing it away.
      if (text == null) break;
      if (text.isNotEmpty) parts.add(text);

      onProgress?.call(TranscriptionProgress(
        block: index + 1,
        total: total,
        text: parts.join(' '),
      ));
    }

    final text = parts.join(' ');
    return text.isEmpty ? null : text;
  }

  /// Decode one block of PCM16 in a session of its own.
  ///
  /// Returns the block's text, `''` when the block held nothing worth
  /// transcribing, or **null** when no session could be opened at all — the
  /// two are different to [transcribePcm]: an empty block is skipped, a
  /// missing session ends the run.
  ///
  /// Separate from [transcribePcm] so the block arithmetic and the progress
  /// reporting can be tested without a 148 MB model on disk; the session it
  /// opens is the only part of this class that needs one.
  @visibleForTesting
  Future<String?> transcribeBlock(
    Uint8List pcm16, {
    required VoiceMemoModel model,
    required String language,
    required bool keepModelLoaded,
  }) async {
    final session = await startSession(
      model,
      language: language,
      keepModelLoaded: keepModelLoaded,
    );
    if (session == null) return null;

    session.feed(pcm16);
    return (await session.stop()).trim();
  }

  /// Transcribe a stored `.opus` attachment.
  ///
  /// This is the whole transcription path now: memos are recorded to storage
  /// first and transcribed from the stored bytes afterwards, so nothing here
  /// runs while the microphone is open. It also means a transcript can be
  /// asked for again at any time — a different model, a different language, or
  /// simply a retry — from a memo that was stored untranscribed.
  ///
  /// The decode is native and off this isolate's critical path in the sense
  /// that matters: it is one call rather than a per-packet loop with a
  /// malloc/free pair each time, which is what the Dart decoder did.
  Future<String?> transcribeMemo(
    Uint8List oggBytes, {
    required VoiceMemoModel model,
    String language = 'en',
    void Function(TranscriptionProgress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final memo = va.VoiceMemo.tryParseOgg(oggBytes);
    if (memo == null) return null;

    final samples = await memo.decodeToPcm(sampleRate: kSampleRate);
    if (samples.isEmpty) return null;

    return transcribePcm(
      samples.buffer.asUint8List(samples.offsetInBytes, samples.lengthInBytes),
      model: model,
      language: language,
      onProgress: onProgress,
      isCancelled: isCancelled,
    );
  }

  /// Hand back the model parked in native memory.
  ///
  /// Called when the database closes: a locked workspace should not be holding
  /// a hundred megabytes of model.
  Future<void> release() => _controller.releaseModel();
}

/// Languages offered in Preferences.
///
/// `auto` is worth exposing because the multilingual models support it, but
/// naming the language is faster and more accurate when it is known.
const Map<String, String> kWhisperLanguages = <String, String>{
  'auto': 'Detect automatically',
  'en': 'English',
  'de': 'German',
  'es': 'Spanish',
  'fr': 'French',
  'it': 'Italian',
  'nl': 'Dutch',
  'pl': 'Polish',
  'pt': 'Portuguese',
  'ru': 'Russian',
  'uk': 'Ukrainian',
};
