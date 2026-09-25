import 'dart:typed_data';

import '../entities/attachment.dart';

/// Abstract repository for attachment operations
abstract class AttachmentRepository {
  /// Get attachments for a task (metadata only)
  Future<List<Attachment>> getAttachmentsForTask(int taskId);

  /// Get attachment count for a task
  Future<int> getAttachmentCount(int taskId);

  /// Load attachment content
  Future<Attachment> loadAttachmentContent(Attachment attachment);

  /// Load an attachment, content included, by its worldId.
  ///
  /// worldId is the identity used by editor content to reference an image
  /// (see `attachment_uri.dart`) because row ids are device-local. Returns null
  /// when no such attachment exists or it has been deleted.
  Future<Attachment?> getAttachmentByWorldId(String worldId);

  /// Replace the bytes of an existing attachment, keeping its worldId — so
  /// every reference to it in task content follows the new content.
  Future<void> replaceAttachmentContent(
    int id,
    Uint8List content, {
    String? filename,
  });

  /// Create a new attachment
  Future<Attachment> createAttachment({
    required int taskId,
    required String filename,
    required Uint8List content,
  });

  /// Update attachment metadata
  Future<void> updateAttachment(Attachment attachment);

  /// Delete an attachment
  Future<void> deleteAttachment(int id);

  /// Undelete a previously deleted attachment
  Future<void> undeleteAttachment(int id);

  /// Reorder attachments for a task
  Future<void> reorderAttachments(int taskId, List<int> attachmentIds);
}
