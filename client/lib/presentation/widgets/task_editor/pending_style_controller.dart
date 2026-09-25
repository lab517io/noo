import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

/// A [QuillController] that carries a *pending* toolbar style across Enter.
///
/// With a collapsed caret a toolbar button changes nothing in the document; it
/// only arms an attribute in `toggledStyle`, which is applied to the next
/// character typed. Turning a style off the same way parks a null-valued
/// attribute there — `getSelectionStyle()` merges `toggledStyle` last and a
/// null value removes the key, which is what darkens the button.
///
/// Quill's `keepStyleOnNewLine` then re-derives `toggledStyle` from the
/// character *before* the caret whenever a newline is inserted, so the new line
/// continues the previous one's styling. It **assigns** that style rather than
/// merging, so anything the user armed or disarmed just before pressing Enter
/// is discarded: switch strikethrough off at the end of struck text, press
/// Enter, and the new line comes back struck through — with the button lit
/// again. Arming works out the same way: turn bold on at the end of plain text,
/// press Enter, and the bold is gone.
///
/// This override re-applies the pending attributes on top of the inherited
/// style, so an explicit toggle wins over the carry-over while everything the
/// user did not touch still carries over.
class PendingStyleQuillController extends QuillController {
  PendingStyleQuillController({
    required super.document,
    required super.selection,
    super.config,
  });

  @override
  void replaceText(
    int index,
    int len,
    Object? data,
    TextSelection? textSelection, {
    bool ignoreFocus = false,
    bool shouldNotifyListeners = true,
  }) {
    // Only newlines re-derive toggledStyle, and only then when the carry-over
    // is on at all. Link is excluded for the same reason quill excludes it:
    // a URL belongs to the text it was attached to, not to the next line.
    final pending = keepStyleOnNewLine && data == '\n'
        ? toggledStyle.attributes.values
            .where((a) => a.isInline && a.key != Attribute.link.key)
            .toList()
        : const <Attribute>[];

    super.replaceText(
      index,
      len,
      data,
      textSelection,
      ignoreFocus: ignoreFocus,
      shouldNotifyListeners: shouldNotifyListeners,
    );

    if (pending.isEmpty) return;

    // `put`, not `merge`: a disarmed attribute is a null value that has to stay
    // in the map to cancel the inherited one.
    var restored = toggledStyle;
    for (final attribute in pending) {
      restored = restored.put(attribute);
    }
    if (restored == toggledStyle) return;

    if (shouldNotifyListeners) {
      // Notifies, so the toolbar repaints with the style the user chose —
      // super.replaceText has already pushed the inherited one out.
      forceToggledStyle(restored);
    } else {
      toggledStyle = restored;
    }
  }
}
