import 'package:flutter/material.dart';

/// The look of the app's chrome, independent of light/dark.
///
/// Stored by enum name (`AppSettings.uiStyle`); a name an older or newer
/// build does not know reads back as [modern].
enum UiStyle {
  /// Material 3 as Flutter draws it: rounded dialogs and buttons, ripples.
  modern('Modern'),

  /// A traditional desktop look: square corners, flat bordered buttons and
  /// panels, no ripples or shadows, scrollbars always shown, and a title bar
  /// in the accent colour with the menu bar on a row of its own.
  classic('Classic');

  const UiStyle(this.label);

  /// What Preferences calls it.
  final String label;

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
  teal('Teal', Color(0xFF4A90A4)),
  blue('Blue', Color(0xFF1F5FBF)),
  indigo('Indigo', Color(0xFF3F51B5)),
  purple('Purple', Color(0xFF7B4FA0)),
  pink('Pink', Color(0xFFB0457A)),
  red('Red', Color(0xFFB3403A)),
  orange('Orange', Color(0xFFC0632A)),
  amber('Amber', Color(0xFF9C7A1E)),
  green('Green', Color(0xFF3F8A4F)),
  graphite('Graphite', Color(0xFF5F6B73));

  const AccentColor(this.label, this.seed);

  final String label;
  final Color seed;

  static AccentColor fromName(String? name) => AccentColor.values.firstWhere(
        (c) => c.name == name,
        orElse: () => AccentColor.teal,
      );
}
