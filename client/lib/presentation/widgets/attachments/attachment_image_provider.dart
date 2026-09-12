import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';

/// Loads the raw bytes of the attachment identified by [worldId].
typedef AttachmentBytesLoader = Future<Uint8List?> Function(String worldId);

/// An [AttachmentImage] for [worldId] that reads through the repository behind
/// [ref] — the usual way to build one.
AttachmentImage attachmentImageFor(WidgetRef ref, String worldId) {
  return AttachmentImage(worldId, loader: (id) async {
    final repo = ref.read(attachmentRepositoryProvider);
    final attachment = await repo?.getAttachmentByWorldId(id);
    return attachment?.content;
  });
}

/// Cache key for [AttachmentImage]. Equality is by worldId + scale only, so the
/// loader closure (which is recreated on every editor rebuild) does not defeat
/// Flutter's image cache.
@immutable
class AttachmentImageKey {
  final String worldId;
  final double scale;

  const AttachmentImageKey(this.worldId, this.scale);

  @override
  bool operator ==(Object other) =>
      other is AttachmentImageKey &&
      other.worldId == worldId &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(worldId, scale);

  @override
  String toString() => 'AttachmentImageKey($worldId)';
}

/// An [ImageProvider] whose bytes come from an attachment BLOB in the database.
///
/// Going through the provider API rather than a `FutureBuilder` + `Image.memory`
/// buys the global image cache: an image scrolled out of view, or a task
/// revisited, is re-rendered from the decoded frame without another database
/// read. Call [evict] after the bytes behind a worldId change.
@immutable
class AttachmentImage extends ImageProvider<AttachmentImageKey> {
  final String worldId;
  final AttachmentBytesLoader loader;
  final double scale;

  const AttachmentImage(
    this.worldId, {
    required this.loader,
    this.scale = 1.0,
  });

  @override
  Future<AttachmentImageKey> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(AttachmentImageKey(worldId, scale));
  }

  @override
  ImageStreamCompleter loadImage(
    AttachmentImageKey key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _load(key, decode),
      scale: key.scale,
      debugLabel: 'noo-attachment://${key.worldId}',
      informationCollector: () => [
        ErrorDescription('attachment worldId: ${key.worldId}'),
      ],
    );
  }

  Future<ui.Codec> _load(
    AttachmentImageKey key,
    ImageDecoderCallback decode,
  ) async {
    final bytes = await loader(key.worldId);
    if (bytes == null || bytes.isEmpty) {
      // Failures are not cached by ImageCache, so a later sync that delivers
      // the bytes resolves normally on the next paint.
      throw StateError('Attachment ${key.worldId} has no content');
    }
    return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
  }

  /// Drop the cached frame for [worldId] so the next paint re-reads the BLOB.
  /// Call after replacing an attachment's content.
  ///
  /// Named apart from [ImageProvider.evict] — which needs an instance, and so
  /// a loader — because callers only have a worldId in hand.
  static void evictWorldId(String worldId, {double scale = 1.0}) {
    PaintingBinding.instance.imageCache
        .evict(AttachmentImageKey(worldId, scale));
  }

  @override
  bool operator ==(Object other) =>
      other is AttachmentImage &&
      other.worldId == worldId &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(worldId, scale);

  @override
  String toString() => 'AttachmentImage("$worldId", scale: $scale)';
}
