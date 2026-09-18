import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/platform_info.dart';
import '../../../data/services/sync_service.dart';
import '../../providers/sync_provider.dart';
import 'classic_form.dart';
import 'sync_log_dialog.dart';

/// Show the detailed, staged sync progress dialog. The sync itself is driven by
/// [runSyncWithProgress] and feeds [syncProgressProvider]; this dialog only
/// renders that state, so dismissing it does not interrupt an in-flight sync.
///
/// [autoCloseOnSuccess] is used by unattended runs (autosync on start): the
/// dialog dismisses itself shortly after a successful finish, while a failure
/// stays on screen. Manual runs keep the dialog open either way.
Future<void> showSyncProgressDialog(BuildContext context,
    {bool autoCloseOnSuccess = false}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => SyncProgressDialog(autoCloseOnSuccess: autoCloseOnSuccess),
  );
}

/// Human-readable label per stage, in display order.
const _stageLabels = <SyncStage, String>{
  SyncStage.preparing: 'Preparing',
  SyncStage.authenticating: 'Validating credentials',
  SyncStage.pushing: 'Pushing changes',
  SyncStage.applying: 'Applying changes',
};

/// Status word shown for a stage that carries no detail of its own.
const _stageStatus = <SyncStageState, String>{
  SyncStageState.pending: 'Pending',
  SyncStageState.active: 'Working…',
  SyncStageState.done: 'Done',
  SyncStageState.skipped: 'Skipped',
  SyncStageState.failed: 'Failed',
};

/// Width of the stage-label column: wider than the shared [classicLabelWidth]
/// because "Validating credentials" has to fit on one line.
///
/// Applies to the wide layout only. It is the widest column in the app, so on
/// a phone [ClassicField] stacks these rows instead and the width is unused —
/// which is the point: 168dp of label would leave the stage detail barely a
/// word per line.
const double _kStageLabelWidth = 168.0;

/// Sync progress, laid out like the preferences property sheet: titled group
/// boxes, an aligned label column and OK-style push buttons, rather than
/// Material's list-tile defaults.
class SyncProgressDialog extends ConsumerWidget {
  final bool autoCloseOnSuccess;

