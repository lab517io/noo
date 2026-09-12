/// The "Test" button in Preferences → Voice memos: record, play back,
/// transcribe, and say which of the three did not work.
///
/// The chain matters more than any one step. A memo that comes out silent, a
/// speaker that is muted and a model that was never downloaded all look
/// identical from the editor — a memo with no text under it — and the only way
/// to tell them apart has been to record a real note and guess. Running the
/// three stages in order, with the level meter visible and each failure named,
/// answers that in about fifteen seconds.
///
/// Nothing here writes anything: the clip is held in memory, played, and
/// dropped. It never becomes an attachment and never reaches the database.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/audio/memo_player.dart';
import '../../data/services/audio/voice_memo_recorder.dart';
import '../../data/services/audio/whisper_service.dart';
import 'audio_device_provider.dart';
import 'settings_provider.dart';
import 'voice_memo_provider.dart';

/// Where a self-test run has got to.
enum AudioCheckStage {
  idle,

  /// The microphone is open. The user ends this by pressing Stop, or it ends
  /// itself at [AudioCheckNotifier.kMaxDuration].
  recording,

  /// Playing the clip back through the chosen speaker.
  playing,

  transcribing,

  /// Finished. [AudioCheckState.transcript] holds the text, if there is any.
  done,

  /// Stopped at some stage with [AudioCheckState.error] explaining which.
  failed,
}

/// What the Test panel draws.
class AudioCheckState {
  const AudioCheckState({
    this.stage = AudioCheckStage.idle,
    this.elapsed = Duration.zero,
    this.level = 0,
    this.peakLevel = 0,
    this.recorded = Duration.zero,
    this.transcript,
    this.error,
    this.note,
    this.transcription,
  });

  final AudioCheckStage stage;

  /// Recording time so far, for the counter.
  final Duration elapsed;

  /// Input level in 0..1, for the meter.
  final double level;

  /// Loudest level seen during the recording.
  ///
  /// Kept because it is the one number that separates "the microphone is not
  /// the one you think it is" from every other failure: a device that opened
  /// but captured nothing reports a peak of zero, and on the platforms that
  /// answer a refused permission with silence rather than an error, that is
  /// the only signal there is.
  final double peakLevel;

  /// Length of the clip that was captured.
  final Duration recorded;

  /// What whisper made of it. Null when transcription did not run.
  final String? transcript;

  /// How far the transcription has got, while [stage] is
  /// [AudioCheckStage.transcribing].
  final TranscriptionProgress? transcription;

  /// Why the run stopped, when [stage] is [AudioCheckStage.failed].
  final String? error;

  /// A remark about a run that otherwise succeeded — silence on the
  /// microphone, or a transcription step that was deliberately skipped.
  final String? note;

  bool get isRunning =>
      stage != AudioCheckStage.idle &&
      stage != AudioCheckStage.done &&
      stage != AudioCheckStage.failed;

  bool get isRecording => stage == AudioCheckStage.recording;

  /// Whether there is a result on screen to be replaced by the next run.
  bool get hasResult =>
      stage == AudioCheckStage.done || stage == AudioCheckStage.failed;

  AudioCheckState copyWith({
    AudioCheckStage? stage,
    Duration? elapsed,
    double? level,
    double? peakLevel,
    Duration? recorded,
    String? transcript,
    String? error,
    String? note,
    TranscriptionProgress? transcription,
  }) {
    return AudioCheckState(
      stage: stage ?? this.stage,
      elapsed: elapsed ?? this.elapsed,
      level: level ?? this.level,
      peakLevel: peakLevel ?? this.peakLevel,
      recorded: recorded ?? this.recorded,
      transcript: transcript ?? this.transcript,
      error: error ?? this.error,
      note: note ?? this.note,
      transcription: transcription ?? this.transcription,
    );
  }
}

/// How the self-test plays its clip back. Overridden in tests.
final memoPlayerProvider =
    Provider<MemoPlayer>((ref) => VoiceAudioMemoPlayer());

