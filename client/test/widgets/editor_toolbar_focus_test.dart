import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/widgets/task_editor/quill_editor_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Arming a style from the toolbar with the caret in the text.
///
/// Italic/Bold on a collapsed selection only *arms* the attribute: quill parks
/// it in `toggledStyle` and applies it to the next character typed. Any
/// selection update clears it, so a toolbar press that unfocuses the editor —
/// on desktop the press counts as a tap outside it — made the button useless:
/// the click needed to get back into the text disarmed it again, and the user
/// kept typing in the plain font.
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

  /// Runs [body] as if on desktop — the platforms where a tap outside the
  /// editor drops its focus, and so the ones the bug shows up on. The override
  /// has to be undone inside the test body: the framework asserts it is clear
  /// before tearDown gets a turn.
  Future<void> onDesktop(Future<void> Function() body) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await body();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  final content = jsonEncode([
    {'insert': 'hello\n'},
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

  /// Clicks into the text, the way a user puts the caret before formatting.
  Future<void> clickInTheText(WidgetTester tester) async {
    final box = tester.getRect(find.byType(QuillEditor));
    final gesture = await tester.startGesture(
      Offset(box.left + 20, box.top + 25),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.up();
    await tester.pumpAndSettle();
  }

  Future<void> clickItalic(WidgetTester tester) async {
    final button = find.byIcon(Icons.format_italic);
    expect(button, findsOneWidget);
    final gesture = await tester.startGesture(
      tester.getCenter(button),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('the editor keeps focus when a toolbar button is pressed',
      (tester) async => onDesktop(() async {
    await pumpEditor(tester);
    await clickInTheText(tester);

    final focusNode = tester.widget<QuillEditor>(find.byType(QuillEditor))
        .focusNode;
    expect(focusNode.hasFocus, isTrue, reason: 'the caret is in the text');

    await clickItalic(tester);

    expect(focusNode.hasFocus, isTrue,
        reason: 'losing focus forces a click back, which disarms the button');
  }));

  testWidgets('text typed after pressing Italic comes out italic',
      (tester) async => onDesktop(() async {
    await pumpEditor(tester);
    await clickInTheText(tester);
    await clickItalic(tester);

    final editor = tester.widget<QuillEditor>(find.byType(QuillEditor));
    expect(editor.focusNode.hasFocus, isTrue,
        reason: 'the user must be able to type straight on, without a click '
            'back into the text that would clear the armed style');

    final controller = controllerOf(tester);
    expect(controller.toggledStyle.attributes, contains(Attribute.italic.key),
        reason: 'the toolbar armed italic for the next character');

    // Same path the editor takes for a typed character.
    final at = controller.selection.baseOffset;
    controller.replaceText(
      at,
      0,
      'x',
      TextSelection.collapsed(offset: at + 1),
    );
    await tester.pumpAndSettle();

    final typed = controller.document
        .toDelta()
        .toList()
        .firstWhere((op) => (op.data as String?)?.contains('x') ?? false);
    expect(typed.attributes, contains(Attribute.italic.key),
        reason: 'the character was inserted in the plain font');
  }));
}
