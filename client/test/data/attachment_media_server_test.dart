import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/attachment_media_server.dart';
import 'package:noo/domain/entities/world_id.dart';

/// The media server hands attachment bytes to the audio player over loopback,
/// so nothing decrypted is written to disk. These tests cover what a player
/// actually exercises: the full body, seeking via Range, and the token that
/// keeps other local processes out.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The test binding installs an HttpOverrides whose client answers every
  // request with 400 so tests cannot reach the network. These requests go to
  // our own loopback server, so the real client is needed.
  setUpAll(() => HttpOverrides.global = null);

  // Larger than one chunk, so the streaming path is exercised rather than a
  // single read.
  final content = Uint8List.fromList(
    List.generate(AttachmentMediaServer.chunkSize * 2 + 517, (i) => i % 251),
  );

  late NooDatabase db;
  late AttachmentMediaServer server;
  late String worldId;
  late HttpClient client;

  setUp(() async {
    db = NooDatabase.memory();
    final taskId = await db.createTask(
      worldId: WorldId.create().value,
      title: 'Task',
    );
    worldId = WorldId.create().value;
    await db.createAttachment(
      taskId: taskId,
      worldId: worldId,
      filename: 'voice note.mp3',
      content: content,
    );

    server = AttachmentMediaServer(db);
    await server.start();
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await server.stop();
    await db.close();
  });

  Future<HttpClientResponse> get(Uri url, {String? range}) async {
    final request = await client.getUrl(url);
    if (range != null) request.headers.set(HttpHeaders.rangeHeader, range);
    return request.close();
  }

  test('serves the whole attachment, with a usable content type', () async {
    final url = server.urlFor(worldId, 'voice note.mp3')!;
    final response = await get(url);

    expect(response.statusCode, HttpStatus.ok);
    expect(response.headers.contentType.toString(), startsWith('audio/mpeg'));
    expect(response.headers.value(HttpHeaders.acceptRangesHeader), 'bytes');
    expect(response.contentLength, content.length);

    final body = await collectBytes(response);
    expect(body, content, reason: 'streamed chunks must reassemble exactly');
  });

  test('serves a byte range, which is how a player seeks', () async {
    final url = server.urlFor(worldId, 'voice note.mp3')!;
    final response = await get(url, range: 'bytes=100-199');

    expect(response.statusCode, HttpStatus.partialContent);
    expect(
      response.headers.value(HttpHeaders.contentRangeHeader),
      'bytes 100-199/${content.length}',
    );

    final body = await collectBytes(response);
    expect(body.length, 100);
    expect(body, content.sublist(100, 200));
  });

  test('an open-ended range runs to the end of the attachment', () async {
    final start = content.length - 300;
    final url = server.urlFor(worldId, 'voice note.mp3')!;
    final response = await get(url, range: 'bytes=$start-');

    expect(response.statusCode, HttpStatus.partialContent);
    final body = await collectBytes(response);
    expect(body, content.sublist(start));
  });

  test('a suffix range returns the last bytes', () async {
    final url = server.urlFor(worldId, 'voice note.mp3')!;
    final response = await get(url, range: 'bytes=-64');

    expect(response.statusCode, HttpStatus.partialContent);
    final body = await collectBytes(response);
    expect(body, content.sublist(content.length - 64));
  });

  test('a range past the end is refused, not silently truncated', () async {
    final url = server.urlFor(worldId, 'voice note.mp3')!;
    final response = await get(url, range: 'bytes=${content.length + 10}-');

    expect(response.statusCode, HttpStatus.requestedRangeNotSatisfiable);
    expect(response.headers.value(HttpHeaders.contentRangeHeader),
        'bytes */${content.length}');
  });

  test('without the token the bytes stay unreachable', () async {
    final url = server.urlFor(worldId, 'voice note.mp3')!;

    final noToken = await get(url.replace(queryParameters: const {}));
    expect(noToken.statusCode, HttpStatus.forbidden);
    await noToken.drain<void>();

    final wrongToken =
        await get(url.replace(queryParameters: {'token': 'nope'}));
    expect(wrongToken.statusCode, HttpStatus.forbidden);
    await wrongToken.drain<void>();
  });

  test('binds on loopback only', () async {
    expect(
      server.urlFor(worldId, 'a.mp3')!.host,
      InternetAddress.loopbackIPv4.address,
    );
  });

  test('a deleted attachment is no longer served', () async {
    final url = server.urlFor(worldId, 'voice note.mp3')!;
    final file = await db.getAttachmentByWorldId(worldId);
    await db.deleteAttachment(file!.id);

    final response = await get(url);
    expect(response.statusCode, HttpStatus.notFound);
    await response.drain<void>();
  });

  test('an unknown worldId is a 404, and reveals nothing else', () async {
    final url = server.urlFor(worldId, 'voice note.mp3')!;
    final unknown = url.replace(
      pathSegments: ['attachment', WorldId.create().value, 'x.mp3'],
    );

    final response = await get(unknown);
    expect(response.statusCode, HttpStatus.notFound);
    await response.drain<void>();
  });

  test('a stop that overtakes a pending start leaves no socket bound',
      () async {
    // The provider that owns the server is disposed by a database swap, and
    // its onDispose runs stop() while start() is still awaiting the bind.
    final late = AttachmentMediaServer(db);
    final starting = late.start();
    await late.stop();
    await starting;

    expect(late.isRunning, isFalse);
    expect(late.port, 0, reason: 'nothing may be left listening');
  });

  test('a token from a previous run does not work after a restart', () async {
    final staleUrl = server.urlFor(worldId, 'voice note.mp3')!;
    await server.stop();
    await server.start();

    // Same path, old token, new port: point it at the new port so only the
    // token differs.
    final response = await get(
      staleUrl.replace(port: server.port),
    );
    expect(response.statusCode, HttpStatus.forbidden);
    await response.drain<void>();
  });
}

Future<Uint8List> collectBytes(HttpClientResponse response) async {
  final builder = BytesBuilder(copy: false);
  await for (final chunk in response) {
    builder.add(chunk);
  }
  return builder.takeBytes();
}
