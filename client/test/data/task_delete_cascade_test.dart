import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';

/// Deleting a task takes its attachments with it (docs/P2P_SYNC.md §3.5).
/// Before this cascade the `file` rows of a deleted task stayed live for
/// good: collection never freed their bytes, every new device fetched them,
/// and the full-state snapshot re-announced them to the relay.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NooDatabase db;

  setUp(() {
    db = NooDatabase.memory();
  });
  tearDown(() => db.close());

  Uint8List bytes(int fill, [int length = 1024]) =>
      Uint8List.fromList(List.filled(length, fill));

  Future<int> attach(int taskId, String worldId, Uint8List content) =>
      db.createAttachment(
        taskId: taskId,
        worldId: worldId,
        filename: '$worldId.bin',
        content: content,
      );

  Future<FileEntry> file(int id) async => (await db.getAttachmentWithContent(id))!;

  /// Timestamps of every `removed` history row of attachment [id], newest
  /// first.
  Future<List<HistoryFileData>> removedRows(int id) async =>
      (await db.getFileHistory(id))
          .where((h) => h.field == 'removed')
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  group('deleteTask', () {
    test('soft-deletes the attachments, each with its own history row at the '
        "task's removal time", () async {
      final taskId = await db.createTask(worldId: 'w-task', title: 'owner');
      final a = await attach(taskId, 'w-a', bytes(1));
      final b = await attach(taskId, 'w-b', bytes(2));

      expect(await db.deleteTask(taskId), isTrue);

      final task = (await db.getTaskById(taskId))!;
      expect(task.removed, 1);
      for (final id in [a, b]) {
        final row = await file(id);
        expect(row.removed, 1);
        expect(row.timestamp, task.timestamp,
            reason: 'file row stamped with the task removal time');
        final history = await removedRows(id);
        expect(history, hasLength(1));
        expect(history.single.newValue, '1');
        expect(history.single.isRemote, 0, reason: 'a local change is pushed');
        final taskRemoval =
            (await db.getLatestTaskHistoryForField(taskId, 'removed'))!;
        expect(history.single.timestamp, taskRemoval.timestamp,
            reason: 'the cascade shares the task row\'s history timestamp');
      }
    });

    test('reaches the attachments of every descendant', () async {
      final root = await db.createTask(worldId: 'w-root', title: 'root');
      final child =
          await db.createTask(worldId: 'w-child', title: 'child', parentId: root);
      final grandchild = await db.createTask(
          worldId: 'w-grandchild', title: 'grandchild', parentId: child);
      final onChild = await attach(child, 'w-c', bytes(3));
      final onGrandchild = await attach(grandchild, 'w-g', bytes(4));

      await db.deleteTask(root);

      expect((await file(onChild)).removed, 1);
      expect((await file(onGrandchild)).removed, 1);
    });

    test('makes the blobs collectable and keeps them out of the missing set',
        () async {
      final taskId = await db.createTask(worldId: 'w-task', title: 'owner');
      final content = bytes(5);
      final id = await attach(taskId, 'w-a', content);

      await db.deleteTask(taskId);

      expect(await db.collectRemovedBlobs(), 1);
      final row = await file(id);
      expect(row.content, isNull, reason: 'bytes released');
      expect(row.contentHash, NooDatabase.blobId(content),
          reason: 'the reference is kept so an undelete can refetch');
      expect(await db.missingBlobHashes(), isEmpty,
          reason: 'a collected blob of a deleted task is not asked for again');
      expect(await db.fillBlob(NooDatabase.blobId(content), content), 0);
    });

    test('leaves an attachment deleted on its own with its own history',
        () async {
      final taskId = await db.createTask(worldId: 'w-task', title: 'owner');
      final gone = await attach(taskId, 'w-gone', bytes(6));
      final kept = await attach(taskId, 'w-kept', bytes(7));
      await db.deleteAttachment(gone);
      final ownRemoval = (await removedRows(gone)).single;

      await db.deleteTask(taskId);

      expect(await removedRows(gone), [ownRemoval],
          reason: 'already removed: the cascade writes nothing for it');
      expect((await removedRows(kept)).single.timestamp,
          isNot(ownRemoval.timestamp));
    });
  });

  group('undeleteTask', () {
    test('restores the attachments the cascade removed', () async {
      final taskId = await db.createTask(worldId: 'w-task', title: 'owner');
      final content = bytes(8);
      final id = await attach(taskId, 'w-a', content);
      await db.deleteTask(taskId);
      await db.collectRemovedBlobs();

      expect(await db.undeleteTask(taskId), isTrue);

      final row = await file(id);
      expect(row.removed, 0);
      expect((await db.getAttachmentsForTask(taskId)).map((f) => f.id), [id]);
      final history = await removedRows(id);
      expect(history.first.newValue, '0');
      expect(history.first.oldValue, '1');
      // Its bytes were collected; the next exchange fetches them back.
      expect(await db.missingBlobHashes(), [NooDatabase.blobId(content)]);
    });

    test('does not restore an attachment the user deleted individually before',
        () async {
      final taskId = await db.createTask(worldId: 'w-task', title: 'owner');
      final gone = await attach(taskId, 'w-gone', bytes(9));
      final kept = await attach(taskId, 'w-kept', bytes(10));
      await db.deleteAttachment(gone);
      await db.deleteTask(taskId);

      await db.undeleteTask(taskId);

      expect((await file(gone)).removed, 1, reason: 'deleted on purpose');
      expect((await file(kept)).removed, 0, reason: 'taken by the cascade');
      expect((await db.getAttachmentsForTask(taskId)).map((f) => f.id), [kept]);
    });

    test('does not restore an attachment deleted after the task was', () async {
      // A removal from another device that reached the file after the task
      // went: its history row is not the cascade's, so the undelete leaves it.
      final taskId = await db.createTask(worldId: 'w-task', title: 'owner');
      final id = await attach(taskId, 'w-a', bytes(11));
      await db.deleteTask(taskId);
      final later = DateTime.now().toUtc().add(const Duration(minutes: 1));
      await db.undeleteAttachment(id, remoteTimestamp: later.toIso8601String());
      await db.deleteAttachment(id,
          remoteTimestamp: later.add(const Duration(minutes: 1)).toIso8601String());

      await db.undeleteTask(taskId,
          remoteTimestamp: later.add(const Duration(minutes: 2)).toIso8601String());

      expect((await file(id)).removed, 1);
    });

    test('survives a rename of the removed row (history, not the row '
        'timestamp, identifies the cascade)', () async {
      final taskId = await db.createTask(worldId: 'w-task', title: 'owner');
      final id = await attach(taskId, 'w-a', bytes(12));
      await db.deleteTask(taskId);
      final later = DateTime.now().toUtc().add(const Duration(minutes: 1));
      // A rename from elsewhere lands on the removed row and moves its
      // timestamp away from the task's.
      await db.updateAttachment(id,
          filename: 'renamed.bin', remoteTimestamp: later.toIso8601String());

      await db.undeleteTask(taskId);

      expect((await file(id)).removed, 0);
    });
  });

  group('applied from another device', () {
    String iso(DateTime t) => NooDatabase.formatIso(t);

    test('a remote deletion cascades too, and applying it twice adds nothing',
        () async {
      final taskId = await db.createTask(worldId: 'w-task', title: 'owner');
      final id = await attach(taskId, 'w-a', bytes(13));
      final ts = iso(DateTime.now().toUtc().add(const Duration(seconds: 1)));

      await db.deleteTask(taskId, remoteTimestamp: ts);
      final row = await file(id);
      expect(row.removed, 1);
      expect(row.timestamp, ts);
      final history = await removedRows(id);
      expect(history, hasLength(1));
      expect(history.single.isRemote, 1, reason: 'never pushed back');
      expect(history.single.timestamp, ts);

      await db.deleteTask(taskId, remoteTimestamp: ts);
      expect(await removedRows(id), hasLength(1),
          reason: 'only live rows are cascaded: idempotent');
    });

    test("the origin's own file removal at the same time is a tie, which "
        'last-writer-wins resolves as nothing to change', () async {
      final taskId = await db.createTask(worldId: 'w-task', title: 'owner');
      final id = await attach(taskId, 'w-a', bytes(14));
      final ts = iso(DateTime.now().toUtc().add(const Duration(seconds: 1)));
      await db.deleteTask(taskId, remoteTimestamp: ts);

      // What SyncService._applyFileChange looks at before applying a
      // `removed` change: the latest local row for the field.
      final latest = (await db.getLatestFileHistoryForField(id, 'removed'))!;
      expect(latest.timestamp, ts);
      expect(latest.newValue, '1');
    });

    test('a remote deletion leaves an attachment changed after it', () async {
      // Attached here while the other device was deleting the task: the
      // twin of a child task created concurrently, which also stays.
      final taskId = await db.createTask(worldId: 'w-task', title: 'owner');
      final id = await attach(taskId, 'w-a', bytes(15));
      final earlier = iso(DateTime.now().toUtc().subtract(const Duration(hours: 1)));

      await db.deleteTask(taskId, remoteTimestamp: earlier);

      expect((await db.getTaskById(taskId))!.removed, 1);
      expect((await file(id)).removed, 0);
      expect(await removedRows(id), isEmpty);
    });

    test('a remote undelete restores what the remote deletion took', () async {
      final taskId = await db.createTask(worldId: 'w-task', title: 'owner');
      final id = await attach(taskId, 'w-a', bytes(16));
      final t1 = DateTime.now().toUtc().add(const Duration(seconds: 1));
      await db.deleteTask(taskId, remoteTimestamp: iso(t1));

      await db.undeleteTask(taskId,
          remoteTimestamp: iso(t1.add(const Duration(seconds: 1))));

      expect((await file(id)).removed, 0);
      expect((await removedRows(id)).first.isRemote, 1);
    });
  });

  group('the v16 sweep', () {
    test('removes the attachments of tasks deleted before the cascade existed',
        () async {
      final db = NooDatabase.memory();
      addTearDown(db.close);
      final kept = await db.createTask(worldId: 'w-kept', title: 'kept');
      final gone = await db.createTask(worldId: 'w-gone', title: 'gone');
      final keptFile = await db.createAttachment(
          taskId: kept, worldId: 'f-kept', filename: 'a', content: Uint8List(3));
      final goneFile = await db.createAttachment(
          taskId: gone, worldId: 'f-gone', filename: 'b', content: Uint8List(3));
      await db.deleteTask(gone);
      // As a pre-cascade build left it: the task removed, its file live.
      await db.customStatement(
          'UPDATE file SET removed = 0 WHERE id = $goneFile');
      await db.customStatement(
          "DELETE FROM history_file WHERE file_id = $goneFile "
          "AND field = 'removed'");

      expect(await db.sweepAttachmentsOfRemovedTasks(), 1);
      expect((await db.getAttachmentMeta(goneFile))?.removed, 1);
      expect((await db.getAttachmentMeta(keptFile))?.removed, 0);
      // Stamped with the task's removal, so undeleting the task restores it.
      await db.undeleteTask(gone);
      expect((await db.getAttachmentMeta(goneFile))?.removed, 0);
      // Idempotent.
      expect(await db.sweepAttachmentsOfRemovedTasks(), 0);
    });
  });

}
