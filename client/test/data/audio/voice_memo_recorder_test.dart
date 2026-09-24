/// The recorder, driven through a fake engine.
///
/// Everything that used to be tested here and is not any more moved into
/// `voice_audio` with the code: frame accumulation, the encoder's lookahead,
/// the level calculation and the Ogg container are covered by that package's
/// own C++ and Dart suites, against a real signal. What is left is ng's part —
/// the elapsed clock, the meter, the filename, cancel, the length cap and how
/// failures are reported — and none of it needs audio hardware, a native
/// library, or a microphone permission.
@TestOn('vm')
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/services/audio/voice_memo_recorder.dart';
import 'package:voice_audio/voice_audio.dart' as va;

import 'memo_fixture.dart';

/// A [VoiceMemoEngine] the test drives by hand.
///
/// Returns a real Ogg Opus recording from `test/fixtures`, so anything that
/// reads the bytes downstream — the attachment row, a re-transcription, a
/// playback attempt — gets something genuinely playable rather than a
/// placeholder that only looks like audio.
class FakeVoiceMemoEngine implements VoiceMemoEngine {
  FakeVoiceMemoEngine({
    VoiceMemoCapture? capture,
    this.permitted = true,
    this.failOnStart = false,
  }) : capture = capture ?? memoFixture();

  /// What [stop] hands back. Null means nothing was captured.
  VoiceMemoCapture? capture;

  bool permitted;
  bool failOnStart;

  /// Driven by the test; the recorder polls these on its progress timer.
  Duration _elapsed = Duration.zero;
  double _level = 0;

  /// Set to have every poll throw from then on, standing in for a device that
  /// went away mid-recording.
  Object? failOnPoll;

  @override
  Duration get elapsed {
    final failure = failOnPoll;
    if (failure != null) throw failure;
    return _elapsed;
  }

  @override
  double get level {
    final failure = failOnPoll;
    if (failure != null) throw failure;
    return _level;
  }

  bool started = false;
  bool stopped = false;
  bool cancelled = false;
  bool disposed = false;

  @override
  Future<bool> hasPermission() async => permitted;

  /// The device the last [start] was handed, so a test can assert that the
  /// preference reached the engine rather than being resolved and dropped.
  va.AudioDevice? startedWith;

  @override
  Future<void> start({va.AudioDevice? microphone}) async {
    if (failOnStart) throw StateError('device would not open');
    started = true;
    startedWith = microphone;
  }

  @override
  Future<VoiceMemoCapture?> stop() async {
    stopped = true;
    return capture;
  }

  @override
  Future<void> cancel() async => cancelled = true;

  @override
  Future<void> dispose() async => disposed = true;

  /// Advance the recording, as the native side would.
  void advance(Duration by, {double at = 0.5}) {
    _elapsed += by;
    _level = at;
  }
}

