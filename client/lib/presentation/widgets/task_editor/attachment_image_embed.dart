import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/attachment_uri.dart';
import '../../providers/providers.dart';
import '../attachments/attachment_image_provider.dart';
import 'attachment_image_ops.dart';

/// Renders `{"insert": {"image": "..."}}` embeds.
///
/// The source it is built for is normally `noo-attachment://<worldId>`, whose
/// bytes come from the `file` table. Other sources still render — a `data:` URI
/// or an `<img src>` from legacy HTML content, an http(s) link, a local path —
/// so imported documents are not silently blank.
class AttachmentImageEmbedBuilder extends EmbedBuilder {
  /// Task the editor is showing; images picked from the menu are attached to
  /// it. Null only if the editor is used without a task (read-only previews).
  final int? taskId;

  const AttachmentImageEmbedBuilder({this.taskId});

  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    return _AttachmentImage(
      // Rebuild from scratch when the line's embed is swapped for another one.
      key: ValueKey(imageSourceOf(embedContext.node)),
      node: embedContext.node,
      controller: embedContext.controller,
      readOnly: embedContext.readOnly,
      taskId: taskId,
    );
  }
}

class _AttachmentImage extends ConsumerStatefulWidget {
  final Embed node;
  final QuillController controller;
  final bool readOnly;
  final int? taskId;

  const _AttachmentImage({
    super.key,
    required this.node,
    required this.controller,
    required this.readOnly,
    required this.taskId,
  });

  @override
  ConsumerState<_AttachmentImage> createState() => _AttachmentImageState();
}

class _AttachmentImageState extends ConsumerState<_AttachmentImage> {
  ImageProvider? _provider;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  /// Pixel size of the decoded image, once known. Drives "fit to natural size"
  /// and the resize dialog's upper bound.
  Size? _naturalSize;

  String? get _source => imageSourceOf(widget.node);

  @override
  void initState() {
    super.initState();
    _provider = _buildProvider();
    _listenForNaturalSize();
  }

  @override
  void didUpdateWidget(_AttachmentImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (imageSourceOf(oldWidget.node) != _source) {
      _provider = _buildProvider();
      _naturalSize = null;
      _listenForNaturalSize();
    }
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  Future<Uint8List?> _loadAttachmentBytes(String worldId) async {
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return null;
    final attachment = await repo.getAttachmentByWorldId(worldId);
    return attachment?.content;
  }

  ImageProvider? _buildProvider() {
    final source = _source;
    if (source == null || source.isEmpty) return null;

    final worldId = attachmentWorldIdOf(source);
    if (worldId != null) {
      return AttachmentImage(worldId, loader: _loadAttachmentBytes);
    }

    if (source.startsWith('data:')) {
      try {
        final bytes = Uri.parse(source).data?.contentAsBytes();
        if (bytes != null) return MemoryImage(bytes);
      } catch (_) {
        // Malformed data URI — fall through to the error placeholder.
      }
      return null;
    }

    if (source.startsWith('http://') || source.startsWith('https://')) {
      return NetworkImage(source);
    }

    return FileImage(File(source));
  }

  /// Resolve the image once outside the [Image] widget to learn its pixel size.
  /// The decoded frame is shared through the image cache, so this costs a
  /// listener, not a second decode.
  void _listenForNaturalSize() {
    _stopListening();
    final provider = _provider;
    if (provider == null) return;

    final stream = provider.resolve(ImageConfiguration.empty);
    final listener = ImageStreamListener(
      (info, _) {
        final size = Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        );
        if (mounted && _naturalSize != size) {
          setState(() => _naturalSize = size);
        }
      },
      onError: (_, _) {
        // The Image widget renders the error state; nothing to do here.
      },
    );
    _stream = stream..addListener(listener);
    _listener = listener;
  }

