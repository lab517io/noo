import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../domain/entities/history_entry.dart';
import '../../domain/entities/sync_packet.dart';
import '../database/database.dart';

/// Packages local history entries into sync packets.
/// Handles coalescing (only latest value per entity+field) and
/// resolving full current values (sync sends full values, not diffs).
class SyncChangePackager {
  final NooDatabase _db;

  SyncChangePackager(this._db);

  String _keyFor(HistoryEntry entry) =>
      '${entry.entityType.name}:${entry.worldId ?? entry.entityId}:${entry.field}';

  /// Coalesce history entries: keep only the latest change per entity+field.
  /// Key = "entityType:worldId:field"
  Map<String, HistoryEntry> coalesce(List<HistoryEntry> entries) {
    final map = <String, HistoryEntry>{};
    for (final entry in entries) {
      // Keep the latest entry (entries are sorted by timestamp)
      map[_keyFor(entry)] = entry;
    }
    return map;
  }

  /// Keys whose history includes a creation. A rename after creation would
  /// otherwise coalesce down to a plain update, and the receiving device
  /// would skip it ("entity doesn't exist and isn't a creation"), leaving the
  /// task with an empty title. Carrying the creation flag forward fixes that.
  Set<String> _creationKeys(List<HistoryEntry> entries) {
    final keys = <String>{};
    for (final entry in entries) {
      if (entry.isCreation) keys.add(_keyFor(entry));
    }
    return keys;
  }

  /// Package coalesced history entries into a SyncPacket identified by
  /// ([deviceId], [counter]). Resolves full current values from the database.
  Future<SyncPacket?> packageChanges({
    required List<HistoryEntry> entries,
    required String deviceId,
    required int counter,
    Map<String, int>? vector,
  }) async {
    if (entries.isEmpty) return null;

    final coalesced = coalesce(entries);
    final creationKeys = _creationKeys(entries);
    final changes = <SyncChange>[];

    for (final mapEntry in coalesced.entries) {
      final isCreation = creationKeys.contains(mapEntry.key);
      final change = await _resolveChange(mapEntry.value, isCreation);
      if (change != null) {
        changes.add(change);
      }
    }

    if (changes.isEmpty) return null;

    return SyncPacket(
      deviceId: deviceId,
      counter: counter,
      timestamp: DateTime.now().toUtc().toIso8601String(),
      changes: changes,
      vector: vector,
    );
  }

  /// What a `file.content` change carries on the wire (docs/P2P_SYNC.md
  /// §3.5): a [BlobRef] to the bytes, never the bytes. The hash is normally
  /// already on the row; a row that has bytes but no hash (written before the
  /// column existed, on a database whose backfill was interrupted) is hashed
  /// here rather than left out. A row with no bytes and no hash has no content
  /// to speak of; a row with a hash and no bytes is a reference this node is
  /// still fetching, and it forwards the reference as-is — the bytes are
  /// somewhere in the fleet even if not here.
  static String? _contentRef(FileEntry f) {
    var hash = f.contentHash;
    if (hash.isEmpty) {
      if (f.content == null) return null;
      hash = NooDatabase.blobId(f.content!);
    }
    return BlobRef(hash).encode();
  }

  /// Whether a `content` change for [f] may be published at all.
  ///
  /// A soft-deleted attachment whose bytes this device has collected
  /// ([NooDatabase.collectRemovedBlobs]) still names its blob, but cannot
  /// supply it — and the relay refuses a packet declaring a blob it does not
  /// hold (§3.5), which would stop that stream at this packet. Its content is
  /// not part of current state anyway: the deletion is what has to propagate.
  ///
  /// Deliberately narrower than "removed": a deleted attachment that still
  /// has its bytes publishes them as before, so nothing changes for a device
  /// that never collects.
  static bool _canPublishContent(FileEntry f) =>
      !(f.removed == 1 && f.content == null);

