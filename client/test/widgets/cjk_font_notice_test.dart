import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/l10n/l10n.dart';
import 'package:noo/platform/cjk_fonts.dart';
import 'package:noo/presentation/providers/settings_provider.dart';
import 'package:noo/presentation/widgets/app_menu_bar.dart';
import 'package:noo/presentation/widgets/cjk_font_notice.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late List<String> probed;

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required String language,
    bool? installed = false,
  }) async {
    probed = [];
    final container = ProviderContainer(overrides: [
      cjkFontProbeProvider.overrideWithValue((code) async {
        probed.add(code);
        return installed;
      }),
      cjkFontInstallCommandProvider
          .overrideWithValue(() async => 'sudo apt install fonts-noto-cjk'),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        navigatorKey: rootNavigatorKey,
        locale: Locale(language),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => CjkFontNotice(child: child!),
        home: const Scaffold(body: Text('home')),
      ),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('warns in English when no Japanese font is installed',
      (tester) async {
    await pump(tester, language: 'ja');
    expect(probed, ['ja']);
    expect(find.text('No Japanese font installed'), findsOneWidget);
    expect(find.text('sudo apt install fonts-noto-cjk'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(CjkFontNoticeDialog), findsNothing);
  });

  testWidgets('says nothing when a font is installed, or cannot be told',
      (tester) async {
    await pump(tester, language: 'zh', installed: true);
    expect(find.byType(CjkFontNoticeDialog), findsNothing);
    await pump(tester, language: 'zh', installed: null);
    expect(find.byType(CjkFontNoticeDialog), findsNothing);
  });

  testWidgets('does not probe for languages that need no CJK font',
      (tester) async {
    await pump(tester, language: 'de');
    expect(probed, isEmpty);
  });

  testWidgets("Don't show again is remembered", (tester) async {
    await pump(tester, language: 'zh');
    await tester.tap(find.text("Don't show this again"));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(kCjkFontWarningDismissedKey), isTrue);

    await tester.pumpWidget(const SizedBox());
    await pump(tester, language: 'zh');
    expect(probed, isEmpty);
    expect(find.byType(CjkFontNoticeDialog), findsNothing);
  });

  testWidgets('Switch to English sets the interface language',
      (tester) async {
    final container = await pump(tester, language: 'ja');
    await tester.tap(find.text('Switch to English'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).appLanguage, 'en');
  });

  test('install command follows os-release', () {
    expect(cjkFontInstallCommandFor('ID=ubuntu\nID_LIKE=debian\n'),
        'sudo apt install fonts-noto-cjk');
    expect(cjkFontInstallCommandFor('ID=linuxmint\nID_LIKE="ubuntu debian"'),
        'sudo apt install fonts-noto-cjk');
    expect(cjkFontInstallCommandFor('ID=fedora\n'),
        'sudo dnf install google-noto-sans-cjk-fonts');
    expect(cjkFontInstallCommandFor('ID=endeavouros\nID_LIKE=arch\n'),
        'sudo pacman -S noto-fonts-cjk');
    expect(cjkFontInstallCommandFor('ID=nixos\n'), isNull);
  });
}
