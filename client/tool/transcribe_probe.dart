// Dev-time probe. Downloads a whisper model (if asked) and transcribes a
// stored memo — transcription end to end, which the unit tests cannot cover
// because they refuse to pull 78 MB.
//
// The input is a `.opus` memo rather than a WAV, because encoding is the
// device's job now: voice_audio records from a microphone and does not take
// PCM the app supplies. `tool/voice_memo_capture_probe.dart` produces exactly
// the file this wants.
//
//   flutter build linux --release -t tool/transcribe_probe.dart
//   NOO_PROBE_IN=/tmp/noo_memo.opus NOO_PROBE_MODEL=tiny NOO_PROBE_DOWNLOAD=1 \
//     xvfb-run -a ./build/linux/x64/release/bundle/noo
//
// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:noo/data/services/audio/whisper_service.dart';
import 'package:voice_audio/voice_audio.dart' as va;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final inPath = Platform.environment['NOO_PROBE_IN'];
  final modelName = Platform.environment['NOO_PROBE_MODEL'] ?? 'tiny';
  final mayDownload = Platform.environment['NOO_PROBE_DOWNLOAD'] == '1';
  final model = VoiceMemoModel.fromName(modelName);

  if (inPath == null || model.isNone) {
    print('PROBE set NOO_PROBE_IN to a .opus memo and NOO_PROBE_MODEL');
    exit(1);
  }

  final service = WhisperService();
  print('PROBE modelDir=${await service.modelDirectory()}');
  print('PROBE model=${model.name} present=${await service.isPresent(model)}');

  if (!await service.isPresent(model)) {
    if (!mayDownload) {
      print('PROBE model absent and NOO_PROBE_DOWNLOAD is not 1 — stopping');
      exit(1);
    }
    print('PROBE downloading ${model.label} '
        '(${(model.downloadBytes / 1048576).round()} MB)...');
    var lastPercent = -1;
    final started = DateTime.now();
    await service.downloadModel(model, onProgress: (progress) {
      final fraction = progress.fraction;
      if (fraction == null) return;
      final percent = (fraction * 100).round();
      if (percent >= lastPercent + 20) {
        lastPercent = percent;
        print('PROBE   $percent%');
      }
    });
    print('PROBE downloaded in ${DateTime.now().difference(started)}, '
        'size=${await service.sizeOnDisk(model)}');
  }

  final memo = File(inPath).readAsBytesSync();
  final parsed = va.VoiceMemo.tryParseOgg(memo);
  if (parsed == null) {
    print('PROBE $inPath is not a memo this build can read');
    exit(1);
  }
  print('PROBE memo=${memo.length} bytes, ${parsed.duration}, '
      '${parsed.sampleRate}Hz');

  // NOO_PROBE_CANCEL=<n> stops the run after n blocks, which is the only way
  // to see cancellation land against a real decode: the block boundary is the
  // one place it can, and how long it takes to get there is the number that
  // matters to whoever pressed the button.
  final cancelAfter = int.tryParse(Platform.environment['NOO_PROBE_CANCEL'] ?? '');
  // NOO_PROBE_CANCEL_MS asks from a timer instead, which is what a button
  // press actually looks like: it lands mid-block, and what gets measured is
  // the wait for the decode already running to finish.
  final cancelMs = int.tryParse(Platform.environment['NOO_PROBE_CANCEL_MS'] ?? '');
  var cancelled = false;
  DateTime? asked;

  if (cancelMs != null) {
    Timer(Duration(milliseconds: cancelMs), () {
      cancelled = true;
      asked = DateTime.now();
      print('PROBE   cancel asked at ${cancelMs}ms');
    });
  }

  final started = DateTime.now();
  String? transcript;
  try {
    transcript = await service.transcribeMemo(
      memo,
      model: model,
      onProgress: (progress) {
        print('PROBE   ${progress.block}/${progress.total} '
            '(${(progress.fraction * 100).round()}%)');
        if (cancelAfter != null && progress.block >= cancelAfter && !cancelled) {
          cancelled = true;
          asked = DateTime.now();
        }
      },
      isCancelled: () => cancelled,
    );
  } on TranscriptionCancelled {
    print('PROBE cancelled after '
        '${DateTime.now().difference(asked!).inMilliseconds}ms');
    await service.release();
    print('PROBE ok');
    exit(0);
  }
  final elapsed = DateTime.now().difference(started);

  print('PROBE transcribed in $elapsed');
  print('PROBE TRANSCRIPT: ${transcript ?? "(nothing)"}');
  await service.release();
  print('PROBE ok');
  exit(0);
}
