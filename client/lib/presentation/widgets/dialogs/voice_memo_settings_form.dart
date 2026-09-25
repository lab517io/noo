import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_audio/voice_audio.dart' as va;

import '../../../core/utils/duration_formatter.dart';
import '../../../data/services/audio/whisper_service.dart';
import '../../providers/audio_check_provider.dart';
import '../../providers/audio_device_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/voice_memo_provider.dart';
import 'classic_form.dart';

/// Voice-memo configuration, the "Voice memos" tab of the preferences dialog.
///
/// The one thing this screen must get right is that **nothing downloads by
/// itself**. Selecting a model only records a preference; the model file
/// arrives when the user presses Download and not before. An app that is
/// otherwise offline and zero-knowledge should never quietly fetch 148 MB.
///
/// Three group boxes: the devices to record from and play through, the
/// transcription model and language, and a self-test that runs the whole
/// chain — see `AudioCheckNotifier` for why the chain rather than the parts.
class VoiceMemoSettingsForm extends ConsumerStatefulWidget {
  const VoiceMemoSettingsForm({super.key});

  @override
  ConsumerState<VoiceMemoSettingsForm> createState() =>
      _VoiceMemoSettingsFormState();
}

class _VoiceMemoSettingsFormState
    extends ConsumerState<VoiceMemoSettingsForm> {
  ModelDownloadProgress? _progress;
  VoiceMemoModel? _downloading;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final model = settings.voiceMemoModel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClassicGroupBox(
          title: 'Devices',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDeviceField(
                label: 'Microphone',
                devices: ref.watch(microphoneDevicesProvider),
                selected: settings.voiceMemoInputDevice,
                onChanged: notifier.setVoiceMemoInputDevice,
                hint: 'Used for voice memos and for the check below.',
              ),
              const SizedBox(height: 10),
              _buildDeviceField(
                label: 'Speaker',
                devices: ref.watch(speakerDevicesProvider),
                selected: settings.voiceMemoOutputDevice,
                onChanged: notifier.setVoiceMemoOutputDevice,
                // Said out loud because the difference is otherwise
                // inexplicable: memos play through this app's own decoder,
                // every other audio attachment through the platform's, and
                // only the first of the two takes a device.
                hint: 'Applies to voice memos. Other audio attachments play '
                    'through the system default.',
              ),
              const SizedBox(height: 10),
              ClassicFieldIndent(
                child: Row(
                  children: [
                    OutlinedButton(
                      style: classicButtonStyle(context),
                      onPressed: () => refreshAudioDevices(
                          ProviderScope.containerOf(context)),
                      child: const Text('Refresh'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ClassicGroupBox(
          title: 'Transcription',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClassicField(
                label: 'Model',
                hint: model.isNone
                    ? 'Memos are recorded and stored as audio only.'
                    : 'Runs on this device. Nothing is sent anywhere.',
                child: ClassicDropdown<VoiceMemoModel>(
                  value: model,
                  onChanged: _downloading != null
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _error = null);
                          notifier.setVoiceMemoModel(value);
                        },
                  items: [
                    for (final option in VoiceMemoModel.values)
                      DropdownMenuItem(
                        value: option,
                        child: Text(option.isNone
                            ? option.label
                            : '${option.label} · '
                                '${_megabytes(option.downloadBytes)}'
                                '${option.recommended ? ' · recommended' : ''}'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildModelStatus(context, model),
              const SizedBox(height: 12),
              ClassicCheckbox(
                label: 'Transcribe after recording',
                hint: 'A memo is stored first and transcribed from the stored '
                    'audio. Off stores it untranscribed; "Transcribe" in the '
                    'attachment menu still works later.',
                value: settings.voiceMemoTranscribe,
                onChanged: model.isNone
                    ? null
                    : (value) => notifier.setVoiceMemoTranscribe(value),
              ),
              const SizedBox(height: 10),
              ClassicField(
                label: 'Language',
                child: ClassicDropdown<String>(
                  value: kWhisperLanguages.containsKey(
                          settings.voiceMemoLanguage)
                      ? settings.voiceMemoLanguage
                      : 'en',
                  onChanged: model.isNone
                      ? null
                      : (value) {
                          if (value != null) {
                            notifier.setVoiceMemoLanguage(value);
                          }
                        },
                  items: [
                    for (final entry in kWhisperLanguages.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _buildCheckBox(context),
        const SizedBox(height: 14),
        Text(
          'Recording works without a model — memos are always stored as audio, '
          'and play back like any other attachment. A model only adds the text.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// One device row: a combo box of what the platform reports, headed by the
  /// system default.
  ///
  /// The value is the device *name*, which is also what the preference stores
  /// — see `AppSettings.voiceMemoInputDevice`. A stored name that is no longer
  /// in the list still gets an entry of its own, marked as missing: dropping it
  /// silently would make the combo box show "System default" while the setting
  /// on disk said otherwise, and would assert on a value with no item.
  Widget _buildDeviceField({
    required String label,
    required AsyncValue<List<va.AudioDevice>> devices,
    required String selected,
    required ValueChanged<String> onChanged,
    String? hint,
  }) {
    final theme = Theme.of(context);

    return devices.when(
      loading: () => ClassicField(
        label: label,
        hint: hint,
        child: Text('Looking…', style: theme.textTheme.bodySmall),
      ),
      // A machine with no audio library at all still has to render this tab.
      error: (error, _) => ClassicField(
        label: label,
        hint: 'No audio devices could be listed: $error',
        child: Text('Unavailable', style: theme.textTheme.bodySmall),
      ),
      data: (list) {
        final names = [for (final device in list) device.name];
        final missing = selected.isNotEmpty && !names.contains(selected);

        return ClassicField(
          label: label,
          hint: hint,
          child: ClassicDropdown<String>(
            width: 260,
            value: selected,
            onChanged: (value) => onChanged(value ?? ''),
            items: [
              const DropdownMenuItem(
                value: '',
                child: Text('System default', overflow: TextOverflow.ellipsis),
              ),
              for (final device in list)
                DropdownMenuItem(
                  value: device.name,
                  child: Text(
                    device.isDefault ? '${device.name} (default)' : device.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (missing)
                DropdownMenuItem(
                  value: selected,
                  child: Text(
                    '$selected (not connected)',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// The self-test: record, play back, transcribe, and say what broke.
  Widget _buildCheckBox(BuildContext context) {
    final theme = Theme.of(context);
    final check = ref.watch(audioCheckProvider);
    final notifier = ref.read(audioCheckProvider.notifier);

    return ClassicGroupBox(
      title: 'Check',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Records a few seconds, plays them back and transcribes them, '
            'using the devices and model above. Nothing is saved.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (check.isRecording)
                FilledButton(
                  style: classicButtonStyle(context),
                  onPressed: notifier.finish,
                  child: const Text('Stop'),
                )
              else
                FilledButton(
                  style: classicButtonStyle(context),
                  // Disabled for the middle of a run: playback and
                  // transcription finish on their own, and there is nothing
                  // useful a second press could do.
                  onPressed: check.isRunning ? null : notifier.start,
                  child: Text(check.hasResult ? 'Test again' : 'Test'),
                ),
              const SizedBox(width: 10),
              if (check.isRunning)
                OutlinedButton(
                  style: classicButtonStyle(context),
                  onPressed: notifier.cancel,
                  child: const Text('Cancel'),
                ),
              const SizedBox(width: 12),
              Expanded(child: _buildCheckStatus(context, check)),
            ],
          ),
          if (check.stage == AudioCheckStage.transcribing &&
              check.transcription?.isGranular == true) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: 160,
              child: LinearProgressIndicator(
                value: check.transcription!.fraction,
              ),
            ),
          ],
          if (check.isRecording) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 160,
                  child: LinearProgressIndicator(
                    value: check.level.clamp(0.0, 1.0),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  DurationFormatter.formatMediaPosition(check.elapsed),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
          if (check.error != null) ...[
            const SizedBox(height: 8),
            Text(
              check.error!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          if (check.note != null) ...[
            const SizedBox(height: 8),
            Text(check.note!, style: theme.textTheme.bodySmall),
          ],
          if (check.transcript != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(3),
              ),
              child: SelectableText(
                check.transcript!,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// The one-line "what is happening" beside the button.
  Widget _buildCheckStatus(BuildContext context, AudioCheckState check) {
    final theme = Theme.of(context);

    final String text;
    switch (check.stage) {
      case AudioCheckStage.idle:
        return const SizedBox.shrink();
      case AudioCheckStage.recording:
        text = 'Recording — say a sentence, then press Stop.';
      case AudioCheckStage.playing:
        text = 'Playing it back…';
      case AudioCheckStage.transcribing:
        final progress = check.transcription;
        text = progress == null || !progress.isGranular
            ? 'Transcribing…'
            : 'Transcribing… ${(progress.fraction * 100).round()}%';
      case AudioCheckStage.done:
        text = 'Recorded '
            '${DurationFormatter.formatMediaPosition(check.recorded)}.';
      case AudioCheckStage.failed:
        text = 'The check did not finish.';
    }

    return Text(text, style: theme.textTheme.bodySmall);
  }

  /// The row under the dropdown: whether the file is here, and the button that
  /// fetches or removes it.
  Widget _buildModelStatus(BuildContext context, VoiceMemoModel model) {
    final theme = Theme.of(context);

    if (model.isNone) return const SizedBox.shrink();

    if (_downloading == model) {
      final fraction = _progress?.fraction;
      final caption = Text(
        fraction == null
            ? 'Downloading…'
            : '${(fraction * 100).round()}% of '
                '${_megabytes(_progress!.total ?? model.downloadBytes)}',
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
      final cancel = OutlinedButton(
        style: classicButtonStyle(context),
        onPressed: () => ref.read(whisperServiceProvider).cancelDownload(),
        child: const Text('Cancel'),
      );

      // A phone's group box is about 290dp wide, which a 140dp bar, the byte
      // count and Cancel cannot share on one line — Cancel, the one control
      // here, was the part that ended up off the screen. Give the bar its own
      // full-width line and put the count beside the button underneath.
      if (classicStackedLayout(context)) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: fraction),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: caption),
                const SizedBox(width: 8),
                cancel,
              ],
            ),
          ],
        );
      }

      return Row(
        children: [
          SizedBox(
            width: 140,
            child: LinearProgressIndicator(value: fraction),
          ),
          const SizedBox(width: 10),
          // Flexible, so a long byte count ellipsizes rather than pushing
          // Cancel past the edge of a narrowed window.
          Flexible(child: caption),
          const Spacer(),
          cancel,
        ],
      );
    }

    final ready = ref.watch(voiceMemoModelReadyProvider);
    return ready.when(
      loading: () => const SizedBox(height: 28),
      error: (error, _) => Text('$error', style: theme.textTheme.bodySmall),
      data: (present) => Row(
        children: [
          Icon(
            present ? Icons.check_circle_outline : Icons.download_outlined,
            size: 16,
            color: present ? theme.colorScheme.primary : theme.hintColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _error ??
                  (present
                      ? '${model.label} is downloaded and ready.'
                      : 'Not downloaded — '
                          '${_megabytes(model.downloadBytes)} from '
                          'HuggingFace.'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: _error != null ? theme.colorScheme.error : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (present)
            OutlinedButton(
              style: classicButtonStyle(context),
              onPressed: () => _delete(model),
              child: const Text('Remove'),
            )
          else
            FilledButton(
              style: classicButtonStyle(context),
              onPressed: () => _download(model),
              child: const Text('Download'),
            ),
        ],
      ),
    );
  }

  Future<void> _download(VoiceMemoModel model) async {
    setState(() {
      _downloading = model;
      _error = null;
      _progress = ModelDownloadProgress(0, model.downloadBytes);
    });

    try {
      await ref.read(whisperServiceProvider).downloadModel(
            model,
            onProgress: (progress) {
              if (mounted) setState(() => _progress = progress);
            },
          );
    } on DownloadCancelled {
      if (mounted) setState(() => _error = 'Download cancelled.');
    } on Object catch (error) {
      if (mounted) setState(() => _error = 'Download failed: $error');
    } finally {
      if (mounted) {
        setState(() {
          _downloading = null;
          _progress = null;
        });
        ref.invalidate(voiceMemoModelReadyProvider);
      }
    }
  }

  Future<void> _delete(VoiceMemoModel model) async {
    await ref.read(whisperServiceProvider).deleteModel(model);
    if (!mounted) return;
    setState(() => _error = null);
    ref.invalidate(voiceMemoModelReadyProvider);
  }

  static String _megabytes(int bytes) =>
      '${(bytes / (1024 * 1024)).round()} MB';
}
