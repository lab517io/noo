/// The whisper model download the user asked for, as state that outlives the
/// Preferences tab showing it.
///
/// The "Voice memos" tab is one page of a `TabBarView`, which disposes a page
/// the moment the user switches away from it. A download whose progress lived
/// in that page's `State` kept running in the service — but the page that came
/// back had no idea, showed "Not downloaded", and offered Download again,
/// which opened the same `.part` file for a second writer. Holding the state
/// here means the returning page draws the bar it left, with its Cancel.
///
/// The service already refuses to run two downloads of one model
/// (`WhisperService.downloadModel` joins the one in flight); this is the
/// UI-side half, so the user is never offered the second one at all.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/audio/whisper_service.dart';
import 'voice_memo_provider.dart';

/// What the model row shows about a download.
class ModelDownloadState {
  const ModelDownloadState({this.model, this.progress, this.error});

  /// The model being fetched, or null when nothing is.
  final VoiceMemoModel? model;

  final ModelDownloadProgress? progress;

  /// How the last download ended, when it did not end with a file: cancelled
  /// or failed. Shown in the row until the next download starts or the model
  /// is changed.
  final String? error;

  bool get isDownloading => model != null;

  /// Whether [candidate] is the model on its way down right now.
  bool isDownloadingModel(VoiceMemoModel candidate) => model == candidate;
}

/// Runs a download and keeps its progress where the tab can find it again.
class ModelDownloadNotifier extends Notifier<ModelDownloadState> {
  @override
  ModelDownloadState build() => const ModelDownloadState();

  /// Fetch [model], unless a download is already running.
  ///
  /// Returns when it has finished, one way or the other. The outcome is in the
  /// state rather than thrown: the caller is a button press, and the row is
  /// what reports.
  Future<void> download(VoiceMemoModel model) async {
    if (state.isDownloading || model.isNone) return;

    state = ModelDownloadState(
      model: model,
      progress: ModelDownloadProgress(0, model.downloadBytes),
    );

    final service = ref.read(whisperServiceProvider);
    String? error;
    try {
      await service.downloadModel(
        model,
        onProgress: (progress) {
          if (state.model != model) return;
          state = ModelDownloadState(model: model, progress: progress);
        },
      );
    } on DownloadCancelled {
      error = 'Download cancelled.';
    } on Object catch (failure) {
      error = 'Download failed: $failure';
    }

    state = ModelDownloadState(error: error);
    // The row under the dropdown reads presence from this; a finished
    // download is the one thing that changes its answer.
    ref.invalidate(voiceMemoModelReadyProvider);
  }

  /// Stop the download in flight. The state follows from the service's own
  /// [DownloadCancelled], so a cancel that arrives too late is harmless.
  void cancel() => ref.read(whisperServiceProvider).cancelDownload();

  /// Forget the last outcome — the user has moved on to another model, or
  /// removed this one.
  void clearError() {
    // An outcome is only ever recorded once the download has ended, so there
    // is no in-flight state to preserve here.
    if (state.error != null) state = const ModelDownloadState();
  }
}

final modelDownloadProvider =
    NotifierProvider<ModelDownloadNotifier, ModelDownloadState>(
        ModelDownloadNotifier.new);
