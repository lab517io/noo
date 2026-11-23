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
import '../../../core/theme/noo_chrome.dart';
import '../../../l10n/l10n.dart';

/// Show the persistent sync log: every run's packets, hashes and merge
/// decisions, newest first. Unlike Sync Details, which shows the run in
/// progress, this reads what was recorded — across restarts and across every
/// kind of sync (relay, nearby devices, peers pulling from this device).
/// Open the sync log — on the newest run, or on [runId] with [search]
/// already typed in, which is how a sync report row shows its own events.
Future<void> showSyncLogDialog(
  BuildContext context, {
  int? runId,
  String? search,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => SyncLogDialog(initialRunId: runId, initialSearch: search),
  );
}

/// What started a run, for people. The stored trigger names are not
/// translated; one this build does not know is shown as stored.
String _triggerLabel(AppLocalizations l, String trigger) => switch (trigger) {
      'relay' => l.traceTriggerRelay,
      'check' => l.traceTriggerCheck,
      'lan' => l.traceTriggerLan,
      'lan-return' => l.traceTriggerLanReturn,
      'lan-serve' => l.traceTriggerLanServe,
      'package' => l.traceTriggerPackage,
      'compaction' => l.traceTriggerCompaction,
      'identity-reset' => l.traceTriggerIdentityReset,
      'attachment' => l.traceTriggerAttachment,
      'blob-collect' => l.traceTriggerBlobCollect,
      _ => trigger,
    };

/// How a run ended, for people. The stored outcome codes are not translated.
String _outcomeLabel(AppLocalizations l, String outcome) => switch (outcome) {
      'running' => l.traceOutcomeRunning,
      'failed' => l.traceOutcomeFailed,
      'declined' => l.traceOutcomeDeclined,
      'busy' => l.traceOutcomeBusy,
      'interrupted' => l.traceOutcomeInterrupted,
      _ => outcome,
    };

enum _LevelFilter { all, warnings, errors }

enum _DirectionFilter { all, incoming, outgoing, local }

class SyncLogDialog extends ConsumerStatefulWidget {
  const SyncLogDialog({super.key, this.initialRunId, this.initialSearch});

  /// The run to open on; null for the newest.
  final int? initialRunId;

