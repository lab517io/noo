@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/audio/voice_memo_recorder.dart';
import 'package:noo/data/services/audio/whisper_service.dart';
import 'package:noo/presentation/providers/audio_device_provider.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/providers/settings_provider.dart';
import 'package:noo/presentation/providers/voice_memo_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio_fakes.dart';
import 'memo_fixture.dart';
import 'voice_memo_recorder_test.dart' show FakeVoiceMemoEngine;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NooDatabase db;
  late int taskId;
  late FakeVoiceMemoEngine engine;

  /// A container wired to an in-memory database and a fake microphone.
  ///
  /// The settings load is awaited before the test runs: `SettingsNotifier`
  /// kicks off an async read in `build()`, and a container torn down while
  /// that is still in flight throws when the read finally touches its ref.
  Future<ProviderContainer> makeContainer({bool withDatabase = true}) async {
    final container = ProviderContainer(overrides: [
      if (withDatabase) databaseProvider.overrideWithValue(db),
      audioDeviceSourceProvider.overrideWithValue(FakeAudioDeviceSource()),
      voiceMemoRecorderFactoryProvider.overrideWithValue(
        () => VoiceMemoRecorder(
          engine: engine,
          progressInterval: const Duration(milliseconds: 5),
        ),
      ),
    ]);
    addTearDown(container.dispose);
    container.read(settingsProvider);
    await pumpEventQueue();
    return container;
  }

  setUp(() async {
    // The notifier reads settings (which model, which language), and
    // SettingsNotifier loads them from SharedPreferences on build.
    SharedPreferences.setMockInitialValues({});
    db = NooDatabase.memory();
    taskId = await db.createTask(
      worldId: WorldId.create().value,
      title: 'Task',
    );
    engine = FakeVoiceMemoEngine();
    addTearDown(db.close);
  });

  group('VoiceMemoNotifier', () {
    test('reports transcription progress while the memo is transcribed',
        () async {
      final whisper = FakeWhisper(text: 'hello')..blocks = 3;
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        audioDeviceSourceProvider.overrideWithValue(FakeAudioDeviceSource()),
        whisperServiceProvider.overrideWithValue(whisper),
        voiceMemoRecorderFactoryProvider.overrideWithValue(
          () => VoiceMemoRecorder(
            engine: engine,
            progressInterval: const Duration(milliseconds: 5),
          ),
        ),
      ]);
      addTearDown(container.dispose);
      container.read(settingsProvider);
      await pumpEventQueue();
      await container
          .read(settingsProvider.notifier)
          .setVoiceMemoModel(VoiceMemoModel.base);

      final fractions = <double>[];
      final sub = container.listen(voiceMemoProvider, (previous, next) {
        final progress = next.transcription;
        if (progress != null && progress != previous?.transcription) {
          fractions.add(progress.fraction);
        }
      });
      addTearDown(sub.close);

      await container.read(voiceMemoProvider.notifier).start(taskId);
      final stored = await container.read(voiceMemoProvider.notifier).stop();

      expect(stored?.transcript, 'hello');
      expect(fractions, [1 / 3, 2 / 3, 1.0]);
    });

    test('cancelling the transcription keeps the memo and drops the text',
        () async {
      final whisper = FakeWhisper(text: 'hello')..blocks = 4;
      final container = ProviderContainer(overrides: [
        databaseProvider.overrideWithValue(db),
        audioDeviceSourceProvider.overrideWithValue(FakeAudioDeviceSource()),
        whisperServiceProvider.overrideWithValue(whisper),
        voiceMemoRecorderFactoryProvider.overrideWithValue(
          () => VoiceMemoRecorder(
            engine: engine,
            progressInterval: const Duration(milliseconds: 5),
          ),
        ),
      ]);
      addTearDown(container.dispose);
      container.read(settingsProvider);
      await pumpEventQueue();
      final notifier = container.read(voiceMemoProvider.notifier);
      await container
          .read(settingsProvider.notifier)
          .setVoiceMemoModel(VoiceMemoModel.base);

      // Cancel from inside the run, after the second of four blocks.
      whisper.onBlock = (block) async {
        if (block == 2) notifier.cancelTranscription();
      };

      await notifier.start(taskId);
      final stored = await notifier.stop();

      // No text — but the attachment was written before transcription began
      // and is still there, which is the whole point of transcribing after
      // storing rather than alongside.
      expect(stored?.transcript, isNull);
      expect(await db.getAttachmentsForTask(taskId), hasLength(1));
      expect(container.read(voiceMemoProvider).status, VoiceMemoStatus.idle);
    });

    test('records from the microphone chosen in Preferences', () async {
      final container = await makeContainer();
      await container
          .read(settingsProvider.notifier)
          .setVoiceMemoInputDevice('USB headset');

      expect(await container.read(voiceMemoProvider.notifier).start(taskId),
          isTrue);

      expect(engine.startedWith?.name, 'USB headset');
      await container.read(voiceMemoProvider.notifier).cancel();
    });

    test('falls back to the default when the chosen microphone has gone',
        () async {
      final container = await makeContainer();
      await container
          .read(settingsProvider.notifier)
          .setVoiceMemoInputDevice('Headset that was unplugged');

      expect(await container.read(voiceMemoProvider.notifier).start(taskId),
          isTrue);

      // Recording still starts — losing a device must not lose the memo — and
      // it starts on the platform default rather than on whatever now happens
      // to sit at the old index.
      expect(engine.startedWith, isNull);
      await container.read(voiceMemoProvider.notifier).cancel();
    });

    test('records, stores the memo as an attachment, and returns to idle',
        () async {
      final container = await makeContainer();
      final notifier = container.read(voiceMemoProvider.notifier);

      expect(await notifier.start(taskId), isTrue);
      expect(container.read(voiceMemoProvider).status,
          VoiceMemoStatus.recording);
      expect(container.read(voiceMemoProvider).taskId, taskId);

      engine.advance(const Duration(seconds: 1));
      await pumpEventQueue();

      final attachment = await notifier.stop();
      expect(attachment, isNotNull);
      expect(attachment!.attachment.filename, endsWith('.opus'));
      expect(attachment.taskId, taskId);

      // Stored, and stored as a real memo rather than an empty row: the bytes
      // that came back out of the database are the Ogg Opus file that went in.
      final rows = await db.getAttachmentsForTask(taskId);
      expect(rows, hasLength(1));
      final stored = await db.getAttachmentWithContent(rows.single.id);
      expect(stored!.content, memoFixtureBytes());
      expect(attachment.duration, kMemoFixtureDuration);

      final state = container.read(voiceMemoProvider);
      expect(state.status, VoiceMemoStatus.idle);
      expect(state.taskId, isNull);
      expect(state.error, isNull);
    });

    test('the memo belongs to the task it was started from', () async {
      final other = await db.createTask(
        worldId: WorldId.create().value,
        title: 'Другая',
      );
      final container = await makeContainer();
      final notifier = container.read(voiceMemoProvider.notifier);

      await notifier.start(taskId);
      engine.advance(const Duration(milliseconds: 500));
      await pumpEventQueue();
      final attachment = await notifier.stop();

      expect(attachment!.taskId, taskId);
      expect(await db.getAttachmentsForTask(other), isEmpty);
    });

    test('tracks elapsed time and level while recording', () async {
      final container = await makeContainer();
      final notifier = container.read(voiceMemoProvider.notifier);
      await notifier.start(taskId);

      for (var i = 0; i < 5; i++) {
        engine.advance(const Duration(milliseconds: 200), at: 0.3);
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      final state = container.read(voiceMemoProvider);
      expect(state.elapsed, greaterThanOrEqualTo(
          const Duration(milliseconds: 800)));
      expect(state.level, greaterThan(0));
      await notifier.cancel();
    });

    test('cancel discards the recording and stores nothing', () async {
      final container = await makeContainer();
      final notifier = container.read(voiceMemoProvider.notifier);

      await notifier.start(taskId);
      engine.advance(const Duration(seconds: 1));
      await pumpEventQueue();
      await notifier.cancel();

      expect(container.read(voiceMemoProvider).status, VoiceMemoStatus.idle);
      expect(await db.getAttachmentsForTask(taskId), isEmpty);
    });

    test('only one recording runs at a time', () async {
      final container = await makeContainer();
      final notifier = container.read(voiceMemoProvider.notifier);

      expect(await notifier.start(taskId), isTrue);
      expect(await notifier.start(taskId), isFalse,
          reason: 'a second start must not disturb the first');
      expect(container.read(voiceMemoProvider).status,
          VoiceMemoStatus.recording);
      await notifier.cancel();
    });

    test('a refused microphone is reported and starts nothing', () async {
      engine.permitted = false;
      final container = await makeContainer();
      final notifier = container.read(voiceMemoProvider.notifier);

      expect(await notifier.start(taskId), isFalse);
      final state = container.read(voiceMemoProvider);
      expect(state.status, VoiceMemoStatus.idle);
      expect(state.error, contains('permission'));
      expect(engine.started, isFalse);
      expect(engine.disposed, isTrue, reason: 'the recorder must be released');
    });

    test('a device that will not open is reported', () async {
      engine.failOnStart = true;
      final container = await makeContainer();
      final notifier = container.read(voiceMemoProvider.notifier);

      expect(await notifier.start(taskId), isFalse);
      final state = container.read(voiceMemoProvider);
      expect(state.status, VoiceMemoStatus.idle);
      expect(state.error, contains('Could not start recording'));
    });

    test('a recording with no database to save into is reported', () async {
      final container = await makeContainer(withDatabase: false);
      final notifier = container.read(voiceMemoProvider.notifier);

      await notifier.start(taskId);
      engine.advance(const Duration(seconds: 1));
      await pumpEventQueue();

      expect(await notifier.stop(), isNull);
      expect(container.read(voiceMemoProvider).error, contains('No database'));
    });

    test('stopping a recording that captured nothing saves nothing', () async {
      final container = await makeContainer();
      final notifier = container.read(voiceMemoProvider.notifier);

      await notifier.start(taskId);
      engine.capture = null;
      expect(await notifier.stop(), isNull);
      expect(container.read(voiceMemoProvider).status, VoiceMemoStatus.idle);
      expect(await db.getAttachmentsForTask(taskId), isEmpty);
    });

    test('a device error aborts the recording rather than saving half of it',
        () async {
      final container = await makeContainer();
      final notifier = container.read(voiceMemoProvider.notifier);

      await notifier.start(taskId);
      engine.advance(const Duration(milliseconds: 500));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      engine.failOnPoll = const FileSystemException('device went away');
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final state = container.read(voiceMemoProvider);
      expect(state.error, contains('Recording failed'));
      expect(state.status, VoiceMemoStatus.idle);
      expect(await db.getAttachmentsForTask(taskId), isEmpty);
    });

    test('an error clears when the next recording starts', () async {
      engine.permitted = false;
      final container = await makeContainer();
      final notifier = container.read(voiceMemoProvider.notifier);
      await notifier.start(taskId);
      expect(container.read(voiceMemoProvider).error, isNotNull);

      engine = FakeVoiceMemoEngine();
      final second = await makeContainer();
      await second.read(voiceMemoProvider.notifier).start(taskId);
      expect(second.read(voiceMemoProvider).error, isNull);
      await second.read(voiceMemoProvider.notifier).cancel();
    });
  });
}
