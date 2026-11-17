import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/widgets/task_editor/quill_editor_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The right-click menu's Copy entry.
///
/// A right-click with nothing selected moves the caret to the pointer, and
/// flutter_quill still lists Copy and Cut for it; both silently do nothing on a
/// collapsed selection, which reads as "copy is broken". The menu now offers
/// them only when there is a selection to copy.
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

  Future<void> onDesktop(Future<void> Function() body) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await body();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  final content = jsonEncode([
    {'insert': 'hello world\n'},
  ]);

  Future<void> pumpEditor(WidgetTester tester,
      {String? withContent, bool readOnly = false}) async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

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
                initialContent: withContent ?? content,
                readOnly: readOnly,
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

  Offset inTheText(WidgetTester tester) {
    final box = tester.getRect(find.byType(QuillEditor));
    return Offset(box.left + 20, box.top + 25);
  }

  Future<void> leftClick(WidgetTester tester, Offset at) async {
    final gesture =
        await tester.startGesture(at, kind: PointerDeviceKind.mouse);
    await gesture.up();
    await tester.pumpAndSettle();
  }

  Future<void> rightClick(WidgetTester tester, Offset at) async {
    final gesture = await tester.startGesture(
      at,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('with nothing selected the menu offers no Copy or Cut',
      (tester) async {
    await onDesktop(() async {
      await pumpEditor(tester);
      final at = inTheText(tester);
      await leftClick(tester, at);
      expect(controllerOf(tester).selection.isCollapsed, isTrue);

      await rightClick(tester, at);

      expect(find.text('Select all'), findsOneWidget,
          reason: 'the menu itself is up');
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Cut'), findsNothing);
    });
  });

  /// Selects the first [length] characters and opens the menu over the text.
  Future<void> selectAndRightClick(WidgetTester tester, int length) async {
    final at = inTheText(tester);
    await leftClick(tester, at);
    controllerOf(tester).updateSelection(
      TextSelection(baseOffset: 0, extentOffset: length),
      ChangeSource.local,
    );
    await tester.pumpAndSettle();
    await rightClick(tester, at);
  }

  testWidgets('with a selection the menu offers Copy', (tester) async {
    await onDesktop(() async {
      await pumpEditor(tester);
      final at = inTheText(tester);
      await leftClick(tester, at);
      controllerOf(tester).updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 5),
        ChangeSource.local,
      );
      await tester.pumpAndSettle();

      await rightClick(tester, at);

      expect(find.text('Copy'), findsOneWidget);
    });
  });

  testWidgets('with a selection the menu offers the two editor commands',
      (tester) async {
    await onDesktop(() async {
      await pumpEditor(tester);

      await selectAndRightClick(tester, 5);

      expect(find.text('Remove formatting'), findsOneWidget);
      expect(find.text('Format as table'), findsOneWidget);
    });
  });

  testWidgets('with nothing selected it offers neither', (tester) async {
    await onDesktop(() async {
      await pumpEditor(tester);
      final at = inTheText(tester);
      await leftClick(tester, at);

      await rightClick(tester, at);

      expect(find.text('Select all'), findsOneWidget,
          reason: 'the menu itself is up');
      expect(find.text('Remove formatting'), findsNothing);
      expect(find.text('Format as table'), findsNothing);
    });
  });

  testWidgets('a read-only editor offers neither', (tester) async {
    await onDesktop(() async {
      await pumpEditor(tester, readOnly: true);

      await selectAndRightClick(tester, 5);

      expect(find.text('Copy'), findsOneWidget,
          reason: 'the menu is up and the selection is copyable');
      expect(find.text('Remove formatting'), findsNothing);
      expect(find.text('Format as table'), findsNothing);
    });
  });

  testWidgets('Format as table lines up the selected lines', (tester) async {
    await onDesktop(() async {
      await pumpEditor(
        tester,
        withContent: jsonEncode([
          {'insert': 'Name: Dmytro\nOccupation: developer\n'},
        ]),
      );

      await selectAndRightClick(tester, 34);
      await tester.tap(find.text('Format as table'));
      await tester.pumpAndSettle();

      expect(controllerOf(tester).document.toPlainText(),
          'Name:       Dmytro\nOccupation: developer\n\n',
          reason: 'the document keeps the empty line its delta ends with');
    });
  });
}
