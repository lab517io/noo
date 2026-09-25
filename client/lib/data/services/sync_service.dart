import 'dart:async';
import 'dart:convert';
import 'dart:io' show HttpStatus, Platform;
import 'dart:typed_data';

import 'package:drift/drift.dart' show TableUpdateQuery, Variable;
import 'package:uuid/uuid.dart';

import '../../domain/entities/history_entry.dart';
import '../../domain/entities/sync_config.dart';
import '../../domain/entities/sync_packet.dart';
import '../../domain/entities/task.dart' show TaskFlags;
import '../../domain/entities/world_id.dart';
import '../database/database.dart';
import '../services/history_service.dart';
import 'sync_api_client.dart';
import 'sync_change_packager.dart';
import 'sync_crypto.dart';
import 'sync_journal.dart';

/// Sync status for UI display
enum SyncStatus {
  disabled,

  /// Sync is configured, but no sync has been verified against the server yet
  /// this session. A local-only check can prove there are pending changes, but
  /// it can never prove we are in sync — only a successful [performSync] can.
  /// This is the honest seed state at startup instead of a green "Synced".
  unknown,
  idle,
  syncing,
  error,
  pendingChanges,
}

/// Ordered stages of a full sync cycle, surfaced to the detailed progress view.
/// The order here is the order they execute (and the order they're displayed).
enum SyncStage {
  preparing, // derive the encryption key from the database password
  authenticating, // sign in to / validate credentials against the relay server
  pushing, // package local changes into the packet store and upload to relay
  applying, // download remote packets and merge them locally
}

/// Lifecycle state of a single [SyncStage].
enum SyncStageState { pending, active, done, skipped, failed }

/// A single progress update emitted during [SyncService.performSync].
///
/// [detail] is a short human-readable note for the stage (e.g. "3 pushed").
/// [error] is set only when [state] is [SyncStageState.failed].
class SyncProgress {
  final SyncStage stage;
  final SyncStageState state;
  final String? detail;
  final String? error;

  /// How far through the stage the run is, 0..1, when that is known (the
  /// apply stage). Null for stages that only report a status.
  final double? fraction;

  const SyncProgress(
    this.stage,
    this.state, {
    this.detail,
    this.error,
    this.fraction,
  });
}

/// One entity with local edits that have not been pushed yet, as shown in the
/// sync indicator's hover preview. All the field changes made to that entity
/// since the last push collapse into a single entry.
class PendingChange {
  final HistoryEntityType entityType;
  final int entityId;

  /// Task title / attachment file name / owning task of a time entry.
  final String label;

  /// Distinct field names touched since the last push ('title', 'content'...).
  final List<String> fields;

  /// Timestamp of the most recent change to this entity.
  final DateTime changedAt;

  const PendingChange({
    required this.entityType,
    required this.entityId,
    required this.label,
    required this.fields,
    required this.changedAt,
  });
}

/// Result of [SyncService.pendingLocalChanges]: a capped, newest-first list of
/// what is waiting to be synced, plus the totals it was cut from.
class PendingChanges {
  /// Described entities, newest change first — at most the requested limit.
  final List<PendingChange> items;

  /// How many entities have pending changes in total (≥ [items].length).
  final int totalEntities;

  /// How many individual field changes are pending in total.
  final int totalChanges;

  const PendingChanges({
    required this.items,
    required this.totalEntities,
    required this.totalChanges,
  });

  bool get isEmpty => totalEntities == 0;

  /// Entities pending beyond the ones described in [items].
  int get hiddenEntities => totalEntities - items.length;
}

/// How a single entity changed in a sync, for the human-readable details view.
enum SyncEntityChangeKind { created, updated, removed }

/// One entity's worth of change, resolved to display-friendly text. The wire
/// format is field-level (one [SyncChange] per field); these are grouped per
/// entity so the details view shows "Node X · title → Y" rather than raw rows.
class SyncEntityChange {
  /// 'task', 'file', or 'timeline'.
  final String entityType;
  final SyncEntityChangeKind kind;

  /// Entity-qualified name, e.g. `Node "Groceries"`, `File "notes.md"`,
  /// or `Time chunk` (times live in [detail]).
  final String label;

  /// What changed, e.g. `title → "Project X"` or `09:00–10:30`.
  /// Null when the [kind] alone says it all (a plain create/remove).
  final String? detail;

  /// Where the entity sits, as node titles from the root down: a node's
  /// ancestors, or for a file or time chunk the node it belongs to and that
  /// node's ancestors. A title alone does not say *which* "Notes" changed, and
  /// after a move it does not say where the node went.
  ///
  /// Null when there is nothing to say — a top-level node, or an owner that
  /// is not on this device. Empty for a node that was moved to the top level,
  /// the one case where "nowhere" is the news.
  final List<String>? path;

  const SyncEntityChange({
    required this.entityType,
    required this.kind,
    required this.label,
    this.detail,
    this.path,
  });
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final int changesPushed;
  final int changesApplied;
  final String? error;

  /// Grouped, display-ready summaries of what was pushed to / applied from the
  /// server this cycle. Empty on failure or when nothing changed.
  final List<SyncEntityChange> pushed;
  final List<SyncEntityChange> applied;

  /// Packets that arrived but could not be read (see [SyncSkippedPacket]).
  /// Non-empty here means data was lost, not merely delayed.
  final List<SyncSkippedPacket> skippedPackets;

  /// Remote changes that arrived intact and were then discarded because the
  /// local value is at least as new (see [SyncLwwSkip]).
  final List<SyncLwwSkip> lwwSkips;

  /// The user stopped the run ([SyncService.requestCancel]). Not a failure:
  /// whatever was pushed or applied before it stopped stays, and the next run
  /// continues from there.
  final bool cancelled;

  /// Something the run completed *around* rather than through — today, the
  /// relay refusing one of this device's attachments as too large, which
  /// stops its own stream at that packet while the pull still goes through.
  /// The run is a success by the counts and a problem by this line.
  final String? warning;

  const SyncResult({
    required this.success,
    this.changesPushed = 0,
    this.changesApplied = 0,
    this.error,
    this.cancelled = false,
    this.pushed = const [],
    this.applied = const [],
    this.skippedPackets = const [],
    this.lwwSkips = const [],
    this.warning,
  });

  /// Whether this run has anything to report beyond the counts — either kind
  /// of silent loss, or a warning. All are invisible in the change counts by
  /// construction: a skipped packet and a lost conflict each apply zero
  /// changes, which reads as "already up to date".
  bool get hasDiagnostics =>
      skippedPackets.isNotEmpty || lwwSkips.isNotEmpty || warning != null;
}

/// Thrown at a safe point of a run after [SyncService.requestCancel].
class SyncCancelledException implements Exception {
  const SyncCancelledException();

  @override
  String toString() => 'Sync cancelled';
}

/// Counts the apply stage's work and reports it at most every
/// [_reportEvery], so a fast stream of tiny packets does not flood the UI
/// with rebuilds while one huge packet still moves the bar change by change.
class _ApplyMeter {
  _ApplyMeter({required this.packetsExpected, required this.report});

  /// See [SyncService._packetsToApply]; 0 when nothing is expected.
  final int packetsExpected;
  final void Function(String detail, double? fraction) report;

  static const _reportEvery = Duration(milliseconds: 100);

  final Stopwatch _clock = Stopwatch()..start();
  Duration _lastReport = Duration.zero;
  int _changes = 0;
  int _packets = 0;
  int _inPacket = 0;
  int _packetSize = 0;

  void beginPacket(int size) {
    _inPacket = 0;
    _packetSize = size;
  }

  void change() {
    _changes++;
    _inPacket++;
    _maybeReport();
  }

  void endPacket() {
    _packets++;
    _inPacket = 0;
    _packetSize = 0;
    _maybeReport();
  }

  double? get _fraction {
    if (packetsExpected <= 0) return null;
    final partial = _packetSize > 0 ? _inPacket / _packetSize : 0.0;
    return ((_packets + partial) / packetsExpected).clamp(0.0, 1.0);
  }

  void _maybeReport() {
    final now = _clock.elapsed;
    if (now - _lastReport < _reportEvery) return;
    _lastReport = now;

    final fraction = _fraction;
    final String what;
    if (packetsExpected <= 1 && _packetSize > 0) {
      // One (large) packet: its own size is the whole job.
      what = '${_count(_inPacket)} of ${_count(_packetSize)} changes';
    } else if (packetsExpected > 1) {
      final current =
          (_packets + (_packetSize > 0 ? 1 : 0)).clamp(1, packetsExpected);
      what = '${_count(_changes)} changes · packet $current of '
          '$packetsExpected';
    } else {
      what = '${_count(_changes)} changes';
    }
    report('$what${_remaining(fraction, now)}', fraction);
  }

  /// "· about 12 s left", once there is enough of a run to extrapolate from.
  static String _remaining(double? fraction, Duration elapsed) {
    if (fraction == null || fraction < 0.05 || elapsed.inSeconds < 1) {
      return '';
    }
    final left = elapsed.inMilliseconds * (1 - fraction) / fraction;
    final seconds = (left / 1000).ceil();
    if (seconds < 1) return '';
    return seconds < 90
        ? ' · about $seconds s left'
        : ' · about ${(seconds / 60).round()} min left';
  }

  /// 10000 → "10,000".
  static String _count(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}

/// A packet this device holds but could not turn into changes: it failed to
/// decrypt, to decompress/parse, or its inner identity disagreed with the
/// envelope it arrived in.
///
/// This is not a delay. The applied vector advances past such a packet
/// (`_ingestPacket` accepts it either way), so its changes are gone for this
/// device and no later sync re-fetches them — which is exactly why it has to
/// be reported rather than counted as "already up to date".
class SyncSkippedPacket {
  final String originDeviceId;
  final int counter;

  /// Which step failed: 'decrypt', 'parse', 'identity', or 'apply'.
  final String stage;

  /// The underlying error, for the details view.
  final String detail;

  const SyncSkippedPacket({
    required this.originDeviceId,
    required this.counter,
    required this.stage,
    required this.detail,
  });

  /// The packet's identity as it appears in the store: "device:counter".
  String get id => '$originDeviceId:$counter';

  /// A decrypt failure has one overwhelmingly likely cause: the two databases
  /// do not share a password, so the derived sync key differs.
  bool get isDecryptFailure => stage == 'decrypt';

  @override
  String toString() => '$id ($stage)';
}

/// A remote change that arrived intact and was then dropped by last-writer-wins:
/// the newest local history row for that entity+field carries a timestamp at or
/// after the remote one, so nothing was written.
///
/// Reported because it is otherwise indistinguishable from "nothing arrived" —
/// and a clock that runs ahead on this device makes every remote edit lose this
/// way, silently, for as long as the skew lasts.
class SyncLwwSkip {
  /// 'task', 'file', or 'timeline'.
  final String entityType;
  final String worldId;
  final String field;
  final DateTime remoteTimestamp;
  final DateTime localTimestamp;

  /// Resolved entity name, filled in after the run; null when the entity could
  /// not be resolved locally.
  final String? label;

  const SyncLwwSkip({
    required this.entityType,
    required this.worldId,
    required this.field,
    required this.remoteTimestamp,
    required this.localTimestamp,
    this.label,
  });

  SyncLwwSkip withLabel(String? value) => SyncLwwSkip(
        entityType: entityType,
        worldId: worldId,
        field: field,
        remoteTimestamp: remoteTimestamp,
        localTimestamp: localTimestamp,
        label: value,
      );

  /// How far the local value's timestamp is ahead of the remote one. Zero is
  /// the exact tie, where both devices skip each other and stay diverged.
  Duration get localAheadBy => localTimestamp.difference(remoteTimestamp);
}

/// Outcome of [SyncService.compactRelay]: what the snapshot cost and what its
/// coverage reclaimed, on the relay and on this device
/// (docs/P2P_SYNC_COMPACTION.md).
class CompactionResult {
  final bool success;
  final String? error;

  /// Counter of the published snapshot, 0 when none was published.
  final int snapshotCounter;

  /// Field-level changes the snapshot carries — one per field of every task,
  /// file and timeline record.
  final int snapshotChanges;

  /// Encrypted size of the snapshot packet. Compaction bounds the log by the
  /// size of the state, so this is the floor it compacts down to.
  final int snapshotBytes;

  final int relayPackets;
  final int relayBytes;

  /// False when the relay stored the snapshot but ignored the coverage
  /// declaration — an older server. Nothing is lost: the snapshot is
  /// published, the local half still applies, and a newer relay prunes later.
  final bool relaySupported;

  final int localPackets;
  final int localBytes;

  /// Relay storage after the run, when it could be read.
  final RelayUsage? usage;

  const CompactionResult({
    required this.success,
    this.error,
    this.snapshotCounter = 0,
    this.snapshotChanges = 0,
    this.snapshotBytes = 0,
    this.relayPackets = 0,
    this.relayBytes = 0,
    this.relaySupported = true,
    this.localPackets = 0,
    this.localBytes = 0,
    this.usage,
  });

  const CompactionResult.failed(String message)
      : this(success: false, error: message);

  /// An empty database: nothing to snapshot, and nothing to reclaim.
  const CompactionResult.nothingToDo() : this(success: true);

  /// Whether anything was actually reclaimed.
  bool get freedAnything => relayPackets > 0 || localPackets > 0;
}

/// Thrown when a remote node holds a higher counter for this device's own
/// stream than this device does **and the overlap could not be verified** —
/// the signature of a database restored from backup re-using its old identity,
/// on a node too old to answer for content hashes or one that has pruned the
/// range. Where the overlap *can* be checked and matches, this is instead lost
/// history and sync recovers it by pulling rather than throwing
/// (docs/P2P_SYNC.md §3.3). Continuing to package would silently fork the
/// stream, so sync refuses until the device identity is reset.
class SyncForkException implements Exception {
  final int localCounter;
  final int remoteCounter;

  SyncForkException(this.localCounter, this.remoteCounter);

  @override
  String toString() =>
      'Device stream fork detected: a remote node holds packet counter '
      '$remoteCounter for this device, but this device is at $localCounter, '
      'and it cannot confirm the two agree on what came before (database '
      'restored from a backup?). Use "Reset device identity" in '
      'Preferences → Sync to resume syncing.';
}

/// Thrown when a remote node holds *different bytes* than this device does for
/// one of this device's own packet identities — the same fork as
/// [SyncForkException], caught by content rather than by counter.
///
/// The counter test only sees a device that is still behind what it published.
/// A restored database that packaged a few edits before its next sync has
/// caught its counter back up, and every packet it re-issued along the way
/// wears an identity that already belongs to different content. Comparing
/// hashes is what makes that visible — and it names the exact counter where
/// the two streams parted, which is what a recovery needs to know.
class SyncStreamDivergedException implements Exception {
  /// The lowest counter of this device's stream that differs. Everything below
  /// it is common history; this is where the fork begins.
  final int counter;

  final String localHash;
  final String remoteHash;

  /// Which node disagreed with us ('relay', 'peer <name>').
  final String sourceName;

  SyncStreamDivergedException({
    required this.counter,
    required this.localHash,
    required this.remoteHash,
    required this.sourceName,
  });

  String get _short =>
      '${localHash.substring(0, 8)} here vs ${remoteHash.substring(0, 8)} there';

  @override
  String toString() =>
      'Device stream diverged at packet counter $counter: this device and '
      '$sourceName hold different content under the same identity ($_short). '
      'This database was most likely restored from a backup and has re-used '
      'packet numbers it had already published. Use "Reset device identity" '
      'in Preferences → Sync to resume syncing; it republishes this '
      'database under a fresh identity and nothing is lost.';
}

/// What a fork recovery did (docs/P2P_SYNC.md §3.3).
class ForkRecovery {
  /// The identity this device published under until now. Its stream is not
  /// deleted — other devices hold it, and its packets stay readable — but this
  /// device never adds to it again.
  final String oldDeviceId;

  /// The identity this device publishes under from now on.
  final String newDeviceId;

  /// Divergent own packets dropped from the local store: the ones wearing an
  /// identity that belongs to different content elsewhere in the fleet.
  final int discardedPackets;

  const ForkRecovery({
    required this.oldDeviceId,
    required this.newDeviceId,
    required this.discardedPackets,
  });

  String get message =>
      'This device now syncs under a new identity. Its next sync publishes '
      'a full copy of the current database, which every other device merges '
      'normally.'
      '${discardedPackets > 0 ? ' $discardedPackets unusable packet(s) were discarded.' : ''}';
}

/// A conflict copy queued while a packet is applied: the task it duplicates
/// and, for edit-vs-edit, the losing remote field values to preserve. For
/// delete-vs-edit ([dueToRemoval]) the copy carries the local values instead.
class _PendingConflictCopy {
  final int taskId;
  String? losingTitle;
  String? losingContent;
  bool dueToRemoval = false;

  _PendingConflictCopy(this.taskId);
}

/// Outcome of applying a single remote change.
enum _ApplyOutcome {
  /// The change took effect locally.
  applied,

  /// The change was a no-op (lost LWW, unknown field, already current).
  skipped,

  /// The target entity (or its required owning task) does not exist yet —
  /// recorded in the orphan table for bounded retry.
  orphaned,
}

/// Main sync orchestrator (protocol v2, see docs/P2P_SYNC.md).
///
/// Packaging is decoupled from transmission: local edits are packaged into
/// the local packet store — identified by (device_id, counter) and encrypted —
/// and transmission is a version-vector exchange run against any node (the
/// relay here; LAN peers via [exchangeWithSource]). A relay is optional: with
/// none configured the service is LAN-only and every path except
/// [performSync] / [pushToRelay] behaves identically.
class SyncService {
  final NooDatabase _db;
  final SyncConfig _config;

  /// The relay client, or null when no relay is configured. Null is the
  /// ordinary P2P-only case, not an error: everything except [performSync] and
  /// [pushToRelay] works without it, LAN exchanges included.
  final SyncApiClient? _apiClient;
  final SyncCrypto _crypto;
  final SyncChangePackager _packager;
  final HistoryService _historyService;
  final String? _databasePassword;

