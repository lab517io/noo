import '../entities/time_line.dart';
import '../entities/time_record.dart';

/// Abstract repository for timeline/time tracking operations
abstract class TimelineRepository {
  /// Get timeline for a specific task
  Future<TimeLine> getTimelineForTask(int taskId);

  /// Start time tracking for a task
  Future<TimeRecord> startTracking(int taskId);

  /// Stop time tracking for a task
  Future<TimeRecord> stopTracking(int taskId);

  /// Add a completed time record
  Future<TimeRecord> addTimeRecord(TimeRecord record);

  /// Update a time record
  Future<void> updateTimeRecord(TimeRecord record);

  /// Delete a time record
  Future<void> deleteTimeRecord(int recordId);

  /// Get total time for a task (including children optionally)
  Future<Duration> getTotalTime(int taskId, {bool includeChildren});

  /// Get time for a task on a specific day
  Future<Duration> getTimeForDay(int taskId, DateTime date);

  /// Get all time records for a date range
  Future<List<TimeRecord>> getRecordsInRange(DateTime start, DateTime end);

  /// Check for overlapping intervals
  Future<bool> hasOverlappingIntervals(int taskId);

  /// Flush any unsaved time data to database
  Future<void> flush();
}
