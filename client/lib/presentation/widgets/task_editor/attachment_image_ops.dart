import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/attachment_uri.dart';
import '../../../core/utils/save_dialog.dart';
import '../../providers/providers.dart';
import '../attachments/attachment_actions.dart';
import '../attachments/attachment_image_provider.dart';
import 'clipboard_image.dart';

/// Insert / replace / remove operations for images embedded in task content.
///
/// Every image is a row in the `file` table — the same store the attachments
/// panel lists — and the document only holds `noo-attachment://<worldId>`.
/// See `attachment_uri.dart` for why.

/// Extensions the file picker offers and that we accept on drop-in.
const _imageExtensions = ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'];

/// Prompt for image files, store each as an attachment of [taskId], and insert
/// them at the caret.
Future<void> insertImagesFromPicker(
  WidgetRef ref,
  QuillController controller,
  int taskId,
) async {
  final result = await FilePicker.pickFiles(
    dialogTitle: 'Insert image',
    type: FileType.custom,
    allowedExtensions: _imageExtensions,
  );
  if (result.isEmpty) return;

  for (final picked in result) {
    final path = picked.path;
    if (path == null) continue;

    final bytes = await File(path).readAsBytes();
    final source = await storeImageAsAttachment(
      ref,
      taskId: taskId,
      filename: picked.name,
      bytes: bytes,
    );
    if (source == null) continue;

    insertImageEmbed(controller, source);
  }

  refreshAttachments(ref, taskId);
}

/// Insert whatever image is on the clipboard at the caret, storing it as an
/// attachment of [taskId].
///
/// Returns true when the paste was handled here, which is what
/// [QuillClipboardConfig.onClipboardPaste] expects — returning false lets the
/// editor's own text/HTML paste run as usual.
///
/// This exists because flutter_quill's built-in image paste never fires on
/// Windows or Linux: it asks quill_native_bridge for the clipboard image, and
/// those platforms do not implement it.
Future<bool> pasteImagesFromClipboard(
  WidgetRef ref,
  QuillController controller,
  int taskId,
) async {
  final images = await readClipboardImages(
    // Pasted screenshots have no name of their own; a stable-but-unique one
    // keeps the attachments list readable.
    nameBuilder: () => 'pasted image ${_pastedImageStamp()}.png',
  );
  if (images.isEmpty) return false;

  var inserted = false;
  for (final image in images) {
    final source = await storeImageAsAttachment(
      ref,
      taskId: taskId,
      filename: image.filename,
      bytes: image.bytes,
    );
    if (source == null) continue;

    insertImageEmbed(controller, source);
    inserted = true;
  }

  if (inserted) refreshAttachments(ref, taskId);
  return inserted;
}

/// `20260804-134512`, local time — sorts naturally and reads as a timestamp.
String _pastedImageStamp() {
  final now = DateTime.now();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${now.year}${two(now.month)}${two(now.day)}'
      '-${two(now.hour)}${two(now.minute)}${two(now.second)}';
}

/// Store [bytes] as a new attachment of [taskId] and return the content
/// reference for it, or null when the database is not available.
Future<String?> storeImageAsAttachment(
  WidgetRef ref, {
  required int taskId,
  required String filename,
  required Uint8List bytes,
}) async {
  final repo = ref.read(attachmentRepositoryProvider);
  if (repo == null) return null;

  final attachment = await repo.createAttachment(
    taskId: taskId,
    filename: filename,
    content: bytes,
  );
  return attachmentUri(attachment.worldId.value);
}

/// Insert an image embed for [source] at the caret, replacing any selection.
void insertImageEmbed(QuillController controller, String source) {
  final index = controller.selection.baseOffset;
  final length = controller.selection.extentOffset - index;
  controller.replaceText(
    index,
    length,
    BlockEmbed.image(source),
    TextSelection.collapsed(offset: index + 1),
  );
}

/// Pick a new file and overwrite the bytes of the attachment behind [node],
/// keeping its worldId — so other references to the same image, on this device
/// and on every synced one, follow the replacement.
///
/// Falls back to inserting a fresh attachment when [node] does not point at one
/// (a pasted http image, or content imported from HTML).
Future<void> replaceImage(
  WidgetRef ref,
  QuillController controller,
  Embed node,
  int taskId,
) async {
  final result = await FilePicker.pickFile(
    dialogTitle: 'Replace image',
    type: FileType.custom,
    allowedExtensions: _imageExtensions,
  );
  final path = result?.path;
  if (path == null) return;

  final bytes = await File(path).readAsBytes();
  final filename = p.basename(path);
  final worldId = attachmentWorldIdOf(imageSourceOf(node));

  if (worldId == null) {
    // Not attachment-backed: swap the embed for a freshly stored attachment.
    final source = await storeImageAsAttachment(
      ref,
      taskId: taskId,
      filename: filename,
      bytes: bytes,
    );
    if (source == null) return;
    final offset = node.documentOffset;
    controller.replaceText(
      offset,
      1,
      BlockEmbed.image(source),
      TextSelection.collapsed(offset: offset + 1),
    );
    refreshAttachments(ref, taskId);
    return;
  }

  final repo = ref.read(attachmentRepositoryProvider);
  if (repo == null) return;

  final attachment = await repo.getAttachmentByWorldId(worldId);
  if (attachment?.id == null) return;

  await repo.replaceAttachmentContent(
    attachment!.id!,
    bytes,
    filename: filename,
  );
  AttachmentImage.evictWorldId(worldId);
  refreshAttachments(ref, taskId);
}

