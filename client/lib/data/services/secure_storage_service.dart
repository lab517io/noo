import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keys for secure storage
class SecureStorageKeys {
  SecureStorageKeys._();

  static const String databasePassword = 'database_password';
  static const String serverPassword = 'sync_server_password';

  /// Bearer token local coding agents present to the MCP server.
  ///
  /// Scoped to the app rather than to a database file, unlike
  /// [databasePassword]: the token is pasted into agent config files by hand,
  /// and per-database tokens would mean reconfiguring every agent on each
  /// database switch. The consequence — an agent configured while one database
  /// was open reaches whichever one is open later — is documented in the MCP
  /// preferences tab.
  static const String mcpToken = 'mcp_token';
}

/// Service for securely storing sensitive data using platform keychain/keyring
class SecureStorageService {
  /// `kSecAttrService` for this app's keychain items on macOS.
  ///
  /// Without it the plugin stores everything under its own default,
  /// `flutter_secure_storage_service` — which is the name macOS shows in
  /// Keychain Access and in the "wants to use your confidential information
  /// stored in ..." prompt, telling the user nothing about whose data it is.
  static const String _keychainService = 'Noo';

  /// The default data-protection keychain requires an
  /// application-identifier/keychain entitlement that this app doesn't have
  /// (unsandboxed + ad-hoc signed): writes fail with errSecMissingEntitlement
  /// (-34018). The legacy file-based keychain has no such requirement.
  /// Ignored on platforms other than macOS.
  static const MacOsOptions _macOptions = MacOsOptions(
    accountName: _keychainService,
    usesDataProtectionKeychain: false,
  );

  /// Items written before [_keychainService] existed live under the plugin's
  /// default service name. [_read] moves them into the bundle on first
  /// access, so an upgrade doesn't lose saved passwords or the MCP token.
  static const MacOsOptions _legacyMacOptions = MacOsOptions(
    usesDataProtectionKeychain: false,
  );

  final FlutterSecureStorage _storage;
  final FlutterSecureStorage _legacyStorage;

  SecureStorageService()
    : _storage = const FlutterSecureStorage(mOptions: _macOptions),
      _legacyStorage = const FlutterSecureStorage(mOptions: _legacyMacOptions);

  /// The one keychain item every secret lives in, as a JSON object of
  /// key → value.
  ///
  /// One item rather than one per secret because of how macOS guards them:
  /// each item has its own access list, and this app is ad-hoc signed, so its
  /// identity is the hash of its binary and every update is a stranger to all
  /// of them. Startup reads three secrets — the database password, the sync
  /// server password and the MCP token — and with three items that was three
  /// "wants to use your confidential information" prompts after each update,
  /// "Always Allow" or not. With one item it is one prompt; with a stable
  /// signing identity it would be none.
  ///
  /// macOS only — see [_bundled].
  static const String _bundleKey = 'secrets';

  /// Whether secrets go into the [_bundleKey] item. Only macOS asks per item;
  /// Secret Service and the Windows store do not prompt at all, so there each
  /// secret stays the separate item it always was and nothing is migrated.
  static bool get _bundled =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  /// Serializes every operation, across instances: a write is a
  /// read-modify-write of the whole bundle, so two of them interleaved would
  /// lose one. Static because the service is constructed in more than one
  /// place (see `SettingsNotifier._secureStorage`). Separate items need no
  /// such thing, so off macOS calls go straight through.
  static Future<void> _queue = Future.value();

  Future<T> _locked<T>(Future<T> Function() body) {
    if (!_bundled) return body();
    final result = _queue.then((_) => body());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<Map<String, String>> _loadBundle() async {
    final raw = await _storage.read(key: _bundleKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return {
          for (final e in decoded.entries)
            if (e.value is String) e.key as String: e.value as String,
        };
      }
    } on FormatException {
      // Unreadable: treated as empty, and replaced by the next write.
    }
    return {};
  }

  Future<void> _storeBundle(Map<String, String> bundle) =>
      _storage.write(key: _bundleKey, value: jsonEncode(bundle));

