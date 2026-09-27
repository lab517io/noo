import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/utils/platform_info.dart';
import '../../../core/utils/safe_filename.dart';
import '../../../core/utils/save_dialog.dart';
import '../../../core/utils/share_utils.dart';
import '../../../domain/entities/attachment.dart';
import '../../providers/attachment_playback_provider.dart';
import '../../providers/providers.dart';
import '../../providers/voice_memo_provider.dart';
import '../task_editor/voice_memo_ops.dart';
import 'attachment_actions.dart';
import 'attachment_preview.dart';

/// Attachment list for the selected task.
///
/// Body only — the section header moved into the editor status bar, which owns
/// the expand/collapse toggle, the file count badge and the add button. This
/// widget is mounted only while the section is expanded, so the list query
/// still runs only on demand.
class AttachmentsPanel extends ConsumerStatefulWidget {
  final int taskId;

  /// Take all the height the parent offers instead of capping the list.
  ///
  /// The cap suits a strip below a desktop editor, which is borrowing the
  /// editor's room; it is wrong for the phone task screen's Files tab, where
  /// the list *is* the screen and a cap would leave the rest of it blank.
  final bool fillHeight;

  const AttachmentsPanel({
    super.key,
    required this.taskId,
    this.fillHeight = false,
  });

  @override
  ConsumerState<AttachmentsPanel> createState() => _AttachmentsPanelState();
}

class _AttachmentsPanelState extends ConsumerState<AttachmentsPanel> {
  /// Attachment ids whose image preview is open. Kept here rather than in the
  /// tile so the state survives the list rebuilding after a rename or a sync.
  final Set<int> _expandedIds = {};

