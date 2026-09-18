import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/theme/app_theme.dart';
import 'package:noo/presentation/providers/audio_device_provider.dart';
import 'package:noo/presentation/providers/voice_memo_provider.dart';
import 'package:noo/presentation/providers/settings_provider.dart';
import 'package:noo/presentation/widgets/dialogs/classic_form.dart';
import 'package:noo/presentation/widgets/dialogs/preferences_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/audio/audio_fakes.dart';

/// Covers the preferences dialog's layout at both the default UI font size and
/// the largest scale Appearance offers (failing on any overflow), and its
/// OK / Cancel semantics — edits apply live, so Cancel has to roll them back.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The sync server password lives in the keychain, so Cancel's rollback goes
  // through this channel. Left unmocked it never answers inside fake async,
  // and the rollback — plus the pop that follows it — hangs forever.
  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
      return switch (call.method) {
        'readAll' => <String, String>{},
        'containsKey' => false,
        _ => null,
      };
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  Future<void> pumpDialog(
    WidgetTester tester, {
    required int tab,
    double fontSizeFactor = 1.0,
    Size size = const Size(1280, 900),
    FakeWhisper? whisper,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Otherwise the Voice memos tab reaches for the real audio engine,
          // which has no native library under `flutter test`, and the device
          // rows would only ever be exercised in their error state.
          audioDeviceSourceProvider.overrideWithValue(FakeAudioDeviceSource()),
          // The real service reaches the whisper plugin's channel when the
          // container is disposed, which throws at teardown here — and a test
          // that pressed Download would otherwise fetch 141MB from HuggingFace.
          whisperServiceProvider
              .overrideWithValue(whisper ?? FakeWhisper(present: false)),
        ],
        child: MaterialApp(
          theme: chromeScaledTheme(
            AppTheme.light,
            family: null,
            scale: fontSizeFactor,
          ),
          home: Scaffold(
            body: PreferencesDialog(initialTab: tab),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Drag the Sync tab down to the storage group, which sits below the fold.
  Future<void> scrollToServerStorage(WidgetTester tester) async {
    await tester.dragUntilVisible(
      find.text('Server storage'),
      find.byType(SingleChildScrollView).last,
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();
  }

  for (final factor in [1.0, 1.5]) {
    testWidgets('Appearance tab lays out at ${factor}x', (tester) async {
      await pumpDialog(tester, tab: 0, fontSizeFactor: factor);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Mode:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Behavior tab lays out at ${factor}x', (tester) async {
      await pumpDialog(tester, tab: 1, fontSizeFactor: factor);
      expect(find.text('Editor'), findsOneWidget);
      expect(find.text('Insert tabs as spaces'), findsOneWidget);
      expect(find.text('Paste:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Voice memos tab lays out at ${factor}x', (tester) async {
      await pumpDialog(tester, tab: 2, fontSizeFactor: factor);
      expect(find.text('Devices'), findsOneWidget);
      expect(find.text('Microphone:'), findsOneWidget);
      expect(find.text('Speaker:'), findsOneWidget);
      expect(find.text('Transcription'), findsOneWidget);
      expect(find.text('Model:'), findsOneWidget);
      expect(find.text('Language:'), findsOneWidget);
      expect(find.text('Check'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Test'), findsOneWidget);
      expect(find.text('Transcribe after recording'), findsOneWidget);
      // Nothing downloads by itself: with no model selected there is no
      // Download button on screen at all.
      expect(find.text('Download'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sync tab lays out at ${factor}x', (tester) async {
      await pumpDialog(tester, tab: 3, fontSizeFactor: factor);
      // Identity is what every sync path needs; the server is the optional
      // extra on top of it, and says so.
      expect(find.text('Identity'), findsOneWidget);
      expect(find.text('User name:'), findsOneWidget);
      expect(find.text('Sync server (optional)'), findsOneWidget);
      expect(find.text('Server URL:'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Storage lives further down the tab; scrolling there is also what
      // catches an overflow in the rows it adds.
      await scrollToServerStorage(tester);
      expect(find.text('Server storage'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MCP tab lays out at ${factor}x', (tester) async {
      await pumpDialog(tester, tab: 4, fontSizeFactor: factor);
      expect(find.text('Agent access'), findsOneWidget);
      expect(find.text('Port:'), findsOneWidget);
      // The token row carries two icon buttons inside a dense field, which is
      // the most plausible thing here to overflow at the largest UI scale.
      expect(tester.takeException(), isNull);
    });
  }

  // ---------- Phone widths ----------
  //
  // The dialog goes full-screen below 600dp, but full-screen only helps if the
  // content stops assuming a 520dp property sheet: a group box on a 360dp
  // phone is ~290dp wide, which is barely more than the label column plus a
  // control. These pump every tab at the narrowest phones and at the largest
  // UI scale on top, and fail on any overflow.
  //
  // Note the bar is stricter than a real device: `flutter test` renders with a
  // font whose every glyph is a full em, so captions here are wider than the
  // ones a phone actually draws.
  for (final width in [320.0, 360.0]) {
    for (final factor in [1.0, 1.5]) {
      testWidgets('Sync tab fits a ${width}dp screen at ${factor}x', (
        tester,
      ) async {
        await pumpDialog(
          tester,
          tab: 3,
          fontSizeFactor: factor,
          size: Size(width, 800),
        );

        // Stacked or not, the rows keep their captions, so the same finders
        // work at every width.
        expect(find.text('User name:'), findsOneWidget);
        expect(find.text('Server URL:'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await scrollToServerStorage(tester);
        expect(find.text('Server storage'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('every tab fits a ${width}dp screen at ${factor}x', (
        tester,
      ) async {
        for (final tab in [0, 1, 2, 4]) {
          await pumpDialog(
            tester,
            tab: tab,
            fontSizeFactor: factor,
            size: Size(width, 800),
          );
          // Drag well past the end so the rows below the fold lay out too.
          await tester.drag(
            find.byType(SingleChildScrollView).last,
            const Offset(0, -2000),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: 'tab $tab overflowed at ${width}dp / ${factor}x');
        }
      });
    }
  }

  // The rows that only exist mid-action — a download in flight, a model on
  // disk — are the ones a plain pump never reaches, and the download row is
  // where Cancel ran off the side of a phone.
  testWidgets('a download in flight keeps Cancel on a 360dp screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'voice_memo_model': 'base'});
    final whisper = FakeWhisper(present: false);

    await pumpDialog(
      tester,
      tab: 2,
      size: const Size(360, 800),
      whisper: whisper,
    );

    await tester.dragUntilVisible(
      find.widgetWithText(FilledButton, 'Download'),
      find.byType(SingleChildScrollView).last,
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();

    // The fake reports progress and then hangs, which is exactly the state the
    // row has to render.
    await tester.tap(find.widgetWithText(FilledButton, 'Download'));
    await tester.pumpAndSettle();

    final cancel = find.widgetWithText(OutlinedButton, 'Cancel');
    expect(cancel, findsOneWidget);
    expect(tester.takeException(), isNull);
    // The complaint was not that it overflowed a Row — it was that the button
    // was off the screen, so check the screen.
    expect(tester.getRect(cancel).right, lessThanOrEqualTo(360.0));

    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(whisper.downloadCancelled, isTrue);
  });

  testWidgets('a model already on disk offers Remove on a 360dp screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'voice_memo_model': 'base'});

    await pumpDialog(
      tester,
      tab: 2,
      size: const Size(360, 800),
      whisper: FakeWhisper(present: true),
    );

    final remove = find.widgetWithText(OutlinedButton, 'Remove');
    await tester.dragUntilVisible(
      remove,
      find.byType(SingleChildScrollView).last,
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(tester.getRect(remove).right, lessThanOrEqualTo(360.0));
  });

  testWidgets('Server storage explains itself when there is no server', (
    tester,
  ) async {
    await pumpDialog(tester, tab: 3);
    await scrollToServerStorage(tester);

    // Nothing is stored remotely in a LAN-only setup, so the tab says so
    // rather than offering a command with nothing to talk to.
    expect(find.textContaining('Nothing is stored on a server'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Compact data on server'),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Server storage offers compaction once a server is configured', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'sync_enabled': true,
      'sync_server_url': 'https://sync.example.com',
      'sync_username': 'alice',
      'sync_device_id': 'device-a',
      // The legacy plain-text key; the notifier migrates it into the keychain
      // on load, which the mocked channel accepts without storing anything.
      'sync_password': 'server-pw',
    });

    await pumpDialog(tester, tab: 3);
    await scrollToServerStorage(tester);

    // Usage costs a round trip, so it is read on demand, not on open.
    expect(find.text('Press Refresh to read the current usage.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Compact data on server'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Scrolling the Appearance tab reaches the last group', (
    tester,
  ) async {
    await pumpDialog(tester, tab: 0);
    await tester.drag(find.text('Preview:'), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Scale:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // ---------- OK / Cancel ----------

  /// Opens the dialog from a host app so it lives on a real dialog route, and
  /// hands back the container the settings can be read from.
  Future<ProviderContainer> showDialogFrom(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => const PreferencesDialog(),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return container;
  }

  /// Taps the Dark theme radio, which applies immediately.
  Future<void> selectDarkTheme(WidgetTester tester) async {
    await tester.tap(find.byType(Radio<ThemeMode>).at(2));
    await tester.pumpAndSettle();
  }

  testWidgets('OK keeps the live-applied edit', (tester) async {
    final container = await showDialogFrom(tester);
    expect(container.read(settingsProvider).themeMode, ThemeMode.system);

    await selectDarkTheme(tester);
    expect(container.read(settingsProvider).themeMode, ThemeMode.dark);

    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await tester.pumpAndSettle();

    expect(find.byType(PreferencesDialog), findsNothing);
    expect(container.read(settingsProvider).themeMode, ThemeMode.dark);
    expect(
      (await SharedPreferences.getInstance()).getInt(SettingsKeys.themeMode),
      ThemeMode.dark.index,
    );
  });

  testWidgets('Cancel rolls the edit back, in memory and on disk',
      (tester) async {
    final container = await showDialogFrom(tester);

    await selectDarkTheme(tester);
    expect(container.read(settingsProvider).themeMode, ThemeMode.dark);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(PreferencesDialog), findsNothing);
    expect(container.read(settingsProvider).themeMode, ThemeMode.system);
    expect(
      (await SharedPreferences.getInstance()).getInt(SettingsKeys.themeMode),
      ThemeMode.system.index,
    );
  });

  testWidgets('The paste mode applies live and rolls back on Cancel',
      (tester) async {
    final container = await showDialogFrom(tester);
    expect(container.read(settingsProvider).pasteFormatting,
        PasteFormatting.keep);

    await tester.tap(find.text('Behavior'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ClassicDropdown<PasteFormatting>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plain text only').last);
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).pasteFormatting,
        PasteFormatting.plainText);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(container.read(settingsProvider).pasteFormatting,
        PasteFormatting.keep);
    expect(
      (await SharedPreferences.getInstance())
          .getString(SettingsKeys.editorPasteFormatting),
      PasteFormatting.keep.name,
    );
  });

  testWidgets('Esc cancels rather than keeping the edit', (tester) async {
    final container = await showDialogFrom(tester);

    await selectDarkTheme(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(PreferencesDialog), findsNothing);
    expect(container.read(settingsProvider).themeMode, ThemeMode.system);
  });

  testWidgets('Cancel rolls back the MCP settings too', (tester) async {
    final container = await showDialogFrom(tester);
    expect(container.read(settingsProvider).mcpEnabled, isFalse);

    await tester.tap(find.text('MCP'));
    await tester.pumpAndSettle();
    // The label, not the ClassicCheckbox: that widget is a narrow tappable row
    // stacked above a wider hint, so its centre lands in the hint and misses.
    await tester.tap(find.text('Enable MCP server'));
    await tester.pumpAndSettle();

    final edited = container.read(settingsProvider);
    expect(edited.mcpEnabled, isTrue);
    // Enabling mints a token, so the common path is one click rather than a
    // toggle plus a button.
    expect(edited.mcpToken, isNotNull);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    // Both halves matter: a setting missing from restorePreferences rolls back
    // in memory via the snapshot but stays written to disk, and nothing else
    // fails loudly when it does.
    expect(container.read(settingsProvider).mcpEnabled, isFalse);
    expect(
      (await SharedPreferences.getInstance()).getBool(SettingsKeys.mcpEnabled),
      isFalse,
    );
  });

  testWidgets('Cancel also restores font settings', (tester) async {
    final container = await showDialogFrom(tester);
    final before = container.read(settingsProvider);

    await tester.tap(find.widgetWithText(ClassicCheckbox, 'Bold'));
    await tester.tap(find.byIcon(Icons.arrow_drop_up).first);
    await tester.pumpAndSettle();

    final edited = container.read(settingsProvider);
    expect(edited.fontBold, isTrue);
    expect(edited.fontSize, before.fontSize + 1);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    final after = container.read(settingsProvider);
    expect(after.fontBold, before.fontBold);
    expect(after.fontSize, before.fontSize);
  });
}
