import 'package:flutter/widgets.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'value_controller.dart';
import '../../data/database/database.dart';
import '../../data/repositories/attachment_repository_impl.dart';
import '../../data/services/database_manager.dart';
import '../../data/services/history_service.dart';
import '../../data/services/secure_storage_service.dart';
import '../../domain/entities/attachment.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/time_line.dart';
import '../../domain/entities/time_record.dart';
import '../../domain/entities/world_id.dart';
import '../../domain/repositories/attachment_repository.dart';
import '../widgets/task_tree/task_tree_controller.dart';

export '../../domain/entities/world_id.dart';
export '../providers/sync_provider.dart';

/// Database manager provider - handles database lifecycle
class DatabaseManagerNotifier extends Notifier<DatabaseManager> {
  @override
  DatabaseManager build() {
    final manager = DatabaseManager();
    // Bridge ChangeNotifier updates to Riverpod so dependents rebuild.
    void listener() => ref.notifyListeners();
    manager.addListener(listener);
    ref.onDispose(() {
      manager.removeListener(listener);
      manager.dispose();
    });
    // Initialize is called from main.dart before runApp
    return manager;
  }
}

final databaseManagerProvider =
    NotifierProvider<DatabaseManagerNotifier, DatabaseManager>(
  DatabaseManagerNotifier.new,
);

/// Database provider - gets current database from manager (nullable during transition)
final databaseProvider = Provider<NooDatabase?>((ref) {
  final manager = ref.watch(databaseManagerProvider);
  return manager.database;
});

/// Provider that indicates if database is ready
final isDatabaseReadyProvider = Provider<bool>((ref) {
  final manager = ref.watch(databaseManagerProvider);
  return manager.isOpen && !manager.isLoading;
});

/// Current database file path
final currentDatabasePathProvider = Provider<String?>((ref) {
  final manager = ref.watch(databaseManagerProvider);
  return manager.currentPath;
});

/// Current database file name (just the filename)
final currentDatabaseFileNameProvider = Provider<String?>((ref) {
  final manager = ref.watch(databaseManagerProvider);
  return manager.currentFileName;
});

/// Task tree controller provider - manages hierarchical task tree
/// Returns null if database is not ready
class TaskTreeControllerNotifier extends Notifier<TaskTreeController?> {
  @override
  TaskTreeController? build() {
    final db = ref.watch(databaseProvider);
    if (db == null) return null;

    final controller = TaskTreeController(db);

    // The controller persists the focused node along with the expansion set,
    // and has to repair the focus when a reload finds it deleted — but the
    // selection itself lives here, in a provider. Hand it a reader and a
    // writer instead of teaching it about Riverpod.
    controller.selectionReader = () {
      try {
        return ref.read(selectedTaskIdProvider);
      } catch (_) {
        return null; // Container torn down mid-flight.
      }
    };
    controller.onSelectionChangeRequired = (taskId) {
      try {
        ref.read(selectedTaskIdProvider.notifier).value = taskId;
      } catch (_) {
        // Same: nothing to select in a disposed container.
      }
    };
    // Moving through the tree changes the state worth restoring next launch.
    ref.listen(selectedTaskIdProvider, (_, _) => controller.scheduleUiStateSave());

    // Bridge ChangeNotifier updates to Riverpod so dependents rebuild.
    void listener() => ref.notifyListeners();
    controller.addListener(listener);
    // Disposed on rebuild (e.g. database swap) and on provider teardown.
    ref.onDispose(() {
      controller.removeListener(listener);
      controller.dispose();
    });

    // Load tree on first access
    controller.loadTree();

    return controller;
  }
}

final taskTreeControllerProvider =
    NotifierProvider<TaskTreeControllerNotifier, TaskTreeController?>(
  TaskTreeControllerNotifier.new,
);

/// Currently selected task ID
final selectedTaskIdProvider = valueProvider<int?>(null);

