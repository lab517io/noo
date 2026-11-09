import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Time tracking is a preference: off for a fresh install, on for one that
/// predates the preference, and the derived answer is stored so it does not
/// change once the fresh install opens its first database. Also the relay
/// URL default, which only applies to a key never written.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
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

  /// Settings as loaded from [prefs]. The load is finished once the
  /// derived time-tracking flag has been written back — the last await.
  Future<ProviderContainer> settingsFrom(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(settingsProvider);
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return container;
  }

  test('a fresh install starts without time tracking, and stays so', () async {
    final container = await settingsFrom({});
    expect(container.read(settingsProvider).timeTrackingEnabled, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(SettingsKeys.timeTrackingEnabled), isFalse,
        reason: 'stored, so a database opened later does not turn it on');
  });

  test('an install that has opened a database keeps time tracking', () async {
    final container =
        await settingsFrom({SettingsKeys.lastDatabasePath: '/tmp/a.noo'});
    expect(container.read(settingsProvider).timeTrackingEnabled, isTrue);
  });

  test('a stored choice wins over the derived default', () async {
    final container = await settingsFrom({
      SettingsKeys.lastDatabasePath: '/tmp/a.noo',
      SettingsKeys.timeTrackingEnabled: false,
    });
    expect(container.read(settingsProvider).timeTrackingEnabled, isFalse);
  });

  test('turning it on is stored and rolls back with Cancel', () async {
    final container = await settingsFrom({});
    final notifier = container.read(settingsProvider.notifier);
    final snapshot = container.read(settingsProvider);

    await notifier.setTimeTrackingEnabled(true);
    expect(container.read(settingsProvider).timeTrackingEnabled, isTrue);

    await notifier.restorePreferences(snapshot);
    expect(container.read(settingsProvider).timeTrackingEnabled, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(SettingsKeys.timeTrackingEnabled), isFalse);
  });

  test('the relay URL defaults to the hosted relay', () async {
    final container = await settingsFrom({});
    expect(container.read(settingsProvider).syncServerUrl,
        AppSettings.kDefaultRelayUrl);
  });

  test('a relay URL the user cleared stays empty', () async {
    final container = await settingsFrom({SettingsKeys.syncServerUrl: ''});
    expect(container.read(settingsProvider).syncServerUrl, '');
  });
}
