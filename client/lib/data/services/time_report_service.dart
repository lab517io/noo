import '../../core/utils/duration_formatter.dart';
import '../database/database.dart';

/// Output format for the time report.
enum TimeReportFormat {
  /// Indented bullet list mirroring the task hierarchy with totals only.
  tree,

  /// Like [tree], but with a per-day breakdown nested under each task.
  treeWithDays,

  /// Chronological flat list of intervals as Markdown bullets.
  flat,

  /// Comma-separated values: task path, date, start, end, duration seconds.
  csv,
}

extension TimeReportFormatX on TimeReportFormat {
  String get label {
    switch (this) {
      case TimeReportFormat.tree:
        return 'Tree (totals only)';
      case TimeReportFormat.treeWithDays:
        return 'Tree with per-day breakdown';
      case TimeReportFormat.flat:
        return 'Flat interval list';
      case TimeReportFormat.csv:
        return 'CSV';
    }
  }

  bool get isMarkdown => this != TimeReportFormat.csv;
}

/// Configuration for a time report.
class TimeReportConfig {
  /// Tasks the user explicitly checked.
  final Set<int> selectedTaskIds;

  /// If true, all descendants of each selected task are also reported.
  final bool includeDescendants;

  /// Local-time inclusive start day.
  final DateTime fromDate;

  /// Local-time inclusive end day.
  final DateTime toDate;

  final TimeReportFormat format;

  /// In tree formats, include tasks with zero clipped time.
  final bool showEmptyTasks;

  const TimeReportConfig({
    required this.selectedTaskIds,
    required this.includeDescendants,
    required this.fromDate,
    required this.toDate,
    required this.format,
    required this.showEmptyTasks,
  });
}

/// The local midnight that ends the calendar day of [day] — the exclusive
/// upper bound of a report whose last day is [day].
///
/// Calendar arithmetic (`day + 1`), not `.add(Duration(days: 1))`: a Duration
/// is absolute time, so on the 25-hour day that ends daylight saving it lands
/// at 23:00 and the report drops the last hour of work, and on the 23-hour day
/// that starts it it reaches into the next morning.
DateTime exclusiveEndOfDay(DateTime day) =>
    DateTime(day.year, day.month, day.day + 1);

/// Result of a [TimeReportService.generate] call.
class TimeReportResult {
  /// The rendered report (Markdown or CSV depending on the requested format).
  final String text;

  /// Sum of clipped durations across all included records.
  final Duration totalDuration;

  /// Number of records that contributed to the report.
  final int recordsCount;

  const TimeReportResult({
    required this.text,
    required this.totalDuration,
    required this.recordsCount,
  });
}

/// Generates time-spent reports across selected tasks and a date range.
///
/// Records that straddle the report range or a day boundary (in [TimeReportFormat.treeWithDays])
/// are clipped and prorated, so the totals reflect time actually spent inside the
/// requested window.
class TimeReportService {
  final NooDatabase _db;

  TimeReportService(this._db);

