import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/platform_info.dart';
import '../../../data/database/database.dart';
import '../../../data/services/sync_journal.dart';
import '../../providers/providers.dart';
import 'classic_form.dart';

/// Show the persistent sync log: every run's packets, hashes and merge
/// decisions, newest first. Unlike Sync Details, which shows the run in
/// progress, this reads what was recorded — across restarts and across every
/// kind of sync (relay, nearby devices, peers pulling from this device).
Future<void> showSyncLogDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const SyncLogDialog(),
  );
}

/// What started a run, for people.
const _triggerLabels = <String, String>{
  'relay': 'Server sync',
  'lan': 'Nearby devices',
  'lan-return': 'Nearby device (requested)',
  'lan-serve': 'Served to nearby device',
  'package': 'Packaged local changes',
  'compaction': 'Compaction',
  'identity-reset': 'Device identity reset',
  'attachment': 'Attachment download',
  'blob-collect': 'Attachment clean-up',
};

enum _LevelFilter { all, warnings, errors }

enum _DirectionFilter { all, incoming, outgoing, local }

class SyncLogDialog extends ConsumerStatefulWidget {
  const SyncLogDialog({super.key});

  @override
  ConsumerState<SyncLogDialog> createState() => _SyncLogDialogState();
}

class _SyncLogDialogState extends ConsumerState<SyncLogDialog> {
  static const int _eventLimit = 5000;

  final TextEditingController _search = TextEditingController();
  Timer? _searchDebounce;
  Timer? _reloadDebounce;
  StreamSubscription<void>? _updates;

  List<SyncLogRunRow> _runs = const [];
  List<SyncLogEventRow> _events = const [];
  Map<String, String> _labels = const {};

  /// Selected run, or null for every run.
  int? _runId;
  _LevelFilter _level = _LevelFilter.all;
  _DirectionFilter _direction = _DirectionFilter.all;
  bool _loading = true;

  /// Events whose details are expanded, by row id.
  final Set<int> _expanded = {};

  NooDatabase? get _db => ref.read(databaseProvider);