  /// Read [key]. Call under [_locked].
  ///
  /// Secrets saved before the bundle existed are separate items, either under
  /// [_keychainService] or under the plugin's default service from before
  /// that. One found there is moved into the bundle and its item deleted, so
  /// the prompt it costs is the last one for it. Per-database passwords are
  /// keyed by a hash of the path, so they cannot be enumerated up front —
  /// each moves the first time its database is opened. Looking up an item
  /// that does not exist does not prompt, so the fallback is free once
  /// everything has moved.
  ///
  /// Off macOS: the separate item, adopted out of the plugin's default
  /// service if that is where it still is.
  Future<String?> _read(String key) async {
    if (!_bundled) {
      final current = await _storage.read(key: key);
      if (current != null) return current;
      final legacy = await _legacyStorage.read(key: key);
      if (legacy == null) return null;
      await _storage.write(key: key, value: legacy);
      await _legacyStorage.delete(key: key);
      return legacy;
    }

    final bundle = await _loadBundle();
    final bundled = bundle[key];
    if (bundled != null) return bundled;

    final separate =
        await _storage.read(key: key) ?? await _legacyStorage.read(key: key);
    if (separate == null) return null;

    try {
      await _storeBundle({...bundle, key: separate});
    } on PlatformException {
      // Keep it where it is; the next read tries again.
      return separate;
    }
    await _deleteSeparate(key);
    return separate;
  }

  /// Store [value] under [key]. Call under [_locked].
  Future<void> _put(String key, String value) async {
    if (!_bundled) return _storage.write(key: key, value: value);
    final bundle = await _loadBundle();
    await _storeBundle({...bundle, key: value});
    // An older copy left as a separate item would come back through [_read]'s
    // fallback if this key were ever removed from the bundle.
    await _deleteSeparate(key);
  }

  /// Remove [key], from the bundle and from any separate item that predates
  /// it — otherwise [_read]'s fallback would bring it back. Call under
  /// [_locked].
  Future<void> _remove(String key) async {
    if (!_bundled) {
      await _storage.delete(key: key);
      await _legacyStorage.delete(key: key);
      return;
    }
    final bundle = await _loadBundle();
    if (bundle.remove(key) != null) await _storeBundle(bundle);
    await _deleteSeparate(key);
  }

  Future<void> _deleteSeparate(String key) async {
    try {
      await _storage.delete(key: key);
      await _legacyStorage.delete(key: key);
    } on PlatformException {
      // The value is safe in the bundle, which [_read] consults first.
    }
  }

  /// Per-database key for the stored password. Different database files must
  /// use different slots — otherwise switching databases autofills the wrong
  /// password and an auth failure clears the other database's saved password.
  /// A null path falls back to the legacy shared key for backward compat.
  String _passwordKey(String? dbPath) {
    if (dbPath == null || dbPath.isEmpty) {
      return SecureStorageKeys.databasePassword;
    }
    final hash = sha256.convert(utf8.encode(dbPath)).toString();
    return '${SecureStorageKeys.databasePassword}:$hash';
  }

  /// Save the database password securely, scoped to [dbPath].
  /// Best-effort: a keychain failure means the password just isn't remembered;
  /// it must never abort the caller (this runs mid-startup).
  Future<void> savePassword(String password, {String? dbPath}) async {
    try {
      await _locked(() => _put(_passwordKey(dbPath), password));
    } on PlatformException {
      // Degrade to "not remembered" — the user is prompted next launch.
    }
  }

  /// Retrieve the saved database password for [dbPath].
  /// Returns null if no password is saved.
  ///
  /// Backward compatibility: databases whose password was saved before
  /// per-database keying existed live under the shared legacy key. When the
  /// per-database slot is empty the legacy password is offered as a
  /// candidate — offered, not adopted: the shared slot does not say which
  /// database it belongs to, so whether it is this one is only known once it
  /// has opened the file. [adoptLegacyPassword] moves it then. Adopting it
  /// here handed the legacy password to whichever database was opened first
  /// after the upgrade, and its real owner lost it.
  Future<String?> getPassword({String? dbPath}) async {
    final key = _passwordKey(dbPath);
    try {
      return await _locked(() async {
        final scoped = await _read(key);
        if (scoped != null) return scoped;

        if (key != SecureStorageKeys.databasePassword) {
          return await _read(SecureStorageKeys.databasePassword);
        }
        return null;
      });
    } on PlatformException {
      // A locked or unavailable keyring (surfaced as a PlatformException since
      // flutter_secure_storage_linux 3.0.1) degrades to "no saved password" so
      // the caller falls back to prompting instead of crashing startup.
      return null;
    }
  }

