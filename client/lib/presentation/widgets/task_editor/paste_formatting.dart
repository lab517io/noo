import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// Cleaning up the formatting that rides along with pasted rich text.
///
/// Text copied out of a browser or an office suite arrives as HTML, which
/// flutter_quill converts to a [Delta] carrying the source page's colours,
/// fonts and sizes. Those rarely suit the note it lands in — and a colour
/// chosen for a white page can come out unreadable against the dark theme —
/// so `Preferences → Behavior → Editor → Paste` decides how much of it
/// survives. See `PasteFormatting`.

/// Attributes that describe *appearance* rather than structure or emphasis.
///
/// Stripping these leaves bold, italic, underline, links, lists, headers and
/// code blocks intact: the pasted text keeps what it means and loses only how
/// the source happened to paint it.
const Set<String> kAppearanceAttributeKeys = {
  'color',
  'background',
  'font',
  'size',
};

/// [delta] with every [kAppearanceAttributeKeys] attribute removed.
///
/// Returns the delta unchanged when it carries none of them, so the common
/// case of pasting from a plain source costs nothing.
Delta stripAppearanceAttributes(Delta delta) {
  if (!delta.toList().any(_hasAppearanceAttribute)) return delta;

  final result = Delta();
  for (final op in delta.toList()) {
    final attributes = _withoutAppearance(op.attributes);
    if (op.isInsert) {
      result.insert(op.data, attributes);
    } else if (op.isRetain) {
      result.retain(op.length!, attributes);
    } else {
      result.delete(op.length!);
    }
  }
  return result;
}

bool _hasAppearanceAttribute(Operation op) {
  final attributes = op.attributes;
  if (attributes == null) return false;
  return attributes.keys.any(kAppearanceAttributeKeys.contains);
}

Map<String, dynamic>? _withoutAppearance(Map<String, dynamic>? attributes) {
  if (attributes == null || attributes.isEmpty) return null;
  final kept = <String, dynamic>{
    for (final entry in attributes.entries)
      if (!kAppearanceAttributeKeys.contains(entry.key)) entry.key: entry.value,
  };
  return kept.isEmpty ? null : kept;
}

/// The text carried by [delta], with every attribute and embed dropped.
///
/// Used when a source offers rich text but no plain text at all, so the plain
/// text has to be recovered from the converted delta.
String deltaToPlainText(Delta delta) {
  final buffer = StringBuffer();
  for (final op in delta.toList()) {
    final data = op.data;
    if (op.isInsert && data is String) buffer.write(data);
  }
  return buffer.toString();
}

/// Insert [text] at the caret as unstyled text, replacing any selection.
///
/// The text still takes on the styling of the character it is inserted after —
/// quill's `PreserveInlineStylesRule` — which is what "paste as plain text"
/// means everywhere else: the clipboard's formatting is dropped, the
/// destination's is kept.
void insertPlainText(QuillController controller, String text) {
  final selection = controller.selection;
  final start = selection.start;
  controller.replaceText(
    start,
    selection.end - start,
    text,
    TextSelection.collapsed(offset: start + text.length),
  );
}
