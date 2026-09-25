@TestOn('vm')
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/audio/voice_memo_recorder.dart';
import 'package:noo/data/services/audio/whisper_service.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/providers/settings_provider.dart';
import 'package:noo/presentation/providers/voice_memo_provider.dart';
import 'package:noo/presentation/widgets/task_editor/voice_memo_ops.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/audio/audio_fakes.dart';
import '../data/audio/memo_fixture.dart';
import '../data/audio/voice_memo_recorder_test.dart' show FakeVoiceMemoEngine;

/// A whisper that answers instantly, so the flow around it can be checked
/// without a 78 MB model on disk.
class FakeWhisperService extends WhisperService {
  FakeWhisperService({this.result = 'hello world', this.throws = false});

  String? result;
  bool throws;

  /// The bytes it was asked to transcribe — a memo, not a stream of chunks.
  Uint8List? received;
  int calls = 0;

  @override
  Future<String?> transcribeMemo(
    Uint8List oggBytes, {
    required VoiceMemoModel model,
    String language = 'en',
    void Function(TranscriptionProgress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    calls++;
    received = oggBytes;
    if (throws) throw StateError('whisper fell over');
    return result;
  }

  @override
  Future<void> release() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('insertTranscript', () {
    late QuillController controller;

    setUp(() => controller = QuillController.basic());
    tearDown(() => controller.dispose());

    String documentText() => controller.document.toPlainText();

    test('inserts the text at the caret as a paragraph', () {
      expect(
        insertTranscript(controller,
            transcript: 'the quick brown fox',
            openTaskId: 7,
            memoTaskId: 7),
        isTrue,
      );
      expect(documentText(), 'the quick brown fox\n\n');
    });

    test('leaves the caret after what it wrote, ready to keep typing', () {
      insertTranscript(controller,
          transcript: 'first memo', openTaskId: 1, memoTaskId: 1);
      expect(controller.selection.baseOffset, 'first memo\n'.length);

      insertTranscript(controller,
          transcript: 'second memo', openTaskId: 1, memoTaskId: 1);
      expect(documentText(), 'first memo\nsecond memo\n\n');
    });

    test('inserts into existing content at the caret, not at the end', () {
      controller.document.insert(0, 'before after');
      controller.updateSelection(
        const TextSelection.collapsed(offset: 7),
        ChangeSource.local,
      );
      insertTranscript(controller,
          transcript: 'MEMO', openTaskId: 1, memoTaskId: 1);
      expect(documentText(), startsWith('before MEMO\nafter'));
    });

    test('replaces the selection, like any other insert', () {
      controller.document.insert(0, 'keep DROP keep');
      controller.updateSelection(
        const TextSelection(baseOffset: 5, extentOffset: 9),
        ChangeSource.local,
      );
      insertTranscript(controller,
          transcript: 'NEW', openTaskId: 1, memoTaskId: 1);
      expect(documentText(), startsWith('keep NEW\n keep'));
    });

    test('writes nothing when the editor has moved to another task', () {
      // The memo belongs to task 7; the user navigated to task 8 while it was
      // being transcribed. Losing the insert beats writing into the wrong note.
      expect(
        insertTranscript(controller,
            transcript: 'wrong note', openTaskId: 8, memoTaskId: 7),
        isFalse,
      );
      expect(documentText().trim(), isEmpty);
    });

    test('writes nothing when no task is open', () {
      expect(
        insertTranscript(controller,
            transcript: 'nowhere', openTaskId: null, memoTaskId: 7),
        isFalse,
      );
      expect(documentText().trim(), isEmpty);
    });

    test('an empty or blank transcript is not an insert', () {
      expect(
        insertTranscript(controller,
            transcript: '', openTaskId: 1, memoTaskId: 1),
        isFalse,
      );
      expect(
        insertTranscript(controller,
            transcript: '   \n\t ', openTaskId: 1, memoTaskId: 1),
        isFalse,
      );
      expect(documentText().trim(), isEmpty);
    });

    test('trims the whitespace whisper leaves around its output', () {
      insertTranscript(controller,
          transcript: '  padded text \n', openTaskId: 1, memoTaskId: 1);
      expect(documentText(), 'padded text\n\n');
    });
  });

  group('transcribing after the memo is stored', () {
    late NooDatabase db;
    late int taskId;
    late FakeVoiceMemoEngine engine;
    late FakeWhisperService whisper;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'voice_memo_model': 'tiny',
        'voice_memo_transcribe': true,
      });
      db = NooDatabase.memory();
      taskId = await db.createTask(
        worldId: WorldId.create().value,
        title: 'Task',
      );
      engine = FakeVoiceMemoEngine();
      whisper = FakeWhisperService();
      addTearDown(db.close);
    });

