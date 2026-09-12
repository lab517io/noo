import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart'
    show ProviderListenable, ProviderOrFamily;

import 'value_controller.dart';
import '../../data/services/lan_sync_coordinator.dart';
import '../../data/services/peer_discovery.dart';
import '../../data/services/sync_api_client.dart';
import '../../data/services/sync_crypto.dart';
import '../../data/services/sync_service.dart';
import '../../data/services/trusted_peers.dart';
import '../../domain/entities/sync_config.dart';
import '../widgets/dialogs/peer_sync_request_dialog.dart';
import 'providers.dart';
import 'settings_provider.dart';

/// Provider for sync configuration from settings
final syncConfigProvider = Provider<SyncConfig>((ref) {
  final settings = ref.watch(settingsProvider);

  return SyncConfig(
    enabled: settings.syncEnabled,
    serverUrl: settings.syncServerUrl,
    username: settings.syncUsername,
    password: settings.syncPassword,
    deviceId: settings.syncDeviceId,
    deviceName: settings.syncDeviceName,
    autoSyncIntervalMinutes: settings.syncAutoInterval,
  );
});

/// Provider for the sync crypto service
final syncCryptoProvider = Provider<SyncCrypto>((ref) {
  return SyncCrypto();
});

/// The relay client, or null when no server is configured.
///
/// Null is an ordinary state, not a broken one: a device that syncs only with
/// LAN peers never has a relay. Nothing below may treat null here as "sync is
/// unavailable" — only the relay path is.
final syncApiClientProvider = Provider<SyncApiClient?>((ref) {
  final config = ref.watch(syncConfigProvider);
  if (!config.isRelayConfigured) return null;
  return SyncApiClient(config: config);
});

/// Provider for the sync service.
///
/// Requires only the workspace identity ([SyncConfig.isIdentityConfigured]) —
/// a workspace name and a device id. The relay client is passed when there is
/// one, and its absence leaves LAN sync fully functional.
final syncServiceProvider = Provider<SyncService?>((ref) {
  final db = ref.watch(databaseProvider);
  final config = ref.watch(syncConfigProvider);
  final apiClient = ref.watch(syncApiClientProvider);
  final crypto = ref.watch(syncCryptoProvider);
  final historyService = ref.watch(historyServiceProvider);
  final dbManager = ref.watch(databaseManagerProvider);

  if (db == null || historyService == null) return null;
  if (!config.isIdentityConfigured) return null;

  return SyncService(
    db: db,
    config: config,
    apiClient: apiClient,
    crypto: crypto,
    historyService: historyService,
    // The sync key is derived from the database password (zero-knowledge
    // design): only devices sharing the DB password can decrypt blobs.
    databasePassword: dbManager.currentPassword,
  );
});

/// Drives interval-based auto-sync (Preferences → Sync, 0 = manual only).
///
/// Each tick runs through the same [_runSync] path as a manual sync rather
/// than calling [SyncService.performSync] directly, so a background run also
/// updates the toolbar status indicator and — critically — refreshes the task
/// tree and open editor with remotely applied data. A raw performSync would
/// leave a stale editor free to overwrite freshly pulled changes on its next
/// auto-save. Sharing the path also shares its re-entrancy guard, so a tick
/// and a manual F5 can no longer race each other into a spurious
/// "Sync already in progress" failure.
///
/// The timer is cancelled and recreated whenever the config or database
/// changes. Lazily initialized: the main screen must `watch` it.
final autoSyncSchedulerProvider = Provider<void>((ref) {
  final config = ref.watch(syncConfigProvider);
  final service = ref.watch(syncServiceProvider);
  // Relay-only: a timer without a server would tick into a guaranteed
  // failure. LAN exchanges stay user-initiated (or peer-initiated) by design.
  if (service == null || !service.hasRelay) return;
  if (config.autoSyncIntervalMinutes <= 0) return;

  final timer = Timer.periodic(
    Duration(minutes: config.autoSyncIntervalMinutes),
    (_) => _runSync(read: ref.read, invalidate: ref.invalidate),
  );
  ref.onDispose(timer.cancel);
});

