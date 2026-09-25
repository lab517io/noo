/// The Voice-memos preferences tab: choosing devices, and the self-test.
///
/// What is worth pinning down here is the awkward half of device selection —
/// a name that no longer matches anything, and a machine that cannot enumerate
/// at all — because both are silent failures everywhere else.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/services/audio/voice_memo_recorder.dart';
import 'package:noo/data/services/audio/whisper_service.dart';
import 'package:noo/presentation/providers/audio_check_provider.dart';
import 'package:noo/presentation/providers/audio_device_provider.dart';
import 'package:noo/presentation/providers/settings_provider.dart';
import 'package:noo/presentation/providers/voice_memo_provider.dart';
import 'package:noo/presentation/widgets/dialogs/voice_memo_settings_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/audio/audio_fakes.dart';
import '../data/audio/voice_memo_recorder_test.dart' show FakeVoiceMemoEngine;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAudioDeviceSource devices;
  late FakeVoiceMemoEngine engine;
  late FakeMemoPlayer player;
  late FakeWhisper whisper;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    devices = FakeAudioDeviceSource();
    engine = FakeVoiceMemoEngine();
    player = FakeMemoPlayer();
    whisper = FakeWhisper(present: false);
  });

  /// Settle the widget *and* the event loop.
  ///
  /// The self-test tears down a stream subscription on its way out of each
  /// stage, and a subscription cancel does not finish inside `pumpAndSettle`'s
  /// fake async — the state change lands after the test has already looked.
  /// See the note about `runAsync` in AGENTS.md.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pumpAndSettle();
  }

  Future<ProviderContainer> pumpForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: [
      audioDeviceSourceProvider.overrideWithValue(devices),
      memoPlayerProvider.overrideWithValue(player),
      // Not for what it transcribes — no model is selected in most of these —
      // but because the real one reaches the whisper plugin's channel when the
      // container is disposed, which under `flutter test` throws at teardown.
      whisperServiceProvider.overrideWithValue(whisper),
      voiceMemoRecorderFactoryProvider.overrideWithValue(
        () => VoiceMemoRecorder(
          engine: engine,
          progressInterval: const Duration(milliseconds: 5),
        ),
      ),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: VoiceMemoSettingsForm(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('device selection', () {
    testWidgets('lists what the platform reports, headed by the default',
        (tester) async {
      await pumpForm(tester);

      expect(find.text('System default'), findsNWidgets(2));
      await tester.tap(find.text('System default').first);
      await tester.pumpAndSettle();

      // The platform's own default is marked, so "System default" and the
      // named device that currently *is* it are not a blind choice.
      expect(find.text('Built-in mic (default)'), findsWidgets);
      expect(find.text('USB headset'), findsWidgets);
    });

    testWidgets('choosing a microphone writes the preference', (tester) async {
      final container = await pumpForm(tester);

      await tester.tap(find.text('System default').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('USB headset').last);
      await tester.pumpAndSettle();

      expect(container.read(settingsProvider).voiceMemoInputDevice,
          'USB headset');
      // Chosen by name, because an index means nothing after a device change.
      expect(SharedPreferences.getInstance().then((p) => p.getString(
              SettingsKeys.voiceMemoInputDevice)),
          completion('USB headset'));
    });

    testWidgets('marks a stored device that is no longer connected',
        (tester) async {
      final container = await pumpForm(tester);
      await container
          .read(settingsProvider.notifier)
          .setVoiceMemoInputDevice('Podcast mic');
      await tester.pumpAndSettle();

      // Not silently reset to the default: the preference on disk still says
      // "Podcast mic", and the dialog has to say the same thing.
      expect(find.text('Podcast mic (not connected)'), findsOneWidget);
    });

    testWidgets('renders when the devices cannot be listed at all',
        (tester) async {
      devices = FakeAudioDeviceSource(failing: true);
      await pumpForm(tester);

      expect(find.text('Unavailable'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Refresh re-scans the hardware', (tester) async {
      await pumpForm(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Refresh'));
      await tester.pumpAndSettle();

      expect(devices.rescans, 1);
    });
  });

  group('the self-test', () {
    testWidgets('records, plays back, and reports the result', (tester) async {
      await pumpForm(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Test'));
      await settle(tester);
      expect(find.textContaining('say a sentence'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Stop'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Stop'));
      await settle(tester);

      expect(player.playedBytes, isNotNull);
      // No model is selected in this container, so the run passes on capture
      // and playback and says why there is no text.
      expect(find.textContaining('No model is selected'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Test again'), findsOneWidget);
    });

    testWidgets('shows the transcription percentage while it runs',
        (tester) async {
      whisper
        ..present = true
        ..blocks = 4;
      final container = await pumpForm(tester);
      await container
          .read(settingsProvider.notifier)
          .setVoiceMemoModel(VoiceMemoModel.base);
      await tester.pumpAndSettle();

      // The final state is what a widget test can see; the intermediate ticks
      // are covered in `audio_check_provider_test.dart`, which can watch the
      // notifier rather than a repainted frame.
      final notifier = container.read(audioCheckProvider.notifier);
      await notifier.start();
      await settle(tester);
      final running = notifier.finish();
      await tester.pump();
      await settle(tester);
      await running;

      expect(find.textContaining('the quick brown fox'), findsOneWidget);
      expect(container.read(audioCheckProvider).transcription?.fraction, 1.0);
    });

    testWidgets('names the stage that failed', (tester) async {
      engine.failOnStart = true;
      await pumpForm(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Test'));
      await settle(tester);

      expect(find.textContaining('would not open'), findsOneWidget);
      expect(player.playedBytes, isNull);
    });

    testWidgets('Cancel abandons a run in progress', (tester) async {
      await pumpForm(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Test'));
      await settle(tester);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
      await settle(tester);

      expect(engine.cancelled, isTrue);
      expect(player.playedBytes, isNull);
      expect(find.widgetWithText(FilledButton, 'Test'), findsOneWidget);
    });

    testWidgets('the model row is untouched by all of this', (tester) async {
      await pumpForm(tester);

      // Nothing downloads by itself, and adding two group boxes around it
      // must not have changed that.
      expect(find.text('Download'), findsNothing);
      expect(find.text(VoiceMemoModel.none.label), findsWidgets);
    });
  });
}
