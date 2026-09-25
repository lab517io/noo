import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'safe_filename.dart';

/// Mobile replacements for "save to a path of your choosing": scoped storage
/// has no user-writable arbitrary paths, so content goes to the app's temp
/// dir and out through the system share sheet instead.

/// Stage [bytes] under a temp file named [filename] and open the share sheet.
Future<void> shareBytes({
  required String filename,
  required List<int> bytes,
  String? title,
}) async {
  final path = await _stagePath(filename);
  await File(path).writeAsBytes(bytes, flush: true);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(path)], title: title),
  );
}

/// Share an existing file (e.g. a just-built export archive).
Future<void> shareFile(String path, {String? title}) async {
  await SharePlus.instance.share(
    ShareParams(files: [XFile(path)], title: title),
  );
}

/// A fresh path under the temp dir's `share/` staging area. Files are tiny
/// and the OS clears the temp dir as needed, so no explicit cleanup.
///
/// [filename] is an attachment's name, which is free text from the user or
/// from another device — see [safeFilename] for why it may not choose the
/// directory.
Future<String> _stagePath(String filename) async {
  final tmp = await getTemporaryDirectory();
  final dir = Directory(p.join(tmp.path, 'share'));
  await dir.create(recursive: true);
  return p.join(dir.path, safeFilename(filename));
}
