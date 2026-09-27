import 'dart:convert';
import 'dart:io';
// import 'dart:nativewrappers/_internal/vm/lib/math_patch.dart';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/utils/diff_utils.dart';
import '../../domain/entities/sync_packet.dart' show BlobRef;
import '../../domain/entities/task.dart' show TaskFlags;
import 'tables.dart';

part 'database.g.dart';

/// Outcome of [NooDatabase.storeSyncPacket] under the v2 insertion rule.
///
/// [conflict] is the slot rule's blind spot made visible: the slot is held,
/// but by *different bytes*. Under §5.2 alone that arrival is indistinguishable
/// from the duplicate a multi-path delivery produces, and is silently dropped;
/// with the content hash it is what it actually is — two versions of one packet
/// identity, i.e. a forked stream (docs/P2P_SYNC.md §3.3).
enum SyncPacketStoreResult { stored, duplicate, gap, conflict }

/// A task reduced to the fields a tree of titles needs — see
/// [NooDatabase.getTaskOutline].
class TaskOutlineRow {
  final int id;
  final int? parentId;
  final String title;
  final int flags;

  const TaskOutlineRow({
    required this.id,
    required this.parentId,
    required this.title,
    required this.flags,
  });
}

@DriftDatabase(tables: [
  Tasks,
  Timeline,
  Files,
  Properties,
  HistoryTask,
  HistoryFile,
  HistoryTimeline,
  Syncs,
  SyncPackets,
  SyncOrphans,
  SyncPushLog,
  BlobFetches,
  SyncLogRuns,
  SyncLogEvents,
])
class NooDatabase extends _$NooDatabase {
  NooDatabase._(super.e);

  /// Create database from a specific file path
  factory NooDatabase.fromPath(String path, {String? password}) {
    return NooDatabase._(_openConnection(path, password));
  }

  /// Create database with default path
  static Future<NooDatabase> open({String? filename, String? password}) async {
    final dbPath = await _getDefaultPath(filename ?? 'database.noo');
    return NooDatabase.fromPath(dbPath, password: password);
  }

  /// In-memory database for tests (no encryption, no file).
  factory NooDatabase.memory() => NooDatabase._(NativeDatabase.memory());

  @override
  int get schemaVersion => 14;

  /// Current UTC time as a fixed-width ISO8601 string (always 6 fractional
  /// digits). Fixed width means lexicographic string comparison agrees with
  /// chronological order — `toIso8601String()` emits 3 or 6 digits depending
  /// on the sub-second value, which breaks ordering at the boundary.
  static String nowIso() => formatIso(DateTime.now());

