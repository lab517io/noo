import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';

import '../database/database.dart';
import 'peer_api_client.dart';
import 'peer_discovery.dart';
import 'peer_sync_server.dart';
import 'sync_crypto.dart';
import 'sync_journal.dart';
import 'sync_service.dart';

/// Where one peer stands within a Sync P2P session.
enum LanPeerState {
  /// Seen on the network; the exchange has not started yet.
  found,

  /// An exchange with this peer is running.
  syncing,

  /// Exchanged with this session.
  synced,

  /// The exchange failed; [LanPeerStatus.error] says why.
  failed,
}

/// One device in the Sync P2P dialog.
class LanPeerStatus {
  final String deviceId;

  /// The name the peer announced when it authenticated with us, if it has.
  final String? deviceName;

  final String? address;
  final LanPeerState state;

  /// Changes applied locally from this peer this session.
  final int changesApplied;

  final String? error;

  const LanPeerStatus({
    required this.deviceId,
    this.deviceName,
    this.address,
    this.state = LanPeerState.found,
    this.changesApplied = 0,
    this.error,
  });

  /// Device name when announced, otherwise the id.
  String get label {
    final name = deviceName?.trim();
    return (name == null || name.isEmpty) ? deviceId : name;
  }

  LanPeerStatus copyWith({
    String? deviceName,
    String? address,
    LanPeerState? state,
    int? changesApplied,
    String? error,
  }) =>
      LanPeerStatus(
        deviceId: deviceId,
        deviceName: deviceName ?? this.deviceName,
        address: address ?? this.address,
        state: state ?? this.state,
        changesApplied: changesApplied ?? this.changesApplied,
        // Cleared unless given: a new state is a new story.
        error: error,
      );
}

/// Orchestrates LAN peer sync (docs/P2P_SYNC.md §9–10).
///
/// Works like the relay path in one respect that matters: nothing happens
/// until someone asks. The peer server and UDP discovery exist only for the
/// life of a *session* — [startSession] when the user opens Sync P2P,
/// [stopSession] when they close it. Outside a session this device neither
/// broadcasts nor listens, so it is invisible on the network.
///
/// Within a session every peer found is synced with automatically: both users
/// opened Sync P2P, which is all the consent an exchange needs. Each exchange
/// pulls from the peer and then asks it to pull back (§9.5), so one exchange
/// converges both devices. To avoid both sides doing that at once, the device
/// with the lower id leads; the other waits [followerGrace] for the leader's
/// request and only starts its own exchange if none arrived — which covers a
/// broadcast that reached one side but not the other.
///
/// Fully independent of the relay path — both feed the same packet store, and
/// whichever delivers a packet first wins the no-op race; the other path
/// deduplicates on the (device, counter) identity.
class LanSyncCoordinator {
  final NooDatabase _db;
  final SyncCrypto _crypto;
  final SyncService _syncService;
  final String _deviceId;
  final String? _deviceName;

  /// Records what this device serves to peers (see [PeerSyncServer.journal]).
  final SyncJournal? journal;

  /// How long the follower of a pair waits for the leader's exchange before
  /// starting its own.
  final Duration followerGrace;

  PeerSyncServer? _server;
  PeerDiscovery? _discovery;

  /// Serializes exchanges so two never interleave against the same packet
  /// store — the one this device starts and the one a peer asks for can
  /// otherwise arrive together.
  Future<void> _chain = Future<void>.value();

  /// Bumped by every [startSession] and [stopSession], so work scheduled by
  /// one session (a follower's grace timer, a detached exchange) does not
  /// report into the next.
  int _generation = 0;

  final Map<String, LanPeerStatus> _statuses = {};
  final Map<String, LanPeer> _peers = {};

  final StreamController<int> _appliedController =
      StreamController<int>.broadcast();
  final StreamController<List<LanPeerStatus>> _statusController =
      StreamController<List<LanPeerStatus>>.broadcast();

