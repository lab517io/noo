import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/widgets/task_editor/quill_editor_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Copying out of the editor with Ctrl+C.
///
/// Copy is routed by *focus*, but flutter_quill paints a selection whether or
/// not the editor has it — and it only asks for focus on tap-up, never on a
/// selection drag. Selecting a URL by dragging while the tree still held focus
/// therefore produced a highlighted selection that Ctrl+C silently ignored,
/// leaving nothing on the system clipboard to paste into another app.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Everything written to the system clipboard, in order.
  late List<String> clipboardWrites;

  setUp(() {
    clipboardWrites = [];
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboardWrites.add((call.arguments as Map)['text'] as String);
      }
      if (call.method == 'Clipboard.getData') {
        return <String, dynamic>{
          'text': clipboardWrites.isEmpty ? '' : clipboardWrites.last,
        };
      }
      return null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  late NooDatabase db;
  late int taskId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = NooDatabase.memory();
    taskId = await db.createTask(worldId: 'task-world-id', title: 'Task');
  });

  tearDown(() async => db.close());

  const url = 'https://example.com/page';

  /// A single line holding [url] as a link, the shape a pasted URL takes.
  final linkContent = jsonEncode([
    {
      'insert': url,
      'attributes': {'link': url},
    },
    {'insert': '\n'},
  ]);

  /// Mounts the editor below a focused stand-in for the task tree — the state
  /// the app is in right after a task is clicked there.
  Future<FocusNode> pumpEditor(WidgetTester tester) async {
    final treeFocus = FocusNode(debugLabel: 'tree');
    addTearDown(treeFocus.dispose);

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
            body: Column(
              children: [
                Focus(
                  focusNode: treeFocus,
                  autofocus: true,
                  child: const SizedBox(width: 600, height: 20),
                ),
                SizedBox(
                  width: 600,
                  height: 400,
                  child: QuillEditorWrapper(
                    contentKey: taskId,
                    taskId: taskId,
                    initialContent: linkContent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(treeFocus.hasFocus, isTrue,
        reason: 'the tree holds focus after a task is clicked there');
    return treeFocus;
  }

  /// Drags the mouse across the editor's first line, selecting the link.
  Future<void> dragAcrossTheLink(WidgetTester tester) async {
    final box = tester.getRect(find.byType(QuillEditor));
    final gesture = await tester.startGesture(
      Offset(box.left + 1, box.top + 25),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(Offset(box.right - 4, box.top + 25));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();
  }

  Future<void> pressCtrlC(WidgetTester tester) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();
  }

  testWidgets('a mouse drag selection puts the editor in focus',
      (tester) async {
    final treeFocus = await pumpEditor(tester);

    await dragAcrossTheLink(tester);

    expect(treeFocus.hasFocus, isFalse);
    final controller = tester.widget<QuillEditor>(find.byType(QuillEditor));
    expect(controller.focusNode.hasFocus, isTrue,
        reason: 'without focus the selection is dead to Ctrl+C');
  });

  testWidgets('Ctrl+C after a drag selection copies the link to the clipboard',
      (tester) async {
    await pumpEditor(tester);
    await dragAcrossTheLink(tester);

    clipboardWrites.clear();
    await pressCtrlC(tester);

    expect(clipboardWrites, isNotEmpty,
        reason: 'nothing reached the system clipboard');
    expect(clipboardWrites.last.trim(), url);
  });

  testWidgets('a touch drag scrolls without stealing focus', (tester) async {
    final treeFocus = await pumpEditor(tester);

    final box = tester.getRect(find.byType(QuillEditor));
    final gesture = await tester.startGesture(
      Offset(box.left + 100, box.top + 25),
      kind: PointerDeviceKind.touch,
    );
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(Offset(box.left + 100, box.top + 120));
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(treeFocus.hasFocus, isTrue,
        reason: 'focusing on a touch scroll would pop the soft keyboard open');
  });
}
