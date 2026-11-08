import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// Help → Check for Update.
///
/// The source of truth is the latest release of the public repository on
/// GitHub — the same place the downloads are published (see
/// `scripts/publish_release.py`). Nothing is checked in the background: the
/// app talks to GitHub only when the user asks.
///
/// What happens with a newer release depends on how the app was installed
/// ([method]). Every in-place path downloads the release's asset for this
/// build and verifies it against the release's `SHA256SUMS` before anything
/// of the running copy is touched:
/// - Linux AppImage (`$APPIMAGE` set): the new AppImage is downloaded next to
///   the running one and renamed over it. The running process keeps its (now
///   unlinked) image; the new one takes effect on restart.
/// - Windows, installed with the setup program (`uninstall.exe` beside the
///   exe): the new setup program is downloaded and, once the app has run its
///   exit sequence, started silently with `/RELAUNCH`. It waits for this
///   process to let go of `noo.exe`, replaces the files, updates the Apps &
///   features entry and starts the app again (`installer/windows/noo.nsi`).
/// - Windows, portable ZIP: the ZIP is downloaded and unpacked in the temp
///   directory, and after the exit sequence the *new* `noo.exe` is started
///   from there with `--apply-update`: it waits for this process to exit,
///   copies the bundle over the old one and starts it
///   (`platform/windows_update_apply.dart`). Nothing is written next to the
///   app until the old process is gone, and nothing at all when its directory
///   is not writable — then the release page is offered instead.
/// - Android: the APK is opened in the browser. Installing it in-app would need
///   REQUEST_INSTALL_PACKAGES, which Play does not allow for this kind of app.
/// - A Linux build not running from an AppImage, macOS: no installable asset,
///   so the release page is opened.
class UpdateService {
  UpdateService({
    http.Client? client,
    Map<String, String>? environment,
    String? executable,
    bool? windows,
    Directory? tempDirectory,
  }) : _client = client ?? http.Client(),
       _environment = environment ?? Platform.environment,
       _executable = executable ?? Platform.resolvedExecutable,
       _windows = windows ?? Platform.isWindows,
       _tempDirectory = tempDirectory ?? Directory.systemTemp;

  static const repository = 'lab517io/noo';
  static final latestReleaseUri = Uri.https(
    'api.github.com',
    '/repos/$repository/releases/latest',
  );

  static const _checksumsAsset = 'SHA256SUMS';

  /// What the Windows setup program leaves beside `noo.exe`; a ZIP has none.
  static const windowsUninstaller = 'uninstall.exe';
  static const windowsExecutable = 'noo.exe';

  /// The top-level directory inside the Windows ZIP (`build_windows.py`).
  static const windowsZipRoot = 'noo';

  /// First argument of a `noo.exe` started to finish a portable update; see
  /// `main.dart` and `applyWindowsUpdate`.
  static const applyUpdateFlag = '--apply-update';

  /// Prefix of the temp directories the Windows paths download into.
  static const tempPrefix = 'noo-update-';

  final http.Client _client;
  final Map<String, String> _environment;
  final String _executable;
  final bool _windows;
  final Directory _tempDirectory;

