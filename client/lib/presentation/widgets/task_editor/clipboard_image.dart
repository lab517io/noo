import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';

/// Reading images off the system clipboard, normalised across platforms.

/// Extensions accepted when an image *file* is pasted (copied in a file
/// manager) rather than the image itself.
const _pastableImageExtensions = [
  '.png',
  '.jpg',
  '.jpeg',
  '.gif',
  '.bmp',
  '.webp',
];

/// An image taken from the clipboard, always PNG-encoded.
class ClipboardImage {
  final Uint8List bytes;
  final String filename;

  const ClipboardImage({required this.bytes, required this.filename});
}

/// The image(s) currently on the clipboard, or an empty list.
///
/// Returns nothing when the clipboard also holds text: a copied selection
/// carries both, and turning an ordinary text paste into an image would be
/// worse than the reverse. Copying an image on its own (a screenshot, or
/// "Copy image" in a browser) leaves no text behind, so it still lands here.
///
/// Every read of the clipboard here is guarded: the platform can refuse
/// (another process holding the clipboard open on Windows, a Wayland session
/// without a text source), and `package:pasteboard` has no implementation
/// under `flutter test` at all. A probe that fails means "no image this app
/// can use", and must not take the paste down with it — the editor's own
/// text paste runs when this returns empty.
Future<List<ClipboardImage>> readClipboardImages({
  String Function()? nameBuilder,
}) async {
  final text = await _probe('text', () => Clipboard.getData(Clipboard.kTextPlain));
  if (text?.text?.isNotEmpty ?? false) return const [];

  final bitmap = await _probe('image', () => Pasteboard.image);
  if (bitmap != null && bitmap.isNotEmpty) {
    final png = await _toPng(bitmap);
    if (png == null) return const [];
    return [
      ClipboardImage(
        bytes: png,
        filename: nameBuilder?.call() ?? 'pasted image.png',
      ),
    ];
  }

  // Nothing bitmap-shaped on the clipboard — but image *files* may have been
  // copied in a file manager, which users expect to paste as images too.
  return _readImageFiles();
}

/// Run one clipboard read, turning a throw into null.
Future<T?> _probe<T>(String what, Future<T?> Function() read) async {
  try {
    return await read();
  } catch (error) {
    if (kDebugMode) debugPrint('Clipboard $what probe failed: $error');
    return null;
  }
}

Future<List<ClipboardImage>> _readImageFiles() async {
  final paths = await _probe('files', Pasteboard.files) ?? const <String>[];
  final images = <ClipboardImage>[];

  for (final path in paths) {
    final lower = path.toLowerCase();
    if (!_pastableImageExtensions.any(lower.endsWith)) continue;

    try {
      final file = File(path);
      if (!await file.exists()) continue;

      images.add(ClipboardImage(
        bytes: await file.readAsBytes(),
        filename: path.split(RegExp(r'[/\\]')).last,
      ));
    } catch (error) {
      // A file the clipboard names but this process cannot read (gone since
      // it was copied, or on a share that is no longer mounted) is skipped,
      // not a reason to lose the rest of the paste.
      if (kDebugMode) debugPrint('Clipboard file $path unreadable: $error');
    }
  }

  return images;
}

/// Re-encode [bytes] as PNG unless they already are one.
///
/// macOS and Linux hand over PNG, but Windows hands over an uncompressed BMP —
/// a 1920x1080 screenshot is ~8 MB there, and that would be stored in the
/// database, diffed into history and pushed through sync at that size. Skia
/// does the conversion, so this costs no extra dependency.
Future<Uint8List?> _toPng(Uint8List bytes) async {
  if (_isPng(bytes)) return bytes;

  ui.Codec? codec;
  ui.Image? image;
  try {
    codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    image = frame.image;
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  } catch (_) {
    // Some clipboard payload Skia cannot decode; treat it as "no image" and
    // let the normal paste handling have its turn.
    return null;
  } finally {
    // Both are native handles: the frame is freed with the image, but the
    // codec is not, and every Windows screenshot paste comes through here.
    image?.dispose();
    codec?.dispose();
  }
}

bool _isPng(Uint8List bytes) {
  const signature = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A];
  if (bytes.length < signature.length) return false;
  for (var i = 0; i < signature.length; i++) {
    if (bytes[i] != signature[i]) return false;
  }
  return true;
}
