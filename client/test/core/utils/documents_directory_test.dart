import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/documents_directory.dart';
import 'package:path/path.dart' as p;

/// Where the default database goes when path_provider cannot say — Linux
/// without xdg-user-dir, which left the welcome screen on "Resolving…".
void main() {
  Future<Directory> missing() async => throw Exception('no xdg-user-dir');

  test("path_provider's answer wins when it has one", () async {
    final dir = await documentsDirectory(
        platform: () async => Directory('/docs'), isLinux: true);
    expect(dir.path, '/docs');
  });

  test('XDG_DOCUMENTS_DIR, with \$HOME expanded', () async {
    final dir = await documentsDirectory(
      platform: missing,
      isLinux: true,
      environment: {'HOME': '/home/u', 'XDG_DOCUMENTS_DIR': r'$HOME/Dokumente'},
    );
    expect(dir.path, '/home/u/Dokumente');
  });

  test('~/Documents when it exists, else the home directory', () async {
    final home = await Directory.systemTemp.createTemp('noo-home');
    addTearDown(() => home.delete(recursive: true));

    var dir = await documentsDirectory(
        platform: missing, isLinux: true, environment: {'HOME': home.path});
    expect(dir.path, home.path);

    await Directory(p.join(home.path, 'Documents')).create();
    dir = await documentsDirectory(
        platform: missing, isLinux: true, environment: {'HOME': home.path});
    expect(dir.path, p.join(home.path, 'Documents'));
  });

  test('other platforms still report the failure', () async {
    expect(
      documentsDirectory(platform: missing, isLinux: false, environment: {'HOME': '/h'}),
      throwsException,
    );
  });
}
