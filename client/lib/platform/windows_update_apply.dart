import 'dart:io';

import 'package:path/path.dart' as p;

import '../data/services/update_service.dart';

/// The second half of a portable Windows update (`UpdateService.method` ==
/// `windowsPortable`).
///
/// The running app cannot replace its own files — Windows keeps `noo.exe`
/// and the loaded DLLs locked — so the *new* `noo.exe`, unpacked into the
/// temp directory, is started with `--apply-update <target> <pid>` as the old
/// one exits. `main.dart` sends it here before anything else runs, so no
/// window appears: it waits for the old process to let go of `noo.exe`,
/// copies the bundle over it and starts the updated app. The old process's
/// PID is only informative; what is actually waited for is the lock, since
/// that is the thing standing in the way.
///
/// The exit code is for the log; nobody waits on it.
Future<int> applyWindowsUpdate(List<String> args) async {
  if (args.isEmpty) return 2;
  return applyUpdate(
    bundleDir: p.dirname(Platform.resolvedExecutable),
    targetDir: args.first,
  );
}

/// Copy [bundleDir] over [targetDir] once `noo.exe` there can be written, and
/// start it.
///
/// [targetFree] answers whether the target's executable is writable (the
/// default tries to open it for writing); it is polled every [interval] for
/// up to [timeout]. [launch] starts the updated app; the default detaches it.
/// Both are parameters so a test runs this on a directory, not a process.
///
/// Returns 0 when everything was copied, 1 when something failed — in which
/// case what went wrong is in `update-error.log` beside the bundle and the
/// app is started anyway, so the user is not left with nothing on screen.
Future<int> applyUpdate({
  required String bundleDir,
  required String targetDir,
  Future<bool> Function()? targetFree,
  Future<void> Function(String executable)? launch,
  Duration timeout = const Duration(seconds: 60),
  Duration interval = const Duration(milliseconds: 250),
}) async {
  final exe = p.join(targetDir, UpdateService.windowsExecutable);
  final isFree = targetFree ?? () => _writable(exe);
  final start = launch ?? _launchDetached;

  var code = 0;
  try {
    final deadline = DateTime.now().add(timeout);
    while (!await isFree()) {
      if (DateTime.now().isAfter(deadline)) {
        throw FileSystemException('still in use after $timeout', exe);
      }
      await Future<void>.delayed(interval);
    }

    // Flutter's data directory is replaced wholesale, as the installer does
    // it, so assets the new version no longer ships do not linger.
    await _retry(() async {
      final data = Directory(p.join(targetDir, 'data'));
      if (await data.exists()) await data.delete(recursive: true);
    });

    final root = p.normalize(p.absolute(bundleDir));
    await for (final entry in Directory(
      root,
    ).list(recursive: true, followLinks: false)) {
      if (entry is! File) continue;
      final rel = p.relative(entry.path, from: root);
      final out = File(p.join(targetDir, rel));
      await _retry(() async {
        await out.parent.create(recursive: true);
        await entry.copy(out.path);
      });
    }
  } catch (e) {
    code = 1;
    try {
      await File(
        p.join(p.dirname(bundleDir), 'update-error.log'),
      ).writeAsString('${DateTime.now().toIso8601String()} $e\n');
    } catch (_) {}
  }

  if (await File(exe).exists()) {
    try {
      await start(exe);
    } catch (_) {
      code = 1;
    }
  }
  return code;
}

/// Whether [path] can be opened for writing — which a running executable,
/// or a DLL a running process has loaded, cannot be.
Future<bool> _writable(String path) async {
  try {
    // Opening for append would create a missing file; nothing to wait for
    // then anyway.
    if (!await File(path).exists()) return true;
    final file = await File(path).open(mode: FileMode.append);
    await file.close();
    return true;
  } on FileSystemException {
    return false;
  }
}

/// A file the old process has just released can still be held for a moment
/// by an antivirus scan; three tries half a second apart cover that.
Future<void> _retry(Future<void> Function() action) async {
  for (var attempt = 1; ; attempt++) {
    try {
      await action();
      return;
    } on FileSystemException {
      if (attempt >= 3) rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }
}

Future<void> _launchDetached(String executable) => Process.start(
  executable,
  const [],
  workingDirectory: p.dirname(executable),
  mode: ProcessStartMode.detached,
);
