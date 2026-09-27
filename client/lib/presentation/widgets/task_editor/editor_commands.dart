import 'package:flutter/widgets.dart' show TextSelection;
import 'package:flutter_quill/flutter_quill.dart';

import '../../../core/constants/fonts.dart';

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

/// Lines up the colon-separated columns of the selected lines and sets them in
/// a fixed-width font, so that
///
///     Name: Dmytro
///     Occupation: developer
///
/// becomes
///
///     Name:       Dmytro
///     Occupation: developer
///
/// Every colon on a line starts a new column, so a line may hold more than the
/// two above; the columns of all the selected lines share their widths. Lines
/// that are not rows — a blank line between two groups, a heading with no
/// colon or one that ends in a colon, like "Addresses:" — are left exactly as
/// they are and take no part in the widths.
///
/// The padding is spaces, which only line up in a fixed-width font, so the
/// lines it rewrites are set in [font] — one of the bundled families, because
/// a generic name is not dependably fixed-width (see `tool/font_probe.dart`).
/// That is also why the rewritten lines lose their inline formatting: the
/// text is replaced wholesale. Lines
/// holding an image (or any other embed) are left alone for the same reason —
/// replacing their text would take the image with it.
void formatSelectionAsTable(QuillController controller, {String? font}) {
  final selection = controller.selection;
  if (!selection.isValid) return;

  final lines = _selectedLines(controller.document, selection);
  if (lines.isEmpty) return;

  final texts = <String?>[
    for (final line in lines)
      line.children.any((node) => node is Embed)
          ? null
          : controller.document
              .getPlainText(line.documentOffset, line.length - 1),
  ];
  final aligned = alignColonColumns(texts);

  final monospace =
      Attribute.fromKeyValue(Attribute.font.key, font ?? kMonospaceFont);
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
/// is not a row of the table — one that came in as null, one with no colon on
/// it, or a heading — and so is to be left exactly as it is.
///
/// Public for the tests: this is the whole of the layout decision, and it is
/// worth checking without an editor around it.
List<String?> alignColonColumns(List<String?> lines) {
  // A row is its line split on the colons, each cell trimmed of the spacing a
  // previous run of this command (or the user) left around it. A line with
  // nothing after its last colon — "Addresses:", a heading over the rows that
  // follow — is not a row: padding the rows out to its width would leave a
  // gap the width of the heading.
  final rows = <List<String>?>[
    for (final line in lines)
      if (line == null || !line.contains(':') || line.trimRight().endsWith(':'))
        null
      else
        [for (final cell in line.split(':')) cell.trim()],
  ];

  // The width of a column is its widest cell plus the colon that closes it.
  // Only columns that something follows need one: the last cell of a row ends
  // the line and is never padded.
  final widths = <int>[];
  for (final row in rows) {
    if (row == null) continue;
    for (var i = 0; i < row.length - 1; i++) {
      final width = row[i].length + 1;
      if (i == widths.length) {
        widths.add(width);
      } else if (width > widths[i]) {
        widths[i] = width;
      }
    }
  }

  return <String?>[
    for (var i = 0; i < lines.length; i++)
      if (rows[i] case final row?)
        [
          for (var c = 0; c < row.length - 1; c++)
            '${row[c]}:'.padRight(widths[c] + 1),
          row.last,
        ].join().trimRight()
      else
        null,
  ];
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
