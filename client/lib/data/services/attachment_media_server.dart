import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import '../database/database.dart';

/// Serves attachment bytes to media players over loopback HTTP.
///
/// Players want a file path or a URL; attachment bytes live in the encrypted
/// database. Writing them to a temp file would leave decrypted media on disk —
/// the one thing this app otherwise never does outside an explicit export — so
/// they are streamed from the database instead, and nothing is persisted.
///
/// Loopback is not private: any process running as this user can reach the
/// port. Every URL therefore carries a per-run random token, and requests
/// without it are refused, so an attachment cannot be fetched (or enumerated)
/// by another local program that merely guesses the port.
///
/// Range requests are served with sliced reads, so playing a large attachment
/// does not allocate it whole.
///
/// Voice memos do not come through here at all any more. They used to, and had
/// to be decoded to WAV on the way past, because `audioplayers` on Windows is
/// Media Foundation and Opus is not one of its built-in formats — it depends on
/// Microsoft's removable *Web Media Extensions*. `voice_audio` plays a memo
/// from its bytes with its own decoder, so that whole detour is gone. What is
/// left here serves the ordinary attachments: mp3, m4a, wav and video.
class AttachmentMediaServer {
  /// Bytes per response chunk, and the cap for an open-ended range request.
  /// Large enough to keep playback smooth, small enough that a big attachment
  /// never lands in memory in one piece.
  static const int chunkSize = 512 * 1024;

  /// Set `NOO_MEDIA_DEBUG=1` to have every request logged to stderr. Playback
  /// failures on Linux surface as one opaque GStreamer message ("Internal data
  /// stream error") whatever went wrong, so seeing what this server was asked
  /// for and what it answered is the only way to tell a refused token from a
  /// failed decode from a request that never arrived.
  static final bool _debug = Platform.environment['NOO_MEDIA_DEBUG'] == '1';

  final NooDatabase _db;

  HttpServer? _server;
  late String _token;

  /// The last attachment decoded, kept so the range requests a player issues
  /// while seeking do not each pay for a fresh decode. One entry: playback is
  /// one attachment at a time.

  AttachmentMediaServer(this._db);

  /// Port the server is listening on, or 0 when it is not running.
  int get port => _server?.port ?? 0;

  bool get isRunning => _server != null;

