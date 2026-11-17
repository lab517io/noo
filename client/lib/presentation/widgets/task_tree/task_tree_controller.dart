import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';

import '../../../data/database/database.dart';
import '../../../data/services/ui_state_store.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/entities/world_id.dart';
import 'tree_node.dart';

/// The keyboard/menu moves of a single task within the tree. Drag and drop
/// covers the arbitrary case; these are the steps that are awkward to drag.
enum TaskMove {
  /// Swap with the sibling above.
  up,

  /// Swap with the sibling below.
  down,

  /// Out of the parent, to just after it (outdent).
  toParentLevel,

  /// Into the sibling above, as its last child (indent).
  underPrevious,
}

/// Controller for managing the hierarchical task tree.
/// Handles loading, expanding/collapsing, and CRUD operations.
class TaskTreeController extends ChangeNotifier {
  final NooDatabase _db;

  /// Root nodes of the tree (top-level tasks)
  final List<TaskTreeNode> roots = [];

  /// Map of task ID to tree node for quick lookup
  final Map<int, TaskTreeNode> _nodeMap = {};

  /// Map of world id to tree node, the sync-stable counterpart of [_nodeMap].
  /// Only non-deleted nodes are in here — [loadTree] never builds nodes for
  /// removed tasks — which is what makes a missing entry mean "gone".
  final Map<String, TaskTreeNode> _worldMap = {};

  /// The TreeController from flutter_fancy_tree_view
  late final TreeController<TaskTreeNode> treeController;

  /// Whether initial load is complete
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  /// Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Persisted expansion/focus state for this database.
  final UiStateStore _uiStore;

  /// Whether the persisted UI state has been applied. Guards the saver so a
  /// save scheduled before the first load can't overwrite the stored state
  /// with an empty tree.
  bool _uiStateRestored = false;

  /// Last known focus path (root→node world ids). Kept so a transient
  /// deselection — closing a database clears the selection just before the
  /// controller is torn down — does not erase the stored focus.
  List<String> _lastSelectedPath = const <String>[];

  /// Coalescing guard for [scheduleUiStateSave]: one write at a time, and at
  /// most one more queued behind it.
  bool _saveInFlight = false;
  bool _saveQueued = false;

  /// Reads the currently focused task id. Supplied by the presentation layer,
  /// which owns the selection state; null while nothing has registered.
  int? Function()? selectionReader;

  /// Called when a reload determines the focus must move: with the nearest
  /// surviving ancestor of a focused node that has disappeared, with the node
  /// restored from persisted state on the first load, or with null when
  /// neither is available.
  void Function(int? taskId)? onSelectionChangeRequired;

  TaskTreeController(this._db) : _uiStore = UiStateStore(_db) {
    treeController = TreeController<TaskTreeNode>(
      roots: roots,
      childrenProvider: (node) => node.children,
    );
  }

  /// Set by [dispose]. Every await in [loadTree] and the UI-state writer
  /// checks it: the provider that owns this controller fires `loadTree` and
  /// forgets it, and a database swap disposes the controller while those
  /// queries are still in flight. Without the flag the continuation queries
  /// the closed database, notifies a disposed notifier (an assert in debug),
  /// and can write session state through a database that is no longer open.
  bool _disposed = false;

