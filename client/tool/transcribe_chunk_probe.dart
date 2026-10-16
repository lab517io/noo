// Dev-time probe. Measures what the *feed chunk size* costs on the whisper
// live path, which is not something a unit test can see: the native side
// re-decodes its whole accumulated window every time enough new audio has
// arrived, so smaller chunks mean more decodes over the same audio.
//
// Reports, per chunk size: wall time, how many partials came back, and the
// final transcript, so a change in speed can be checked against a change in
// what was actually heard.
//
//   flutter build linux --release -t tool/transcribe_chunk_probe.dart
//   NOO_PROBE_IN=/tmp/long.opus NOO_PROBE_MODEL=tiny NOO_PROBE_CHUNKS=1,5,25 \
//     xvfb-run -a ./build/linux/x64/release/bundle/noo
//
// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:noo/data/services/audio/whisper_service.dart';
import 'package:voice_audio/voice_audio.dart' as va;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final inPath = Platform.environment['NOO_PROBE_IN'];
  final modelName = Platform.environment['NOO_PROBE_MODEL'] ?? 'tiny';
  final chunkSpec = Platform.environment['NOO_PROBE_CHUNKS'] ?? '1,25';
  final model = VoiceMemoModel.fromName(modelName);

  if (inPath == null || model.isNone) {
    print('PROBE set NOO_PROBE_IN to a .opus memo and NOO_PROBE_MODEL');
    exit(1);
  }

  final service = WhisperService();
  if (!await service.isPresent(model)) {
    print('PROBE ${model.label} is not downloaded — run transcribe_probe first');
    exit(1);
  }

  final memo = va.VoiceMemo.tryParseOgg(File(inPath).readAsBytesSync());
  if (memo == null) {
    print('PROBE $inPath is not a memo this build can read');
    exit(1);
  }
  final samples = await memo.decodeToPcm(sampleRate: WhisperService.kSampleRate);
  final pcm = samples.buffer
      .asUint8List(samples.offsetInBytes, samples.lengthInBytes);
  print('PROBE memo=${memo.duration}, ${samples.length} samples, '
      'model=${model.name}');

  for (final spec in chunkSpec.split(',')) {
    final seconds = double.parse(spec.trim());
    final chunk = (WhisperService.kSampleRate * 2 * seconds).round();

    final session = await service.startSession(model, language: 'en');
    if (session == null) {
      print('PROBE could not open a session');
      exit(1);
    }

    var partials = 0;
    final sub = session.partials.listen((_) => partials++);

    final started = DateTime.now();
    for (var offset = 0; offset < pcm.length; offset += chunk) {
      final end = offset + chunk < pcm.length ? offset + chunk : pcm.length;
      session.feed(Uint8List.sublistView(pcm, offset, end));
    }
    final text = await session.stop();
    final elapsed = DateTime.now().difference(started);
    await sub.cancel();

    final ratio = memo.duration.inMilliseconds / elapsed.inMilliseconds;
    print('PROBE chunk=${seconds}s  wall=${elapsed.inMilliseconds}ms  '
        '${ratio.toStringAsFixed(1)}x realtime  partials=$partials');
    print('PROBE   text: ${text.trim()}');
  }

  // One session per block, which is the shape that can report an exact
  // "block k of N" — the single-session path has no acknowledgement to count.
  final blockSpec = Platform.environment['NOO_PROBE_BLOCKS'];
  if (blockSpec != null) {
    final seconds = double.parse(blockSpec.trim());
    final block = (WhisperService.kSampleRate * 2 * seconds).round();
    final blocks = (pcm.length / block).ceil();

    final started = DateTime.now();
    final parts = <String>[];
    for (var i = 0; i < blocks; i++) {
      final blockStarted = DateTime.now();
      final offset = i * block;
      final end = offset + block < pcm.length ? offset + block : pcm.length;

      final session = await service.startSession(model, language: 'en');
      if (session == null) break;
      session.feed(Uint8List.sublistView(pcm, offset, end));
      final text = await session.stop();
      parts.add(text.trim());
      print('PROBE   block ${i + 1}/$blocks in '
          '${DateTime.now().difference(blockStarted).inMilliseconds}ms');
    }
    final elapsed = DateTime.now().difference(started);
    final ratio = memo.duration.inMilliseconds / elapsed.inMilliseconds;
    print('PROBE blocks=${seconds}s  wall=${elapsed.inMilliseconds}ms  '
        '${ratio.toStringAsFixed(1)}x realtime  blocks=$blocks');
    print('PROBE   text: ${parts.join(' ')}');
  }

  await service.release();
  print('PROBE ok');
  exit(0);
}
