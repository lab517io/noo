import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/sync_service.dart';
import '../../../domain/entities/history_entry.dart';
import '../../providers/sync_provider.dart';

/// How long the pointer must rest on the indicator before the preview opens.
/// Long enough that crossing the status bar on the way somewhere else never
/// pops it up.
const _hoverDelay = Duration(seconds: 3);

/// Grace period after the pointer leaves, so moving from the icon up into the
/// card (they touch, but the pointer briefly belongs to neither) keeps it open.
const _hideGrace = Duration(milliseconds: 120);

/// Wraps the status bar's sync indicator with a hover preview: rest the
/// pointer on it for three seconds and a card appears above it listing what is
/// waiting to be synced — the same edits the next push would send.
///
/// Pure inspection: the card is read-only, and it stays out of the way when
/// there is nothing pending (the plain tooltip on the indicator says as much
/// already). Mouse-only by design; touch platforms just get the tooltip.
class PendingSyncPreview extends ConsumerStatefulWidget {
  const PendingSyncPreview({super.key, required this.child});

  /// The sync indicator itself.
  final Widget child;

  @override
  ConsumerState<PendingSyncPreview> createState() => _PendingSyncPreviewState();
}

class _PendingSyncPreviewState extends ConsumerState<PendingSyncPreview> {
  final LayerLink _link = LayerLink();
  final OverlayPortalController _portal = OverlayPortalController();

  Timer? _showTimer;
  Timer? _hideTimer;
  bool _overIcon = false;
  bool _overCard = false;

  /// Invalidates in-flight loads: a query that returns after the pointer has
  /// left (or after a newer query started) must not pop the card open.
  int _loadId = 0;

  PendingChanges? _pending;

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onIconEnter() {
    _overIcon = true;
    _hideTimer?.cancel();
    _showTimer?.cancel();
    _showTimer = Timer(_hoverDelay, _load);
  }

  void _onIconExit() {
    _overIcon = false;
    _showTimer?.cancel();
    _scheduleHide();
  }

  Future<void> _load() async {
    final service = ref.read(syncServiceProvider);
    if (service == null) return;

    final id = ++_loadId;
    final pending = await service.pendingLocalChanges();
    if (!mounted || id != _loadId || !_overIcon) return;
    // Nothing to show: leave the indicator's own tooltip as the whole story.
    if (pending.isEmpty) return;

    setState(() => _pending = pending);
    // The indicator's tooltip renders in the same corner and would otherwise
    // sit on top of the card.
    Tooltip.dismissAllToolTips();
    _portal.show();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_hideGrace, () {
      if (!mounted || _overIcon || _overCard) return;
      _loadId++; // discard whatever a pending load would have shown
      _portal.hide();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: _buildCard,
        child: MouseRegion(
          onEnter: (_) => _onIconEnter(),
          onExit: (_) => _onIconExit(),
          child: widget.child,
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context) {
    final pending = _pending;
    if (pending == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Positioned(
      left: 0,
      top: 0,
      child: CompositedTransformFollower(
        link: _link,
        // The indicator lives in the bottom-right of the window, so the card
        // grows up and to the left from it.
        targetAnchor: Alignment.topRight,
        followerAnchor: Alignment.bottomRight,
        offset: const Offset(0, -6),
        child: MouseRegion(
          onEnter: (_) {
            _overCard = true;
            _hideTimer?.cancel();
          },
          onExit: (_) {
            _overCard = false;
            _scheduleHide();
          },
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(6),
            color: theme.colorScheme.surfaceContainerHighest,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_headline(pending), style: theme.textTheme.labelLarge),
                    const SizedBox(height: 6),
                    for (final item in pending.items) _itemRow(theme, item),
                    if (pending.hiddenEntities > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '+${pending.hiddenEntities} more',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.hintColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _itemRow(ThemeData theme, PendingChange item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 6),
            child: Icon(
              _iconFor(item.entityType),
              size: 14,
              color: theme.hintColor,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  '${_fieldsLabel(item.fields)} · ${_ago(item.changedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _headline(PendingChanges pending) {
    final items = pending.totalEntities == 1 ? 'item' : 'items';
    final changes = pending.totalChanges == 1 ? 'change' : 'changes';
    return 'Waiting to sync: ${pending.totalEntities} $items, '
        '${pending.totalChanges} $changes';
  }

  IconData _iconFor(HistoryEntityType type) {
    switch (type) {
      case HistoryEntityType.task:
        return Icons.description_outlined;
      case HistoryEntityType.file:
        return Icons.attach_file;
      case HistoryEntityType.timeline:
        return Icons.timer_outlined;
    }
  }

  /// Field names as the user thinks of them; anything unmapped falls through
  /// as-is rather than being hidden, so a new column still shows up here.
  String _fieldsLabel(List<String> fields) {
    const names = {
      'title': 'title',
      'content': 'content',
      'parentId': 'moved',
      'orderId': 'reordered',
      'flags': 'flags',
      'removed': 'deleted',
      'filename': 'name',
      'taskId': 'moved',
      'startTime': 'start time',
      'endTime': 'end time',
    };
    final labels = <String>{for (final f in fields) names[f] ?? f};
    return labels.join(', ');
  }

  String _ago(DateTime when) {
    final delta = DateTime.now().difference(when);
    if (delta.inSeconds < 60) return 'just now';
    if (delta.inMinutes < 60) return '${delta.inMinutes} min ago';
    if (delta.inHours < 24) return '${delta.inHours} h ago';
    return '${delta.inDays} d ago';
  }
}