  const SyncProgressDialog({super.key, this.autoCloseOnSuccess = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final report = ref.watch(syncProgressProvider);

    if (autoCloseOnSuccess) {
      ref.listen(syncProgressProvider, (previous, next) {
        if (previous?.running == true && next.succeeded) {
          // Linger briefly so "Sync complete" is visible, then dismiss.
          Future.delayed(const Duration(milliseconds: 1200), () {
            // context.mounted alone is not enough: if the user closed the
            // dialog themselves moments ago, its widgets stay mounted while
            // the exit animation plays even though the route is already off
            // the stack — popping then would remove the route *below* (the
            // app's only route, leaving a black window). Only pop while this
            // dialog's route is still the current top of the stack; that also
            // covers the case where another dialog has opened on top.
            if (!context.mounted) return;
            final route = ModalRoute.of(context);
            if (route == null || !route.isCurrent) return;
            Navigator.of(context).pop();
          });
        }
      });
    }

    // "Idle" = reopened via the menu with no sync ever having run this session.
    // Distinguished from success so the title isn't a misleading "Sync complete".
    final bool idle = !report.running && report.result == null;
    final scale = classicUiScale(context);

    final String titleText;
    if (report.running) {
      titleText = 'Synchronizing…';
    } else if (report.failed) {
      titleText = 'Sync failed';
    } else if (idle) {
      titleText = 'Sync';
    } else {
      titleText = 'Sync complete';
    }

    // The action offered besides plain dismissal, if any.
    final String? actionLabel = report.failed
        ? 'Retry'
        : idle
            ? 'Sync Now'
            : null;

    final body = _buildBody(theme, report, idle, scale);

    // Phones: present the same content full-screen, as the preferences sheet
    // does, instead of squeezing the property sheet onto a narrow screen.
    if (isCompactLayout(context)) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text(titleText),
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: report.running ? 'Hide' : 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.receipt_long_outlined),
                tooltip: 'Show full log',
                onPressed: () => showSyncLogDialog(context),
              ),
              if (actionLabel != null)
                TextButton(
                  onPressed: () => runSyncWithProgress(ref),
                  child: Text(actionLabel),
                ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: body,
            ),
          ),
        ),
      );
    }

    return AlertDialog(
      title: Text(titleText),
      titleTextStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: 460 * scale,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: body,
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      actions: [
        // Every packet, hash and merge decision behind this summary — and
        // those of earlier runs.
        OutlinedButton(
          style: classicButtonStyle(context),
          onPressed: () => showSyncLogDialog(context),
          child: const Text('Show Full Log'),
        ),
        if (actionLabel != null) ...[
          FilledButton(
            style: classicButtonStyle(context),
            onPressed: () => runSyncWithProgress(ref),
            child: Text(actionLabel),
          ),
          OutlinedButton(
            style: classicButtonStyle(context),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ] else
          FilledButton(
            style: classicButtonStyle(context),
            onPressed: () => Navigator.of(context).pop(),
            // While running, closing only hides the dialog; the sync continues
            // and its outcome is reflected by the toolbar indicator.
            child: Text(report.running ? 'Hide' : 'Close'),
          ),
      ],
    );
  }

  /// The group boxes making up the dialog body, shared by both layouts.
  Widget _buildBody(
    ThemeData theme,
    SyncProgressReport report,
    bool idle,
    double scale,
  ) {
    final result = report.result;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClassicGroupBox(
          title: 'Progress',
          child: idle
              ? Text(
                  'No sync has run yet. Use “Sync Now” to synchronize; the '
                  'details of the last sync will appear here.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final stage in SyncStage.values) ...[
                      if (stage != SyncStage.values.first) kClassicRowGap,
                      _StageRow(
                        label: _stageLabels[stage]!,
                        detail: report.detailOf(stage),
                        state: report.stateOf(stage),
                        labelWidth: _kStageLabelWidth * scale,
                      ),
                    ],
                  ],
                ),
        ),
        if (report.failed && report.errorMessage != null) ...[
          kClassicGroupGap,
          ClassicGroupBox(
            title: 'Error',
            child: _ErrorBox(message: report.errorMessage!),
          ),
        ],
        if (report.succeeded && result != null) ...[
          kClassicGroupGap,
          ClassicGroupBox(
            title: 'Summary',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClassicField(
                  label: 'Changes pushed',
                  labelWidth: _kStageLabelWidth * scale,
                  child: Text('${result.changesPushed}'),
                ),
                kClassicRowGap,
                ClassicField(
                  label: 'Changes applied',
                  labelWidth: _kStageLabelWidth * scale,
                  child: Text('${result.changesApplied}'),
                ),
              ],
            ),
          ),
          if (result.applied.isNotEmpty) ...[
            kClassicGroupGap,
            ClassicGroupBox(
              title: 'Applied — from other devices',
              child: _ChangeList(changes: result.applied),
            ),
          ],
          if (result.pushed.isNotEmpty) ...[
            kClassicGroupGap,
            ClassicGroupBox(
              title: 'Pushed — from this device',
              child: _ChangeList(changes: result.pushed),
            ),
          ],
        ],
        // Shown for failed runs too: a run that died half-way can still have
        // dropped packets on the way, and those are not coming back.
        if (result != null && result.lwwSkips.isNotEmpty) ...[
          kClassicGroupGap,
          ClassicGroupBox(
            title: 'Not applied — this device already had a newer value',
            child: _LwwSkipList(skips: result.lwwSkips),
          ),
        ],
        if (result != null && result.skippedPackets.isNotEmpty) ...[
          kClassicGroupGap,
          ClassicGroupBox(
            title: 'Could not be read',
            child: _SkippedPacketList(packets: result.skippedPackets),
          ),
        ],
      ],
    );
  }
}

/// The remote changes that arrived and were dropped by last-writer-wins.
///
/// This is the box that distinguishes "the other device never sent it" from
/// "it came and this device kept its own value" — the second reads as a
/// successful, empty sync everywhere else in the UI.
class _LwwSkipList extends StatelessWidget {
  final List<SyncLwwSkip> skips;

  const _LwwSkipList({required this.skips});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A tie means both devices skip each other's value and stay diverged; a
    // large one-sided gap usually means this device's clock runs ahead.
    final bool anyTie = skips.any((s) => s.localAheadBy == Duration.zero);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final skip in skips) _LwwSkipRow(skip: skip),
            const SizedBox(height: 6),
            Text(
              anyTie
                  ? 'Timestamps that match exactly are kept as they are on '
                      'both devices, so the two stay different. Edit the item '
                      'again on the device whose version you want to keep.'
                  : 'The incoming value was older than this device\'s, so it '
                      'was not written. If it should have won, check that the '
                      'clocks on both devices agree.',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            ),
          ],
        ),
      ),
    );
  }
}

/// One dropped-by-LWW line: what it was, and both timestamps that decided it.
class _LwwSkipRow extends StatelessWidget {
  final SyncLwwSkip skip;

  const _LwwSkipRow({required this.skip});