  /// Load the entire task tree from the database
  Future<void> loadTree() async {
    if (_isLoading || _disposed) return;

    _isLoading = true;
    notifyListeners();

    int? selectionRequest;
    var selectionChangeRequired = false;

    try {
      // Expansion state is keyed by node identity in the tree controller, and
      // we recreate every node below, so capture which task ids are currently
      // expanded and re-apply them to the fresh nodes afterwards. Otherwise
      // every reload (e.g. after a sync) would silently collapse the tree.
      final expandedIds = <int>{};
      for (final entry in _nodeMap.entries) {
        if (treeController.getExpansionState(entry.value)) {
          expandedIds.add(entry.key);
        }
      }

      // The focused node may not survive this reload — a sync applies remote
      // deletions, and deleted tasks are not part of the tree. Capture its
      // ancestry while the old nodes are still around, so the focus can fall
      // back to the nearest ancestor that is still there.
      final previousSelection = selectionReader?.call();
      final previousSelectionPath = _worldIdPath(previousSelection);

      roots.clear();
      _nodeMap.clear();
      _worldMap.clear();
      // Drop the now-stale node instances from the controller's expansion set.
      treeController.toggledNodes.clear();

      // Load top-level tasks
      final topTasks = await _db.getTopLevelTasks();
      if (_disposed) return;

      for (final row in topTasks) {
        final node = _createNodeFromRow(row);
        roots.add(node);
        _index(node);

        // Load children recursively
        await _loadChildren(node);
        if (_disposed) return;
      }

      // Restore expansion state onto the freshly created nodes.
      for (final id in expandedIds) {
        final node = _nodeMap[id];
        if (node != null) treeController.setExpansionState(node, true);
      }

      // First load of this database: apply what the previous session left
      // behind. World ids that no longer resolve are simply skipped.
      if (!_uiStateRestored) {
        _uiStateRestored = true;
        final saved = await _uiStore.load();
        if (_disposed) return;
        if (saved != null) {
          for (final worldId in saved.expanded) {
            final node = _worldMap[worldId];
            if (node != null) treeController.setExpansionState(node, true);
          }
          _lastSelectedPath = saved.selectedPath;
          if (previousSelection == null) {
            final restored = _resolveWorldIdPath(saved.selectedPath);
            if (restored != null) {
              _expandAncestors(restored);
              selectionRequest = restored;
              selectionChangeRequired = true;
            }
          }
        }
      }

      // The focused node is gone (deleted here, or by a sync that pulled a
      // remote deletion): move the focus to the nearest surviving ancestor
      // rather than leave it dangling on a row the tree no longer shows. The
      // editor follows the selection, and a soft-deleted task still reads back
      // from the database, so without this it would keep editing — and
      // re-saving — a deleted task.
      if (previousSelection != null &&
          !_nodeMap.containsKey(previousSelection)) {
        selectionRequest = _resolveWorldIdPath(previousSelectionPath);
        selectionChangeRequired = true;
        if (selectionRequest != null) _expandAncestors(selectionRequest);
      }

      // `roots` is the same List instance the tree controller already holds, so
      // assigning `treeController.roots = roots` short-circuits (identity check)
      // and would not rebuild. Notify the controller explicitly so the tree
      // view regenerates its flattened node list and reflects structural
      // changes such as children added by a sync.
      treeController.rebuild();

      _isLoaded = true;
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }

    // Outside the loading guard: the presentation layer writes the new
    // selection back, which in turn schedules a UI-state save.
    if (selectionChangeRequired && !_disposed) {
      onSelectionChangeRequired?.call(selectionRequest);
    }
  }

  /// Load children for a node recursively
  Future<void> _loadChildren(TaskTreeNode parent) async {
    if (parent.id == null) return;

    final childRows = await _db.getChildTasks(parent.id!);

    for (final row in childRows) {
      final childNode = _createNodeFromRow(row);
      parent.addChild(childNode);
      _index(childNode);

      // Recursively load grandchildren
      await _loadChildren(childNode);
    }

    parent.childrenLoaded = true;
  }

  /// Create a TaskTreeNode from a database row
  TaskTreeNode _createNodeFromRow(TaskRow row) {
    final task = Task(
      id: row.id,
      parentId: row.parentId,
      worldId: WorldId.fromString(row.worldId),
      title: row.title,
      index: row.orderId,
      flags: row.flags,
    );
    return TaskTreeNode(task: task);
  }

  /// Find a node by task ID
  TaskTreeNode? findNode(int taskId) => _nodeMap[taskId];

  /// Register [node] in both lookup maps.
  void _index(TaskTreeNode node) {
    _nodeMap[node.id!] = node;
    _worldMap[node.task.worldId.value] = node;
  }

  /// Register [updated] in place of [old], an earlier instance of the same
  /// task.
  ///
  /// The tree controller keys expansion by node *identity*, and nodes are
  /// immutable wrappers that get replaced whenever their task changes. Without
  /// carrying the state across, moving an expanded node — or renumbering the
  /// siblings a move displaced — silently collapses it.
  void _supersede(TaskTreeNode old, TaskTreeNode updated) {
    if (treeController.getExpansionState(old)) {
      treeController.setExpansionState(old, false);
      treeController.setExpansionState(updated, true);
    }
    _index(updated);
  }

