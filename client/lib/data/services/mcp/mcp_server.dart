import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../database/database.dart';
import 'mcp_protocol.dart';
import 'mcp_task_api.dart';
import 'mcp_tools.dart';

/// Serves the open outline to local coding agents over loopback HTTP.
///
/// Speaks MCP's Streamable HTTP transport in its simplest legal form: one
/// JSON-RPC request per POST, answered with one JSON response. Nothing here
/// ever sends a message the client did not ask for — no sampling, no progress,
/// no listChanged — so there is no SSE stream to hold open and `GET` is a 405.
///
/// Loopback is not privacy. Any process running as this user can reach the
/// port, exactly as with the attachment media server, so the bearer token is
/// the whole boundary and every request is checked before it is parsed.
///
/// One instance lives for the whole process. The database, the enabled flag,
/// the port, the token and the read-only flag are all pushed in through
/// [configure], which rebinds the socket only when the port actually changed —
/// so regenerating a token or toggling read-only cannot fail on a port still
/// in TIME_WAIT, and never drops a request in flight.
class McpServer extends ChangeNotifier {
  /// How long writes are gathered before the UI is told to reload.
  ///
  /// An agent renaming fifty tasks should cost one tree reload, not fifty.
  static const Duration changeCoalescingWindow = Duration(milliseconds: 250);

  /// Origins allowed to reach this server, as exact hosts.
  ///
  /// The MCP specification requires validating `Origin` on a local server:
  /// loopback is reachable from a page in the user's browser through DNS
  /// rebinding. Compared for equality, never with `contains` — that would
  /// admit `localhost.attacker.example`.
  static const Set<String> allowedOriginHosts = {
    'localhost',
    '127.0.0.1',
    '::1',
  };

  HttpServer? _socket;
  int _boundPort = 0;
  Object? _lastBindError;

  NooDatabase? _db;
  McpTaskApi? _api;
  bool _enabled = false;
  int _port = 0;
  String? _token;
  bool _readOnly = false;
  String _databaseLabel = '';

  DateTime? _lastRequestAt;
  int _rejectedRequests = 0;

  final StreamController<void> _changed = StreamController<void>.broadcast();
  Timer? _changeTimer;

  /// Serialises [configure] so a stop always finishes before the next bind.
  Future<void> _chain = Future.value();

  /// Flushes the editor's pending text before a write tool runs.
  ///
  /// The editor saves on a debounce, so an agent that edits the task the user
  /// currently has open would be overwritten a few seconds later by text that
  /// predates it. Sync solves the same problem the same way before it reads
  /// the database.
  Future<void> Function()? beforeWrite;

  /// Fires after agent writes, coalesced over [changeCoalescingWindow].
  Stream<void> get onChanged => _changed.stream;

  bool get isRunning => _socket != null;

  /// Port currently bound, or 0 when the server is not running.
  int get port => _boundPort;

  /// Why the last bind attempt failed, or null.
  ///
  /// Surfaced rather than swallowed because this is the likeliest real failure:
  /// single-instance mode is off by default, so a second Noo window fails to
  /// bind and its agent would otherwise silently keep talking to the first
  /// window's database.
  Object? get lastBindError => _lastBindError;

  DateTime? get lastRequestAt => _lastRequestAt;

  /// Requests refused for a missing or wrong token.
  ///
  /// Counted and shown rather than rate-limited: this socket is reachable only
  /// by processes already running as this user, so a lockout would be a
  /// self-inflicted denial of service against no attacker it could stop. What
  /// the user needs is the fact that something is knocking with the wrong
  /// token, which turns "my agent says it isn't working" into "I pasted the
  /// old one".
  int get rejectedRequests => _rejectedRequests;

