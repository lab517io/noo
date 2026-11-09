import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/widgets/task_editor/task_editor_panel.dart';
import 'package:noo/presentation/widgets/task_tree/task_tree_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Picking a task in the tree with the mouse and typing straight away.
///
/// On desktop flutter_quill drops its focus on any click outside the editor,
/// and a tree row is exactly that. Nothing else took focus, so after choosing
/// a task every keystroke went to the root scope and Ctrl+C — routed by focus —
/// did nothing, while the editor still painted its selection. The row now hands
/// focus back to the editor once the click has been applied.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NooDatabase db;
  late int taskId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = NooDatabase.memory();
    taskId = await db.createTask(
      worldId: WorldId.create().value,
      title: 'Budget review',
    );
  });

  tearDown(() async => db.close());

  /// Runs [body] on a desktop platform — where a click outside the editor
  /// costs it focus. The override has to be undone inside the test body: the
  /// framework asserts it is clear before tearDown gets a turn.
  Future<void> onDesktop(Future<void> Function() body) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await body();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  /// The desktop layout: tree on the left, editor beside it, task selected.
  Future<void> pumpWide(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    container.read(selectedTaskIdProvider.notifier).value = taskId;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
          home: Scaffold(
            body: Row(
              children: [
                SizedBox(width: 300, child: TaskTreePanel()),
                Expanded(child: TaskEditorPanel()),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Budget review'), findsOneWidget);
    expect(find.byType(QuillEditor), findsOneWidget);
  }

  FocusNode editorFocus(WidgetTester tester) =>
      tester.widget<QuillEditor>(find.byType(QuillEditor)).focusNode;

  Future<void> mouseClick(WidgetTester tester, Offset at) async {
    final gesture =
        await tester.startGesture(at, kind: PointerDeviceKind.mouse);
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('a mouse click on a tree row leaves the editor focused',
      (tester) async {
    await onDesktop(() async {
      await pumpWide(tester);

      // Put the caret in the text, as a user does before working in a note.
      final editor = tester.getRect(find.byType(QuillEditor));
      await mouseClick(tester, Offset(editor.left + 20, editor.top + 20));
      expect(editorFocus(tester).hasFocus, isTrue);

      // Pick the task in the tree.
      await mouseClick(tester, tester.getCenter(find.text('Budget review')));

      expect(editorFocus(tester).hasFocus, isTrue,
          reason: 'typing after picking a task must land in the editor');
    });
  });

  testWidgets('a mouse click on a tree row focuses an editor that never had it',
      (tester) async {
    await onDesktop(() async {
      await pumpWide(tester);
      expect(editorFocus(tester).hasFocus, isFalse);

      await mouseClick(tester, tester.getCenter(find.text('Budget review')));

      expect(editorFocus(tester).hasFocus, isTrue);
    });
  });

  testWidgets('a touch tap on a tree row does not focus the editor',
      (tester) async {
    await pumpWide(tester);
    expect(editorFocus(tester).hasFocus, isFalse);

    await tester.tap(find.text('Budget review'));
    await tester.pumpAndSettle();

    expect(editorFocus(tester).hasFocus, isFalse,
        reason: 'a touch tap must not pop the soft keyboard');
  });
}
