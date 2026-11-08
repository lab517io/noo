import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/duration_formatter.dart';
import '../../../core/utils/platform_info.dart';
import '../../providers/providers.dart';
import '../../providers/voice_memo_provider.dart';
import '../../screens/task_editor_screen.dart';
import '../attachments/attachment_actions.dart';
import 'voice_memo_ops.dart';

/// Attach file and Record voice memo, floating in the note's bottom-right
/// corner (Preferences → Editor → Floating buttons).
///
/// An addition, not a replacement: the toolbar keeps its mic button and the
/// status bar its add button, and both run the same code as these. What this
/// adds is reach — on a phone the toolbar is only on screen while the note has
/// focus, so recording a memo while reading meant tapping into the text and
/// raising the keyboard first; on a desktop adding a file meant opening the
/// attachments section before its `+` appeared.
class EditorFloatingActions extends ConsumerWidget {
  const EditorFloatingActions({super.key, required this.taskId});

  final int taskId;

  /// How much of the editor's bottom edge the cluster covers, so the editor
  /// can pad its text clear of it.
  static double reservedHeight(BuildContext context) =>
      isCompactLayout(context) ? 72 : 60;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memo = ref.watch(voiceMemoProvider);
    final scheme = Theme.of(context).colorScheme;
    final compact = isCompactLayout(context);
    final gap = SizedBox(width: compact ? 12 : 8);

    // Starting, saving or transcribing: the mic is spoken for, and the
    // recording bar above says with what.
    final micBusy = memo.isBusy && !memo.isRecording;

    // Inside a TextFieldTapRegion, like the toolbar: a press that counted as a
    // tap outside the editor would unfocus it and move the caret the
    // transcript is inserted at.
    return TextFieldTapRegion(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _FloatingButton(
            compact: compact,
            icon: Icons.attach_file,
            tooltip: compact
                ? 'Attach file\n(long-press to show attachments)'
                : 'Attach file\n(long-press to show or hide attachments)',
            onPressed: () => _attach(context, ref),
            onLongPress: () => _toggleAttachments(context, ref),
          ),
          gap,
          _FloatingButton(
            compact: compact,
            icon: memo.isRecording ? Icons.stop : Icons.mic_none,
            label: memo.isRecording
                ? DurationFormatter.formatMediaPosition(memo.elapsed)
                : null,
            background: memo.isRecording ? scheme.error : null,
            foreground: memo.isRecording ? scheme.onError : null,
            tooltip: memo.isRecording
                ? 'Stop recording'
                : 'Record voice memo\n'
                      '(long-press to record without transcribing)',
            onPressed: micBusy
                ? null
                : () => toggleVoiceMemo(context, ref, taskId),
            // Only a start can skip the transcript; a long-press while
            // recording is simply a stop.
            onLongPress: micBusy
                ? null
                : () => toggleVoiceMemo(
                    context,
                    ref,
                    taskId,
                    transcribe: memo.isRecording,
                  ),
          ),
        ],
      ),
    );
  }

  /// Show the attachments without adding one: fold the section under the
  /// editor out or back in on a wide layout, switch to the Files tab on a
  /// phone — where there is nothing to fold back, since the tab bar is the
  /// way back to the note.
  void _toggleAttachments(BuildContext context, WidgetRef ref) {
    if (isCompactLayout(context)) {
      TaskEditorScreen.showFiles(context);
      return;
    }
    final section = ref.read(attachmentsSectionExpandedProvider.notifier);
    section.value = !ref.read(attachmentsSectionExpandedProvider);
  }

  /// Pick files, then show where they went: the attachments section on a
  /// wide layout, which may well be folded away, and the Files tab on a phone.
  Future<void> _attach(BuildContext context, WidgetRef ref) async {
    final added = await addAttachments(ref, taskId);
    if (added.isEmpty || !context.mounted) return;

    if (!isCompactLayout(context)) {
      ref.read(attachmentsSectionExpandedProvider.notifier).value = true;
      return;
    }

    final what = added.length == 1 ? added.single : '${added.length} files';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Attached $what'),
        action: SnackBarAction(
          label: 'Show',
          onPressed: () => TaskEditorScreen.showFiles(context),
        ),
      ),
    );
  }
}

class _FloatingButton extends StatelessWidget {
  const _FloatingButton({
    required this.compact,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.onLongPress,
    this.label,
    this.background,
    this.foreground,
  });

  final bool compact;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final String? label;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null;
    final bg = background ?? scheme.secondaryContainer;
    final fg = foreground ?? scheme.onSecondaryContainer;
    // A touch target on a phone, a quiet control on a desktop.
    final size = compact ? 48.0 : 40.0;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: enabled ? bg : bg.withValues(alpha: 0.5),
        elevation: 3,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          onLongPress: onLongPress,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: size, minHeight: size),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: label == null ? 0 : 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: compact ? 24 : 20,
                    color: enabled ? fg : fg.withValues(alpha: 0.5),
                  ),
                  if (label != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      label!,
                      style: TextStyle(
                        color: fg,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
