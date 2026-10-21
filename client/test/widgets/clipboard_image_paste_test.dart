import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/attachment_uri.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/widgets/task_editor/attachment_image_ops.dart';
import 'package:noo/presentation/widgets/task_editor/clipboard_image.dart';
import 'package:noo/presentation/widgets/task_editor/quill_editor_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'editor_image_embed_test.dart' show buildPng;

/// Pasting a screenshot into task content.
///
/// flutter_quill's own image paste never fires on Windows or Linux (its native
/// bridge does not read clipboard images there), so the app reads the clipboard
/// itself. What comes back differs per platform — PNG on macOS and Linux, an
/// uncompressed BMP on Windows — and these tests pin the normalisation.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const pasteboardChannel = MethodChannel('pasteboard');

  final tempFiles = <File>[];

  /// Answer the pasteboard channel the way the host platform's plugin would:
  /// Windows returns the path of a temp file holding the bitmap, everything
  /// else returns the bytes.
  void mockClipboard({Uint8List? image, List<String> files = const []}) {
    messenger.setMockMethodCallHandler(pasteboardChannel, (call) async {
      switch (call.method) {
        case 'image':
          if (image == null) return null;
          if (Platform.isWindows) {
            final file = File(
              '${Directory.systemTemp.path}/noo_clipboard_${tempFiles.length}.bmp',
            )..writeAsBytesSync(image);
            tempFiles.add(file);
            return file.path;
          }
          return image;
        case 'files':
          return files;
        default:
          return null;
      }
    });
  }

  void mockClipboardText(String? text) {
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        return text == null ? null : <String, dynamic>{'text': text};
      }
      return null;
    });
  }

  setUp(() => mockClipboardText(null));

  tearDown(() {
    messenger.setMockMethodCallHandler(pasteboardChannel, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
    for (final file in tempFiles) {
      if (file.existsSync()) file.deleteSync();
    }
    tempFiles.clear();
  });

  test('a clipboard image comes back as PNG bytes', () async {
    final png = buildPng(8);
    mockClipboard(image: png);

    final images = await readClipboardImages();
    expect(images, hasLength(1));
    expect(images.single.bytes, png, reason: 'already PNG: pass it through');
    expect(images.single.filename, endsWith('.png'));
  });

  test('a Windows bitmap is re-encoded, not stored raw', () async {
    final bmp = buildBmp(64);
    mockClipboard(image: bmp);

    final images = await readClipboardImages();
    expect(images, hasLength(1));

    final bytes = images.single.bytes;
    expect(bytes.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
        reason: 'an 8 MB BMP screenshot must not reach the database');
    expect(bytes.length, lessThan(bmp.length));

    // The picture itself must survive the round trip.
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    expect(frame.image.width, 64);
    expect(frame.image.height, 64);
    frame.image.dispose();
  });

  test('text on the clipboard wins, so ordinary pastes still paste text',
      () async {
    // A copied selection carries both; hijacking it would be worse than the
    // reverse.
    mockClipboard(image: buildPng(8));
    mockClipboardText('some copied text');

    expect(await readClipboardImages(), isEmpty);
  });

  test('copied image files are pasted as images', () async {
    final source = File('${Directory.systemTemp.path}/noo_pasted_source.png')
      ..writeAsBytesSync(buildPng(8));
    tempFiles.add(source);

    mockClipboard(files: [source.path]);

    final images = await readClipboardImages();
    expect(images, hasLength(1));
    expect(images.single.filename, 'noo_pasted_source.png');
    expect(images.single.bytes, buildPng(8));
  });

  test('copied non-image files are left to the normal paste', () async {
    final source = File('${Directory.systemTemp.path}/noo_pasted_source.txt')
      ..writeAsStringSync('hello');
    tempFiles.add(source);

    mockClipboard(files: [source.path]);

    expect(await readClipboardImages(), isEmpty);
  });

  test('an empty clipboard yields nothing', () async {
    mockClipboard();
    expect(await readClipboardImages(), isEmpty);
  });

  test('undecodable clipboard payload is ignored rather than stored', () async {
    mockClipboard(image: Uint8List.fromList(List.filled(64, 0x7F)));
    expect(await readClipboardImages(), isEmpty);
  });

  test('the name builder names pasted screenshots', () async {
    mockClipboard(image: buildPng(8));

    final images = await readClipboardImages(
      nameBuilder: () => 'pasted image 20260804-134512.png',
    );
    expect(images.single.filename, 'pasted image 20260804-134512.png');
  });

  group('in the editor', () {
    late NooDatabase db;
    late int taskId;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = NooDatabase.memory();
      taskId = await db.createTask(worldId: 'task-world-id', title: 'Task');
    });

    tearDown(() async {
      await db.close();
    });

    Future<String?> pumpAndPaste(WidgetTester tester) async {
      String? saved;
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [FlutterQuillLocalizations.delegate],
            home: Scaffold(
              body: SizedBox(
                width: 600,
                height: 400,
                child: QuillEditorWrapper(
                  contentKey: taskId,
                  taskId: taskId,
                  onContentChanged: (content) => saved = content,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Paste goes through the focused editor, exactly as Ctrl+V does.
      await tester.tap(find.byType(QuillEditor));
      await tester.pumpAndSettle();

      // Inside runAsync: reading the clipboard and writing the attachment are
      // real async work, which the test binding's fake async never advances.
      await tester.runAsync(() async {
        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      return saved;
    }

    testWidgets('Ctrl+V stores the image and references it in the content',
        (tester) async {
      mockClipboard(image: buildPng(8));

      final saved = await pumpAndPaste(tester);

      final attachments = await db.getAttachmentsForTask(taskId);
      expect(attachments, hasLength(1),
          reason: 'the bytes belong in the attachment table');
      expect(attachments.single.filename, startsWith('pasted image '));
      expect(attachments.single.content, buildPng(8));

      expect(
        attachmentRefsInContent(saved),
        {attachments.single.worldId},
        reason: 'the content carries a reference, never the bytes',
      );
    });

    testWidgets('with text on the clipboard the paste is declined',
        (tester) async {
      // Asserted on the operation rather than through the editor: declining
      // hands the paste to Quill's own HTML path, which asks
      // quill_native_bridge for the clipboard — and that has no implementation
      // under the test binding, so the editor route can only ever fail here.
      mockClipboard();
      mockClipboardText('just text');

      final controller = QuillController.basic();
      addTearDown(controller.dispose);

      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      late WidgetRef capturedRef;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const SizedBox();
            },
          ),
        ),
      );

      final handled = await tester.runAsync(
        () => pasteImagesFromClipboard(capturedRef, controller, taskId),
      );

      expect(handled, isFalse,
          reason: 'the editor must go on to paste the text');
      expect(await db.getAttachmentsForTask(taskId), isEmpty);
      expect(controller.document.toPlainText().trim(), isEmpty);
    });
  });
}

