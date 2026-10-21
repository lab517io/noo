import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/duration_formatter.dart';
import '../../../domain/entities/time_line.dart';
import '../../providers/providers.dart';
import '../../providers/settings_provider.dart';

/// Time tracking details for the selected task: today / this-month totals and
/// the active session readout. Equivalent to Qt's NodePropertiesWidget time
/// section.
///
/// Body only — the section header moved into the editor status bar, which owns
/// the expand/collapse toggle and the start/stop and timeline controls. This
/// widget is mounted only while the section is expanded.
class TimeStatsPanel extends ConsumerStatefulWidget {
  final int taskId;

  const TimeStatsPanel({
    super.key,
    required this.taskId,
  });

  @override
  ConsumerState<TimeStatsPanel> createState() => _TimeStatsPanelState();
}

class _TimeStatsPanelState extends ConsumerState<TimeStatsPanel> {
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    _updateTickTimer();
  }

  @override
  void didUpdateWidget(TimeStatsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.taskId != widget.taskId) _updateTickTimer();
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  void _updateTickTimer() {
    _tickTimer?.cancel();
    final isTracking = ref.read(activeTrackingTaskIdProvider) == widget.taskId;
    if (isTracking) {
      _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTaskId = ref.watch(activeTrackingTaskIdProvider);
    final isTracking = activeTaskId == widget.taskId;
    final settings = ref.watch(settingsProvider);

    // Refresh tick timer when tracking state changes
    ref.listen(activeTrackingTaskIdProvider, (_, _) => _updateTickTimer());

    // Keep the last loaded records on screen while a reload is in flight so the
    // totals don't blank out on every start/stop.
    final timeLine = ref.watch(taskTimelineProvider(widget.taskId)).value;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: timeLine == null
          ? const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          : _buildStats(context, timeLine, settings, isTracking),
    );
  }

  // The active session's open-ended record is persisted at start and part of
  // the timeline, and TimeRecord.duration counts open records up to now — so no
  // manual elapsed time is added to the totals here (it would double-count).
  Widget _buildStats(
    BuildContext context,
    TimeLine timeLine,
    AppSettings settings,
    bool isTracking,
  ) {
    final showSeconds = settings.showSeconds;

    return Column(
      children: [
        _buildStatRow(
          context,
          'Today:',
          DurationFormatter.formatHMS(timeLine.today, showSeconds: showSeconds),
        ),
        const SizedBox(height: 4),
        _buildStatRow(
          context,
          'This month:',
          DurationFormatter.formatHMS(timeLine.thisMonth,
              showSeconds: showSeconds),
        ),
        if (isTracking) ...[
          const SizedBox(height: 8),
          _buildActiveTrackingInfo(context),
        ],
      ],
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTrackingInfo(BuildContext context) {
    final activeStart = ref.read(activeTrackingStartTimeProvider);
    if (activeStart == null) return const SizedBox.shrink();

    final elapsed = DateTime.now().toUtc().difference(activeStart);
    final startLocal = activeStart.toLocal();
    final timeFormat = DateFormat.Hm();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.fiber_manual_record,
            size: 12,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 8),
          Text(
            'Recording since ${timeFormat.format(startLocal)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Spacer(),
          Text(
            DurationFormatter.formatHMS(elapsed),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