  Future<TimeReportResult> generate(TimeReportConfig config) async {
    if (config.selectedTaskIds.isEmpty) {
      return const TimeReportResult(
        text: '',
        totalDuration: Duration.zero,
        recordsCount: 0,
      );
    }

    // Compute UTC clip range from local-time bounds.
    final fromLocal = DateTime(
      config.fromDate.year,
      config.fromDate.month,
      config.fromDate.day,
    );
    final fromUtc = fromLocal.toUtc();
    final toUtc = exclusiveEndOfDay(config.toDate).toUtc();

    // Load and index all tasks once.
    final allRows = await _db.getAllTasks();
    final byId = <int, TaskRow>{
      for (final row in allRows) row.id: row,
    };
    final childrenByParent = <int?, List<TaskRow>>{};
    for (final row in allRows) {
      childrenByParent.putIfAbsent(row.parentId, () => []).add(row);
    }
    for (final list in childrenByParent.values) {
      list.sort((a, b) => a.orderId.compareTo(b.orderId));
    }

    // Resolve effective task set.
    final effective = <int>{};
    for (final id in config.selectedTaskIds) {
      if (!byId.containsKey(id)) continue;
      effective.add(id);
      if (config.includeDescendants) {
        _collectDescendants(id, childrenByParent, effective);
      }
    }

    // Load and clip time records for each effective task.
    final taskInfos = <int, _TaskInfo>{};
    Duration grandTotal = Duration.zero;
    int grandCount = 0;

    for (final taskId in effective) {
      final entries = await _db.getTimelineForTask(taskId);
      final clipped = <_ClippedRecord>[];
      Duration ownTotal = Duration.zero;

      for (final entry in entries) {
        final start = DateTime.parse(entry.startTime).toUtc();
        final end = entry.endTime != null
            ? DateTime.parse(entry.endTime!).toUtc()
            : DateTime.now().toUtc();

        final effStart = start.isAfter(fromUtc) ? start : fromUtc;
        final effEnd = end.isBefore(toUtc) ? end : toUtc;
        if (!effEnd.isAfter(effStart)) continue;

        final dur = effEnd.difference(effStart);
        ownTotal += dur;
        clipped.add(_ClippedRecord(
          start: effStart,
          end: effEnd,
          duration: dur,
          isOngoing: entry.endTime == null,
        ));
        grandCount++;
      }

      grandTotal += ownTotal;
      taskInfos[taskId] = _TaskInfo(
        row: byId[taskId]!,
        ownDuration: ownTotal,
        clippedRecords: clipped,
      );
    }

    // Build the rendered output.
    String text;
    switch (config.format) {
      case TimeReportFormat.tree:
        text = _renderTree(
          config: config,
          taskInfos: taskInfos,
          childrenByParent: childrenByParent,
          grandTotal: grandTotal,
          withDays: false,
        );
        break;
      case TimeReportFormat.treeWithDays:
        text = _renderTree(
          config: config,
          taskInfos: taskInfos,
          childrenByParent: childrenByParent,
          grandTotal: grandTotal,
          withDays: true,
        );
        break;
      case TimeReportFormat.flat:
        text = _renderFlat(
          config: config,
          taskInfos: taskInfos,
          grandTotal: grandTotal,
        );
        break;
      case TimeReportFormat.csv:
        text = _renderCsv(
          config: config,
          taskInfos: taskInfos,
          byId: byId,
        );
        break;
    }

    return TimeReportResult(
      text: text,
      totalDuration: grandTotal,
      recordsCount: grandCount,
    );
  }

  void _collectDescendants(
    int rootId,
    Map<int?, List<TaskRow>> childrenByParent,
    Set<int> out,
  ) {
    final children = childrenByParent[rootId];
    if (children == null) return;
    for (final child in children) {
      if (out.add(child.id)) {
        _collectDescendants(child.id, childrenByParent, out);
      }
    }
  }

  // ============================================================
  // Tree rendering (markdown)
  // ============================================================

  String _renderTree({
    required TimeReportConfig config,
    required Map<int, _TaskInfo> taskInfos,
    required Map<int?, List<TaskRow>> childrenByParent,
    required Duration grandTotal,
    required bool withDays,
  }) {
    final buf = StringBuffer();
    _writeMarkdownHeader(buf, config, grandTotal);

    // Find the roots of the *effective* forest: tasks in taskInfos whose
    // parent is not also in taskInfos.
    final effectiveIds = taskInfos.keys.toSet();
    final roots = taskInfos.values.where((info) {
      final pid = info.row.parentId;
      return pid == null || !effectiveIds.contains(pid);
    }).toList()
      ..sort((a, b) {
        final ao = a.row.orderId;
        final bo = b.row.orderId;
        if (ao != bo) return ao.compareTo(bo);
        return a.row.title.toLowerCase().compareTo(b.row.title.toLowerCase());
      });

    if (roots.isEmpty) {
      buf.writeln('_No time records in the selected period._');
      return buf.toString();
    }

    for (final root in roots) {
      _writeTreeNode(
        buf: buf,
        info: root,
        depth: 0,
        taskInfos: taskInfos,
        childrenByParent: childrenByParent,
        config: config,
        withDays: withDays,
      );
    }

    return buf.toString();
  }

