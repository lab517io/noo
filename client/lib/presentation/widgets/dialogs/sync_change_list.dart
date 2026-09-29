import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../data/services/sync_journal.dart';
import '../../../data/services/sync_service.dart';
import 'sync_log_dialog.dart';

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
  String more = 'see the Sync Log',
}) {
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
          '…and $hidden more — $more',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
        ),
      ),
  ];
}

/// How a [SyncEntityChange.path] reads under its change: `in Work › Q3`, or
/// `at top level` for a node that was moved there.
///
/// `›` rather than `/`, which is common in titles ("Q3 / Q4 planning").
String changeLocation(List<String> path) =>
    path.isEmpty ? 'at top level' : 'in ${path.join(' › ')}';

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
    this.more = 'see the Sync Log',
  });

  final List<SyncEntityChange> changes;

  /// Where the rows past the cap are, for the line that replaces them.
  final String more;

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
      suffix = '  (new)';
    } else if (change.kind == SyncEntityChangeKind.removed) {
      suffix = '  (removed)';
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
                  changeLocation(change.path!),
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
          borderRadius: BorderRadius.circular(3),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Tooltip(
              message: onToggle == null ? '' : 'Show how this change happened',
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

  static String _bytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String _short(String id) =>
      id.length <= 8 ? id : '${id.substring(0, 8)}…';

  static String _device(String id, String? name) => name ?? _short(id);

  /// What a decision means, in words.
  static String _decision(String kind) => switch (kind) {
        SyncLogKind.applied => 'applied',
        SyncLogKind.created => 'created here',
        SyncLogKind.conflictCopy =>
          'applied — the value it replaced was kept as a conflict copy',
        SyncLogKind.cycleToRoot =>
          'moved to the top level — its parent would have made a loop',
        SyncLogKind.parentMissing =>
          'placed at the top level until its parent arrives',
        SyncLogKind.blobPending =>
          'applied — the attachment bytes follow separately',
        SyncLogKind.outgoing => 'sent',
        SyncLogKind.served => 'forwarded',
        _ => kind,
      };

  /// Where a packet came from or went, in one sentence.
  static String _route(SyncPacketTrace p) {
    final author = _device(p.originDeviceId, p.originName);
    final peer = p.peerDeviceId == null
        ? null
        : _device(p.peerDeviceId!, p.peerName);
    switch (p.route) {
      case SyncPacketRoute.relay:
        final stored = _time(p.relayStoredAt);
        return 'Downloaded from the relay'
            '${stored == null ? '' : ', which stored it $stored'}.';
      case SyncPacketRoute.peer:
        return p.forwarded
            ? 'Forwarded by $peer over the local network — $author wrote it.'
            : 'Directly from $peer over the local network.';
      case SyncPacketRoute.stored:
        final at = _time(p.receivedAt);
        final from = p.receivedFrom;
        if (at == null) {
          return 'Already on this device from an earlier exchange; '
              'applied in this one.';
        }
        return 'Already on this device — received $at'
            '${from == null ? '' : ' from $from'}; applied in this one.';
      case SyncPacketRoute.packaged:
        return switch (p.upload) {
          'stored' => 'Packaged here and uploaded to the relay.',
          'alreadyHeld' =>
            'Packaged here; the relay already had it from another path.',
          'blocked' => 'Packaged here; not uploaded yet — an attachment it '
              'needs could not go up.',
          _ => 'Packaged here; waiting for the relay or a peer to take it.',
        };
      case SyncPacketRoute.served:
        return p.forwarded
            ? 'Pulled by $peer over the local network — forwarded on '
                "$author's behalf."
            : 'Pulled by $peer over the local network.';
    }
  }

  static String _blob(SyncBlobTrace b) {
    final size = b.bytes == null ? '' : ' (${_bytes(b.bytes!)})';
    return switch (b.state) {
      SyncBlobState.arrived =>
        'downloaded now${b.source == null ? '' : ' from ${b.source}'}$size',
      SyncBlobState.waiting =>
        'not downloaded yet — it follows on a later sync, or when opened',
      SyncBlobState.held => 'already on this device',
      SyncBlobState.uploaded => 'uploaded to the relay$size',
      SyncBlobState.onRelay => 'the relay already had them',
      SyncBlobState.offered => 'on this device for others to fetch',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
      children.add(Text(
        change.entityType == 'snapshot'
            ? 'A compaction snapshot: the whole database of '
                '${_device(p.originDeviceId, p.originName)}, in one packet.'
            : 'Part of a full-state snapshot from '
                '${_device(p.originDeviceId, p.originName)}. A snapshot '
                "carries the author's whole database; this item is listed "
                'because it differed here.',
        style: hint,
      ));
    } else if (change.fields.isNotEmpty) {
      children.add(heading('Fields'));
      for (final f in change.fields) {
        final times = [
          if (f.remoteTs != null)
            '${f.decision == SyncLogKind.outgoing || f.decision == SyncLogKind.served ? 'edited' : 'theirs'} ${_time(f.remoteTs)}',
          if (f.localTs != null) 'this device ${_time(f.localTs)}',
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
                text: '\n${_decision(f.decision)}'
                    '${times.isEmpty ? '' : '  ·  $times'}'
                    '${f.message == null ? '' : '\n${f.message}'}',
                style: hint),
          ])),
        ));
      }
    }

    for (final p in change.packets) {
      children.add(heading(
          'Packet ${_device(p.originDeviceId, p.originName)} #${p.counter}'
          '${p.fullState ? ' (snapshot)' : ''}'));
      final facts = [
        if (p.createdAt != null) 'written ${_time(p.createdAt)}',
        if (p.changeCount != null)
          '${p.changeCount} change${p.changeCount == 1 ? '' : 's'}',
        if (p.bytes != null) _bytes(p.bytes!),
      ].join(' · ');
      if (facts.isNotEmpty) children.add(Text(facts, style: hint));
      children.add(Text(_route(p), style: hint));
      children.add(Tooltip(
        message: 'Author device ${p.originDeviceId}',
        child: Text('from device ${_short(p.originDeviceId)}', style: hint),
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
              tooltip: 'Copy the packet hash',
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
      children.add(heading('Attachment bytes'));
      for (final b in change.blobs) {
        children.add(Text('${_short(b.id)} — ${_blob(b)}', style: hint));
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
          label: const Text('Show in Sync Log'),
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
