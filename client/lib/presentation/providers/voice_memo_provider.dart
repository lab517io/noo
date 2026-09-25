import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../data/services/audio/voice_memo_recorder.dart';
import '../../data/services/audio/whisper_service.dart';
import '../../domain/entities/attachment.dart';
import 'audio_device_provider.dart';
import 'providers.dart';
import 'settings_provider.dart';

/// Where a voice memo recording is in its life.
enum VoiceMemoStatus {
  idle,

  /// Permission is being asked for, or the device is opening.
  starting,

  recording,

  /// Encoding the tail and storing the attachment.
  saving,

  /// Stored, and now being transcribed. The memo is already safe by this
  /// point - this step can fail, or be interrupted, without costing anything.
  transcribing,
}

/// State of the one recording the app allows at a time.
class VoiceMemoState {
  const VoiceMemoState({
    this.status = VoiceMemoStatus.idle,
    this.taskId,
    this.elapsed = Duration.zero,
    this.level = 0,
    this.error,
    this.reachedLimit = false,
    this.transcription,
  });

  final VoiceMemoStatus status;

  /// The task the memo will be attached to. A recording belongs to the task it
  /// was started from, not to whatever is selected when it stops.
  final int? taskId;

  final Duration elapsed;

  /// Input level in 0..1, for the meter.
  final double level;

  /// Last failure, shown in the bar until the next recording starts.
  final String? error;

  /// Set when recording stopped by itself at the length cap.
  final bool reachedLimit;

  /// How far the transcription has got, while [status] is
  /// [VoiceMemoStatus.transcribing]. Null before it starts and after it ends.
  final TranscriptionProgress? transcription;

  bool get isBusy => status != VoiceMemoStatus.idle;
  bool get isRecording => status == VoiceMemoStatus.recording;

  /// Whether the bar has anything to say while nothing is being recorded —
  /// a failure, or an explanation of why the last recording ended itself.
  bool get hasNotice => !isBusy && (error != null || reachedLimit);

  /// Whether a memo may be started for [taskId] right now.
  bool canStartFor(int taskId) => status == VoiceMemoStatus.idle;

  VoiceMemoState copyWith({
    VoiceMemoStatus? status,
    int? taskId,
    Duration? elapsed,
    double? level,
    String? error,
    bool? reachedLimit,
    TranscriptionProgress? transcription,
    bool clearError = false,
    bool clearTask = false,
  }) {
    return VoiceMemoState(
      status: status ?? this.status,
      taskId: clearTask ? null : (taskId ?? this.taskId),
      elapsed: elapsed ?? this.elapsed,
      level: level ?? this.level,
      error: clearError ? null : (error ?? this.error),
      reachedLimit: reachedLimit ?? this.reachedLimit,
      transcription: transcription ?? this.transcription,
    );
  }
}

/// The app's one [WhisperService]. Models, downloads and sessions all go
/// through it, and whisper allows a single live session per process anyway.
final whisperServiceProvider = Provider<WhisperService>((ref) {
  final service = WhisperService();
  // A locked workspace should not be holding a model in native memory.
  ref.onDispose(() => unawaited(service.release()));
  return service;
});

/// Whether the selected model has been downloaded. Watched by the toolbar and
/// by Preferences; invalidated after a download or a delete.
final voiceMemoModelReadyProvider = FutureProvider<bool>((ref) async {
  final model = ref.watch(settingsProvider.select((s) => s.voiceMemoModel));
  if (model.isNone) return false;
  return ref.watch(whisperServiceProvider).isPresent(model);
});

/// Builds the recorder. Overridden in tests to inject a fake engine.
typedef VoiceMemoRecorderFactory = VoiceMemoRecorder Function();

final voiceMemoRecorderFactoryProvider =
    Provider<VoiceMemoRecorderFactory>((ref) => VoiceMemoRecorder.new);

