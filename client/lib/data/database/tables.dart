import 'package:drift/drift.dart';

/// Tasks table - hierarchical task/outline nodes
/// Matches Qt schema: task table
///
/// `world_id` is the sync-side identity: applying a remote change looks the
/// entity up by it once per field, so an unindexed lookup costs a full scan
/// per change. `parent_id` backs the tree load, one query per expanded node.
@DataClassName('TaskRow')
@TableIndex(name: 'idx_tasks_world_id', columns: {#worldId})
@TableIndex(name: 'idx_tasks_parent_id', columns: {#parentId})
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get parentId => integer().nullable()();
  TextColumn get worldId => text().withDefault(const Constant(''))();
  IntColumn get orderId => integer().withDefault(const Constant(0))();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get content => text().nullable()();
  IntColumn get flags => integer().withDefault(const Constant(0))();
  TextColumn get timestamp => text()();
  IntColumn get removed => integer().withDefault(const Constant(0))();
}

/// Timeline table - time tracking intervals
/// Matches Qt schema: timeline table
@DataClassName('TimelineEntry')
@TableIndex(name: 'idx_timeline_world_id', columns: {#worldId})
@TableIndex(name: 'idx_timeline_task_id', columns: {#taskId})
class Timeline extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer()();
  TextColumn get worldId => text().withDefault(const Constant(''))();
  TextColumn get startTime => text()();
  TextColumn get endTime => text().nullable()();
  TextColumn get timestamp => text()();
  IntColumn get removed => integer().withDefault(const Constant(0))();
}

/// Files table - attachments stored as BLOBs
/// Matches Qt schema: file table
@DataClassName('FileEntry')
@TableIndex(name: 'idx_file_world_id', columns: {#worldId})
@TableIndex(name: 'idx_file_task_id', columns: {#taskId})
@TableIndex(name: 'idx_file_content_hash', columns: {#contentHash})
class Files extends Table {
  @override
  String get tableName => 'file';

  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer()();
  TextColumn get worldId => text().withDefault(const Constant(''))();
  TextColumn get filename => text().withDefault(const Constant(''))();
  BlobColumn get content => blob().nullable()();

  /// SHA-256 of [content], lowercase hex — the attachment's identity in the
  /// sync blob store (docs/P2P_SYNC.md §3.5). Packets carry this instead of
  /// the bytes, and this table doubles as the node's blob store: any row with
  /// this hash and a non-null content can serve the bytes.
  ///
  /// A row with a hash but **null content** is an attachment this device knows
  /// about but has not fetched yet — the reference arrived in a packet, the
  /// bytes come separately, from whichever node has them.
  TextColumn get contentHash => text().withDefault(const Constant(''))();
  IntColumn get orderId => integer().withDefault(const Constant(0))();
  TextColumn get timestamp => text()();
  IntColumn get removed => integer().withDefault(const Constant(0))();
}

/// Properties table - key/value configuration
/// Matches Qt schema: properties table
class Properties extends Table {
  TextColumn get type => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {type};
}

/// History table for task changes (sync/audit)
/// Matches Qt schema: history_task table
///
/// The (entity, field, timestamp) index serves the field-level LWW lookup —
/// "latest history row for this entity+field" — which runs once per incoming
/// change and would otherwise scan the whole table. Ordering by timestamp in
/// the index also removes the sort. It doubles as the entity-history index,
/// since (entity) is a prefix of it.
@TableIndex(
    name: 'idx_history_task_lookup', columns: {#taskId, #field, #timestamp})
class HistoryTask extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId => integer()();
  TextColumn get worldId => text().withDefault(const Constant(''))();
  TextColumn get field => text()();
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
  TextColumn get timestamp => text()();

  /// 1 when this row was produced by applying a change pulled from another
  /// device. Remote-origin rows are excluded from push (no echo) but still
  /// participate in conflict resolution.
  IntColumn get isRemote => integer().withDefault(const Constant(0))();
}

/// History table for file changes (sync/audit)
/// Matches Qt schema: history_file table
@TableIndex(
    name: 'idx_history_file_lookup', columns: {#fileId, #field, #timestamp})
class HistoryFile extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get fileId => integer()();
  TextColumn get worldId => text().withDefault(const Constant(''))();
  TextColumn get field => text()();
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
  TextColumn get timestamp => text()();
  IntColumn get isRemote => integer().withDefault(const Constant(0))();
}

/// History table for timeline changes (sync/audit)
@TableIndex(
    name: 'idx_history_timeline_lookup',
    columns: {#timelineId, #field, #timestamp})
class HistoryTimeline extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get timelineId => integer()();
  TextColumn get worldId => text().withDefault(const Constant(''))();
  TextColumn get field => text()();
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
  TextColumn get timestamp => text()();
  IntColumn get isRemote => integer().withDefault(const Constant(0))();
}

/// Sync status tracking
/// Matches Qt schema: syncs table
class Syncs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get timestamp => text()();
  IntColumn get status => integer()();
}

/// Packet store (sync protocol v2): every encrypted sync packet this node
/// holds — its own and other devices' — keyed by (origin device, counter).
/// Payloads are stored verbatim as received/created (ciphertext; the database
/// file itself is SQLCipher-encrypted), so any copy on any node is
/// byte-identical and AAD-verifiable. Holdings per device are contiguous
/// counter prefixes, so `max(counter)` per device is the node's version vector.
@DataClassName('SyncPacketRow')
class SyncPackets extends Table {
  TextColumn get originDeviceId => text()();
  IntColumn get counter => integer()();
  BlobColumn get payload => blob()();

  /// Local receive/creation time (informational only).
  TextColumn get storedAt => text()();

  /// SHA-256 of [payload], lowercase hex — the packet's *content* identity,
  /// as opposed to the `(origin device, counter)` slot it occupies.
  ///
  /// The slot rule (docs/P2P_SYNC.md §5.2) assumes an occupied slot always
  /// holds the same bytes everywhere, and treats a second arrival as a
  /// duplicate. A device restored from a backup breaks that assumption: it
  /// re-issues counters it has already used, with different content. Keeping
  /// the hash lets a node say which of the two it means, so divergence is a
  /// detectable event at a named counter rather than a silent no-op.
  ///
  /// Empty for rows written before the column existed and never re-hashed —
  /// treated as "unknown", never as a mismatch.
  TextColumn get payloadHash => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {originDeviceId, counter};
}

/// Changes skipped because their target entity (or required owning task) did
/// not exist yet. Per-device streams carry no cross-device ordering, so an
/// edit can arrive before its entity's creation; these rows are retried after
/// every sync exchange and aged out after 30 days.
@DataClassName('SyncOrphanRow')
class SyncOrphans extends Table {
  TextColumn get entityType => text()();
  TextColumn get worldId => text()();
  TextColumn get field => text()();
  TextColumn get value => text().nullable()();
  TextColumn get timestamp => text()();
  IntColumn get isCreation => integer().withDefault(const Constant(0))();
  TextColumn get parentWorldId => text().nullable()();
  TextColumn get firstSeen => text()();

  @override
  Set<Column> get primaryKey => {entityType, worldId, field};
}

/// For each of this device's own sync packets, the highest task-history row
/// id it packaged. Translates a sender's version-vector entry for us ("I had
/// applied your packets up to counter v") into "had that sender seen this
/// local history row" — the causal test behind conflict copies
/// (docs/P2P_SYNC.md §8.3). Only own packets are recorded.
class SyncPushLog extends Table {
  IntColumn get counter => integer()();
  IntColumn get taskHistoryId => integer()();

  @override
  Set<Column> get primaryKey => {counter};
}

/// Ciphertext of an attachment blob this device is part-way through fetching
/// (docs/P2P_SYNC.md §3.5).
///
/// A blob is one AES-256-GCM ciphertext, so a range can be transferred but not
/// verified on its own — the tag covers the whole thing. Chunks therefore
/// accumulate here until the blob is complete, at which point it is decrypted,
/// checked against its content id, and the row is dropped. Persisting rather
/// than buffering in memory is the point: it is what lets a transfer that a
/// phone interrupted resume on the next exchange instead of starting over.
class BlobFetches extends Table {
  /// Content id of the blob being fetched — sha256 of the *plaintext*, so the
  /// row is named by what it will become, not by what it holds.
  TextColumn get hash => text()();

  /// Ciphertext received so far, always a prefix starting at offset 0.
  BlobColumn get received => blob()();

  /// Full ciphertext length, once a node has said what it is. Null while no
  /// answer has reported one.
  IntColumn get total => integer().nullable()();

  /// When this row last grew. Stale rows are dropped rather than resumed: the
  /// node holding the blob may have re-encrypted it since.
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {hash};
}
