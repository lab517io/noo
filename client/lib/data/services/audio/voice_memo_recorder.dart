/// Recording a voice memo: microphone → Opus → attachment bytes.
///
/// The whole pipeline is in memory and, since the move to `voice_audio`, all of
/// it is native. Capture, encoding and the Ogg container live on the other side
/// of an FFI boundary; what crosses it is one compressed blob per recording.
/// Raw PCM never reaches Dart during a recording at all, which is the point:
/// there is no audio deadline on this isolate to miss.
///
/// Transcription happens *after* the memo is stored, not alongside it — see
/// `VoiceMemoNotifier.stop`. The memo is the thing worth protecting; a
/// transcript that can be produced from the stored bytes at any time need not
/// share the recording's fate.
///
/// The engine sits behind [VoiceMemoEngine] so everything above it — the
/// elapsed clock, the level meter, cancel, the length cap, the filename — can
/// be tested by handing over a canned recording, with no audio hardware and no
/// native library present.
library;

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:permission_handler/permission_handler.dart';
import 'package:voice_audio/voice_audio.dart' as va;

/// The rate everything runs at. Wideband speech, and exactly what whisper wants
/// as input, so nothing in the chain ever resamples.
const int kVoiceMemoSampleRate = 16000;

/// Encoder bitrate. Roughly 165 KB a minute stored, and about 220 KB a minute
/// on the wire once an attachment is base64'd into a sync packet.
const int kVoiceMemoBitrate = 24000;

/// A finished memo, ready to become a row in the `file` table.
class VoiceMemo {
  const VoiceMemo({
    required this.bytes,
    required this.duration,
    required this.filename,
  });

  /// The complete Ogg Opus file.
  final Uint8List bytes;

  /// Exactly what was captured — the container's trims already applied.
  final Duration duration;

  /// `memo 2026-08-19 21-05-33.opus`. Dashes rather than colons: a colon is
  /// not a legal filename character on Windows, and attachments keep their
  /// name when exported.
  final String filename;
}

/// What an engine hands back when a recording stops.
///
/// The duration comes from the engine rather than being re-derived here,
/// because the engine already knows it: it is the container's own playable
/// length, trims applied, and re-parsing the bytes to ask again would only be
/// a chance to disagree.
class VoiceMemoCapture {
  const VoiceMemoCapture({required this.bytes, required this.duration});

  /// The complete Ogg Opus file.
  final Uint8List bytes;
  final Duration duration;
}

/// What the recording bar draws.
class VoiceMemoProgress {
  const VoiceMemoProgress({required this.elapsed, required this.level});

  final Duration elapsed;

  /// Signal level in 0..1. Worth showing for more than decoration: where a
  /// platform answers a denied microphone permission with silence rather than
  /// an error — Android does, on some devices — a meter pinned at zero is the
  /// only portable way to notice.
  final double level;
}

/// Where the recording comes from.
///
/// Exists to keep [VoiceMemoRecorder] testable: the real implementation is
/// [VoiceAudioEngine], and tests pass a fake that hands back a canned memo.
/// The unit is a whole recording rather than a stream of chunks, because that
/// is now the smallest thing that crosses the FFI boundary.
abstract class VoiceMemoEngine {
  /// Whether the microphone may be used, asking the user if necessary.
  Future<bool> hasPermission();

  /// Open the device and start encoding.
  ///
  /// [microphone] is the device chosen in Preferences, or null for whatever
  /// the platform considers the default.
  Future<void> start({va.AudioDevice? microphone});

  /// Stop, close the device, and return the recording. Null when nothing was
  /// captured.
  Future<VoiceMemoCapture?> stop();

  /// Stop and discard.
  Future<void> cancel();

  Future<void> dispose();

  /// Audio captured so far, measured from the encoded frames rather than the
  /// wall clock — the two drift, and the frames are what gets stored.
  Duration get elapsed;

  /// Peak of the last frame, 0..1.
  double get level;
}

/// [VoiceMemoEngine] backed by the `voice_audio` plugin.
class VoiceAudioEngine implements VoiceMemoEngine {
  VoiceAudioEngine({va.VoiceAudio? audio}) : _audio = audio ?? va.VoiceAudio.instance;

  final va.VoiceAudio _audio;

  @override
  Future<bool> hasPermission() async {
    // Only Android has a runtime microphone permission to ask for. macOS
    // prompts by itself the first time a non-sandboxed app opens the device,
    // given NSMicrophoneUsageDescription and the audio-input entitlement — both
    // of which are already in place — and Linux and Windows have no permission
    // model at all.
    if (!Platform.isAndroid) return true;

    final status = await Permission.microphone.request();
    return status.isGranted || status.isLimited;
  }

  @override
  Future<void> start({va.AudioDevice? microphone}) async {
    await _audio.initialize();

    // The rate is this app's decision, not the package's default. `initialize`
    // ignores its settings argument once the engine is already up — playback
    // brings it up too — so it is checked here, before the device opens, which
    // is also the only time the engine accepts a change to it.
    final settings = _audio.settings;
    if (settings.sampleRate != kVoiceMemoSampleRate) {
      await _audio
          .applySettings(settings.copyWith(sampleRate: kVoiceMemoSampleRate));
    }

    await _audio.recorder.start(
      // Null is the package's own word for the system default, so an
      // unresolved preference needs no special case here.
      microphone: microphone,
      bitrate: kVoiceMemoBitrate,
      // Silence is not free here the way it is in a call: a memo is played back
      // whole, and discontinuous frames make the waveform and the seek bar lie
      // about where the quiet parts are.
      dtx: false,
      complexity: 10,
    );
  }