    Future<ProviderContainer> makeContainer() async {
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        whisperServiceProvider.overrideWithValue(whisper),
        voiceMemoRecorderFactoryProvider.overrideWithValue(
          () => VoiceMemoRecorder(
            engine: engine,
            progressInterval: const Duration(milliseconds: 5),
          ),
        ),
      ]);
      addTearDown(container.dispose);
      container.read(settingsProvider);
      await pumpEventQueue();
      return container;
    }

    test('transcribes the stored bytes, not a live stream', () async {
      final container = await makeContainer();
      final notifier = container.read(voiceMemoProvider.notifier);

      await notifier.start(taskId);
      engine.advance(const Duration(seconds: 1));
      final stored = await notifier.stop();

      expect(stored!.transcript, 'hello world');
      expect(whisper.calls, 1);

      // The bytes handed to whisper are the ones that went into the database.
      // That is the whole point of transcribing afterwards: what gets
      // transcribed is provably what got stored.
      expect(whisper.received, memoFixtureBytes());
    });

    test('the memo is already saved before transcription runs', () async {
      whisper.throws = true;
      final container = await makeContainer();
      final notifier = container.read(voiceMemoProvider.notifier);

      await notifier.start(taskId);
      engine.advance(const Duration(seconds: 1));
      final stored = await notifier.stop();

      // Whisper fell over and the memo survived it, with no error shown: a
      // transcript is a bonus, the audio is the memo.
      expect(stored, isNotNull);
      expect(stored!.transcript, isNull);
      expect(await db.getAttachmentsForTask(taskId), hasLength(1));
      expect(container.read(voiceMemoProvider).error, isNull);
    });

    test('an empty transcript is an ordinary outcome, not a failure', () async {
      whisper.result = null;
      final container = await makeContainer();
      final notifier = container.read(voiceMemoProvider.notifier);

      await notifier.start(taskId);
      engine.advance(const Duration(seconds: 1));
      final stored = await notifier.stop();

      expect(stored, isNotNull);
      expect(stored!.hasTranscript, isFalse);
      expect(container.read(voiceMemoProvider).error, isNull);
    });

    test('nothing is transcribed when the setting is off', () async {
      SharedPreferences.setMockInitialValues({
        'voice_memo_model': 'tiny',
        'voice_memo_transcribe': false,
      });
      final container = await makeContainer();
      final notifier = container.read(voiceMemoProvider.notifier);

      await notifier.start(taskId);
      engine.advance(const Duration(seconds: 1));
      final stored = await notifier.stop();

      expect(stored!.transcript, isNull);
      expect(whisper.calls, 0);
      expect(await db.getAttachmentsForTask(taskId), hasLength(1));
    });

    test('nothing is transcribed when no model is chosen', () async {
      SharedPreferences.setMockInitialValues({'voice_memo_transcribe': true});
      final container = await makeContainer();
      final notifier = container.read(voiceMemoProvider.notifier);

      await notifier.start(taskId);
      engine.advance(const Duration(seconds: 1));
      final stored = await notifier.stop();

      expect(stored!.transcript, isNull);
      expect(whisper.calls, 0);
    });

    test('a cancelled recording transcribes nothing', () async {
      final container = await makeContainer();
      final notifier = container.read(voiceMemoProvider.notifier);

      await notifier.start(taskId);
      engine.advance(const Duration(seconds: 1));
      await notifier.cancel();

      expect(whisper.calls, 0);
      expect(await db.getAttachmentsForTask(taskId), isEmpty);
    });
  });

  group('the Transcribe action on a stored memo', () {
    late NooDatabase db;
    late int taskId;
    late FakeWhisper whisper;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'voice_memo_model': 'tiny'});
      db = NooDatabase.memory();
      taskId = await db.createTask(
        worldId: WorldId.create().value,
        title: 'Task',
      );
      whisper = FakeWhisper()..blocks = 4;
      addTearDown(db.close);
    });

    /// Runs [body] outside the fake-async zone, then rebuilds.
    ///
    /// The action loads the attachment from the database on its way to
    /// whisper, and database work does not progress under fake async — the
    /// same reason `voice_memo_bar_test.dart` has one of these.
    Future<void> real(WidgetTester tester, Future<void> Function() body) async {
      await tester.runAsync(body);
      await tester.pumpAndSettle();
    }

    /// A screen whose context has a real `ScaffoldMessenger` for the snack bar
    /// to live in, with the action ready to run against a stored memo.
    Future<
        ({
          QuillController controller,
          Future<void> Function() transcribe,
        })> pumpAction(WidgetTester tester) async {
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        whisperServiceProvider.overrideWithValue(whisper),
      ]);
      addTearDown(container.dispose);
      // Started *inside* the real zone: `SettingsNotifier.build` kicks off a
      // SharedPreferences read, and a future created in the fake zone does not
      // complete in a later `runAsync`. Read there and the settings arrive as
      // "tiny" rather than staying at the default "off", which would make the
      // action bail before it ever reached whisper.
      await tester.runAsync(() async {
        container.read(settingsProvider);
        await pumpEventQueue();
      });

      final repo = container.read(attachmentRepositoryProvider)!;
      final memo = await repo.createAttachment(
        taskId: taskId,
        filename: 'memo.opus',
        content: memoFixtureBytes(),
      );

      final controller = QuillController.basic();
      addTearDown(controller.dispose);

      late BuildContext screen;
      late WidgetRef reference;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(builder: (context, ref, _) {
                screen = context;
                reference = ref;
                return const SizedBox.expand();
              }),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      return (
        controller: controller,
        transcribe: () => transcribeStoredMemo(
              screen,
              reference,
              controller,
              memo: memo,
              openTaskId: taskId,
            ),
      );
    }

    testWidgets('shows progress with a Cancel beside it', (tester) async {
      final gate = Completer<void>();
      whisper.onBlock = (block) async {
        if (block == 1) await gate.future;
      };

      final screen = await pumpAction(tester);
      final running = screen.transcribe();
      await real(tester, () => pumpEventQueue());

      expect(find.textContaining('Transcribing…'), findsOneWidget);
      expect(find.widgetWithText(SnackBarAction, 'Cancel'), findsOneWidget);

      gate.complete();
      await real(tester, () => running);
    });

    testWidgets('Cancel stops it and inserts nothing', (tester) async {
      final gate = Completer<void>();
      whisper.onBlock = (block) async {
        if (block == 1) await gate.future;
      };

      final screen = await pumpAction(tester);
      final running = screen.transcribe();
      await real(tester, () => pumpEventQueue());

      await tester.tap(find.widgetWithText(SnackBarAction, 'Cancel'));
      await tester.pump();
      gate.complete();
      await real(tester, () => running);

      // Nothing in the note, and no "could not transcribe" scolding either:
      // the user is the one who stopped it.
      expect(screen.controller.document.toPlainText().trim(), isEmpty);
      expect(find.textContaining('Could not transcribe'), findsNothing);
      // It stopped where it was told to rather than running to the end.
      expect(whisper.blocksRun, 1);
    });

    testWidgets('left alone, it inserts the transcript', (tester) async {
      final screen = await pumpAction(tester);
      await real(tester, () => screen.transcribe());

      expect(screen.controller.document.toPlainText(),
          contains('the quick brown fox'));
      expect(whisper.blocksRun, 4);
    });
  });
}
