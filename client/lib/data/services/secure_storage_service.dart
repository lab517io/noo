import 'dart:convert';

import 'package:crypto/crypto.dart';
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
  /// default service name. [_read] adopts them into the renamed service on
  /// first access, so an upgrade doesn't lose saved passwords or the MCP
  /// token.
  static const MacOsOptions _legacyMacOptions = MacOsOptions(
    usesDataProtectionKeychain: false,
  );

  final FlutterSecureStorage _storage;
  final FlutterSecureStorage _legacyStorage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(mOptions: _macOptions),
        _legacyStorage =
            const FlutterSecureStorage(mOptions: _legacyMacOptions);

  /// Read [key], migrating it out of the legacy keychain service on the way.
  ///
  /// The migration is a no-op on Linux and Windows, where the service name
  /// isn't part of the item's identity and both handles address the same slot.
  Future<String?> _read(String key) async {
    final current = await _storage.read(key: key);
    if (current != null) return current;

    final legacy = await _legacyStorage.read(key: key);
    if (legacy == null) return null;

    await _storage.write(key: key, value: legacy);
    await _legacyStorage.delete(key: key);
    return legacy;
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
      await _storage.write(key: _passwordKey(dbPath), value: password);
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
      final scoped = await _read(key);
      if (scoped != null) return scoped;

      if (key != SecureStorageKeys.databasePassword) {
        return await _read(SecureStorageKeys.databasePassword);
      }
      return null;
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
      return await _read(key) == null &&
          await _read(SecureStorageKeys.databasePassword) != null;
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
      if (await _read(key) != null) return;
      final legacy = await _read(SecureStorageKeys.databasePassword);
      if (legacy == null) return;
      await _storage.write(key: key, value: legacy);
      await _storage.delete(key: SecureStorageKeys.databasePassword);
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
      await _storage.delete(key: _passwordKey(dbPath));
      await _legacyStorage.delete(key: _passwordKey(dbPath));
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
      await _storage.write(
        key: SecureStorageKeys.serverPassword,
        value: password,
      );
    } on PlatformException {
      // Degrade to "not remembered".
    } on MissingPluginException {
      // Same, on a host without the plugin.
    }
  }

  /// Retrieve the saved sync server password
  Future<String?> getServerPassword() async {
    try {
      return await _read(SecureStorageKeys.serverPassword);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Delete the saved sync server password
  Future<void> deleteServerPassword() async {
    try {
      await _storage.delete(key: SecureStorageKeys.serverPassword);
      await _legacyStorage.delete(key: SecureStorageKeys.serverPassword);
    } on PlatformException {
      // Ignore: an unavailable keychain has nothing to delete.
    } on MissingPluginException {
      // Ignore.
    }
  }

  /// Save the MCP access token securely. Best-effort, see [savePassword].
  Future<void> saveMcpToken(String token) async {
    try {
      await _storage.write(key: SecureStorageKeys.mcpToken, value: token);
    } on PlatformException {
      // Degrade to "no token", which keeps the server unbound.
    } on MissingPluginException {
      // Same, on a host without the plugin.
    }
  }

  /// Retrieve the saved MCP access token, or null when none is stored.
  Future<String?> getMcpToken() async {
    try {
      return await _read(SecureStorageKeys.mcpToken);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Delete the saved MCP access token. Best-effort, see [savePassword].
  Future<void> deleteMcpToken() async {
    try {
      await _storage.delete(key: SecureStorageKeys.mcpToken);
      await _legacyStorage.delete(key: SecureStorageKeys.mcpToken);
    } on PlatformException {
      // Ignore: an unavailable keychain has nothing to delete.
    } on MissingPluginException {
      // Ignore.
    }
  }

  /// Delete all secure storage data
  Future<void> deleteAll() async {
    await _storage.deleteAll();
    await _legacyStorage.deleteAll();
  }
}
