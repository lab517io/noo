import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:noo/data/services/update_service.dart';
import 'package:path/path.dart' as p;

const _base = 'https://github.com/lab517io/noo/releases/download/v1.3.0/';
const _zipName = 'noo-1.3.0-windows-x64.zip';
const _setupName = 'noo-1.3.0-windows-x64-setup.exe';

ReleaseInfo _release({bool zip = true, bool setup = true, bool sums = true}) =>
    ReleaseInfo.fromGitHubJson({
      'tag_name': 'v1.3.0',
      'html_url': 'https://github.com/lab517io/noo/releases/tag/v1.3.0',
      'body': '',
      'assets': [
        if (zip) {'name': _zipName, 'browser_download_url': '$_base$_zipName'},
        if (setup)
          {'name': _setupName, 'browser_download_url': '$_base$_setupName'},
        {
          'name': 'noo-1.3.0-x86_64.AppImage',
          'browser_download_url': '${_base}noo-1.3.0-x86_64.AppImage',
        },
        if (sums)
          {'name': 'SHA256SUMS', 'browser_download_url': '${_base}SHA256SUMS'},
      ],
    });

/// A ZIP laid out like `build_windows.py` makes it: everything under `noo/`.
Uint8List _zip(Map<String, String> files) {
  final archive = Archive();
  files.forEach((name, text) {
    final bytes = utf8.encode(text);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

final _bundle = _zip({
  'noo/noo.exe': 'new exe',
  'noo/flutter_windows.dll': 'dll',
  'noo/data/flutter_assets/kernel_blob.bin': 'assets',
});
final _setup = utf8.encode('setup program bytes');

String _sums({Uint8List? zip, List<int>? setup}) =>
    '${sha256.convert(zip ?? _bundle)}  $_zipName\n'
    '${sha256.convert(setup ?? _setup)}  $_setupName\n';

void main() {
  late Directory root;
  late Directory temp;
  late Directory app;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('noo_update_win');
    temp = await Directory(p.join(root.path, 'temp')).create();
    app = await Directory(p.join(root.path, 'app')).create();
    await File(p.join(app.path, 'noo.exe')).writeAsString('old exe');
  });

  tearDown(() => root.delete(recursive: true));

  UpdateService service({
    String sums = '',
    Uint8List? zip,
    List<int>? setup,
    bool installed = false,
    bool windows = true,
    Map<String, String> environment = const {},
  }) {
    if (installed) {
      File(p.join(app.path, 'uninstall.exe')).writeAsStringSync('u');
    }
    return UpdateService(
      environment: environment,
      executable: p.join(app.path, 'noo.exe'),
      windows: windows,
      tempDirectory: temp,
      client: MockClient.streaming((req, _) async {
        final url = req.url.toString();
        if (url == '${_base}SHA256SUMS') {
          return http.StreamedResponse(Stream.value(utf8.encode(sums)), 200);
        }
        if (url == '$_base$_zipName') {
          final bytes = zip ?? _bundle;
          return http.StreamedResponse(
            Stream.fromIterable([bytes.sublist(0, 10), bytes.sublist(10)]),
            200,
            contentLength: bytes.length,
          );
        }
        if (url == '$_base$_setupName') {
          return http.StreamedResponse(
            Stream.value(setup ?? _setup),
            200,
            contentLength: (setup ?? _setup).length,
          );
        }
        return http.StreamedResponse(const Stream.empty(), 404);
      }),
    );
  }

  List<String> tempEntries() =>
      temp.listSync().map((e) => p.basename(e.path)).toList();

  group('method', () {
    test('is the installer when uninstall.exe sits beside noo.exe', () {
      expect(service(installed: true).method, UpdateMethod.windowsInstaller);
    });

    test('is portable for a bare noo.exe', () {
      expect(service().method, UpdateMethod.windowsPortable);
    });

    test('is the AppImage when APPIMAGE is set, and none elsewhere', () {
      expect(
        service(windows: false, environment: {'APPIMAGE': '/x/Noo'}).method,
        UpdateMethod.appImage,
      );
      expect(service(windows: false).method, UpdateMethod.none);
    });

    test('canInstall needs the asset the method installs from', () {
      expect(service().canInstall(_release(zip: false)), isFalse);
      expect(service().canInstall(_release(setup: false)), isTrue);
      expect(
        service(installed: true).canInstall(_release(setup: false)),
        isFalse,
      );
      expect(service(installed: true).canInstall(_release()), isTrue);
      expect(service(windows: false).canInstall(_release()), isFalse);
    });
  });

  group('portable', () {
    test('downloads, verifies and unpacks the ZIP into the temp dir', () async {
      final progress = <int>[];
      final prepared = await service(sums: _sums()).prepare(
        _release(),
        onProgress: (received, total) {
          expect(total, _bundle.length);
          progress.add(received);
        },
      );
      expect(progress.last, _bundle.length);
      final update = prepared as WindowsPortableUpdate;
      expect(update.targetDir, app.path);
      expect(p.isWithin(temp.path, update.bundleDir), isTrue);
      expect(p.isWithin(update.tempDir, update.bundleDir), isTrue);
      expect(
        await File(p.join(update.bundleDir, 'noo.exe')).readAsString(),
        'new exe',
      );
      expect(
        await File(
          p.join(update.bundleDir, 'data', 'flutter_assets', 'kernel_blob.bin'),
        ).readAsString(),
        'assets',
      );
      // The archive itself is not kept once unpacked.
      expect(
        Directory(update.tempDir).listSync().map((e) => p.basename(e.path)),
        ['staging'],
      );
      // Nothing beside the running app was touched.
      expect(await File(p.join(app.path, 'noo.exe')).readAsString(), 'old exe');
      expect(app.listSync().length, 1);

      await service().discard(update);
      expect(tempEntries(), isEmpty);
    });

    test('a checksum mismatch leaves nothing behind', () async {
      await expectLater(
        service(
          sums: _sums(zip: _zip({'noo/noo.exe': 'other'})),
        ).prepare(_release()),
        throwsA(
          isA<UpdateException>().having(
            (e) => e.message,
            'message',
            contains('checksum'),
          ),
        ),
      );
      expect(tempEntries(), isEmpty);
    });

    test('a ZIP without noo/noo.exe is refused', () async {
      final zip = _zip({'readme.txt': 'nothing here'});
      await expectLater(
        service(
          sums: _sums(zip: zip),
          zip: zip,
        ).prepare(_release()),
        throwsA(
          isA<UpdateException>().having(
            (e) => e.message,
            'message',
            contains('noo.exe'),
          ),
        ),
      );
      expect(tempEntries(), isEmpty);
    });

    test('an entry that escapes the staging dir is refused', () async {
      for (final name in ['../evil.exe', 'noo/../../evil.exe', 'C:/evil.exe']) {
        final zip = _zip({'noo/noo.exe': 'x', name: 'payload'});
        await expectLater(
          service(
            sums: _sums(zip: zip),
            zip: zip,
          ).prepare(_release()),
          throwsA(
            isA<UpdateException>().having(
              (e) => e.message,
              'message',
              contains('unsafe'),
            ),
          ),
          reason: name,
        );
        expect(File(p.join(root.path, 'evil.exe')).existsSync(), isFalse);
        expect(tempEntries(), isEmpty, reason: name);
      }
    });

    test('cancel leaves nothing behind', () async {
      final cancel = Completer<void>();
      await expectLater(
        service(sums: _sums()).prepare(
          _release(),
          cancel: cancel.future,
          onProgress: (_, _) {
            if (!cancel.isCompleted) cancel.complete();
          },
        ),
        throwsA(isA<UpdateCancelled>()),
      );
      expect(tempEntries(), isEmpty);
    });

    test('a release without the ZIP is refused before any download', () async {
      await expectLater(
        service(sums: _sums()).prepare(_release(zip: false)),
        throwsA(isA<UpdateException>()),
      );
      expect(tempEntries(), isEmpty);
    });
  });

  group('installer', () {
    test('downloads and verifies the setup program', () async {
      final prepared = await service(
        sums: _sums(),
        installed: true,
      ).prepare(_release());
      final update = prepared as WindowsInstallerUpdate;
      expect(p.isWithin(temp.path, update.setupPath), isTrue);
      expect(p.basename(update.setupPath), _setupName);
      expect(await File(update.setupPath).readAsBytes(), _setup);

      await service().discard(update);
      expect(tempEntries(), isEmpty);
    });

    test('a checksum mismatch leaves nothing behind', () async {
      await expectLater(
        service(
          sums: _sums(setup: utf8.encode('other')),
          installed: true,
        ).prepare(_release()),
        throwsA(isA<UpdateException>()),
      );
      expect(tempEntries(), isEmpty);
    });

    test('a release without SHA256SUMS is refused', () async {
      await expectLater(
        service(installed: true).prepare(_release(sums: false)),
        throwsA(isA<UpdateException>()),
      );
      expect(tempEntries(), isEmpty);
    });
  });

  group('cleanStaleDownloads', () {
    test(
      'removes old noo-update-* dirs and keeps fresh and foreign ones',
      () async {
        final old = await Directory(
          p.join(temp.path, 'noo-update-old'),
        ).create();
        await File(p.join(old.path, 'setup.exe')).writeAsString('x');
        // Directory mtime cannot be set from Dart; mark the fresh one by
        // leaving it as created and age the old one through its parent's
        // listing instead: the cutoff is an hour, so only an explicitly aged
        // directory can be deleted. Age it with the platform's touch.
        await _age(old, const Duration(hours: 2));
        final fresh = await Directory(
          p.join(temp.path, 'noo-update-fresh'),
        ).create();
        final foreign = await Directory(
          p.join(temp.path, 'other-old'),
        ).create();
        await _age(foreign, const Duration(hours: 2));

        await UpdateService.cleanStaleDownloads(tempDirectory: temp);

        expect(old.existsSync(), isFalse);
        expect(fresh.existsSync(), isTrue);
        expect(foreign.existsSync(), isTrue);
      },
    );

    test('a missing temp dir is not an error', () async {
      await UpdateService.cleanStaleDownloads(
        tempDirectory: Directory(p.join(root.path, 'nowhere')),
      );
    });
  });
}

/// Set a directory's modification time [age] into the past.
Future<void> _age(Directory dir, Duration age) async {
  final when = DateTime.now().subtract(age);
  if (Platform.isWindows) {
    final stamp = when.toIso8601String();
    final result = await Process.run('powershell', [
      '-NoProfile',
      '-Command',
      "(Get-Item -LiteralPath '${dir.path}').LastWriteTime = [DateTime]::Parse('$stamp')",
    ]);
    expect(result.exitCode, 0, reason: result.stderr.toString());
  } else {
    final stamp = when.toUtc().toIso8601String();
    final result = await Process.run('touch', ['-d', stamp, dir.path]);
    expect(result.exitCode, 0, reason: result.stderr.toString());
  }
  expect(
    (await dir.stat()).modified.isBefore(when.add(const Duration(minutes: 1))),
    isTrue,
  );
}
