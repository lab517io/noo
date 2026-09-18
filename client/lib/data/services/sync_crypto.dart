import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Handles encryption/decryption for sync payloads (protocol v2).
/// Uses AES-256-GCM with HKDF-SHA256 key derivation from the database password.
///
/// Two independent keys are derived per (database password, username) pair:
/// - the sync key (`noo-sync-v2`) encrypts packet payloads;
/// - the peer key (`noo-p2p-v2`) is used only for LAN discovery fingerprints
///   and peer authentication HMACs, so a break of the peer-auth usage cannot
///   expose packet contents.
class SyncCrypto {
  SecretKey? _syncKey;
  SecretKey? _peerKey;
  final AesGcm _aesGcm = AesGcm.with256bits();

  /// Derive the sync and peer keys from the database password and username.
  /// Must be called before encrypt/decrypt or any peer-auth operation.
  Future<void> deriveKey({
    required String password,
    required String username,
  }) async {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final inputKey = SecretKey(utf8.encode(password));

    _syncKey = await hkdf.deriveKey(
      secretKey: inputKey,
      nonce: utf8.encode(username),
      info: utf8.encode('noo-sync-v2'),
    );
    _peerKey = await hkdf.deriveKey(
      secretKey: inputKey,
      nonce: utf8.encode(username),
      info: utf8.encode('noo-p2p-v2'),
    );
  }

  /// AAD for a packet: binds the ciphertext to its full identity, so a blob
  /// re-served under any other (device, counter) slot fails authentication.
  static String packetAad(String originDeviceId, int counter) =>
      '$originDeviceId:$counter';

  /// AAD for an attachment blob (docs/P2P_SYNC.md §3.5): binds the ciphertext
  /// to the content id it is stored under. The prefix keeps the two AAD
  /// namespaces apart — a packet slot and a blob id can never be confused for
  /// each other, whatever their text.
  static String blobAad(String blobId) => 'blob:$blobId';

  /// Encrypt plaintext bytes. Returns nonce || ciphertext || tag.
  /// [aad] is additional authenticated data ([packetAad] for packets).
  Future<Uint8List> encrypt(Uint8List plaintext, {required String aad}) async {
    if (_syncKey == null) throw StateError('Key not derived. Call deriveKey() first.');

    final secretBox = await _aesGcm.encrypt(
      plaintext,
      secretKey: _syncKey!,
      aad: utf8.encode(aad),
    );

    // Format: nonce (12 bytes) || ciphertext || mac (16 bytes)
    final result = Uint8List(
      secretBox.nonce.length + secretBox.cipherText.length + secretBox.mac.bytes.length,
    );
    var offset = 0;
    result.setAll(offset, secretBox.nonce);
    offset += secretBox.nonce.length;
    result.setAll(offset, secretBox.cipherText);
    offset += secretBox.cipherText.length;
    result.setAll(offset, secretBox.mac.bytes);

    return result;
  }

  /// Decrypt data that was encrypted with [encrypt].
  /// [aad] must match the value used during encryption.
  Future<Uint8List> decrypt(Uint8List data, {required String aad}) async {
    if (_syncKey == null) throw StateError('Key not derived. Call deriveKey() first.');

    // Parse: nonce (12 bytes) || ciphertext || mac (16 bytes)
    const nonceLength = 12;
    const macLength = 16;

    if (data.length < nonceLength + macLength) {
      throw ArgumentError('Data too short to contain nonce and MAC');
    }

    final nonce = data.sublist(0, nonceLength);
    final cipherText = data.sublist(nonceLength, data.length - macLength);
    final mac = Mac(data.sublist(data.length - macLength));

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: mac,
    );

    final plaintext = await _aesGcm.decrypt(
      secretBox,
      secretKey: _syncKey!,
      aad: utf8.encode(aad),
    );

    return Uint8List.fromList(plaintext);
  }

  /// HMAC-SHA256 over [message] with the peer key, hex-encoded. Used for the
  /// LAN discovery fingerprint and the mutual peer-auth challenge-response.
  Future<String> peerHmac(List<int> message) async {
    final key = _peerKey;
    if (key == null) throw StateError('Key not derived. Call deriveKey() first.');
    final mac = await Hmac.sha256().calculateMac(message, secretKey: key);
    return mac.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Account fingerprint broadcast during LAN discovery: same for all devices
  /// sharing username + database password, and reveals neither. Truncated to
  /// 16 hex chars — it only pre-filters peers; real auth is the handshake.
  Future<String> accountFingerprint() async =>
      (await peerHmac(utf8.encode('noo-fp'))).substring(0, 16);

  /// Check if the keys have been derived
  bool get isReady => _syncKey != null;

  /// Clear the derived keys from memory
  void dispose() {
    _syncKey = null;
    _peerKey = null;
  }
}
