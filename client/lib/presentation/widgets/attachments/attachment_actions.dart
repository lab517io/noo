import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/providers.dart';

/// Attachment actions shared by the attachments panel and the editor status
/// bar, which hosts the "add" button now that the panel has no header row.

/// Prompt for files and attach them to [taskId], then refresh the list and the
/// status bar badge. Returns the names of the files attached — empty when the
/// picker was cancelled.
Future<List<String>> addAttachments(WidgetRef ref, int taskId) async {
  final result = await FilePicker.pickFiles(type: FileType.any);

  if (result.isEmpty) return const [];

  final repo = ref.read(attachmentRepositoryProvider);
  if (repo == null) return const [];

  final added = <String>[];

  for (final file in result) {
    if (file.path == null) continue;

    final fileData = await File(file.path!).readAsBytes();

    await repo.createAttachment(
      taskId: taskId,
      filename: file.name,
      content: fileData,
    );
    added.add(file.name);
  }

  refreshAttachments(ref, taskId);
  return added;
}

/// Invalidate the cached attachment list for [taskId] and bump the refresh
/// tick that the list and count providers watch.
void refreshAttachments(WidgetRef ref, int taskId) {
  ref.invalidate(taskAttachmentsProvider(taskId));
  ref.read(attachmentRefreshProvider.notifier).value++;
}
