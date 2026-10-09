/// The model download row of Preferences → Voice memos, across tab switches.
///
/// The "Voice memos" tab is a `TabBarView` page, disposed the moment the user
/// looks at another tab. A download whose state lived in that page's `State`
/// kept running in the service, but the page that came back showed "Not
/// downloaded" and offered Download again — a second writer on the same
/// `.part` file. The state now lives in `modelDownloadProvider`, and these
/// tests are what pin that down.
@TestOn('vm')
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/presentation/providers/audio_device_provider.dart';
import 'package:noo/presentation/providers/model_download_provider.dart';
import 'package:noo/presentation/providers/voice_memo_provider.dart';
import 'package:noo/presentation/widgets/dialogs/preferences_dialog.dart';
import 'package:noo/presentation/widgets/dialogs/voice_memo_settings_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/audio/audio_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The Sync tab's settings reach the keychain; left unmocked the channel
  // never answers inside fake async.
  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  late FakeWhisper whisper;

  setUp(() {
    SharedPreferences.setMockInitialValues({'voice_memo_model': 'base'});
    whisper = FakeWhisper(present: false);
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

  /// The dialog on its Voice memos tab, desktop-sized.
  Future<ProviderContainer> pumpDialog(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(overrides: [
      audioDeviceSourceProvider.overrideWithValue(FakeAudioDeviceSource()),
      whisperServiceProvider.overrideWithValue(whisper),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: PreferencesDialog(initialTab: 2)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// The form's own Cancel — the dialog has one of its own at the bottom.
  Finder formCancel() => find.descendant(
        of: find.byType(VoiceMemoSettingsForm),
        matching: find.widgetWithText(OutlinedButton, 'Cancel'),
      );

  Finder download() => find.widgetWithText(FilledButton, 'Download');

  Future<void> switchTo(WidgetTester tester, String tab) async {
    await tester.tap(find.descendant(
      of: find.byType(TabBar),
      matching: find.text(tab),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('a download in flight is still there after a tab switch',
      (tester) async {
    final container = await pumpDialog(tester);

    await tester.tap(download());
    await tester.pumpAndSettle();
    expect(formCancel(), findsOneWidget);
    expect(find.textContaining('% of'), findsOneWidget);

    // Away, and back. The page is rebuilt from scratch in between.
    await switchTo(tester, 'Sync');
    expect(find.byType(VoiceMemoSettingsForm), findsNothing);
    await switchTo(tester, 'Voice memos');

    expect(formCancel(), findsOneWidget, reason: 'the bar came back');
    expect(find.textContaining('% of'), findsOneWidget);
    expect(download(), findsNothing,
        reason: 'a second Download would be a second writer');
    expect(container.read(modelDownloadProvider).isDownloadingModel(
            container.read(modelDownloadProvider).model!),
        isTrue);

    whisper.completeDownload();
    await tester.pumpAndSettle();

    expect(whisper.downloads, 1);
    expect(find.text('Base is downloaded and ready.'), findsOneWidget);
    expect(formCancel(), findsNothing);
    expect(container.read(modelDownloadProvider).isDownloading, isFalse);
  });

  testWidgets('Cancel after coming back stops the download that was started',
      (tester) async {
    await pumpDialog(tester);

    await tester.tap(download());
    await tester.pumpAndSettle();
    await switchTo(tester, 'Sync');
    await switchTo(tester, 'Voice memos');

    await tester.tap(formCancel());
    await tester.pumpAndSettle();

    expect(whisper.downloadCancelled, isTrue);
    expect(find.text('Download cancelled.'), findsOneWidget);
    expect(download(), findsOneWidget, reason: 'free to try again');
  });

  testWidgets('a download that outlives the dialog is still reported',
      (tester) async {
    // Closing Preferences does not stop the download — the service runs it
    // to the end — and the outcome has to be waiting when the tab is opened
    // again rather than lost with the widget that started it.
    final container = await pumpDialog(tester);
    await tester.tap(download());
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: SizedBox())),
      ),
    );
    await tester.pumpAndSettle();
    expect(container.read(modelDownloadProvider).isDownloading, isTrue);

    whisper.completeDownload();
    await tester.pumpAndSettle();
    expect(container.read(modelDownloadProvider).isDownloading, isFalse);
    expect(container.read(modelDownloadProvider).error, isNull);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: PreferencesDialog(initialTab: 2)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Base is downloaded and ready.'), findsOneWidget);
  });
}
