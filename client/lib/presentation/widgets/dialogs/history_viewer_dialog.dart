import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/database/database.dart';
import '../../../data/services/history_service.dart';
import '../../providers/providers.dart';

/// A single field change within a grouped entry
class FieldChange {
  final String field;
  final String? oldValue;
  final String? newValue;

  FieldChange({
    required this.field,
    this.oldValue,
    this.newValue,
  });

  String get changeType {
    if (oldValue == null && newValue != null) return 'CREATE';
    if (oldValue != null && newValue == null) return 'DELETE';
    return 'UPDATE';
  }
}

/// A grouped history entry combining multiple field changes
class GroupedHistoryEntry {
  final String entityType;
  final int entityId;
  final DateTime timestamp;
  final List<FieldChange> changes;

  GroupedHistoryEntry({
    required this.entityType,
    required this.entityId,
    required this.timestamp,
    required this.changes,
  });

  /// Overall change type based on the fields changed
  String get changeType {
    // If all changes are creates (oldValue == null), it's a CREATE
    if (changes.every((c) => c.oldValue == null && c.newValue != null)) {
      return 'CREATE';
    }
    // If 'removed' field changed to '1', it's a DELETE
    final removedChange = changes.where((c) => c.field == 'removed').firstOrNull;
    if (removedChange != null && removedChange.newValue == '1') {
      return 'DELETE';
    }
    return 'UPDATE';
  }

  Color getChangeColor(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    switch (changeType) {
      case 'CREATE':
        return Colors.green;
      case 'DELETE':
        return colors.error;
      default:
        return Colors.blue;
    }
  }

  /// Key for grouping: entityType + entityId + timestamp (rounded to second)
  static String groupKey(String entityType, int entityId, DateTime timestamp) {
    // Round timestamp to nearest second for grouping
    final rounded = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
      timestamp.hour,
      timestamp.minute,
      timestamp.second,
    );
    return '$entityType:$entityId:${rounded.toIso8601String()}';
  }
}

/// Temporary class for collecting changes before grouping
class _TempChange {
  final String entityType;
  final int entityId;
  final String field;
  final String? oldValue;
  final String? newValue;
  final DateTime timestamp;

  _TempChange({
    required this.entityType,
    required this.entityId,
    required this.field,
    this.oldValue,
    this.newValue,
    required this.timestamp,
  });
}

/// Dialog to view change history from the database
class HistoryViewerDialog extends ConsumerStatefulWidget {
  const HistoryViewerDialog({super.key});

  @override
  ConsumerState<HistoryViewerDialog> createState() => _HistoryViewerDialogState();
}

class _HistoryViewerDialogState extends ConsumerState<HistoryViewerDialog> {
  List<GroupedHistoryEntry> _entries = [];
  int _totalFieldChanges = 0;
  bool _loading = true;
  String _filter = 'all';
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final db = ref.read(databaseProvider);
      if (db == null) {
        setState(() {
          _error = 'No database open';
          _loading = false;
        });
        return;
      }

      // Temporary structure to collect changes before grouping
      final changesByKey = <String, List<_TempChange>>{};
      int totalChanges = 0;

      // Load task history
      final taskHistory = await db.getAllTaskHistory();

      // Title/content rows store dmp patches, not values (and their old
      // value only as each chain's base) — replay every chain so the dialog
      // shows the actual before/after text.
      final chains = <String, List<HistoryTaskData>>{};
      for (final h in taskHistory) {
        if (h.field == 'title' || h.field == 'content') {
          chains.putIfAbsent('${h.taskId}:${h.field}', () => []).add(h);
        }
      }
      final reconstructed = <int, ({String? oldValue, String? newValue})>{};
      for (final chain in chains.values) {
        final values = HistoryService.reconstructTaskFieldChain(chain);
        for (var i = 0; i < chain.length; i++) {
          reconstructed[chain[i].id] = values[i];
        }
      }

      for (final h in taskHistory) {
        final timestamp = DateTime.parse(h.timestamp);
        final key = GroupedHistoryEntry.groupKey('task', h.taskId, timestamp);
        changesByKey.putIfAbsent(key, () => []);
        final rec = reconstructed[h.id];
        changesByKey[key]!.add(_TempChange(
          entityType: 'task',
          entityId: h.taskId,
          field: h.field,
          oldValue: _truncateValue(rec != null ? rec.oldValue : h.oldValue),
          newValue: _truncateValue(rec != null ? rec.newValue : h.newValue),
          timestamp: timestamp,
        ));
        totalChanges++;
      }

