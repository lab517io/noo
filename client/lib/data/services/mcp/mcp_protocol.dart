import 'dart:math';

/// Constants and JSON-RPC framing for the MCP server.
///
/// Deliberately free of I/O and of the database, so the wire format can be
/// exercised without a socket.
class McpProtocol {
  McpProtocol._();

  /// The single path the server answers on.
  static const String path = '/mcp';

  /// Newest protocol revision this server implements.
  ///
  /// A client asking for an older one it is listed under gets that echoed
  /// back: the wire shape emitted here — a lone JSON response per POST, tools
  /// only, no server-initiated messages — is the same across all three, so
  /// there is nothing to downgrade.
  static const String latestProtocolVersion = '2025-06-18';
  static const Set<String> supportedProtocolVersions = {
    '2025-06-18',
    '2025-03-26',
    '2024-11-05',
  };

  static const String serverName = 'noo';

  /// Largest request body read, so a stray upload cannot be buffered whole.
  static const int maxBodyBytes = 1 << 20;

  // JSON-RPC 2.0 reserved error codes.
  static const int parseError = -32700;
  static const int invalidRequest = -32600;
  static const int methodNotFound = -32601;
  static const int invalidParams = -32602;
  static const int internalError = -32603;

  static final Random _random = Random.secure();

  /// A fresh bearer token: 32 bytes, hex.
  ///
  /// Twice the length of [AttachmentMediaServer]'s per-run token, because this
  /// one is persisted to the keychain and pasted into agent config files
  /// rather than dying with the process.
  static String randomToken() => List.generate(
        32,
        (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();

  /// Compare two tokens without leaking their common prefix through timing.
  ///
  /// Deliberately a copy of the same helper in `peer_sync_server.dart` rather
  /// than a shared extraction: that file is the LAN sync auth path, and
  /// refactoring it from here would put a change with no test coverage of its
  /// own into a feature branch.
  static bool constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }

  static Map<String, dynamic> result(Object? id, Map<String, dynamic> value) => {
        'jsonrpc': '2.0',
        'id': id,
        'result': value,
      };

  static Map<String, dynamic> error(Object? id, int code, String message) => {
        'jsonrpc': '2.0',
        'id': id,
        'error': {'code': code, 'message': message},
      };

  /// The protocol version to answer `initialize` with.
  static String negotiateVersion(Object? requested) =>
      requested is String && supportedProtocolVersions.contains(requested)
          ? requested
          : latestProtocolVersion;
}
