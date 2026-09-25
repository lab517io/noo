import 'dart:typed_data';

import '../../domain/entities/attachment.dart';
import '../../domain/entities/world_id.dart';
import '../../domain/repositories/attachment_repository.dart';
import '../database/database.dart';

/// Concrete implementation of AttachmentRepository using Drift database.
class AttachmentRepositoryImpl implements AttachmentRepository {
  final NooDatabase _database;

  AttachmentRepositoryImpl(this._database);

  /// Convert database FileEntry to domain Attachment (metadata only)
  Attachment _toAttachment(FileEntry entry, {Uint8List? content}) {
    return Attachment(
      id: entry.id,
      taskId: entry.taskId,
      worldId: WorldId.fromString(entry.worldId),
      filename: entry.filename,
      index: entry.orderId,
      content: content,
      contentLoaded: content != null,
      pendingDownload: entry.content == null && entry.contentHash.isNotEmpty,
    );
  }

  @override
  Future<List<Attachment>> getAttachmentsForTask(int taskId) async {
    final entries = await _database.getAttachmentsForTask(taskId);
    return entries.map((e) => _toAttachment(e)).toList();
  }

  @override
  Future<int> getAttachmentCount(int taskId) {
    return _database.getAttachmentCount(taskId);
  }

  @override
  Future<Attachment> loadAttachmentContent(Attachment attachment) async {
    if (attachment.id == null) {
      throw ArgumentError('Cannot load content for attachment without id');
    }

    final entry = await _database.getAttachmentWithContent(attachment.id!);
    if (entry == null) {
      throw StateError('Attachment not found: ${attachment.id}');
    }

    return attachment.copyWith(
      content: entry.content,
      contentLoaded: true,
    );
  }

  @override
  Future<Attachment?> getAttachmentByWorldId(String worldId) async {
    final entry = await _database.getAttachmentByWorldId(worldId);
    // A soft-removed attachment stays in the table so the deletion can sync;
    // to the editor it is gone, and the image renders as missing.
    if (entry == null || entry.removed != 0) return null;
    return _toAttachment(entry, content: entry.content);
  }

  @override
  Future<void> replaceAttachmentContent(
    int id,
    Uint8List content, {
    String? filename,
  }) async {
    if (filename != null) {
      await _database.updateAttachment(id, filename: filename);
    }
    await _database.updateAttachmentContent(id, content);
  }

  @override
  Future<Attachment> createAttachment({
    required int taskId,
    required String filename,
    required Uint8List content,
  }) async {
    final worldId = WorldId.create();

    // Get current max orderId for this task
    final existing = await _database.getAttachmentsForTask(taskId);
    final orderId = existing.isEmpty
        ? 0
        : existing.map((e) => e.orderId).reduce((a, b) => a > b ? a : b) + 1;

    final id = await _database.createAttachment(
      taskId: taskId,
      worldId: worldId.value,
      filename: filename,
      content: content,
      orderId: orderId,
    );

    return Attachment(
      id: id,
      taskId: taskId,
      worldId: worldId,
      filename: filename,
      index: orderId,
      content: content,
      contentLoaded: true,
    );
  }

  @override
  Future<void> updateAttachment(Attachment attachment) async {
    if (attachment.id == null) {
      throw ArgumentError('Cannot update attachment without id');
    }

    await _database.updateAttachment(
      attachment.id!,
      filename: attachment.filename,
      orderId: attachment.index,
    );

    // Only rewrite the BLOB when the bytes actually changed. Rewriting it on a
    // plain rename would store the full old+new content in history (and push a
    // needless full-content sync) for no reason.
    if (attachment.contentLoaded && attachment.content != null) {
      final existing = await _database.getAttachmentWithContent(attachment.id!);
      if (existing == null ||
          !_bytesEqual(existing.content, attachment.content)) {
        await _database.updateAttachmentContent(
          attachment.id!,
          attachment.content!,
        );
      }
    }
  }

  bool _bytesEqual(List<int>? a, List<int>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Future<void> deleteAttachment(int id) {
    return _database.deleteAttachment(id);
  }

  @override
  Future<void> undeleteAttachment(int id) {
    return _database.undeleteAttachment(id);
  }

  @override
  Future<void> reorderAttachments(int taskId, List<int> attachmentIds) {
    return _database.reorderAttachments(taskId, attachmentIds);
  }
}
