import 'package:flutter/widgets.dart' show TextSelection;
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/constants/fonts.dart';
import '../../../core/constants/table_separator.dart';
import '../../../core/utils/text_width.dart';

/// The two editor commands the context menu adds to quill's own Cut/Copy/Paste.
///
/// Both work on whole lines of the selection and are no-ops on a document that
/// has nothing selected.

/// Strips every attribute from the selection — the toolbar's clear-format
/// button, reachable without opening the toolbar.
///
/// Collecting the styles first and clearing them one by one is quill's own
/// implementation (`QuillToolbarClearFormatButton`): `getAllSelectionStyles`
/// reports every attribute present anywhere in the selection, so a selection
/// spanning bold *and* italic text loses both.
void clearFormatting(QuillController controller) {
  final attributes = <Attribute>{
    for (final style in controller.getAllSelectionStyles())
      ...style.attributes.values,
  };
  for (final attribute in attributes) {
    controller.formatSelection(Attribute.clone(attribute, null));
  }
}

/// Lines up the columns of the selected lines and sets them in a fixed-width
/// font, so that
///
///     Name: Dmytro
///     Occupation: developer
///
/// becomes
///
///     Name:       Dmytro
///     Occupation: developer
///
/// Columns are split on [separator] (Preferences → Editor → Table columns,
/// a colon unless the user picked another). Every separator on a line starts
/// a new column, so a line may hold more than the two above; the columns of
/// all the selected lines share their widths. A separator inside a URL or a
/// quoted string is not a column break (see [splitTableCells]). Lines that are
/// not rows — a blank line between two groups, a heading with no separator or
/// one that ends in it, like "Addresses:" — are left exactly as they are and
/// take no part in the widths.
///
/// The padding is spaces, which only line up in a fixed-width font, so the
/// lines it rewrites are set in [font] — one of the bundled families, because
/// a generic name is not dependably fixed-width (see `tool/font_probe.dart`).
/// That is also why the rewritten lines lose their inline formatting: the
/// text is replaced wholesale. Lines
/// holding an image (or any other embed) are left alone for the same reason —
/// replacing their text would take the image with it.
void formatSelectionAsTable(
  QuillController controller, {
  String? font,
  TableSeparator separator = TableSeparator.colon,
}) {
  final selection = controller.selection;
  if (!selection.isValid) return;

  final lines = _selectedLines(controller.document, selection);
  if (lines.isEmpty) return;

  final texts = <String?>[
    for (final line in lines)
      line.children.any((node) => node is Embed)
          ? null
          : controller.document.getPlainText(
              line.documentOffset,
              line.length - 1,
            ),
  ];
  final aligned = alignTableColumns(texts, separator: separator);

  final monospace = Attribute.fromKeyValue(
    Attribute.font.key,
    font ?? kMonospaceFont,
  );
  // Back to front: replacing a line moves everything after it, so working
  // upwards keeps the offsets of the lines still to come correct.
  for (var i = lines.length - 1; i >= 0; i--) {
    final text = aligned[i];
    if (text == null) continue;

    final at = lines[i].documentOffset;
    if (text != texts[i]) {
      controller.replaceText(at, texts[i]!.length, text, null);
    }
    // Every row of the table is set in the fixed-width font, including the
    // widest one, whose own spacing the alignment had nothing to change.
    if (text.isNotEmpty) {
      controller.formatText(at, text.length, monospace);
    }
  }

  // Leave the table selected. Padding can also shorten a line — a column the
  // user had over-spaced — so the old selection is not necessarily a range the
  // document still has.
  final start = lines.first.documentOffset;
  var length = 0;
  for (var i = 0; i < lines.length; i++) {
    // A line left alone keeps the length it had, newline included.
    final text = aligned[i] ?? texts[i];
    length += text == null ? lines[i].length : text.length + 1;
  }
  controller.updateSelection(
    TextSelection(baseOffset: start, extentOffset: start + length - 1),
    ChangeSource.local,
  );
}

