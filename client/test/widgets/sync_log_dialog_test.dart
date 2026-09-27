import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/sync_journal.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/widgets/dialogs/sync_log_dialog.dart';

void main() {
  late NooDatabase db;

  setUp(() => db = NooDatabase.memory());
  tearDown(() => db.close());

  /// Two recorded runs: a clean relay sync, then a LAN
  /// exchange with a tie on a named task.
  Future<String> seed() async {
    final wid = WorldId.create().value;
    await db.createTask(worldId: wid, title: 'Groceries');
    final journal = SyncJournal(db);

    final relay = await journal.begin('relay', remote: 'relay http://x');
    relay.add(SyncLogKind.packetStored,
        direction: 'in',
        originDevice: 'device-a',
        counter: 7,
        packetHash: 'ab' * 32);
    await relay.finish();

    final lan = await journal.begin('lan', remote: 'peer device-b@10.0.0.2:4000');
    lan.add(SyncLogKind.lwwTie,
        level: SyncLogLevel.warning,
        direction: 'in',
        originDevice: 'device-b',
        counter: 3,
        entityType: 'task',
        worldId: wid,
        field: 'title',
        remoteTs: '2026-09-17T10:00:00.000000Z',
        localTs: '2026-09-17T10:00:00.000000Z',
        value: 'Shopping',
        hasValue: true,
        message: 'Same timestamp on both sides');
    await lan.finish();
    return wid;
  }

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => showSyncLogDialog(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
  }

  testWidgets('lists runs and shows the newest run with named entities',
      (tester) async {
    await tester.runAsync(seed);
    await open(tester);

    expect(find.text('All runs'), findsOneWidget);
    expect(find.textContaining('Server sync'), findsOneWidget);
    expect(find.textContaining('Nearby devices'), findsOneWidget);

    // Newest run is selected: the tie, under the task's current name.
    expect(find.text(SyncLogKind.lwwTie), findsOneWidget);
    expect(find.textContaining('Groceries · title'), findsOneWidget);
    expect(find.textContaining('"Shopping"'), findsOneWidget);
    expect(find.text(SyncLogKind.packetStored), findsNothing);

    // All runs: both events.
    await tester.tap(find.text('All runs'));
    await settle(tester);
    expect(find.text(SyncLogKind.packetStored), findsOneWidget);
    expect(find.text(SyncLogKind.lwwTie), findsOneWidget);

    // Warnings only.
    await tester.tap(find.text('Warnings'));
    await settle(tester);
    expect(find.text(SyncLogKind.packetStored), findsNothing);
    expect(find.text(SyncLogKind.lwwTie), findsOneWidget);
  });

  testWidgets('tapping an event expands every recorded field', (tester) async {
    final wid = (await tester.runAsync(seed))!;
    await open(tester);

    await tester.tap(find.text(SyncLogKind.lwwTie));
    await settle(tester);
    expect(find.text('World id'), findsOneWidget);
    expect(find.text(wid), findsOneWidget);
    expect(find.text('Value hash'), findsOneWidget);
    expect(find.text(SyncJournal.valueHash('Shopping')!), findsOneWidget);
  });

  testWidgets('searching by name narrows to that entity', (tester) async {
    await tester.runAsync(seed);
    await open(tester);
    await tester.tap(find.text('All runs'));
    await settle(tester);

    await tester.enterText(find.byType(TextField).first, 'grocer');
    await tester.pump(const Duration(milliseconds: 300));
    await settle(tester);
    expect(find.text(SyncLogKind.lwwTie), findsOneWidget);
    expect(find.text(SyncLogKind.packetStored), findsNothing);
  });

  testWidgets('an empty log explains itself', (tester) async {
    await open(tester);
    expect(find.textContaining('No sync has been recorded yet'), findsOneWidget);
  });
}

/// Let the dialog's database reads complete (they are real I/O, outside the
/// fake clock) and render their result.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 500));
  }
}
