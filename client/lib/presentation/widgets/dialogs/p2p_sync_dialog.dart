import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/lan_sync_coordinator.dart';
import '../../providers/providers.dart';

/// Open Sync P2P: look for this account's devices on the network and sync
/// with each one found, for as long as the dialog stays open.
Future<void> showP2pSyncDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const P2pSyncDialog(),
  );
}

/// The LAN counterpart of the relay's Sync Now: the session exists only while
/// this dialog does. Opening it starts the peer server and discovery; closing
/// it stops both, after which this device can no longer be found or reached.
///
/// The other device has to have Sync P2P open too — that is how both users say
/// yes, so no further confirmation is asked for.
class P2pSyncDialog extends ConsumerStatefulWidget {
  const P2pSyncDialog({super.key});

  @override
  ConsumerState<P2pSyncDialog> createState() => _P2pSyncDialogState();
}

class _P2pSyncDialogState extends ConsumerState<P2pSyncDialog> {
  LanSyncCoordinator? _coordinator;
  StreamSubscription<List<LanPeerStatus>>? _sub;
  List<LanPeerStatus> _peers = const [];
  bool _starting = true;
  String? _startError;

  @override
  void initState() {
    super.initState();
    _coordinator = ref.read(lanSyncCoordinatorProvider);
    _start();
  }

  Future<void> _start() async {
    final coordinator = _coordinator;
    if (coordinator == null) {
      setState(() => _starting = false);
      return;
    }
    _sub = coordinator.statuses.listen((peers) {
      if (mounted) setState(() => _peers = peers);
    });
    try {
      await coordinator.startSession();
    } catch (e) {
      if (mounted) setState(() => _startError = '$e');
    }
    if (mounted) setState(() => _starting = false);
  }

  @override
  void dispose() {
    _sub?.cancel();
    // Closing the dialog is what ends the session: stop being discoverable.
    unawaited(_coordinator?.stopSession());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coordinator = _coordinator;
    final hint =
        theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline);
    final busy = _peers.any((p) => p.state == LanPeerState.syncing);

    Widget body;
    if (coordinator == null) {
      body = const Text(
        'Sync is not configured. Set a user name in Preferences → Sync first.',
      );
    } else if (_startError != null) {
      body = Text('Could not start peer-to-peer sync: $_startError');
    } else {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(_starting
                    ? 'Starting...'
                    : 'Looking for devices on this network...'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Open Sync P2P... on the other device too. Devices sync as '
            'soon as they find each other; they stop being visible when this '
            'window is closed.',
            style: hint,
          ),
          if (_peers.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final peer in _peers) _PeerRow(peer: peer),
          ],
        ],
      );
    }

    return AlertDialog(
      icon: const Icon(Icons.devices),
      title: const Text('Sync P2P'),
      content: SizedBox(width: 420, child: body),
      actions: [
        if (coordinator != null && _startError == null)
          TextButton(
            onPressed: _peers.isEmpty || busy ? null : coordinator.syncAgain,
            child: const Text('Sync Again'),
          ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _PeerRow extends StatelessWidget {
  final LanPeerStatus peer;

  const _PeerRow({required this.peer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outline;

    final (Widget icon, String status) = switch (peer.state) {
      LanPeerState.found => (
          Icon(Icons.schedule, size: 18, color: outline),
          'Found — waiting to sync',
        ),
      LanPeerState.syncing => (
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          'Syncing...',
        ),
      LanPeerState.synced => (
          Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary),
          peer.changesApplied == 0
              ? 'Synced — already up to date'
              : 'Synced — ${peer.changesApplied} '
                  '${peer.changesApplied == 1 ? 'change' : 'changes'} received',
        ),
      LanPeerState.failed => (
          Icon(Icons.error, size: 18, color: theme.colorScheme.error),
          'Failed — ${peer.error ?? 'unknown error'}',
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 20, child: Center(child: icon)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: peer.deviceId,
                  child: Text(
                    peer.address == null
                        ? peer.label
                        : '${peer.label} (${peer.address})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  status,
                  style: theme.textTheme.bodySmall?.copyWith(color: outline),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