  /// Where runs are recorded for the Sync Log window, or null for no log.
  final SyncJournal? _journal;

  SyncService({
    required NooDatabase db,
    required SyncConfig config,
    required SyncCrypto crypto,
    required HistoryService historyService,
    SyncApiClient? apiClient,
    String? databasePassword,
    SyncJournal? journal,
    this.autoFetchBudgetBytes = defaultAutoFetchBudgetBytes,
    this.blobChunkBytes = defaultBlobChunkBytes,
  })  : _db = db,
        _config = config,
        _apiClient = apiClient,
        _crypto = crypto,
        _packager = SyncChangePackager(db),
        _historyService = historyService,
        _databasePassword = databasePassword,
        _journal = journal;

  /// Default per-exchange attachment budget: enough for a normal day's notes
  /// and voice memos, small enough that a phone joining a large notebook is
  /// not held up downloading all of it before the sync reports done. The rest
  /// follows over the next exchanges, or on demand when opened.
  static const int defaultAutoFetchBudgetBytes = 32 * 1024 * 1024;

  /// Whether a relay is configured. False means LAN sync only — the free
  /// P2P path — and the relay-only entry points report that rather than
  /// failing on a null client.
  bool get hasRelay => _apiClient != null;

  String get _deviceId => _config.deviceId ?? '';

  // ============================================================
  // Sync log
  // ============================================================

  /// The sync-log run of the guarded operation in progress (a relay sync, a
  /// LAN exchange, a compaction), or null when none is — or no log is kept.
  SyncLogRun? _log;

  String get _relayName => 'relay ${_config.serverUrl ?? ''}'.trim();

  Future<SyncLogRun?> _beginLog(String trigger, {String? remote}) async {
    final journal = _journal;
    if (journal == null) return null;
    return journal.begin(trigger, remote: remote, deviceId: _deviceId);
  }

  /// Finish the current run and detach it.
  Future<void> _endLog(String outcome, {String? error}) async {
    final log = _log;
    _log = null;
    await log?.finish(outcome: outcome, error: error);
  }

  /// The exchange's starting point: what each side holds, and what this
  /// device has applied.
  Future<void> _logExchangeStart(
      String source, Map<String, int> remoteVector) async {
    final log = _log;
    if (log == null) return;
    log.add(
      SyncLogKind.exchangeStart,
      message: 'Exchange with $source',
      detail: {
        'local_vector': await _db.getSyncVector(),
        'applied_vector': await _readAppliedVector(),
        'remote_vector': remoteVector,
      },
    );
  }

  /// Log how many attachments are still waiting for their bytes.
  Future<void> _logBlobsWaiting() async {
    final log = _log;
    if (log == null) return;
    final waiting = (await _db.missingBlobHashes()).length;
    if (waiting > 0) {
      log.add(SyncLogKind.blobsWaiting,
          message: '$waiting attachment(s) still to download');
    }
  }

  /// The decision behind the change being applied, set by the apply path and
  /// written as one event by [_applyRemoteChange].
  ({
    String kind,
    SyncLogLevel level,
    String? localTs,
    String? message,
    Map<String, Object?>? detail,
  })? _note;

  /// Record why the current change went the way it did. A more severe note
  /// replaces a milder one (a creation that then hit a cycle is a cycle).
  void _noteChange(
    String kind, {
    SyncLogLevel level = SyncLogLevel.info,
    String? localTs,
    String? message,
    Map<String, Object?>? detail,
  }) {
    final held = _note;
    if (held != null && held.level.index > level.index) return;
    _note = (
      kind: kind,
      level: level,
      localTs: localTs ?? held?.localTs,
      message: message,
      detail: detail,
    );
  }

  /// Identity of the packet being applied, for its change events.
  ({String device, int counter})? _applyingPacket;

  /// Per-packet outcome counts for the packet-applied summary.
  final Map<String, int> _packetStats = {};

  /// Whether orphans are being retried (their events say so).
  bool _retryingOrphans = false;

  /// Derive the sync key and authenticate with the server.
  /// Must run before any push or pull so that a device with no local
  /// changes can still decrypt and apply remote data.
  /// [onLogin] fires immediately before a network login is attempted. It does
  /// not fire when a cached token is still valid (login skipped), letting the
  /// caller distinguish "validated credentials" from "already signed in".
  Future<void> _prepareSync(
    SyncApiClient client, {
    void Function()? onLogin,
  }) async {
    await prepareCrypto();

    if (!client.isAuthenticated) {
      onLogin?.call();
      await client.login(platform: Platform.operatingSystem);
    }
  }

  /// Derive the sync/peer keys from the database password. Public because the
  /// LAN peer machinery (server, discovery) needs the keys without a relay
  /// login.
  Future<void> prepareCrypto() async {
    final username = _config.username;
    final dbPassword = _databasePassword;
    if (dbPassword == null || dbPassword.isEmpty) {
      throw StateError(
        'Database password is not available; cannot derive the sync key. '
        'Sync requires a password-protected database.',
      );
    }
    if (username == null || username.isEmpty) {
      throw StateError('Sync username is not configured');
    }
    // Re-derive every cycle: cheap, and picks up password/username changes.
    await _crypto.deriveKey(password: dbPassword, username: username);
  }

  bool _syncInProgress = false;

  /// Set by [requestCancel]; checked at the run's safe points.
  bool _cancelRequested = false;

  /// Ask the sync in progress to stop at its next safe point: between
  /// packets, pages and attachments, never inside one. A request already on
  /// the wire is waited for, so the stop is not instant. Everything done by
  /// then is kept — every step persists its own progress (the applied vector
  /// per packet, blob-fetch checkpoints) — so nothing is rolled back and the
  /// next run resumes where this one stopped. No-op when nothing is running.
  void requestCancel() {
    if (_syncInProgress) _cancelRequested = true;
  }

  void _throwIfCancelled() {
    if (_cancelRequested) throw const SyncCancelledException();
  }

  /// How long the apply loops may hold the isolate before letting it draw a
  /// frame. The database runs on the UI isolate and completes synchronously,
  /// so without these turns a 10,000-change packet froze the window — no
  /// frames, no input, no Cancel — for the whole apply.
  static const _kBusySliceMs = 12;

  final Stopwatch _busyClock = Stopwatch()..start();

  /// Give the event loop a turn once this run has been busy for
  /// [_kBusySliceMs]. A zero-length timer is enough: it goes to the back of
  /// the event queue, behind any pending frame and input.
  Future<void> _yieldIfBusy() async {
    if (_busyClock.elapsedMilliseconds < _kBusySliceMs) return;
    await Future<void>.delayed(Duration.zero);
    _busyClock.reset();
  }

  /// Progress of the apply stage while a relay run is in it; null otherwise.
  _ApplyMeter? _meter;

  /// Packets still to apply at the start of the apply stage: those the relay
  /// holds beyond this device's store, plus stored ones not yet applied. An
  /// estimate — a pruned stream starts at its snapshot rather than at 1 — so
  /// the bar may finish a little short; it is never shown past the end.
  Future<int> _packetsToApply(Map<String, int> relayVector) async {
    final store = await _db.getSyncVector();
    final applied = await _readAppliedVector();
    var total = 0;
    for (final device in {...relayVector.keys, ...store.keys}) {
      if (device == _deviceId) continue;
      final held = store[device] ?? 0;
      final remote = (relayVector[device] ?? 0) - held;
      final backlog = held - (applied[device] ?? 0);
      total += (remote > 0 ? remote : 0) + (backlog > 0 ? backlog : 0);
    }
    return total;
  }

  /// Perform a full sync cycle against the relay: package local changes, push
  /// missing packets, then pull and apply remote packets.
  /// Reentrant calls (overlapping auto-sync tick, LAN exchange, or double
  /// manual trigger) are rejected instead of racing the same store and vector.
  Future<SyncResult> performSync({void Function(SyncProgress)? onProgress}) async {
    final client = _apiClient;
    if (client == null) {
      // P2P-only configuration. Not a failure of this run so much as a
      // feature that is not set up; the LAN path (exchangeWithSource) is
      // unaffected and remains the way these devices converge.
      return const SyncResult(
        success: false,
        error: 'No sync server is configured. '
            'Use "Sync P2P..." for local sync, or add a server '
            'in Preferences → Sync.',
      );
    }
    if (_syncInProgress) {
      return const SyncResult(success: false, error: 'Sync already in progress');
    }
    _syncInProgress = true;
    _cancelRequested = false;
    _beginRunDiagnostics();
    _log = await _beginLog('relay', remote: _relayName);

    // Tracks the stage currently executing so the catch block can attribute a
    // failure to the right stage in the detailed progress view.
    var stage = SyncStage.preparing;
    void emit(SyncStageState state, {String? detail, String? error}) {
      onProgress?.call(SyncProgress(stage, state, detail: detail, error: error));
    }

    try {
      // Stage 1: derive the encryption key. Stage 2: sign in (only if there is
      // no valid cached token — otherwise the auth stage is marked "skipped").
      stage = SyncStage.preparing;
      emit(SyncStageState.active, detail: 'Deriving encryption key');
      await _prepareSync(client, onLogin: () {
        emit(SyncStageState.done);
        stage = SyncStage.authenticating;
        emit(SyncStageState.active, detail: 'Validating credentials');
      });
      if (stage == SyncStage.preparing) {
        // Login was skipped: the cached session token is still valid.
        emit(SyncStageState.done);
        stage = SyncStage.authenticating;
        emit(SyncStageState.skipped, detail: 'Already signed in');
      } else {
        emit(SyncStageState.done);
      }
      _throwIfCancelled();

      // Stage 3: fork-check against the relay's vector, package local changes
      // into the packet store, then upload every packet the relay lacks (own
      // and carried). The fork check must precede packaging: a restored-backup
      // device is detectable only while its own stream is still behind the
      // relay's — packaging first would close that gap with fresh (forked)
      // identities (docs/P2P_SYNC.md §3.3).
      stage = SyncStage.pushing;
      emit(SyncStageState.active, detail: 'Packaging local changes');
      final relayVector = await client.getVector();
      await _logExchangeStart(client.sourceName, relayVector);
      final catchingUp = await _checkForFork(client, relayVector);
      _throwIfCancelled();
      final pushedRaw = <SyncChange>[];
      // Behind on our own stream with a clean overlap: pull the lost packets
      // back before adding to the stream. Packaging now would issue counters
      // the fleet has already used for other content (§3.3).
      if (catchingUp) {
        emit(SyncStageState.active,
            detail: 'Recovering this device\'s own history');
      }
      final pushCount =
          catchingUp ? 0 : await packageLocalChanges(changeSink: pushedRaw);
      _throwIfCancelled();
      emit(SyncStageState.active, detail: 'Uploading to server');
      final uploadedPackets = await pushToRelay(relayVector: relayVector);
      // A refused attachment fails the stage, not the run: the pull below is
      // unaffected, and the result must stay a success for the views to be
      // refreshed with what it applied.
      final refusal = _ownStreamRefusal;
      if (refusal != null) {
        emit(SyncStageState.failed, error: refusal);
      } else {
        emit(SyncStageState.done,
            detail: pushCount == 0 && uploadedPackets == 0
                ? 'No local changes'
                : '$pushCount change${pushCount == 1 ? '' : 's'} pushed');
      }

      // Stage 4: pull + apply remote packets, then re-try orphans.
      stage = SyncStage.applying;
      emit(SyncStageState.active, detail: 'Downloading remote changes');
      _meter = _ApplyMeter(
        packetsExpected: await _packetsToApply(relayVector),
        report: (detail, fraction) => onProgress?.call(SyncProgress(
            SyncStage.applying, SyncStageState.active,
            detail: detail, fraction: fraction)),
      );
      final appliedRaw = <SyncChange>[];
      var pullCount = await applyBacklog(changeSink: appliedRaw);
      pullCount += await pullFromSource(
        client,
        changeSink: appliedRaw,
        checkFork: false, // pushToRelay already fetched and checked the vector
      );
      _meter = null;
      _throwIfCancelled();
      pullCount += await retryOrphans(changeSink: appliedRaw);
      _throwIfCancelled();
      final fetched = await _fetchMissingBlobs(client);
      if (fetched > 0) {
        emit(SyncStageState.active,
            detail: '$fetched attachment${fetched == 1 ? '' : 's'} downloaded');
      }
      // What the budget left behind is not a failure, but it should not look
      // like everything arrived either — these come on later exchanges, or
      // when opened.
      await _logBlobsWaiting();
      final waiting = (await _db.missingBlobHashes()).length;
      if (waiting > 0) {
        emit(SyncStageState.active,
            detail: '$waiting attachment${waiting == 1 ? '' : 's'} still to '
                'download');
      }
      emit(SyncStageState.done,
          detail: pullCount == 0
              ? 'Already up to date'
              : '$pullCount change${pullCount == 1 ? '' : 's'} applied');

      // Record successful sync
      await _db.insertSync(1);
      await _endLog('ok');

      // Resolve the raw field-level changes into grouped, display-ready
      // summaries for the details view. Done after both stages so entities
      // created by the pull are already present for name resolution.
      final pushed = await _summarizeChanges(pushedRaw);
      final applied = await _summarizeChanges(appliedRaw);

      return SyncResult(
        success: true,
        changesPushed: pushCount,
        changesApplied: pullCount,
        pushed: pushed,
        applied: applied,
        // What did *not* apply, and why. Both lists are normally empty; when
        // they are not, they are the difference between "nothing to bring"
        // and "something came and was dropped".
        skippedPackets: _runSkippedPackets(),
        lwwSkips: await _summarizeLwwSkips(),
        warning: refusal,
      );
    } on SyncCancelledException {
      // The stage that was running stops here; later ones never started.
      emit(SyncStageState.skipped, detail: 'Cancelled');
      _log?.add(SyncLogKind.note,
          level: SyncLogLevel.warning,
          message: 'Cancelled by the user; progress so far is kept');
      await _endLog('cancelled');
      return SyncResult(
        success: false,
        cancelled: true,
        error: 'Sync cancelled',
        skippedPackets: _runSkippedPackets(),
      );
    } catch (e) {
      // Attribute the failure to whichever stage was executing.
      emit(SyncStageState.failed, error: e.toString());
      // Record failed sync
      await _db.insertSync(0);
      _log?.add(SyncLogKind.note,
          level: SyncLogLevel.error, message: 'Sync failed: $e');
      await _endLog('failed', error: e.toString());
      // A run that failed part-way can still have dropped packets before it
      // did, and those are gone for good — report them alongside the error.
      return SyncResult(
        success: false,
        error: e.toString(),
        skippedPackets: _runSkippedPackets(),
      );
    } finally {
      _syncInProgress = false;
      _cancelRequested = false;
      _meter = null;
    }
  }

  /// Exchange with an arbitrary [PacketSource] (a LAN peer): package local
  /// edits, reconcile the apply backlog, pull whatever the source holds that
  /// we don't, and retry orphans. Pull-only and symmetric — the peer pulls
  /// from this device's embedded server on its own schedule.
  /// Returns the number of changes applied locally, or -1 when a sync was
  /// already in progress (the exchange is skipped, not queued).
  ///
  /// [trigger] names the run in the sync log: `lan` for an exchange this
  /// device's user started, `lan-return` for one a peer asked for.
  Future<int> exchangeWithSource(PacketSource source,
      {String trigger = 'lan'}) async {
    if (_syncInProgress) {
      final log = await _beginLog(trigger, remote: source.sourceName);
      log?.add(SyncLogKind.note,
          level: SyncLogLevel.warning,
          message: 'Skipped: another sync was in progress');
      await log?.finish(outcome: 'busy');
      return -1;
    }
    _syncInProgress = true;
    _cancelRequested = false;
    _beginRunDiagnostics();
    _log = await _beginLog(trigger, remote: source.sourceName);
    try {
      await prepareCrypto();
      // Fork check before packaging, for the same reason as in performSync.
      final remoteVector = await source.getVector();
      await _logExchangeStart(source.sourceName, remoteVector);
      final catchingUp = await _checkForFork(source, remoteVector);
      if (!catchingUp) await packageLocalChanges();
      var applied = await applyBacklog();
      applied += await pullFromSource(source, checkFork: false);
      applied += await retryOrphans();
      await _fetchMissingBlobs(source);
      await _logBlobsWaiting();
      await _endLog('ok');
      return applied;
    } catch (e) {
      _log?.add(SyncLogKind.note,
          level: SyncLogLevel.error, message: 'Exchange failed: $e');
      await _endLog('failed', error: e.toString());
      rethrow;
    } finally {
      _syncInProgress = false;
      _cancelRequested = false;
    }
  }

  /// How much a single exchange will pull in attachments before leaving the
  /// rest for later. A phone that syncs a notebook full of voice memos used to
  /// download every one of them before the sync was considered done; past this
  /// budget the remaining blobs wait for the next exchange, or for someone to
  /// open the attachment ([fetchAttachmentNow]).
  ///
  /// A transfer already under way is always finished rather than abandoned at
  /// the budget, so one attachment larger than the whole budget still arrives.
  final int autoFetchBudgetBytes;

  /// How much ciphertext one request asks for. Small enough that a dropped
  /// connection loses little, large enough that the per-request overhead does
  /// not dominate.
  final int blobChunkBytes;

  /// See [blobChunkBytes].
  static const int defaultBlobChunkBytes = 512 * 1024;

  /// How much may arrive between checkpoints of a partial transfer. Saving a
  /// checkpoint rewrites the prefix received so far, so this trades how much
  /// an interruption costs against how much is rewritten getting there.
  static const int _blobCheckpointBytes = 4 * 1024 * 1024;

