import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/constants/fonts.dart';
import 'package:noo/presentation/providers/settings_provider.dart';

void main() {
  group('fontSettingsToStyle', () {
    test('returns base untouched when all fields are default', () {
      const settings = AppSettings();
      const base = TextStyle(color: Colors.red, fontSize: 99);
      final result = fontSettingsToStyle(settings, base: base);
      expect(result.color, Colors.red);
      expect(result.fontSize, 99);
      expect(result.fontFamily, isNull);
      expect(result.fontWeight, isNull);
      expect(result.fontStyle, isNull);
    });

    test('applies family, size, bold, italic', () {
      const settings = AppSettings(
        fontFamily: 'Roboto',
        fontSize: 18.0,
        fontBold: true,
        fontItalic: true,
      );
      final result = fontSettingsToStyle(settings);
      expect(result.fontFamily, 'Roboto');
      expect(result.fontSize, 18.0);
      expect(result.fontWeight, FontWeight.bold);
      expect(result.fontStyle, FontStyle.italic);
    });

    test('leaves base fontSize when settings has default size', () {
      const settings = AppSettings();
      const base = TextStyle(fontSize: 20);
      final result = fontSettingsToStyle(settings, base: base);
      expect(result.fontSize, 20);
    });

    test('settings size overrides base size', () {
      const settings = AppSettings(fontSize: 22.0);
      const base = TextStyle(fontSize: 10);
      final result = fontSettingsToStyle(settings, base: base);
      expect(result.fontSize, 22.0);
    });

    test('preserves base fontWeight and fontStyle when settings are default', () {
      const settings = AppSettings();
      const base = TextStyle(
        fontWeight: FontWeight.w300,
        fontStyle: FontStyle.italic,
        fontFamily: 'Courier',
      );
      final result = fontSettingsToStyle(settings, base: base);
      expect(result.fontWeight, FontWeight.w300);
      expect(result.fontStyle, FontStyle.italic);
      expect(result.fontFamily, 'Courier');
    });

    test('returns base-equivalent style when base is null and settings are default', () {
      const settings = AppSettings();
      final result = fontSettingsToStyle(settings);
      expect(result.fontFamily, isNull);
      expect(result.fontSize, isNull);
      expect(result.fontWeight, isNull);
      expect(result.fontStyle, isNull);
    });

    test('kCuratedFonts has system-default null sentinel followed by real families', () {
      expect(kCuratedFonts.first, isNull);
      expect(kCuratedFonts, contains('Roboto'));
      expect(kCuratedFonts, contains('Noto Sans'));
      expect(kCuratedFonts, contains('Noto Serif'));
      expect(kCuratedFonts, containsAll(kMonospaceFonts));
      expect(kCuratedFonts.whereType<String>().length,
          3 + kMonospaceFonts.length);
    });
  });

  group('monospace fonts only', () {
    test('leaves the Preferences content list alone', () {
      expect(kCuratedFonts, contains(kMonospaceFont));
      expect(kCuratedFonts.length, greaterThan(1),
          reason: 'the content font dresses the tree as well as the editor, '
              'so the preference does not narrow it');
    });

    test('narrows the toolbar menu but keeps Clear', () {
      final items = editorFontFamilies(monospaceOnly: true);
      expect(items.values, containsAll(kMonospaceFonts));
      expect(items.values, isNot(contains('monospace')),
          reason: 'the generic name resolves to a proportional face on Linux '
              '— see tool/font_probe.dart');
      expect(items['Clear'], 'Clear',
          reason: 'clearing the family is not a choice of family');
      expect(items.values, isNot(contains('sans-serif')));
      expect(items.values, isNot(contains('serif')));
      expect(items.values, isNot(contains('Roboto')));
    });

    test('the full toolbar menu lists each family once', () {
      final values = kEditorFontFamilies.values.toList();
      expect(values.toSet().length, values.length,
          reason: 'the generic monospace and the curated one are one entry');
      expect(kEditorFontFamilies['Monospace'], 'monospace');
    });

    test('isMonospaceFont answers only for the bundled families', () {
      for (final family in kMonospaceFonts) {
        expect(isMonospaceFont(family), isTrue, reason: family);
      }
      expect(isMonospaceFont('Consolas'), isFalse,
          reason: 'proprietary to Windows and Office, so it cannot be '
              'bundled — and it falls back silently everywhere else');
      expect(isMonospaceFont('monospace'), isFalse,
          reason: 'a generic name is whatever the platform makes of it');
      expect(isMonospaceFont('Noto Sans'), isFalse);
      expect(isMonospaceFont(null), isFalse,
          reason: 'System default is not known to be fixed-width');
    });

    test('a note already in a console font keeps it', () {
      expect(monospaceFontFor('Cascadia Mono'), 'Cascadia Mono');
      expect(monospaceFontFor('Inconsolata'), 'Inconsolata');
      expect(monospaceFontFor('Noto Sans'), kMonospaceFont,
          reason: 'a proportional note gets the default console font');
      expect(monospaceFontFor(null), kMonospaceFont);
    });

    test('fontFamilyLabel names the sentinel and the generic families', () {
      expect(fontFamilyLabel(null), 'System default');
      expect(fontFamilyLabel('sans-serif'), 'Sans Serif');
      expect(fontFamilyLabel('serif'), 'Serif');
      expect(fontFamilyLabel('monospace'), 'Monospace');
      expect(fontFamilyLabel('JetBrains Mono'), 'JetBrains Mono');
    });
  });
}