/// Owns the LAN peer sync machinery (docs/P2P_SYNC.md §9–10): the embedded
/// peer server and UDP discovery. Started whenever sync is configured and a
/// database is open; torn down (and restarted) when either changes.
///
/// Discovery running does *not* mean data moves: LAN exchanges only happen
/// when the user asks for one ([runLanSync]) or when a peer relays a user's
/// request from the other side. Independent of the relay auto-sync timer —
/// both paths feed the same packet store and deduplicate by design.
final lanSyncCoordinatorProvider = Provider<LanSyncCoordinator?>((ref) {
  final db = ref.watch(databaseProvider);
  final config = ref.watch(syncConfigProvider);
  final service = ref.watch(syncServiceProvider);
  final crypto = ref.watch(syncCryptoProvider);

  if (db == null || service == null || !config.isIdentityConfigured) {
    return null;
  }

  final coordinator = LanSyncCoordinator(
    db: db,
    crypto: crypto,
    syncService: service,
    deviceId: config.deviceId!,
    deviceName: config.deviceName,
    // Every peer-initiated sync is confirmed by the person holding this
    // device, except for devices they ticked "always allow" for, and the
    // return leg of a sync started here — which the coordinator recognises
    // and does not ask about twice.
    confirmIncomingSync: peerSyncConfirmation(ref.read(trustedPeersProvider)!),
  );
  // Fire-and-forget: binding sockets is async; failures (e.g. no network)
  // leave the coordinator idle until the provider is rebuilt.
  coordinator.start().catchError((_) {});
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

/// Devices this database has been told to accept sync requests from without
/// asking. Null until a database is open.
final trustedPeersProvider = Provider<TrustedPeers?>((ref) {
  final db = ref.watch(databaseProvider);
  return db == null ? null : TrustedPeers(db);
});

/// The trusted device list for Preferences → Sync, as id → last announced
/// name. Invalidate after trusting or revoking to refresh it.
final trustedPeerListProvider = FutureProvider<Map<String, String>>((ref) async {
  final trusted = ref.watch(trustedPeersProvider);
  return trusted == null ? const {} : trusted.all();
});

/// Devices of this account currently visible on the LAN. Empty while sync is
/// unconfigured or nothing has answered discovery.
final lanPeersProvider = StreamProvider<List<LanPeer>>((ref) {
  final coordinator = ref.watch(lanSyncCoordinatorProvider);
  if (coordinator == null) return Stream.value(const <LanPeer>[]);
  return coordinator.peers;
});

/// True while a user-initiated LAN sync is running, for the peer indicator's
/// spinner.
final lanSyncBusyProvider = valueProvider<bool>(false);

/// Exchange with every visible LAN peer, at the user's request, and report
/// what happened. Each peer is pulled from and then asked to pull back, so one
/// press converges both devices.
///
/// The tree/editor refresh is not done here — [lanSyncListenerProvider] does
/// it off the coordinator's applied stream, which also covers the exchanges a
/// peer initiates.
Future<LanSyncOutcome> runLanSync(WidgetRef ref) async {
  final coordinator = ref.read(lanSyncCoordinatorProvider);
  if (coordinator == null) return const LanSyncOutcome.unavailable();

  final busy = ref.read(lanSyncBusyProvider.notifier);
  busy.value = true;
  try {
    return await coordinator.syncNow();
  } finally {
    busy.value = false;
  }
}

/// Refreshes the task tree / editor / timeline when a LAN peer exchange
/// applies remote changes — the LAN analogue of the post-sync refresh in
/// [_runSync]. Lazily initialized: the main screen must `watch` it.
final lanSyncListenerProvider = Provider<void>((ref) {
  final coordinator = ref.watch(lanSyncCoordinatorProvider);
  if (coordinator == null) return;

  final sub = coordinator.onApplied.listen((_) {
    ref.read(lastSyncTimeProvider.notifier).value = DateTime.now();
    // Refresh views with remotely applied data so a stale editor doesn't
    // overwrite freshly pulled changes on the next auto-save.
    ref.read(taskTreeControllerProvider)?.loadTree();
    ref.read(timelineRefreshProvider.notifier).value++;
    ref.invalidate(taskByIdProvider);
  });
  ref.onDispose(sub.cancel);
});

/// Current sync status
final syncStatusProvider = valueProvider<SyncStatus>(SyncStatus.disabled);

/// Keeps [syncStatusProvider] honest as the user edits: after a sync the
/// indicator shows "Synced" (idle), but any subsequent local change must flip
/// it to "Pending changes". This watches the local history tables and
/// re-evaluates [SyncService.hasPendingLocalChanges] on every edit.
///
/// It never overrides a transient/terminal run state — while a sync is in
/// flight (syncing) or after it failed (error) the status is left alone; only
/// the idle ↔ pendingChanges transition is managed here. Lazily initialized,
/// so a consumer (the main screen) must `watch` it to activate the listener.
final syncPendingWatcherProvider = Provider<void>((ref) {
  final service = ref.watch(syncServiceProvider);
  final config = ref.watch(syncConfigProvider);
  final statusNotifier = ref.read(syncStatusProvider.notifier);

  // Sync off or not configured: reflect that and do nothing further. The
  // write is deferred because this provider initializes lazily inside the
  // main screen's build (via watch), and Riverpod forbids modifying another
  // provider during initialization. refresh() below needs no such guard —
  // its writes happen after an await, past initialization.
  if (service == null || !config.enabled) {
    Future.microtask(() => statusNotifier.value = SyncStatus.disabled);
    return;
  }

  Future<void> refresh() async {
    final current = statusNotifier.value;
    // Don't stomp on an in-flight sync or a failure state.
    if (current == SyncStatus.syncing || current == SyncStatus.error) return;
    final pending = await service.hasPendingLocalChanges();
    // A local check can prove we're dirty (pending changes) but never that
    // we're in sync with the server — nothing has contacted it yet. So the
    // clean case stays "unknown" (grey) until a successful performSync flips
    // us to idle (green); we never manufacture a green "Synced" from a
    // local-only inspection. Once earned, idle is preserved while clean.
    final SyncStatus next;
    if (pending) {
      next = SyncStatus.pendingChanges;
    } else {
      next = current == SyncStatus.idle ? SyncStatus.idle : SyncStatus.unknown;
    }
    if (statusNotifier.value == current) statusNotifier.value = next;
  }

  // Seed the status from the current pending state, then track edits.
  refresh();
  final sub = service.watchLocalChanges().listen((_) => refresh());
  ref.onDispose(sub.cancel);
});

/// Last successful sync time
final lastSyncTimeProvider = valueProvider<DateTime?>(null);

/// Number of pending local changes
final pendingChangesCountProvider = Provider<int>((ref) => 0);

/// UI-facing snapshot of the current/last sync run, driven by
/// [SyncService.performSync]'s progress callback and rendered by the detailed
/// sync progress dialog.
class SyncProgressReport {
  /// Whether a sync is currently in flight.
  final bool running;

  /// Current lifecycle state of each stage (defaults to pending).
  final Map<SyncStage, SyncStageState> stageStates;

  /// Short human-readable note per stage (e.g. "3 changes pushed").
  final Map<SyncStage, String> stageDetails;

  /// Terminal result once the run finishes (null while running).
  final SyncResult? result;

  /// Error message when a stage failed.
  final String? errorMessage;

  const SyncProgressReport({
    required this.running,
    required this.stageStates,
    required this.stageDetails,
    this.result,
    this.errorMessage,
  });

  factory SyncProgressReport.initial() => const SyncProgressReport(
        running: false,
        stageStates: {},
        stageDetails: {},
      );

  SyncStageState stateOf(SyncStage stage) =>
      stageStates[stage] ?? SyncStageState.pending;

  String? detailOf(SyncStage stage) => stageDetails[stage];

  bool get succeeded => result?.success ?? false;
  bool get failed => result != null && !result!.success;

  SyncProgressReport copyWith({
    bool? running,
    Map<SyncStage, SyncStageState>? stageStates,
    Map<SyncStage, String>? stageDetails,
    SyncResult? result,
    String? errorMessage,
  }) {
    return SyncProgressReport(
      running: running ?? this.running,
      stageStates: stageStates ?? this.stageStates,
      stageDetails: stageDetails ?? this.stageDetails,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Holds the live [SyncProgressReport] for the detailed progress view.
class SyncProgressController extends Notifier<SyncProgressReport> {
  @override
  SyncProgressReport build() => SyncProgressReport.initial();

  /// Reset to a fresh run with every stage pending.
  void start() {
    state = SyncProgressReport(
      running: true,
      stageStates: {
        for (final s in SyncStage.values) s: SyncStageState.pending,
      },
      stageDetails: const {},
    );
  }

  /// Apply one progress update from the sync service.
  void update(SyncProgress progress) {
    final states = Map<SyncStage, SyncStageState>.of(state.stageStates);
    final details = Map<SyncStage, String>.of(state.stageDetails);

    states[progress.stage] = progress.state;
    if (progress.detail != null) details[progress.stage] = progress.detail!;

    // Defensive: when a stage becomes active or done, make sure earlier stages
    // are not left dangling in pending/active — they must have completed.
    if (progress.state == SyncStageState.active ||
        progress.state == SyncStageState.done) {
      for (final s in SyncStage.values) {
        if (s.index < progress.stage.index) {
          final cur = states[s] ?? SyncStageState.pending;
          if (cur == SyncStageState.pending || cur == SyncStageState.active) {
            states[s] = SyncStageState.done;
          }
        }
      }
    }

    state = state.copyWith(
      stageStates: states,
      stageDetails: details,
      errorMessage: progress.error ?? state.errorMessage,
    );
  }

  /// Mark the run finished with its terminal [result].
  void finish(SyncResult result) {
    state = state.copyWith(
      running: false,
      result: result,
      errorMessage: result.error ?? state.errorMessage,
    );
  }
}

final syncProgressProvider =
    NotifierProvider<SyncProgressController, SyncProgressReport>(
  SyncProgressController.new,
);

/// Run a full sync while feeding the [syncProgressProvider] so the detailed
/// progress dialog can render stages live. Also keeps [syncStatusProvider] (the
/// toolbar indicator) and, on success, the task tree / editor / timeline in
/// sync. Safe to call from the menu action and from the dialog's Retry button.
///
/// Uses only [ref] (no BuildContext), so it is unaffected by the dialog being
/// dismissed mid-run.
Future<void> runSyncWithProgress(WidgetRef ref) =>
    _runSync(read: ref.read, invalidate: ref.invalidate);

/// Shared implementation behind [runSyncWithProgress] and the auto-sync timer
/// in [autoSyncSchedulerProvider]. Takes `read`/`invalidate` tear-offs because
/// the two callers hold different ref types (WidgetRef vs Ref) with no common
/// supertype.
Future<void> _runSync({
  required T Function<T>(ProviderListenable<T> provider) read,
  required void Function(ProviderOrFamily provider) invalidate,
}) async {
  final syncService = read(syncServiceProvider);
  final statusNotifier = read(syncStatusProvider.notifier);
  final progress = read(syncProgressProvider.notifier);

  if (syncService == null || !syncService.hasRelay) {
    progress.start();
    progress.finish(
      SyncResult(
        success: false,
        error: syncService == null
            ? 'Sync is not configured. Open Sync Settings first.'
            : 'No sync server is configured. Use "Sync with Nearby Devices" '
                'for local sync, or add a server in Preferences → Sync.',
      ),
    );
    statusNotifier.value = SyncStatus.error;
    return;
  }

  // Guard against overlapping runs (auto-sync tick, double trigger).
  if (statusNotifier.value == SyncStatus.syncing) return;

  // Flush any unsaved, still-debounced editor content so text typed right
  // before this run (e.g. via F5) is included rather than left behind the
  // auto-save timer. A flush failure must not abort the sync — the edit simply
  // stays pending locally.
  final flushEditor = read(editorFlushProvider);
  if (flushEditor != null) {
    try {
      await flushEditor();
    } catch (_) {}
  }

  // Capture every ref-derived object up front. These notifiers/controllers are
  // owned by the ProviderContainer, so they stay valid even if the caller's ref
  // is a progress dialog that gets dismissed mid-run — the completion path below
  // must not touch `read` after the await (except the guarded invalidate).
  final lastSync = read(lastSyncTimeProvider.notifier);
  final treeController = read(taskTreeControllerProvider);
  final timelineRefresh = read(timelineRefreshProvider.notifier);

  statusNotifier.value = SyncStatus.syncing;
  progress.start();

  final result = await syncService.performSync(onProgress: progress.update);

  // On success, reflect any edits made while the sync was in flight: those sit
  // beyond the advanced watermark, so the indicator should stay "pending"
  // rather than falsely show "Synced".
  if (result.success) {
    statusNotifier.value = await syncService.hasPendingLocalChanges()
        ? SyncStatus.pendingChanges
        : SyncStatus.idle;
  } else {
    statusNotifier.value = SyncStatus.error;
  }
  progress.finish(result);

  if (result.success) {
    lastSync.value = DateTime.now();
    // Refresh views with remotely applied data so a stale editor doesn't
    // overwrite freshly pulled changes on the next auto-save.
    treeController?.loadTree();
    timelineRefresh.value++;
    try {
      invalidate(taskByIdProvider);
    } catch (_) {
      // The caller's ref was disposed (progress dialog dismissed mid-run). The
      // tree reload above covers the visible tree; an open editor picks up the
      // change on its next rebuild.
    }
  }
}
