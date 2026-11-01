@TestOn('vm')
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/services/audio/whisper_service.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

/// Model bookkeeping and the download, which is the part with a user waiting
/// on it, plus how a recording is split into blocks and how that progress is
/// reported — [WhisperService.transcribeBlock] is a seam precisely so those
/// can be checked here. The decoding itself needs a 78 MB model and is covered
/// by `client/tool/transcribe_probe.dart` and `transcribe_chunk_probe.dart`
/// instead.
/// A [WhisperService] whose blocks decode without a model.
///
/// [WhisperService.transcribeBlock] is the one thing in the class that needs a
/// 148 MB file on disk, so overriding it leaves the block arithmetic, the
/// progress ticks and the text assembly testable exactly as they ship.
class RecordingWhisper extends WhisperService {
  RecordingWhisper(
    Directory dir, {
    this.silentBlocks = const {},
    this.sessionsBefore,
  }) : super(directory: (() async => dir.path));

  /// 1-based blocks that decode to nothing, standing in for silence.
  final Set<int> silentBlocks;

  /// How many blocks get a session before there is no longer one to open —
  /// the model deleted from under a run.
  final int? sessionsBefore;

  final List<int> blockLengths = [];

  /// The first byte of each decoded block, so a test that runs two
  /// transcriptions can tell whose audio each block was.
  final List<int> tags = [];

  /// Awaited inside each block (numbered across all runs), so a test can hold
  /// one transcription mid-way while it starts another.
  Future<void> Function(int block)? onBlock;

  /// Thrown from the next block, once — a native decode that failed.
  Object? failure;

