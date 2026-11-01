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

/// Cache key for [AttachmentImage]. Equality is by worldId + scale + revision,
/// never by the loader closure (which is recreated on every editor rebuild and
/// would otherwise defeat Flutter's image cache).
@immutable
class AttachmentImageKey {
  final String worldId;
  final double scale;

  /// Bumped by [AttachmentImage.evictWorldId] — see there.
  final int revision;

  const AttachmentImageKey(this.worldId, this.scale, [this.revision = 0]);

  @override
  bool operator ==(Object other) =>
      other is AttachmentImageKey &&
      other.worldId == worldId &&
      other.scale == scale &&
      other.revision == revision;

  @override
  int get hashCode => Object.hash(worldId, scale, revision);

  @override
  String toString() => 'AttachmentImageKey($worldId, r$revision)';
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

  /// Which bytes this provider stands for: the worldId's revision at the time
  /// it was built. [evictWorldId] moves the revision on, so a provider built
  /// after a replace is *not equal* to one built before it — which is the only
  /// thing that makes a mounted [Image] re-resolve. Evicting the cache entry
  /// alone does not: `Image` re-resolves on `didUpdateWidget` only when the
  /// provider changed, and the worldId is deliberately the same across a
  /// replace so every reference follows.
  final int revision;

  AttachmentImage(
    this.worldId, {
    required this.loader,
    this.scale = 1.0,
  }) : revision = revisionOf(worldId);

  /// Per-worldId revision counters, bumped by [evictWorldId]. Process-wide,
  /// like the image cache the keys index into.
  static final Map<String, int> _revisions = {};

  /// The current revision of [worldId]'s bytes, as far as this process knows.
  static int revisionOf(String worldId) => _revisions[worldId] ?? 0;

  @override
  Future<AttachmentImageKey> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(AttachmentImageKey(worldId, scale, revision));
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

  /// Drop the cached frame for [worldId] so the next paint re-reads the BLOB,
  /// and move its revision on so that providers built from now on compare
  /// unequal to the ones already mounted. Call after replacing an attachment's
  /// content; widgets holding a provider then rebuild theirs (see
  /// `_AttachmentImageState`).
  ///
  /// Named apart from [ImageProvider.evict] — which needs an instance, and so
  /// a loader — because callers only have a worldId in hand.
  static void evictWorldId(String worldId, {double scale = 1.0}) {
    final revision = revisionOf(worldId);
    PaintingBinding.instance.imageCache
        .evict(AttachmentImageKey(worldId, scale, revision));
    _revisions[worldId] = revision + 1;
  }

  @override
  bool operator ==(Object other) =>
      other is AttachmentImage &&
      other.worldId == worldId &&
      other.scale == scale &&
      other.revision == revision;

  @override
  int get hashCode => Object.hash(worldId, scale, revision);

  @override
  String toString() =>
      'AttachmentImage("$worldId", scale: $scale, revision: $revision)';
}
