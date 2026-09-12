import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'peer_sync_server.dart';
import 'sync_api_client.dart';
import 'sync_crypto.dart';

/// HTTP client for another Noo device's embedded [PeerSyncServer], speaking
/// the same v2 vector exchange as the relay — [SyncService.exchangeWithSource]
/// treats both identically via [PacketSource].
///
/// Authentication is the mutual challenge-response of docs/P2P_SYNC.md §9.4;
/// [authenticate] verifies the *peer's* proof before any data is exchanged,
/// so a rogue LAN host that answered discovery cannot even learn our vector.
class PeerApiClient implements PacketSource {
  final String host;
  final int port;
  final String peerDeviceId;
  final String _ownDeviceId;

  /// Name announced to the peer so its confirmation prompt can say "Laptop"
  /// rather than a UUID. Advisory: it is not covered by the proof, but only a
  /// device already holding the peer key ever gets to state one.
  final String? _ownDeviceName;
  final SyncCrypto _crypto;
  final http.Client _client;

  String? _session;

  PeerApiClient({
    required this.host,
    required this.port,
    required this.peerDeviceId,
    required String ownDeviceId,
    String? ownDeviceName,
    required SyncCrypto crypto,
    http.Client? client,
  })  : _ownDeviceId = ownDeviceId,
        _ownDeviceName = ownDeviceName,
        _crypto = crypto,
        _client = client ?? http.Client();

  @override
  String get sourceName => 'peer $peerDeviceId@$host:$port';

  Uri _uri(String path, [Map<String, String>? query]) => Uri(
        scheme: 'http',
        host: host,
        port: port,
        path: '${PeerProtocol.basePath}$path',
        queryParameters: query,
      );

  /// Run the mutual handshake and cache the session token.
  Future<void> authenticate() async {
    final nonceA = PeerProtocol.randomNonce();
    final startResp = await _client.post(
      _uri('/auth/start'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'device_id': _ownDeviceId, 'nonce_a': nonceA}),
    );
    if (startResp.statusCode != 200) {
      throw SyncApiException(
          'Peer auth start failed: ${startResp.body}', startResp.statusCode);
    }
    final start = jsonDecode(startResp.body) as Map<String, dynamic>;
    final nonceB = start['nonce_b'] as String;
    final proofB = start['proof_b'] as String;
    final claimedDeviceId = start['device_id'] as String? ?? peerDeviceId;

    // Verify the peer holds the shared key (and is who discovery said it is)
    // before proving anything about ourselves.
    final expectedB = await _crypto.peerHmac(utf8.encode(
        PeerProtocol.respProofInput(nonceA, nonceB, claimedDeviceId)));
    if (expectedB != proofB || claimedDeviceId != peerDeviceId) {
      throw SyncApiException('Peer failed mutual authentication', 401);
    }

    final proofA = await _crypto.peerHmac(utf8
        .encode(PeerProtocol.initProofInput(nonceA, nonceB, _ownDeviceId)));
    final completeResp = await _client.post(
      _uri('/auth/complete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'device_id': _ownDeviceId,
        if (_ownDeviceName != null) 'device_name': _ownDeviceName,
        'nonce_a': nonceA,
        'proof_a': proofA,
      }),
    );
    // 403 is the peer's user declining, not a failure — the caller reports it
    // as such rather than as an error.
    if (completeResp.statusCode != 200) {
      throw SyncApiException('Peer auth complete failed: ${completeResp.body}',
          completeResp.statusCode);
    }
    _session =
        (jsonDecode(completeResp.body) as Map<String, dynamic>)['session']
            as String;
  }

  Future<http.Response> _authedGet(Uri uri, {Map<String, String>? headers}) async {
    if (_session == null) await authenticate();
    Map<String, String> withAuth() =>
        {...?headers, 'Authorization': 'Noo-Session $_session'};
    var response = await _client.get(uri, headers: withAuth());
    if (response.statusCode == 401) {
      // Session expired — one transparent re-auth and retry.
      await authenticate();
      response = await _client.get(uri, headers: withAuth());
    }
    if (response.statusCode >= 400) {
      throw SyncApiException(
          'Peer API error: ${response.body}', response.statusCode);
    }
    return response;
  }

  Future<http.Response> _authedPost(Uri uri, Map<String, dynamic> body) async {
    if (_session == null) await authenticate();
    Future<http.Response> send() => _client.post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Noo-Session $_session',
          },
          body: jsonEncode(body),
        );
    var response = await send();
    if (response.statusCode == 401) {
      await authenticate();
      response = await send();
    }
    if (response.statusCode >= 400) {
      throw SyncApiException(
          'Peer API error: ${response.body}', response.statusCode);
    }
    return response;
  }

  /// Ask this peer to pull from us in turn (docs/P2P_SYNC.md §9.5).
  ///
  /// Exchanges are pull-only, so pulling alone leaves the peer without our
  /// packets. A user-initiated sync sends this afterwards so one press
  /// converges both devices. [callbackPort] is our own peer server's port, so
  /// the peer can reach us even if discovery has not seen us yet.
  ///
  /// Returns once the peer has *accepted* the request — its exchange with us
  /// runs on its own time and is not waited for here.
  Future<void> requestSync({required int callbackPort}) async {
    await _authedPost(_uri('/sync-request'), {'port': callbackPort});
  }

  @override
  Future<Map<String, int>> getVector() async {
    final response = await _authedGet(_uri('/vector'));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['vectors'] as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as int));
  }

  @override
  Future<({List<RemotePacket> changes, bool hasMore})> getChanges(
    Map<String, int> have, {
    int limit = 100,
  }) async {
    final response = await _authedGet(_uri('/changes', {
      'have': jsonEncode(have),
      'limit': limit.toString(),
    }));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final changes = (data['changes'] as List).map((c) {
      final change = c as Map<String, dynamic>;
      return RemotePacket(
        originDeviceId: change['origin_device_id'] as String,
        counter: change['counter'] as int,
        payload: base64Decode(change['payload'] as String),
        storedAt: change['stored_at'] as String? ?? '',
      );
    }).toList();
    return (changes: changes, hasMore: data['has_more'] as bool);
  }

  /// This peer's content hashes for one device's stream (docs/P2P_SYNC.md
  /// §3.3). A peer running an older build has no such route and answers 404 —
  /// reported as "cannot verify", never as a failed exchange.
  @override
  Future<Map<int, String>?> getStreamHashes(
    String deviceId, {
    required int from,
    required int to,
  }) async {
    try {
      final response = await _authedGet(_uri('/hashes', {
        'device': deviceId,
        'from': from.toString(),
        'to': to.toString(),
      }));
      return parseStreamHashes(response.body);
    } on SyncApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<Uint8List?> getBlob(String blobId) async {
    try {
      final response = await _authedGet(_uri('/blobs/$blobId'));
      return response.bodyBytes;
    } on SyncApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<BlobSlice?> getBlobSlice(
    String blobId, {
    required int offset,
    required int length,
  }) async {
    try {
      final response = await _authedGet(
        _uri('/blobs/$blobId'),
        headers: {'Range': 'bytes=$offset-${offset + length - 1}'},
      );
      return SyncApiClient.sliceFrom(response, offset: offset);
    } on SyncApiException catch (e) {
      if (e.statusCode == 404) return null;
      if (e.statusCode == 416) {
        final whole = await getBlob(blobId);
        if (whole == null) return null;
        return BlobSlice(
            bytes: whole, offset: 0, total: whole.length, partial: false);
      }
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}
