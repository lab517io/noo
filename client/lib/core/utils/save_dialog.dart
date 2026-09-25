import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Adapters over file_picker 12's save dialog.
///
/// file_picker 12 folded the write into the dialog: [FilePicker.saveFile] takes
/// the bytes, writes them itself and returns a [Uri] rather than handing back a
/// path. That fits "export these bytes" call sites directly, but not the ones
/// that only need a destination for a file this app creates itself (a new
/// database, which SQLCipher writes). These helpers cover the difference.

/// The filesystem path behind a save-dialog result, or null when the platform
/// returned something that is not a local file. Android's SAF yields
/// `content:` URIs, which have no path an [File] can open.
String? savedFilePath(Uri uri) => uri.isScheme('file') ? uri.toFilePath() : null;

/// Ask where to put a file that the caller writes itself.
///
/// There is no path-only save dialog in file_picker 12, so this writes an empty
/// placeholder at the chosen location and returns its path; the caller's own
/// creation step is expected to replace it.
///
/// The placeholder is written the moment the dialog closes, and it truncates
/// whatever the user chose to overwrite. So everything the caller might still
/// cancel on — a password, a confirmation — must be asked *before* this, or a
/// cancelled flow leaves the user's existing file at zero bytes.
///
/// When [requiredExtension] is given and the name the user typed lacks it, the
/// extension is appended. The placeholder was created under the typed name, so
/// it is removed rather than left orphaned next to the real file.
///
/// Returns null if the user cancelled, or if the platform returned a non-file
/// destination (see [savedFilePath]).
Future<String?> pickSavePath({
  required String fileName,
  String? dialogTitle,
  String? initialDirectory,
  FileType type = FileType.any,
  List<String>? allowedExtensions,
  String? requiredExtension,
}) async {
  final uri = await FilePicker.saveFile(
    fileName: fileName,
    bytes: Uint8List(0),
    dialogTitle: dialogTitle,
    initialDirectory: initialDirectory,
    type: type,
    allowedExtensions: allowedExtensions,
  );
  if (uri == null) return null;

  final path = savedFilePath(uri);
  if (path == null) return null;

  if (requiredExtension == null ||
      path.toLowerCase().endsWith(requiredExtension.toLowerCase())) {
    return path;
  }

  final placeholder = File(path);
  if (await placeholder.exists()) {
    await placeholder.delete();
  }
  return '$path$requiredExtension';
}
