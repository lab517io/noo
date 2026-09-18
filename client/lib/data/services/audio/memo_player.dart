/// Playing a recording straight from its bytes, and waiting for the end.
///
/// The attachment panel plays memos through `voice_audio` already; what is new
/// here is a caller that needs to *wait* for playback to finish before moving
/// on, and that has to work in a test with no speaker. Hence the seam: the
/// preferences self-test drives [MemoPlayer], the real one is
/// [VoiceAudioMemoPlayer], and a widget test hands over one that returns
/// immediately.
library;

import 'dart:typed_data';

import 'package:voice_audio/voice_audio.dart' as va;

/// Plays one recording and completes when it has finished.
abstract class MemoPlayer {
  /// Play [oggBytes] through [speaker] (null for the platform default) and
  /// return when the recording has played out.
  ///
  /// Returns false when the bytes are not a recording this can play, which is
  /// a report worth making rather than an exception: it says the capture side
  /// produced something malformed.
  Future<bool> play(Uint8List oggBytes, {va.AudioDevice? speaker});

  /// Stop early. Safe when nothing is playing.
  Future<void> stop();
}

/// [MemoPlayer] backed by the `voice_audio` player.
class VoiceAudioMemoPlayer implements MemoPlayer {
  VoiceAudioMemoPlayer({va.VoiceAudio? audio})
      : _audio = audio ?? va.VoiceAudio.instance;

  final va.VoiceAudio _audio;

  @override
  Future<bool> play(Uint8List oggBytes, {va.AudioDevice? speaker}) async {
    final memo = va.VoiceMemo.tryParseOgg(oggBytes);
    if (memo == null) return false;

    await _audio.initialize();
    await _audio.player.play(memo, speaker: speaker);

    // `completed` resolves on the native end-of-stream event, or early when
    // [stop] is called — so a user who closes the dialog mid-playback is not
    // waited on.
    await _audio.player.completed;
    return true;
  }

  @override
  Future<void> stop() async {
    if (!_audio.isInitialized) return;
    await _audio.player.stop();
  }
}
