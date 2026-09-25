import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/time_line.dart';
import '../providers/providers.dart';
import '../widgets/attachments/attachment_actions.dart';
import '../widgets/attachments/attachments_panel.dart';
import '../widgets/task_editor/task_editor_panel.dart';
import '../widgets/time_tracking/time_stats_panel.dart';
import '../widgets/time_tracking/time_tracking_actions.dart';
import '../widgets/time_tracking/timeline_view.dart';

/// Full-screen task view for compact (phone) layouts, pushed from the task
/// tree. Wide layouts render [TaskEditorPanel] beside the tree instead and
/// never navigate here.
///
/// Everything about the node lives here, in three tabs: the note itself, its
/// time, and its files. On a desktop those last two are strips that the status
/// bar folds out under the editor — but the status bar belongs to the main
/// window, which on a phone is the tree screen, one route back. Their controls
/// were therefore unreachable from the very screen they describe; tabs put
/// each section on the node it belongs to, and give it the whole screen rather
/// than a strip below a squeezed editor.
///
/// Follows [selectedTaskIdProvider] like the panel does, so nothing here owns
/// the task — the screen is chrome around the same providers the wide layout
/// uses.
class TaskEditorScreen extends ConsumerStatefulWidget {
  /// The tabs, for callers that open the screen on one of them — the tree
  /// screen's status bar opens straight onto the section its chip describes.
  static const int notesTab = 0;
  static const int timeTab = 1;
  static const int filesTab = 2;

  final int initialTab;

  const TaskEditorScreen({super.key, this.initialTab = notesTab});

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      initialIndex: widget.initialTab
          .clamp(TaskEditorScreen.notesTab, TaskEditorScreen.filesTab),
      vsync: this,
    );
    // The tab bar's visibility depends on which tab is showing — see
    // [_tabsHidden].
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() => setState(() {});

  /// Whether the tab bar is put away: while the note is being typed into.
  ///
  /// With the soft keyboard up, the app bar, the tab bar and the formatting
  /// toolbar left about three hundred pixels for the text on an ordinary
  /// phone, and the tabs are the one part of that nobody reaches for mid
  /// sentence. They come back as soon as the keyboard goes down.
  ///
  /// The Notes tab only. Swiping to another tab with the keyboard still up —
  /// the editor is kept alive, so it keeps its focus — must show where you
  /// have landed, or the screen changes under a bar that says nothing.
  bool _tabsHidden(BuildContext context) =>
      _tabController.index == TaskEditorScreen.notesTab &&
      MediaQuery.viewInsetsOf(context).bottom > 0;

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedTaskIdProvider);
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(
        // Denser than Material's 56: on a phone every row of chrome is a row
        // of the note that does not fit.
        toolbarHeight: 48,
        title: selectedId == null || db == null
            ? const Text('Task')
            : FutureBuilder(
                future: db.getTaskById(selectedId),
                builder: (context, snapshot) {
                  final title = snapshot.data?.title;
                  return Text(
                    (title == null || title.isEmpty) ? 'Task' : title,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
        // Start/stop belongs in the app bar rather than in the Time tab: it is
        // the one control you reach for while reading or writing the note, and
        // switching tabs to press it would lose your place.
        actions: [
          if (selectedId != null) _buildTrackingAction(selectedId),
        ],
        // Three fixed-width tabs on a phone leave about a third of the screen
        // each, so the labels stay short — the today total belongs on the Time
        // tab's first line, not on the tab. The ellipsis covers the largest
        // system font settings, where even these do not fit.
        bottom: _tabsHidden(context)
            ? null
            : TabBar(
                controller: _tabController,
                tabs: [
                  const Tab(child: _TabLabel('Notes')),
                  const Tab(child: _TabLabel('Time')),
                  Tab(child: _TabLabel(_filesTabLabel(selectedId))),
                ],
              ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Kept alive across tab switches. A TabBarView unmounts the page
            // you leave, and tearing the editor down to glance at the files
            // would discard the undo history, the caret and the scroll
            // position of a note that is still open — and run
            // TaskEditorPanel.dispose, which writes to providers, in the
            // middle of a build.
            const _KeepAlive(child: TaskEditorPanel()),
            _KeepAlive(child: _buildTimeTab(selectedId)),
            _KeepAlive(child: _buildFilesTab(selectedId)),
          ],
        ),
      ),
    );
  }

  /// The file count rides on the tab, the way the desktop status bar puts it
  /// on its chip: it is the reading you would otherwise open the tab just to
  /// see, and it is short enough to fit beside two other labels.
  String _filesTabLabel(int? taskId) {
    if (taskId == null) return 'Files';
    final count = ref.watch(attachmentCountProvider(taskId)).value ?? 0;
    return count == 0 ? 'Files' : 'Files ($count)';
  }

  Widget _buildTrackingAction(int taskId) {
    final theme = Theme.of(context);
    final isTracking = ref.watch(activeTrackingTaskIdProvider) == taskId;

    return IconButton(
      icon: Icon(isTracking ? Icons.stop : Icons.play_arrow),
      color: isTracking ? theme.colorScheme.error : null,
      tooltip: isTracking ? 'Stop tracking' : 'Start tracking',
      onPressed: () => toggleTracking(ref, taskId),
    );
  }

  /// Totals above, the individual records below — the whole of what the
  /// desktop splits between the stats strip and the timeline dialog.
  Widget _buildTimeTab(int? taskId) {
    if (taskId == null) return _buildNoTask('No task selected.');

    final timeLine =
        ref.watch(taskTimelineProvider(taskId)).value ?? const TimeLine();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TimeStatsPanel(taskId: taskId),
        Expanded(
          child: TimelineView(
            taskId: taskId,
            timeLine: timeLine,
            onChanged: () =>
                ref.read(timelineRefreshProvider.notifier).value++,
          ),
        ),
      ],
    );
  }

  /// The attachment list plus the add command that used to live on the status
  /// bar beside the count.
  Widget _buildFilesTab(int? taskId) {
    if (taskId == null) return _buildNoTask('No task selected.');
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Icon(Icons.attach_file, size: 16, color: theme.hintColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Attachments', style: theme.textTheme.titleSmall),
              ),
              TextButton.icon(
                onPressed: () => addAttachments(ref, taskId),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: AttachmentsPanel(taskId: taskId, fillHeight: true),
        ),
      ],
    );
  }

  /// The task went away while its screen was open — deleted here, or removed
  /// by a sync that landed underneath us.
  Widget _buildNoTask(String message) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

/// Holds [child] mounted while its tab is off screen.
///
/// `PageView` — which is what a `TabBarView` is — honours keep-alive clients
/// among its children, so this is all it takes.
class _KeepAlive extends StatefulWidget {
  final Widget child;

  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// A tab caption that ellipsizes rather than overflowing its third of the bar.
class _TabLabel extends StatelessWidget {
  final String text;

  const _TabLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}
