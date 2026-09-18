import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
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

  Future<void> addAttachment(String filename, {Uint8List? content}) {
    return db.createAttachment(
      taskId: taskId,
      worldId: WorldId.create().value,
      filename: filename,
      content: content ?? Uint8List.fromList([1, 2, 3]),
    );
  }

  Future<void> pumpPanel(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
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
    expect(thumbnail.image, isA<AttachmentImage>());

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
}
