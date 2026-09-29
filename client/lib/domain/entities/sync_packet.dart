import 'dart:convert';

/// Represents a single field change in a sync packet
class SyncChange {
  final String entityType;    // 'task', 'file', 'timeline'
  final String worldId;
  final String field;
  final String? value;        // full current value (not diff)
  final String timestamp;     // ISO8601 UTC
  final bool isCreation;
  final String? parentWorldId; // for tasks only

  const SyncChange({
    required this.entityType,
    required this.worldId,
    required this.field,
    this.value,
    required this.timestamp,
    this.isCreation = false,
    this.parentWorldId,
  });

  Map<String, dynamic> toJson() => {
    'entity_type': entityType,
    'world_id': worldId,
    'field': field,
    'value': value,
    'timestamp': timestamp,
    'is_creation': isCreation,
    if (parentWorldId != null) 'parent_world_id': parentWorldId,
  };

  factory SyncChange.fromJson(Map<String, dynamic> json) => SyncChange(
    entityType: json['entity_type'] as String,
    worldId: json['world_id'] as String,
    field: json['field'] as String,
    value: json['value'] as String?,
    timestamp: json['timestamp'] as String,
    isCreation: json['is_creation'] as bool? ?? false,
    parentWorldId: json['parent_world_id'] as String?,
  );
}

/// A reference to attachment bytes stored outside the packet, by content
/// (docs/P2P_SYNC.md §3.5). On the wire a `file.content` value is either the
/// v2 form — the whole file, base64 — or this: `blob:<sha256 hex>`.
///
/// Splitting content out of the log is what stops the log growing with the
/// size of what is attached: a packet names the bytes, every node stores them
/// once under that name, and the same file attached twice, or re-sent after a
/// rename, costs nothing the second time.
class BlobRef {
  static const String _prefix = 'blob:';

  /// Content identity: lowercase hex SHA-256 of the plaintext.
  final String id;

  const BlobRef(this.id);

  String encode() => '$_prefix$id';

  /// The reference a `file.content` value carries, or null for a v2 inline
  /// value (or no value at all).
  static BlobRef? tryParse(String? value) {
    if (value == null || !value.startsWith(_prefix)) return null;
    final id = value.substring(_prefix.length);
    return isValidId(id) ? BlobRef(id) : null;
  }

  static final _hex64 = RegExp(r'^[0-9a-f]{64}$');
  static bool isValidId(String id) => _hex64.hasMatch(id);
}

/// A packet of changes to be synced.
///
/// Protocol v2: a packet is globally identified by (deviceId, counter), where
/// [counter] is a client-assigned monotonic integer, contiguous per origin
/// device. The identity also travels outside the ciphertext (store keys,
/// upload metadata) and is bound to it via the AEAD AAD.
///
/// Version 3 differs from 2 in exactly one field: `file.content` is a
/// [BlobRef] rather than the inline base64 bytes. Receivers accept both;
/// senders emit 3. A v2 receiver skips a v3 packet unread (and its vector
/// moves past it), so a fleet must update together — the same condition
/// compaction already imposes.
class SyncPacket {
  static const int currentVersion = 3;

  /// Versions this build can apply.
  static const Set<int> acceptedVersions = {2, 3};

  /// Every blob this packet's changes reference, in order of first mention.
  /// What a node must hold to apply the packet in full, and what it declares
  /// when uploading so the relay can keep those blobs alive (§3.5).
  List<String> get blobIds {
    final seen = <String>{};
    final ids = <String>[];
    for (final c in changes) {
      if (c.entityType != 'file' || c.field != 'content') continue;
      final ref = BlobRef.tryParse(c.value);
      if (ref != null && seen.add(ref.id)) ids.add(ref.id);
    }
    return ids;
  }

  final int version;
  final String deviceId;
  final String timestamp;
  final int counter;
  final List<SyncChange> changes;

  /// The sender's applied version vector at packaging time: {device →
  /// highest counter applied}. Says what the sender had *seen* when it made
  /// these changes, which is what turns "my value lost LWW" into "my value
  /// lost to a concurrent edit" (the conflict-copy trigger). Optional and
  /// ignored by pre-vector clients, so no version bump; null when absent.
  final Map<String, int>? vector;

  /// True for a full-state re-announce (v1→v2 migration, fork recovery): the
  /// packet echoes the sender's entire current state rather than fresh edits.
  /// Receivers suppress conflict copies for such packets — a stale echoed
  /// value losing LWW is not a concurrent edit. Optional on the wire, so
  /// pre-flag clients interoperate unchanged.
  final bool fullState;

  const SyncPacket({
    this.version = currentVersion,
    required this.deviceId,
    required this.counter,
    required this.timestamp,
    required this.changes,
    this.vector,
    this.fullState = false,
  });

  Map<String, dynamic> toJson() => {
    'version': version,
    'device_id': deviceId,
    'counter': counter,
    'timestamp': timestamp,
    'changes': changes.map((c) => c.toJson()).toList(),
    if (vector != null) 'vector': vector,
    if (fullState) 'full_state': true,
  };

  factory SyncPacket.fromJson(Map<String, dynamic> json) => SyncPacket(
    version: json['version'] as int,
    deviceId: json['device_id'] as String,
    counter: json['counter'] as int? ?? 0,
    timestamp: json['timestamp'] as String,
    changes: (json['changes'] as List)
        .map((c) => SyncChange.fromJson(c as Map<String, dynamic>))
        .toList(),
    vector: (json['vector'] as Map<String, dynamic>?)
        ?.map((k, v) => MapEntry(k, v as int)),
    fullState: json['full_state'] as bool? ?? false,
  );

  /// Serialize to JSON string
  String serialize() => jsonEncode(toJson());

  /// Deserialize from JSON string
  factory SyncPacket.deserialize(String data) =>
      SyncPacket.fromJson(jsonDecode(data) as Map<String, dynamic>);
}
