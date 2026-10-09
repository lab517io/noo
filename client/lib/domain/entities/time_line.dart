import 'package:equatable/equatable.dart';

import '../../core/utils/date_utils.dart';
import 'time_record.dart';

/// Aggregates time records for a single task with time analysis capabilities.
/// Equivalent to Qt's TimeLine class.
class TimeLine extends Equatable {
  final List<TimeRecord> records;
  final bool isActive;
  final TimeRecord? activeRecord;

  const TimeLine({
    this.records = const [],
    this.isActive = false,
    this.activeRecord,
  });

  /// Create an empty timeline
  factory TimeLine.empty() => const TimeLine();

  /// Get total tracked time
  Duration get totalTime {
    return records.fold(
      Duration.zero,
      (sum, record) => sum + record.duration,
    );
  }

  /// Get time tracked today
  Duration get today => timeForDay(DateTime.now());

  /// Get time tracked this month
  Duration get thisMonth => timeForMonth(DateTime.now());

  /// Get time for a specific day
  Duration timeForDay(DateTime date) {
    return records
        .where((r) => NooDateUtils.isSameDay(r.startTime.toLocal(), date))
        .fold(Duration.zero, (sum, r) => sum + r.duration);
  }

  /// Get time for a specific month
  Duration timeForMonth(DateTime date) {
    return records
        .where((r) => NooDateUtils.isSameMonth(r.startTime.toLocal(), date))
        .fold(Duration.zero, (sum, r) => sum + r.duration);
  }

  /// Get time for a specific year
  Duration timeForYear(int year) {
    return records
        .where((r) => r.startTime.toLocal().year == year)
        .fold(Duration.zero, (sum, r) => sum + r.duration);
  }

  /// Get time within a date range (inclusive)
  Duration timeForRange(DateTime start, DateTime end) {
    return records
        .where((r) =>
            !r.startTime.isBefore(start) &&
            !r.startTime.isAfter(end))
        .fold(Duration.zero, (sum, r) => sum + r.duration);
  }

  /// Get all years that have time records
  Set<int> getYears() {
    return records.map((r) => r.startTime.toLocal().year).toSet();
  }

  /// Get all months for a specific year that have time records
  Set<int> getMonths(int year) {
    return records
        .where((r) => r.startTime.toLocal().year == year)
        .map((r) => r.startTime.toLocal().month)
        .toSet();
  }

  /// Get all days for a specific month that have time records
  Set<int> getDays(int year, int month) {
    return records
        .where((r) =>
            r.startTime.toLocal().year == year &&
            r.startTime.toLocal().month == month)
        .map((r) => r.startTime.toLocal().day)
        .toSet();
  }

  /// Get all hours for a specific day that have time records
  Set<int> getHours(int year, int month, int day) {
    return records
        .where((r) {
          final local = r.startTime.toLocal();
          return local.year == year &&
              local.month == month &&
              local.day == day;
        })
        .map((r) => r.startTime.toLocal().hour)
        .toSet();
  }

  /// Get records for a specific day
  List<TimeRecord> recordsForDay(DateTime date) {
    return records
        .where((r) => NooDateUtils.isSameDay(r.startTime.toLocal(), date))
        .toList();
  }

  /// Check if there's any time interval overlap (duplicate detection)
  bool get hasDuplicates {
    for (int i = 0; i < records.length; i++) {
      for (int j = i + 1; j < records.length; j++) {
        if (records[i].overlapsWith(records[j])) {
          return true;
        }
      }
    }
    return false;
  }

  /// Check if a new interval would intersect with existing ones
  bool hasIntersection(DateTime start, DateTime end) {
    return records.any((r) {
      final recordEnd = r.endTime ?? DateTime.now().toUtc();
      return start.isBefore(recordEnd) && end.isAfter(r.startTime);
    });
  }

  /// Find a record by ID
  TimeRecord? findById(int id) {
    try {
      return records.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Start tracking (creates a new active record)
  TimeLine start(int taskId) {
    if (isActive) return this;

    final record = TimeRecord.startNow(taskId: taskId);
    return copyWith(
      isActive: true,
      activeRecord: record,
    );
  }

  /// Stop tracking (finalizes the active record)
  TimeLine stop() {
    if (!isActive || activeRecord == null) return this;

    final stoppedRecord = activeRecord!.stop();
    return TimeLine(
      records: [...records, stoppedRecord],
      isActive: false,
      activeRecord: null,
    );
  }

  /// Add a completed time record
  TimeLine addRecord(TimeRecord record) {
    return copyWith(records: [...records, record]);
  }

  /// Remove a time record by ID
  TimeLine removeRecord(int recordId) {
    return copyWith(
      records: records.where((r) => r.id != recordId).toList(),
    );
  }

  /// Update a time record
  TimeLine updateRecord(TimeRecord updated) {
    return copyWith(
      records: records.map((r) => r.id == updated.id ? updated : r).toList(),
    );
  }

  static const _unset = Object();

  TimeLine copyWith({
    List<TimeRecord>? records,
    bool? isActive,
    // Sentinel default so `activeRecord: null` can actually clear it (the
    // usual `?? this.activeRecord` trap makes clearing impossible).
    Object? activeRecord = _unset,
  }) {
    return TimeLine(
      records: records ?? this.records,
      isActive: isActive ?? this.isActive,
      activeRecord: identical(activeRecord, _unset)
          ? this.activeRecord
          : activeRecord as TimeRecord?,
    );
  }

  @override
  List<Object?> get props => [records, isActive, activeRecord];
}
