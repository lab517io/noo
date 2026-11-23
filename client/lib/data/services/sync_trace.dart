import 'dart:convert';

import '../database/database.dart';

/// How a sync change got here: the packet that carried it, the route that
/// packet took, and what this device decided about each field. Shown when a
/// row of a sync report is opened.
///
/// Everything here is known at the moment the change is applied or packaged —
/// it is kept rather than looked up, so the report needs no second pass over
/// the log.

/// How a packet reached (or left) this device.
enum SyncPacketRoute {
  /// Pulled from the relay in this run.
  relay,

  /// Pulled from a LAN peer in this run.
  peer,

  /// Already in this device's packet store — an earlier exchange delivered it
  /// and this run applied it (the backlog).
  stored,

  /// Packaged on this device in this run.
  packaged,

  /// Served to a LAN peer that pulled it from this device.
  served,
}

/// One packet, as far as a report needs to describe it.
class SyncPacketTrace {
  /// The device that wrote the packet — its author, not whoever forwarded it.
  final String originDeviceId;
  final int counter;

  /// SHA-256 of the ciphertext, the packet's identity on the wire.
  final String? hash;

  /// Ciphertext size.
  final int? bytes;

  /// When the author packaged it, by the author's clock.
  final String? createdAt;

  /// A compaction snapshot: the author's whole database, not an edit.
  final bool fullState;

  /// How many field changes the packet carries in all.
  final int? changeCount;

  final SyncPacketRoute route;

  /// The LAN peer it came from ([SyncPacketRoute.peer]) or went to
  /// ([SyncPacketRoute.served]).
  final String? peerDeviceId;

  /// When the relay stored it ([SyncPacketRoute.relay]).
  final String? relayStoredAt;

  /// For a packet applied from the store ([SyncPacketRoute.stored]): when it
  /// arrived, and from where as the sync log remembers it (`relay …`,
  /// `peer …`). Both null when the log no longer does.
  final String? receivedAt;
  final String? receivedFrom;

  /// What became of a packaged packet on the relay: `stored`, `alreadyHeld`,
  /// or `blocked` when an attachment it needs could not go up. Null when it
  /// was not offered to one (LAN only, or a run without a relay).
  final String? upload;

  /// Names for [originDeviceId] and [peerDeviceId], resolved when the report
  /// is built. Null when this device has never learned one.
  final String? originName;
  final String? peerName;

  const SyncPacketTrace({
    required this.originDeviceId,
    required this.counter,
    required this.route,
    this.hash,
    this.bytes,
    this.createdAt,
    this.fullState = false,
    this.changeCount,
    this.peerDeviceId,
    this.relayStoredAt,
    this.receivedAt,
    this.receivedFrom,
    this.upload,
    this.originName,
    this.peerName,
  });

  /// `device:counter`, the packet's identity.
  String get id => '$originDeviceId:$counter';

  /// Came through a peer that did not write it — gossip.
  bool get forwarded =>
      (route == SyncPacketRoute.peer || route == SyncPacketRoute.served) &&
      peerDeviceId != null &&
      peerDeviceId != originDeviceId;

  SyncPacketTrace copyWith({
    String? upload,
    String? originName,
    String? peerName,
    String? receivedAt,
    String? receivedFrom,
  }) =>
      SyncPacketTrace(
        originDeviceId: originDeviceId,
        counter: counter,
        route: route,
        hash: hash,
        bytes: bytes,
        createdAt: createdAt,
        fullState: fullState,
        changeCount: changeCount,
        peerDeviceId: peerDeviceId,
        relayStoredAt: relayStoredAt,
        receivedAt: receivedAt ?? this.receivedAt,
        receivedFrom: receivedFrom ?? this.receivedFrom,
        upload: upload ?? this.upload,
        originName: originName ?? this.originName,
        peerName: peerName ?? this.peerName,
      );
}

/// What happened to one field of one entity.
class SyncFieldTrace {
  final String field;

  /// The decision, as a [SyncLogKind] string: `applied`, `created`,
  /// `conflict-copy`, `cycle-to-root`, `change-out`, …
  final String decision;

  /// The change's own timestamp — what last-writer-wins compared.
  final String? remoteTs;

  /// This device's timestamp for the same field, when it had one to compare.
  final String? localTs;

  /// A short, readable form of the new value.
  final String? value;

  /// Why, in words, when the decision needs more than its name.
  final String? message;

  final SyncPacketTrace? packet;

  const SyncFieldTrace({
    required this.field,
    required this.decision,
    this.remoteTs,
    this.localTs,
    this.value,
    this.message,
    this.packet,
  });

  SyncFieldTrace withPacket(SyncPacketTrace? packet) => SyncFieldTrace(
        field: field,
        decision: decision,
        remoteTs: remoteTs,
        localTs: localTs,
        value: value,
        message: message,
        packet: packet,
      );
}

/// Where an attachment's bytes stand after the run.
enum SyncBlobState {
  /// Downloaded in this run.
  arrived,

  /// Referenced, not downloaded yet — later, or when opened.
  waiting,

  /// Already on this device (the same bytes are attached elsewhere).
  held,

  /// Uploaded to the relay in this run.
  uploaded,

  /// The relay had them already.
  onRelay,

  /// On this device, for peers to fetch.
  offered,
}

/// One attachment's bytes, referenced by a file change.
class SyncBlobTrace {
  /// SHA-256 of the plaintext (`blob:<id>`).
  final String id;
  final SyncBlobState state;

  /// Bytes that came off (or went on) the wire, when known.
  final int? bytes;

  /// Where they came from, as the source names itself.
  final String? source;

  const SyncBlobTrace({
    required this.id,
    required this.state,
    this.bytes,
    this.source,
  });
}

/// Device ids this database has seen, with the names they go by.
///
/// Stored per database in `properties`, local only: it is filled from the
/// relay's device list and from the names LAN peers announce, and read when a
/// report is built, so a packet says "from Laptop" rather than a UUID.
class SyncDeviceNames {
  SyncDeviceNames(this._db);

  final NooDatabase _db;

  static const String propertyKey = 'sync_device_names';

  Map<String, String>? _cache;

  Future<Map<String, String>> all() async {
    final cached = _cache;
    if (cached != null) return cached;
    final raw = await _db.getProperty(propertyKey);
    var names = <String, String>{};
    if (raw != null && raw.isNotEmpty) {
      try {
        names = (jsonDecode(raw) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, '$v'));
      } catch (_) {
        // A damaged entry costs names, not a sync.
      }
    }
    return _cache = names;
  }

  Future<String?> nameOf(String deviceId) async => (await all())[deviceId];

  /// Record names; blank names and unchanged entries are ignored.
  Future<void> remember(Map<String, String?> names) async {
    final current = Map<String, String>.of(await all());
    var changed = false;
    names.forEach((id, name) {
      final trimmed = name?.trim();
      if (id.isEmpty || trimmed == null || trimmed.isEmpty) return;
      if (current[id] == trimmed) return;
      current[id] = trimmed;
      changed = true;
    });
    if (!changed) return;
    _cache = current;
    await _db.setProperty(propertyKey, jsonEncode(current));
  }
}
