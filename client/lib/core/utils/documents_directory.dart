import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The user's documents directory, where the default database lives.
///
/// On Linux path_provider asks the `xdg-user-dir` tool and throws
/// `MissingPlatformDirectoryException` when it is not installed — a minimal
/// system, a container, AppImageHub's test runner — which left the welcome
/// screen's default location on "Resolving…" for good. There the answer is
/// worked out the way xdg-user-dirs itself would: `$XDG_DOCUMENTS_DIR`, then
/// `~/Documents` when it exists, then the home directory.
Future<Directory> documentsDirectory({
  Future<Directory> Function() platform = getApplicationDocumentsDirectory,
  Map<String, String>? environment,
  bool? isLinux,
}) async {
  try {
    return await platform();
  } catch (_) {
    if (!(isLinux ?? Platform.isLinux)) rethrow;
    final env = environment ?? Platform.environment;
    final home = env['HOME'];
    final xdg = env['XDG_DOCUMENTS_DIR'];
    if (xdg != null && xdg.isNotEmpty) {
      return Directory(home == null ? xdg : xdg.replaceFirst(r'$HOME', home));
    }
    if (home == null || home.isEmpty) rethrow;
    final documents = Directory(p.join(home, 'Documents'));
    return documents.existsSync() ? documents : Directory(home);
  }
}
