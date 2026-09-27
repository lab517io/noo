import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/history_service.dart';
import 'package:noo/data/services/lan_sync_coordinator.dart';
import 'package:noo/data/services/peer_api_client.dart';
import 'package:noo/data/services/peer_discovery.dart';
import 'package:noo/data/services/peer_sync_server.dart';
import 'package:noo/data/services/sync_crypto.dart';
import 'package:noo/data/services/sync_service.dart';
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

    test('a started session reports the name the peer announced', () async {
      String? seenName;
      String? seenDevice;
      await startServers();
      await serverB!.stop();
      serverB = PeerSyncServer(
        db: b.db,
        crypto: b.crypto,
        deviceId: 'device-b',
        onSessionStarted: (deviceId, deviceName) {
          seenDevice = deviceId;
          seenName = deviceName;
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

    test('a bad proof never gets a session', () async {
      var started = false;
      await startServers();
      await serverB!.stop();
      serverB = PeerSyncServer(
        db: b.db,
        crypto: b.crypto,
        deviceId: 'device-b',
        onSessionStarted: (_, _) => started = true,
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

      expect(started, isFalse);
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
    late ({SyncService sync, SyncCrypto crypto, NooDatabase db}) a;
    late ({SyncService sync, SyncCrypto crypto, NooDatabase db}) b;
    late LanSyncCoordinator coordinatorA;
    late LanSyncCoordinator coordinatorB;

    setUp(() async {
      a = _node('device-a');
      b = _node('device-b');
      await a.sync.prepareCrypto();
      await b.sync.prepareCrypto();
      coordinatorA = LanSyncCoordinator(
        db: a.db,
        crypto: a.crypto,
        syncService: a.sync,
        deviceId: 'device-a',
        deviceName: 'Laptop',
        followerGrace: const Duration(milliseconds: 300),
      );
      coordinatorB = LanSyncCoordinator(
        db: b.db,
        crypto: b.crypto,
        syncService: b.sync,
        deviceId: 'device-b',
        deviceName: 'Phone',
        followerGrace: const Duration(milliseconds: 300),
      );
    });

    tearDown(() async {
      await coordinatorA.dispose();
      await coordinatorB.dispose();
      await a.db.close();
      await b.db.close();
    });

    LanPeer peerOf(String deviceId, LanSyncCoordinator coordinator) => LanPeer(
          deviceId: deviceId,
          address: InternetAddress('127.0.0.1'),
          tcpPort: coordinator.peerPort,
          lastSeen: DateTime.now(),
        );

    Future<void> until(Future<bool> Function() condition) async {
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (!await condition() && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }

    LanPeerState? stateOf(LanSyncCoordinator c, String deviceId) => c
        .peerStatuses
        .where((s) => s.deviceId == deviceId)
        .firstOrNull
        ?.state;

    test('nothing listens until a session is started', () async {
      expect(coordinatorA.isRunning, isFalse);
      expect(coordinatorA.peerPort, 0);

      await coordinatorA.startSession(discover: false);
      expect(coordinatorA.isRunning, isTrue);
      expect(coordinatorA.peerPort, greaterThan(0));

      final port = coordinatorA.peerPort;
      await coordinatorA.stopSession();
      expect(coordinatorA.isRunning, isFalse);
      await expectLater(
        Socket.connect('127.0.0.1', port),
        throwsA(isA<SocketException>()),
        reason: 'a closed session must not leave the peer server reachable',
      );
    });

    test('a peer found during a session is synced both ways', () async {
      await coordinatorA.startSession(discover: false);
      await coordinatorB.startSession(discover: false);

      final widA = WorldId.create();
      final widB = WorldId.create();
      await a.db.createTask(worldId: widA.value, title: 'From A');
      await b.db.createTask(worldId: widB.value, title: 'From B');

      // Stand in for discovery on both sides. A has the lower id, so it
      // leads; B waits for A's request instead of starting its own exchange.
      coordinatorA.peerFound(peerOf('device-b', coordinatorB));
      coordinatorB.peerFound(peerOf('device-a', coordinatorA));

      await until(() async =>
          stateOf(coordinatorA, 'device-b') == LanPeerState.synced &&
          stateOf(coordinatorB, 'device-a') == LanPeerState.synced);

      expect((await a.db.getTaskByWorldId(widB.value))?.title, 'From B');
      expect((await b.db.getTaskByWorldId(widA.value))?.title, 'From A');

      // Each side learned the other's name from its authentication.
      expect(coordinatorA.peerStatuses.single.label, 'Phone');
      expect(coordinatorB.peerStatuses.single.label, 'Laptop');
    });

    test('a follower syncs on its own when the leader never asks', () async {
      // Only B's discovery saw the other side. B follows (higher id), so it
      // waits out its grace period and then leads the exchange itself.
      await coordinatorA.startSession(discover: false);
      await coordinatorB.startSession(discover: false);

      final wid = WorldId.create();
      await a.db.createTask(worldId: wid.value, title: 'From A');

      coordinatorB.peerFound(peerOf('device-a', coordinatorA));
      expect(stateOf(coordinatorB, 'device-a'), LanPeerState.found);

      await until(() async => await b.db.getTaskByWorldId(wid.value) != null);
      expect((await b.db.getTaskByWorldId(wid.value))?.title, 'From A');
    });

    test('an exchange asked for by a peer does not ask back', () async {
      // The ping-pong guard: B answers A's sync-request by pulling from A, and
      // must not send A a sync-request of its own — otherwise two devices
      // would trade requests forever off a single exchange.
      var requestsBackToA = 0;
      final serverA = PeerSyncServer(
        db: a.db,
        crypto: a.crypto,
        deviceId: 'device-a',
        onSyncRequested: (_, _, _) => requestsBackToA++,
        beforeServe: a.sync.packageLocalChanges,
      );
      await serverA.start();

      try {
        await coordinatorB.startSession(discover: false);

        final wid = WorldId.create();
        await a.db.createTask(worldId: wid.value, title: 'From A');

        final toB = PeerApiClient(
          host: '127.0.0.1',
          port: coordinatorB.peerPort,
          peerDeviceId: 'device-b',
          ownDeviceId: 'device-a',
          crypto: a.crypto,
        );
        await toB.requestSync(callbackPort: serverA.port);
        toB.dispose();

        await until(() async => await b.db.getTaskByWorldId(wid.value) != null);

        expect((await b.db.getTaskByWorldId(wid.value))?.title, 'From A',
            reason: 'B should have pulled from A when asked');
        expect(requestsBackToA, 0,
            reason: 'a requested exchange must not request one in return');
      } finally {
        await serverA.stop();
      }
    });

    test('a peer that cannot be reached is reported as failed', () async {
      await coordinatorA.startSession(discover: false);
      // A leads against a port nothing listens on.
      coordinatorA.peerFound(LanPeer(
        deviceId: 'device-b',
        address: InternetAddress('127.0.0.1'),
        tcpPort: 1,
        lastSeen: DateTime.now(),
      ));
      await until(() async =>
          stateOf(coordinatorA, 'device-b') == LanPeerState.failed);
      expect(stateOf(coordinatorA, 'device-b'), LanPeerState.failed);
      expect(coordinatorA.peerStatuses.single.error, isNotNull);
    });

    test('peers found outside a session are ignored', () async {
      coordinatorA.peerFound(peerOf('device-b', coordinatorB));
      expect(coordinatorA.peerStatuses, isEmpty);
    });
  });
}
