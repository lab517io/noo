import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/history_service.dart';
import 'package:noo/data/services/sync_crypto.dart';
import 'package:noo/data/services/sync_service.dart';
import 'package:noo/domain/entities/sync_config.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/providers/settings_provider.dart';
import 'package:noo/presentation/widgets/app_menu_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The menu bar's commands that close the current database — Open, New and
/// Exit — owe it three things first: the editor's unsaved text, the running
/// tracking session, and (for Exit) a sync prompt whose Cancel must leave
/// everything as it was. These cover the order those happen in.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  late NooDatabase db;
  late int taskId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    // The settings notifier reads the sync password from the keychain while
    // loading; left unmocked the channel never answers inside fake async and
    // the settings — including syncOnExit — never arrive.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
      return switch (call.method) {
        'readAll' => <String, String>{},
        'containsKey' => false,
        _ => null,
      };
    });
    db = NooDatabase.memory();
    taskId = await db.createTask(
      worldId: WorldId.create().value,
      title: 'Tracked',
    );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
    await db.close();
  });

  /// Pump a host app on the root navigator the exit prompt uses, and hand
  /// back the container plus a live [WidgetRef] for the static commands.
  Future<(ProviderContainer, WidgetRef)> pumpHost(
    WidgetTester tester, {
    SyncService? syncService,
  }) async {
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      if (syncService != null)
        syncServiceProvider.overrideWithValue(syncService),
    ]);
    addTearDown(container.dispose);

    late WidgetRef ref;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          navigatorKey: rootNavigatorKey,
          home: Consumer(
            builder: (context, r, _) {
              ref = r;
              return const Scaffold(body: SizedBox());
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (container, ref);
  }

  /// Start a session the way the status bar does: an open-ended record in
  /// the database and the three tracking providers pointing at it.
  Future<int> startTracking(ProviderContainer container) async {
    final start = DateTime.now().toUtc();
    final recordId = await db.createTimeRecord(
      taskId: taskId,
      worldId: WorldId.create().value,
      startTime: start.toIso8601String(),
    );
    container.read(activeTrackingTaskIdProvider.notifier).value = taskId;
    container.read(activeTrackingStartTimeProvider.notifier).value = start;
    container.read(activeTrackingRecordIdProvider.notifier).value = recordId;
    return recordId;
  }

  Future<String?> endTimeOf(int recordId) async {
    final rows = await db.getTimelineForTask(taskId);
    return rows.singleWhere((r) => r.id == recordId).endTime;
  }

  testWidgets(
      'switching databases flushes the editor before finalizing tracking '
      'and clears the selection', (tester) async {
    final (container, ref) = await pumpHost(tester);
    final recordId = await startTracking(container);
    container.read(selectedTaskIdProvider.notifier).value = taskId;

    // The flush closure notes what the tracking state was when it ran: the
    // save must land in the database the record is then closed against,
    // which means the clock is still running at that point.
    int? trackingWhenFlushed;
    var flushes = 0;
    container.read(editorFlushProvider.notifier).value = () async {
      flushes++;
      trackingWhenFlushed = container.read(activeTrackingTaskIdProvider);
    };

    await tester.runAsync(() => AppMenuBar.prepareDatabaseSwitch(ref));

    expect(flushes, 1, reason: 'unsaved text goes to the old database');
    expect(trackingWhenFlushed, taskId,
        reason: 'the flush runs before tracking is finalized');
    expect(await endTimeOf(recordId), isNotNull,
        reason: 'the session is closed against the database it belongs to');
    expect(container.read(activeTrackingTaskIdProvider), isNull);
    expect(container.read(activeTrackingRecordIdProvider), isNull);
    expect(container.read(selectedTaskIdProvider), isNull);
  });

  testWidgets('a failing editor flush does not block the switch',
      (tester) async {
    final (container, ref) = await pumpHost(tester);
    final recordId = await startTracking(container);
    container.read(editorFlushProvider.notifier).value =
        () async => throw StateError('save failed');

    await tester.runAsync(() => AppMenuBar.prepareDatabaseSwitch(ref));

    expect(await endTimeOf(recordId), isNotNull);
    expect(container.read(activeTrackingTaskIdProvider), isNull);
  });

  group('exit prompt', () {
    Future<(ProviderContainer, WidgetRef)> pumpWithExitPrompt(
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'sync_enabled': true,
        'sync_on_exit': true,
        'sync_server_url': 'https://sync.example.com',
        'sync_username': 'alice',
        'sync_device_id': 'device-a',
      });
      final (container, ref) =
          await pumpHost(tester, syncService: _RelayWithoutChanges(db));
      // Settings load asynchronously from the (mocked) preferences.
      await tester.pumpAndSettle();
      expect(container.read(settingsProvider).syncOnExit, isTrue);
      return (container, ref);
    }

    testWidgets('Cancel keeps the app open with the clock still running',
        (tester) async {
      final (container, ref) = await pumpWithExitPrompt(tester);
      final recordId = await startTracking(container);

      // Nothing else is pending, so the running session alone is what asks
      // the question — finalizing it is a change the sync would carry.
      bool? proceed;
      AppMenuBar.runExitSequence(ref).then((value) => proceed = value);
      await tester.pumpAndSettle();
      expect(find.text('Unsynced changes'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(proceed, isFalse);
      expect(container.read(activeTrackingTaskIdProvider), taskId,
          reason: 'the user said not to close; the clock they left running '
              'must still be running');
      expect(container.read(activeTrackingRecordIdProvider), recordId);
      expect(await endTimeOf(recordId), isNull,
          reason: 'the record stays open-ended');
    });

    testWidgets("Don't sync finalizes the session and closes",
        (tester) async {
      final (container, ref) = await pumpWithExitPrompt(tester);
      final recordId = await startTracking(container);

      bool? proceed;
      AppMenuBar.runExitSequence(ref).then((value) => proceed = value);
      await tester.pumpAndSettle();
      expect(find.text('Unsynced changes'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, "Don't sync"));
      await tester.pumpAndSettle();

      expect(proceed, isTrue);
      expect(container.read(activeTrackingTaskIdProvider), isNull);
      expect(await endTimeOf(recordId), isNotNull);
    });
  });
}

/// A relay-backed service with nothing of its own to push, so only the
/// running tracking session can raise the exit prompt.
class _RelayWithoutChanges extends SyncService {
  _RelayWithoutChanges(NooDatabase db)
      : super(
          db: db,
          config: const SyncConfig(
            enabled: true,
            serverUrl: 'https://sync.example.com',
            username: 'alice',
            deviceId: 'device-a',
          ),
          crypto: SyncCrypto(),
          historyService: HistoryService(db),
          databasePassword: 'pw',
        );

  @override
  bool get hasRelay => true;

  @override
  Future<bool> hasPendingLocalChanges() async => false;
}
