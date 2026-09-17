import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/audio/voice_memo_recorder.dart';
import 'package:noo/data/services/audio/whisper_service.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/providers/voice_memo_provider.dart';
import 'package:noo/presentation/widgets/task_editor/quill_editor_wrapper.dart';
import 'package:noo/presentation/widgets/task_editor/voice_memo_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/audio/voice_memo_recorder_test.dart' show FakeVoiceMemoEngine;

/// The recording strip and the toolbar's mic button, driven through the
/// provider with a fake engine. Nothing here needs audio hardware or a native
/// library: the recording is a fixture and the clock is advanced by hand.
void main() {
  late NooDatabase db;
  late int taskId;
  late FakeVoiceMemoEngine engine;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = NooDatabase.memory();
    taskId = await db.createTask(
      worldId: WorldId.create().value,
      title: 'Task',
    );
    engine = FakeVoiceMemoEngine();
  });

  tearDown(() async => db.close());

  ProviderContainer makeContainer() {
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      voiceMemoRecorderFactoryProvider.overrideWithValue(
        () => VoiceMemoRecorder(
          engine: engine,
          progressInterval: const Duration(milliseconds: 5),
        ),
      ),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  /// Runs [body] outside the fake-async zone, then rebuilds.
  ///
  /// Two things force this. Recording work is driven by a microphone stream:
  /// under fake async its events and teardown futures only progress when the
  /// microtask queue is pumped, and awaiting them from the test body blocks
  /// the very code that would pump — a deadlock with no timeout to break it,
  /// since the timeout would be a fake timer nobody advances either. And once
  /// the subscription is created in the real zone, the chunks fed to it have
  /// to be delivered there too.
  Future<void> real(WidgetTester tester, Future<void> Function() body) async {
    await tester.runAsync(body);
    await tester.pump();
  }

  /// Advance the recording and let the progress timer report it.
  Future<void> feed(WidgetTester tester, Duration by) =>
      real(tester, () async {
        engine.advance(by, at: 0.3);
        await Future<void>.delayed(const Duration(milliseconds: 30));
      });

  /// Tap something that kicks off recorder work, and let that work land.
  Future<void> tapAndRun(WidgetTester tester, Finder finder) =>
      real(tester, () async {
        await tester.tap(finder);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

  Future<void> startRecording(
    WidgetTester tester,
    ProviderContainer container,
  ) =>
      real(tester,
          () => container.read(voiceMemoProvider.notifier).start(taskId));

  Future<void> endRecording(
    WidgetTester tester,
    ProviderContainer container,
  ) =>
      real(tester,
          () => container.read(voiceMemoProvider.notifier).cancel());

  /// The bar needs a controller: Stop hands the transcript to the document,
  /// so without one the button is deliberately disabled.
  Future<void> pumpBar(WidgetTester tester, ProviderContainer container) {
    final controller = QuillController.basic();
    addTearDown(controller.dispose);
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: VoiceMemoBar(taskId: taskId, controller: controller),
          ),
        ),
      ),
    );
  }

  /// The editor harness needs a wide surface: the toolbar scrolls
  /// horizontally, and on the default 800x600 test view the custom buttons sit
  /// past its right edge — present in the tree, but offstage and untappable.
  Future<void> pumpEditor(WidgetTester tester, ProviderContainer container) {
    tester.view.physicalSize = const Size(2200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [FlutterQuillLocalizations.delegate],
          home: Scaffold(
            body: SizedBox(
              width: 2000,
              height: 500,
              child: QuillEditorWrapper(
                initialContent: '',
                contentKey: taskId,
                taskId: taskId,
                onContentChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('VoiceMemoBar', () {
    testWidgets('takes no space while idle', (tester) async {
      final container = makeContainer();
      await pumpBar(tester, container);

      expect(tester.getSize(find.byType(VoiceMemoBar)), Size.zero);
      expect(find.text('Stop'), findsNothing);
    });

    testWidgets('shows the elapsed clock and a stop button while recording',
        (tester) async {
      final container = makeContainer();
      await pumpBar(tester, container);

      await startRecording(tester, container);
      await feed(tester, const Duration(milliseconds: 3500));

      expect(find.text('0:03'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.byTooltip('Discard'), findsOneWidget);

      await endRecording(tester, container);
    });

    testWidgets('the stop button stores the memo', (tester) async {
      final container = makeContainer();
      await pumpBar(tester, container);

      await startRecording(tester, container);
      await feed(tester, const Duration(seconds: 1));
      await tapAndRun(tester, find.text('Stop'));

      expect(await db.getAttachmentsForTask(taskId), hasLength(1));
      expect(find.text('Stop'), findsNothing);
    });

    testWidgets('discard stores nothing and clears the bar', (tester) async {
      final container = makeContainer();
      await pumpBar(tester, container);

      await startRecording(tester, container);
      await feed(tester, const Duration(seconds: 1));
      await tapAndRun(tester, find.byTooltip('Discard'));

      expect(await db.getAttachmentsForTask(taskId), isEmpty);
      expect(tester.getSize(find.byType(VoiceMemoBar)), Size.zero);
    });

    testWidgets('shows a refusal, and it can be dismissed', (tester) async {
      engine.permitted = false;
      final container = makeContainer();
      await pumpBar(tester, container);

      await startRecording(tester, container);

      expect(find.textContaining('permission'), findsOneWidget);
      expect(find.text('Stop'), findsNothing);

      await tapAndRun(tester, find.byTooltip('Dismiss'));
      expect(tester.getSize(find.byType(VoiceMemoBar)), Size.zero);
    });

    testWidgets('says so when the length cap is reached', (tester) async {
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        voiceMemoRecorderFactoryProvider.overrideWithValue(
          () => VoiceMemoRecorder(
            engine: engine,
            progressInterval: const Duration(milliseconds: 5),
            maxDuration: const Duration(milliseconds: 300),
          ),
        ),
      ]);
      addTearDown(container.dispose);
      await pumpBar(tester, container);

      await startRecording(tester, container);
      await feed(tester, const Duration(seconds: 1)); // well past the cap

      // Stopped by itself, saved what it had, and said why.
      expect(await db.getAttachmentsForTask(taskId), hasLength(1));
      final state = container.read(voiceMemoProvider);
      expect(state.isBusy, isFalse);
      expect(state.reachedLimit, isTrue);
      expect(find.textContaining('limit'), findsOneWidget);

      await tapAndRun(tester, find.byTooltip('Dismiss'));
      expect(tester.getSize(find.byType(VoiceMemoBar)), Size.zero);
    });
  });

  group('the editor toolbar', () {
    testWidgets('offers a mic button that starts and stops a recording',
        (tester) async {
      final container = makeContainer();
      await pumpEditor(tester, container);

      final mic = find.byIcon(Icons.mic_none);
      expect(mic, findsOneWidget);
      expect(find.byType(VoiceMemoBar), findsOneWidget);
      expect(tester.getSize(find.byType(VoiceMemoBar)), Size.zero);

      await tapAndRun(tester, mic);

      // The same button is now a stop button, and the bar has appeared.
      expect(find.byIcon(Icons.stop_circle_outlined), findsOneWidget);
      expect(find.byIcon(Icons.mic_none), findsNothing);
      expect(tester.getSize(find.byType(VoiceMemoBar)).height, greaterThan(0));

      await feed(tester, const Duration(seconds: 1));
      await tapAndRun(tester, find.byIcon(Icons.stop_circle_outlined));

      expect(find.byIcon(Icons.mic_none), findsOneWidget);
      expect(await db.getAttachmentsForTask(taskId), hasLength(1));

      // Pressing a toolbar button hands focus back to the editor, which starts
      // flutter_quill's cursor-blink timer. Tear the tree down inside the test
      // so that timer is cancelled before the framework checks for strays.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('the transcribing notice', () {
    /// The bar reads the percentage straight off the state, so driving the
    /// state is enough — and it avoids standing up a whisper that reports
    /// ticks through a real recording, which `voice_memo_provider_test.dart`
    /// already covers.
    Future<void> pumpBar(WidgetTester tester, VoiceMemoState state) async {
      final container = makeContainer();
      container.read(voiceMemoProvider.notifier).state = state;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: VoiceMemoBar(taskId: 1)),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('says only "Transcribing…" before the first block',
        (tester) async {
      await pumpBar(
          tester,
          const VoiceMemoState(
              status: VoiceMemoStatus.transcribing, taskId: 1));
      expect(find.text('Saved. Transcribing…'), findsOneWidget);
    });

    testWidgets('keeps quiet about a percentage on a single-block memo',
        (tester) async {
      // One block means 0% and then done, which says less than the word does.
      await pumpBar(
        tester,
        const VoiceMemoState(
          status: VoiceMemoStatus.transcribing,
          taskId: 1,
          transcription: TranscriptionProgress(block: 0, total: 1, text: ''),
        ),
      );
      expect(find.text('Saved. Transcribing…'), findsOneWidget);
    });

    testWidgets('offers Cancel, not Discard and Stop', (tester) async {
      await pumpBar(
          tester,
          const VoiceMemoState(
              status: VoiceMemoStatus.transcribing, taskId: 1));

      // The memo is already stored by this point, so a "Discard" would be a
      // lie and a "Stop" has no recording left to stop.
      expect(find.widgetWithText(FilledButton, 'Cancel'), findsOneWidget);
      expect(find.text('Stop'), findsNothing);
      expect(find.byTooltip('Discard'), findsNothing);
    });

    testWidgets('Cancel leaves the bar and the transcription behind',
        (tester) async {
      final container = makeContainer();
      final notifier = container.read(voiceMemoProvider.notifier);
      notifier.state = const VoiceMemoState(
        status: VoiceMemoStatus.transcribing,
        taskId: 1,
        transcription:
            TranscriptionProgress(block: 1, total: 4, text: 'hello'),
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: VoiceMemoBar(taskId: 1)),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Cancel'));
      await tester.pump();

      // Idle, so the run's own poll of this status ends it at the next block.
      expect(container.read(voiceMemoProvider).status, VoiceMemoStatus.idle);
      expect(find.text('Cancel'), findsNothing);
    });

    testWidgets('shows the percentage once blocks start landing',
        (tester) async {
      await pumpBar(
        tester,
        const VoiceMemoState(
          status: VoiceMemoStatus.transcribing,
          taskId: 1,
          transcription:
              TranscriptionProgress(block: 1, total: 4, text: 'hello'),
        ),
      );
      // "Saved." stays in front of it: the point of the notice is that the
      // recording is already safe, whatever the transcription does next.
      expect(find.text('Saved. Transcribing… 25%'), findsOneWidget);
    });
  });
}
