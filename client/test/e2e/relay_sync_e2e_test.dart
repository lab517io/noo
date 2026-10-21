@Tags(['e2e'])
library;

/// End-to-end harness for Phase 4 sync verification against a *live* relay.
///
/// Not part of the normal suite: every test is skipped unless NOO_E2E=1.
/// The harness impersonates the desktop device with the real
/// [SyncApiClient]/[SyncService] stack over HTTP, while a human (or script)
/// drives the Android app as the other device. State persists in a
/// file-backed database so the steps can be run one at a time, interleaved
/// with actions on the phone:
///
///   1. NOO_E2E_STEP=seed            — register the account, push two tasks.
///      (then: Android enrolls into the same account, syncs, sees both
///       tasks, creates 'Android task', syncs again)
///   2. NOO_E2E_STEP=verify_android  — pull; assert 'Android task' arrived;
///      rename 'Desktop task one' → 'Renamed on desktop'; push.
///      (then: Android renames the same task to 'Renamed on Android' —
///       a later wall-clock edit — and syncs)
///   3. NOO_E2E_STEP=final           — pull; assert LWW picked the Android
///      rename.
///
/// Environment: NOO_E2E_DIR (state directory, required), NOO_E2E_SERVER
/// (default http://127.0.0.1:8080). The database password must match the one
/// used on the phone — the packet key is HKDF-derived from it.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/history_service.dart';
import 'package:noo/data/services/sync_api_client.dart';
import 'package:noo/data/services/sync_crypto.dart';
import 'package:noo/data/services/sync_service.dart';
import 'package:noo/domain/entities/sync_config.dart';
import 'package:noo/domain/entities/world_id.dart';

const _dbPassword = 'test1234test1234';
const _relayUser = 'e2e_phase4';
const _relayPassword = 'relay-secret-1';
const _deviceId = 'e2e-desktop-device';

void main() {
  final env = Platform.environment;
  final enabled = env['NOO_E2E'] == '1';
  final step = env['NOO_E2E_STEP'] ?? 'seed';
  final serverUrl = env['NOO_E2E_SERVER'] ?? 'http://127.0.0.1:8080';
  final stateDir = env['NOO_E2E_DIR'];

  late NooDatabase db;
  late SyncApiClient api;
  late SyncService sync;

  setUp(() {
    expect(stateDir, isNotNull, reason: 'NOO_E2E_DIR must be set');
    Directory(stateDir!).createSync(recursive: true);
    db = NooDatabase.fromPath('$stateDir/desktop.db', password: _dbPassword);
    final config = SyncConfig(
      enabled: true,
      serverUrl: serverUrl,
      username: _relayUser,
      password: _relayPassword,
      deviceId: _deviceId,
      deviceName: 'E2E Desktop',
    );
    api = SyncApiClient(config: config);
    sync = SyncService(
      db: db,
      config: config,
      apiClient: api,
      crypto: SyncCrypto(),
      historyService: HistoryService(db),
      databasePassword: _dbPassword,
    );
  });

  tearDown(() async {
    api.dispose();
    await db.close();
  });

  Future<TaskRow?> taskByTitle(String title) =>
      (db.select(db.tasks)..where((t) => t.title.equals(title)))
          .getSingleOrNull();

  Future<void> dumpTasks(String label) async {
    final all = await db.select(db.tasks).get();
    // ignore: avoid_print
    print('[$label] ${all.length} task(s): '
        '${all.map((t) => '"${t.title}"').join(', ')}');
  }

  test('seed: enroll desktop device and push initial tasks', () async {
    try {
      await api.register();
    } on SyncApiException catch (e) {
      // Re-runs land here: the account already exists on the relay.
      // ignore: avoid_print
      print('register: already exists (${e.statusCode}), continuing');
    }

    await db.createTask(
        worldId: WorldId.create().value, title: 'Desktop task one');
    await db.createTask(
        worldId: WorldId.create().value, title: 'Desktop task two');

    final result = await sync.performSync();
    expect(result.success, isTrue, reason: 'seed sync failed: $result');

    final vector = await api.getVector();
    expect(vector[_deviceId], greaterThanOrEqualTo(1),
        reason: 'relay should hold the desktop stream after the push');
    await dumpTasks('seed');
  }, skip: !enabled || step != 'seed');

  test('verify_android: pull phone task, then make the older conflict edit',
      () async {
    final result = await sync.performSync();
    expect(result.success, isTrue, reason: 'pull failed: $result');
    await dumpTasks('verify_android');

    final fromPhone = await taskByTitle('Android task');
    expect(fromPhone, isNotNull,
        reason: "the task created on the phone should arrive via the relay");

    // Older half of the LWW conflict: rename now, the phone renames the same
    // task afterwards, so the phone's title must win everywhere in the end.
    final target = await taskByTitle('Desktop task one');
    expect(target, isNotNull);
    await db.updateTask(target!.id, title: 'Renamed on desktop');

    final push = await sync.performSync();
    expect(push.success, isTrue, reason: 'conflict push failed: $push');
  }, skip: !enabled || step != 'verify_android');

  test('final: the later phone rename wins LWW on the desktop', () async {
    final result = await sync.performSync();
    expect(result.success, isTrue, reason: 'final pull failed: $result');
    await dumpTasks('final');

    expect(await taskByTitle('Renamed on Android'), isNotNull,
        reason: 'the newer phone edit must overwrite the desktop rename');
    expect(await taskByTitle('Renamed on desktop'), isNull,
        reason: 'the older desktop rename must have been superseded');
  }, skip: !enabled || step != 'final');
}
