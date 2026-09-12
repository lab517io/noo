import 'dart:async';
import 'dart:io';

import 'package:meta/meta.dart';

import '../database/database.dart';
import 'peer_api_client.dart';
import 'peer_discovery.dart';
import 'peer_sync_server.dart';
import 'sync_api_client.dart';
import 'sync_crypto.dart';
import 'sync_service.dart';

/// What a user-initiated LAN sync did, for the snackbar that reports it back.
class LanSyncOutcome {
  /// Peers we completed an exchange with.
  final int peersSynced;

  /// Peers whose user answered "no" to the confirmation prompt.
  final int peersDeclined;

  /// Peers that were visible but could not be exchanged with (gone, auth
  /// failure, network error).
  final int peersFailed;

  /// Changes applied locally across all peers.
  final int changesApplied;

  /// A sync was already running; this press did nothing.
  final bool busy;

  /// LAN sync is not running at all (sync unconfigured, or sockets unbound).
  final bool unavailable;

  const LanSyncOutcome({
    this.peersSynced = 0,
    this.peersDeclined = 0,
    this.peersFailed = 0,
    this.changesApplied = 0,
    this.busy = false,
    this.unavailable = false,
  });

  const LanSyncOutcome.busy() : this(busy: true);
  const LanSyncOutcome.unavailable() : this(unavailable: true);

  /// Nothing was on the LAN to sync with.
  bool get noPeers =>
      !busy &&
      !unavailable &&
      peersSynced == 0 &&
      peersDeclined == 0 &&
      peersFailed == 0;
}

