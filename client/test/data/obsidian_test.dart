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

  test('block formats and inline marks export as Markdown (DEEPSEEK M12)',
      () async {
    final content = jsonEncode([
      {'insert': 'Title'},
      {
        'insert': '\n',
        'attributes': {'header': 2}
      },
      {'insert': 'first'},
      {
        'insert': '\n',
        'attributes': {'list': 'bullet'}
      },
      {'insert': 'second, '},
      {
        'insert': 'bold',
        'attributes': {'bold': true}
      },
      {
        'insert': '\n',
        'attributes': {'list': 'bullet', 'indent': 1}
      },
      {'insert': 'step'},
      {
        'insert': '\n',
        'attributes': {'list': 'ordered'}
      },
      {'insert': 'quoted'},
      {
        'insert': '\n',
        'attributes': {'blockquote': true}
      },
      // Each code line carries the block attribute on its own newline, as
      // Quill stores it; a plain newline inside a text run ends a plain line.
      {'insert': 'x = 1'},
      {
        'insert': '\n',
        'attributes': {'code-block': true}
      },
      {'insert': 'y = **2**'},
      {
        'insert': '\n',
        'attributes': {'code-block': true}
      },
      {'insert': 'see '},
      {
        'insert': 'the site',
        'attributes': {'link': 'https://example.com'}
      },
      {'insert': '\n'},
    ]);
    await db.createTask(
      worldId: WorldId.create().value,
      title: 'Formatted',
      content: content,
    );

    final result = await ObsidianExportService(db).export(tempDir.path);
    expect(result.success, isTrue);

    final md = File('${tempDir.path}/Formatted.md').readAsStringSync();
    final lines = md.split('\n');
    expect(lines, containsAllInOrder([
      '# Formatted',
      '## Title',
      '- first',
      '    - second, **bold**',
      '1. step',
      '> quoted',
      '```',
      'x = 1',
      'y = **2**',
      '```',
      'see [the site](https://example.com)',
    ]));
  });

  test('re-importing an exported vault does not add an _images task '
      '(DEEPSEEK M12)', () async {
    final png = Uint8List.fromList(base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    ));
    final taskId = await db.createTask(
      worldId: WorldId.create().value,
      title: 'Note',
    );
    final imageWorldId = WorldId.create().value;
    await db.createAttachment(
      taskId: taskId,
      worldId: imageWorldId,
      filename: 'shot.png',
      content: png,
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
    // Obsidian's own settings folder is hidden and not a task either.
    Directory('${tempDir.path}/.obsidian').createSync();
    File('${tempDir.path}/.obsidian/app.json').writeAsStringSync('{}');

    expect((await ObsidianExportService(db).export(tempDir.path)).success,
        isTrue);
    expect(Directory('${tempDir.path}/_images').existsSync(), isTrue);

    final target = NooDatabase.memory();
    addTearDown(target.close);
    final imported = await ObsidianImportService(target).import(tempDir.path);
    expect(imported.success, isTrue);
    expect(imported.tasksImported, 1);
    final titles = (await target.getTopLevelTasks()).map((t) => t.title);
    expect(titles, ['Note']);
  });

  test('a task titled _images does not export into the images folder',
      () async {
    final id = await db.createTask(
      worldId: WorldId.create().value,
      title: '_images',
    );
    await db.createTask(
      worldId: WorldId.create().value,
      title: 'child',
      parentId: id,
    );
    expect((await ObsidianExportService(db).export(tempDir.path)).success,
        isTrue);
    expect(Directory('${tempDir.path}/_images (2)').existsSync(), isTrue);
  });

  test('Windows device names are suffixed on export (DEEPSEEK M13)',
      () async {
    final com = await db.createTask(
      worldId: WorldId.create().value,
      title: 'COM1',
    );
    await db.createTask(
      worldId: WorldId.create().value,
      title: 'nul',
      parentId: com,
    );
    await db.createTask(
      worldId: WorldId.create().value,
      title: 'Con.log',
    );
    await db.createTask(
      worldId: WorldId.create().value,
      title: 'Console',
    );

    final result = await ObsidianExportService(db).export(tempDir.path);
    expect(result.success, isTrue, reason: result.error);
    expect(result.tasksExported, 4);

    expect(Directory('${tempDir.path}/COM1_').existsSync(), isTrue);
    expect(File('${tempDir.path}/COM1_/COM1_.md').existsSync(), isTrue);
    expect(File('${tempDir.path}/COM1_/nul_.md').existsSync(), isTrue);
    expect(File('${tempDir.path}/Con_.log.md').existsSync(), isTrue);
    // Only the exact device names, not everything starting with one.
    expect(File('${tempDir.path}/Console.md').existsSync(), isTrue);

    // The note inside still carries the real title.
    expect(File('${tempDir.path}/COM1_/nul_.md').readAsStringSync(),
        startsWith('# nul\n'));
  });

  test("a folder note beside its folder is the folder task's note "
      '(DEEPSEEK M12)', () async {
    // Obsidian's folder-note layout: Meeting.md beside Meeting/, no
    // Meeting/Meeting.md inside. The folder task takes the sibling's text.
    Directory('${tempDir.path}/Meeting').createSync();
    File('${tempDir.path}/Meeting.md')
        .writeAsStringSync('# Meeting\n\nagenda\n');
    File('${tempDir.path}/Meeting/Notes.md')
        .writeAsStringSync('# Notes\n\nminutes\n');

    final result = await ObsidianImportService(db).import(tempDir.path);
    expect(result.success, isTrue, reason: result.error);
    expect(result.tasksImported, 2);

    final top = await db.getTopLevelTasks();
    expect(top.map((t) => t.title), ['Meeting']);
    expect(top.single.content, contains('agenda'));
    final children = await db.getChildTasks(top.single.id);
    expect(children.map((t) => t.title), ['Notes']);
  });

  test('a sibling note is kept as a leaf when the folder has its own note',
      () async {
    Directory('${tempDir.path}/Meeting').createSync();
    // No heading: the title falls back to the file name, which on Windows
    // used to come out as `Meeting/Meeting` from the mixed-separator path.
    File('${tempDir.path}/Meeting/Meeting.md').writeAsStringSync('inside\n');
    File('${tempDir.path}/Meeting.md')
        .writeAsStringSync('# Meeting notes\n\nbeside\n');

    final result = await ObsidianImportService(db).import(tempDir.path);
    expect(result.success, isTrue, reason: result.error);
    expect(result.tasksImported, 2);

    final top = await db.getTopLevelTasks();
    expect(top.map((t) => t.title).toSet(), {'Meeting', 'Meeting notes'});
    final folder = top.singleWhere((t) => t.title == 'Meeting');
    expect(folder.content, contains('inside'));
  });
}
