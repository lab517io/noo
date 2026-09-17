import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/duration_formatter.dart';
import '../../../data/services/audio/voice_memo_recorder.dart';
import '../../providers/voice_memo_provider.dart';
import 'voice_memo_ops.dart';

/// The strip under the toolbar while a memo is being recorded.
///
/// Renders nothing when idle and there is no error to report, so it costs an
/// empty box in the editor's Column the rest of the time.
class VoiceMemoBar extends ConsumerWidget {
  const VoiceMemoBar({super.key, required this.taskId, this.controller});

  final int? taskId;

  /// The editor's controller, so Stop can drop the transcript in. Null in the
  /// bar's own tests, where there is no document.
  final QuillController? controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceMemoProvider);
    if (!state.isBusy && !state.hasNotice) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final failed = !state.isBusy && state.error != null;
    // A recording that ended at the cap is a notice, not a failure: the memo
    // was saved, so it must not be dressed in the error colours.
    final notice = !state.isBusy && state.error == null;
    final background = failed
        ? scheme.errorContainer
        : notice
            ? scheme.surfaceContainerHigh
            : scheme.tertiaryContainer;
    final foreground = failed
        ? scheme.onErrorContainer
        : notice
            ? scheme.onSurface
            : scheme.onTertiaryContainer;

    return Container(
      decoration: BoxDecoration(
        color: background,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: (failed || notice)
            ? _noticeChildren(context, ref, state, foreground, failed)
            : _recordingChildren(context, ref, state, foreground, scheme),
      ),
    );
  }

  /// The strip when nothing is recording: either the last attempt failed, or
  /// the last recording stopped itself at the length cap.
  List<Widget> _noticeChildren(
    BuildContext context,
    WidgetRef ref,
    VoiceMemoState state,
    Color foreground,
    bool failed,
  ) {
    final message = state.error ??
        'Recording stopped at the '
            '${VoiceMemoRecorder.kMaxVoiceMemoDuration.inMinutes} minute '
            'limit. The memo was saved.';
    return [
      Icon(failed ? Icons.mic_off_outlined : Icons.timer_off_outlined,
          size: 18, color: foreground),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          message,
          style: TextStyle(color: foreground),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      IconButton(
        icon: const Icon(Icons.close, size: 18),
        color: foreground,
        tooltip: 'Dismiss',
        onPressed: () => cancelVoiceMemo(ref),
      ),
    ];
  }

  List<Widget> _recordingChildren(
    BuildContext context,
    WidgetRef ref,
    VoiceMemoState state,
    Color foreground,
    ColorScheme scheme,
  ) {
    final saving = state.status == VoiceMemoStatus.saving;
    final transcribing = state.status == VoiceMemoStatus.transcribing;
    final starting = state.status == VoiceMemoStatus.starting;

    return [
      _RecordingDot(active: state.isRecording, color: scheme.error),
      const SizedBox(width: 10),
      Text(
        DurationFormatter.formatMediaPosition(state.elapsed),
        style: TextStyle(
          color: foreground,
          fontFeatures: const [FontFeature.tabularFigures()],
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: starting
            ? Text('Opening the microphone…',
                style: TextStyle(color: foreground))
            : saving
                ? Text('Saving…', style: TextStyle(color: foreground))
                : transcribing
                    // The memo is already stored by this point. Saying so
                    // matters: transcription can take a while on a long one,
                    // and the user should know the recording is not at risk.
                    ? Text(
                        state.transcription?.isGranular != true
                            ? 'Saved. Transcribing…'
                            : 'Saved. Transcribing… '
                                '${(state.transcription!.fraction * 100).round()}%',
                        style: TextStyle(color: foreground))
                    : _LevelMeter(level: state.level, color: foreground),
      ),
      if (state.reachedLimit) ...[
        const SizedBox(width: 8),
        Tooltip(
          message: 'Reached the 30 minute limit',
          child: Icon(Icons.timer_off_outlined, size: 18, color: foreground),
        ),
      ],
      const SizedBox(width: 8),
      // Transcribing is past the point where anything can be thrown away — the
      // memo is stored — so the pair of buttons that end a *recording* would
      // both be lies here. One button, and it drops the text only.
      if (transcribing)
        FilledButton(
          onPressed: () => cancelVoiceMemoTranscription(ref),
          child: const Text('Cancel'),
        )
      else ...[
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 18),
          color: foreground,
          tooltip: 'Discard',
          onPressed: saving ? null : () => cancelVoiceMemo(ref),
        ),
        FilledButton.icon(
          icon: const Icon(Icons.stop, size: 18),
          label: const Text('Stop'),
          onPressed:
              (saving || starting || taskId == null || controller == null)
                  ? null
                  : () => stopVoiceMemo(context, ref, controller!, taskId!),
        ),
      ],
    ];
  }
}

/// The blinking record indicator.
class _RecordingDot extends StatefulWidget {
  const _RecordingDot({required this.active, required this.color});

  final bool active;
  final Color color;

  @override
  State<_RecordingDot> createState() => _RecordingDotState();
}

class _RecordingDotState extends State<_RecordingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_RecordingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller.drive(Tween(begin: 0.35, end: 1.0)),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

/// Input level, drawn as a row of segments rather than a smooth bar so a
/// glance tells you the microphone is live even when the level is low.
class _LevelMeter extends StatelessWidget {
  const _LevelMeter({required this.level, required this.color});

  final double level;
  final Color color;

  static const int _segments = 24;

  @override
  Widget build(BuildContext context) {
    final lit = (level.clamp(0.0, 1.0) * _segments).round();
    return SizedBox(
      height: 12,
      child: Row(
        children: [
          for (var i = 0; i < _segments; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: i < lit ? 0.9 : 0.15),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
