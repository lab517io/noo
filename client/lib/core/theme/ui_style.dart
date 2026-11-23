import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// The look of the app's chrome, independent of light/dark.
///
/// Stored by enum name (`AppSettings.uiStyle`); a name an older or newer
/// build does not know reads back as [modern].
enum UiStyle {
  /// Material 3 as Flutter draws it: rounded dialogs and buttons, ripples.
  modern,

  /// A traditional desktop look: square corners, flat bordered buttons and
  /// panels, no ripples or shadows, scrollbars always shown, and a title bar
  /// in the accent colour with the menu bar on a row of its own.
  classic;

  /// What Preferences calls it, in the interface language.
  String get label => switch (this) {
        modern => appL10n.prefsUiStyleModern,
        classic => appL10n.prefsUiStyleClassic,
      };

  static UiStyle fromName(String? name) => UiStyle.values.firstWhere(
        (s) => s.name == name,
        orElse: () => UiStyle.modern,
      );
}

/// The colour the theme is seeded from: buttons, selection, focus rings,
/// links, and — in [UiStyle.classic] — the active title bar.
///
/// Presets rather than a free colour picker: each has been checked to give a
/// readable scheme in both brightnesses, which an arbitrary seed does not
/// promise (a pale yellow seed makes white-on-primary text unreadable).
/// Stored by enum name; an unknown name reads back as [teal], the original.
enum AccentColor {
  teal(Color(0xFF4A90A4)),
  blue(Color(0xFF1F5FBF)),
  indigo(Color(0xFF3F51B5)),
  purple(Color(0xFF7B4FA0)),
  pink(Color(0xFFB0457A)),
  red(Color(0xFFB3403A)),
  orange(Color(0xFFC0632A)),
  amber(Color(0xFF9C7A1E)),
  green(Color(0xFF3F8A4F)),
  graphite(Color(0xFF5F6B73));

  const AccentColor(this.seed);

  final Color seed;

  /// The colour's name, in the interface language.
  String get label {
    final l10n = appL10n;
    return switch (this) {
      teal => l10n.prefsAccentTeal,
      blue => l10n.prefsAccentBlue,
      indigo => l10n.prefsAccentIndigo,
      purple => l10n.prefsAccentPurple,
      pink => l10n.prefsAccentPink,
      red => l10n.prefsAccentRed,
      orange => l10n.prefsAccentOrange,
      amber => l10n.prefsAccentAmber,
      green => l10n.prefsAccentGreen,
      graphite => l10n.prefsAccentGraphite,
    };
  }

  static AccentColor fromName(String? name) => AccentColor.values.firstWhere(
        (c) => c.name == name,
        orElse: () => AccentColor.teal,
      );
}
