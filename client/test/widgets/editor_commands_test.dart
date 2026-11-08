import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/constants/fonts.dart';
import 'package:noo/presentation/widgets/task_editor/editor_commands.dart';

/// The two commands the editor's right-click menu adds: Remove formatting and
/// Format as table.
void main() {
  /// A controller over [text] with all of it selected.
  QuillController allSelected(String text) {
    final controller = QuillController(
      document: Document()..insert(0, text),
      selection: const TextSelection.collapsed(offset: 0),
    );
    controller.updateSelection(
      TextSelection(baseOffset: 0, extentOffset: controller.document.length - 1),
      ChangeSource.local,
    );
    return controller;
  }

  /// The document's text without the newline it always ends with.
  String textOf(QuillController controller) {
    final text = controller.document.toPlainText();
    return text.substring(0, text.length - 1);
  }

  /// The `font` attribute on the character at [offset], if any.
  String? fontAt(QuillController controller, int offset) => controller
      .document
      .collectStyle(offset, 0)
      .attributes[Attribute.font.key]
      ?.value as String?;

  group('alignColonColumns', () {
    test('pads every column to the widest cell above or below it', () {
      expect(
        alignColonColumns([
          'Name: Dmytro',
          'Occupation: developer',
          'City: Kyiv',
        ]),
        [
          'Name:       Dmytro',
          'Occupation: developer',
          'City:       Kyiv',
        ],
      );
    });

    test('a line carries as many columns as it has colons', () {
      expect(
        alignColonColumns([
          'Mon: standup: 9am',
          'Tuesday: review: 2pm',
        ]),
        [
          'Mon:     standup: 9am',
          'Tuesday: review:  2pm',
        ],
      );
    });

    test('lines with no colon are not rows and set no widths', () {
      expect(
        alignColonColumns([
          'Contact',
          '',
          'Name: Dmytro',
          'City: Kyiv',
        ]),
        [null, null, 'Name: Dmytro', 'City: Kyiv'],
        reason: 'null is "leave this line exactly as it is"',
      );
    });

    test('running it twice changes nothing the second time', () {
      const lines = ['Name: Dmytro', 'Occupation: developer'];
      final once = alignColonColumns(lines);
      expect(alignColonColumns(once), once);
    });

    test('a heading ending in a colon is not a row and sets no width', () {
      expect(
        alignColonColumns(['Addresses:', 'Home: Kyiv', 'Work: Lviv']),
        [null, 'Home: Kyiv', 'Work: Lviv'],
        reason: 'the rows below do not get a gap the width of the heading',
      );
    });

    test('spacing the user left behind is redone, not added to', () {
      expect(
        alignColonColumns(['Name:        Dmytro', 'City:   Kyiv']),
        ['Name: Dmytro', 'City: Kyiv'],
      );
    });

    test('a line that is not to be touched stays out of the table', () {
      expect(
        alignColonColumns(['Name: Dmytro', null, 'City: Kyiv']),
        ['Name: Dmytro', null, 'City: Kyiv'],
      );
    });
  });

  group('formatSelectionAsTable', () {
    test('aligns the selected lines and sets them in the bundled font', () {
      final controller = allSelected('Name: Dmytro\nOccupation: developer');

      formatSelectionAsTable(controller);

      expect(textOf(controller), 'Name:       Dmytro\nOccupation: developer');
      expect(fontAt(controller, 1), kMonospaceFont);
      expect(fontAt(controller, 20), kMonospaceFont);
    });

    test('sets the console font it is given', () {
      final controller = allSelected('Name: Dmytro\nOccupation: developer');

      formatSelectionAsTable(controller, font: 'Cascadia Mono');

      expect(fontAt(controller, 1), 'Cascadia Mono',
          reason: 'a note already in a console font keeps that one');
    });

    test('leaves the lines outside the selection alone', () {
      final controller = QuillController(
        document: Document()
          ..insert(0, 'Name: Dmytro\nCity: Kyiv\nNote: untouched here'),
        selection: const TextSelection.collapsed(offset: 0),
      );
      // The first two lines only: 'Name: Dmytro\n' is 13 characters.
      controller.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 20),
        ChangeSource.local,
      );

      formatSelectionAsTable(controller);

      expect(textOf(controller), 'Name: Dmytro\nCity: Kyiv\nNote: untouched here');
      expect(fontAt(controller, 30), isNull,
          reason: 'the third line keeps the font it had');
    });

    test('a line holding an image is left as it is', () {
      final controller = QuillController(
        document: Document.fromJson([
          {'insert': 'Name: Dmytro\n'},
          {
            'insert': {'image': 'blob:abc'}
          },
          {'insert': '\n'},
          {'insert': 'Occupation: developer\n'},
        ]),
        selection: const TextSelection.collapsed(offset: 0),
      );
      controller.updateSelection(
        TextSelection(
            baseOffset: 0, extentOffset: controller.document.length - 1),
        ChangeSource.local,
      );

      formatSelectionAsTable(controller);

      final delta = controller.document.toDelta().toJson();
      expect(delta.any((op) => op['insert'] is Map), isTrue,
          reason: 'the image is still there');
      expect(controller.document.toPlainText(),
          contains('Name:       Dmytro'));
      expect(controller.document.toPlainText(),
          contains('Occupation: developer'));
    });

    test('leaves the rewritten lines selected', () {
      final controller = allSelected('Name: Dmytro\nOccupation: developer');

      formatSelectionAsTable(controller);

      expect(controller.selection.baseOffset, 0);
      expect(controller.selection.extentOffset,
          controller.document.length - 1);
      expect(controller.selection.extentOffset,
          lessThan(controller.document.length));
    });

    test('one undo puts the whole table back', () {
      // Built from a delta, not by inserting: an insert of its own would sit
      // in the history and be what the undo below took back.
      final controller = QuillController(
        document: Document.fromJson([
          {'insert': 'Name: Dmytro\nOccupation: developer\n'},
        ]),
        selection: const TextSelection.collapsed(offset: 0),
      );
      controller.updateSelection(
        TextSelection(
            baseOffset: 0, extentOffset: controller.document.length - 1),
        ChangeSource.local,
      );

      formatSelectionAsTable(controller);
      controller.undo();

      expect(controller.document.toPlainText(),
          'Name: Dmytro\nOccupation: developer\n',
          reason: 'the line replacements and the font are one history entry');
      expect(fontAt(controller, 1), isNull);
    });

    test('does nothing to text with no colon in it', () {
      final controller = allSelected('just a note\nand another line');

      formatSelectionAsTable(controller);

      expect(textOf(controller), 'just a note\nand another line');
      expect(fontAt(controller, 1), isNull);
    });
  });

  group('clearFormatting', () {
    test('strips every attribute the selection carries', () {
      final controller = QuillController(
        document: Document.fromJson([
          {
            'insert': 'bold',
            'attributes': {'bold': true}
          },
          {
            'insert': ' and italic',
            'attributes': {'italic': true}
          },
          {'insert': '\n'},
        ]),
        selection: const TextSelection.collapsed(offset: 0),
      );
      controller.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 15),
        ChangeSource.local,
      );

      clearFormatting(controller);

      final delta = controller.document.toDelta().toJson();
      expect(delta.every((op) => op['attributes'] == null), isTrue);
      expect(controller.document.toPlainText(), 'bold and italic\n');
    });
  });
}
