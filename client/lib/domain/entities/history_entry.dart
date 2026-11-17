import 'package:equatable/equatable.dart';

/// Type of entity that a history entry refers to
enum HistoryEntityType {
  task,
  file,
  timeline,
}

/// Represents a single change record in history.
/// Used for tracking changes and sync operations.
class HistoryEntry extends Equatable {
  /// Database ID (null if not persisted)
  final int? id;

  /// ID of the entity that changed (taskId, fileId, or timelineId)
  final int entityId;

  /// Type of entity this change applies to
  final HistoryEntityType entityType;

  /// Name of the field that changed
  final String field;

  /// Previous value (null for creation)
  final String? oldValue;

  /// New value (null for deletion)
  final String? newValue;

  /// When the change occurred (ISO8601 UTC)
  final DateTime timestamp;

  /// WorldId of the entity (for sync matching)
  final String? worldId;

  const HistoryEntry({
    this.id,
    required this.entityId,
    required this.entityType,
    required this.field,
    this.oldValue,
    this.newValue,
    required this.timestamp,
    this.worldId,
  });

  /// Whether this is a creation (no old value)
  bool get isCreation => oldValue == null && newValue != null;

  /// Whether this is a deletion (no new value)
  bool get isDeletion => oldValue != null && newValue == null;

  /// Whether this is an update (both old and new values)
  bool get isUpdate => oldValue != null && newValue != null;

  /// Create a copy with updated values
  HistoryEntry copyWith({
    int? id,
    int? entityId,
    HistoryEntityType? entityType,
    String? field,
    String? oldValue,
    String? newValue,
    DateTime? timestamp,
    String? worldId,
  }) {
    return HistoryEntry(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      field: field ?? this.field,
      oldValue: oldValue ?? this.oldValue,
      newValue: newValue ?? this.newValue,
      timestamp: timestamp ?? this.timestamp,
      worldId: worldId ?? this.worldId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        entityId,
        entityType,
        field,
        oldValue,
        newValue,
        timestamp,
        worldId,
      ];

  @override
  String toString() =>
      'HistoryEntry(entityType: $entityType, entityId: $entityId, field: $field)';
}