  /// Apply the current settings, binding or unbinding as needed.
  ///
  /// Safe to call repeatedly with unchanged values; it does nothing.
  Future<void> configure({
    required NooDatabase? db,
    required bool enabled,
    required int port,
    required String? token,
    required bool readOnly,
    String databaseLabel = '',
  }) {
    final result = _chain.then(
      (_) => _applyConfiguration(
        db: db,
        enabled: enabled,
        port: port,
        token: token,
        readOnly: readOnly,
        databaseLabel: databaseLabel,
      ),
    );
    _chain = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<void> _applyConfiguration({
    required NooDatabase? db,
    required bool enabled,
    required int port,
    required String? token,
    required bool readOnly,
    required String databaseLabel,
  }) async {
    final changed = _db != db ||
        _enabled != enabled ||
        _port != port ||
        _token != token ||
        _readOnly != readOnly ||
        _databaseLabel != databaseLabel;
    if (!changed) return;

    if (!identical(_db, db)) {
      _api = db == null ? null : McpTaskApi(db);
    }
    _db = db;
    _enabled = enabled;
    _port = port;
    _token = token;
    _readOnly = readOnly;
    _databaseLabel = databaseLabel;

    final shouldRun =
        enabled && db != null && token != null && token.isNotEmpty;

    if (!shouldRun) {
      await _unbind();
      notifyListeners();
      return;
    }

    // Only the port justifies tearing the socket down: everything else is read
    // per request, so a new token takes effect on the very next one.
    if (_socket != null && _boundPort == port) {
      notifyListeners();
      return;
    }

    await _unbind();
    try {
      final socket = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      _socket = socket;
      _boundPort = socket.port;
      _lastBindError = null;
      unawaited(socket.forEach(_handle).catchError((Object _) {
        // Closed underneath us by _unbind; nothing to recover.
      }));
    } catch (error) {
      _lastBindError = error;
      _socket = null;
      _boundPort = 0;
    }
    notifyListeners();
  }

  Future<void> _unbind() async {
    final socket = _socket;
    _socket = null;
    _boundPort = 0;
    await socket?.close(force: true);
  }

  @override
  void dispose() {
    _changeTimer?.cancel();
    _chain = _chain.then((_) => _unbind());
    unawaited(_changed.close());
    super.dispose();
  }

  // ============================================================
  // Request handling
  // ============================================================

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    try {
      // Cheapest rejection first, and it reveals nothing about what else is
      // served here.
      final path = request.uri.path;
      if (path != McpProtocol.path && path != '${McpProtocol.path}/') {
        await _refuse(request, HttpStatus.notFound);
        return;
      }

      if (!_originAllowed(request)) {
        await _refuse(request, HttpStatus.forbidden);
        return;
      }

      if (!_authorized(request)) {
        _rejectedRequests++;
        notifyListeners();
        response.headers.set(HttpHeaders.wwwAuthenticateHeader, 'Bearer');
        await _refuse(request, HttpStatus.unauthorized);
        return;
      }

      _lastRequestAt = DateTime.now();
      notifyListeners();

      switch (request.method) {
        case 'POST':
          await _handlePost(request);
        case 'DELETE':
          // No Mcp-Session-Id is ever issued, so there is no session to end.
          // Saying so plainly stops a client retrying.
          await _refuse(request, HttpStatus.noContent);
        default:
          // Including GET: the spec lets a server that offers no server-to-
          // client stream decline it, and holding a socket open to say nothing
          // would be worse than an honest refusal.
          response.headers.set(HttpHeaders.allowHeader, 'POST, DELETE');
          await _refuse(request, HttpStatus.methodNotAllowed);
      }
    } catch (_) {
      // A client that disconnects mid-response surfaces here and is normal.
      try {
        await response.close();
      } catch (_) {
        // Already gone.
      }
    }
  }

  Future<void> _handlePost(HttpRequest request) async {
    final body = await _readBody(request);
    if (body == null) {
      await _refuse(request, HttpStatus.requestEntityTooLarge);
      return;
    }

    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      await _writeJson(
        request,
        McpProtocol.error(null, McpProtocol.parseError, 'Invalid JSON.'),
        status: HttpStatus.badRequest,
      );
      return;
    }

    if (decoded is List) {
      // Batching existed only in the 2025-03-26 revision and was removed in
      // 2025-06-18.
      await _writeJson(
        request,
        McpProtocol.error(
          null,
          McpProtocol.invalidRequest,
          'JSON-RPC batching is not supported.',
        ),
        status: HttpStatus.badRequest,
      );
      return;
    }

    if (decoded is! Map<String, dynamic>) {
      await _writeJson(
        request,
        McpProtocol.error(
          null,
          McpProtocol.invalidRequest,
          'Expected a JSON-RPC request object.',
        ),
        status: HttpStatus.badRequest,
      );
      return;
    }

    // No id means a notification. The transport answer is an accepted-with-no-
    // content, and writing a JSON-RPC response to one would be a protocol
    // error in its own right.
    if (!decoded.containsKey('id')) {
      await _refuse(request, HttpStatus.accepted);
      return;
    }

