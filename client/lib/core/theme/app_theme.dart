import 'package:flutter/material.dart';

import 'noo_chrome.dart';
import 'ui_style.dart';

export 'noo_chrome.dart';
export 'ui_style.dart';

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

/// Application theme configuration: brightness × [UiStyle] × [AccentColor].
class AppTheme {
  AppTheme._();

  /// Modern, in the original teal — what the app looked like before it had
  /// styles, and what tests and bare previews are built with.
  static ThemeData get light => build(Brightness.light);
  static ThemeData get dark => build(Brightness.dark);

  static ThemeData build(
    Brightness brightness, {
    UiStyle style = UiStyle.modern,
    AccentColor accent = AccentColor.teal,
  }) {
    final scheme = _scheme(brightness, style, accent);
    return switch (style) {
      UiStyle.modern => _modern(scheme),
      UiStyle.classic => _classic(scheme),
    };
  }

  /// Seeded from [accent], with the surfaces replaced where the seeded ones
  /// do not suit.
  ///
  /// Dark (both styles): deliberately lower-contrast than the stock Material
  /// dark scheme. The seeded surfaces are near-black and the seeded
  /// `onSurface` near-white, which is harsh over a long editing session; the
  /// surfaces below are a lighter neutral grey and the foregrounds a dimmed
  /// grey rather than white, keeping body text around 9:1 against the surface
  /// instead of ~15:1.
  ///
  /// Classic light: neutral greys for the containers instead of the seeded
  /// ones, which carry a tint of the accent. Traditional chrome is grey, and
  /// a pink accent should not turn every dialog pink.
  static ColorScheme _scheme(
      Brightness brightness, UiStyle style, AccentColor accent) {
    final seeded =
        ColorScheme.fromSeed(seedColor: accent.seed, brightness: brightness);
    if (brightness == Brightness.dark) {
      return seeded.copyWith(
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
    }
    if (style == UiStyle.classic) {
      return seeded.copyWith(
        surface: const Color(0xFFFFFFFF),
        onSurface: const Color(0xFF1C1C1C),
        onSurfaceVariant: const Color(0xFF4A4A4A),
        surfaceDim: const Color(0xFFE0E0E0),
        surfaceBright: const Color(0xFFFFFFFF),
        surfaceContainerLowest: const Color(0xFFFFFFFF),
        surfaceContainerLow: const Color(0xFFF7F7F7),
        surfaceContainer: const Color(0xFFF0F0F0),
        surfaceContainerHigh: const Color(0xFFECECEC),
        surfaceContainerHighest: const Color(0xFFE2E2E2),
        outline: const Color(0xFF8A8A8A),
        outlineVariant: const Color(0xFFCFCFCF),
      );
    }
    return seeded;
  }

  /// What both styles share.
  static ThemeData _base(ColorScheme scheme) => ThemeData(
        useMaterial3: true,
        brightness: scheme.brightness,
        colorScheme: scheme,
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
        dividerTheme: const DividerThemeData(thickness: 1, space: 1),
        listTileTheme: const ListTileThemeData(
          dense: true,
          visualDensity: VisualDensity.compact,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      );

  static ThemeData _modern(ColorScheme scheme) =>
      _base(scheme).copyWith(extensions: [NooChrome.modern(scheme)]);

  /// The traditional desktop look. Everything Material draws is reshaped
  /// through its component themes, so no widget has to know which style is
  /// on; the app's own widgets read [NooChrome].
  static ThemeData _classic(ColorScheme scheme) {
    const radius = BorderRadius.all(Radius.circular(2));
    const shape = RoundedRectangleBorder(borderRadius: radius);
    final edge = BorderSide(color: scheme.outline);
    final framed = RoundedRectangleBorder(borderRadius: radius, side: edge);
    final menuFrame = RoundedRectangleBorder(
      side: BorderSide(color: scheme.outlineVariant),
    );
    final base = _base(scheme);

    // Shared by every button type: square, flat, no ripple.
    final buttonShape = WidgetStatePropertyAll<OutlinedBorder>(shape);
    const flat = WidgetStatePropertyAll<double>(0);

    final menuStyle = MenuStyle(
      shape: WidgetStatePropertyAll(menuFrame),
      elevation: const WidgetStatePropertyAll(3),
      backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerLowest),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 2)),
    );

    return base.copyWith(
      splashFactory: NoSplash.splashFactory,
      dividerColor: scheme.outlineVariant,
      scaffoldBackgroundColor: scheme.surface,
      extensions: [NooChrome.classic(scheme)],
      dialogTheme: DialogThemeData(
        shape: framed,
        elevation: 4,
        backgroundColor: scheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(shape: buttonShape, elevation: flat),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(shape: buttonShape, elevation: flat),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          shape: buttonShape,
          side: WidgetStatePropertyAll(edge),
          backgroundColor:
              WidgetStatePropertyAll(scheme.surfaceContainerLowest),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(shape: buttonShape),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(shape: buttonShape),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(shape: buttonShape),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: shape,
        elevation: 1,
        focusElevation: 1,
        hoverElevation: 2,
        highlightElevation: 1,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        border: const OutlineInputBorder(borderRadius: radius),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(1)),
        ),
        side: BorderSide(color: scheme.outline, width: 1.5),
      ),
      chipTheme: const ChipThemeData(shape: shape),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outlineVariant),
        ),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        shape: menuFrame,
        elevation: 3,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
      ),
      menuTheme: MenuThemeData(style: menuStyle),
      dropdownMenuTheme: DropdownMenuThemeData(menuStyle: menuStyle),
      menuBarTheme: MenuBarThemeData(
        style: MenuStyle(
          shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
          elevation: const WidgetStatePropertyAll(0),
          backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainer),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      menuButtonTheme: MenuButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(RoundedRectangleBorder()),
          // The traditional highlight: the accent behind the hovered item.
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.focused)
                  ? scheme.primary
                  : null),
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.disabled)
                  ? null
                  : states.contains(WidgetState.hovered) ||
                          states.contains(WidgetState.focused)
                      ? scheme.onPrimary
                      : scheme.onSurface),
          iconColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.focused)
                  ? scheme.onPrimary
                  : null),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          border: Border.all(color: scheme.outline),
          borderRadius: const BorderRadius.all(Radius.circular(1)),
        ),
        textStyle: TextStyle(color: scheme.onSurface, fontSize: 12),
        waitDuration: const Duration(milliseconds: 500),
      ),
      snackBarTheme: const SnackBarThemeData(
        shape: shape,
        behavior: SnackBarBehavior.floating,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(),
      ),
      // A raised tab on the sheet behind it, rather than a pill underline.
      tabBarTheme: TabBarThemeData(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: scheme.outline,
        indicator: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          border: Border(
            top: BorderSide(color: scheme.primary, width: 2),
            left: BorderSide(color: scheme.outline),
            right: BorderSide(color: scheme.outline),
          ),
        ),
        labelColor: scheme.onSurface,
        unselectedLabelColor: scheme.onSurfaceVariant,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
      ),
      // Always there, the way desktop scrollbars are — not only on hover.
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: const WidgetStatePropertyAll(true),
        thickness: const WidgetStatePropertyAll(8),
        radius: const Radius.circular(1),
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.dragged) ||
                    states.contains(WidgetState.hovered)
                ? scheme.outline
                : scheme.outlineVariant),
      ),
    );
  }
}
