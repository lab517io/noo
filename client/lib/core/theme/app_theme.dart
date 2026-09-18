import 'package:flutter/material.dart';

/// Apply the chrome font [family] and [scale] to [base] without disturbing
/// per-role weight/letter-spacing. A `null` family keeps the theme's default
/// family; a scale of `1.0` is identity.
///
/// [ThemeData]'s text themes carry null font sizes until `MaterialApp`
/// localizes them against the typography geometry, and scaling a null size is
/// an error (and a silent no-op in release). So the geometry is resolved here
/// first; the later localization keeps these now-concrete sizes.
ThemeData chromeScaledTheme(
  ThemeData base, {
  required String? family,
  required double scale,
}) {
  if (family == null && scale == 1.0) return base;

  final resolved = ThemeData.localize(base, base.typography.englishLike);
  return resolved.copyWith(
    textTheme: resolved.textTheme.apply(
      fontFamily: family,
      fontSizeFactor: scale,
    ),
    primaryTextTheme: resolved.primaryTextTheme.apply(
      fontFamily: family,
      fontSizeFactor: scale,
    ),
  );
}

/// Application theme configuration
class AppTheme {
  AppTheme._();

  /// Seeded dark scheme with the surface/foreground ramp replaced by the
  /// relaxed greys. Accents (primary, secondary, error, ...) stay seeded.
  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF4A90A4),
    brightness: Brightness.dark,
  ).copyWith(
    surface: const Color(0xFF23282B),
    onSurface: const Color(0xFFC6CBCE),
    onSurfaceVariant: const Color(0xFFA3ABAF),
    surfaceDim: const Color(0xFF1E2325),
    surfaceBright: const Color(0xFF33393C),
    surfaceContainerLowest: const Color(0xFF1B2022),
    surfaceContainerLow: const Color(0xFF23282B),
    surfaceContainer: const Color(0xFF272D30),
    surfaceContainerHigh: const Color(0xFF2E3437),
    surfaceContainerHighest: const Color(0xFF373D40),
    outline: const Color(0xFF6B7377),
    outlineVariant: const Color(0xFF3D4447),
    inverseSurface: const Color(0xFFC6CBCE),
    onInverseSurface: const Color(0xFF23282B),
  );

  /// Light theme
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90A4),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          thickness: 1,
          space: 1,
        ),
        listTileTheme: const ListTileThemeData(
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );

  /// Dark theme.
  ///
  /// Deliberately lower-contrast than the stock Material dark scheme: the
  /// seeded surfaces are near-black and the seeded `onSurface` near-white,
  /// which is harsh over a long editing session. The surfaces below are a
  /// lighter neutral grey and the foregrounds a dimmed grey rather than white,
  /// keeping body text around 9:1 against the surface instead of ~15:1.
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: _darkScheme,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          thickness: 1,
          space: 1,
        ),
        listTileTheme: const ListTileThemeData(
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );
}
