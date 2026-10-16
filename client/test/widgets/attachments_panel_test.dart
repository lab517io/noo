import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/attachment_uri.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/history_service.dart';
import 'package:noo/data/services/sync_crypto.dart';
import 'package:noo/data/services/sync_service.dart';
import 'package:noo/domain/entities/sync_config.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/widgets/attachments/attachment_image_provider.dart';
import 'package:noo/presentation/widgets/attachments/attachment_preview.dart';
import 'package:noo/presentation/widgets/attachments/attachments_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'editor_image_embed_test.dart' show buildPng;

/// The panel previews what it can in place: images render from their BLOB,
/// audio gets transport controls, anything else stays a plain file row.
void main() {
  final png = buildPng(8);

  late NooDatabase db;
  late int taskId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = NooDatabase.memory();
    taskId = await db.createTask(
      worldId: WorldId.create().value,
      title: 'Task',
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> addAttachment(
    String filename, {
    Uint8List? content,
    String? worldId,
  }) {
    return db.createAttachment(
      taskId: taskId,
      worldId: worldId ?? WorldId.create().value,
      filename: filename,
      content: content ?? Uint8List.fromList([1, 2, 3]),
    );
  }

  Future<ProviderContainer> pumpPanel(
    WidgetTester tester, {
    SyncService? sync,
  }) async {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        if (sync != null) syncServiceProvider.overrideWithValue(sync),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              child: AttachmentsPanel(taskId: taskId),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('an image attachment shows a thumbnail and expands in place',
      (tester) async {
    await addAttachment('shot.png', content: png);
    await pumpPanel(tester);

    expect(find.byType(AttachmentThumbnail), findsOneWidget);
    expect(find.byType(AttachmentImagePreview), findsNothing,
        reason: 'the preview starts collapsed');

    // The thumbnail must read the BLOB, not just occupy the icon slot.
    final thumbnail = tester.widget<Image>(
      find.descendant(
        of: find.byType(AttachmentThumbnail),
        matching: find.byType(Image),
      ),
    );
    // ...and decode at tile size rather than at the photo's full resolution.
    expect(
      thumbnail.image,
      isA<ResizeImage>()
          .having((r) => r.imageProvider, 'imageProvider',
              isA<AttachmentImage>())
          .having((r) => r.policy, 'policy', ResizeImagePolicy.fit),
    );

    await tester.tap(find.byTooltip('Show preview'));
    await tester.pumpAndSettle();

    expect(find.byType(AttachmentImagePreview), findsOneWidget);

    await tester.tap(find.byTooltip('Hide preview'));
    await tester.pumpAndSettle();

    expect(find.byType(AttachmentImagePreview), findsNothing);
  });

  testWidgets('an audio attachment gets transport controls', (tester) async {
    await addAttachment('voice note.mp3');
    await pumpPanel(tester);

    expect(find.byType(AttachmentAudioBar), findsOneWidget);
    expect(find.byTooltip('Play'), findsOneWidget);

    // Nothing is loaded yet, so there is no duration to seek within and the
    // slider must not pretend otherwise.
    final slider = tester.widget<Slider>(find.byType(Slider));
    expect(slider.onChanged, isNull);
    expect(find.text('0:00 / 0:00'), findsOneWidget);

    // Audio rows are always live; they have nothing extra to expand.
    expect(find.byTooltip('Show preview'), findsNothing);
  });

  testWidgets('other file types keep the plain row', (tester) async {
    await addAttachment('notes.pdf');
    await pumpPanel(tester);

    expect(find.byType(AttachmentThumbnail), findsNothing);
    expect(find.byType(AttachmentAudioBar), findsNothing);
    expect(find.byTooltip('Show preview'), findsNothing);
    expect(find.text('notes.pdf'), findsOneWidget);
  });

  testWidgets('each attachment previews according to its own type',
      (tester) async {
    await addAttachment('shot.png', content: png);
    await addAttachment('voice note.mp3');
    await addAttachment('notes.pdf');
    await pumpPanel(tester);

    expect(find.byType(AttachmentThumbnail), findsOneWidget);
    expect(find.byType(AttachmentAudioBar), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(3));
  });

  /// Open the row menu and choose Delete.
  Future<void> chooseDelete(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
  }

  group('deleting', () {
    testWidgets('an image the note still shows is refused', (tester) async {
      final imageWorldId = WorldId.create().value;
      await addAttachment('shot.png', content: png, worldId: imageWorldId);
      await db.updateTask(
        taskId,
        content: jsonEncode([
          {'insert': 'see '},
          {'insert': {'image': attachmentUri(imageWorldId)}},
          {'insert': '\n'},
        ]),
      );
      await pumpPanel(tester);

      await chooseDelete(tester);

      // Told why, with no Delete to confirm: the embed would otherwise turn
      // into "Image not available" with nothing to say what happened.
      expect(find.text('Image is in the note'), findsOneWidget);
      expect(find.text('Delete attachment?'), findsNothing);
      await tester.tap(find.widgetWithText(FilledButton, 'OK'));
      await tester.pumpAndSettle();

      expect((await db.getAttachmentByWorldId(imageWorldId))?.removed, 0);
      expect(find.text('shot.png'), findsOneWidget);
    });

    testWidgets('the check reads the editor, not just the stored note',
        (tester) async {
      final imageWorldId = WorldId.create().value;
      await addAttachment('shot.png', content: png, worldId: imageWorldId);

      // The stored content has no image; the open editor does, and has not
      // auto-saved yet. The panel asks it to before looking.
      var flushed = false;
      final container = await pumpPanel(tester);
      container.read(editorFlushProvider.notifier).value = () async {
        flushed = true;
        await db.updateTask(
          taskId,
          content: jsonEncode([
            {'insert': {'image': attachmentUri(imageWorldId)}},
            {'insert': '\n'},
          ]),
        );
      };

      await chooseDelete(tester);

      expect(flushed, isTrue);
      expect(find.text('Image is in the note'), findsOneWidget);
    });

    testWidgets('an image the note no longer shows deletes after confirming',
        (tester) async {
      final imageWorldId = WorldId.create().value;
      await addAttachment('shot.png', content: png, worldId: imageWorldId);
      await db.updateTask(
        taskId,
        content: jsonEncode([
          {'insert': 'no pictures here\n'},
        ]),
      );
      await pumpPanel(tester);

      await chooseDelete(tester);
      expect(find.text('Delete attachment?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect((await db.getAttachmentByWorldId(imageWorldId))?.removed, 1);
    });
  });

  testWidgets('the download dialog comes down by its own route',
      (tester) async {
    // An attachment whose bytes have not arrived: a row with a hash and no
    // content, which is what a tap on it asks the sync service to fetch.
    final id = await db.createAttachmentFromRemote(
      taskId: taskId,
      worldId: WorldId.create().value,
      remoteTimestamp: DateTime.now().toUtc().toIso8601String(),
    );
    await db.markAttachmentPendingBlob(
      id,
      'a' * 64,
      remoteTimestamp: DateTime.now().toUtc().toIso8601String(),
    );
    final sync = _SlowFetch(db);
    await pumpPanel(tester, sync: sync);

    // A tap on a plain file row exports it, which needs the bytes first.
    await tester.tap(find.byType(ListTile));
    await tester.pump();
    await tester.pump();
    expect(find.text('Downloading attachment…'), findsOneWidget);

    // Something else opens over the progress dialog while the fetch runs —
    // the F5 sync dialog, the close-button prompt.
    // (Fixed pumps throughout: the spinner animates for as long as the
    // progress dialog is up, so pumpAndSettle would never return.)
    final panelContext = tester.element(find.byType(AttachmentsPanel));
    unawaited(showDialog<void>(
      context: panelContext,
      builder: (_) => const AlertDialog(title: Text('On top')),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('On top'), findsOneWidget);

    sync.finish(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Downloading attachment…'), findsNothing,
        reason: 'the progress dialog is the one that goes');
    expect(find.text('On top'), findsOneWidget,
        reason: 'the route pushed over it is not the one popped');
  });
}

/// A sync service whose attachment fetch waits until the test releases it.
class _SlowFetch extends SyncService {
  _SlowFetch(NooDatabase db)
      : super(
          db: db,
          config: const SyncConfig(
            enabled: true,
            serverUrl: 'https://sync.example.com',
            username: 'alice',
            deviceId: 'device-a',
          ),
          crypto: SyncCrypto(),
          historyService: HistoryService(db),
          databasePassword: 'pw',
        );

  final _completer = Completer<bool>();

  void finish(bool fetched) => _completer.complete(fetched);

  @override
  Future<bool> fetchAttachmentNow(int attachmentId) => _completer.future;
}
