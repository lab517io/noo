import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:noo/domain/entities/sync_config.dart';

/// One encrypted packet fetched from a remote node (relay or LAN peer),
/// identified by (originDeviceId, counter) — sync protocol v2.
class RemotePacket {
  final String originDeviceId;
  final int counter;
  final Uint8List payload;
  final String storedAt;

  const RemotePacket({
    required this.originDeviceId,
    required this.counter,
    required this.payload,
    required this.storedAt,
  });
}

/// Outcome of uploading one packet to the relay.
enum PacketUploadResult {
  stored,

  /// The relay already holds this (device, counter) slot — expected when the
  /// packet reached it via another path (e.g. carried by a LAN peer).
  alreadyHeld,
}

/// What a snapshot upload reclaimed on the relay
/// (docs/P2P_SYNC_COMPACTION.md §4.3). Zero when the upload carried no
/// coverage declaration, or when the relay had nothing covered left to drop.
class RelayPruneResult {
  final int packets;
  final int bytes;

  const RelayPruneResult({this.packets = 0, this.bytes = 0});

  factory RelayPruneResult.fromJson(Map<String, dynamic> json) =>
      RelayPruneResult(
        packets: json['pruned_packets'] as int? ?? 0,
        bytes: json['pruned_bytes'] as int? ?? 0,
      );
}

/// One origin device's share of the account's relay storage.
class RelayDeviceUsage {
  final String deviceId;

  /// The name the device registered under, or empty for a device that has
  /// never logged in to this relay (its packets arrived by gossip).
  final String deviceName;
  final int packets;
  final int bytes;
  final int firstCounter;
  final int lastCounter;

  /// How many of the stored packets are full-state snapshots.
  final int snapshots;

  const RelayDeviceUsage({
    required this.deviceId,
    required this.deviceName,
    required this.packets,
    required this.bytes,
    required this.firstCounter,
    required this.lastCounter,
    required this.snapshots,
  });

  factory RelayDeviceUsage.fromJson(Map<String, dynamic> json) =>
      RelayDeviceUsage(
        deviceId: json['device_id'] as String? ?? '',
        deviceName: json['device_name'] as String? ?? '',
        packets: json['packets'] as int? ?? 0,
        bytes: json['bytes'] as int? ?? 0,
        firstCounter: json['first_counter'] as int? ?? 0,
        lastCounter: json['last_counter'] as int? ?? 0,
        snapshots: json['snapshots'] as int? ?? 0,
      );
}

/// What this account occupies on the relay, largest device first.
class RelayUsage {
  final int packets;
  final int bytes;
  final List<RelayDeviceUsage> devices;

  /// Attachment blobs (docs/P2P_SYNC.md §3.5), account-wide — they belong to
  /// content, not to the device that happened to upload them. Zero from a
  /// relay that predates the blob store.
  final int blobs;
  final int blobBytes;

  const RelayUsage({
    required this.packets,
    required this.bytes,
    required this.devices,
    this.blobs = 0,
    this.blobBytes = 0,
  });

  factory RelayUsage.fromJson(Map<String, dynamic> json) => RelayUsage(
        packets: json['packets'] as int? ?? 0,
        bytes: json['bytes'] as int? ?? 0,
        devices: ((json['devices'] as List?) ?? const [])
            .map((d) => RelayDeviceUsage.fromJson(d as Map<String, dynamic>))
            .toList(),
        blobs: json['blobs'] as int? ?? 0,
        blobBytes: json['blob_bytes'] as int? ?? 0,
      );
}

/// What one blob read returned (docs/P2P_SYNC.md §3.5).
///
/// A blob is a single AES-256-GCM ciphertext, so a range can be *transferred*
/// but not decrypted on its own: the tag covers the whole thing. Slices are
/// therefore accumulated as ciphertext and verified once, at the end.
class BlobSlice {
  /// The ciphertext bytes returned, starting at [offset].
  final Uint8List bytes;

  /// Where [bytes] begin in the blob.
  final int offset;

  /// Length of the whole ciphertext, when the node reported it (a ranged
  /// answer always does; a whole-blob answer is its own length). Null only
  /// when a node streamed without saying how much was coming.
  final int? total;

  /// Whether the node honoured the requested range. False means it ignored
  /// the range and sent everything — [bytes] is the whole blob, and there is
  /// nothing left to ask for.
  final bool partial;

  const BlobSlice({
    required this.bytes,
    required this.offset,
    required this.total,
    required this.partial,
  });

  /// Whether the blob is fully in hand once these bytes are appended.
  bool get isComplete => total == null || offset + bytes.length >= total!;
}

/// A remote source of sync packets speaking the v2 exchange: a version-vector
/// query plus a "give me everything above my vector" pull. Implemented by the
/// relay client below and by the LAN peer client, so [SyncService] runs the
/// same exchange against both.
abstract class PacketSource {
  /// Human-readable name for logs/errors (`relay`, `peer <name>`).
  String get sourceName;