  /// Build creation changes for the entire current database state — every
  /// task, file, and timeline record (soft-removed ones included, so deletions
  /// propagate). Used for the v1→v2 migration and for fork recovery
  /// (docs/P2P_SYNC.md §11.2): the packet re-announces current state as a
  /// fresh stream.
  ///
  /// Each field carries its latest history timestamp (falling back to the
  /// row's timestamp) rather than now(), so LWW against other devices resolves
  /// exactly as it would have without the re-package.
  Future<List<SyncChange>> buildFullStateChanges() async {
    final changes = <SyncChange>[];

    Future<String> taskFieldTs(TaskRow t, String field) async =>
        (await _db.getLatestTaskHistoryForField(t.id, field))?.timestamp ??
        t.timestamp;

    final taskById = <int, TaskRow>{};
    final tasks = await _db.getAllTaskRows();
    for (final t in tasks) {
      taskById[t.id] = t;
    }

    for (final t in tasks) {
      if (t.worldId.isEmpty) continue;
      final parentWorldId =
          t.parentId != null ? taskById[t.parentId!]?.worldId : null;
      Future<void> add(String field, String? value) async {
        changes.add(SyncChange(
          entityType: 'task',
          worldId: t.worldId,
          field: field,
          value: value,
          timestamp: _iso(await taskFieldTs(t, field)),
          isCreation: true,
          parentWorldId: parentWorldId,
        ));
      }

      await add('title', t.title);
      if (t.content != null) await add('content', t.content);
      await add('parentId', parentWorldId);
      await add('orderId', t.orderId.toString());
      await add('flags', t.flags.toString());
      await add('removed', t.removed.toString());
    }

    for (final f in await _db.getAllFileRows()) {
      if (f.worldId.isEmpty) continue;
      final ownerWorldId = taskById[f.taskId]?.worldId;
      if (ownerWorldId == null) continue;
      Future<String> ts(String field) async =>
          (await _db.getLatestFileHistoryForField(f.id, field))?.timestamp ??
          f.timestamp;
      Future<void> add(String field, String? value) async {
        changes.add(SyncChange(
          entityType: 'file',
          worldId: f.worldId,
          field: field,
          value: value,
          timestamp: _iso(await ts(field)),
          isCreation: true,
          parentWorldId: ownerWorldId,
        ));
      }

      await add('filename', f.filename);
      final ref = _canPublishContent(f) ? _contentRef(f) : null;
      if (ref != null) await add('content', ref);
      await add('orderId', f.orderId.toString());
      await add('removed', f.removed.toString());
    }

    for (final r in await _db.getAllTimelineRows()) {
      if (r.worldId.isEmpty) continue;
      final ownerWorldId = taskById[r.taskId]?.worldId;
      if (ownerWorldId == null) continue;
      Future<String> ts(String field) async =>
          (await _db.getLatestTimelineHistoryForField(r.id, field))
              ?.timestamp ??
          r.timestamp;
      Future<void> add(String field, String? value) async {
        changes.add(SyncChange(
          entityType: 'timeline',
          worldId: r.worldId,
          field: field,
          value: value,
          timestamp: _iso(await ts(field)),
          isCreation: true,
          parentWorldId: ownerWorldId,
        ));
      }

      await add('taskId', ownerWorldId);
      await add('startTime', r.startTime);
      if (r.endTime != null) await add('endTime', r.endTime);
      await add('removed', r.removed.toString());
    }

    return changes;
  }

  /// Normalize a stored timestamp to ISO-8601 UTC for the wire.
  String _iso(String stored) {
    final dt = DateTime.tryParse(stored);
    return dt == null ? stored : dt.toUtc().toIso8601String();
  }

  /// Resolve a history entry to a SyncChange with full current values.
  Future<SyncChange?> _resolveChange(HistoryEntry entry, bool isCreation) async {
    switch (entry.entityType) {
      case HistoryEntityType.task:
        return _resolveTaskChange(entry, isCreation);
      case HistoryEntityType.file:
        return _resolveFileChange(entry, isCreation);
      case HistoryEntityType.timeline:
        return _resolveTimelineChange(entry, isCreation);
    }
  }

