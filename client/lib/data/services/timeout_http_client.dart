import 'dart:async';

import 'package:http/http.dart' as http;

/// An [http.Client] whose requests cannot wait forever.
///
/// `package:http` sets no timeout of its own, and a TCP peer that simply stops
/// answering — a phone whose screen locked mid-exchange, a relay behind a
/// dropped connection that the kernel keeps acknowledging — never produces an
/// error, so a bare request never completes. In this app a request that never
/// completes holds `SyncService`'s one-run-at-a-time guard for the rest of
/// the process: every later relay sync, LAN exchange and sync-on-exit answers
/// "busy" until a restart. Two limits, both turning a stall into a
/// [TimeoutException] the sync reports as a failed run:
///
/// - [responseTimeout]: from sending the request to receiving the response
///   headers. This also spans the upload of the request body, so a client
///   that puts multi-megabyte blobs gets a longer one.
/// - [idleTimeout]: the longest silence allowed *within* the response body —
///   a page of packets or a blob slice that stops arriving halfway.
class TimeoutHttpClient extends http.BaseClient {
  TimeoutHttpClient(
    this._inner, {
    required this.responseTimeout,
    required this.idleTimeout,
  });

  final http.Client _inner;
  final Duration responseTimeout;
  final Duration idleTimeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request).timeout(
          responseTimeout,
          onTimeout: () => throw TimeoutException(
            'No response from ${request.url.host} within '
            '${responseTimeout.inSeconds}s',
          ),
        );
    final body = response.stream.timeout(
      idleTimeout,
      onTimeout: (sink) {
        sink.addError(TimeoutException(
          'Response from ${request.url.host} stalled for '
          '${idleTimeout.inSeconds}s',
        ));
        sink.close();
      },
    );
    return http.StreamedResponse(
      body,
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() => _inner.close();
}