  /// Whether the password [getPassword] returned for [dbPath] came from the
  /// shared legacy slot rather than the database's own — see
  /// [adoptLegacyPassword].
  Future<bool> isLegacyPassword({String? dbPath}) async {
    final key = _passwordKey(dbPath);
    if (key == SecureStorageKeys.databasePassword) return false;
    try {
      return await _locked(
        () async =>
            await _read(key) == null &&
            await _read(SecureStorageKeys.databasePassword) != null,
      );
    } on PlatformException {
      return false;
    }
  }

  /// File the legacy shared password under [dbPath]'s own slot and retire the
  /// shared one. Called only after that password has opened [dbPath], which is
  /// the one proof of ownership there is; a legacy password that failed to
  /// open a database is left where it was, for the database it does belong to.
  Future<void> adoptLegacyPassword({required String dbPath}) async {
    final key = _passwordKey(dbPath);
    if (key == SecureStorageKeys.databasePassword) return;
    try {
      await _locked(() async {
        if (await _read(key) != null) return;
        final legacy = await _read(SecureStorageKeys.databasePassword);
        if (legacy == null) return;
        await _put(key, legacy);
        await _remove(SecureStorageKeys.databasePassword);
      });
    } on PlatformException {
      // Best-effort, like [savePassword]: next launch offers it again.
    }
  }

  /// Delete the saved database password for [dbPath]. Best-effort, see
  /// [savePassword].
  ///
  /// Deletes only [dbPath]'s own slot. The shared legacy slot is left alone
  /// even when it was what [getPassword] returned: a legacy password that
  /// failed here may well be another database's, and this is its only copy.
  Future<void> deletePassword({String? dbPath}) async {
    try {
      await _locked(() => _remove(_passwordKey(dbPath)));
    } on PlatformException {
      // Ignore: an unavailable keychain has nothing to delete.
    }
  }

  /// Check if a password is saved for [dbPath].
  Future<bool> hasPassword({String? dbPath}) async {
    final password = await getPassword(dbPath: dbPath);
    return password != null && password.isNotEmpty;
  }

  /// Save the sync server password securely. Best-effort, see [savePassword].
  ///
  /// The server-password accessors also swallow [MissingPluginException]:
  /// they run during settings load, which happens in widget tests and in any
  /// host without the plugin registered, and an unreachable keychain must
  /// degrade to "not remembered" rather than break startup.
  Future<void> saveServerPassword(String password) async {
    try {
      await _locked(() => _put(SecureStorageKeys.serverPassword, password));
    } on PlatformException {
      // Degrade to "not remembered".
    } on MissingPluginException {
      // Same, on a host without the plugin.
    }
  }

  /// Retrieve the saved sync server password
  Future<String?> getServerPassword() async {
    try {
      return await _locked(() => _read(SecureStorageKeys.serverPassword));
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Delete the saved sync server password
  Future<void> deleteServerPassword() async {
    try {
      await _locked(() => _remove(SecureStorageKeys.serverPassword));
    } on PlatformException {
      // Ignore: an unavailable keychain has nothing to delete.
    } on MissingPluginException {
      // Ignore.
    }
  }

  /// Save the MCP access token securely. Best-effort, see [savePassword].
  Future<void> saveMcpToken(String token) async {
    try {
      await _locked(() => _put(SecureStorageKeys.mcpToken, token));
    } on PlatformException {
      // Degrade to "no token", which keeps the server unbound.
    } on MissingPluginException {
      // Same, on a host without the plugin.
    }
  }

  /// Retrieve the saved MCP access token, or null when none is stored.
  Future<String?> getMcpToken() async {
    try {
      return await _locked(() => _read(SecureStorageKeys.mcpToken));
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Delete the saved MCP access token. Best-effort, see [savePassword].
  Future<void> deleteMcpToken() async {
    try {
      await _locked(() => _remove(SecureStorageKeys.mcpToken));
    } on PlatformException {
      // Ignore: an unavailable keychain has nothing to delete.
    } on MissingPluginException {
      // Ignore.
    }
  }

  /// Delete all secure storage data
  Future<void> deleteAll() => _locked(() async {
    await _storage.deleteAll();
    await _legacyStorage.deleteAll();
  });
}