  /// The remote node's version vector: `{device_id → highest counter held}`.
  Future<Map<String, int>> getVector();

  /// Packets the remote holds above [have], ascending per origin device.
  Future<({List<RemotePacket> changes, bool hasMore})> getChanges(
    Map<String, int> have, {
    int limit,
  });

  /// The remote's content hashes for one device's stream over the inclusive
  /// counter range [from]..[to] — `{counter → sha256 hex}`.
  ///
  /// Sparse: counters the remote never fetched or has pruned are absent, and
  /// the caller compares only the overlap. Returns null when the remote does
  /// not implement the query (a relay that predates it), which makes stream
  /// verification unavailable rather than failed — the exchange goes ahead
  /// with exactly the guarantees it had before.
  Future<Map<int, String>?> getStreamHashes(
    String deviceId, {
    required int from,
    required int to,
  });

  /// The encrypted attachment blob stored under [blobId] (docs/P2P_SYNC.md
  /// §3.5), or null when the remote does not hold it — which is not an
  /// error: the bytes are fetched from whichever node has them, and a packet
  /// can be applied before its attachments have caught up.
  Future<Uint8List?> getBlob(String blobId);

  /// [length] bytes of [blobId]'s ciphertext from [offset], so a large
  /// attachment arrives in pieces and a failed transfer resumes where it
  /// stopped instead of starting over.
  ///
  /// Nodes are not required to support this. The default asks for the whole
  /// blob and reports `partial: false`, which is what a node that ignores the
  /// range does anyway — the caller handles both without asking which it got.
  Future<BlobSlice?> getBlobSlice(
    String blobId, {
    required int offset,
    required int length,
  }) async {
    final whole = await getBlob(blobId);
    if (whole == null) return null;
    return BlobSlice(
      bytes: whole,
      offset: 0,
      total: whole.length,
      partial: false,
    );
  }
}

/// HTTP client for the Noo sync relay API (protocol v2).
class SyncApiClient implements PacketSource {
  final SyncConfig config;
  String? _accessToken;
  String? _refreshToken;
  final http.Client _client;

  SyncApiClient({
    required this.config,
    http.Client? client,
  }) : _client = client ?? http.Client();

  @override
  String get sourceName => 'relay';

  Map<String, String> get _authHeaders => {
    'Authorization': 'Bearer $_accessToken',
    'Content-Type': 'application/json',
  };

  /// Register a new account
  Future<void> register() async {
    final response = await _client.post(
      Uri.parse('${config.serverUrl}/api/v2/auth/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': config.username, 'password': config.password}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw SyncApiException('Registration failed: ${response.body}', response.statusCode);
    }
  }

  /// Login and obtain tokens
  Future<void> login({required String platform}) async {
    final response = await _client.post(
      Uri.parse('${config.serverUrl}/api/v2/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': config.username,
        'password': config.password,
        'device_id': config.deviceId,
        'device_name': config.deviceName,
        'platform': platform,
      }),
    );
    if (response.statusCode != 200) {
      throw SyncApiException('Login failed: ${response.body}', response.statusCode);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _accessToken = data['access_token'] as String;
    _refreshToken = data['refresh_token'] as String;
  }

  /// Refresh the access token
  Future<void> refreshAccessToken() async {
    if (_refreshToken == null) throw StateError('No refresh token available');

    final response = await _client.post(
      Uri.parse('${config.serverUrl}/api/v2/auth/refresh/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': _refreshToken}),
    );
    if (response.statusCode != 200) {
      throw SyncApiException('Token refresh failed: ${response.body}', response.statusCode);
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _accessToken = data['access_token'] as String;
    if (data.containsKey('refresh_token')) {
      _refreshToken = data['refresh_token'] as String;
    }
  }

  /// The relay's version vector for this user.
  @override
  Future<Map<String, int>> getVector() async {
    final response = await _request(() => _client.get(
      Uri.parse('${config.serverUrl}/api/v2/changes/vector'),
      headers: _authHeaders,
    ));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final vectors = data['vectors'] as Map<String, dynamic>;
    return vectors.map((k, v) => MapEntry(k, v as int));
  }

