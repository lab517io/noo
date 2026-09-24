import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' show Value;

import '../../domain/entities/sync_packet.dart' show BlobRef;
import '../database/database.dart';

/// Severity of a sync-log event.
enum SyncLogLevel { info, warning, error }

/// Event kinds written to the sync log. Strings, not an enum: they are stored,
/// searched and exported, and an old log must stay readable after a kind is
/// added or retired.
abstract final class SyncLogKind {
  // Exchange
  static const exchangeStart = 'exchange-start';
  static const streamVerify = 'stream-verify';
  static const forkCheck = 'fork-check';

  // Outgoing
  static const packaged = 'packaged';
  static const outgoing = 'change-out';
  static const pushed = 'pushed';
  static const pushBlocked = 'push-blocked';
  static const blobUploaded = 'blob-uploaded';
  static const served = 'packet-served';
  static const serveVector = 'vector-served';
  static const serveHashes = 'hashes-served';
  static const serveBlob = 'blob-served';

  // Incoming packets
  static const packetStored = 'packet-stored';
  static const packetDuplicate = 'packet-duplicate';
  static const packetDiverged = 'packet-diverged';
  static const packetDeferred = 'packet-deferred';
  static const packetApplied = 'packet-applied';
  static const decodeFailed = 'decode-failed';
  static const applyFailed = 'apply-failed';
  static const snapshotAdopted = 'snapshot-adopted';

  // Per-change decisions
  static const applied = 'applied';
  static const created = 'created';
  static const lwwLost = 'lww-lost';
  static const lwwTie = 'lww-tie';
  static const orphaned = 'orphaned';
  static const orphanExpired = 'orphan-expired';
  static const conflictCopy = 'conflict-copy';
  static const cycleToRoot = 'cycle-to-root';
  static const parentMissing = 'parent-missing';
  static const ignored = 'ignored';
  static const unknownField = 'unknown-field';
  static const blobPending = 'blob-pending';

  // Attachments
  static const blobFetched = 'blob-fetched';
  static const blobFetchFailed = 'blob-fetch-failed';
  static const blobsWaiting = 'blobs-waiting';

  // Peer requests
  static const syncRequested = 'sync-requested';

  // Maintenance
  static const compaction = 'compaction';
  static const identityReset = 'identity-reset';
  static const note = 'note';

  /// Routine per-change decisions. For full-state packets these are counted
  /// rather than logged one by one — a snapshot carries every field of the
  /// database, and what matters in it is the exceptions.
  static const routine = {applied, created, lwwLost, blobPending, outgoing};
}

/// Writes the sync log (tables `sync_log_runs` / `sync_log_events`).
///
/// One journal per open database. Logging is diagnostics: every write is
/// best-effort, and a failure to log never fails a sync.
class SyncJournal {
  final NooDatabase _db;

  SyncJournal(this._db);

  /// Retention: runs older than this, or beyond [maxRuns], are pruned when a
  /// run starts (at most once per [_pruneInterval]).
  static const Duration retention = Duration(days: 30);
  static const int maxRuns = 200;
  static const Duration _pruneInterval = Duration(hours: 1);

  final Set<int> _active = {};
  DateTime? _lastPrune;

  NooDatabase get database => _db;

  /// Start a run. Never throws: when the log cannot be written the run is
  /// detached and silently discards its events.
  Future<SyncLogRun> begin(
    String trigger, {
    String? remote,
    String deviceId = '',
  }) async {
    try {
      await _housekeep();
      final id = await _db.startSyncLogRun(
        trigger: trigger,
        remote: remote,
        deviceId: deviceId,
      );
      _active.add(id);
      return SyncLogRun._(this, id);
    } catch (_) {
      return SyncLogRun._(this, null);
    }
  }

  Future<void> _housekeep() async {
    final now = DateTime.now();
    final last = _lastPrune;
    if (last != null && now.difference(last) < _pruneInterval) return;
    _lastPrune = now;
    // Anything still "running" that this journal did not start belongs to a
    // process that ended mid-run.
    if (last == null) await _db.closeAbandonedSyncLogRuns(_active);
    await _db.pruneSyncLog(
      beforeIso: NooDatabase.formatIso(now.subtract(retention)),
      keepRuns: maxRuns,
    );
  }

  /// A short, stable fingerprint of a field value: the first 16 hex digits of
  /// its SHA-256. Enough to tell two devices' values apart in a log.
  static String? valueHash(String? value) => value == null
      ? null
      : sha256.convert(utf8.encode(value)).toString().substring(0, 16);

  static const int previewLength = 80;