  void _stopListening() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
    _stream = null;
    _listener = null;
  }

  @override
  Widget build(BuildContext context) {
    final provider = _provider;
    if (provider == null) return _buildBroken(context);

    final requestedWidth = imageWidthOf(widget.node);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : null;
        var width = requestedWidth ?? _naturalSize?.width;
        if (width != null && maxWidth != null && width > maxWidth) {
          width = maxWidth;
        }

        return Align(
          alignment: Alignment.centerLeft,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTapDown: (details) => _showMenu(details.globalPosition),
              onSecondaryTapDown: (details) =>
                  _showMenu(details.globalPosition),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Image(
                  image: provider,
                  width: width,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildBroken(context),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Shown when the source is unusable — most often an attachment that was
  /// deleted, or one whose bytes have not arrived from another device yet.
  Widget _buildBroken(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTapDown: (details) => _showMenu(details.globalPosition),
        onSecondaryTapDown: (details) => _showMenu(details.globalPosition),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(4),
            color: theme.colorScheme.surfaceContainerLow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: 18,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 8),
              Text(
                'Image not available',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMenu(Offset globalPosition) async {
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    final position = RelativeRect.fromRect(
      globalPosition & Size.zero,
      Offset.zero & overlay.size,
    );

    final attachmentBacked = attachmentWorldIdOf(_source) != null;
    final editable = !widget.readOnly && widget.taskId != null;

    final action = await showMenu<_ImageAction>(
      context: context,
      position: position,
      items: [
        if (editable)
          const PopupMenuItem(
            value: _ImageAction.resize,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.photo_size_select_large, size: 18),
              title: Text('Resize...'),
            ),
          ),
        if (editable)
          const PopupMenuItem(
            value: _ImageAction.replace,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.swap_horiz, size: 18),
              title: Text('Replace image...'),
            ),
          ),
        if (attachmentBacked)
          const PopupMenuItem(
            value: _ImageAction.save,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.save_alt, size: 18),
              title: Text('Save image as...'),
            ),
          ),
        if (editable) const PopupMenuDivider(),
        if (editable)
          const PopupMenuItem(
            value: _ImageAction.remove,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.text_fields, size: 18),
              title: Text('Remove from text'),
              subtitle: Text('Keeps the file in Attachments'),
            ),
          ),
        if (editable && attachmentBacked)
          const PopupMenuItem(
            value: _ImageAction.delete,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.delete_outline, size: 18),
              title: Text('Delete image'),
              subtitle: Text('Also deletes the attachment'),
            ),
          ),
      ],
    );

    if (action == null || !mounted) return;

    switch (action) {
      case _ImageAction.resize:
        await _resize();
      case _ImageAction.replace:
        await replaceImage(
          ref,
          widget.controller,
          widget.node,
          widget.taskId!,
        );
      case _ImageAction.save:
        await saveImageAs(context, ref, widget.node);
      case _ImageAction.remove:
        removeImageEmbed(widget.controller, widget.node);
      case _ImageAction.delete:
        await deleteImage(ref, widget.controller, widget.node, widget.taskId!);
    }
  }

  Future<void> _resize() async {
    final current = imageWidthOf(widget.node) ?? _naturalSize?.width ?? 320;

    final result = await showDialog<_ResizeResult>(
      context: context,
      builder: (context) => _ResizeDialog(
        initialWidth: current,
        naturalWidth: _naturalSize?.width,
      ),
    );
    if (result == null || !mounted) return;

    setImageWidth(widget.controller, widget.node, result.width);
  }
}

enum _ImageAction { resize, replace, save, remove, delete }

class _ResizeResult {
  /// Null restores the image's natural size.
  final double? width;

  const _ResizeResult(this.width);
}

class _ResizeDialog extends StatefulWidget {
  final double initialWidth;
  final double? naturalWidth;

  const _ResizeDialog({required this.initialWidth, this.naturalWidth});

  @override
  State<_ResizeDialog> createState() => _ResizeDialogState();
}

class _ResizeDialogState extends State<_ResizeDialog> {
  static const _minWidth = 40.0;

  /// Nothing sensible is wider than this, and it keeps a stray keystroke from
  /// producing an image that costs a fortune to lay out.
  static const _maxWidth = 4000.0;

  late double _width;
  late final TextEditingController _controller;

  /// The slider covers the natural size — the common case is shrinking a
  /// screenshot — but follows the typed value when it goes beyond that, so a
  /// deliberately enlarged image is still adjustable by dragging.
  double get _sliderMax {
    final natural = widget.naturalWidth ?? 1600;
    return [natural, _width, _minWidth * 2].reduce((a, b) => a > b ? a : b);
  }

  @override
  void initState() {
    super.initState();
    _width = widget.initialWidth.clamp(_minWidth, _maxWidth);
    _controller = TextEditingController(text: _width.round().toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setWidth(double value, {bool syncField = true}) {
    setState(() => _width = value.clamp(_minWidth, _maxWidth));
    if (syncField) _controller.text = _width.round().toString();
  }

  @override
  Widget build(BuildContext context) {
    final natural = widget.naturalWidth;
    final percent = natural == null ? null : (_width / natural * 100).round();

    return AlertDialog(
      title: const Text('Resize image'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 96,
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Width',
                    suffixText: 'px',
                    isDense: true,
                  ),
                  onChanged: (text) {
                    final value = double.tryParse(text);
                    if (value != null) _setWidth(value, syncField: false);
                  },
                ),
              ),
              const SizedBox(width: 12),
              if (percent != null)
                Text(
                  '$percent% of ${natural!.round()} px',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          Slider(
            min: _minWidth,
            max: _sliderMax,
            value: _width.clamp(_minWidth, _sliderMax),
            onChanged: _setWidth,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(const _ResizeResult(null)),
          child: const Text('Original size'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_ResizeResult(_width)),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