  /// Upload one packet. The relay stores it verbatim under its
  /// (origin device, counter) identity — including packets this device merely
  /// carries for other devices (gossip).
  ///
  /// [snapshotCovers], when given, declares that this packet is a full-state
  /// snapshot superseding every packet at or below the named counters, and
  /// authorises the relay to delete them (docs/P2P_SYNC_COMPACTION.md §4.3).
  /// The relay cannot read the payload, so this travels in a header; what it
  /// freed comes back in [prune].
  ///
  /// [blobIds] declares the attachment blobs the packet references (§3.5).
  /// The relay cannot read the packet, so this is how it learns which blobs
  /// the packet keeps alive; it refuses (409) a packet whose declared blobs it
  /// does not hold, which is why [putBlob] must run first.
  Future<({PacketUploadResult result, RelayPruneResult? prune})> uploadPacket({
    required String originDeviceId,
    required int counter,
    required Uint8List payload,
    Map<String, int>? snapshotCovers,
    List<String> blobIds = const [],
  }) async {
    final response = await _request(() => _client.post(
      Uri.parse('${config.serverUrl}/api/v2/changes/'),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/octet-stream',
        'X-Noo-Origin-Device': originDeviceId,
        'X-Noo-Counter': counter.toString(),
        if (snapshotCovers != null)
          'X-Noo-Snapshot-Covers': jsonEncode(snapshotCovers),
        if (blobIds.isNotEmpty) 'X-Noo-Blobs': blobIds.join(','),
      },
      body: payload,
    ));
    final result = response.statusCode == 201
        ? PacketUploadResult.stored
        : PacketUploadResult.alreadyHeld;

