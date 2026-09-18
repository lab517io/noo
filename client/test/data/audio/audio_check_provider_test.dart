/// The Preferences self-test: record, play back, transcribe.
///
/// The point of the feature is that it names the stage that broke, so most of
/// what is checked here is the failure reporting — a microphone that captured
/// nothing, a clip that would not play, a model that was never downloaded —
/// rather than the happy path alone.
@TestOn('vm')
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/services/audio/voice_memo_recorder.dart';
import 'package:noo/data/services/audio/whisper_service.dart';
import 'package:noo/presentation/providers/audio_check_provider.dart';
import 'package:noo/presentation/providers/audio_device_provider.dart';
import 'package:noo/presentation/providers/settings_provider.dart';
import 'package:noo/presentation/providers/voice_memo_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_fakes.dart';
import 'memo_fixture.dart';
import 'voice_memo_recorder_test.dart' show FakeVoiceMemoEngine;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeVoiceMemoEngine engine;
  late FakeMemoPlayer player;
  late FakeWhisper whisper;
  late FakeAudioDeviceSource devices;

  /// Let the recorder's 5 ms progress timer fire a few times.
  Future<void> pump([int ticks = 4]) =>
      Future<void>.delayed(const Duration(milliseconds: 5) * (ticks + 1));

  Future<ProviderContainer> makeContainer() async {
    final container = ProviderContainer(overrides: [
      audioDeviceSourceProvider.overrideWithValue(devices),
      memoPlayerProvider.overrideWithValue(player),
      whisperServiceProvider.overrideWithValue(whisper),
      voiceMemoRecorderFactoryProvider.overrideWithValue(
        () => VoiceMemoRecorder(
          engine: engine,
          progressInterval: const Duration(milliseconds: 5),
        ),
      ),
    ]);
    addTearDown(container.dispose);
    // SettingsNotifier reads SharedPreferences asynchronously in build(); a
    // container torn down mid-read throws when the read touches its ref.
    container.read(settingsProvider);
    await pumpEventQueue();
    return container;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    engine = FakeVoiceMemoEngine();
    player = FakeMemoPlayer();
    whisper = FakeWhisper();
    devices = FakeAudioDeviceSource();
  });

  group('AudioCheckNotifier', () {
    test('records, plays back and transcribes, reporting each stage',
        () async {
      final container = await makeContainer();
      await container
          .read(settingsProvider.notifier)
          .setVoiceMemoModel(VoiceMemoModel.base);
      final notifier = container.read(audioCheckProvider.notifier);

      await notifier.start();
      expect(container.read(audioCheckProvider).stage,
          AudioCheckStage.recording);

      engine.advance(const Duration(seconds: 2), at: 0.4);
      await pump();
      expect(container.read(audioCheckProvider).level, 0.4);

      await notifier.finish();

      final state = container.read(audioCheckProvider);
      expect(state.stage, AudioCheckStage.done);
      expect(state.transcript, 'the quick brown fox');
      expect(state.recorded, kMemoFixtureDuration);
      expect(state.error, isNull);
      // The clip that was played is the one that was recorded, not a re-read.
      expect(player.playedBytes, memoFixtureBytes());
      expect(whisper.calls, 1);
    });

    test('records from the microphone chosen in Preferences', () async {
      final container = await makeContainer();
      await container
          .read(settingsProvider.notifier)
          .setVoiceMemoInputDevice('USB headset');

      await container.read(audioCheckProvider.notifier).start();

      expect(engine.startedWith?.name, 'USB headset');
      expect(engine.startedWith?.index, 1);
      await container.read(audioCheckProvider.notifier).cancel();
    });

    test('plays back through the speaker chosen in Preferences', () async {
      final container = await makeContainer();
      await container
          .read(settingsProvider.notifier)
          .setVoiceMemoOutputDevice('HDMI out');
      final notifier = container.read(audioCheckProvider.notifier);

      await notifier.start();
      await notifier.finish();

      expect(player.playedThrough?.name, 'HDMI out');
    });

    test('falls back to the system default when the device is gone', () async {
      final container = await makeContainer();
      await container
          .read(settingsProvider.notifier)
          .setVoiceMemoInputDevice('Headset that was unplugged');

      await container.read(audioCheckProvider.notifier).start();

      // Null is `voice_audio`'s own word for the platform default, so a stale
      // name must not become an index pointing at some other device.
      expect(engine.startedWith, isNull);
      await container.read(audioCheckProvider.notifier).cancel();
    });

    test('reports a microphone that captured nothing', () async {
      engine.capture = null;
      final container = await makeContainer();
      final notifier = container.read(audioCheckProvider.notifier);

      await notifier.start();
      await notifier.finish();

      final state = container.read(audioCheckProvider);
      expect(state.stage, AudioCheckStage.failed);
      expect(state.error, contains('Nothing was recorded'));
      expect(whisper.calls, 0);
    });

    test('reports a microphone that would not open', () async {
      engine.failOnStart = true;
      final container = await makeContainer();

      await container.read(audioCheckProvider.notifier).start();

      final state = container.read(audioCheckProvider);
      expect(state.stage, AudioCheckStage.failed);
      expect(state.error, contains('would not open'));
    });

    test('reports a refused microphone permission', () async {
      engine.permitted = false;
      final container = await makeContainer();

      await container.read(audioCheckProvider.notifier).start();

      expect(container.read(audioCheckProvider).error, contains('refused'));
    });

    test('reports playback that failed', () async {
      player.failure = StateError('no speaker');
      final container = await makeContainer();
      final notifier = container.read(audioCheckProvider.notifier);

      await notifier.start();
      await notifier.finish();

      final state = container.read(audioCheckProvider);
      expect(state.stage, AudioCheckStage.failed);
      expect(state.error, contains('Playback failed'));
      expect(whisper.calls, 0);
    });

    test('reports a clip the player could not parse', () async {
      player.playable = false;
      final container = await makeContainer();
      final notifier = container.read(audioCheckProvider.notifier);

      await notifier.start();
      await notifier.finish();

      expect(container.read(audioCheckProvider).error, contains('malformed'));
    });

    test('says nothing was transcribed when no model is selected', () async {
      final container = await makeContainer();
      final notifier = container.read(audioCheckProvider.notifier);

      await notifier.start();
      await notifier.finish();

      final state = container.read(audioCheckProvider);
      // Capture and playback are still a pass: the check reports what worked.
      expect(state.stage, AudioCheckStage.done);
      expect(state.note, contains('No model is selected'));
      expect(state.transcript, isNull);
      expect(whisper.calls, 0);
    });

    test('says so when the model has not been downloaded', () async {
      whisper.present = false;
      final container = await makeContainer();
      await container
          .read(settingsProvider.notifier)
          .setVoiceMemoModel(VoiceMemoModel.base);
      final notifier = container.read(audioCheckProvider.notifier);

      await notifier.start();
      await notifier.finish();

      final state = container.read(audioCheckProvider);
      expect(state.stage, AudioCheckStage.done);
      expect(state.note, contains('has not been downloaded'));
      expect(whisper.calls, 0);
    });

    test('blames silence when the meter never moved and there is no text',
        () async {
      whisper.text = null;
      final container = await makeContainer();
      await container
          .read(settingsProvider.notifier)
          .setVoiceMemoModel(VoiceMemoModel.base);
      final notifier = container.read(audioCheckProvider.notifier);

      await notifier.start();
      // No advance(at:) at all, so the peak stays at zero — which on the
      // platforms that answer a refused permission with silence is the only
      // signal there is.
      await notifier.finish();

      expect(container.read(audioCheckProvider).note, contains('silence'));
    });

    test('blames whisper, not the microphone, when the input was audible',
        () async {
      whisper.text = null;
      final container = await makeContainer();
      await container
          .read(settingsProvider.notifier)
          .setVoiceMemoModel(VoiceMemoModel.base);
      final notifier = container.read(audioCheckProvider.notifier);

      await notifier.start();
      engine.advance(const Duration(seconds: 1), at: 0.6);
      await pump();
      await notifier.finish();

      expect(container.read(audioCheckProvider).note, contains('no speech'));
    });

    test('passes the configured language to whisper', () async {
      final container = await makeContainer();
      final settings = container.read(settingsProvider.notifier);
      await settings.setVoiceMemoModel(VoiceMemoModel.base);
      await settings.setVoiceMemoLanguage('auto');
      final notifier = container.read(audioCheckProvider.notifier);

      await notifier.start();
      await notifier.finish();

      expect(whisper.language, 'auto');
    });

    test('reports transcription progress as it goes', () async {
      whisper.blocks = 4;
      final container = await makeContainer();
      await container
          .read(settingsProvider.notifier)
          .setVoiceMemoModel(VoiceMemoModel.base);
      final notifier = container.read(audioCheckProvider.notifier);

      final fractions = <double>[];
      final sub = container.listen(audioCheckProvider, (previous, next) {
        final progress = next.transcription;
        if (progress != null && progress != previous?.transcription) {
          fractions.add(progress.fraction);
        }
      });
      addTearDown(sub.close);

      await notifier.start();
      await notifier.finish();

      expect(fractions, [0.25, 0.5, 0.75, 1.0]);
      expect(container.read(audioCheckProvider).stage, AudioCheckStage.done);
    });

    test('reports transcription that threw', () async {
      whisper.failure = StateError('whisper fell over');
      final container = await makeContainer();
      await container
          .read(settingsProvider.notifier)
          .setVoiceMemoModel(VoiceMemoModel.base);
      final notifier = container.read(audioCheckProvider.notifier);

      await notifier.start();
      await notifier.finish();

      final state = container.read(audioCheckProvider);
      expect(state.stage, AudioCheckStage.failed);
      expect(state.error, contains('Transcription failed'));
    });

    test('stops itself at the length cap', () async {
      final container = await makeContainer();
      final notifier = container.read(audioCheckProvider.notifier);

      await notifier.start();
      engine.advance(AudioCheckNotifier.kMaxDuration, at: 0.5);
      await pump();
      await pumpEventQueue();

      // A user who walks away does not leave the microphone open: the run
      // finished on its own and went through playback.
      expect(container.read(audioCheckProvider).isRecording, isFalse);
      expect(player.playedBytes, isNotNull);
    });

    test('refuses to steal the microphone from a memo being recorded',
        () async {
      final container = await makeContainer();
      // A memo in flight is the state that matters, and `isBusy` is what the
      // check consults; drive the notifier into it directly rather than
      // standing up a database for one assertion.
      container.read(voiceMemoProvider.notifier).state =
          const VoiceMemoState(status: VoiceMemoStatus.recording, taskId: 1);

      await container.read(audioCheckProvider.notifier).start();

      final state = container.read(audioCheckProvider);
      expect(state.stage, AudioCheckStage.failed);
      expect(state.error, contains('voice memo is being recorded'));
      expect(engine.started, isFalse);
    });

    test('a run cancelled mid-playback never writes its result', () async {
      final container = await makeContainer();
      await container
          .read(settingsProvider.notifier)
          .setVoiceMemoModel(VoiceMemoModel.base);
      final notifier = container.read(audioCheckProvider.notifier);

      await notifier.start();
      // Nothing can interrupt a native decode, so playback and transcription
      // run to completion regardless — what must not happen is the finished
      // run putting a transcript into a panel the user has already cleared.
      final running = notifier.finish();
      await notifier.cancel();
      await running;

      final state = container.read(audioCheckProvider);
      expect(state.stage, AudioCheckStage.idle);
      expect(state.transcript, isNull);
    });

    test('cancel stops the transcription rather than waiting it out',
        () async {
      whisper.blocks = 6;
      final container = await makeContainer();
      await container
          .read(settingsProvider.notifier)
          .setVoiceMemoModel(VoiceMemoModel.base);
      final notifier = container.read(audioCheckProvider.notifier);

      // Cancel from inside the run, after the second of six blocks.
      whisper.onBlock = (block) async {
        if (block == 2) await notifier.cancel();
      };

      await notifier.start();
      await notifier.finish();

      final state = container.read(audioCheckProvider);
      expect(state.stage, AudioCheckStage.idle);
      expect(state.transcript, isNull);
      expect(state.error, isNull);
    });

    test('cancel discards the clip and returns to idle', () async {
      final container = await makeContainer();
      final notifier = container.read(audioCheckProvider.notifier);

      await notifier.start();
      await notifier.cancel();

      expect(container.read(audioCheckProvider).stage, AudioCheckStage.idle);
      expect(engine.cancelled, isTrue);
      expect(player.playedBytes, isNull);
    });
  });
}
