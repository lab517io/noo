import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../data/services/sync_journal.dart';
import '../../../data/services/sync_service.dart';
import 'sync_log_dialog.dart';
import '../../../core/theme/noo_chrome.dart';
import '../../../l10n/l10n.dart';

/// Most rows a change list builds. The lists are built eagerly (their rows
/// wrap, so they have no fixed extent to virtualize on), and a 10,000-change
/// sync used to stall the finished dialog for seconds building every row.
/// What is past the cap is in the full log.
const int kMaxSyncListRows = 200;

/// The first [kMaxSyncListRows] of [items] as rows, then a line saying how
/// many were left out and [more] — where to find them.
List<Widget> cappedSyncRows<T>(
  BuildContext context,
  List<T> items,
  Widget Function(int index, T item) row, {
  String? more,
}) {
  final where = more ?? context.l10n.traceMoreSeeSyncLog;
  final shown = items.length > kMaxSyncListRows
      ? items.sublist(0, kMaxSyncListRows)
      : items;
  final hidden = items.length - shown.length;
  final theme = Theme.of(context);
  return [
    for (var i = 0; i < shown.length; i++) row(i, shown[i]),
    if (hidden > 0)
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          context.l10n.traceMoreRows(hidden, where),
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      ),
  ];
}

/// How a [SyncEntityChange.path] reads under its change: `in Work › Q3`, or
/// `at top level` for a node that was moved there.
///
/// `›` rather than `/`, which is common in titles ("Q3 / Q4 planning").
String changeLocation(List<String> path, [AppLocalizations? l10n]) {
  final l = l10n ?? appL10n;
  return path.isEmpty ? l.traceAtTopLevel : l.traceInPath(path.join(' › '));
}

/// The changes of one sync report, each row opening onto how it happened:
/// what was decided per field, the packet it travelled in and the route that
/// packet took, and where an attachment's bytes stand.
///
/// Scrolls once it is taller than [maxHeight], so a busy sync cannot push a
/// dialog's buttons off screen.
class SyncChangeList extends StatefulWidget {
  const SyncChangeList({
    super.key,
    required this.changes,
    this.logRunId,
    this.maxHeight = 200,
    this.more,
  });

  final List<SyncEntityChange> changes;

  /// Where the rows past the cap are, for the line that replaces them.
  /// Null for the Sync Log.
  final String? more;

  /// The run the changes belong to, for "Show in Sync Log". Null hides it.
  final int? logRunId;

  final double maxHeight;

  @override
  State<SyncChangeList> createState() => _SyncChangeListState();
}

class _SyncChangeListState extends State<SyncChangeList> {
  final Set<int> _expanded = {};

  @override
  void didUpdateWidget(SyncChangeList oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rows are identified by position; a new report is a new list.
    if (!identical(oldWidget.changes, widget.changes)) _expanded.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: widget.maxHeight),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: cappedSyncRows(
            context,
            widget.changes,
            (index, change) => SyncChangeRow(
              change: change,
              logRunId: widget.logRunId,
              expanded: _expanded.contains(index),
              onToggle: change.hasTrace
                  ? () => setState(() {
                        if (!_expanded.remove(index)) _expanded.add(index);
                      })
                  : null,
            ),
            more: widget.more,
          ),
        ),
      ),
    );
  }
}

/// One change line: a kind glyph, the entity label, an optional detail and
/// the path; opened, the trace under it.
class SyncChangeRow extends StatelessWidget {
  const SyncChangeRow({
    super.key,
    required this.change,
    this.logRunId,
    this.expanded = false,
    this.onToggle,
  });

  final SyncEntityChange change;
  final int? logRunId;
  final bool expanded;

  /// Null when there is nothing to open.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;

    final (IconData icon, Color color) = switch (change.kind) {
      SyncEntityChangeKind.created => (Icons.add_circle_outline, Colors.green),
      SyncEntityChangeKind.updated => (
          change.entityType == 'snapshot'
              ? Icons.inventory_2_outlined
              : Icons.edit_outlined,
          theme.colorScheme.primary,
        ),
      SyncEntityChangeKind.removed => (
          Icons.remove_circle_outline,
          theme.colorScheme.error,
        ),
    };

    // With a detail, read as "label · detail"; otherwise a create/remove tag.
    final String suffix;
    if (change.detail != null && change.detail!.isNotEmpty) {
      suffix = '  ·  ${change.detail}';
    } else if (change.kind == SyncEntityChangeKind.created) {
      suffix = '  ${l.traceRowNew}';
    } else if (change.kind == SyncEntityChangeKind.removed) {
      suffix = '  ${l.traceRowRemoved}';
    } else {
      suffix = '';
    }

