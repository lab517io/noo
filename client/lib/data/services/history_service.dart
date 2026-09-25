import 'dart:convert';

import '../../core/utils/diff_utils.dart';
import '../../domain/entities/history_entry.dart';
import '../database/database.dart';

/// Field names for history tracking
class HistoryFields {
  HistoryFields._();

  // Task fields
  static const String title = 'title';
  static const String content = 'content';
  static const String parentId = 'parentId';
  static const String orderId = 'orderId';
  static const String flags = 'flags';
  static const String removed = 'removed';

  // File fields
  static const String filename = 'filename';
  static const String fileContent = 'fileContent';

  // Timeline fields
  static const String taskId = 'taskId';
  static const String startTime = 'startTime';
  static const String endTime = 'endTime';
}

/// Service for recording changes to history tables.
/// Handles diff computation for text fields and full value storage for others.
class HistoryService {
  final NooDatabase _db;

  HistoryService(this._db);

  // ============================================================
  // Task History Recording
  // ============================================================

  /// Record the creation of a new task
  Future<void> recordTaskCreation(TaskRow task) async {
    // Record each non-null field as a creation (oldValue = null)
    await _db.insertTaskHistory(
      taskId: task.id,
      field: HistoryFields.title,
      oldValue: null,
      newValue: task.title,
    );

    if (task.content != null) {
      await _db.insertTaskHistory(
        taskId: task.id,
        field: HistoryFields.content,
        oldValue: null,
        newValue: task.content,
      );
    }

    if (task.parentId != null) {
      await _db.insertTaskHistory(
        taskId: task.id,
        field: HistoryFields.parentId,
        oldValue: null,
        newValue: task.parentId.toString(),
      );
    }

    await _db.insertTaskHistory(
      taskId: task.id,
      field: HistoryFields.orderId,
      oldValue: null,
      newValue: task.orderId.toString(),
    );

    await _db.insertTaskHistory(
      taskId: task.id,
      field: HistoryFields.flags,
      oldValue: null,
      newValue: task.flags.toString(),
    );
  }

  /// Record changes between old and new task state
  Future<void> recordTaskChanges({
    required TaskRow oldTask,
    required TaskRow newTask,
  }) async {
    // Title change. Diff fields store the patch only; oldValue is '' unless
    // this is the chain's first row (see NooDatabase.updateTask, which is the
    // live write path and defines the format).
    if (oldTask.title != newTask.title) {
      final diff = DiffUtils.computeDiff(oldTask.title, newTask.title);
      if (diff != null) {
        final hasPrior = await _db.getLatestTaskHistoryForField(
                newTask.id, HistoryFields.title) !=
            null;
        await _db.insertTaskHistory(
          taskId: newTask.id,
          field: HistoryFields.title,
          oldValue: hasPrior ? '' : oldTask.title,
          newValue: diff,
        );
      }
    }

    // Content change
    if (oldTask.content != newTask.content) {
      final diff = DiffUtils.computeDiff(oldTask.content, newTask.content);
      if (diff != null) {
        final hasPrior = await _db.getLatestTaskHistoryForField(
                newTask.id, HistoryFields.content) !=
            null;
        await _db.insertTaskHistory(
          taskId: newTask.id,
          field: HistoryFields.content,
          oldValue: hasPrior ? '' : oldTask.content,
          newValue: diff,
        );
      }
    }

    // Parent change
    if (oldTask.parentId != newTask.parentId) {
      await _db.insertTaskHistory(
        taskId: newTask.id,
        field: HistoryFields.parentId,
        oldValue: oldTask.parentId?.toString(),
        newValue: newTask.parentId?.toString(),
      );
    }

    // Order change
    if (oldTask.orderId != newTask.orderId) {
      await _db.insertTaskHistory(
        taskId: newTask.id,
        field: HistoryFields.orderId,
        oldValue: oldTask.orderId.toString(),
        newValue: newTask.orderId.toString(),
      );
    }

    // Flags change
    if (oldTask.flags != newTask.flags) {
      await _db.insertTaskHistory(
        taskId: newTask.id,
        field: HistoryFields.flags,
        oldValue: oldTask.flags.toString(),
        newValue: newTask.flags.toString(),
      );
    }

    // Removed change (soft delete)
    if (oldTask.removed != newTask.removed) {
      await _db.insertTaskHistory(
        taskId: newTask.id,
        field: HistoryFields.removed,
        oldValue: oldTask.removed.toString(),
        newValue: newTask.removed.toString(),
      );
    }
  }

