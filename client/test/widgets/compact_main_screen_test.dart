import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/presentation/screens/main_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The phone layout (below 600dp): no menu bar, so the app bar's overflow
/// menu has to carry what the desktop menus do.
Future<void> _pumpPhone(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    const ProviderScope(child: MaterialApp(home: MainScreen())),
  );
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  testWidgets('the app bar keeps the database name small', (tester) async {
    await _pumpPhone(tester);

    final bar = tester.widget<AppBar>(find.byType(AppBar));
    expect(bar.toolbarHeight, 48);
    final title = tester.widget<Text>(
      find.descendant(of: find.byType(AppBar), matching: find.text('Noo')),
    );
    final context = tester.element(find.byType(AppBar));
    expect(title.style?.fontSize,
        Theme.of(context).textTheme.labelMedium?.fontSize);
    expect(title.maxLines, 1);
  });

  testWidgets('the overflow menu offers the desktop menus\' actions',
      (tester) async {
    await _pumpPhone(tester);

    await tester.tap(find.byTooltip('Show menu'));
    await tester.pump(const Duration(milliseconds: 500));

    for (final item in [
      'Open Database...',
      'New Database...',
      'Sync P2P...',
      'Sync Log...',
      'Timeline...',
      'Time Report...',
      'Compact Database...',
      'Export to Obsidian...',
      'Import from Obsidian...',
      'Theme...',
      'Preferences...',
      'Check for Update...',
      'About Noo',
    ]) {
      expect(find.text(item), findsOneWidget, reason: item);
    }
  });
}
