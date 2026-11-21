import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// What the app shows to keep a running clock in view once the user has moved
/// on to another task: the status bar's tracking chip, the tree's marker, the
/// window title and the mini tracker all read from here.
///
/// The status bar on its own follows the *selected* task, so selecting
/// anything else used to leave no sign at all that a clock was still running.

/// Time since the running session started, ticking once a second; null while
/// nothing is tracked.
///
/// One ticker for every reader, and only while tracking: the providers built
/// on it coarsen it (the window title to minutes) so their own listeners are
/// not woken every second.
final trackingElapsedProvider =
    NotifierProvider<TrackingElapsedNotifier, Duration?>(
      TrackingElapsedNotifier.new,
    );

class TrackingElapsedNotifier extends Notifier<Duration?> {
  /// The wall clock, replaceable in tests.
  static DateTime Function() now = () => DateTime.now().toUtc();

  @override
  Duration? build() {
    final start = ref.watch(activeTrackingStartTimeProvider);
    if (start == null) return null;
    final timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => state = _since(start),
    );
    ref.onDispose(timer.cancel);
    return _since(start);
  }

  static Duration _since(DateTime start) {
    final elapsed = now().difference(start);
    // A clock set back under a running session would otherwise read negative.
    return elapsed.isNegative ? Duration.zero : elapsed;
  }
}

/// Title of the tracked task as the tree shows it (`Untitled` for an empty
/// one), or null while nothing is tracked. From the tree, like
/// [selectedTaskTitleProvider], so it follows a rename as it is typed.
final trackedTaskTitleProvider = Provider<String?>((ref) {
  final taskId = ref.watch(activeTrackingTaskIdProvider);
  final controller = ref.watch(taskTreeControllerProvider);
  if (taskId == null || controller == null) return null;
  final node = controller.findNode(taskId);
  if (node == null) return null;
  final title = node.title.trim();
  return title.isEmpty ? 'Untitled' : title;
});

/// Ids of every ancestor of the tracked task; empty while nothing is tracked.
///
/// The tree marks the tracked row itself, and also a *collapsed* row that
/// contains it — otherwise folding the branch would hide the one marker
/// there is. Tiles `select` their own membership, so a tree notification only
/// rebuilds the rows whose answer changed.
final trackedTaskAncestorIdsProvider = Provider<Set<int>>((ref) {
  final taskId = ref.watch(activeTrackingTaskIdProvider);
  final controller = ref.watch(taskTreeControllerProvider);
  if (taskId == null || controller == null) return const {};
  final ancestors = <int>{};
  var parentId = controller.findNode(taskId)?.parentId;
  // Bounded by the tree itself: a parent seen twice is a cycle, not a path.
  while (parentId != null && ancestors.add(parentId)) {
    parentId = controller.findNode(parentId)?.parentId;
  }
  return ancestors;
});

/// The tracking part of the window title — `42m Report` — or null while
/// nothing is tracked. Minutes only: the taskbar and alt-tab re-read the title
/// on every change, and a title rewritten every second is noise there.
final trackingTitleProvider = Provider<String?>((ref) {
  final title = ref.watch(trackedTaskTitleProvider);
  if (title == null) return null;
  final minutes = ref.watch(
    trackingElapsedProvider.select((d) => d?.inMinutes ?? 0),
  );
  return '${formatTrackingMinutes(minutes)} $title';
});

/// `0m`, `42m`, `1:05`: the elapsed time as the title shows it.
String formatTrackingMinutes(int minutes) {
  if (minutes < 60) return '${minutes}m';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return '$h:${m.toString().padLeft(2, '0')}';
}
