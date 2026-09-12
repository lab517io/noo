import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/attachment_uri.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/widgets/attachments/attachment_image_provider.dart';
import 'package:noo/presentation/widgets/task_editor/attachment_image_ops.dart';
import 'package:noo/presentation/widgets/task_editor/quill_editor_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Images in task content are references — the bytes stay in the attachment
/// table so they sync and so `tasks.content` stays diff-sized. These tests
/// cover the two halves of that: the editor resolves a reference back to the
/// stored BLOB, and edits to the image are written into the Delta.
/// Build a valid [size]x[size] 8-bit greyscale PNG.
///
/// Generated rather than pasted so the bytes are certainly decodable — the
/// widgets under test lay out from the decoded image, so a broken fixture
/// silently produces zero-height images and untappable menus.
Uint8List buildPng(int size) {
  int crc32(List<int> bytes) {
    var crc = 0xFFFFFFFF;
    for (final byte in bytes) {
      crc ^= byte;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
      }
    }
    return crc ^ 0xFFFFFFFF;
  }

  Uint8List be32(int value) {
    final data = ByteData(4)..setUint32(0, value);
    return data.buffer.asUint8List();
  }

  List<int> chunk(String type, List<int> payload) {
    final typeBytes = ascii.encode(type);
    return [
      ...be32(payload.length),
      ...typeBytes,
      ...payload,
      ...be32(crc32([...typeBytes, ...payload])),
    ];
  }

  final ihdr = [
    ...be32(size), ...be32(size),
    8, // bit depth
    0, // colour type: greyscale
    0, 0, 0, // compression, filter, interlace
  ];

  final raw = <int>[];
  for (var y = 0; y < size; y++) {
    raw..add(0) // filter type: none
      ..addAll(List.filled(size, 0x40));
  }

  return Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
    ...chunk('IHDR', ihdr),
    ...chunk('IDAT', ZLibEncoder().convert(raw)),
    ...chunk('IEND', const []),
  ]);
}