/// Drives voice memo recording.
///
/// The recording lives here rather than in the widget for two reasons: it has
/// to survive the attachments panel collapsing or the toolbar rebuilding, and
/// only one may run at a time — the microphone is a single device.
class VoiceMemoNotifier extends Notifier<VoiceMemoState> {
  VoiceMemoRecorder? _recorder;
  StreamSubscription<VoiceMemoProgress>? _progress;

  @override
  VoiceMemoState build() {
    ref.onDispose(() {
      _progress?.cancel();
      unawaited(_recorder?.dispose());
    });

    // Closing the workspace ends any recording: there is nowhere to save it,
    // and leaving the microphone open on a locked database would be worse
    // than losing the take. It also hands back the whisper model, so a locked
    // workspace is not holding a hundred megabytes in native memory.
    ref.listen<NooDatabase?>(databaseProvider, (previous, next) {
      if (next != null) return;
      if (_recorder != null) unawaited(cancel());
      unawaited(ref.read(whisperServiceProvider).release());
    });

    return const VoiceMemoState();
  }

  /// Start recording a memo for [taskId].
  ///
  /// Returns false when it could not start — no permission, no libopus, no
  /// microphone — with the reason in [VoiceMemoState.error].
  Future<bool> start(int taskId) async {
    if (state.isBusy) return false;

    state = VoiceMemoState(status: VoiceMemoStatus.starting, taskId: taskId);

    final recorder = ref.read(voiceMemoRecorderFactoryProvider)();
    try {
      if (!await recorder.hasPermission()) {
        await recorder.dispose();
        return _fail('Microphone permission was refused');
      }
      // Resolved here, from the name in Preferences, rather than held as a
      // device: an index is only meaningful in the enumeration it came from,
      // and a headset unplugged since the choice was made resolves to null,
      // which is the platform default.
      await recorder.start(microphone: await selectedMicrophone(ref));
    } on Object catch (error) {
      await recorder.dispose();
      return _fail('Could not start recording: $error');
    }

    _recorder = recorder;
    _progress = recorder.progress.listen(
      (tick) {
        if (state.status != VoiceMemoStatus.recording) return;
        state = state.copyWith(elapsed: tick.elapsed, level: tick.level);
        if (recorder.reachedLimit && !state.reachedLimit) {
          state = state.copyWith(reachedLimit: true);
          unawaited(stop());
        }
      },
      onError: (Object error) {
        state = state.copyWith(error: 'Recording failed: $error');
        unawaited(cancel());
      },
    );

    state = state.copyWith(status: VoiceMemoStatus.recording);
    return true;
  }

  /// Stop recording and store the memo as an attachment of the task it was
  /// started for. Returns null when nothing was captured or the store failed.
  ///
  /// The transcript rides along on [StoredVoiceMemo] rather than being written
  /// into the document here: inserting into a Quill document is the editor's
  /// business, and it has to check that the editor still shows the same task.
  Future<StoredVoiceMemo?> stop() async {
    final recorder = _recorder;
    final taskId = state.taskId;
    if (recorder == null || taskId == null) return null;
    if (state.status == VoiceMemoStatus.saving) return null;

    state = state.copyWith(status: VoiceMemoStatus.saving);

    VoiceMemo? memo;
    try {
      memo = await recorder.stop();
    } on Object catch (error) {
      await _release();
      _fail('Could not finish the recording: $error');
      return null;
    }
    await _release();

    // The cap notice outlives the recording: an auto-stop that simply cleared
    // the bar would leave the user wondering why their memo ended.
    final capped = state.reachedLimit;

    if (memo == null) {
      state = VoiceMemoState(reachedLimit: capped);
      return null;
    }

    final repo = ref.read(attachmentRepositoryProvider);
    if (repo == null) {
      _fail('No database is open, so the memo could not be saved');
      return null;
    }

    final Attachment attachment;
    try {
      attachment = await repo.createAttachment(
        taskId: taskId,
        filename: memo.filename,
        content: memo.bytes,
      );
    } on Object catch (error) {
      _fail('Could not save the memo: $error');
      return null;
    }

    // The memo is safe from here on. Transcription runs against the stored
    // bytes rather than alongside the microphone, so it can take as long as it
    // takes, fail, be cancelled, or be skipped entirely without any of that
    // reaching the recording. It can also be asked for again later from the
    // attachment row.
    final transcript = await _transcribe(memo.bytes, capped: capped);

    state = VoiceMemoState(reachedLimit: capped);
    return StoredVoiceMemo(
      attachment: attachment,
      taskId: taskId,
      transcript: transcript,
      duration: memo.duration,
    );
  }

