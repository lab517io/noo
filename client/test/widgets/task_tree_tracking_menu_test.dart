import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/providers/settings_provider.dart';
import 'package:noo/presentation/widgets/task_tree/task_tree_panel.dart';
import 'package:noo/presentation/widgets/time_tracking/timeline_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The tracking entries of the tree's context menu: Start/Stop tracking on
/// every row, Timeline... only on a row whose task has time records — and
/// both act on the row right-clicked, not on the selected task.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NooDatabase db;
  late int alphaId;
  late int betaId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = NooDatabase.memory();
    alphaId = await db.createTask(
        worldId: WorldId.create().value, title: 'Alpha', orderId: 0);
    betaId = await db.createTask(
        worldId: WorldId.create().value, title: 'Beta', orderId: 1);
    final start = DateTime.utc(2026, 11, 3, 9);
    await db.createTimeRecord(
      taskId: alphaId,
      worldId: WorldId.create().value,
      startTime: start.toIso8601String(),
      endTime: start.add(const Duration(hours: 1)).toIso8601String(),
    );
  });

  tearDown(() async => db.close());

  Future<ProviderContainer> pumpTree(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    // Off by default for a fresh install; these tests exercise it.
    container.read(settingsProvider.notifier).setTimeTrackingEnabled(true);
    container.read(selectedTaskIdProvider.notifier).value = betaId;
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        home: Scaffold(body: SizedBox(width: 300, child: TaskTreePanel())),
      ),
    ));
    await tester.pumpAndSettle();
    return container;
  }

  /// Right-click [title]'s row; the menu opens once the database has said
  /// whether the task has time records.
  Future<void> rightClick(WidgetTester tester, String title) async {
    await tester.runAsync(() async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.text(title)),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryButton,
      );
      await gesture.up();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
  }

  Future<void> onDesktop(Future<void> Function() body) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await body();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  testWidgets('with time tracking off the menu has no tracking entries',
      (tester) async {
    await onDesktop(() async {
      final container = await pumpTree(tester);
      container.read(settingsProvider.notifier).setTimeTrackingEnabled(false);

      await rightClick(tester, 'Alpha');
      expect(find.text('Rename'), findsOneWidget);
      expect(find.text('Start tracking'), findsNothing);
      expect(find.text('Timeline...'), findsNothing,
          reason: 'not even on a row that has time records');
    });
  });

  testWidgets('Timeline... is offered only where there are time records',
      (tester) async {
    await onDesktop(() async {
      await pumpTree(tester);

      await rightClick(tester, 'Beta');
      expect(find.text('Start tracking'), findsOneWidget);
      expect(find.text('Timeline...'), findsNothing);
      await tester.tapAt(const Offset(790, 590));
      await tester.pumpAndSettle();

      await rightClick(tester, 'Alpha');
      expect(find.text('Start tracking'), findsOneWidget);
      expect(find.text('Timeline...'), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.text('Timeline...'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      final dialog = tester.widget<TimelineDialog>(find.byType(TimelineDialog));
      expect(dialog.taskId, alphaId,
          reason: 'the row right-clicked, not the selected Beta');
      expect(dialog.timeLine.records, hasLength(1));
    });
  });

  testWidgets('Start tracking tracks the row; the menu then offers Stop',
      (tester) async {
    await onDesktop(() async {
      final container = await pumpTree(tester);

      await rightClick(tester, 'Alpha');
      await tester.runAsync(() async {
        await tester.tap(find.text('Start tracking'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(container.read(activeTrackingTaskIdProvider), alphaId);
      expect(container.read(selectedTaskIdProvider), betaId);

      await rightClick(tester, 'Alpha');
      expect(find.text('Stop tracking'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('Stop tracking'));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      expect(container.read(activeTrackingTaskIdProvider), isNull);
      final records = await tester
          .runAsync(() => db.getTimelineForTask(alphaId));
      expect(records, hasLength(2));
      expect(records!.every((r) => r.endTime != null), isTrue);
    });
  });
}
