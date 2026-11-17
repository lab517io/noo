import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/sync_change_packager.dart';

/// Device-side blob collection (docs/P2P_SYNC.md §3.5). A device's blob store
/// is its `file` table, and nothing on a device used to release one: an
/// attachment deleted everywhere still occupied space on every device, while
/// only the relay collected. Collection drops the bytes and keeps the
/// reference, which is the same shape as a blob that has not been fetched yet.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NooDatabase db;
  late int taskId;

  setUp(() async {
    db = NooDatabase.memory();
    taskId = await db.createTask(worldId: 'w-task', title: 'owner');
  });
  tearDown(() => db.close());

  Uint8List bytes(int fill, [int length = 2048]) =>
      Uint8List.fromList(List.filled(length, fill));

  Future<int> attach(String worldId, Uint8List content) => db.createAttachment(
        taskId: taskId,
        worldId: worldId,
        filename: '$worldId.bin',
        content: content,
      );

  group('collectRemovedBlobs', () {
    test('frees a deleted attachment but keeps the reference', () async {
      final content = bytes(1);
      final id = await attach('w-f', content);
      await db.deleteAttachment(id);

      expect(await db.collectRemovedBlobs(), 1);

      final row = (await db.getAttachmentWithContent(id))!;
      expect(row.content, isNull, reason: 'bytes released');
      expect(row.contentHash, NooDatabase.blobId(content),
          reason: 'still names the blob it was');
      expect(row.removed, 1);
    });

    test('leaves a live attachment alone', () async {
      final id = await attach('w-f', bytes(2));
      expect(await db.collectRemovedBlobs(), 0);
      expect((await db.getAttachmentWithContent(id))!.content, isNotNull);
    });

    test('spares a blob a live attachment still shares', () async {
      // The same file attached twice is one blob; deleting one copy must not
      // take the bytes the other is still using.
      final shared = bytes(3);
      final kept = await attach('w-keep', shared);
      final dropped = await attach('w-drop', shared);
      await db.deleteAttachment(dropped);

      expect(await db.collectRemovedBlobs(), 0);
      expect((await db.getAttachmentWithContent(kept))!.content, shared);
      expect((await db.getAttachmentWithContent(dropped))!.content, shared);

      // Once the last live user goes, both copies are collectable.
      await db.deleteAttachment(kept);
      expect(await db.collectRemovedBlobs(), 2);
    });

    test('spares a row with no hash — nothing could name it afterwards',
        () async {
      final id = await attach('w-f', bytes(4));
      await db.deleteAttachment(id);
      await db.customStatement(
          "UPDATE file SET content_hash = '' WHERE id = ?", [id]);

      expect(await db.collectRemovedBlobs(), 0);
      expect((await db.getAttachmentWithContent(id))!.content, isNotNull);
    });

    test('is idempotent', () async {
      final id = await attach('w-f', bytes(5));
      await db.deleteAttachment(id);
      expect(await db.collectRemovedBlobs(), 1);
      expect(await db.collectRemovedBlobs(), 0);
    });
  });

  group('a collected blob is not fetched back', () {
    test('a deleted attachment is not in the missing set', () async {
      final id = await attach('w-f', bytes(6));
      await db.deleteAttachment(id);
      await db.collectRemovedBlobs();

      // Without this the next exchange would download the bytes straight back
      // in, and collection would never actually free anything.
      expect(await db.missingBlobHashes(), isEmpty);
    });

    test('fillBlob does not refill a deleted attachment', () async {
      final content = bytes(7);
      final id = await attach('w-f', content);
      await db.deleteAttachment(id);
      await db.collectRemovedBlobs();

      expect(await db.fillBlob(NooDatabase.blobId(content), content), 0);
      expect((await db.getAttachmentWithContent(id))!.content, isNull);
    });

    test('undeleting asks for the bytes again', () async {
      final content = bytes(8);
      final id = await attach('w-f', content);
      await db.deleteAttachment(id);
      await db.collectRemovedBlobs();
      await db.undeleteAttachment(id);

      final hash = NooDatabase.blobId(content);
      expect(await db.missingBlobHashes(), [hash]);
      expect(await db.fillBlob(hash, content), 1);
      expect((await db.getAttachmentWithContent(id))!.content, content);
    });
  });

  group('a collected blob is never published', () {
    // Publishing a reference this device cannot serve would be refused by the
    // relay (a packet may not declare a blob the relay does not hold), and
    // that refusal stops the whole stream at that packet.
    test('a snapshot omits the content of a collected attachment', () async {
      await attach('w-live', bytes(9));
      final gone = await attach('w-gone', bytes(10));
      await db.deleteAttachment(gone);
      await db.collectRemovedBlobs();

      final changes = await SyncChangePackager(db).buildFullStateChanges();
      String? valueFor(String worldId, String field) => changes
          .where((c) => c.worldId == worldId && c.field == field)
          .map((c) => c.value)
          .firstOrNull;

      expect(valueFor('w-gone', 'content'), isNull);
      expect(valueFor('w-gone', 'removed'), '1',
          reason: 'the deletion still propagates');
      expect(valueFor('w-live', 'content'), isNotNull);
    });

    test('a deleted attachment that still has its bytes publishes them',
        () async {
      // Narrow on purpose: nothing changes for a device that never collects.
      final id = await attach('w-gone', bytes(11));
      await db.deleteAttachment(id);

      final changes = await SyncChangePackager(db).buildFullStateChanges();
      expect(
        changes
            .where((c) => c.worldId == 'w-gone' && c.field == 'content')
            .single
            .value,
        startsWith('blob:'),
      );
    });
  });
}
