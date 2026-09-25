import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_audio/voice_audio.dart' as va;

import '../../data/services/audio/audio_devices.dart';
import 'settings_provider.dart';

/// How the app enumerates audio devices. Overridden in tests with a fake, so
/// Preferences lays out and the self-test runs with no audio hardware.
final audioDeviceSourceProvider =
    Provider<AudioDeviceSource>((ref) => VoiceAudioDeviceSource());

/// Microphones, as the platform currently reports them.
///
/// A `FutureProvider` rather than a cached list because the answer expires:
/// invalidate it to re-enumerate after a Refresh, or when a device is plugged
/// in on the one platform that says so.
final microphoneDevicesProvider =
    FutureProvider<List<va.AudioDevice>>((ref) async {
  return ref.watch(audioDeviceSourceProvider).microphones();
});

/// Speakers, on the same terms as [microphoneDevicesProvider].
final speakerDevicesProvider =
    FutureProvider<List<va.AudioDevice>>((ref) async {
  return ref.watch(audioDeviceSourceProvider).speakers();
});

/// Re-scan the hardware and rebuild both lists.
///
/// Takes a [WidgetRef] because the Refresh button is the only caller: nothing
/// inside a provider has a reason to re-enumerate on its own.
Future<void> refreshAudioDevices(WidgetRef ref) async {
  // Best effort: a backend with no rescan of its own still gets a fresh
  // enumeration from the invalidation below, which is the part that matters.
  try {
    await ref.read(audioDeviceSourceProvider).rescan();
  } on Object {
    // Ignored deliberately — see above.
  }
  ref.invalidate(microphoneDevicesProvider);
  ref.invalidate(speakerDevicesProvider);
}

/// The microphone to record from right now, or null for the system default.
///
/// Resolved at the moment of use rather than being held onto: the stored
/// preference is a name, and the index it maps to is only true of the
/// enumeration it came from. See `resolveAudioDevice`.
Future<va.AudioDevice?> selectedMicrophone(Ref ref) async {
  final name = ref.read(settingsProvider).voiceMemoInputDevice;
  if (name.isEmpty) return null;
  try {
    return resolveAudioDevice(
        await ref.read(audioDeviceSourceProvider).microphones(), name);
  } on Object {
    // The device list is a convenience; failing to get it must not stop a
    // recording that the default device would have handled.
    return null;
  }
}

/// The speaker to play through right now, or null for the system default.
Future<va.AudioDevice?> selectedSpeaker(Ref ref) async {
  final name = ref.read(settingsProvider).voiceMemoOutputDevice;
  if (name.isEmpty) return null;
  try {
    return resolveAudioDevice(
        await ref.read(audioDeviceSourceProvider).speakers(), name);
  } on Object {
    return null;
  }
}
