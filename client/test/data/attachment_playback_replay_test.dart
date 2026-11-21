/// Playing the same memo twice.
///
/// This one needs the real `voice_audio` library and a speaker, because the bug
/// it guards against lives in the seam between them: when a recording reaches
/// its end the native player goes **idle**, not paused, so `resume()` has
/// nothing to resume and silently does nothing. `audioplayers` restarts on
/// resume-after-complete, which is why the question never came up for mp3.
///
/// The symptom is a play button that does nothing on the second press, with the
/// position stuck at the beginning.
///
/// The same seam produced a second one: seeking a finished recording revives it
/// natively, so dragging the slider after a memo ran out started audio the UI
/// knew nothing about and poisoned the next press. That case is here too.
///
/// Opt in by pointing the loader at a build tree; without it the group skips,
/// because the rest of the suite deliberately runs with no native audio at all:
///
///   VOICE_AUDIO_LIBRARY=/path/to/flutter_voice_audio/build-shared-real/libvoice_audio.so \
///     flutter test test/data/attachment_playback_replay_test.dart
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/repositories/attachment_repository_impl.dart';
import 'package:noo/domain/entities/attachment.dart';
import 'package:noo/presentation/providers/attachment_playback_provider.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:voice_audio/voice_audio.dart' as va;

import 'audio/memo_fixture.dart';

final String? _skip = Platform.environment['VOICE_AUDIO_LIBRARY'] == null
    ? 'set VOICE_AUDIO_LIBRARY to a voice_audio build to run this'
    : null;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NooDatabase db;
  late Attachment memo;

  setUp(() async {
    db = NooDatabase.memory();
    final taskId = await db.createTask(
      worldId: WorldId.create().value,
      title: 'Task',
    );
    // Through the repository, so the row looks exactly like a stored memo -
    // worldId included, which is what playback reads it back by.
    memo = await AttachmentRepositoryImpl(db).createAttachment(
      taskId: taskId,
      filename: 'memo 2026-03-07 21-05-33.opus',
      content: memoFixtureBytes(),
    );
    addTearDown(db.close);
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    return container;
  }

  group('memo playback', () {
    test('plays again after it has finished', () async {
      final container = makeContainer();
      final notifier = container.read(audioPlaybackProvider.notifier);

      await notifier.toggle(memo);
      expect(container.read(audioPlaybackProvider).playing, isTrue);
      expect(container.read(audioPlaybackProvider).duration,
          kMemoFixtureDuration);

      // Let it run out.
      await va.VoiceAudio.instance.player.completed
          .timeout(kMemoFixtureDuration + const Duration(seconds: 3));
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(container.read(audioPlaybackProvider).playing, isFalse);

      // The second press. This is the one that used to do nothing.
      await notifier.toggle(memo);
      expect(container.read(audioPlaybackProvider).playing, isTrue);
      expect(va.VoiceAudio.instance.player.state, va.PlayerState.playing);

      await notifier.stop();
    });

    test('a drag after it finished starts the next play from there', () async {
      final container = makeContainer();
      final notifier = container.read(audioPlaybackProvider.notifier);

      await notifier.toggle(memo);
      await va.VoiceAudio.instance.player.completed
          .timeout(kMemoFixtureDuration + const Duration(seconds: 3));
      await Future<void>.delayed(const Duration(milliseconds: 250));

      // The slider is still on screen and still enabled here - the duration is
      // known and the position is back at zero - so this is an ordinary drag.
      const target = Duration(milliseconds: 400);
      await notifier.seek(target);

      // A drag is not a play. The native seek would take a finished recording
      // and start it again, which used to leave audio running with the UI
      // saying nothing was playing, and the next press throwing out of
      // resume() because the package considers the recording finished.
      expect(va.VoiceAudio.instance.player.state, va.PlayerState.idle);
      expect(container.read(audioPlaybackProvider).playing, isFalse);
      expect(container.read(audioPlaybackProvider).position, target);

      // The press that follows picks the drag up.
      await notifier.toggle(memo);
      expect(container.read(audioPlaybackProvider).playing, isTrue);
      expect(container.read(audioPlaybackProvider).position, target);
      expect(va.VoiceAudio.instance.player.position,
          greaterThanOrEqualTo(target));

      await notifier.stop();
    });

    test('pause and resume still work mid-recording', () async {
      final container = makeContainer();
      final notifier = container.read(audioPlaybackProvider.notifier);

      await notifier.toggle(memo);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      await notifier.toggle(memo);
      expect(container.read(audioPlaybackProvider).playing, isFalse,
          reason: 'a press part way through is a pause, not a restart');
      expect(va.VoiceAudio.instance.player.state, va.PlayerState.paused);

      await notifier.toggle(memo);
      expect(container.read(audioPlaybackProvider).playing, isTrue);
      expect(va.VoiceAudio.instance.player.state, va.PlayerState.playing);

      await notifier.stop();
    });
  }, skip: _skip);
}