  /// Root→node world ids for [taskId]; empty when it is not in the tree.
  List<String> _worldIdPath(int? taskId) {
    if (taskId == null) return const <String>[];
    final node = _nodeMap[taskId];
    if (node == null) return const <String>[];

    final path = <String>[node.task.worldId.value];
    var parentId = node.parentId;
    while (parentId != null) {
      final parent = _nodeMap[parentId];
      if (parent == null) break;
      path.insert(0, parent.task.worldId.value);
      parentId = parent.parentId;
    }
    return path;
  }

  /// Task id of the deepest node of [path] that still exists, or null when the
  /// whole chain is gone. Walking from the tail is what turns a deleted focus
  /// into "focus its closest surviving ancestor".
  int? _resolveWorldIdPath(List<String> path) {
    for (var i = path.length - 1; i >= 0; i--) {
      final id = _worldMap[path[i]]?.id;
      if (id != null) return id;
    }
    return null;
  }

  /// Expand every ancestor of [taskId] without rebuilding — used inside
  /// [loadTree], which rebuilds once at the end.
  void _expandAncestors(int taskId) {
    var parentId = _nodeMap[taskId]?.parentId;
    while (parentId != null) {
      final parent = _nodeMap[parentId];
      if (parent == null) break;
      treeController.setExpansionState(parent, true);
      parentId = parent.parentId;
    }
  }

  /// Persist the expansion set and the focused node.
  ///
  /// Deliberately not debounced on a timer: the write is a single-row upsert,
  /// and a pending timer would be one more thing that has to survive a crash,
  /// a database swap and a widget test. Instead, overlapping calls collapse —
  /// while a write runs, further requests set a flag and one more write runs
  /// afterwards with whatever the state is by then.
  void scheduleUiStateSave() {
    if (!_uiStateRestored) return;
    if (_saveInFlight) {
      _saveQueued = true;
      return;
    }
    unawaited(_runQueuedSaves());
  }

  Future<void> _runQueuedSaves() async {
    _saveInFlight = true;
    try {
      do {
        _saveQueued = false;
        await _persistUiState();
      } while (_saveQueued && !_disposed);
    } finally {
      _saveInFlight = false;
    }
  }

  /// Write the UI state now, on the shutdown paths.
  Future<void> flushUiState() => _persistUiState();

  Future<void> _persistUiState() async {
    if (!_uiStateRestored || _disposed) return;

    final selectedPath = _worldIdPath(selectionReader?.call());
    // An empty path means "nothing focused right now", which happens while a
    // database is being closed and when the focused node was just deleted.
    // Neither is a reason to forget where the user was, so keep the last known
    // path — on restore it resolves to the nearest surviving ancestor.
    if (selectedPath.isNotEmpty) _lastSelectedPath = selectedPath;

    final expanded = <String>[];
    for (final entry in _worldMap.entries) {
      if (treeController.getExpansionState(entry.value)) expanded.add(entry.key);
    }

    await _uiStore.save(
      TreeUiState(expanded: expanded, selectedPath: _lastSelectedPath),
    );
  }

  /// Create a new task
  /// If parentId is null, creates at top level.
  /// Returns the ID of the new task.
  Future<int> createTask({int? parentId, int? insertIndex}) async {
    final worldId = WorldId.create();

    // Determine the order index
    final siblings = parentId == null
        ? roots
        : _nodeMap[parentId]?.children ?? [];
    final index = insertIndex ?? siblings.length;

    // Insert into database
    final newId = await _db.createTask(
      parentId: parentId,
      worldId: worldId.toString(),
      orderId: index,
      title: '',
    );

    // Create the node
    final task = Task(
      id: newId,
      parentId: parentId,
      worldId: worldId,
      title: '',
      index: index,
    );
    final newNode = TaskTreeNode(task: task, childrenLoaded: true);
    _index(newNode);

    // Insert into tree
    if (parentId == null) {
      if (index >= roots.length) {
        roots.add(newNode);
      } else {
        roots.insert(index, newNode);
      }
    } else {
      final parentNode = _nodeMap[parentId];
      if (parentNode != null) {
        if (index >= parentNode.children.length) {
          parentNode.addChild(newNode);
        } else {
          parentNode.children.insert(index, newNode);
        }
        // Ensure parent is expanded to show new child
        treeController.expand(parentNode);
      }
    }

    // A mid-list insert shifts the following siblings; persist their new
    // orderIds so the order survives a reload (otherwise the new task and
    // the one it displaced share the same orderId).
    if (index < siblings.length - 1) {
      await _updateSiblingIndices(parentId);
    }

    // Rebuild tree controller
    treeController.rebuild();
    notifyListeners();

    return newId;
  }

