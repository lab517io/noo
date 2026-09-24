import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../../domain/entities/sync_packet.dart';
import '../database/database.dart';
import 'sync_crypto.dart';
import 'sync_journal.dart';

/// Constants shared by the LAN peer protocol (docs/P2P_SYNC.md §9).
class PeerProtocol {
  /// UDP discovery port (broadcast probes and unicast announces).
  static const int discoveryPort = 46630;

  /// Base path of the peer HTTP API.
  static const String basePath = '/peer/v2';

  /// Peer session lifetime; re-auth afterwards is cheap.
  static const Duration sessionTtl = Duration(minutes: 10);

  /// How long a pending auth handshake may take before its nonce expires.
  static const Duration handshakeTtl = Duration(seconds: 30);

  static final Random _random = Random.secure();

  static String randomNonce() =>
      List.generate(16, (_) => _random.nextInt(256))
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

  /// Proof strings for the mutual challenge-response (§9.4). Distinct labels
  /// for the two roles prevent reflecting a proof back to its author.
  static String initProofInput(String nonceA, String nonceB, String deviceId) =>
      'init|$nonceA|$nonceB|$deviceId';
  static String respProofInput(String nonceA, String nonceB, String deviceId) =>
      'resp|$nonceA|$nonceB|$deviceId';
}

/// Embedded HTTP server every client runs on the LAN: a miniature relay that
/// answers vector queries and serves packets from the local packet store.
/// Pull-only — peers never push; each side pulls from the other.
///
/// Authentication is a mutual challenge-response over the peer key (derived
/// from the database password — possession of the key *is* the pairing):
///
///   POST /peer/v2/auth/start    {device_id, nonce_a}
///     → {nonce_b, proof_b}         (this server proves itself first)
///   POST /peer/v2/auth/complete {device_id, device_name, nonce_a, proof_a}
///     → {session}                  (the caller proves itself; gets a token)
///
/// Payloads served are ciphertext end-to-end, so plain HTTP leaks only the
/// same metadata class the relay already sees (vectors, sizes, device ids).
class PeerSyncServer {
  final NooDatabase _db;
  final SyncCrypto _crypto;
  final String _deviceId;

  /// Invoked when an authenticated peer asks us to pull from it
  /// (`POST /peer/v2/sync-request`, §9.5). Exchanges are pull-only, so this is
  /// how one side's manual sync makes *both* devices converge: the presser
  /// pulls, then asks its peer to pull back. The callback receives the calling
  /// device's id, the address it connected from, and the port its own peer
  /// server listens on.
  final void Function(String deviceId, InternetAddress address, int port)?
      onSyncRequested;

  /// Told when a peer has proved itself and been given a session, with its
  /// device id and the name it announced (null when it announced none).
  ///
  /// There is no approval step: this server only runs while this device's user
  /// has Sync P2P open, and holding the peer key *is* the pairing — so a peer
  /// that authenticates is one this user already agreed to sync with.
  final void Function(String deviceId, String? deviceName)? onSessionStarted;

  /// Packages pending local edits before a vector query is answered, so what
  /// we advertise (and then serve) is our current state rather than whatever
  /// we last happened to package.
  ///
  /// Without it a peer's pull silently misses every edit made since this
  /// device's own last sync — invisible while both sides exchanged on a timer,
  /// but plainly wrong once a single press is expected to converge both.
  final Future<void> Function()? beforeServe;

  /// Where what we serve is recorded, one `lan-serve` run per peer session.
  final SyncJournal? journal;

  /// Sync-log run of each live session, by session token.
  final Map<String, SyncLogRun> _serveLogs = {};

  HttpServer? _server;
  final Map<String, ({String nonceB, DateTime expires})> _pendingAuth = {};

  /// Live session tokens, each bound to the device that proved itself for it —
  /// [_syncRequest] needs the caller's identity, not just its validity.
  final Map<String, ({String deviceId, DateTime expires})> _sessions = {};

  PeerSyncServer({
    required NooDatabase db,
    required SyncCrypto crypto,
    required String deviceId,
    this.onSyncRequested,
    this.onSessionStarted,
    this.beforeServe,
    this.journal,
  })  : _db = db,
        _crypto = crypto,
        _deviceId = deviceId;

