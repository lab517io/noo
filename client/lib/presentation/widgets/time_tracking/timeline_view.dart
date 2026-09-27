import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/duration_formatter.dart';
import '../../../core/utils/platform_info.dart';
import '../../../domain/entities/time_line.dart';
import '../../../domain/entities/time_record.dart';
import '../../providers/providers.dart';
import '../../providers/settings_provider.dart';
import 'time_interval_dialog.dart';

/// A task's individual time records as a Year > Month > Day > Interval tree,
/// with the commands that add, edit and remove them. Equivalent to Qt's
/// TimeTreeDlg body.
///
/// Body only, so it can be hosted either by [TimelineDialog] (desktop, where
/// the timeline is something you open, look at and dismiss) or directly by the
/// Time tab of the phone task screen, where it is simply part of the node.
///
/// Owns its copy of the [timeLine] because every edit here reloads it from the
/// database; a new value from the host — a sync landing, tracking stopping —
/// is adopted in [didUpdateWidget].
class TimelineView extends ConsumerStatefulWidget {
  final int taskId;
  final TimeLine timeLine;

  /// Called after any change reaches the database, so the host can refresh
  /// whatever else reads the same records.
  final VoidCallback? onChanged;

  const TimelineView({
    super.key,
    required this.taskId,
    required this.timeLine,
    this.onChanged,
  });

