import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/duration_formatter.dart';
import '../../../core/utils/platform_info.dart';
import '../../../data/services/sync_service.dart';
import '../../../domain/entities/time_line.dart';
import '../../providers/providers.dart';
import '../../providers/settings_provider.dart';
import '../../screens/task_editor_screen.dart';
import '../app_menu_bar.dart';
import '../attachments/attachment_actions.dart';
import '../time_tracking/time_tracking_actions.dart';
import '../time_tracking/timeline_dialog.dart';
import 'pending_sync_preview.dart';

/// Full-width status bar along the bottom of the main window.
///
/// Collects everything that used to occupy its own strip of vertical space: the
/// expand/collapse toggles and controls for the time-tracking and attachments
/// sections (two permanent header rows), the modified indicator, the selected
/// node's path (its own row under the toolbar), and the database path plus sync
/// state (the toolbar itself). One ~27px bar now carries all of it.
///
/// Left to right: database path, node path, modified, task sections, sync —
/// where you are on the left, what you can act on to the right.
class StatusBar extends ConsumerStatefulWidget {
  const StatusBar({super.key});

  @override
  ConsumerState<StatusBar> createState() => _StatusBarState();
}

class _StatusBarState extends ConsumerState<StatusBar> {
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _updateTickTimer();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  /// Keep today's total ticking while the *selected* task is the one being
  /// recorded — that's the only reading on this bar that changes on its own.
  void _updateTickTimer() {
    _tickTimer?.cancel();
    _tickTimer = null;

    final selectedId = ref.read(selectedTaskIdProvider);
    if (selectedId == null) return;
    if (ref.read(activeTrackingTaskIdProvider) != selectedId) return;

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedId = ref.watch(selectedTaskIdProvider);
    final syncStatus = ref.watch(syncStatusProvider);
    final databasePath = ref.watch(currentDatabasePathProvider);
    final isModified = ref.watch(editorModifiedProvider);

    // Both the tracked task and the selected one decide whether the total needs
    // a ticker; listen rather than act in build so no timer starts mid-frame.
    ref.listen(activeTrackingTaskIdProvider, (_, _) => _updateTickTimer());
    ref.listen(selectedTaskIdProvider, (_, _) => _updateTickTimer());

    final nodePath = _nodePathParts(selectedId);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          // The two paths share all the slack: this is the row's only flexible
          // child, so whatever they don't use becomes the gap in front of the
          // controls and the sync icon stays pinned to the right edge.
          Expanded(
            child: Row(
              children: [
                // Compact layouts show the database name in the app bar, so
                // the path here would only crowd out the node path.
                if (databasePath != null && !isCompactLayout(context))
                  Flexible(
                    flex: 2,
                    child: _PathText(
                      icon: Icons.storage,
                      head: _databaseDirectory(databasePath),
                      tail: p.basename(databasePath),
                      tooltip: databasePath,
                    ),
                  ),
                if (databasePath != null &&
                    !isCompactLayout(context) &&
                    nodePath.isNotEmpty)
                  _separator(theme),
                if (nodePath.isNotEmpty)
                  Flexible(
                    flex: 3,
                    child: _PathText(
                      head: nodePath.length == 1
                          ? ''
                          : '${nodePath.sublist(0, nodePath.length - 1).join(' > ')} > ',
                      tail: nodePath.last,
                      tooltip: nodePath.join(' > '),
                    ),
                  ),
              ],
            ),
          ),
          if (isModified) ...[
            const SizedBox(width: 8),
            Icon(Icons.edit, size: 13, color: theme.colorScheme.outline),
            const SizedBox(width: 4),
            Text(
              'Modified',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
          if (selectedId != null) ...[
            _separator(theme),
            ..._buildTaskSections(context, selectedId),
          ],
          _separator(theme),
          _buildPeerIndicator(),
          _buildSyncIndicator(_effectiveSyncStatus(syncStatus, isModified)),
        ],
      ),
    );
  }

  /// Noo devices visible on the LAN, and the only always-present way to sync
  /// with them. Nothing on the LAN exchanges on its own, so this doubles as
  /// the trigger: the count tells you it is possible, the click does it.
  ///
  /// Absent entirely when nothing is nearby — an empty count would suggest
  /// something is wrong rather than that nobody else is home.
  Widget _buildPeerIndicator() {
    final peers = ref.watch(lanPeersProvider).value ?? const [];
    final busy = ref.watch(lanSyncBusyProvider);
    if (peers.isEmpty && !busy) return const SizedBox.shrink();

    if (busy) {
      return const Padding(
        padding: EdgeInsets.all(4),
        child: Tooltip(
          message: 'Syncing with nearby devices...',
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final names = peers.map((p) => '• ${p.deviceId} (${p.address.address})');
    return Tooltip(
      message: '${peers.length == 1 ? '1 device' : '${peers.length} devices'} '
          'nearby — click to sync\n${names.join('\n')}',
      child: InkWell(
        onTap: () => AppMenuBar.syncWithPeers(context, ref),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.devices, size: 15, color: theme.colorScheme.primary),
              const SizedBox(width: 3),
              Text(
                '${peers.length}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Time tracking and attachments: a toggle chip each, plus the controls that
  /// have to stay reachable without expanding anything.
  ///
  /// On a phone there is nothing here to expand *into* — this bar sits under
  /// the tree, and the editor it would fold the sections out of is a route
  /// away. So the chips navigate instead, opening the node on the tab they
  /// describe; the readings they carry stay exactly as useful.
  List<Widget> _buildTaskSections(BuildContext context, int taskId) {
    final theme = Theme.of(context);
    final compact = isCompactLayout(context);
    final isTracking = ref.watch(activeTrackingTaskIdProvider) == taskId;
    final showSeconds = ref.watch(settingsProvider).showSeconds;
    final timeExpanded = ref.watch(timeSectionExpandedProvider) && !compact;
    final attachmentsExpanded =
        ref.watch(attachmentsSectionExpandedProvider) && !compact;

    // Keep the last loaded values while a reload is in flight so the readings
    // don't blank out on every refresh.
    final timeLine =
        ref.watch(taskTimelineProvider(taskId)).value ?? const TimeLine();
    final attachmentCount =
        ref.watch(attachmentCountProvider(taskId)).value ?? 0;

    return [
      _StatusChip(
        icon: Icons.timer,
        iconColor:
            isTracking ? theme.colorScheme.primary : theme.colorScheme.outline,
        label:
            DurationFormatter.formatHMS(timeLine.today, showSeconds: showSeconds),
        selected: timeExpanded,
        tooltip: compact
            ? 'Time tracked today — tap to open'
            : timeExpanded
                ? 'Hide time tracking'
                : 'Time tracked today — click for details',
        showDot: isTracking,
        onTap: compact
            ? () => _openTaskDetails(TaskEditorScreen.timeTab)
            : () => ref.read(timeSectionExpandedProvider.notifier).value =
                !timeExpanded,
      ),
      _BarButton(
        icon: Icons.list_alt,
        tooltip: 'View timeline',
        onPressed: compact
            ? () => _openTaskDetails(TaskEditorScreen.timeTab)
            : () => _showTimelineDialog(taskId, timeLine),
      ),
      _BarButton(
        icon: isTracking ? Icons.stop : Icons.play_arrow,
        color: isTracking ? theme.colorScheme.error : null,
        tooltip: isTracking ? 'Stop tracking' : 'Start tracking',
        onPressed: () => toggleTracking(ref, taskId),
      ),
      _separator(theme),
      _StatusChip(
        icon: Icons.attach_file,
        iconColor: theme.colorScheme.outline,
        label: '$attachmentCount',
        selected: attachmentsExpanded,
        tooltip: compact
            ? 'Attachments — tap to open'
            : attachmentsExpanded
                ? 'Hide attachments'
                : 'Attachments — click to show',
        onTap: compact
            ? () => _openTaskDetails(TaskEditorScreen.filesTab)
            : () => ref
                .read(attachmentsSectionExpandedProvider.notifier)
                .value = !attachmentsExpanded,
      ),
      // Mirrors the old header: adding is offered only while the list is
      // visible, so the file lands somewhere the user can see it. The phone's
      // Files tab carries its own Add button for the same reason.
      if (attachmentsExpanded)
        _BarButton(
          icon: Icons.add,
          tooltip: 'Add attachment',
          onPressed: () => addAttachments(ref, taskId),
        ),
    ];
  }

  /// Open the selected node's own screen on [tab] — the phone's answer to
  /// expanding a section under an editor that isn't on this screen.
  void _openTaskDetails(int tab) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TaskEditorScreen(initialTab: tab)),
    );
  }

  /// Ancestor chain of the selected node, root first — `[Work, Q3, Report]`.
  /// Empty when there is no selection or the tree isn't loaded yet.
  List<String> _nodePathParts(int? selectedId) {
    if (selectedId == null) return const [];
    final treeCtrl = ref.watch(taskTreeControllerProvider);
    if (treeCtrl == null) return const [];

    final parts = <String>[];
    int? currentId = selectedId;
    while (currentId != null) {
      final node = treeCtrl.findNode(currentId);
      if (node == null) break;
      final title = node.task.title.isEmpty ? '(untitled)' : node.task.title;
      parts.add(title);
      currentId = node.parentId;
    }
    return parts.reversed.toList();
  }

  /// Directory part of the database path, kept with a trailing separator so it
  /// reads as a path once the file name is appended.
  String _databaseDirectory(String path) {
    final dir = p.dirname(path);
    if (dir.isEmpty || dir == '.') return '';
    return dir.endsWith(p.separator) ? dir : '$dir${p.separator}';
  }

  /// Unsaved editor text is a local change too, even though it hasn't reached
  /// the history tables [syncPendingWatcherProvider] watches — the autosave
  /// debounce hasn't fired yet. Leaving the indicator green while the bar says
  /// "Modified" claims we're in sync with the server about text the server has
  /// never seen, so a modified editor forces "pending changes".
  ///
  /// Only the green "Synced" state is overridden: disabled/syncing/error/
  /// unknown already say something the editor's state doesn't contradict.
  SyncStatus _effectiveSyncStatus(SyncStatus status, bool isModified) {
    if (isModified && status == SyncStatus.idle) return SyncStatus.pendingChanges;
    return status;
  }

  Widget _buildSyncIndicator(SyncStatus status) {
    final Widget indicator;
    switch (status) {
      case SyncStatus.disabled:
        indicator = const Tooltip(
          message: 'Sync disabled — click to sync',
          child: Icon(Icons.cloud_off, size: 16, color: Colors.grey),
        );
      case SyncStatus.unknown:
        indicator = const Tooltip(
          message: 'Not synced yet — click to sync',
          child: Icon(Icons.cloud_queue, size: 16, color: Colors.grey),
        );
      case SyncStatus.idle:
        indicator = const Tooltip(
          message: 'Synced — click to sync',
          child: Icon(Icons.cloud_done, size: 16, color: Colors.green),
        );
      case SyncStatus.syncing:
        indicator = const Tooltip(
          message: 'Syncing...',
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case SyncStatus.error:
        indicator = const Tooltip(
          message: 'Sync error — click to retry',
          child: Icon(Icons.cloud_off, size: 16, color: Colors.red),
        );
      case SyncStatus.pendingChanges:
        indicator = const Tooltip(
          message: 'Pending changes — click to sync',
          child: Icon(Icons.cloud_upload, size: 16, color: Colors.orange),
        );
    }

    // While a sync is in flight, keep the spinner inert; otherwise let a click
    // trigger a sync (same action as the File → Sync Now menu / F5).
    if (status == SyncStatus.syncing) {
      return Padding(padding: const EdgeInsets.all(4), child: indicator);
    }

    // Resting the pointer here lists what is actually waiting to be synced —
    // the tooltip only says *that* something is.
    return PendingSyncPreview(
      child: InkWell(
        onTap: () => AppMenuBar.syncNow(context, ref),
        borderRadius: BorderRadius.circular(4),
        child: Padding(padding: const EdgeInsets.all(4), child: indicator),
      ),
    );
  }

  Widget _separator(ThemeData theme) => Container(
        width: 1,
        height: 16,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: theme.dividerColor,
      );

  void _showTimelineDialog(int taskId, TimeLine timeLine) {
    showDialog(
      context: context,
      builder: (context) => TimelineDialog(
        taskId: taskId,
        timeLine: timeLine,
        onChanged: () => ref.read(timelineRefreshProvider.notifier).value++,
      ),
    );
  }
}

/// A path whose last segment — the node title, the file name — is the part
/// worth reading, so the leading directories/ancestors absorb the ellipsis
/// instead. [tail] is laid out first and [head] takes whatever is left.
class _PathText extends StatelessWidget {
  final String head;
  final String tail;
  final String tooltip;
  final IconData? icon;

  const _PathText({
    required this.head,
    required this.tail,
    required this.tooltip,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall;

    // The tail — the node's own name, the database's own file name — is what
    // the reading is *for*, so it is laid out first and keeps whatever width
    // it needs; the head is context and ellipsizes away in front of it.
    //
    // That only works while the tail itself fits. Bounding it to the row makes
    // the last resort an ellipsis rather than text running off the screen,
    // which is what a long title on a phone did.
    // Width the icon takes out of the row before the text gets any: its size
    // plus the gap after it.
    const iconWidth = 13.0 + 4.0;

    return Tooltip(
      message: tooltip,
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: theme.colorScheme.outline),
              const SizedBox(width: 4),
            ],
            if (head.isNotEmpty)
              Flexible(
                child: Text(
                  head,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: style?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: (constraints.maxWidth -
                        (icon == null ? 0.0 : iconWidth))
                    .clamp(0.0, double.infinity),
              ),
              child: Text(
                tail,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style:
                    style?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clickable section toggle: icon, value and a pressed-looking background while
/// the matching section is expanded.
class _StatusChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool selected;
  final String tooltip;
  final bool showDot;
  final VoidCallback onTap;

  const _StatusChip({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.selected,
    required this.tooltip,
    required this.onTap,
    this.showDot = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.surfaceContainerHighest
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: iconColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (showDot) ...[
                const SizedBox(width: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon button sized for the status bar's reduced height.
class _BarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  const _BarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 16, color: color),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 26, minHeight: 22),
      padding: EdgeInsets.zero,
      // Material 3 keeps a 40px tap target unless the style says otherwise,
      // which would set the height of the whole bar.
      style: IconButton.styleFrom(
        minimumSize: const Size(26, 22),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
