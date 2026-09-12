import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'peer_sync_server.dart';

/// A Noo device seen on the LAN.
class LanPeer {
  final String deviceId;
  final InternetAddress address;
  final int tcpPort;
  DateTime lastSeen;

  LanPeer({
    required this.deviceId,
    required this.address,
    required this.tcpPort,
    required this.lastSeen,
  });

  @override
  String toString() => '$deviceId@${address.address}:$tcpPort';
}

/// UDP broadcast discovery (docs/P2P_SYNC.md §9.3).
///
/// Wire format (single datagram, pipe-separated):
///   NOO2P|<fingerprint>|<device_id>|<tcp_port>   — broadcast probe
///   NOO2A|<fingerprint>|<device_id>|<tcp_port>   — unicast announce (reply)
///
/// The fingerprint is HMAC-derived from the peer key, so devices of other
/// accounts (or with a different database password) are filtered before any
/// TCP connection; it reveals neither username nor key material. Discovery is
/// advisory only — every peer still passes mutual authentication on TCP.
///
/// The socket binds the well-known discovery port when free, or an ephemeral
/// port otherwise (another Noo instance on the same host owns the well-known
/// one). Ephemeral-bound instances still probe the well-known port and learn
/// peers from the unicast replies; the well-known listener learns *them* from
/// the probes' source addresses. Probes repeat on a slow timer.
class PeerDiscovery {
  final String fingerprint;
  final String deviceId;

  /// The local [PeerSyncServer] port announced to peers.
  final int Function() tcpPort;

  /// Called when a peer is first seen (not on refreshes of a known peer).
  final void Function(LanPeer peer)? onPeerAppeared;

  static const Duration probeInterval = Duration(seconds: 15);
  static const Duration peerExpiry = Duration(seconds: 60);

  RawDatagramSocket? _socket;
  Timer? _probeTimer;
  final Map<String, LanPeer> _peers = {};

  PeerDiscovery({
    required this.fingerprint,
    required this.deviceId,
    required this.tcpPort,
    this.onPeerAppeared,
  });

  /// Peers heard from within [peerExpiry].
  List<LanPeer> get activePeers {
    final cutoff = DateTime.now().subtract(peerExpiry);
    _peers.removeWhere((_, p) => p.lastSeen.isBefore(cutoff));
    return _peers.values.toList();
  }

  bool get isRunning => _socket != null;

  Future<void> start() async {
    if (_socket != null) return;
    RawDatagramSocket socket;
    try {
      socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        PeerProtocol.discoveryPort,
        reuseAddress: true,
      );
    } on SocketException {
      // Another instance on this host holds the discovery port; listen on an
      // ephemeral port instead (replies come back unicast to it).
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    }
    socket.broadcastEnabled = true;
    socket.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = socket.receive();
        if (datagram != null) _onDatagram(datagram);
      }
    }, onError: (_) {}, cancelOnError: false);
    _socket = socket;

    _probeTimer = Timer.periodic(probeInterval, (_) => probe());
    probe();
  }

  Future<void> stop() async {
    _probeTimer?.cancel();
    _probeTimer = null;
    _socket?.close();
    _socket = null;
    _peers.clear();
  }

  /// Broadcast one probe. Peers with the same fingerprint reply unicast.
  void probe() {
    _send('NOO2P', InternetAddress('255.255.255.255'),
        PeerProtocol.discoveryPort);
  }

  void _send(String kind, InternetAddress to, int port) {
    final socket = _socket;
    if (socket == null) return;
    final message = '$kind|$fingerprint|$deviceId|${tcpPort()}';
    try {
      socket.send(utf8.encode(message), to, port);
    } catch (_) {
      // Transient network errors (interface down etc.) — next probe retries.
    }
  }

  void _onDatagram(Datagram datagram) {
    String text;
    try {
      text = utf8.decode(datagram.data);
    } catch (_) {
      return;
    }
    final parts = text.split('|');
    if (parts.length != 4) return;
    final kind = parts[0];
    if (kind != 'NOO2P' && kind != 'NOO2A') return;
    if (parts[1] != fingerprint) return; // other account / other password
    final peerDevice = parts[2];
    if (peerDevice == deviceId) return; // our own broadcast echoed back
    final peerTcpPort = int.tryParse(parts[3]);
    if (peerTcpPort == null || peerTcpPort <= 0 || peerTcpPort > 65535) return;

    final existing = _peers[peerDevice];
    final isNew = existing == null;
    final peer = LanPeer(
      deviceId: peerDevice,
      address: datagram.address,
      tcpPort: peerTcpPort,
      lastSeen: DateTime.now(),
    );
    _peers[peerDevice] = peer;

    // Answer probes unicast so a newly arrived (or ephemeral-port) instance
    // learns us without waiting for our next broadcast. Announces are never
    // answered — that would loop.
    if (kind == 'NOO2P') {
      _send('NOO2A', datagram.address, datagram.port);
    }

    if (isNew) onPeerAppeared?.call(peer);
  }
}
