import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/fonts.dart';
import '../../../core/utils/menu_shortcuts.dart';
import '../../../core/utils/platform_info.dart';
import '../../providers/providers.dart';
import '../../screens/task_editor_screen.dart';
import '../../providers/settings_provider.dart';
import '../../providers/value_controller.dart';
import 'task_tree_controller.dart';
import 'tree_node.dart';

/// Drop position relative to a node
enum DropPosition {
  above,
  inside,
  below,
}

/// Panel displaying the hierarchical task tree with drag-and-drop support
class TaskTreePanel extends ConsumerStatefulWidget {
  const TaskTreePanel({super.key});

  @override
  ConsumerState<TaskTreePanel> createState() => _TaskTreePanelState();
}

class _TaskTreePanelState extends ConsumerState<TaskTreePanel> {
  /// Currently dragged node
  TaskTreeNode? _draggedNode;

  /// Current drop target node
  TaskTreeNode? _dropTargetNode;

  /// Current drop position
  DropPosition? _dropPosition;

  /// Task ID currently being edited inline
  int? _editingTaskId;

  /// Scroll position of the tree, needed to bring freshly created nodes into
  /// the sliver's build window — see [_scrollNodeIntoView].
  final ScrollController _scrollController = ScrollController();

  /// Whether the first selection this panel saw has been scrolled into view.
  /// The focus restored from the previous session is worth nothing if it sits
  /// below the fold, and the tree always starts scrolled to the top.
  bool _initialSelectionRevealed = false;

  /// Creation callbacks published for the app-level shortcuts, kept alongside
  /// the controller that holds them so dispose can unregister without `ref`.
  late final TaskCreationActions _creationActions;
  ValueController<TaskCreationActions?>? _creationController;

  /// The move entry point published for the app-level shortcuts; same
  /// ownership rules as [_creationActions].
  late final Future<void> Function(TaskMove) _moveAction;
  ValueController<Future<void> Function(TaskMove)?>? _moveController;

  /// Task whose row should scroll itself fully on screen once it is built —
  /// set after a move, since a keyboard move can carry the row out of view.
  int? _pendingRevealId;

