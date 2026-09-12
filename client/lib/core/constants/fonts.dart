import 'package:flutter/material.dart';

import '../../presentation/providers/settings_provider.dart';

/// Curated font families offered in Preferences.
///
/// The leading `null` entry represents "System default" — no family override.
/// Other entries are family names that Flutter forwards to the platform font
/// system; unresolvable names fall back silently to the platform default.
const List<String?> kCuratedFonts = <String?>[
  null,
  'Roboto',
  'Noto Sans',
  'Noto Serif',
  'JetBrains Mono',
];

/// Font families offered by the editor toolbar's Font menu, as
/// label → stored `font` attribute value.
///
/// The generic three come first because they resolve on every platform; the
/// rest are [kCuratedFonts], so the toolbar and Preferences offer the same
/// names. `Clear` is flutter_quill's own sentinel for "no family attribute" —
/// the label has to read exactly that for the button to treat it as a reset.
final Map<String, String> kEditorFontFamilies = {
  'Sans Serif': 'sans-serif',
  'Serif': 'serif',
  'Monospace': 'monospace',
  for (final family in kCuratedFonts.whereType<String>()) family: family,
  'Clear': 'Clear',
};

/// Point sizes offered by the editor toolbar's Size menu, as label → stored
/// `size` attribute value.
///
/// An explicit size overrides the content font size from Preferences for the
/// text it is applied to; `Clear` (value `0`) puts that text back under it.
const Map<String, String> kEditorFontSizes = {
  '10': '10',
  '12': '12',
  '14': '14',
  '16': '16',
  '18': '18',
  '20': '20',
  '24': '24',
  '32': '32',
  'Clear': '0',
};

/// Compose [settings]'s font fields into a [TextStyle], optionally layered on
/// top of [base]. Fields that are at their default (null family, 14.0 size,
/// false bold/italic) do not override [base].
TextStyle fontSettingsToStyle(AppSettings settings, {TextStyle? base}) {
  final baseStyle = base ?? const TextStyle();
  return baseStyle.copyWith(
    fontFamily: settings.fontFamily ?? baseStyle.fontFamily,
    fontSize: settings.fontSize == AppSettings.kDefaultContentFontSize
        ? baseStyle.fontSize
        : settings.fontSize,
    fontWeight: settings.fontBold ? FontWeight.bold : baseStyle.fontWeight,
    fontStyle: settings.fontItalic ? FontStyle.italic : baseStyle.fontStyle,
  );
}
