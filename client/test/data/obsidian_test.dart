import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/attachment_uri.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/obsidian_export_service.dart';
import 'package:noo/data/services/obsidian_import_service.dart';
import 'package:noo/domain/entities/world_id.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NooDatabase db;
  late Directory tempDir;

  setUp(() {
    db = NooDatabase.memory();
    tempDir = Directory.systemTemp.createTempSync('noo_obsidian_test');
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('sibling tasks with the same title export to distinct files (M1)',
      () async {
    await db.createTask(worldId: WorldId.create().value, title: 'Notes');
    await db.createTask(worldId: WorldId.create().value, title: 'Notes');

    final result = await ObsidianExportService(db).export(tempDir.path);
    expect(result.success, isTrue);
    expect(result.tasksExported, 2);

    final mdFiles = tempDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .toList();
    expect(mdFiles.length, 2,
        reason: 'both siblings must produce their own file, not overwrite');
  });

  test('embedded images are written once and linked from every note',
      () async {
    // A 1x1 PNG is enough: the export only copies bytes, it never decodes.
    final png = Uint8List.fromList(base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    ));

    final parentId = await db.createTask(
      worldId: WorldId.create().value,
      title: 'Parent',
    );
    final childId = await db.createTask(
      worldId: WorldId.create().value,
      title: 'Child',
      parentId: parentId,
    );

    final imageWorldId = WorldId.create().value;
    await db.createAttachment(
      taskId: parentId,
      worldId: imageWorldId,
      filename: 'screen shot.png',
      content: png,
    );

    // Both notes reference the same attachment; the parent twice.
    final content = jsonEncode([
      {'insert': 'see:\n'},
      {
        'insert': {'image': attachmentUri(imageWorldId)}
      },
      {
        'insert': {'image': attachmentUri(imageWorldId)}
      },
      {'insert': '\n'},
    ]);
    await db.updateTask(parentId, content: content);
    await db.updateTask(childId, content: content);

    final result = await ObsidianExportService(db).export(tempDir.path);
    expect(result.success, isTrue);
    expect(result.imagesExported, 1, reason: 'one attachment, one file');

    final images = Directory('${tempDir.path}/_images')
        .listSync()
        .whereType<File>()
        .toList();
    expect(images.length, 1);
    expect(images.single.path, endsWith('screen shot.png'));
    expect(images.single.readAsBytesSync(), png);

    // Parent note sits in Parent/, so it reaches _images/ one level up.
    final parentMd =
        File('${tempDir.path}/Parent/Parent.md').readAsStringSync();
    expect(parentMd, contains('![](../_images/screen%20shot.png)'));

    // The child is a leaf inside Parent/ — same depth, same link.
    final childMd = File('${tempDir.path}/Parent/Child.md').readAsStringSync();
    expect(childMd, contains('![](../_images/screen%20shot.png)'));
  });

  test('a deleted attachment leaves the note without a broken link', () async {
    final taskId = await db.createTask(
      worldId: WorldId.create().value,
      title: 'Task',
    );
    final imageWorldId = WorldId.create().value;
    final fileId = await db.createAttachment(
      taskId: taskId,
      worldId: imageWorldId,
      filename: 'gone.png',
      content: Uint8List.fromList([1, 2, 3]),
    );
    await db.updateTask(
      taskId,
      content: jsonEncode([
        {
          'insert': {'image': attachmentUri(imageWorldId)}
        },
        {'insert': '\n'},
      ]),
    );
    await db.deleteAttachment(fileId);

    final result = await ObsidianExportService(db).export(tempDir.path);
    expect(result.success, isTrue);
    expect(result.imagesExported, 0);
    expect(Directory('${tempDir.path}/_images').existsSync(), isFalse);
    expect(File('${tempDir.path}/Task.md').readAsStringSync(),
        isNot(contains('![]')));
  });

  test('a root task named like the vault folder survives import (M1)',
      () async {
    final vaultName = tempDir.path.split(Platform.pathSeparator).last;
    File('${tempDir.path}/$vaultName.md').writeAsStringSync('# $vaultName\n');
    File('${tempDir.path}/Other.md').writeAsStringSync('# Other\n');

    final result = await ObsidianImportService(db).import(tempDir.path);
    expect(result.success, isTrue);

    final tasks = await db.getTopLevelTasks();
    final titles = tasks.map((t) => t.title).toSet();
    expect(titles, containsAll([vaultName, 'Other']));
  });
}