/// Orchestrates LAN peer sync (docs/P2P_SYNC.md §9–10): runs the embedded peer
/// server and UDP discovery, and exchanges with peers **only when asked to**.
///
/// Discovery runs continuously so the UI can show which devices are nearby,
/// but seeing a peer never starts an exchange — [syncNow] does, and so does a
/// peer's explicit sync request, which is itself the far side's [syncNow].
/// Nothing here is on a sync timer: putting a phone next to a desktop must not
/// move data until someone asks for it.
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

  /// Asks this device's user to confirm a peer-initiated sync — see
  /// [PeerSyncServer.approveSession]. When null, authenticated peers are
  /// allowed without asking.
  final Future<bool> Function(String deviceId, String? deviceName)?
      confirmIncomingSync;

  /// How often the visible-peer list is re-published so the indicator drops
  /// peers that have aged out. Discovery bookkeeping only — never a sync.
  static const Duration peerRefreshInterval = Duration(seconds: 5);

  /// How long after pressing sync a peer's reciprocal exchange is taken as
  /// already consented to (§9.5). Long enough to outlast the peer's own
  /// confirmation prompt, short enough that consent does not linger.
  static const Duration reciprocalGrace = Duration(minutes: 2);

  PeerSyncServer? _server;
  PeerDiscovery? _discovery;
  Timer? _peerRefreshTimer;

  /// Serializes exchanges (a manual sync, and the reciprocal ones peers ask
  /// for) so two never interleave against the same packet store. Queuing
  /// rather than dropping matters when both users press at the same moment.
  Future<void> _chain = Future<void>.value();

  /// True while [syncNow] is running, so a second press reports "busy"
  /// instead of silently queueing another full pass.
  bool _manualInFlight = false;

  final StreamController<int> _appliedController =
      StreamController<int>.broadcast();
  final StreamController<List<LanPeer>> _peersController =
      StreamController<List<LanPeer>>.broadcast();
  String _lastPeerKey = '';

  /// Peers we have just asked to sync back, and when we asked. Their return
  /// exchange is the second half of a press this device's user already made,
  /// so prompting for it again would ask the same person the same question.
  final Map<String, DateTime> _awaitingReciprocal = {};

  LanSyncCoordinator({
    required NooDatabase db,
    required SyncCrypto crypto,
    required SyncService syncService,
    required String deviceId,
    String? deviceName,
    this.confirmIncomingSync,
  })  : _db = db,
        _crypto = crypto,
        _syncService = syncService,
        _deviceId = deviceId,
        _deviceName = deviceName;

  /// Emits the number of changes applied after each peer exchange that
  /// applied at least one — the UI listens to refresh the tree/editor.
  Stream<int> get onApplied => _appliedController.stream;

  /// The visible peers, starting with the current list so a fresh listener
  /// renders immediately instead of waiting for the next change.
  Stream<List<LanPeer>> get peers async* {
    yield activePeers;
    yield* _peersController.stream;
  }

  bool get isRunning => _server?.isRunning ?? false;
  List<LanPeer> get activePeers => _discovery?.activePeers ?? const [];

  /// Port the embedded peer server listens on, or 0 when not running.
  int get peerPort => _server?.port ?? 0;

  Future<void> start() async {
    if (isRunning) return;
    // The discovery fingerprint and peer auth need the derived keys.
    await _syncService.prepareCrypto();

    final server = PeerSyncServer(
      db: _db,
      crypto: _crypto,
      deviceId: _deviceId,
      // The far side pressed sync and has already pulled from us; it now wants
      // our packets, which under a pull-only protocol means we pull from it.
      onSyncRequested: _onSyncRequested,
      approveSession: _approveIncoming,
      // Serve our current state, not our last-packaged one — a peer's single
      // press has to pick up edits made since we last synced anywhere.
      beforeServe: _syncService.packageLocalChanges,
    );
    await server.start();
    _server = server;

    final discovery = PeerDiscovery(
      fingerprint: await _crypto.accountFingerprint(),
      deviceId: _deviceId,
      tcpPort: () => server.port,
      // Appearing on the LAN only updates the indicator. It does not sync.
      onPeerAppeared: (_) => _publishPeers(),
    );
    await discovery.start();
    _discovery = discovery;

    _peerRefreshTimer =
        Timer.periodic(peerRefreshInterval, (_) => _publishPeers());
  }

  Future<void> stop() async {
    _peerRefreshTimer?.cancel();
    _peerRefreshTimer = null;
    await _discovery?.stop();
    _discovery = null;
    await _server?.stop();
    _server = null;
    _lastPeerKey = '';
    _awaitingReciprocal.clear();
  }

  Future<void> dispose() async {
    await stop();
    await _appliedController.close();
    await _peersController.close();
  }

  /// Exchange with every visible peer, at the user's request.
  ///
  /// Each peer is pulled from and then asked to pull back, so one press leaves
  /// both devices holding the same data.
  Future<LanSyncOutcome> syncNow() => syncWith(activePeers);

  /// [syncNow] against an explicit peer list instead of whatever discovery
  /// currently sees. Exists so tests can exercise the exchange without
  /// depending on UDP broadcast reaching anything.
  @visibleForTesting
  Future<LanSyncOutcome> syncWith(List<LanPeer> peers) async {
    if (!isRunning) return const LanSyncOutcome.unavailable();
    if (_manualInFlight) return const LanSyncOutcome.busy();

    _manualInFlight = true;
    try {
      var synced = 0;
      var declined = 0;
      var failed = 0;
      var applied = 0;
      for (final peer in peers) {
        try {
          applied += await _serialized(
            () => _exchangeWith(peer, reciprocate: true),
          );
          synced++;
        } on SyncApiException catch (e) {
          // The peer's user said no. Reported separately from a failure: it
          // is the system working, not breaking.
          if (e.statusCode == HttpStatus.forbidden) {
            declined++;
          } else {
            failed++;
          }
        } catch (_) {
          // A peer that vanished mid-exchange is counted, not thrown: the
          // remaining peers still deserve their turn.
          failed++;
        }
      }
      _publishApplied(applied);
      return LanSyncOutcome(
        peersSynced: synced,
        peersDeclined: declined,
        peersFailed: failed,
        changesApplied: applied,
      );
    } finally {
      _manualInFlight = false;
    }
  }

  /// Decide whether a peer that just authenticated may sync with us.
  ///
  /// The one case that must not prompt is a peer completing a sync *this*
  /// device's user started: they already answered this question by pressing
  /// the button, and asking again on the return leg would make every sync
  /// take two confirmations, one of them on the device that initiated it.
  Future<bool> _approveIncoming(String deviceId, String? deviceName) async {
    final asked = _awaitingReciprocal.remove(deviceId);
    if (asked != null &&
        DateTime.now().difference(asked) < reciprocalGrace) {
      return true;
    }
    final confirm = confirmIncomingSync;
    if (confirm == null) return true;
    return confirm(deviceId, deviceName);
  }

  /// A peer completed its half of a user-initiated sync and asked us to pull
  /// from it. Runs detached — the peer's HTTP request has already been
  /// answered and must not wait on this.
  void _onSyncRequested(String deviceId, InternetAddress address, int port) {
    final peer = LanPeer(
      deviceId: deviceId,
      address: address,
      tcpPort: port,
      lastSeen: DateTime.now(),
    );
    unawaited(
      _serialized(() => _exchangeWith(peer, reciprocate: false))
          .then(_publishApplied)
          // The requesting peer went away or its keys no longer match; its own
          // sync already told its user what happened.
          .catchError((_) {}),
    );
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
      final applied = await _syncService.exchangeWithSource(client);
      if (reciprocate) {
        final port = _server?.port ?? 0;
        if (port > 0) {
          // Recorded before asking, so the peer's return exchange is never
          // racing an entry that is not there yet and prompting for it.
          final now = DateTime.now();
          // Peers that were asked but never came back would otherwise sit
          // here for the life of the process.
          _awaitingReciprocal
              .removeWhere((_, at) => now.difference(at) >= reciprocalGrace);
          _awaitingReciprocal[peer.deviceId] = now;
          await client.requestSync(callbackPort: port);
        }
      }
      // A negative count means a relay sync held the service's own guard, so
      // nothing was exchanged this time.
      return applied < 0 ? 0 : applied;
    } finally {
      client.dispose();
    }
  }

  void _publishApplied(int applied) {
    if (applied > 0 && !_appliedController.isClosed) {
      _appliedController.add(applied);
    }
  }

  /// Re-publish the visible peers, but only when the set actually changed —
  /// this runs on a timer and would otherwise rebuild the indicator forever.
  void _publishPeers() {
    final peers = activePeers;
    final ids = peers.map((p) => p.deviceId).toList()..sort();
    final key = ids.join(',');
    if (key == _lastPeerKey) return;
    _lastPeerKey = key;
    if (!_peersController.isClosed) _peersController.add(peers);
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