/// The aligned form of [lines], entry for entry, with null for every line that
/// is not a row of the table — one that came in as null, one with no
/// separator on it, or a heading — and so is to be left exactly as it is.
///
/// With the vertical bar, a line that starts *and* ends with one is a
/// Markdown table row: `| Name | City |`. Its borders are kept, its last cell
/// is padded like the others so the closing bars line up, and a delimiter row
/// (`|---|:---:|`) is redrawn in dashes to the column widths, keeping its
/// alignment colons. A bar-separated row without borders in the same
/// selection shares the widths but not the leading `| `.
///
/// Public for the tests: this is the whole of the layout decision, and it is
/// worth checking without an editor around it.
List<String?> alignTableColumns(
  List<String?> lines, {
  TableSeparator separator = TableSeparator.colon,
}) {
  // A row is its line split on the separators, each cell trimmed of the
  // spacing a previous run of this command (or the user) left around it. A
  // line with nothing after its last separator — "Addresses:", a heading over
  // the rows that follow — is not a row: padding the rows out to its width
  // would leave a gap the width of the heading. A bordered Markdown row ends
  // in its separator too, but on purpose, and starts with one as well.
  final rows = <_TableRow?>[
    for (final line in lines) _tableRow(line, separator),
  ];

  // The width of a column is its widest cell (plus the separator, where that
  // hugs the cell). Only columns that something follows need one: the last
  // cell of a row ends the line and is never padded — except in a bordered
  // row, where the closing border follows it. A delimiter cell counts as the
  // three dashes Markdown asks for at least, not its current length, so that
  // a column whose text got shorter narrows on the next run.
  final attached = separator.style == TableSeparatorStyle.attached;
  final widths = <int>[];
  for (final row in rows) {
    if (row == null) continue;
    final padded = row.bordered ? row.cells.length : row.cells.length - 1;
    for (var i = 0; i < padded; i++) {
      final width = row.delimiter
          ? 3
          : displayWidth(row.cells[i]) + (attached ? 1 : 0);
      if (i == widths.length) {
        widths.add(width);
      } else if (width > widths[i]) {
        widths[i] = width;
      }
    }
  }

  String cell(String text, int width) => switch (separator.style) {
    TableSeparatorStyle.attached => padToWidth(
      '$text${separator.char}',
      width + 1,
    ),
    TableSeparatorStyle.spaced => '${padToWidth(text, width)} ${separator.char} ',
    TableSeparatorStyle.replaced => padToWidth(text, width + 2),
  };

  String bordered(_TableRow row) {
    final cells = [
      for (var c = 0; c < row.cells.length; c++)
        row.delimiter
            ? _delimiterCell(row.cells[c], widths[c])
            : padToWidth(row.cells[c], widths[c]),
    ];
    return '| ${cells.join(' | ')} |';
  }

  return <String?>[
    for (var i = 0; i < lines.length; i++)
      if (rows[i] case final row?)
        row.bordered
            ? bordered(row)
            : [
                for (var c = 0; c < row.cells.length - 1; c++)
                  cell(row.cells[c], widths[c]),
                row.cells.last,
              ].join().trimRight()
      else
        null,
  ];
}

/// One row of a table: its cells, trimmed, and — for a Markdown row — whether
/// it had borders and whether it is the delimiter row under the header.
class _TableRow {
  const _TableRow(this.cells, {this.bordered = false, this.delimiter = false});

  /// For a bordered row, the cells between the borders.
  final List<String> cells;
  final bool bordered;
  final bool delimiter;
}

/// A Markdown delimiter cell: dashes, with a colon at either end for the
/// column's alignment.
final _delimiterPattern = RegExp(r'^:?-+:?$');

