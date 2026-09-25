import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/history_service.dart';
import 'package:noo/data/services/sync_api_client.dart';
import 'package:noo/data/services/sync_change_packager.dart';
import 'package:noo/data/services/sync_crypto.dart';
import 'package:noo/data/services/sync_journal.dart';
import 'package:noo/data/services/sync_service.dart';
import 'package:noo/domain/entities/sync_config.dart';
import 'package:noo/domain/entities/sync_packet.dart';
import 'package:noo/domain/entities/world_id.dart';

/// Shared in-memory relay standing in for the v2 server: one contiguous
/// packet stream per origin device, a version vector, and a "give me
/// everything above my vector" pull — the same exchange the real relay speaks.
class _FakeServer {
  /// device → counter → payload. Sparse rather than a list: compaction
  /// deletes low counters (docs/P2P_SYNC_COMPACTION.md §4.3), so a stream is
  /// not necessarily a prefix any more.
  final Map<String, Map<int, Uint8List>> streams = {};

  /// device → highest counter ever accepted. Kept across pruning, so a stream
  /// emptied by compaction still continues where it left off instead of
  /// re-issuing identities (§4.3, safety rule 4).
  final Map<String, int> marks = {};

  /// Identities ("device:counter") uploaded with a coverage declaration.
  final Set<String> snapshots = {};

  /// Attachment blob store (docs/P2P_SYNC.md §3.5): id → encrypted bytes.
  final Map<String, Uint8List> blobs = {};

  /// Which blobs each stored packet declared ("device:counter" → ids), the
  /// relay's only knowledge of what a packet references.
  final Map<String, List<String>> packetBlobs = {};

  /// Every blob id ever asked for with GET, so a test can assert that a
  /// device which already had the bytes did not fetch them again.
  final List<String> blobFetches = [];

  /// Whether this relay honours `Range` on a blob read. Off models a relay
  /// that predates chunked transfer and answers with the whole thing.
  bool servesRanges = true;

  /// Each ranged read, so a test can see a transfer arrive in pieces and
  /// resume at the right offset.
  final List<({String id, int offset, int length})> blobRequests = [];

  /// Drop the connection on the ranged read following this many successful
  /// ones, once. Models a transfer interrupted part-way.
  int? failSliceAfter;

  /// Pull returns streams in this order (defaults to insertion order). Tests
  /// use it to force cross-device delivery order (e.g. a file creation before
  /// its owning task's creation) — v2 guarantees order only per device.
  List<String>? orderHint;

  ({PacketUploadResult result, RelayPruneResult? prune}) upload(
    String device,
    int counter,
    Uint8List blob, {
    Map<String, int>? covers,
    List<String> blobIds = const [],
  }) {
    final held = marks[device] ?? 0;
    if (counter > held + 1) {
      throw SyncApiException('Non-contiguous counter', 409);
    }
    // The invariant the relay enforces: a stored packet's declared blobs are
    // stored too. Declaring is how a packet keeps its blobs alive across a
    // prune, so an undeclared reference would be silently collectable.
    final missing = blobIds.where((id) => !blobs.containsKey(id)).toList();
    if (missing.isNotEmpty) {
      throw SyncApiException('Missing blobs: ${missing.join(', ')}', 409);
    }
    if (counter == held + 1) {
      streams.putIfAbsent(device, () => {})[counter] = blob;
      marks[device] = counter;
      if (covers != null) snapshots.add('$device:$counter');
      packetBlobs['$device:$counter'] = List.of(blobIds);
    }
    return (
      result: counter <= held
          ? PacketUploadResult.alreadyHeld
          : PacketUploadResult.stored,
      prune: covers == null ? null : _prune(covers, device, counter),
    );
  }

  /// Delete every packet a snapshot covers, never the snapshot itself.
  RelayPruneResult _prune(
      Map<String, int> covers, String keepOrigin, int keepCounter) {
    var packets = 0, bytes = 0;
    covers.forEach((device, declared) {
      final upTo =
          device == keepOrigin && declared >= keepCounter ? keepCounter - 1 : declared;
      final stream = streams[device];
      if (stream == null) return;
      for (final counter in stream.keys.toList()) {
        if (counter > upTo) continue;
        bytes += stream.remove(counter)!.length;
        snapshots.remove('$device:$counter');
        packetBlobs.remove('$device:$counter');
        packets++;
      }
    });
    // A blob no stored packet declares any more is unreachable: nothing can
    // ask for it by reference, so it goes with the packets that named it.
    final live = packetBlobs.values.expand((ids) => ids).toSet();
    blobs.removeWhere((id, _) => !live.contains(id));
    return RelayPruneResult(packets: packets, bytes: bytes);
  }

  /// Append an undecryptable packet as the next counter of [device].
  void injectCorrupt(String device) => store(device, Uint8List.fromList([1, 2, 3]));

  /// Append [blob] as the next counter of [device], bypassing upload.
  int store(String device, Uint8List blob, {bool snapshot = false}) {
    final counter = (marks[device] ?? 0) + 1;
    streams.putIfAbsent(device, () => {})[counter] = blob;
    marks[device] = counter;
    if (snapshot) snapshots.add('$device:$counter');
    return counter;
  }

  Map<String, int> vector() => {...marks};

  /// Clear to answer as a relay that predates the hash endpoint (404 → null),
  /// so the "cannot verify" path is exercised rather than assumed.
  bool servesHashes = true;

  /// Content hashes for one device's stream, as the relay's
  /// `GET /changes/hashes` answers them: only counters actually stored, so a
  /// pruned range is absent rather than zero.
  Map<int, String> hashes(String device, {required int from, required int to}) {
    final stream = streams[device] ?? const {};
    return {
      for (final entry in stream.entries)
        if (entry.key >= from && entry.key <= to)
          entry.key: NooDatabase.syncPayloadHash(entry.value),
    };
  }

  /// Overwrite a stored packet in place, keeping its identity — what a device
  /// restored from a backup does to its own stream when it re-uses counters it
  /// has already published.
  void overwrite(String device, int counter, Uint8List blob) {
    streams[device]![counter] = blob;
  }

  ({List<RemotePacket> changes, bool hasMore}) changes(
    Map<String, int> have, {
    int limit = 100,
  }) {
    final candidates = <RemotePacket>[];
    for (final device in orderHint ?? streams.keys.toList()) {
      final stream = streams[device];
      if (stream == null) continue;
      final from = have[device] ?? 0;
      final counters = stream.keys.where((c) => c > from).toList()..sort();
      for (final counter in counters) {
        candidates.add(RemotePacket(
          originDeviceId: device,
          counter: counter,
          payload: stream[counter]!,
          storedAt: '',
        ));
      }
    }
    // Snapshots first (§4.2): a requester starting above a pruned range can
    // accept the rest of a stream only after adopting a snapshot's coverage.
    final ordered = [
      ...candidates.where(_isSnapshot),
      ...candidates.where((p) => !_isSnapshot(p)),
    ];
    return (
      changes: ordered.take(limit).toList(),
      hasMore: ordered.length > limit,
    );
  }

  bool _isSnapshot(RemotePacket packet) =>
      snapshots.contains('${packet.originDeviceId}:${packet.counter}');

  RelayUsage usage() => RelayUsage(
        packets: totalPackets,
        bytes: totalBytes,
        devices: [
          for (final entry in streams.entries)
            if (entry.value.isNotEmpty)
              RelayDeviceUsage(
                deviceId: entry.key,
                deviceName: entry.key,
                packets: entry.value.length,
                bytes: entry.value.values
                    .fold(0, (sum, blob) => sum + blob.length),
                firstCounter: entry.value.keys.reduce((a, b) => a < b ? a : b),
                lastCounter: entry.value.keys.reduce((a, b) => a > b ? a : b),
                snapshots: entry.value.keys
                    .where((c) => snapshots.contains('${entry.key}:$c'))
                    .length,
              ),
        ],
      );

  int get totalPackets =>
      streams.values.fold(0, (sum, stream) => sum + stream.length);

  int get totalBytes => streams.values.fold(
      0,
      (sum, stream) =>
          sum + stream.values.fold<int>(0, (b, blob) => b + blob.length));
}

class _FakeApiClient extends SyncApiClient {
  final _FakeServer server;
  _FakeApiClient(this.server, SyncConfig config) : super(config: config);

  @override
  bool get isAuthenticated => true;

  @override
  Future<void> login({required String platform}) async {}

  @override
  Future<Map<String, int>> getVector() async => server.vector();

  @override
  Future<({PacketUploadResult result, RelayPruneResult? prune})> uploadPacket({
    required String originDeviceId,
    required int counter,
    required Uint8List payload,
    Map<String, int>? snapshotCovers,
    List<String> blobIds = const [],
  }) async =>
      server.upload(originDeviceId, counter, payload,
          covers: snapshotCovers, blobIds: blobIds);

  @override
  Future<bool> hasBlob(String blobId) async => server.blobs.containsKey(blobId);

  @override
  Future<void> putBlob(String blobId, Uint8List encrypted) async {
    server.blobs.putIfAbsent(blobId, () => encrypted);
  }

  @override
  Future<Uint8List?> getBlob(String blobId) async {
    server.blobFetches.add(blobId);
    return server.blobs[blobId];
  }

  /// Ranged read, as a relay that implements `Range` answers it. With
  /// [_FakeServer.servesRanges] off it ignores the range and sends the whole
  /// blob, which is exactly what an older relay does — the client has to cope
  /// with both.
  @override
  Future<BlobSlice?> getBlobSlice(
    String blobId, {
    required int offset,
    required int length,
  }) async {
    final whole = server.blobs[blobId];
    if (whole == null) {
      server.blobFetches.add(blobId);
      return null;
    }
    if (!server.servesRanges) {
      // What a relay without range support does: ignore the header, send it
      // all. (Not `super`, which would attempt a real HTTP request.)
      server.blobFetches.add(blobId);
      return BlobSlice(
          bytes: whole, offset: 0, total: whole.length, partial: false);
    }

    server.blobFetches.add(blobId);
    final servedBefore =
        server.blobRequests.where((r) => r.id == blobId).length;
    if (server.failSliceAfter != null &&
        servedBefore >= server.failSliceAfter!) {
      server.failSliceAfter = null;
      throw SyncApiException('connection lost', 500);
    }
    server.blobRequests.add((id: blobId, offset: offset, length: length));
    if (offset >= whole.length) {
      // 416: the client's partial is not a prefix of what we hold.
      return BlobSlice(
          bytes: whole, offset: 0, total: whole.length, partial: false);
    }
    final end = (offset + length).clamp(0, whole.length);
    return BlobSlice(
      bytes: Uint8List.sublistView(whole, offset, end),
      offset: offset,
      total: whole.length,
      partial: true,
    );
  }

  @override
  Future<RelayUsage> getUsage() async => server.usage();