  LanSyncCoordinator({
    required NooDatabase db,
    required SyncCrypto crypto,
    required SyncService syncService,
    required String deviceId,
    String? deviceName,
    this.journal,
    this.followerGrace = const Duration(seconds: 4),
  })  : _db = db,
        _crypto = crypto,
        _syncService = syncService,
        _deviceId = deviceId,
        _deviceName = deviceName;

  /// Emits the number of changes applied after each peer exchange that
  /// applied at least one — the UI listens to refresh the tree/editor.
  Stream<int> get onApplied => _appliedController.stream;

  /// The session's peers and where each stands, starting with the current
  /// list so a fresh listener renders immediately.
  Stream<List<LanPeerStatus>> get statuses async* {
    yield peerStatuses;
    yield* _statusController.stream;
  }

  List<LanPeerStatus> get peerStatuses => _statuses.values.toList();

  /// True while a session is open.
  bool get isRunning => _server?.isRunning ?? false;

  /// Port the embedded peer server listens on, or 0 outside a session.
  int get peerPort => _server?.port ?? 0;

  /// Start listening for and looking for peers. Throws when the sockets
  /// cannot be bound; the session is then not running.
  ///
  /// [discover] exists for tests, which stand in for UDP with [peerFound].
  Future<void> startSession({@visibleForTesting bool discover = true}) async {
    if (isRunning) return;
    final generation = ++_generation;
    _statuses.clear();
    _peers.clear();
    _publishStatuses();

    // The discovery fingerprint and peer auth need the derived keys.
    await _syncService.prepareCrypto();

    final server = PeerSyncServer(
      db: _db,
      crypto: _crypto,
      deviceId: _deviceId,
      // The far side has pulled from us and now wants our packets, which
      // under a pull-only protocol means we pull from it.
      onSyncRequested: _onSyncRequested,
      onSessionStarted: _onSessionStarted,
      // Serve our current state, not our last-packaged one — the peer's
      // exchange has to pick up edits made since we last synced anywhere.
      beforeServe: _syncService.packageLocalChanges,
      journal: journal,
    );
    await server.start();
    if (generation != _generation) {
      await server.stop();
      return;
    }
    _server = server;

    if (!discover) return;
    try {
      final discovery = PeerDiscovery(
        fingerprint: await _crypto.accountFingerprint(),
        deviceId: _deviceId,
        tcpPort: () => server.port,
        onPeerAppeared: peerFound,
      );
      await discovery.start();
      if (generation != _generation) {
        await discovery.stop();
        return;
      }
      _discovery = discovery;
    } catch (_) {
      await stopSession();
      rethrow;
    }
  }

  /// Stop listening and looking. Exchanges already running finish, but
  /// report nowhere.
  Future<void> stopSession() async {
    _generation++;
    await _discovery?.stop();
    _discovery = null;
    await _server?.stop();
    _server = null;
  }

  Future<void> dispose() async {
    await stopSession();
    await _appliedController.close();
    await _statusController.close();
  }

  /// A peer turned up during the session: sync with it, unless this session
  /// already has.
  @visibleForTesting
  void peerFound(LanPeer peer) {
    if (!isRunning) return;
    final known = _peers.containsKey(peer.deviceId);
    _peers[peer.deviceId] = peer;
    _update(peer.deviceId, (s) => s.copyWith(
          address: peer.address.address,
          error: s.error,
        ));
    // Already synced, syncing or scheduled — by discovery or by the peer
    // asking first.
    if (known) return;

    final generation = _generation;
    if (_deviceId.compareTo(peer.deviceId) < 0) {
      _syncWith(peer, generation);
    } else {
      Timer(followerGrace, () {
        if (generation != _generation) return;
        if (_statuses[peer.deviceId]?.state != LanPeerState.found) return;
        _syncWith(peer, generation);
      });
    }
  }

