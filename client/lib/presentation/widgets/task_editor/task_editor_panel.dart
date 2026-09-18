import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/platform_info.dart';
import '../../../data/database/database.dart';
import '../../../domain/entities/task.dart';
import '../../providers/providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/value_controller.dart';
import '../attachments/attachments_panel.dart';
import '../time_tracking/time_stats_panel.dart';
import 'quill_editor_wrapper.dart';

/// Panel for editing task title and content
class TaskEditorPanel extends ConsumerStatefulWidget {
  const TaskEditorPanel({super.key});

  @override
  ConsumerState<TaskEditorPanel> createState() => _TaskEditorPanelState();
}

class _TaskEditorPanelState extends ConsumerState<TaskEditorPanel> {
  final _editorFocusNode = FocusNode();

  /// The task ID that we're currently editing (selection)
  int? _currentTaskId;

  /// The task ID whose data is actually loaded in the controllers
  int? _loadedTaskId;

  /// Current content from the Quill editor (updated via callback)
  String? _currentContent;

  /// Last content loaded from database (for comparison)
  String? _lastLoadedContent;

  /// Content currently rendered by the Quill editor. Only reassigned when a
  /// (re)load actually happens, so rebuilds during typing never reset the
  /// editor document.
  String? _editorContent;

  /// In-flight saves keyed by task id. When switching back to a task whose
  /// save hasn't landed yet, the pending content wins over the stale DB read.
  final Map<int, String?> _pendingSaves = {};

  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;

  /// Cached provider objects for use in [dispose]: `ref` is unusable once the
  /// element is unmounted, so everything dispose needs is captured up front
  /// (flush registration) or refreshed every build (database).
  ValueController<Future<void> Function()?>? _flushController;
  ValueController<bool>? _modifiedController;
  ValueController<FocusNode?>? _focusController;
  NooDatabase? _db;

