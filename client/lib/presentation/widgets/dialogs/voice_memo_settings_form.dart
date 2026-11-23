import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_audio/voice_audio.dart' as va;

import '../../../core/utils/duration_formatter.dart';
import '../../../data/services/audio/whisper_service.dart';
import '../../../l10n/l10n.dart';
import '../../providers/audio_check_provider.dart';
import '../../providers/audio_device_provider.dart';
import '../../providers/model_download_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/voice_memo_provider.dart';
import 'classic_form.dart';
import '../../../core/theme/noo_chrome.dart';

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
  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final model = settings.voiceMemoModel;
    // Held in a provider, not here: this form is a `TabBarView` page and is
    // disposed on every tab switch, while the download it started is not.
    final download = ref.watch(modelDownloadProvider);
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClassicGroupBox(
          title: l10n.prefsVoiceGroupDevices,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDeviceField(
                label: l10n.prefsVoiceMicrophone,
                devices: ref.watch(microphoneDevicesProvider),
                selected: settings.voiceMemoInputDevice,
                onChanged: notifier.setVoiceMemoInputDevice,
                hint: l10n.prefsVoiceMicrophoneHint,
              ),
              const SizedBox(height: 10),
              _buildDeviceField(
                label: l10n.prefsVoiceSpeaker,
                devices: ref.watch(speakerDevicesProvider),
                selected: settings.voiceMemoOutputDevice,
                onChanged: notifier.setVoiceMemoOutputDevice,
                // Said out loud because the difference is otherwise
                // inexplicable: memos play through this app's own decoder,
                // every other audio attachment through the platform's, and
                // only the first of the two takes a device.
                hint: l10n.prefsVoiceSpeakerHint,
              ),
              const SizedBox(height: 10),
              ClassicFieldIndent(
                child: Row(
                  children: [
                    OutlinedButton(
                      style: classicButtonStyle(context),
                      onPressed: () => refreshAudioDevices(
                          ProviderScope.containerOf(context)),
                      child: Text(l10n.commonRefresh),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ClassicGroupBox(
          title: l10n.prefsVoiceGroupTranscription,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClassicField(
                label: l10n.prefsVoiceModel,
                hint: model.isNone
                    ? l10n.prefsVoiceModelHintNone
                    : l10n.prefsVoiceModelHintLocal,
                child: ClassicDropdown<VoiceMemoModel>(
                  value: model,
                  onChanged: download.isDownloading
                      ? null
                      : (value) {
                          if (value == null) return;
                          ref.read(modelDownloadProvider.notifier).clearError();
                          notifier.setVoiceMemoModel(value);
                        },
                  items: [
                    for (final option in VoiceMemoModel.values)
                      DropdownMenuItem(
                        value: option,
                        child: Text(option.isNone
                            ? l10n.prefsVoiceModelOff
                            : option.recommended
                                ? l10n.prefsVoiceModelItemRecommended(
                                    option.label,
                                    _megabytes(l10n, option.downloadBytes))
                                : l10n.prefsVoiceModelItem(option.label,
                                    _megabytes(l10n, option.downloadBytes))),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildModelStatus(context, model),
              const SizedBox(height: 12),
              ClassicCheckbox(
                label: l10n.prefsVoiceTranscribeAfter,
                hint: l10n.prefsVoiceTranscribeAfterHint,
                value: settings.voiceMemoTranscribe,
                onChanged: model.isNone
                    ? null
                    : (value) => notifier.setVoiceMemoTranscribe(value),
              ),
              const SizedBox(height: 10),
              ClassicField(
                label: l10n.prefsVoiceLanguage,
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
                        // The languages are named in their own tongue; only
                        // the automatic choice is a word of the interface.
                        child: Text(entry.key == 'auto'
                            ? l10n.prefsVoiceLanguageAuto
                            : entry.value),
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
          l10n.prefsVoiceFooter,
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
    final l10n = context.l10n;

    return devices.when(
      loading: () => ClassicField(
        label: label,
        hint: hint,
        child: Text(l10n.prefsVoiceDevicesLooking,
            style: theme.textTheme.bodySmall),
      ),
      // A machine with no audio library at all still has to render this tab.
      error: (error, _) => ClassicField(
        label: label,
        hint: l10n.prefsVoiceDevicesError('$error'),
        child: Text(l10n.prefsVoiceDevicesUnavailable,
            style: theme.textTheme.bodySmall),
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
              DropdownMenuItem(
                value: '',
                child: Text(l10n.commonSystemDefault,
                    overflow: TextOverflow.ellipsis),
              ),
              for (final device in list)
                DropdownMenuItem(
                  value: device.name,
                  child: Text(
                    device.isDefault
                        ? l10n.prefsVoiceDeviceDefault(device.name)
                        : device.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              if (missing)
                DropdownMenuItem(
                  value: selected,
                  child: Text(
                    l10n.prefsVoiceDeviceMissing(selected),
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
    final l10n = context.l10n;

    return ClassicGroupBox(
      title: l10n.prefsVoiceGroupCheck,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.prefsVoiceCheckIntro,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (check.isRecording)
                FilledButton(
                  style: classicButtonStyle(context),
                  onPressed: notifier.finish,
                  child: Text(l10n.prefsVoiceStop),
                )
              else
                FilledButton(
                  style: classicButtonStyle(context),
                  // Disabled for the middle of a run: playback and
                  // transcription finish on their own, and there is nothing
                  // useful a second press could do.
                  onPressed: check.isRunning ? null : notifier.start,
                  child: Text(
                      check.hasResult ? l10n.prefsVoiceTestAgain : l10n.commonTest),
                ),
              const SizedBox(width: 10),
              if (check.isRunning)
                OutlinedButton(
                  style: classicButtonStyle(context),
                  onPressed: notifier.cancel,
                  child: Text(l10n.commonCancel),
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
                borderRadius: NooChrome.of(context).smallRadius,
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
    final l10n = context.l10n;

    final String text;
    switch (check.stage) {
      case AudioCheckStage.idle:
        return const SizedBox.shrink();
      case AudioCheckStage.recording:
        text = l10n.prefsVoiceCheckRecording;
      case AudioCheckStage.playing:
        text = l10n.prefsVoiceCheckPlaying;
      case AudioCheckStage.transcribing:
        final progress = check.transcription;
        text = progress == null || !progress.isGranular
            ? l10n.prefsVoiceCheckTranscribing
            : l10n.prefsVoiceCheckTranscribingPercent(
                (progress.fraction * 100).round());
      case AudioCheckStage.done:
        text = l10n.prefsVoiceCheckDone(
            DurationFormatter.formatMediaPosition(check.recorded));
      case AudioCheckStage.failed:
        text = l10n.prefsVoiceCheckFailed;
    }

    return Text(text, style: theme.textTheme.bodySmall);
  }

  /// The row under the dropdown: whether the file is here, and the button that
  /// fetches or removes it.
  Widget _buildModelStatus(BuildContext context, VoiceMemoModel model) {
    final theme = Theme.of(context);

    if (model.isNone) return const SizedBox.shrink();
    final l10n = context.l10n;

    final download = ref.watch(modelDownloadProvider);
    if (download.isDownloadingModel(model)) {
      final progress = download.progress;
      final fraction = progress?.fraction;
      final caption = Text(
        fraction == null
            ? l10n.prefsVoiceDownloading
            : l10n.prefsVoiceDownloadProgress((fraction * 100).round(),
                _megabytes(l10n, progress!.total ?? model.downloadBytes)),
        style: theme.textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
      final cancel = OutlinedButton(
        style: classicButtonStyle(context),
        onPressed: ref.read(modelDownloadProvider.notifier).cancel,
        child: Text(l10n.commonCancel),
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

    final error = download.error;
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
              error ??
                  (present
                      ? l10n.prefsVoiceModelReady(model.label)
                      : l10n.prefsVoiceModelNotDownloaded(
                          _megabytes(l10n, model.downloadBytes))),
              style: theme.textTheme.bodySmall?.copyWith(
                color: error != null ? theme.colorScheme.error : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (present)
            OutlinedButton(
              style: classicButtonStyle(context),
              onPressed: () => _delete(model),
              child: Text(l10n.commonRemove),
            )
          else
            FilledButton(
              style: classicButtonStyle(context),
              // Disabled, not merely ignored, while another model is coming
              // down: the service runs one download at a time.
              onPressed: download.isDownloading
                  ? null
                  : () => ref
                      .read(modelDownloadProvider.notifier)
                      .download(model),
              child: Text(l10n.commonDownload),
            ),
        ],
      ),
    );
  }

  Future<void> _delete(VoiceMemoModel model) async {
    await ref.read(whisperServiceProvider).deleteModel(model);
    if (!mounted) return;
    ref.read(modelDownloadProvider.notifier).clearError();
    ref.invalidate(voiceMemoModelReadyProvider);
  }

  static String _megabytes(AppLocalizations l10n, int bytes) =>
      l10n.prefsMegabytes('${(bytes / (1024 * 1024)).round()}');
}