  /// The latest published (non-draft, non-prerelease) release.
  Future<ReleaseInfo> fetchLatest() async {
    final http.Response response;
    try {
      response = await _client
          .get(
            latestReleaseUri,
            headers: const {
              'Accept': 'application/vnd.github+json',
              'User-Agent': 'noo-update-check',
            },
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const UpdateException('GitHub did not answer in time');
    } on SocketException catch (e) {
      throw UpdateException('Cannot reach GitHub: ${e.message}');
    } on http.ClientException catch (e) {
      throw UpdateException('Cannot reach GitHub: ${e.message}');
    }
    if (response.statusCode != 200) {
      throw UpdateException(
        'GitHub answered ${response.statusCode} for the latest release',
      );
    }
    try {
      return ReleaseInfo.fromGitHubJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on FormatException catch (e) {
      throw UpdateException('Unexpected release data: ${e.message}');
    } on TypeError {
      throw const UpdateException('Unexpected release data');
    }
  }

  /// Path of the running AppImage, or null when not running from one.
  String? get appImagePath {
    final path = _environment['APPIMAGE'];
    return (path == null || path.isEmpty) ? null : path;
  }

  /// The directory `noo.exe` runs from (Windows).
  String get _windowsAppDir => p.dirname(_executable);

  /// How this copy of the app can be replaced in place, if at all.
  late final UpdateMethod method = _detectMethod();

  UpdateMethod _detectMethod() {
    if (appImagePath != null) return UpdateMethod.appImage;
    if (_windows) {
      final installed = File(
        p.join(_windowsAppDir, windowsUninstaller),
      ).existsSync();
      return installed
          ? UpdateMethod.windowsInstaller
          : UpdateMethod.windowsPortable;
    }
    return UpdateMethod.none;
  }

  /// Whether [release] can be installed in place on this machine: there is a
  /// method, and the release carries the asset it needs.
  bool canInstall(ReleaseInfo release) {
    final platform = method.platform;
    return platform != null && release.assetFor(platform) != null;
  }

  /// Download and verify [release] for [method], and do whatever can be done
  /// while the app is still running. What comes back is handed to
  /// [launchAfterExit] once the app has run its exit sequence, or to
  /// [discard].
  ///
  /// [onProgress] receives bytes received and the total (null if unknown).
  /// Completing [cancel] abandons the download and leaves the current copy
  /// untouched.
  Future<PreparedUpdate> prepare(
    ReleaseInfo release, {
    void Function(int received, int? total)? onProgress,
    Future<void>? cancel,
  }) async {
    switch (method) {
      case UpdateMethod.appImage:
        await installAppImage(release, onProgress: onProgress, cancel: cancel);
        return const AppImageUpdate();
      case UpdateMethod.windowsInstaller:
        return _prepareWindowsInstaller(
          release,
          onProgress: onProgress,
          cancel: cancel,
        );
      case UpdateMethod.windowsPortable:
        return _prepareWindowsPortable(
          release,
          onProgress: onProgress,
          cancel: cancel,
        );
      case UpdateMethod.none:
        throw const UpdateException('No in-place update on this platform');
    }
  }

  /// Start whatever finishes [update] once this process has exited. Called
  /// right before `exit(0)`, after the app's exit sequence.
  Future<void> launchAfterExit(PreparedUpdate update) async {
    switch (update) {
      case AppImageUpdate():
        await scheduleRelaunch();
      case WindowsInstallerUpdate(:final setupPath):
        // The setup waits for noo.exe to be released (WAIT_FOR_APP_EXIT in
        // noo.nsi retries in silent mode), so starting it before we exit is
        // not a race.
        await Process.start(setupPath, const [
          '/S',
          '/RELAUNCH',
        ], mode: ProcessStartMode.detached);
      case WindowsPortableUpdate(:final bundleDir, :final targetDir):
        await Process.start(
          p.join(bundleDir, windowsExecutable),
          [applyUpdateFlag, targetDir, '$pid'],
          workingDirectory: bundleDir,
          mode: ProcessStartMode.detached,
        );
    }
  }

  /// Remove what [prepare] downloaded, when the user decides against it.
  Future<void> discard(PreparedUpdate update) async {
    final dir = switch (update) {
      AppImageUpdate() => null,
      WindowsInstallerUpdate(:final tempDir) => tempDir,
      WindowsPortableUpdate(:final tempDir) => tempDir,
    };
    if (dir != null) await _deleteQuietly(Directory(dir));
  }

  /// Delete the temp directories earlier runs left behind: a setup program
  /// that has run, a bundle whose `noo.exe` finished applying itself. Only
  /// those older than an hour, so a download in progress in another instance
  /// is left alone; a directory something still holds open simply survives
  /// until the next start. Best-effort, never throws.
  static Future<void> cleanStaleDownloads({Directory? tempDirectory}) async {
    final temp = tempDirectory ?? Directory.systemTemp;
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    try {
      await for (final entry in temp.list(followLinks: false)) {
        if (entry is! Directory) continue;
        if (!p.basename(entry.path).startsWith(tempPrefix)) continue;
        try {
          if ((await entry.stat()).modified.isAfter(cutoff)) continue;
          await entry.delete(recursive: true);
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<WindowsInstallerUpdate> _prepareWindowsInstaller(
    ReleaseInfo release, {
    void Function(int received, int? total)? onProgress,
    Future<void>? cancel,
  }) async {
    final asset = release.assetFor(UpdatePlatform.windowsInstaller);
    if (asset == null) {
      throw UpdateException(
        'Release ${release.version} has no Windows installer',
      );
    }
    final expected = await _expectedSha256(release, asset.name);
    final dir = await _tempDirectory.createTemp(tempPrefix);
    try {
      final setup = File(p.join(dir.path, asset.name));
      await _download(
        asset,
        expected,
        setup,
        onProgress: onProgress,
        cancel: cancel,
      );
      return WindowsInstallerUpdate(tempDir: dir.path, setupPath: setup.path);
    } catch (_) {
      await _deleteQuietly(dir);
      rethrow;
    }
  }

  Future<WindowsPortableUpdate> _prepareWindowsPortable(
    ReleaseInfo release, {
    void Function(int received, int? total)? onProgress,
    Future<void>? cancel,
  }) async {
    final asset = release.assetFor(UpdatePlatform.windows);
    if (asset == null) {
      throw UpdateException('Release ${release.version} has no Windows ZIP');
    }
    final targetDir = _windowsAppDir;
    // Fail before downloading 20 MB if the app's directory is not ours.
    final probe = File(p.join(targetDir, '.noo-update-probe'));
    try {
      await probe.writeAsBytes(const [], flush: true);
      await probe.delete();
    } on FileSystemException {
      throw UpdateException(
        'Cannot write to $targetDir; download the new version manually',
      );
    }
    final expected = await _expectedSha256(release, asset.name);
    final dir = await _tempDirectory.createTemp(tempPrefix);
    try {
      final zip = File(p.join(dir.path, asset.name));
      await _download(
        asset,
        expected,
        zip,
        onProgress: onProgress,
        cancel: cancel,
      );
      final staging = Directory(p.join(dir.path, 'staging'));
      await _extractZip(zip, staging);
      await zip.delete();
      final bundleDir = p.join(staging.path, windowsZipRoot);
      if (!File(p.join(bundleDir, windowsExecutable)).existsSync()) {
        throw UpdateException(
          '${asset.name} does not contain $windowsZipRoot\\$windowsExecutable',
        );
      }
      return WindowsPortableUpdate(
        tempDir: dir.path,
        bundleDir: bundleDir,
        targetDir: targetDir,
      );
    } catch (_) {
      await _deleteQuietly(dir);
      rethrow;
    }
  }

  /// Unpack [zip] under [into]. An entry that would land outside [into] —
  /// an absolute name, a `..` segment, a drive letter — fails the whole
  /// update: the archive came over the network, hash-checked against what
  /// was published, but the publishing script is the only thing that makes
  /// it well-formed.
  static Future<void> _extractZip(File zip, Directory into) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(await zip.readAsBytes());
    } on ArchiveException catch (e) {
      throw UpdateException('The download is not a valid ZIP: ${e.message}');
    }
    final root = p.normalize(p.absolute(into.path));
    for (final entry in archive) {
      if (!entry.isFile) continue;
      final name = entry.name.replaceAll('\\', '/');
      final segments = p.posix.split(name);
      if (p.posix.isAbsolute(name) ||
          segments.any((s) => s == '..' || s.contains(':'))) {
        throw UpdateException('The ZIP holds an unsafe path: ${entry.name}');
      }
      final out = File(p.join(root, p.joinAll(segments)));
      if (!p.isWithin(root, out.path)) {
        throw UpdateException('The ZIP holds an unsafe path: ${entry.name}');
      }
      try {
        await out.parent.create(recursive: true);
        await out.writeAsBytes(entry.content, flush: true);
      } on FileSystemException catch (e) {
        throw UpdateException('Cannot unpack the download: ${e.message}');
      }
    }
  }

  /// Download [release]'s AppImage and put it in place of the running one.
  ///
  /// The download goes to a hidden file in the same directory, so the final
  /// step is a rename within one file system — atomic, and the running
  /// process is unaffected because it holds the old inode open. Nothing
  /// replaces the current AppImage unless the whole file arrived and its
  /// SHA-256 matches the release's `SHA256SUMS`.
  ///
  /// [onProgress] receives bytes received and the total (null if unknown).
  /// Completing [cancel] abandons the download and leaves the current
  /// AppImage untouched.
  Future<void> installAppImage(
    ReleaseInfo release, {
    void Function(int received, int? total)? onProgress,
    Future<void>? cancel,
  }) async {
    final target = appImagePath;
    if (target == null) {
      throw const UpdateException('Not running from an AppImage');
    }
    final asset = release.assetFor(UpdatePlatform.linuxAppImage);
    if (asset == null) {
      throw UpdateException('Release ${release.version} has no Linux AppImage');
    }
    final expected = await _expectedSha256(release, asset.name);

    final partial = File(
      p.join(p.dirname(target), '.${p.basename(target)}.update'),
    );

    // Fail before downloading 25 MB if the AppImage's directory is not ours.
    try {
      await partial.writeAsBytes(const [], flush: true);
    } on FileSystemException {
      throw UpdateException(
        'Cannot write to ${p.dirname(target)}; download the new version '
        'manually',
      );
    }

    try {
      await _download(
        asset,
        expected,
        partial,
        onProgress: onProgress,
        cancel: cancel,
      );

      // Same permissions as the file it replaces (at least u+x).
      final mode = (await File(target).stat()).mode & 0x1ff;
      final chmod = await Process.run('chmod', [
        (mode | 0x40).toRadixString(8),
        partial.path,
      ]);
      if (chmod.exitCode != 0) {
        throw UpdateException(
          'Cannot make the new AppImage executable: ${chmod.stderr}',
        );
      }
      try {
        await partial.rename(target);
      } on FileSystemException catch (e) {
        throw UpdateException('Cannot replace $target: ${e.message}');
      }
    } finally {
      if (await partial.exists()) {
        try {
          await partial.delete();
        } catch (_) {}
      }
    }
  }

  /// Stream [asset] into [file], hashing as it goes, and refuse it unless
  /// the whole thing arrived and matches [expected]. On any failure — the
  /// network, the disk, a cancel, a wrong hash — [file] is removed.
  Future<void> _download(
    ReleaseAsset asset,
    String expected,
    File file, {
    void Function(int received, int? total)? onProgress,
    Future<void>? cancel,
  }) async {
    var cancelled = false;
    unawaited(cancel?.then((_) => cancelled = true));
    var ok = false;
    try {
      final request = http.Request('GET', Uri.parse(asset.downloadUrl))
        ..headers['User-Agent'] = 'noo-update-check';
      final http.StreamedResponse response;
      try {
        response = await _client.send(request);
      } on SocketException catch (e) {
        throw UpdateException('Download failed: ${e.message}');
      } on http.ClientException catch (e) {
        throw UpdateException('Download failed: ${e.message}');
      }
      if (response.statusCode != 200) {
        throw UpdateException(
          'Download failed: server answered ${response.statusCode}',
        );
      }

      final IOSink sink;
      try {
        sink = file.openWrite();
      } on FileSystemException catch (e) {
        throw UpdateException('Cannot save the download: ${e.message}');
      }
      final total =
          response.contentLength ?? (asset.size > 0 ? asset.size : null);
      var received = 0;
      final hashSink = _DigestSink();
      final hasher = sha256.startChunkedConversion(hashSink);
      try {
        await for (final chunk in response.stream) {
          if (cancelled) throw const UpdateCancelled();
          sink.add(chunk);
          hasher.add(chunk);
          received += chunk.length;
          onProgress?.call(received, total);
        }
        await sink.flush();
      } on FileSystemException catch (e) {
        throw UpdateException('Cannot save the download: ${e.message}');
      } on http.ClientException catch (e) {
        throw UpdateException('Download interrupted: ${e.message}');
      } finally {
        try {
          await sink.close();
        } catch (_) {}
      }
      hasher.close();
      if (cancelled) throw const UpdateCancelled();

      if (hashSink.value.toString() != expected) {
        throw const UpdateException(
          'The downloaded file does not match its published checksum',
        );
      }
      ok = true;
    } finally {
      if (!ok && await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }
    }
  }

  /// Start the (replaced) AppImage once this process has exited.
  ///
  /// Launching it directly would race the exit: with single-instance enabled
  /// the new process would find this one still alive and hand itself over to
  /// it. A detached shell waits for our PID to disappear first.
  Future<void> scheduleRelaunch() async {
    final target = appImagePath;
    if (target == null) return;
    await Process.start('/bin/sh', [
      '-c',
      'while kill -0 "\$1" 2>/dev/null; do sleep 0.2; done; exec "\$2"',
      'noo-relaunch',
      '$pid',
      target,
    ], mode: ProcessStartMode.detached);
  }

  Future<String> _expectedSha256(ReleaseInfo release, String fileName) async {
    final sums = release.assets
        .where((a) => a.name == _checksumsAsset)
        .firstOrNull;
    if (sums == null) {
      throw UpdateException(
        'Release ${release.version} publishes no checksums; download it '
        'manually',
      );
    }
    final http.Response response;
    try {
      response = await _client
          .get(
            Uri.parse(sums.downloadUrl),
            headers: const {'User-Agent': 'noo-update-check'},
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw const UpdateException('Checksum download timed out');
    } on SocketException catch (e) {
      throw UpdateException('Checksum download failed: ${e.message}');
    } on http.ClientException catch (e) {
      throw UpdateException('Checksum download failed: ${e.message}');
    }
    if (response.statusCode != 200) {
      throw UpdateException(
        'Checksum download failed: server answered ${response.statusCode}',
      );
    }
    final hash = parseSha256Sums(response.body)[fileName];
    if (hash == null) {
      throw UpdateException('$fileName is not listed in $_checksumsAsset');
    }
    return hash;
  }

  static Future<void> _deleteQuietly(Directory dir) async {
    try {
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  void close() => _client.close();
}

/// How the running copy can be replaced in place.
enum UpdateMethod {
  appImage(UpdatePlatform.linuxAppImage),
  windowsInstaller(UpdatePlatform.windowsInstaller),
  windowsPortable(UpdatePlatform.windows),
  none(null);

  const UpdateMethod(this.platform);

  /// The release asset the method installs from.
  final UpdatePlatform? platform;
}

/// What [UpdateService.prepare] produced, for [UpdateService.launchAfterExit].
sealed class PreparedUpdate {
  const PreparedUpdate();
}

/// The new AppImage is already in place; it only needs a restart.
class AppImageUpdate extends PreparedUpdate {
  const AppImageUpdate();
}

/// The verified setup program, waiting in [tempDir].
class WindowsInstallerUpdate extends PreparedUpdate {
  const WindowsInstallerUpdate({
    required this.tempDir,
    required this.setupPath,
  });

  final String tempDir;
  final String setupPath;
}

/// The verified ZIP, unpacked: [bundleDir] holds the new `noo.exe` and
/// everything beside it, to be copied over [targetDir].
class WindowsPortableUpdate extends PreparedUpdate {
  const WindowsPortableUpdate({
    required this.tempDir,
    required this.bundleDir,
    required this.targetDir,
  });

  final String tempDir;
  final String bundleDir;
  final String targetDir;
}

/// `sha256sum` output: `<hex>  <name>` per line (`*<name>` in binary mode).
Map<String, String> parseSha256Sums(String text) {
  final result = <String, String>{};
  for (final line in const LineSplitter().convert(text)) {
    final match = RegExp(r'^([0-9a-fA-F]{64})\s+\*?(.+?)\s*$').firstMatch(line);
    if (match != null) result[match.group(2)!] = match.group(1)!.toLowerCase();
  }
  return result;
}

/// Compare two `major.minor.patch` versions; a leading `v` and any `+build`
/// or `-pre` suffix are ignored. Missing or non-numeric parts count as 0.
int compareVersions(String a, String b) {
  List<int> parts(String v) {
    var s = v.trim();
    if (s.startsWith('v') || s.startsWith('V')) s = s.substring(1);
    s = s.split(RegExp(r'[+\-]')).first;
    return s.split('.').map((x) => int.tryParse(x) ?? 0).toList();
  }

  final pa = parts(a), pb = parts(b);
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

/// Which build the running app is, for picking a release asset.
enum UpdatePlatform {
  linuxAppImage('-x86_64.AppImage'),
  android('-android.apk'),
  windows('-windows-x64.zip'),
  windowsInstaller('-windows-x64-setup.exe');

  const UpdatePlatform(this.assetSuffix);

  /// Asset name ending, matching `scripts/publish_release.py` / the build
  /// scripts: `noo-<version><suffix>`.
  final String assetSuffix;

  /// The asset to offer as a plain download when nothing installs in place.
  static UpdatePlatform? get current {
    if (Platform.isAndroid) return UpdatePlatform.android;
    if (Platform.isWindows) return UpdatePlatform.windows;
    if (Platform.isLinux) return UpdatePlatform.linuxAppImage;
    return null;
  }
}

class ReleaseAsset {
  const ReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
  });

  final String name;
  final String downloadUrl;
  final int size;
}

class ReleaseInfo {
  const ReleaseInfo({
    required this.version,
    required this.notes,
    required this.pageUrl,
    required this.assets,
  });

  factory ReleaseInfo.fromGitHubJson(Map<String, dynamic> json) {
    final tag = json['tag_name'] as String? ?? '';
    if (tag.isEmpty) throw const FormatException('release has no tag');
    return ReleaseInfo(
      version: tag.startsWith('v') ? tag.substring(1) : tag,
      notes: (json['body'] as String? ?? '').trim(),
      pageUrl:
          json['html_url'] as String? ??
          'https://github.com/${UpdateService.repository}/releases/latest',
      assets: [
        for (final a in (json['assets'] as List? ?? const []))
          ReleaseAsset(
            name: (a as Map<String, dynamic>)['name'] as String,
            downloadUrl: a['browser_download_url'] as String,
            size: a['size'] as int? ?? 0,
          ),
      ],
    );
  }

  /// Version without the leading `v` of its tag.
  final String version;

  /// Release notes (Markdown, as written on GitHub).
  final String notes;

  /// The release's page on GitHub.
  final String pageUrl;

  final List<ReleaseAsset> assets;

  bool isNewerThan(String installed) => compareVersions(version, installed) > 0;

  ReleaseAsset? assetFor(UpdatePlatform platform) =>
      assets.where((a) => a.name.endsWith(platform.assetSuffix)).firstOrNull;
}

class UpdateException implements Exception {
  const UpdateException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The user cancelled [UpdateService.prepare].
class UpdateCancelled implements Exception {
  const UpdateCancelled();
}

class _DigestSink implements Sink<Digest> {
  late Digest value;
  @override
  void add(Digest data) => value = data;
  @override
  void close() {}
}