    final line = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: change.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: suffix,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                    ),
                  ],
                ),
              ),
              // Where it is, on a line of its own. Wrapped rather than
              // ellipsized: the whole path is the point, and its far end —
              // the node's own parent — is the part an ellipsis would cut.
              if (change.path != null)
                Text(
                  changeLocation(change.path!, l),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
            ],
          ),
        ),
        if (onToggle != null)
          Icon(
            expanded ? Icons.expand_less : Icons.expand_more,
            size: 16,
            color: theme.hintColor,
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onToggle,
          borderRadius: NooChrome.of(context).smallRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Tooltip(
              message: onToggle == null ? '' : l.traceShowHowTooltip,
              waitDuration: const Duration(milliseconds: 600),
              child: line,
            ),
          ),
        ),
        if (expanded) SyncChangeTrace(change: change, logRunId: logRunId),
      ],
    );
  }
}

/// The opened part of a row: fields, packets, attachment bytes.
class SyncChangeTrace extends StatelessWidget {
  const SyncChangeTrace({super.key, required this.change, this.logRunId});

  final SyncEntityChange change;
  final int? logRunId;

  static final DateFormat _stamp = DateFormat('d MMM HH:mm:ss');

  static String? _time(String? iso) {
    if (iso == null) return null;
    final parsed = DateTime.tryParse(iso);
    return parsed == null ? iso : _stamp.format(parsed.toLocal());
  }

  static String _bytes(AppLocalizations l, int bytes) {
    if (bytes < 1024) return l.traceBytes(bytes);
    if (bytes < 1024 * 1024) {
      return l.traceKilobytes((bytes / 1024).toStringAsFixed(1));
    }
    return l.traceMegabytes((bytes / (1024 * 1024)).toStringAsFixed(1));
  }

  static String _short(String id) =>
      id.length <= 8 ? id : '${id.substring(0, 8)}…';

  static String _device(String id, String? name) => name ?? _short(id);

  /// What a decision means, in words.
  /// Other decisions show their stored code.
  static String _decision(AppLocalizations l, String kind) => switch (kind) {
        SyncLogKind.applied => l.traceDecisionApplied,
        SyncLogKind.created => l.traceDecisionCreated,
        SyncLogKind.conflictCopy => l.traceDecisionConflictCopy,
        SyncLogKind.merged => l.traceDecisionMerged,
        SyncLogKind.cycleToRoot => l.traceDecisionCycleToRoot,
        SyncLogKind.parentMissing => l.traceDecisionParentMissing,
        SyncLogKind.blobPending => l.traceDecisionBlobPending,
        SyncLogKind.outgoing => l.traceDecisionSent,
        SyncLogKind.served => l.traceDecisionForwarded,
        _ => kind,
      };

  /// Where a packet came from or went, in one sentence.
  static String _route(AppLocalizations l, SyncPacketTrace p) {
    final author = _device(p.originDeviceId, p.originName);
    final peer = p.peerDeviceId == null
        ? null
        : _device(p.peerDeviceId!, p.peerName);
    switch (p.route) {
      case SyncPacketRoute.relay:
        final stored = _time(p.relayStoredAt);
        return stored == null
            ? l.traceRouteRelay
            : l.traceRouteRelayStored(stored);
      case SyncPacketRoute.peer:
        return p.forwarded
            ? l.traceRoutePeerForwarded('$peer', author)
            : l.traceRoutePeerDirect('$peer');
      case SyncPacketRoute.stored:
        final at = _time(p.receivedAt);
        final from = p.receivedFrom;
        if (at == null) return l.traceRouteStoredEarlier;
        return from == null
            ? l.traceRouteStoredAt(at)
            : l.traceRouteStoredAtFrom(at, from);
      case SyncPacketRoute.packaged:
        return switch (p.upload) {
          'stored' => l.traceRoutePackagedUploaded,
          'alreadyHeld' => l.traceRoutePackagedAlreadyHeld,
          'blocked' => l.traceRoutePackagedBlocked,
          _ => l.traceRoutePackagedWaiting,
        };
      case SyncPacketRoute.served:
        return p.forwarded
            ? l.traceRouteServedForwarded('$peer', author)
            : l.traceRouteServedDirect('$peer');
    }
  }

