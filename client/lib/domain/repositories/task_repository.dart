import '../entities/task.dart';

/// Abstract repository for task operations
abstract class TaskRepository {
  /// Get all top-level tasks (no parent)
  Future<List<Task>> getTopLevelTasks();

  /// Get child tasks for a parent
  Future<List<Task>> getChildTasks(int parentId);

  /// Get a single task by ID
  Future<Task?> getTaskById(int id);

  /// Create a new task
  Future<Task> createTask({int? parentId, int index});

  /// Update task metadata
  Future<void> updateTask(Task task);

  /// Delete a task (soft delete)
  Future<void> deleteTask(int id);

  /// Permanently delete a task and all its children
  Future<void> permanentlyDeleteTask(int id);

  /// Move a task to a new parent and/or position
  Future<void> moveTask(int taskId, int? newParentId, int newIndex);

  /// Load task content (html, timeline) - lazy loading
  Future<Task> loadTaskContent(Task task);

  /// Save task content
  Future<void> saveTaskContent(Task task);

  /// Undelete a previously soft-deleted task
  Future<void> undeleteTask(int id);

  /// Get all tasks as a flat list
  Future<List<Task>> getAllTasks();

  /// Search tasks by title
  Future<List<Task>> searchTasks(String query);
}