  /// Create a child task under the given parent
  Future<int> createChildTask(int parentId) async {
    return createTask(parentId: parentId);
  }

  /// Create a sibling task after the given task
  Future<int> createSiblingTask(int siblingId) async {
    final sibling = _nodeMap[siblingId];
    if (sibling == null) {
      return createTask();
    }

    final parentId = sibling.parentId;
    final siblings = parentId == null ? roots : _nodeMap[parentId]?.children ?? [];
    final currentIndex = siblings.indexWhere((n) => n.id == siblingId);
    final insertIndex = currentIndex >= 0 ? currentIndex + 1 : siblings.length;

    return createTask(parentId: parentId, insertIndex: insertIndex);
  }

  /// Delete a task (soft delete)
  Future<void> deleteTask(int taskId) async {
    final node = _nodeMap[taskId];
    if (node == null) return;

    // Delete from database
    await _db.deleteTask(taskId);

    // Remove from tree
    final parentId = node.parentId;
    if (parentId == null) {
      roots.removeWhere((n) => n.id == taskId);
    } else {
      _nodeMap[parentId]?.removeChild(taskId);
    }

    // Remove from map (and all descendants)
    _removeFromMap(node);

    // Rebuild tree controller
    treeController.rebuild();
    notifyListeners();
  }

  /// Remove a node and all descendants from the maps
  void _removeFromMap(TaskTreeNode node) {
    if (node.id != null) {
      _nodeMap.remove(node.id);
      _worldMap.remove(node.task.worldId.value);
    }
    for (final child in node.children) {
      _removeFromMap(child);
    }
  }

  /// Update a task's title in memory only (for live preview while typing)
  void updateTaskTitleInMemory(int taskId, String title) {
    final node = _nodeMap[taskId];
    if (node != null) {
      final updatedTask = node.task.copyWith(title: title);
      final updatedNode = node.copyWithTask(updatedTask);

      // Replace in parent's children or roots
      _replaceNode(node, updatedNode);

      treeController.rebuild();
      notifyListeners();
    }
  }

  /// Update a task's title (saves to database)
  Future<void> updateTaskTitle(int taskId, String title) async {
    await _db.updateTask(taskId, title: title);

    // Also update in memory if not already done
    final node = _nodeMap[taskId];
    if (node != null && node.task.title != title) {
      final updatedTask = node.task.copyWith(title: title);
      final updatedNode = node.copyWithTask(updatedTask);

      // Replace in parent's children or roots
      _replaceNode(node, updatedNode);

      treeController.rebuild();
      notifyListeners();
    }
  }

  /// Replace a node with an updated version
  void _replaceNode(TaskTreeNode oldNode, TaskTreeNode newNode) {
    if (oldNode.id == null) return;

    final parentId = oldNode.parentId;
    if (parentId == null) {
      final index = roots.indexWhere((n) => n.id == oldNode.id);
      if (index >= 0) {
        roots[index] = newNode;
      }
    } else {
      final parent = _nodeMap[parentId];
      if (parent != null) {
        final index = parent.children.indexWhere((n) => n.id == oldNode.id);
        if (index >= 0) {
          parent.children[index] = newNode;
        }
      }
    }

    _supersede(oldNode, newNode);
  }

  /// Expand a node
  void expand(TaskTreeNode node) {
    treeController.expand(node);
    scheduleUiStateSave();
    notifyListeners();
  }

  /// Collapse a node
  void collapse(TaskTreeNode node) {
    treeController.collapse(node);
    scheduleUiStateSave();
    notifyListeners();
  }

  /// Toggle expand/collapse
  void toggleExpanded(TaskTreeNode node) {
    treeController.toggleExpansion(node);
    scheduleUiStateSave();
    notifyListeners();
  }

  /// Check if a node is expanded
  bool isExpanded(TaskTreeNode node) {
    return treeController.getExpansionState(node);
  }

  /// Expand all nodes
  void expandAll() {
    treeController.expandAll();
    scheduleUiStateSave();
    notifyListeners();
  }