  Future<SyncChange?> _resolveTaskChange(HistoryEntry entry, bool isCreation) async {
    final task = await _db.getTaskById(entry.entityId);
    if (task == null) return null;

    String? value;
    String? parentWorldId;

    // Resolve full current value based on field
    switch (entry.field) {
      case 'title':
        value = task.title;
        break;
      case 'content':
        value = task.content;
        break;
      case 'parentId':
        if (task.parentId != null) {
          final parent = await _db.getTaskById(task.parentId!);
          parentWorldId = parent?.worldId;
          value = parent?.worldId;
        } else {
          value = null; // root level
        }
        break;
      case 'orderId':
        value = task.orderId.toString();
        break;
      case 'flags':
        value = task.flags.toString();
        break;
      case 'removed':
        value = task.removed.toString();
        break;
      default:
        return null;
    }

    // For creation, also resolve parent worldId
    if (isCreation && task.parentId != null && parentWorldId == null) {
      final parent = await _db.getTaskById(task.parentId!);
      parentWorldId = parent?.worldId;
    }

    return SyncChange(
      entityType: 'task',
      worldId: task.worldId,
      field: entry.field,
      value: value,
      timestamp: entry.timestamp.toUtc().toIso8601String(),
      isCreation: isCreation,
      parentWorldId: parentWorldId,
    );
  }

  Future<SyncChange?> _resolveFileChange(HistoryEntry entry, bool isCreation) async {
    // For files, we need to look up by fileId
    final file = await _db.getAttachmentWithContent(entry.entityId);
    if (file == null) return null;

    String? value;
    switch (entry.field) {
      case 'filename':
        value = file.filename;
        break;
      case 'content':
        // Nothing to publish for a collected, deleted attachment — and
        // publishing a reference we cannot serve would stall the stream.
        if (!_canPublishContent(file)) return null;
        value = _contentRef(file);
        break;
      case 'orderId':
        value = file.orderId.toString();
        break;
      case 'removed':
        value = file.removed.toString();
        break;
      default:
        return null;
    }

    // Resolve task worldId for file association
    final task = await _db.getTaskById(file.taskId);

    return SyncChange(
      entityType: 'file',
      worldId: file.worldId,
      field: entry.field,
      value: value,
      timestamp: entry.timestamp.toUtc().toIso8601String(),
      isCreation: isCreation,
      parentWorldId: task?.worldId, // task that owns the file
    );
  }

  Future<SyncChange?> _resolveTimelineChange(HistoryEntry entry, bool isCreation) async {
    final record = await _db.getTimeRecordById(entry.entityId);
    if (record == null) return null;

    String? value;
    switch (entry.field) {
      case 'taskId':
        // Resolve to task worldId
        final task = await _db.getTaskById(record.taskId);
        value = task?.worldId;
        break;
      case 'startTime':
        value = record.startTime;
        break;
      case 'endTime':
        value = record.endTime;
        break;
      case 'removed':
        value = record.removed.toString();
        break;
      default:
        return null;
    }

    // Resolve task worldId
    final task = await _db.getTaskById(record.taskId);

    return SyncChange(
      entityType: 'timeline',
      worldId: record.worldId,
      field: entry.field,
      value: value,
      timestamp: entry.timestamp.toUtc().toIso8601String(),
      isCreation: isCreation,
      parentWorldId: task?.worldId, // task that owns the time record
    );
  }

  /// Compress a JSON string using gzip
  Uint8List compress(String json) {
    return Uint8List.fromList(gzip.encode(utf8.encode(json)));
  }

  /// Decompress gzipped data to a JSON string
  String decompress(Uint8List data) {
    return utf8.decode(gzip.decode(data));
  }
}
