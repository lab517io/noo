import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/history_service.dart';
import 'package:noo/data/services/peer_api_client.dart';
import 'package:noo/data/services/peer_sync_server.dart';
import 'package:noo/data/services/sync_crypto.dart';
import 'package:noo/data/services/sync_service.dart';
import 'package:noo/domain/entities/sync_config.dart';
import 'package:noo/domain/entities/world_id.dart';

({SyncService sync, SyncCrypto crypto, NooDatabase db}) _node(
    String deviceId, String password) {
  final db = NooDatabase.memory();
  final crypto = SyncCrypto();
  // No server URL and no server password: these nodes are configured exactly
  // as a P2P-only user's would be, so the test also proves LAN sync needs no
  // relay account.
  final config = SyncConfig(
    enabled: true,
    username: 'alice',
    deviceId: deviceId,
  );
  final sync = SyncService(
    db: db,
    config: config,
    crypto: crypto,
    historyService: HistoryService(db),
    databasePassword: password,
  );
  return (sync: sync, crypto: crypto, db: db);
}

void main() {
  // Deliberately NO TestWidgetsFlutterBinding.ensureInitialized(): the widgets
  // binding replaces HttpClient with a mock that answers 400 to everything,
  // and these tests exercise real loopback HTTP against the embedded server.

  group('LAN peer sync over loopback HTTP', () {
    test('two devices converge through their embedded peer servers', () async {
      final a = _node('device-a', 'shared-pw');
      final b = _node('device-b', 'shared-pw');
      await a.sync.prepareCrypto();
      await b.sync.prepareCrypto();

      final serverA = PeerSyncServer(
          db: a.db, crypto: a.crypto, deviceId: 'device-a');
      final serverB = PeerSyncServer(
          db: b.db, crypto: b.crypto, deviceId: 'device-b');
      await serverA.start();
      await serverB.start();

      try {
        final widA = WorldId.create();
        final widB = WorldId.create();
        await a.db.createTask(worldId: widA.value, title: 'From A');
        await b.db.createTask(worldId: widB.value, title: 'From B');

        PeerApiClient clientTo(PeerSyncServer server, String peerDevice,
                String ownDevice, SyncCrypto crypto) =>
            PeerApiClient(
              host: '127.0.0.1',
              port: server.port,
              peerDeviceId: peerDevice,
              ownDeviceId: ownDevice,
              crypto: crypto,
            );

        // A packages and pulls from B (B has nothing packaged yet)...
        final aToB = clientTo(serverB, 'device-b', 'device-a', a.crypto);
        expect(await a.sync.exchangeWithSource(aToB), 0);
        aToB.dispose();

        // ...B packages and pulls A's task...
        final bToA = clientTo(serverA, 'device-a', 'device-b', b.crypto);
        expect(await b.sync.exchangeWithSource(bToA), greaterThan(0));
        bToA.dispose();

        // ...and A pulls B's task on the next exchange.
        final aToB2 = clientTo(serverB, 'device-b', 'device-a', a.crypto);
        expect(await a.sync.exchangeWithSource(aToB2), greaterThan(0));
        aToB2.dispose();

        expect((await a.db.getTaskByWorldId(widB.value))?.title, 'From B');
        expect((await b.db.getTaskByWorldId(widA.value))?.title, 'From A');
      } finally {
        await serverA.stop();
        await serverB.stop();
        await a.db.close();
        await b.db.close();
      }
    });

    test('a peer with a different database password fails mutual auth',
        () async {
      final a = _node('device-a', 'password-one');
      final b = _node('device-b', 'password-two');
      await a.sync.prepareCrypto();
      await b.sync.prepareCrypto();

      final serverB = PeerSyncServer(
          db: b.db, crypto: b.crypto, deviceId: 'device-b');
      await serverB.start();

      try {
        final client = PeerApiClient(
          host: '127.0.0.1',
          port: serverB.port,
          peerDeviceId: 'device-b',
          ownDeviceId: 'device-a',
          crypto: a.crypto,
        );
        await expectLater(client.authenticate(), throwsA(isA<Exception>()));
        client.dispose();
      } finally {
        await serverB.stop();
        await a.db.close();
        await b.db.close();
      }
    });

    test('unauthenticated requests are rejected', () async {
      final b = _node('device-b', 'shared-pw');
      await b.sync.prepareCrypto();
      final serverB = PeerSyncServer(
          db: b.db, crypto: b.crypto, deviceId: 'device-b');
      await serverB.start();

      try {
        // A forged session token must not expose the vector.
        final client = PeerApiClient(
          host: '127.0.0.1',
          port: serverB.port,
          peerDeviceId: 'device-b',
          ownDeviceId: 'device-x',
          crypto: SyncCrypto(), // keys never derived — auth cannot succeed
        );
        await expectLater(client.getVector(), throwsA(isA<Object>()));
        client.dispose();
      } finally {
        await serverB.stop();
        await b.db.close();
      }
    });

    test('carried packets gossip through an intermediary peer', () async {
      // A and B exchange; B carries A's packets. A third device C that only
      // ever talks to B must still receive A's data.
      final a = _node('device-a', 'shared-pw');
      final b = _node('device-b', 'shared-pw');
      final c = _node('device-c', 'shared-pw');
      await a.sync.prepareCrypto();
      await b.sync.prepareCrypto();
      await c.sync.prepareCrypto();

      final serverA = PeerSyncServer(
          db: a.db, crypto: a.crypto, deviceId: 'device-a');
      final serverB = PeerSyncServer(
          db: b.db, crypto: b.crypto, deviceId: 'device-b');
      await serverA.start();
      await serverB.start();

      try {
        final wid = WorldId.create();
        final taskId = await a.db.createTask(
            worldId: wid.value, title: 'Travels far');
        await a.db.createAttachment(
          taskId: taskId,
          worldId: WorldId.create().value,
          filename: 'carried.txt',
          content: Uint8List.fromList([1, 2, 3]),
        );

        // A must package before B can pull; exchange with B's server does it.
        final aToB = clientFor(serverB, 'device-b', 'device-a', a.crypto);
        await a.sync.exchangeWithSource(aToB);
        aToB.dispose();

        final bToA = clientFor(serverA, 'device-a', 'device-b', b.crypto);
        await b.sync.exchangeWithSource(bToA);
        bToA.dispose();

        // C talks only to B.
        final cToB = clientFor(serverB, 'device-b', 'device-c', c.crypto);
        final applied = await c.sync.exchangeWithSource(cToB);
        cToB.dispose();

        expect(applied, greaterThan(0));
        final taskOnC = await c.db.getTaskByWorldId(wid.value);
        expect(taskOnC?.title, 'Travels far');
        final filesOnC = await c.db.getAttachmentsForTask(taskOnC!.id);
        expect(filesOnC.single.filename, 'carried.txt');
      } finally {
        await serverA.stop();
        await serverB.stop();
        await a.db.close();
        await b.db.close();
        await c.db.close();
      }
    });
  });

  group('peer blob ranges', () {
    test('a peer serves a blob in verifiable pieces', () async {
      final a = _node('device-a', 'shared-pw');
      final b = _node('device-b', 'shared-pw');
      await a.sync.prepareCrypto();
      await b.sync.prepareCrypto();

      // Bigger than the server's caching threshold, so the ranges of one
      // transfer come out of a single ciphertext — every encryption uses a
      // fresh nonce, and slices of two of them would not join.
      final content =
          Uint8List.fromList(List.generate(512 * 1024, (i) => i % 251));
      final taskId = await a.db.createTask(worldId: 'w-t', title: 'owner');
      await a.db.createAttachment(
          taskId: taskId,
          worldId: 'w-f',
          filename: 'big.opus',
          content: content);
      final hash = NooDatabase.blobId(content);

      final serverA =
          PeerSyncServer(db: a.db, crypto: a.crypto, deviceId: 'device-a');
      await serverA.start();
      final client = clientFor(serverA, 'device-a', 'device-b', b.crypto);
      try {
        const chunk = 64 * 1024;
        final joined = <int>[];
        int? total;
        while (total == null || joined.length < total) {
          final slice = await client.getBlobSlice(hash,
              offset: joined.length, length: chunk);
          expect(slice, isNotNull);
          expect(slice!.partial, isTrue, reason: 'the peer answered 206');
          expect(slice.offset, joined.length);
          expect(slice.bytes.length, lessThanOrEqualTo(chunk));
          total = slice.total;
          expect(total, isNotNull, reason: 'Content-Range carries the length');
          joined.addAll(slice.bytes);
        }
        expect(joined.length, greaterThan(content.length),
            reason: 'ciphertext carries nonce and tag on top of the plaintext');

        // The join decrypts, which is the real assertion: the pieces came from
        // one ciphertext, not from a fresh encryption per request.
        final plain = await b.crypto.decrypt(Uint8List.fromList(joined),
            aad: SyncCrypto.blobAad(hash));
        expect(plain, content);
        expect(NooDatabase.blobId(plain), hash);
      } finally {
        client.dispose();
        await serverA.stop();
        await a.db.close();
        await b.db.close();
      }
    });

    test('a range past the end falls back to the whole blob', () async {
      final a = _node('device-a', 'shared-pw');
      final b = _node('device-b', 'shared-pw');
      await a.sync.prepareCrypto();
      await b.sync.prepareCrypto();

      final content = Uint8List.fromList(List.filled(1024, 7));
      final taskId = await a.db.createTask(worldId: 'w-t', title: 'owner');
      await a.db.createAttachment(
          taskId: taskId,
          worldId: 'w-f',
          filename: 'small.bin',
          content: content);
      final hash = NooDatabase.blobId(content);

      final serverA =
          PeerSyncServer(db: a.db, crypto: a.crypto, deviceId: 'device-a');
      await serverA.start();
      final client = clientFor(serverA, 'device-a', 'device-b', b.crypto);
      try {
        // What a stale partial looks like: an offset the blob does not reach.
        final slice =
            await client.getBlobSlice(hash, offset: 1 << 20, length: 4096);
        expect(slice, isNotNull);
        expect(slice!.partial, isFalse,
            reason: '416 is answered with the whole blob instead');
        expect(slice.offset, 0);
        final plain =
            await b.crypto.decrypt(slice.bytes, aad: SyncCrypto.blobAad(hash));
        expect(plain, content);
      } finally {
        client.dispose();
        await serverA.stop();
        await a.db.close();
        await b.db.close();
      }
    });
  });

  group('peer server limits', () {
    /// POST [body] to the peer server, or null when the server dropped the
    /// connection before answering. A fresh client per call, so a connection
    /// the server closed cannot be reused for the next request.
    Future<({int status, String body})?> post(
        PeerSyncServer server, String path, List<int> body) async {
      final client = HttpClient();
      try {
        final request = await client.post('127.0.0.1', server.port, path);
        request.headers.contentType = ContentType.json;
        request.contentLength = body.length;
        request.add(body);
        final response = await request.close();
        final text = await utf8.decoder.bind(response).join();
        return (status: response.statusCode, body: text);
      } on HttpException {
        return null;
      } on SocketException {
        return null;
      } finally {
        client.close(force: true);
      }
    }

    test('a body past the cap is refused and the server goes on serving',
        () async {
      final a = _node('device-a', 'shared-pw');
      await a.sync.prepareCrypto();
      final server =
          PeerSyncServer(db: a.db, crypto: a.crypto, deviceId: 'device-a');
      await server.start();
      try {
        final oversized = utf8.encode(
            '{"nonce_a":"${'a' * (PeerProtocol.maxBodyBytes + 1024)}"}');
        final refused =
            await post(server, '${PeerProtocol.basePath}/auth/start', oversized);
        expect(refused == null || refused.status == HttpStatus.badRequest,
            isTrue,
            reason: 'either a 400 or a dropped connection, never a handshake');

        final ok = await post(server, '${PeerProtocol.basePath}/auth/start',
            utf8.encode('{"nonce_a":"real-peer"}'));
        expect(ok, isNotNull);
        expect(ok!.status, HttpStatus.ok);
        expect(jsonDecode(ok.body), containsPair('device_id', 'device-a'));
      } finally {
        await server.stop();
        await a.db.close();
      }
    });

    test('pending handshakes are capped; the oldest is dropped first',
        () async {
      final a = _node('device-a', 'shared-pw');
      await a.sync.prepareCrypto();
      final server =
          PeerSyncServer(db: a.db, crypto: a.crypto, deviceId: 'device-a');
      await server.start();
      try {
        final count = PeerProtocol.maxPendingHandshakes + 1;
        for (var i = 0; i < count; i++) {
          final started = await post(server,
              '${PeerProtocol.basePath}/auth/start',
              utf8.encode('{"nonce_a":"n$i"}'));
          expect(started?.status, HttpStatus.ok);
        }

        Future<String> complete(String nonce) async {
          final answer = await post(
              server,
              '${PeerProtocol.basePath}/auth/complete',
              utf8.encode('{"device_id":"stranger","nonce_a":"$nonce",'
                  '"proof_a":"00"}'));
          expect(answer?.status, HttpStatus.unauthorized);
          return jsonDecode(answer!.body)['error'] as String;
        }

        // The first handshake made room for the one past the cap...
        expect(await complete('n0'), 'unknown handshake');
        // ...which is still pending, and fails on its proof rather than on
        // being forgotten.
        expect(await complete('n${count - 1}'), 'bad proof');
      } finally {
        await server.stop();
        await a.db.close();
      }
    });
  });
}

PeerApiClient clientFor(PeerSyncServer server, String peerDevice,
        String ownDevice, SyncCrypto crypto) =>
    PeerApiClient(
      host: '127.0.0.1',
      port: server.port,
      peerDeviceId: peerDevice,
      ownDeviceId: ownDevice,
      crypto: crypto,
    );
