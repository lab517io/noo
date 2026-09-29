/// Fakes for the three audio seams: enumerating devices, playing a clip back,
/// and transcribing one.
///
/// They exist so the device rows in Preferences and the whole record → play →
/// transcribe check can be driven with no audio hardware, no native library,
/// no 78 MB model on disk and no speaker making a noise in CI.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:noo/data/services/audio/audio_devices.dart';
import 'package:noo/data/services/audio/memo_player.dart';
import 'package:noo/data/services/audio/whisper_service.dart';
import 'package:voice_audio/voice_audio.dart' as va;

/// A machine with the devices the test says it has.
class FakeAudioDeviceSource implements AudioDeviceSource {
  FakeAudioDeviceSource({
    List<va.AudioDevice>? microphones,
    List<va.AudioDevice>? speakers,
    this.failing = false,
  })  : _microphones = microphones ??
            const [
              va.AudioDevice(index: 0, name: 'Built-in mic', isDefault: true),
              va.AudioDevice(index: 1, name: 'USB headset'),
            ],
        _speakers = speakers ??
            const [
              va.AudioDevice(index: 0, name: 'Speakers', isDefault: true),
              va.AudioDevice(index: 1, name: 'HDMI out'),
            ];

  final List<va.AudioDevice> _microphones;
  final List<va.AudioDevice> _speakers;

  /// Stands in for a machine with no audio library, which is the case
  /// Preferences has to render rather than throw on.
  final bool failing;

  int rescans = 0;

  @override
  Future<List<va.AudioDevice>> microphones() async {
    if (failing) throw StateError('no audio library');
    return _microphones;
  }

  @override
  Future<List<va.AudioDevice>> speakers() async {
    if (failing) throw StateError('no audio library');
    return _speakers;
  }

  @override
  Future<void> rescan() async => rescans++;
}

/// A player that records what it was asked to play instead of playing it.
class FakeMemoPlayer implements MemoPlayer {
  FakeMemoPlayer({this.playable = true, this.failure});

  /// What [play] answers — false is "these bytes are not a recording".
  bool playable;

  /// Thrown from [play] when set, for the "the speaker would not open" path.
  Object? failure;

  Uint8List? playedBytes;
  va.AudioDevice? playedThrough;
  int stops = 0;

  @override
  Future<bool> play(Uint8List oggBytes, {va.AudioDevice? speaker}) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    playedBytes = oggBytes;
    playedThrough = speaker;
    return playable;
  }

  @override
  Future<void> stop() async => stops++;
}

/// A whisper with no model directory behind it.
///
/// [isPresent] is overridden as well as [transcribeMemo] because the real one
/// asks `path_provider` where the app-support directory is, which no unit test
/// can answer — and because "the model is not downloaded" is one of the
/// outcomes the check has to report. [release] is overridden for the same
/// reason: it reaches the whisper plugin's channel, and it runs whenever a
/// container holding one of these is disposed.
class FakeWhisper extends WhisperService {
  FakeWhisper({this.present = true, this.text = 'the quick brown fox'});

  bool present;
  String? text;
  Object? failure;

  /// How many progress ticks [transcribeMemo] reports.
  int blocks = 2;

  /// Blocks that actually ran, so a cancelled run can be told from one that
  /// finished and merely threw its result away.
  int blocksRun = 0;

  /// Awaited after each block, so a test can cancel from inside a run.
  Future<void> Function(int block)? onBlock;

  int calls = 0;
  String? language;

  /// The in-flight download, if one has been started and not yet finished.
  /// A test that wants to look at the downloading UI simply leaves it pending.
  Completer<void>? _download;

  /// Progress reported as soon as [downloadModel] is called, so the row under
  /// test renders a real percentage rather than the indeterminate state.
  ModelDownloadProgress downloadProgress =
      const ModelDownloadProgress(64 * 1024 * 1024, 147951465);

  bool downloadCancelled = false;

  @override
  Future<bool> isPresent(VoiceMemoModel model) async => present;

  @override
  Future<void> downloadModel(
    VoiceMemoModel model, {
    void Function(ModelDownloadProgress)? onProgress,
  }) async {
    onProgress?.call(downloadProgress);
    final download = Completer<void>();
    _download = download;
    await download.future;
    present = true;
  }

  /// Finish a pending download successfully, as the real service does when the
  /// last byte arrives.
  void completeDownload() {
    _download?.complete();
    _download = null;
  }

  @override
  void cancelDownload() {
    downloadCancelled = true;
    _download?.completeError(const DownloadCancelled());
    _download = null;
  }

  @override
  Future<void> deleteModel(VoiceMemoModel model) async => present = false;

  @override
  Future<String?> transcribeMemo(
    Uint8List oggBytes, {
    required VoiceMemoModel model,
    String language = 'en',
    void Function(TranscriptionProgress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    calls++;
    this.language = language;
    final failure = this.failure;
    if (failure != null) throw failure;
    // Reported the way the real one does — a tick per block — so the callers
    // that draw a percentage are exercised rather than assumed.
    for (var block = 1; block <= blocks; block++) {
      // Polled between blocks, exactly where the real one polls it — which is
      // what makes "cancel" testable at all: a caller that only flipped a flag
      // after the run finished would pass against a fake that never asked.
      if (isCancelled?.call() ?? false) throw const TranscriptionCancelled();
      blocksRun = block;
      onProgress?.call(TranscriptionProgress(
        block: block,
        total: blocks,
        text: text ?? '',
      ));
      await onBlock?.call(block);
    }
    return text;
  }

  @override
  Future<void> release() async {}
}