  @override
  Widget build(BuildContext context) {
    final attachmentsAsync = ref.watch(taskAttachmentsProvider(widget.taskId));

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: attachmentsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (e, st) => Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error,
                  size: 16, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Failed to load attachments: $e',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        data: (attachments) => attachments.isEmpty
            ? _buildEmptyState(context)
            : _buildAttachmentsList(context, attachments),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.attachment,
            size: 48,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'No attachments',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => addAttachments(ref, widget.taskId),
            icon: const Icon(Icons.add),
            label: const Text('Add file'),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsList(BuildContext context, List<Attachment> attachments) {
    // "Transcribe" only appears once a model is actually on disk: offering it
    // otherwise would be a menu item whose only effect is an error.
    final transcriptionReady =
        ref.watch(voiceMemoModelReadyProvider).value ?? false;
    return Container(
      // Previews make rows much taller than a bare file list, so the section
      // gets more room before it starts scrolling.
      constraints: widget.fillHeight
          ? const BoxConstraints.expand()
          : const BoxConstraints(maxHeight: 320),
      child: ListView.builder(
        // Only when the height is borrowed from the editor: given a height of
        // its own the list must fill it, and a shrink-wrapped list would size
        // itself to its rows and leave the rest blank.
        shrinkWrap: !widget.fillHeight,
        itemCount: attachments.length,
        itemBuilder: (context, index) {
          final attachment = attachments[index];
          final id = attachment.id;
          return _AttachmentTile(
            attachment: attachment,
            expanded: id != null && _expandedIds.contains(id),
            onToggleExpanded: id == null ? null : () => _toggleExpanded(id),
            onExport: () => _exportAttachment(attachment),
            onDelete: () => _deleteAttachment(attachment),
            onRename: () => _renameAttachment(attachment),
            onOpen:
                isMobilePlatform ? () => _openAttachment(attachment) : null,
            onTranscribe: attachment.isAudio && transcriptionReady
                ? () => _transcribeAttachment(attachment)
                : null,
          );
        },
      ),
    );
  }

  /// Transcribe [attachment] and insert the text into the open note.
  ///
  /// The editor's controller is published by the mounted task editor; when no
  /// editor is on screen, or it has moved to another task, the op reports that
  /// rather than writing into the wrong note.
  Future<void> _transcribeAttachment(Attachment attachment) async {
    await transcribeStoredMemo(
      context,
      ref,
      ref.read(editorControllerProvider),
      memo: attachment,
      openTaskId: ref.read(selectedTaskIdProvider),
    );
  }

  void _toggleExpanded(int id) {
    setState(() {
      if (!_expandedIds.remove(id)) _expandedIds.add(id);
    });
  }

  /// Load an attachment's bytes, or show a snackbar and return null.
  ///
  /// An attachment whose bytes have not arrived yet is fetched here rather
  /// than left until the next sync: after an exchange only a bounded slice of
  /// the pending attachments is pulled, so opening one is the other way it
  /// gets asked for (docs/P2P_SYNC.md \u00a73.5).
  Future<List<int>?> _loadContent(Attachment attachment) async {
    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return null;

    var withContent = attachment.contentLoaded
        ? attachment
        : await repo.loadAttachmentContent(attachment);

    if (withContent.content == null && attachment.pendingDownload) {
      final fetched = await _downloadNow(attachment);
      if (fetched && mounted) {
        withContent = await repo.loadAttachmentContent(attachment);
      }
    }

    if (withContent.content == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(attachment.pendingDownload
                ? 'This attachment has not been downloaded yet \u2014 '
                    'sync to fetch it'
                : 'Failed to load attachment content'),
          ),
        );
      }
      return null;
    }
    return withContent.content!;
  }

  /// Pull one attachment's bytes on demand, with a progress dialog \u2014 it is a
  /// network round trip on a file that may be large, so it must not look like
  /// the app simply stopped responding to the tap.
  Future<bool> _downloadNow(Attachment attachment) async {
    final sync = ref.read(syncServiceProvider);
    final id = attachment.id;
    if (sync == null || id == null) return false;

    // Captured before the await: if this panel is disposed while the download
    // runs, `Navigator.of(context)` would no longer be reachable and the
    // progress dialog would be left on screen with nothing to dismiss it. The
    // root navigator, because that is where showDialog puts the route.
    final navigator = Navigator.of(context, rootNavigator: true);
    // The barrier flag does not cover the Android back button, and a pop
    // after the dialog has already gone would take whatever route is on top
    // instead \u2014 the task screen, or a dialog opened since. So the dialog
    // refuses to pop on its own, and the finally only pops it while it is
    // still up.
    var dialogOpen = true;
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(child: Text('Downloading attachment\u2026')),
            ],
          ),
        ),
      ),
    ).whenComplete(() => dialogOpen = false));
    try {
      return await sync.fetchAttachmentNow(id);
    } finally {
      if (dialogOpen) navigator.pop();
    }
  }

  Future<void> _exportAttachment(Attachment attachment) async {
    final content = await _loadContent(attachment);
    if (content == null) return;

    // Scoped storage has no arbitrary save paths — hand off via share sheet.
    if (isMobilePlatform) {
      await shareBytes(filename: attachment.filename, bytes: content);
      return;
    }

    // Ask user where to save. file_picker performs the write itself.
    final saved = await FilePicker.saveFile(
      dialogTitle: 'Export attachment',
      fileName: attachment.filename,
      bytes: Uint8List.fromList(content),
    );

    if (saved == null) return;

    if (mounted) {
      final shown = savedFilePath(saved) ?? attachment.filename;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported: ${p.basename(shown)}')),
      );
    }
  }

  /// Mobile: stage the attachment in the temp dir and hand it to whatever app
  /// claims the file type (the on-device equivalent of double-click-to-open).
  Future<void> _openAttachment(Attachment attachment) async {
    final content = await _loadContent(attachment);
    if (content == null) return;

    final tmp = await getTemporaryDirectory();
    final dir = Directory(p.join(tmp.path, 'attachments'));
    await dir.create(recursive: true);
    // The name is the user's — or another device's — free text, so it may not
    // pick the directory: see [safeFilename].
    final path = p.join(dir.path, safeFilename(attachment.filename));
    await File(path).writeAsBytes(content, flush: true);

    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No app can open ${attachment.filename}')),
      );
    }
  }

  Future<void> _deleteAttachment(Attachment attachment) async {
    // Confirm deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete attachment?'),
        content: Text('Are you sure you want to delete "${attachment.filename}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null || attachment.id == null) return;

    // Free the audio device first: the player would otherwise keep streaming
    // from a row the server no longer serves.
    await ref
        .read(audioPlaybackProvider.notifier)
        .stopIfPlaying(attachment.id);

    await repo.deleteAttachment(attachment.id!);
    _expandedIds.remove(attachment.id);
    refreshAttachments(ref, widget.taskId);
  }

  Future<void> _renameAttachment(Attachment attachment) async {
    final controller = TextEditingController(text: attachment.filename);

    final String? newName;
    try {
      newName = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rename attachment'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'File name',
            ),
            onSubmitted: (value) => Navigator.of(context).pop(value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Rename'),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }

    if (newName == null || newName.isEmpty || newName == attachment.filename) {
      return;
    }

    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) return;

    await repo.updateAttachment(attachment.copyWith(filename: newName));
    refreshAttachments(ref, widget.taskId);
  }
}