/// The task-creation entry points of the mounted task tree.
///
/// Creating a task is more than a database insert — the new task is selected,
/// revealed, and its title opened for inline renaming, all of which lives in
/// the tree panel's state. Publishing the callbacks lets app-level shortcuts
/// (Ctrl+N, Ctrl+Shift+N in [MainScreen]) go through exactly the same path as
/// the tree's own toolbar instead of reimplementing half of it.
class TaskCreationActions {
  const TaskCreationActions({
    required this.createTask,
    required this.createChildTask,
  });

  /// Create a top-level task.
  final Future<void> Function() createTask;

  /// Create a child of the selected task. Does nothing when nothing is
  /// selected, mirroring the toolbar button being disabled in that state.
  final Future<void> Function() createChildTask;
}

/// Registered by the mounted task tree; null when no tree is on screen.
final taskCreationProvider = valueProvider<TaskCreationActions?>(null);

/// Active time tracking task ID
final activeTrackingTaskIdProvider = valueProvider<int?>(null);

/// Whether time tracking is active
final isTrackingProvider = Provider<bool>((ref) {
  return ref.watch(activeTrackingTaskIdProvider) != null;
});

/// Start time of the active tracking session (UTC)
final activeTrackingStartTimeProvider = valueProvider<DateTime?>(null);

/// Database ID of the open-ended time record backing the active tracking
/// session. The record is created at start (endTime = null) and finalized at
/// stop, so a crash or exit never loses the interval.
final activeTrackingRecordIdProvider = valueProvider<int?>(null);

/// Notifier to trigger timeline reload in time stats panels
final timelineRefreshProvider = valueProvider<int>(0);

/// Time records of a single task, reloaded whenever [timelineRefreshProvider]
/// ticks. Shared by the editor status bar (which shows today's total even while
/// the section is collapsed) and the expanded stats panel, so both always read
/// the same records instead of each running its own loader.
final taskTimelineProvider =
    FutureProvider.autoDispose.family<TimeLine, int>((ref, taskId) async {
  ref.watch(timelineRefreshProvider);
  final db = ref.watch(databaseProvider);
  if (db == null) return const TimeLine();

  final entries = await db.getTimelineForTask(taskId);
  return TimeLine(
    records: entries
        .map((e) => TimeRecord(
              id: e.id,
              taskId: e.taskId,
              worldId: WorldId.fromString(e.worldId),
              startTime: DateTime.parse(e.startTime).toUtc(),
              endTime:
                  e.endTime != null ? DateTime.parse(e.endTime!).toUtc() : null,
              saved: true,
            ))
        .toList(),
  );
});

/// Whether the editor's time-tracking / attachments sections are expanded above
/// the status bar. Held in providers because the toggles live in the status bar
/// — a sibling of the editor — while the section bodies render inside it.
final timeSectionExpandedProvider = valueProvider<bool>(false);
final attachmentsSectionExpandedProvider = valueProvider<bool>(false);

/// Whether the open task has edits that haven't reached the database yet.
/// Published by the task editor for the status bar's modified indicator.
final editorModifiedProvider = valueProvider<bool>(false);

/// Registered by the mounted task editor so a sync run can force any unsaved,
/// still-debounced content to disk before it reads the database. Without this,
/// text typed right before a manual sync (F5) sits behind the auto-save timer
/// and is missed by the run. Null when no editor is active.
final editorFlushProvider = valueProvider<Future<void> Function()?>(null);

/// The mounted task editor's focus node. Null when no editor is on screen.
///
/// Published so the widgets that legitimately take focus away — the search
/// panel, the tree's inline title editor — can hand it back when they close.
/// This matters more than it looks: flutter_quill paints the text selection
/// regardless of focus, while Ctrl+C/Ctrl+X are routed *by* focus. Leaving
/// focus stranded elsewhere therefore produces an editor that still shows a
/// highlighted selection but silently ignores copy.
final editorFocusProvider = valueProvider<FocusNode?>(null);

/// The mounted task editor's Quill controller. Null when no editor is on
/// screen.
///
/// Published for the same reason as [editorFocusProvider]: work that starts
/// outside the editor sometimes has to write into the open document. The
/// attachments panel's "Transcribe" is the case in point — it lives in a
/// sibling widget but its result belongs in the note.
///
final editorControllerProvider = valueProvider<QuillController?>(null);

