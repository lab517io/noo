
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/domain/entities/sync_packet.dart';

/// Every statement the database runs, so a test can assert that a metadata
/// write never selects the `content` column. Drift renders a column as
/// `"file"."content"` and the hash as `"file"."content_hash"`, so the quoted
/// form below matches the BLOB and only the BLOB; a `SELECT *` on `file`
/// reads it too and is caught separately.
class _StatementLog extends QueryInterceptor {
  final List<String> statements = [];

  @override
  Future<List<Map<String, Object?>>> runSelect(
      QueryExecutor executor, String statement, List<Object?> args) {
    statements.add(statement);
    return executor.runSelect(statement, args);
  }

  Iterable<String> get blobReads => statements.where((s) {
        final lower = s.toLowerCase();
        if (!lower.contains('file')) return false;
        return lower.contains('."content"') ||
            lower.contains(' content ') ||
            lower.contains(' content,') ||
            RegExp(r'select\s+\*\s+from\s+"?file"?').hasMatch(lower);
      });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _StatementLog log;
  late NooDatabase db;
  late int taskId;

  setUp(() async {
    log = _StatementLog();
    db = NooDatabase.withExecutor(NativeDatabase.memory().interceptWith(log));
    taskId = await db.createTask(worldId: 'w-task', title: 'owner');
  });
  tearDown(() => db.close());

  final large = Uint8List.fromList(List.generate(512 * 1024, (i) => i % 253));

  Future<int> attach(String worldId, Uint8List content) => db.createAttachment(
        taskId: taskId,
        worldId: worldId,
        filename: '$worldId.bin',
        content: content,
      );

  test('getAttachmentMeta returns the row without its bytes', () async {
    final id = await attach('w-a', large);
    log.statements.clear();

    final meta = (await db.getAttachmentMeta(id))!;

    expect(meta.id, id);
    expect(meta.taskId, taskId);
    expect(meta.worldId, 'w-a');
    expect(meta.filename, 'w-a.bin');
    expect(meta.orderId, 0);
    expect(meta.contentHash, NooDatabase.blobId(large));
    expect(meta.removed, 0);
    expect(log.blobReads, isEmpty);
    expect(await db.getAttachmentMeta(id + 100), isNull);
    expect(meta.timestamp, (await db.getAttachmentWithContent(id))!.timestamp);
  });

  test('rename, reorder, delete and undelete never read the BLOB', () async {
    final a = await attach('w-a', large);
    final b = await attach('w-b', large);
    log.statements.clear();

    await db.updateAttachment(a, filename: 'renamed.bin');
    await db.updateAttachment(a, orderId: 5, remoteTimestamp: '2030-01-01T00:00:00Z');
    await db.reorderAttachments(taskId, [b, a]);
    await db.deleteAttachment(a);
    await db.undeleteAttachment(a);
    // insertFileHistory resolving the worldId itself must not either.
    await db.insertFileHistory(fileId: a, field: 'filename', newValue: 'x');

    expect(log.blobReads, isEmpty,
        reason: 'metadata writes read metadata: ${log.statements}');
    expect((await db.getAttachmentWithContent(a))!.filename, 'renamed.bin');
    expect((await db.getFileHistory(a)).every((h) => h.worldId == 'w-a'), isTrue,
        reason: 'history rows still name the attachment');
  });

  test('a pending blob reference is recorded without reading the old bytes',
      () async {
    final id = await attach('w-a', large);
    log.statements.clear();

    await db.markAttachmentPendingBlob(id, 'f' * 64,
        remoteTimestamp: '2030-01-01T00:00:00Z');

    expect(log.blobReads, isEmpty);
    final history = (await db.getFileHistory(id))
        .where((h) => h.field == 'content')
        .toList();
    expect(history.last.oldValue, BlobRef(NooDatabase.blobId(large)).encode(),
        reason: 'the prior reference comes from the stored hash');
  });

  test('replacing content records the prior blob reference from the hash',
      () async {
    final id = await attach('w-a', large);
    final replacement = Uint8List.fromList([1, 2, 3]);
    log.statements.clear();

    await db.updateAttachmentContent(id, replacement);

    expect(log.blobReads, isEmpty,
        reason: 'the old bytes are not needed when their hash is stored');
    final history = (await db.getFileHistory(id))
        .where((h) => h.field == 'content')
        .toList();
    expect(history.last.oldValue, BlobRef(NooDatabase.blobId(large)).encode());
    expect(history.last.newValue, BlobRef(NooDatabase.blobId(replacement)).encode());
  });

  test('a row never hashed (pre-v11) loads its bytes once, to hash them',
      () async {
    final id = await attach('w-a', large);
    await db.customStatement(
        "UPDATE file SET content_hash = '' WHERE id = ?", [id]);
    final replacement = Uint8List.fromList([4, 5, 6]);
    log.statements.clear();

    await db.updateAttachmentContent(id, replacement);

    expect(log.blobReads, hasLength(1),
        reason: 'the fallback reads the content column, and only then');
    final history = (await db.getFileHistory(id))
        .where((h) => h.field == 'content')
        .toList();
    expect(history.last.oldValue, BlobRef(NooDatabase.blobId(large)).encode(),
        reason: 'the prior reference is still right');
    expect((await db.getAttachmentMeta(id))!.contentHash,
        NooDatabase.blobId(replacement));
  });
}