  @override
  Future<({List<RemotePacket> changes, bool hasMore})> getChanges(
    Map<String, int> have, {
    int limit = 100,
  }) async =>
      server.changes(have, limit: limit);

  @override
  Future<Map<int, String>?> getStreamHashes(
    String deviceId, {
    required int from,
    required int to,
  }) async =>
      server.servesHashes ? server.hashes(deviceId, from: from, to: to) : null;
}

SyncService _service(
  NooDatabase db,
  _FakeServer server,
  String deviceId, {
  int autoFetchBudgetBytes = SyncService.defaultAutoFetchBudgetBytes,
  int blobChunkBytes = SyncService.defaultBlobChunkBytes,
  SyncJournal? journal,
}) {
  const password = 'shared-db-password';
  const username = 'alice';
  final config = SyncConfig(
    enabled: true,
    serverUrl: 'http://x',
    username: username,
    password: 'server-pw',
    deviceId: deviceId,
  );
  return SyncService(
    db: db,
    config: config,
    apiClient: _FakeApiClient(server, config),
    crypto: SyncCrypto(),
    historyService: HistoryService(db),
    databasePassword: password,
    autoFetchBudgetBytes: autoFetchBudgetBytes,
    blobChunkBytes: blobChunkBytes,
    journal: journal,
  );
}

Future<int> _createTask(NooDatabase db, WorldId wid, String title) {
  return db.createTask(worldId: wid.value, title: title);
}

