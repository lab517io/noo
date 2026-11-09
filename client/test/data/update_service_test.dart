import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:noo/data/services/update_service.dart';
import 'package:path/path.dart' as p;

const _appImageUrl =
    'https://github.com/lab517io/noo/releases/download/v1.3.0/noo-1.3.0-x86_64.AppImage';
const _sumsUrl =
    'https://github.com/lab517io/noo/releases/download/v1.3.0/SHA256SUMS';

Map<String, dynamic> _releaseJson({bool withSums = true}) => {
  'tag_name': 'v1.3.0',
  'html_url': 'https://github.com/lab517io/noo/releases/tag/v1.3.0',
  'body': '  Notes  ',
  'assets': [
    {
      'name': 'noo-1.3.0-android.apk',
      'browser_download_url': 'https://example/noo-1.3.0-android.apk',
      'size': 10,
    },
    {
      'name': 'noo-1.3.0-x86_64.AppImage',
      'browser_download_url': _appImageUrl,
      'size': 5,
    },
    if (withSums)
      {'name': 'SHA256SUMS', 'browser_download_url': _sumsUrl, 'size': 100},
  ],
};

void main() {
  group('compareVersions', () {
    test('orders numerically, not lexically', () {
      expect(compareVersions('1.2.10', '1.2.9'), greaterThan(0));
      expect(compareVersions('1.2.6', '1.3.0'), lessThan(0));
      expect(compareVersions('2.0.0', '1.99.99'), greaterThan(0));
    });

    test('ignores a v prefix and build/pre-release suffixes', () {
      expect(compareVersions('v1.2.6', '1.2.6'), 0);
      expect(compareVersions('1.2.6+3', '1.2.6'), 0);
      expect(compareVersions('1.2', '1.2.0'), 0);
    });
  });

  test('parseSha256Sums reads text and binary mode lines', () {
    final a = 'a' * 64, b = 'B' * 64;
    final sums = parseSha256Sums('$a  noo.AppImage\n$b *noo.apk\ngarbage\n');
    expect(sums, {'noo.AppImage': a, 'noo.apk': 'b' * 64});
  });

  group('ReleaseInfo', () {
    test('parses the GitHub payload and picks assets by platform', () {
      final r = ReleaseInfo.fromGitHubJson(_releaseJson());
      expect(r.version, '1.3.0');
      expect(r.notes, 'Notes');
      expect(r.isNewerThan('1.2.6'), isTrue);
      expect(r.isNewerThan('1.3.0'), isFalse);
      expect(r.assetFor(UpdatePlatform.android)?.name, 'noo-1.3.0-android.apk');
      expect(
        r.assetFor(UpdatePlatform.linuxAppImage)?.downloadUrl,
        _appImageUrl,
      );
      expect(r.assetFor(UpdatePlatform.windows), isNull);
    });
  });

  group('fetchLatest', () {
    test('returns the release on 200', () async {
      final service = UpdateService(
        client: MockClient((req) async {
          expect(req.url, UpdateService.latestReleaseUri);
          return http.Response(jsonEncode(_releaseJson()), 200);
        }),
      );
      expect((await service.fetchLatest()).version, '1.3.0');
    });

    test('turns an HTTP error into an UpdateException', () async {
      final service = UpdateService(
        client: MockClient((_) async => http.Response('rate limited', 403)),
      );
      expect(service.fetchLatest(), throwsA(isA<UpdateException>()));
    });
  });

  group('installAppImage', () {
    late Directory dir;
    late File appImage;
    final payload = utf8.encode('new appimage bytes');

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('noo_update_test');
      appImage = File(p.join(dir.path, 'Noo.AppImage'));
      await appImage.writeAsString('old');
      await Process.run('chmod', ['755', appImage.path]);
    });

    tearDown(() => dir.delete(recursive: true));

    UpdateService serviceWith(String sums) => UpdateService(
      environment: {'APPIMAGE': appImage.path},
      client: MockClient.streaming((req, _) async {
        if (req.url.toString() == _sumsUrl) {
          return http.StreamedResponse(Stream.value(utf8.encode(sums)), 200);
        }
        if (req.url.toString() == _appImageUrl) {
          return http.StreamedResponse(
            Stream.fromIterable([payload.sublist(0, 4), payload.sublist(4)]),
            200,
            contentLength: payload.length,
          );
        }
        return http.StreamedResponse(const Stream.empty(), 404);
      }),
    );

    List<String> leftovers() => dir
        .listSync()
        .map((e) => p.basename(e.path))
        .where((n) => n != 'Noo.AppImage')
        .toList();

    test('replaces the AppImage when the checksum matches', () async {
      final service = serviceWith(
        '${sha256.convert(payload)}  noo-1.3.0-x86_64.AppImage\n',
      );
      final progress = <int>[];
      await service.installAppImage(
        ReleaseInfo.fromGitHubJson(_releaseJson()),
        onProgress: (received, total) {
          expect(total, payload.length);
          progress.add(received);
        },
      );
      expect(await appImage.readAsBytes(), payload);
      expect(progress.last, payload.length);
      expect((await appImage.stat()).mode & 0x1ff, 0x1ed); // 0755
      expect(leftovers(), isEmpty);
    });

    test('keeps the old AppImage on a checksum mismatch', () async {
      final service = serviceWith('${'0' * 64}  noo-1.3.0-x86_64.AppImage\n');
      await expectLater(
        service.installAppImage(ReleaseInfo.fromGitHubJson(_releaseJson())),
        throwsA(isA<UpdateException>()),
      );
      expect(await appImage.readAsString(), 'old');
      expect(leftovers(), isEmpty);
    });

    test('refuses a release without SHA256SUMS', () async {
      final service = serviceWith('');
      await expectLater(
        service.installAppImage(
          ReleaseInfo.fromGitHubJson(_releaseJson(withSums: false)),
        ),
        throwsA(isA<UpdateException>()),
      );
      expect(await appImage.readAsString(), 'old');
    });

    test('cancel leaves the old AppImage in place', () async {
      final service = serviceWith(
        '${sha256.convert(payload)}  noo-1.3.0-x86_64.AppImage\n',
      );
      final cancel = Completer<void>();
      await expectLater(
        service.installAppImage(
          ReleaseInfo.fromGitHubJson(_releaseJson()),
          cancel: cancel.future,
          onProgress: (_, _) {
            if (!cancel.isCompleted) cancel.complete();
          },
        ),
        throwsA(isA<UpdateCancelled>()),
      );
      expect(await appImage.readAsString(), 'old');
      expect(leftovers(), isEmpty);
    });

    test('is refused when not running from an AppImage', () {
      final service = UpdateService(
        environment: const {},
        client: MockClient((_) async => http.Response('', 404)),
      );
      expect(
        service.installAppImage(ReleaseInfo.fromGitHubJson(_releaseJson())),
        throwsA(isA<UpdateException>()),
      );
    });
  });
}