  @override
  void initState() {
    super.initState();
    // Let a sync run force pending, still-debounced content to disk before it
    // reads the database (see editorFlushProvider). Deferred to a post-frame
    // callback so we don't mutate a provider during the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _flushController = ref.read(editorFlushProvider.notifier);
        _flushController!.value = _flushPendingSave;
        _modifiedController = ref.read(editorModifiedProvider.notifier);
        // Publish the editor's focus node so widgets that take focus away
        // (search panel, tree rename) can return it — see editorFocusProvider.
        _focusController = ref.read(editorFocusProvider.notifier);
        _focusController!.value = _editorFocusNode;
        _publishModified();
      }
    });
  }

  /// Mirrors [_hasUnsavedChanges] to [editorModifiedProvider] so the status bar
  /// — which lives outside this panel — can show the modified indicator.
  ///
  /// Deferred to after the frame because some transitions run during build (a
  /// selection change flushes the previous task's save), and mutating a
  /// provider mid-build throws.
  void _publishModified() {
    final controller = _modifiedController;
    if (controller == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.value = _hasUnsavedChanges;
    });
  }

  @override
  void dispose() {
    try {
      // Unregister only if the registration is still ours — a replacement
      // panel instance may have installed its own callback already.
      if (_flushController?.value == _flushPendingSave) {
        _flushController!.value = null;
      }
      // No editor on screen, so nothing can be modified.
      _modifiedController?.value = false;
      // Same guard as the flush registration: a replacement panel may already
      // have published its own node.
      if (_focusController?.value == _editorFocusNode) {
        _focusController!.value = null;
      }
    } catch (_) {
      // Container being torn down; nothing left to unregister from.
    }
    _saveCurrentContent(notifyErrors: false);
    _editorFocusNode.dispose();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  /// Persists any unsaved edit immediately and awaits the write, bypassing the
  /// auto-save debounce. Called before a sync run so freshly typed text is part
  /// of the sync instead of being stranded behind the timer.
  Future<void> _flushPendingSave() async {
    _autoSaveTimer?.cancel();
    await _saveTask();
  }

  @override
  Widget build(BuildContext context) {
    // Refresh the cached database handle; a database switch always clears the
    // selection (and thus saves + rebuilds) before this panel could save into
    // the wrong database.
    _db = ref.read(databaseProvider);
    final selectedId = ref.watch(selectedTaskIdProvider);

    // Handle selection change
    if (selectedId != _currentTaskId) {
      _onSelectionChanged(selectedId);
    }

    if (selectedId == null) {
      return _buildEmptyState(context);
    }
    return _buildTaskContent(context, selectedId);
  }

  Widget _buildTaskContent(BuildContext context, int selectedId) {
    final taskAsync = ref.watch(taskByIdProvider(selectedId));

    return taskAsync.when(
      loading: () {
        if (_loadedTaskId != null) {
          return _buildEditor(context, _loadedTaskId!, _editorContent);
        }
        return const Center(child: CircularProgressIndicator());
      },
      error: (e, st) => Center(child: Text('Error: $e')),
      data: (task) {
        if (task == null) {
          return const Center(child: Text('Task not found'));
        }
        _handleTaskLoaded(task);
        return _buildEditor(context, task.id!, _editorContent);
      },
    );
  }

  void _onSelectionChanged(int? newId) {
    // Save current task before switching
    _saveCurrentContent();
    _currentTaskId = newId;
    _autoSaveTimer?.cancel();

    if (newId == null) {
      _loadedTaskId = null;
      _currentContent = null;
      _lastLoadedContent = null;
      _hasUnsavedChanges = false;
      _publishModified();
    }
  }

  void _handleTaskLoaded(Task task) {
    final taskId = task.id as int;
    if (_loadedTaskId != taskId) {
      _loadedTaskId = taskId;
      // Prefer content from a still-in-flight save over the DB read, which
      // may predate that save when switching tasks back and forth quickly.
      _currentContent = _pendingSaves.containsKey(taskId)
          ? _pendingSaves[taskId]
          : task.content;
      _lastLoadedContent = _currentContent;
      _editorContent = _currentContent;
      _hasUnsavedChanges = false;
      _publishModified();
    } else if (!_hasUnsavedChanges &&
        !_pendingSaves.containsKey(taskId) &&
        task.content != _lastLoadedContent) {
      // The open task changed externally (e.g. a sync pulled remote edits)
      // — refresh the editor so stale content isn't re-saved over it.
      _currentContent = task.content;
      _lastLoadedContent = _currentContent;
      _editorContent = _currentContent;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.edit_note,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Select a task to edit',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(BuildContext context, int taskId, String? html) {
    // Toggled from the status bar, which sits below this panel in MainScreen.
    //
    // Phones have no status bar on the task screen and therefore no toggles:
    // there the sections are tabs of their own beside this one (see
    // [TaskEditorScreen]), so appending them here would show them twice — and
    // with no way to put them away again.
    final sectionsHere = !isCompactLayout(context);
    final timeExpanded = ref.watch(timeSectionExpandedProvider) && sectionsHere;
    final attachmentsExpanded =
        ref.watch(attachmentsSectionExpandedProvider) && sectionsHere;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Rich text content editor - reused across tasks, content updates via didUpdateWidget
        Expanded(
          child: QuillEditorWrapper(
            initialContent: html,
            contentKey: taskId,
            taskId: taskId,
            hintText: 'Start typing...',
            focusNode: _editorFocusNode,
            onContentChanged: _onContentChanged,
          ),
        ),
        // Time tracking stats — only while expanded from the status bar
        if (timeExpanded) TimeStatsPanel(taskId: taskId),
        // Attachments list — only while expanded from the status bar
        if (attachmentsExpanded) AttachmentsPanel(taskId: taskId),
      ],
    );
  }

  /// Called when Quill editor content changes
  void _onContentChanged(String content) {
    _currentContent = content;
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    if (!mounted) return;

    // Only call setState if state actually changed (avoid unnecessary rebuilds)
    if (!_hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = true;
      });
      _publishModified();
    }

    final autoSaveInterval = ref.read(settingsProvider).autoSaveIntervalSeconds;

    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(
      Duration(seconds: autoSaveInterval),
      _saveTask,
    );
  }

  /// Synchronously captures content and starts an async save in the background.
  /// Does not block the UI — the new task renders immediately while the save
  /// runs. Errors surface via a SnackBar.
  void _saveCurrentContent({bool notifyErrors = true}) {
    if (_loadedTaskId == null || !_hasUnsavedChanges) return;

    // Cached handle, not ref.read: this also runs from dispose, where ref is
    // no longer usable.
    final db = _db;
    if (db == null) return;

    final taskIdToSave = _loadedTaskId!;
    final contentToSave = _currentContent;
    // Skip the ancestor lookup when called from dispose — looking up a
    // deactivated widget's ancestor asserts in debug builds.
    final messenger =
        notifyErrors && mounted ? ScaffoldMessenger.maybeOf(context) : null;

    _lastLoadedContent = contentToSave;
    _hasUnsavedChanges = false;
    _publishModified();
    _pendingSaves[taskIdToSave] = contentToSave;

    unawaited(() async {
      try {
        await db.updateTask(taskIdToSave, content: contentToSave);
        // Drop the provider's pre-write snapshot — see [_saveTask]. Safe to do
        // here even though this method is reached from `build` (via
        // [_onSelectionChanged]): the await above lands in a later event loop
        // turn, so the frame is long finished.
        if (mounted) ref.invalidate(taskByIdProvider(taskIdToSave));
      } catch (e) {
        messenger?.showSnackBar(
          SnackBar(content: Text('Failed to save task: $e')),
        );
      } finally {
        // Only clear if no newer save for the same task superseded this one
        if (_pendingSaves[taskIdToSave] == contentToSave) {
          _pendingSaves.remove(taskIdToSave);
        }
      }
    }());
  }

  Future<void> _saveTask() async {
    if (_loadedTaskId == null || !_hasUnsavedChanges) return;

    final taskIdToSave = _loadedTaskId!;
    final contentToSave = _currentContent;

    final db = _db;
    if (db == null) return;

    _pendingSaves[taskIdToSave] = contentToSave;
    try {
      await db.updateTask(taskIdToSave, content: contentToSave);
    } finally {
      if (_pendingSaves[taskIdToSave] == contentToSave) {
        _pendingSaves.remove(taskIdToSave);
      }
    }

    if (mounted) {
      // [taskByIdProvider] is a FutureProvider, so `task.content` is whatever
      // was read at the last invalidation — it does not re-read after a write.
      // Leaving that snapshot in place makes the next rebuild read this very
      // save back as an *external* change: `_lastLoadedContent` has just moved
      // to the new text and `_hasUnsavedChanges` has just been cleared, so
      // every clause of the guard in [_handleTaskLoaded] passes and the editor
      // is rolled back to the pre-save content, losing whatever was typed.
      ref.invalidate(taskByIdProvider(taskIdToSave));

      setState(() {
        _lastLoadedContent = contentToSave;
        // Only mark the editor clean if nothing was typed while the write was
        // in flight. Clearing the flag unconditionally would strand those
        // keystrokes: the auto-save timer rescheduled by _onContentChanged
        // returns early on !_hasUnsavedChanges, so they'd never reach disk.
        if (_currentContent == contentToSave) {
          _hasUnsavedChanges = false;
        }
      });
      _publishModified();
    }
  }
}
