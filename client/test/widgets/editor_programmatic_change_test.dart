import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/widgets/task_editor/quill_editor_wrapper.dart';
import 'package:noo/presentation/widgets/task_editor/voice_memo_ops.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Changes to the document that are not keystrokes.
///
/// flutter_quill treats every controller notification as typing unless
/// `ignoreFocusOnTextChange` is set while it fires. On a phone with the soft
/// keyboard down, "typing" means: pop the keyboard, take focus, and skip the
/// refresh of the IME's copy of the text — after which the user's real
/// keystrokes are diffed against stale text and land wrongly or not at all.
/// The two programmatic writers here — a refresh of the open task and a
/// transcript insert — must fire with the flag set.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NooDatabase db;
  late int taskId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = NooDatabase.memory();
    taskId = await db.createTask(worldId: 'task-world-id', title: 'Task');
  });

  tearDown(() async => db.close());

  String content(String text) => jsonEncode([
        {'insert': '$text\n'},
      ]);

  Future<void> pumpEditor(
    WidgetTester tester,
    ProviderContainer container,
    String text,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [FlutterQuillLocalizations.delegate],
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: QuillEditorWrapper(
                contentKey: taskId,
                taskId: taskId,
                initialContent: content(text),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  QuillController controllerOf(WidgetTester tester) =>
      tester.widget<QuillEditor>(find.byType(QuillEditor)).controller;

  /// Records, for every notification the controller fires, whether the
  /// "not a keystroke" flag was set at the time.
  List<bool> recordFlag(QuillController controller) {
    final seen = <bool>[];
    controller.addListener(() => seen.add(controller.ignoreFocusOnTextChange));
    return seen;
  }

  testWidgets('a refresh of the open task is not treated as typing',
      (tester) async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await pumpEditor(tester, container, 'first');
    final controller = controllerOf(tester);
    final seen = recordFlag(controller);

    await pumpEditor(tester, container, 'second');

    expect(controller.document.toPlainText(), 'second\n');
    expect(seen, isNotEmpty, reason: 'the swap notifies the editor');
    expect(seen, everyElement(isTrue));
    expect(controller.ignoreFocusOnTextChange, isFalse,
        reason: 'the flag is only held for the swap itself');
  });

  testWidgets('a transcript insert is not treated as typing', (tester) async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await pumpEditor(tester, container, 'note');
    final controller = controllerOf(tester);
    final seen = recordFlag(controller);

    final written = insertTranscript(
      controller,
      transcript: 'spoken words',
      openTaskId: taskId,
      memoTaskId: taskId,
    );

    expect(written, isTrue);
    expect(controller.document.toPlainText(), startsWith('spoken words\nnote\n'));
    expect(seen, isNotEmpty);
    expect(seen, everyElement(isTrue));
    expect(controller.ignoreFocusOnTextChange, isFalse);
  });
}