_TableRow? _tableRow(String? line, TableSeparator separator) {
  if (line == null) return null;
  final cells = splitTableCells(line, separator.char);
  if (cells == null) return null;

  if (separator == TableSeparator.pipe &&
      cells.length >= 3 &&
      cells.first.isEmpty &&
      cells.last.isEmpty) {
    final inner = cells.sublist(1, cells.length - 1);
    return _TableRow(
      inner,
      bordered: true,
      delimiter: inner.every(_delimiterPattern.hasMatch),
    );
  }
  if (cells.last.isEmpty) return null;
  return _TableRow(cells);
}

/// [cell] (`---`, `:--`, `--:`, `:-:`) redrawn [width] wide.
String _delimiterCell(String cell, int width) {
  final left = cell.startsWith(':');
  final right = cell.length > 1 && cell.endsWith(':');
  final dashes = width - (left ? 1 : 0) - (right ? 1 : 0);
  return '${left ? ':' : ''}${'-' * dashes}${right ? ':' : ''}';
}

/// A URL: a scheme followed by `://` (`https://host:8080/a?b=c`), or one of
/// the schemes written without it, running to the next whitespace. The
/// lookbehind keeps "Site:https://…" from being read as a scheme "Site".
final _urlPattern = RegExp(
  r'(?<![A-Za-z0-9+.\-])(?:[A-Za-z][A-Za-z0-9+.\-]*://|(?:mailto|tel|urn):)\S+',
);

final _wordChar = RegExp(r'[\p{L}\p{N}]', unicode: true);

bool _isWordChar(String char) => _wordChar.hasMatch(char);

/// [line] split on [separator], each cell trimmed — or null when no
/// separator on it counts, and so the line is not a row at all.
///
/// A separator does not count inside
/// - a URL: `Site: https://example.com:8080/path` is two cells. One at the
///   very end of a URL, before whitespace or the end of the line, does — it
///   reads as punctuation after the link, not as part of it;
/// - a quoted string, `"…"` or `'…'`, quotes kept in the cell. A quote
///   opens a string only when a matching one closes it later on the line, and
///   a single quote only at the start of a word and closed at the end of one,
///   so the apostrophe in "don't" opens nothing.
/// - after a backslash: `a \| b` is one cell, as in a Markdown table.
List<String>? splitTableCells(String line, String separator) {
  final shielded = List<bool>.filled(line.length, false);

  for (final match in _urlPattern.allMatches(line)) {
    var end = match.end;
    // Trailing separators (and only those) are left outside the URL.
    while (end > match.start + 1 && line[end - 1] == separator) {
      end--;
    }
    shielded.fillRange(match.start, end, true);
  }

  for (var i = 0; i < line.length; i++) {
    if (shielded[i]) continue;
    final quote = line[i];
    if (quote != '"' && quote != "'") continue;
    if (quote == "'" && i > 0 && _isWordChar(line[i - 1])) continue;

    var close = -1;
    for (var j = i + 1; j < line.length; j++) {
      if (line[j] != quote) continue;
      if (quote == "'" && j + 1 < line.length && _isWordChar(line[j + 1])) {
        continue;
      }
      close = j;
      break;
    }
    if (close < 0) continue;
    shielded.fillRange(i, close + 1, true);
    i = close;
  }

  final cells = <String>[];
  var from = 0;
  for (var i = 0; i < line.length; i++) {
    if (line[i] == separator &&
        !shielded[i] &&
        (i == 0 || line[i - 1] != '\\')) {
      cells.add(line.substring(from, i).trim());
      from = i + 1;
    }
  }
  if (cells.isEmpty) return null;
  cells.add(line.substring(from).trim());
  return cells;
}

/// The lines [selection] touches, in document order. A selection that ends
/// exactly where a line begins does not reach into that line.
List<Line> _selectedLines(Document document, TextSelection selection) {
  final lines = <Line>[];
  var offset = selection.start;
  while (offset < document.length) {
    final line = document.queryChild(offset).node;
    if (line is! Line) break;
    lines.add(line);

    offset = line.documentOffset + line.length;
    if (offset >= selection.end) break;
  }
  return lines;
}
