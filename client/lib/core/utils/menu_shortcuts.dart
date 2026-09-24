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

/// Toggling the search panel. ⌘F on macOS, the standard Find key there;
/// Ctrl+Shift+F elsewhere, which leaves plain Ctrl+F to the text editor.
SingleActivator get findActivator => usesCommandModifier
    ? const SingleActivator(LogicalKeyboardKey.keyF, meta: true)
    : const SingleActivator(
        LogicalKeyboardKey.keyF,
        control: true,
        shift: true,
      );
