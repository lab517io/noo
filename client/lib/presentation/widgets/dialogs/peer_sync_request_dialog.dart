import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/services/trusted_peers.dart';
import '../app_menu_bar.dart' show rootNavigatorKey;

/// How long the prompt waits for an answer before denying on its own.
///
/// Someone has to be looking at this device for the prompt to be answered, and
/// often nobody is — a phone in a pocket must not leave a dialog open, and the
/// device that pressed sync must not wait forever for one. Denying is the safe
/// default: the sync can always be pressed again.
const Duration peerSyncRequestTimeout = Duration(seconds: 45);

/// The user's answer, plus whether they want to stop being asked.
class _PeerSyncAnswer {
  final bool allowed;
  final bool remember;

  const _PeerSyncAnswer(this.allowed, this.remember);
}

/// Builds the confirmation handler the LAN coordinator calls when a peer
/// authenticates: it consults [trusted] first and only prompts for devices
/// that are not already on the list.
///
/// Kept as a factory rather than a bare function so the trust store — which
/// hangs off the open database — is bound once, where the coordinator is
/// built, instead of being looked up inside a dialog.
Future<bool> Function(String deviceId, String? deviceName)
    peerSyncConfirmation(TrustedPeers trusted) {
  return (deviceId, deviceName) async {
    // Already answered "always" for this device. Note this still does not
    // start a sync on its own — a peer only reaches here because someone
    // pressed sync on it.
    if (await trusted.isTrusted(deviceId)) {
      // Keep the stored name fresh so Preferences shows what the device
      // currently calls itself, not what it called itself when trusted.
      if (deviceName != null && deviceName.trim().isNotEmpty) {
        await trusted.trust(deviceId, deviceName);
      }
      return true;
    }

    final answer = await _askUser(deviceId, deviceName);
    if (answer.allowed && answer.remember) {
      await trusted.trust(deviceId, deviceName);
    }
    return answer.allowed;
  };
}

/// Ask this device's user whether [deviceName] (or [deviceId] when it
/// announced no name) may sync with us.
///
/// Called from the peer server's request handler, not from a widget, so it
/// reaches the UI through [rootNavigatorKey]. Denies — without showing
/// anything — when there is no navigator to show it on, which is the right
/// answer for a background or still-starting app: silence is not consent.
Future<_PeerSyncAnswer> _askUser(String deviceId, String? deviceName) async {
  final context = rootNavigatorKey.currentContext;
  if (context == null) return const _PeerSyncAnswer(false, false);

  final answer = await showDialog<_PeerSyncAnswer>(
    context: context,
    // Deliberately not dismissible: the answer decides whether data leaves
    // this device, so it should be given, not tapped away by accident.
    barrierDismissible: false,
    builder: (context) => _PeerSyncRequestDialog(
      label: (deviceName == null || deviceName.trim().isEmpty)
          ? deviceId
          : deviceName.trim(),
    ),
  );
  return answer ?? const _PeerSyncAnswer(false, false);
}

class _PeerSyncRequestDialog extends StatefulWidget {
  /// Device name if it announced one, otherwise its id.
  final String label;

  const _PeerSyncRequestDialog({required this.label});

  @override
  State<_PeerSyncRequestDialog> createState() => _PeerSyncRequestDialogState();
}

class _PeerSyncRequestDialogState extends State<_PeerSyncRequestDialog> {
  Timer? _ticker;
  int _secondsLeft = peerSyncRequestTimeout.inSeconds;
  bool _remember = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      // Timing out is a denial, so it never records trust regardless of the
      // checkbox — walking away is not the same as agreeing forever.
      if (_secondsLeft <= 0) _answer(false);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _answer(bool allowed) {
    _ticker?.cancel();
    _ticker = null;
    if (mounted) {
      Navigator.of(context).pop(_PeerSyncAnswer(allowed, allowed && _remember));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      icon: const Icon(Icons.sync),
      title: const Text('Sync request'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: widget.label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const TextSpan(
                  text: ' wants to sync with this device. Allowing it '
                      'exchanges tasks, attachments and time records between '
                      'the two.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _remember,
            onChanged: (value) => setState(() => _remember = value ?? false),
            title: const Text('Always allow this device'),
            subtitle: const Text(
              'It still only syncs when someone presses sync. '
              'Revoke in Preferences → Sync.',
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const SizedBox(height: 4),
          Text(
            'Denying automatically in ${_secondsLeft}s.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _answer(false),
          child: const Text('Deny'),
        ),
        FilledButton(
          onPressed: () => _answer(true),
          child: const Text('Allow'),
        ),
      ],
    );
  }
}
