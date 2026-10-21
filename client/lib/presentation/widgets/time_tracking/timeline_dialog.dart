import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/time_line.dart';
import 'timeline_view.dart';

/// Dialog for viewing and managing time intervals for a task.
///
/// Chrome only: the record tree and its commands live in [TimelineView], which
/// the Time tab of the phone task screen hosts directly — there, a task's time
/// records are part of the node rather than something you open a dialog for.
class TimelineDialog extends ConsumerWidget {
  final int taskId;
  final TimeLine timeLine;
  final VoidCallback? onChanged;

  const TimelineDialog({
    super.key,
    required this.taskId,
    required this.timeLine,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fit within a phone screen; the desktop size is the ceiling. The dialog's
    // own insets take ~80px horizontally, the rest of the slack is margin.
    final screen = MediaQuery.sizeOf(context);
    return AlertDialog(
      title: const Text('Timeline'),
      content: SizedBox(
        width: math.min(500, screen.width - 112),
        height: math.min(400, screen.height * 0.6),
        child: TimelineView(
          taskId: taskId,
          timeLine: timeLine,
          onChanged: onChanged,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