  /// Record task deletion
  Future<void> recordTaskDeletion(TaskRow task) async {
    await _db.insertTaskHistory(
      taskId: task.id,
      field: HistoryFields.removed,
      oldValue: '0',
      newValue: '1',
    );
  }

  // ============================================================
  // File History Recording
  // ============================================================

  /// Record the creation of a new file attachment
  Future<void> recordFileCreation(FileEntry file) async {
    await _db.insertFileHistory(
      fileId: file.id,
      field: HistoryFields.filename,
      oldValue: null,
      newValue: file.filename,
    );

    if (file.content != null) {
      await _db.insertFileHistory(
        fileId: file.id,
        field: HistoryFields.content,
        oldValue: null,
        newValue: base64.encode(file.content!),
      );
    }

    await _db.insertFileHistory(
      fileId: file.id,
      field: HistoryFields.orderId,
      oldValue: null,
      newValue: file.orderId.toString(),
    );
  }

  /// Record changes to a file attachment
  Future<void> recordFileChanges({
    required FileEntry oldFile,
    required FileEntry newFile,
  }) async {
    // Filename change
    if (oldFile.filename != newFile.filename) {
      await _db.insertFileHistory(
        fileId: newFile.id,
        field: HistoryFields.filename,
        oldValue: oldFile.filename,
        newValue: newFile.filename,
      );
    }

    // Order change
    if (oldFile.orderId != newFile.orderId) {
      await _db.insertFileHistory(
        fileId: newFile.id,
        field: HistoryFields.orderId,
        oldValue: oldFile.orderId.toString(),
        newValue: newFile.orderId.toString(),
      );
    }

    // Removed change
    if (oldFile.removed != newFile.removed) {
      await _db.insertFileHistory(
        fileId: newFile.id,
        field: HistoryFields.removed,
        oldValue: oldFile.removed.toString(),
        newValue: newFile.removed.toString(),
      );
    }
  }

  /// Record content change for a file (stored as base64)
  Future<void> recordFileContentChange({
    required int fileId,
    required List<int>? oldContent,
    required List<int>? newContent,
  }) async {
    await _db.insertFileHistory(
      fileId: fileId,
      field: HistoryFields.content,
      oldValue: oldContent != null ? base64.encode(oldContent) : null,
      newValue: newContent != null ? base64.encode(newContent) : null,
    );
  }

  /// Record file deletion
  Future<void> recordFileDeletion(FileEntry file) async {
    await _db.insertFileHistory(
      fileId: file.id,
      field: HistoryFields.removed,
      oldValue: '0',
      newValue: '1',
    );
  }

  // ============================================================
  // Timeline History Recording
  // ============================================================

  /// Record the creation of a new time record
  Future<void> recordTimelineCreation(TimelineEntry entry) async {
    await _db.insertTimelineHistory(
      timelineId: entry.id,
      field: HistoryFields.taskId,
      oldValue: null,
      newValue: entry.taskId.toString(),
    );

    await _db.insertTimelineHistory(
      timelineId: entry.id,
      field: HistoryFields.startTime,
      oldValue: null,
      newValue: entry.startTime,
    );

    if (entry.endTime != null) {
      await _db.insertTimelineHistory(
        timelineId: entry.id,
        field: HistoryFields.endTime,
        oldValue: null,
        newValue: entry.endTime,
      );
    }
  }

