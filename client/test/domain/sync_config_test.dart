import 'package:flutter_test/flutter_test.dart';
import 'package:noo/domain/entities/sync_config.dart';

void main() {
  group('SyncConfig equality', () {
    const a = SyncConfig(
      enabled: true,
      serverUrl: 'https://relay.example',
      username: 'alice',
      password: 'secret',
      deviceId: 'dev-1',
      deviceName: 'Laptop',
      autoSyncIntervalMinutes: 5,
    );

    test('two configs built from the same settings are equal', () {
      // syncConfigProvider rebuilds a fresh instance on every settings write;
      // equality is what stops the relay client, the auto-sync timer and the
      // LAN coordinator from being torn down by an unrelated preference edit.
      const b = SyncConfig(
        enabled: true,
        serverUrl: 'https://relay.example',
        username: 'alice',
        password: 'secret',
        deviceId: 'dev-1',
        deviceName: 'Laptop',
        autoSyncIntervalMinutes: 5,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a.copyWith(), equals(a));
    });

    test('any sync field changing makes them unequal', () {
      expect(a.copyWith(serverUrl: 'https://other.example'), isNot(equals(a)));
      expect(a.copyWith(username: 'bob'), isNot(equals(a)));
      expect(a.copyWith(password: 'other'), isNot(equals(a)));
      expect(a.copyWith(deviceId: 'dev-2'), isNot(equals(a)));
      expect(a.copyWith(deviceName: 'Desktop'), isNot(equals(a)));
      expect(a.copyWith(autoSyncIntervalMinutes: 10), isNot(equals(a)));
      expect(a.copyWith(enabled: false), isNot(equals(a)));
    });
  });
}
