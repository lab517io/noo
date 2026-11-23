import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/platform/window_state.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/providers/settings_provider.dart';
import 'package:noo/presentation/providers/tracking_indicator_provider.dart';
import 'package:noo/presentation/widgets/status_bar/status_bar.dart';
import 'package:noo/presentation/widgets/task_tree/task_tree_panel.dart';
import 'package:noo/presentation/widgets/time_tracking/mini_tracker.dart';
import 'package:noo/presentation/widgets/window_title_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The hints that keep a running clock in view after the user has selected
/// another task: the window title, the status bar chip, the tree's marker and
/// the mini tracker.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NooDatabase db;
  late int parentId;
  late int childId;
  late int otherId;
  final start = DateTime.utc(2026, 11, 20, 9);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TrackingElapsedNotifier.now = () => start.add(const Duration(minutes: 42));
    db = NooDatabase.memory();
    parentId = await db.createTask(
      worldId: WorldId.create().value,
      title: 'Project',
      orderId: 0,
    );
    childId = await db.createTask(
      worldId: WorldId.create().value,
      parentId: parentId,
      title: 'Report',
      orderId: 0,
    );
    otherId = await db.createTask(
      worldId: WorldId.create().value,
      title: 'Inbox',
      orderId: 1,
    );
  });

  tearDown(() async {
    TrackingElapsedNotifier.now = () => DateTime.now().toUtc();
    await db.close();
  });

  Future<ProviderContainer> makeContainer() async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    container.read(settingsProvider.notifier).setTimeTrackingEnabled(true);
    final controller = container.read(taskTreeControllerProvider)!;
    while (!controller.isLoaded || controller.isLoading) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    return container;
  }

  /// Marks [taskId] as tracked since [start] without touching the database.
  void track(ProviderContainer container, int? taskId) {
    container.read(activeTrackingTaskIdProvider.notifier).value = taskId;
    container.read(activeTrackingStartTimeProvider.notifier).value =
        taskId == null ? null : start;
  }

  group('window title', () {
    test('the clock goes first, behind a dot', () {
      expect(
        windowTitleText('work.noo', taskTitle: 'Inbox', tracking: '42m Report'),
        '● 42m Report — Noo — work.noo — Inbox',
      );
      expect(
        windowTitleText(null, tracking: '42m Report'),
        'Noo',
        reason: 'nothing tracked without a database',
      );
    });

    test('minutes, then hours', () {
      expect(formatTrackingMinutes(0), '0m');
      expect(formatTrackingMinutes(42), '42m');
      expect(formatTrackingMinutes(65), '1:05');
    });

    test(
      'trackingTitleProvider names the tracked task, whatever is selected',
      () async {
        final container = await makeContainer();
        expect(container.read(trackingTitleProvider), isNull);

        container.read(selectedTaskIdProvider.notifier).value = otherId;
        track(container, childId);
        expect(container.read(trackingTitleProvider), '42m Report');

        container
            .read(taskTreeControllerProvider)!
            .updateTaskTitleInMemory(childId, 'Quarterly');
        expect(
          container.read(trackingTitleProvider),
          '42m Quarterly',
          reason: 'follows a rename as it is typed',
        );

        track(container, null);
        expect(container.read(trackingTitleProvider), isNull);
      },
    );

    test('ancestors of the tracked task', () async {
      final container = await makeContainer();
      expect(container.read(trackedTaskAncestorIdsProvider), isEmpty);
      track(container, childId);
      expect(container.read(trackedTaskAncestorIdsProvider), {parentId});
      track(container, otherId);
      expect(container.read(trackedTaskAncestorIdsProvider), isEmpty);
    });
  });

  Widget app(
    ProviderContainer container,
    Widget home, {
    TransitionBuilder? builder,
  }) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      builder: builder,
      home: home,
    ),
  );

  void desktopView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets(
    'the tree marks the tracked row, and a folded branch holding it',
    (tester) async {
      desktopView(tester);
      final container = await tester.runAsync(makeContainer);
      container!.read(selectedTaskIdProvider.notifier).value = otherId;
      await tester.pumpWidget(
        app(
          container,
          const Scaffold(body: SizedBox(width: 400, child: TaskTreePanel())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tracked-inside-icon')), findsNothing);

      track(container, childId);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('tracked-inside-icon')),
        findsOneWidget,
        reason: 'Project is collapsed, so Report is not on screen',
      );
      expect(find.byKey(const ValueKey('tracked-task-icon')), findsNothing);

      container.read(taskTreeControllerProvider)!.revealNode(childId);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('tracked-task-icon')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('tracked-inside-icon')),
        findsNothing,
        reason: 'an expanded parent shows its tracked child itself',
      );

      track(container, null);
      await tester.pump();
      expect(find.byKey(const ValueKey('tracked-task-icon')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the status bar shows a clock running on another task', (
    tester,
  ) async {
    desktopView(tester);
    final container = await tester.runAsync(makeContainer);
    container!.read(selectedTaskIdProvider.notifier).value = otherId;
    await tester.pumpWidget(
      app(
        container,
        const Scaffold(body: Column(children: [Spacer(), StatusBar()])),
      ),
    );
    await tester.pumpAndSettle();
    final chip = find.byKey(const ValueKey('tracking-chip'));
    expect(chip, findsNothing);

    track(container, childId);
    await tester.pump();
    expect(chip, findsOneWidget);
    expect(
      find.descendant(of: chip, matching: find.text('Report')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: chip, matching: find.text('00:42')),
      findsOneWidget,
    );

    await tester.tap(chip);
    await tester.pump();
    expect(
      container.read(selectedTaskIdProvider),
      childId,
      reason: 'clicking it goes to the tracked task',
    );
    expect(
      chip,
      findsNothing,
      reason: 'the bar\'s own sections now describe the tracked task',
    );

    track(container, null);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('the chip fits a phone\'s status bar', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final container = await tester.runAsync(makeContainer);
    container!.read(selectedTaskIdProvider.notifier).value = otherId;
    track(container, childId);
    await tester.pumpWidget(
      app(
        container,
        const Scaffold(body: Column(children: [Spacer(), StatusBar()])),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('tracking-chip')), findsOneWidget);
    expect(tester.takeException(), isNull, reason: 'no overflow');
    track(container, null);
    await tester.pumpAndSettle();
  });

  group('mini tracker', () {
    const channel = MethodChannel('window_manager');
    late List<MethodCall> calls;
    late Rect windowBounds;

    setUp(() {
      calls = [];
      windowBounds = const Rect.fromLTWH(100, 50, 1000, 700);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            switch (call.method) {
              case 'getBounds':
                return {
                  'x': windowBounds.left,
                  'y': windowBounds.top,
                  'width': windowBounds.width,
                  'height': windowBounds.height,
                };
              case 'setBounds':
                final a = call.arguments as Map;
                windowBounds = Rect.fromLTWH(
                  (a['x'] as double?) ?? windowBounds.left,
                  (a['y'] as double?) ?? windowBounds.top,
                  (a['width'] as double?) ?? windowBounds.width,
                  (a['height'] as double?) ?? windowBounds.height,
                );
                return null;
              case 'isMaximized':
              case 'isFullScreen':
                return false;
              default:
                return null;
            }
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      WindowStateStore.suspended = false;
    });

    Iterable<dynamic> argsOf(String method) =>
        calls.where((c) => c.method == method).map((c) => c.arguments);

    testWidgets('shrinks to a pill and comes back with the app as it was', (
      tester,
    ) async {
      desktopView(tester);
      final container = await tester.runAsync(makeContainer);
      container!.read(selectedTaskIdProvider.notifier).value = otherId;
      track(container, childId);

      await tester.pumpWidget(
        app(
          container,
          const _Probe(),
          builder: (context, child) => MiniTrackerHost(child: child!),
        ),
      );
      await tester.tap(find.text('count 0'));
      await tester.pump();

      await tester.runAsync(
        () => MiniTracker.enter(
          tester.element(find.byType(_Probe)),
          _refOf(tester),
        ),
      );
      // What the native window now is.
      tester.view.physicalSize = kMiniTrackerSize;
      await tester.pump();

      expect(find.byType(MiniTrackerBar), findsOneWidget);
      expect(find.text('Report'), findsOneWidget);
      expect(find.text('00:42'), findsOneWidget);
      expect(WindowStateStore.suspended, isTrue);
      expect(argsOf('setAlwaysOnTop').last, {'isAlwaysOnTop': true});
      expect(windowBounds.size, kMiniTrackerSize);
      expect(argsOf('setResizable').last, {'isResizable': false},
          reason: 'the pill\'s size is fixed');
      // Underneath, the app keeps its size and its state.
      expect(find.text('count 1 at 1000', skipOffstage: false), findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('mini-tracker-restore')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      tester.view.physicalSize = windowBounds.size;
      await tester.pump();

      expect(find.byType(MiniTrackerBar), findsNothing);
      expect(
        find.text('count 1 at 1000'),
        findsOneWidget,
        reason: 'the same state, never torn down',
      );
      expect(argsOf('setAlwaysOnTop').last, {'isAlwaysOnTop': false});
      expect(argsOf('setResizable').last, {'isResizable': true});
      expect(windowBounds, const Rect.fromLTWH(100, 50, 1000, 700));
      expect(WindowStateStore.suspended, isFalse);
      final prefs = await tester.runAsync(SharedPreferences.getInstance);
      expect(
        prefs!.getDouble('window_width'),
        1000,
        reason: 'the full window\'s geometry, never the pill\'s',
      );
      expect(
        prefs.getDouble('mini_tracker_x'),
        100,
        reason: 'where the pill was is where it opens next time',
      );

      track(container, null);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('stop in the pill stops the clock', (tester) async {
      desktopView(tester);
      final container = await tester.runAsync(makeContainer);
      container!.read(selectedTaskIdProvider.notifier).value = otherId;
      await tester.runAsync(() async {
        final recordId = await db.createTimeRecord(
          taskId: childId,
          worldId: WorldId.create().value,
          startTime: start.toIso8601String(),
        );
        track(container, childId);
        container.read(activeTrackingRecordIdProvider.notifier).value =
            recordId;
      });

      await tester.pumpWidget(
        app(
          container,
          const _Probe(),
          builder: (context, child) => MiniTrackerHost(child: child!),
        ),
      );
      await tester.runAsync(
        () => MiniTracker.enter(
          tester.element(find.byType(_Probe)),
          _refOf(tester),
        ),
      );
      tester.view.physicalSize = kMiniTrackerSize;
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('mini-tracker-stop')));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pump();
      expect(container.read(activeTrackingTaskIdProvider), isNull);
      expect(
        find.byKey(const ValueKey('mini-tracker-start')),
        findsOneWidget,
        reason: 'offers to start on the selected task instead',
      );
      expect(find.text('Inbox'), findsOneWidget);

      final records = await tester.runAsync(
        () => db.getTimelineForTask(childId),
      );
      expect(records!.single.endTime, isNotNull);

      await tester.runAsync(() => MiniTracker.leave(_refOf(tester)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('minimize becomes the pill only while tracking with the '
        'preference on', (tester) async {
      desktopView(tester);
      final container = await tester.runAsync(makeContainer);
      container!.read(selectedTaskIdProvider.notifier).value = otherId;

      await tester.pumpWidget(
        app(
          container,
          const _Probe(),
          builder: (context, child) => MiniTrackerHost(child: child!),
        ),
      );
      await tester.tap(find.text('count 0'));
      await tester.pump();

      // Preference off: an ordinary minimize, clock or not.
      track(container, childId);
      await tester.runAsync(MiniTracker.minimize);
      await tester.pump();
      expect(calls.where((c) => c.method == 'minimize'), hasLength(1));
      expect(find.byType(MiniTrackerBar), findsNothing);

      // On, but no clock running: still an ordinary minimize.
      await tester.runAsync(
        () => container
            .read(settingsProvider.notifier)
            .setMiniTrackerOnMinimize(true),
      );
      track(container, null);
      await tester.runAsync(MiniTracker.minimize);
      await tester.pump();
      expect(calls.where((c) => c.method == 'minimize'), hasLength(2));
      expect(find.byType(MiniTrackerBar), findsNothing);

      // On, with a clock: the pill instead of the taskbar.
      track(container, childId);
      await tester.runAsync(MiniTracker.minimize);
      tester.view.physicalSize = kMiniTrackerSize;
      await tester.pump();
      expect(calls.where((c) => c.method == 'minimize'), hasLength(2));
      expect(find.byType(MiniTrackerBar), findsOneWidget);
      expect(windowBounds.size, kMiniTrackerSize);
      expect(
        find.text('count 1 at 1000', skipOffstage: false),
        findsOneWidget,
        reason: 'laid out at the full window\'s size underneath',
      );

      await tester.runAsync(() => MiniTracker.leave(_refOf(tester)));
      tester.view.physicalSize = windowBounds.size;
      track(container, null);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    test('a saved pill position is kept only while it is on a display', () {
      const display = Rect.fromLTWH(0, 0, 1920, 1080);
      expect(MiniTracker.pillFits(const Offset(1500, 20), [display]), isTrue);
      expect(MiniTracker.pillFits(const Offset(1900, 20), [display]), isFalse);
      expect(MiniTracker.pillFits(const Offset(2500, 20), [display]), isFalse);
    });
  });
}

WidgetRef _refOf(WidgetTester tester) =>
    tester.state<_ProbeState>(find.byType(_Probe, skipOffstage: false)).ref;

/// A counter that reports the width it is laid out at, to show the app under
/// the pill keeps both its state and its size.
class _Probe extends ConsumerStatefulWidget {
  const _Probe();

  @override
  ConsumerState<_Probe> createState() => _ProbeState();
}

class _ProbeState extends ConsumerState<_Probe> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width.round();
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => setState(() => _count++),
          child: Text(_count == 0 ? 'count 0' : 'count $_count at $width'),
        ),
      ),
    );
  }
}