  bool get isRunning => _server != null;
  int get port => _server?.port ?? 0;

  /// Bind on all interfaces at an ephemeral port. The port is announced via
  /// discovery, so it need not be fixed.
  Future<void> start() async {
    if (_server != null) return;
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _server = server;
    server.listen(_handle, onError: (_) {}, cancelOnError: false);
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    _pendingAuth.clear();
    _sessions.clear();
    _serveLogs.clear();
    await server?.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      final path = request.uri.path;
      if (!_crypto.isReady) {
        _json(request, HttpStatus.serviceUnavailable, {'error': 'not ready'});
        return;
      }
      if (request.method == 'POST' &&
          path == '${PeerProtocol.basePath}/auth/start') {
        await _authStart(request);
      } else if (request.method == 'POST' &&
          path == '${PeerProtocol.basePath}/auth/complete') {
        await _authComplete(request);
      } else if (request.method == 'GET' &&
          path == '${PeerProtocol.basePath}/vector') {
        await _vector(request);
      } else if (request.method == 'GET' &&
          path == '${PeerProtocol.basePath}/changes') {
        await _changes(request);
      } else if (request.method == 'GET' &&
          path == '${PeerProtocol.basePath}/hashes') {
        await _hashes(request);
      } else if (request.method == 'GET' &&
          path.startsWith('${PeerProtocol.basePath}/blobs/')) {
        await _blob(request,
            path.substring('${PeerProtocol.basePath}/blobs/'.length));
      } else if (request.method == 'POST' &&
          path == '${PeerProtocol.basePath}/sync-request') {
        await _syncRequest(request);
      } else {
        _json(request, HttpStatus.notFound, {'error': 'not found'});
      }
    } catch (_) {
      try {
        _json(request, HttpStatus.internalServerError, {'error': 'internal'});
      } catch (_) {
        // Response already committed or connection gone — nothing to do.
      }
    }
  }

  Future<Map<String, dynamic>?> _body(HttpRequest request) async {
    try {
      final text = await utf8.decoder.bind(request).join();
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  void _json(HttpRequest request, int status, Map<String, dynamic> body) {
    request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(body));
    request.response.close();
  }

  void _expire() {
    final now = DateTime.now();
    _pendingAuth.removeWhere((_, v) => v.expires.isBefore(now));
    _sessions.removeWhere((_, v) => v.expires.isBefore(now));
    _serveLogs.removeWhere((token, _) => !_sessions.containsKey(token));
  }

  /// The sync-log run for this request's session, opened on first use.
  Future<SyncLogRun?> _serveLog(HttpRequest request) async {
    final journal = this.journal;
    if (journal == null) return null;
    final header = request.headers.value('authorization') ?? '';
    const prefix = 'Noo-Session ';
    if (!header.startsWith(prefix)) return null;
    final token = header.substring(prefix.length);
    final session = _sessions[token];
    if (session == null) return null;
    final held = _serveLogs[token];
    if (held != null) return held;
    final address = request.connectionInfo?.remoteAddress.address;
    final run = await journal.begin(
      'lan-serve',
      remote: 'peer ${session.deviceId}${address == null ? '' : '@$address'}',
      deviceId: _deviceId,
    );
    return _serveLogs[token] = run;
  }

  Future<void> _authStart(HttpRequest request) async {
    _expire();
    final body = await _body(request);
    final nonceA = body?['nonce_a'] as String?;
    if (nonceA == null || nonceA.isEmpty || nonceA.length > 128) {
      _json(request, HttpStatus.badRequest, {'error': 'bad request'});
      return;
    }
    final nonceB = PeerProtocol.randomNonce();
    _pendingAuth[nonceA] = (
      nonceB: nonceB,
      expires: DateTime.now().add(PeerProtocol.handshakeTtl),
    );
    // Prove this server's identity first: the caller verifies proof_b before
    // revealing anything about itself beyond a random nonce.
    final proofB = await _crypto.peerHmac(
        utf8.encode(PeerProtocol.respProofInput(nonceA, nonceB, _deviceId)));
    _json(request, HttpStatus.ok, {
      'device_id': _deviceId,
      'nonce_b': nonceB,
      'proof_b': proofB,
    });
  }

  Future<void> _authComplete(HttpRequest request) async {
    _expire();
    final body = await _body(request);
    final deviceId = body?['device_id'] as String?;
    final nonceA = body?['nonce_a'] as String?;
    final proofA = body?['proof_a'] as String?;
    if (deviceId == null || nonceA == null || proofA == null) {
      _json(request, HttpStatus.badRequest, {'error': 'bad request'});
      return;
    }
    final pending = _pendingAuth.remove(nonceA);
    if (pending == null) {
      _json(request, HttpStatus.unauthorized, {'error': 'unknown handshake'});
      return;
    }
    final expected = await _crypto.peerHmac(utf8.encode(
        PeerProtocol.initProofInput(nonceA, pending.nonceB, deviceId)));
    if (!_constantTimeEquals(expected, proofA)) {
      _json(request, HttpStatus.unauthorized, {'error': 'bad proof'});
      return;
    }

    final session = PeerProtocol.randomNonce();
    _sessions[session] = (
      deviceId: deviceId,
      expires: DateTime.now().add(PeerProtocol.sessionTtl),
    );
    _json(request, HttpStatus.ok, {'session': session});
    onSessionStarted?.call(deviceId, body?['device_name'] as String?);
  }

  /// The device behind this request's session token, or null when the token is
  /// missing, malformed or expired.
  String? _sessionDevice(HttpRequest request) {
    _expire();
    final header = request.headers.value('authorization') ?? '';
    const prefix = 'Noo-Session ';
    if (!header.startsWith(prefix)) return null;
    return _sessions[header.substring(prefix.length)]?.deviceId;
  }

  bool _authorized(HttpRequest request) => _sessionDevice(request) != null;

  /// A peer that just pulled from us asks us to pull from it, so a single
  /// manual sync converges both devices (§9.5). Answered immediately; the
  /// exchange itself runs after the response, out of this request's lifetime.
  Future<void> _syncRequest(HttpRequest request) async {
    final deviceId = _sessionDevice(request);
    if (deviceId == null) {
      _json(request, HttpStatus.unauthorized, {'error': 'unauthorized'});
      return;
    }
    final body = await _body(request);
    final port = body?['port'];
    final address = request.connectionInfo?.remoteAddress;
    if (port is! int || port <= 0 || port > 65535 || address == null) {
      _json(request, HttpStatus.badRequest, {'error': 'bad request'});
      return;
    }
    // Accepted, not done: the caller must not wait on our exchange with it.
    _json(request, HttpStatus.accepted, {'status': 'accepted'});
    final log = await _serveLog(request);
    log?.add(SyncLogKind.syncRequested,
        direction: 'in',
        originDevice: deviceId,
        message: 'Peer asked this device to pull from it');
    await log?.finish();
    onSyncRequested?.call(deviceId, address, port);
  }

  Future<void> _vector(HttpRequest request) async {
    if (!_authorized(request)) {
      _json(request, HttpStatus.unauthorized, {'error': 'unauthorized'});
      return;
    }
    // Every exchange starts here, so this is the one place that has to see our
    // pending edits. The paged /changes calls that follow read the same store
    // and need no packaging of their own.
    if (beforeServe != null) {
      try {
        await beforeServe!();
      } catch (_) {
        // Packaging failed (bad key, database busy): still answer with the
        // vector we have. The peer gets a consistent, if older, view.
      }
    }
    final vector = await _db.getSyncVector();
    _json(request, HttpStatus.ok, {'vectors': vector});
    final log = await _serveLog(request);
    log?.add(SyncLogKind.serveVector,
        direction: 'out',
        message: 'Peer asked what this device holds',
        detail: {'vector': vector});
    await log?.finish();
  }

  Future<void> _changes(HttpRequest request) async {
    if (!_authorized(request)) {
      _json(request, HttpStatus.unauthorized, {'error': 'unauthorized'});
      return;
    }
    Map<String, int> have;
    try {
      final raw = request.uri.queryParameters['have'] ?? '{}';
      have = (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      _json(request, HttpStatus.badRequest, {'error': 'invalid have vector'});
      return;
    }
    final limit =
        (int.tryParse(request.uri.queryParameters['limit'] ?? '') ?? 100)
            .clamp(1, 1000);

    final rows = await _db.getSyncPacketsAboveVector(have, limit: limit + 1);
    final hasMore = rows.length > limit;
    final page = rows.take(limit).toList();
    _json(request, HttpStatus.ok, {
      'changes': [
        for (final row in page)
          {
            'origin_device_id': row.originDeviceId,
            'counter': row.counter,
            'payload': base64Encode(row.payload),
            'stored_at': row.storedAt,
          }
      ],
      'has_more': hasMore,
    });
    final log = await _serveLog(request);
    if (log != null) {
      for (final row in page) {
        log.add(SyncLogKind.served,
            direction: 'out',
            originDevice: row.originDeviceId,
            counter: row.counter,
            packetHash: row.payloadHash.isNotEmpty
                ? row.payloadHash
                : NooDatabase.syncPayloadHash(row.payload),
            detail: {'bytes': row.payload.length});
      }
      if (page.isEmpty) {
        log.add(SyncLogKind.note,
            direction: 'out',
            message: 'Peer already holds everything this device has',
            detail: {'have': have});
      }
      await log.finish();
    }
  }

  /// Our content hashes for one device's stream over an inclusive counter
  /// range (docs/P2P_SYNC.md §3.3), so a peer can check that the packets we
  /// both claim to hold really are the same packets.
  ///
  /// Answers only about *stored* packets: counters covered by a snapshot but
  /// pruned are absent, which reads as "cannot say", never as a mismatch.
  /// Hashes are metadata over ciphertext the peer is already entitled to pull,
  /// so this reveals nothing the exchange does not.
  Future<void> _hashes(HttpRequest request) async {
    if (!_authorized(request)) {
      _json(request, HttpStatus.unauthorized, {'error': 'unauthorized'});
      return;
    }
    final params = request.uri.queryParameters;
    final device = params['device'] ?? '';
    final from = int.tryParse(params['from'] ?? '');
    final to = int.tryParse(params['to'] ?? '');
    if (device.isEmpty || from == null || to == null || from < 1 || to < from) {
      _json(request, HttpStatus.badRequest, {'error': 'invalid range'});
      return;
    }
    // Bounded so one request cannot ask us to read the whole store; the
    // caller checks a recent window, not the entire history.
    final capped = to > from + _maxHashRange ? from + _maxHashRange : to;
    final hashes = await _db.syncPacketHashes(device, from: from, to: capped);
    _json(request, HttpStatus.ok, {
      'hashes': {
        for (final entry in hashes.entries) entry.key.toString(): entry.value,
      },
    });
    final log = await _serveLog(request);
    log?.add(SyncLogKind.serveHashes,
        direction: 'out',
        originDevice: device,
        message: 'Peer verified stream #$from–#$capped '
            '(${hashes.length} hash(es) answered)');
    await log?.finish();
  }

  /// Most counters one hash query may span.
  static const int _maxHashRange = 500;

  /// Serve one attachment blob by content id (docs/P2P_SYNC.md §3.5),
  /// encrypted for the wire the same way the relay stores it. The bytes come
  /// from whichever attachment row holds that content; 404 when none does —
  /// including when this node itself is still waiting for them.
  ///
  /// Honours a single-range `Range: bytes=<from>-<to>` so a peer can pull a
  /// large attachment in pieces and resume a broken transfer, answering 206
  /// with a `Content-Range`. Anything else — no header, a form we do not
  /// parse, multiple ranges — is served whole, which is what the requester
  /// falls back to anyway.
  Future<void> _blob(HttpRequest request, String blobId) async {
    if (!_authorized(request)) {
      _json(request, HttpStatus.unauthorized, {'error': 'unauthorized'});
      return;
    }
    if (!BlobRef.isValidId(blobId)) {
      _json(request, HttpStatus.badRequest, {'error': 'invalid blob id'});
      return;
    }
    final encrypted = await _encryptedBlob(blobId);
    if (encrypted == null) {
      _json(request, HttpStatus.notFound, {'error': 'not held'});
      final log = await _serveLog(request);
      log?.add(SyncLogKind.serveBlob,
          direction: 'out',
          packetHash: blobId,
          message: 'Attachment ${blobId.substring(0, 12)}… requested but not '
              'held here');
      await log?.finish();
      return;
    }

    final range = _parseRange(
        request.headers.value(HttpHeaders.rangeHeader), encrypted.length);
    // One event per attachment, when its last byte goes out — not one per
    // chunk of a large transfer.
    if (range == null || range.end + 1 >= encrypted.length) {
      final log = await _serveLog(request);
      log?.add(SyncLogKind.serveBlob,
          direction: 'out',
          packetHash: blobId,
          message: 'Attachment ${blobId.substring(0, 12)}… served',
          detail: {'bytes': encrypted.length});
      await log?.finish();
    }
    if (range == null) {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.binary
        ..contentLength = encrypted.length
        ..add(encrypted);
      await request.response.close();
      return;
    }
    if (range.start >= encrypted.length) {
      request.response
        ..statusCode = HttpStatus.requestedRangeNotSatisfiable
        ..headers.set(HttpHeaders.contentRangeHeader,
            'bytes */${encrypted.length}');
      await request.response.close();
      return;
    }

    final slice = encrypted.sublist(range.start, range.end + 1);
    request.response
      ..statusCode = HttpStatus.partialContent
      ..headers.contentType = ContentType.binary
      ..headers.set(HttpHeaders.contentRangeHeader,
          'bytes ${range.start}-${range.end}/${encrypted.length}')
      ..contentLength = slice.length
      ..add(slice);
    await request.response.close();
  }

  /// The wire form of [blobId], held briefly so the ranges of one transfer
  /// come out of a single ciphertext.
  ///
  /// Every encryption uses a fresh nonce, so re-encrypting per request would
  /// hand out slices of *different* ciphertexts and the requester's AEAD tag
  /// check would fail on the join. It would only fail — never silently
  /// corrupt — but it would also never succeed, so the transfer needs one
  /// stable answer to slice up. The entry is dropped once it has gone unread
  /// for [_blobCacheTtl]; a peer that restarts mid-transfer simply makes the
  /// requester start that blob again.
  Future<List<int>?> _encryptedBlob(String blobId) async {
    final now = DateTime.now();
    _blobCache.removeWhere((_, e) => now.difference(e.touched) > _blobCacheTtl);

    final cached = _blobCache[blobId];
    if (cached != null) {
      _blobCache[blobId] = (bytes: cached.bytes, touched: now);
      return cached.bytes;
    }

    final content = await _db.findBlobLocally(blobId);
    if (content == null) return null;
    final encrypted =
        await _crypto.encrypt(content, aad: SyncCrypto.blobAad(blobId));
    // Only worth holding for something big enough to be fetched in pieces.
    if (encrypted.length > _blobChunkThreshold) {
      _blobCache[blobId] = (bytes: encrypted, touched: now);
    }
    return encrypted;
  }

  /// A single `bytes=<from>-<to>` range clamped to [length], or null for any
  /// header this server does not serve piecewise.
  static ({int start, int end})? _parseRange(String? header, int length) {
    if (header == null) return null;
    final match =
        RegExp(r'^bytes=(\d+)-(\d*)$').firstMatch(header.trim().toLowerCase());
    if (match == null) return null;
    final start = int.parse(match.group(1)!);
    final endGroup = match.group(2)!;
    final end = endGroup.isEmpty
        ? length - 1
        : min(int.parse(endGroup), length - 1);
    if (end < start) return null;
    return (start: start, end: end);
  }

  /// Ciphertexts kept alive across the requests of one ranged transfer.
  final Map<String, ({List<int> bytes, DateTime touched})> _blobCache = {};

  /// How long an unread cached ciphertext survives.
  static const Duration _blobCacheTtl = Duration(minutes: 2);

  /// Below this, caching the ciphertext costs more than it saves — such a
  /// blob arrives in one chunk anyway.
  static const int _blobChunkThreshold = 256 * 1024;

  /// Compare two hex digests without leaking the mismatch position via timing.
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
