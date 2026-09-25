import 'package:equatable/equatable.dart';

/// Configuration for sync operations.
///
/// A value, compared by its fields: `syncConfigProvider` derives one from the
/// whole settings object, which is rewritten on every preference edit, and
/// each provider below it — the relay client, the sync service, the auto-sync
/// timer, the LAN coordinator — is rebuilt whenever the config it watches
/// *compares* unequal. Without equality every nudge of the font size closed
/// the relay client's connection and tore down an open P2P session.
class SyncConfig extends Equatable {
  final bool enabled;
  final String? serverUrl;
  final String? username;
  final String? password;
  final String? deviceId;      // auto-generated UUID
  final String? deviceName;
  final int autoSyncIntervalMinutes;  // 0 = manual only

  const SyncConfig({
    this.enabled = false,
    this.serverUrl,
    this.username,
    this.password,
    this.deviceId,
    this.deviceName,
    this.autoSyncIntervalMinutes = 0,
  });

  /// Everything sync needs that does *not* involve a server: the workspace
  /// identity and this device's id.
  ///
  /// [username] is not merely an account name — it is the HKDF nonce for both
  /// the sync key and the LAN peer key (see [SyncCrypto.deriveKey]), so two
  /// devices converge only when they share it along with the database
  /// password. LAN peer sync needs exactly this and nothing more; requiring a
  /// relay account on top of it would make P2P-only use impossible.
  bool get isIdentityConfigured =>
      enabled &&
      username != null &&
      username!.isNotEmpty &&
      deviceId != null &&
      deviceId!.isNotEmpty;

  /// Identity plus credentials for a hosted relay. Only the relay path
  /// (`SyncService.performSync`) requires this; LAN sync does not.
  bool get isRelayConfigured =>
      isIdentityConfigured &&
      serverUrl != null &&
      serverUrl!.isNotEmpty &&
      password != null &&
      password!.isNotEmpty;

  @override
  List<Object?> get props => [
        enabled,
        serverUrl,
        username,
        password,
        deviceId,
        deviceName,
        autoSyncIntervalMinutes,
      ];

  SyncConfig copyWith({
    bool? enabled,
    String? serverUrl,
    String? username,
    String? password,
    String? deviceId,
    String? deviceName,
    int? autoSyncIntervalMinutes,
  }) {
    return SyncConfig(
      enabled: enabled ?? this.enabled,
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      autoSyncIntervalMinutes: autoSyncIntervalMinutes ?? this.autoSyncIntervalMinutes,
    );
  }
}
