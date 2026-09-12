import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/history_service.dart';
import 'package:noo/data/services/sync_crypto.dart';
import 'package:noo/data/services/sync_service.dart';
import 'package:noo/domain/entities/sync_config.dart';
import 'package:noo/presentation/providers/providers.dart';

/// A P2P-only user: a workspace name and a device id, and no server at all.
const _identityOnly = SyncConfig(
  enabled: true,
  username: 'alice',
  deviceId: 'device-a',
  deviceName: 'Laptop',
);

const _withRelay = SyncConfig(
  enabled: true,
  serverUrl: 'https://sync.example.com',
  username: 'alice',
  password: 'server-pw',
  deviceId: 'device-a',
);

void main() {
  // No TestWidgetsFlutterBinding: the LAN coordinator binds real sockets, and
  // the widgets binding's mock HttpClient would get in the way (see
  // lan_sync_test.dart).

  group('SyncConfig', () {
    test('identity alone configures sync, but not a relay', () {
      expect(_identityOnly.isIdentityConfigured, isTrue);
      expect(_identityOnly.isRelayConfigured, isFalse);
    });

    test('server credentials add the relay on top of identity', () {
      expect(_withRelay.isIdentityConfigured, isTrue);
      expect(_withRelay.isRelayConfigured, isTrue);
    });

    test('a relay without an identity is not configured either', () {
      // username keys the crypto (see SyncCrypto.deriveKey), so a server URL
      // on its own cannot sync anything.
      const noUsername = SyncConfig(
        enabled: true,
        serverUrl: 'https://sync.example.com',
        password: 'server-pw',
        deviceId: 'device-a',
      );
      expect(noUsername.isIdentityConfigured, isFalse);
      expect(noUsername.isRelayConfigured, isFalse);
    });

    test('sync switched off configures nothing', () {
      expect(_withRelay.copyWith(enabled: false).isIdentityConfigured, isFalse);
    });
  });

  group('providers with no server configured', () {
    late NooDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = NooDatabase.memory();
      container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        historyServiceProvider.overrideWithValue(HistoryService(db)),
        syncConfigProvider.overrideWithValue(_identityOnly),
      ]);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('there is no relay client', () {
      expect(container.read(syncApiClientProvider), isNull);
    });

    test('the sync service still exists, without a relay', () {
      final service = container.read(syncServiceProvider);
      expect(service, isNotNull,
          reason: 'LAN sync needs a SyncService; requiring a relay account '
              'for one made P2P-only use impossible');
      expect(service!.hasRelay, isFalse);
    });

    test('LAN peer sync is available', () {
      expect(container.read(lanSyncCoordinatorProvider), isNotNull);
    });
  });

  group('providers with a server configured', () {
    late NooDatabase db;
    late ProviderContainer container;

    setUp(() {
      db = NooDatabase.memory();
      container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        historyServiceProvider.overrideWithValue(HistoryService(db)),
        syncConfigProvider.overrideWithValue(_withRelay),
      ]);
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    test('the relay client is built and handed to the service', () {
      expect(container.read(syncApiClientProvider), isNotNull);
      expect(container.read(syncServiceProvider)?.hasRelay, isTrue);
    });
  });

  group('SyncService without a relay', () {
    late NooDatabase db;
    late SyncService sync;

    setUp(() {
      db = NooDatabase.memory();
      sync = SyncService(
        db: db,
        config: _identityOnly,
        crypto: SyncCrypto(),
        historyService: HistoryService(db),
        databasePassword: 'db-pw',
      );
    });

    tearDown(() => db.close());

    test('performSync reports the missing server instead of throwing',
        () async {
      final result = await sync.performSync();
      expect(result.success, isFalse);
      expect(result.error, contains('Nearby Devices'));
    });

    test('pushToRelay is a programming error, not a silent no-op', () {
      expect(sync.pushToRelay(), throwsStateError);
    });

    test('key derivation works without any server credentials', () async {
      // The sync key comes from the database password and the user name; the
      // server password is not an input (docs/P2P_SYNC.md).
      await sync.prepareCrypto();
    });
  });
}