      // Load file history
      final fileHistory = await db.getAllFileHistory();
      for (final h in fileHistory) {
        final timestamp = DateTime.parse(h.timestamp);
        final key = GroupedHistoryEntry.groupKey('file', h.fileId, timestamp);
        changesByKey.putIfAbsent(key, () => []);
        changesByKey[key]!.add(_TempChange(
          entityType: 'file',
          entityId: h.fileId,
          field: h.field,
          oldValue: _truncateValue(h.oldValue),
          newValue: _truncateValue(h.newValue),
          timestamp: timestamp,
        ));
        totalChanges++;
      }

      // Load timeline history
      final timelineHistory = await db.getAllTimelineHistory();
      for (final h in timelineHistory) {
        final timestamp = DateTime.parse(h.timestamp);
        final key = GroupedHistoryEntry.groupKey('timeline', h.timelineId, timestamp);
        changesByKey.putIfAbsent(key, () => []);
        changesByKey[key]!.add(_TempChange(
          entityType: 'timeline',
          entityId: h.timelineId,
          field: h.field,
          oldValue: h.oldValue,
          newValue: h.newValue,
          timestamp: timestamp,
        ));
        totalChanges++;
      }

      // Convert to grouped entries
      final entries = <GroupedHistoryEntry>[];
      for (final changes in changesByKey.values) {
        if (changes.isEmpty) continue;
        final first = changes.first;
        entries.add(GroupedHistoryEntry(
          entityType: first.entityType,
          entityId: first.entityId,
          timestamp: first.timestamp,
          changes: changes
              .map((c) => FieldChange(
                    field: c.field,
                    oldValue: c.oldValue,
                    newValue: c.newValue,
                  ))
              .toList(),
        ));
      }

      // Sort by timestamp descending (newest first)
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _entries = entries;
        _totalFieldChanges = totalChanges;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String? _truncateValue(String? value) {
    if (value == null) return null;
    if (value.length > 100) {
      return '${value.substring(0, 100)}...';
    }
    return value;
  }

  List<GroupedHistoryEntry> get _filteredEntries {
    if (_filter == 'all') return _entries;
    return _entries.where((e) => e.entityType == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Dialog(
      child: Container(
        width: 800,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Change History',
                  style: theme.textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadHistory,
                  tooltip: 'Refresh',
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Filter chips
            Row(
              children: [
                const Text('Filter: '),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('All (${_entries.length})'),
                  selected: _filter == 'all',
                  onSelected: (_) => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Tasks (${_entries.where((e) => e.entityType == 'task').length})'),
                  selected: _filter == 'task',
                  onSelected: (_) => setState(() => _filter = 'task'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Files (${_entries.where((e) => e.entityType == 'file').length})'),
                  selected: _filter == 'file',
                  onSelected: (_) => setState(() => _filter = 'file'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: Text('Timeline (${_entries.where((e) => e.entityType == 'timeline').length})'),
                  selected: _filter == 'timeline',
                  onSelected: (_) => setState(() => _filter = 'timeline'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),

            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
                              const SizedBox(height: 16),
                              Text('Error: $_error'),
                            ],
                          ),
                        )
                      : _filteredEntries.isEmpty
                          ? const Center(child: Text('No history entries found'))
                          : ListView.builder(
                              itemCount: _filteredEntries.length,
                              itemBuilder: (context, index) {
                                final entry = _filteredEntries[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Header row
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: entry.getChangeColor(context).withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                entry.changeType,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: entry.getChangeColor(context),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.surfaceContainerHighest,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '${entry.entityType} #${entry.entityId}',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${entry.changes.length} field${entry.changes.length > 1 ? 's' : ''} changed',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: theme.colorScheme.outline,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              dateFormat.format(entry.timestamp.toLocal()),
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: theme.colorScheme.outline,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Field changes
                                        ...entry.changes.map((change) => _buildFieldChangeRow(
                                          context,
                                          change,
                                          theme,
                                        )),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),

            // Footer stats
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Showing ${_filteredEntries.length} of ${_entries.length} grouped entries ($_totalFieldChanges total field changes)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldChangeRow(BuildContext context, FieldChange change, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Field name with change type indicator
          Row(
            children: [
              Icon(
                change.changeType == 'CREATE'
                    ? Icons.add_circle_outline
                    : change.changeType == 'DELETE'
                        ? Icons.remove_circle_outline
                        : Icons.edit_outlined,
                size: 14,
                color: change.changeType == 'CREATE'
                    ? Colors.green
                    : change.changeType == 'DELETE'
                        ? theme.colorScheme.error
                        : Colors.blue,
              ),
              const SizedBox(width: 4),
              Text(
                change.field,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          // Old value
          if (change.oldValue != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      'Old:',
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(
                        change.oldValue!,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // New value
          if (change.newValue != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(
                      'New:',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: SelectableText(
                        change.newValue!,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
