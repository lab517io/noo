import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/diff_utils.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/history_service.dart';
import 'package:noo/domain/entities/sync_packet.dart';

/// Diff-field history storage (title/content): update rows store the dmp
/// patch only — the full previous value is kept just once, as the base of a
/// chain that has no creation row — and the actual values are reconstructable
/// by replaying the chain. The v9 migration compacts legacy rows (full old
/// text stored beside every patch) to the same shape.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('diff-field history storage', () {
    late NooDatabase db;

    setUp(() => db = NooDatabase.memory());
    tearDown(() => db.close());

    test('update rows carry the patch only; creation row anchors the chain',
        () async {
      final id = await db.createTask(
          worldId: 'w-1', title: 'First', content: 'one');
      await db.updateTask(id, title: 'Second', content: 'one two');
      await db.updateTask(id, title: 'Third', content: 'one two three');

      for (final field in ['title', 'content']) {
        final rows = await db.getTaskHistoryForField(id, field);
        expect(rows, hasLength(3));

        // Creation row: full value, null old.
        expect(rows.first.oldValue, isNull);
        expect(DiffUtils.isPatch(rows.first.newValue!), isFalse);

        // Update rows: patch in newValue, '' marker in oldValue — never the
        // full previous text, and never null (null means creation).
        for (final row in rows.skip(1)) {
          expect(row.oldValue, '');
          expect(DiffUtils.isPatch(row.newValue!), isTrue);
        }
      }
    });

    test('replay reconstructs the exact value sequence', () async {
      final id = await db.createTask(worldId: 'w-1', title: 'v1');
      await db.updateTask(id, title: 'v2 with more words');
      await db.updateTask(id, title: 'v3');
      await db.updateTask(id, title: 'v3 — final, with «unicode» ✓');

      final history = HistoryService(db);
      final values = await history.reconstructTaskField(id, 'title');
      expect(values.map((v) => v.value).toList(),
          ['v1', 'v2 with more words', 'v3', 'v3 — final, with «unicode» ✓']);

      // And the per-row (old, new) pairs line up as a chain.
      final rows = await db.getTaskHistoryForField(id, 'title');
      final pairs = HistoryService.reconstructTaskFieldChain(rows);
      expect(pairs.first.oldValue, isNull);
      for (var i = 1; i < pairs.length; i++) {
        expect(pairs[i].oldValue, pairs[i - 1].newValue);
      }
    });

    test('a remote-created chain keeps its base and stays reconstructable',
        () async {
      // Remote creation records no history; the first update row must anchor
      // the chain itself. Remote timestamps lie in the past so the later
      // local edit sorts after them.
      final t0 = DateTime.now().toUtc().subtract(const Duration(hours: 1));
      final id = await db.createTaskFromRemote(
        worldId: 'w-r',
        remoteTimestamp: t0.toIso8601String(),
      );
      await db.updateTask(id,
          content: 'remote v1',
          remoteTimestamp:
              t0.add(const Duration(seconds: 1)).toIso8601String());
      await db.updateTask(id, content: 'remote v1 + local edit');

      final rows = await db.getTaskHistoryForField(id, 'content');
      expect(rows, hasLength(2));
      // Base row: old content was null (no prior value) — the patch replays
      // from ''. Second row: '' marker.
      expect(rows[0].oldValue, isNull);
      expect(rows[1].oldValue, '');

      final values =
          await HistoryService(db).reconstructTaskField(id, 'content');
      expect(values.map((v) => v.value).toList(),
          ['remote v1', 'remote v1 + local edit']);
    });

    test('legacy rows (full old value beside the patch) replay correctly',
        () async {
      final id = await db.createTask(worldId: 'w-1', title: 'start');
      // Hand-write a legacy-format update row the way pre-v9 builds did.
      await db.insertTaskHistory(
        taskId: id,
        field: 'title',
        oldValue: 'start',
        newValue: DiffUtils.computeDiff('start', 'legacy edit')!,
      );
      // Continue the chain in the current format.
      await db.insertTaskHistory(
        taskId: id,
        field: 'title',
        oldValue: '',
        newValue: DiffUtils.computeDiff('legacy edit', 'new-format edit')!,
      );

      final rows = await db.getTaskHistoryForField(id, 'title');
      final pairs = HistoryService.reconstructTaskFieldChain(rows);
      expect(pairs.map((p) => p.newValue).toList(),
          ['start', 'legacy edit', 'new-format edit']);
    });

    test('compaction blanks legacy old values but keeps each chain base',
        () async {
      // A chain with no creation row (remote-created task, legacy rows).
      final t0 = DateTime.now().toUtc();
      final id = await db.createTaskFromRemote(
          worldId: 'w-r', remoteTimestamp: t0.toIso8601String());
      await db.insertTaskHistory(
        taskId: id,
        field: 'content',
        oldValue: 'base value', // legacy base: full old text
        newValue: DiffUtils.computeDiff('base value', 'edit one')!,
      );
      await db.insertTaskHistory(
        taskId: id,
        field: 'content',
        oldValue: 'edit one', // legacy redundancy — should be blanked
        newValue: DiffUtils.computeDiff('edit one', 'edit two')!,
      );

      await db.compactTaskHistoryOldValues();
      await db.compactTaskHistoryOldValues(); // idempotent

      final rows = await db.getTaskHistoryForField(id, 'content');
      expect(rows[0].oldValue, 'base value'); // chain base retained
      expect(rows[1].oldValue, '');

      final pairs = HistoryService.reconstructTaskFieldChain(rows);
      expect(pairs.map((p) => p.newValue).toList(), ['edit one', 'edit two']);
    });
  });

  group('v9 migration', () {
    late Directory dir;
    late String path;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('noo-history-v9');
      path = '${dir.path}/history.noo';
    });

    tearDown(() => dir.deleteSync(recursive: true));

    test('a pre-v9 database is compacted on open', () async {
      final seed = NooDatabase.fromPath(path);
      final id = await seed.createTask(worldId: 'w-1', title: 'start');
      // Legacy-format rows as pre-v9 builds wrote them.
      await seed.insertTaskHistory(
        taskId: id,
        field: 'title',
        oldValue: 'start',
        newValue: DiffUtils.computeDiff('start', 'middle')!,
      );
      await seed.insertTaskHistory(
        taskId: id,
        field: 'title',
        oldValue: 'middle',
        newValue: DiffUtils.computeDiff('middle', 'end')!,
      );
      await seed.customStatement('PRAGMA user_version = 8');
      await seed.close();

      final upgraded = NooDatabase.fromPath(path);
      addTearDown(upgraded.close);

      final rows = await upgraded.getTaskHistoryForField(id, 'title');
      expect(rows, hasLength(3));
      expect(rows[0].oldValue, isNull); // creation row untouched
      expect(rows[1].oldValue, ''); // full old text dropped
      expect(rows[2].oldValue, '');

      final pairs = HistoryService.reconstructTaskFieldChain(rows);
      expect(pairs.map((p) => p.newValue).toList(), ['start', 'middle', 'end']);
    });
  });

  group('attachment content history', () {
    late NooDatabase db;

    setUp(() => db = NooDatabase.memory());
    tearDown(() => db.close());

    /// Content history rows for one attachment, oldest first.
    Future<List<HistoryFileData>> contentRows(int fileId) async =>
        (await db.getAllFileHistory())
            .where((h) => h.fileId == fileId && h.field == 'content')
            .toList();

    Future<int> seedAttachment(Uint8List content) async {
      final taskId = await db.createTask(worldId: 'w-t', title: 'owner');
      return db.createAttachment(
        taskId: taskId,
        worldId: 'w-f',
        filename: 'memo.ogg',
        content: content,
      );
    }

    test('creation records the blob reference, not the bytes', () async {
      final content = Uint8List.fromList(List.filled(4096, 7));
      final id = await seedAttachment(content);

      final rows = await contentRows(id);
      expect(rows, hasLength(1));
      expect(rows.single.oldValue, isNull); // creation
      expect(rows.single.newValue, 'blob:${NooDatabase.blobId(content)}');
      expect(BlobRef.tryParse(rows.single.newValue!), isNotNull);
    });

    test('an update references both blobs and stores neither', () async {
      final v1 = Uint8List.fromList(List.filled(4096, 1));
      final v2 = Uint8List.fromList(List.filled(8192, 2));
      final id = await seedAttachment(v1);
      await db.updateAttachmentContent(id, v2);

      final rows = await contentRows(id);
      expect(rows, hasLength(2));
      expect(rows[1].oldValue, 'blob:${NooDatabase.blobId(v1)}');
      expect(rows[1].newValue, 'blob:${NooDatabase.blobId(v2)}');

      // The bytes are in the file row, and only there.
      final file = await db.getAttachmentWithContent(id);
      expect(file!.content, v2);
    });

    test('a pending-blob reference records the prior blob, not its bytes',
        () async {
      final v1 = Uint8List.fromList(List.filled(4096, 3));
      final id = await seedAttachment(v1);
      final remoteHash = NooDatabase.blobId(Uint8List.fromList([9, 9, 9]));
      await db.markAttachmentPendingBlob(id, remoteHash,
          remoteTimestamp: DateTime.now().toUtc().toIso8601String());

      final rows = await contentRows(id);
      expect(rows[1].oldValue, 'blob:${NooDatabase.blobId(v1)}');
      expect(rows[1].newValue, 'blob:$remoteHash');
    });

    test('history size does not grow with the size of the attachment',
        () async {
      // The regression this whole change is about: before it, each edit wrote
      // the whole attachment twice into history, so a big file made big rows.
      final id = await seedAttachment(Uint8List.fromList(List.filled(64, 1)));
      for (var i = 0; i < 5; i++) {
        await db.updateAttachmentContent(
            id, Uint8List.fromList(List.filled(512 * 1024, i)));
      }

      final rows = await contentRows(id);
      expect(rows, hasLength(6));
      for (final row in rows) {
        expect((row.oldValue ?? '').length, lessThanOrEqualTo(69));
        expect(row.newValue!.length, 69); // 'blob:' + 64 hex
      }
    });
  });

  group('v12 migration', () {
    late Directory dir;
    late String path;

    setUp(() {
      dir = Directory.systemTemp.createTempSync('noo-history-v12');
      path = '${dir.path}/history.noo';
    });

    tearDown(() => dir.deleteSync(recursive: true));

    /// Write a legacy content row the way pre-v12 builds did: the whole
    /// attachment, base64, on both sides of the change.
    Future<void> seedLegacyRow(NooDatabase db, int fileId,
        {Uint8List? from, required Uint8List to}) {
      return db.insertFileHistory(
        fileId: fileId,
        field: 'content',
        oldValue: from == null ? null : base64.encode(from),
        newValue: base64.encode(to),
      );
    }

    test('a pre-v12 database is compacted on open', () async {
      final v1 = Uint8List.fromList(List.filled(2048, 11));
      final v2 = Uint8List.fromList(List.filled(4096, 22));

      final seed = NooDatabase.fromPath(path);
      final taskId = await seed.createTask(worldId: 'w-t', title: 'owner');
      final fileId = await seed.createAttachment(
        taskId: taskId,
        worldId: 'w-f',
        filename: 'a.bin',
        content: v1,
      );
      // Replace the reference createAttachment wrote with the legacy form,
      // then add a legacy update row on top of it.
      await seed.customStatement(
          "UPDATE history_file SET new_value = ? WHERE field = 'content'",
          [base64.encode(v1)]);
      await seedLegacyRow(seed, fileId, from: v1, to: v2);
      await seed.customStatement('PRAGMA user_version = 11');
      await seed.close();

      final upgraded = NooDatabase.fromPath(path);
      addTearDown(upgraded.close);

      final rows = (await upgraded.getAllFileHistory())
          .where((h) => h.field == 'content')
          .toList();
      expect(rows, hasLength(2));
      expect(rows[0].oldValue, isNull); // creation row keeps its null
      expect(rows[0].newValue, 'blob:${NooDatabase.blobId(v1)}');
      expect(rows[1].oldValue, 'blob:${NooDatabase.blobId(v1)}');
      expect(rows[1].newValue, 'blob:${NooDatabase.blobId(v2)}');
    });

    test('compaction is idempotent and spares what it cannot decode',
        () async {
      final v1 = Uint8List.fromList(List.filled(1024, 5));

      final db = NooDatabase.fromPath(path);
      addTearDown(db.close);
      final taskId = await db.createTask(worldId: 'w-t', title: 'owner');
      final fileId = await db.createAttachment(
        taskId: taskId,
        worldId: 'w-f',
        filename: 'a.bin',
        content: v1,
      );
      await seedLegacyRow(db, fileId, to: v1);
      // Not base64, and not a reference: a row nothing can interpret.
      await db.insertFileHistory(
          fileId: fileId, field: 'content', newValue: 'not base64 !!!');

      expect(await db.compactFileHistoryContent(), 1);
      // Second run finds nothing left to do — the reference rows are skipped
      // and the undecodable row is left exactly as it was.
      expect(await db.compactFileHistoryContent(), 0);

      final rows = (await db.getAllFileHistory())
          .where((h) => h.field == 'content')
          .toList();
      expect(rows.map((r) => r.newValue).toList(), [
        'blob:${NooDatabase.blobId(v1)}',
        'blob:${NooDatabase.blobId(v1)}',
        'not base64 !!!',
      ]);
    });
  });
}