    final reply = await _dispatch(decoded);
    await _writeJson(request, reply);
  }

  Future<Map<String, dynamic>> _dispatch(Map<String, dynamic> request) async {
    final id = request['id'];
    final method = request['method'];
    final params = request['params'];

    if (method is! String) {
      return McpProtocol.error(
        id,
        McpProtocol.invalidRequest,
        'Missing "method".',
      );
    }

    switch (method) {
      case 'initialize':
        return McpProtocol.result(id, {
          'protocolVersion': McpProtocol.negotiateVersion(
            params is Map ? params['protocolVersion'] : null,
          ),
          'capabilities': {
            'tools': {'listChanged': false},
          },
          'serverInfo': {
            'name': McpProtocol.serverName,
            'version': _serverVersion,
          },
          'instructions': _instructions,
        });

      case 'ping':
        return McpProtocol.result(id, const {});

      case 'tools/list':
        return McpProtocol.result(id, {
          'tools': mcpToolDescriptors(readOnly: _readOnly),
        });

      case 'tools/call':
        return await _callTool(id, params);

      default:
        return McpProtocol.error(
          id,
          McpProtocol.methodNotFound,
          'Unknown method "$method".',
        );
    }
  }

  Future<Map<String, dynamic>> _callTool(Object? id, Object? params) async {
    if (params is! Map) {
      return McpProtocol.error(
        id,
        McpProtocol.invalidParams,
        'Expected an object for "params".',
      );
    }

    final name = params['name'];
    if (name is! String) {
      return McpProtocol.error(
        id,
        McpProtocol.invalidParams,
        'Expected a tool name in "params.name".',
      );
    }

    final rawArguments = params['arguments'];
    final arguments = rawArguments is Map
        ? Map<String, Object?>.from(rawArguments)
        : <String, Object?>{};

    final api = _api;
    if (api == null) {
      return McpProtocol.result(id, _toolError(
        'No Noo database is open. The user has to unlock one before the '
        'outline can be read.',
      ));
    }

    // Flush the editor before anything that writes, so an agent's edit is not
    // undone by a debounced save that predates it.
    if (McpToolNames.write.contains(name)) {
      final flush = beforeWrite;
      if (flush != null) {
        try {
          await flush();
        } catch (_) {
          // A failed flush is not a reason to refuse the write; the worst case
          // is the same race that exists without an MCP server at all.
        }
      }
    }

    final result = await api.call(name, arguments, readOnly: _readOnly);
    if (result.mutated) _scheduleChanged();

    return McpProtocol.result(id, {
      'content': [
        {'type': 'text', 'text': result.text},
      ],
      'isError': result.isError,
    });
  }

  Map<String, dynamic> _toolError(String message) => {
        'content': [
          {'type': 'text', 'text': message},
        ],
        'isError': true,
      };

  /// Names the open database so a user running two windows can tell which one
  /// their agent reached — the failure mode when a second instance could not
  /// bind and the agent silently kept talking to the first.
  String get _instructions {
    final where = _databaseLabel.isEmpty
        ? 'the open Noo database'
        : "the Noo database '$_databaseLabel'";
    return 'Hierarchical outline from $where. Task ids are UUIDs that are '
        "stable across the user's devices — store those rather than titles or "
        'positions. Note bodies are rich text and are read and written here as '
        'plain text. There is no done or completed flag: tasks are organised, '
        'not checked off. The user can exclude branches of the outline from '
        'this server; anything excluded is simply absent here, so a task the '
        'user describes but no tool can find is theirs to unhide in the app.'
        '${_readOnly ? ' This server is in read-only mode.' : ''}';
  }

  static const String _serverVersion = '1.3.0';

  bool _originAllowed(HttpRequest request) {
    // Read as a list: `headers.value` throws when a request repeats the
    // header, and whether to repeat it is the caller's choice, not ours.
    final origins = request.headers['origin'];
    if (origins == null || origins.isEmpty) {
      // Absent is the normal case: the CLI clients this serves send none.
      return true;
    }
    if (origins.length > 1) return false;

    final origin = Uri.tryParse(origins.first);
    if (origin == null) return false;
    return allowedOriginHosts.contains(origin.host);
  }

  bool _authorized(HttpRequest request) {
    final token = _token;
    if (token == null || token.isEmpty) return false;

    final headers = request.headers[HttpHeaders.authorizationHeader];
    if (headers == null || headers.length != 1) return false;

    const prefix = 'Bearer ';
    final header = headers.first;
    if (!header.startsWith(prefix)) return false;

    return McpProtocol.constantTimeEquals(header.substring(prefix.length), token);
  }

  /// Read the body, or null when it exceeds [McpProtocol.maxBodyBytes].
  ///
  /// An oversized body is still read to the end, discarding as it goes, so
  /// memory stays bounded while the connection does not. Abandoning the stream
  /// mid-request instead leaves unread bytes on the socket, and dart:io then
  /// drops the connection before the refusal is flushed — the client sees a
  /// reset rather than the status it was sent.
  Future<String?> _readBody(HttpRequest request) async {
    final chunks = <List<int>>[];
    var total = 0;
    var overflowed = false;

    await for (final chunk in request) {
      total += chunk.length;
      if (total > McpProtocol.maxBodyBytes) {
        overflowed = true;
        chunks.clear();
        continue;
      }
      chunks.add(chunk);
    }
    if (overflowed) return null;

    return utf8.decode(
      [for (final chunk in chunks) ...chunk],
      allowMalformed: true,
    );
  }

  Future<void> _writeJson(
    HttpRequest request,
    Map<String, dynamic> body, {
    int status = HttpStatus.ok,
  }) async {
    final response = request.response
      ..statusCode = status
      ..headers.contentType = ContentType.json
      ..headers.set(HttpHeaders.cacheControlHeader, 'no-store');
    response.write(jsonEncode(body));
    await response.close();
  }

  /// Answer with a bare status.
  ///
  /// The body is drained first: closing a response before reading the request
  /// body can reach the client as a connection reset instead of the status it
  /// was sent, which turns a plain 401 into an unexplained failure.
  Future<void> _refuse(HttpRequest request, int status) async {
    try {
      await request.drain<void>();
    } catch (_) {
      // Client hung up mid-body; the status below is best effort anyway.
    }
    final response = request.response
      ..statusCode = status
      ..contentLength = 0;
    await response.close();
  }

  void _scheduleChanged() {
    _changeTimer?.cancel();
    _changeTimer = Timer(changeCoalescingWindow, () {
      if (!_changed.isClosed) _changed.add(null);
    });
  }
}
