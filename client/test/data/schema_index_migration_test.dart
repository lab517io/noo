import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';

/// The v7 migration adds the indexes the schema never had. It has to land on
/// databases created before v7, and — like the column migrations before it —
/// survive a database whose schema is already ahead of its recorded
/// `user_version` (the Syncthing-merge case).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late String path;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('noo-schema');
    path = '${dir.path}/schema.noo';
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<Set<String>> indexesIn(NooDatabase db) async {
    final rows = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name LIKE 'idx_%'",
        )
        .get();
    return rows.map((r) => r.read<String>('name')).toSet();
  }

  /// Every index the current schema declares.
  Set<String> declaredIn(NooDatabase db) =>
      db.allSchemaEntities.whereType<Index>().map((i) => i.entityName).toSet();

  test('a freshly created database has every declared index', () async {
    final db = NooDatabase.fromPath(path);
    addTearDown(db.close);

    final declared = declaredIn(db);
    expect(declared, isNotEmpty);
    expect(await indexesIn(db), declared);
  });

  test('a pre-v7 database gains the indexes on open', () async {
    // Build a current database, then rewind it to look like v6: drop the
    // indexes and put the version counter back.
    final seed = NooDatabase.fromPath(path);
    final declared = declaredIn(seed);
    await seed.createTask(worldId: 'w-1', title: 'Before the migration');
    for (final name in declared) {
      await seed.customStatement('DROP INDEX $name');
    }
    await seed.customStatement('PRAGMA user_version = 6');
    await seed.close();

    final upgraded = NooDatabase.fromPath(path);
    addTearDown(upgraded.close);

    expect(await indexesIn(upgraded), declared);
    // Additive only: the row is untouched.
    expect((await upgraded.getTaskByWorldId('w-1'))?.title,
        'Before the migration');
  });

  test('a database whose indexes already exist migrates without throwing',
      () async {
    // Schema ahead of user_version: indexes present, counter still at 6.
    final seed = NooDatabase.fromPath(path);
    final declared = declaredIn(seed);
    await seed.customStatement('PRAGMA user_version = 6');
    await seed.close();

    final reopened = NooDatabase.fromPath(path);
    addTearDown(reopened.close);

    expect(await indexesIn(reopened), declared);
  });

  test('the LWW lookup uses its index rather than scanning', () async {
    final db = NooDatabase.fromPath(path);
    addTearDown(db.close);

    final id = await db.createTask(worldId: 'w-1', title: 'Indexed');
    await db.updateTask(id, title: 'Indexed twice');

    final plan = await db
        .customSelect(
          'EXPLAIN QUERY PLAN SELECT * FROM history_task '
          "WHERE task_id = ? AND field = 'title' "
          'ORDER BY timestamp DESC, id DESC LIMIT 1',
          variables: [Variable.withInt(id)],
        )
        .get();
    final detail = plan.map((r) => r.read<String>('detail')).join(' | ');

    expect(detail, contains('idx_history_task_lookup'));
    expect(detail, isNot(contains('SCAN history_task')));
  });

  test('a v11 database upgrades all the way in one open', () async {
    // The jump a user actually makes: an installed build stamped at v11,
    // opened by one that is at 13. Both migrations have to land, and the data
    // that was there has to survive them.
    final content = Uint8List.fromList(List.filled(4096, 3));
    final seed = NooDatabase.fromPath(path);
    final taskId = await seed.createTask(worldId: 'w-t', title: 'owner');
    final fileId = await seed.createAttachment(
      taskId: taskId,
      worldId: 'w-f',
      filename: 'a.bin',
      content: content,
    );
    // As a pre-v12 build wrote the content row.
    await seed.customStatement(
        "UPDATE history_file SET new_value = ? WHERE field = 'content'",
        [base64.encode(content)]);
    await seed.customStatement('PRAGMA user_version = 11');
    await seed.close();

    final db = NooDatabase.fromPath(path);
    addTearDown(db.close);

    final version = (await db
            .customSelect('PRAGMA user_version')
            .getSingle())
        .read<int>('user_version');
    expect(version, 13);

    // v12: the inlined attachment became a reference.
    final history = (await db.getAllFileHistory())
        .where((h) => h.field == 'content')
        .single;
    expect(history.newValue, 'blob:${NooDatabase.blobId(content)}');

    // v13: the partial-fetch table exists and works.
    await db.saveBlobFetch('a' * 64, Uint8List.fromList([1, 2, 3]), 9);
    expect((await db.getBlobFetch('a' * 64))!.total, 9);

    // And the attachment itself is untouched.
    expect((await db.getAttachmentWithContent(fileId))!.content, content);
  });
}