/// Build a [size]x[size] 24-bit BMP — the shape Windows puts on the clipboard.
Uint8List buildBmp(int size) {
  // Rows are bottom-up and padded to a 4-byte boundary.
  final rowBytes = size * 3;
  final padding = (4 - rowBytes % 4) % 4;
  final pixelBytes = (rowBytes + padding) * size;
  const headerBytes = 14 + 40;

  final bytes = BytesBuilder();
  final header = ByteData(headerBytes);

  // BITMAPFILEHEADER
  header.setUint8(0, 0x42); // 'B'
  header.setUint8(1, 0x4D); // 'M'
  header.setUint32(2, headerBytes + pixelBytes, Endian.little);
  header.setUint32(10, headerBytes, Endian.little);

  // BITMAPINFOHEADER
  header.setUint32(14, 40, Endian.little);
  header.setInt32(18, size, Endian.little);
  header.setInt32(22, size, Endian.little);
  header.setUint16(26, 1, Endian.little); // planes
  header.setUint16(28, 24, Endian.little); // bits per pixel
  header.setUint32(34, pixelBytes, Endian.little);

  bytes.add(header.buffer.asUint8List());

  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      bytes..addByte(0x20)..addByte(0x40)..addByte(0x60); // BGR
    }
    bytes.add(List.filled(padding, 0));
  }

  return bytes.takeBytes();
}
