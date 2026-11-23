import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// True where ⌘ — not Ctrl — is the modifier accelerators hang off. macOS
/// reserves Ctrl for other things, so the same command is spelled differently
/// there and every binding has to be built rather than written as a literal.
bool get usesCommandModifier => !kIsWeb && Platform.isMacOS;

/// An accelerator on the platform's primary modifier: ⌘ on macOS, Ctrl
/// elsewhere.
SingleActivator primaryActivator(
  LogicalKeyboardKey key, {
  bool shift = false,
}) =>
    SingleActivator(
      key,
      control: !usesCommandModifier,
      meta: usesCommandModifier,
      shift: shift,
    );

/// Moving the selected task in the tree, where [arrow] is one of the four
/// arrow keys: up/down swap it with a sibling, left lifts it to its parent's
/// level, right tucks it under the sibling above.
///
/// Every Ctrl/Alt/Shift combination of the arrows is already text navigation
/// somewhere, and these fire while the note editor has focus, so the choice is
/// which one to give up. Alt+Shift is Word's and OneNote's "move paragraph";
/// on Windows and Linux Flutter maps it to selecting to the line or document
/// boundary, which Shift+Home/End and Ctrl+Shift+Home/End already do. On macOS
/// Option+Shift is everyday paragraph selection, so ⌃⌘ is used there instead.
SingleActivator treeMoveActivator(LogicalKeyboardKey arrow) =>
    usesCommandModifier
        ? SingleActivator(arrow, control: true, meta: true)
        : SingleActivator(arrow, alt: true, shift: true);

/// Menu label for [treeMoveActivator], e.g. `Alt+Shift+↑` or `⌃⌘↑`.
String treeMoveShortcutLabel(LogicalKeyboardKey arrow) {
  final glyph = switch (arrow) {
    LogicalKeyboardKey.arrowUp => '↑',
    LogicalKeyboardKey.arrowDown => '↓',
    LogicalKeyboardKey.arrowLeft => '←',
    LogicalKeyboardKey.arrowRight => '→',
    _ => arrow.keyLabel,
  };
  return usesCommandModifier ? '⌃⌘$glyph' : 'Alt+Shift+$glyph';
}

/// Toggling the search panel. ⌘F on macOS, the standard Find key there;
/// Ctrl+Shift+F elsewhere, which leaves plain Ctrl+F to the text editor.
SingleActivator get findActivator => usesCommandModifier
    ? const SingleActivator(LogicalKeyboardKey.keyF, meta: true)
    : const SingleActivator(
        LogicalKeyboardKey.keyF,
        control: true,
        shift: true,
      );