  /// Bind on loopback at an ephemeral port. Safe to call repeatedly.
  Future<void> start() async {
    if (_server != null) return;

    _token = _randomToken();
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;

    unawaited(server.forEach(_handle).catchError((Object _) {
      // The server was closed underneath us; nothing to recover.
    }));
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  /// URL a player can open for the attachment identified by [worldId].
  ///
  /// The file name is carried as a trailing path segment because some players
  /// pick their demuxer from the extension.
  Uri? urlFor(String worldId, String filename) {
    final server = _server;
    if (server == null) return null;

    return Uri(
      scheme: 'http',
      host: InternetAddress.loopbackIPv4.address,
      port: server.port,
      pathSegments: ['attachment', worldId, _safeSegment(filename)],
      queryParameters: {'token': _token},
    );
  }

  static void _log(String message) {
    if (_debug) stderr.writeln('[media] $message');
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;
    // Once a byte is written the status is on the wire and cannot be changed;
    // until then a failure here should reach the player as a 500 rather than
    // as an empty 200, which it would report as an unexplained stream error.
    var bodyStarted = false;
    try {
      _log('${request.method} ${request.uri.path} '
          'range=${request.headers.value(HttpHeaders.rangeHeader)}');
      if (request.method != 'GET' && request.method != 'HEAD') {
        response.statusCode = HttpStatus.methodNotAllowed;
        await response.close();
        return;
      }

      // Constant-time-ish comparison is overkill here — a wrong token yields
      // no oracle beyond "not this one" — but the check must come first.
      if (request.uri.queryParameters['token'] != _token) {
        _log('403: token mismatch');
        response.statusCode = HttpStatus.forbidden;
        await response.close();
        return;
      }

      final segments = request.uri.pathSegments;
      if (segments.length < 2 || segments[0] != 'attachment') {
        _log('404: not an attachment path');
        response.statusCode = HttpStatus.notFound;
        await response.close();
        return;
      }

      final worldId = segments[1];
      final storedSize = await _db.getAttachmentSize(worldId);
      if (storedSize == null) {
        _log('404: no attachment $worldId');
        response.statusCode = HttpStatus.notFound;
        await response.close();
        return;
      }

      final filename = segments.length > 2 ? segments[2] : '';
      final size = storedSize;
      _log('serving $size B unchanged');

      response.headers
        ..contentType = _contentTypeFor(filename)
        ..set(HttpHeaders.acceptRangesHeader, 'bytes')
        // These URLs die with the process; never let anything cache them.
        ..set(HttpHeaders.cacheControlHeader, 'no-store');

      final range = _parseRange(request.headers.value(HttpHeaders.rangeHeader), size);

      if (range == null) {
        response.statusCode = HttpStatus.ok;
        response.headers.contentLength = size;
        if (request.method == 'HEAD') {
          await response.close();
          return;
        }
        bodyStarted = true;
        await _writeSlice(response, worldId, 0, size);
        await response.close();
        _log('200: sent $size B');
        return;
      }

      if (range.start >= size) {
        response.statusCode = HttpStatus.requestedRangeNotSatisfiable;
        response.headers.set(HttpHeaders.contentRangeHeader, 'bytes */$size');
        await response.close();
        return;
      }

      final length = range.end - range.start + 1;
      response.statusCode = HttpStatus.partialContent;
      response.headers
        ..contentLength = length
        ..set(
          HttpHeaders.contentRangeHeader,
          'bytes ${range.start}-${range.end}/$size',
        );

      if (request.method == 'HEAD') {
        await response.close();
        return;
      }

      bodyStarted = true;
      await _writeSlice(response, worldId, range.start, length);
      await response.close();
      _log('206: sent $length B from ${range.start}');
    } catch (error) {
      _log('aborted: $error');
      if (!bodyStarted) {
        try {
          response.statusCode = HttpStatus.internalServerError;
        } catch (_) {
          // Headers already went out; the status stands as it is.
        }
      }
      // A player that seeks aborts the in-flight response; that surfaces here
      // as a write error and is entirely normal.
      try {
        await response.close();
      } catch (_) {
        // Already gone.
      }
    }
  }

  /// Stream [length] bytes from [start] in [chunkSize] pieces, straight out of
  /// the database.
  Future<void> _writeSlice(
    HttpResponse response,
    String worldId,
    int start,
    int length,
  ) async {
    var sent = 0;
    while (sent < length) {
      final wanted = min(chunkSize, length - sent);
      final chunk = await _db.readAttachmentSlice(worldId, start + sent, wanted);
      if (chunk == null || chunk.isEmpty) break;

      response.add(chunk);
      // Let the socket drain before pulling the next slice, so a paused player
      // does not make us read the whole attachment into the write buffer.
      await response.flush();
      sent += chunk.length;
    }
  }

  /// Parse a single-range `Range: bytes=…` header. Multi-range requests (which
  /// no audio player issues) and malformed values fall back to a full body.
  _ByteRange? _parseRange(String? header, int size) {
    if (header == null || !header.startsWith('bytes=')) return null;

    final spec = header.substring('bytes='.length).trim();
    if (spec.contains(',')) return null;

    final dash = spec.indexOf('-');
    if (dash < 0) return null;

    final startText = spec.substring(0, dash).trim();
    final endText = spec.substring(dash + 1).trim();

    if (startText.isEmpty) {
      // Suffix form: the last N bytes.
      final suffix = int.tryParse(endText);
      if (suffix == null || suffix <= 0) return null;
      final start = max(0, size - suffix);
      return _ByteRange(start, size - 1);
    }

    final start = int.tryParse(startText);
    if (start == null || start < 0) return null;

    final end = endText.isEmpty ? size - 1 : int.tryParse(endText);
    if (end == null) return null;

    return _ByteRange(start, min(end, size - 1));
  }

  ContentType _contentTypeFor(String filename) {
    final dot = filename.lastIndexOf('.');
    final extension =
        dot < 0 ? '' : filename.substring(dot + 1).toLowerCase();

    return switch (extension) {
      'mp3' => ContentType('audio', 'mpeg'),
      'm4a' || 'aac' => ContentType('audio', 'mp4'),
      'wav' => ContentType('audio', 'wav'),
      'ogg' || 'oga' => ContentType('audio', 'ogg'),
      'opus' => ContentType('audio', 'opus'),
      'flac' => ContentType('audio', 'flac'),
      'mp4' || 'm4v' => ContentType('video', 'mp4'),
      'webm' => ContentType('video', 'webm'),
      _ => ContentType('application', 'octet-stream'),
    };
  }

  /// Keep the URL's last segment to a plain file name.
  String _safeSegment(String filename) {
    final cleaned = filename.replaceAll(RegExp(r'[/\\?#]'), '_').trim();
    return cleaned.isEmpty ? 'file' : cleaned;
  }

  static String _randomToken() {
    final random = Random.secure();
    return List.generate(
      24,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }
}

class _ByteRange {
  final int start;
  final int end;

  const _ByteRange(this.start, this.end);
}