/// Individual attachment tile with context menu.
///
/// Images and audio preview in place: an image shows a thumbnail and expands to
/// a full-width preview, audio carries transport controls under its name.
class _AttachmentTile extends StatelessWidget {
  final Attachment attachment;
  final bool expanded;
  final VoidCallback? onToggleExpanded;
  final VoidCallback onExport;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  /// Mobile only: open the attachment in another app. When set, "Export"
  /// becomes "Share" and tapping the tile opens instead of exporting.
  final VoidCallback? onOpen;

  /// Run the memo through the transcriber and put the text in the note. Only
  /// offered for audio, and only when a model is downloaded — this is how a
  /// memo recorded on another device, or before a model existed, gets text.
  final VoidCallback? onTranscribe;

  const _AttachmentTile({
    required this.attachment,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onExport,
    required this.onDelete,
    required this.onRename,
    this.onOpen,
    this.onTranscribe,
  });

  /// Only images expand; audio is already fully controllable from the row.
  bool get _canExpand => attachment.isImage && onToggleExpanded != null;

  IconData _getFileIcon() {
    if (attachment.isImage) {
      return Icons.image;
    } else if (attachment.isAudio) {
      return Icons.audio_file;
    } else if (attachment.isDocument) {
      return Icons.description;
    } else {
      switch (attachment.extension) {
        case 'zip':
        case 'rar':
        case 'tar':
        case 'gz':
        case '7z':
          return Icons.archive;
        case 'mp4':
        case 'avi':
        case 'mkv':
        case 'mov':
          return Icons.video_file;
        case 'xls':
        case 'xlsx':
        case 'csv':
          return Icons.table_chart;
        default:
          return Icons.insert_drive_file;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRow(context),
        if (attachment.isImage && expanded)
          AttachmentImagePreview(attachment: attachment),
        if (attachment.isAudio) AttachmentAudioBar(attachment: attachment),
      ],
    );
  }

  Widget _buildRow(BuildContext context) {
    return ListTile(
      dense: true,
      leading: attachment.isImage
          ? AttachmentThumbnail(attachment: attachment)
          : Icon(_getFileIcon(), size: 24),
      title: Text(
        attachment.filename,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_canExpand)
            IconButton(
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              tooltip: expanded ? 'Hide preview' : 'Show preview',
              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              onPressed: onToggleExpanded,
            ),
          _buildMenu(context),
        ],
      ),
      // Tapping an image toggles its preview. Otherwise the tap keeps the
      // platform default: export on desktop, open in another app on mobile
      // (sharing lives in the menu there).
      onTap: _canExpand ? onToggleExpanded : (onOpen ?? onExport),
    );
  }

  Widget _buildMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, size: 20),
      onSelected: (value) {
        switch (value) {
          case 'open':
            onOpen?.call();
            break;
          case 'export':
            onExport();
            break;
          case 'rename':
            onRename();
            break;
          case 'transcribe':
            onTranscribe?.call();
            break;
          case 'delete':
            onDelete();
            break;
        }
      },
      itemBuilder: (context) => [
        if (onOpen != null)
          const PopupMenuItem(
            value: 'open',
            child: ListTile(
              leading: Icon(Icons.open_in_new),
              title: Text('Open'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        PopupMenuItem(
          value: 'export',
          child: ListTile(
            leading: Icon(onOpen != null ? Icons.share : Icons.download),
            title: Text(onOpen != null ? 'Share' : 'Export'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (onTranscribe != null)
          const PopupMenuItem(
            value: 'transcribe',
            child: ListTile(
              leading: Icon(Icons.transcribe),
              title: Text('Transcribe'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        const PopupMenuItem(
          value: 'rename',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Rename'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete),
            title: Text('Delete'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
