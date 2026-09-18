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

  Future<void> pumpEditor(WidgetTester tester) async {
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
                initialContent: content,
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
}
