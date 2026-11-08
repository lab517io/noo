import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/theme/app_theme.dart';
import 'package:noo/presentation/providers/settings_provider.dart';
import 'package:noo/presentation/widgets/app_menu_bar.dart';
import 'package:noo/presentation/widgets/window_title_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Where the menu bar goes: inside the app-drawn title strip (Modern), on a
/// row of its own under a classic title strip (Classic), or under the
/// desktop's own title bar when the user chose that frame.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const secureStorage =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  const windowManager = MethodChannel('window_manager');
  late List<MethodCall> nativeCalls;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    messenger.setMockMethodCallHandler(secureStorage, (call) async {
      return switch (call.method) {
        'readAll' => <String, String>{},
        'containsKey' => false,
        _ => null,
      };
    });
    nativeCalls = [];
    messenger.setMockMethodCallHandler(windowManager, (call) async {
      nativeCalls.add(call);
      return call.method == 'isMaximized' ? false : null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(secureStorage, null);
    messenger.setMockMethodCallHandler(windowManager, null);
    debugSetSystemTitleBar(false);
  });

  late ProviderContainer container;

  Future<void> pumpMenu(WidgetTester tester, ThemeData theme) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        theme: theme,
        home: const Scaffold(body: AppMenuBar(child: SizedBox.expand())),
      ),
    ));
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
        tester.element(find.byType(AppMenuBar)));
  }

  Finder menuInTitleStrip() => find.descendant(
      of: find.byType(WindowTitleBar), matching: find.byType(MenuBar));

  testWidgets('modern: the menu shares the title strip', (tester) async {
    if (!usesCustomTitleBar) return; // macOS: the system menu bar instead
    await pumpMenu(tester, AppTheme.light);

    expect(find.byType(WindowTitleBar), findsOneWidget);
    expect(menuInTitleStrip(), findsOneWidget);
  });

  testWidgets('classic: the menu sits on its own row under the title strip',
      (tester) async {
    if (!usesCustomTitleBar) return;
    await pumpMenu(
        tester, AppTheme.build(Brightness.light, style: UiStyle.classic));

    expect(find.byType(WindowTitleBar), findsOneWidget);
    expect(menuInTitleStrip(), findsNothing);
    expect(tester.getTopLeft(find.byType(MenuBar)).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(find.byType(WindowTitleBar)).dy));
    expect(tester.getTopLeft(find.byType(MenuBar)).dx, 0,
        reason: 'the menu starts at the window edge, not centred');
  });

  testWidgets('system title bar: no app-drawn strip at all', (tester) async {
    if (!offersSystemTitleBarChoice) return;
    debugSetSystemTitleBar(true);
    await pumpMenu(tester, AppTheme.light);

    expect(find.byType(WindowTitleBar), findsNothing);
    expect(find.byType(MenuBar), findsOneWidget);
    expect(tester.getSize(find.byType(MenuBar)).width, 1280);
  });

  testWidgets('switching the frame live moves the menu out of the strip',
      (tester) async {
    if (!offersSystemTitleBarChoice) return;
    await pumpMenu(tester, AppTheme.light);
    expect(find.byType(WindowTitleBar), findsOneWidget);

    // What NooApp's listener does when the preference changes: record the
    // frame (synchronously) and swap the native one.
    debugSetSystemTitleBar(true);
    await container.read(settingsProvider.notifier).setUseSystemTitleBar(true);
    await tester.pumpAndSettle();

    expect(find.byType(WindowTitleBar), findsNothing,
        reason: 'no restart: the strip goes as soon as the setting changes');
    expect(find.byType(MenuBar), findsOneWidget);
  });

  test('applySystemTitleBar asks for the native frame, and back', () async {
    if (!offersSystemTitleBarChoice) return;
    await applySystemTitleBar(true);
    expect(usesCustomTitleBar, isFalse);
    await applySystemTitleBar(false);
    expect(usesCustomTitleBar, isTrue);

    final styles = [
      for (final c in nativeCalls)
        if (c.method == 'setTitleBarStyle')
          (c.arguments as Map)['titleBarStyle'],
    ];
    expect(styles, ['normal', 'hidden']);
  });
}