  /// Sync again with every peer this session has seen — for edits made while
  /// the dialog stayed open, or a peer that failed.
  void syncAgain() {
    if (!isRunning) return;
    final generation = _generation;
    for (final peer in _peers.values) {
      if (_statuses[peer.deviceId]?.state == LanPeerState.syncing) continue;
      _syncWith(peer, generation);
    }
  }

  void _syncWith(LanPeer peer, int generation) {
    _update(peer.deviceId, (s) => s.copyWith(state: LanPeerState.syncing));
    unawaited(_serialized(() => _exchangeWith(peer, reciprocate: true)).then(
      (applied) => _finished(peer.deviceId, generation, applied),
      onError: (Object e) => _failed(peer.deviceId, generation, e),
    ));
  }

  /// A peer has authenticated with us — note the name it announced, which
  /// discovery does not carry.
  void _onSessionStarted(String deviceId, String? deviceName) {
    if (deviceName == null || deviceName.trim().isEmpty) return;
    _update(deviceId, (s) => s.copyWith(
          deviceName: deviceName,
          error: s.error,
        ));
  }

  /// A peer completed its half of an exchange and asked us to pull from it.
  /// Runs detached — the peer's HTTP request has already been answered and
  /// must not wait on this.
  void _onSyncRequested(String deviceId, InternetAddress address, int port) {
    final peer = LanPeer(
      deviceId: deviceId,
      address: address,
      tcpPort: port,
      lastSeen: DateTime.now(),
    );
    _peers[deviceId] = peer;
    final generation = _generation;
    _update(deviceId, (s) => s.copyWith(
          address: address.address,
          state: LanPeerState.syncing,
        ));
    unawaited(_serialized(() => _exchangeWith(peer, reciprocate: false)).then(
      (applied) => _finished(deviceId, generation, applied),
      onError: (Object e) => _failed(deviceId, generation, e),
    ));
  }

  void _finished(String deviceId, int generation, int applied) {
    _publishApplied(applied);
    if (generation != _generation) return;
    _update(deviceId, (s) => s.copyWith(
          state: LanPeerState.synced,
          changesApplied: s.changesApplied + applied,
        ));
  }

  void _failed(String deviceId, int generation, Object error) {
    if (generation != _generation) return;
    _update(deviceId, (s) => s.copyWith(
          state: LanPeerState.failed,
          error: '$error',
        ));
  }

  /// Pull from [peer] and, when [reciprocate] is set, ask it to pull from us.
  /// Returns the number of changes applied locally; throws if the exchange
  /// itself failed.
  Future<int> _exchangeWith(LanPeer peer, {required bool reciprocate}) async {
    final client = PeerApiClient(
      host: peer.address.address,
      port: peer.tcpPort,
      peerDeviceId: peer.deviceId,
      ownDeviceId: _deviceId,
      ownDeviceName: _deviceName,
      crypto: _crypto,
    );
    try {
      final applied = await _syncService.exchangeWithSource(
        client,
        trigger: reciprocate ? 'lan' : 'lan-return',
      );
      if (reciprocate) {
        final port = _server?.port ?? 0;
        if (port > 0) await client.requestSync(callbackPort: port);
      }
      // A negative count means a relay sync held the service's own guard, so
      // nothing was exchanged this time.
      return applied < 0 ? 0 : applied;
    } finally {
      client.dispose();
    }
  }

  void _update(
    String deviceId,
    LanPeerStatus Function(LanPeerStatus current) change,
  ) {
    final current = _statuses[deviceId] ?? LanPeerStatus(deviceId: deviceId);
    _statuses[deviceId] = change(current);
    _publishStatuses();
  }

  void _publishApplied(int applied) {
    if (applied > 0 && !_appliedController.isClosed) {
      _appliedController.add(applied);
    }
  }

  void _publishStatuses() {
    if (!_statusController.isClosed) _statusController.add(peerStatuses);
  }

  Future<T> _serialized<T>(Future<T> Function() body) {
    final completer = Completer<T>();
    _chain = _chain.then((_) async {
      try {
        completer.complete(await body());
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    });
    return completer.future;
  }
}
