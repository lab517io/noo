import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/constants/fonts.dart';
import 'package:noo/core/constants/table_separator.dart';
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
      TextSelection(
        baseOffset: 0,
        extentOffset: controller.document.length - 1,
      ),
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
  String? fontAt(QuillController controller, int offset) =>
      controller.document
              .collectStyle(offset, 0)
              .attributes[Attribute.font.key]
              ?.value
          as String?;

  group('alignTableColumns', () {
    test('a Chinese or Japanese character counts two columns', () {
      expect(alignTableColumns(['名前: 太郎', 'City: Kyiv']), [
        '名前: 太郎',
        'City: Kyiv',
      ]);
      expect(alignTableColumns(['東京: 1', 'Ankara: 2']), [
        '東京:   1',
        'Ankara: 2',
      ]);
    });

    test('pads every column to the widest cell above or below it', () {
      expect(
        alignTableColumns([
          'Name: Dmytro',
          'Occupation: developer',
          'City: Kyiv',
        ]),
        ['Name:       Dmytro', 'Occupation: developer', 'City:       Kyiv'],
      );
    });

    test('a line carries as many columns as it has colons', () {
      expect(alignTableColumns(['Mon: standup: 9am', 'Tuesday: review: 2pm']), [
        'Mon:     standup: 9am',
        'Tuesday: review:  2pm',
      ]);
    });

    test('lines with no colon are not rows and set no widths', () {
      expect(alignTableColumns(['Contact', '', 'Name: Dmytro', 'City: Kyiv']), [
        null,
        null,
        'Name: Dmytro',
        'City: Kyiv',
      ], reason: 'null is "leave this line exactly as it is"');
    });

    test('running it twice changes nothing the second time', () {
      const lines = ['Name: Dmytro', 'Occupation: developer'];
      final once = alignTableColumns(lines);
      expect(alignTableColumns(once), once);
    });

    test('a heading ending in a colon is not a row and sets no width', () {
      expect(alignTableColumns(['Addresses:', 'Home: Kyiv', 'Work: Lviv']), [
        null,
        'Home: Kyiv',
        'Work: Lviv',
      ], reason: 'the rows below do not get a gap the width of the heading');
    });

    test('a URL keeps its colons and takes part as one cell', () {
      expect(
        alignTableColumns([
          'Site: https://example.com:8080',
          'Repository: git@host: mirror',
        ]),
        [
          'Site:       https://example.com:8080',
          'Repository: git@host: mirror',
        ],
      );
    });

    test('spacing the user left behind is redone, not added to', () {
      expect(alignTableColumns(['Name:        Dmytro', 'City:   Kyiv']), [
        'Name: Dmytro',
        'City: Kyiv',
      ]);
    });

    test('a line that is not to be touched stays out of the table', () {
      expect(alignTableColumns(['Name: Dmytro', null, 'City: Kyiv']), [
        'Name: Dmytro',
        null,
        'City: Kyiv',
      ]);
    });
  });

  group('splitTableCells', () {
    test('a colon inside a URL is not a column break', () {
      expect(splitTableCells('Site: https://example.com:8080/a?b=c', ':'), [
        'Site',
        'https://example.com:8080/a?b=c',
      ]);
    });

    test('nor one right after the separator, with no space', () {
      expect(splitTableCells('Site:https://example.com', ':'), [
        'Site',
        'https://example.com',
      ]);
    });

    test('mailto and tel have no // and are URLs all the same', () {
      expect(splitTableCells('Mail: mailto:me@example.com', ':'), [
        'Mail',
        'mailto:me@example.com',
      ]);
      expect(splitTableCells('Phone: tel:+380441234567', ':'), [
        'Phone',
        'tel:+380441234567',
      ]);
    });

    test('a separator closing a URL is punctuation, not part of it', () {
      expect(splitTableCells('https://example.com/a,b, next', ','), [
        'https://example.com/a,b',
        'next',
      ]);
    });

    test('a separator inside quotes is not a column break', () {
      expect(splitTableCells('Note: "time: 9:30": done', ':'), [
        'Note',
        '"time: 9:30"',
        'done',
      ]);
      expect(splitTableCells("Item, 'a, b', c", ','), ['Item', "'a, b'", 'c']);
    });

    test('an unclosed quote or an apostrophe opens nothing', () {
      expect(splitTableCells('Say: "hello: world', ':'), [
        'Say',
        '"hello',
        'world',
      ]);
      expect(splitTableCells("Don't: it's: fine", ':'), [
        "Don't",
        "it's",
        'fine',
      ]);
    });

    test('a line with no separator that counts is not a row', () {
      expect(splitTableCells('see https://example.com:80', ':'), isNull);
      expect(splitTableCells('just text', ':'), isNull);
    });
  });

  group('other separators', () {
    test('equals and the bar line up in a column of their own', () {
      expect(
        alignTableColumns([
          'a=1',
          'long = 2',
        ], separator: TableSeparator.equals),
        ['a    = 1', 'long = 2'],
      );
      expect(
        alignTableColumns([
          'x | y | z',
          'wide|b|c',
        ], separator: TableSeparator.pipe),
        ['x    | y | z', 'wide | b | c'],
      );
    });

    test('a comma hugs its cell like the colon', () {
      expect(
        alignTableColumns([
          'Kyiv,UA',
          'Lisbon, PT',
        ], separator: TableSeparator.comma),
        ['Kyiv,   UA', 'Lisbon, PT'],
      );
    });

    test('a tab is replaced by the padding', () {
      expect(
        alignTableColumns([
          'a\tb\tc',
          'long\tx\ty',
        ], separator: TableSeparator.tab),
        ['a     b  c', 'long  x  y'],
      );
    });

    test('a re-run re-fits rather than adds, whatever the separator', () {
      for (final separator in [
        TableSeparator.equals,
        TableSeparator.pipe,
        TableSeparator.semicolon,
      ]) {
        final c = separator.char;
        final once = alignTableColumns([
          'a${c}1${c}x',
          'long${c}22${c}y',
        ], separator: separator);
        expect(
          alignTableColumns(once, separator: separator),
          once,
          reason: separator.name,
        );
      }
    });

    test('the colon is not special when another separator is chosen', () {
      expect(
        alignTableColumns([
          'Time: 9:30 = start',
          'End = 18:00',
        ], separator: TableSeparator.equals),
        ['Time: 9:30 = start', 'End        = 18:00'],
      );
    });

    test('formatSelectionAsTable splits on the separator it is given', () {
      final controller = allSelected('a;1\nlong;2');

      formatSelectionAsTable(controller, separator: TableSeparator.semicolon);

      expect(textOf(controller), 'a;    1\nlong; 2');
    });
  });

  group('Markdown tables', () {
    List<String?> pipe(List<String?> lines) =>
        alignTableColumns(lines, separator: TableSeparator.pipe);

    test('borders are kept and the closing bars line up', () {
      expect(pipe(['| Name | City |', '|---|---|', '| Dmytro | Kyiv |']), [
        '| Name   | City |',
        '| ------ | ---- |',
        '| Dmytro | Kyiv |',
      ]);
    });

    test('the delimiter row keeps its alignment colons', () {
      expect(pipe(['| Left | Centre | Right |', '|:--|:-:|--:|']), [
        '| Left | Centre | Right |',
        '| :--- | :----: | ----: |',
      ]);
    });

    test('a re-run re-fits, narrowing a column whose text got shorter', () {
      final once = pipe(['| Name | City |', '|-|-|', '| Dmytro | Kyiv |']);
      expect(pipe(once), once);

      expect(
        pipe(['| Name   | City |', '| ------ | ---- |', '| Al | Kyiv |']),
        ['| Name | City |', '| ---- | ---- |', '| Al   | Kyiv |'],
      );
    });

    test('an escaped bar is part of its cell', () {
      expect(pipe([r'| a \| b | c |', '| long cell | d |']), [
        r'| a \| b    | c |',
        '| long cell | d |',
      ]);
    });

    test('an empty cell keeps its place', () {
      expect(pipe(['| a | | c |', '| long | b | c |']), [
        '| a    |   | c |',
        '| long | b | c |',
      ]);
    });

    test('borders mean nothing to the other separators', () {
      expect(alignTableColumns([':a:b:'], separator: TableSeparator.colon), [
        null,
      ], reason: 'still a line ending in its separator, so a heading');
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

      expect(
        fontAt(controller, 1),
        'Cascadia Mono',
        reason: 'a note already in a console font keeps that one',
      );
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

      expect(
        textOf(controller),
        'Name: Dmytro\nCity: Kyiv\nNote: untouched here',
      );
      expect(
        fontAt(controller, 30),
        isNull,
        reason: 'the third line keeps the font it had',
      );
    });

    test('a line holding an image is left as it is', () {
      final controller = QuillController(
        document: Document.fromJson([
          {'insert': 'Name: Dmytro\n'},
          {
            'insert': {'image': 'blob:abc'},
          },
          {'insert': '\n'},
          {'insert': 'Occupation: developer\n'},
        ]),
        selection: const TextSelection.collapsed(offset: 0),
      );
      controller.updateSelection(
        TextSelection(
          baseOffset: 0,
          extentOffset: controller.document.length - 1,
        ),
        ChangeSource.local,
      );

      formatSelectionAsTable(controller);

      final delta = controller.document.toDelta().toJson();
      expect(
        delta.any((op) => op['insert'] is Map),
        isTrue,
        reason: 'the image is still there',
      );
      expect(controller.document.toPlainText(), contains('Name:       Dmytro'));
      expect(
        controller.document.toPlainText(),
        contains('Occupation: developer'),
      );
    });

    test('leaves the rewritten lines selected', () {
      final controller = allSelected('Name: Dmytro\nOccupation: developer');

      formatSelectionAsTable(controller);

      expect(controller.selection.baseOffset, 0);
      expect(controller.selection.extentOffset, controller.document.length - 1);
      expect(
        controller.selection.extentOffset,
        lessThan(controller.document.length),
      );
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
          baseOffset: 0,
          extentOffset: controller.document.length - 1,
        ),
        ChangeSource.local,
      );

      formatSelectionAsTable(controller);
      controller.undo();

      expect(
        controller.document.toPlainText(),
        'Name: Dmytro\nOccupation: developer\n',
        reason: 'the line replacements and the font are one history entry',
      );
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
            'attributes': {'bold': true},
          },
          {
            'insert': ' and italic',
            'attributes': {'italic': true},
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