/// Runs the record → play → transcribe check.
class AudioCheckNotifier extends Notifier<AudioCheckState> {
  /// Long enough for a sentence worth transcribing, short enough that a user
  /// who walks away from a running test does not leave the microphone open.
  static const Duration kMaxDuration = Duration(seconds: 15);

  /// Below this peak the recording is treated as silence. The same order of
  /// magnitude as whisper's own energy gate (`WhisperService.kGateRmsMin`),
  /// because a clip too quiet for the gate has nothing to transcribe either.
  static const double kSilenceThreshold = 0.01;

  VoiceMemoRecorder? _recorder;
  StreamSubscription<VoiceMemoProgress>? _progress;

  /// Which run the state belongs to.
  ///
  /// Playback and transcription are awaited, and a user who presses Cancel
  /// during either does not stop them — nothing here can interrupt a native
  /// decode. So the run is stamped, [cancel] moves the stamp on, and a
  /// continuation that comes back to a stamp that is no longer current writes
  /// nothing. Without it, cancelling mid-playback puts the panel back to idle
  /// and then a transcript appears in it a second later.
  int _run = 0;

  @override
  AudioCheckState build() {
    // Held rather than read from the callback: `ref` is off limits inside a
    // life-cycle, and this one has to silence a speaker that is still playing
    // when the workspace closes.
    final player = ref.read(memoPlayerProvider);
    ref.onDispose(() {
      _progress?.cancel();
      unawaited(_recorder?.dispose());
      unawaited(player.stop());
    });
    return const AudioCheckState();
  }

  /// Begin the check by recording.
  ///
  /// Refuses while a real memo is being recorded: there is one microphone, and
  /// a test that stole it would cost the user the note they were dictating.
  Future<void> start() async {
    if (state.isRunning) return;

    if (ref.read(voiceMemoProvider).isBusy) {
      state = const AudioCheckState(
        stage: AudioCheckStage.failed,
        error: 'A voice memo is being recorded. Finish it first.',
      );
      return;
    }

    final run = ++_run;
    state = const AudioCheckState(stage: AudioCheckStage.recording);

    final recorder = ref.read(voiceMemoRecorderFactoryProvider)();
    try {
      if (!await recorder.hasPermission()) {
        await recorder.dispose();
        _fail(run, 'The microphone permission was refused.');
        return;
      }
      await recorder.start(microphone: await selectedMicrophone(ref));
    } on Object catch (error) {
      await recorder.dispose();
      _fail(run, 'The microphone would not open: $error');
      return;
    }

    _recorder = recorder;
    _progress = recorder.progress.listen(
      (tick) {
        if (state.stage != AudioCheckStage.recording) return;
        state = state.copyWith(
          elapsed: tick.elapsed,
          level: tick.level,
          peakLevel:
              tick.level > state.peakLevel ? tick.level : state.peakLevel,
        );
        // The cap is enforced here rather than through the recorder's own
        // maxDuration so that the shared recorder factory keeps the thirty
        // minutes a real memo is allowed.
        if (tick.elapsed >= kMaxDuration) unawaited(finish());
      },
      onError: (Object error) {
        _fail(run, 'Recording failed: $error');
        unawaited(_release(discard: true));
      },
    );
  }

  /// Stop recording and run the rest of the chain: play back, then transcribe.
  Future<void> finish() async {
    final recorder = _recorder;
    if (recorder == null || state.stage != AudioCheckStage.recording) return;

    final run = _run;

    // Moved off `recording` first, so the cap check in the progress listener
    // cannot start a second finish while this one is awaiting the encoder.
    state = state.copyWith(stage: AudioCheckStage.playing);

    VoiceMemo? memo;
    try {
      memo = await recorder.stop();
    } on Object catch (error) {
      await _release();
      _fail(run, 'The recording could not be finished: $error');
      return;
    }
    await _release();

    if (memo == null) {
      _fail(run, 'Nothing was recorded. Hold the test a moment longer, or pick '
          'another microphone.');
      return;
    }

    final silent = state.peakLevel < kSilenceThreshold;
    state = state.copyWith(recorded: memo.duration, level: 0);

    try {
      final played = await ref
          .read(memoPlayerProvider)
          .play(memo.bytes, speaker: await selectedSpeaker(ref));
      if (!played) {
        _fail(run, 'The recording came back malformed and would not play.');
        return;
      }
    } on Object catch (error) {
      _fail(run, 'Playback failed: $error');
      return;
    }
    if (run != _run) return;

    await _transcribe(run, memo, silent: silent);
  }

