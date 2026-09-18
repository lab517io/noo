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
      expect(kCuratedFonts, contains('JetBrains Mono'));
      expect(kCuratedFonts.whereType<String>().length, 4);
    });
  });
}
