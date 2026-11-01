import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/theme/app_theme.dart';

/// `ThemeData`'s text themes carry null font sizes until they are localized
/// against the typography geometry, so scaling them has to resolve the
/// geometry first. Guards the Appearance > "UI scale" preference.
void main() {
  test('scaling a raw theme text style is a no-op (why localize first)', () {
    expect(AppTheme.light.textTheme.bodyMedium?.fontSize, isNull);
  });

  test('localized theme text styles can be scaled', () {
    final base = AppTheme.light;
    final resolved = ThemeData.localize(base, base.typography.englishLike);
    final unscaled = resolved.textTheme.bodyMedium!.fontSize!;
    final scaled =
        resolved.textTheme.apply(fontSizeFactor: 1.5).bodyMedium!.fontSize!;
    expect(scaled, closeTo(unscaled * 1.5, 0.01));
  });

  testWidgets('UI scale enlarges chrome text in the widget tree',
      (tester) async {
    late double scaledSize;

    await tester.pumpWidget(
      MaterialApp(
        theme: chromeScaledTheme(AppTheme.light, family: null, scale: 1.5),
        home: Builder(
          builder: (context) {
            scaledSize = Theme.of(context).textTheme.bodyMedium!.fontSize!;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    final base = ThemeData.localize(
      AppTheme.light,
      AppTheme.light.typography.englishLike,
    );
    expect(scaledSize, closeTo(base.textTheme.bodyMedium!.fontSize! * 1.5, 0.01));
  });
}