  void _writeTreeNode({
    required StringBuffer buf,
    required _TaskInfo info,
    required int depth,
    required Map<int, _TaskInfo> taskInfos,
    required Map<int?, List<TaskRow>> childrenByParent,
    required TimeReportConfig config,
    required bool withDays,
  }) {
    final cumulative = _cumulative(info.row.id, taskInfos, childrenByParent);
    if (!config.showEmptyTasks && cumulative == Duration.zero) return;

    final indent = '  ' * depth;
    final title = _escapeMarkdown(_titleOrUntitled(info.row.title));
    final cumulativeStr = DurationFormatter.formatHuman(cumulative);
    final ownStr = DurationFormatter.formatHuman(info.ownDuration);

    if (info.ownDuration != cumulative && info.ownDuration > Duration.zero) {
      buf.writeln('$indent- **$title** — $cumulativeStr _(self: $ownStr)_');
    } else if (info.ownDuration == cumulative) {
      buf.writeln('$indent- **$title** — $cumulativeStr');
    } else {
      buf.writeln('$indent- **$title** — $cumulativeStr');
    }

    if (withDays && info.clippedRecords.isNotEmpty) {
      final perDay = _aggregateByDay(info.clippedRecords);
      final sortedDays = perDay.keys.toList()..sort();
      for (final day in sortedDays) {
        final dayDur = perDay[day]!;
        if (dayDur == Duration.zero) continue;
        buf.writeln(
          '$indent  - $day — ${DurationFormatter.formatHuman(dayDur)}',
        );
      }
    }

    // Recurse into children that are also in the effective set.
    final children = childrenByParent[info.row.id] ?? const <TaskRow>[];
    for (final child in children) {
      final childInfo = taskInfos[child.id];
      if (childInfo == null) continue;
      _writeTreeNode(
        buf: buf,
        info: childInfo,
        depth: depth + 1,
        taskInfos: taskInfos,
        childrenByParent: childrenByParent,
        config: config,
        withDays: withDays,
      );
    }
  }

  /// Cumulative time of a task, including all descendants that are present
  /// in [taskInfos]. Tasks not in the effective set contribute zero.
  Duration _cumulative(
    int taskId,
    Map<int, _TaskInfo> taskInfos,
    Map<int?, List<TaskRow>> childrenByParent,
  ) {
    final info = taskInfos[taskId];
    var total = info?.ownDuration ?? Duration.zero;
    final children = childrenByParent[taskId] ?? const <TaskRow>[];
    for (final child in children) {
      total += _cumulative(child.id, taskInfos, childrenByParent);
    }
    return total;
  }

  // ============================================================
  // Flat rendering (markdown)
  // ============================================================

  String _renderFlat({
    required TimeReportConfig config,
    required Map<int, _TaskInfo> taskInfos,
    required Duration grandTotal,
  }) {
    final buf = StringBuffer();
    _writeMarkdownHeader(buf, config, grandTotal);

    final all = <_FlatRow>[];
    for (final info in taskInfos.values) {
      for (final rec in info.clippedRecords) {
        all.add(_FlatRow(
          start: rec.start.toLocal(),
          end: rec.end.toLocal(),
          duration: rec.duration,
          taskTitle: _titleOrUntitled(info.row.title),
          isOngoing: rec.isOngoing,
        ));
      }
    }
    all.sort((a, b) => a.start.compareTo(b.start));

    if (all.isEmpty) {
      buf.writeln('_No time records in the selected period._');
      return buf.toString();
    }

    for (final row in all) {
      final date = _formatDate(row.start);
      final start = _formatTime(row.start);
      final end = _formatTime(row.end);
      final dur = DurationFormatter.formatHuman(row.duration);
      final ongoing = row.isOngoing ? ' _(ongoing)_' : '';
      buf.writeln(
        '- $date $start–$end ($dur) — ${_escapeMarkdown(row.taskTitle)}$ongoing',
      );
    }

    return buf.toString();
  }

  // ============================================================
  // CSV rendering
  // ============================================================

  String _renderCsv({
    required TimeReportConfig config,
    required Map<int, _TaskInfo> taskInfos,
    required Map<int, TaskRow> byId,
  }) {
    final buf = StringBuffer();
    buf.writeln(
      'task_path,task_id,date,start_time,end_time,duration_seconds,ongoing',
    );

    final all = <_CsvRow>[];
    for (final info in taskInfos.values) {
      final path = _taskPath(info.row, byId);
      for (final rec in info.clippedRecords) {
        all.add(_CsvRow(
          taskPath: path,
          taskId: info.row.id,
          start: rec.start.toLocal(),
          end: rec.end.toLocal(),
          duration: rec.duration,
          isOngoing: rec.isOngoing,
        ));
      }
    }
    all.sort((a, b) => a.start.compareTo(b.start));

    for (final row in all) {
      buf.writeln([
        _csvEscape(row.taskPath),
        row.taskId.toString(),
        _formatDate(row.start),
        _formatTime(row.start),
        _formatTime(row.end),
        row.duration.inSeconds.toString(),
        row.isOngoing ? 'true' : 'false',
      ].join(','));
    }

    return buf.toString();
  }