  @override
  ConsumerState<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends ConsumerState<TimelineView> {
  late TimeLine _timeLine;
  int? _selectedRecordId;

  @override
  void initState() {
    super.initState();
    _timeLine = widget.timeLine;
  }

  @override
  void didUpdateWidget(TimelineView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only when the host actually hands over a different set of records: our
    // own reloads already hold the newer copy, and overwriting it here would
    // undo an edit the host has not caught up with yet.
    if (!identical(widget.timeLine, oldWidget.timeLine)) {
      _timeLine = widget.timeLine;
    }
  }

  Future<void> _reload() async {
    final db = ref.read(databaseProvider);
    if (db == null) return;

    final entries = await db.getTimelineForTask(widget.taskId);
    if (!mounted) return;

    final records = entries.map((e) => TimeRecord(
      id: e.id,
      taskId: e.taskId,
      worldId: WorldId.fromString(e.worldId),
      startTime: DateTime.parse(e.startTime).toUtc(),
      endTime: e.endTime != null ? DateTime.parse(e.endTime!).toUtc() : null,
      saved: true,
    )).toList();

    setState(() {
      _timeLine = TimeLine(records: records);
    });

    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    final list = _timeLine.records.isEmpty
        ? _buildEmptyState(context)
        : _buildTree(context, settings);

    // A phone has no width to spare for a button column beside the tree: the
    // records themselves would be left with about half the screen. Below the
    // list the buttons cost one row and the tree keeps the full width.
    if (isCompactLayout(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: list),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _addInterval(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _selectedRecordId != null
                        ? () => _removeInterval(context)
                        : null,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Remove'),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: list),
        const SizedBox(width: 16),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 100,
              child: FilledButton(
                onPressed: () => _addInterval(context),
                child: const Text('Add...'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 100,
              child: OutlinedButton(
                onPressed: _selectedRecordId != null
                    ? () => _removeInterval(context)
                    : null,
                child: const Text('Remove'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Text(
        'No time records',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildTree(BuildContext context, AppSettings settings) {
    final years = _timeLine.getYears().toList()..sort((a, b) => b.compareTo(a));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final year in years) _buildYearNode(context, settings, year),
        ],
      ),
    );
  }

  Widget _buildYearNode(BuildContext context, AppSettings settings, int year) {
    final months = _timeLine.getMonths(year).toList()
      ..sort((a, b) => b.compareTo(a));

    return ExpansionTile(
      key: ValueKey('year_$year'),
      title: Text(
        '$year',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      initiallyExpanded: year == DateTime.now().year,
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      childrenPadding: const EdgeInsets.only(left: 16),
      children: [
        for (final month in months) _buildMonthNode(context, settings, year, month),
      ],
    );
  }

  Widget _buildMonthNode(BuildContext context, AppSettings settings, int year, int month) {
    final days = _timeLine.getDays(year, month).toList()
      ..sort((a, b) => b.compareTo(a));
    final monthName = DateFormat.MMMM().format(DateTime(year, month));

    final now = DateTime.now();
    final isCurrentMonth = year == now.year && month == now.month;

    return ExpansionTile(
      key: ValueKey('month_${year}_$month'),
      title: Text(monthName),
      initiallyExpanded: isCurrentMonth,
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      childrenPadding: const EdgeInsets.only(left: 16),
      children: [
        for (final day in days) _buildDayNode(context, settings, year, month, day),
      ],
    );
  }

  Widget _buildDayNode(BuildContext context, AppSettings settings, int year, int month, int day) {
    final date = DateTime(year, month, day);
    final records = _timeLine.records.where((r) {
      final local = r.startTime.toLocal();
      return local.year == year && local.month == month && local.day == day;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final now = DateTime.now();
    final isToday = year == now.year && month == now.month && day == now.day;

    return ExpansionTile(
      key: ValueKey('day_${year}_${month}_$day'),
      title: Text(
        '$day (${DateFormat.E().format(date)})',
        style: isToday
            ? TextStyle(color: Theme.of(context).colorScheme.primary)
            : null,
      ),
      initiallyExpanded: isToday,
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      childrenPadding: const EdgeInsets.only(left: 16),
      children: [
        for (final record in records)
          _buildIntervalTile(context, settings, record),
      ],
    );
  }

  Widget _buildIntervalTile(BuildContext context, AppSettings settings, TimeRecord record) {
    final timeFormat = settings.showSeconds
        ? DateFormat.Hms()
        : DateFormat.Hm();

    final startStr = timeFormat.format(record.startTime.toLocal());
    final endStr = record.endTime != null
        ? timeFormat.format(record.endTime!.toLocal())
        : 'now';

    final durationStr = DurationFormatter.formatHuman(record.duration);
    final isSelected = _selectedRecordId == record.id;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
      leading: Icon(
        Icons.schedule,
        size: 16,
        color: record.isActive
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.outline,
      ),
      title: Text(
        '$startStr - $endStr',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      trailing: Text(
        durationStr,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: () {
        setState(() {
          _selectedRecordId = isSelected ? null : record.id;
        });
      },
      onLongPress: () {
        if (record.id != null && record.endTime != null) {
          _editInterval(context, record);
        }
      },
    );
  }

  Future<void> _addInterval(BuildContext context) async {
    final now = DateTime.now();
    final defaultStart = now.subtract(const Duration(minutes: 10));

    final result = await showDialog<TimeIntervalResult>(
      context: context,
      builder: (context) => TimeIntervalDialog(
        initialStart: defaultStart,
        initialEnd: now,
        timeLine: _timeLine,
        mode: TimeIntervalMode.add,
      ),
    );

    if (result == null) return;

    final db = ref.read(databaseProvider);
    if (db == null) return;

    await db.createTimeRecord(
      taskId: widget.taskId,
      worldId: WorldId.create().value,
      startTime: result.startTime.toUtc().toIso8601String(),
      endTime: result.endTime.toUtc().toIso8601String(),
    );

    await _reload();
  }

  Future<void> _editInterval(BuildContext context, TimeRecord record) async {
    final result = await showDialog<TimeIntervalResult>(
      context: context,
      builder: (context) => TimeIntervalDialog(
        initialStart: record.startTime.toLocal(),
        initialEnd: record.endTime!.toLocal(),
        timeLine: _timeLine,
        mode: TimeIntervalMode.edit,
        editingRecordId: record.id,
      ),
    );

    if (result == null || record.id == null) return;

    final db = ref.read(databaseProvider);
    if (db == null) return;

    await db.updateTimeRecord(
      record.id!,
      startTime: result.startTime.toUtc().toIso8601String(),
      endTime: result.endTime.toUtc().toIso8601String(),
    );

    await _reload();
  }

  Future<void> _removeInterval(BuildContext context) async {
    if (_selectedRecordId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove interval?'),
        content: const Text('Are you sure you want to remove this time interval?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final db = ref.read(databaseProvider);
    if (db == null) return;

    await db.deleteTimeRecord(_selectedRecordId!);

    setState(() {
      _selectedRecordId = null;
    });

    await _reload();
  }
}
