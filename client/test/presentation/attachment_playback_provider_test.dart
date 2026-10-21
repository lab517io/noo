import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/repositories/attachment_repository_impl.dart';
import 'package:noo/domain/entities/attachment.dart';
import 'package:noo/presentation/providers/attachment_playback_provider.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/providers/value_controller.dart';

/// The playback model's identity and lifetime, without any audio backend:
/// the media server is stubbed out, so `toggle` stops at "unavailable" — an
/// attachment loaded with an error, which is all these need.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NooDatabase db;
  late Attachment mp3;

  setUp(() async {
    db = NooDatabase.memory();
    addTearDown(db.close);
    final taskId = await db.createTask(
      worldId: WorldId.create().value,
      title: 'Task',
    );
    mp3 = await AttachmentRepositoryImpl(db).createAttachment(
      taskId: taskId,
      filename: 'song.mp3',
      content: Uint8List.fromList([1, 2, 3]),
    );
  });

  test('isCurrent is keyed on the worldId, not the row id', () {
    final playback = AudioPlayback(worldId: mp3.worldId.value);

    expect(playback.isCurrent(mp3), isTrue);
    expect(playback.isCurrent(mp3.copyWith(id: 99)), isTrue,
        reason: 'the same attachment read back under another row id');
    expect(
      playback.isCurrent(Attachment(
        id: mp3.id,
        taskId: mp3.taskId,
        worldId: WorldId.create(),
        filename: 'other.mp3',
      )),
      isFalse,
      reason: 'another file at the same row id — the state after a database '
          'swap — is not the one playing',
    );
    expect(const AudioPlayback().isCurrent(mp3), isFalse);
  });

  test('a database swap stops playback and forgets the attachment', () async {
    final openDb = valueProvider<NooDatabase?>(db);
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWith((ref) => ref.watch(openDb)),
      attachmentMediaServerProvider.overrideWith((ref) async => null),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(audioPlaybackProvider.notifier);
    await notifier.toggle(mp3);
    expect(container.read(audioPlaybackProvider).isCurrent(mp3), isTrue,
        reason: 'loaded, if only as far as the unavailable-server error');

    final other = NooDatabase.memory();
    addTearDown(other.close);
    container.read(openDb.notifier).value = other;
    // In the app every screen watches databaseProvider, so a swap refreshes
    // it at once; here nothing else does, so read it the way they would and
    // let the notifier's listener run.
    expect(container.read(databaseProvider), same(other));
    await Future<void>.delayed(Duration.zero);

    final after = container.read(audioPlaybackProvider);
    expect(after.worldId, isNull,
        reason: 'the bytes came from a database that is no longer open');
    expect(after.isCurrent(mp3), isFalse);
    expect(after.error, isNull);
  });

  test('a failed attempt is started over on the next press, not resumed',
      () async {
    var serverCalls = 0;
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      attachmentMediaServerProvider.overrideWith((ref) async {
        serverCalls++;
        return null;
      }),
    ]);
    addTearDown(container.dispose);

    final notifier = container.read(audioPlaybackProvider.notifier);
    await notifier.toggle(mp3);
    expect(container.read(audioPlaybackProvider).error, isNotNull);

    // Same attachment again. A resume would find nothing loaded and leave
    // the error on screen; a fresh start asks the server again.
    container.invalidate(attachmentMediaServerProvider);
    await notifier.toggle(mp3);
    expect(serverCalls, 2);
  });
}