  /// Record changes to a time record
  Future<void> recordTimelineChanges({
    required TimelineEntry oldEntry,
    required TimelineEntry newEntry,
  }) async {
    // Start time change
    if (oldEntry.startTime != newEntry.startTime) {
      await _db.insertTimelineHistory(
        timelineId: newEntry.id,
        field: HistoryFields.startTime,
        oldValue: oldEntry.startTime,
        newValue: newEntry.startTime,
      );
    }

    // End time change
    if (oldEntry.endTime != newEntry.endTime) {
      await _db.insertTimelineHistory(
        timelineId: newEntry.id,
        field: HistoryFields.endTime,
        oldValue: oldEntry.endTime,
        newValue: newEntry.endTime,
      );
    }

    // Removed change
    if (oldEntry.removed != newEntry.removed) {
      await _db.insertTimelineHistory(
        timelineId: newEntry.id,
        field: HistoryFields.removed,
        oldValue: oldEntry.removed.toString(),
        newValue: newEntry.removed.toString(),
      );
    }
  }

  /// Record timeline deletion
  Future<void> recordTimelineDeletion(TimelineEntry entry) async {
    await _db.insertTimelineHistory(
      timelineId: entry.id,
      field: HistoryFields.removed,
      oldValue: '0',
      newValue: '1',
    );
  }

  // ============================================================
  // Diff-chain reconstruction
  // ============================================================

  /// Rebuild the actual value each history row of one task's diff field
  /// (title/content) represents, by replaying the patch chain.
  ///
  /// [rows] must be one (task, field) chain in chronological order (the order
  /// the history queries return). Handles every storage generation:
  ///  - creation rows (oldValue null) and legacy pre-diff rows carry the full
  ///    value in newValue;
  ///  - patch rows (newValue starts with a dmp hunk header) apply to the
  ///    running value — seeded, for a chain without a creation row, by the
  ///    base row's retained oldValue.
  ///
  /// Returns, per input row, the (oldValue, newValue) pair it represents —
  /// full text on both sides, unlike the stored columns.
  static List<({String? oldValue, String? newValue})> reconstructTaskFieldChain(
      List<HistoryTaskData> rows) {
    final out = <({String? oldValue, String? newValue})>[];
    String? running;
    for (final row in rows) {
      final stored = row.newValue;
      String? current;
      if (stored == null) {
        current = null;
      } else if (DiffUtils.isPatch(stored)) {
        // Base of a remote-created chain: the first row keeps its full old
        // value; later rows replay from the running value.
        final base =
            running ?? ((row.oldValue?.isNotEmpty ?? false) ? row.oldValue! : '');
        current = DiffUtils.applyDiff(base, stored);
      } else {
        current = stored; // creation row or legacy full value
      }
      out.add((oldValue: running, newValue: current));
      running = current;
    }
    return out;
  }

  /// Reconstructed full values for one field of one task, oldest first —
  /// (timestamp, value) per history row.
  Future<List<({DateTime timestamp, String? value})>> reconstructTaskField(
      int taskId, String field) async {
    final rows = await _db.getTaskHistoryForField(taskId, field);
    final values = reconstructTaskFieldChain(rows);
    return [
      for (var i = 0; i < rows.length; i++)
        (
          timestamp: DateTime.parse(rows[i].timestamp),
          value: values[i].newValue,
        )
    ];
  }

  // ============================================================
  // History Query Methods
  // ============================================================

  /// Get all task history entries as domain entities
  Future<List<HistoryEntry>> getAllTaskHistoryEntries() async {
    final data = await _db.getAllTaskHistory();
    return data.map((d) => _taskDataToEntry(d)).toList();
  }

  /// Get task history since a timestamp
  Future<List<HistoryEntry>> getTaskHistorySince(DateTime since) async {
    final data = await _db.getTaskHistorySince(since.toUtc().toIso8601String());
    return data.map((d) => _taskDataToEntry(d)).toList();
  }

