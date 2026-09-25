import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'world_id.dart';

/// File attachment metadata and content.
/// Equivalent to Qt's Attachment class.
class Attachment extends Equatable {
  final int? id;
  final int taskId;
  final WorldId worldId;
  final String filename;
  final int index;

  /// Content is loaded separately (lazy loading)
  final Uint8List? content;
  final bool contentLoaded;

  /// The attachment arrived by sync as a reference and its bytes have not
  /// been fetched yet (docs/P2P_SYNC.md §3.5). Nothing is wrong with it — the
  /// next sync with any node that has the bytes fills it in.
  final bool pendingDownload;

  const Attachment({
    this.id,
    required this.taskId,
    required this.worldId,
    required this.filename,
    this.index = 0,
    this.content,
    this.contentLoaded = false,
    this.pendingDownload = false,
  });

  /// Create a new attachment
  factory Attachment.create({
    required int taskId,
    required String filename,
    Uint8List? content,
    int index = 0,
  }) {
    return Attachment(
      taskId: taskId,
      worldId: WorldId.create(),
      filename: filename,
      index: index,
      content: content,
      contentLoaded: content != null,
    );
  }

  /// Get file extension (lowercase)
  String get extension {
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == filename.length - 1) {
      return '';
    }
    return filename.substring(dotIndex + 1).toLowerCase();
  }

  /// Get file size in bytes (0 if content not loaded)
  int get size => content?.length ?? 0;

  /// Check if this is an image attachment
  bool get isImage {
    const imageExtensions = ['png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp'];
    return imageExtensions.contains(extension);
  }

  /// Check if this is an audio attachment the app can play in place.
  ///
  /// Actual decoding is the platform's job (Media Foundation on Windows,
  /// GStreamer on Linux, AVFoundation on macOS), so this list is what those
  /// three agree on rather than everything each can open.
  bool get isAudio {
    const audioExtensions = [
      'mp3',
      'm4a',
      'aac',
      'wav',
      'ogg',
      'oga',
      'opus',
      'flac',
    ];
    return audioExtensions.contains(extension);
  }

  /// Check if this is a document attachment
  bool get isDocument {
    const docExtensions = ['pdf', 'doc', 'docx', 'txt', 'rtf', 'odt'];
    return docExtensions.contains(extension);
  }

  Attachment copyWith({
    int? id,
    int? taskId,
    WorldId? worldId,
    String? filename,
    int? index,
    Uint8List? content,
    bool? contentLoaded,
  }) {
    return Attachment(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      worldId: worldId ?? this.worldId,
      filename: filename ?? this.filename,
      index: index ?? this.index,
      content: content ?? this.content,
      contentLoaded: contentLoaded ?? this.contentLoaded,
    );
  }

  @override
  List<Object?> get props => [id, taskId, worldId, filename, index];

  @override
  String toString() {
    return 'Attachment(id: $id, filename: $filename, size: $size)';
  }
}
