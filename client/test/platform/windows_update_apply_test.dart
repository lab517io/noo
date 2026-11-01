import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/platform/windows_update_apply.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  late Directory bundle;
  late Directory target;

  Future<void> write(Directory dir, String rel, String text) async {
    final file = File(p.join(dir.path, rel));
    await file.parent.create(recursive: true);
    await file.writeAsString(text);
  }

  Future<String?> read(Directory dir, String rel) async {
    final file = File(p.join(dir.path, rel));
    return await file.exists() ? file.readAsString() : null;
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('noo_apply_test');
    bundle = await Directory(
      p.join(root.path, 'temp', 'staging', 'noo'),
    ).create(recursive: true);
    target = await Directory(p.join(root.path, 'app')).create();
    await write(bundle, 'noo.exe', 'new exe');
    await write(bundle, 'flutter_windows.dll', 'new dll');
    await write(bundle, 'data/flutter_assets/kernel_blob.bin', 'new assets');
    await write(bundle, 'data/icudtl.dat', 'icu');
    await write(target, 'noo.exe', 'old exe');
    await write(target, 'flutter_windows.dll', 'old dll');
    await write(target, 'data/flutter_assets/kernel_blob.bin', 'old assets');
    await write(target, 'data/flutter_assets/stale.bin', 'gone in the new one');
    await write(target, 'my-notes.txt', 'the user put this here');
  });

  tearDown(() => root.delete(recursive: true));

  test(
    'waits for the lock, replaces data wholesale, and starts the app',
    () async {
      var polls = 0;
      final launched = <String>[];
      final code = await applyUpdate(
        bundleDir: bundle.path,
        targetDir: target.path,
        targetFree: () async => ++polls >= 3,
        launch: (exe) async => launched.add(exe),
        interval: Duration.zero,
      );
      expect(code, 0);
      expect(polls, 3);
      expect(await read(target, 'noo.exe'), 'new exe');
      expect(await read(target, 'flutter_windows.dll'), 'new dll');
      expect(
        await read(target, 'data/flutter_assets/kernel_blob.bin'),
        'new assets',
      );
      expect(await read(target, 'data/icudtl.dat'), 'icu');
      // The old data directory went with everything in it...
      expect(await read(target, 'data/flutter_assets/stale.bin'), isNull);
      // ...and nothing else of the user's did.
      expect(await read(target, 'my-notes.txt'), 'the user put this here');
      expect(launched, [p.join(target.path, 'noo.exe')]);
      // The bundle is left for the next start's cleanup, not deleted by the
      // process running from it.
      expect(await read(bundle, 'noo.exe'), 'new exe');
    },
  );

  test(
    'gives up after the timeout, logs it, and still starts the app',
    () async {
      final launched = <String>[];
      final code = await applyUpdate(
        bundleDir: bundle.path,
        targetDir: target.path,
        targetFree: () async => false,
        launch: (exe) async => launched.add(exe),
        timeout: const Duration(milliseconds: 50),
        interval: const Duration(milliseconds: 5),
      );
      expect(code, 1);
      expect(await read(target, 'noo.exe'), 'old exe');
      expect(await read(target, 'data/flutter_assets/stale.bin'), isNotNull);
      expect(launched, [p.join(target.path, 'noo.exe')]);
      final log = File(
        p.join(root.path, 'temp', 'staging', 'update-error.log'),
      );
      expect(await log.readAsString(), contains('still in use'));
    },
  );

  test('the default lock probe passes for a file nothing holds', () async {
    final launched = <String>[];
    final code = await applyUpdate(
      bundleDir: bundle.path,
      targetDir: target.path,
      launch: (exe) async => launched.add(exe),
      timeout: const Duration(seconds: 5),
    );
    expect(code, 0);
    expect(await read(target, 'noo.exe'), 'new exe');
    expect(launched, hasLength(1));
  });

  test('a bad argument list is an error, not a crash', () async {
    expect(await applyWindowsUpdate(const []), 2);
  });
}
