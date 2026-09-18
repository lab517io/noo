import 'package:equatable/equatable.dart';

import 'time_line.dart';
import 'world_id.dart';

/// Task flags matching Qt implementation
class TaskFlags {
  TaskFlags._();

  /// Task has time tracking disabled
  static const int noTimeTracking = 1;

  /// Task — and everything below it — is withheld from the MCP server.
  ///
  /// Set on the root of the hidden branch only: exclusion is inherited by the
  /// whole subtree, so moving a task under a hidden parent hides it too and no
  /// per-descendant bookkeeping can fall out of step with the tree.
  ///
  /// Lives in `flags` rather than in a local `properties` row because `flags`
  /// is a synced, history-tracked field: a branch hidden on one device is
  /// hidden from the agents on every other device the user syncs to, which is
  /// the only useful meaning for a privacy control. This bit is
  /// Flutter-specific; a Qt client neither sets nor understands it, but
  /// round-trips it because `flags` travels as one integer.
  static const int mcpExcluded = 2;
}

/// Hierarchical task/outline node.
/// Equivalent to Qt's Task class.
class Task extends Equatable {
  final int? id;
  final int? parentId;
  final WorldId worldId;
  final String title;
  final String? content;
  final int index;
  final int flags;
  final int attachmentCount;
  final List<Task> children;
  final TimeLine timeLine;

  /// Whether content (content, timeline) has been loaded
  final bool contentLoaded;

  /// Modification tracking for incremental updates
  final bool titleModified;
  final bool contentModified;
  final bool indexModified;
  final bool parentModified;

  const Task({
    this.id,
    this.parentId,
    required this.worldId,
    this.title = '',
    this.content,
    this.index = 0,
    this.flags = 0,
    this.attachmentCount = 0,
    this.children = const [],
    this.timeLine = const TimeLine(),
    this.contentLoaded = false,
    this.titleModified = false,
    this.contentModified = false,
    this.indexModified = false,
    this.parentModified = false,
  });

  /// Create a new task with a generated WorldId
  factory Task.create({
    int? parentId,
    String title = '',
    int index = 0,
  }) {
    return Task(
      parentId: parentId,
      worldId: WorldId.create(),
      title: title,
      index: index,
    );
  }

  /// Whether time tracking is enabled for this task
  bool get hasTimeTracking => (flags & TaskFlags.noTimeTracking) == 0;

  /// Whether this task is the root of a branch hidden from AI agents.
  ///
  /// False on the descendants of a hidden task even though they are hidden
  /// too — the flag marks where the branch starts, which is what the tree
  /// badge and the preferences list show.
  bool get mcpExcluded => (flags & TaskFlags.mcpExcluded) != 0;

  /// Whether this is a root-level task
  bool get isRoot => parentId == null;

  /// Whether this task has children
  bool get hasChildren => children.isNotEmpty;

  /// Total time including children (for cumulative reports)
  Duration get totalTimeWithChildren {
    return timeLine.totalTime +
        children.fold(
          Duration.zero,
          (sum, child) => sum + child.totalTimeWithChildren,
        );
  }

  /// Find a child task by ID (recursive)
  Task? findChildById(int taskId) {
    for (final child in children) {
      if (child.id == taskId) return child;
      final found = child.findChildById(taskId);
      if (found != null) return found;
    }
    return null;
  }

  /// Get all descendant task IDs (recursive)
  List<int> get allDescendantIds {
    final ids = <int>[];
    for (final child in children) {
      if (child.id != null) {
        ids.add(child.id!);
        ids.addAll(child.allDescendantIds);
      }
    }
    return ids;
  }

  /// Check if any modifications need to be saved
  bool get needsSave =>
      titleModified || contentModified || indexModified || parentModified;

  /// Clear all modification flags
  Task clearModifications() {
    return copyWith(
      titleModified: false,
      contentModified: false,
      indexModified: false,
      parentModified: false,
    );
  }

  static const _unset = Object();

  Task copyWith({
    int? id,
    Object? parentId = _unset,
    WorldId? worldId,
    String? title,
    String? content,
    int? index,
    int? flags,
    int? attachmentCount,
    List<Task>? children,
    TimeLine? timeLine,
    bool? contentLoaded,
    bool? titleModified,
    bool? contentModified,
    bool? indexModified,
    bool? parentModified,
  }) {
    return Task(
      id: id ?? this.id,
      parentId: identical(parentId, _unset) ? this.parentId : parentId as int?,
      worldId: worldId ?? this.worldId,
      title: title ?? this.title,
      content: content ?? this.content,
      index: index ?? this.index,
      flags: flags ?? this.flags,
      attachmentCount: attachmentCount ?? this.attachmentCount,
      children: children ?? this.children,
      timeLine: timeLine ?? this.timeLine,
      contentLoaded: contentLoaded ?? this.contentLoaded,
      titleModified: titleModified ?? this.titleModified,
      contentModified: contentModified ?? this.contentModified,
      indexModified: indexModified ?? this.indexModified,
      parentModified: parentModified ?? this.parentModified,
    );
  }

  @override
  List<Object?> get props => [
        id,
        parentId,
        worldId,
        title,
        content,
        index,
        flags,
        attachmentCount,
        children,
        timeLine,
        contentLoaded,
      ];

  @override
  String toString() {
    return 'Task(id: $id, title: $title, children: ${children.length})';
  }
}