  /// The last stage. A run that gets here has already proved capture and
  /// playback, so everything below reports rather than fails the whole check.
  Future<void> _transcribe(int run, VoiceMemo memo,
      {required bool silent}) async {
    final settings = ref.read(settingsProvider);
    final model = settings.voiceMemoModel;
    final whisper = ref.read(whisperServiceProvider);

    if (model.isNone) {
      _done(run,
          note: 'Recording and playback worked. No model is selected, so '
              'there is nothing to transcribe.');
      return;
    }
    if (!await whisper.isPresent(model)) {
      _done(run,
          note: 'Recording and playback worked. ${model.label} has not been '
              'downloaded yet, so nothing was transcribed.');
      return;
    }
    if (run != _run) return;

    state = state.copyWith(stage: AudioCheckStage.transcribing);

    String? text;
    try {
      text = await whisper.transcribeMemo(
        memo.bytes,
        model: model,
        language: settings.voiceMemoLanguage,
        onProgress: (progress) {
          if (run != _run) return;
          state = state.copyWith(transcription: progress);
        },
        // Cancel already moves the run number on, so the same stamp that keeps
        // a stale result out of the panel also stops the work producing it.
        isCancelled: () => run != _run,
      );
    } on TranscriptionCancelled {
      return;
    } on Object catch (error) {
      _fail(run, 'Transcription failed: $error');
      return;
    }

    if (text == null || text.isEmpty) {
      _done(
        run,
        note: silent
            ? 'The microphone produced silence — the level meter never moved. '
                'Check that the right device is selected and that the app may '
                'use it.'
            : 'Recording and playback worked, but whisper found no speech. Try '
                'speaking closer to the microphone, or another language.',
      );
      return;
    }
    if (run != _run) return;

    state = state.copyWith(
      stage: AudioCheckStage.done,
      transcript: text,
      note: silent
          ? 'The level meter never moved, so the input is very quiet.'
          : null,
    );
  }

  /// Abandon the run, discarding the clip and silencing the speaker.
  Future<void> cancel() async {
    // Moved on even for an idle notifier: it costs nothing, and it means a
    // stale continuation can never be revived by a later run reusing the
    // number it was waiting on.
    _run++;
    if (!state.isRunning) {
      state = const AudioCheckState();
      return;
    }
    final recorder = _recorder;
    if (recorder != null) {
      try {
        await recorder.cancel();
      } on Object {
        // Cancelling is best-effort: the clip is going in the bin either way.
      }
    }
    await _release();
    await ref.read(memoPlayerProvider).stop();
    state = const AudioCheckState();
  }

  Future<void> _release({bool discard = false}) async {
    await _progress?.cancel();
    _progress = null;
    final recorder = _recorder;
    _recorder = null;
    if (discard) {
      try {
        await recorder?.cancel();
      } on Object {
        // See [cancel].
      }
    }
    await recorder?.dispose();
  }

  void _fail(int run, String message) {
    if (run != _run) return;
    state = state.copyWith(stage: AudioCheckStage.failed, error: message);
  }

  void _done(int run, {String? note}) {
    if (run != _run) return;
    state = state.copyWith(stage: AudioCheckStage.done, note: note);
  }
}

final audioCheckProvider =
    NotifierProvider<AudioCheckNotifier, AudioCheckState>(
        AudioCheckNotifier.new);
