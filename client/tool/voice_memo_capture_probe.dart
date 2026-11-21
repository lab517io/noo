// Dev-time probe. Records from the *real* microphone through the same path the
// UI uses — voice_audio → VoiceMemoRecorder → Ogg — and writes the memo out so
// external tools can check it.
//
// This is the one part of the recording path unit tests cannot reach: they
// drive a fake engine, so the plugin, the device and the encoder are only
// exercised here. Run it after any change to voice_audio, and listen to what
// comes out — nothing in the test suite can tell you the audio sounds right.
//
//   flutter build linux --release -t tool/voice_memo_capture_probe.dart
//   NOO_PROBE_OUT=/tmp/memo NOO_PROBE_SECONDS=4 \
//     xvfb-run -a ./build/linux/x64/release/bundle/noo
//   opusinfo /tmp/memo.opus
//
// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:noo/data/services/audio/voice_memo_recorder.dart';
import 'package:voice_audio/voice_audio.dart' as va;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final outBase = Platform.environment['NOO_PROBE_OUT'] ?? '/tmp/noo_memo';
  final seconds =
      int.tryParse(Platform.environment['NOO_PROBE_SECONDS'] ?? '') ?? 4;

  final recorder = VoiceMemoRecorder();

  if (!await recorder.hasPermission()) {
    print('PROBE no microphone permission');
    exit(1);
  }

  var ticks = 0;
  var peak = 0.0;
  recorder.progress.listen(
    (tick) {
      ticks++;
      if (tick.level > peak) peak = tick.level;
    },
    onError: (Object error) => print('PROBE stream error: $error'),
  );

  final started = DateTime.now();
  try {
    await recorder.start();
  } on Object catch (error) {
    print('PROBE could not start: $error');
    exit(1);
  }
  print('PROBE recording for ${seconds}s...');
  await Future<void>.delayed(Duration(seconds: seconds));

  final memo = await recorder.stop();
  final wall = DateTime.now().difference(started);
  await recorder.dispose();

  if (memo == null) {
    print('PROBE captured nothing — is a source connected?');
    exit(1);
  }

  final parsed = va.VoiceMemo.tryParseOgg(memo.bytes);
  File('$outBase.opus').writeAsBytesSync(memo.bytes);

  print('PROBE filename=${memo.filename}');
  print('PROBE captured=${memo.duration} wall=$wall '
      'bytes=${memo.bytes.length} '
      '${(memo.bytes.length * 8 / memo.duration.inMilliseconds).toStringAsFixed(2)} kbit/s');
  print('PROBE ticks=$ticks peakLevel=${peak.toStringAsFixed(3)}');
  if (parsed == null) {
    print('PROBE the recording did not read back as Ogg Opus');
    exit(1);
  }

  final pcm = await parsed.decodeToPcm();
  print('PROBE backend=${va.VoiceAudio.instance.backend} '
      'codec=${va.VoiceAudio.instance.codecVersion}');
  print('PROBE container: ${parsed.sampleRate}Hz frames=${parsed.frameCount} '
      'duration=${parsed.duration}');
  print('PROBE decoded=${pcm.length} samples '
      '(${pcm.length * 1000 ~/ parsed.sampleRate} ms)');
  print('PROBE wrote $outBase.opus');

  // Play it back. The unit tests drive a fake engine, so this is the only
  // place the decode-and-play path runs against a real speaker.
  final player = va.VoiceAudio.instance.player;
  final playStarted = DateTime.now();
  await player.play(parsed);
  print('PROBE playing, duration=${player.duration}');

  await player.seek(parsed.duration ~/ 2);
  print('PROBE seeked to ${player.position}');

  await player.completed.timeout(
    parsed.duration + const Duration(seconds: 5),
    onTimeout: () => print('PROBE playback did not finish in time'),
  );
  print('PROBE played in ${DateTime.now().difference(playStarted)}');

  final peaks = await parsed.waveform(buckets: 16);
  print('PROBE waveform=${peaks.map((p) => p.toStringAsFixed(2)).join(" ")}');

  print('PROBE ok');
  exit(0);
}