void main() {
  const tick = Duration(milliseconds: 5);

  /// Let a few progress timers fire.
  Future<void> pump([int ticks = 4]) =>
      Future<void>.delayed(tick * (ticks + 1));

  VoiceMemoRecorder recorderFor(
    FakeVoiceMemoEngine engine, {
    Duration? maxDuration,
    DateTime Function()? clock,
  }) {
    return VoiceMemoRecorder(
      engine: engine,
      progressInterval: tick,
      maxDuration: maxDuration ?? VoiceMemoRecorder.kMaxVoiceMemoDuration,
      clock: clock,
    );
  }

  group('VoiceMemoRecorder', () {
    test('returns the recording the engine captured', () async {
      final engine = FakeVoiceMemoEngine();
      final recorder = recorderFor(engine);

      await recorder.start();
      expect(engine.started, isTrue);
      expect(recorder.isRecording, isTrue);

      final memo = await recorder.stop();

      expect(memo, isNotNull);
      expect(engine.stopped, isTrue);
      expect(recorder.isRecording, isFalse);

      // A real Ogg Opus file, not a stand-in: it starts with an Ogg page and
      // reports the length the fixture was made at.
      expect(String.fromCharCodes(memo!.bytes.take(4)), 'OggS');
      expect(memo.duration, const Duration(seconds: 1));
      await recorder.dispose();
    });

    test('names the memo after the moment it started', () async {
      final engine = FakeVoiceMemoEngine();
      final recorder = recorderFor(
        engine,
        clock: () => DateTime(2026, 3, 7, 21, 5, 33),
      );

      await recorder.start();
      final memo = await recorder.stop();

      // Dashes, not colons: Windows will not have a colon in a filename, and
      // attachments keep their name when exported.
      expect(memo!.filename, 'memo 2026-03-07 21-05-33.opus');
      await recorder.dispose();
    });

    test('reports elapsed time and level while recording', () async {
      final engine = FakeVoiceMemoEngine();
      final recorder = recorderFor(engine);

      final ticks = <VoiceMemoProgress>[];
      final subscription = recorder.progress.listen(ticks.add);

      await recorder.start();
      engine.advance(const Duration(milliseconds: 200), at: 0.4);
      await pump();

      expect(ticks, isNotEmpty);
      expect(ticks.last.elapsed, const Duration(milliseconds: 200));
      expect(ticks.last.level, 0.4);
      expect(recorder.elapsed, const Duration(milliseconds: 200));

      await subscription.cancel();
      await recorder.dispose();
    });

    test('stops ticking once the recording ends', () async {
      final engine = FakeVoiceMemoEngine();
      final recorder = recorderFor(engine);

      final ticks = <VoiceMemoProgress>[];
      final subscription = recorder.progress.listen(ticks.add);

      await recorder.start();
      await pump();
      await recorder.stop();

      final settled = ticks.length;
      await pump();
      expect(ticks.length, settled,
          reason: 'the timer must not outlive the recording');

      await subscription.cancel();
      await recorder.dispose();
    });

    test('cancel throws the recording away and never returns bytes', () async {
      final engine = FakeVoiceMemoEngine();
      final recorder = recorderFor(engine);

      await recorder.start();
      await recorder.cancel();

      expect(engine.cancelled, isTrue);
      expect(engine.stopped, isFalse);
      expect(recorder.isRecording, isFalse);
      expect(await recorder.stop(), isNull);
      await recorder.dispose();
    });

    test('a recording with no audio in it is not a memo', () async {
      final engine = FakeVoiceMemoEngine()..capture = null;
      final recorder = recorderFor(engine);

      await recorder.start();
      expect(await recorder.stop(), isNull);
      await recorder.dispose();
    });

    test('a zero-length recording is not a memo either', () async {
      final engine = FakeVoiceMemoEngine(
        capture: VoiceMemoCapture(
            bytes: Uint8List.fromList(const [1, 2, 3]),
            duration: Duration.zero),
      );
      final recorder = recorderFor(engine);

      await recorder.start();
      expect(await recorder.stop(), isNull);
      await recorder.dispose();
    });

    test('a press too short to be a memo stores nothing', () async {
      // Not a hypothetical: stop straight after start and the engine still
      // reports two 20 ms frames, so this is the only thing standing between a
      // stray tap on the mic button and an attachment row.
      final engine = FakeVoiceMemoEngine(
        capture: memoFixture(duration: const Duration(milliseconds: 20)),
      );
      final recorder = recorderFor(engine);

      await recorder.start();
      expect(await recorder.stop(), isNull);
      await recorder.dispose();
    });

    test('a press just over the floor is kept', () async {
      final engine = FakeVoiceMemoEngine(
        capture: memoFixture(
            duration: VoiceMemoRecorder.kMinVoiceMemoDuration +
                const Duration(milliseconds: 20)),
      );
      final recorder = recorderFor(engine);

      await recorder.start();
      final memo = await recorder.stop();
      expect(memo, isNotNull);
      expect(memo!.bytes, isNotEmpty);
      await recorder.dispose();
    });

    test('stops itself at the length cap', () async {
      final engine = FakeVoiceMemoEngine();
      final recorder =
          recorderFor(engine, maxDuration: const Duration(milliseconds: 500));

      final ticks = <VoiceMemoProgress>[];
      final subscription = recorder.progress.listen(ticks.add);

      await recorder.start();
      expect(recorder.reachedLimit, isFalse);

      engine.advance(const Duration(milliseconds: 600));
      await pump();

      expect(recorder.reachedLimit, isTrue);
      // The tick is how the caller learns to stop. Setting the flag without
      // emitting would leave a recording that nobody knows to finish.
      expect(ticks.last.elapsed, greaterThanOrEqualTo(recorder.maxDuration));

      await subscription.cancel();
      await recorder.dispose();
    });

    test('surfaces a device error on the progress stream', () async {
      final engine = FakeVoiceMemoEngine()
        ..failOnPoll = StateError('the device went away');
      final recorder = recorderFor(engine);

      final errors = <Object>[];
      final subscription =
          recorder.progress.listen((_) {}, onError: errors.add);

      await recorder.start();
      await pump();

      expect(errors, isNotEmpty);
      await subscription.cancel();
      await recorder.dispose();
    });

    test('an engine that cannot start leaves nothing behind', () async {
      final engine = FakeVoiceMemoEngine(failOnStart: true);
      final recorder = recorderFor(engine);

      await expectLater(recorder.start(), throwsA(isA<StateError>()));
      expect(recorder.isRecording, isFalse);
      await recorder.dispose();
    });

    test('refuses to start twice', () async {
      final engine = FakeVoiceMemoEngine();
      final recorder = recorderFor(engine);

      await recorder.start();
      await expectLater(recorder.start(), throwsA(isA<StateError>()));
      await recorder.dispose();
    });

    test('permission is reported, not assumed', () async {
      final engine = FakeVoiceMemoEngine(permitted: false);
      final recorder = recorderFor(engine);

      expect(await recorder.hasPermission(), isFalse);

      engine.permitted = true;
      expect(await recorder.hasPermission(), isTrue);
      await recorder.dispose();
    });

    test('dispose releases the engine and closes the stream', () async {
      final engine = FakeVoiceMemoEngine();
      final recorder = recorderFor(engine);

      await recorder.start();
      await recorder.dispose();

      expect(engine.cancelled, isTrue);
      expect(engine.disposed, isTrue);
      expect(recorder.progress.isBroadcast, isTrue);
    });
  });
}
