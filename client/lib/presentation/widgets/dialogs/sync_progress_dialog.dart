import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/platform_info.dart';
import '../../../data/services/sync_service.dart';
import '../../../l10n/l10n.dart';
import '../../providers/sync_provider.dart';
import 'classic_form.dart';
import 'sync_change_list.dart';
import 'sync_log_dialog.dart';
import '../../../core/theme/noo_chrome.dart';

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
String _stageLabel(AppLocalizations l10n, SyncStage stage) => switch (stage) {
      SyncStage.preparing => l10n.syncStagePreparing,
      SyncStage.authenticating => l10n.syncStageAuthenticating,
      SyncStage.pushing => l10n.syncStagePushing,
      SyncStage.applying => l10n.syncStageApplying,
    };

/// Status word shown for a stage that carries no detail of its own.
String _stageStatus(AppLocalizations l10n, SyncStageState state) =>
    switch (state) {
      SyncStageState.pending => l10n.syncStatePending,
      SyncStageState.active => l10n.syncStateActive,
      SyncStageState.done => l10n.syncStateDone,
      SyncStageState.skipped => l10n.syncStateSkipped,
      SyncStageState.failed => l10n.syncStateFailed,
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
    final l10n = context.l10n;
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
    if (report.cancelling) {
      titleText = l10n.syncCancelling;
    } else if (report.running) {
      titleText = l10n.syncSynchronizing;
    } else if (report.cancelled) {
      titleText = l10n.syncCancelled;
    } else if (report.failed) {
      titleText = l10n.syncFailed;
    } else if (idle) {
      titleText = l10n.syncTitle;
    } else {
      titleText = l10n.syncComplete;
    }

    // The action offered besides plain dismissal, if any.
    final String? actionLabel = report.failed
        ? l10n.commonRetry
        : idle || report.cancelled
            ? l10n.syncNow
            : null;

    // While running there are two ways out: Cancel stops the sync itself,
    // Hide only closes the dialog and leaves it running (the toolbar
    // indicator reports the outcome). Cancel stays disabled once pressed —
    // the run finishes the request already on the wire before it stops.
    final VoidCallback? onCancel =
        report.cancelling ? null : () => cancelSync(ref);
    final String cancelLabel =
        report.cancelling ? l10n.syncCancelling : l10n.commonCancel;

    final body = _buildBody(theme, l10n, report, idle, scale);

    // Phones: present the same content full-screen, as the preferences sheet
    // does, instead of squeezing the property sheet onto a narrow screen.
    if (isCompactLayout(context)) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text(titleText),
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: report.running ? l10n.commonHide : l10n.commonClose,
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.receipt_long_outlined),
                tooltip: l10n.syncShowFullLogTooltip,
                onPressed: () => showSyncLogDialog(context),
              ),
              if (report.running)
                TextButton(onPressed: onCancel, child: Text(cancelLabel)),
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
      shape: NooChrome.of(context).dialogShape,
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
          child: Text(l10n.syncShowFullLog),
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
            child: Text(l10n.commonClose),
          ),
        ] else if (report.running) ...[
          OutlinedButton(
            style: classicButtonStyle(context),
            onPressed: onCancel,
            child: Text(cancelLabel),
          ),
          FilledButton(
            style: classicButtonStyle(context),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonHide),
          ),
        ] else
          FilledButton(
            style: classicButtonStyle(context),
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonClose),
          ),
      ],
    );
  }

  /// The group boxes making up the dialog body, shared by both layouts.
  Widget _buildBody(
    ThemeData theme,
    AppLocalizations l10n,
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
          title: l10n.syncGroupProgress,
          child: idle
              ? Text(
                  l10n.syncNoRunYet,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final stage in SyncStage.values) ...[
                      if (stage != SyncStage.values.first) kClassicRowGap,
                      _StageRow(
                        label: _stageLabel(l10n, stage),
                        detail: report.detailOf(stage),
                        state: report.stateOf(stage),
                        fraction: report.fractionOf(stage),
                        labelWidth: _kStageLabelWidth * scale,
                      ),
                    ],
                  ],
                ),
        ),
        if (report.cancelled) ...[
          const SizedBox(height: 8),
          Text(
            l10n.syncCancelledNote,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
          ),
        ],
        if (report.failed && report.errorMessage != null) ...[
          kClassicGroupGap,
          ClassicGroupBox(
            title: l10n.commonError,
            child: _ErrorBox(message: report.errorMessage!),
          ),
        ],
        if (report.succeeded && result != null) ...[
          kClassicGroupGap,
          ClassicGroupBox(
            title: l10n.syncGroupSummary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClassicField(
                  label: l10n.syncChangesPushed,
                  labelWidth: _kStageLabelWidth * scale,
                  child: Text('${result.changesPushed}'),
                ),
                kClassicRowGap,
                ClassicField(
                  label: l10n.syncChangesApplied,
                  labelWidth: _kStageLabelWidth * scale,
                  child: Text('${result.changesApplied}'),
                ),
              ],
            ),
          ),
          if (result.applied.isNotEmpty) ...[
            kClassicGroupGap,
            ClassicGroupBox(
              title: l10n.syncGroupApplied,
              child: SyncChangeList(
                changes: result.applied,
                logRunId: result.logRunId,
                more: l10n.syncMoreSeeFullLog,
              ),
            ),
          ],
          if (result.pushed.isNotEmpty) ...[
            kClassicGroupGap,
            ClassicGroupBox(
              title: l10n.syncGroupPushed,
              child: SyncChangeList(
                changes: result.pushed,
                logRunId: result.logRunId,
                more: l10n.syncMoreSeeFullLog,
              ),
            ),
          ],
        ],
        // Shown for failed runs too: a run that died half-way can still have
        // dropped packets on the way, and those are not coming back.
        if (result != null && result.lwwSkips.isNotEmpty) ...[
          kClassicGroupGap,
          ClassicGroupBox(
            title: l10n.syncGroupLwwSkipped,
            child: _LwwSkipList(skips: result.lwwSkips),
          ),
        ],
        if (result != null && result.skippedPackets.isNotEmpty) ...[
          kClassicGroupGap,
          ClassicGroupBox(
            title: l10n.syncGroupUnreadable,
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
            ...cappedSyncRows(
              context,
              skips,
              (_, skip) => _LwwSkipRow(skip: skip),
              more: context.l10n.syncMoreSeeFullLog,
            ),
            const SizedBox(height: 6),
            Text(
              anyTie
                  ? context.l10n.syncLwwTieNote
                  : context.l10n.syncLwwOlderNote,
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
  static String _skew(AppLocalizations l10n, Duration d) {
    if (d == Duration.zero) return l10n.syncSkewSame;
    final seconds = d.inSeconds;
    if (seconds < 60) return l10n.syncSkewSeconds(seconds);
    if (seconds < 3600) {
      return l10n.syncSkewMinutes(d.inMinutes, seconds % 60);
    }
    if (d.inHours < 48) {
      return l10n.syncSkewHours(d.inHours, d.inMinutes % 60);
    }
    return l10n.syncSkewDays(d.inDays);
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
                  context.l10n.syncLwwSkipTimes(
                    _stamp.format(skip.remoteTimestamp.toLocal()),
                    _stamp.format(skip.localTimestamp.toLocal()),
                    _skew(context.l10n, skip.localAheadBy),
                  ),
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
            ...cappedSyncRows(
              context,
              packets,
              (_, packet) => Padding(
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
                        context.l10n.syncSkippedPacketLine(
                            packet.id, packet.stage, packet.detail),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
              more: context.l10n.syncMoreSeeFullLog,
            ),
            const SizedBox(height: 6),
            Text(
              anyDecrypt
                  ? context.l10n.syncSkippedDecryptNote
                  : context.l10n.syncSkippedUnreadableNote,
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

  /// 0..1 while an active stage knows how far it is; draws a bar under the
  /// status.
  final double? fraction;

  const _StageRow({
    required this.label,
    required this.detail,
    required this.state,
    required this.labelWidth,
    this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool dimmed =
        state == SyncStageState.pending || state == SyncStageState.skipped;
    final String status =
        (detail != null && detail!.isNotEmpty)
        ? detail!
        : _stageStatus(context.l10n, state);

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
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
                if (fraction != null && state == SyncStageState.active) ...[
                  const SizedBox(height: 4),
                  LinearProgressIndicator(value: fraction),
                ],
              ],
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
        borderRadius: NooChrome.of(context).smallRadius,
      ),
      child: SelectableText(
        message,
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.error),
      ),
    );
  }
}
