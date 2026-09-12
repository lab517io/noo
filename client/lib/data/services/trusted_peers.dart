import 'dart:convert';

import '../database/database.dart';

/// Devices whose sync requests this device has agreed to accept without being
/// asked again (docs/P2P_SYNC.md §9.6).
///
/// Trust is **local to this database file** and never synced: it records what
/// the person using this device decided, which is not a fact about the data.
/// It lives in the properties table alongside the sync watermarks rather than
/// in app settings, because a settings write rebuilds the sync config and
/// would restart the LAN sockets — including in the middle of the very
/// exchange being approved.
///
/// Trusting a device removes the *prompt*, not the *press*: an exchange still
/// only happens because someone asked for one on one side or the other.
class TrustedPeers {
  static const String propertyKey = 'lan_trusted_peers';

  final NooDatabase _db;

  TrustedPeers(this._db);

  /// Trusted device ids mapped to the name they last announced (empty string
  /// when they announced none). Ordering is not meaningful.
  Future<Map<String, String>> all() async {
    final raw = await _db.getProperty(propertyKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map((k, v) => MapEntry('$k', v is String ? v : ''));
    } catch (_) {
      // Corrupt or hand-edited value: treat as "nothing trusted" rather than
      // failing every handshake. The next trust() rewrites it cleanly.
      return {};
    }
  }

  Future<bool> isTrusted(String deviceId) async =>
      (await all()).containsKey(deviceId);

  /// Remember [deviceId], refreshing the stored name if it announced one.
  Future<void> trust(String deviceId, String? deviceName) async {
    final current = await all();
    current[deviceId] = deviceName?.trim() ?? '';
    await _db.setProperty(propertyKey, jsonEncode(current));
  }

  /// Forget [deviceId]; its next sync request prompts again.
  Future<void> revoke(String deviceId) async {
    final current = await all();
    if (current.remove(deviceId) == null) return;
    await _db.setProperty(propertyKey, jsonEncode(current));
  }
}