  /// Fetch the bytes of the attachments this device holds a reference to but
  /// no content for (§3.5), from [source]. Returns how many were filled in.
  ///
  /// Runs after every exchange, against the node just exchanged with — any
  /// node may hold a blob, and the one that just sent us the reference is the
  /// likeliest. A blob the source lacks, or that fails to decrypt or verify,
  /// stays missing and is tried again on the next exchange with anyone;
  /// nothing here can fail the sync, only leave an attachment for later.
  ///
  /// Bounded by [autoFetchBudgetBytes] unless [budgetBytes] overrides it, and
  /// restricted to [only] when the caller wants one specific blob.
  Future<int> _fetchMissingBlobs(
    PacketSource source, {
    int? budgetBytes,
    String? only,
  }) async {
    final budget = budgetBytes ?? autoFetchBudgetBytes;
    var spent = 0;
    var filled = 0;

    final missing = await _db.missingBlobHashes();
    final wanted =
        only != null ? [if (missing.contains(only)) only] : missing;

    for (final id in wanted) {
      if (spent >= budget) break;
      _throwIfCancelled();
      try {
        final result = await _fetchOneBlob(source, id);
        spent += result.bytes;
        if (result.filled) {
          filled++;
          _log?.add(SyncLogKind.blobFetched,
              direction: 'in',
              packetHash: id,
              message: 'Attachment ${id.substring(0, 12)}… downloaded',
              detail: {'bytes': result.bytes, 'source': source.sourceName});
        }
      } on SyncCancelledException {
        rethrow;
      } catch (e) {
        // Left missing; the reference is intact and the bytes are elsewhere.
        // Whatever arrived before the failure stays in blob_fetches, so the
        // next attempt continues from there rather than from zero.
        _log?.add(SyncLogKind.blobFetchFailed,
            level: SyncLogLevel.warning,
            direction: 'in',
            packetHash: id,
            message: 'Attachment ${id.substring(0, 12)}… failed: $e');
      }
    }
    if (spent >= budget) {
      _log?.add(SyncLogKind.note,
          message: 'Attachment download budget reached; the rest follow later',
          detail: {'budget_bytes': budget, 'spent_bytes': spent});
    }
    await _log?.flush();
    return filled;
  }

  /// Pull one blob from [source], chunk by chunk, resuming whatever an earlier
  /// attempt left behind. Returns how many bytes came off the wire and whether
  /// the attachment is now readable.
  ///
  /// The ciphertext is only verified once it is whole: a blob is a single
  /// AES-256-GCM box, and the tag covers all of it. A join that does not
  /// decrypt therefore means the pieces did not come from one ciphertext (the
  /// serving node re-encrypted between requests, say) — the partial is thrown
  /// away so the next attempt starts clean instead of resuming into rubbish.
  Future<({int bytes, bool filled})> _fetchOneBlob(
      PacketSource source, String id,
      {bool allowResume = true}) async {
    final resumed = allowResume ? await _db.getBlobFetch(id) : null;
    // Accumulated with a builder rather than by re-concatenating: a blob
    // reassembled with `[...received, ...slice]` copies everything received so
    // far on every chunk, which is quadratic in the size of the attachment.
    final buffer = BytesBuilder(copy: false);
    if (resumed != null) buffer.add(resumed.received);
    var total = resumed?.total;
    var spent = 0;
    var unflushed = 0;

    try {
      while (total == null || buffer.length < total) {
        // A cancel mid-attachment keeps what arrived: the catch below
        // checkpoints it, and the next exchange resumes from there.
        _throwIfCancelled();
        final slice = await source.getBlobSlice(
          id,
          offset: buffer.length,
          length: blobChunkBytes,
        );
        if (slice == null) {
          // This node does not hold it. Keep what we have for one that does.
          if (unflushed > 0) {
            await _db.saveBlobFetch(id, buffer.toBytes(), total);
          }
          return (bytes: spent, filled: false);
        }
        spent += slice.bytes.length;

        if (!slice.partial) {
          // The node ignored the range: this is the whole blob, and anything
          // we had accumulated is redundant.
          buffer.clear();
          buffer.add(slice.bytes);
          total = slice.bytes.length;
          break;
        }
        if (slice.offset != buffer.length) {
          // Not the piece we asked for — do not splice it in at a guess.
          await _db.clearBlobFetch(id);
          return (bytes: spent, filled: false);
        }
        if (slice.bytes.isEmpty) break; // no progress; stop rather than spin

        buffer.add(slice.bytes);
        unflushed += slice.bytes.length;
        total = slice.total ?? total;

        // Checkpointing rewrites the whole prefix, so it happens on a byte
        // interval rather than on every chunk: an interruption costs at most
        // [_blobCheckpointBytes], and getting there does not re-save a growing
        // blob for every 512 KB that arrives.
        if (total != null &&
            buffer.length < total &&
            unflushed >= _blobCheckpointBytes) {
          await _db.saveBlobFetch(id, buffer.toBytes(), total);
          unflushed = 0;
        }
        if (slice.isComplete) break;
      }
    } catch (_) {
      // A transfer that died mid-flight still keeps its ground: whatever came
      // in since the last checkpoint is written before the failure propagates,
      // so the next attempt resumes from here rather than from zero.
      if (unflushed > 0) await _db.saveBlobFetch(id, buffer.toBytes(), total);
      rethrow;
    }

    final received = buffer.toBytes();
    try {
      final content =
          await _crypto.decrypt(received, aad: SyncCrypto.blobAad(id));
      // fillBlob re-checks the hash: an AEAD failure is caught here, but a
      // blob is named by its plaintext and that is what must match.
      final filled = await _db.fillBlob(id, content) > 0;
      await _db.clearBlobFetch(id);
      return (bytes: spent, filled: filled);
    } catch (_) {
      // The join is not a valid box. Whatever we hold is not a prefix of the
      // real ciphertext, so keeping it would poison every future attempt.
      await _db.clearBlobFetch(id);
      if (resumed == null) rethrow;
      // We had resumed into a stored prefix, and that prefix is the likeliest
      // culprit — the node re-encrypted between attempts, say. Now that it is
      // gone, one clean run from the start settles whether the blob itself is
      // bad, without making the user wait for another exchange.
      final retry = await _fetchOneBlob(source, id, allowResume: false);
      return (bytes: spent + retry.bytes, filled: retry.filled);
    }
  }

  /// Fetch attachment [attachmentId]'s bytes now, because someone is trying to
  /// open it — the on-demand counterpart to the bounded prefetch that follows
  /// an exchange. Returns whether the attachment is readable afterwards.
  ///
  /// No budget applies: this one was actually asked for. Only the relay is
  /// tried — a LAN peer is reachable during an exchange, not on a whim — so a
  /// LAN-only device answers false and the caller keeps saying "sync to fetch
  /// it", which for that setup remains the honest instruction.
  Future<bool> fetchAttachmentNow(int attachmentId) async {
    final row = await _db.getAttachmentWithContent(attachmentId);
    if (row == null) return false;
    if (row.content != null) return true;
    if (row.contentHash.isEmpty) return false;

    final client = _apiClient;
    if (client == null) return false;
    // Runs beside a sync rather than inside it, so it logs to its own run.
    final log = await _beginLog('attachment', remote: _relayName);
    try {
      await prepareCrypto();
      await _prepareSync(client);
      if (!(await _db.missingBlobHashes()).contains(row.contentHash)) {
        await log?.finish(outcome: 'failed', error: 'not a missing blob');
        return false;
      }
      final filled = await _fetchOneBlobLogged(client, row.contentHash, log);
      await log?.finish(outcome: filled ? 'ok' : 'failed');
      return filled;
    } catch (e) {
      await log?.finish(outcome: 'failed', error: e.toString());
      return false;
    }
  }

  /// One on-demand blob fetch, logged to [log] rather than to [_log] (which
  /// belongs to whatever sync may be running at the same time).
  Future<bool> _fetchOneBlobLogged(
      PacketSource source, String id, SyncLogRun? log) async {
    try {
      final result = await _fetchOneBlob(source, id);
      log?.add(
        result.filled ? SyncLogKind.blobFetched : SyncLogKind.blobFetchFailed,
        level: result.filled ? SyncLogLevel.info : SyncLogLevel.warning,
        direction: 'in',
        packetHash: id,
        message: result.filled
            ? 'Attachment ${id.substring(0, 12)}… downloaded on demand'
            : 'Attachment ${id.substring(0, 12)}… not available from '
                '${source.sourceName}',
        detail: {'bytes': result.bytes},
      );
      return result.filled;
    } catch (e) {
      log?.add(SyncLogKind.blobFetchFailed,
          level: SyncLogLevel.warning,
          direction: 'in',
          packetHash: id,
          message: 'Attachment ${id.substring(0, 12)}… failed: $e');
      return false;
    }
  }

  /// Release the bytes of soft-deleted attachments this device is still
  /// holding — the device-side counterpart of the relay's own blob collection
  /// (docs/P2P_SYNC.md §3.5). Reports what was freed, or why nothing was.
  ///
  /// Collected bytes only come back from another node, so this refuses unless
  /// everything this device has to say is already on the relay — in both the
  /// stages a local change passes through:
  ///
  ///  - **not yet packaged**: history rows above the push watermarks still
  ///    have to become a packet, and [SyncChangePackager] resolves a
  ///    `content` change from the row's *current* bytes;
  ///  - **packaged but not uploaded**: a stored packet above the relay's
  ///    vector is uploaded from local bytes ([_ensureBlobsOnRelay]).
  ///
  /// Either one would be left naming a blob this device can no longer supply,
  /// and the relay refuses such a packet — which, contiguity being what it is,
  /// stops that stream for good. Past both checks the implication runs the
  /// other way: our packets are all up there, so (the relay having refused any
  /// packet whose blobs it lacked) their blobs are all up there too, and every
  /// collected blob is refetchable for as long as those packets live.
  ///
  /// With no relay configured (LAN-only) no node carries that guarantee, so
  /// nothing is collected — a peer may be the only other holder, or may be a
  /// device that collected the same blob.
  Future<({int collected, String? blocked})> collectRemovedBlobs() async {
    final client = _apiClient;
    if (client == null) {
      return (
        collected: 0,
        blocked: 'Nearby-device sync alone cannot guarantee another device '
            'still holds a deleted attachment, so none were released.',
      );
    }
    if (_syncInProgress) {
      return (collected: 0, blocked: 'A sync is already in progress.');
    }

    const unsynced = 'This device has changes the server has not stored yet. '
        'Sync first, then compact.';
    if (!(await pendingLocalChanges(limit: 1)).isEmpty) {
      return (collected: 0, blocked: unsynced);
    }

    await prepareCrypto();
    await _prepareSync(client);
    final relayVector = await client.getVector();
    final localVector = await _db.getSyncVector();
    for (final entry in localVector.entries) {
      if (entry.value > (relayVector[entry.key] ?? 0)) {
        return (collected: 0, blocked: unsynced);
      }
    }

    final collected = await _db.collectRemovedBlobs();
    if (collected > 0) {
      final log = await _beginLog('blob-collect');
      log?.add(SyncLogKind.note,
          message: 'Released the bytes of $collected deleted attachment(s)');
      await log?.finish();
    }
    return (collected: collected, blocked: null);
  }

  /// The attachment blobs [payload] references, or an empty list when the
  /// packet cannot be read (a carried packet in a format this node does not
  /// understand still gets uploaded — its blobs are then whoever's problem
  /// can read it).
  Future<List<String>> _blobIdsIn(
      String originDeviceId, int counter, Uint8List payload) async {
    try {
      final decrypted = await _crypto.decrypt(payload,
          aad: SyncCrypto.packetAad(originDeviceId, counter));
      return SyncPacket.deserialize(_packager.decompress(decrypted)).blobIds;
    } catch (_) {
      return const [];
    }
  }

  /// Make sure the relay holds every blob in [blobIds] before a packet that
  /// references them is uploaded — the relay refuses the packet otherwise, and
  /// that refusal is what keeps "stored packet ⇒ its blobs are stored" true.
  ///
  /// Returns false when a blob cannot be put there: not on this device either
  /// (a carried packet whose attachment has not reached us yet), or refused
  /// by the relay as too large. The caller must then stop carrying that
  /// stream at this packet, since contiguity forbids skipping.
  ///
  /// [originDeviceId] is whose stream the packet belongs to. A refusal that
  /// stops *this device's own* stream is the one the user has to hear about
  /// — nothing edited here since can reach the relay — and is kept in
  /// [_ownStreamRefusal] for the run's result; a carried stream's is only
  /// logged, its origin device reports it itself.
  Future<bool> _ensureBlobsOnRelay(
    SyncApiClient client,
    List<String> blobIds, {
    required String originDeviceId,
  }) async {
    for (final id in blobIds) {
      final content = await _db.findBlobLocally(id);
      if (content == null) return false;
      final refused = _refusedBlobs[id];
      if (refused != null) {
        _noteRefusal(originDeviceId, id, refused);
        return false;
      }
      if (await client.hasBlob(id)) continue;
      final encrypted =
          await _crypto.encrypt(content, aad: SyncCrypto.blobAad(id));
      try {
        await client.putBlob(id, encrypted);
      } on SyncApiException catch (e) {
        if (e.statusCode != HttpStatus.requestEntityTooLarge) rethrow;
        final message = await _describeRefusal(id, content.length, e);
        _refusedBlobs[id] = message;
        _noteRefusal(originDeviceId, id, message);
        return false;
      }
      _log?.add(SyncLogKind.blobUploaded,
          direction: 'out',
          packetHash: id,
          message: 'Attachment ${id.substring(0, 12)}… uploaded',
          detail: {'bytes': encrypted.length});
    }
    return true;
  }

  /// Blobs the relay refused as too large this session, each with the message
  /// it was reported with. Remembered so a later run does not upload the
  /// same megabytes again just to be told again — the relay's limit will not
  /// have moved between two runs of one session.
  final Map<String, String> _refusedBlobs = {};

  /// The refusal that stopped this device's own stream this run, if any.
  String? _ownStreamRefusal;

  void _noteRefusal(String originDeviceId, String id, String message) {
    final own = originDeviceId == _deviceId;
    if (own) _ownStreamRefusal ??= message;
    _log?.add(SyncLogKind.pushBlocked,
        level: own ? SyncLogLevel.error : SyncLogLevel.warning,
        direction: 'out',
        originDevice: originDeviceId,
        packetHash: id,
        message: own
            ? message
            : 'Not uploaded: the server refuses attachment '
                '${id.substring(0, 12)}… as too large; its origin device '
                'reports this');
  }

  /// What to tell the user about a blob the relay would not take, naming the
  /// attachment the way the panel does rather than by hash.
  Future<String> _describeRefusal(
      String id, int bytes, SyncApiException e) async {
    final name = await _attachmentNameForBlob(id) ?? id.substring(0, 12);
    final limit = _relayLimitIn(e.message);
    return 'The server refused the attachment "$name" (${_describeBytes(bytes)}) '
        'as too large${limit == null ? '' : ' (its limit is ${_describeBytes(limit)})'}. '
        'Nothing this device has changed since it was attached can reach the '
        'server; nearby devices still get everything through Sync P2P.';
  }

  /// A filename carrying blob [id], preferring a live row over a deleted one.
  Future<String?> _attachmentNameForBlob(String id) async {
    final row = await _db.customSelect(
      'SELECT filename AS f FROM file WHERE content_hash = ? '
      'ORDER BY removed ASC, id DESC LIMIT 1',
      variables: [Variable.withString(id)],
    ).getSingleOrNull();
    return row?.read<String>('f');
  }