void main() {
  final png = buildPng(8);

  late NooDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = NooDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedTask() {
    return db.createTask(worldId: WorldId.create().value, title: 'Task');
  }

  /// The seed PNG is small, so anything that needs to be clicked gets an
  /// explicit size — stored the way the app stores it, as a style declaration.
  String contentWithImage(String worldId, {String? width}) {
    return jsonEncode([
      {
        'insert': {'image': attachmentUri(worldId)},
        if (width != null) 'attributes': {'style': 'width: $width'},
      },
      {'insert': '\n'},
    ]);
  }

  Future<void> pumpEditor(
    WidgetTester tester, {
    required int taskId,
    required String content,
    ValueChanged<String>? onContentChanged,
  }) async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          // The toolbar's built-in buttons read their tooltips from here.
          localizationsDelegates: const [FlutterQuillLocalizations.delegate],
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: QuillEditorWrapper(
                initialContent: content,
                contentKey: taskId,
                taskId: taskId,
                onContentChanged: onContentChanged,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Decode the images on screen for real.
  ///
  /// The test binding runs with fake async, so an image never finishes loading
  /// under `pumpAndSettle` alone — it lays out zero-height, which makes it
  /// untappable. Precaching inside [WidgetTester.runAsync] performs the actual
  /// database read and decode, after which layout matches the running app.
  Future<void> decodeImages(WidgetTester tester) async {
    for (final element in find.byType(Image).evaluate()) {
      final image = element.widget as Image;
      await tester.runAsync(() => precacheImage(image.image, element));
    }
    await tester.pumpAndSettle();
  }

  testWidgets('an image reference renders from the attachment BLOB',
      (tester) async {
    final taskId = await seedTask();
    final imageWorldId = WorldId.create().value;
    await db.createAttachment(
      taskId: taskId,
      worldId: imageWorldId,
      filename: 'shot.png',
      content: png,
    );

    await pumpEditor(
      tester,
      taskId: taskId,
      content: contentWithImage(imageWorldId),
    );

    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image;
    expect(provider, isA<AttachmentImage>());
    expect((provider as AttachmentImage).worldId, imageWorldId);

    // The provider must actually reach the database, not just be constructed
    // with the right key — decoding needs real async, hence runAsync.
    final bytes = await tester.runAsync(() => provider.loader(imageWorldId));
    expect(bytes, png);
  });

  testWidgets('a reference with no attachment behind it degrades to a notice',
      (tester) async {
    final taskId = await seedTask();

    await pumpEditor(
      tester,
      taskId: taskId,
      // Nothing was ever stored under this worldId — the state a device is in
      // when the text has synced but the bytes have not.
      content: contentWithImage(WorldId.create().value),
    );
    await tester.pump();

    expect(find.text('Image not available'), findsOneWidget);
  });

  testWidgets('resizing writes a width into the stored Delta, and clears it',
      (tester) async {
    final taskId = await seedTask();
    final imageWorldId = WorldId.create().value;
    await db.createAttachment(
      taskId: taskId,
      worldId: imageWorldId,
      filename: 'shot.png',
      content: png,
    );

    String? saved;
    await pumpEditor(
      tester,
      taskId: taskId,
      content: contentWithImage(imageWorldId, width: '200px'),
      onContentChanged: (content) => saved = content,
    );
    await decodeImages(tester);

    Future<void> openMenu() async {
      await tester.tap(find.byType(Image));
      await tester.pumpAndSettle();
    }

    await openMenu();
    await tester.tap(find.text('Resize...'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, '240');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    var ops = jsonDecode(saved!) as List<dynamic>;
    var imageOp = ops.firstWhere((op) => op['insert'] is Map) as Map;
    expect(imageOp['attributes']?['style'], contains('width: 240px'),
        reason: 'the size belongs in the document, not in the image bytes');
    expect((imageOp['insert'] as Map)['image'], attachmentUri(imageWorldId),
        reason: 'resizing must not disturb the reference');

    // "Original size" takes the override back out again.
    await openMenu();
    await tester.tap(find.text('Resize...'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Original size'));
    await tester.pumpAndSettle();

    ops = jsonDecode(saved!) as List<dynamic>;
    imageOp = ops.firstWhere((op) => op['insert'] is Map) as Map;
    expect(imageOp['attributes']?['style'], isNull);
  });

  test('inserting puts the reference at the caret, over any selection', () {
    final controller = QuillController.basic();
    addTearDown(controller.dispose);

    controller.document.insert(0, 'ab');
    controller.updateSelection(
      const TextSelection(baseOffset: 1, extentOffset: 2),
      ChangeSource.local,
    );

    insertImageEmbed(controller, attachmentUri('w-1'));

    final ops = controller.document.toDelta().toJson();
    expect(ops.first['insert'], 'a', reason: 'text before the caret survives');
    expect(ops[1]['insert'], {'image': attachmentUri('w-1')});
    expect(controller.selection.baseOffset, 2,
        reason: 'the caret lands after the image, ready to keep typing');
  });

  testWidgets('deleting one copy of a shared image keeps the attachment',
      (tester) async {
    final taskId = await seedTask();
    final imageWorldId = WorldId.create().value;
    await db.createAttachment(
      taskId: taskId,
      worldId: imageWorldId,
      filename: 'shared.png',
      content: png,
    );

    // The same image twice — what a copy/paste of the embed produces.
    String? saved;
    await pumpEditor(
      tester,
      taskId: taskId,
      content: jsonEncode([
        {
          'insert': {'image': attachmentUri(imageWorldId)},
          'attributes': {'style': 'width: 200px'},
        },
        {'insert': '\n'},
        {
          'insert': {'image': attachmentUri(imageWorldId)},
          'attributes': {'style': 'width: 200px'},
        },
        {'insert': '\n'},
      ]),
      onContentChanged: (content) => saved = content,
    );
    await decodeImages(tester);

    await tester.tap(find.byType(Image).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete image'));
    await tester.pumpAndSettle();

    expect(imageSourcesInContent(saved).length, 1,
        reason: 'only the clicked copy leaves the text');
    final attachment = await db.getAttachmentByWorldId(imageWorldId);
    expect(attachment?.removed, 0,
        reason: 'the surviving copy would otherwise render as broken');
  });

  testWidgets('removing from text keeps the attachment, deleting drops it',
      (tester) async {
    final taskId = await seedTask();
    final keptWorldId = WorldId.create().value;
    final deletedWorldId = WorldId.create().value;
    await db.createAttachment(
      taskId: taskId,
      worldId: keptWorldId,
      filename: 'kept.png',
      content: png,
    );
    await db.createAttachment(
      taskId: taskId,
      worldId: deletedWorldId,
      filename: 'dropped.png',
      content: png,
    );

    String? saved;
    await pumpEditor(
      tester,
      taskId: taskId,
      content: jsonEncode([
        {
          'insert': {'image': attachmentUri(keptWorldId)},
          'attributes': {'style': 'width: 200px'},
        },
        {'insert': '\n'},
        {
          'insert': {'image': attachmentUri(deletedWorldId)},
          'attributes': {'style': 'width: 200px'},
        },
        {'insert': '\n'},
      ]),
      onContentChanged: (content) => saved = content,
    );
    await decodeImages(tester);

    expect(find.byType(Image), findsNWidgets(2));

    // First image: remove from text only.
    await tester.tap(find.byType(Image).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from text'));
    await tester.pumpAndSettle();

    expect(attachmentRefsInContent(saved), {deletedWorldId});
    expect(await db.getAttachmentByWorldId(keptWorldId), isNotNull,
        reason: 'the file stays listed in the attachments panel');

    // Remaining image: delete outright.
    await tester.tap(find.byType(Image));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete image'));
    await tester.pumpAndSettle();

    expect(attachmentRefsInContent(saved), isEmpty);
    final deleted = await db.getAttachmentByWorldId(deletedWorldId);
    expect(deleted?.removed, 1, reason: 'soft-deleted so the delete syncs');
  });
}
