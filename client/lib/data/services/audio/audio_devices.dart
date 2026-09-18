/// Which microphone records and which speaker plays back.
///
/// Two things live here. [AudioDeviceSource] is the enumeration itself, behind
/// an interface so that Preferences, the recorder and the tests all reach the
/// hardware through one seam — nothing above this file touches the FFI
/// boundary, and a widget test can list two fake devices without a native
/// library on the machine.
///
/// [resolveAudioDevice] is the other half, and the more important one. A
/// device's index is its only identifier in `voice_audio` and indices are not
/// stable across a device change, so a stored index is a recording from the
/// wrong microphone waiting to happen. What is stored is the *name*, matched
/// against a fresh enumeration each time; a name that is no longer there
/// resolves to null, which everywhere in `voice_audio` means "the platform
/// default".
library;

import 'package:voice_audio/voice_audio.dart' as va;

/// Lists the machine's capture and playback endpoints.
abstract class AudioDeviceSource {
  Future<List<va.AudioDevice>> microphones();
  Future<List<va.AudioDevice>> speakers();

  /// Re-scan, for the Refresh button. Hot-plug is only reported on Windows —
  /// see `VoiceAudio.deviceListChanges` — so on every other platform this is
  /// the only way a headset plugged in after the dialog opened shows up.
  Future<void> rescan();
}

/// [AudioDeviceSource] backed by the `voice_audio` engine.
class VoiceAudioDeviceSource implements AudioDeviceSource {
  VoiceAudioDeviceSource({va.VoiceAudio? audio})
      : _audio = audio ?? va.VoiceAudio.instance;

  final va.VoiceAudio _audio;

  /// The engine has to be up before it will answer: every entry point in
  /// `voice_audio` throws until `initialize` has run. Bringing it up to list
  /// devices opens nothing — the capture and playback streams are opened by
  /// the recorder and the player, not by this.
  Future<void> _ready() => _audio.initialize();

  @override
  Future<List<va.AudioDevice>> microphones() async {
    await _ready();
    return _audio.microphones();
  }

  @override
  Future<List<va.AudioDevice>> speakers() async {
    await _ready();
    return _audio.speakers();
  }

  @override
  Future<void> rescan() async {
    await _ready();
    await _audio.rescanDevices();
  }
}

/// Find the device [name] refers to, or null for "let the platform decide".
///
/// Null is returned for an empty name and for a name that is no longer in
/// [devices] — a headset that has been unplugged since it was chosen. Both are
/// the same answer as far as every caller is concerned, because null is what
/// `voice_audio` takes to mean the system default.
va.AudioDevice? resolveAudioDevice(
  List<va.AudioDevice> devices,
  String name,
) {
  if (name.isEmpty) return null;
  for (final device in devices) {
    if (device.name == name) return device;
  }
  return null;
}