  /// Transcribe a memo that is already stored, or return null.
  ///
  /// Null covers every "no text" case — transcription off, no model downloaded,
  /// a memo that was silence, a model that failed to load — and all of them are
  /// ordinary outcomes rather than errors to report.
  Future<String?> _transcribe(Uint8List bytes, {required bool capped}) async {
    final settings = ref.read(settingsProvider);
    if (!settings.voiceMemoTranscribe || settings.voiceMemoModel.isNone) {
      return null;
    }

    state = state.copyWith(
        status: VoiceMemoStatus.transcribing, reachedLimit: capped);

    try {
      return await ref.read(whisperServiceProvider).transcribeMemo(
            bytes,
            model: settings.voiceMemoModel,
            language: settings.voiceMemoLanguage,
            onProgress: (progress) {
              // Guarded: a workspace closed mid-transcription cancels the
              // recording, and a tick arriving after that must not put the
              // bar back into a state the memo has already left.
              if (state.status != VoiceMemoStatus.transcribing) return;
              state = state.copyWith(transcription: progress);
            },
            // Leaving the transcribing state *is* the cancellation — see
            // [cancelTranscription], and the workspace-closed listener in
            // [build], which both do it by moving the status on.
            isCancelled: () => state.status != VoiceMemoStatus.transcribing,
          );
    } on Object {
      return null;
    }
  }

  /// Stop transcribing, and keep the memo.
  ///
  /// Nothing is undone by this: the attachment was stored before transcription
  /// began, and it stays exactly where it is. What is dropped is the text —
  /// which can be asked for again from the attachment menu at any time, with a
  /// different model or a different language.
  ///
  /// The run itself notices at its next block boundary, because it polls this
  /// status; there is nothing to await here.
  void cancelTranscription() {
    if (state.status != VoiceMemoStatus.transcribing) return;
    state = VoiceMemoState(reachedLimit: state.reachedLimit);
  }

  /// Throw the recording away.
  Future<void> cancel() async {
    final recorder = _recorder;
    if (recorder == null) {
      state = const VoiceMemoState();
      return;
    }
    await recorder.cancel();
    await _release();
    state = VoiceMemoState(error: state.error);
  }

  Future<void> _release() async {
    await _progress?.cancel();
    _progress = null;
    final recorder = _recorder;
    _recorder = null;
    await recorder?.dispose();
  }

  bool _fail(String message) {
    state = VoiceMemoState(error: message);
    return false;
  }
}

/// What [VoiceMemoNotifier.stop] produced: the stored attachment plus the
/// transcript, if there is one, and the task both belong to.
class StoredVoiceMemo {
  const StoredVoiceMemo({
    required this.attachment,
    required this.taskId,
    required this.duration,
    this.transcript,
  });

  final Attachment attachment;

  /// The task the recording was started from — not necessarily the one open
  /// now, which is why the editor has to check before inserting.
  final int taskId;

  final Duration duration;
  final String? transcript;

  bool get hasTranscript => transcript != null && transcript!.trim().isNotEmpty;
}

final voiceMemoProvider =
    NotifierProvider<VoiceMemoNotifier, VoiceMemoState>(VoiceMemoNotifier.new);