  /// The limit the relay states in its refusal ("Blob exceeds maximum size of
  /// N bytes"), when it states one.
  static int? _relayLimitIn(String message) {
    final match =
        RegExp(r'maximum size of (\d+) bytes').firstMatch(message);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  static String _describeBytes(int bytes) {
    if (bytes < 1024) return '$bytes bytes';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static const _kPushedTaskHid = 'sync_pushed_task_hid';
  static const _kPushedFileHid = 'sync_pushed_file_hid';
  static const _kPushedTimelineHid = 'sync_pushed_timeline_hid';
  static const _kRepackageNeeded = 'sync_v2_repackage_needed';
  static const _kAppliedVector = 'sync_applied_v2';

  Future<int> _readWatermark(String key) async =>
      int.tryParse(await _db.getProperty(key) ?? '0') ?? 0;

  /// The vector of packets this device has *applied* (as opposed to merely
  /// stored): {device_id → highest applied counter}, persisted as JSON.
  /// Normally it tracks the store vector exactly; a crash between storing and
  /// applying leaves it behind, and [applyBacklog] closes the gap.
  Future<Map<String, int>> _readAppliedVector() async {
    final raw = await _db.getProperty(_kAppliedVector);
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return {};
    }
  }

  Future<void> _advanceApplied(String deviceId, int counter) async {
    final vector = await _readAppliedVector();
    if ((vector[deviceId] ?? 0) >= counter) return;
    vector[deviceId] = counter;
    await _db.setProperty(_kAppliedVector, jsonEncode(vector));
  }

  /// Package pending local edits into one encrypted packet in the local
  /// packet store. Purely local — no network. Returns the number of
  /// field-level changes packaged (0 when there is nothing to package).
  ///
  /// The packet's counter is client-assigned: max own counter in the store
  /// plus one, so the own stream stays contiguous. Watermarks advance in the
  /// same transaction that stores the packet — the packet is durable locally,
  /// so a later transmission failure can neither lose nor duplicate changes.
  ///
  /// When the database is flagged for a full re-package (v1→v2 migration or
  /// fork recovery), the packet carries creation changes for the entire
  /// current state instead of a history delta (docs/P2P_SYNC.md §11.2).
  ///
  /// Serialized: the counter is `max + 1`, so two packagings in flight at once
  /// would claim the same one. That is reachable now that a LAN peer pulling
  /// from us packages our changes first (docs/P2P_SYNC.md §9.2), which can
  /// land while our own exchange is packaging. The lock is safe to hold —
  /// packaging touches only the local database and never the network.
  /// [onPacket] receives the packet that was stored, if any — how the
  /// compaction path learns the snapshot's counter and coverage.
  ///
  /// Logged to the current sync run; packaging outside one (a nearby device
  /// pulling from us) opens a `package` run of its own when it stores a packet.
  Future<int> packageLocalChanges({
    List<SyncChange>? changeSink,
    void Function(SyncPacket packet)? onPacket,
  }) {
    final completer = Completer<int>();
    final log = _log;
    _packageChain = _packageChain.then((_) async {
      try {
        completer.complete(await _packageLocalChanges(
          changeSink: changeSink,
          onPacket: onPacket,
          log: log,
        ));
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }

  Future<void> _packageChain = Future<void>.value();

  Future<int> _packageLocalChanges({
    List<SyncChange>? changeSink,
    void Function(SyncPacket packet)? onPacket,
    SyncLogRun? log,
  }) async {
    final deviceId = _deviceId;
    if (deviceId.isEmpty) throw StateError('Sync device id is not configured');

    final repackage = await _db.getProperty(_kRepackageNeeded) == '1';

    // Watermark advancement targets: the max local history row id per table
    // at packaging time (repackage subsumes all existing history).
    final taskAfter = repackage ? 0 : await _readWatermark(_kPushedTaskHid);
    final fileAfter = repackage ? 0 : await _readWatermark(_kPushedFileHid);
    final timelineAfter =
        repackage ? 0 : await _readWatermark(_kPushedTimelineHid);

    final entries = await _historyService.getLocalHistoryAfterIds(
      taskAfterId: taskAfter,
      fileAfterId: fileAfter,
      timelineAfterId: timelineAfter,
    );

    // Remember the pre-packaging watermark: a history row above it was
    // definitely never on the wire before this cycle, which is what the
    // conflict-copy check falls back on for packets that carry no vector.
    _prePackageTaskHid = taskAfter;

    final counter = await _db.maxSyncCounterFor(deviceId) + 1;
    // The applied vector at packaging time — what this device had seen when
    // these changes were made. Travels in the packet for the receivers'
    // conflict-copy check.
    final appliedVector = await _readAppliedVector();
    SyncPacket? packet;
    if (repackage) {
      final changes = await _packager.buildFullStateChanges();
      if (changes.isNotEmpty) {
        packet = SyncPacket(
          deviceId: deviceId,
          counter: counter,
          timestamp: DateTime.now().toUtc().toIso8601String(),
          changes: changes,
          vector: appliedVector,
          fullState: true,
        );
      }
    } else {
      if (entries.isEmpty) return 0;
      packet = await _packager.packageChanges(
        entries: entries,
        deviceId: deviceId,
        counter: counter,
        vector: appliedVector,
      );
    }

    if (packet == null) {
      // Nothing to send (e.g. empty database on repackage) — still clear the
      // flag so the next cycle doesn't retry a no-op.
      if (repackage) await _db.setProperty(_kRepackageNeeded, '0');
      return 0;
    }

    // Serialize → compress → encrypt with the identity-binding AAD.
    final encrypted = await _crypto.encrypt(
      _packager.compress(packet.serialize()),
      aad: SyncCrypto.packetAad(deviceId, counter),
    );

    var maxTask = taskAfter, maxFile = fileAfter, maxTimeline = timelineAfter;
    for (final e in entries) {
      final id = e.id;
      if (id == null) continue;
      switch (e.entityType) {
        case HistoryEntityType.task:
          if (id > maxTask) maxTask = id;
          break;
        case HistoryEntityType.file:
          if (id > maxFile) maxFile = id;
          break;
        case HistoryEntityType.timeline:
          if (id > maxTimeline) maxTimeline = id;
          break;
      }
    }

    await _db.transaction(() async {
      final stored = await _db.storeSyncPacket(
        originDeviceId: deviceId,
        counter: counter,
        payload: encrypted,
      );
      if (stored != SyncPacketStoreResult.stored) {
        throw StateError('Own packet slot ($deviceId, $counter) already held');
      }
      await _db.setProperty(_kPushedTaskHid, maxTask.toString());
      await _db.setProperty(_kPushedFileHid, maxFile.toString());
      await _db.setProperty(_kPushedTimelineHid, maxTimeline.toString());
      // Push log: which task-history rows this counter covers, so a remote
      // vector entry for us can later be resolved to "had they seen row X".
      await _db.insertSyncPushLog(counter: counter, taskHistoryId: maxTask);
      if (repackage) await _db.setProperty(_kRepackageNeeded, '0');
    });
    // Own packets are never re-applied — their content is already local state.
    await _advanceApplied(deviceId, counter);
    await _logPackaged(packet, encrypted, log);

    // A full re-package re-announces the whole database; listing every entity
    // in the details view (and resolving each name) would be noise, so only
    // delta packets feed the sink.
    if (!repackage) changeSink?.addAll(packet.changes);
    onPacket?.call(packet);

    return packet.changes.length;
  }

  /// Record a packet this device just packaged, and the changes it carries.
  Future<void> _logPackaged(
      SyncPacket packet, Uint8List encrypted, SyncLogRun? log) async {
    final standalone = log == null;
    log ??= await _beginLog('package');
    if (log == null) return;
    final hash = NooDatabase.syncPayloadHash(encrypted);
    log.add(
      SyncLogKind.packaged,
      direction: 'out',
      originDevice: packet.deviceId,
      counter: packet.counter,
      packetHash: hash,
      message: packet.fullState
          ? 'Packaged full-state packet #${packet.counter} '
              '(${packet.changes.length} changes)'
          : 'Packaged packet #${packet.counter} '
              '(${packet.changes.length} changes)',
      detail: {
        'changes': packet.changes.length,
        'full_state': packet.fullState,
        'bytes': encrypted.length,
        'blobs': packet.blobIds.length,
        if (packet.vector != null) 'vector': packet.vector,
      },
    );
    for (final change in packet.changes) {
      if (packet.fullState) {
        log.tally(SyncLogKind.outgoing);
        continue;
      }
      log.add(
        SyncLogKind.outgoing,
        direction: 'out',
        originDevice: packet.deviceId,
        counter: packet.counter,
        packetHash: hash,
        entityType: change.entityType,
        worldId: change.worldId,
        field: change.field,
        remoteTs: change.timestamp,
        value: change.value,
        hasValue: true,
        detail: change.isCreation ? {'creation': true} : null,
      );
    }
    if (standalone) {
      await log.finish();
    } else {
      await log.flush();
    }
  }

  /// Upload every packet the relay lacks — this device's own and any it
  /// carries for other devices (gossip). Returns the number of packets
  /// uploaded. [relayVector], when already fetched by the caller (who must
  /// then also have run the fork check), avoids a second round trip.
  Future<int> pushToRelay({Map<String, int>? relayVector}) async {
    final client = _apiClient;
    if (client == null) {
      throw StateError(
        'No sync server is configured; there is nothing to push to. '
        'Check hasRelay before calling pushToRelay.',
      );
    }
    if (relayVector == null) {
      relayVector = await client.getVector();
      await _checkForFork(client, relayVector);
    }

    final localVector = await _db.getSyncVector();
    var uploaded = 0;
    for (final entry in localVector.entries) {
      final relayHas = relayVector[entry.key] ?? 0;
      if (entry.value <= relayHas) continue;
      final packets = await _db.getSyncPacketsAbove(entry.key, relayHas);
      for (final p in packets) {
        _throwIfCancelled();
        final payload = Uint8List.fromList(p.payload);
        final blobIds = await _blobIdsIn(p.originDeviceId, p.counter, payload);
        // A carried packet whose attachment we do not hold yet cannot go up,
        // and neither can anything after it in that stream (§6.3). Its origin
        // device, or a carrier that has the bytes, will deliver it instead.
        final hash = p.payloadHash.isNotEmpty
            ? p.payloadHash
            : NooDatabase.syncPayloadHash(payload);
        if (!await _ensureBlobsOnRelay(client, blobIds,
            originDeviceId: p.originDeviceId)) {
          final refused = blobIds.any(_refusedBlobs.containsKey);
          _log?.add(SyncLogKind.pushBlocked,
              level: SyncLogLevel.warning,
              direction: 'out',
              originDevice: p.originDeviceId,
              counter: p.counter,
              packetHash: hash,
              message: refused
                  ? 'Not uploaded: the server refuses an attachment it '
                      'references; the rest of this stream waits too'
                  : 'Not uploaded: an attachment it references is not on '
                      'this device yet; the rest of this stream waits too');
          break;
        }
        final upload = await client.uploadPacket(
          originDeviceId: p.originDeviceId,
          counter: p.counter,
          payload: payload,
          blobIds: blobIds,
        );
        _log?.add(SyncLogKind.pushed,
            direction: 'out',
            originDevice: p.originDeviceId,
            counter: p.counter,
            packetHash: hash,
            message: upload.result == PacketUploadResult.alreadyHeld
                ? 'Relay already held this packet'
                : p.originDeviceId == _deviceId
                    ? 'Uploaded'
                    : 'Uploaded on behalf of another device',
            detail: {
              'bytes': payload.length,
              'blobs': blobIds.length,
              'result': upload.result.name,
            });
        uploaded++;
      }
    }
    await _log?.flush();
    return uploaded;
  }

  /// Why the relay-storage entry points do nothing in a LAN-only setup.
  static const _kCompactionUnavailable =
      'No sync server is configured. Compaction publishes a snapshot to the '
      'relay; with nearby-device sync alone there is no relay storage to '
      'reclaim.';

  /// Publish a full-state snapshot and discard everything it covers, on the
  /// relay and in this device's own packet store.
  ///
  /// The log is append-only, so storage grows without bound even when the
  /// state does not. A snapshot carries the merged result of every packet it
  /// covers, which makes those packets redundant: the relay deletes them on
  /// the strength of the coverage declaration (§4.3), and every other device
  /// drops its own copies as it applies the snapshot (§4.1, §4.4).
  ///
  /// What is lost is history below the snapshot horizon — intermediate values
  /// and who-changed-what-when — never current state. A device that has not
  /// yet learned to adopt coverage cannot accept a stream that no longer
  /// starts at 1, so every device should be updated before this is run.
  ///
  /// Ordinary sync runs first: a snapshot must be packaged from a fully
  /// applied state (§7, rule 3), or it would declare coverage of packets this
  /// device never merged.
  Future<CompactionResult> compactRelay({
    void Function(String stage)? onProgress,
  }) async {
    final client = _apiClient;
    if (client == null) {
      return const CompactionResult.failed(_kCompactionUnavailable);
    }
    if (_syncInProgress) {
      return const CompactionResult.failed('A sync is already in progress.');
    }

    onProgress?.call('Syncing before compaction');
    final sync = await performSync();
    if (!sync.success) {
      return CompactionResult.failed(
          'Compaction needs a completed sync first: ${sync.error}');
    }

    _syncInProgress = true;
    _log = await _beginLog('compaction', remote: _relayName);
    var result = const CompactionResult.failed('Compaction did not finish.');
    try {
      result = await _compact(client, onProgress);
      return result;
    } finally {
      _log?.add(
        SyncLogKind.compaction,
        level: result.success ? SyncLogLevel.info : SyncLogLevel.error,
        counter: result.snapshotCounter == 0 ? null : result.snapshotCounter,
        originDevice: result.snapshotCounter == 0 ? null : _deviceId,
        message: result.success
            ? 'Compaction: snapshot #${result.snapshotCounter}, relay freed '
                '${result.relayPackets} packet(s), this device freed '
                '${result.localPackets}'
            : 'Compaction failed: ${result.error}',
        detail: {
          'snapshot_changes': result.snapshotChanges,
          'snapshot_bytes': result.snapshotBytes,
          'relay_packets': result.relayPackets,
          'relay_bytes': result.relayBytes,
          'relay_supported': result.relaySupported,
          'local_packets': result.localPackets,
          'local_bytes': result.localBytes,
        },
      );
      await _endLog(result.success ? 'ok' : 'failed', error: result.error);
      _syncInProgress = false;
    }
  }

  Future<CompactionResult> _compact(
    SyncApiClient client,
    void Function(String stage)? onProgress,
  ) async {
    try {
      onProgress?.call('Checking this device is up to date');
      final blocker = await _compactionBlocker(client);
      if (blocker != null) return CompactionResult.failed(blocker);

      onProgress?.call('Packaging a snapshot of the whole database');
      SyncPacket? snapshot;
      await _db.setProperty(_kRepackageNeeded, '1');
      final changes = await packageLocalChanges(
        onPacket: (packet) => snapshot = packet,
      );
      final packet = snapshot;
      if (packet == null) {
        // An empty database has nothing to snapshot, and so nothing the
        // relay could be told to drop.
        return const CompactionResult.nothingToDo();
      }
      if (!packet.fullState) {
        // Something else packaged between the flag and this call — a LAN peer
        // pulling from us takes the same packaging lock — and took the
        // re-package with it. Declaring coverage for a delta packet would
        // authorise deleting state nothing else carries, so stop.
        return const CompactionResult.failed(
            'Another sync packaged first. Try compacting again.');
      }

      final rows =
          await _db.getSyncPacketsAbove(_deviceId, packet.counter - 1, limit: 1);
      if (rows.isEmpty) {
        return const CompactionResult.failed(
            'The snapshot was packaged but is not in the local store.');
      }

      // Coverage: what this device had applied when it packaged. Its own
      // stream is covered up to the packet before the snapshot — never the
      // snapshot itself, which is the one packet that must survive.
      final covers = <String, int>{...?packet.vector};
      covers[_deviceId] = packet.counter - 1;
      covers.removeWhere((_, counter) => counter < 1);

      // Everything the snapshot references must be on the relay before the
      // relay is told to prune: a pruned packet releases its blobs, and only
      // the snapshot's own declaration keeps the live ones (§3.5).
      onProgress?.call('Uploading attachments the snapshot references');
      final blobIds = packet.blobIds;
      if (!await _ensureBlobsOnRelay(client, blobIds,
          originDeviceId: _deviceId)) {
        return CompactionResult.failed(_ownStreamRefusal ??
            'This device is still missing some attachments. Sync until every '
            'attachment has downloaded, then compact.');
      }

      onProgress?.call('Uploading the snapshot');
      final upload = await client.uploadPacket(
        originDeviceId: _deviceId,
        counter: packet.counter,
        payload: Uint8List.fromList(rows.first.payload),
        snapshotCovers: covers,
        blobIds: blobIds,
      );

      onProgress?.call('Reclaiming space on this device');
      final local = await adoptSnapshotCoverage(packet);

      onProgress?.call('Reading relay storage');
      RelayUsage? usage;
      try {
        usage = await client.getUsage();
      } catch (_) {
        // Cosmetic: the compaction itself has already happened.
      }

      return CompactionResult(
        success: true,
        snapshotCounter: packet.counter,
        snapshotChanges: changes,
        snapshotBytes: rows.first.payload.length,
        relayPackets: upload.prune?.packets ?? 0,
        relayBytes: upload.prune?.bytes ?? 0,
        relaySupported: upload.prune != null,
        localPackets: local.packets,
        localBytes: local.bytes,
        usage: usage,
      );
    } on SyncApiException catch (e) {
      return CompactionResult.failed('Relay refused the snapshot: ${e.message}');
    } catch (e) {
      return CompactionResult.failed('Compaction failed: $e');
    }
  }

  /// Why this device must not snapshot right now, or null when it may.
  ///
  /// A snapshot declares coverage of everything the packager had applied, so
  /// a device whose store or relay holds packets it has not merged would
  /// authorise deleting packets that never reached it (§7, rule 3).
  Future<String?> _compactionBlocker(SyncApiClient client) async {
    if (_skippedPackets.isNotEmpty) {
      return 'This device could not read ${_skippedPackets.length} packet(s) '
          '(${skippedBlobs.take(3).join(', ')}), so its state is not the '
          'merge of everything in the log. Compacting would discard packets '
          'this device never applied.';
    }
    if (await hasPendingLocalChanges()) {
      return 'This device still has unsynced edits. Sync first, then compact.';
    }
    final applied = await _readAppliedVector();
    final behind = <String>[];
    void check(Map<String, int> vector) {
      vector.forEach((device, counter) {
        if ((applied[device] ?? 0) < counter && !behind.contains(device)) {
          behind.add(device);
        }
      });
    }

    check(await _db.getSyncVector());
    check(await client.getVector());
    if (behind.isEmpty) return null;
    return 'This device has not applied everything it holds for '
        '${behind.length} device(s). Sync again, then compact.';
  }

  /// What this account occupies on the relay, per origin device.
  Future<RelayUsage> fetchRelayUsage() async {
    final client = _apiClient;
    if (client == null) throw StateError(_kCompactionUnavailable);
    await _prepareSync(client);
    return client.getUsage();
  }

  /// What the local packet store occupies — the same log, on this device.
  Future<({int packets, int bytes})> localPacketStorage() =>
      _db.syncPacketStorage();

  /// Detect a forked own stream (docs/P2P_SYNC.md §3.3): a remote node holding
  /// a higher counter for this device than the device itself means this
  /// database regressed (restored backup). Refuse to sync rather than re-issue
  /// existing packet identities with different content.
  /// Returns whether packaging must be **skipped** this cycle.
  ///
  /// Content is checked before counters, because the content is what decides
  /// what a counter difference means. A device behind on its own stream with a
  /// byte-for-byte identical overlap has published nothing that disagrees with
  /// the fleet: it is not forked, it has *lost history* a restore rolled back,
  /// and the fleet still holds it. That heals by pulling the missing packets
  /// back — so this cycle packages nothing (packaging is precisely what would
  /// turn the recoverable gap into a real fork) and the next one resumes
  /// normally, above the recovered counters.
  Future<bool> _checkForFork(
      PacketSource source, Map<String, int> remoteVector) async {
    final own = await _db.maxSyncCounterFor(_deviceId);
    final remoteOwn = remoteVector[_deviceId] ?? 0;
    final verified =
        await _verifyOwnStream(source, own < remoteOwn ? own : remoteOwn);
    _log?.add(
      SyncLogKind.streamVerify,
      originDevice: _deviceId,
      message: verified
          ? 'Own stream matches ${source.sourceName} over the checked window'
          : 'Own stream could not be compared with ${source.sourceName}',
      detail: {'local_counter': own, 'remote_counter': remoteOwn},
    );

    if (remoteOwn > own) {
      if (verified) {
        _log?.add(SyncLogKind.forkCheck,
            level: SyncLogLevel.warning,
            originDevice: _deviceId,
            counter: remoteOwn,
            message: 'The remote holds own packets up to #$remoteOwn but this '
                'device only #$own: recovering them, packaging nothing this run');
        return true;
      }
      // Unverifiable — an older remote, or an overlap this node has pruned.
      // A lost history and a re-issued one look identical from here, so this
      // stays what it always was: a refusal.
      _log?.add(SyncLogKind.forkCheck,
          level: SyncLogLevel.error,
          originDevice: _deviceId,
          counter: remoteOwn,
          message: 'Fork: the remote holds own packets up to #$remoteOwn, this '
              'device only #$own, and the overlap cannot be verified');
      throw SyncForkException(own, remoteOwn);
    }
    return false;
  }

  /// Recover from a detected fork by taking a fresh device identity.
  ///
  /// Re-identity rather than repair, because a fork cannot be retracted: by the
  /// time it is found a LAN peer may already hold the re-issued packets, and no
  /// message takes them back. A new identity sidesteps the argument — the old
  /// stream freezes wherever each node happens to have it, and the full-state
  /// snapshot published under the new one carries this device's current values
  /// with their original edit timestamps, so ordinary LWW (§8) converges the
  /// fleet whichever version of the old packets a node holds.
  ///
  /// [divergedAtCounter], from [SyncStreamDivergedException], drops this
  /// device's packets from that counter up: those wear identities that belong
  /// to other content, and serving them on is how one device's fork becomes
  /// everybody's. Packets below it are shared history and stay. Omitted (a
  /// reset the user asked for rather than one a mismatch forced), nothing is
  /// discarded — the new identity alone is enough to stop the bleeding.
  ///
  /// [persistIdentity] stores the new id where the app reads it from
  /// ([SyncConfig.deviceId]). It runs **last**, for two reasons: persisting it
  /// rebuilds the sync configuration — and with it this service — so anything
  /// done afterwards would race a fresh instance over the same database; and
  /// every step below is idempotent, so a failed persist leaves a store that
  /// is safe as it stands (its worst case is a full-state packet published
  /// under the old identity at a fresh counter, which re-uses nothing) and
  /// that a retry completes cleanly.
  ///
  /// This service keeps its old id until it is rebuilt, which is what lets the
  /// clean-up below address the old stream correctly.
  Future<ForkRecovery> recoverFromFork({
    int? divergedAtCounter,
    required Future<void> Function(String newDeviceId) persistIdentity,
  }) async {
    if (_syncInProgress) {
      throw StateError('Cannot reset the device identity during a sync');
    }
    _syncInProgress = true;
    try {
      final newDeviceId = const Uuid().v4();
      var discarded = 0;
      if (divergedAtCounter != null && divergedAtCounter > 0) {
        discarded =
            await _db.deleteSyncPacketsFrom(_deviceId, divergedAtCounter);
        // Re-pull whatever the fleet holds under those identities: its version
        // is the one that stands, and this device's copy of it is now gone.
        await _rewindApplied(_deviceId, divergedAtCounter - 1);
      }
      // Counters restart at 1 under the new identity, so push-log rows keyed
      // by the old stream's counters would answer §8.3's causal test about
      // entirely unrelated packets.
      await _db.clearSyncPushLog();
      // Publish the whole current database under the new identity, watermarks
      // ignored — the point is to owe the fleet nothing from the old stream.
      await _db.setProperty(_kRepackageNeeded, '1');

      final log = await _beginLog('identity-reset');
      log?.add(SyncLogKind.identityReset,
          level: SyncLogLevel.warning,
          originDevice: _deviceId,
          counter: divergedAtCounter,
          message: 'Device identity reset: $_deviceId → $newDeviceId'
              '${discarded > 0 ? ', $discarded own packet(s) discarded' : ''}',
          detail: {'old_device': _deviceId, 'new_device': newDeviceId});
      await log?.finish();

      await persistIdentity(newDeviceId);

      return ForkRecovery(
        oldDeviceId: _deviceId,
        newDeviceId: newDeviceId,
        discardedPackets: discarded,
      );
    } finally {
      _syncInProgress = false;
    }
  }

  /// Lower the applied-vector entry for [deviceId] to [counter], so packets
  /// above it are pulled and applied afresh. The one place the applied vector
  /// moves backwards; everywhere else it is monotonic by construction.
  Future<void> _rewindApplied(String deviceId, int counter) async {
    final vector = await _readAppliedVector();
    if ((vector[deviceId] ?? 0) <= counter) return;
    if (counter <= 0) {
      vector.remove(deviceId);
    } else {
      vector[deviceId] = counter;
    }
    await _db.setProperty(_kAppliedVector, jsonEncode(vector));
  }

  /// The counter reported by the most recent [SyncStreamDivergedException],
  /// so a recovery started from Preferences discards exactly the contested
  /// packets without the user having to read a number out of an error message.
  ///
  /// Session-scoped on purpose. After a restart it is null, and a recovery
  /// then discards nothing — which is still safe: the fresh identity alone is
  /// what stops the fork, and the stale packets are inert once nothing adds to
  /// that stream.
  int? get lastDivergenceCounter => _lastDivergenceCounter;
  int? _lastDivergenceCounter;

  /// How many of this device's most recent packets are content-checked against
  /// a remote per exchange. A window rather than the whole stream: a fork shows
  /// up in the packets around where it happened, the two sides have been
  /// checking each other all along, and compaction means neither is guaranteed
  /// to still hold the deep history anyway.
  static const int _forkCheckWindow = 25;

  /// Verify that a remote's copy of *this device's own* stream is byte-for-byte
  /// what this device holds, over the newest counters both sides claim.
  ///
  /// Only our own stream: a fork is something a device does to itself by
  /// re-using its identities, so this is the one stream we are the authority
  /// on. Divergence in another device's stream is that device's to detect when
  /// it next syncs — and blocking here would only stop the node that noticed.
  ///
  /// Silent by design when it cannot conclude anything: an unimplemented
  /// endpoint, a pruned range, a slot neither side stores. The check adds
  /// detection where it can and never manufactures a failure where it can't.
  ///
  /// Returns whether the overlap was actually established as clean — false
  /// means "could not tell", which callers must not read as "fine". An empty
  /// overlap counts as clean: a device that has published nothing under this
  /// identity has published nothing that can disagree.
  Future<bool> _verifyOwnStream(PacketSource source, int upTo) async {
    if (upTo < 1) return true;
    final from = upTo - _forkCheckWindow + 1;
    final start = from < 1 ? 1 : from;

    final mine = await _db.syncPacketHashes(_deviceId, from: start, to: upTo);
    if (mine.isEmpty) return false;

    // A verification that cannot run must not become a sync that cannot run:
    // this check is strictly additional safety, and every error here (no such
    // endpoint, a dropped connection, a malformed answer) leaves the exchange
    // exactly as safe as it was before the check existed. Only a genuine
    // mismatch, below, is allowed to stop anything.
    final Map<int, String>? theirs;
    try {
      theirs = await source.getStreamHashes(_deviceId, from: start, to: upTo);
    } catch (_) {
      return false;
    }
    if (theirs == null) return false;

    // Ascending, so the first mismatch is the lowest one: that counter is
    // where the streams parted, and everything below it is shared history.
    var compared = 0;
    for (final counter in mine.keys.toList()..sort()) {
      final remote = theirs[counter];
      if (remote == null) continue;
      compared++;
      if (remote != mine[counter]) {
        _lastDivergenceCounter = counter;
        _log?.add(SyncLogKind.streamVerify,
            level: SyncLogLevel.error,
            originDevice: _deviceId,
            counter: counter,
            packetHash: mine[counter],
            message: 'Own stream diverged at #$counter: ${source.sourceName} '
                'holds ${remote.substring(0, 12)}…',
            detail: {'local_hash': mine[counter], 'remote_hash': remote});
        throw SyncStreamDivergedException(
          counter: counter,
          localHash: mine[counter]!,
          remoteHash: remote,
          sourceName: source.sourceName,
        );
      }
    }
    // Nothing actually overlapped (the remote holds none of the counters we
    // do): agreement was never tested, so it was not established.
    return compared > 0;
  }

  /// Whether any local edits have been made that have not yet been packaged.
  /// Uses the same per-table row-id watermarks as [packageLocalChanges] so it
  /// agrees exactly with what the next push would send. Drives the toolbar
  /// "pending changes" indicator.
  Future<bool> hasPendingLocalChanges() async {
    final taskAfter = await _readWatermark(_kPushedTaskHid);
    final fileAfter = await _readWatermark(_kPushedFileHid);
    final timelineAfter = await _readWatermark(_kPushedTimelineHid);

    final entries = await _historyService.getLocalHistoryAfterIds(
      taskAfterId: taskAfter,
      fileAfterId: fileAfter,
      timelineAfterId: timelineAfter,
    );
    return entries.isNotEmpty;
  }

  /// What [hasPendingLocalChanges] is true *about*: the not-yet-pushed edits
  /// grouped per entity, newest first, for the sync indicator's hover preview.
  ///
  /// Reads the same watermarks as [packageLocalChanges], so the preview lists
  /// exactly what the next push would send. [limit] caps how many entities are
  /// described (labels cost one lookup each); the counts in the returned
  /// [PendingChanges] always cover everything pending.
  Future<PendingChanges> pendingLocalChanges({int limit = 8}) async {
    final entries = await _historyService.getLocalHistoryAfterIds(
      taskAfterId: await _readWatermark(_kPushedTaskHid),
      fileAfterId: await _readWatermark(_kPushedFileHid),
      timelineAfterId: await _readWatermark(_kPushedTimelineHid),
    );
    if (entries.isEmpty) {
      return const PendingChanges(items: [], totalEntities: 0, totalChanges: 0);
    }

    // Group by entity: one edited task with five touched fields is one line in
    // the preview, not five.
    final groups = <String, List<HistoryEntry>>{};
    for (final e in entries) {
      groups.putIfAbsent('${e.entityType.name}:${e.entityId}', () => []).add(e);
    }

    final ordered = groups.values.toList()
      ..sort((a, b) => _latestOf(b).compareTo(_latestOf(a)));

    final items = <PendingChange>[];
    for (final group in ordered.take(limit)) {
      final first = group.first;
      items.add(PendingChange(
        entityType: first.entityType,
        entityId: first.entityId,
        label: await _describeEntity(first.entityType, first.entityId),
        fields: {for (final e in group) e.field}.toList(),
        changedAt: _latestOf(group),
      ));
    }

    return PendingChanges(
      items: items,
      totalEntities: groups.length,
      totalChanges: entries.length,
    );
  }

  DateTime _latestOf(List<HistoryEntry> group) => group
      .map((e) => e.timestamp)
      .reduce((a, b) => a.isAfter(b) ? a : b);

  /// Human-readable name for an entity in the pending-changes preview. Rows
  /// can be gone by now (deleted task, purged attachment) — the id is then all
  /// we can honestly show.
  Future<String> _describeEntity(HistoryEntityType type, int id) async {
    switch (type) {
      case HistoryEntityType.task:
        final task = await _db.getTaskById(id);
        final title = task?.title.trim() ?? '';
        return title.isEmpty ? 'Task #$id' : title;
      case HistoryEntityType.file:
        final file = await _db.getAttachmentLabel(id);
        final name = file?.filename.trim() ?? '';
        return name.isEmpty ? 'Attachment #$id' : name;
      case HistoryEntityType.timeline:
        final record = await _db.getTimeRecordById(id);
        if (record == null) return 'Time entry #$id';
        final task = await _db.getTaskById(record.taskId);
        final title = task?.title.trim() ?? '';
        return title.isEmpty ? 'Time entry #$id' : 'Time on "$title"';
    }
  }

  /// Emits whenever a local change is recorded (a row is written to any of the
  /// history tables). Consumers re-evaluate [hasPendingLocalChanges] to keep the
  /// sync status current as the user edits.
  Stream<void> watchLocalChanges() {
    return _db
        .tableUpdates(
          TableUpdateQuery.onAllTables([
            _db.historyTask,
            _db.historyFile,
            _db.historyTimeline,
          ]),
        )
        .map((_) {});
  }

  /// Apply packets that are in the store but ahead of the applied vector —
  /// e.g. after a crash between storing and applying, or packets received
  /// through another path. Idempotent under LWW, so over-applying is safe.
  Future<int> applyBacklog({List<SyncChange>? changeSink}) async {
    final storeVector = await _db.getSyncVector();
    final appliedVector = await _readAppliedVector();
    var totalApplied = 0;

    for (final entry in storeVector.entries) {
      final device = entry.key;
      if (device == _deviceId) {
        // Own packets are local state already; just normalize the vector.
        await _advanceApplied(device, entry.value);
        continue;
      }
      var from = appliedVector[device] ?? 0;
      while (from < entry.value) {
        final rows = await _db.getSyncPacketsAbove(device, from, limit: 50);
        if (rows.isEmpty) break;
        for (final row in rows) {
          _throwIfCancelled();
          await _yieldIfBusy();
          totalApplied += await _applyPacketBlob(
            originDeviceId: row.originDeviceId,
            counter: row.counter,
            payload: Uint8List.fromList(row.payload),
            changeSink: changeSink,
          );
          from = row.counter;
          await _advanceApplied(device, row.counter);
          _meter?.endPacket();
        }
      }
    }
    return totalApplied;
  }

  /// Pull remote packets from [source] and apply them locally.
  /// Returns the number of changes applied.
  ///
  /// The exchange is the v2 vector pull: "here is my vector → give me
  /// everything above it", paged, ascending per origin device. Each packet is
  /// stored (contiguity-checked) and applied; the applied vector is persisted
  /// after every packet, so an interruption resumes exactly where it stopped.
  ///
  /// [onApplied] is called with the running applied-count as pages are
  /// processed, so the detailed progress view can show live progress.
  /// [changeSink], when provided, collects the field-level changes that were
  /// actually applied (conflict-losers and no-ops are excluded).
  Future<int> pullFromSource(
    PacketSource source, {
    void Function(int total)? onApplied,
    List<SyncChange>? changeSink,
    bool checkFork = true,
  }) async {
    if (checkFork) await _checkForFork(source, await source.getVector());

    final have = await _db.getSyncVector();
    var totalApplied = 0;
    var hasMore = true;

    while (hasMore) {
      _throwIfCancelled();
      final result = await source.getChanges(have, limit: 100);
      hasMore = result.hasMore;

      var progressed = false;
      // Packets contiguity refused. A snapshot elsewhere in the same page can
      // make them acceptable (docs/P2P_SYNC_COMPACTION.md §4.2), so they are
      // retried once the page is through rather than waiting an exchange.
      var deferred = <RemotePacket>[];

      for (final packet in result.changes) {
        // Between packets only: each one is stored, applied and recorded in
        // the applied vector as a unit, so the next pull re-asks from here.
        _throwIfCancelled();
        await _yieldIfBusy();
        final outcome = await _ingestPacket(packet, have, changeSink);
        totalApplied += outcome.applied;
        if (outcome.progressed) progressed = true;
        if (outcome.deferred) {
          deferred.add(packet);
        } else {
          _meter?.endPacket();
        }
      }

      while (deferred.isNotEmpty) {
        final again = <RemotePacket>[];
        for (final packet in deferred) {
          _throwIfCancelled();
          await _yieldIfBusy();
          final outcome = await _ingestPacket(packet, have, changeSink);
          totalApplied += outcome.applied;
          if (outcome.progressed) progressed = true;
          if (outcome.deferred) {
            again.add(packet);
          } else {
            _meter?.endPacket();
          }
        }
        // Nothing moved: the remaining gaps are real, and the next exchange
        // re-fetches them.
        if (again.length == deferred.length) break;
        deferred = again;
      }

      // Safety valve: a page that stored nothing cannot advance the vector,
      // so re-asking with the same `have` would loop forever.
      if (!progressed) break;

      if (totalApplied > 0) onApplied?.call(totalApplied);
    }

    return totalApplied;
  }

  /// Store and apply one pulled packet, advancing [have] as it goes.
  ///
  /// `deferred` means contiguity refused the packet: either a genuine gap, or
  /// a packet that only a snapshot still to come can authorise. A snapshot
  /// itself is never deferred — it is self-sufficient, so it is applied where
  /// it lands and its coverage then admits it to the store (§4.1).
  Future<({int applied, bool progressed, bool deferred})> _ingestPacket(
    RemotePacket packet,
    Map<String, int> have,
    List<SyncChange>? changeSink,
  ) async {
    Future<void> accept() async {
      final held = have[packet.originDeviceId] ?? 0;
      if (packet.counter > held) have[packet.originDeviceId] = packet.counter;
      // Advance and persist per packet, applied or skipped, so an
      // interruption mid-page neither reprocesses nor gets stuck.
      await _advanceApplied(packet.originDeviceId, packet.counter);
    }

    final stored = await _db.storeSyncPacket(
      originDeviceId: packet.originDeviceId,
      counter: packet.counter,
      payload: packet.payload,
    );

    final log = _log;
    if (log != null) {
      final hash = NooDatabase.syncPayloadHash(packet.payload);
      void event(String kind, SyncLogLevel level, String message) => log.add(
            kind,
            level: level,
            direction: 'in',
            originDevice: packet.originDeviceId,
            counter: packet.counter,
            packetHash: hash,
            message: message,
            detail: {'bytes': packet.payload.length},
          );
      switch (stored) {
        case SyncPacketStoreResult.stored:
          event(SyncLogKind.packetStored, SyncLogLevel.info, 'Received');
        case SyncPacketStoreResult.duplicate:
          event(SyncLogKind.packetDuplicate, SyncLogLevel.info,
              'Already held (arrived by another path, or below a snapshot)');
        case SyncPacketStoreResult.conflict:
          event(
              SyncLogKind.packetDiverged,
              SyncLogLevel.error,
              'A different packet is already stored under this identity '
              '(held ${(await _db.syncPacketHashAt(packet.originDeviceId, packet.counter))?.padRight(12).substring(0, 12)}…)');
        case SyncPacketStoreResult.gap:
          event(SyncLogKind.packetDeferred, SyncLogLevel.info,
              'Not contiguous with what this device holds; retried after '
              'the page, or on the next exchange');
      }
    }

    switch (stored) {
      case SyncPacketStoreResult.stored:
        final applied = await _applyPacketBlob(
          originDeviceId: packet.originDeviceId,
          counter: packet.counter,
          payload: packet.payload,
          changeSink: changeSink,
        );
        await accept();
        return (applied: applied, progressed: true, deferred: false);

      case SyncPacketStoreResult.duplicate:
        // Already held (it arrived via another path), or below an adopted
        // snapshot's coverage — either way there is nothing to do.
        return (applied: 0, progressed: false, deferred: false);

      case SyncPacketStoreResult.conflict:
        // The slot is held by different bytes: this packet's origin device
        // forked its own stream, and one of the two packets is not the packet
        // its identity claims to be. Neither can be preferred from here, so
        // hold on to what is already applied and record the collision.
        //
        // Recorded rather than thrown: the fork belongs to the origin device,
        // which will detect it itself (_verifyOwnStream) on its next sync.
        // Every other device's stream in this exchange is unaffected, and
        // refusing them would spread one device's problem to the whole fleet.
        // Compaction is blocked while this stands, since this device's state
        // is demonstrably not the merge of everything in the log.
        _skippedPackets.add(SyncSkippedPacket(
          originDeviceId: packet.originDeviceId,
          counter: packet.counter,
          stage: 'diverged',
          detail: 'A different packet is already stored under this identity; '
              'the origin device has re-used a counter (restored backup?).',
        ));
        return (applied: 0, progressed: false, deferred: false);

      case SyncPacketStoreResult.gap:
        final decoded = await _decodePacket(
          originDeviceId: packet.originDeviceId,
          counter: packet.counter,
          payload: packet.payload,
        );
        if (decoded == null) {
          // Undecryptable: not a gap this node can ever close by waiting.
          return (applied: 0, progressed: false, deferred: false);
        }
        if (!decoded.fullState) {
          return (applied: 0, progressed: false, deferred: true);
        }
        final applied = await _applyDecodedPacket(decoded, changeSink);
        if (applied == null) {
          return (applied: 0, progressed: false, deferred: false);
        }
        // Adoption raised the baseline to this packet's predecessor, so the
        // store now accepts the snapshot itself.
        await _db.storeSyncPacket(
          originDeviceId: packet.originDeviceId,
          counter: packet.counter,
          payload: packet.payload,
        );
        await accept();
        return (applied: applied, progressed: true, deferred: false);
    }
  }

  /// Packets skipped because they could not be decrypted, decoded or applied.
  /// Cumulative for the session — [_compactionBlocker] needs the whole
  /// history, since a packet skipped an hour ago is still missing from this
  /// device's state. Per-run reporting slices this from [_runSkipMark].
  final List<SyncSkippedPacket> _skippedPackets = [];

  /// Identities ("device:counter") of every packet skipped this session.
  List<String> get skippedBlobs =>
      List.unmodifiable(_skippedPackets.map((p) => p.id));

  /// The full records behind [skippedBlobs].
  List<SyncSkippedPacket> get skippedPackets =>
      List.unmodifiable(_skippedPackets);

  /// Where [_skippedPackets] stood when the current run started, so a result
  /// reports this run's losses rather than the whole session's.
  int _runSkipMark = 0;

  /// Remote changes this run dropped under LWW.
  final List<SyncLwwSkip> _lwwSkips = [];

  /// Start collecting diagnostics for one sync run. The skipped-packet list is
  /// cumulative, so only the mark moves; LWW losses are per-run.
  void _beginRunDiagnostics() {
    _runSkipMark = _skippedPackets.length;
    _lwwSkips.clear();
    _ownStreamRefusal = null;
  }

  /// The packets this run could not read.
  List<SyncSkippedPacket> _runSkippedPackets() =>
      List.unmodifiable(_skippedPackets.sublist(_runSkipMark));

  /// This run's LWW losses, one entry per entity+field (the newest remote
  /// attempt takes the slot), with entity names resolved for display.
  Future<List<SyncLwwSkip>> _summarizeLwwSkips() async {
    if (_lwwSkips.isEmpty) return const [];

    final byField = <String, SyncLwwSkip>{};
    for (final skip in _lwwSkips) {
      final key = '${skip.entityType}:${skip.worldId}:${skip.field}';
      final held = byField[key];
      if (held == null || skip.remoteTimestamp.isAfter(held.remoteTimestamp)) {
        byField[key] = skip;
      }
    }

    final resolved = <SyncLwwSkip>[];
    for (final skip in byField.values) {
      resolved.add(skip.withLabel(
        await _labelForWorldId(skip.entityType, skip.worldId),
      ));
    }
    resolved.sort((a, b) => b.remoteTimestamp.compareTo(a.remoteTimestamp));
    return resolved;
  }

  /// Display name for an entity addressed by world id, or null when this
  /// device has no such row.
  Future<String?> _labelForWorldId(String entityType, String worldId) async {
    switch (entityType) {
      case 'task':
        final task = await _db.getTaskByWorldId(worldId);
        if (task == null) return null;
        final title = task.title.trim();
        return title.isEmpty ? 'Untitled node' : title;
      case 'file':
        final file = await _db.getAttachmentByWorldId(worldId);
        if (file == null) return null;
        final name = file.filename.trim();
        return name.isEmpty ? 'Attachment' : name;
      case 'timeline':
        final record = await _db.getTimeRecordByWorldId(worldId);
        if (record == null) return null;
        final task = await _db.getTaskById(record.taskId);
        final title = task?.title.trim() ?? '';
        return title.isEmpty ? 'Time entry' : 'Time on "$title"';
      default:
        return null;
    }
  }

  /// Decrypt, parse, and apply one stored packet blob. Returns the number of
  /// changes applied. A packet that fails to decrypt, parse, or whose inner
  /// identity disagrees with its envelope identity is skipped and logged —
  /// one corrupt blob must not wedge the stream. A packet that is sound but
  /// could not be written *throws* (see [_applyDecodedPacket]), so the
  /// applied vector stays below it and the next run tries again.
  Future<int> _applyPacketBlob({
    required String originDeviceId,
    required int counter,
    required Uint8List payload,
    List<SyncChange>? changeSink,
  }) async {
    final packet = await _decodePacket(
      originDeviceId: originDeviceId,
      counter: counter,
      payload: payload,
    );
    if (packet == null) return 0;
    return await _applyDecodedPacket(packet, changeSink) ?? 0;
  }

  /// Apply an already-decoded packet. Returns null when its content made the
  /// apply throw — the packet is then recorded in [skippedPackets] and the
  /// stream moves on, since it would fail the same way every time. Any other
  /// failure — the database refusing a write, a connection gone away — is
  /// rethrown: that is this device's problem, not the packet's, and the
  /// packet must stay unconsumed so the next run's backlog pass applies it.
  Future<int?> _applyDecodedPacket(
    SyncPacket packet,
    List<SyncChange>? changeSink,
  ) async {
    final lwwMark = _lwwSkips.length;
    final logMark = _log?.mark;
    try {
      final applied = await _applyRemotePacket(packet, changeSink);
      _log?.add(
        SyncLogKind.packetApplied,
        direction: 'in',
        originDevice: packet.deviceId,
        counter: packet.counter,
        message: '${packet.fullState ? 'Full-state packet' : 'Packet'}: '
            '$applied of ${packet.changes.length} change(s) applied',
        detail: {
          'changes': packet.changes.length,
          'full_state': packet.fullState,
          ..._packetStats,
          if (packet.vector != null) 'sender_vector': packet.vector,
        },
      );
      // A snapshot authorises forgetting what it covers — and only after it
      // has actually been applied (§4.1: never on a declaration alone).
      if (packet.fullState) await adoptSnapshotCoverage(packet);
      await _log?.flush();
      return applied;
    } catch (e) {
      // The packet's transaction rolled back, so the conflicts it recorded on
      // the way through never happened — drop them with it.
      _lwwSkips.removeRange(lwwMark, _lwwSkips.length);
      if (logMark != null) _log?.rollbackTo(logMark);
      // A cancel is not a broken packet: it stays stored and unapplied, and
      // the next run applies it — it must not be written off as skipped.
      if (e is SyncCancelledException) rethrow;
      if (!isPacketFault(e)) {
        _log?.add(SyncLogKind.applyFailed,
            level: SyncLogLevel.error,
            direction: 'in',
            originDevice: packet.deviceId,
            counter: packet.counter,
            message: 'Packet rolled back; it is kept and applied again on the '
                'next sync: $e');
        await _log?.flush();
        rethrow;
      }
      _log?.add(SyncLogKind.applyFailed,
          level: SyncLogLevel.error,
          direction: 'in',
          originDevice: packet.deviceId,
          counter: packet.counter,
          message: 'Packet rolled back and skipped; its changes are lost on '
              'this device: $e');
      await _log?.flush();
      _skippedPackets.add(SyncSkippedPacket(
        originDeviceId: packet.deviceId,
        counter: packet.counter,
        stage: 'apply',
        detail: e.toString(),
      ));
      return null;
    }
  }

  /// Whether [error] is the packet's own doing — a value that does not parse,
  /// an argument out of range — which will fail identically however often it
  /// is retried. Everything else is taken to be this device's failure and
  /// worth retrying: a packet written off over a transient database error is
  /// lost for good, while one retried needlessly costs a rolled-back
  /// transaction. Public only so the rule itself can be tested.
  static bool isPacketFault(Object error) =>
      error is FormatException || error is ArgumentError || error is TypeError;

  /// Decrypt and parse one stored blob, or null when it is unusable (and then
  /// recorded in [skippedPackets]).
  ///
  /// The failure stages are kept apart because they mean different things:
  /// 'decrypt' is a key mismatch (nearly always a different database password
  /// on this device), 'parse' is a corrupt or truncated blob, and 'identity'
  /// is a payload that does not belong to the envelope it came in.
  Future<SyncPacket?> _decodePacket({
    required String originDeviceId,
    required int counter,
    required Uint8List payload,
  }) async {
    void skip(String stage, Object error) {
      _skippedPackets.add(SyncSkippedPacket(
        originDeviceId: originDeviceId,
        counter: counter,
        stage: stage,
        detail: error.toString(),
      ));
      _log?.add(SyncLogKind.decodeFailed,
          level: SyncLogLevel.error,
          direction: 'in',
          originDevice: originDeviceId,
          counter: counter,
          packetHash: NooDatabase.syncPayloadHash(payload),
          message: stage == 'decrypt'
              ? 'Could not decrypt (different database password?); skipped'
              : 'Unreadable ($stage); skipped: $error',
          detail: {'stage': stage});
    }

    Uint8List decrypted;
    try {
      decrypted = await _crypto.decrypt(
        payload,
        aad: SyncCrypto.packetAad(originDeviceId, counter),
      );
    } catch (e) {
      skip('decrypt', e);
      return null;
    }

    try {
      final json = _packager.decompress(decrypted);
      final packet = SyncPacket.deserialize(json);
      if (!SyncPacket.acceptedVersions.contains(packet.version) ||
          packet.deviceId != originDeviceId ||
          packet.counter != counter) {
        skip(
          'identity',
          'envelope $originDeviceId:$counter carries '
              '${packet.deviceId}:${packet.counter} (v${packet.version})',
        );
        return null;
      }
      return packet;
    } catch (e) {
      skip('parse', e);
      return null;
    }
  }

  /// Adopt the coverage of an applied full-state snapshot
  /// (docs/P2P_SYNC_COMPACTION.md §4.1) and drop the packets it supersedes
  /// (§4.4). Returns what the local store gave back.
  ///
  /// The snapshot carries the merged result of everything it covers, so the
  /// covered packets add nothing: holding them costs space, and *knowing* the
  /// coverage is what lets this node accept a stream that no longer starts at
  /// 1. What is genuinely lost is history below the horizon, not state.
  ///
  /// This device's own stream is adopted only up to what is actually stored
  /// here. Taking a sender's word for our own counters would mask a fork
  /// (docs/P2P_SYNC.md §3.3): a restored backup must still be caught by
  /// [_checkForFork] rather than quietly resuming above its own history.
  Future<({int packets, int bytes})> adoptSnapshotCoverage(
      SyncPacket packet) async {
    final coverage = <String, int>{...?packet.vector};
    // A device's own snapshot always supersedes its own earlier packets,
    // whatever its declared vector says: the snapshot is that state.
    final ownPrior = packet.counter - 1;
    if (ownPrior > (coverage[packet.deviceId] ?? 0)) {
      coverage[packet.deviceId] = ownPrior;
    }
    final stored = await _db.maxStoredSyncCounterFor(_deviceId);
    if ((coverage[_deviceId] ?? 0) > stored) coverage[_deviceId] = stored;
    coverage.removeWhere((_, counter) => counter < 1);
    if (coverage.isEmpty) return (packets: 0, bytes: 0);

    await _db.mergeSyncBaselineVector(coverage);
    var packets = 0, bytes = 0;
    for (final entry in coverage.entries) {
      // Coverage implies the state is applied, whether or not this node ever
      // held the packets — otherwise applyBacklog would hunt for packets that
      // are gone.
      await _advanceApplied(entry.key, entry.value);
      final freed = await _db.deleteSyncPacketsUpTo(entry.key, entry.value);
      packets += freed.packets;
      bytes += freed.bytes;
    }
    _log?.add(SyncLogKind.snapshotAdopted,
        originDevice: packet.deviceId,
        counter: packet.counter,
        message: 'Snapshot coverage adopted; $packets superseded packet(s) '
            'dropped',
        detail: {'coverage': coverage, 'packets': packets, 'bytes': bytes});
    return (packets: packets, bytes: bytes);
  }

  /// Re-apply orphaned changes (entity arrived after its edits); successes and
  /// stale entries are removed, the rest age out after 30 days.
  Future<int> retryOrphans({List<SyncChange>? changeSink}) async {
    final orphans = await _db.getAllSyncOrphans();
    _applyingFullState = false;
    _applyingPacket = null;
    _retryingOrphans = true;
    var applied = 0;
    final resolved = <String>{};
    try {
    for (final o in orphans) {
      await _yieldIfBusy();
      final change = SyncChange(
        entityType: o.entityType,
        worldId: o.worldId,
        field: o.field,
        value: o.value,
        timestamp: o.timestamp,
        isCreation: o.isCreation == 1,
        parentWorldId: o.parentWorldId,
      );
      final outcome = await _applyRemoteChange(change, recordOrphans: false);
      if (outcome != _ApplyOutcome.orphaned) {
        resolved.add('${o.entityType}:${o.worldId}:${o.field}');
        await _db.deleteSyncOrphan(o.entityType, o.worldId, o.field);
        if (outcome == _ApplyOutcome.applied) {
          applied++;
          changeSink?.add(change);
        }
      }
    }
    // Orphan rows carry no sender vector, so any conflicts noted here came
    // through the conservative fallback; materialize them the same way.
    await _materializeConflictCopies();
    } finally {
      _retryingOrphans = false;
    }
    final cutoff = NooDatabase.formatIso(
        DateTime.now().subtract(const Duration(days: 30)));
    for (final o in orphans) {
      if (o.firstSeen.compareTo(cutoff) >= 0) continue;
      if (resolved.contains('${o.entityType}:${o.worldId}:${o.field}')) {
        continue;
      }
      _log?.add(SyncLogKind.orphanExpired,
          level: SyncLogLevel.warning,
          direction: 'in',
          entityType: o.entityType,
          worldId: o.worldId,
          field: o.field,
          remoteTs: o.timestamp,
          value: o.value,
          hasValue: true,
          message: 'Dropped after 30 days: the entity it belongs to never '
              'arrived (first seen ${o.firstSeen})');
    }
    await _db.purgeSyncOrphansBefore(cutoff);
    await _log?.flush();
    return applied;
  }

  /// Apply a remote sync packet to the local database.
  /// Returns the number of changes actually applied. Changes that actually took
  /// effect are added to [changeSink] (if provided) for the details view.
  ///
  /// The whole packet is applied in one transaction. Autocommit would make
  /// every field-level change its own commit, which dominates the cost of a
  /// large packet — the v1→v2 full-state re-package carries one change per
  /// field of every task, file and timeline record, so a modest database
  /// yields tens of thousands of commits on a first sync. Batching also
  /// collapses drift's per-statement table-update notifications into one
  /// round of stream rebuilds at commit.
  ///
  /// A packet is therefore all-or-nothing: if a change throws mid-packet the
  /// transaction rolls back and [_applyPacketBlob] records the whole packet as
  /// skipped, rather than leaving it half-applied. [changeSink] is fed only
  /// after the commit, so a rollback cannot leave phantom entries in the
  /// details view.
  Future<int> _applyRemotePacket(
      SyncPacket packet, List<SyncChange>? changeSink) async {
    final applied = <SyncChange>[];

    await _db.transaction(() async {
      applied.clear();
      _pendingConflictCopies.clear();
      _packetStats.clear();
      _applyingPacket = (device: packet.deviceId, counter: packet.counter);
      _applyingFullState = packet.fullState;
      _meter?.beginPacket(packet.changes.length);
      for (final change in packet.changes) {
        // Inside the transaction: a cancel here rolls the whole packet back,
        // and the next run applies it again from the store (applyBacklog).
        _throwIfCancelled();
        await _yieldIfBusy();
        final outcome =
            await _applyRemoteChange(change, senderVector: packet.vector);
        if (outcome == _ApplyOutcome.applied) {
          applied.add(change);
        }
        _meter?.change();
      }
      // Materialize any conflict copies inside the same transaction, so the
      // copy and the overwrite that made it necessary commit atomically.
      await _materializeConflictCopies();
    });

    changeSink?.addAll(applied);
    return applied.length;
  }

  /// Apply a single remote change with conflict resolution.
  /// [recordOrphans] is false when re-applying from the orphan table, so a
  /// still-unresolvable change keeps its original first-seen age.
  Future<_ApplyOutcome> _applyRemoteChange(
    SyncChange change, {
    bool recordOrphans = true,
    Map<String, int>? senderVector,
  }) async {
    _note = null;
    final outcome =
        await _applyRemoteChangeInner(change, senderVector: senderVector);
    _logChange(change, outcome, recordOrphans: recordOrphans);
    if (outcome == _ApplyOutcome.orphaned && recordOrphans) {
      await _db.upsertSyncOrphan(
        entityType: change.entityType,
        worldId: change.worldId,
        field: change.field,
        value: change.value,
        timestamp: change.timestamp,
        isCreation: change.isCreation,
        parentWorldId: change.parentWorldId,
      );
    }
    return outcome;
  }

  /// Write the event for one applied (or not) remote change.
  void _logChange(SyncChange change, _ApplyOutcome outcome,
      {required bool recordOrphans}) {
    final note = _note;
    _note = null;
    final log = _log;
    if (log == null) return;

    String kind;
    var level = note?.level ?? SyncLogLevel.info;
    var message = note?.message;
    switch (outcome) {
      case _ApplyOutcome.applied:
        kind = note?.kind ?? SyncLogKind.applied;
      case _ApplyOutcome.skipped:
        kind = note?.kind ?? SyncLogKind.ignored;
      case _ApplyOutcome.orphaned:
        // Still waiting on a retry is not news; it was logged when it arrived.
        if (!recordOrphans) return;
        kind = SyncLogKind.orphaned;
        level = SyncLogLevel.warning;
        message = 'The entity it belongs to has not arrived yet; kept for '
            'retry (30 days)';
    }
    _packetStats[kind] = (_packetStats[kind] ?? 0) + 1;
    if (_retryingOrphans) {
      message = 'Orphan retried: ${message ?? kind}';
    }

    if (_applyingFullState &&
        level == SyncLogLevel.info &&
        SyncLogKind.routine.contains(kind)) {
      log.tally(kind);
      return;
    }
    final packet = _applyingPacket;
    final detail = <String, Object?>{
      if (change.isCreation) 'creation': true,
      if (change.parentWorldId != null) 'parent': change.parentWorldId,
      ...?note?.detail,
    };
    log.add(
      kind,
      level: level,
      direction: 'in',
      originDevice: packet?.device,
      counter: packet?.counter,
      entityType: change.entityType,
      worldId: change.worldId,
      field: change.field,
      remoteTs: change.timestamp,
      localTs: note?.localTs,
      value: change.value,
      hasValue: true,
      message: message,
      detail: detail.isEmpty ? null : detail,
    );
  }

  Future<_ApplyOutcome> _applyRemoteChangeInner(
    SyncChange change, {
    Map<String, int>? senderVector,
  }) async {
    switch (change.entityType) {
      case 'task':
        return _applyTaskChange(change, senderVector: senderVector);
      case 'file':
        return _applyFileChange(change);
      case 'timeline':
        return _applyTimelineChange(change);
      default:
        _noteChange(SyncLogKind.ignored,
            level: SyncLogLevel.warning,
            message: 'Unknown entity type "${change.entityType}"');
        return _ApplyOutcome.skipped;
    }
  }

  // ============================================================
  // Task Changes
  // ============================================================

  /// Field-level Last-Writer-Wins: apply the remote change only if its origin
  /// timestamp is newer than the timestamp of the value currently stored for
  /// that entity+field. [latestLocalTimestamp] is the timestamp of the latest
  /// history row (local or previously-applied remote) for that field, or null
  /// if the field has never been written — in which case the remote wins.
  ///
  /// A loss is recorded in [_lwwSkips]: it writes nothing, so it is invisible
  /// in the change counts, and the one cause worth catching — a clock that
  /// runs ahead on this device — looks exactly like a change that never
  /// arrived.
  ///
  /// An exact tie is broken by the values themselves ([localValue] is asked
  /// for only then): the greater string wins, null below every string. Both
  /// sides apply the same rule to the same pair, so exactly one of them
  /// changes and the fleet converges — with strict "newer wins" each device
  /// kept its own value and they stayed different for good
  /// (docs/P2P_SYNC.md §8.1).
  Future<bool> _remoteWins(
    SyncChange change,
    String? latestLocalTimestamp, {
    required Future<String?> Function() localValue,
  }) async {
    if (latestLocalTimestamp == null) return true;
    final remote = DateTime.parse(change.timestamp);
    final local = DateTime.parse(latestLocalTimestamp);
    if (remote.isAfter(local)) {
      _noteChange(SyncLogKind.applied, localTs: latestLocalTimestamp);
      return true;
    }
    final ahead = local.difference(remote);
    if (ahead == Duration.zero) {
      final held = await localValue();
      final order = _compareValues(change.value, held);
      if (order == 0) {
        _noteChange(SyncLogKind.lwwTie,
            localTs: latestLocalTimestamp,
            message: 'Same timestamp and same value on both sides; nothing '
                'to change');
        return false;
      }
      if (order > 0) {
        _noteChange(SyncLogKind.lwwTie,
            level: SyncLogLevel.warning,
            localTs: latestLocalTimestamp,
            message: 'Same timestamp on both sides: the greater value wins so '
                'every device converges — the incoming one');
        return true;
      }
      _noteChange(SyncLogKind.lwwTie,
          level: SyncLogLevel.warning,
          localTs: latestLocalTimestamp,
          message: 'Same timestamp on both sides: the greater value wins so '
              'every device converges — the one already here');
    } else {
      _noteChange(SyncLogKind.lwwLost,
          localTs: latestLocalTimestamp,
          message: 'Local value is newer by ${_describeGap(ahead)}',
          detail: {'local_ahead_ms': ahead.inMilliseconds});
    }
    _lwwSkips.add(SyncLwwSkip(
      entityType: change.entityType,
      worldId: change.worldId,
      field: change.field,
      remoteTimestamp: remote,
      localTimestamp: local,
    ));
    return false;
  }

  /// The tie-break order: null first, then plain string order. Nothing
  /// cleverer — it only has to be total and the same on every device.
  static int _compareValues(String? a, String? b) {
    if (a == null) return b == null ? 0 : -1;
    if (b == null) return 1;
    return a.compareTo(b);
  }

  /// A task field as the packager would publish it (see
  /// `SyncChangePackager`), so a tie compares like with like.
  Future<String?> _localTaskValue(TaskRow task, String field) async {
    switch (field) {
      case 'title':
        return task.title;
      case 'content':
        return task.content;
      case 'parentId':
        final parentId = task.parentId;
        if (parentId == null) return null;
        return (await _db.getTaskById(parentId))?.worldId;
      case 'orderId':
        return task.orderId.toString();
      case 'flags':
        return task.flags.toString();
      case 'removed':
        return task.removed.toString();
    }
    return null;
  }

  /// A file field as the packager would publish it.
  Future<String?> _localFileValue(FileEntry file, String field) async {
    switch (field) {
      case 'filename':
        return file.filename;
      case 'content':
        return file.contentHash.isEmpty
            ? null
            : BlobRef(file.contentHash).encode();
      case 'orderId':
        return file.orderId.toString();
      case 'removed':
        return file.removed.toString();
    }
    return null;
  }

  /// A time entry field as the packager would publish it.
  Future<String?> _localTimelineValue(
      TimelineEntry record, String field) async {
    switch (field) {
      case 'taskId':
        return (await _db.getTaskById(record.taskId))?.worldId;
      case 'startTime':
        return record.startTime;
      case 'endTime':
        return record.endTime;
      case 'removed':
        return record.removed.toString();
    }
    return null;
  }

  static String _describeGap(Duration d) {
    if (d.inSeconds < 1) return '${d.inMilliseconds} ms';
    if (d.inMinutes < 1) return '${d.inSeconds} s';
    if (d.inHours < 1) return '${d.inMinutes} min';
    if (d.inDays < 2) return '${d.inHours} h';
    return '${d.inDays} days';
  }

  Future<_ApplyOutcome> _applyTaskChange(
    SyncChange change, {
    Map<String, int>? senderVector,
  }) async {
    final localTask = await _db.getTaskByWorldId(change.worldId);

    if (localTask == null) {
      if (change.isCreation) {
        return _createTaskFromRemote(change, senderVector: senderVector);
      }
      // Entity doesn't exist locally and this isn't a creation — its creation
      // is elsewhere in another device's stream; keep for retry.
      return _ApplyOutcome.orphaned;
    }

    final latest =
        await _db.getLatestTaskHistoryForField(localTask.id, change.field);
    if (!await _remoteWins(change, latest?.timestamp,
        localValue: () => _localTaskValue(localTask, change.field))) {
      await _noteEditConflict(localTask, change, latest, senderVector);
      return _ApplyOutcome.skipped;
    }
    if (change.field == 'removed' && change.value == '1') {
      await _noteRemovalConflict(localTask, change, senderVector);
    }
    return _applyTaskField(localTask, change);
  }

  Future<_ApplyOutcome> _createTaskFromRemote(
    SyncChange change, {
    Map<String, int>? senderVector,
  }) async {
    final existing = await _db.getTaskByWorldId(change.worldId);
    if (existing != null) {
      // Already created by a sibling change — apply this field with LWW.
      return _applyTaskChange(change, senderVector: senderVector);
    }

    // Resolve parent
    int? parentId;
    if (change.parentWorldId != null && change.parentWorldId!.isNotEmpty) {
      final parent = await _db.getTaskByWorldId(change.parentWorldId!);
      parentId = parent?.id;
    }
    final parentMissing = parentId == null &&
        change.parentWorldId != null &&
        change.parentWorldId!.isNotEmpty;
    if (parentMissing) {
      _noteChange(SyncLogKind.parentMissing,
          level: SyncLogLevel.warning,
          message: 'Created at the root for now: its parent '
              '${change.parentWorldId} is not on this device yet; moved under '
              'it when it arrives');
    } else {
      _noteChange(SyncLogKind.created);
    }

    // Create a bare, history-free remote row, then apply the triggering field
    // (and later siblings) with their own origin timestamps. This avoids
    // stamping default field values at now() and having them wrongly beat the
    // real remote values under LWW.
    final newId = await _db.createTaskFromRemote(
      worldId: change.worldId,
      parentId: parentId,
      remoteTimestamp: change.timestamp,
    );
    // The root placement is provisional: the move under the real parent is
    // kept as an orphan of its own (§8.2), so it happens when that parent's
    // creation arrives — from whichever stream carries it, in whatever order.
    // Unless this very change is the move, which records itself below.
    if (parentMissing && change.field != 'parentId') {
      await _db.upsertSyncOrphan(
        entityType: 'task',
        worldId: change.worldId,
        field: 'parentId',
        value: change.parentWorldId,
        timestamp: change.timestamp,
        isCreation: false,
        parentWorldId: change.parentWorldId,
      );
    }
    final row = await _db.getTaskById(newId);
    if (row == null) return _ApplyOutcome.skipped;
    return _applyTaskField(row, change);
  }

  /// Applies a single remote field to a task, stamping the row and history
  /// with the change's origin timestamp (marks it remote so it is not pushed).
  Future<_ApplyOutcome> _applyTaskField(TaskRow task, SyncChange change) async {
    final ts = change.timestamp;
    switch (change.field) {
      case 'title':
        await _db.updateTask(task.id, title: change.value ?? '', remoteTimestamp: ts);
        return _ApplyOutcome.applied;
      case 'content':
        await _db.updateTask(task.id, content: change.value, remoteTimestamp: ts);
        return _ApplyOutcome.applied;
      case 'parentId':
        if (change.value == null || change.value!.isEmpty) {
          await _db.updateTask(task.id, clearParent: true, remoteTimestamp: ts);
        } else {
          final parent = await _db.getTaskByWorldId(change.value!);
          if (parent != null) {
            // Cycle detection: ensure the new parent isn't a descendant
            if (!await _db.wouldCreateCycle(task.id, parent.id)) {
              await _db.updateTask(task.id, parentId: parent.id, remoteTimestamp: ts);
            } else {
              // Cycle detected — move to root instead
              _noteChange(SyncLogKind.cycleToRoot,
                  level: SyncLogLevel.warning,
                  message: 'Moving under ${parent.worldId} would create a '
                      'cycle; moved to the root instead');
              await _db.updateTask(task.id, clearParent: true, remoteTimestamp: ts);
            }
          } else {
            // Streams apply in arbitrary order across devices, so the parent
            // is often simply still on its way. Kept for retry rather than
            // dropped: a move dropped here was lost for good, since nothing
            // re-sends it once the stream has been applied.
            _noteChange(SyncLogKind.parentMissing,
                level: SyncLogLevel.warning,
                message: 'Kept for retry: new parent ${change.value} is not '
                    'on this device yet');
            return _ApplyOutcome.orphaned;
          }
        }
        return _ApplyOutcome.applied;
      case 'orderId':
        final orderId = int.tryParse(change.value ?? '0') ?? 0;
        await _db.updateTask(task.id, orderId: orderId, remoteTimestamp: ts);
        return _ApplyOutcome.applied;
      case 'flags':
        final flags = int.tryParse(change.value ?? '0') ?? 0;
        await _db.updateTask(task.id, flags: flags, remoteTimestamp: ts);
        return _ApplyOutcome.applied;
      case 'removed':
        final removed = int.tryParse(change.value ?? '0') ?? 0;
        if (removed == 1) {
          await _db.deleteTask(task.id, remoteTimestamp: ts);
        } else {
          await _db.undeleteTask(task.id, remoteTimestamp: ts);
        }
        return _ApplyOutcome.applied;
      default:
        _noteChange(SyncLogKind.unknownField,
            level: SyncLogLevel.warning,
            message: 'Unknown task field; ignored');
        return _ApplyOutcome.skipped;
    }
  }

  // ============================================================
  // Conflict copies (docs/P2P_SYNC.md §8.3)
  // ============================================================
  //
  // LWW silently discards the losing side of a concurrent edit. When the
  // loss is user-written text (a task's title or content), the losing value
  // is preserved as a "conflict copy" — a new sibling task — instead of
  // vanishing. A copy is made only for *concurrent* edits: the sender must
  // not have seen the value it is overriding, which the sender's packet
  // vector plus the push log answers exactly. A normal newer edit made on
  // top of a synced value never produces a copy.
  //
  // Exactly one device in the fleet creates each copy, so convergence cannot
  // duplicate it:
  //  - edit-vs-edit: the device owning the *winning* value (only there is
  //    the winning history row local-origin) copies the losing remote value
  //    when it arrives and loses.
  //  - delete-vs-edit: the device owning the unseen local edit copies its
  //    own values when the winning remote deletion applies.
  // The copy is an ordinary locally-created task, so it syncs everywhere by
  // the normal path.

  /// Pending conflict copies for the packet being applied, keyed by the
  /// original task's worldId (one copy per task per packet).
  final Map<String, _PendingConflictCopy> _pendingConflictCopies = {};

  /// Whether the packet currently being applied is a full-state re-announce
  /// (see [SyncPacket.fullState]); conflict copies are suppressed for those.
  bool _applyingFullState = false;

  /// Task-history watermark from before this cycle's packaging — the
  /// conservative fallback base for [_senderHadNotSeen] when a packet
  /// carries no vector.
  int? _prePackageTaskHid;

  /// Whether the sender of the packet being applied had not seen local
  /// task-history row [rowId] when it packaged. Exact when the packet
  /// carries a vector (resolved through the push log); otherwise falls back
  /// to "the row had not been packaged before this cycle", which catches the
  /// common offline-edit case and never fires on long-synced values.
  Future<bool> _senderHadNotSeen(
      int rowId, Map<String, int>? senderVector) async {
    if (senderVector != null) {
      final seen = senderVector[_deviceId] ?? 0;
      if (seen == 0) return true; // sender never applied any of our packets
      final watermark = await _db.getPushLogTaskHidAtOrBelow(seen);
      if (watermark != null) return rowId > watermark;
      // No push log that far back (packets sent before the log existed) —
      // fall through to the conservative test.
    }
    final pushed = _prePackageTaskHid ?? await _readWatermark(_kPushedTaskHid);
    return rowId > pushed;
  }

  /// An incoming title/content change lost LWW to a local-origin value the
  /// sender had not seen — a concurrent edit whose remote side would
  /// otherwise be discarded everywhere. Queue the losing value for a copy.
  /// (A change's own isCreation flag is no discriminator here: it also marks
  /// a field's first-ever value on an existing task.)
  Future<void> _noteEditConflict(
    TaskRow task,
    SyncChange change,
    HistoryTaskData? latest,
    Map<String, int>? senderVector,
  ) async {
    // Full-state re-announces (migration, fork recovery) echo stale values
    // back; a stale echo losing LWW is not a concurrent edit.
    if (_applyingFullState) return;
    if (change.field != 'title' && change.field != 'content') return;
    if (latest == null || latest.isRemote != 0) return;
    final current = change.field == 'title' ? task.title : task.content;
    if (change.value == current) return; // identical — nothing would be lost
    if (!await _senderHadNotSeen(latest.id, senderVector)) return;

    final pending = _pendingConflictCopies.putIfAbsent(
        task.worldId, () => _PendingConflictCopy(task.id));
    if (change.field == 'title') {
      pending.losingTitle = change.value;
    } else {
      pending.losingContent = change.value;
    }
  }

  /// A winning remote deletion is about to hide local-origin edits the
  /// deleting device never saw (delete-vs-edit). Queue a copy carrying the
  /// local values; the deletion itself still applies.
  Future<void> _noteRemovalConflict(
    TaskRow task,
    SyncChange change,
    Map<String, int>? senderVector,
  ) async {
    if (_applyingFullState) return;
    if (task.removed != 0) return; // already gone locally; nothing newly lost
    for (final field in const ['title', 'content']) {
      final latest = await _db.getLatestTaskHistoryForField(task.id, field);
      if (latest == null || latest.isRemote != 0) continue;
      if (!await _senderHadNotSeen(latest.id, senderVector)) continue;
      _pendingConflictCopies
          .putIfAbsent(task.worldId, () => _PendingConflictCopy(task.id))
          .dueToRemoval = true;
      return;
    }
  }

  /// Create the queued conflict copies as ordinary local tasks (they record
  /// history and sync out by the normal path). Runs inside the packet's
  /// transaction; reapplying the same packet cannot re-queue (the conflicted
  /// field's latest history row is remote-origin afterwards), so this stays
  /// idempotent.
  Future<void> _materializeConflictCopies() async {
    if (_pendingConflictCopies.isEmpty) return;
    final pending = List.of(_pendingConflictCopies.values);
    _pendingConflictCopies.clear();

    for (final p in pending) {
      final task = await _db.getTaskById(p.taskId);
      if (task == null) continue;

      // Keep the copy next to the original; fall back to root when the
      // parent is gone or removed (a subtree deletion removes it too).
      int? parentId;
      if (task.parentId != null) {
        final parent = await _db.getTaskById(task.parentId!);
        if (parent != null && parent.removed == 0) parentId = parent.id;
      }

      // A copy of a task hidden from AI agents must be hidden too. Copying
      // `flags` below already covers the ordinary case — the copy sits beside
      // the original and inherits from the same ancestors — but the fallback
      // above can lift it to the root, out from under the branch whose flag
      // was doing the hiding, and the copy carries the original's title and
      // content.
      var flags = task.flags;
      if (parentId == null &&
          task.parentId != null &&
          await _db.isTaskMcpExcluded(task.id)) {
        flags |= TaskFlags.mcpExcluded;
      }

      // Delete-vs-edit preserves the local values (soft delete keeps the row
      // intact); edit-vs-edit preserves the losing remote values, falling
      // back per field to the current value when only the other conflicted.
      final baseTitle =
          p.dueToRemoval ? task.title : (p.losingTitle ?? task.title);
      final content =
          p.dueToRemoval ? task.content : (p.losingContent ?? task.content);

      final now = DateTime.now();
      String two(int v) => v.toString().padLeft(2, '0');
      final stamp = '${now.year}-${two(now.month)}-${two(now.day)} '
          '${two(now.hour)}:${two(now.minute)}';
      final title = baseTitle.isEmpty
          ? '(conflict $stamp)'
          : '$baseTitle (conflict $stamp)';

      final copyWorldId = WorldId.create().value;
      await _db.createTask(
        parentId: parentId,
        worldId: copyWorldId,
        orderId: task.orderId,
        title: title,
        content: content,
        flags: flags,
      );
      final packet = _applyingPacket;
      _log?.add(
        SyncLogKind.conflictCopy,
        level: SyncLogLevel.warning,
        direction: 'in',
        originDevice: packet?.device,
        counter: packet?.counter,
        entityType: 'task',
        worldId: task.worldId,
        value: title,
        hasValue: false,
        message: p.dueToRemoval
            ? 'Deleted remotely while edited here: local text kept as a '
                'conflict copy'
            : 'Edited on both devices: the losing '
                '${[
                if (p.losingTitle != null) 'title',
                if (p.losingContent != null) 'content'
              ].join(' and ')} kept as a conflict copy',
        detail: {'copy_world_id': copyWorldId, 'copy_title': title},
      );
    }
  }

  // ============================================================
  // File Changes
  // ============================================================

  Future<_ApplyOutcome> _applyFileChange(SyncChange change) async {
    final localFile = await _db.getAttachmentByWorldId(change.worldId);

    if (localFile == null) {
      if (change.isCreation) {
        return _createFileFromRemote(change);
      }
      return _ApplyOutcome.orphaned;
    }

    final latest =
        await _db.getLatestFileHistoryForField(localFile.id, change.field);
    if (!await _remoteWins(change, latest?.timestamp,
        localValue: () => _localFileValue(localFile, change.field))) {
      return _ApplyOutcome.skipped;
    }
    return _applyFileField(localFile, change);
  }

  Future<_ApplyOutcome> _createFileFromRemote(SyncChange change) async {
    final existing = await _db.getAttachmentByWorldId(change.worldId);
    if (existing != null) {
      return _applyFileChange(change);
    }

    // Resolve parent task
    int? taskId;
    if (change.parentWorldId != null) {
      final task = await _db.getTaskByWorldId(change.parentWorldId!);
      taskId = task?.id;
    }
    // Files require a resolvable owning task; keep for retry until the task's
    // creation arrives.
    if (taskId == null) return _ApplyOutcome.orphaned;
    _noteChange(SyncLogKind.created);

    final newId = await _db.createAttachmentFromRemote(
      taskId: taskId,
      worldId: change.worldId,
      remoteTimestamp: change.timestamp,
    );
    final row = await _db.getAttachmentWithContent(newId);
    if (row == null) return _ApplyOutcome.skipped;
    return _applyFileField(row, change);
  }

  Future<_ApplyOutcome> _applyFileField(FileEntry file, SyncChange change) async {
    final ts = change.timestamp;
    switch (change.field) {
      case 'filename':
        await _db.updateAttachment(file.id, filename: change.value, remoteTimestamp: ts);
        return _ApplyOutcome.applied;
      case 'content':
        if (change.value == null) return _ApplyOutcome.applied;
        final ref = BlobRef.tryParse(change.value);
        if (ref == null) {
          // v2 form: the bytes travelled inline.
          await _db.updateAttachmentContent(
              file.id, base64Decode(change.value!), remoteTimestamp: ts);
          return _ApplyOutcome.applied;
        }
        // v3 form: a reference (§3.5). The bytes may already be here — this
        // device attached the same file elsewhere, or originated it — in
        // which case the reference resolves locally and no fetch is needed.
        // Otherwise the change is recorded now, at its origin time, and the
        // bytes follow from whichever node has them (_fetchMissingBlobs).
        final local = await _db.findBlobLocally(ref.id);
        if (local != null) {
          await _db.updateAttachmentContent(file.id, local, remoteTimestamp: ts);
        } else {
          _noteChange(SyncLogKind.blobPending,
              message: 'Content recorded; bytes of blob '
                  '${ref.id.substring(0, 12)}… still to download');
          await _db.markAttachmentPendingBlob(file.id, ref.id,
              remoteTimestamp: ts);
        }
        return _ApplyOutcome.applied;
      case 'orderId':
        final orderId = int.tryParse(change.value ?? '0') ?? 0;
        await _db.updateAttachment(file.id, orderId: orderId, remoteTimestamp: ts);
        return _ApplyOutcome.applied;
      case 'removed':
        final removed = int.tryParse(change.value ?? '0') ?? 0;
        if (removed == 1) {
          await _db.deleteAttachment(file.id, remoteTimestamp: ts);
        } else {
          await _db.undeleteAttachment(file.id, remoteTimestamp: ts);
        }
        return _ApplyOutcome.applied;
      default:
        _noteChange(SyncLogKind.unknownField,
            level: SyncLogLevel.warning,
            message: 'Unknown file field; ignored');
        return _ApplyOutcome.skipped;
    }
  }

  // ============================================================
  // Timeline Changes
  // ============================================================

  Future<_ApplyOutcome> _applyTimelineChange(SyncChange change) async {
    final localRecord = await _db.getTimeRecordByWorldId(change.worldId);

    if (localRecord == null) {
      if (change.isCreation) {
        return _createTimelineFromRemote(change);
      }
      return _ApplyOutcome.orphaned;
    }

    final latest =
        await _db.getLatestTimelineHistoryForField(localRecord.id, change.field);
    if (!await _remoteWins(change, latest?.timestamp,
        localValue: () => _localTimelineValue(localRecord, change.field))) {
      return _ApplyOutcome.skipped;
    }
    return _applyTimelineField(localRecord, change);
  }

  Future<_ApplyOutcome> _createTimelineFromRemote(SyncChange change) async {
    final existing = await _db.getTimeRecordByWorldId(change.worldId);
    if (existing != null) {
      return _applyTimelineChange(change);
    }

    // Resolve parent task by worldId
    int? taskId;
    if (change.parentWorldId != null) {
      final task = await _db.getTaskByWorldId(change.parentWorldId!);
      taskId = task?.id;
    }
    // Also check the value if field is taskId (which carries the task's worldId)
    if (taskId == null && change.field == 'taskId' && change.value != null) {
      final task = await _db.getTaskByWorldId(change.value!);
      taskId = task?.id;
    }
    // Timeline records require a resolvable owning task; keep for retry.
    if (taskId == null) return _ApplyOutcome.orphaned;
    _noteChange(SyncLogKind.created);

    // Placeholder startTime = the change's origin time; the real startTime
    // change (if this wasn't it) overwrites it via LWW. No local history is
    // recorded for the bare row, so sibling field changes apply cleanly.
    final startTime = change.field == 'startTime'
        ? (change.value ?? change.timestamp)
        : change.timestamp;

    final newId = await _db.createTimeRecordFromRemote(
      taskId: taskId,
      worldId: change.worldId,
      startTime: startTime,
      remoteTimestamp: change.timestamp,
    );
    final row = await _db.getTimeRecordById(newId);
    if (row == null) return _ApplyOutcome.skipped;
    return _applyTimelineField(row, change);
  }

  Future<_ApplyOutcome> _applyTimelineField(
      TimelineEntry record, SyncChange change) async {
    final ts = change.timestamp;
    switch (change.field) {
      case 'startTime':
        await _db.updateTimeRecord(record.id, startTime: change.value, remoteTimestamp: ts);
        return _ApplyOutcome.applied;
      case 'endTime':
        await _db.updateTimeRecord(record.id, endTime: change.value, remoteTimestamp: ts);
        return _ApplyOutcome.applied;
      case 'taskId':
        // Task association is fixed at creation; nothing to update.
        if (_note?.kind != SyncLogKind.created) {
          _noteChange(SyncLogKind.ignored,
              message: 'A time entry stays with the task it was created on');
        }
        return _ApplyOutcome.applied;
      case 'removed':
        final removed = int.tryParse(change.value ?? '0') ?? 0;
        if (removed == 1) {
          await _db.deleteTimeRecord(record.id, remoteTimestamp: ts);
        } else {
          await _db.undeleteTimeRecord(record.id, remoteTimestamp: ts);
        }
        return _ApplyOutcome.applied;
      default:
        _noteChange(SyncLogKind.unknownField,
            level: SyncLogLevel.warning,
            message: 'Unknown time entry field; ignored');
        return _ApplyOutcome.skipped;
    }
  }

  // ============================================================
  // Details summarization
  // ============================================================

  /// Group field-level [changes] by entity and resolve each group into a
  /// display-ready [SyncEntityChange] for the sync details view.
  Future<List<SyncEntityChange>> _summarizeChanges(
      List<SyncChange> changes) async {
    // Preserve first-seen order while grouping by entity identity.
    final order = <String>[];
    final groups = <String, List<SyncChange>>{};
    for (final c in changes) {
      final key = '${c.entityType}:${c.worldId}';
      final list = groups.putIfAbsent(key, () {
        order.add(key);
        return <SyncChange>[];
      });
      list.add(c);
    }

    // One cache for the whole run: the changes of a sync tend to share their
    // ancestors, and each would otherwise walk the same chain again.
    final rows = <int, TaskRow?>{};
    final result = <SyncEntityChange>[];
    for (final key in order) {
      final summary = await _summarizeEntity(groups[key]!, rows);
      if (summary != null) result.add(summary);
    }
    return result;
  }

  /// Titles of [task]'s ancestors, root first — or of [task] and its
  /// ancestors, with [includeSelf]. Read after the run has applied, so a moved
  /// node is already under its new parent.
  ///
  /// The walk is bounded: sync refuses to apply a parent change that would
  /// make a cycle, but a report must not hang on a database that has one
  /// anyway.
  Future<List<String>> _pathOf(
    TaskRow task,
    Map<int, TaskRow?> rows, {
    bool includeSelf = false,
  }) async {
    final titles = <String>[if (includeSelf) _titleOf(task)];
    var parentId = task.parentId;
    for (var hops = 0; parentId != null && hops < 256; hops++) {
      final parent = rows.containsKey(parentId)
          ? rows[parentId]
          : rows[parentId] = await _db.getTaskById(parentId);
      if (parent == null) break;
      titles.add(_titleOf(parent));
      parentId = parent.parentId;
    }
    return titles.reversed.toList();
  }

  static String _titleOf(TaskRow task) {
    final title = task.title.trim();
    return title.isEmpty ? 'Untitled' : title;
  }

  /// The last change for [field] in [group], or null if that field is absent.
  SyncChange? _lastField(List<SyncChange> group, String field) {
    SyncChange? found;
    for (final c in group) {
      if (c.field == field) found = c;
    }
    return found;
  }

  /// Classify a group of field changes into create / remove / update. A
  /// `removed → 1` wins (the entity is gone regardless of other fields); a
  /// creation flag on any field marks a create; otherwise it's an update.
  SyncEntityChangeKind _kindOf(List<SyncChange> group) {
    final removed = _lastField(group, 'removed');
    if (removed != null && removed.value == '1') {
      return SyncEntityChangeKind.removed;
    }
    if (group.any((c) => c.isCreation)) return SyncEntityChangeKind.created;
    return SyncEntityChangeKind.updated;
  }

  /// Format an ISO-8601 (or best-effort) timestamp as local HH:mm; falls back
  /// to the raw string when it can't be parsed.
  String _fmtTime(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    final local = dt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<SyncEntityChange?> _summarizeEntity(
      List<SyncChange> group, Map<int, TaskRow?> rows) async {
    switch (group.first.entityType) {
      case 'task':
        return _summarizeTask(group, rows);
      case 'file':
        return _summarizeFile(group, rows);
      case 'timeline':
        return _summarizeTimeline(group, rows);
      default:
        return null;
    }
  }

  Future<SyncEntityChange> _summarizeTask(
      List<SyncChange> group, Map<int, TaskRow?> rows) async {
    final worldId = group.first.worldId;
    final task = await _db.getTaskByWorldId(worldId);
    final titleChange = _lastField(group, 'title');
    var name = (task?.title.isNotEmpty ?? false) ? task!.title : titleChange?.value;
    if (name == null || name.isEmpty) name = 'Untitled';

    final kind = _kindOf(group);
    final moved = _lastField(group, 'parentId') != null;
    String? detail;
    if (kind == SyncEntityChangeKind.updated) {
      final parts = <String>[];
      if (titleChange != null) parts.add('renamed to "${titleChange.value ?? ''}"');
      if (_lastField(group, 'content') != null) parts.add('content edited');
      if (moved) parts.add('moved');
      if (_lastField(group, 'orderId') != null) parts.add('reordered');
      if (_lastField(group, 'flags') != null) parts.add('flags changed');
      if (parts.isNotEmpty) detail = parts.join(', ');
    }

    final path = task == null ? null : await _pathOf(task, rows);

    return SyncEntityChange(
      entityType: 'task',
      kind: kind,
      label: 'Node "$name"',
      detail: detail,
      // A top-level node needs no path, unless it just moved there.
      path: (path?.isNotEmpty ?? false) || (moved && path != null) ? path : null,
    );
  }

  Future<SyncEntityChange> _summarizeFile(
      List<SyncChange> group, Map<int, TaskRow?> rows) async {
    final file = await _db.getAttachmentByWorldId(group.first.worldId);
    final nameChange = _lastField(group, 'filename');
    var name = file?.filename ?? nameChange?.value;
    if (name == null || name.isEmpty) name = 'file';

    final kind = _kindOf(group);
    String? detail;
    if (kind == SyncEntityChangeKind.updated) {
      final parts = <String>[];
      if (nameChange != null) parts.add('renamed');
      if (_lastField(group, 'content') != null) parts.add('content updated');
      if (_lastField(group, 'orderId') != null) parts.add('reordered');
      if (parts.isNotEmpty) detail = parts.join(', ');
    }

    final owner = file == null ? null : await _db.getTaskById(file.taskId);

    return SyncEntityChange(
      entityType: 'file',
      kind: kind,
      label: 'File "$name"',
      detail: detail,
      path: owner == null ? null : await _pathOf(owner, rows, includeSelf: true),
    );
  }

  Future<SyncEntityChange> _summarizeTimeline(
      List<SyncChange> group, Map<int, TaskRow?> rows) async {
    // The owning task is carried on parentWorldId (or the taskId field value).
    String? taskWorldId;
    for (final c in group) {
      taskWorldId ??= c.parentWorldId;
      if (c.field == 'taskId') taskWorldId ??= c.value;
    }
    final task =
        taskWorldId == null ? null : await _db.getTaskByWorldId(taskWorldId);

    final kind = _kindOf(group);
    final start = _lastField(group, 'startTime')?.value;
    final end = _lastField(group, 'endTime')?.value;

    String? range;
    if (start != null && end != null) {
      range = '${_fmtTime(start)}–${_fmtTime(end)}';
    } else if (start != null) {
      range = 'from ${_fmtTime(start)}';
    } else if (end != null) {
      range = 'until ${_fmtTime(end)}';
    }

    // The detail is the time range; the owning task is the end of the path.
    final detail = kind == SyncEntityChangeKind.removed ? null : range;

    return SyncEntityChange(
      entityType: 'timeline',
      kind: kind,
      label: 'Time chunk',
      detail: detail,
      path: task == null ? null : await _pathOf(task, rows, includeSelf: true),
    );
  }

}
