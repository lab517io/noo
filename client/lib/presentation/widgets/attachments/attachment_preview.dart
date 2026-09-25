import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/duration_formatter.dart';
import '../../../domain/entities/attachment.dart';
import '../../providers/attachment_playback_provider.dart';
import 'attachment_image_provider.dart';

/// In-place previews for attachments: images render from their BLOB, audio
/// gets transport controls. Everything else keeps the plain file tile.

/// Small square preview shown in place of the file-type icon.
class AttachmentThumbnail extends ConsumerWidget {
  final Attachment attachment;
  final double size;

  const AttachmentThumbnail({
    super.key,
    required this.attachment,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Decode at display size: without the ResizeImage a 12 MP photo is held
    // as a full-resolution RGBA frame (~48 MB) just to paint 32 logical
    // pixels, and a task with a few photos keeps hundreds of megabytes alive
    // as the list scrolls. `fit` keeps the aspect ratio; the tile crops.
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).ceil();

    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Image(
        image: ResizeImage(
          attachmentImageFor(ref, attachment.worldId.value),
          width: pixels,
          height: pixels,
          policy: ResizeImagePolicy.fit,
        ),
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.broken_image_outlined,
          size: size * 0.75,
          color: theme.colorScheme.outline,
        ),
      ),
    );
  }
}

/// Full-width inline image, shown when an image tile is expanded.
class AttachmentImagePreview extends ConsumerWidget {
  final Attachment attachment;

  /// Beyond this the preview scrolls the list more than it informs; the image
  /// stays fully visible via Export or the editor.
  static const double maxHeight = 260;

  const AttachmentImagePreview({super.key, required this.attachment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(56, 0, 16, 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: maxHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image(
            image: attachmentImageFor(ref, attachment.worldId.value),
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
            errorBuilder: (context, error, stackTrace) => Text(
              'Image not available',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
        ),
      ),
    );
  }
}

/// Transport controls for an audio attachment: play/pause, a seek bar, and the
/// elapsed/total times.
///
/// The bytes reach the player over the loopback server rather than a temp file
/// (see [attachmentMediaServerProvider]), and one player is shared app-wide, so
/// starting this attachment stops whatever else was playing.
class AttachmentAudioBar extends ConsumerWidget {
  final Attachment attachment;

  const AttachmentAudioBar({super.key, required this.attachment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playback = ref.watch(audioPlaybackProvider);
    final isCurrent = playback.isCurrent(attachment);

    final position = isCurrent ? playback.position : Duration.zero;
    final duration = isCurrent ? playback.duration : Duration.zero;
    final error = isCurrent ? playback.error : null;

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(56, 0, 16, 12),
        child: Row(
          children: [
            Icon(Icons.error_outline,
                size: 16, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      );
    }

    // Until the duration arrives the slider has nothing to scale to; showing it
    // at zero would let a drag seek to a position that means nothing.
    final maxMillis = duration.inMilliseconds.toDouble();
    final value = maxMillis <= 0
        ? 0.0
        : position.inMilliseconds.toDouble().clamp(0, maxMillis);

    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 0, 16, 8),
      child: Row(
        children: [
          IconButton(
            iconSize: 22,
            visualDensity: VisualDensity.compact,
            tooltip: isCurrent && playback.playing ? 'Pause' : 'Play',
            icon: Icon(
              isCurrent && playback.playing
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline,
            ),
            onPressed: () =>
                ref.read(audioPlaybackProvider.notifier).toggle(attachment),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              ),
              child: Slider(
                min: 0,
                max: maxMillis <= 0 ? 1 : maxMillis,
                value: value.toDouble(),
                onChanged: maxMillis <= 0
                    ? null
                    : (millis) => ref
                        .read(audioPlaybackProvider.notifier)
                        .seek(Duration(milliseconds: millis.round())),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${DurationFormatter.formatMediaPosition(position)}'
            ' / ${DurationFormatter.formatMediaPosition(duration)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