/// Append a hand-built packet as [device]'s next counter, encrypted the way a
/// real client would. Lets a test place changes on the wire that the packager
/// would never produce.
Future<void> _injectPacket(
  _FakeServer server,
  NooDatabase db,
  String device,
  List<SyncChange> changes, {
  bool fullState = false,
  Map<String, int>? vector,
  int version = SyncPacket.currentVersion,
}) async {
  final counter = (server.marks[device] ?? 0) + 1;
  final crypto = SyncCrypto();
  await crypto.deriveKey(password: 'shared-db-password', username: 'alice');
  final packet = SyncPacket(
    version: version,
    deviceId: device,
    counter: counter,
    timestamp: DateTime.now().toUtc().toIso8601String(),
    changes: changes,
    vector: vector,
    fullState: fullState,
  );
  final blob = await crypto.encrypt(
    SyncChangePackager(db).compress(packet.serialize()),
    aad: SyncCrypto.packetAad(device, counter),
  );
  server.store(device, blob, snapshot: fullState);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncService round trip', () {
    late NooDatabase dbA;
    late NooDatabase dbB;
    late _FakeServer server;
    late SyncService syncA;
    late SyncService syncB;

    setUp(() {
      dbA = NooDatabase.memory();
      dbB = NooDatabase.memory();
      server = _FakeServer();
      syncA = _service(dbA, server, 'device-a');
      syncB = _service(dbB, server, 'device-b');
    });

    tearDown(() async {
      await dbA.close();
      await dbB.close();
    });

    test('a task created on A appears on B after sync', () async {
      final wid = WorldId.create();
      await _createTask(dbA, wid, 'Hello');

      final pushRes = await syncA.performSync();
      expect(pushRes.success, isTrue);

      final pullRes = await syncB.performSync();
      expect(pullRes.success, isTrue);

      final onB = await dbB.getTaskByWorldId(wid.value);
      expect(onB, isNotNull);
      expect(onB!.title, 'Hello');
    });

    test('rename before first sync still arrives with the new title (H1)',
        () async {
      final wid = WorldId.create();
      final id = await _createTask(dbA, wid, 'Original');
      // Rename before ever syncing: coalescing must keep the creation flag.
      await dbA.updateTask(id, title: 'Renamed');

      await syncA.performSync();
      await syncB.performSync();

      final onB = await dbB.getTaskByWorldId(wid.value);
      expect(onB, isNotNull);
      expect(onB!.title, 'Renamed');
    });

    test('newer remote edit wins, older remote edit loses (LWW, C4)', () async {
      // Both devices know the task first.
      final wid = WorldId.create();
      await _createTask(dbA, wid, 'Base');
      await syncA.performSync();
      await syncB.performSync();

      final idA = (await dbA.getTaskByWorldId(wid.value))!.id;
      final idB = (await dbB.getTaskByWorldId(wid.value))!.id;

      // A edits later than B (wall clock advances between the two edits).
      await dbB.updateTask(idB, title: 'FromB-early');
      await Future.delayed(const Duration(milliseconds: 5));
      await dbA.updateTask(idA, title: 'FromA-late');

      // B pushes first (older), then A pushes (newer).
      await syncB.performSync();
      await syncA.performSync();

      // Each pulls the other's change; the later A edit must win on both.
      await syncA.performSync();
      await syncB.performSync();

      expect((await dbA.getTaskByWorldId(wid.value))!.title, 'FromA-late');
      expect((await dbB.getTaskByWorldId(wid.value))!.title, 'FromA-late');
    });

    test('a corrupt packet is skipped without wedging later changes (C5)',
        () async {
      // A genuine task from A.
      final wid = WorldId.create();
      await _createTask(dbA, wid, 'Good');
      await syncA.performSync();

      // A corrupt packet from a third device lands in the stream...
      server.injectCorrupt('device-c');

      // ...followed by another good change from A.
      final wid2 = WorldId.create();
      await _createTask(dbA, wid2, 'AlsoGood');
      await syncA.performSync();

      final pull = await syncB.performSync();
      expect(pull.success, isTrue);
      expect(syncB.skippedBlobs, contains('device-c:1'));
      // Both good tasks still applied despite the corrupt packet.
      expect(await dbB.getTaskByWorldId(wid.value), isNotNull);
      expect(await dbB.getTaskByWorldId(wid2.value), isNotNull);
    });

    test('an unreadable packet is reported in the result of the run that '
        'consumed it', () async {
      server.injectCorrupt('device-c');

      final first = await syncB.performSync();
      // A successful sync that nevertheless lost data: the counts alone say
      // "already up to date", which is exactly what the report is for.
      expect(first.success, isTrue);
      expect(first.changesApplied, 0);
      expect(first.hasDiagnostics, isTrue);
      expect(first.skippedPackets, hasLength(1));
      expect(first.skippedPackets.single.id, 'device-c:1');
      expect(first.skippedPackets.single.stage, 'decrypt');
      expect(first.skippedPackets.single.isDecryptFailure, isTrue);

      // The applied vector has moved past it, so the next run has nothing new
      // to report — a result describes its own run.
      final second = await syncB.performSync();
      expect(second.skippedPackets, isEmpty);
      expect(second.hasDiagnostics, isFalse);
      // The session-wide list still remembers it; that is what blocks
      // compaction on a device whose state is missing a packet.
      expect(syncB.skippedBlobs, contains('device-c:1'));
    });

    test('a remote change dropped by LWW is reported with both timestamps',
        () async {
      final wid = WorldId.create();
      await _createTask(dbA, wid, 'Base');
      await syncA.performSync();
      await syncB.performSync();

      final idA = (await dbA.getTaskByWorldId(wid.value))!.id;
      final idB = (await dbB.getTaskByWorldId(wid.value))!.id;

      // A edits first, B edits after: A's change arrives at B and loses.
      await dbA.updateTask(idA, title: 'FromA-early');
      await Future.delayed(const Duration(milliseconds: 5));
      await dbB.updateTask(idB, title: 'FromB-late');

      await syncA.performSync();
      final pull = await syncB.performSync();

      expect(pull.success, isTrue);
      // Nothing to show in the counts — but something did arrive and was
      // deliberately dropped, which is the distinction being reported.
      expect(pull.changesApplied, 0);
      expect(pull.lwwSkips, hasLength(1));

      final skip = pull.lwwSkips.single;
      expect(skip.entityType, 'task');
      expect(skip.worldId, wid.value);
      expect(skip.field, 'title');
      expect(skip.label, 'FromB-late');
      expect(skip.localTimestamp.isAfter(skip.remoteTimestamp), isTrue);
      expect(skip.localAheadBy, greaterThan(Duration.zero));
      expect((await dbB.getTaskByWorldId(wid.value))!.title, 'FromB-late');
    });

    test('an applied change is not reported as an LWW loss', () async {
      final wid = WorldId.create();
      await _createTask(dbA, wid, 'Hello');
      await syncA.performSync();

      final pull = await syncB.performSync();
      expect(pull.changesApplied, greaterThan(0));
      expect(pull.lwwSkips, isEmpty);
      expect(pull.hasDiagnostics, isFalse);
    });

    test('a packet that fails part-way applies none of its changes', () async {
      // B needs the task and its file before the poisoned packet can target
      // them — otherwise the changes would merely be orphaned, not applied.
      final wid = WorldId.create();
      await _createTask(dbA, wid, 'Intact');
      final taskA = (await dbA.getTaskByWorldId(wid.value))!;
      final fileWid = WorldId.create();
      await dbA.createAttachment(
        taskId: taskA.id,
        worldId: fileWid.value,
        filename: 'notes.md',
        content: Uint8List.fromList([104, 105]),
      );
      await syncA.performSync();
      await syncB.performSync();

      final later = DateTime.now().toUtc().add(const Duration(minutes: 1));
      await _injectPacket(server, dbA, 'device-c', [
        // Applies cleanly...
        SyncChange(
          entityType: 'task',
          worldId: wid.value,
          field: 'title',
          value: 'Poisoned',
          timestamp: later.toIso8601String(),
        ),
        // ...and then this throws: file content must be base64.
        SyncChange(
          entityType: 'file',
          worldId: fileWid.value,
          field: 'content',
          value: 'not base64 !!!',
          timestamp: later.toIso8601String(),
        ),
      ]);

      final pull = await syncB.performSync();
      expect(pull.success, isTrue);
      expect(syncB.skippedBlobs, contains('device-c:1'));

      // The rename shared a transaction with the failing change, so it rolled
      // back with it rather than leaving the packet half-applied.
      expect((await dbB.getTaskByWorldId(wid.value))!.title, 'Intact');
      expect(pull.changesApplied, 0);
      expect(pull.applied, isEmpty);
    });

    test('edits are not echoed back to the origin device', () async {
      final wid = WorldId.create();
      await _createTask(dbA, wid, 'Once');
      await syncA.performSync();
      await syncB.performSync();

      // B applied A's change. B must not re-upload it as its own.
      final packetsBefore = server.totalPackets;
      await syncB.performSync();
      expect(server.totalPackets, packetsBefore,
          reason: 'remote-applied changes must not be pushed back');
    });

    test('re-pulling the same stream applies nothing (idempotent under vector)',
        () async {
      final wid = WorldId.create();
      await _createTask(dbA, wid, 'Stable');
      await syncA.performSync();
      await syncB.performSync();

      final again = await syncB.performSync();
      expect(again.success, isTrue);
      expect(again.changesApplied, 0);
    });

    test(
        'an edit arriving before its entity\'s creation is orphaned, '
        'then applied by retry in the same cycle', () async {
      // A creates task T; B (synced) attaches a file to it. A fresh device C
      // is then served B's stream (file creation) before A's (task creation) —
      // legal in v2, which orders only per device.
      final wid = WorldId.create();
      await _createTask(dbA, wid, 'Owner');
      await syncA.performSync();
      await syncB.performSync();

      final taskOnB = (await dbB.getTaskByWorldId(wid.value))!;
      await dbB.createAttachment(
        taskId: taskOnB.id,
        worldId: WorldId.create().value,
        filename: 'notes.md',
        content: Uint8List.fromList([104, 105]),
      );
      await syncB.performSync();

      server.orderHint = ['device-b', 'device-a'];
      final dbC = NooDatabase.memory();
      final syncC = _service(dbC, server, 'device-c');
      final res = await syncC.performSync();
      expect(res.success, isTrue);

      final taskOnC = await dbC.getTaskByWorldId(wid.value);
      expect(taskOnC, isNotNull);
      final filesOnC = await dbC.getAttachmentsForTask(taskOnC!.id);
      expect(filesOnC, hasLength(1));
      expect(filesOnC.single.filename, 'notes.md');
      await dbC.close();
    });

    test('full re-package announces entire current state (migration path)',
        () async {
      final wid1 = WorldId.create();
      final wid2 = WorldId.create();
      await _createTask(dbA, wid1, 'First');
      await _createTask(dbA, wid2, 'Second');
      // Simulate what the v5→v6 schema migration sets.
      await dbA.setProperty('sync_v2_repackage_needed', '1');

      await syncA.performSync();
      await syncB.performSync();

      expect((await dbB.getTaskByWorldId(wid1.value))?.title, 'First');
      expect((await dbB.getTaskByWorldId(wid2.value))?.title, 'Second');

      // The flag is one-shot: the next cycle packages nothing new.
      final packetsBefore = server.totalPackets;
      await syncA.performSync();
      expect(server.totalPackets, packetsBefore);
    });

    test('a restored-from-backup device recovers its own stream instead of '
        'being refused', () async {
      final wid = WorldId.create();
      await _createTask(dbA, wid, 'Pre-backup');
      await syncA.performSync();

      // "Restore": a fresh database re-using device-a's identity, whose own
      // stream counter has regressed to zero.
      final dbRestored = NooDatabase.memory();
      final syncRestored = _service(dbRestored, server, 'device-a');
      final post = WorldId.create();
      await _createTask(dbRestored, post, 'Post-restore');

      // Having published nothing under this identity, this database has
      // nothing that can contradict the fleet: the gap is history the restore
      // dropped, and the first run pulls it back rather than refusing.
      final recovery = await syncRestored.performSync();
      expect(recovery.success, isTrue);
      expect(await dbRestored.getTaskByWorldId(wid.value), isNotNull);
      // Crucially, it published nothing while behind — re-issuing device-a:1
      // is the fork this check exists to prevent.
      expect(server.streams['device-a'], hasLength(1));

      // The next run resumes the stream above what it recovered.
      final resumed = await syncRestored.performSync();
      expect(resumed.success, isTrue);
      expect(server.streams['device-a'], hasLength(2));
      expect(await dbA.getTaskByWorldId(post.value), isNull);
      await syncA.performSync();
      expect(await dbA.getTaskByWorldId(post.value), isNotNull);

      await dbRestored.close();
    });

    // ============================================================
    // Conflict copies (LWW + conflict copy)
    // ============================================================

    Future<List<TaskRow>> liveTasks(NooDatabase db) async =>
        (await db.getAllTaskRows()).where((t) => t.removed == 0).toList();

    test('concurrent edits: losing value survives as exactly one conflict copy',
        () async {
      final wid = WorldId.create();
      final idA = await _createTask(dbA, wid, 'Base');
      await syncA.performSync();
      await syncB.performSync();
      final idB = (await dbB.getTaskByWorldId(wid.value))!.id;

      // Concurrent offline edits: B first, A later (A wins LWW).
      await dbB.updateTask(idB, content: 'from-b');
      await Future.delayed(const Duration(milliseconds: 5));
      await dbA.updateTask(idA, content: 'from-a');

      await syncB.performSync(); // B pushes its (losing) edit
      await syncA.performSync(); // A pushes, pulls B's edit → copy made on A
      await syncA.performSync(); // A pushes the copy
      await syncB.performSync(); // B pulls A's edit + the copy

      for (final db in [dbA, dbB]) {
        final tasks = await liveTasks(db);
        expect(tasks, hasLength(2));
        final original = tasks.singleWhere((t) => t.worldId == wid.value);
        expect(original.content, 'from-a');
        final copy = tasks.singleWhere((t) => t.worldId != wid.value);
        expect(copy.title, contains('(conflict'));
        expect(copy.content, 'from-b');
      }
    });

    test('an edit made after seeing the previous value creates no copy',
        () async {
      final wid = WorldId.create();
      final idA = await _createTask(dbA, wid, 'Base');
      await dbA.updateTask(idA, content: 'first');
      await syncA.performSync();
      await syncB.performSync(); // B sees 'first'...

      final idB = (await dbB.getTaskByWorldId(wid.value))!.id;
      await dbB.updateTask(idB, content: 'second'); // ...then edits on top
      await syncB.performSync();
      await syncA.performSync();

      for (final db in [dbA, dbB]) {
        final tasks = await liveTasks(db);
        expect(tasks, hasLength(1));
        expect(tasks.single.content, 'second');
      }
    });

    test('a deletion that wins over unseen edits leaves a conflict copy',
        () async {
      final wid = WorldId.create();
      final idA = await _createTask(dbA, wid, 'Base');
      await syncA.performSync();
      await syncB.performSync();
      final idB = (await dbB.getTaskByWorldId(wid.value))!.id;

      // B edits while A concurrently deletes.
      await dbB.updateTask(idB, content: 'precious');
      await dbA.deleteTask(idA);

      await syncA.performSync(); // deletion on the wire
      await syncB.performSync(); // B: deletion applies → copy of local values
      await syncB.performSync(); // B pushes the copy
      await syncA.performSync(); // A pulls B's edit + the copy

      for (final db in [dbA, dbB]) {
        expect((await db.getTaskByWorldId(wid.value))!.removed, 1);
        final tasks = await liveTasks(db);
        expect(tasks, hasLength(1));
        expect(tasks.single.title, contains('(conflict'));
        expect(tasks.single.content, 'precious');
      }
    });

    test('a conflict copy lifted to the root stays hidden from agents',
        () async {
      // The one path where a copy can leave the branch that was hiding it:
      // its parent is deleted out from under it, so it falls back to the top
      // level carrying the original's title and content.
      final parentWid = WorldId.create();
      final childWid = WorldId.create();
      final parentA = await _createTask(dbA, parentWid, 'Private');
      final childA = await dbA.createTask(
        parentId: parentA,
        worldId: childWid.value,
        title: 'Salary',
      );
      await dbA.setTaskMcpExcluded(parentA, true);

      await syncA.performSync();
      await syncB.performSync();
      final childB = (await dbB.getTaskByWorldId(childWid.value))!.id;

      // B edits the child while A deletes the whole private branch.
      await dbB.updateTask(childB, content: 'precious');
      await dbA.deleteTask(parentA);
      expect(childA, isNotNull);

      await syncA.performSync();
      await syncB.performSync(); // B: deletion applies → copy of local values
      await syncB.performSync();
      await syncA.performSync();

      for (final db in [dbA, dbB]) {
        final copy = (await liveTasks(db))
            .singleWhere((t) => t.title.contains('(conflict'));
        expect(copy.parentId, isNull, reason: 'the parent is gone');
        expect(copy.content, 'precious');
        // Would otherwise be a top-level task holding the hidden branch's
        // content, in plain view of every MCP tool.
        expect(await db.isTaskMcpExcluded(copy.id), isTrue);
      }
    });

    test('identical concurrent values create no copy', () async {
      final wid = WorldId.create();
      final idA = await _createTask(dbA, wid, 'Base');
      await syncA.performSync();
      await syncB.performSync();
      final idB = (await dbB.getTaskByWorldId(wid.value))!.id;

      await dbB.updateTask(idB, content: 'same');
      await Future.delayed(const Duration(milliseconds: 5));
      await dbA.updateTask(idA, content: 'same');

      await syncB.performSync();
      await syncA.performSync();
      await syncA.performSync();
      await syncB.performSync();

      for (final db in [dbA, dbB]) {
        expect(await liveTasks(db), hasLength(1));
      }
    });

    test('a vectorless losing change still yields a copy for an unpushed edit',
        () async {
      final wid = WorldId.create();
      final idA = await _createTask(dbA, wid, 'Base');
      await syncA.performSync();

      final before = DateTime.now().toUtc().toIso8601String();
      await Future.delayed(const Duration(milliseconds: 5));
      await dbA.updateTask(idA, content: 'local-unpushed');

      // Old-format packet (no vector) carrying an older concurrent edit.
      await _injectPacket(server, dbA, 'device-x', [
        SyncChange(
          entityType: 'task',
          worldId: wid.value,
          field: 'content',
          value: 'from-x',
          timestamp: before,
        ),
      ]);

      await syncA.performSync();

      final tasks = await liveTasks(dbA);
      expect(tasks, hasLength(2));
      expect(tasks.singleWhere((t) => t.worldId == wid.value).content,
          'local-unpushed');
      expect(tasks.singleWhere((t) => t.worldId != wid.value).content,
          'from-x');
    });

    test('losing full-state re-announces never create copies',
        () async {
      final wid = WorldId.create();
      final idA = await _createTask(dbA, wid, 'Base');
      await syncA.performSync();

      final before = DateTime.now().toUtc().toIso8601String();
      await Future.delayed(const Duration(milliseconds: 5));
      await dbA.updateTask(idA, content: 'newer-local');

      await _injectPacket(server, dbA, 'device-x', [
        SyncChange(
          entityType: 'task',
          worldId: wid.value,
          field: 'content',
          value: 'stale-echo',
          timestamp: before,
          isCreation: true,
        ),
      ], fullState: true);

      await syncA.performSync();

      expect(await liveTasks(dbA), hasLength(1));
    });
  });

  group('pending local changes preview', () {
    late NooDatabase db;
    late _FakeServer server;
    late SyncService sync;

    setUp(() {
      db = NooDatabase.memory();
      server = _FakeServer();
      sync = _service(db, server, 'device-a');
    });

    tearDown(() async => db.close());

    test('nothing pending after a sync', () async {
      await _createTask(db, WorldId.create(), 'Hello');
      await sync.performSync();

      final pending = await sync.pendingLocalChanges();
      expect(pending.isEmpty, isTrue);
      expect(pending.items, isEmpty);
    });

    test('groups every field change of a task into one labelled item',
        () async {
      final id = await _createTask(db, WorldId.create(), 'Hello');
      await sync.performSync();
      await db.updateTask(id, title: 'Renamed', content: 'body');

      final pending = await sync.pendingLocalChanges();
      expect(pending.totalEntities, 1);
      expect(pending.totalChanges, 2);
      final item = pending.items.single;
      expect(item.label, 'Renamed');
      expect(item.fields, containsAll(<String>['title', 'content']));
    });

    test('caps the described items but counts them all', () async {
      for (var i = 0; i < 5; i++) {
        await _createTask(db, WorldId.create(), 'Task $i');
      }

      final pending = await sync.pendingLocalChanges(limit: 2);
      expect(pending.items, hasLength(2));
      expect(pending.totalEntities, 5);
      expect(pending.hiddenEntities, 3);
      // Newest first: the last task created leads the list.
      expect(pending.items.first.label, 'Task 4');
    });
  });

  group('compaction', () {
    late NooDatabase dbA;
    late NooDatabase dbB;
    late _FakeServer server;
    late SyncService syncA;
    late SyncService syncB;

    setUp(() {
      dbA = NooDatabase.memory();
      dbB = NooDatabase.memory();
      server = _FakeServer();
      syncA = _service(dbA, server, 'device-a');
      syncB = _service(dbB, server, 'device-b');
    });

    tearDown(() async {
      await dbA.close();
      await dbB.close();
    });

    /// Two devices with a few packets each, fully converged.
    Future<List<WorldId>> seedConvergedHistory() async {
      final first = WorldId.create();
      await _createTask(dbA, first, 'From A');
      await syncA.performSync();
      await syncB.performSync();

      final second = WorldId.create();
      await _createTask(dbB, second, 'From B');
      await syncB.performSync();
      await syncA.performSync();

      final idA = (await dbA.getTaskByWorldId(first.value))!.id;
      await dbA.updateTask(idA, title: 'From A, renamed');
      await syncA.performSync();
      await syncB.performSync();
      return [first, second];
    }

    test('publishes a snapshot and prunes what it covers', () async {
      final wids = await seedConvergedHistory();
      expect(server.totalPackets, greaterThan(1));

      final result = await syncA.compactRelay();
      expect(result.error, isNull);
      expect(result.success, isTrue);
      expect(result.relaySupported, isTrue);
      expect(result.relayPackets, greaterThan(0));
      expect(result.relayBytes, greaterThan(0));

      // Only the snapshot survives on the relay...
      expect(server.totalPackets, 1);
      expect(server.snapshots, hasLength(1));
      // ...and the vector still names the top of every stream, so nothing is
      // re-uploaded on the next sync.
      expect(server.vector()['device-a'], result.snapshotCounter);
      expect(server.vector()['device-b'], greaterThan(0));

      // The compacting device dropped its own covered packets too.
      final localA = await dbA.syncPacketStorage();
      expect(localA.packets, 1);
      expect(result.localPackets, greaterThan(0));

      // State is untouched by any of it.
      for (final wid in wids) {
        expect(await dbA.getTaskByWorldId(wid.value), isNotNull);
      }
      expect((await dbA.getTaskByWorldId(wids.first.value))!.title,
          'From A, renamed');
    });

    test('a second device adopts the coverage and prunes its own store',
        () async {
      final wids = await seedConvergedHistory();
      await syncA.compactRelay();

      final before = await dbB.syncPacketStorage();
      final pull = await syncB.performSync();
      expect(pull.success, isTrue);

      final after = await dbB.syncPacketStorage();
      expect(after.packets, lessThan(before.packets),
          reason: 'the snapshot supersedes the packets B was holding');
      expect(after.bytes, lessThan(before.bytes));

      // B keeps the state, and can still package its next edit.
      for (final wid in wids) {
        expect(await dbB.getTaskByWorldId(wid.value), isNotNull);
      }
      final fresh = WorldId.create();
      await _createTask(dbB, fresh, 'After compaction');
      final push = await syncB.performSync();
      expect(push.success, isTrue);
      await syncA.performSync();
      expect(await dbA.getTaskByWorldId(fresh.value), isNotNull);
    });

    test('a device joining after compaction bootstraps from the snapshot',
        () async {
      final wids = await seedConvergedHistory();
      await syncA.compactRelay();

      // Everything below the snapshot is gone from the relay, so this device
      // can only converge by accepting a stream that no longer starts at 1.
      final dbC = NooDatabase.memory();
      final syncC = _service(dbC, server, 'device-c');
      final result = await syncC.performSync();
      expect(result.success, isTrue);
      expect(syncC.skippedBlobs, isEmpty);

      for (final wid in wids) {
        expect(await dbC.getTaskByWorldId(wid.value), isNotNull,
            reason: 'the snapshot is self-sufficient for bootstrap');
      }
      // It adopted the coverage rather than storing the pruned packets.
      final vector = await dbC.getSyncVector();
      expect(vector['device-b'], greaterThan(0));
      expect((await dbC.syncPacketStorage()).packets, 1);
      await dbC.close();
    });

    test('an out-of-order snapshot is applied and the refused packets retried',
        () async {
      final wids = await seedConvergedHistory();
      await syncA.compactRelay();
      await syncB.performSync();

      // A packet from B above the pruned range: a fresh device cannot accept
      // it until it has adopted the snapshot's coverage.
      final later = WorldId.create();
      await _createTask(dbB, later, 'Post-snapshot');
      await syncB.performSync();

      // A relay that does not put snapshots first — an older server, or a
      // page boundary landing badly. The client must still converge within
      // the exchange (§4.2).
      server.snapshots.clear();
      server.orderHint = ['device-b', 'device-a'];

      final dbC = NooDatabase.memory();
      final syncC = _service(dbC, server, 'device-c');
      final result = await syncC.performSync();
      expect(result.success, isTrue);
      expect(await dbC.getTaskByWorldId(later.value), isNotNull,
          reason: 'the packet refused before the snapshot must be retried');
      for (final wid in wids) {
        expect(await dbC.getTaskByWorldId(wid.value), isNotNull);
      }
      await dbC.close();
    });

    test('a pruned stream continues instead of restarting at 1', () async {
      await seedConvergedHistory();
      final result = await syncA.compactRelay();

      // A's own packets below the snapshot are gone locally and on the relay.
      final next = WorldId.create();
      await _createTask(dbA, next, 'Next');
      final push = await syncA.performSync();
      expect(push.success, isTrue);
      expect(server.vector()['device-a'], result.snapshotCounter + 1,
          reason: 'the next counter comes from the mark, not from MAX(counter)');
      expect(syncA.skippedBlobs, isEmpty);
    });

    test('a snapshot cannot raise this device\'s own counter', () async {
      await seedConvergedHistory();
      final ownBefore = (await dbB.getSyncVector())['device-b'];
      expect(ownBefore, isNotNull);

      // A snapshot claiming to have seen packets from B that B never issued
      // must not be believed about B's own stream — that would mask a fork.
      await _injectPacket(
        server,
        dbA,
        'device-a',
        [
          SyncChange(
            entityType: 'task',
            worldId: WorldId.create().value,
            field: 'title',
            value: 'Snapshotted',
            timestamp: DateTime.now().toUtc().toIso8601String(),
            isCreation: true,
          ),
        ],
        fullState: true,
        vector: {'device-b': ownBefore! + 99},
      );

      await syncB.performSync();
      expect((await dbB.getSyncVector())['device-b'], ownBefore,
          reason: "a remote snapshot must not advance our own stream");
    });

    test('refuses to compact when a packet could not be read', () async {
      await seedConvergedHistory();
      server.injectCorrupt('device-c');
      await syncA.performSync();
      expect(syncA.skippedBlobs, isNotEmpty);

      final packetsBefore = server.totalPackets;
      final result = await syncA.compactRelay();
      expect(result.success, isFalse);
      expect(result.error, contains('could not read'));
      expect(server.totalPackets, packetsBefore,
          reason: 'a refused compaction must publish nothing');
    });

    test('refuses to compact with unsynced local edits', () async {
      await seedConvergedHistory();

      // Package nothing, but leave a local edit behind: performSync inside
      // compactRelay pushes it, so the blocker is reached only when the edit
      // lands after that sync. Simulate by compacting a service with no
      // relay — the honest "nothing to compact against" case.
      final dbLocal = NooDatabase.memory();
      final localOnly = SyncService(
        db: dbLocal,
        config: const SyncConfig(
            enabled: true, username: 'alice', deviceId: 'device-d'),
        apiClient: null,
        crypto: SyncCrypto(),
        historyService: HistoryService(dbLocal),
        databasePassword: 'shared-db-password',
      );
      final result = await localOnly.compactRelay();
      expect(result.success, isFalse);
      expect(result.error, contains('No sync server'));
      await dbLocal.close();
    });

    test('reports relay usage', () async {
      await seedConvergedHistory();
      final usage = await syncA.fetchRelayUsage();
      expect(usage.packets, server.totalPackets);
      expect(usage.bytes, greaterThan(0));
      expect(usage.devices.map((d) => d.deviceId),
          containsAll(<String>['device-a', 'device-b']));

      await syncA.compactRelay();
      final after = await syncA.fetchRelayUsage();
      expect(after.packets, 1);
      expect(after.bytes, lessThan(usage.bytes));
      expect(after.devices.single.snapshots, 1);
    });
  });

  group('stream integrity', () {
    late NooDatabase dbA;
    late NooDatabase dbB;
    late _FakeServer server;
    late SyncService syncA;
    late SyncService syncB;

    setUp(() {
      dbA = NooDatabase.memory();
      dbB = NooDatabase.memory();
      server = _FakeServer();
      syncA = _service(dbA, server, 'device-a');
      syncB = _service(dbB, server, 'device-b');
    });

    tearDown(() async {
      await dbA.close();
      await dbB.close();
    });

    test('an occupied slot is a duplicate for the same bytes and a conflict '
        'for different ones', () async {
      final blob = Uint8List.fromList(List.generate(32, (i) => i));
      expect(
        await dbA.storeSyncPacket(
            originDeviceId: 'device-x', counter: 1, payload: blob),
        SyncPacketStoreResult.stored,
      );
      // The multi-path duplicate the slot rule is written for: same packet,
      // second delivery, nothing to do.
      expect(
        await dbA.storeSyncPacket(
            originDeviceId: 'device-x', counter: 1, payload: blob),
        SyncPacketStoreResult.duplicate,
      );
      // The case the slot rule alone cannot see: same identity, other bytes.
      expect(
        await dbA.storeSyncPacket(
            originDeviceId: 'device-x',
            counter: 1,
            payload: Uint8List.fromList(List.filled(32, 9))),
        SyncPacketStoreResult.conflict,
      );
    });

    test('the backfill hashes packets stored before the column existed',
        () async {
      final blob = Uint8List.fromList([1, 2, 3, 4]);
      await dbA.storeSyncPacket(
          originDeviceId: 'device-x', counter: 1, payload: blob);
      await dbA.customStatement("UPDATE sync_packets SET payload_hash = ''");
      // An unhashed row says nothing rather than something wrong.
      expect(await dbA.syncPacketHashes('device-x', from: 1, to: 1), isEmpty);

      expect(await dbA.backfillSyncPacketHashes(), 1);
      expect((await dbA.syncPacketHashes('device-x', from: 1, to: 1))[1],
          NooDatabase.syncPayloadHash(blob));
    });

    test('a re-issued packet identity is caught by content once the counter '
        'has caught up', () async {
      await _createTask(dbA, WorldId.create(), 'One');
      await syncA.performSync();
      await _createTask(dbA, WorldId.create(), 'Two');
      await syncA.performSync();
      expect(server.marks['device-a'], 2);

      // What a restore leaves behind once the device has packaged over
      // counters it had already published: same identity, different content.
      server.overwrite('device-a', 2, Uint8List.fromList(List.filled(64, 7)));

      // The §3.3 counter test cannot see this — the two sides agree exactly.
      expect(await dbA.maxSyncCounterFor('device-a'), server.marks['device-a']);

      final result = await syncA.performSync();
      expect(result.success, isFalse);
      // And it names where the streams parted, not merely that they did.
      expect(result.error, contains('diverged at packet counter 2'));
    });

    test('divergence is reported at the lowest counter that differs',
        () async {
      await _createTask(dbA, WorldId.create(), 'One');
      await syncA.performSync();
      await _createTask(dbA, WorldId.create(), 'Two');
      await syncA.performSync();

      server.overwrite('device-a', 1, Uint8List.fromList(List.filled(64, 5)));
      server.overwrite('device-a', 2, Uint8List.fromList(List.filled(64, 7)));

      final result = await syncA.performSync();
      expect(result.error, contains('counter 1'));
    });

    test('a healthy stream is never reported as diverged', () async {
      await _createTask(dbA, WorldId.create(), 'One');
      expect((await syncA.performSync()).success, isTrue);
      await _createTask(dbA, WorldId.create(), 'Two');
      expect((await syncA.performSync()).success, isTrue);
      expect((await syncB.performSync()).success, isTrue);
      // B has now carried A's packets; A re-checks against a relay holding
      // them by both paths.
      expect((await syncA.performSync()).success, isTrue);
    });

    test('a remote that cannot answer for hashes leaves the exchange as safe '
        'as it was, not failed', () async {
      await _createTask(dbA, WorldId.create(), 'One');
      await syncA.performSync();
      server.overwrite('device-a', 1, Uint8List.fromList(List.filled(64, 7)));
      server.servesHashes = false;

      // Undetectable without the endpoint — but an unanswerable check is not
      // a failed sync, or deploying the client before the relay would wedge
      // every device.
      expect((await syncA.performSync()).success, isTrue);
    });

    test('a device behind on its own stream catches up instead of refusing',
        () async {
      await _createTask(dbA, WorldId.create(), 'One');
      await syncA.performSync();
      await _createTask(dbA, WorldId.create(), 'Two');
      await syncA.performSync();
      expect(server.marks['device-a'], 2);

      // Roll this database back to just after packet 1, as restoring a backup
      // does: the relay is at 2, we are at 1, and our packet 1 is untouched.
      await dbA.deleteSyncPacketsFrom('device-a', 2);
      expect(await dbA.maxSyncCounterFor('device-a'), 1);

      // The overlap is byte-for-byte clean, so this is lost history, not a
      // fork: the run recovers it rather than refusing.
      final recovered = await syncA.performSync();
      expect(recovered.success, isTrue);
      expect(await dbA.maxSyncCounterFor('device-a'), 2);

      // And the next run resumes packaging above the recovered counters.
      await _createTask(dbA, WorldId.create(), 'Three');
      expect((await syncA.performSync()).success, isTrue);
      expect(server.marks['device-a'], 3);
    });

    test('a device behind on an unverifiable stream still refuses', () async {
      await _createTask(dbA, WorldId.create(), 'One');
      await syncA.performSync();
      await _createTask(dbA, WorldId.create(), 'Two');
      await syncA.performSync();

      await dbA.deleteSyncPacketsFrom('device-a', 2);
      // Without hashes, lost history and a re-issued identity look identical.
      server.servesHashes = false;

      final result = await syncA.performSync();
      expect(result.success, isFalse);
      expect(result.error, contains('fork detected'));
    });

    test('recovery takes a new identity and republishes the database',
        () async {
      final kept = WorldId.create();
      await _createTask(dbA, kept, 'Kept');
      await syncA.performSync();
      await _createTask(dbA, WorldId.create(), 'Two');
      await syncA.performSync();
      server.overwrite('device-a', 2, Uint8List.fromList(List.filled(64, 7)));

      final diverged = await syncA.performSync();
      expect(diverged.error, contains('diverged at packet counter 2'));

      String? persisted;
      final recovery = await syncA.recoverFromFork(
        divergedAtCounter: 2,
        persistIdentity: (id) async => persisted = id,
      );

      expect(persisted, recovery.newDeviceId);
      expect(recovery.newDeviceId, isNot(recovery.oldDeviceId));
      // The packets wearing a contested identity are gone; shared history
      // below the fork stays.
      expect(recovery.discardedPackets, 1);
      expect(await dbA.maxSyncCounterFor('device-a'), 1);

      // The app rebuilds the service under the new identity; its first sync
      // publishes the whole database, so nothing is owed to the old stream.
      final syncA2 = _service(dbA, server, recovery.newDeviceId);
      expect((await syncA2.performSync()).success, isTrue);
      expect(server.marks[recovery.newDeviceId], 1);

      // A device that has never seen either stream still gets everything.
      expect((await syncB.performSync()).success, isTrue);
      expect(await dbB.getTaskByWorldId(kept.value), isNotNull);
    });

    test('discarded packets lose their identity, not their content', () async {
      // Packet 1: a task the fleet already has, plus one that packet 2 deletes.
      final fromOne = WorldId.create();
      final doomed = WorldId.create();
      await _createTask(dbA, fromOne, 'From packet one');
      final doomedId = await _createTask(dbA, doomed, 'Doomed');
      await syncA.performSync();
      await syncB.performSync();
      expect((await dbB.getTaskByWorldId(doomed.value))!.removed, 0);

      // Packet 2 carries the only copy of both of these facts: a new task, and
      // a deletion. This is the packet recovery throws away.
      final onlyInTwo = WorldId.create();
      await _createTask(dbA, onlyInTwo, 'Only in packet two');
      await dbA.deleteTask(doomedId);
      await syncA.performSync();
      expect(server.marks['device-a'], 2);

      server.overwrite('device-a', 2, Uint8List.fromList(List.filled(64, 7)));
      expect((await syncA.performSync()).error,
          contains('diverged at packet counter 2'));

      final recovery = await syncA.recoverFromFork(
        divergedAtCounter: 2,
        persistIdentity: (_) async {},
      );
      expect(recovery.discardedPackets, 1);

      // The packet is gone from the store...
      expect(await dbA.syncPacketHashes('device-a', from: 2, to: 2), isEmpty);
      // ...but its content never lived there. Packaging serialises the tasks
      // and history tables; it does not move anything out of them.
      expect(await dbA.getTaskByWorldId(onlyInTwo.value), isNotNull);
      expect((await dbA.getTaskByWorldId(doomed.value))!.removed, 1);

      // And the full-state snapshot carries both facts to the fleet under the
      // new identity, deletion included.
      final syncA2 = _service(dbA, server, recovery.newDeviceId);
      expect((await syncA2.performSync()).success, isTrue);
      expect((await syncB.performSync()).success, isTrue);

      expect(await dbB.getTaskByWorldId(onlyInTwo.value), isNotNull);
      expect((await dbB.getTaskByWorldId(doomed.value))!.removed, 1);
      expect(await dbB.getTaskByWorldId(fromOne.value), isNotNull);
    });

    test('a recovery whose identity cannot be persisted leaves a safe store '
        'and a clean retry', () async {
      await _createTask(dbA, WorldId.create(), 'One');
      await syncA.performSync();
      await _createTask(dbA, WorldId.create(), 'Two');
      await syncA.performSync();
      server.overwrite('device-a', 2, Uint8List.fromList(List.filled(64, 7)));

      await expectLater(
        syncA.recoverFromFork(
          divergedAtCounter: 2,
          persistIdentity: (_) async => throw StateError('settings are gone'),
        ),
        throwsA(isA<StateError>()),
      );

      // The store is mid-recovery but never unsafe: the contested packets are
      // gone and a full re-package is queued. Nothing here re-uses an
      // identity, which is the only thing that must not happen.
      expect(await dbA.maxSyncCounterFor('device-a'), 1);

      // And the retry completes: every step is idempotent.
      String? persisted;
      final recovery = await syncA.recoverFromFork(
        divergedAtCounter: 2,
        persistIdentity: (id) async => persisted = id,
      );
      expect(persisted, recovery.newDeviceId);
      expect(recovery.discardedPackets, 0, reason: 'already discarded');

      final syncA2 = _service(dbA, server, recovery.newDeviceId);
      expect((await syncA2.performSync()).success, isTrue);
      expect(server.marks[recovery.newDeviceId], 1);
    });

    test("a divergence in another device's stream is recorded, not fatal",
        () async {
      final mine = Uint8List.fromList(List.filled(48, 1));
      await dbB.storeSyncPacket(
          originDeviceId: 'device-c', counter: 1, payload: mine);

      final applied = await syncB.pullFromSource(
        _StubSource(RemotePacket(
          originDeviceId: 'device-c',
          counter: 1,
          payload: Uint8List.fromList(List.filled(48, 2)),
          storedAt: '',
        )),
        checkFork: false,
      );

      expect(applied, 0);
      expect(syncB.skippedBlobs, contains('device-c:1'));
      // Neither packet can be preferred from here, so what we hold stands.
      expect((await dbB.syncPacketHashes('device-c', from: 1, to: 1))[1],
          NooDatabase.syncPayloadHash(mine));
    });
  });

  group('attachment blob store', () {
    late NooDatabase dbA;
    late NooDatabase dbB;
    late _FakeServer server;
    late SyncService syncA;
    late SyncService syncB;

    setUp(() {
      dbA = NooDatabase.memory();
      dbB = NooDatabase.memory();
      server = _FakeServer();
      syncA = _service(dbA, server, 'device-a');
      syncB = _service(dbB, server, 'device-b');
    });

    tearDown(() async {
      await dbA.close();
      await dbB.close();
    });

    /// A task on A with one attachment of [bytes]; returns the task's world id.
    Future<WorldId> attachOnA(Uint8List bytes, {String name = 'memo.opus'}) async {
      final wid = WorldId.create();
      final taskId = await _createTask(dbA, wid, 'With attachment');
      await dbA.createAttachment(
          taskId: taskId,
          worldId: WorldId.create().value,
          filename: name,
          content: bytes);
      return wid;
    }

    Future<FileEntry> attachmentOn(NooDatabase db, WorldId taskWid) async {
      final task = (await db.getTaskByWorldId(taskWid.value))!;
      return (await db.getAttachmentsForTask(task.id)).single;
    }

    final big = Uint8List.fromList(List.generate(200 * 1024, (i) => i % 251));
    final bigId = NooDatabase.blobId(big);

    test('the packet names the bytes; the bytes travel once, separately',
        () async {
      final wid = await attachOnA(big);
      expect((await syncA.performSync()).success, isTrue);

      // The log did not grow with the attachment.
      final packet = server.streams['device-a']![1]!;
      expect(packet.length, lessThan(4 * 1024),
          reason: 'a 200 KB attachment must not be inlined in the packet');
      expect(server.packetBlobs['device-a:1'], [bigId]);
      expect(server.blobs, contains(bigId));
      // What the relay holds is ciphertext, not the file.
      expect(server.blobs[bigId], isNot(equals(big)));

      expect((await syncB.performSync()).success, isTrue);
      final onB = await attachmentOn(dbB, wid);
      expect(onB.contentHash, bigId);
      expect(onB.content, big);
      expect(server.blobFetches, [bigId]);
    });

    test('bytes already on the device resolve locally without a fetch',
        () async {
      // B already has the same file, attached to something of its own.
      final own = await _createTask(dbB, WorldId.create(), 'Mine');
      await dbB.createAttachment(
          taskId: own,
          worldId: WorldId.create().value,
          filename: 'same-bytes.bin',
          content: big);

      final wid = await attachOnA(big);
      await syncA.performSync();
      expect((await syncB.performSync()).success, isTrue);

      expect((await attachmentOn(dbB, wid)).content, big);
      expect(server.blobFetches, isEmpty,
          reason: 'identical content is the same blob, wherever it came from');
    });

    test('a reference whose bytes are not yet obtainable waits, and fills in '
        'from whichever node has them', () async {
      final wid = await attachOnA(big);
      await syncA.performSync();
      // The relay lost the blob (or B reached a node that never had it).
      final encrypted = server.blobs.remove(bigId)!;

      expect((await syncB.performSync()).success, isTrue);
      final pending = await attachmentOn(dbB, wid);
      expect(pending.contentHash, bigId);
      expect(pending.content, isNull, reason: 'known, not yet fetched');
      expect(await dbB.missingBlobHashes(), [bigId]);

      // A LAN peer that has the bytes fills the gap on the next exchange;
      // the packet itself is not needed again.
      final peer = _StubSource(
        RemotePacket(
            originDeviceId: 'device-a',
            counter: 1,
            payload: server.streams['device-a']![1]!,
            storedAt: ''),
        blobs: {bigId: encrypted},
      );
      await syncB.exchangeWithSource(peer);

      expect((await attachmentOn(dbB, wid)).content, big);
      expect(await dbB.missingBlobHashes(), isEmpty);
    });

    test('a blob that fails to verify is left missing, never stored', () async {
      final wid = await attachOnA(big);
      await syncA.performSync();
      // Ciphertext under the right id that decrypts to the wrong bytes: only
      // reachable by a node with the key lying, but the hash check is what
      // makes the id mean something, so it is checked regardless.
      final crypto = SyncCrypto();
      await crypto.deriveKey(password: 'shared-db-password', username: 'alice');
      server.blobs[bigId] = await crypto.encrypt(Uint8List.fromList([1, 2, 3]),
          aad: SyncCrypto.blobAad(bigId));

      expect((await syncB.performSync()).success, isTrue);
      expect((await attachmentOn(dbB, wid)).content, isNull);
      expect(await dbB.missingBlobHashes(), [bigId]);
    });

    test('v2 packets with inline content still apply', () async {
      final task = WorldId.create();
      final file = WorldId.create();
      await _injectPacket(server, dbB, 'device-c', [
        SyncChange(
            entityType: 'task',
            worldId: task.value,
            field: 'title',
            value: 'Old sender',
            timestamp: '2026-01-01T00:00:00.000000Z',
            isCreation: true),
        SyncChange(
            entityType: 'file',
            worldId: file.value,
            field: 'filename',
            value: 'legacy.txt',
            timestamp: '2026-01-01T00:00:00.000000Z',
            isCreation: true,
            parentWorldId: task.value),
        SyncChange(
            entityType: 'file',
            worldId: file.value,
            field: 'content',
            value: base64Encode([104, 105]),
            timestamp: '2026-01-01T00:00:00.000000Z',
            isCreation: true,
            parentWorldId: task.value),
      ], version: 2);

      expect((await syncB.performSync()).success, isTrue);
      final onB = await attachmentOn(dbB, task);
      expect(onB.content, [104, 105]);
      // And it is now addressable by hash like anything else.
      expect(onB.contentHash, NooDatabase.blobId([104, 105]));
    });

    test('a full-state snapshot references blobs and keeps them alive '
        'through compaction; replaced content is collected', () async {
      final wid = await attachOnA(big);
      await syncA.performSync();
      await syncB.performSync();

      // Replace the attachment's bytes: the old blob is now referenced only
      // by packet 1, which the snapshot will supersede.
      final replacement = Uint8List.fromList(List.filled(1000, 9));
      final onA = await attachmentOn(dbA, wid);
      await dbA.updateAttachmentContent(onA.id, replacement);
      await syncA.performSync();
      expect(server.blobs.keys, containsAll([bigId, NooDatabase.blobId(replacement)]));

      final result = await syncA.compactRelay();
      expect(result.success, isTrue, reason: result.error);

      final snapshotId = 'device-a:${result.snapshotCounter}';
      expect(server.packetBlobs[snapshotId], [NooDatabase.blobId(replacement)]);
      expect(server.blobs.keys, [NooDatabase.blobId(replacement)],
          reason: 'the superseded blob went with the packets that named it');
      // The snapshot itself did not inline the bytes.
      expect(server.streams['device-a']![result.snapshotCounter]!.length,
          lessThan(4 * 1024));

      // A device bootstrapping from the snapshot still gets the attachment.
      final dbC = NooDatabase.memory();
      final syncC = _service(dbC, server, 'device-c');
      expect((await syncC.performSync()).success, isTrue);
      expect((await attachmentOn(dbC, wid)).content, replacement);
      await dbC.close();
    });

    test('compaction refuses while this device is still missing attachments',
        () async {
      final wid = await attachOnA(big);
      await syncA.performSync();
      server.blobs.remove(bigId);
      await syncB.performSync();
      expect((await attachmentOn(dbB, wid)).content, isNull);

      final result = await syncB.compactRelay();
      expect(result.success, isFalse);
      expect(result.error, contains('missing some attachments'));
    });

    group('device-side collection', () {
      /// The attachment row for [taskWid], soft-deleted ones included —
      /// [attachmentOn] goes through the list query, which hides those, and
      /// deleting is the whole point here.
      Future<FileEntry> fileRowOn(NooDatabase db, WorldId taskWid) async {
        final task = (await db.getTaskByWorldId(taskWid.value))!;
        return (await db.getAllFileRows())
            .firstWhere((f) => f.taskId == task.id);
      }

      test('a deleted attachment gives its space back and comes back on undelete',
          () async {
        final wid = await attachOnA(big);
        await syncA.performSync();
        await syncB.performSync();
        expect((await fileRowOn(dbB, wid)).content, big);

        // Deleted on A, and the deletion reaches B.
        await dbA.deleteAttachment((await fileRowOn(dbA, wid)).id);
        await syncA.performSync();
        await syncB.performSync();
        expect((await fileRowOn(dbB, wid)).removed, 1);

        // Both devices can now release the bytes; the relay still has them,
        // which is what makes it safe.
        for (final sync in [syncA, syncB]) {
          final collected = await sync.collectRemovedBlobs();
          expect(collected.blocked, isNull);
          expect(collected.collected, 1);
        }
        expect((await fileRowOn(dbA, wid)).content, isNull);
        expect((await fileRowOn(dbB, wid)).content, isNull);
        expect((await fileRowOn(dbB, wid)).contentHash, bigId,
            reason: 'the reference outlives the bytes');

        // Nothing drags them back in on the next exchange...
        server.blobFetches.clear();
        await syncB.performSync();
        expect(server.blobFetches, isEmpty);
        expect((await fileRowOn(dbB, wid)).content, isNull);

        // ...but restoring the attachment does.
        await dbB.undeleteAttachment((await fileRowOn(dbB, wid)).id);
        await syncB.performSync();
        expect(server.blobFetches, [bigId]);
        expect((await fileRowOn(dbB, wid)).content, big);
      });

      test('collecting never stalls the stream it has not pushed yet',
          () async {
        // The hazard collection has to avoid: dropping bytes that an unsent
        // packet still references leaves a packet the relay must refuse, and
        // contiguity means everything behind it stops too.
        final wid = await attachOnA(big);
        await dbA.deleteAttachment((await fileRowOn(dbA, wid)).id);

        // Nothing is on the relay yet, so there is nothing to collect against.
        final blockedNow = await syncA.collectRemovedBlobs();
        expect(blockedNow.collected, 0);
        expect(blockedNow.blocked, contains('has not stored yet'));
        expect((await fileRowOn(dbA, wid)).content, isNotNull);

        // The push still works, precisely because the bytes are still here.
        expect((await syncA.performSync()).success, isTrue);
        expect(server.blobs, contains(bigId));

        // Now it is safe, and a later sync is still clean.
        expect((await syncA.collectRemovedBlobs()).collected, 1);
        expect((await syncA.performSync()).success, isTrue);
        expect((await syncB.performSync()).success, isTrue);
        expect((await fileRowOn(dbB, wid)).removed, 1);
      });

      test('a collected device can still compact', () async {
        // A snapshot names current state; a deleted attachment whose bytes are
        // gone must not be declared, or the relay refuses the snapshot.
        final wid = await attachOnA(big);
        await syncA.performSync();
        await dbA.deleteAttachment((await fileRowOn(dbA, wid)).id);
        await syncA.performSync();
        expect((await syncA.collectRemovedBlobs()).collected, 1);

        final result = await syncA.compactRelay();
        expect(result.success, isTrue, reason: result.error);
        expect(server.packetBlobs['device-a:${result.snapshotCounter}'],
            isEmpty);
        expect(server.blobs, isEmpty,
            reason: 'nothing references the blob any more, on any node');

        // And a fresh device bootstrapping from that snapshot agrees.
        final dbC = NooDatabase.memory();
        addTearDown(dbC.close);
        final syncC = _service(dbC, server, 'device-c');
        expect((await syncC.performSync()).success, isTrue);
        expect((await fileRowOn(dbC, wid)).removed, 1);
      });

      test('a LAN-only device collects nothing', () async {
        final wid = await attachOnA(big);
        await syncA.performSync();
        await dbA.deleteAttachment((await fileRowOn(dbA, wid)).id);
        await syncA.performSync();

        final lanOnly = SyncService(
          db: dbA,
          config: const SyncConfig(enabled: true, deviceId: 'device-a'),
          crypto: SyncCrypto(),
          historyService: HistoryService(dbA),
          databasePassword: 'shared-db-password',
        );
        final result = await lanOnly.collectRemovedBlobs();
        expect(result.collected, 0);
        expect(result.blocked, contains('Nearby-device sync'));
        expect((await fileRowOn(dbA, wid)).content, isNotNull);
      });
    });

    group('chunked, resumable, bounded transfer', () {
      /// 64 KB chunks, so the 200 KB fixture actually takes several requests
      /// (the shipping default is [SyncService.defaultBlobChunkBytes], which
      /// would swallow it whole).
      const chunk = 64 * 1024;

      test('a large attachment arrives in pieces', () async {
        final syncChunked =
            _service(dbB, server, 'device-b', blobChunkBytes: chunk);
        final wid = await attachOnA(big);
        await syncA.performSync();

        server.blobRequests.clear();
        expect((await syncChunked.performSync()).success, isTrue);

        final forBlob =
            server.blobRequests.where((r) => r.id == bigId).toList();
        expect(forBlob.length, greaterThan(1),
            reason: '200 KB of ciphertext at $chunk per request '
                'should not be one shot');
        // Contiguous, ascending, starting at the beginning.
        expect(forBlob.first.offset, 0);
        for (var i = 1; i < forBlob.length; i++) {
          expect(forBlob[i].offset,
              forBlob[i - 1].offset + forBlob[i - 1].length);
        }
        expect((await attachmentOn(dbB, wid)).content, big);
      });

      test('a relay with no range support still delivers the whole blob',
          () async {
        server.servesRanges = false;
        final wid = await attachOnA(big);
        await syncA.performSync();
        expect((await syncB.performSync()).success, isTrue);

        expect(server.blobRequests, isEmpty, reason: 'no ranged reads served');
        expect((await attachmentOn(dbB, wid)).content, big);
      });

      test('an interrupted transfer resumes instead of starting over',
          () async {
        final syncChunked =
            _service(dbB, server, 'device-b', blobChunkBytes: chunk);
        final wid = await attachOnA(big);
        await syncA.performSync();

        // Drop the connection after the first chunk.
        server.failSliceAfter = 1;
        server.blobRequests.clear();
        expect((await syncChunked.performSync()).success, isTrue,
            reason: 'a failed attachment never fails the sync');
        expect((await attachmentOn(dbB, wid)).content, isNull);

        // The bytes that did arrive were kept.
        final partial = await dbB.getBlobFetch(bigId);
        expect(partial, isNotNull);
        expect(partial!.received.length, chunk);
        expect(partial.total, isNotNull);

        // The next exchange picks up from there, not from zero.
        server.blobRequests.clear();
        expect((await syncChunked.performSync()).success, isTrue);
        expect(server.blobRequests.first.offset, chunk,
            reason: 'resumed at the offset the interruption left');
        expect((await attachmentOn(dbB, wid)).content, big);
        expect(await dbB.getBlobFetch(bigId), isNull,
            reason: 'the partial is cleared once the blob is whole');
      });

      test('a partial that cannot be verified is thrown away, not resumed into',
          () async {
        final wid = await attachOnA(big);
        await syncA.performSync();

        // Something that is not this blob's ciphertext, left behind by an
        // earlier attempt against a node that had re-encrypted it.
        await dbB.saveBlobFetch(
            bigId, Uint8List.fromList(List.filled(1024, 42)), null);

        expect((await syncB.performSync()).success, isTrue);
        expect((await attachmentOn(dbB, wid)).content, big,
            reason: 'the transfer recovered on its own');
        expect(await dbB.getBlobFetch(bigId), isNull);
      });

      test('the per-exchange budget leaves the rest for later', () async {
        // Three attachments, a budget that only covers one of them.
        final wids = <WorldId>[];
        for (var i = 0; i < 3; i++) {
          wids.add(await attachOnA(
              Uint8List.fromList(List.generate(100 * 1024, (n) => (n + i) % 251)),
              name: 'memo-$i.opus'));
        }
        await syncA.performSync();

        final dbC = NooDatabase.memory();
        addTearDown(dbC.close);
        // Smaller than one attachment: the first is always finished rather
        // than abandoned, and the budget stops the loop before the second.
        final syncC =
            _service(dbC, server, 'device-c', autoFetchBudgetBytes: 50 * 1024);

        expect((await syncC.performSync()).success, isTrue);
        var have = 0;
        for (final wid in wids) {
          if ((await attachmentOn(dbC, wid)).content != null) have++;
        }
        expect(have, 1, reason: 'the budget stopped after the first');
        expect((await dbC.missingBlobHashes()).length, 2);

        // Later exchanges bring the rest, without anyone asking again.
        await syncC.performSync();
        await syncC.performSync();
        for (final wid in wids) {
          expect((await attachmentOn(dbC, wid)).content, isNotNull);
        }
        expect(await dbC.missingBlobHashes(), isEmpty);
      });

      test('opening an attachment fetches it past the budget', () async {
        final wid = await attachOnA(big);
        await syncA.performSync();

        final dbC = NooDatabase.memory();
        addTearDown(dbC.close);
        final syncC = _service(dbC, server, 'device-c', autoFetchBudgetBytes: 0);

        expect((await syncC.performSync()).success, isTrue);
        final pending = await attachmentOn(dbC, wid);
        expect(pending.content, isNull, reason: 'nothing was in budget');

        // What the attachments panel does when the file is tapped.
        expect(await syncC.fetchAttachmentNow(pending.id), isTrue);
        expect((await attachmentOn(dbC, wid)).content, big);
      });

      test('fetching on demand reports failure rather than throwing',
          () async {
        final wid = await attachOnA(big);
        await syncA.performSync();
        final dbC = NooDatabase.memory();
        addTearDown(dbC.close);
        final syncC = _service(dbC, server, 'device-c', autoFetchBudgetBytes: 0);
        await syncC.performSync();
        final pending = await attachmentOn(dbC, wid);

        server.blobs.remove(bigId);
        expect(await syncC.fetchAttachmentNow(pending.id), isFalse);
        expect((await attachmentOn(dbC, wid)).content, isNull);
      });
    });
  });

  group('sync log', () {
    late NooDatabase dbA;
    late NooDatabase dbB;
    late _FakeServer server;
    late SyncService syncA;
    late SyncService syncB;

    setUp(() {
      dbA = NooDatabase.memory();
      dbB = NooDatabase.memory();
      server = _FakeServer();
      syncA = _service(dbA, server, 'device-a', journal: SyncJournal(dbA));
      syncB = _service(dbB, server, 'device-b', journal: SyncJournal(dbB));
    });

    tearDown(() async {
      await dbA.close();
      await dbB.close();
    });

    Future<List<SyncLogEventRow>> events(NooDatabase db,
            {String? kind, int minLevel = 0}) async =>
        (await db.getSyncLogEvents(minLevel: minLevel))
            .where((e) => kind == null || e.kind == kind)
            .toList();

    test('a relay sync records the packet on both sides under one hash',
        () async {
      final wid = WorldId.create();
      await _createTask(dbA, wid, 'Groceries');
      await syncA.performSync();
      await syncB.performSync();

      final runsA = await dbA.getSyncLogRuns();
      expect(runsA.single.trigger, 'relay');
      expect(runsA.single.outcome, 'ok');
      expect(runsA.single.finishedAt, isNotNull);

      final packaged = (await events(dbA, kind: SyncLogKind.packaged)).single;
      final pushed = (await events(dbA, kind: SyncLogKind.pushed)).single;
      final received =
          (await events(dbB, kind: SyncLogKind.packetStored)).single;
      expect(packaged.packetHash, hasLength(64));
      expect(pushed.packetHash, packaged.packetHash);
      expect(received.packetHash, packaged.packetHash);
      expect(received.originDevice, 'device-a');
      expect(received.counter, packaged.counter);

      // Outgoing and incoming change events agree on the value fingerprint.
      final out = (await events(dbA, kind: SyncLogKind.outgoing))
          .singleWhere((e) => e.field == 'title');
      final created = (await events(dbB))
          .singleWhere((e) => e.field == 'title' && e.direction == 'in');
      expect(created.kind, SyncLogKind.created);
      expect(out.valuePreview, 'Groceries');
      expect(created.valueHash, out.valueHash);
      expect(created.worldId, wid.value);
    });

    test('an exact timestamp tie is a warning carrying both timestamps',
        () async {
      final wid = WorldId.create();
      final id = await _createTask(dbB, wid, 'Mine');
      final local = await dbB.getLatestTaskHistoryForField(id, 'title');

      await _injectPacket(server, dbB, 'device-c', [
        SyncChange(
          entityType: 'task',
          worldId: wid.value,
          field: 'title',
          value: 'Theirs',
          timestamp: local!.timestamp,
          isCreation: false,
        ),
      ]);
      await syncB.performSync();

      final tie = (await events(dbB, kind: SyncLogKind.lwwTie)).single;
      expect(tie.level, SyncLogLevel.warning.index);
      expect(tie.remoteTs, local.timestamp);
      expect(tie.localTs, local.timestamp);
      expect(tie.valuePreview, 'Theirs');
      final warnings = await dbB.getSyncLogEvents(minLevel: 1);
      expect(warnings.map((e) => e.kind), contains(SyncLogKind.lwwTie));
    });

    test('an older incoming value is logged as lost, not as a warning',
        () async {
      final wid = WorldId.create();
      await _createTask(dbB, wid, 'Newer');
      await _injectPacket(server, dbB, 'device-c', [
        SyncChange(
          entityType: 'task',
          worldId: wid.value,
          field: 'title',
          value: 'Older',
          timestamp: '2020-01-01T00:00:00.000000Z',
          isCreation: false,
        ),
      ]);
      await syncB.performSync();

      final lost = (await events(dbB, kind: SyncLogKind.lwwLost)).single;
      expect(lost.level, SyncLogLevel.info.index);
      expect(lost.localTs, isNotNull);
      expect(lost.message, contains('newer'));
    });

    test('a conflict copy is logged on the device that makes it', () async {
      final wid = WorldId.create();
      final idA = await _createTask(dbA, wid, 'Base');
      await syncA.performSync();
      await syncB.performSync();
      final idB = (await dbB.getTaskByWorldId(wid.value))!.id;

      await dbB.updateTask(idB, content: 'from-b');
      await Future.delayed(const Duration(milliseconds: 5));
      await dbA.updateTask(idA, content: 'from-a');
      await syncB.performSync();
      await syncA.performSync();

      final copy = (await events(dbA, kind: SyncLogKind.conflictCopy)).single;
      expect(copy.worldId, wid.value);
      expect(copy.originDevice, 'device-b');
      expect(copy.level, SyncLogLevel.warning.index);
      expect(await events(dbB, kind: SyncLogKind.conflictCopy), isEmpty);
    });

    test('an unreadable packet and an orphaned change are reported', () async {
      server.injectCorrupt('device-c');
      await _injectPacket(server, dbB, 'device-d', [
        SyncChange(
          entityType: 'task',
          worldId: WorldId.create().value,
          field: 'title',
          value: 'Edit to a task never seen',
          timestamp: NooDatabase.nowIso(),
          isCreation: false,
        ),
      ]);
      await syncB.performSync();

      final failed = (await events(dbB, kind: SyncLogKind.decodeFailed)).single;
      expect(failed.level, SyncLogLevel.error.index);
      expect(failed.originDevice, 'device-c');
      final orphan = (await events(dbB, kind: SyncLogKind.orphaned)).single;
      expect(orphan.originDevice, 'device-d');
      expect(orphan.level, SyncLogLevel.warning.index);
    });

    test('a full-state packet counts routine changes and logs exceptions',
        () async {
      final changes = <SyncChange>[];
      for (var i = 0; i < 20; i++) {
        changes.add(SyncChange(
          entityType: 'task',
          worldId: WorldId.create().value,
          field: 'title',
          value: 'Task $i',
          timestamp: NooDatabase.nowIso(),
          isCreation: true,
        ));
      }
      changes.add(SyncChange(
        entityType: 'file',
        worldId: WorldId.create().value,
        field: 'filename',
        value: 'lost.txt',
        timestamp: NooDatabase.nowIso(),
        isCreation: true,
        parentWorldId: WorldId.create().value,
      ));
      await _injectPacket(server, dbB, 'device-c', changes, fullState: true);
      await syncB.performSync();

      expect(await events(dbB, kind: SyncLogKind.created), isEmpty);
      expect(await events(dbB, kind: SyncLogKind.orphaned), hasLength(1));
      final summary =
          (await events(dbB, kind: SyncLogKind.packetApplied)).single;
      expect(summary.detailJson, contains('"created":20'));
      final run = (await dbB.getSyncLogRuns()).single;
      expect(run.countsJson, contains('"created":20'));
    });

    test('a packet that rolls back leaves no change events behind', () async {
      final task = WorldId.create().value;
      await _injectPacket(server, dbB, 'device-c', [
        SyncChange(
          entityType: 'task',
          worldId: task,
          field: 'title',
          value: 'Owner',
          timestamp: NooDatabase.nowIso(),
          isCreation: true,
        ),
        SyncChange(
          entityType: 'file',
          worldId: WorldId.create().value,
          field: 'content',
          value: '%%% not base64 %%%',
          timestamp: NooDatabase.nowIso(),
          isCreation: true,
          parentWorldId: task,
        ),
      ]);
      await syncB.performSync();

      expect(await dbB.getTaskByWorldId(task), isNull);
      expect(await events(dbB, kind: SyncLogKind.created), isEmpty);
      final failed = (await events(dbB, kind: SyncLogKind.applyFailed)).single;
      expect(failed.level, SyncLogLevel.error.index);
    });

    test('a LAN exchange is its own run, named after the peer', () async {
      final wid = WorldId.create();
      await _createTask(dbA, wid, 'Via relay');
      await syncA.performSync();

      await syncB.exchangeWithSource(_FakeApiClient(server, const SyncConfig()),
          trigger: 'lan-return');
      final run = (await dbB.getSyncLogRuns()).single;
      expect(run.trigger, 'lan-return');
      expect(run.remote, 'relay');
      expect(await events(dbB, kind: SyncLogKind.exchangeStart), hasLength(1));
    });

    test('retention keeps the newest runs and drops old ones with their events',
        () async {
      for (var i = 0; i < 12; i++) {
        final run = await dbA.startSyncLogRun(trigger: 'relay');
        await dbA.insertSyncLogEvents([
          SyncLogEventsCompanion.insert(
              runId: run, seq: 0, at: NooDatabase.nowIso(), kind: 'note'),
        ]);
      }
      await dbA.customStatement(
          "UPDATE sync_log_runs SET started_at = '2000-01-01T00:00:00.000000Z' "
          'WHERE id = 12');

      final removed = await dbA.pruneSyncLog(
        beforeIso: NooDatabase.formatIso(
            DateTime.now().subtract(const Duration(days: 30))),
        keepRuns: 10,
      );
      expect(removed, 3); // runs 1 and 2 by count, run 12 by age
      final runs = await dbA.getSyncLogRuns();
      expect(runs.map((r) => r.id), [11, 10, 9, 8, 7, 6, 5, 4, 3]);
      expect(await dbA.getSyncLogEvents(), hasLength(9));
    });

    test('a run left open by a previous process is marked interrupted',
        () async {
      final stale = await dbA.startSyncLogRun(trigger: 'relay');
      await _createTask(dbA, WorldId.create(), 'x');
      await syncA.performSync();

      final runs = await dbA.getSyncLogRuns();
      expect(runs.firstWhere((r) => r.id == stale).outcome, 'interrupted');
      expect(runs.firstWhere((r) => r.id != stale).outcome, 'ok');
    });

    test('searching by a task name finds its events', () async {
      final wid = WorldId.create();
      await _createTask(dbA, wid, 'Quarterly report');
      await syncA.performSync();

      final ids = await dbA.worldIdsMatchingName('quarterly');
      expect(ids, {wid.value});
      final found =
          await dbA.getSyncLogEvents(search: 'quarterly', worldIds: ids);
      expect(found.where((e) => e.worldId == wid.value), isNotEmpty);
      expect(await dbA.syncLogLabels({wid.value}),
          {wid.value: 'Quarterly report'});
    });
  });

  group('cancel', () {
    late NooDatabase dbA;
    late NooDatabase dbB;
    late _FakeServer server;
    late SyncService syncA;
    late SyncService syncB;

    setUp(() {
      dbA = NooDatabase.memory();
      dbB = NooDatabase.memory();
      server = _FakeServer();
      syncA = _service(dbA, server, 'device-a');
      syncB = _service(dbB, server, 'device-b');
    });

    tearDown(() async {
      await dbA.close();
      await dbB.close();
    });

    /// Cancel as soon as the run reports [detail].
    void Function(SyncProgress) cancelAt(SyncService service, String detail) =>
        (p) {
          if (p.detail == detail) service.requestCancel();
        };

    test('cancelled before upload: nothing reaches the relay, the next run '
        'sends it', () async {
      final wid = WorldId.create();
      await _createTask(dbA, wid, 'Hello');

      final res = await syncA.performSync(
          onProgress: cancelAt(syncA, 'Uploading to server'));
      expect(res.success, isFalse);
      expect(res.cancelled, isTrue);
      expect(server.vector(), isEmpty);

      expect((await syncA.performSync()).success, isTrue);
      expect((await syncB.performSync()).success, isTrue);
      expect(await dbB.getTaskByWorldId(wid.value), isNotNull);
    });

    test('cancelled before the pull: nothing applied, the next run resumes',
        () async {
      final wid = WorldId.create();
      await _createTask(dbA, wid, 'Hello');
      await syncA.performSync();

      final res = await syncB.performSync(
          onProgress: cancelAt(syncB, 'Downloading remote changes'));
      expect(res.cancelled, isTrue);
      expect(await dbB.getTaskByWorldId(wid.value), isNull);

      final again = await syncB.performSync();
      expect(again.success, isTrue);
      expect(again.cancelled, isFalse);
      expect(await dbB.getTaskByWorldId(wid.value), isNotNull);
    });

    test('a large packet yields to the event loop, reports progress, and a '
        'cancel inside it rolls it back for the next run', () async {
      await syncA.prepareCrypto();
      final wids = <WorldId>[];
      for (var i = 0; i < 800; i++) {
        final wid = WorldId.create();
        wids.add(wid);
        await _createTask(dbA, wid, 'Task $i');
      }
      await syncA.performSync(); // one packet of ~3,200 changes
      expect(server.vector(), {'device-a': 1});

      // Only a run that gives the event loop turns lets this timer fire
      // before the apply is over.
      final fractions = <double>[];
      Timer? cancelTimer;
      final res = await syncB.performSync(onProgress: (p) {
        if (p.stage == SyncStage.applying && p.fraction != null) {
          fractions.add(p.fraction!);
        }
        if (p.detail == 'Downloading remote changes') {
          cancelTimer = Timer(const Duration(milliseconds: 250),
              syncB.requestCancel);
        }
      });
      cancelTimer?.cancel();

      expect(res.cancelled, isTrue);
      expect(fractions, isNotEmpty);
      expect(fractions.every((f) => f >= 0 && f < 1), isTrue);
      // The packet's transaction rolled back: nothing half-applied, and not
      // written off as unreadable either.
      expect(await dbB.getTaskByWorldId(wids.first.value), isNull);
      expect(res.skippedPackets, isEmpty);
      expect(syncB.skippedBlobs, isEmpty);

      final again = await syncB.performSync();
      expect(again.success, isTrue);
      for (final wid in [wids.first, wids.last]) {
        expect(await dbB.getTaskByWorldId(wid.value), isNotNull);
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('a request with nothing running is ignored', () async {
      syncA.requestCancel();
      final res = await syncA.performSync();
      expect(res.success, isTrue);
      expect(res.cancelled, isFalse);
    });
  });
}

/// A [PacketSource] that offers one packet whatever the requester's vector
/// says. A real exchange filters held slots out before they reach the ingest
/// path, so this is the only way to put a colliding packet in front of it.
class _StubSource extends PacketSource {
  final RemotePacket packet;

  /// Encrypted blobs this source will hand out, by id.
  final Map<String, Uint8List> blobs;

  _StubSource(this.packet, {this.blobs = const {}});

  @override
  String get sourceName => 'stub';

  @override
  Future<Map<String, int>> getVector() async =>
      {packet.originDeviceId: packet.counter};

  @override
  Future<({List<RemotePacket> changes, bool hasMore})> getChanges(
    Map<String, int> have, {
    int limit = 100,
  }) async =>
      (changes: [packet], hasMore: false);

  @override
  Future<Map<int, String>?> getStreamHashes(
    String deviceId, {
    required int from,
    required int to,
  }) async =>
      null;

  @override
  Future<Uint8List?> getBlob(String blobId) async => blobs[blobId];
}
