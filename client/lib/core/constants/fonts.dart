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
  ...kMonospaceFonts,
];

/// The bundled console fonts — the only families the app can promise line up.
///
/// They are assets (see `pubspec.yaml`) because nothing else is dependable:
/// `tool/font_probe.dart` measures Flutter on Linux resolving the generic
/// `monospace` to a *proportional* face, and a family that is not installed
/// falls back to the default without an error, so text padded into columns
/// comes out looking exactly as it did before.
///
/// Consolas is not here and cannot be — it ships with Windows and Office, and
/// is not redistributable. Cascadia Mono is Microsoft's own successor to it,
/// and Inconsolata was drawn as an open homage to it.
const List<String> kMonospaceFonts = <String>[
  'JetBrains Mono',
  'Cascadia Mono',
  'Inconsolata',
  'Source Code Pro',
  'IBM Plex Mono',
];

/// The fixed-width family to reach for when the text has not asked for one —
/// what Format as table sets on a note that is in a proportional font.
const String kMonospaceFont = 'JetBrains Mono';

/// The generic families the platform resolves itself, whatever is installed.
/// They are spelled the way a stylesheet spells them, so [fontFamilyLabel]
/// gives them a display name.
const List<String> kGenericFonts = <String>['sans-serif', 'serif', 'monospace'];

/// Whether [family] is one we can promise is fixed-width. Only the bundled
/// ones qualify: a generic name resolves to whatever the platform feels like,
/// and a family typed into Custom… is the user's to judge.
bool isMonospaceFont(String? family) => kMonospaceFonts.contains(family);

/// The fixed-width family to set on text that has to line up, given the font
/// the editor is already in: a note already set in one of the bundled console
/// fonts keeps it, rather than being moved to a different one mid-document.
String monospaceFontFor(String? editorFamily) =>
    isMonospaceFont(editorFamily) ? editorFamily! : kMonospaceFont;

/// How a family is written in a menu: the null sentinel and the generic
/// families get a name a reader recognises, everything else is its own.
String fontFamilyLabel(String? family) => switch (family) {
      null => 'System default',
      'sans-serif' => 'Sans Serif',
      'serif' => 'Serif',
      'monospace' => 'Monospace',
      final String name => name,
    };

/// Font families offered by the editor toolbar's Font menu, as
/// label → stored `font` attribute value.
///
/// The generic ones come first because they resolve on every platform; the
/// rest are [kCuratedFonts], so the toolbar and Preferences offer the same
/// names. `Clear` is flutter_quill's own sentinel for "no family attribute" —
/// the label has to read exactly that for the button to treat it as a reset.
final Map<String, String> kEditorFontFamilies = {
  for (final family in kGenericFonts) fontFamilyLabel(family): family,
  for (final family in kCuratedFonts.whereType<String>())
    if (!kGenericFonts.contains(family)) family: family,
  'Clear': 'Clear',
};

/// [kEditorFontFamilies] narrowed to the fixed-width family when
/// [monospaceOnly] is set — the editor's own Font menu, and the only font
/// choice the preference governs. The content font in Preferences is not
/// narrowed: it dresses the tree as well as the editor, and the tree has no
/// columns to line up.
///
/// `Clear` stays either way: putting text back under the content font is not
/// a choice of family.
Map<String, String> editorFontFamilies({required bool monospaceOnly}) =>
    monospaceOnly
        ? {
            for (final entry in kEditorFontFamilies.entries)
              if (isMonospaceFont(entry.value) || entry.value == 'Clear')
                entry.key: entry.value,
          }
        : kEditorFontFamilies;

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

/// Compose the editor's font fields from [settings] into a [TextStyle],
/// optionally layered on top of [base]. Fields that are at their default
/// (null family, 14.0 size, false bold/italic) do not override [base].
TextStyle fontSettingsToStyle(AppSettings settings, {TextStyle? base}) =>
    _fontToStyle(
      family: settings.fontFamily,
      size: settings.fontSize,
      bold: settings.fontBold,
      italic: settings.fontItalic,
      base: base,
    );

/// The same for the tree, which has its own font — see
/// [AppSettings.treeFontFamily].
TextStyle treeFontSettingsToStyle(AppSettings settings, {TextStyle? base}) =>
    _fontToStyle(
      family: settings.treeFontFamily,
      size: settings.treeFontSize,
      bold: settings.treeFontBold,
      italic: settings.treeFontItalic,
      base: base,
    );

TextStyle _fontToStyle({
  required String? family,
  required double size,
  required bool bold,
  required bool italic,
  TextStyle? base,
}) {
  final baseStyle = base ?? const TextStyle();
  return baseStyle.copyWith(
    fontFamily: family ?? baseStyle.fontFamily,
    fontSize: size == AppSettings.kDefaultContentFontSize
        ? baseStyle.fontSize
        : size,
    fontWeight: bold ? FontWeight.bold : baseStyle.fontWeight,
    fontStyle: italic ? FontStyle.italic : baseStyle.fontStyle,
  );
}