/// Remove the embed from the document. The attachment row is left alone — it
/// stays listed in the attachments panel, and an undo brings the image back.
void removeImageEmbed(QuillController controller, Embed node) {
  final offset = node.documentOffset;
  controller.replaceText(
    offset,
    1,
    '',
    TextSelection.collapsed(offset: offset),
  );
}

/// Remove the embed *and* delete the attachment behind it.
///
/// The attachment is kept when the document still shows the same image
/// somewhere else (a copy/paste of the embed) — deleting it there would leave
/// the remaining copies broken.
Future<void> deleteImage(
  WidgetRef ref,
  QuillController controller,
  Embed node,
  int taskId,
) async {
  final source = imageSourceOf(node);
  final worldId = attachmentWorldIdOf(source);
  removeImageEmbed(controller, node);

  if (worldId == null) return;
  if (countImageRefs(controller.document, source!) > 0) return;

  final repo = ref.read(attachmentRepositoryProvider);
  if (repo == null) return;

  final attachment = await repo.getAttachmentByWorldId(worldId);
  if (attachment?.id == null) return;

  await repo.deleteAttachment(attachment!.id!);
  refreshAttachments(ref, taskId);
}

/// Write the image behind [node] to a file the user picks.
Future<void> saveImageAs(
  BuildContext context,
  WidgetRef ref,
  Embed node,
) async {
  final worldId = attachmentWorldIdOf(imageSourceOf(node));
  if (worldId == null) return;

  final repo = ref.read(attachmentRepositoryProvider);
  if (repo == null) return;

  final attachment = await repo.getAttachmentByWorldId(worldId);
  final bytes = attachment?.content;
  if (bytes == null) return;

  // file_picker performs the write itself.
  final saved = await FilePicker.saveFile(
    dialogTitle: 'Save image',
    fileName: attachment!.filename,
    bytes: Uint8List.fromList(bytes),
  );
  if (saved == null) return;

  if (context.mounted) {
    final shown = savedFilePath(saved) ?? attachment.filename;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved: ${p.basename(shown)}')),
    );
  }
}

/// Apply a display width to the image, in logical pixels. Passing null clears
/// the override and restores the image's natural size.
///
/// The size goes into the embed's `style` attribute rather than a `width` one:
/// `ResolveImageFormatRule` — the only rule flutter_quill has for formatting an
/// embed — matches on `style` alone, and throws for anything else. Other
/// declarations already on the embed are preserved.
void setImageWidth(QuillController controller, Embed node, double? width) {
  final declarations = _cssDeclarations(
    node.style.attributes[Attribute.style.key]?.value?.toString(),
  );

  if (width == null) {
    declarations.remove('width');
  } else {
    declarations['width'] = '${width.round()}px';
  }

  final style = declarations.entries
      .map((e) => '${e.key}: ${e.value}')
      .join('; ');

  controller.formatText(
    node.documentOffset,
    1,
    StyleAttribute(style.isEmpty ? null : style),
  );
}

/// The image source string of an embed node (`{"image": "<source>"}`).
String? imageSourceOf(Embed node) {
  final data = node.value.data;
  return data is String ? data : null;
}

/// The display width stored on [node], if any.
///
/// Reads the `style` declaration this app writes, falling back to a bare
/// `width` attribute — that is what content converted from HTML carries.
double? imageWidthOf(Embed node) {
  final attributes = node.style.attributes;
  final fromStyle = _cssDeclarations(
    attributes[Attribute.style.key]?.value?.toString(),
  )['width'];
  final raw = fromStyle ?? attributes[Attribute.width.key]?.value?.toString();
  if (raw == null) return null;

  // Tolerate units: "200", "200px", "200 px".
  final number = RegExp(r'-?\d+(\.\d+)?').firstMatch(raw);
  return number == null ? null : double.tryParse(number.group(0)!);
}

/// Split a CSS declaration string ("width: 200px; margin: 4") into a map.
/// Order is preserved so rewriting a style keeps the rest of it recognizable.
Map<String, String> _cssDeclarations(String? style) {
  final declarations = <String, String>{};
  if (style == null) return declarations;

  for (final part in style.split(';')) {
    final colon = part.indexOf(':');
    if (colon <= 0) continue;
    final key = part.substring(0, colon).trim().toLowerCase();
    final value = part.substring(colon + 1).trim();
    if (key.isNotEmpty && value.isNotEmpty) declarations[key] = value;
  }
  return declarations;
}

/// How many image embeds in [document] point at [source].
int countImageRefs(Document document, String source) {
  var count = 0;
  for (final op in document.toDelta().toList()) {
    final data = op.data;
    if (data is Map && data['image'] == source) count++;
  }
  return count;
}