  /// Collapse all nodes
  void collapseAll() {
    treeController.collapseAll();
    scheduleUiStateSave();
    notifyListeners();
  }

  /// Reveal a node in the tree by expanding all its ancestors.
  void revealNode(int taskId) {
    final node = _nodeMap[taskId];
    if (node == null) return;

    // Walk up the parent chain and collect ancestors
    final ancestors = <TaskTreeNode>[];
    int? currentParentId = node.parentId;
    while (currentParentId != null) {
      final parent = _nodeMap[currentParentId];
      if (parent == null) break;
      ancestors.add(parent);
      currentParentId = parent.parentId;
    }

    // Expand from root down to immediate parent
    for (final ancestor in ancestors.reversed) {
      treeController.expand(ancestor);
    }

    treeController.rebuild();
    scheduleUiStateSave();
    notifyListeners();
  }

  /// Refresh the tree from database
  Future<void> refresh() async {
    await loadTree();
  }

  /// Move a task to a new location
  /// [taskId] - the task to move
  /// [newParentId] - the new parent (null for root level)
  /// [newIndex] - the position within the new parent's children
  Future<bool> moveTask(int taskId, int? newParentId, int newIndex) async {
    final node = _nodeMap[taskId];
    if (node == null) return false;

    // Prevent moving a node into itself or its descendants
    if (newParentId != null) {
      if (taskId == newParentId) return false;
      if (_isDescendant(taskId, newParentId)) return false;
    }

    final oldParentId = node.parentId;

    // Remove from old location (by ID, not reference)
    final oldSiblings =
        oldParentId == null ? roots : _nodeMap[oldParentId]?.children;
    final removalIndex =
        oldSiblings?.indexWhere((n) => n.id == taskId) ?? -1;
    oldSiblings?.removeWhere((n) => n.id == taskId);

    // The drop index was computed against the sibling list that still
    // contained the dragged node. After removal, positions past the old
    // slot shift left by one — without this, moving a node down within
    // the same parent lands one position too far.
    if (oldParentId == newParentId &&
        removalIndex >= 0 &&
        removalIndex < newIndex) {
      newIndex -= 1;
    }

    // Update the node's parent reference
    final updatedTask = node.task.copyWith(
      parentId: newParentId,
      index: newIndex,
    );
    final updatedNode = TaskTreeNode(
      task: updatedTask,
      children: node.children,
      childrenLoaded: node.childrenLoaded,
    );
    _supersede(node, updatedNode);

    // Insert at new location
    final newSiblings = newParentId == null ? roots : _nodeMap[newParentId]?.children;
    if (newSiblings != null) {
      final clampedIndex = newIndex.clamp(0, newSiblings.length);
      newSiblings.insert(clampedIndex, updatedNode);

      // Expand new parent if needed
      if (newParentId != null) {
        final newParent = _nodeMap[newParentId];
        if (newParent != null) {
          treeController.expand(newParent);
        }
      }
    }

    // Update database
    await _db.updateTask(
      taskId,
      parentId: newParentId,
      clearParent: newParentId == null,
      orderId: newIndex,
    );

    // Update order indices for old siblings
    await _updateSiblingIndices(oldParentId);

    // Update order indices for new siblings
    if (oldParentId != newParentId) {
      await _updateSiblingIndices(newParentId);
    }

    // Rebuild tree
    treeController.rebuild();
    notifyListeners();

    return true;
  }

  /// Whether [move] would change anything for [taskId].
  bool canMove(int taskId, TaskMove move) => switch (move) {
        TaskMove.up => canMoveUp(taskId),
        TaskMove.down => canMoveDown(taskId),
        TaskMove.toParentLevel => canMoveToParentLevel(taskId),
        TaskMove.underPrevious => canMoveUnderPrevious(taskId),
      };

  /// Apply [move] to [taskId]; false when it was not possible.
  Future<bool> move(int taskId, TaskMove move) => switch (move) {
        TaskMove.up => moveUp(taskId),
        TaskMove.down => moveDown(taskId),
        TaskMove.toParentLevel => moveToParentLevel(taskId),
        TaskMove.underPrevious => moveUnderPrevious(taskId),
      };

  /// Position of [taskId] among its siblings, or -1 when it is not in the tree.
  int _siblingIndex(int taskId) =>
      getSiblings(taskId).indexWhere((n) => n.id == taskId);