  /// Normalize any DateTime (or a parsed timestamp) to the fixed-width form.
  static String formatIso(DateTime dt) {
    final u = dt.toUtc();
    String p(int v, int w) => v.toString().padLeft(w, '0');
    final frac = p(u.millisecond, 3) + p(u.microsecond, 3);
    return '${p(u.year, 4)}-${p(u.month, 2)}-${p(u.day, 2)}'
        'T${p(u.hour, 2)}:${p(u.minute, 2)}:${p(u.second, 2)}.${frac}Z';
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          // Insert default schema version
          await into(properties).insert(
            PropertiesCompanion.insert(type: 'version', value: '0'),
          );
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Migration from version 1 to 2: Add history and sync tables
          if (from < 2) {
            await m.createTable(historyTask);
            await m.createTable(historyFile);
            await m.createTable(historyTimeline);
            await m.createTable(syncs);
          }
          // Migration from version 2 to 3: Rename html column to content
          if (from < 3) {
            await customStatement('ALTER TABLE tasks RENAME COLUMN html TO content');
          }
          // Migration from version 3 to 4: Add worldId to history tables for sync.
          // Skipped when coming from v1: createTable above already created the
          // history tables with the current schema (world_id included), so the
          // ALTER would fail with "duplicate column name".
          if (from >= 2 && from < 4) {
            await customStatement(
                "ALTER TABLE history_task ADD COLUMN world_id TEXT NOT NULL DEFAULT ''");
            await customStatement(
                "ALTER TABLE history_file ADD COLUMN world_id TEXT NOT NULL DEFAULT ''");
            await customStatement(
                "ALTER TABLE history_timeline ADD COLUMN world_id TEXT NOT NULL DEFAULT ''");
            // Backfill worldId from entity tables
            await customStatement('''
              UPDATE history_task SET world_id = (
                SELECT tasks.world_id FROM tasks WHERE tasks.id = history_task.task_id
              ) WHERE world_id = ''
            ''');
            await customStatement('''
              UPDATE history_file SET world_id = (
                SELECT file.world_id FROM file WHERE file.id = history_file.file_id
              ) WHERE world_id = ''
            ''');
            await customStatement('''
              UPDATE history_timeline SET world_id = (
                SELECT timeline.world_id FROM timeline WHERE timeline.id = history_timeline.timeline_id
              ) WHERE world_id = ''
            ''');
          }
          // Migration to version 5: mark remote-origin history rows so they
          // are excluded from push. Existing rows default to local (0).
          //
          // Added idempotently: a Syncthing-synced database can arrive with the
          // columns already present but user_version still at 4 (the schema and
          // the version counter are synced/merged independently), which would
          // otherwise fail the migration with "duplicate column name".
          if (from < 5) {
            await _addColumnIfMissing(
                'history_task', 'is_remote', 'INTEGER NOT NULL DEFAULT 0');
            await _addColumnIfMissing(
                'history_file', 'is_remote', 'INTEGER NOT NULL DEFAULT 0');
            await _addColumnIfMissing(
                'history_timeline', 'is_remote', 'INTEGER NOT NULL DEFAULT 0');
          }
          // Migration to version 6: sync protocol v2 (per-device packet
          // streams, see docs/P2P_SYNC.md). Adds the packet store and orphan
          // retry tables, drops v1 sync state (global-sequence cursor and push
          // watermarks — v2 is a clean epoch break), and flags the database
          // for a one-time full re-package on the next sync so current state
          // is re-announced as a fresh v2 stream.
          if (from < 6) {
            await m.createTable(syncPackets);
            await m.createTable(syncOrphans);
            await customStatement(
                "DELETE FROM properties WHERE type IN ("
                "'sync_last_sequence', 'sync_pushed_task_hid', "
                "'sync_pushed_file_hid', 'sync_pushed_timeline_hid')");
            await customStatement(
                "INSERT OR REPLACE INTO properties (type, value) "
                "VALUES ('sync_v2_repackage_needed', '1')");
          }
          // Migration to version 7: indexes. The schema had none, so every
          // world-id lookup and every field-level LWW lookup was a full table
          // scan — the dominant cost of applying a sync packet, and the reason
          // a first sync of a modest database takes seconds. Purely additive:
          // no data is touched and older builds ignore the indexes.
          if (from < 7) {
            for (final index in allSchemaEntities.whereType<Index>()) {
              await _createIndexIfMissing(index);
            }
          }
          // Migration to version 8: per-own-packet push log, consulted by the
          // conflict-copy check. Additive; packets sent before the upgrade
          // simply have no entry, and the check falls back to its conservative
          // path for them.
          if (from < 8) {
            await m.createTable(syncPushLog);
          }
          // Migration to version 9: drop the redundant full old text from
          // title/content history rows (each stored the complete previous
          // value next to the patch — costing more than full-value storage
          // would have). Each chain's base row keeps its old value; replay
          // reconstructs the rest. Data-only, no schema change; freed pages
          // are reclaimed on a later VACUUM.
          if (from < 9) {
            await compactTaskHistoryOldValues();
          }

          // Migration to version 10: give every stored packet its content
          // hash, so an occupied slot can be checked rather than assumed
          // (docs/P2P_SYNC.md §3.3, §5.2). Backfilled here rather than lazily:
          // a hash that only some rows carry cannot answer "do we hold the
          // same stream", which is the whole point of the column.
          if (from < 10) {
            await _addColumnIfMissing(
                'sync_packets', 'payload_hash', "TEXT NOT NULL DEFAULT ''");
            await backfillSyncPacketHashes();
          }

          // Migration to version 11: attachments get a content hash, which is
          // their identity in the sync blob store (docs/P2P_SYNC.md §3.5).
          // Backfilled so every existing attachment can be referenced and
          // served by hash from the first v3 packet on.
          if (from < 11) {
            await _addColumnIfMissing(
                'file', 'content_hash', "TEXT NOT NULL DEFAULT ''");
            await _createIndexIfMissing(idxFileContentHash);
            await backfillFileContentHashes();
          }

          // Migration to version 12: replace the inlined base64 in
          // `history_file` content rows with the blob reference the row
          // already means (docs/P2P_SYNC.md §3.5). Before this, every
          // attachment version was stored whole in its history row — on both
          // sides of an update — so a k-times-edited attachment cost 2k+2
          // copies of itself. The bytes live in the `file` table and in the
          // blob store; history only has to say *which* blob. Same shape as
          // the v9 task-history compaction: keep the row, drop the payload.
          // Data-only, no schema change; freed pages return on a VACUUM.
          if (from < 12) {
            await compactFileHistoryContent();
          }

          // Migration to version 13: somewhere to keep a half-fetched blob.
          // Attachments used to arrive in one request that either finished or
          // was thrown away; a phone on a bad connection could therefore
          // never finish a large one. Accumulating the ciphertext here makes
          // the transfer resumable across exchanges and restarts
          // (docs/P2P_SYNC.md §3.5).
          if (from < 13) {
            await m.createTable(blobFetches);
          }
          // The sync log: a persistent record of every run's packets and
          // merge decisions, for diagnosing devices that disagree.
          if (from < 14) {
            await m.createTable(syncLogRuns);
            await m.createTable(syncLogEvents);
            for (final index in allSchemaEntities.whereType<Index>()) {
              if (index.entityName.startsWith('idx_sync_log_')) {
                await _createIndexIfMissing(index);
              }
            }
          }
        },
        beforeOpen: (details) async {
          // Enable foreign keys
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Creates [index] unless it already exists.
  ///
  /// `Migrator.createIndex` issues a bare `CREATE INDEX`, which throws against
  /// a database that already carries the index but still records an older
  /// `user_version` — the Syncthing-merge case [_addColumnIfMissing] guards
  /// against. Re-using the generated statement keeps the annotation in
  /// `tables.dart` the single definition of each index.
  Future<void> _createIndexIfMissing(Index index) async {
    final sql = index.createStatementsByDialect[SqlDialect.sqlite];
    if (sql == null) return;
    await customStatement(
      sql.replaceFirst('CREATE INDEX ', 'CREATE INDEX IF NOT EXISTS '),
    );
  }

  /// Adds [column] to [table] only if it isn't already present, so a migration
  /// step is safe to re-run against a database whose schema is ahead of its
  /// recorded `user_version` (e.g. after a Syncthing merge).
  Future<void> _addColumnIfMissing(
      String table, String column, String definition) async {
    final existing = await customSelect(
      "SELECT 1 FROM pragma_table_info('$table') WHERE name = '$column'",
    ).get();
    if (existing.isEmpty) {
      await customStatement('ALTER TABLE $table ADD COLUMN $column $definition');
    }
  }

  static Future<String> _getDefaultPath(String filename) async {
    final appDir = await getApplicationDocumentsDirectory();
    final nooDir = Directory(p.join(appDir.path, 'noo'));
    if (!await nooDir.exists()) {
      await nooDir.create(recursive: true);
    }
    return p.join(nooDir.path, filename);
  }

  /// Derives the encryption key from the user password.
  /// Uses SHA256 hash + base64 encoding for consistent key format.
  static String _deriveKey(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return base64.encode(hash.bytes);
  }

  static QueryExecutor _openConnection(String path, String? password) {
    // Use direct NativeDatabase instead of createInBackground to avoid
    // isolate communication overhead (~30ms per query)
    final native = NativeDatabase(
      File(path),
      setup: (db) {
        // Guard against the loader having resolved plain sqlite3 instead of
        // the bundled SQLCipher (e.g. the macOS fallback to
        // DynamicLibrary.process() picking /usr/lib/libsqlite3.dylib). Plain
        // sqlite returns no rows for this pragma; failing here prevents
        // silently creating an *unencrypted* database or misreporting a good
        // password as wrong.
        final cipherVersion = db.select('PRAGMA cipher_version');
        if (cipherVersion.isEmpty) {
          throw StateError(
              'SQLCipher library not loaded: PRAGMA cipher_version returned '
              'nothing, so the process is using plain sqlite3. Refusing to '
              'open the database.');
        }

        // Apply SQLCipher encryption key if provided
        if (password != null && password.isNotEmpty) {
          final key = _deriveKey(password);
          // NB: never log the derived key — it is the at-rest encryption
          // secret. Logging it would defeat SQLCipher for anyone with log
          // access.
          db.execute("PRAGMA key = '$key'");
        }

        // Performance settings matching Qt implementation
        db.execute('PRAGMA locking_mode = EXCLUSIVE');
        db.execute('PRAGMA journal_mode = MEMORY');
        db.execute('PRAGMA temp_store = MEMORY');
      },
    );
    return native;
  }

  // ============================================================
  // Database Verification
  // ============================================================

  /// Verify the database is accessible (password is correct)
  /// Returns true if database is valid, false if password is wrong or DB corrupted
  Future<bool> verifyAccess() async {
    try {
      // Try to query sqlite_master - this will fail if password is wrong
      await customSelect('SELECT count(*) FROM sqlite_master').get();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // WorldId Lookups (for sync)
  // ============================================================

  /// Get a task by its worldId
  Future<TaskRow?> getTaskByWorldId(String worldId) {
    return (select(tasks)..where((t) => t.worldId.equals(worldId)))
        .getSingleOrNull();
  }

  /// Get a time record by its worldId
  Future<TimelineEntry?> getTimeRecordByWorldId(String worldId) {
    return (select(timeline)..where((t) => t.worldId.equals(worldId)))
        .getSingleOrNull();
  }

  /// Get an attachment by its worldId
  Future<FileEntry?> getAttachmentByWorldId(String worldId) {
    return (select(files)..where((f) => f.worldId.equals(worldId)))
        .getSingleOrNull();
  }

  // ============================================================
  // Task Operations
  // ============================================================

  /// Get all top-level tasks (no parent)
  Future<List<TaskRow>> getTopLevelTasks() {
    return (select(tasks)
          ..where((t) => t.parentId.isNull() & t.removed.equals(0))
          ..orderBy([(t) => OrderingTerm.asc(t.orderId)]))
        .get();
  }

  /// Every task row including soft-removed ones (full-state re-package).
  Future<List<TaskRow>> getAllTaskRows() => select(tasks).get();

  /// Every file row including soft-removed ones (full-state re-package).
  Future<List<FileEntry>> getAllFileRows() => select(files).get();

  /// Every timeline row including soft-removed ones (full-state re-package).
  Future<List<TimelineEntry>> getAllTimelineRows() => select(timeline).get();

  /// Get every non-removed task in the database (any depth).
  Future<List<TaskRow>> getAllTasks() {
    return (select(tasks)
          ..where((t) => t.removed.equals(0))
          ..orderBy([(t) => OrderingTerm.asc(t.orderId)]))
        .get();
  }

  /// Get child tasks for a parent
  Future<List<TaskRow>> getChildTasks(int parentId) {
    return (select(tasks)
          ..where((t) => t.parentId.equals(parentId) & t.removed.equals(0))
          ..orderBy([(t) => OrderingTerm.asc(t.orderId)]))
        .get();
  }

  /// Get a single task by ID
  Future<TaskRow?> getTaskById(int id) {
    return (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Every non-removed task as just the fields a tree outline needs.
  ///
  /// Not [getAllTasks]: that carries `content`, which is the note body of
  /// every task in the database — tens of megabytes on a large outline, read
  /// and decrypted to render a list of titles. Ordered by `orderId` so
  /// grouping the result by parent yields each parent's children in order.
  Future<List<TaskOutlineRow>> getTaskOutline() async {
    final rows = await customSelect(
      'SELECT id, parent_id, title, flags FROM tasks '
      'WHERE removed = 0 ORDER BY order_id ASC',
      readsFrom: {tasks},
    ).get();

    return [
      for (final row in rows)
        TaskOutlineRow(
          id: row.read<int>('id'),
          parentId: row.readNullable<int>('parent_id'),
          title: row.read<String>('title'),
          flags: row.read<int>('flags'),
        ),
    ];
  }

  /// Every task marked as the root of a branch hidden from AI agents.
  ///
  /// Only the marked rows: the descendants they hide carry no flag of their
  /// own, and listing them would turn "three hidden branches" into a page of
  /// tasks in the preferences tab.
  ///
  /// Unindexed by design: this runs when the preferences tab opens, not per
  /// MCP request, and an index over a bitfield nothing else filters on would
  /// cost every task write for one screen.
  Future<List<TaskRow>> getMcpExcludedTasks() {
    return (select(tasks)
          ..where((t) =>
              t.removed.equals(0) &
              t.flags
                  .bitwiseAnd(const Constant(TaskFlags.mcpExcluded))
                  .isBiggerThanValue(0))
          ..orderBy([(t) => OrderingTerm.asc(t.orderId)]))
        .get();
  }

  /// Longest ancestor walk before a corrupt parent cycle is assumed.
  ///
  /// Matches `McpLimits.maxPathDepth`; kept here so the data layer does not
  /// reach into an MCP constant for a rule about its own tree.
  static const int maxAncestorWalk = 64;

  /// Whether the task [id] sits in a branch excluded from agent access —
  /// either carrying [TaskFlags.mcpExcluded] itself or descending from one
  /// that does.
  ///
  /// The canonical answer. `McpTaskApi._isHidden` is the same walk with a
  /// per-request row cache, because it asks this of hundreds of rows at a
  /// time; anything asking about a single task should come here.
  Future<bool> isTaskMcpExcluded(int id) async {
    var row = await getTaskById(id);
    var hops = 0;

    while (row != null && hops < maxAncestorWalk) {
      if ((row.flags & TaskFlags.mcpExcluded) != 0) return true;
      final parentId = row.parentId;
      if (parentId == null) return false;
      row = await getTaskById(parentId);
      hops++;
    }
    return false;
  }

  /// Hide or reveal the branch rooted at [id] for the MCP server.
  ///
  /// Goes through [updateTask] rather than writing `flags` directly so the
  /// change records a history row and reaches the user's other devices — a
  /// branch hidden here has to stay hidden from the agents there too.
  Future<bool> setTaskMcpExcluded(int id, bool excluded) async {
    final row = await getTaskById(id);
    if (row == null) return false;

    final flags = excluded
        ? row.flags | TaskFlags.mcpExcluded
        : row.flags & ~TaskFlags.mcpExcluded;
    if (flags == row.flags) return true;

    return updateTask(id, flags: flags);
  }

  /// Search tasks by title and content.
  ///
  /// This is a *prefilter*: it requires every whitespace-separated token of the
  /// query to appear somewhere in the title or the raw content. That is looser
  /// than a single contiguous LIKE over the whole phrase, so a phrase split
  /// across Quill formatting boundaries in the stored Delta JSON still passes
  /// (the caller does the authoritative plaintext phrase match on the results).
  /// The old code applied a hard LIMIT here, before that plaintext filter, so
  /// structural matches could crowd out real ones — the cap is deliberately
  /// generous and the real limiting happens after plaintext extraction.
  Future<List<TaskRow>> searchTasks(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    final tokens =
        trimmed.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    return (select(tasks)
          ..where((t) {
            var pred = t.removed.equals(0);
            for (final token in tokens) {
              final pattern = '%$token%';
              pred = pred & (t.title.like(pattern) | t.content.like(pattern));
            }
            return pred;
          })
          ..limit(500))
        .get();
  }

  /// Create a new task. The row insert and its creation-history rows run in one
  /// transaction so a crash can't leave an entity with no creation history
  /// (which sync would then never send).
  Future<int> createTask({
    int? parentId,
    required String worldId,
    int orderId = 0,
    String title = '',
    String? content,
    int flags = 0,
  }) async {
    return transaction(() async {
      final taskId = await into(tasks).insert(
        TasksCompanion.insert(
          parentId: Value(parentId),
          worldId: Value(worldId),
          orderId: Value(orderId),
          title: Value(title),
          content: Value(content),
          flags: Value(flags),
          timestamp: nowIso(),
        ),
      );

      // Record history for creation (oldValue = null for all fields)
      await insertTaskHistory(taskId: taskId, field: 'title', newValue: title);
      if (content != null) {
        await insertTaskHistory(taskId: taskId, field: 'content', newValue: content);
      }
      if (parentId != null) {
        await insertTaskHistory(
            taskId: taskId, field: 'parentId', newValue: parentId.toString());
      }
      await insertTaskHistory(
          taskId: taskId, field: 'orderId', newValue: orderId.toString());
      await insertTaskHistory(
          taskId: taskId, field: 'flags', newValue: flags.toString());

      return taskId;
    });
  }

  /// Update task metadata.
  /// Use [clearParent] = true to set parentId to null (move to root).
  /// [remoteTimestamp], when set, marks this as an applied remote change: the
  /// row and history rows are stamped with that origin time and the history is
  /// flagged remote so it is not pushed back.
  Future<bool> updateTask(int id, {
    String? title,
    String? content,
    int? orderId,
    int? parentId,
    bool clearParent = false,
    int? flags,
    String? remoteTimestamp,
  }) async {
    final bool isRemote = remoteTimestamp != null;
    final String rowTs =
        isRemote ? formatIso(DateTime.parse(remoteTimestamp)) : nowIso();
    return transaction(() async {
      // Fetch old state for history recording
      final oldTask = await getTaskById(id);
      if (oldTask == null) return false;

      Value<int?> parentIdValue;
      if (clearParent) {
        parentIdValue = const Value(null);
      } else if (parentId != null) {
        parentIdValue = Value(parentId);
      } else {
        parentIdValue = const Value.absent();
      }

      final rowsUpdated = await (update(tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          title: title != null ? Value(title) : const Value.absent(),
          content: content != null ? Value(content) : const Value.absent(),
          orderId: orderId != null ? Value(orderId) : const Value.absent(),
          parentId: parentIdValue,
          flags: flags != null ? Value(flags) : const Value.absent(),
          timestamp: Value(rowTs),
        ),
      );

      if (rowsUpdated > 0) {
        // Record history for changed fields.
        //
        // Diff fields (title, content) store a dmp patch in newValue, not the
        // full text. oldValue is NOT the full previous text — that would cost
        // more than storing the new value whole. Instead:
        //  - '' when the field already has history: old values are
        //    reconstructable by replaying the patch chain from its base
        //    (HistoryService.reconstructTaskFieldChain).
        //  - the full previous value only when this is the field's first
        //    history row (task created from remote records no creation row),
        //    anchoring the chain.
        // Never null — oldValue == null is what marks a creation row.
        if (title != null && title != oldTask.title) {
          final diff = DiffUtils.computeDiff(oldTask.title, title);
          final hasPrior =
              await getLatestTaskHistoryForField(id, 'title') != null;
          await insertTaskHistory(
            taskId: id,
            field: 'title',
            oldValue: hasPrior ? '' : oldTask.title,
            newValue: diff ?? title,
            timestamp: remoteTimestamp,
            isRemote: isRemote,
          );
        }

        if (content != null && content != oldTask.content) {
          final diff = DiffUtils.computeDiff(oldTask.content, content);
          final hasPrior =
              await getLatestTaskHistoryForField(id, 'content') != null;
          await insertTaskHistory(
            taskId: id,
            field: 'content',
            // A null old content anchors the chain at "no value" — the patch
            // in newValue is relative to '' and replays from there.
            oldValue: hasPrior ? '' : oldTask.content,
            newValue: diff ?? content,
            timestamp: remoteTimestamp,
            isRemote: isRemote,
          );
        }

        if (orderId != null && orderId != oldTask.orderId) {
          await insertTaskHistory(
            taskId: id,
            field: 'orderId',
            oldValue: oldTask.orderId.toString(),
            newValue: orderId.toString(),
            timestamp: remoteTimestamp,
            isRemote: isRemote,
          );
        }

        if (clearParent && oldTask.parentId != null) {
          await insertTaskHistory(
            taskId: id,
            field: 'parentId',
            oldValue: oldTask.parentId.toString(),
            newValue: null,
            timestamp: remoteTimestamp,
            isRemote: isRemote,
          );
        } else if (parentId != null && parentId != oldTask.parentId) {
          await insertTaskHistory(
            taskId: id,
            field: 'parentId',
            oldValue: oldTask.parentId?.toString(),
            newValue: parentId.toString(),
            timestamp: remoteTimestamp,
            isRemote: isRemote,
          );
        }

        if (flags != null && flags != oldTask.flags) {
          await insertTaskHistory(
            taskId: id,
            field: 'flags',
            oldValue: oldTask.flags.toString(),
            newValue: flags.toString(),
            timestamp: remoteTimestamp,
            isRemote: isRemote,
          );
        }
      }

      return rowsUpdated > 0;
    });
  }

  /// Soft delete a task and all of its descendants.
  /// Each removed row gets its own history entry so deletions of the whole
  /// subtree propagate through sync instead of leaving live orphans.
  /// A remote deletion ([remoteTimestamp] set) does not cascade — the origin
  /// device already sends a removal for each descendant.
  Future<bool> deleteTask(int id, {String? remoteTimestamp}) async {
    final bool isRemote = remoteTimestamp != null;
    final String rowTs =
        isRemote ? formatIso(DateTime.parse(remoteTimestamp)) : nowIso();

    final ids = <int>[id];
    if (!isRemote) {
      Future<void> collectDescendants(int parentId) async {
        final children = await getChildTasks(parentId);
        for (final child in children) {
          ids.add(child.id);
          await collectDescendants(child.id);
        }
      }

      await collectDescendants(id);
    }

    return transaction(() async {
      var any = false;
      for (final taskId in ids) {
        final rowsUpdated =
            await (update(tasks)..where((t) => t.id.equals(taskId))).write(
          TasksCompanion(
            removed: const Value(1),
            timestamp: Value(rowTs),
          ),
        );

        if (rowsUpdated > 0) {
          any = true;
          await insertTaskHistory(
            taskId: taskId,
            field: 'removed',
            oldValue: '0',
            newValue: '1',
            timestamp: remoteTimestamp,
            isRemote: isRemote,
          );
        }
      }
      return any;
    });
  }

  /// Restore a soft-deleted task (used when a remote undelete is applied).
  Future<bool> undeleteTask(int id, {String? remoteTimestamp}) async {
    final bool isRemote = remoteTimestamp != null;
    final String rowTs =
        isRemote ? formatIso(DateTime.parse(remoteTimestamp)) : nowIso();
    return transaction(() async {
      final rowsUpdated =
          await (update(tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(removed: const Value(0), timestamp: Value(rowTs)),
      );
      if (rowsUpdated > 0) {
        await insertTaskHistory(
          taskId: id,
          field: 'removed',
          oldValue: '1',
          newValue: '0',
          timestamp: remoteTimestamp,
          isRemote: isRemote,
        );
      }
      return rowsUpdated > 0;
    });
  }

  /// Create a task row for a change pulled from another device. Records no
  /// local history (the row is remote-origin); the triggering field and any
  /// siblings are applied via updateTask with their own origin timestamps.
  Future<int> createTaskFromRemote({
    required String worldId,
    int? parentId,
    required String remoteTimestamp,
  }) async {
    return into(tasks).insert(
      TasksCompanion.insert(
        parentId: Value(parentId),
        worldId: Value(worldId),
        timestamp: formatIso(DateTime.parse(remoteTimestamp)),
      ),
    );
  }

  /// Permanently delete a task
  Future<int> permanentlyDeleteTask(int id) {
    return (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  /// Whether reparenting [taskId] under [potentialParentId] would form a loop.
  ///
  /// [updateTask] does no such check, so every caller that lets something other
  /// than the tree widget choose a parent — applying a remote change, serving
  /// an agent's move — has to ask first. A cycle is not a visible error: the
  /// affected subtree simply stops appearing in any parent-walked load, because
  /// nothing in it ever reaches a root.
  ///
  /// The visited set bounds the walk on a database that already contains one.
  Future<bool> wouldCreateCycle(int taskId, int potentialParentId) async {
    var currentId = potentialParentId;
    final visited = <int>{};

    while (true) {
      if (currentId == taskId) return true;
      if (visited.contains(currentId)) return false;
      visited.add(currentId);

      final task = await getTaskById(currentId);
      if (task == null || task.parentId == null) return false;
      currentId = task.parentId!;
    }
  }

  /// Get attachment count for a task
  Future<int> getAttachmentCount(int taskId) async {
    final count = countAll();
    final query = selectOnly(files)
      ..addColumns([count])
      ..where(files.taskId.equals(taskId) & files.removed.equals(0));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }

  // ============================================================
  // Timeline Operations
  // ============================================================

  /// Get all time records for a task
  Future<List<TimelineEntry>> getTimelineForTask(int taskId) {
    return (select(timeline)
          ..where((t) => t.taskId.equals(taskId) & t.removed.equals(0))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .get();
  }

  /// Get a time record by ID
  Future<TimelineEntry?> getTimeRecordById(int id) {
    return (select(timeline)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Get the most recent open-ended time record (endTime IS NULL), if any.
  /// Used to resume an interrupted tracking session after a restart/crash.
  Future<TimelineEntry?> getActiveTimeRecord() {
    return (select(timeline)
          ..where((t) => t.endTime.isNull() & t.removed.equals(0))
          ..orderBy([(t) => OrderingTerm.desc(t.startTime)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Create a new time record
  Future<int> createTimeRecord({
    required int taskId,
    required String worldId,
    required String startTime,
    String? endTime,
  }) async {
    return transaction(() async {
      final timelineId = await into(timeline).insert(
        TimelineCompanion.insert(
          taskId: taskId,
          worldId: Value(worldId),
          startTime: startTime,
          endTime: Value(endTime),
          timestamp: nowIso(),
        ),
      );

      // Record history for creation
      await insertTimelineHistory(
          timelineId: timelineId, field: 'taskId', newValue: taskId.toString());
      await insertTimelineHistory(
          timelineId: timelineId, field: 'startTime', newValue: startTime);
      if (endTime != null) {
        await insertTimelineHistory(
            timelineId: timelineId, field: 'endTime', newValue: endTime);
      }

      return timelineId;
    });
  }

  /// Create a time record for a change pulled from another device. Records no
  /// local history; fields are applied via updateTimeRecord with origin times.
  Future<int> createTimeRecordFromRemote({
    required int taskId,
    required String worldId,
    required String startTime,
    required String remoteTimestamp,
  }) async {
    return into(timeline).insert(
      TimelineCompanion.insert(
        taskId: taskId,
        worldId: Value(worldId),
        startTime: startTime,
        timestamp: formatIso(DateTime.parse(remoteTimestamp)),
      ),
    );
  }

  /// Update a time record. [remoteTimestamp] marks an applied remote change.
  Future<bool> updateTimeRecord(int id, {
    String? startTime,
    String? endTime,
    String? remoteTimestamp,
  }) async {
    final bool isRemote = remoteTimestamp != null;
    final String rowTs =
        isRemote ? formatIso(DateTime.parse(remoteTimestamp)) : nowIso();
    // Fetch old state
    final oldEntry = await getTimeRecordById(id);
    if (oldEntry == null) return false;

    final rowsUpdated = await (update(timeline)..where((t) => t.id.equals(id))).write(
      TimelineCompanion(
        startTime: startTime != null ? Value(startTime) : const Value.absent(),
        endTime: endTime != null ? Value(endTime) : const Value.absent(),
        timestamp: Value(rowTs),
      ),
    );

    if (rowsUpdated > 0) {
      if (startTime != null && startTime != oldEntry.startTime) {
        await insertTimelineHistory(
          timelineId: id,
          field: 'startTime',
          oldValue: oldEntry.startTime,
          newValue: startTime,
          timestamp: remoteTimestamp,
          isRemote: isRemote,
        );
      }

      if (endTime != null && endTime != oldEntry.endTime) {
        await insertTimelineHistory(
          timelineId: id,
          field: 'endTime',
          oldValue: oldEntry.endTime,
          newValue: endTime,
          timestamp: remoteTimestamp,
          isRemote: isRemote,
        );
      }
    }

    return rowsUpdated > 0;
  }

  /// Delete a time record. [remoteTimestamp] marks an applied remote change.
  Future<bool> deleteTimeRecord(int id, {String? remoteTimestamp}) async {
    final bool isRemote = remoteTimestamp != null;
    final String rowTs =
        isRemote ? formatIso(DateTime.parse(remoteTimestamp)) : nowIso();
    final rowsUpdated = await (update(timeline)..where((t) => t.id.equals(id))).write(
      TimelineCompanion(
        removed: const Value(1),
        timestamp: Value(rowTs),
      ),
    );

    if (rowsUpdated > 0) {
      await insertTimelineHistory(
        timelineId: id,
        field: 'removed',
        oldValue: '0',
        newValue: '1',
        timestamp: remoteTimestamp,
        isRemote: isRemote,
      );
    }

    return rowsUpdated > 0;
  }

  /// Restore a soft-deleted time record (used when a remote undelete is
  /// applied). The mirror of [deleteTimeRecord], history row included, so the
  /// restore is what LWW compares the next `removed` change against.
  Future<bool> undeleteTimeRecord(int id, {String? remoteTimestamp}) async {
    final bool isRemote = remoteTimestamp != null;
    final String rowTs =
        isRemote ? formatIso(DateTime.parse(remoteTimestamp)) : nowIso();
    final rowsUpdated = await (update(timeline)..where((t) => t.id.equals(id))).write(
      TimelineCompanion(
        removed: const Value(0),
        timestamp: Value(rowTs),
      ),
    );

    if (rowsUpdated > 0) {
      await insertTimelineHistory(
        timelineId: id,
        field: 'removed',
        oldValue: '1',
        newValue: '0',
        timestamp: remoteTimestamp,
        isRemote: isRemote,
      );
    }

    return rowsUpdated > 0;
  }

  // ============================================================
  // Attachment Operations
  // ============================================================

  /// Get attachments for a task (metadata only)
  Future<List<FileEntry>> getAttachmentsForTask(int taskId) {
    return (select(files)
          ..where((f) => f.taskId.equals(taskId) & f.removed.equals(0))
          ..orderBy([(f) => OrderingTerm.asc(f.orderId)]))
        .get();
  }

  /// Get attachment content
  Future<FileEntry?> getAttachmentWithContent(int id) {
    return (select(files)..where((f) => f.id.equals(id))).getSingleOrNull();
  }

  /// File name and owning task of an attachment, without touching its BLOB —
  /// for labelling an attachment in lists (e.g. the pending-sync preview),
  /// where [getAttachmentWithContent] would drag the whole payload into memory.
  Future<({String filename, int taskId})?> getAttachmentLabel(int id) async {
    final query = selectOnly(files)
      ..addColumns([files.filename, files.taskId])
      ..where(files.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return (
      filename: row.read(files.filename) ?? '',
      taskId: row.read(files.taskId) ?? 0,
    );
  }

  /// Size in bytes of a live attachment's content, or null when there is no
  /// such attachment. Reads `length(content)` rather than the BLOB itself.
  Future<int?> getAttachmentSize(String worldId) async {
    final row = await customSelect(
      'SELECT length(content) AS size FROM file '
      'WHERE world_id = ? AND removed = 0',
      variables: [Variable.withString(worldId)],
      readsFrom: {files},
    ).getSingleOrNull();
    return row?.read<int?>('size');
  }

  /// Read [length] bytes of an attachment's content starting at [offset].
  ///
  /// `substr` keeps the slice out of Dart memory-wise: a media player asking
  /// for a range of a 300 MB attachment gets just that range, where selecting
  /// the column would allocate the whole BLOB. package:sqlite3 exposes no
  /// incremental BLOB API, so this is the way to stream one.
  ///
  /// SQLite's substr() is 1-based over BLOBs.
  Future<Uint8List?> readAttachmentSlice(
    String worldId,
    int offset,
    int length,
  ) async {
    if (length <= 0) return Uint8List(0);

    final row = await customSelect(
      'SELECT substr(content, ?, ?) AS chunk FROM file '
      'WHERE world_id = ? AND removed = 0',
      variables: [
        Variable.withInt(offset + 1),
        Variable.withInt(length),
        Variable.withString(worldId),
      ],
      readsFrom: {files},
    ).getSingleOrNull();

    return row?.read<Uint8List?>('chunk');
  }

  /// Create a new attachment
  Future<int> createAttachment({
    required int taskId,
    required String worldId,
    required String filename,
    required Uint8List content,
    int orderId = 0,
  }) async {
    final hash = blobId(content);
    return transaction(() async {
      final fileId = await into(files).insert(
        FilesCompanion.insert(
          taskId: taskId,
          worldId: Value(worldId),
          filename: Value(filename),
          content: Value(content),
          contentHash: Value(hash),
          orderId: Value(orderId),
          timestamp: nowIso(),
        ),
      );

      // Record history for creation
      await insertFileHistory(
          fileId: fileId, field: 'filename', newValue: filename);
      await insertFileHistory(
          fileId: fileId, field: 'content', newValue: BlobRef(hash).encode());
      await insertFileHistory(
          fileId: fileId, field: 'orderId', newValue: orderId.toString());

      return fileId;
    });
  }

  /// Create an attachment for a change pulled from another device (no local
  /// history; fields applied via update* with origin timestamps).
  Future<int> createAttachmentFromRemote({
    required int taskId,
    required String worldId,
    required String remoteTimestamp,
  }) async {
    return into(files).insert(
      FilesCompanion.insert(
        taskId: taskId,
        worldId: Value(worldId),
        timestamp: formatIso(DateTime.parse(remoteTimestamp)),
      ),
    );
  }

  /// Update attachment metadata. [remoteTimestamp] marks an applied remote change.
  Future<bool> updateAttachment(int id, {
    String? filename,
    int? orderId,
    String? remoteTimestamp,
  }) async {
    final bool isRemote = remoteTimestamp != null;
    final String rowTs =
        isRemote ? formatIso(DateTime.parse(remoteTimestamp)) : nowIso();
    // Fetch old state
    final oldFile = await getAttachmentWithContent(id);
    if (oldFile == null) return false;

    final rowsUpdated = await (update(files)..where((f) => f.id.equals(id))).write(
      FilesCompanion(
        filename: filename != null ? Value(filename) : const Value.absent(),
        orderId: orderId != null ? Value(orderId) : const Value.absent(),
        timestamp: Value(rowTs),
      ),
    );

    if (rowsUpdated > 0) {
      if (filename != null && filename != oldFile.filename) {
        await insertFileHistory(
          fileId: id,
          field: 'filename',
          oldValue: oldFile.filename,
          newValue: filename,
          timestamp: remoteTimestamp,
          isRemote: isRemote,
        );
      }

      if (orderId != null && orderId != oldFile.orderId) {
        await insertFileHistory(
          fileId: id,
          field: 'orderId',
          oldValue: oldFile.orderId.toString(),
          newValue: orderId.toString(),
          timestamp: remoteTimestamp,
          isRemote: isRemote,
        );
      }
    }

    return rowsUpdated > 0;
  }

  /// The `content` history value for an attachment's *previous* state: a blob
  /// reference, never the bytes (docs/P2P_SYNC.md §3.5). Null when there was
  /// no previous content — which is what a creation row records.
  ///
  /// Prefers the stored hash and falls back to hashing the bytes, for a row
  /// written before the v11 backfill gave every attachment its hash.
  static String? _priorContentRef(FileEntry file) {
    if (file.contentHash.isNotEmpty) return BlobRef(file.contentHash).encode();
    final content = file.content;
    if (content == null) return null;
    return BlobRef(blobId(content)).encode();
  }

  /// Update attachment content. [remoteTimestamp] marks an applied remote change.
  Future<bool> updateAttachmentContent(int id, Uint8List content,
      {String? remoteTimestamp}) async {
    final bool isRemote = remoteTimestamp != null;
    final String rowTs =
        isRemote ? formatIso(DateTime.parse(remoteTimestamp)) : nowIso();
    // Fetch old state
    final oldFile = await getAttachmentWithContent(id);
    if (oldFile == null) return false;

    final hash = blobId(content);
    final rowsUpdated = await (update(files)..where((f) => f.id.equals(id))).write(
      FilesCompanion(
        content: Value(content),
        contentHash: Value(hash),
        timestamp: Value(rowTs),
      ),
    );

    if (rowsUpdated > 0) {
      await insertFileHistory(
        fileId: id,
        field: 'content',
        oldValue: _priorContentRef(oldFile),
        newValue: BlobRef(hash).encode(),
        timestamp: remoteTimestamp,
        isRemote: isRemote,
      );
    }

    return rowsUpdated > 0;
  }

  /// Soft delete an attachment. [remoteTimestamp] marks an applied remote change.
  Future<bool> deleteAttachment(int id, {String? remoteTimestamp}) async {
    final bool isRemote = remoteTimestamp != null;
    final String rowTs =
        isRemote ? formatIso(DateTime.parse(remoteTimestamp)) : nowIso();
    final rowsUpdated = await (update(files)..where((f) => f.id.equals(id))).write(
      FilesCompanion(
        removed: const Value(1),
        timestamp: Value(rowTs),
      ),
    );

    if (rowsUpdated > 0) {
      await insertFileHistory(
        fileId: id,
        field: 'removed',
        oldValue: '0',
        newValue: '1',
        timestamp: remoteTimestamp,
        isRemote: isRemote,
      );
    }

    return rowsUpdated > 0;
  }

  /// Undelete an attachment. [remoteTimestamp] marks an applied remote change.
  Future<bool> undeleteAttachment(int id, {String? remoteTimestamp}) async {
    final bool isRemote = remoteTimestamp != null;
    final String rowTs =
        isRemote ? formatIso(DateTime.parse(remoteTimestamp)) : nowIso();
    final rowsUpdated = await (update(files)..where((f) => f.id.equals(id))).write(
      FilesCompanion(
        removed: const Value(0),
        timestamp: Value(rowTs),
      ),
    );

    if (rowsUpdated > 0) {
      await insertFileHistory(
        fileId: id,
        field: 'removed',
        oldValue: '1',
        newValue: '0',
        timestamp: remoteTimestamp,
        isRemote: isRemote,
      );
    }

    return rowsUpdated > 0;
  }

  /// Reorder attachments for a task
  Future<void> reorderAttachments(int taskId, List<int> attachmentIds) async {
    await transaction(() async {
      for (var i = 0; i < attachmentIds.length; i++) {
        final oldFile = await getAttachmentWithContent(attachmentIds[i]);
        if (oldFile != null && oldFile.orderId != i) {
          await (update(files)..where((f) => f.id.equals(attachmentIds[i]))).write(
            FilesCompanion(
              orderId: Value(i),
              timestamp: Value(nowIso()),
            ),
          );
          await insertFileHistory(
            fileId: attachmentIds[i],
            field: 'orderId',
            oldValue: oldFile.orderId.toString(),
            newValue: i.toString(),
          );
        }
      }
    });
  }

  // ============================================================
  // Properties Operations
  // ============================================================

  /// Get a property value
  Future<String?> getProperty(String key) async {
    final result = await (select(properties)
          ..where((p) => p.type.equals(key)))
        .getSingleOrNull();
    return result?.value;
  }

  /// Set a property value
  Future<void> setProperty(String key, String value) {
    return into(properties).insertOnConflictUpdate(
      PropertiesCompanion.insert(type: key, value: value),
    );
  }

  // ============================================================
  // History Operations
  // ============================================================

  /// Insert a task history record.
  /// [timestamp] overrides the modification time (used to preserve a remote
  /// change's origin time); [isRemote] marks a row applied from another device
  /// so it is not pushed back.
  Future<int> insertTaskHistory({
    required int taskId,
    required String field,
    String? oldValue,
    String? newValue,
    String? worldId,
    String? timestamp,
    bool isRemote = false,
  }) async {
    // Resolve worldId if not provided
    final resolvedWorldId = worldId ?? (await getTaskById(taskId))?.worldId ?? '';
    return into(historyTask).insert(
      HistoryTaskCompanion.insert(
        taskId: taskId,
        worldId: Value(resolvedWorldId),
        field: field,
        oldValue: Value(oldValue),
        newValue: Value(newValue),
        timestamp: timestamp != null ? formatIso(DateTime.parse(timestamp)) : nowIso(),
        isRemote: Value(isRemote ? 1 : 0),
      ),
    );
  }

  /// Insert a file history record. See [insertTaskHistory] for the extra params.
  Future<int> insertFileHistory({
    required int fileId,
    required String field,
    String? oldValue,
    String? newValue,
    String? worldId,
    String? timestamp,
    bool isRemote = false,
  }) async {
    // Resolve worldId if not provided
    final resolvedWorldId = worldId ?? (await getAttachmentWithContent(fileId))?.worldId ?? '';
    return into(historyFile).insert(
      HistoryFileCompanion.insert(
        fileId: fileId,
        worldId: Value(resolvedWorldId),
        field: field,
        oldValue: Value(oldValue),
        newValue: Value(newValue),
        timestamp: timestamp != null ? formatIso(DateTime.parse(timestamp)) : nowIso(),
        isRemote: Value(isRemote ? 1 : 0),
      ),
    );
  }

  /// Insert a timeline history record. See [insertTaskHistory] for extra params.
  Future<int> insertTimelineHistory({
    required int timelineId,
    required String field,
    String? oldValue,
    String? newValue,
    String? worldId,
    String? timestamp,
    bool isRemote = false,
  }) async {
    // Resolve worldId if not provided
    final resolvedWorldId = worldId ?? (await getTimeRecordById(timelineId))?.worldId ?? '';
    return into(historyTimeline).insert(
      HistoryTimelineCompanion.insert(
        timelineId: timelineId,
        worldId: Value(resolvedWorldId),
        field: field,
        oldValue: Value(oldValue),
        newValue: Value(newValue),
        timestamp: timestamp != null ? formatIso(DateTime.parse(timestamp)) : nowIso(),
        isRemote: Value(isRemote ? 1 : 0),
      ),
    );
  }

  /// Get all task history entries
  Future<List<HistoryTaskData>> getAllTaskHistory() {
    return (select(historyTask)
          ..orderBy([(h) => OrderingTerm.asc(h.timestamp)]))
        .get();
  }

  /// Get task history for a specific task
  Future<List<HistoryTaskData>> getTaskHistory(int taskId) {
    return (select(historyTask)
          ..where((h) => h.taskId.equals(taskId))
          ..orderBy([(h) => OrderingTerm.asc(h.timestamp)]))
        .get();
  }

  /// Get task history since a timestamp
  Future<List<HistoryTaskData>> getTaskHistorySince(String sinceTimestamp) {
    return (select(historyTask)
          ..where((h) => h.timestamp.isBiggerThanValue(sinceTimestamp))
          ..orderBy([(h) => OrderingTerm.asc(h.timestamp)]))
        .get();
  }

  /// Get all file history entries
  Future<List<HistoryFileData>> getAllFileHistory() {
    return (select(historyFile)
          ..orderBy([(h) => OrderingTerm.asc(h.timestamp)]))
        .get();
  }

  /// Get file history for a specific file
  Future<List<HistoryFileData>> getFileHistory(int fileId) {
    return (select(historyFile)
          ..where((h) => h.fileId.equals(fileId))
          ..orderBy([(h) => OrderingTerm.asc(h.timestamp)]))
        .get();
  }

  /// Get file history since a timestamp
  Future<List<HistoryFileData>> getFileHistorySince(String sinceTimestamp) {
    return (select(historyFile)
          ..where((h) => h.timestamp.isBiggerThanValue(sinceTimestamp))
          ..orderBy([(h) => OrderingTerm.asc(h.timestamp)]))
        .get();
  }

  /// Get all timeline history entries
  Future<List<HistoryTimelineData>> getAllTimelineHistory() {
    return (select(historyTimeline)
          ..orderBy([(h) => OrderingTerm.asc(h.timestamp)]))
        .get();
  }

  /// Get timeline history for a specific timeline entry
  Future<List<HistoryTimelineData>> getTimelineHistory(int timelineId) {
    return (select(historyTimeline)
          ..where((h) => h.timelineId.equals(timelineId))
          ..orderBy([(h) => OrderingTerm.asc(h.timestamp)]))
        .get();
  }

  /// Get timeline history since a timestamp
  Future<List<HistoryTimelineData>> getTimelineHistorySince(String sinceTimestamp) {
    return (select(historyTimeline)
          ..where((h) => h.timestamp.isBiggerThanValue(sinceTimestamp))
          ..orderBy([(h) => OrderingTerm.asc(h.timestamp)]))
        .get();
  }

  // ---- Push watermark by history row id (local, non-remote rows only) ----
  // Row ids are monotonic and assigned at insert, so a watermark on them is
  // immune to clock skew and to the "edit made while a sync is in flight"
  // loss that a timestamp watermark suffers. isRemote rows are excluded so
  // changes applied from other devices are never echoed back.

  Future<List<HistoryTaskData>> getLocalTaskHistoryAfterId(int afterId) {
    return (select(historyTask)
          ..where((h) => h.id.isBiggerThanValue(afterId) & h.isRemote.equals(0))
          ..orderBy([(h) => OrderingTerm.asc(h.id)]))
        .get();
  }

  Future<List<HistoryFileData>> getLocalFileHistoryAfterId(int afterId) {
    return (select(historyFile)
          ..where((h) => h.id.isBiggerThanValue(afterId) & h.isRemote.equals(0))
          ..orderBy([(h) => OrderingTerm.asc(h.id)]))
        .get();
  }

  Future<List<HistoryTimelineData>> getLocalTimelineHistoryAfterId(int afterId) {
    return (select(historyTimeline)
          ..where((h) => h.id.isBiggerThanValue(afterId) & h.isRemote.equals(0))
          ..orderBy([(h) => OrderingTerm.asc(h.id)]))
        .get();
  }

  // ---- Latest writer per entity+field, for conflict resolution ----
  // Returns the most recent write (local or remote) so LWW compares an
  // incoming change against the timestamp of the value actually stored,
  // regardless of when the last sync happened.

  /// One task field's full history chain, oldest first — the input order
  /// HistoryService.reconstructTaskFieldChain expects.
  Future<List<HistoryTaskData>> getTaskHistoryForField(int taskId, String field) {
    return (select(historyTask)
          ..where((h) => h.taskId.equals(taskId) & h.field.equals(field))
          ..orderBy([(h) => OrderingTerm.asc(h.timestamp), (h) => OrderingTerm.asc(h.id)]))
        .get();
  }

  Future<HistoryTaskData?> getLatestTaskHistoryForField(int taskId, String field) {
    return (select(historyTask)
          ..where((h) => h.taskId.equals(taskId) & h.field.equals(field))
          ..orderBy([(h) => OrderingTerm.desc(h.timestamp), (h) => OrderingTerm.desc(h.id)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<HistoryFileData?> getLatestFileHistoryForField(int fileId, String field) {
    return (select(historyFile)
          ..where((h) => h.fileId.equals(fileId) & h.field.equals(field))
          ..orderBy([(h) => OrderingTerm.desc(h.timestamp), (h) => OrderingTerm.desc(h.id)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<HistoryTimelineData?> getLatestTimelineHistoryForField(int timelineId, String field) {
    return (select(historyTimeline)
          ..where((h) => h.timelineId.equals(timelineId) & h.field.equals(field))
          ..orderBy([(h) => OrderingTerm.desc(h.timestamp), (h) => OrderingTerm.desc(h.id)])
          ..limit(1))
        .getSingleOrNull();
  }

  // ============================================================
  // Blob store (sync protocol v2, §3.5) — the file table, viewed by hash
  // ============================================================

  /// Content identity of an attachment: SHA-256 of its bytes, lowercase hex.
  ///
  /// Unkeyed on purpose: a pure function of the content is computable here,
  /// at write time, with no key in hand, and survives a password change. The
  /// cost is that a relay can confirm a *guess* — "does this account hold
  /// this exact well-known file?" — which is the standard trade of
  /// content-addressed storage. An HMAC under the sync key would close it at
  /// the price of re-hashing everything whenever the password changes.
  static String blobId(List<int> content) => sha256.convert(content).toString();

  /// The bytes stored under [hash] on this node, if any row holds them.
  /// Any attachment with that content will do — the same file attached
  /// twice is the same blob.
  Future<Uint8List?> findBlobLocally(String hash) async {
    if (hash.isEmpty) return null;
    final row = await customSelect(
      'SELECT content AS c FROM file '
      'WHERE content_hash = ? AND content IS NOT NULL LIMIT 1',
      variables: [Variable.withString(hash)],
    ).getSingleOrNull();
    return row?.readNullable<Uint8List>('c');
  }

  /// Hashes this node has references to but no bytes for — attachments whose
  /// packet has been applied and whose content is still to be fetched.
  ///
  /// Soft-deleted rows are not waiting for anything: their bytes are what
  /// [collectRemovedBlobs] releases, and asking for them again would undo the
  /// collection on the next exchange. An undelete puts the row back in this
  /// set, and the fetch happens then.
  Future<List<String>> missingBlobHashes() async {
    final rows = await customSelect(
      "SELECT DISTINCT content_hash AS h FROM file "
      "WHERE content IS NULL AND content_hash != '' AND removed = 0 "
      "ORDER BY content_hash",
    ).get();
    return [for (final r in rows) r.read<String>('h')];
  }

  /// Drop the bytes of soft-deleted attachments, keeping the `blob:<hash>`
  /// reference that names them (docs/P2P_SYNC.md §3.5). Returns how many rows
  /// were freed; the space returns to the filesystem on the next [vacuum].
  ///
  /// A device's blob store *is* its `file` table, and nothing on a device ever
  /// released one before this: only the relay collected, so an attachment
  /// deleted everywhere still occupied space on every device forever. A
  /// collected row is left in the same shape as a reference that has not been
  /// fetched yet, so undeleting it simply makes it missing again and the next
  /// exchange refetches it — provided the fleet still holds the blob, which is
  /// the caller's business to establish (see [SyncService.collectRemovedBlobs]).
  ///
  /// Two kinds of row are spared on purpose:
  ///  - one with no `content_hash`, since dropping those bytes would leave
  ///    nothing to name them by and they could never come back;
  ///  - one whose hash a live attachment still uses — the same file attached
  ///    twice is one blob, and the other copy is still in use.
  Future<int> collectRemovedBlobs() {
    return customUpdate(
      "UPDATE file SET content = NULL "
      "WHERE removed = 1 AND content IS NOT NULL AND content_hash != '' "
      "  AND NOT EXISTS ("
      "    SELECT 1 FROM file live "
      "    WHERE live.removed = 0 AND live.content_hash = file.content_hash)",
      updates: {files},
    );
  }

  /// The ciphertext accumulated so far for [hash], or null when this device
  /// has not started (or has finished) fetching it.
  ///
  /// A row older than [staleAfter] is dropped and reported as absent: the node
  /// that served the earlier chunks may have re-encrypted the blob since, and
  /// resuming into a different ciphertext can only fail the tag check at the
  /// end. Starting over costs one transfer; resuming into rubbish costs one
  /// transfer *and* the bytes already fetched.
  Future<({Uint8List received, int? total})?> getBlobFetch(
    String hash, {
    Duration staleAfter = const Duration(days: 1),
  }) async {
    final row = await (select(blobFetches)..where((b) => b.hash.equals(hash)))
        .getSingleOrNull();
    if (row == null) return null;
    final age = DateTime.now().toUtc().difference(DateTime.parse(row.updatedAt));
    if (age > staleAfter) {
      await clearBlobFetch(hash);
      return null;
    }
    return (received: row.received, total: row.total);
  }

  /// Record the ciphertext prefix fetched for [hash] so far.
  Future<void> saveBlobFetch(String hash, Uint8List received, int? total) {
    return into(blobFetches).insert(
      BlobFetchesCompanion.insert(
        hash: hash,
        received: received,
        total: Value(total),
        updatedAt: nowIso(),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Forget a partial fetch — because it completed, or because it turned out
  /// not to be a prefix of what the blob actually is.
  Future<int> clearBlobFetch(String hash) {
    return (delete(blobFetches)..where((b) => b.hash.equals(hash))).go();
  }

  /// Total ciphertext held for transfers in flight, for the storage report.
  Future<int> pendingBlobFetchBytes() async {
    final row = await customSelect(
      'SELECT COALESCE(SUM(LENGTH(received)), 0) AS b FROM blob_fetches',
      readsFrom: {blobFetches},
    ).getSingle();
    return row.read<int>('b');
  }

  /// Store fetched [content] into every row waiting for [hash]. Returns how
  /// many attachments became readable. No history row: the change was
  /// recorded when the reference arrived; this is only its bytes catching up.
  ///
  /// Soft-deleted rows are skipped for the same reason they are not in
  /// [missingBlobHashes]: filling one would re-spend the space collection just
  /// reclaimed, for an attachment nobody can open.
  Future<int> fillBlob(String hash, Uint8List content) async {
    if (blobId(content) != hash) {
      throw ArgumentError('Content does not hash to $hash');
    }
    return (update(files)
          ..where((f) =>
              f.contentHash.equals(hash) &
              f.content.isNull() &
              f.removed.equals(0)))
        .write(FilesCompanion(content: Value(content)));
  }

  /// Record that attachment [id]'s content is now the blob [hash], which this
  /// node does not hold yet. The history row lands at the origin timestamp so
  /// LWW sees the change; the bytes arrive via [fillBlob].
  ///
  /// When the bytes are already here under another attachment, the caller
  /// should use [updateAttachmentContent] instead — this is only for the
  /// reference-without-bytes case.
  Future<bool> markAttachmentPendingBlob(int id, String hash,
      {required String remoteTimestamp}) async {
    final oldFile = await getAttachmentWithContent(id);
    if (oldFile == null) return false;
    final rowsUpdated =
        await (update(files)..where((f) => f.id.equals(id))).write(
      FilesCompanion(
        content: const Value(null),
        contentHash: Value(hash),
        timestamp: Value(formatIso(DateTime.parse(remoteTimestamp))),
      ),
    );
    if (rowsUpdated > 0) {
      await insertFileHistory(
        fileId: id,
        field: 'content',
        oldValue: _priorContentRef(oldFile),
        newValue: BlobRef(hash).encode(),
        timestamp: remoteTimestamp,
        isRemote: true,
      );
    }
    return rowsUpdated > 0;
  }

  /// Hash every attachment that has bytes but no hash yet. Batched by row id:
  /// attachments are the largest things in the database, and all of them at
  /// once will not fit in memory.
  Future<int> backfillFileContentHashes({int batchSize = 50}) async {
    var filled = 0;
    var afterId = 0;
    while (true) {
      final rows = await customSelect(
        "SELECT id AS i, content AS c FROM file "
        "WHERE content_hash = '' AND content IS NOT NULL AND id > ? "
        "ORDER BY id LIMIT ?",
        variables: [Variable.withInt(afterId), Variable.withInt(batchSize)],
      ).get();
      if (rows.isEmpty) return filled;
      await batch((b) {
        for (final row in rows) {
          b.customStatement(
            'UPDATE file SET content_hash = ? WHERE id = ?',
            [blobId(row.read<Uint8List>('c')), row.read<int>('i')],
          );
        }
      });
      afterId = rows.last.read<int>('i');
      filled += rows.length;
    }
  }

  // ============================================================
  // Packet Store (sync protocol v2)
  // ============================================================

  /// Property key of the coverage baseline: {device → counter} this node has
  /// adopted from a snapshot without holding the packets themselves
  /// (docs/P2P_SYNC_COMPACTION.md §4.1).
  static const _kSyncBaseline = 'sync_v2_baseline';

  /// Coverage this node has adopted from snapshots. Below these counters a
  /// stream is *known*, not held: the packets were pruned (or never fetched)
  /// because a snapshot already carried their merged result.
  Future<Map<String, int>> getSyncBaselineVector() async {
    final raw = await getProperty(_kSyncBaseline);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final entry in decoded.entries)
          if (entry.value is int) entry.key: entry.value as int,
      };
    } catch (_) {
      // A corrupt baseline must not wedge sync; the worst case of forgetting
      // it is refetching packets we could have skipped.
      return {};
    }
  }

  /// Raise the coverage baseline to include [coverage], never lowering an
  /// entry. Idempotent, so re-applying the same snapshot is free.
  Future<void> mergeSyncBaselineVector(Map<String, int> coverage) async {
    final baseline = await getSyncBaselineVector();
    var changed = false;
    coverage.forEach((device, counter) {
      if (counter > (baseline[device] ?? 0)) {
        baseline[device] = counter;
        changed = true;
      }
    });
    if (changed) await setProperty(_kSyncBaseline, jsonEncode(baseline));
  }

  /// This node's version vector: highest counter *known* per origin device —
  /// the greater of what is stored and what a snapshot's coverage has been
  /// adopted for. Holdings above the baseline are contiguous prefixes (see
  /// [storeSyncPacket]), so one integer per device fully describes them.
  Future<Map<String, int>> getSyncVector() async {
    final rows = await customSelect(
      'SELECT origin_device_id AS d, MAX(counter) AS c FROM sync_packets '
      'GROUP BY origin_device_id',
    ).get();
    final vector = {
      for (final row in rows) row.read<String>('d'): row.read<int>('c'),
    };
    (await getSyncBaselineVector()).forEach((device, counter) {
      if (counter > (vector[device] ?? 0)) vector[device] = counter;
    });
    return vector;
  }

  /// Highest counter known for [deviceId] — stored or adopted — or 0 when the
  /// device is unknown. This, not `MAX(counter)`, is what the next counter of
  /// a stream is derived from: pruning removes low counters, and a stream
  /// pruned to nothing would otherwise restart at 1 and fork itself
  /// (docs/P2P_SYNC.md §3.3).
  Future<int> maxSyncCounterFor(String deviceId) async {
    final row = await customSelect(
      'SELECT MAX(counter) AS c FROM sync_packets WHERE origin_device_id = ?',
      variables: [Variable.withString(deviceId)],
    ).getSingle();
    final stored = row.readNullable<int>('c') ?? 0;
    final adopted = (await getSyncBaselineVector())[deviceId] ?? 0;
    return stored > adopted ? stored : adopted;
  }

  /// Highest counter actually *stored* for [deviceId] — what this node can
  /// still hand to a peer, as opposed to what it knows about.
  Future<int> maxStoredSyncCounterFor(String deviceId) async {
    final row = await customSelect(
      'SELECT MAX(counter) AS c FROM sync_packets WHERE origin_device_id = ?',
      variables: [Variable.withString(deviceId)],
    ).getSingle();
    return row.readNullable<int>('c') ?? 0;
  }

  /// Delete packets of [deviceId] at or above [from] — the local half of fork
  /// recovery (docs/P2P_SYNC.md §3.3). Returns how many packets were dropped.
  ///
  /// The opposite end of the stream from [deleteSyncPacketsUpTo], and for the
  /// opposite reason: compaction discards packets whose *content* a snapshot
  /// already carries, while this discards packets whose *identity* belongs to
  /// different content elsewhere in the fleet. Holding on to them would mean
  /// serving them to peers that have not seen the real ones yet, which is how
  /// one device's fork becomes everybody's.
  Future<int> deleteSyncPacketsFrom(String deviceId, int from) async {
    return transaction(() async {
      final row = await customSelect(
        'SELECT COUNT(*) AS n FROM sync_packets '
        'WHERE origin_device_id = ? AND counter >= ?',
        variables: [Variable.withString(deviceId), Variable.withInt(from)],
      ).getSingle();
      await customStatement(
        'DELETE FROM sync_packets WHERE origin_device_id = ? AND counter >= ?',
        [deviceId, from],
      );
      return row.read<int>('n');
    });
  }

  /// Forget every own-packet push-log row. Counters restart from 1 under a new
  /// device identity, so rows keyed by the old stream's counters would answer
  /// the conflict-copy causal test (§8.3) about the wrong packets.
  Future<void> clearSyncPushLog() => delete(syncPushLog).go();

  /// Delete packets of [deviceId] at or below [upTo] — the local half of
  /// compaction (docs/P2P_SYNC_COMPACTION.md §4.4). Returns how many packets
  /// and bytes were discarded. The caller must have adopted coverage for the
  /// range first: what is deleted here is state a snapshot already carries.
  Future<({int packets, int bytes})> deleteSyncPacketsUpTo(
    String deviceId,
    int upTo,
  ) async {
    if (upTo < 1) return (packets: 0, bytes: 0);
    return transaction(() async {
      final row = await customSelect(
        'SELECT COUNT(*) AS n, COALESCE(SUM(LENGTH(payload)), 0) AS b '
        'FROM sync_packets WHERE origin_device_id = ? AND counter <= ?',
        variables: [Variable.withString(deviceId), Variable.withInt(upTo)],
      ).getSingle();
      final packets = row.read<int>('n');
      if (packets == 0) return (packets: 0, bytes: 0);
      final bytes = row.read<int>('b');
      await customStatement(
        'DELETE FROM sync_packets WHERE origin_device_id = ? AND counter <= ?',
        [deviceId, upTo],
      );
      return (packets: packets, bytes: bytes);
    });
  }

  /// What the local packet store occupies, per origin device.
  Future<({int packets, int bytes})> syncPacketStorage() async {
    final row = await customSelect(
      'SELECT COUNT(*) AS n, COALESCE(SUM(LENGTH(payload)), 0) AS b '
      'FROM sync_packets',
    ).getSingle();
    return (packets: row.read<int>('n'), bytes: row.read<int>('b'));
  }

  /// Blank the full old text stored beside the patch in legacy title/content
  /// history rows, keeping each (task, field) chain's earliest row intact as
  /// the replay base. Only patch-shaped rows are touched: a full-value
  /// newValue (legacy pre-diff rows) stays self-sufficient as written.
  /// Idempotent; run by the v9 migration.
  Future<void> compactTaskHistoryOldValues() {
    return customStatement('''
      UPDATE history_task SET old_value = ''
      WHERE field IN ('title', 'content')
        AND old_value IS NOT NULL AND old_value != ''
        AND new_value LIKE '@@ -%'
        AND EXISTS (
          SELECT 1 FROM history_task prior
          WHERE prior.task_id = history_task.task_id
            AND prior.field = history_task.field
            AND prior.id < history_task.id
        )
    ''');
  }

  /// Rewrite legacy `history_file` content rows that inline the attachment as
  /// base64 into the `blob:<sha256>` reference the row already means
  /// (docs/P2P_SYNC.md §3.5). Returns how many rows were rewritten.
  ///
  /// The history row's job is to say *that* content changed, when, and to
  /// which blob; the bytes belong to the `file` table and the blob store. The
  /// reference is derived from the stored base64 rather than from the file
  /// row, so a superseded version still names the blob it actually was.
  ///
  /// Idempotent — a row already holding a reference is skipped, so a re-run
  /// (or a Syncthing-merged database carrying a mix) converges. A value that
  /// is not decodable base64 is left alone: it cannot be interpreted, and
  /// guessing would lose more than the space is worth.
  ///
  /// Rows are visited one at a time on purpose. These values are the largest
  /// strings in the database, and a batch of them will not fit in memory on a
  /// phone — [ids] are paged, the payloads are not.
  Future<int> compactFileHistoryContent({int idPageSize = 500}) async {
    var rewritten = 0;
    var afterId = 0;
    while (true) {
      final ids = await customSelect(
        "SELECT id AS i FROM history_file "
        "WHERE field = 'content' AND id > ? "
        "AND ((old_value IS NOT NULL AND old_value != '' "
        "      AND old_value NOT LIKE 'blob:%') "
        "  OR (new_value IS NOT NULL AND new_value != '' "
        "      AND new_value NOT LIKE 'blob:%')) "
        "ORDER BY id LIMIT ?",
        variables: [Variable.withInt(afterId), Variable.withInt(idPageSize)],
      ).get();
      if (ids.isEmpty) return rewritten;

      for (final idRow in ids) {
        final id = idRow.read<int>('i');
        afterId = id;
        final row = await customSelect(
          'SELECT old_value AS o, new_value AS n FROM history_file WHERE id = ?',
          variables: [Variable.withInt(id)],
        ).getSingleOrNull();
        if (row == null) continue;

        final oldRef = _base64ToBlobRef(row.readNullable<String>('o'));
        final newRef = _base64ToBlobRef(row.readNullable<String>('n'));
        if (oldRef == null && newRef == null) continue;

        await customStatement(
          'UPDATE history_file SET old_value = COALESCE(?, old_value), '
          'new_value = COALESCE(?, new_value) WHERE id = ?',
          [oldRef, newRef, id],
        );
        rewritten++;
      }
    }
  }

  /// The blob reference for an inlined base64 history value, or null when
  /// [value] is absent, already a reference, or not decodable — the cases
  /// [compactFileHistoryContent] leaves untouched.
  static String? _base64ToBlobRef(String? value) {
    if (value == null || value.isEmpty) return null;
    if (BlobRef.tryParse(value) != null) return null;
    try {
      return BlobRef(blobId(base64.decode(value))).encode();
    } on FormatException {
      return null;
    }
  }

  /// Rebuild the database file, handing pages freed by deletes and by
  /// [compactTaskHistoryOldValues] back to the filesystem.
  ///
  /// SQLite only marks such pages reusable inside the file; `VACUUM` is what
  /// actually shrinks it. Issued as a bare statement because it cannot run
  /// inside a transaction, and it holds the connection for its whole run —
  /// on a large database that is seconds, not milliseconds.
  Future<void> vacuum() => customStatement('VACUUM');

  /// Record that own packet [counter] packaged task-history rows up to
  /// [taskHistoryId] (see [SyncPushLog]).
  Future<void> insertSyncPushLog({
    required int counter,
    required int taskHistoryId,
  }) {
    return into(syncPushLog).insert(
      SyncPushLogCompanion.insert(
          counter: Value(counter), taskHistoryId: taskHistoryId),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// The task-history watermark of the latest own packet with counter ≤
  /// [counter], or null when no logged packet is that old (packets sent
  /// before the push log existed).
  Future<int?> getPushLogTaskHidAtOrBelow(int counter) async {
    final row = await (select(syncPushLog)
          ..where((l) => l.counter.isSmallerOrEqualValue(counter))
          ..orderBy([(l) => OrderingTerm.desc(l.counter)])
          ..limit(1))
        .getSingleOrNull();
    return row?.taskHistoryId;
  }

  /// Store packet ([originDeviceId], [counter]) under the v2 insertion rule:
  /// accepted only when it is the next contiguous counter for its device.
  /// Returns [SyncPacketStoreResult.duplicate] for an already-held slot (an
  /// expected no-op when the same packet arrives via relay and LAN) and
  /// [SyncPacketStoreResult.gap] when the sender violated per-device ordering
  /// (the gap is re-fetched on the next exchange).
  /// Returns [SyncPacketStoreResult.conflict] when the slot is held by
  /// *different* bytes — a forked stream, not a duplicate (§3.3).
  Future<SyncPacketStoreResult> storeSyncPacket({
    required String originDeviceId,
    required int counter,
    required Uint8List payload,
  }) async {
    final hash = syncPayloadHash(payload);
    return transaction(() async {
      final held = await maxSyncCounterFor(originDeviceId);
      if (counter <= held) {
        // The slot is spoken for — but by these bytes, or by others? Without
        // the hash both answers look identical and the packet is dropped
        // either way. A slot known only through a snapshot's coverage has no
        // row and therefore no hash; unknown stays a duplicate, since a
        // pruned packet is exactly one we chose not to be able to compare.
        final heldHash = await syncPacketHashAt(originDeviceId, counter);
        if (heldHash != null && heldHash.isNotEmpty && heldHash != hash) {
          return SyncPacketStoreResult.conflict;
        }
        return SyncPacketStoreResult.duplicate;
      }
      if (counter != held + 1) return SyncPacketStoreResult.gap;
      await into(syncPackets).insert(
        SyncPacketsCompanion.insert(
          originDeviceId: originDeviceId,
          counter: counter,
          payload: payload,
          storedAt: nowIso(),
          payloadHash: Value(hash),
        ),
      );
      return SyncPacketStoreResult.stored;
    });
  }

  /// Content identity of a packet: SHA-256 of the wire blob, lowercase hex.
  ///
  /// Hashing the *stored ciphertext* rather than the plaintext is deliberate:
  /// payloads travel and are stored verbatim, so every node computes this over
  /// identical bytes, and a node can verify a stream it cannot decrypt.
  static String syncPayloadHash(List<int> payload) =>
      sha256.convert(payload).toString();

  /// The stored hash for one slot, or null when this node holds no such packet
  /// (never fetched, or pruned by compaction). Empty means the row predates
  /// the column and was never re-hashed.
  Future<String?> syncPacketHashAt(String deviceId, int counter) async {
    final row = await customSelect(
      'SELECT payload_hash AS h FROM sync_packets '
      'WHERE origin_device_id = ? AND counter = ?',
      variables: [Variable.withString(deviceId), Variable.withInt(counter)],
    ).getSingleOrNull();
    return row?.readNullable<String>('h');
  }

  /// Hashes this node holds for [deviceId] in the inclusive counter range
  /// [from]..[to]. Sparse by design: counters the node never fetched or has
  /// pruned are simply absent, and the caller compares only the overlap.
  Future<Map<int, String>> syncPacketHashes(
    String deviceId, {
    required int from,
    required int to,
  }) async {
    if (to < from) return {};
    final rows = await customSelect(
      'SELECT counter AS c, payload_hash AS h FROM sync_packets '
      'WHERE origin_device_id = ? AND counter >= ? AND counter <= ? '
      'ORDER BY counter',
      variables: [
        Variable.withString(deviceId),
        Variable.withInt(from),
        Variable.withInt(to),
      ],
    ).get();
    return {
      for (final row in rows)
        if (row.read<String>('h').isNotEmpty)
          row.read<int>('c'): row.read<String>('h'),
    };
  }

  /// Compute the content hash of every packet that lacks one. Batched, because
  /// payloads carry attachments and the whole store will not fit in memory.
  /// Returns how many rows were filled in.
  Future<int> backfillSyncPacketHashes({int batchSize = 100}) async {
    var filled = 0;
    while (true) {
      final rows = await customSelect(
        'SELECT origin_device_id AS d, counter AS c, payload AS p '
        "FROM sync_packets WHERE payload_hash = '' LIMIT ?",
        variables: [Variable.withInt(batchSize)],
      ).get();
      if (rows.isEmpty) return filled;
      await batch((b) {
        for (final row in rows) {
          b.customStatement(
            'UPDATE sync_packets SET payload_hash = ? '
            'WHERE origin_device_id = ? AND counter = ?',
            [
              syncPayloadHash(row.read<Uint8List>('p')),
              row.read<String>('d'),
              row.read<int>('c'),
            ],
          );
        }
      });
      filled += rows.length;
    }
  }

  /// Packets for [deviceId] with counter > [afterCounter], ascending.
  Future<List<SyncPacketRow>> getSyncPacketsAbove(
    String deviceId,
    int afterCounter, {
    int? limit,
  }) {
    final query = select(syncPackets)
      ..where((p) =>
          p.originDeviceId.equals(deviceId) &
          p.counter.isBiggerThanValue(afterCounter))
      ..orderBy([(p) => OrderingTerm.asc(p.counter)]);
    if (limit != null) query.limit(limit);
    return query.get();
  }

  /// All packets this node holds above the requester's vector [have]:
  /// for each device in the store, counters > (have[device] ?? 0), ascending
  /// per device (devices in [have] order-independently). Capped at [limit]
  /// packets total; the caller pages by re-asking with an advanced vector.
  Future<List<SyncPacketRow>> getSyncPacketsAboveVector(
    Map<String, int> have, {
    required int limit,
  }) async {
    final result = <SyncPacketRow>[];
    final vector = await getSyncVector();
    for (final device in vector.keys) {
      if (result.length >= limit) break;
      final after = have[device] ?? 0;
      if (vector[device]! <= after) continue;
      result.addAll(
        await getSyncPacketsAbove(device, after, limit: limit - result.length),
      );
    }
    return result;
  }

  // ============================================================
  // Orphan Retry (sync protocol v2)
  // ============================================================

  /// Record a change that could not apply because its entity (or required
  /// owning task) is missing. Keeps the newest change per entity+field.
  Future<void> upsertSyncOrphan({
    required String entityType,
    required String worldId,
    required String field,
    String? value,
    required String timestamp,
    required bool isCreation,
    String? parentWorldId,
  }) async {
    final existing = await (select(syncOrphans)
          ..where((o) =>
              o.entityType.equals(entityType) &
              o.worldId.equals(worldId) &
              o.field.equals(field)))
        .getSingleOrNull();
    // Compared as instants, not as strings: `toIso8601String` omits the
    // microsecond digits when they are zero, so `.123Z` sorts after `.123456Z`
    // lexically although it is the earlier of the two.
    if (existing != null &&
        !_isoAfter(timestamp, existing.timestamp)) {
      return;
    }
    await into(syncOrphans).insertOnConflictUpdate(
      SyncOrphansCompanion.insert(
        entityType: entityType,
        worldId: worldId,
        field: field,
        value: Value(value),
        timestamp: timestamp,
        isCreation: Value(isCreation ? 1 : 0),
        parentWorldId: Value(parentWorldId),
        firstSeen: existing?.firstSeen ?? nowIso(),
      ),
    );
  }

  /// Whether ISO timestamp [a] is strictly later than [b]; falls back to the
  /// string order for a value that does not parse.
  static bool _isoAfter(String a, String b) {
    final ta = DateTime.tryParse(a);
    final tb = DateTime.tryParse(b);
    if (ta == null || tb == null) return a.compareTo(b) > 0;
    return ta.isAfter(tb);
  }

  Future<List<SyncOrphanRow>> getAllSyncOrphans() {
    return (select(syncOrphans)
          ..orderBy([(o) => OrderingTerm.asc(o.timestamp)]))
        .get();
  }

  Future<void> deleteSyncOrphan(
      String entityType, String worldId, String field) {
    return (delete(syncOrphans)
          ..where((o) =>
              o.entityType.equals(entityType) &
              o.worldId.equals(worldId) &
              o.field.equals(field)))
        .go();
  }

  /// Drop orphans first seen before [cutoffIso] — their missing creation is
  /// presumed permanently lost.
  Future<void> purgeSyncOrphansBefore(String cutoffIso) {
    return (delete(syncOrphans)
          ..where((o) => o.firstSeen.isSmallerThanValue(cutoffIso)))
        .go();
  }

  // ============================================================
  // Sync Operations
  // ============================================================

  /// Insert a sync record
  Future<int> insertSync(int status) {
    return into(syncs).insert(
      SyncsCompanion.insert(
        timestamp: nowIso(),
        status: status,
      ),
    );
  }

  // ============================================================
  // Sync Log (local diagnostics, never synced)
  // ============================================================

  /// Open a sync-log run and return its id.
  Future<int> startSyncLogRun({
    required String trigger,
    String? remote,
    String deviceId = '',
  }) {
    return into(syncLogRuns).insert(SyncLogRunsCompanion.insert(
      startedAt: nowIso(),
      trigger: trigger,
      remote: Value(remote),
      deviceId: Value(deviceId),
    ));
  }

  /// Update a run's outcome and counts. [finished] stamps `finished_at`; a run
  /// that stays open (a peer's session with us) only refreshes its counts.
  Future<void> updateSyncLogRun(
    int id, {
    String? outcome,
    String? error,
    String? remote,
    String? countsJson,
    bool finished = false,
  }) {
    return (update(syncLogRuns)..where((r) => r.id.equals(id))).write(
      SyncLogRunsCompanion(
        outcome: outcome == null ? const Value.absent() : Value(outcome),
        error: error == null ? const Value.absent() : Value(error),
        remote: remote == null ? const Value.absent() : Value(remote),
        countsJson:
            countsJson == null ? const Value.absent() : Value(countsJson),
        finishedAt: finished ? Value(nowIso()) : const Value.absent(),
      ),
    );
  }

  Future<void> insertSyncLogEvents(List<SyncLogEventsCompanion> events) {
    if (events.isEmpty) return Future.value();
    return batch((b) => b.insertAll(syncLogEvents, events));
  }

  /// Newest runs first.
  Future<List<SyncLogRunRow>> getSyncLogRuns({int limit = 200}) {
    return (select(syncLogRuns)
          ..orderBy([(r) => OrderingTerm.desc(r.id)])
          ..limit(limit))
        .get();
  }

  /// Events of one run ([runId]) or of every run, in order. [minLevel] keeps
  /// warnings/errors only; [search] matches kind, message, entity, device,
  /// hashes and previews; [worldIds] adds entities matched by name elsewhere.
  Future<List<SyncLogEventRow>> getSyncLogEvents({
    int? runId,
    int minLevel = 0,
    String? direction,
    String? search,
    Set<String> worldIds = const {},
    int limit = 5000,
  }) {
    final query = select(syncLogEvents);
    query.where((e) {
      Expression<bool> cond = e.level.isBiggerOrEqualValue(minLevel);
      if (runId != null) cond = cond & e.runId.equals(runId);
      if (direction != null) cond = cond & e.direction.equals(direction);
      final text = search?.trim() ?? '';
      if (text.isNotEmpty) {
        final like = '%$text%';
        Expression<bool> match = e.kind.like(like) |
            e.message.like(like) |
            e.worldId.like(like) |
            e.field.like(like) |
            e.originDevice.like(like) |
            e.packetHash.like('$text%') |
            e.valueHash.like('$text%') |
            e.valuePreview.like(like) |
            e.detailJson.like(like);
        if (worldIds.isNotEmpty) match = match | e.worldId.isIn(worldIds);
        cond = cond & match;
      }
      return cond;
    });
    query
      ..orderBy([
        (e) => OrderingTerm.desc(e.runId),
        (e) => OrderingTerm.asc(e.seq),
      ])
      ..limit(limit);
    return query.get();
  }

  /// World ids of tasks and attachments whose name contains [text], so a log
  /// search for "Groceries" finds the events of that node.
  Future<Set<String>> worldIdsMatchingName(String text, {int limit = 200}) async {
    final like = '%${text.trim()}%';
    final rows = await customSelect(
      'SELECT world_id AS w FROM tasks WHERE title LIKE ? '
      'UNION SELECT world_id AS w FROM file WHERE filename LIKE ? '
      'LIMIT ?',
      variables: [
        Variable.withString(like),
        Variable.withString(like),
        Variable.withInt(limit),
      ],
    ).get();
    return {for (final r in rows) r.read<String>('w')};
  }

  /// Mark runs that were still open when the process ended — everything
  /// running that is not in [activeIds] — as interrupted.
  Future<void> closeAbandonedSyncLogRuns(Set<int> activeIds) {
    return (update(syncLogRuns)
          ..where((r) =>
              r.finishedAt.isNull() &
              r.outcome.equals('running') &
              r.id.isNotIn(activeIds)))
        .write(const SyncLogRunsCompanion(outcome: Value('interrupted')));
  }

  /// Keep runs newer than [beforeIso] and at most the newest [keepRuns]; drop
  /// the rest with their events. Returns how many runs were removed.
  Future<int> pruneSyncLog({
    required String beforeIso,
    required int keepRuns,
  }) {
    return transaction(() async {
      final cutoff = await customSelect(
        'SELECT id FROM sync_log_runs ORDER BY id DESC LIMIT 1 OFFSET ?',
        variables: [Variable.withInt(keepRuns - 1)],
      ).getSingleOrNull();
      final minKeptId = cutoff?.read<int>('id') ?? 0;
      final doomed = await customSelect(
        'SELECT id FROM sync_log_runs WHERE started_at < ? OR id < ?',
        variables: [Variable.withString(beforeIso), Variable.withInt(minKeptId)],
      ).get();
      if (doomed.isEmpty) return 0;
      final ids = [for (final r in doomed) r.read<int>('id')];
      await (delete(syncLogEvents)..where((e) => e.runId.isIn(ids))).go();
      await (delete(syncLogRuns)..where((r) => r.id.isIn(ids))).go();
      return ids.length;
    });
  }

  Future<void> clearSyncLog() => transaction(() async {
        await delete(syncLogEvents).go();
        await delete(syncLogRuns).go();
      });

  /// Display names for the entities of log events, by world id. Tasks and
  /// attachments by name; time entries by their task.
  Future<Map<String, String>> syncLogLabels(Set<String> worldIds) async {
    if (worldIds.isEmpty) return const {};
    final labels = <String, String>{};
    final ids = worldIds.toList();
    for (var i = 0; i < ids.length; i += 500) {
      final chunk = ids.sublist(i, i + 500 > ids.length ? ids.length : i + 500);
      final marks = List.filled(chunk.length, '?').join(',');
      final vars = [for (final id in chunk) Variable.withString(id)];
      final rows = await customSelect(
        'SELECT world_id AS w, title AS n FROM tasks WHERE world_id IN ($marks) '
        'UNION ALL SELECT world_id AS w, filename AS n FROM file '
        'WHERE world_id IN ($marks) '
        "UNION ALL SELECT t.world_id AS w, 'Time on \"' || k.title || '\"' AS n "
        'FROM timeline t JOIN tasks k ON k.id = t.task_id '
        'WHERE t.world_id IN ($marks)',
        variables: [...vars, ...vars, ...vars],
      ).get();
      for (final r in rows) {
        labels[r.read<String>('w')] = r.read<String>('n');
      }
    }
    return labels;
  }

  /// Get all sync records
  Future<List<Sync>> getAllSyncs() {
    return (select(syncs)
          ..orderBy([(s) => OrderingTerm.desc(s.timestamp)]))
        .get();
  }

  /// Get last successful sync (status == 1)
  Future<Sync?> getLastSuccessfulSync() {
    return (select(syncs)
          ..where((s) => s.status.equals(1))
          ..orderBy([(s) => OrderingTerm.desc(s.timestamp)])
          ..limit(1))
        .getSingleOrNull();
  }
}
