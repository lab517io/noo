import 'package:flutter/material.dart';

/// What the app's own widgets need from the theme that [ThemeData] has no
/// slot for: the corner radii they draw their boxes with, the shape of the
/// property-sheet dialogs, and the colours of the title bar the app draws on
/// Windows and Linux.
///
/// Material's widgets take their look from ThemeData's component themes;
/// these are the rest — group boxes, badges, status bar chips, previews, the
/// title strip — which used to hard-code a radius or a colour each and so
/// could not change with the style.
@immutable
class NooChrome extends ThemeExtension<NooChrome> {
  const NooChrome({
    required this.smallRadius,
    required this.radius,
    required this.largeRadius,
    required this.dialogShape,
    required this.titleBarColor,
    required this.titleBarForeground,
    required this.titleBarInactiveColor,
    required this.titleBarInactiveForeground,
    required this.titleBarBoldTitle,
    required this.menuBelowTitle,
  });

  /// Tight boxes: chips, code-like labels, field frames, group boxes.
  final BorderRadius smallRadius;

  /// Ordinary boxes: panels, previews, selected rows.
  final BorderRadius radius;

  /// Larger surfaces: cards, report panes.
  final BorderRadius largeRadius;

  /// The property-sheet dialogs (Preferences, the sync dialogs), which used
  /// to set a 4px rectangle of their own rather than Material's rounded one.
  final ShapeBorder dialogShape;

  /// The app-drawn title bar while the window is active, and while it is not.
  final Color titleBarColor;
  final Color titleBarForeground;
  final Color titleBarInactiveColor;
  final Color titleBarInactiveForeground;

  /// Title in bold and at the left, the way traditional title bars set it,
  /// rather than muted and centred.
  final bool titleBarBoldTitle;

  /// The menu bar on a row of its own under the title strip, rather than in
  /// it. Classic: a title strip in the accent colour cannot carry menu text
  /// drawn for the window background.
  final bool menuBelowTitle;

  /// The extension of [context]'s theme, or the modern one for a theme built
  /// without it (tests, a bare MaterialApp).
  static NooChrome of(BuildContext context) => fromTheme(Theme.of(context));

  static NooChrome fromTheme(ThemeData theme) =>
      theme.extension<NooChrome>() ?? modern(theme.colorScheme);

  /// The radii the app used before it had styles, so Modern looks as it did.
  static NooChrome modern(ColorScheme scheme) => NooChrome(
        smallRadius: BorderRadius.circular(3),
        radius: BorderRadius.circular(4),
        largeRadius: BorderRadius.circular(6),
        dialogShape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        titleBarColor: scheme.surfaceContainerLow,
        titleBarForeground: scheme.onSurfaceVariant,
        titleBarInactiveColor: scheme.surfaceContainerLow,
        titleBarInactiveForeground: scheme.onSurfaceVariant.withValues(alpha: 0.6),
        titleBarBoldTitle: false,
        menuBelowTitle: false,
      );

  static NooChrome classic(ColorScheme scheme) {
    const square = BorderRadius.all(Radius.circular(2));
    return NooChrome(
      smallRadius: const BorderRadius.all(Radius.circular(1)),
      radius: square,
      largeRadius: square,
      dialogShape: RoundedRectangleBorder(
        borderRadius: square,
        side: BorderSide(color: scheme.outline),
      ),
      // The accent itself in the light theme. In the dark one the scheme's
      // primary is a pale tint — a glaring strip over dark chrome — so the
      // deeper container tone carries the accent there instead.
      titleBarColor: scheme.brightness == Brightness.light
          ? scheme.primary
          : scheme.primaryContainer,
      titleBarForeground: scheme.brightness == Brightness.light
          ? scheme.onPrimary
          : scheme.onPrimaryContainer,
      titleBarInactiveColor: scheme.surfaceContainerHighest,
      titleBarInactiveForeground: scheme.onSurfaceVariant,
      titleBarBoldTitle: true,
      menuBelowTitle: true,
    );
  }

  @override
  NooChrome copyWith({
    BorderRadius? smallRadius,
    BorderRadius? radius,
    BorderRadius? largeRadius,
    ShapeBorder? dialogShape,
    Color? titleBarColor,
    Color? titleBarForeground,
    Color? titleBarInactiveColor,
    Color? titleBarInactiveForeground,
    bool? titleBarBoldTitle,
    bool? menuBelowTitle,
  }) =>
      NooChrome(
        smallRadius: smallRadius ?? this.smallRadius,
        radius: radius ?? this.radius,
        largeRadius: largeRadius ?? this.largeRadius,
        dialogShape: dialogShape ?? this.dialogShape,
        titleBarColor: titleBarColor ?? this.titleBarColor,
        titleBarForeground: titleBarForeground ?? this.titleBarForeground,
        titleBarInactiveColor:
            titleBarInactiveColor ?? this.titleBarInactiveColor,
        titleBarInactiveForeground:
            titleBarInactiveForeground ?? this.titleBarInactiveForeground,
        titleBarBoldTitle: titleBarBoldTitle ?? this.titleBarBoldTitle,
        menuBelowTitle: menuBelowTitle ?? this.menuBelowTitle,
      );

  @override
  NooChrome lerp(covariant NooChrome? other, double t) {
    if (other == null) return this;
    BorderRadius r(BorderRadius a, BorderRadius b) =>
        BorderRadius.lerp(a, b, t) ?? b;
    // Layout flags cannot be blended; they switch halfway.
    final near = t < 0.5 ? this : other;
    return NooChrome(
      smallRadius: r(smallRadius, other.smallRadius),
      radius: r(radius, other.radius),
      largeRadius: r(largeRadius, other.largeRadius),
      dialogShape: ShapeBorder.lerp(dialogShape, other.dialogShape, t) ??
          other.dialogShape,
      titleBarColor: Color.lerp(titleBarColor, other.titleBarColor, t)!,
      titleBarForeground:
          Color.lerp(titleBarForeground, other.titleBarForeground, t)!,
      titleBarInactiveColor:
          Color.lerp(titleBarInactiveColor, other.titleBarInactiveColor, t)!,
      titleBarInactiveForeground: Color.lerp(
          titleBarInactiveForeground, other.titleBarInactiveForeground, t)!,
      titleBarBoldTitle: near.titleBarBoldTitle,
      menuBelowTitle: near.menuBelowTitle,
    );
  }
}

