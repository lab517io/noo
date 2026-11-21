import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/history_service.dart';
import 'package:noo/data/services/lan_sync_coordinator.dart';
import 'package:noo/data/services/sync_crypto.dart';
import 'package:noo/data/services/sync_journal.dart';
import 'package:noo/data/services/sync_service.dart';
import 'package:noo/domain/entities/sync_config.dart';
import 'package:noo/presentation/providers/sync_provider.dart';
import 'package:noo/presentation/widgets/dialogs/p2p_sync_dialog.dart';

/// A coordinator that reports [peers] and opens no sockets: the dialog is
/// what is under test, not discovery.
class _StubCoordinator extends LanSyncCoordinator {
  _StubCoordinator(this.peers, NooDatabase db, SyncCrypto crypto)
      : super(
          db: db,
          crypto: crypto,
          syncService: SyncService(
            db: db,
            config: const SyncConfig(enabled: true, deviceId: 'device-a'),
            crypto: crypto,
            historyService: HistoryService(db),
          ),
          deviceId: 'device-a',
        );

  final List<LanPeerStatus> peers;

  @override
  Stream<List<LanPeerStatus>> get statuses => Stream.value(peers);

  @override
  Future<void> startSession({bool discover = true}) async {}

  @override
  Future<void> stopSession() async {}
}

void main() {
  late NooDatabase db;

  setUp(() => db = NooDatabase.memory());
  tearDown(() => db.close());

  SyncEntityChange node(String title, SyncPacketRoute route) =>
      SyncEntityChange(
        entityType: 'task',
        kind: SyncEntityChangeKind.created,
        label: 'Node "$title"',
        worldId: 'wid-$title',
        fields: const [
          SyncFieldTrace(field: 'title', decision: SyncLogKind.created),
        ],
        packets: [
          SyncPacketTrace(
            originDeviceId: 'device-b',
            counter: 3,
            route: route,
            peerDeviceId: 'device-b',
            originName: 'Phone',
            peerName: 'Phone',
          ),
        ],
      );

  testWidgets('a peer lists what came and went, each row opening', (
    tester,
  ) async {
    final coordinator = _StubCoordinator(
      [
        LanPeerStatus(
          deviceId: 'device-b',
          deviceName: 'Phone',
          state: LanPeerState.synced,
          changesApplied: 1,
          received: [node('From B', SyncPacketRoute.peer)],
          sent: [node('From A', SyncPacketRoute.served)],
          logRunId: 5,
        ),
      ],
      db,
      SyncCrypto(),
    );
    final container = ProviderContainer(overrides: [
      lanSyncCoordinatorProvider.overrideWithValue(coordinator),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => showP2pSyncDialog(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Synced — 1 change received'), findsOneWidget);
    expect(find.text('Received from Phone (1)'), findsOneWidget);
    expect(find.text('Sent to Phone (1)'), findsOneWidget);
    expect(find.textContaining('Node "From B"'), findsNothing);

    await tester.tap(find.text('Received from Phone (1)'));
    await tester.pump();
    expect(find.textContaining('Node "From B"'), findsOneWidget);

    await tester.tap(find.textContaining('Node "From B"'));
    await tester.pump();
    expect(find.text('Directly from Phone over the local network.'),
        findsOneWidget);
    expect(find.text('Show in Sync Log'), findsOneWidget);

    await tester.ensureVisible(find.text('Sent to Phone (1)'));
    await tester.tap(find.text('Sent to Phone (1)'));
    await tester.pump();
    await tester.ensureVisible(find.textContaining('Node "From A"'));
    await tester.tap(find.textContaining('Node "From A"'));
    await tester.pump();
    expect(find.text('Pulled by Phone over the local network.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