  static final DateFormat _stamp = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// "1m 16s ahead", or "same timestamp" for the tie.
  static String _skew(Duration d) {
    if (d == Duration.zero) return 'same timestamp';
    final seconds = d.inSeconds;
    if (seconds < 60) return 'local $seconds s ahead';
    if (seconds < 3600) {
      return 'local ${d.inMinutes} min ${seconds % 60} s ahead';
    }
    if (d.inHours < 48) {
      return 'local ${d.inHours} h ${d.inMinutes % 60} min ahead';
    }
    return 'local ${d.inDays} days ahead';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = skip.label ?? '${skip.entityType} ${skip.worldId}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.block_outlined,
                size: 14, color: theme.colorScheme.tertiary),
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
                        text: name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: '  ·  ${skip.field}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.hintColor),
                      ),
                    ],
                  ),
                ),
                SelectableText(
                  'incoming ${_stamp.format(skip.remoteTimestamp.toLocal())} · '
                  'local ${_stamp.format(skip.localTimestamp.toLocal())} '
                  '(${_skew(skip.localAheadBy)})',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Packets that reached this device and could not be turned into changes.
/// Their contents are lost — the applied vector moved past them — so this box
/// says so plainly rather than leaving a silent gap.
class _SkippedPacketList extends StatelessWidget {
  final List<SyncSkippedPacket> packets;

  const _SkippedPacketList({required this.packets});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool anyDecrypt = packets.any((p) => p.isDecryptFailure);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final packet in packets)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(Icons.help_outline,
                          size: 14, color: theme.colorScheme.error),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SelectableText(
                        '${packet.id}  ·  ${packet.stage} failed  ·  '
                        '${packet.detail}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Text(
              anyDecrypt
                  ? 'These packets could not be decrypted, which means this '
                      'database\'s password differs from the one on the device '
                      'that wrote them. Sync does not retry them: make the '
                      'passwords match, then re-save the affected items on '
                      'the other device so they are sent again.'
                  : 'These packets could not be read and sync has moved past '
                      'them — their changes will not arrive on their own. '
                      'Re-save the affected items on the other device to send '
                      'them again.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ],
        ),
      ),
    );
  }
}

/// One stage line: the stage name in the label column, then a status glyph and
/// either the stage's own note ("3 changes pushed") or a plain status word.
class _StageRow extends StatelessWidget {
  final String label;
  final String? detail;
  final SyncStageState state;
  final double labelWidth;

  const _StageRow({
    required this.label,
    required this.detail,
    required this.state,
    required this.labelWidth,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool dimmed =
        state == SyncStageState.pending || state == SyncStageState.skipped;
    final String status =
        (detail != null && detail!.isNotEmpty) ? detail! : _stageStatus[state]!;

    return ClassicField(
      label: label,
      labelWidth: labelWidth,
      expand: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 18, height: 18, child: Center(child: _glyph(theme))),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: state == SyncStageState.active
                    ? FontWeight.w600
                    : FontWeight.normal,
                color: state == SyncStageState.failed
                    ? theme.colorScheme.error
                    : dimmed
                        ? theme.hintColor
                        : theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glyph(ThemeData theme) {
    switch (state) {
      case SyncStageState.pending:
        return Icon(Icons.radio_button_unchecked,
            size: 14, color: theme.colorScheme.outlineVariant);
      case SyncStageState.active:
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case SyncStageState.done:
        return const Icon(Icons.check, size: 16, color: Colors.green);
      case SyncStageState.skipped:
        return Icon(Icons.remove, size: 16, color: theme.hintColor);
      case SyncStageState.failed:
        return Icon(Icons.close, size: 16, color: theme.colorScheme.error);
    }
  }
}

/// The change rows of one group box, scrollable once the list gets long so a
/// busy sync cannot push the buttons off screen.
class _ChangeList extends StatelessWidget {
  final List<SyncEntityChange> changes;

  const _ChangeList({required this.changes});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 200),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (final change in changes) _ChangeRow(change: change)],
        ),
      ),
    );
  }
}

/// One change line: a kind glyph, the entity label, and an optional detail.
class _ChangeRow extends StatelessWidget {
  final SyncEntityChange change;

  const _ChangeRow({required this.change});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final IconData icon;
    final Color color;
    switch (change.kind) {
      case SyncEntityChangeKind.created:
        icon = Icons.add_circle_outline;
        color = Colors.green;
        break;
      case SyncEntityChangeKind.updated:
        icon = Icons.edit_outlined;
        color = theme.colorScheme.primary;
        break;
      case SyncEntityChangeKind.removed:
        icon = Icons.remove_circle_outline;
        color = theme.colorScheme.error;
        break;
    }

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
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
          ),
        ],
      ),
    );
  }
}

/// Error message, framed like the other boxed controls rather than as a filled
/// Material banner.
class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.error),
        borderRadius: BorderRadius.circular(3),
      ),
      child: SelectableText(
        message,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.error),
      ),
    );
  }
}
