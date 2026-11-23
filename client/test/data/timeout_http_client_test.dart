import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:noo/data/services/timeout_http_client.dart';

/// A peer that accepts the connection and never answers is the failure mode
/// `package:http` cannot see: no error ever arrives, so the request — and the
/// sync guard the caller holds — would wait forever.
void main() {
  late HttpServer server;
  final held = <HttpRequest>[];

  setUp(() async {
    // The test binding stubs HttpClient to answer 400 to everything; this
    // test talks to a real loopback socket.
    HttpOverrides.global = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  });

  tearDown(() async {
    for (final r in held) {
      try {
        await r.response.close();
      } catch (_) {}
    }
    held.clear();
    await server.close(force: true);
  });

  test('a request whose response never comes times out', () async {
    server.listen(held.add); // accept, say nothing
    final client = TimeoutHttpClient(
      http.Client(),
      responseTimeout: const Duration(milliseconds: 200),
      idleTimeout: const Duration(seconds: 5),
    );
    addTearDown(client.close);

    await expectLater(
      client.get(Uri.parse('http://127.0.0.1:${server.port}/x')),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('a body that stops arriving times out', () async {
    server.listen((req) async {
      held.add(req);
      req.response.headers.contentType = ContentType.text;
      req.response.write('first half');
      await req.response.flush();
      // ...and then nothing, with the connection still open.
    });
    final client = TimeoutHttpClient(
      http.Client(),
      responseTimeout: const Duration(seconds: 5),
      idleTimeout: const Duration(milliseconds: 200),
    );
    addTearDown(client.close);

    await expectLater(
      client.get(Uri.parse('http://127.0.0.1:${server.port}/x')),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('a prompt answer passes through untouched', () async {
    server.listen((req) async {
      req.response.statusCode = 201;
      req.response.headers.set('x-marker', 'yes');
      req.response.write('hello');
      await req.response.close();
    });
    final client = TimeoutHttpClient(
      http.Client(),
      responseTimeout: const Duration(seconds: 5),
      idleTimeout: const Duration(seconds: 5),
    );
    addTearDown(client.close);

    final response =
        await client.get(Uri.parse('http://127.0.0.1:${server.port}/x'));
    expect(response.statusCode, 201);
    expect(response.headers['x-marker'], 'yes');
    expect(response.body, 'hello');
  });
}