    RelayPruneResult? prune;
    if (snapshotCovers != null) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final pruned = body['pruned'] as Map<String, dynamic>?;
        // A relay too old to know the header stores the packet and says
        // nothing about pruning — the compaction is then a no-op, not a
        // failure, and the caller reports it as such.
        if (pruned != null) prune = RelayPruneResult.fromJson(pruned);
      } catch (_) {
        prune = null;
      }
    }
    return (result: result, prune: prune);
  }

  /// What this account occupies on the relay, per origin device.
  Future<RelayUsage> getUsage() async {
    final response = await _request(() => _client.get(
      Uri.parse('${config.serverUrl}/api/v2/changes/usage'),
      headers: _authHeaders,
    ));
    return RelayUsage.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Packets the relay holds above [have], ascending per origin device.
  @override
  Future<({List<RemotePacket> changes, bool hasMore})> getChanges(
    Map<String, int> have, {
    int limit = 100,
  }) async {
    final haveParam = Uri.encodeQueryComponent(jsonEncode(have));
    final response = await _request(() => _client.get(
      Uri.parse('${config.serverUrl}/api/v2/changes/?have=$haveParam&limit=$limit'),
      headers: _authHeaders,
    ));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final changesList = (data['changes'] as List).map((c) {
      final change = c as Map<String, dynamic>;
      return RemotePacket(
        originDeviceId: change['origin_device_id'] as String,
        counter: change['counter'] as int,
        payload: base64Decode(change['payload'] as String),
        storedAt: change['stored_at'] as String? ?? '',
      );
    }).toList();

    return (
      changes: changesList,
      hasMore: data['has_more'] as bool,
    );
  }

  /// Read a blob response as a slice, whether the node ranged it (206, with a
  /// `Content-Range` giving the full length) or ignored the range (200).
  static BlobSlice sliceFrom(http.Response response, {required int offset}) {
    final bytes = response.bodyBytes;
    if (response.statusCode != 206) {
      return BlobSlice(
          bytes: bytes, offset: 0, total: bytes.length, partial: false);
    }
    return BlobSlice(
      bytes: bytes,
      offset: offset,
      total: _totalFromContentRange(response.headers['content-range']),
      partial: true,
    );
  }

  /// The instance length out of `bytes <start>-<end>/<total>`; null for the
  /// unknown-length form (`*`) or a header we cannot parse, which leaves the
  /// caller fetching until a short answer ends it.
  static int? _totalFromContentRange(String? header) {
    if (header == null) return null;
    final slash = header.lastIndexOf('/');
    if (slash < 0) return null;
    return int.tryParse(header.substring(slash + 1).trim());
  }

  Uri _blobUri(String blobId) =>
      Uri.parse('${config.serverUrl}/api/v2/blobs/$blobId');

  /// Whether the relay already holds [blobId]. Asked before every upload so a
  /// blob is sent once, not once per packet that mentions it.
  Future<bool> hasBlob(String blobId) async {
    try {
      await _request(() => _client.head(
        _blobUri(blobId),
        headers: {'Authorization': 'Bearer $_accessToken'},
      ));
      return true;
    } on SyncApiException catch (e) {
      if (e.statusCode == 404) return false;
      rethrow;
    }
  }

  /// Store an encrypted attachment blob under its content id. Idempotent:
  /// a blob already held answers 200 and the bytes are discarded.
  Future<void> putBlob(String blobId, Uint8List encrypted) async {
    await _request(() => _client.put(
      _blobUri(blobId),
      headers: {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/octet-stream',
      },
      body: encrypted,
    ));
  }

  @override
  Future<Uint8List?> getBlob(String blobId) async {
    try {
      final response = await _request(() => _client.get(
        _blobUri(blobId),
        headers: {'Authorization': 'Bearer $_accessToken'},
      ));
      return response.bodyBytes;
    } on SyncApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Ranged read over plain HTTP `Range`. A relay that does not implement it
  /// answers 200 with the whole blob, which [BlobSlice.partial] reports and
  /// the caller takes as the complete answer — so this is safe against a
  /// relay older than the feature, and starts chunking the day one supports
  /// it, with no version negotiation.
  @override
  Future<BlobSlice?> getBlobSlice(
    String blobId, {
    required int offset,
    required int length,
  }) async {
    try {
      final response = await _request(() => _client.get(
            _blobUri(blobId),
            headers: {
              'Authorization': 'Bearer $_accessToken',
              'Range': 'bytes=$offset-${offset + length - 1}',
            },
          ));
      return sliceFrom(response, offset: offset);
    } on SyncApiException catch (e) {
      if (e.statusCode == 404) return null;
      // 416 says the offset is past the end: what we have locally is not a
      // prefix of what the relay holds. Nothing to resume into, so take the
      // whole blob and let the usual verification settle it.
      if (e.statusCode == 416) {
        final whole = await getBlob(blobId);
        if (whole == null) return null;
        return BlobSlice(
            bytes: whole, offset: 0, total: whole.length, partial: false);
      }
      rethrow;
    }
  }

  /// The relay's content hashes for one device's stream (docs/P2P_SYNC.md
  /// §3.3). A relay that predates the endpoint answers 404, which is reported
  /// as "cannot verify" rather than propagated as a sync failure.
  @override
  Future<Map<int, String>?> getStreamHashes(
    String deviceId, {
    required int from,
    required int to,
  }) async {
    final device = Uri.encodeQueryComponent(deviceId);
    try {
      final response = await _request(() => _client.get(
        Uri.parse('${config.serverUrl}/api/v2/changes/hashes'
            '?device=$device&from=$from&to=$to'),
        headers: _authHeaders,
      ));
      return parseStreamHashes(response.body);
    } on SyncApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Get list of registered devices
  Future<List<Map<String, dynamic>>> getDevices() async {
    final response = await _request(() => _client.get(
      Uri.parse('${config.serverUrl}/api/v2/devices/'),
      headers: _authHeaders,
    ));
    final data = jsonDecode(response.body) as List;
    return data.cast<Map<String, dynamic>>();
  }

  /// Delete a device
  Future<void> deleteDevice(String targetDeviceId) async {
    await _request(() => _client.delete(
      Uri.parse('${config.serverUrl}/api/v2/devices/$targetDeviceId'),
      headers: _authHeaders,
    ));
  }

  /// Test connection to server
  Future<bool> testConnection() async {
    try {
      final response = await _client.get(Uri.parse('${config.serverUrl}/health'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  bool get isAuthenticated => _accessToken != null;

  /// Clear cached tokens so the next sync performs a fresh login. Called when
  /// the refresh token is rejected (e.g. expired, or the device was revoked).
  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  /// Execute a request with automatic token refresh on 401
  Future<http.Response> _request(Future<http.Response> Function() requestFn) async {
    var response = await requestFn();

    if (response.statusCode == 401 && _refreshToken != null) {
      try {
        await refreshAccessToken();
        response = await requestFn();
      } catch (_) {
        // Refresh failed — drop the stale tokens so _prepareSync logs in
        // again on the next cycle instead of being wedged until app restart.
        clearTokens();
        throw SyncApiException('Authentication failed', 401);
      }
    }

    if (response.statusCode >= 400) {
      throw SyncApiException(
        'API error: ${response.body}',
        response.statusCode,
      );
    }

    return response;
  }

  void dispose() {
    _client.close();
  }
}

/// Decode a stream-hash response body — `{"hashes": {"<counter>": "<hex>"}}`.
///
/// JSON object keys are strings, so the counters arrive as text and are parsed
/// back. Shared by the relay and peer clients: both endpoints answer in this
/// shape, and a hash comparison is only meaningful if both sides read it the
/// same way. Unparseable entries are dropped rather than guessed at — a
/// missing hash costs a check, a wrong one costs a false fork alarm.
Map<int, String> parseStreamHashes(String body) {
  final data = jsonDecode(body) as Map<String, dynamic>;
  final hashes = data['hashes'] as Map<String, dynamic>? ?? {};
  final parsed = <int, String>{};
  hashes.forEach((counter, hash) {
    final n = int.tryParse(counter);
    if (n != null && hash is String && hash.isNotEmpty) parsed[n] = hash;
  });
  return parsed;
}

class SyncApiException implements Exception {
  final String message;
  final int statusCode;

  SyncApiException(this.message, this.statusCode);

  @override
  String toString() => 'SyncApiException($statusCode): $message';
}
