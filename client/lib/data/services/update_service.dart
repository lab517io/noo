import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
/// What happens with a newer release depends on how the app was installed:
/// - Linux AppImage (`$APPIMAGE` set): the new AppImage is downloaded next to
///   the running one, verified against the release's `SHA256SUMS`, and renamed
///   over it. The running process keeps its (now unlinked) image; the new one
///   takes effect on restart.
/// - Android: the APK is opened in the browser. Installing it in-app would need
///   REQUEST_INSTALL_PACKAGES, which Play does not allow for this kind of app.
/// - Windows, or a Linux build not running from an AppImage: no installable
///   asset, so the release page is opened.
class UpdateService {
  UpdateService({http.Client? client, Map<String, String>? environment})
    : _client = client ?? http.Client(),
      _environment = environment ?? Platform.environment;

  static const repository = 'lab517io/noo';
  static final latestReleaseUri = Uri.https(
    'api.github.com',
    '/repos/$repository/releases/latest',
  );

  static const _checksumsAsset = 'SHA256SUMS';

  final http.Client _client;
  final Map<String, String> _environment;

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
    var cancelled = false;
    unawaited(cancel?.then((_) => cancelled = true));

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

      final sink = partial.openWrite();
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

  void close() => _client.close();
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
  windows('-windows-x64.zip');

  const UpdatePlatform(this.assetSuffix);

  /// Asset name ending, matching `scripts/publish_release.py` / the build
  /// scripts: `noo-<version><suffix>`.
  final String assetSuffix;

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

/// The user cancelled [UpdateService.installAppImage].
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