/// Hands keyboard focus back to the task editor, if one is mounted.
///
/// Deferred to after the frame because callers invoke this while tearing down
/// the widget that currently holds focus; disposing a node that has primary
/// focus pushes focus to the enclosing scope, which would undo an immediate
/// request.
void restoreEditorFocus(WidgetRef ref) {
  final node = ref.read(editorFocusProvider);
  if (node == null) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (node.canRequestFocus) node.requestFocus();
  });
}

/// Top-level tasks provider (deprecated - use taskTreeControllerProvider instead)
final topLevelTasksProvider = FutureProvider<List<Task>>((ref) async {
  final db = ref.watch(databaseProvider);
  if (db == null) return [];

  final rows = await db.getTopLevelTasks();

  return rows.map((row) => Task(
    id: row.id,
    parentId: row.parentId,
    worldId: WorldId.fromString(row.worldId),
    title: row.title,
    index: row.orderId,
    flags: row.flags,
  )).toList();
});

/// Provider for child tasks of a specific parent
final childTasksProvider = FutureProvider.family<List<Task>, int>((ref, parentId) async {
  final db = ref.watch(databaseProvider);
  if (db == null) return [];

  final rows = await db.getChildTasks(parentId);

  return rows.map((row) => Task(
    id: row.id,
    parentId: row.parentId,
    worldId: WorldId.fromString(row.worldId),
    title: row.title,
    index: row.orderId,
    flags: row.flags,
  )).toList();
});

/// Provider for a single task by ID
final taskByIdProvider = FutureProvider.autoDispose.family<Task?, int>((ref, id) async {
  final db = ref.watch(databaseProvider);
  if (db == null) return null;

  final row = await db.getTaskById(id);
  if (row == null) return null;

  return Task(
    id: row.id,
    parentId: row.parentId,
    worldId: WorldId.fromString(row.worldId),
    title: row.title,
    content: row.content,
    index: row.orderId,
    flags: row.flags,
    contentLoaded: true,
  );
});

// ============================================================
// Attachment Providers
// ============================================================

/// Attachment repository provider
final attachmentRepositoryProvider = Provider<AttachmentRepository?>((ref) {
  final db = ref.watch(databaseProvider);
  if (db == null) return null;
  return AttachmentRepositoryImpl(db);
});

/// Provider for attachments of a specific task
final taskAttachmentsProvider = FutureProvider.family<List<Attachment>, int>((ref, taskId) async {
  ref.watch(attachmentRefreshProvider);
  final repo = ref.watch(attachmentRepositoryProvider);
  if (repo == null) return [];
  return repo.getAttachmentsForTask(taskId);
});

/// Provider for attachment count of a specific task. Watches the refresh tick
/// so the status bar badge follows adds and deletes even while the attachments
/// section is collapsed and the list provider isn't being read.
final attachmentCountProvider = FutureProvider.family<int, int>((ref, taskId) async {
  ref.watch(attachmentRefreshProvider);
  final repo = ref.watch(attachmentRepositoryProvider);
  if (repo == null) return 0;
  return repo.getAttachmentCount(taskId);
});

/// Notifier to trigger attachment list refresh
final attachmentRefreshProvider = valueProvider<int>(0);

// ============================================================
// History Providers
// ============================================================

/// History service provider - for change tracking and sync
final historyServiceProvider = Provider<HistoryService?>((ref) {
  final db = ref.watch(databaseProvider);
  if (db == null) return null;
  return HistoryService(db);
});

// ============================================================
// Secure Storage Providers
// ============================================================

/// Secure storage service provider - for storing sensitive data like passwords
final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

// ============================================================
// Initial Database Path Provider
// ============================================================

/// Initial database path from command line arguments (if specified)
/// This is overridden in main.dart when a path is passed as argument
final initialDatabasePathProvider = Provider<String?>((ref) => null);

// ============================================================
// Search Providers
// ============================================================

/// Whether the global search panel is visible
final searchVisibleProvider = valueProvider<bool>(false);

/// Current search query text
final searchQueryProvider = valueProvider<String>('');
