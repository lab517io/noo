import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/theme/app_theme.dart';

/// Brightness × style × accent, and the chrome values the app's own widgets
/// read from the theme.
void main() {
  test('unknown stored names read back as the defaults', () {
    expect(UiStyle.fromName('baroque'), UiStyle.modern);
    expect(UiStyle.fromName(null), UiStyle.modern);
    expect(UiStyle.fromName('classic'), UiStyle.classic);
    expect(AccentColor.fromName('chartreuse'), AccentColor.teal);
    expect(AccentColor.fromName('red'), AccentColor.red);
  });

  test('the default build is what AppTheme.light/dark always were', () {
    expect(AppTheme.build(Brightness.light).colorScheme,
        AppTheme.light.colorScheme);
    expect(AppTheme.dark.colorScheme.surface, const Color(0xFF23282B),
        reason: 'the relaxed dark surfaces survive the refactor');
  });

  test('modern chrome keeps the radii the widgets used to hard-code', () {
    final chrome = NooChrome.fromTheme(AppTheme.light);
    expect(chrome.smallRadius, BorderRadius.circular(3));
    expect(chrome.radius, BorderRadius.circular(4));
    expect(chrome.menuBelowTitle, isFalse);
    expect(chrome.titleBarBoldTitle, isFalse);
  });

  test('a theme without the extension falls back to modern chrome', () {
    final chrome = NooChrome.fromTheme(ThemeData());
    expect(chrome.radius, BorderRadius.circular(4));
  });

  for (final brightness in Brightness.values) {
    test('classic ($brightness): square, flat, no ripple, menu under title',
        () {
      final theme = AppTheme.build(brightness, style: UiStyle.classic);
      final chrome = NooChrome.fromTheme(theme);

      expect(theme.brightness, brightness);
      expect(theme.splashFactory, NoSplash.splashFactory);
      expect(chrome.menuBelowTitle, isTrue);
      expect(chrome.titleBarBoldTitle, isTrue);
      // The accent: itself in light, its deeper container tone in dark,
      // where the scheme's primary is a pale tint.
      final light = brightness == Brightness.light;
      expect(chrome.titleBarColor,
          light ? theme.colorScheme.primary : theme.colorScheme.primaryContainer);
      expect(chrome.titleBarForeground,
          light ? theme.colorScheme.onPrimary : theme.colorScheme.onPrimaryContainer);

      final dialogShape = theme.dialogTheme.shape! as RoundedRectangleBorder;
      expect(dialogShape.borderRadius, const BorderRadius.all(Radius.circular(2)));
      expect(dialogShape.side.style, BorderStyle.solid);

      final buttonShape = theme.filledButtonTheme.style!.shape!
          .resolve({})! as RoundedRectangleBorder;
      expect(buttonShape.borderRadius,
          const BorderRadius.all(Radius.circular(2)));
      expect(theme.scrollbarTheme.thumbVisibility!.resolve({}), isTrue);
    });
  }

  test('classic light chrome is neutral grey, whatever the accent', () {
    final pink = AppTheme.build(Brightness.light,
        style: UiStyle.classic, accent: AccentColor.pink);
    expect(pink.colorScheme.surfaceContainer, const Color(0xFFF0F0F0));
    expect(pink.dialogTheme.backgroundColor, const Color(0xFFF0F0F0));
  });

  test('the accent seeds the scheme', () {
    final teal = AppTheme.build(Brightness.light).colorScheme.primary;
    final red = AppTheme.build(Brightness.light, accent: AccentColor.red)
        .colorScheme
        .primary;
    expect(red, isNot(teal));
    expect(red.r, greaterThan(red.b), reason: 'a red accent is reddish');
  });

  test('every accent leaves the classic title readable', () {
    double luminance(Color c) => c.computeLuminance();
    double contrast(Color a, Color b) {
      final la = luminance(a), lb = luminance(b);
      return (la > lb ? la + 0.05 : lb + 0.05) /
          (la > lb ? lb + 0.05 : la + 0.05);
    }

    for (final brightness in Brightness.values) {
      for (final accent in AccentColor.values) {
        final chrome = NooChrome.fromTheme(AppTheme.build(brightness,
            style: UiStyle.classic, accent: accent));
        expect(
            contrast(chrome.titleBarColor, chrome.titleBarForeground),
            greaterThanOrEqualTo(4.5),
            reason: '$accent in $brightness: the classic title bar text');
      }
    }
  });

  test('blending styles switches the layout flags halfway', () {
    final modern = NooChrome.fromTheme(AppTheme.light);
    final classic = NooChrome.fromTheme(
        AppTheme.build(Brightness.light, style: UiStyle.classic));
    expect(modern.lerp(classic, 0.4).menuBelowTitle, isFalse);
    expect(modern.lerp(classic, 0.6).menuBelowTitle, isTrue);
  });
}
