import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/mcp/mcp_protocol.dart';
import 'package:noo/data/services/mcp/mcp_server.dart';
import 'package:noo/data/services/mcp/mcp_tools.dart';
import 'package:noo/domain/entities/world_id.dart';

/// The wire behaviour an MCP client relies on: the handshake, the tool list,
/// and the three things that keep other local programs out.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The test binding installs an HttpOverrides whose client answers every
  // request with 400 so tests cannot reach the network. These requests go to
  // our own loopback server, so the real client is needed.
  setUpAll(() => HttpOverrides.global = null);

  const token = 'test-token';

  late NooDatabase db;
  late McpServer server;
  late HttpClient client;

  setUp(() async {
    db = NooDatabase.memory();
    server = McpServer();
    client = HttpClient();
    // Port 0: the fixed 8737 is a user setting, never a constant in here, so
    // the tests can bind without fighting a running app for the port.
    await server.configure(
      db: db,
      enabled: true,
      port: 0,
      token: token,
      readOnly: false,
      databaseLabel: 'test.noo',
    );
  });

  tearDown(() async {
    client.close(force: true);
    server.dispose();
    await db.close();
  });

  Uri endpoint({String path = McpProtocol.path}) =>
      Uri.parse('http://127.0.0.1:${server.port}$path');

  Future<HttpClientResponse> send(
    Object? body, {
    String method = 'POST',
    String? auth = 'Bearer $token',
    String? origin,
    Uri? url,
  }) async {
    final request = await client.openUrl(method, url ?? endpoint());
    if (auth != null) {
      request.headers.set(HttpHeaders.authorizationHeader, auth);
    }
    if (origin != null) request.headers.set('origin', origin);
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    return request.close();
  }

  Future<Map<String, dynamic>> rpc(
    String method, [
    Map<String, dynamic>? params,
  ]) async {
    final response = await send({
      'jsonrpc': '2.0',
      'id': 1,
      'method': method,
      'params': ?params,
    });
    expect(response.statusCode, HttpStatus.ok);
    return jsonDecode(await response.transform(utf8.decoder).join())
        as Map<String, dynamic>;
  }

  group('binding', () {
    test('binds loopback only', () async {
      expect(server.isRunning, isTrue);
      expect(server.port, greaterThan(0));
      expect(server.lastBindError, isNull);
    });

    test('a taken port is reported rather than thrown', () async {
      final blocker = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => blocker.close(force: true));

      await server.configure(
        db: db,
        enabled: true,
        port: blocker.port,
        token: token,
        readOnly: false,
      );

      // The likeliest real failure — a second Noo window — has to reach the
      // preferences tab, not the console.
      expect(server.isRunning, isFalse);
      expect(server.lastBindError, isNotNull);
    });

    test('disabling closes the socket', () async {
      final port = server.port;
      await server.configure(
        db: db,
        enabled: false,
        port: 0,
        token: token,
        readOnly: false,
      );

      expect(server.isRunning, isFalse);
      await expectLater(
        client.getUrl(Uri.parse('http://127.0.0.1:$port/mcp')),
        throwsA(isA<SocketException>()),
      );
    });

    test('closing the database closes the socket', () async {
      await server.configure(
        db: null,
        enabled: true,
        port: 0,
        token: token,
        readOnly: false,
      );
      expect(server.isRunning, isFalse);
    });

    test('a token with no database leaves the server unbound', () async {
      final fresh = McpServer();
      addTearDown(fresh.dispose);

      await fresh.configure(
        db: null,
        enabled: true,
        port: 0,
        token: token,
        readOnly: false,
      );
      expect(fresh.isRunning, isFalse);
    });

    test('changing the token does not rebind the socket', () async {
      final before = server.port;
      await server.configure(
        db: db,
        enabled: true,
        port: before,
        token: 'rotated',
        readOnly: false,
      );

      // Rebinding here would race the old socket's TIME_WAIT on a fixed port
      // and drop anything in flight, for no benefit — the token is read per
      // request.
      expect(server.port, before);
      expect(server.isRunning, isTrue);

      final stale = await send({'jsonrpc': '2.0', 'id': 1, 'method': 'ping'});
      expect(stale.statusCode, HttpStatus.unauthorized);

      final fresh = await send(
        {'jsonrpc': '2.0', 'id': 1, 'method': 'ping'},
        auth: 'Bearer rotated',
      );
      expect(fresh.statusCode, HttpStatus.ok);
    });
  });

  group('authentication', () {
    test('a missing token is refused', () async {
      final response = await send(
        {'jsonrpc': '2.0', 'id': 1, 'method': 'ping'},
        auth: null,
      );
      expect(response.statusCode, HttpStatus.unauthorized);
      expect(response.headers.value(HttpHeaders.wwwAuthenticateHeader),
          'Bearer');
    });

    test('a wrong token is refused and counted', () async {
      await send(
        {'jsonrpc': '2.0', 'id': 1, 'method': 'ping'},
        auth: 'Bearer wrong',
      );
      await send({'jsonrpc': '2.0', 'id': 1, 'method': 'ping'}, auth: null);

      // Counted and shown rather than rate-limited: what the user needs is the
      // fact that something is knocking with the wrong token.
      expect(server.rejectedRequests, 2);
    });

    test('a non-bearer scheme is refused', () async {
      final response = await send(
        {'jsonrpc': '2.0', 'id': 1, 'method': 'ping'},
        auth: 'Basic $token',
      );
      expect(response.statusCode, HttpStatus.unauthorized);
    });
  });

  group('origin checking', () {
    test('an absent origin is allowed', () async {
      final response = await send({'jsonrpc': '2.0', 'id': 1, 'method': 'ping'});
      expect(response.statusCode, HttpStatus.ok);
    });

    test('a loopback origin is allowed', () async {
      final response = await send(
        {'jsonrpc': '2.0', 'id': 1, 'method': 'ping'},
        origin: 'http://localhost:3000',
      );
      expect(response.statusCode, HttpStatus.ok);
    });

    test('a foreign origin is refused', () async {
      final response = await send(
        {'jsonrpc': '2.0', 'id': 1, 'method': 'ping'},
        origin: 'http://evil.example',
      );
      expect(response.statusCode, HttpStatus.forbidden);
    });

    test('a look-alike origin is refused', () async {
      // The reason the host is compared for equality: a substring test would
      // wave this straight through.
      final response = await send(
        {'jsonrpc': '2.0', 'id': 1, 'method': 'ping'},
        origin: 'http://localhost.evil.example',
      );
      expect(response.statusCode, HttpStatus.forbidden);
    });
  });

  group('transport', () {
    test('an unknown path is not found', () async {
      final response = await send(
        {'jsonrpc': '2.0', 'id': 1, 'method': 'ping'},
        url: endpoint(path: '/nope'),
      );
      expect(response.statusCode, HttpStatus.notFound);
    });

    test('a trailing slash is the same endpoint', () async {
      final response = await send(
        {'jsonrpc': '2.0', 'id': 1, 'method': 'ping'},
        url: endpoint(path: '/mcp/'),
      );
      expect(response.statusCode, HttpStatus.ok);
    });

    test('GET is refused, because nothing is ever pushed', () async {
      final response = await send(null, method: 'GET');
      expect(response.statusCode, HttpStatus.methodNotAllowed);
      expect(response.headers.value(HttpHeaders.allowHeader), 'POST, DELETE');
    });

    test('DELETE succeeds with no content, since there is no session', () async {
      final response = await send(null, method: 'DELETE');
      expect(response.statusCode, HttpStatus.noContent);
    });

    test('a notification gets 202 and no JSON-RPC frame', () async {
      final response = await send({
        'jsonrpc': '2.0',
        'method': 'notifications/initialized',
      });
      expect(response.statusCode, HttpStatus.accepted);
      expect(await response.transform(utf8.decoder).join(), isEmpty);
    });

    test('malformed JSON is a parse error', () async {
      final request = await client.postUrl(endpoint());
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.write('not json');
      final response = await request.close();

      expect(response.statusCode, HttpStatus.badRequest);
      final body = jsonDecode(await response.transform(utf8.decoder).join());
      expect(body['error']['code'], McpProtocol.parseError);
    });

    test('a batch is refused', () async {
      final response = await send([
        {'jsonrpc': '2.0', 'id': 1, 'method': 'ping'},
      ]);
      expect(response.statusCode, HttpStatus.badRequest);
      final body = jsonDecode(await response.transform(utf8.decoder).join());
      // Batching was added in 2025-03-26 and removed in 2025-06-18.
      expect(body['error']['code'], McpProtocol.invalidRequest);
      expect(body['error']['message'], contains('batching'));
    });

    test('an oversized body is refused', () async {
      final request = await client.postUrl(endpoint());
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      request.write('x' * (McpProtocol.maxBodyBytes + 1024));
      final response = await request.close();

      expect(response.statusCode, HttpStatus.requestEntityTooLarge);
    });
  });

  group('protocol', () {
    test('initialize advertises tools and names the database', () async {
      final reply = await rpc('initialize', {
        'protocolVersion': '2025-06-18',
        'capabilities': <String, dynamic>{},
        'clientInfo': {'name': 'test', 'version': '1'},
      });

      final result = reply['result'] as Map<String, dynamic>;
      expect(result['protocolVersion'], '2025-06-18');
      expect(result['capabilities']['tools'], isNotNull);
      expect(result['serverInfo']['name'], McpProtocol.serverName);
      // Two open windows is a real configuration; the agent has to be able to
      // say which one it reached.
      expect(result['instructions'], contains('test.noo'));
    });

    test('an older protocol version is echoed back', () async {
      final reply =
          await rpc('initialize', {'protocolVersion': '2024-11-05'});
      expect(reply['result']['protocolVersion'], '2024-11-05');
    });

    test('an unknown protocol version falls back to the newest', () async {
      final reply = await rpc('initialize', {'protocolVersion': '1999-01-01'});
      expect(
        reply['result']['protocolVersion'],
        McpProtocol.latestProtocolVersion,
      );
    });

    test('ping answers empty', () async {
      final reply = await rpc('ping');
      expect(reply['result'], isEmpty);
    });

    test('an unknown method is method-not-found', () async {
      final reply = await rpc('resources/list');
      expect(reply['error']['code'], McpProtocol.methodNotFound);
    });

    test('tools/list offers every tool when writes are allowed', () async {
      final reply = await rpc('tools/list');
      final names = [
        for (final t in reply['result']['tools'] as List) (t as Map)['name'],
      ];
      expect(names.toSet(), McpToolNames.all);
    });

    test('read-only mode withholds the write tools', () async {
      await server.configure(
        db: db,
        enabled: true,
        port: server.port,
        token: token,
        readOnly: true,
      );

      final reply = await rpc('tools/list');
      final names = {
        for (final t in reply['result']['tools'] as List) (t as Map)['name'],
      };
      expect(names, McpToolNames.read);
      expect(names.intersection(McpToolNames.write), isEmpty);
    });
  });

  group('tools/call', () {
    test('a tool round-trips through the database', () async {
      await db.createTask(
        worldId: WorldId.create().toString(),
        title: 'Findable',
      );

      final reply = await rpc('tools/call', {
        'name': McpToolNames.searchTasks,
        'arguments': {'query': 'Findable'},
      });

      final result = reply['result'] as Map<String, dynamic>;
      expect(result['isError'], isFalse);
      final payload = jsonDecode(result['content'][0]['text'] as String);
      expect(payload['results'], hasLength(1));
    });

    test('a failing tool is an isError result, not a JSON-RPC error', () async {
      final reply = await rpc('tools/call', {
        'name': McpToolNames.getTask,
        'arguments': {'id': 'missing'},
      });

      // Agents surface protocol errors far worse than they surface isError.
      expect(reply['error'], isNull);
      expect(reply['result']['isError'], isTrue);
    });

    test('a malformed params object is invalid params', () async {
      final reply = await rpc('tools/call', {'arguments': <String, dynamic>{}});
      expect(reply['error']['code'], McpProtocol.invalidParams);
    });

    test('writes coalesce into a single change notification', () async {
      final seen = <void>[];
      final sub = server.onChanged.listen(seen.add);
      addTearDown(sub.cancel);

      for (var i = 0; i < 3; i++) {
        await rpc('tools/call', {
          'name': McpToolNames.createTask,
          'arguments': {'title': 'Task $i'},
        });
      }

      // An agent renaming fifty tasks should cost one tree reload, not fifty.
      await Future<void>.delayed(
        McpServer.changeCoalescingWindow + const Duration(milliseconds: 150),
      );
      expect(seen, hasLength(1));
    });

    test('a read does not signal a change', () async {
      final seen = <void>[];
      final sub = server.onChanged.listen(seen.add);
      addTearDown(sub.cancel);

      await rpc('tools/call', {
        'name': McpToolNames.searchTasks,
        'arguments': {'query': 'nothing'},
      });

      await Future<void>.delayed(
        McpServer.changeCoalescingWindow + const Duration(milliseconds: 150),
      );
      expect(seen, isEmpty);
    });

    test('a write flushes the editor first', () async {
      var flushed = false;
      server.beforeWrite = () async => flushed = true;

      await rpc('tools/call', {
        'name': McpToolNames.createTask,
        'arguments': {'title': 'Written'},
      });

      // Without this the editor's debounced save, holding text that predates
      // the agent's edit, silently overwrites it seconds later.
      expect(flushed, isTrue);
    });

    test('a read does not flush the editor', () async {
      var flushed = false;
      server.beforeWrite = () async => flushed = true;

      await rpc('tools/call', {
        'name': McpToolNames.getTree,
        'arguments': <String, dynamic>{},
      });

      expect(flushed, isFalse);
    });
  });
}
