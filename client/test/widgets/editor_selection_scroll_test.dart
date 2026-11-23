import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

/// Extending a selection with the keyboard must scroll the editor after the
/// moving end of the selection.
///
/// flutter_quill 11.5.1's `getOffsetToRevealCursor` examined the *first*
/// endpoint of any extended selection, i.e. its start in document order, so
/// Shift+Down kept checking the anchor — which never leaves the viewport — and
/// let the extent walk off the bottom unseen. The pubspec pins a fork with the
/// fix (`dependency_overrides`); this test is what notices an upgrade that
/// drops the override before upstream has shipped it.
void main() {
  late QuillController controller;
  late ScrollController scrollController;

  // Forty lines in a viewport that shows about eight of them.
  final tall = List.generate(40, (i) => 'line ${i + 1}').join('\n');

  Future<void> pumpEditor(WidgetTester tester, {required int caret}) async {
    controller = QuillController(
      document: Document()..insert(0, tall),
      selection: TextSelection.collapsed(offset: caret),
    );
    addTearDown(controller.dispose);
    scrollController = ScrollController();
    addTearDown(scrollController.dispose);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 160,
          child: QuillEditor(
            controller: controller,
            focusNode: focusNode,
            scrollController: scrollController,
            config: const QuillEditorConfig(
              expands: true,
              scrollable: true,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ),
    ));
    focusNode.requestFocus();
    await tester.pump();
  }

  /// One Shift+arrow press, followed by enough frames for quill's 100 ms
  /// caret-reveal animation to finish: it is started from a post-frame
  /// callback, and a ticker's first tick reports no elapsed time, so the
  /// scroll offset only moves on the second pumped frame after the press.
  Future<void> pressShift(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(key);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 250));
  }

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

  testDesktop('Shift+Down past the bottom edge scrolls after the extent',
      (tester) async {
    await pumpEditor(tester, caret: 0);
    expect(scrollController.offset, 0);

    for (var i = 0; i < 20; i++) {
      await pressShift(tester, LogicalKeyboardKey.arrowDown);
    }

    final selection = controller.selection;
    expect(selection.baseOffset, 0, reason: 'the anchor stays at the top');
    expect(selection.extentOffset, greaterThan(0));
    expect(scrollController.offset, greaterThan(0),
        reason: 'the editor scrolled to keep the moving end in view');
  });

  testDesktop('Shift+Up past the top edge scrolls after the extent',
      (tester) async {
    await pumpEditor(tester, caret: tall.length);
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
    await tester.pump();
    final startOffset = scrollController.offset;
    expect(startOffset, greaterThan(0));

    for (var i = 0; i < 20; i++) {
      await pressShift(tester, LogicalKeyboardKey.arrowUp);
    }

    expect(controller.selection.baseOffset, tall.length);
    expect(scrollController.offset, lessThan(startOffset));
  });

  testDesktop('Shift+End from the top reveals the end of the document',
      (tester) async {
    await pumpEditor(tester, caret: 0);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await pressShift(tester, LogicalKeyboardKey.end);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(controller.selection.extentOffset, tall.length);
    expect(scrollController.offset, scrollController.position.maxScrollExtent);
  });
}
