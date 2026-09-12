import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/history_service.dart';
import 'package:noo/data/services/lan_sync_coordinator.dart';
import 'package:noo/data/services/peer_api_client.dart';
import 'package:noo/data/services/peer_discovery.dart';
import 'package:noo/data/services/peer_sync_server.dart';
import 'package:noo/data/services/sync_api_client.dart';
import 'package:noo/data/services/sync_crypto.dart';
import 'package:noo/data/services/sync_service.dart';
import 'package:noo/data/services/trusted_peers.dart';
import 'package:noo/domain/entities/sync_config.dart';
import 'package:noo/domain/entities/world_id.dart';

({SyncService sync, SyncCrypto crypto, NooDatabase db}) _node(String deviceId) {
  final db = NooDatabase.memory();
  final crypto = SyncCrypto();
  final sync = SyncService(
    db: db,
    // Identity only — no server URL, no server password. A P2P-only user.
    config: SyncConfig(
      enabled: true,
      username: 'alice',
      deviceId: deviceId,
    ),
    crypto: crypto,
    historyService: HistoryService(db),
    databasePassword: 'shared-pw',
  );
  return (sync: sync, crypto: crypto, db: db);
}

void main() {
  // No TestWidgetsFlutterBinding: these tests use real loopback HTTP, and the
  // widgets binding installs an HttpClient mock that answers 400 to
  // everything.

  group('user-initiated LAN sync', () {
    late ({SyncService sync, SyncCrypto crypto, NooDatabase db}) a;
    late ({SyncService sync, SyncCrypto crypto, NooDatabase db}) b;
    PeerSyncServer? serverA;
    PeerSyncServer? serverB;

    setUp(() async {
      a = _node('device-a');
      b = _node('device-b');
      await a.sync.prepareCrypto();
      await b.sync.prepareCrypto();
    });

    tearDown(() async {
      await serverA?.stop();
      await serverB?.stop();
      await a.db.close();
      await b.db.close();
    });

    /// Wires both sides the way [LanSyncCoordinator] does — including the
    /// reciprocal sync-request handler — without discovery or any timer.
    Future<void> startServers({
      void Function(String, InternetAddress, int)? onRequestToA,
      void Function(String, InternetAddress, int)? onRequestToB,
    }) async {
      serverA = PeerSyncServer(
        db: a.db,
        crypto: a.crypto,
        deviceId: 'device-a',
        onSyncRequested: onRequestToA,
        beforeServe: a.sync.packageLocalChanges,
      );
      serverB = PeerSyncServer(
        db: b.db,
        crypto: b.crypto,
        deviceId: 'device-b',
        onSyncRequested: onRequestToB,
        beforeServe: b.sync.packageLocalChanges,
      );
      await serverA!.start();
      await serverB!.start();
    }

    test('one press converges both devices', () async {
      // B answers A's sync-request by pulling from A, which is exactly what
      // the coordinator's onSyncRequested does.
      final reciprocated = Completer<void>();
      await startServers(
        onRequestToB: (deviceId, address, port) async {
          expect(deviceId, 'device-a');
          final client = PeerApiClient(
            host: address.address,
            port: port,
            peerDeviceId: 'device-a',
            ownDeviceId: 'device-b',
            crypto: b.crypto,
          );
          try {
            await b.sync.exchangeWithSource(client);
          } finally {
            client.dispose();
            reciprocated.complete();
          }
        },
      );

      final widA = WorldId.create();
      final widB = WorldId.create();
      await a.db.createTask(worldId: widA.value, title: 'From A');
      await b.db.createTask(worldId: widB.value, title: 'From B');

      // A presses sync: pull from B, then ask B to pull back.
      final aToB = PeerApiClient(
        host: '127.0.0.1',
        port: serverB!.port,
        peerDeviceId: 'device-b',
        ownDeviceId: 'device-a',
        crypto: a.crypto,
      );
      await a.sync.exchangeWithSource(aToB);
      await aToB.requestSync(callbackPort: serverA!.port);
      aToB.dispose();

      await reciprocated.future.timeout(const Duration(seconds: 10));

      // Both directions landed from the single press on A.
      expect((await a.db.getTaskByWorldId(widB.value))?.title, 'From B');
      expect((await b.db.getTaskByWorldId(widA.value))?.title, 'From A');
    });

    test('a declined peer gets no session and no data', () async {
      await startServers();
      serverB = PeerSyncServer(
        db: b.db,
        crypto: b.crypto,
        deviceId: 'device-b',
        approveSession: (_, _) async => false,
        beforeServe: b.sync.packageLocalChanges,
      );
      await serverB!.start();

      final wid = WorldId.create();
      await b.db.createTask(worldId: wid.value, title: 'Private to B');

      final client = PeerApiClient(
        host: '127.0.0.1',
        port: serverB!.port,
        peerDeviceId: 'device-b',
        ownDeviceId: 'device-a',
        crypto: a.crypto,
      );

      // The handshake itself fails, so the vector is never even requested —
      // a "no" must not leak what B holds.
      await expectLater(
        client.getVector(),
        throwsA(isA<SyncApiException>()
            .having((e) => e.statusCode, 'statusCode', HttpStatus.forbidden)),
      );
      client.dispose();

      expect(await a.db.getTaskByWorldId(wid.value), isNull);
    });

    test('the confirmation sees the name the peer announced', () async {
      String? seenName;
      String? seenDevice;
      await startServers();
      serverB = PeerSyncServer(
        db: b.db,
        crypto: b.crypto,
        deviceId: 'device-b',
        approveSession: (deviceId, deviceName) async {
          seenDevice = deviceId;
          seenName = deviceName;
          return true;
        },
      );
      await serverB!.start();

      final client = PeerApiClient(
        host: '127.0.0.1',
        port: serverB!.port,
        peerDeviceId: 'device-b',
        ownDeviceId: 'device-a',
        ownDeviceName: "Dmytro's Laptop",
        crypto: a.crypto,
      );
      await client.getVector();
      client.dispose();

      expect(seenDevice, 'device-a');
      expect(seenName, "Dmytro's Laptop");
    });

    test('a bad proof is rejected before the user is ever asked', () async {
      var asked = false;
      await startServers();
      serverB = PeerSyncServer(
        db: b.db,
        crypto: b.crypto,
        deviceId: 'device-b',
        approveSession: (_, _) async {
          asked = true;
          return true;
        },
      );
      await serverB!.start();

      // Keys never derived, so the proof cannot match.
      final client = PeerApiClient(
        host: '127.0.0.1',
        port: serverB!.port,
        peerDeviceId: 'device-b',
        ownDeviceId: 'device-x',
        crypto: SyncCrypto(),
      );
      await expectLater(client.authenticate(), throwsA(isA<Object>()));
      client.dispose();

      expect(asked, isFalse,
          reason: 'a stranger must not be able to raise a prompt on this '
              'device by connecting to it');
    });

    test('sync-request without a session is rejected', () async {
      var called = false;
      await startServers(onRequestToB: (_, _, _) => called = true);

      final response = await HttpClient()
          .postUrl(Uri.parse(
              'http://127.0.0.1:${serverB!.port}${PeerProtocol.basePath}/sync-request'))
          .then((request) {
        request.headers.contentType = ContentType.json;
        request.write('{"port": 1234}');
        return request.close();
      });

      expect(response.statusCode, HttpStatus.unauthorized);
      expect(called, isFalse, reason: 'an unauthenticated peer must not be '
          'able to make us start an exchange');
    });

    test('a sync-request carries the caller identity, not a claimed one',
        () async {
      String? seenDevice;
      await startServers(
        onRequestToB: (deviceId, _, _) => seenDevice = deviceId,
      );

      final client = PeerApiClient(
        host: '127.0.0.1',
        port: serverB!.port,
        peerDeviceId: 'device-b',
        ownDeviceId: 'device-a',
        crypto: a.crypto,
      );
      await client.requestSync(callbackPort: serverA!.port);
      client.dispose();

      // Taken from the authenticated session, not from anything in the body.
      expect(seenDevice, 'device-a');
    });
  });

  group('LanSyncCoordinator', () {
    test('discovering a peer does not exchange anything', () async {
      final a = _node('device-a');
      final b = _node('device-b');
      await a.sync.prepareCrypto();
      await b.sync.prepareCrypto();

      final coordinator = LanSyncCoordinator(
        db: a.db,
        crypto: a.crypto,
        syncService: a.sync,
        deviceId: 'device-a',
      );
      final serverB = PeerSyncServer(
        db: b.db,
        crypto: b.crypto,
        deviceId: 'device-b',
      );
      await serverB.start();

      try {
        await coordinator.start();

        final wid = WorldId.create();
        await b.db.createTask(worldId: wid.value, title: 'From B');
        // Package B's change so it is genuinely available to be pulled.
        await b.sync.packageLocalChanges();

        // Sit with a visible peer for well over the old 30s exchange timer's
        // worth of event-loop turns. Nothing may cross without a press.
        for (var i = 0; i < 50; i++) {
          await Future<void>.delayed(Duration.zero);
        }

        expect(await a.db.getTaskByWorldId(wid.value), isNull,
            reason: 'a peer being visible must never move data on its own');
      } finally {
        await coordinator.dispose();
        await serverB.stop();
        await a.db.close();
        await b.db.close();
      }
    });

    test('an exchange asked for by a peer does not ask back', () async {
      // The ping-pong guard: B answers A's sync-request by pulling from A, and
      // must not send A a sync-request of its own — otherwise two devices
      // would trade requests forever off a single press.
      final a = _node('device-a');
      final b = _node('device-b');
      await a.sync.prepareCrypto();
      await b.sync.prepareCrypto();

      var requestsBackToA = 0;
      final serverA = PeerSyncServer(
        db: a.db,
        crypto: a.crypto,
        deviceId: 'device-a',
        onSyncRequested: (_, _, _) => requestsBackToA++,
        beforeServe: a.sync.packageLocalChanges,
      );
      await serverA.start();

      final coordinatorB = LanSyncCoordinator(
        db: b.db,
        crypto: b.crypto,
        syncService: b.sync,
        deviceId: 'device-b',
      );

      try {
        await coordinatorB.start();

        final wid = WorldId.create();
        await a.db.createTask(worldId: wid.value, title: 'From A');

        // Stand in for A's half of a press: ask B to pull from us.
        final toB = PeerApiClient(
          host: '127.0.0.1',
          port: coordinatorB.peerPort,
          peerDeviceId: 'device-b',
          ownDeviceId: 'device-a',
          crypto: a.crypto,
        );
        await toB.requestSync(callbackPort: serverA.port);
        toB.dispose();

        // B's exchange is detached from the request; wait for it to land.
        final deadline = DateTime.now().add(const Duration(seconds: 10));
        while (await b.db.getTaskByWorldId(wid.value) == null &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }

        expect((await b.db.getTaskByWorldId(wid.value))?.title, 'From A',
            reason: 'B should have pulled from A when asked');
        expect(requestsBackToA, 0,
            reason: 'a requested exchange must not request one in return');
      } finally {
        await coordinatorB.dispose();
        await serverA.stop();
        await a.db.close();
        await b.db.close();
      }
    });

    test('one press asks the other device once, and converges both', () async {
      final a = _node('device-a');
      final b = _node('device-b');
      await a.sync.prepareCrypto();
      await b.sync.prepareCrypto();

      final promptsOnA = <String>[];
      final promptsOnB = <String>[];

      final coordinatorA = LanSyncCoordinator(
        db: a.db,
        crypto: a.crypto,
        syncService: a.sync,
        deviceId: 'device-a',
        deviceName: 'Laptop',
        confirmIncomingSync: (id, _) async {
          promptsOnA.add(id);
          return true;
        },
      );
      final coordinatorB = LanSyncCoordinator(
        db: b.db,
        crypto: b.crypto,
        syncService: b.sync,
        deviceId: 'device-b',
        deviceName: 'Phone',
        confirmIncomingSync: (id, _) async {
          promptsOnB.add(id);
          return true;
        },
      );

      try {
        await coordinatorA.start();
        await coordinatorB.start();

        final widA = WorldId.create();
        final widB = WorldId.create();
        await a.db.createTask(worldId: widA.value, title: 'From A');
        await b.db.createTask(worldId: widB.value, title: 'From B');

        // A's user presses sync. Stand in for discovery with the real port.
        final outcome = await coordinatorA.syncWith([
          LanPeer(
            deviceId: 'device-b',
            address: InternetAddress('127.0.0.1'),
            tcpPort: coordinatorB.peerPort,
            lastSeen: DateTime.now(),
          ),
        ]);

        expect(outcome.peersSynced, 1);
        expect(outcome.peersDeclined, 0);

        // B's reciprocal pull is detached from the request; wait for it.
        final deadline = DateTime.now().add(const Duration(seconds: 10));
        while (await b.db.getTaskByWorldId(widA.value) == null &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }

        expect((await a.db.getTaskByWorldId(widB.value))?.title, 'From B');
        expect((await b.db.getTaskByWorldId(widA.value))?.title, 'From A');

        // Exactly one person was asked: the one who did not press the button.
        expect(promptsOnB, ['device-a']);
        expect(promptsOnA, isEmpty,
            reason: 'the device that pressed sync must not be asked to '
                'confirm the return leg of its own request');
      } finally {
        await coordinatorA.dispose();
        await coordinatorB.dispose();
        await a.db.close();
        await b.db.close();
      }
    });

    test('a declined press moves nothing and is reported as declined',
        () async {
      final a = _node('device-a');
      final b = _node('device-b');
      await a.sync.prepareCrypto();
      await b.sync.prepareCrypto();

      final coordinatorA = LanSyncCoordinator(
        db: a.db,
        crypto: a.crypto,
        syncService: a.sync,
        deviceId: 'device-a',
      );
      final coordinatorB = LanSyncCoordinator(
        db: b.db,
        crypto: b.crypto,
        syncService: b.sync,
        deviceId: 'device-b',
        confirmIncomingSync: (_, _) async => false,
      );

      try {
        await coordinatorA.start();
        await coordinatorB.start();

        final widA = WorldId.create();
        final widB = WorldId.create();
        await a.db.createTask(worldId: widA.value, title: 'From A');
        await b.db.createTask(worldId: widB.value, title: 'From B');

        final outcome = await coordinatorA.syncWith([
          LanPeer(
            deviceId: 'device-b',
            address: InternetAddress('127.0.0.1'),
            tcpPort: coordinatorB.peerPort,
            lastSeen: DateTime.now(),
          ),
        ]);

        expect(outcome.peersDeclined, 1);
        expect(outcome.peersSynced, 0);
        expect(outcome.peersFailed, 0);
        expect(outcome.changesApplied, 0);

        // Neither direction moved: "no" stops the whole exchange, not just
        // the half that would have come back.
        expect(await a.db.getTaskByWorldId(widB.value), isNull);
        expect(await b.db.getTaskByWorldId(widA.value), isNull);
      } finally {
        await coordinatorA.dispose();
        await coordinatorB.dispose();
        await a.db.close();
        await b.db.close();
      }
    });

    test('a trusted device syncs without a prompt', () async {
      final a = _node('device-a');
      final b = _node('device-b');
      await a.sync.prepareCrypto();
      await b.sync.prepareCrypto();

      // B has previously ticked "always allow" for A.
      final trustedOnB = TrustedPeers(b.db);
      await trustedOnB.trust('device-a', 'Laptop');

      var prompted = 0;
      final coordinatorA = LanSyncCoordinator(
        db: a.db,
        crypto: a.crypto,
        syncService: a.sync,
        deviceId: 'device-a',
      );
      final coordinatorB = LanSyncCoordinator(
        db: b.db,
        crypto: b.crypto,
        syncService: b.sync,
        deviceId: 'device-b',
        confirmIncomingSync: (deviceId, deviceName) async {
          if (await trustedOnB.isTrusted(deviceId)) return true;
          prompted++;
          return false;
        },
      );

      try {
        await coordinatorA.start();
        await coordinatorB.start();

        final wid = WorldId.create();
        await b.db.createTask(worldId: wid.value, title: 'From B');

        final outcome = await coordinatorA.syncWith([
          LanPeer(
            deviceId: 'device-b',
            address: InternetAddress('127.0.0.1'),
            tcpPort: coordinatorB.peerPort,
            lastSeen: DateTime.now(),
          ),
        ]);

        expect(outcome.peersSynced, 1);
        expect(prompted, 0, reason: 'a trusted device must not be asked about');
        expect((await a.db.getTaskByWorldId(wid.value))?.title, 'From B');
      } finally {
        await coordinatorA.dispose();
        await coordinatorB.dispose();
        await a.db.close();
        await b.db.close();
      }
    });

    test('syncNow reports when nothing is nearby', () async {
      final a = _node('device-a');
      await a.sync.prepareCrypto();
      final coordinator = LanSyncCoordinator(
        db: a.db,
        crypto: a.crypto,
        syncService: a.sync,
        deviceId: 'device-a',
      );
      try {
        await coordinator.start();
        final outcome = await coordinator.syncNow();
        expect(outcome.noPeers, isTrue);
        expect(outcome.changesApplied, 0);
      } finally {
        await coordinator.dispose();
        await a.db.close();
      }
    });

    test('syncNow on a stopped coordinator reports unavailable', () async {
      final a = _node('device-a');
      final coordinator = LanSyncCoordinator(
        db: a.db,
        crypto: a.crypto,
        syncService: a.sync,
        deviceId: 'device-a',
      );
      try {
        expect((await coordinator.syncNow()).unavailable, isTrue);
      } finally {
        await coordinator.dispose();
        await a.db.close();
      }
    });
  });
}