  static String _blob(AppLocalizations l, SyncBlobTrace b) {
    final size = b.bytes == null ? null : _bytes(l, b.bytes!);
    final source = b.source;
    return switch (b.state) {
      SyncBlobState.arrived => switch ((source, size)) {
          (null, null) => l.traceBlobDownloaded,
          (null, final size?) => l.traceBlobDownloadedSized(size),
          (final source?, null) => l.traceBlobDownloadedFrom(source),
          (final source?, final size?) =>
            l.traceBlobDownloadedFromSized(source, size),
        },
      SyncBlobState.waiting => l.traceBlobWaiting,
      SyncBlobState.held => l.traceBlobHeld,
      SyncBlobState.uploaded =>
        size == null ? l.traceBlobUploaded : l.traceBlobUploadedSized(size),
      SyncBlobState.onRelay => l.traceBlobOnRelay,
      SyncBlobState.offered => l.traceBlobOffered,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final small = theme.textTheme.bodySmall;
    final hint = small?.copyWith(color: theme.hintColor);
    final strong = small?.copyWith(
        color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600);

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Text(text, style: strong),
        );

    final children = <Widget>[];

    if (change.fromSnapshot) {
      final p = change.packets.firstWhere((p) => p.fullState);
      final author = _device(p.originDeviceId, p.originName);
      children.add(Text(
        change.entityType == 'snapshot'
            ? l.traceSnapshotWhole(author)
            : l.traceSnapshotPart(author),
        style: hint,
      ));
    } else if (change.fields.isNotEmpty) {
      children.add(heading(l.traceFieldsHeading));
      for (final f in change.fields) {
        final times = [
          if (f.remoteTs != null)
            f.decision == SyncLogKind.outgoing ||
                    f.decision == SyncLogKind.served
                ? l.traceTimeEdited('${_time(f.remoteTs)}')
                : l.traceTimeTheirs('${_time(f.remoteTs)}'),
          if (f.localTs != null) l.traceTimeThisDevice('${_time(f.localTs)}'),
        ].join(' · ');
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Text.rich(TextSpan(children: [
            TextSpan(
                text: f.field,
                style: small?.copyWith(color: theme.colorScheme.onSurface)),
            if (f.value != null && f.value!.isNotEmpty)
              TextSpan(text: '  →  ${f.value}', style: small),
            TextSpan(
                text: '\n${_decision(l, f.decision)}'
                    '${times.isEmpty ? '' : '  ·  $times'}'
                    '${f.message == null ? '' : '\n${f.message}'}',
                style: hint),
          ])),
        ));
      }
    }

    for (final p in change.packets) {
      final device = _device(p.originDeviceId, p.originName);
      children.add(heading(p.fullState
          ? l.tracePacketHeadingSnapshot(device, '${p.counter}')
          : l.tracePacketHeading(device, '${p.counter}')));
      final facts = [
        if (p.createdAt != null) l.tracePacketWritten('${_time(p.createdAt)}'),
        if (p.changeCount != null) l.tracePacketChanges(p.changeCount!),
        if (p.bytes != null) _bytes(l, p.bytes!),
      ].join(' · ');
      if (facts.isNotEmpty) children.add(Text(facts, style: hint));
      children.add(Text(_route(l, p), style: hint));
      children.add(Tooltip(
        message: l.tracePacketAuthorTooltip(p.originDeviceId),
        child: Text(l.tracePacketFromDevice(_short(p.originDeviceId)),
            style: hint),
      ));
      if (p.hash != null) {
        children.add(Row(
          children: [
            Expanded(
              child: SelectableText('sha256 ${p.hash}',
                  style: hint?.copyWith(fontFamily: 'JetBrains Mono'),
                  maxLines: 1),
            ),
            IconButton(
              tooltip: l.traceCopyHashTooltip,
              visualDensity: VisualDensity.compact,
              iconSize: 14,
              icon: const Icon(Icons.copy),
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: p.hash!)),
            ),
          ],
        ));
      }
    }

    if (change.blobs.isNotEmpty) {
      children.add(heading(l.traceAttachmentBytesHeading));
      for (final b in change.blobs) {
        children.add(
            Text(l.traceBlobLine(_short(b.id), _blob(l, b)), style: hint));
      }
    }

    final runId = logRunId;
    final worldId = change.worldId;
    if (runId != null && worldId != null) {
      children.add(Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
          icon: const Icon(Icons.receipt_long_outlined, size: 14),
          label: Text(l.traceShowInSyncLog),
          onPressed: () =>
              showSyncLogDialog(context, runId: runId, search: worldId),
        ),
      ));
    }

    return Container(
      margin: const EdgeInsets.only(left: 6, bottom: 6),
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: theme.dividerColor, width: 2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