  String _taskPath(TaskRow row, Map<int, TaskRow> byId) {
    final segments = <String>[];
    TaskRow? current = row;
    while (current != null) {
      segments.add(_titleOrUntitled(current.title));
      final pid = current.parentId;
      current = pid == null ? null : byId[pid];
    }
    return segments.reversed.join(' / ');
  }

  // ============================================================
  // Helpers
  // ============================================================

  void _writeMarkdownHeader(
    StringBuffer buf,
    TimeReportConfig config,
    Duration total,
  ) {
    final from = _formatDate(config.fromDate);
    final to = _formatDate(config.toDate);
    final now = _formatDateTime(DateTime.now());

    buf.writeln('# Time Report');
    buf.writeln();
    buf.writeln('**Period:** $from — $to  ');
    buf.writeln('**Total:** ${DurationFormatter.formatHuman(total)}  ');
    buf.writeln('**Generated:** $now');
    buf.writeln();
    buf.writeln(
      '_Records that straddle the period boundaries are clipped to the range._',
    );
    buf.writeln();
  }

  Map<String, Duration> _aggregateByDay(List<_ClippedRecord> records) {
    final result = <String, Duration>{};
    for (final rec in records) {
      var cursorLocal = rec.start.toLocal();
      final endLocal = rec.end.toLocal();
      while (cursorLocal.isBefore(endLocal)) {
        final dayStart = DateTime(
          cursorLocal.year,
          cursorLocal.month,
          cursorLocal.day,
        );
        // Next local midnight via calendar arithmetic (day + 1), not a fixed
        // 24h add — otherwise on a DST-transition day the boundary lands at
        // 01:00 and work is bucketed into the wrong date.
        final nextMidnight = DateTime(
          cursorLocal.year,
          cursorLocal.month,
          cursorLocal.day + 1,
        );
        final segStart = cursorLocal;
        final segEnd = endLocal.isBefore(nextMidnight) ? endLocal : nextMidnight;
        final key = _formatDate(dayStart);
        result[key] = (result[key] ?? Duration.zero) + segEnd.difference(segStart);
        cursorLocal = nextMidnight;
      }
    }
    return result;
  }

  String _titleOrUntitled(String raw) {
    final t = raw.trim();
    return t.isEmpty ? '(untitled)' : t;
  }

  String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _formatTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _formatDateTime(DateTime d) {
    return '${_formatDate(d)} ${_formatTime(d)}';
  }

  String _escapeMarkdown(String s) {
    return s
        .replaceAll(r'\', r'\\')
        .replaceAll('*', r'\*')
        .replaceAll('_', r'\_')
        .replaceAll('[', r'\[')
        .replaceAll(']', r'\]');
  }

  String _csvEscape(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }
}

// ============================================================
// Internal value types
// ============================================================

class _TaskInfo {
  final TaskRow row;
  final Duration ownDuration;
  final List<_ClippedRecord> clippedRecords;

  const _TaskInfo({
    required this.row,
    required this.ownDuration,
    required this.clippedRecords,
  });
}

class _ClippedRecord {
  final DateTime start; // UTC
  final DateTime end; // UTC
  final Duration duration;
  final bool isOngoing;

  const _ClippedRecord({
    required this.start,
    required this.end,
    required this.duration,
    required this.isOngoing,
  });
}

class _FlatRow {
  final DateTime start;
  final DateTime end;
  final Duration duration;
  final String taskTitle;
  final bool isOngoing;

  const _FlatRow({
    required this.start,
    required this.end,
    required this.duration,
    required this.taskTitle,
    required this.isOngoing,
  });
}

class _CsvRow {
  final String taskPath;
  final int taskId;
  final DateTime start;
  final DateTime end;
  final Duration duration;
  final bool isOngoing;

  const _CsvRow({
    required this.taskPath,
    required this.taskId,
    required this.start,
    required this.end,
    required this.duration,
    required this.isOngoing,
  });
}
