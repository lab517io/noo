import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `restorePreferences` is what Preferences → Cancel (and Esc, and a click
/// outside) runs. "Reset device identity" lives on the Sync tab and writes the
/// new id through the same notifier; leaving the dialog any way but OK must
/// not put the forked id back, or the next sync republishes under it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('restoring a snapshot keeps the device id written after it', () async {
    SharedPreferences.setMockInitialValues({
      SettingsKeys.syncDeviceId: 'forked-id',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // The notifier's initial load goes through the keychain plugin's method
    // channel as well as SharedPreferences, so wait for it rather than for a
    // fixed number of event-loop turns.
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (container.read(settingsProvider).syncDeviceId == null) {
      if (DateTime.now().isAfter(deadline)) fail('settings never loaded');
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(container.read(settingsProvider).syncDeviceId, 'forked-id');

    final snapshot = container.read(settingsProvider);
    final notifier = container.read(settingsProvider.notifier);
    await notifier.setSyncDeviceId('fresh-id');
    await notifier.setShowSeconds(!snapshot.showSeconds);

    await notifier.restorePreferences(snapshot);

    final restored = container.read(settingsProvider);
    // The preference rolled back; the identity did not.
    expect(restored.showSeconds, snapshot.showSeconds);
    expect(restored.syncDeviceId, 'fresh-id');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(SettingsKeys.syncDeviceId), 'fresh-id');
  });
}