  /// Search text to open with.
  final String? initialSearch;

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
    _runId = widget.initialRunId;
    _search.text = widget.initialSearch ?? '';
    _search.addListener(() {
      _searchDebounce?.cancel();
      _searchDebounce =
          Timer(const Duration(milliseconds: 250), () => _reload());
    });
    _reload(selectNewest: widget.initialRunId == null);
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
      SnackBar(content: Text(context.l10n.traceCopiedJson(_events.length))),
    );
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.traceClearTitle),
        content: Text(context.l10n.traceClearBody),
        actions: [
          OutlinedButton(
            style: classicButtonStyle(context),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            style: classicButtonStyle(context),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.commonClear),
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
    final l = context.l10n;
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
            title: Text(l.traceTitle),
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: l.commonClose,
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy_all_outlined),
                tooltip: l.traceCopyAsJson,
                onPressed: _events.isEmpty ? null : _copyJson,
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: l.traceClearLogTooltip,
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
      title: Text(l.traceTitle),
      titleTextStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      shape: NooChrome.of(context).dialogShape,
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
          child: Text(l.traceClearLogButton),
        ),
        OutlinedButton(
          style: classicButtonStyle(context),
          onPressed: _events.isEmpty ? null : _copyJson,
          child: Text(l.traceCopyAsJson),
        ),
        FilledButton(
          style: classicButtonStyle(context),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.commonClose),
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
String _runSummary(AppLocalizations l, SyncLogRunRow run) {
  final c = _countsOf(run);
  int n(String k) => c[k] ?? 0;
  final received = n(SyncLogKind.packetStored);
  final sent = n(SyncLogKind.packaged) + n(SyncLogKind.served);
  final pushed = n(SyncLogKind.pushed);
  final applied = n(SyncLogKind.applied) + n(SyncLogKind.created);
  final parts = <String>[
    if (received > 0) '↓ $received',
    if (sent > 0 || pushed > 0) '↑ ${sent > pushed ? sent : pushed}',
    if (applied > 0) l.traceSummaryApplied(applied),
    if (n('warnings') > 0) l.traceSummaryWarnings(n('warnings')),
    if (n('errors') > 0) l.traceSummaryErrors(n('errors')),
  ];
  return parts.isEmpty ? l.traceNothingExchanged : parts.join(' · ');
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
    final l = context.l10n;
    if (runs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          l.traceNoRuns,
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
            title: l.traceAllRuns,
            subtitle: l.traceRunsRecorded(runs.length),
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
              '${_triggerLabel(l, run.trigger)}',
          subtitle: [
            if (remote != null && remote.isNotEmpty && run.trigger != 'relay')
              remote,
            if (run.outcome != 'ok') _outcomeLabel(l, run.outcome),
            _runSummary(l, run),
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
      borderRadius: NooChrome.of(context).smallRadius,
      child: InkWell(
        borderRadius: NooChrome.of(context).smallRadius,
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
    final l = context.l10n;
    return DropdownButtonFormField<int?>(
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        isDense: true,
        border: const OutlineInputBorder(),
        labelText: l.traceRunLabel,
      ),
      items: [
        DropdownMenuItem<int?>(
          value: null,
          child: Text(l.traceAllRunsCount(runs.length)),
        ),
        for (final run in runs)
          DropdownMenuItem<int?>(
            value: run.id,
            child: Text(
              '${_localStamp(_runStamp, run.startedAt)} · '
              '${_triggerLabel(l, run.trigger)} · '
              '${_runSummary(l, run)}',
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
    final l = context.l10n;
    final searchField = ClassicTextField(
      controller: search,
      hintText: l.traceSearchHint,
    );
    final levels = SegmentedButton<_LevelFilter>(
      showSelectedIcon: false,
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      segments: [
        ButtonSegment(value: _LevelFilter.all, label: Text(l.traceLevelAll)),
        ButtonSegment(
            value: _LevelFilter.warnings, label: Text(l.traceLevelWarnings)),
        ButtonSegment(
            value: _LevelFilter.errors, label: Text(l.traceLevelErrors)),
      ],
      selected: {level},
      onSelectionChanged: (v) => onLevel(v.single),
    );
    final directions = DropdownButton<_DirectionFilter>(
      value: direction,
      isDense: true,
      underline: const SizedBox.shrink(),
      items: [
        DropdownMenuItem(
            value: _DirectionFilter.all, child: Text(l.traceDirectionAll)),
        DropdownMenuItem(
            value: _DirectionFilter.incoming,
            child: Text(l.traceDirectionIncoming)),
        DropdownMenuItem(
            value: _DirectionFilter.outgoing,
            child: Text(l.traceDirectionOutgoing)),
        DropdownMenuItem(
            value: _DirectionFilter.local, child: Text(l.traceDirectionLocal)),
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
    final l = context.l10n;
    if (events.isEmpty) {
      return Center(
        child: Text(
          l.traceNoEvents,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: NooChrome.of(context).smallRadius,
      ),
      child: ListView.separated(
        itemCount: events.length + (truncated ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          if (index == events.length) {
            return Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                l.traceEventsTruncated(events.length),
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
                  child: Text(l.traceRunNumber(event.runId),
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
  String _headline(AppLocalizations l) {
    final e = event;
    final parts = <String>[];
    if (e.entityType != null) {
      final name = label ?? '${e.entityType} ${_short(e.worldId)}';
      parts.add(e.field == null ? name : '$name · ${e.field}');
      if (e.valuePreview != null) {
        parts.add('"${e.valuePreview}"');
      } else if (e.valueHash == null && e.field != null && e.kind != SyncLogKind.conflictCopy) {
        parts.add(l.traceEmptyValue);
      }
    }
    if (e.message != null) parts.add(e.message!);
    if (parts.isEmpty && e.counter != null) {
      parts.add('${_short(e.originDevice)} #${e.counter}');
    }
    return parts.join('  —  ');
  }

  /// Identity and timestamps, when there are any.
  String _subline(AppLocalizations l) {
    final e = event;
    final parts = <String>[
      if (e.counter != null) '${_short(e.originDevice)}#${e.counter}',
      if (e.counter == null && e.originDevice != null) _short(e.originDevice),
      if (e.packetHash != null) l.traceSubHash(_short(e.packetHash, 12)),
      if (e.valueHash != null) l.traceSubValue(e.valueHash!),
      if (e.remoteTs != null)
        l.traceSubRemote(_localStamp(_eventStamp, e.remoteTs!)),
      if (e.localTs != null)
        l.traceSubLocal(_localStamp(_eventStamp, e.localTs!)),
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
    final l = context.l10n;
    final sub = _subline(l);

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
                borderRadius: NooChrome.of(context).smallRadius,
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
                    _headline(l),
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
    final l = context.l10n;
    // A list, not a map: two labels may translate alike.
    final rows = <(String, String?)>[
      (l.traceRunLabel, '#${e.runId}'),
      (l.traceDetailAt, e.at),
      (l.traceDetailDirection, e.direction),
      (l.traceDetailOriginDevice, e.originDevice),
      (l.traceDetailCounter, e.counter?.toString()),
      (l.traceDetailHash, e.packetHash),
      (l.traceDetailEntity, e.entityType),
      (l.traceDetailWorldId, e.worldId),
      (l.traceDetailName, label),
      (l.traceDetailField, e.field),
      (l.traceDetailRemoteTs, e.remoteTs),
      (l.traceDetailLocalTs, e.localTs),
      (l.traceDetailValueHash, e.valueHash),
      (l.traceDetailValuePreview, e.valuePreview),
      (l.traceDetailMessage, e.message),
      if (detail != null)
        (l.traceDetailDetail, const JsonEncoder.withIndent('  ').convert(detail)),
    ]..removeWhere((r) => r.$2 == null || r.$2!.isEmpty);

    final mono = theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace');
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: NooChrome.of(context).smallRadius,
      ),
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (key, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(key,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.hintColor)),
                    ),
                    Expanded(child: Text(value!, style: mono)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