  @override
  void initState() {
    super.initState();
    _creationActions = TaskCreationActions(
      createTask: _createTaskFromShortcut,
      createChildTask: _createChildTaskFromShortcut,
    );
    _moveAction = _moveSelectedFromShortcut;
    // Deferred to a post-frame callback so we don't mutate a provider during
    // the build phase (same reason as the editor panel's registrations).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _creationController = ref.read(taskCreationProvider.notifier);
      _creationController!.value = _creationActions;
      _moveController = ref.read(taskMoveProvider.notifier);
      _moveController!.value = _moveAction;
    });
  }

  @override
  void dispose() {
    try {
      // Unregister only if the registration is still ours — a replacement
      // panel may already have published its own callbacks.
      if (identical(_creationController?.value, _creationActions)) {
        _creationController!.value = null;
      }
      if (identical(_moveController?.value, _moveAction)) {
        _moveController!.value = null;
      }
    } catch (_) {
      // Container being torn down; nothing left to unregister from.
    }
    _scrollController.dispose();
    super.dispose();
  }

  /// Ctrl+N: a new top-level task.
  Future<void> _createTaskFromShortcut() async {
    final controller = ref.read(taskTreeControllerProvider);
    if (controller == null) return;
    await _createTask(ref, controller, null);
  }

  /// Ctrl+Shift+N: a new child of the selected task.
  Future<void> _createChildTaskFromShortcut() async {
    final controller = ref.read(taskTreeControllerProvider);
    final selectedId = ref.read(selectedTaskIdProvider);
    if (controller == null || selectedId == null) return;
    await _createChildTask(ref, controller, selectedId);
  }

  /// Alt+Shift+arrows (⌃⌘ on macOS): move the selected task.
  Future<void> _moveSelectedFromShortcut(TaskMove move) async {
    final controller = ref.read(taskTreeControllerProvider);
    final selectedId = ref.read(selectedTaskIdProvider);
    if (controller == null || selectedId == null) return;
    await _moveTask(controller, selectedId, move);
  }

  /// Move [taskId] and keep its row in sight: the new parent is expanded by
  /// the move itself, and the row is scrolled back on screen if the move took
  /// it past the edge of the viewport.
  Future<void> _moveTask(
    TaskTreeController controller,
    int taskId,
    TaskMove move,
  ) async {
    if (!await controller.move(taskId, move)) return;
    if (!mounted) return;
    controller.revealNode(taskId);
    setState(() => _pendingRevealId = taskId);
    _scrollNodeIntoView(controller, taskId);
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(taskTreeControllerProvider);
    final selectedId = ref.watch(selectedTaskIdProvider);

    // Show loading if controller is not ready
    if (controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_initialSelectionRevealed && controller.isLoaded && selectedId != null) {
      _initialSelectionRevealed = true;
      _scrollNodeIntoView(controller, selectedId);
    }

    return Column(
      children: [
        // Toolbar
        _buildToolbar(context, ref, controller, selectedId),
        const Divider(height: 1),
        // Task tree
        Expanded(
          child: _buildTree(context, ref, controller, selectedId),
        ),
      ],
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    WidgetRef ref,
    TaskTreeController controller,
    int? selectedId,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New task (Ctrl+N)',
            onPressed: () => _createTask(ref, controller, null),
            iconSize: 20,
          ),
          IconButton(
            icon: const Icon(Icons.subdirectory_arrow_right),
            tooltip: 'New child task (Ctrl+Shift+N)',
            onPressed: selectedId != null
                ? () => _createChildTask(ref, controller, selectedId)
                : null,
            iconSize: 20,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete task',
            onPressed: selectedId != null
                ? () => _deleteTask(ref, controller, selectedId)
                : null,
            iconSize: 20,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.unfold_more),
            tooltip: 'Expand all',
            onPressed: controller.roots.isNotEmpty
                ? () => controller.expandAll()
                : null,
            iconSize: 20,
          ),
          IconButton(
            icon: const Icon(Icons.unfold_less),
            tooltip: 'Collapse all',
            onPressed: controller.roots.isNotEmpty
                ? () => controller.collapseAll()
                : null,
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildTree(
    BuildContext context,
    WidgetRef ref,
    TaskTreeController controller,
    int? selectedId,
  ) {
    if (controller.isLoading && !controller.isLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.roots.isEmpty) {
      return _buildEmptyState(context, ref, controller);
    }

    return AnimatedTreeView<TaskTreeNode>(
      controller: _scrollController,
      treeController: controller.treeController,
      nodeBuilder: (context, entry) {
        return _DraggableTreeTile(
          key: ValueKey(entry.node.id),
          entry: entry,
          isSelected: entry.node.id == selectedId,
          isDragging: _draggedNode?.id == entry.node.id,
          isDropTarget: _dropTargetNode?.id == entry.node.id,
          dropPosition: _dropTargetNode?.id == entry.node.id ? _dropPosition : null,
          isEditing: _editingTaskId == entry.node.id,
          reveal: _pendingRevealId == entry.node.id,
          onRevealed: () => _pendingRevealId = null,
          onTap: () {
            ref.read(selectedTaskIdProvider.notifier).value = entry.node.id;
          },
          onOpen: isCompactLayout(context)
              ? () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TaskEditorScreen(),
                    ),
                  )
              : null,
          onToggleExpand: () {
            controller.toggleExpanded(entry.node);
          },
          onStartEdit: () {
            setState(() {
              _editingTaskId = entry.node.id;
            });
          },
          onEndEdit: () {
            setState(() {
              _editingTaskId = null;
            });
          },
          onTitleChanged: (newTitle) {
            if (entry.node.id != null) {
              controller.updateTaskTitle(entry.node.id!, newTitle);
            }
          },
          onDragStarted: () {
            setState(() {
              _draggedNode = entry.node;
            });
          },
          onDragEnd: () {
            setState(() {
              _draggedNode = null;
              _dropTargetNode = null;
              _dropPosition = null;
            });
          },
          onDragOver: (position) {
            if (_draggedNode == null) return;
            if (_draggedNode!.id == entry.node.id) return;

            setState(() {
              _dropTargetNode = entry.node;
              _dropPosition = position;
            });
          },
          onDrop: () async {
            if (_draggedNode == null || _dropTargetNode == null || _dropPosition == null) {
              return;
            }

            final draggedId = _draggedNode!.id;
            final targetNode = _dropTargetNode!;
            final position = _dropPosition!;

            if (draggedId == null || targetNode.id == null) return;

            int? newParentId;
            int newIndex;

            switch (position) {
              case DropPosition.above:
                // Insert as sibling above target
                newParentId = targetNode.parentId;
                final siblings = controller.getSiblings(targetNode.id!);
                newIndex = siblings.indexWhere((n) => n.id == targetNode.id);
                if (newIndex < 0) newIndex = 0;
                break;

              case DropPosition.inside:
                // Insert as first child of target
                newParentId = targetNode.id;
                newIndex = 0;
                break;

              case DropPosition.below:
                // Insert as sibling below target
                newParentId = targetNode.parentId;
                final siblings = controller.getSiblings(targetNode.id!);
                newIndex = siblings.indexWhere((n) => n.id == targetNode.id) + 1;
                if (newIndex <= 0) newIndex = siblings.length;
                break;
            }

            await controller.moveTask(draggedId, newParentId, newIndex);

            setState(() {
              _draggedNode = null;
              _dropTargetNode = null;
              _dropPosition = null;
            });
          },
          onCreateChild: () {
            if (entry.node.id != null) {
              _createChildTask(ref, controller, entry.node.id!);
            }
          },
          onDelete: () {
            if (entry.node.id != null) {
              _deleteTask(ref, controller, entry.node.id!);
            }
          },
          canMove: (move) =>
              entry.node.id != null && controller.canMove(entry.node.id!, move),
          onMove: (move) {
            if (entry.node.id != null) {
              _moveTask(controller, entry.node.id!, move);
            }
          },
        );
      },
      duration: const Duration(milliseconds: 200),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    TaskTreeController controller,
  ) {
    return DragTarget<TaskTreeNode>(
      onAcceptWithDetails: (details) async {
        // Move to root level at the end
        if (details.data.id != null) {
          await controller.moveTask(details.data.id!, null, controller.roots.length);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No tasks yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Create your first task'),
                onPressed: () => _createTask(ref, controller, null),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createTask(
    WidgetRef ref,
    TaskTreeController controller,
    int? parentId,
  ) async {
    if (parentId != null) await _revealParentBeforeInsert(controller, parentId);
    if (!mounted) return;
    final newId = await controller.createTask(parentId: parentId);
    _selectAndRename(ref, controller, newId);
  }

  Future<void> _createChildTask(
    WidgetRef ref,
    TaskTreeController controller,
    int parentId,
  ) async {
    await _revealParentBeforeInsert(controller, parentId);
    if (!mounted) return;
    final newId = await controller.createChildTask(parentId);
    _selectAndRename(ref, controller, newId);
  }

  /// Bring the parent's row into the list before it gains a child, and wait
  /// for the frame that builds it.
  ///
  /// Gaining a child expands the parent, and [AnimatedTreeView] only plays —
  /// and, more importantly, only ever *finishes* — that expand animation for a
  /// row it has already built. Expanding a row the lazy list never built leaves
  /// the node marked as animating for good, which keeps its whole subtree, the
  /// new child included, out of the tree. Scrolling to the parent first avoids
  /// the situation instead of trying to recover from it.
  Future<void> _revealParentBeforeInsert(
    TaskTreeController controller,
    int parentId,
  ) async {
    if (!_jumpNodeIntoBuildWindow(controller, parentId)) return;
    await WidgetsBinding.instance.endOfFrame;
  }

  /// Hand a freshly created task straight to the user: select it, make sure it
  /// is visible in the tree, and open its title for inline editing. A new task
  /// has no title, so without this it lands as an "Untitled" row that has to be
  /// found and double-clicked before it can be named.
  void _selectAndRename(
    WidgetRef ref,
    TaskTreeController controller,
    int taskId,
  ) {
    ref.read(selectedTaskIdProvider.notifier).value = taskId;
    controller.revealNode(taskId);
    if (!mounted) return;
    setState(() {
      _editingTaskId = taskId;
    });
    _scrollNodeIntoView(controller, taskId);
  }

  /// Distance beyond the viewport for which the sliver still builds rows
  /// (Flutter's default cache extent is 250). A node inside this band already
  /// has a tile, so it can scroll itself into view; one outside it does not
  /// exist yet and has to be reached by moving the scroll position first.
  static const double _tileBuildMargin = 200;

  /// Make sure the row for [taskId] ends up on screen.
  ///
  /// The tile performs the final, minimal scroll itself once it enters inline
  /// edit mode (see `_beginEdit`), which keeps the movement small and animated.
  /// That only works for rows the lazy list has actually built, so a node
  /// further away is first approached with a coarse jump, deferred to the end
  /// of the frame that adds the node to the tree.
  void _scrollNodeIntoView(TaskTreeController controller, int taskId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _jumpNodeIntoBuildWindow(controller, taskId);
    });
  }

  /// Scrolls the tree so the row for [taskId] falls inside the sliver's build
  /// window, and reports whether that required moving.
  ///
  /// The row's position is estimated from the average row extent — the list is
  /// lazy, so there is no laid-out row to measure until it is close enough to
  /// the viewport. The estimate only has to be good enough to get the row
  /// built; whoever needs it exactly can scroll from there.
  bool _jumpNodeIntoBuildWindow(TaskTreeController controller, int taskId) {
    if (!_scrollController.hasClients) return false;

    // Index of the node among the currently visible (expanded) rows, plus the
    // total row count used to derive the average extent.
    var index = -1;
    var rowCount = 0;
    controller.treeController.depthFirstTraversal(
      onTraverse: (entry) {
        if (entry.node.id == taskId) index = rowCount;
        rowCount++;
      },
    );
    if (index < 0 || rowCount == 0) return false;

    final position = _scrollController.position;
    final rowExtent =
        (position.maxScrollExtent + position.viewportDimension) / rowCount;
    final rowOffset = index * rowExtent;

    final builtFrom = position.pixels - _tileBuildMargin;
    final builtTo =
        position.pixels + position.viewportDimension + _tileBuildMargin;
    if (rowOffset >= builtFrom && rowOffset + rowExtent <= builtTo) {
      return false;
    }

    // Centre the estimated position rather than align it to an edge: the
    // estimate is off by a row or two on trees with uneven row heights, and a
    // centred target keeps the node inside the viewport regardless.
    _scrollController.jumpTo(
      (rowOffset - (position.viewportDimension - rowExtent) / 2)
          .clamp(position.minScrollExtent, position.maxScrollExtent),
    );
    return true;
  }

  Future<void> _deleteTask(
    WidgetRef ref,
    TaskTreeController controller,
    int taskId,
  ) async {
    // Capture the subtree ids before the nodes are removed — selection and
    // tracking may point at a descendant, not just the deleted task itself.
    final removedIds = <int>{};
    void collect(TaskTreeNode node) {
      final id = node.id;
      if (id != null) removedIds.add(id);
      for (final child in node.children) {
        collect(child);
      }
    }

    final node = controller.findNode(taskId);
    if (node != null) collect(node);

    // Stop tracking if the tracked task is inside the deleted subtree
    final trackedId = ref.read(activeTrackingTaskIdProvider);
    if (trackedId != null && removedIds.contains(trackedId)) {
      final db = ref.read(databaseProvider);
      final recordId = ref.read(activeTrackingRecordIdProvider);
      if (db != null && recordId != null) {
        await db.updateTimeRecord(
          recordId,
          endTime: DateTime.now().toUtc().toIso8601String(),
        );
      }
      ref.read(activeTrackingTaskIdProvider.notifier).value = null;
      ref.read(activeTrackingStartTimeProvider.notifier).value = null;
      ref.read(activeTrackingRecordIdProvider.notifier).value = null;
    }

    await controller.deleteTask(taskId);

    // Clear selection if the selected task was inside the deleted subtree
    final selectedId = ref.read(selectedTaskIdProvider);
    if (selectedId != null && removedIds.contains(selectedId)) {
      ref.read(selectedTaskIdProvider.notifier).value = null;
    }
  }
}

/// Draggable task tile in the tree
class _DraggableTreeTile extends ConsumerStatefulWidget {
  final TreeEntry<TaskTreeNode> entry;
  final bool isSelected;
  final bool isDragging;
  final bool isDropTarget;
  final DropPosition? dropPosition;
  final bool isEditing;
  final VoidCallback onTap;

  /// Compact layouts only: invoked on a completed tap (not pointer-down, so
  /// scroll gestures never trigger it) to navigate to the full-screen editor.
  /// Null on wide layouts, where the editor pane is always visible.
  final VoidCallback? onOpen;
  final VoidCallback onToggleExpand;
  final VoidCallback onStartEdit;
  final VoidCallback onEndEdit;
  final void Function(String) onTitleChanged;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;
  final void Function(DropPosition) onDragOver;
  final VoidCallback onDrop;
  final VoidCallback onCreateChild;
  final VoidCallback onDelete;

  /// Whether a move is possible, asked when the context menu opens so the
  /// entries that would do nothing are shown disabled.
  final bool Function(TaskMove) canMove;
  final void Function(TaskMove) onMove;

  /// Scroll this row fully on screen once built, then report [onRevealed].
  final bool reveal;
  final VoidCallback onRevealed;

  const _DraggableTreeTile({
    super.key,
    required this.entry,
    required this.isSelected,
    required this.isDragging,
    required this.isDropTarget,
    required this.dropPosition,
    required this.isEditing,
    required this.onTap,
    this.onOpen,
    required this.onToggleExpand,
    required this.onStartEdit,
    required this.onEndEdit,
    required this.onTitleChanged,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.onDragOver,
    required this.onDrop,
    required this.onCreateChild,
    required this.onDelete,
    required this.canMove,
    required this.onMove,
    required this.reveal,
    required this.onRevealed,
  });

  @override
  ConsumerState<_DraggableTreeTile> createState() => _DraggableTreeTileState();
}

class _DraggableTreeTileState extends ConsumerState<_DraggableTreeTile> {
  final TextEditingController _editController = TextEditingController();
  final FocusNode _editFocusNode = FocusNode();
  final FocusNode _escKeyFocusNode = FocusNode(skipTraversal: true);

  /// True from entering inline edit until the title is committed or discarded.
  /// Tracked separately from `widget.isEditing` because edit mode can be taken
  /// away from this tile from the outside, and because Enter reaches
  /// [_saveAndExitEdit] twice (onEditingComplete then onSubmitted).
  bool _editActive = false;

  /// Id of the pointer that went down on the expand/collapse chevron, if that
  /// pointer is still the most recent one. The chevron reacts on pointer-down
  /// via a [Listener], which observes but never claims the event, so the very
  /// same tap still completes on the tile's [GestureDetector]. Without this,
  /// expanding a node on a compact layout also navigates into the editor.
  int? _chevronPointer;

  @override
  void initState() {
    super.initState();
    _editFocusNode.addListener(_onFocusChange);

    // A tile can be created *already* in edit mode: a newly created task is put
    // into inline rename before its tile exists, so there is no false -> true
    // transition for didUpdateWidget to catch.
    if (widget.isEditing) _beginEdit();
    if (widget.reveal) _scheduleReveal();
  }

  @override
  void dispose() {
    _editFocusNode.removeListener(_onFocusChange);
    _editController.dispose();
    _editFocusNode.dispose();
    _escKeyFocusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_DraggableTreeTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    // When entering edit mode, initialize controller and request focus
    if (widget.isEditing && !oldWidget.isEditing) _beginEdit();

    // Not gated on a false -> true transition: a second move of the same task
    // arrives while the flag is still set from the first.
    if (widget.reveal) _scheduleReveal();

    // Edit mode taken away from outside this tile — creating a task with
    // Ctrl+N while a rename is open moves editing to the new node. The field
    // is gone from the tree by now and a node detached this way never reports
    // losing focus, so commit what was typed here or it is silently dropped.
    if (!widget.isEditing && oldWidget.isEditing && _editActive) {
      _commitPendingTitle();
    }
  }

  /// Seed the inline title field with the current title (selected, so typing
  /// replaces it) and give it keyboard focus once it has been laid out.
  void _beginEdit() {
    _editActive = true;
    _editController.text = widget.entry.node.title;
    _editController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _editController.text.length,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _editFocusNode.requestFocus();
      // Focus alone does not move the tree: a node created just under the fold
      // would take the keyboard while staying invisible. showOnScreen scrolls
      // the enclosing viewport by the smallest amount that reveals this row,
      // and is a no-op when the row is already fully visible.
      context.findRenderObject()?.showOnScreen(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
          );
    });
  }

  /// Bring this row fully on screen after the frame that lays it out.
  void _scheduleReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onRevealed();
      context.findRenderObject()?.showOnScreen(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
          );
    });
  }

  void _onFocusChange() {
    // When focus is lost, save and exit edit mode.
    if (!_editFocusNode.hasFocus && _editActive) {
      _saveAndExitEdit();
    }
  }

  /// Persists the typed title, if it changed, and marks the edit finished.
  /// Does not touch edit mode — see [_saveAndExitEdit] for that.
  void _commitPendingTitle() {
    _editActive = false;
    final newTitle = _editController.text.trim();
    if (newTitle != widget.entry.node.title) {
      widget.onTitleChanged(newTitle);
    }
  }

  /// Ends the inline title edit.
  ///
  /// [restoreFocus] hands focus to the task editor afterwards. It is set for
  /// the keyboard exits (Enter, Escape), where focus would otherwise land on
  /// the enclosing scope once this TextField's node is disposed. It stays off
  /// when the edit ends *because* focus went somewhere else (a click outside),
  /// since stealing it back would fight the user's click.
  void _saveAndExitEdit({bool restoreFocus = false}) {
    if (!_editActive) return;
    _commitPendingTitle();

    // Only give edit mode back if the panel still considers this tile the one
    // being edited; if editing has already moved to another node, clearing it
    // would close that node's editor too.
    if (widget.isEditing) widget.onEndEdit();
    if (restoreFocus) restoreEditorFocus(ref);
  }

  void _cancelEdit() {
    _editActive = false;
    widget.onEndEdit();
    restoreEditorFocus(ref);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final node = widget.entry.node;
    final settings = ref.watch(settingsProvider);

    return DragTarget<TaskTreeNode>(
      onWillAcceptWithDetails: (details) {
        // Don't allow dropping on self
        return details.data.id != node.id;
      },
      onAcceptWithDetails: (details) {
        widget.onDrop();
      },
      onMove: (details) {
        // Determine drop position based on vertical position within the tile
        final renderBox = context.findRenderObject() as RenderBox;
        final localPosition = renderBox.globalToLocal(details.offset);
        final height = renderBox.size.height;

        DropPosition position;
        if (localPosition.dy < height * 0.25) {
          position = DropPosition.above;
        } else if (localPosition.dy > height * 0.75) {
          position = DropPosition.below;
        } else {
          position = DropPosition.inside;
        }

        widget.onDragOver(position);
      },
      onLeave: (data) {
        // Will be handled by parent
      },
      builder: (context, candidateData, rejectedData) {
        // On touch platforms an immediate whole-tile Draggable would win the
        // gesture arena against list scrolling, so the drag starts from the
        // trailing handle inside the tile content instead.
        if (isMobilePlatform) {
          return Opacity(
            opacity: widget.isDragging ? 0.5 : 1,
            child: _buildTileContent(context, theme),
          );
        }
        return Draggable<TaskTreeNode>(
          data: node,
          onDragStarted: widget.onDragStarted,
          onDragEnd: (details) => widget.onDragEnd(),
          onDraggableCanceled: (velocity, offset) => widget.onDragEnd(),
          feedback: _dragFeedback(theme, settings, node),
          childWhenDragging: Opacity(
            opacity: 0.5,
            child: _buildTileContent(context, theme),
          ),
          child: _buildTileContent(context, theme),
        );
      },
    );
  }

  /// Floating representation of the node while it is being dragged.
  Widget _dragFeedback(ThemeData theme, AppSettings settings, TaskTreeNode node) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.article_outlined,
              size: 16,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 8),
            Text(
              node.title.isEmpty ? 'Untitled' : node.title,
              style: treeFontSettingsToStyle(
                settings,
                base: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// True once for the tap whose pointer-down hit the expand chevron. That tap
  /// has already done its job (toggling the node) and must not also act on the
  /// tile itself.
  bool _consumeChevronTap() {
    if (_chevronPointer == null) return false;
    _chevronPointer = null;
    return true;
  }

  void _handleTap() {
    if (_consumeChevronTap()) return;
    widget.onOpen?.call();
  }

  void _handleDoubleTap() {
    // Tapping the chevron twice in quick succession is expand/collapse, not a
    // request to rename.
    if (_consumeChevronTap()) return;
    widget.onStartEdit();
  }

  Widget _buildTileContent(BuildContext context, ThemeData theme) {
    final node = widget.entry.node;
    final hasChildren = node.hasChildren;
    final title = node.title.isEmpty ? 'Untitled' : node.title;
    final settings = ref.watch(settingsProvider);

    return Listener(
      // Select immediately on raw pointer-down. Doing this via GestureDetector
      // onTapDown would stall ~300ms waiting for kDoubleTapTimeout whenever
      // onDoubleTap is also registered.
      onPointerDown: (e) {
        if (e.buttons == kPrimaryButton) {
          // Pointer events are dispatched innermost-first, so the chevron below
          // has already claimed this pointer if the tap landed on it. Any other
          // pointer means the tap missed the chevron.
          if (e.pointer != _chevronPointer) _chevronPointer = null;
          widget.onTap();
          // A mouse click on a row is also a click outside the editor, which
          // flutter_quill answers by dropping its focus. Nothing else takes
          // it, so keystrokes after picking a task went to the root scope
          // and Ctrl+C — routed by focus — did nothing, while the editor
          // still painted its selection. Hand focus back once the frame has
          // applied the unfocus. Post-frame ordering keeps a double-click's
          // rename in charge: its own focus request is queued later than
          // this one. Touch is excluded so a tap on a phone doesn't pop the
          // soft keyboard for a screen that is about to be pushed.
          if (e.kind != PointerDeviceKind.touch && !widget.isEditing) {
            restoreEditorFocus(ref);
          }
        }
      },
      child: GestureDetector(
      // Compact layouts navigate to the editor on a completed tap; selection
      // itself already happened on pointer-down above. Suppressed during
      // inline rename so a stray tap doesn't yank the user off the field.
      onTap: (widget.isEditing || widget.onOpen == null) ? null : _handleTap,
      // Double-tap still works for edit mode
      onDoubleTap: widget.isEditing ? null : _handleDoubleTap,
      onSecondaryTap: () => _showContextMenu(context),
      // Touch equivalent of the right-click menu (rename, delete, …).
      onLongPress: () => _showContextMenu(context),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isSelected ? theme.colorScheme.primaryContainer : null,
          border: _buildDropIndicatorBorder(theme),
        ),
        child: TreeIndentation(
          entry: widget.entry,
          guide: IndentGuide.connectingLines(
            indent: 24,
            color: theme.colorScheme.outlineVariant,
            thickness: 1,
            origin: 0.5,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              children: [
                // Expand/collapse button
                SizedBox(
                  width: 24,
                  height: 24,
                  child: hasChildren
                      ? Listener(
                          // onPointerDown avoids the kDoubleTapTimeout wait imposed
                          // by the parent GestureDetector's onDoubleTap.
                          onPointerDown: (e) {
                            if (e.buttons == kPrimaryButton) {
                              _chevronPointer = e.pointer;
                              widget.onToggleExpand();
                            }
                          },
                          // The glyph is smaller than its box; without this a tap
                          // in the corner falls through to the tile instead of
                          // toggling — on touch that is most of the target.
                          behavior: HitTestBehavior.opaque,
                          child: Icon(
                            widget.entry.isExpanded
                                ? Icons.expand_more
                                : Icons.chevron_right,
                            size: 18,
                            color: theme.colorScheme.outline,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(width: 4),
                // Task icon
                Icon(
                  Icons.article_outlined,
                  size: 16,
                  color: widget.isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                // Title (Text or TextField based on edit mode)
                Expanded(
                  child: widget.isEditing
                      ? KeyboardListener(
                          focusNode: _escKeyFocusNode,
                          onKeyEvent: (event) {
                            if (event is KeyDownEvent &&
                                event.logicalKey == LogicalKeyboardKey.escape) {
                              _cancelEdit();
                            }
                          },
                          child: TextField(
                            controller: _editController,
                            focusNode: _editFocusNode,
                            style: treeFontSettingsToStyle(
                              settings,
                              base: theme.textTheme.bodyMedium?.copyWith(
                                color: widget.isSelected
                                    ? theme.colorScheme.onPrimaryContainer
                                    : null,
                              ),
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            // Enter reaches both of these (onEditingComplete
                            // first, then onSubmitted); _saveAndExitEdit is
                            // idempotent, so both ask for the focus hand-back
                            // and whichever runs first performs it.
                            onSubmitted: (value) =>
                                _saveAndExitEdit(restoreFocus: true),
                            onEditingComplete: () =>
                                _saveAndExitEdit(restoreFocus: true),
                            onTapOutside: (event) => _saveAndExitEdit(),
                          ),
                        )
                      : Text(
                          title,
                          style: treeFontSettingsToStyle(
                            settings,
                            base: theme.textTheme.bodyMedium?.copyWith(
                              color: widget.isSelected
                                  ? theme.colorScheme.onPrimaryContainer
                                  : (node.title.isEmpty
                                      ? theme.colorScheme.outline
                                      : null),
                              fontStyle: node.title.isEmpty
                                  ? FontStyle.italic
                                  : null,
                            ),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
                // Hidden-from-agents marker. Sits before the child count so
                // the row's rightmost element stays the same one on every
                // node; the tooltip is where "and everything under it" is
                // said, since the icon can only be on the branch root.
                if (node.mcpExcluded)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Tooltip(
                      message: 'Hidden from AI agents, including everything '
                          'under it',
                      child: Icon(
                        Icons.visibility_off_outlined,
                        size: 14,
                        color: widget.isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ),
                // Child count badge
                if (hasChildren)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.2)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${node.children.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: widget.isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.outline,
                      ),
                    ),
                  ),
                // Touch drag handle: the only drag-start area on mobile,
                // where a whole-tile drag would fight the list scroll.
                if (isMobilePlatform && !widget.isEditing)
                  Draggable<TaskTreeNode>(
                    data: node,
                    onDragStarted: widget.onDragStarted,
                    onDragEnd: (details) => widget.onDragEnd(),
                    onDraggableCanceled: (velocity, offset) =>
                        widget.onDragEnd(),
                    feedback: _dragFeedback(theme, settings, node),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.drag_indicator,
                        size: 20,
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  Border? _buildDropIndicatorBorder(ThemeData theme) {
    if (!widget.isDropTarget || widget.dropPosition == null) return null;

    final indicatorColor = theme.colorScheme.primary;
    const indicatorWidth = 2.0;

    switch (widget.dropPosition!) {
      case DropPosition.above:
        return Border(
          top: BorderSide(color: indicatorColor, width: indicatorWidth),
        );
      case DropPosition.inside:
        return Border.all(color: indicatorColor, width: indicatorWidth);
      case DropPosition.below:
        return Border(
          bottom: BorderSide(color: indicatorColor, width: indicatorWidth),
        );
    }
  }

  /// The move entries of the context menu, in menu order, with the arrow key
  /// of each one's shortcut (see [treeMoveActivator]).
  static const _moveEntries = [
    (TaskMove.up, Icons.arrow_upward, 'Move up', LogicalKeyboardKey.arrowUp),
    (
      TaskMove.down,
      Icons.arrow_downward,
      'Move down',
      LogicalKeyboardKey.arrowDown,
    ),
    (
      TaskMove.toParentLevel,
      Icons.format_indent_decrease,
      'Move to parent level',
      LogicalKeyboardKey.arrowLeft,
    ),
    (
      TaskMove.underPrevious,
      Icons.format_indent_increase,
      'Move under previous',
      LogicalKeyboardKey.arrowRight,
    ),
  ];

  void _showContextMenu(BuildContext context) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset position = box.localToGlobal(
      box.size.centerRight(Offset.zero),
      ancestor: overlay,
    );

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        const PopupMenuItem(
          value: 'rename',
          child: ListTile(
            leading: Icon(Icons.edit),
            title: Text('Rename'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: 'add_child',
          child: ListTile(
            leading: Icon(Icons.subdirectory_arrow_right),
            title: Text('Add child task'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete_outline),
            title: Text('Delete'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuDivider(),
        for (final (move, icon, label, arrow) in _moveEntries)
          PopupMenuItem(
            value: move.name,
            enabled: widget.canMove(move),
            child: ListTile(
              leading: Icon(icon),
              title: Text(label),
              // Shortcut hint on desktop only: there is no keyboard to press
              // it on a phone, and the label would crowd a narrow menu.
              trailing: isMobilePlatform
                  ? null
                  : Text(
                      treeMoveShortcutLabel(arrow),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
              contentPadding: EdgeInsets.zero,
              dense: true,
              enabled: widget.canMove(move),
            ),
          ),
      ],
    ).then((value) {
      for (final move in TaskMove.values) {
        if (value == move.name) return widget.onMove(move);
      }
      switch (value) {
        case 'rename':
          widget.onStartEdit();
          break;
        case 'add_child':
          widget.onCreateChild();
          break;
        case 'delete':
          widget.onDelete();
          break;
      }
    });
  }
}
