import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';

/// Word wrap off (`QuillEditorConfig.wrapLines`, added by the fork the
/// pubspec pins): lines are laid out unwrapped at the widest line's width,
/// the editor scrolls sideways on its own, and the view follows the caret.
void main() {
  late QuillController controller;

  final long = List.filled(60, 'word').join(' ');
  final text = 'short\n$long\nend';

  Future<void> pumpEditor(WidgetTester tester,
      {required bool wrap, Document? document}) async {
    controller = QuillController(
      document: document ?? (Document()..insert(0, text)),
      selection: const TextSelection.collapsed(offset: 0),
    );
    addTearDown(controller.dispose);
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: FlutterQuillLocalizations.localizationsDelegates,
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 200,
          child: QuillEditor(
            controller: controller,
            focusNode: focusNode,
            scrollController: scroll,
            config: QuillEditorConfig(
              expands: true,
              scrollable: true,
              padding: EdgeInsets.zero,
              wrapLines: wrap,
            ),
          ),
        ),
      ),
    ));
    focusNode.requestFocus();
    await tester.pump();
    await tester.pump();
  }

  // Desktop, where the editor reveals the caret on every selection change.
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

  RenderEditor editor(WidgetTester tester) =>
      tester.allRenderObjects.whereType<RenderEditor>().single;

  /// The rendered box of the document's second line (the long one).
  RenderBox longLine(WidgetTester tester) {
    final e = editor(tester);
    return e.childAfter(e.firstChild!)!;
  }

  double lineX(WidgetTester tester) =>
      (longLine(tester).parentData! as BoxParentData).offset.dx;

  testDesktop('with word wrap on, the long line wraps at the editor edge',
      (tester) async {
    await pumpEditor(tester, wrap: true);
    final first = editor(tester).firstChild!;
    expect(longLine(tester).size.width, 300);
    expect(longLine(tester).size.height, greaterThan(first.size.height * 3));
  });

  testDesktop('with word wrap off, the long line stays on one line and runs '
      'past the edge', (tester) async {
    await pumpEditor(tester, wrap: false);
    final first = editor(tester).firstChild!;
    expect(editor(tester).size.width, 300);
    expect(longLine(tester).size.width, greaterThan(1000));
    expect(longLine(tester).size.height, first.size.height);
    // Every line is laid out at the same width, so the short ones too.
    expect(first.size.width, longLine(tester).size.width);
    expect(lineX(tester), 0);
  });

  testDesktop('Shift + wheel scrolls sideways; the caret is followed',
      (tester) async {
    await pumpEditor(tester, wrap: false);

    final center = tester.getCenter(find.byType(QuillEditor));
    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendEventToBinding(pointer.hover(center));
    await tester.sendEventToBinding(pointer.scroll(const Offset(0, 120)));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(lineX(tester), -120);

    // The caret at the end of the long line: the view follows it there...
    controller.updateSelection(
      TextSelection.collapsed(offset: 'short\n'.length + long.length),
      ChangeSource.local,
    );
    await tester.pump();
    await tester.pump();
    // (quill's caret rect is vertical only: the line's offset is the scroll)
    final caret = editor(tester)
        .getLocalRectForCaret(controller.selection.extent)
        .shift(Offset(lineX(tester), 0));
    expect(caret.right, lessThanOrEqualTo(300));
    expect(caret.left, greaterThan(200));

    // ...and back to the start of the document.
    controller.updateSelection(
        const TextSelection.collapsed(offset: 0), ChangeSource.local);
    await tester.pump();
    await tester.pump();
    expect(lineX(tester), 0);
  });

  testDesktop('a tap past the edge lands in the scrolled text', (tester) async {
    {
      await pumpEditor(tester, wrap: false);
      final scrollbarFree = tester.getTopLeft(find.byType(QuillEditor));
      final pointer = TestPointer(1, PointerDeviceKind.mouse);
      await tester.sendEventToBinding(pointer.hover(scrollbarFree + const Offset(10, 10)));
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendEventToBinding(pointer.scroll(const Offset(0, 400)));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();

      // Tap at the left edge of the long line: the offset under the tap is
      // well into the line, not its start.
      final lineTop = longLine(tester).localToGlobal(Offset.zero).dy;
      final position = editor(tester).getPositionForOffset(
          Offset(scrollbarFree.dx + 2, lineTop + 4));
      expect(position.offset, greaterThan('short\n'.length + 20));
    }
  });

  testDesktop('list items and code blocks stay on one line too',
      (tester) async {
    final doc = Document()
      ..insert(0, 'intro\n$long\n$long\n')
      ..format(6, 1, Attribute.ul)
      ..format(6 + long.length + 1, 1, Attribute.codeBlock);
    await pumpEditor(tester, wrap: false, document: doc);
    expect(tester.takeException(), isNull);

    final e = editor(tester);
    final intro = e.firstChild!;
    for (var block = e.childAfter(intro); block != null;
        block = e.childAfter(block)) {
      expect(block.size.width, greaterThan(1000));
      // One line plus the block's padding; wrapped, it would be a dozen.
      expect(block.size.height, lessThan(intro.size.height * 4));
    }
  });
}