  @override
  Future<VoiceMemoCapture?> stop() async {
    final memo = await _audio.recorder.stop();
    if (memo.duration == Duration.zero) return null;
    return VoiceMemoCapture(bytes: memo.oggBytes, duration: memo.duration);
  }

  @override
  Future<void> cancel() => _audio.recorder.cancel();

  @override
  Future<void> dispose() async {
    if (_audio.recorder.isRecording) await _audio.recorder.cancel();
  }

  @override
  Duration get elapsed => _audio.recorder.duration;

  @override
  double get level => _audio.recorder.level;
}

/// Records one voice memo.
///
/// Create, [start], then [stop] for the bytes or [cancel] to throw them away.
/// A recorder is single-use per recording but reusable afterwards.
class VoiceMemoRecorder {
  VoiceMemoRecorder({
    VoiceMemoEngine? engine,
    this.maxDuration = kMaxVoiceMemoDuration,
    this.progressInterval = const Duration(milliseconds: 100),
    DateTime Function()? clock,
  })  : _engine = engine ?? VoiceAudioEngine(),
        _now = clock ?? DateTime.now;

  /// Nothing streams a memo to storage — it is held in memory until stop — so
  /// the length is capped rather than discovered the hard way. At ~165 KB per
  /// minute, half an hour is about 5 MB.
  static const Duration kMaxVoiceMemoDuration = Duration(minutes: 30);

  /// Shorter than this and it was a mis-tap rather than a memo.
  ///
  /// A floor is needed because the engine has no way to report "nothing":
  /// stopping the instant after starting still hands back two 20 ms frames — a
  /// 150-byte Ogg file — so without one, a stray press on the mic button
  /// leaves a real attachment on the task and syncs it to every other device.
  static const Duration kMinVoiceMemoDuration = Duration(milliseconds: 300);

  final VoiceMemoEngine _engine;
  final DateTime Function() _now;

  final Duration maxDuration;

  /// How often [progress] emits.
  final Duration progressInterval;

  final StreamController<VoiceMemoProgress> _progress =
      StreamController<VoiceMemoProgress>.broadcast();

  Timer? _ticker;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;

  bool _recording = false;
  bool _capped = false;

  /// Ticks while recording: elapsed time and input level.
  Stream<VoiceMemoProgress> get progress => _progress.stream;

  bool get isRecording => _recording;

  /// Audio captured so far, from the samples rather than the wall clock.
  Duration get elapsed => _elapsed;

  /// Whether recording stopped because it hit [maxDuration].
  bool get reachedLimit => _capped;

  Future<bool> hasPermission() => _engine.hasPermission();

  /// Begin recording.
  ///
  /// Throws [StateError] when already recording, and whatever the engine throws
  /// when the device will not open. Permission is the caller's business: check
  /// [hasPermission] first so a refusal can be reported in the UI.
  ///
  /// [microphone] is resolved by the caller from the preference — see
  /// `selectedMicrophone` — because the name-to-device lookup needs a fresh
  /// enumeration and this class deliberately knows nothing about settings.
  Future<void> start({va.AudioDevice? microphone}) async {
    if (_recording) throw StateError('already recording');

    await _engine.start(microphone: microphone);

    _elapsed = Duration.zero;
    _capped = false;
    _recording = true;
    _startedAt = _now();

    // A timer over two cheap native reads rather than a callback out of the
    // audio thread. Nothing here is on a deadline: the meter and the clock are
    // for a human to look at, and the recording is safe in native memory
    // whether or not this isolate is keeping up.
    _ticker = Timer.periodic(progressInterval, (_) => _tick());
  }

  void _tick() {
    if (!_recording) return;

    final Duration elapsed;
    final double level;
    try {
      elapsed = _engine.elapsed;
      level = _engine.level;
    } on Object catch (error, stack) {
      if (!_progress.isClosed) _progress.addError(error, stack);
      return;
    }

    _elapsed = elapsed;

    // Check the cap before emitting, and always emit once it trips. The tick is
    // how the caller learns to stop; setting the flag without a tick would
    // leave a recording nobody knows to finish.
    if (elapsed >= maxDuration && !_capped) {
      _capped = true;
    }

    if (!_progress.isClosed) {
      _progress.add(VoiceMemoProgress(elapsed: elapsed, level: level));
    }
  }

  /// Stop recording and return the memo, or null when nothing worth keeping was
  /// captured — see [kMinVoiceMemoDuration].
  Future<VoiceMemo?> stop() async {
    if (!_recording) return null;
    _recording = false;
    _stopTicker();

    final capture = await _engine.stop();
    if (capture == null ||
        capture.bytes.isEmpty ||
        capture.duration < kMinVoiceMemoDuration) {
      return null;
    }

    // The container's length, not the clock that has been driving the meter:
    // the container is what gets stored, and it is what every other reader of
    // these bytes will report.
    _elapsed = capture.duration;

    return VoiceMemo(
      bytes: capture.bytes,
      duration: capture.duration,
      filename: _filenameFor(_startedAt ?? _now()),
    );
  }

  /// Stop recording and discard everything captured.
  Future<void> cancel() async {
    if (!_recording) return;
    _recording = false;
    _stopTicker();

    try {
      await _engine.cancel();
    } on Object {
      // Cancelling is best-effort: the memo is going in the bin either way.
    }
  }

  Future<void> dispose() async {
    await cancel();
    _stopTicker();
    await _progress.close();
    await _engine.dispose();
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  static String _filenameFor(DateTime when) {
    String two(int value) => value.toString().padLeft(2, '0');
    return 'memo ${when.year}-${two(when.month)}-${two(when.day)} '
        '${two(when.hour)}-${two(when.minute)}-${two(when.second)}.opus';
  }
}
