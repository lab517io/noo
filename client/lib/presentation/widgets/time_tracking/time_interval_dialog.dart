import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/entities/time_line.dart';
import '../../../l10n/l10n.dart';

enum TimeIntervalMode { add, edit }

/// Result returned when user accepts a time interval.
class TimeIntervalResult {
  final DateTime startTime;
  final DateTime endTime;

  const TimeIntervalResult({
    required this.startTime,
    required this.endTime,
  });
}

/// Dialog for adding or editing a time interval.
/// Equivalent to Qt's TimeIntervalDlg.
class TimeIntervalDialog extends StatefulWidget {
  final DateTime initialStart;
  final DateTime initialEnd;
  final TimeLine timeLine;
  final TimeIntervalMode mode;

  /// When editing, exclude this record from overlap detection.
  final int? editingRecordId;

  const TimeIntervalDialog({
    super.key,
    required this.initialStart,
    required this.initialEnd,
    required this.timeLine,
    required this.mode,
    this.editingRecordId,
  });

  @override
  State<TimeIntervalDialog> createState() => _TimeIntervalDialogState();
}

class _TimeIntervalDialogState extends State<TimeIntervalDialog> {
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;

  // TimeOfDay has minute precision only. Preserve the original seconds so
  // accepting an unmodified dialog doesn't silently shift a record by up to
  // 59 s; they are reset to 0 when the user picks a new time.
  late int _startSeconds;
  late int _endSeconds;

  /// Why OK is disabled, if it is. Kept as a value rather than a message:
  /// [_validate] runs from initState, before the localizations can be read.
  _IntervalError? _validationError;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStart;
    _startTime = TimeOfDay.fromDateTime(widget.initialStart);
    _startSeconds = widget.initialStart.second;
    _endDate = widget.initialEnd;
    _endTime = TimeOfDay.fromDateTime(widget.initialEnd);
    _endSeconds = widget.initialEnd.second;
    _validate();
  }

  DateTime get _startDateTime => DateTime(
    _startDate.year,
    _startDate.month,
    _startDate.day,
    _startTime.hour,
    _startTime.minute,
    _startSeconds,
  );

  DateTime get _endDateTime => DateTime(
    _endDate.year,
    _endDate.month,
    _endDate.day,
    _endTime.hour,
    _endTime.minute,
    _endSeconds,
  );

  void _validate() {
    final start = _startDateTime;
    final end = _endDateTime;

    if (!end.isAfter(start)) {
      _validationError = _IntervalError.endBeforeStart;
      return;
    }

    // Check for overlaps with existing records (excluding the one being edited)
    final startUtc = start.toUtc();
    final endUtc = end.toUtc();

    final hasOverlap = widget.timeLine.records.any((r) {
      if (widget.editingRecordId != null && r.id == widget.editingRecordId) {
        return false;
      }
      final recordEnd = r.endTime ?? DateTime.now().toUtc();
      return startUtc.isBefore(recordEnd) && endUtc.isAfter(r.startTime);
    });

    if (hasOverlap) {
      _validationError = _IntervalError.overlaps;
      return;
    }

    _validationError = null;
  }

  @override
  Widget build(BuildContext context) {
    final isAdd = widget.mode == TimeIntervalMode.add;
    final dateFormat = DateFormat.yMMMd();
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(
          isAdd ? l10n.timeAddIntervalTitle : l10n.timeEditIntervalTitle),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Start time row
            _buildDateTimeRow(
              context,
              label: l10n.timeStartTime,
              date: _startDate,
              time: _startTime,
              dateFormat: dateFormat,
              onDateChanged: (date) {
                setState(() {
                  _startDate = date;
                  _validate();
                });
              },
              onTimeChanged: (time) {
                setState(() {
                  _startTime = time;
                  _startSeconds = 0;
                  _validate();
                });
              },
            ),
            const SizedBox(height: 16),
            // End time row
            _buildDateTimeRow(
              context,
              label: l10n.timeFinishTime,
              date: _endDate,
              time: _endTime,
              dateFormat: dateFormat,
              onDateChanged: (date) {
                setState(() {
                  _endDate = date;
                  _validate();
                });
              },
              onTimeChanged: (time) {
                setState(() {
                  _endTime = time;
                  _endSeconds = 0;
                  _validate();
                });
              },
            ),
            // Duration display
            const SizedBox(height: 16),
            if (_validationError == null && _endDateTime.isAfter(_startDateTime))
              _buildDurationInfo(context),
            // Validation error
            if (_validationError != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    switch (_validationError!) {
                      _IntervalError.endBeforeStart => l10n.timeEndBeforeStart,
                      _IntervalError.overlaps => l10n.timeOverlaps,
                    },
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _validationError == null
              ? () {
                  Navigator.of(context).pop(TimeIntervalResult(
                    startTime: _startDateTime,
                    endTime: _endDateTime,
                  ));
                }
              : null,
          child: Text(l10n.commonOk),
        ),
      ],
    );
  }

  Widget _buildDateTimeRow(
    BuildContext context, {
    required String label,
    required DateTime date,
    required TimeOfDay time,
    required DateFormat dateFormat,
    required ValueChanged<DateTime> onDateChanged,
    required ValueChanged<TimeOfDay> onTimeChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        // Date button
        OutlinedButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) {
              onDateChanged(picked);
            }
          },
          child: Text(dateFormat.format(date)),
        ),
        const SizedBox(width: 8),
        // Time button
        OutlinedButton(
          onPressed: () async {
            final picked = await showTimePicker(
              context: context,
              initialTime: time,
            );
            if (picked != null) {
              onTimeChanged(picked);
            }
          },
          child: Text(time.format(context)),
        ),
      ],
    );
  }

  Widget _buildDurationInfo(BuildContext context) {
    final duration = _endDateTime.difference(_startDateTime);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    final l10n = context.l10n;
    String durationStr;
    if (hours > 0 && minutes > 0) {
      durationStr = l10n.timeDurationHoursMinutes(hours, minutes);
    } else if (hours > 0) {
      durationStr = l10n.timeDurationHours(hours);
    } else {
      durationStr = l10n.timeDurationMinutes(minutes);
    }

    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            l10n.timeDurationLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          durationStr,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

enum _IntervalError { endBeforeStart, overlaps }