  @override
  Future<String?> transcribeBlock(
    Uint8List pcm16, {
    required VoiceMemoModel model,
    required String language,
    required bool keepModelLoaded,
  }) async {
    final limit = sessionsBefore;
    if (limit != null && blockLengths.length >= limit) return null;

    final failure = this.failure;
    if (failure != null) {
      this.failure = null;
      throw failure;
    }

    blockLengths.add(pcm16.length);
    tags.add(pcm16.isEmpty ? -1 : pcm16[0]);
    final index = blockLengths.length;
    await onBlock?.call(index);
    return silentBlocks.contains(index) ? '' : 'block $index';
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The test binding installs an HttpOverrides that answers everything with
  // 400; these requests go to our own loopback server.
  setUpAll(() => HttpOverrides.global = null);

  late Directory dir;
  late HttpServer server;

  /// What the fake HuggingFace serves.
  late List<int> body;

  /// Set to stall the response mid-flight, so a cancel has something to catch.
  Duration? chunkDelay;
  int? statusCode;
  bool omitContentLength = false;

  /// How many requests the fake HuggingFace has answered.
  var requests = 0;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('noo_whisper_test');
    body = List<int>.generate(64 * 1024, (i) => i % 251);
    chunkDelay = null;
    statusCode = null;
    omitContentLength = false;
    requests = 0;

    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    // One handler per request, not an `await for` over the server: a client
    // that hangs up mid-body (the cancel test) can leave its handler waiting
    // in `flush()` on a dead socket, and a sequential loop would then hold
    // every later request — the one the test is about — until the timeout.
    server.listen((request) async {
      requests++;
      final response = request.response;
      if (statusCode != null) {
        response.statusCode = statusCode!;
        await response.close();
        return;
      }
      if (!omitContentLength) response.contentLength = body.length;
      try {
        const chunk = 8 * 1024;
        for (var i = 0; i < body.length; i += chunk) {
          response.add(body.sublist(i, (i + chunk).clamp(0, body.length)));
          await response.flush();
          if (chunkDelay != null) await Future<void>.delayed(chunkDelay!);
        }
        await response.close();
      } on Object {
        // The client hung up: that is what the cancel test is doing.
      }
    });
  });

  tearDown(() async {
    await server.close(force: true);
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  WhisperService makeService() => WhisperService(
        directory: () async => dir.path,
        httpClient: HttpClient.new,
        modelUri: (model) =>
            Uri.parse('http://${server.address.host}:${server.port}/'
                '${model.modelName}.bin'),
      );

  String fileFor(VoiceMemoModel model) =>
      '${dir.path}/ggml-${model.model!.modelName}.bin';

  group('model bookkeeping', () {
    test('"off" has no file, no size and nothing to download', () async {
      final service = makeService();
      expect(await service.pathFor(VoiceMemoModel.none), isNull);
      expect(await service.isPresent(VoiceMemoModel.none), isFalse);
      expect(await service.sizeOnDisk(VoiceMemoModel.none), isNull);
      expect(() => service.downloadModel(VoiceMemoModel.none),
          throwsArgumentError);
    });

    test('resolves the path whisper_ggml itself would use', () async {
      final service = makeService();
      expect(await service.pathFor(VoiceMemoModel.tiny),
          '${dir.path}/ggml-tiny.bin');
      expect(await service.pathFor(VoiceMemoModel.base),
          '${dir.path}/ggml-base.bin');
    });

    test('reports presence and size from the filesystem', () async {
      final service = makeService();
      expect(await service.isPresent(VoiceMemoModel.tiny), isFalse);

      File(fileFor(VoiceMemoModel.tiny)).writeAsBytesSync(List.filled(1234, 7));
      expect(await service.isPresent(VoiceMemoModel.tiny), isTrue);
      expect(await service.sizeOnDisk(VoiceMemoModel.tiny), 1234);
    });

    test('the enum survives a round trip through preferences', () {
      for (final model in VoiceMemoModel.values) {
        expect(VoiceMemoModel.fromName(model.name), model);
      }
      // An unknown name must not throw — a preferences file from a newer
      // build should degrade to transcription off, not crash the app.
      expect(VoiceMemoModel.fromName('gigantic'), VoiceMemoModel.none);
      expect(VoiceMemoModel.fromName(null), VoiceMemoModel.none);
    });

    test('quotes the real download sizes', () {
      // Measured, and shown to the user before they commit to the download.
      expect(VoiceMemoModel.tiny.downloadBytes, 77691713);
      expect(VoiceMemoModel.base.downloadBytes, 147951465);
      expect(VoiceMemoModel.small.downloadBytes, 487601967);
      expect(VoiceMemoModel.none.downloadBytes, 0);
    });

    test('a model can be deleted, along with a stray part file', () async {
      final service = makeService();
      File(fileFor(VoiceMemoModel.tiny)).writeAsBytesSync([1, 2, 3]);
      File('${fileFor(VoiceMemoModel.tiny)}.part').writeAsBytesSync([4]);

      await service.deleteModel(VoiceMemoModel.tiny);
      expect(await service.isPresent(VoiceMemoModel.tiny), isFalse);
      expect(File('${fileFor(VoiceMemoModel.tiny)}.part').existsSync(), isFalse);
    });
  });

  group('download', () {
    test('fetches the model and reports progress along the way', () async {
      final service = makeService();
      final seen = <ModelDownloadProgress>[];

      await service.downloadModel(VoiceMemoModel.tiny,
          onProgress: seen.add);

      expect(await service.isPresent(VoiceMemoModel.tiny), isTrue);
      expect(File(fileFor(VoiceMemoModel.tiny)).readAsBytesSync(),
          Uint8List.fromList(body));

      expect(seen, isNotEmpty);
      expect(seen.first.received, 0);
      expect(seen.last.received, body.length);
      expect(seen.last.fraction, 1.0);
      expect(seen.every((p) => p.total == body.length), isTrue);
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i].received, greaterThanOrEqualTo(seen[i - 1].received));
      }
    });

    test('leaves no .part file behind', () async {
      final service = makeService();
      await service.downloadModel(VoiceMemoModel.tiny);
      expect(File('${fileFor(VoiceMemoModel.tiny)}.part').existsSync(), isFalse);
    });

    test('a model already on disk is not fetched again', () async {
      final service = makeService();
      File(fileFor(VoiceMemoModel.tiny)).writeAsBytesSync([9, 9, 9]);

      var progressed = false;
      await service.downloadModel(VoiceMemoModel.tiny,
          onProgress: (_) => progressed = true);

      expect(progressed, isFalse);
      expect(File(fileFor(VoiceMemoModel.tiny)).lengthSync(), 3);
    });

    test('copes with a server that sends no Content-Length', () async {
      omitContentLength = true;
      final service = makeService();
      final seen = <ModelDownloadProgress>[];

      await service.downloadModel(VoiceMemoModel.tiny, onProgress: seen.add);

      expect(await service.isPresent(VoiceMemoModel.tiny), isTrue);
      expect(seen.last.total, isNull);
      expect(seen.last.fraction, isNull, reason: 'unknown, not zero');
    });

    test('a failed download leaves nothing that looks like a model', () async {
      // The trap this guards: a truncated file passes isPresent, and whisper
      // then fails to load it with no hint why.
      statusCode = HttpStatus.notFound;
      final service = makeService();

      await expectLater(
        service.downloadModel(VoiceMemoModel.tiny),
        throwsA(isA<HttpException>()),
      );
      expect(await service.isPresent(VoiceMemoModel.tiny), isFalse);
      expect(File('${fileFor(VoiceMemoModel.tiny)}.part').existsSync(), isFalse);
    });

    test('cancelling stops it and cleans up', () async {
      chunkDelay = const Duration(milliseconds: 40);
      final service = makeService();

      final download = service.downloadModel(
        VoiceMemoModel.tiny,
        onProgress: (progress) {
          if (progress.received > 0) service.cancelDownload();
        },
      );

      // Always the cancellation, never the socket's own "connection closed"
      // that closing the client provokes — the row says "cancelled" from it.
      await expectLater(download, throwsA(isA<DownloadCancelled>()));
      expect(await service.isPresent(VoiceMemoModel.tiny), isFalse);
      expect(File('${fileFor(VoiceMemoModel.tiny)}.part').existsSync(), isFalse);
      expect(service.isDownloading, isFalse);
    });

    test('cancelling when nothing is downloading is harmless', () {
      final service = makeService();
      expect(service.isDownloading, isFalse);
      service.cancelDownload();
      expect(service.isDownloading, isFalse);
    });

    test('a second download runs after a cancelled one', () async {
      chunkDelay = const Duration(milliseconds: 40);
      final service = makeService();
      await expectLater(
        service.downloadModel(
          VoiceMemoModel.tiny,
          onProgress: (p) {
            if (p.received > 0) service.cancelDownload();
          },
        ),
        throwsA(isA<DownloadCancelled>()),
      );

      chunkDelay = null;
      await service.downloadModel(VoiceMemoModel.tiny);
      expect(await service.isPresent(VoiceMemoModel.tiny), isTrue);
    });

    test('a second download of the same model joins the first', () async {
      // The trap: two writers on one `.part` file, and the first to finish
      // renames a garbled file into place as a ready model. The Preferences
      // tab used to be able to do this, because its "downloading" flag lived
      // in a widget the tab bar disposes on every switch.
      chunkDelay = const Duration(milliseconds: 20);
      final service = makeService();
      final first = <ModelDownloadProgress>[];
      final second = <ModelDownloadProgress>[];

      final a = service.downloadModel(VoiceMemoModel.tiny,
          onProgress: first.add);
      expect(service.isDownloading, isTrue);
      expect(service.downloadingModel, VoiceMemoModel.tiny);
      // Join part-way through, once some bytes have landed.
      while (first.isEmpty || first.last.received == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      final b = service.downloadModel(VoiceMemoModel.tiny,
          onProgress: second.add);
      await Future.wait([a, b]);

      expect(requests, 1, reason: 'one fetch, not two');
      expect(File(fileFor(VoiceMemoModel.tiny)).readAsBytesSync(),
          Uint8List.fromList(body));
      expect(File('${fileFor(VoiceMemoModel.tiny)}.part').existsSync(), isFalse);
      // The joiner is told where the download has got to at once, then
      // follows it to the end alongside the original caller.
      expect(second, isNotEmpty);
      expect(second.first.received, greaterThan(0));
      expect(second.last.received, body.length);
      expect(first.last.received, body.length);
      expect(service.isDownloading, isFalse);
    });

    test('a cancel reaches everyone waiting on the joined download', () async {
      chunkDelay = const Duration(milliseconds: 40);
      final service = makeService();

      final a = service.downloadModel(VoiceMemoModel.tiny);
      final b = service.downloadModel(VoiceMemoModel.tiny,
          onProgress: (p) {
            if (p.received > 0) service.cancelDownload();
          });

      await expectLater(a, throwsA(isA<DownloadCancelled>()));
      await expectLater(b, throwsA(isA<DownloadCancelled>()));
      expect(await service.isPresent(VoiceMemoModel.tiny), isFalse);
      expect(service.isDownloading, isFalse);
    });

    test('a different model while one is in flight is refused', () async {
      chunkDelay = const Duration(milliseconds: 20);
      final service = makeService();

      final tiny = service.downloadModel(VoiceMemoModel.tiny);
      // One cancel flag and one client: a second, unrelated download would
      // share both. Refused plainly rather than queued, since the button for
      // it is disabled while the row shows a bar.
      expect(() => service.downloadModel(VoiceMemoModel.base),
          throwsStateError);
      await tiny;

      expect(await service.isPresent(VoiceMemoModel.tiny), isTrue);
      expect(await service.isPresent(VoiceMemoModel.base), isFalse);
      // Free again once the first has landed.
      chunkDelay = null;
      await service.downloadModel(VoiceMemoModel.base);
      expect(await service.isPresent(VoiceMemoModel.base), isTrue);
    });
  });

  group('one transcription at a time', () {
    /// PCM filled with [tag], so every block cut from it carries it.
    Uint8List pcmSeconds(int seconds, {int tag = 0}) =>
        Uint8List(WhisperService.kSampleRate * 2 * seconds)
          ..fillRange(0, WhisperService.kSampleRate * 2 * seconds, tag);

    test('two overlapping transcriptions run strictly one after the other',
        () async {
      // Natively there is one stream: starting a session disposes the one
      // before it, and feed/stop carry no session identity. Interleaved
      // blocks would hand memo A the words of memo B.
      final whisper = RecordingWhisper(dir);
      final gate = Completer<void>();
      whisper.onBlock = (block) => block == 1 ? gate.future : Future.value();

      final a = whisper.transcribePcm(pcmSeconds(75, tag: 1),
          model: VoiceMemoModel.base);
      final b = whisper.transcribePcm(pcmSeconds(50, tag: 2),
          model: VoiceMemoModel.base);
      await pumpEventQueue();

      // A is held inside its first block; B has not opened a session.
      expect(whisper.tags, [1]);
      gate.complete();

      expect(await a, 'block 1 block 2 block 3');
      expect(await b, 'block 4 block 5');
      expect(whisper.tags, [1, 1, 1, 2, 2],
          reason: 'every block of A before any block of B');
    });

    test('a queued transcription cancelled while waiting never starts',
        () async {
      final whisper = RecordingWhisper(dir);
      final gate = Completer<void>();
      whisper.onBlock = (block) => block == 1 ? gate.future : Future.value();
      var cancelB = false;
      final ticksB = <TranscriptionProgress>[];

      final a = whisper.transcribePcm(pcmSeconds(75, tag: 1),
          model: VoiceMemoModel.base);
      final b = whisper.transcribePcm(
        pcmSeconds(50, tag: 2),
        model: VoiceMemoModel.base,
        onProgress: ticksB.add,
        isCancelled: () => cancelB,
      );
      final bOutcome = expectLater(b, throwsA(isA<TranscriptionCancelled>()));

      // The user changes their mind while B is still behind A.
      cancelB = true;
      gate.complete();

      expect(await a, 'block 1 block 2 block 3');
      await bOutcome;
      expect(whisper.tags, [1, 1, 1], reason: 'B decoded nothing');
      expect(ticksB, isEmpty, reason: 'not even a 0% tick');
    });

    test('a failed transcription does not wedge the next', () async {
      final whisper = RecordingWhisper(dir)..failure = StateError('no model');

      final a = whisper.transcribePcm(pcmSeconds(50, tag: 1),
          model: VoiceMemoModel.base);
      final b = whisper.transcribePcm(pcmSeconds(50, tag: 2),
          model: VoiceMemoModel.base);

      await expectLater(a, throwsStateError);
      expect(await b, 'block 1 block 2');
      expect(whisper.tags, [2, 2]);
    });
  });

  group('block splitting and progress', () {
    /// One second of PCM16 at the rate everything runs at.
    Uint8List pcmSeconds(int seconds) =>
        Uint8List(WhisperService.kSampleRate * 2 * seconds);

    test('splits a recording on the native commit window', () async {
      final whisper = RecordingWhisper(dir);
      // 25 s is the native side's own commit boundary; matching it is what
      // stops the same audio being decoded eleven times over.
      await whisper.transcribePcm(pcmSeconds(60),
          model: VoiceMemoModel.base);

      expect(whisper.blockLengths.length, 3);
      final block = WhisperService.kSampleRate * 2 * 25;
      expect(whisper.blockLengths, [block, block, block ~/ 2.5]);
    });

    test('a recording shorter than one block is a single block', () async {
      final whisper = RecordingWhisper(dir);
      final ticks = <TranscriptionProgress>[];
      await whisper.transcribePcm(pcmSeconds(3),
          model: VoiceMemoModel.base, onProgress: ticks.add);

      expect(whisper.blockLengths.length, 1);
      // Nothing to draw a bar from — one block is 0% and then done — and the
      // callers use this to fall back to a plain "Transcribing…".
      expect(ticks.every((t) => !t.isGranular), isTrue);
    });

    test('reports a tick before the first block and after every one',
        () async {
      final whisper = RecordingWhisper(dir);
      final ticks = <TranscriptionProgress>[];

      await whisper.transcribePcm(pcmSeconds(60),
          model: VoiceMemoModel.base, onProgress: ticks.add);

      // The leading 0-of-3 matters: it is what puts a bar on screen at 0%
      // rather than leaving it blank until the first block lands.
      expect(ticks.map((t) => '${t.block}/${t.total}'),
          ['0/3', '1/3', '2/3', '3/3']);
      expect(ticks.map((t) => t.fraction), [0.0, 1 / 3, 2 / 3, 1.0]);
    });

    test('the text builds up as the blocks land', () async {
      final whisper = RecordingWhisper(dir);
      final texts = <String>[];

      final transcript = await whisper.transcribePcm(pcmSeconds(60),
          model: VoiceMemoModel.base,
          onProgress: (progress) => texts.add(progress.text));

      expect(texts, ['', 'block 1', 'block 1 block 2', 'block 1 block 2 block 3']);
      expect(transcript, 'block 1 block 2 block 3');
    });

    test('a block that held no speech is skipped, not written as a gap',
        () async {
      final whisper = RecordingWhisper(dir, silentBlocks: {2});
      final transcript = await whisper.transcribePcm(pcmSeconds(60),
          model: VoiceMemoModel.base);
      expect(transcript, 'block 1 block 3');
    });

    test('a recording with nothing in it transcribes to null', () async {
      final whisper = RecordingWhisper(dir, silentBlocks: {1, 2, 3});
      expect(
        await whisper.transcribePcm(pcmSeconds(60),
            model: VoiceMemoModel.base),
        isNull,
      );
    });

    test('empty input decodes nothing at all', () async {
      final whisper = RecordingWhisper(dir);
      expect(
        await whisper.transcribePcm(Uint8List(0),
            model: VoiceMemoModel.base),
        isNull,
      );
      expect(whisper.blockLengths, isEmpty);
    });

    test('cancelling stops it at the next block boundary', () async {
      final whisper = RecordingWhisper(dir);
      var cancelled = false;
      final ticks = <TranscriptionProgress>[];

      await expectLater(
        whisper.transcribePcm(
          pcmSeconds(200),
          model: VoiceMemoModel.base,
          // Asked for after the second block has landed.
          onProgress: (progress) {
            ticks.add(progress);
            if (progress.block == 2) cancelled = true;
          },
          isCancelled: () => cancelled,
        ),
        throwsA(isA<TranscriptionCancelled>()),
      );

      // Eight blocks were due; the third never started. A native decode cannot
      // be interrupted, so a block boundary is as close as cancelling gets.
      expect(whisper.blockLengths.length, 2);
      expect(ticks.last.block, 2);
    });

    test('cancelling before the first block decodes nothing', () async {
      final whisper = RecordingWhisper(dir);
      await expectLater(
        whisper.transcribePcm(pcmSeconds(60),
            model: VoiceMemoModel.base, isCancelled: () => true),
        throwsA(isA<TranscriptionCancelled>()),
      );
      expect(whisper.blockLengths, isEmpty);
    });

    test('a run nobody cancels is unaffected by the check', () async {
      final whisper = RecordingWhisper(dir);
      expect(
        await whisper.transcribePcm(pcmSeconds(60),
            model: VoiceMemoModel.base, isCancelled: () => false),
        'block 1 block 2 block 3',
      );
    });

    test('a model deleted mid-run keeps what was already decoded', () async {
      // The model is removed from Preferences while a long memo is running:
      // the blocks that did decode are worth more than a clean failure.
      final whisper = RecordingWhisper(dir, sessionsBefore: 2);
      final ticks = <TranscriptionProgress>[];

      final transcript = await whisper.transcribePcm(pcmSeconds(60),
          model: VoiceMemoModel.base, onProgress: ticks.add);

      expect(transcript, 'block 1 block 2');
      expect(ticks.last.block, 2);
    });
  });

  group('sessions', () {
    test('a model that is not downloaded yields no session', () async {
      final service = makeService();
      expect(await service.startSession(VoiceMemoModel.tiny), isNull);
      expect(await service.startSession(VoiceMemoModel.none), isNull);
      expect(
        await service.transcribePcm(Uint8List(3200),
            model: VoiceMemoModel.tiny),
        isNull,
      );
    });
  });

  group('languages', () {
    test('offers auto-detect and English, with English the default', () {
      expect(kWhisperLanguages.keys.first, 'auto');
      expect(kWhisperLanguages['en'], 'English');
      expect(kWhisperLanguages.containsKey('en'), isTrue);
    });

    test('every model name maps to a whisper_ggml model', () {
      for (final model in VoiceMemoModel.values.where((m) => !m.isNone)) {
        expect(model.model, isA<WhisperModel>());
        expect(model.model!.modelUri.host, 'huggingface.co');
      }
    });
  });
}
