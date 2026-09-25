import 'package:equatable/equatable.dart';

import 'world_id.dart';

/// Represents a single time tracking interval.
/// Equivalent to Qt's TimeRecord class.
class TimeRecord extends Equatable {
  final int? id;
  final int taskId;
  final WorldId worldId;
  final DateTime startTime;
  final DateTime? endTime;
  final bool saved;

  const TimeRecord({
    this.id,
    required this.taskId,
    required this.worldId,
    required this.startTime,
    this.endTime,
    this.saved = false,
  });

  /// Create a new time record starting now
  factory TimeRecord.startNow({
    required int taskId,
    WorldId? worldId,
  }) {
    return TimeRecord(
      taskId: taskId,
      worldId: worldId ?? WorldId.create(),
      startTime: DateTime.now().toUtc(),
    );
  }

  /// Get the duration of this time record
  Duration get duration {
    final end = endTime ?? DateTime.now().toUtc();
    return end.difference(startTime);
  }

  /// Alias for duration (Qt compatibility)
  Duration get length => duration;

  /// Check if this record is currently active (no end time)
  bool get isActive => endTime == null;

  /// Check if this record overlaps with another
  bool overlapsWith(TimeRecord other) {
    final thisEnd = endTime ?? DateTime.now().toUtc();
    final otherEnd = other.endTime ?? DateTime.now().toUtc();

    return startTime.isBefore(otherEnd) && thisEnd.isAfter(other.startTime);
  }

  /// Check if this record contains a specific time
  bool contains(DateTime time) {
    final end = endTime ?? DateTime.now().toUtc();
    return !time.isBefore(startTime) && !time.isAfter(end);
  }

  /// Stop this record (set end time to now)
  TimeRecord stop() {
    if (endTime != null) return this;
    return copyWith(endTime: DateTime.now().toUtc());
  }

  TimeRecord copyWith({
    int? id,
    int? taskId,
    WorldId? worldId,
    DateTime? startTime,
    DateTime? endTime,
    bool? saved,
  }) {
    return TimeRecord(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      worldId: worldId ?? this.worldId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      saved: saved ?? this.saved,
    );
  }

  @override
  List<Object?> get props => [id, taskId, worldId, startTime, endTime, saved];

  @override
  String toString() {
    return 'TimeRecord(id: $id, taskId: $taskId, start: $startTime, end: $endTime)';
  }
}
