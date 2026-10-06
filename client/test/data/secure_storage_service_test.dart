import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/services/secure_storage_service.dart';

/// Every secret lives in one keychain item, because macOS asks once per item
/// whenever the (ad-hoc signed) app has changed — three items meant three
/// prompts after each update. These cover the bundle and the move of items
/// saved before it existed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  /// service → key → value. The service is the macOS `accountName`, so the
  /// app's own service and the plugin's default one are kept apart the way
  /// the keychain keeps them.
  late Map<String, Map<String, String>> keychain;
  late List<String> reads;

  Map<String, String> slot(MethodCall call) {
    final options = (call.arguments['options'] as Map?) ?? const {};
    return keychain.putIfAbsent(
      options['accountName'] as String? ?? '',
      () => {},
    );
  }

  setUp(() {
    // The plugin picks its options by target platform, which is Android
    // under `flutter test`; macOS is the one that prompts per item.
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    keychain = {};
    reads = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final key = call.arguments['key'] as String?;
          switch (call.method) {
            case 'read':
              final value = slot(call)[key];
              if (value != null) reads.add(key!);
              return value;
            case 'write':
              slot(call)[key!] = call.arguments['value'] as String;
              return null;
            case 'delete':
              slot(call).remove(key);
              return null;
            case 'deleteAll':
              slot(call).clear();
              return null;
          }
          return null;
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  /// Every item, whichever service holds it, keyed by its account.
  Map<String, String> items() => {for (final s in keychain.values) ...s};

  Map<String, dynamic> bundle() =>
      jsonDecode(items()['secrets']!) as Map<String, dynamic>;

  test('all secrets go into one item', () async {
    final storage = SecureStorageService();
    await storage.savePassword('db', dbPath: '/a.noo');
    await storage.saveServerPassword('server');
    await storage.saveMcpToken('token');

    expect(items().keys, ['secrets']);
    expect(bundle().values, containsAll(['db', 'server', 'token']));

    expect(await storage.getPassword(dbPath: '/a.noo'), 'db');
    expect(await storage.getServerPassword(), 'server');
    expect(await storage.getMcpToken(), 'token');
  });

  test('concurrent writes from separate instances all land', () async {
    await Future.wait([
      SecureStorageService().savePassword('db', dbPath: '/a.noo'),
      SecureStorageService().saveServerPassword('server'),
      SecureStorageService().saveMcpToken('token'),
    ]);
    expect(bundle(), hasLength(3));
  });

  test('a separate item from before the bundle moves into it, once', () async {
    // Written by an older build: the server password under the app's
    // service, the MCP token under the plugin's default one.
    final old = SecureStorageService();
    keychain['Noo'] = {'sync_server_password': 'server'};
    keychain['flutter_secure_storage_service'] = {'mcp_token': 'token'};

    expect(await old.getServerPassword(), 'server');
    expect(await old.getMcpToken(), 'token');
    expect(items().keys, ['secrets']);

    reads.clear();
    expect(await old.getServerPassword(), 'server');
    expect(await old.getMcpToken(), 'token');
    expect(reads, [
      'secrets',
      'secrets',
    ], reason: 'only the bundle is read once the items have moved');
  });

  test('a deleted secret does not come back from an older item', () async {
    final storage = SecureStorageService();
    await storage.saveMcpToken('new');
    keychain['Noo']!['mcp_token'] = 'stale';

    await storage.deleteMcpToken();
    expect(await storage.getMcpToken(), isNull);
  });

  test('the shared legacy password is offered, then adopted', () async {
    keychain['Noo'] = {'database_password': 'legacy'};
    final storage = SecureStorageService();

    expect(await storage.getPassword(dbPath: '/a.noo'), 'legacy');
    expect(await storage.isLegacyPassword(dbPath: '/a.noo'), isTrue);

    await storage.adoptLegacyPassword(dbPath: '/a.noo');
    expect(await storage.isLegacyPassword(dbPath: '/a.noo'), isFalse);
    expect(await storage.getPassword(dbPath: '/a.noo'), 'legacy');
    expect(await storage.getPassword(dbPath: '/b.noo'), isNull);
  });

  test('a keychain that refuses writes degrades to "not remembered"', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'write') throw PlatformException(code: 'locked');
          return null;
        });
    final storage = SecureStorageService();
    await storage.saveServerPassword('server');
    expect(await storage.getServerPassword(), isNull);
  });

  test('off macOS each secret stays its own item', () async {
    // Nothing prompts per item there, so nothing is migrated.
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final storage = SecureStorageService();
    await storage.saveServerPassword('server');
    await storage.saveMcpToken('token');

    expect(items(), {'sync_server_password': 'server', 'mcp_token': 'token'});
    expect(await storage.getMcpToken(), 'token');
  });
}
