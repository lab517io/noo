import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/database.dart';
import '../../providers/providers.dart';

/// Start/stop actions for the active tracking session.
///
/// Lives outside any widget because the controls sit in the editor status bar
/// while the readout sits in the (optionally collapsed) stats panel — both must
/// drive the exact same record lifecycle.

/// Finalize the persisted open-ended record for the active session.
/// Falls back to creating a closed record if the open one is missing
/// (e.g. session state predates the record-at-start behavior).
Future<void> finalizeActiveTimeRecord(WidgetRef ref, NooDatabase db) async {
  final recordId = ref.read(activeTrackingRecordIdProvider);
  final startTime = ref.read(activeTrackingStartTimeProvider);
  final taskId = ref.read(activeTrackingTaskIdProvider);
  final now = DateTime.now().toUtc();

  if (recordId != null) {
    await db.updateTimeRecord(recordId, endTime: now.toIso8601String());
  } else if (taskId != null && startTime != null) {
    await db.createTimeRecord(
      taskId: taskId,
      worldId: WorldId.create().value,
      startTime: startTime.toIso8601String(),
      endTime: now.toIso8601String(),
    );
  }
}

void clearActiveTrackingState(WidgetRef ref) {
  ref.read(activeTrackingTaskIdProvider.notifier).value = null;
  ref.read(activeTrackingStartTimeProvider.notifier).value = null;
  ref.read(activeTrackingRecordIdProvider.notifier).value = null;
}

/// Toggle tracking for [taskId]: stop it if it is the task being tracked,
/// otherwise start it (finalizing any other task's session first).
Future<void> toggleTracking(WidgetRef ref, int taskId) async {
  final db = ref.read(databaseProvider);
  if (db == null) return;

  final activeTaskId = ref.read(activeTrackingTaskIdProvider);

  if (activeTaskId == taskId) {
    // Stop tracking
    await finalizeActiveTimeRecord(ref, db);
    clearActiveTrackingState(ref);
    ref.read(timelineRefreshProvider.notifier).value++;
    return;
  }

  // Stop any other active tracking first
  if (activeTaskId != null) {
    await finalizeActiveTimeRecord(ref, db);
  }
  // Start tracking this task: persist the open-ended record immediately
  // so the interval survives a crash or app exit.
  final start = DateTime.now().toUtc();
  final recordId = await db.createTimeRecord(
    taskId: taskId,
    worldId: WorldId.create().value,
    startTime: start.toIso8601String(),
  );
  ref.read(activeTrackingTaskIdProvider.notifier).value = taskId;
  ref.read(activeTrackingStartTimeProvider.notifier).value = start;
  ref.read(activeTrackingRecordIdProvider.notifier).value = recordId;
  ref.read(timelineRefreshProvider.notifier).value++;
}