  /// Get all file history entries as domain entities
  Future<List<HistoryEntry>> getAllFileHistoryEntries() async {
    final data = await _db.getAllFileHistory();
    return data.map((d) => _fileDataToEntry(d)).toList();
  }

  /// Get file history since a timestamp
  Future<List<HistoryEntry>> getFileHistorySince(DateTime since) async {
    final data = await _db.getFileHistorySince(since.toUtc().toIso8601String());
    return data.map((d) => _fileDataToEntry(d)).toList();
  }

  /// Get all timeline history entries as domain entities
  Future<List<HistoryEntry>> getAllTimelineHistoryEntries() async {
    final data = await _db.getAllTimelineHistory();
    return data.map((d) => _timelineDataToEntry(d)).toList();
  }

  /// Get timeline history since a timestamp
  Future<List<HistoryEntry>> getTimelineHistorySince(DateTime since) async {
    final data =
        await _db.getTimelineHistorySince(since.toUtc().toIso8601String());
    return data.map((d) => _timelineDataToEntry(d)).toList();
  }

  /// Get all history since a timestamp (combined)
  Future<List<HistoryEntry>> getAllHistorySince(DateTime since) async {
    final taskHistory = await getTaskHistorySince(since);
    final fileHistory = await getFileHistorySince(since);
    final timelineHistory = await getTimelineHistorySince(since);

    final combined = [...taskHistory, ...fileHistory, ...timelineHistory];
    combined.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return combined;
  }

  /// Get local (non-remote) history not yet pushed, using per-table row-id
  /// watermarks. Row ids are monotonic and immune to clock skew, so an edit
  /// made while a sync is in flight is picked up on the next push instead of
  /// being lost behind a wall-clock watermark.
  Future<List<HistoryEntry>> getLocalHistoryAfterIds({
    required int taskAfterId,
    required int fileAfterId,
    required int timelineAfterId,
  }) async {
    final taskHistory = (await _db.getLocalTaskHistoryAfterId(taskAfterId))
        .map(_taskDataToEntry);
    final fileHistory = (await _db.getLocalFileHistoryAfterId(fileAfterId))
        .map(_fileDataToEntry);
    final timelineHistory =
        (await _db.getLocalTimelineHistoryAfterId(timelineAfterId))
            .map(_timelineDataToEntry);

    final combined = [...taskHistory, ...fileHistory, ...timelineHistory];
    combined.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return combined;
  }

  // ============================================================
  // Private Helpers
  // ============================================================

  HistoryEntry _taskDataToEntry(HistoryTaskData data) {
    return HistoryEntry(
      id: data.id,
      entityId: data.taskId,
      entityType: HistoryEntityType.task,
      field: data.field,
      oldValue: data.oldValue,
      newValue: data.newValue,
      timestamp: DateTime.parse(data.timestamp),
      worldId: data.worldId.isNotEmpty ? data.worldId : null,
    );
  }

  HistoryEntry _fileDataToEntry(HistoryFileData data) {
    return HistoryEntry(
      id: data.id,
      entityId: data.fileId,
      entityType: HistoryEntityType.file,
      field: data.field,
      oldValue: data.oldValue,
      newValue: data.newValue,
      timestamp: DateTime.parse(data.timestamp),
      worldId: data.worldId.isNotEmpty ? data.worldId : null,
    );
  }

  HistoryEntry _timelineDataToEntry(HistoryTimelineData data) {
    return HistoryEntry(
      id: data.id,
      entityId: data.timelineId,
      entityType: HistoryEntityType.timeline,
      field: data.field,
      oldValue: data.oldValue,
      newValue: data.newValue,
      timestamp: DateTime.parse(data.timestamp),
      worldId: data.worldId.isNotEmpty ? data.worldId : null,
    );
  }
}
