import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/presentation/widgets/task_editor/word_navigation_actions.dart';

/// Ctrl+Right (and its siblings) in the last word of the document.
///
/// quill's forward word boundary walks past the last character and asks
/// `RenderEditor.getWordBoundary` about an offset no line owns; that falls back
/// to the *first* line, so the caret jumped backwards — to the end of the first
/// paragraph — instead of stopping at the end of the text. See
/// [WordNavigationActions].
void main() {
  late QuillController controller;

  Future<void> pumpEditor(WidgetTester tester, String text,
      {required int caret, bool readOnly = false}) async {
    controller = QuillController(
      document: Document()..insert(0, text),
      selection: TextSelection.collapsed(offset: caret),
      readOnly: readOnly,
    );
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 600,
          height: 400,
          child: WordNavigationActions(
            controller: controller,
            child: QuillEditor(
              controller: controller,
              focusNode: focusNode,
              scrollController: ScrollController(),
              config: const QuillEditorConfig(
                expands: true,
                padding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
    ));
    focusNode.requestFocus();
    await tester.pump();
  }

  Future<void> pressCtrl(WidgetTester tester, LogicalKeyboardKey key,
      {bool shift = false}) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
  }

  /// The word-jump shortcuts are bound per platform, and a widget test runs as
  /// Android unless told otherwise. The override has to be undone inside the
  /// test body: flutter_test checks for stray debug variables before tearDown.
  void testDesktop(
      String description, Future<void> Function(WidgetTester) body) {
    testWidgets(description, (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      try {
        await body(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  // 'hello world\nsecond line here': word ends at 5, 11, 18, 23, 28, and 28 is
  // the last offset the caret can take (the document's trailing newline is 28).
  const twoLines = 'hello world\nsecond line here';

  testDesktop('Ctrl+Right walks forward and stops at the end of the text',
      (tester) async {
    await pumpEditor(tester, twoLines, caret: 0);

    final stops = <int>[];
    for (var i = 0; i < 7; i++) {
      await pressCtrl(tester, LogicalKeyboardKey.arrowRight);
      stops.add(controller.selection.baseOffset);
    }

    expect(stops, [5, 11, 18, 23, 28, 28, 28],
        reason: 'the caret never moves backwards, and the end of the last '
            'word is where it stays');
  });

  testDesktop('Ctrl+Right stops at the end with blank lines after the text',
      (tester) async {
    await pumpEditor(tester, '$twoLines\n\n', caret: 24);

    await pressCtrl(tester, LogicalKeyboardKey.arrowRight);
    expect(controller.selection.baseOffset, 28);
    await pressCtrl(tester, LogicalKeyboardKey.arrowRight);
    expect(controller.selection.baseOffset, controller.document.length - 1,
        reason: 'past the last word, the end of the document is the last stop');
  });

  testDesktop('Ctrl+Shift+Right extends to the end, never backwards',
      (tester) async {
    await pumpEditor(tester, twoLines, caret: 24);

    await pressCtrl(tester, LogicalKeyboardKey.arrowRight, shift: true);
    expect(controller.selection, const TextSelection(baseOffset: 24, extentOffset: 28));

    await pressCtrl(tester, LogicalKeyboardKey.arrowRight, shift: true);
    expect(controller.selection.baseOffset, 24);
    expect(controller.selection.extentOffset, 28,
        reason: 'the selection holds instead of flipping to the first line');
  });

  testDesktop('Ctrl+Delete in the last word deletes nothing and does not throw',
      (tester) async {
    await pumpEditor(tester, twoLines, caret: 28);

    await pressCtrl(tester, LogicalKeyboardKey.delete);

    expect(tester.takeException(), isNull);
    expect(controller.document.toPlainText(), '$twoLines\n');
    expect(controller.selection.baseOffset, 28);
  });

  testDesktop('Ctrl+Delete at the end of the text takes the blank lines after it',
      (tester) async {
    await pumpEditor(tester, '$twoLines\n\n', caret: 28);

    await pressCtrl(tester, LogicalKeyboardKey.delete);

    expect(tester.takeException(), isNull);
    expect(controller.document.toPlainText(), '$twoLines\n');
  });

  testDesktop('Ctrl+Delete is still inert in a read-only editor',
      (tester) async {
    await pumpEditor(tester, '$twoLines\n\n', caret: 28, readOnly: true);

    await pressCtrl(tester, LogicalKeyboardKey.delete);

    expect(tester.takeException(), isNull);
    expect(controller.document.toPlainText(), '$twoLines\n\n\n');
  });

  testDesktop('word navigation away from the end is left to quill',
      (tester) async {
    await pumpEditor(tester, twoLines, caret: 0);

    // Forward into the middle, then back out again: both directions still take
    // quill's own boundaries.
    await pressCtrl(tester, LogicalKeyboardKey.arrowRight);
    await pressCtrl(tester, LogicalKeyboardKey.arrowRight);
    expect(controller.selection.baseOffset, 11);

    await pressCtrl(tester, LogicalKeyboardKey.arrowLeft);
    expect(controller.selection.baseOffset, 6);

    // With a selection, quill moves the extent on and collapses there rather
    // than collapsing where the selection ended.
    controller.updateSelection(
      const TextSelection(baseOffset: 0, extentOffset: 5),
      ChangeSource.local,
    );
    await pressCtrl(tester, LogicalKeyboardKey.arrowRight);
    expect(controller.selection, const TextSelection.collapsed(offset: 11));
  });
}