  @override
  void initState() {
    super.initState();
    final db = _db;
    if (db != null) {
      // Follow a sync that is running while the log is open.
      _updates = db
          .tableUpdates(TableUpdateQuery.onAllTables([db.syncLogRuns]))
          .listen((_) {
        _reloadDebounce?.cancel();
        _reloadDebounce =
            Timer(const Duration(milliseconds: 400), () => _reload());
      });
    }
    _search.addListener(() {
      _searchDebounce?.cancel();
      _searchDebounce =
          Timer(const Duration(milliseconds: 250), () => _reload());
    });
    _reload(selectNewest: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _reloadDebounce?.cancel();
    _updates?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _reload({bool selectNewest = false}) async {
    final db = _db;
    if (db == null) return;
    final runs = await db.getSyncLogRuns(limit: SyncJournal.maxRuns);
    var runId = _runId;
    if (selectNewest) runId = runs.isEmpty ? null : runs.first.id;
    if (runId != null && !runs.any((r) => r.id == runId)) runId = null;

    final text = _search.text.trim();
    final worldIds = text.length >= 2
        ? await db.worldIdsMatchingName(text)
        : const <String>{};
    final events = await db.getSyncLogEvents(
      runId: runId,
      minLevel: switch (_level) {
        _LevelFilter.all => 0,
        _LevelFilter.warnings => SyncLogLevel.warning.index,
        _LevelFilter.errors => SyncLogLevel.error.index,
      },
      direction: switch (_direction) {
        _DirectionFilter.all => null,
        _DirectionFilter.incoming => 'in',
        _DirectionFilter.outgoing => 'out',
        _DirectionFilter.local => 'local',
      },
      search: text,
      worldIds: worldIds,
      limit: _eventLimit,
    );
    final labels = await db.syncLogLabels({
      for (final e in events)
        if (e.worldId != null) e.worldId!,
    });
    if (!mounted) return;
    setState(() {
      _runs = runs;
      _runId = runId;
      _events = events;
      _labels = labels;
      _loading = false;
    });
  }

  void _selectRun(int? id) {
    setState(() {
      _runId = id;
      _expanded.clear();
    });
    _reload();
  }

  Future<void> _copyJson() async {
    final runIds = {for (final e in _events) e.runId};
    final data = {
      'exported_at': NooDatabase.nowIso(),
      'filters': {
        'run': _runId,
        'level': _level.name,
        'direction': _direction.name,
        'search': _search.text,
      },
      'runs': [
        for (final r in _runs)
          if (runIds.contains(r.id) || r.id == _runId) r.toJson(),
      ],
      'events': [
        for (final e in _events)
          {
            ...e.toJson(),
            if (e.worldId != null && _labels[e.worldId] != null)
              'label': _labels[e.worldId],
          },
      ],
    };
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(data)),
    );
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text('Copied ${_events.length} event(s) as JSON')),
    );
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear sync log?'),
        content: const Text(
          'Every recorded run and event on this device is deleted. Synced '
          'data is not affected.',
        ),
        actions: [
          OutlinedButton(
            style: classicButtonStyle(context),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: classicButtonStyle(context),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _db?.clearSyncLog();
    _expanded.clear();
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    final toolbar = _Toolbar(
      search: _search,
      level: _level,
      direction: _direction,
      onLevel: (v) {
        setState(() => _level = v);
        _reload();
      },
      onDirection: (v) {
        setState(() => _direction = v);
        _reload();
      },
    );

    final eventsPane = _loading
        ? const Center(child: CircularProgressIndicator())
        : _EventList(
            events: _events,
            labels: _labels,
            showRun: _runId == null,
            truncated: _events.length >= _eventLimit,
            expanded: _expanded,
            onToggle: (id) => setState(() {
              if (!_expanded.remove(id)) _expanded.add(id);
            }),
          );

    if (compact) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Sync Log'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy_all_outlined),
                tooltip: 'Copy as JSON',
                onPressed: _events.isEmpty ? null : _copyJson,
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Clear log',
                onPressed: _runs.isEmpty ? null : _clear,
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RunDropdown(
                    runs: _runs,
                    selected: _runId,
                    onSelected: _selectRun,
                  ),
                  const SizedBox(height: 8),
                  toolbar,
                  const SizedBox(height: 8),
                  Expanded(child: eventsPane),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final scale = classicUiScale(context);
    return AlertDialog(
      title: const Text('Sync Log'),
      titleTextStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      content: SizedBox(
        width: (1080 * scale).clamp(0, size.width - 80),
        height: (720 * scale).clamp(0, size.height - 180),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 290 * scale,
              child: _RunList(
                runs: _runs,
                selected: _runId,
                onSelected: _selectRun,
              ),
            ),
            const VerticalDivider(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  toolbar,
                  const SizedBox(height: 8),
                  Expanded(child: eventsPane),
                ],
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      actions: [
        OutlinedButton(
          style: classicButtonStyle(context),
          onPressed: _runs.isEmpty ? null : _clear,
          child: const Text('Clear Log'),
        ),
        OutlinedButton(
          style: classicButtonStyle(context),
          onPressed: _events.isEmpty ? null : _copyJson,
          child: const Text('Copy as JSON'),
        ),
        FilledButton(
          style: classicButtonStyle(context),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// ============================================================
// Runs
// ============================================================

final DateFormat _runStamp = DateFormat('MMM d, HH:mm:ss');
final DateFormat _eventStamp = DateFormat('HH:mm:ss.SSS');

String _localStamp(DateFormat format, String iso) {
  final parsed = DateTime.tryParse(iso);
  return parsed == null ? iso : format.format(parsed.toLocal());
}

Map<String, int> _countsOf(SyncLogRunRow run) {
  try {
    return (jsonDecode(run.countsJson) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v as int));
  } catch (_) {
    return const {};
  }
}

/// "↓ 3 packets · ↑ 1 · 12 applied · 2 warnings".
String _runSummary(SyncLogRunRow run) {
  final c = _countsOf(run);
  int n(String k) => c[k] ?? 0;
  final received = n(SyncLogKind.packetStored);
  final sent = n(SyncLogKind.packaged) + n(SyncLogKind.served);
  final pushed = n(SyncLogKind.pushed);
  final applied = n(SyncLogKind.applied) + n(SyncLogKind.created);
  final parts = <String>[
    if (received > 0) '↓ $received',
    if (sent > 0 || pushed > 0) '↑ ${sent > pushed ? sent : pushed}',
    if (applied > 0) '$applied applied',
    if (n('warnings') > 0) '${n('warnings')} warning${n('warnings') == 1 ? '' : 's'}',
    if (n('errors') > 0) '${n('errors')} error${n('errors') == 1 ? '' : 's'}',
  ];
  return parts.isEmpty ? 'Nothing exchanged' : parts.join(' · ');
}

({IconData icon, Color color}) _outcomeIcon(ThemeData theme, SyncLogRunRow run) {
  final counts = _countsOf(run);
  switch (run.outcome) {
    case 'running':
      return (icon: Icons.sync, color: theme.colorScheme.primary);
    case 'failed':
    case 'interrupted':
      return (icon: Icons.error_outline, color: theme.colorScheme.error);
    case 'declined':
    case 'busy':
      return (icon: Icons.do_not_disturb_on_outlined, color: theme.hintColor);
  }
  if ((counts['errors'] ?? 0) > 0) {
    return (icon: Icons.error_outline, color: theme.colorScheme.error);
  }
  if ((counts['warnings'] ?? 0) > 0) {
    return (icon: Icons.warning_amber_rounded, color: Colors.orange.shade700);
  }
  return (icon: Icons.check_circle_outline, color: Colors.green.shade600);
}

class _RunList extends StatelessWidget {
  final List<SyncLogRunRow> runs;
  final int? selected;
  final ValueChanged<int?> onSelected;

  const _RunList({
    required this.runs,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (runs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          'No sync has been recorded yet. Runs appear here as this device '
          'syncs with the server or with nearby devices.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      );
    }
    return ListView.builder(
      itemCount: runs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _RunTile(
            selected: selected == null,
            onTap: () => onSelected(null),
            leading: Icon(Icons.all_inclusive, size: 18, color: theme.hintColor),
            title: 'All runs',
            subtitle: '${runs.length} recorded',
          );
        }
        final run = runs[index - 1];
        final outcome = _outcomeIcon(theme, run);
        final remote = run.remote;
        return _RunTile(
          selected: selected == run.id,
          onTap: () => onSelected(run.id),
          leading: Icon(outcome.icon, size: 18, color: outcome.color),
          title: '${_localStamp(_runStamp, run.startedAt)}  ·  '
              '${_triggerLabels[run.trigger] ?? run.trigger}',
          subtitle: [
            if (remote != null && remote.isNotEmpty && run.trigger != 'relay')
              remote,
            if (run.outcome != 'ok') run.outcome,
            _runSummary(run),
          ].join(' · '),
        );
      },
    );
  }
}

class _RunTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;

  const _RunTile({
    required this.selected,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.secondaryContainer
          : Colors.transparent,
      borderRadius: BorderRadius.circular(3),
      child: InkWell(
        borderRadius: BorderRadius.circular(3),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.only(top: 1), child: leading),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(subtitle,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RunDropdown extends StatelessWidget {
  final List<SyncLogRunRow> runs;
  final int? selected;
  final ValueChanged<int?> onSelected;

  const _RunDropdown({
    required this.runs,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int?>(
      initialValue: selected,
      isExpanded: true,
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
        labelText: 'Run',
      ),
      items: [
        DropdownMenuItem<int?>(
          value: null,
          child: Text('All runs (${runs.length})'),
        ),
        for (final run in runs)
          DropdownMenuItem<int?>(
            value: run.id,
            child: Text(
              '${_localStamp(_runStamp, run.startedAt)} · '
              '${_triggerLabels[run.trigger] ?? run.trigger} · '
              '${_runSummary(run)}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: onSelected,
    );
  }
}

// ============================================================
// Filters
// ============================================================

class _Toolbar extends StatelessWidget {
  final TextEditingController search;
  final _LevelFilter level;
  final _DirectionFilter direction;
  final ValueChanged<_LevelFilter> onLevel;
  final ValueChanged<_DirectionFilter> onDirection;

  const _Toolbar({
    required this.search,
    required this.level,
    required this.direction,
    required this.onLevel,
    required this.onDirection,
  });

  @override
  Widget build(BuildContext context) {
    final searchField = ClassicTextField(
      controller: search,
      hintText: 'Search: node name, id, hash, device, kind…',
    );
    final levels = SegmentedButton<_LevelFilter>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: const [
        ButtonSegment(value: _LevelFilter.all, label: Text('All')),
        ButtonSegment(value: _LevelFilter.warnings, label: Text('Warnings')),
        ButtonSegment(value: _LevelFilter.errors, label: Text('Errors')),
      ],
      selected: {level},
      onSelectionChanged: (v) => onLevel(v.single),
    );
    final directions = DropdownButton<_DirectionFilter>(
      value: direction,
      isDense: true,
      underline: const SizedBox.shrink(),
      items: const [
        DropdownMenuItem(
            value: _DirectionFilter.all, child: Text('In and out')),
        DropdownMenuItem(
            value: _DirectionFilter.incoming, child: Text('Incoming')),
        DropdownMenuItem(
            value: _DirectionFilter.outgoing, child: Text('Outgoing')),
        DropdownMenuItem(value: _DirectionFilter.local, child: Text('Local')),
      ],
      onChanged: (v) {
        if (v != null) onDirection(v);
      },
    );

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 220, maxWidth: 360),
          child: searchField,
        ),
        levels,
        directions,
      ],
    );
  }
}

// ============================================================
// Events
// ============================================================

class _EventList extends StatelessWidget {
  final List<SyncLogEventRow> events;
  final Map<String, String> labels;
  final bool showRun;
  final bool truncated;
  final Set<int> expanded;
  final ValueChanged<int> onToggle;

  const _EventList({
    required this.events,
    required this.labels,
    required this.showRun,
    required this.truncated,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (events.isEmpty) {
      return Center(
        child: Text(
          'No events match.',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(3),
      ),
      child: ListView.separated(
        itemCount: events.length + (truncated ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == events.length) {
            return Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                'Showing the first ${events.length} events. Narrow the '
                'search or pick a run to see the rest.',
                style:
                    theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
              ),
            );
          }
          final event = events[index];
          final previous = index > 0 ? events[index - 1] : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showRun && previous?.runId != event.runId)
                Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  child: Text('Run #${event.runId}',
                      style: theme.textTheme.labelSmall),
                ),
              _EventRow(
                event: event,
                label: event.worldId == null ? null : labels[event.worldId],
                expanded: expanded.contains(event.id),
                onTap: () => onToggle(event.id),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _short(String? value, [int length = 8]) {
  if (value == null) return '';
  return value.length <= length ? value : value.substring(0, length);
}

class _EventRow extends StatelessWidget {
  final SyncLogEventRow event;
  final String? label;
  final bool expanded;
  final VoidCallback onTap;

  const _EventRow({
    required this.event,
    required this.label,
    required this.expanded,
    required this.onTap,
  });

  /// The one line that says what happened.
  String _headline() {
    final e = event;
    final parts = <String>[];
    if (e.entityType != null) {
      final name = label ?? '${e.entityType} ${_short(e.worldId)}';
      parts.add(e.field == null ? name : '$name · ${e.field}');
      if (e.valuePreview != null) {
        parts.add('"${e.valuePreview}"');
      } else if (e.valueHash == null && e.field != null && e.kind != SyncLogKind.conflictCopy) {
        parts.add('(empty)');
      }
    }
    if (e.message != null) parts.add(e.message!);
    if (parts.isEmpty && e.counter != null) {
      parts.add('${_short(e.originDevice)} #${e.counter}');
    }
    return parts.join('  —  ');
  }

  /// Identity and timestamps, when there are any.
  String _subline() {
    final e = event;
    final parts = <String>[
      if (e.counter != null) '${_short(e.originDevice)}#${e.counter}',
      if (e.counter == null && e.originDevice != null) _short(e.originDevice),
      if (e.packetHash != null) 'hash ${_short(e.packetHash, 12)}',
      if (e.valueHash != null) 'value ${e.valueHash}',
      if (e.remoteTs != null) 'remote ${_localStamp(_eventStamp, e.remoteTs!)}',
      if (e.localTs != null) 'local ${_localStamp(_eventStamp, e.localTs!)}',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = SyncLogLevel.values[event.level.clamp(0, 2)];
    final (IconData icon, Color color) = switch (level) {
      SyncLogLevel.error => (Icons.error_outline, theme.colorScheme.error),
      SyncLogLevel.warning => (
          Icons.warning_amber_rounded,
          Colors.orange.shade700
        ),
      SyncLogLevel.info => switch (event.direction) {
          'in' => (Icons.south_west, theme.colorScheme.primary),
          'out' => (Icons.north_east, theme.colorScheme.tertiary),
          _ => (Icons.circle_outlined, theme.hintColor),
        },
    };
    final small = theme.textTheme.bodySmall;
    final sub = _subline();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 86,
              child: Text(_localStamp(_eventStamp, event.at),
                  style: small?.copyWith(
                      color: theme.hintColor,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(icon, size: 14, color: color),
            ),
            const SizedBox(width: 6),
            Container(
              margin: const EdgeInsets.only(top: 1),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(event.kind,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(fontFamily: 'monospace')),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _headline(),
                    style: small?.copyWith(color: theme.colorScheme.onSurface),
                    maxLines: expanded ? null : 2,
                    overflow: expanded ? null : TextOverflow.ellipsis,
                  ),
                  if (sub.isNotEmpty)
                    Text(sub,
                        style: small?.copyWith(color: theme.hintColor),
                        maxLines: expanded ? null : 1,
                        overflow: expanded ? null : TextOverflow.ellipsis),
                  if (expanded) _EventDetails(event: event, label: label),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Every recorded field of one event, selectable for copying.
class _EventDetails extends StatelessWidget {
  final SyncLogEventRow event;
  final String? label;

  const _EventDetails({required this.event, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final e = event;
    Object? detail;
    if (e.detailJson != null) {
      try {
        detail = jsonDecode(e.detailJson!);
      } catch (_) {
        detail = e.detailJson;
      }
    }
    final rows = <String, String?>{
      'Run': '#${e.runId}',
      'At': e.at,
      'Direction': e.direction,
      'Origin device': e.originDevice,
      'Counter': e.counter?.toString(),
      'Packet / blob hash': e.packetHash,
      'Entity': e.entityType,
      'World id': e.worldId,
      'Name': label,
      'Field': e.field,
      'Remote timestamp': e.remoteTs,
      'Local timestamp': e.localTs,
      'Value hash': e.valueHash,
      'Value preview': e.valuePreview,
      'Message': e.message,
      if (detail != null)
        'Detail': const JsonEncoder.withIndent('  ').convert(detail),
    }..removeWhere((_, v) => v == null || v.isEmpty);

    final mono = theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace');
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final entry in rows.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(entry.key,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor)),
                    ),
                    Expanded(child: Text(entry.value!, style: mono)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