  /// Whether [moveUp] would do anything: the task is not already first.
  bool canMoveUp(int taskId) => _siblingIndex(taskId) > 0;

  /// Whether [moveDown] would do anything: the task is not already last.
  bool canMoveDown(int taskId) {
    final index = _siblingIndex(taskId);
    return index >= 0 && index < getSiblings(taskId).length - 1;
  }

  /// Whether [moveToParentLevel] would do anything: the task is not top-level.
  bool canMoveToParentLevel(int taskId) => _nodeMap[taskId]?.parentId != null;

  /// Whether [moveUnderPrevious] would do anything: there is a sibling above
  /// to become the parent.
  bool canMoveUnderPrevious(int taskId) => canMoveUp(taskId);

  /// Swap the task with the sibling above it.
  Future<bool> moveUp(int taskId) async {
    final node = _nodeMap[taskId];
    if (node == null || !canMoveUp(taskId)) return false;
    return moveTask(taskId, node.parentId, _siblingIndex(taskId) - 1);
  }

  /// Swap the task with the sibling below it.
  Future<bool> moveDown(int taskId) async {
    final node = _nodeMap[taskId];
    if (node == null || !canMoveDown(taskId)) return false;
    // moveTask takes the index in the list *before* the node is removed from
    // it, so "after the next sibling" is two slots further, not one.
    return moveTask(taskId, node.parentId, _siblingIndex(taskId) + 2);
  }

  /// Lift the task out of its parent, placing it right after that parent —
  /// the same spot an outliner's outdent puts it, so the task stays next to
  /// the context it came from rather than jumping to the end of the level.
  Future<bool> moveToParentLevel(int taskId) async {
    final parentId = _nodeMap[taskId]?.parentId;
    if (parentId == null) return false;
    final parent = _nodeMap[parentId];
    if (parent == null) return false;
    return moveTask(taskId, parent.parentId, _siblingIndex(parentId) + 1);
  }

  /// Make the task the last child of the sibling above it — an outliner's
  /// indent, and the exact inverse of [moveToParentLevel] for a last child.
  Future<bool> moveUnderPrevious(int taskId) async {
    if (!canMoveUnderPrevious(taskId)) return false;
    final previous = getSiblings(taskId)[_siblingIndex(taskId) - 1];
    if (previous.id == null) return false;
    return moveTask(taskId, previous.id, previous.children.length);
  }

  /// Check if potentialDescendant is a descendant of ancestorId
  bool _isDescendant(int ancestorId, int potentialDescendantId) {
    final ancestor = _nodeMap[ancestorId];
    if (ancestor == null) return false;

    bool checkChildren(TaskTreeNode node) {
      for (final child in node.children) {
        if (child.id == potentialDescendantId) return true;
        if (checkChildren(child)) return true;
      }
      return false;
    }

    return checkChildren(ancestor);
  }

  /// Update the order indices of all siblings after a move
  Future<void> _updateSiblingIndices(int? parentId) async {
    final siblings = parentId == null ? roots : _nodeMap[parentId]?.children ?? [];

    for (int i = 0; i < siblings.length; i++) {
      final sibling = siblings[i];
      if (sibling.id != null && sibling.task.index != i) {
        // Update in memory
        final updatedTask = sibling.task.copyWith(index: i);
        final updatedNode = TaskTreeNode(
          task: updatedTask,
          children: sibling.children,
          childrenLoaded: sibling.childrenLoaded,
        );
        siblings[i] = updatedNode;
        _supersede(sibling, updatedNode);

        // Update in database
        await _db.updateTask(sibling.id!, orderId: i);
      }
    }
  }

  /// Get the parent node for a task
  TaskTreeNode? getParent(int taskId) {
    final node = _nodeMap[taskId];
    if (node?.parentId == null) return null;
    return _nodeMap[node!.parentId!];
  }

  /// Get siblings (including self) for a task
  List<TaskTreeNode> getSiblings(int taskId) {
    final node = _nodeMap[taskId];
    if (node == null) return [];
    if (node.parentId == null) return roots;
    return _nodeMap[node.parentId!]?.children ?? [];
  }

  @override
  void dispose() {
    _disposed = true;
    treeController.dispose();
    super.dispose();
  }
}
