import '../../../domain/entities/task.dart';

/// A tree node that wraps a Task with tree-related state.
/// Used by flutter_fancy_tree_view to manage the hierarchical display.
class TaskTreeNode {
  final Task task;
  final List<TaskTreeNode> children;

  /// Whether this node's children have been loaded from the database
  bool childrenLoaded;

  TaskTreeNode({
    required this.task,
    List<TaskTreeNode>? children,
    this.childrenLoaded = false,
  }) : children = children ?? [];

  /// Task ID (convenience accessor)
  int? get id => task.id;

  /// Task title (convenience accessor)
  String get title => task.title;

  /// Whether this task has any children
  bool get hasChildren => children.isNotEmpty;

  /// Whether this node starts a branch hidden from AI agents.
  ///
  /// Only the marked node reports true; its descendants are hidden by
  /// inheritance and carry no flag, which is why the tree badges the root of
  /// the branch and nothing below it.
  bool get mcpExcluded => task.mcpExcluded;

  /// Parent task ID (convenience accessor)
  int? get parentId => task.parentId;

  /// Add a child node
  void addChild(TaskTreeNode child) {
    children.add(child);
  }

  /// Remove a child node by ID
  bool removeChild(int taskId) {
    final index = children.indexWhere((n) => n.id == taskId);
    if (index >= 0) {
      children.removeAt(index);
      return true;
    }
    return false;
  }

  /// Find a descendant node by ID (recursive search)
  TaskTreeNode? findById(int taskId) {
    if (id == taskId) return this;
    for (final child in children) {
      final found = child.findById(taskId);
      if (found != null) return found;
    }
    return null;
  }

  /// Update the task data
  TaskTreeNode copyWithTask(Task newTask) {
    return TaskTreeNode(
      task: newTask,
      children: children,
      childrenLoaded: childrenLoaded,
    );
  }

  @override
  String toString() => 'TaskTreeNode(id: $id, title: $title, children: ${children.length})';
}
