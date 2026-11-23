import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/theme/app_theme.dart';
import 'package:noo/l10n/l10n.dart';
import 'package:noo/presentation/providers/audio_device_provider.dart';
import 'package:noo/presentation/providers/voice_memo_provider.dart';
import 'package:noo/presentation/widgets/app_menu_bar.dart';
import 'package:noo/presentation/widgets/dialogs/preferences_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/audio/audio_fakes.dart';

/// The translated interface has to fit where the English one does: German
/// runs a third longer, and a caption that fits in English can overflow its
/// row. Pumps the densest surfaces — every Preferences tab, desktop and phone
/// width, and the menu bar — in every language, failing on any overflow.
///
/// As in `preferences_dialog_test.dart`, `flutter test` draws every glyph a
/// full em wide, so this is stricter than a real screen for Latin text.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const secureStorage =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  const windowManager = MethodChannel('window_manager');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    messenger.setMockMethodCallHandler(secureStorage, (call) async {
      return switch (call.method) {
        'readAll' => <String, String>{},
        'containsKey' => false,
        _ => null,
      };
    });
    messenger.setMockMethodCallHandler(windowManager, (call) async {
      return call.method == 'isMaximized' ? false : null;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(secureStorage, null);
    messenger.setMockMethodCallHandler(windowManager, null);
    updateAppLocale(const Locale('en'));
  });

  Widget app(Locale locale, Widget home) {
    updateAppLocale(locale);
    return ProviderScope(
      overrides: [
        audioDeviceSourceProvider.overrideWithValue(FakeAudioDeviceSource()),
        whisperServiceProvider.overrideWithValue(FakeWhisper(present: false)),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(body: home),
      ),
    );
  }

  for (final locale in AppLocalizations.supportedLocales) {
    final code = locale.languageCode;

    for (final size in const [Size(1280, 900), Size(360, 800)]) {
      testWidgets('[$code] every Preferences tab fits ${size.width}dp',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        for (var tab = 0; tab < 5; tab++) {
          await tester
              .pumpWidget(app(locale, PreferencesDialog(initialTab: tab)));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: '$code tab $tab overflowed at ${size.width}dp');
          // The tabs are labelled in this language, not in English: the
          // test would prove nothing if the translation never loaded.
          expect(find.text(lookupAppLocalizations(locale).prefsTabAppearance),
              findsWidgets);
          await tester.drag(
            find.byType(SingleChildScrollView).last,
            const Offset(0, -3000),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: '$code tab $tab overflowed below the fold');
        }
      });
    }

    testWidgets('[$code] the menu bar fits a 1024dp window', (tester) async {
      tester.view.physicalSize = const Size(1024, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
          app(locale, const AppMenuBar(child: SizedBox.expand())));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
