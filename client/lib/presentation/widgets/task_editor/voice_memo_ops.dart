import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/audio/whisper_service.dart';
import '../../../domain/entities/attachment.dart';
import '../../providers/providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/voice_memo_provider.dart';
import '../attachments/attachment_actions.dart';

/// Start / stop / cancel for voice memos, and putting the transcript in the
/// document — the counterpart of `attachment_image_ops.dart`.
///
/// A memo is an ordinary attachment: the bytes land in the `file` table and
/// sync through the path that already exists. The transcript is ordinary text
/// inserted at the caret, so it is searchable and exportable with everything
/// else, and needs no schema or protocol change.

/// Stop transcribing the memo that was just recorded, keeping the memo.
void cancelVoiceMemoTranscription(WidgetRef ref) =>
    ref.read(voiceMemoProvider.notifier).cancelTranscription();

/// Toggle recording for [taskId]: start when idle, stop and store when
/// already recording.
Future<void> toggleVoiceMemo(
  BuildContext context,
  WidgetRef ref,
  QuillController controller,
  int taskId,
) async {
  final state = ref.read(voiceMemoProvider);

  if (state.isRecording) {
    await stopVoiceMemo(context, ref, controller, taskId);
    return;
  }
  if (state.isBusy) return;

  await ref.read(voiceMemoProvider.notifier).start(taskId);

  // Failures land in the state, which the bar renders; a refusal before the
  // bar is on screen is the one case that needs telling.
  if (!context.mounted) return;
  final error = ref.read(voiceMemoProvider).error;
  if (error != null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(error)));
  }
}

/// Stop the recording, store it, and insert its transcript if there is one.
Future<void> stopVoiceMemo(
  BuildContext context,
  WidgetRef ref,
  QuillController controller,
  int taskId,
) async {
  final memo = await ref.read(voiceMemoProvider.notifier).stop();

  if (memo == null) {
    if (!context.mounted) return;
    final error = ref.read(voiceMemoProvider).error;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
    return;
  }

  // The attachment row exists before any text does, so a failed store never
  // leaves an orphan line in the document.
  refreshAttachments(ref, memo.taskId);

  if (memo.hasTranscript) {
    insertTranscript(
      controller,
      transcript: memo.transcript!,
      openTaskId: taskId,
      memoTaskId: memo.taskId,
    );
  }
}

/// Discard the recording in progress.
Future<void> cancelVoiceMemo(WidgetRef ref) =>
    ref.read(voiceMemoProvider.notifier).cancel();

/// Insert [transcript] at the caret.
///
/// Skipped when the editor has moved on to another task while the memo was
/// being transcribed: writing into the wrong note is worse than losing the
/// insert, and the memo is still attached to its own task with "Transcribe"
/// available from the row menu.
///
/// Returns whether anything was written.
bool insertTranscript(
  QuillController controller, {
  required String transcript,
  required int? openTaskId,
  required int memoTaskId,
}) {
  if (openTaskId != memoTaskId) return false;

  final text = transcript.trim();
  if (text.isEmpty) return false;

  // `start`/`end`, not base/extent: a selection made right-to-left would
  // otherwise give a negative length, which quill reads as "delete nothing".
  final selection = controller.selection;
  final index = selection.start;
  final length = selection.end - index;
  if (index < 0) return false;

  // A plain paragraph, deliberately unprefixed: the least surprising thing to
  // find in a note, and it reads as the user's own words rather than as a
  // machine annotation. The newline keeps it off the end of whatever line the
  // caret happened to be on.
  final insert = '$text\n';
  controller.replaceText(
    index,
    length,
    insert,
    TextSelection.collapsed(offset: index + insert.length),
    // Not a keystroke: this arrives from the attachments panel, possibly with
    // the soft keyboard down. Without the flag flutter_quill treats the change
    // like typing — on a phone it pops the keyboard and, worse, skips the
    // update of the IME's copy of the text, so the next real keystrokes are
    // diffed against stale text and land in the wrong place or nowhere.
    ignoreFocus: true,
  );
  return true;
}

/// Re-transcribe a memo that is already stored, and insert the result.
///
/// Needs no microphone and no temp file: the stored packets are decoded and
/// replayed through the same session the recorder uses. This is how a memo
/// recorded on another device — or one recorded before a model was
/// downloaded — gets its text.
Future<void> transcribeStoredMemo(
  BuildContext context,
  WidgetRef ref,
  QuillController? controller, {
  required Attachment memo,
  required int? openTaskId,
}) async {
  final settings = ref.read(settingsProvider);
  final messenger = ScaffoldMessenger.of(context);

  if (settings.voiceMemoModel.isNone) {
    messenger.showSnackBar(const SnackBar(
      content: Text('Choose a transcription model in Preferences first'),
    ));
    return;
  }

  final service = ref.read(whisperServiceProvider);
  if (!await service.isPresent(settings.voiceMemoModel)) {
    messenger.showSnackBar(SnackBar(
      content: Text('The ${settings.voiceMemoModel.label} model has not been '
          'downloaded yet — see Preferences'),
    ));
    return;
  }

  final repo = ref.read(attachmentRepositoryProvider);
  if (repo == null) return;
  final bytes = (await repo.loadAttachmentContent(memo)).content;
  if (bytes == null || bytes.isEmpty) return;

  // A snack bar cannot be edited once shown, and re-showing one per block
  // would make it flicker and restart its own timer. So the bar is shown once
  // with a notifier inside it, and the blocks push into that. It is dismissed
  // by hand below rather than on a duration, because a long memo outlives any
  // duration worth choosing.
  final progress = ValueNotifier<TranscriptionProgress?>(null);
  var cancelled = false;
  messenger.showSnackBar(SnackBar(
    duration: const Duration(days: 1),
    action: SnackBarAction(
      label: 'Cancel',
      onPressed: () => cancelled = true,
    ),
    content: ValueListenableBuilder<TranscriptionProgress?>(
      valueListenable: progress,
      builder: (context, value, _) => Text(
        value?.isGranular != true
            ? 'Transcribing…'
            : 'Transcribing… ${(value!.fraction * 100).round()}%',
      ),
    ),
  ));

  String? transcript;
  try {
    transcript = await service.transcribeMemo(
      bytes,
      model: settings.voiceMemoModel,
      language: settings.voiceMemoLanguage,
      onProgress: (value) => progress.value = value,
      isCancelled: () => cancelled,
    );
  } on TranscriptionCancelled {
    // The action dismissed the bar on its way out, so there is nothing to
    // hide and nothing to say: the user is the one who stopped it.
    return;
  } on Object catch (error) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
        SnackBar(content: Text('Could not transcribe: $error')));
    return;
  } finally {
    progress.dispose();
  }
  messenger.hideCurrentSnackBar();

  if (transcript == null) {
    messenger.showSnackBar(
        const SnackBar(content: Text('No speech found in this memo')));
    return;
  }

  final inserted = controller != null &&
      insertTranscript(
        controller,
        transcript: transcript,
        openTaskId: openTaskId,
        memoTaskId: memo.taskId,
      );
  if (!inserted) {
    messenger.showSnackBar(const SnackBar(
      content: Text('Transcribed, but the note it belongs to is not open'),
    ));
  }
}