  /// What a log shows of a value: a single-line prefix for text, a reference
  /// or size for attachment content.
  static String? valuePreview(String entityType, String field, String? value) {
    if (value == null) return null;
    if (entityType == 'file' && field == 'content') {
      final ref = BlobRef.tryParse(value);
      if (ref != null) return 'blob ${ref.id.substring(0, 12)}…';
      return 'inline ${(value.length * 3) ~/ 4} bytes';
    }
    final line = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (line.length <= previewLength) return line;
    return '${line.substring(0, previewLength)}…';
  }

  void _ended(int id) => _active.remove(id);
}

/// One run of the sync log. Events are buffered and written at [flush] — the
/// caller flushes after each packet commits, and [rollbackTo] drops what a
/// rolled-back packet had logged, so the log never claims what did not happen.
class SyncLogRun {
  final SyncJournal _journal;

  /// Row id, or null for a detached run whose log could not be opened.
  final int? id;

  SyncLogRun._(this._journal, this.id);

  final List<SyncLogEventsCompanion> _buffer = [];
  final List<({String key, int n})> _tallies = [];
  final Map<String, int> _counts = {};
  int _seq = 0;
  bool _finished = false;

  /// Counters so far (flushed and buffered).
  Map<String, int> get counts {
    final all = Map.of(_counts);
    for (final t in _tallies) {
      all[t.key] = (all[t.key] ?? 0) + t.n;
    }
    return all;
  }

  void add(
    String kind, {
    SyncLogLevel level = SyncLogLevel.info,
    String direction = 'local',
    String? originDevice,
    int? counter,
    String? packetHash,
    String? entityType,
    String? worldId,
    String? field,
    String? remoteTs,
    String? localTs,
    String? value,
    bool hasValue = false,
    String? message,
    Map<String, Object?>? detail,
  }) {
    if (id == null) return;
    _tally(kind);
    if (level == SyncLogLevel.warning) _tally('warnings');
    if (level == SyncLogLevel.error) _tally('errors');
    _buffer.add(
      SyncLogEventsCompanion.insert(
        runId: id!,
        seq: _seq++,
        at: NooDatabase.nowIso(),
        level: Value(level.index),
        kind: kind,
        direction: Value(direction),
        originDevice: Value(originDevice),
        counter: Value(counter),
        packetHash: Value(packetHash),
        entityType: Value(entityType),
        worldId: Value(worldId),
        field: Value(field),
        remoteTs: Value(remoteTs),
        localTs: Value(localTs),
        valueHash: Value(hasValue ? SyncJournal.valueHash(value) : null),
        valuePreview: Value(
          hasValue && entityType != null && field != null
              ? SyncJournal.valuePreview(entityType, field, value)
              : null,
        ),
        message: Value(message),
        detailJson: Value(detail == null ? null : jsonEncode(detail)),
      ),
    );
  }

  /// Count something without logging an event for it.
  void tally(String key, [int n = 1]) {
    if (id == null || n == 0) return;
    _tally(key, n);
  }

  void _tally(String key, [int n = 1]) => _tallies.add((key: key, n: n));

  /// A position to roll back to.
  (int, int) get mark => (_buffer.length, _tallies.length);

  /// Forget everything added since [mark] — the packet it described rolled back.
  void rollbackTo((int, int) mark) {
    if (_buffer.length > mark.$1) _buffer.removeRange(mark.$1, _buffer.length);
    if (_tallies.length > mark.$2) {
      _tallies.removeRange(mark.$2, _tallies.length);
    }
  }

  /// Write buffered events.
  Future<void> flush() async {
    if (id == null || (_buffer.isEmpty && _tallies.isEmpty)) return;
    final events = List.of(_buffer);
    _buffer.clear();
    for (final t in _tallies) {
      _counts[t.key] = (_counts[t.key] ?? 0) + t.n;
    }
    _tallies.clear();
    try {
      await _journal._db.insertSyncLogEvents(events);
      await _journal._db.updateSyncLogRun(id!, countsJson: jsonEncode(_counts));
    } catch (_) {
      // Diagnostics only.
    }
  }

  /// Flush and record the outcome. A run may be finished more than once — a
  /// peer's session with us is re-stamped after every request it makes.
  Future<void> finish({
    String outcome = 'ok',
    String? error,
    String? remote,
  }) async {
    if (id == null) return;
    await flush();
    try {
      await _journal._db.updateSyncLogRun(
        id!,
        outcome: outcome,
        error: error,
        remote: remote,
        countsJson: jsonEncode(_counts),
        finished: true,
      );
    } catch (_) {
      // Diagnostics only.
    }
    if (!_finished) {
      _finished = true;
      _journal._ended(id!);
    }
  }
}
