import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/presentation/widgets/task_editor/pending_style_controller.dart';

/// Toggling a style off (or on) with the caret at the end of a line, then
/// pressing Enter.
///
/// A toolbar press on a collapsed caret only arms an attribute in
/// `toggledStyle`; quill's `keepStyleOnNewLine` re-derives that field from the
/// character before the caret on every newline and *assigns* it, throwing the
/// user's pending toggle away. Switching strikethrough off at the end of struck
/// text and pressing Enter therefore came back struck, with the toolbar button
/// lit again. See [PendingStyleQuillController].
void main() {
  /// A document holding [text] with every character struck through.
  PendingStyleQuillController struckThrough(String text) =>
      PendingStyleQuillController(
        document: Document.fromJson([
          {
            'insert': text,
            'attributes': {Attribute.strikeThrough.key: true},
          },
          {'insert': '\n'},
        ]),
        selection: TextSelection.collapsed(offset: text.length),
      );

  /// Presses Enter at the caret, the way the editor does for the key.
  void pressEnter(QuillController controller) {
    final at = controller.selection.baseOffset;
    controller.replaceText(
      at,
      0,
      '\n',
      TextSelection.collapsed(offset: at + 1),
    );
  }

  /// Types [text] at the caret, the way the editor does for a keystroke.
  void type(QuillController controller, String text) {
    final at = controller.selection.baseOffset;
    controller.replaceText(
      at,
      0,
      text,
      TextSelection.collapsed(offset: at + text.length),
    );
  }

  test('a style switched off before Enter stays off on the new line', () {
    final controller = struckThrough('hello');

    // The toolbar button: with nothing selected this only disarms the style.
    controller.formatSelection(Attribute.clone(Attribute.strikeThrough, null));
    expect(controller.getSelectionStyle().attributes,
        isNot(contains(Attribute.strikeThrough.key)),
        reason: 'the button goes dark the moment it is pressed');

    pressEnter(controller);

    expect(controller.getSelectionStyle().attributes,
        isNot(contains(Attribute.strikeThrough.key)),
        reason: 'the new line inherited the struck style the user just left');

    type(controller, 'x');

    final typed = controller.document.toDelta().last;
    expect(typed.data, contains('x'));
    expect(typed.attributes ?? const {},
        isNot(contains(Attribute.strikeThrough.key)),
        reason: 'text on the new line came out struck through');
  });

  test('a style left alone still carries over to the new line', () {
    final controller = struckThrough('hello');

    pressEnter(controller);

    expect(controller.getSelectionStyle().attributes,
        contains(Attribute.strikeThrough.key),
        reason: 'quill continues the previous line and must keep doing so');
  });

  test('a style switched on before Enter survives to the new line', () {
    final controller = PendingStyleQuillController(
      document: Document.fromJson([
        {'insert': 'hello\n'},
      ]),
      selection: const TextSelection.collapsed(offset: 5),
    );

    controller.formatSelection(Attribute.bold);
    pressEnter(controller);

    expect(controller.getSelectionStyle().attributes,
        contains(Attribute.bold.key),
        reason: 'the plain text before the caret disarmed the button again');
  });
}
