import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/screens/task_editor_screen.dart';
import 'package:noo/presentation/widgets/status_bar/status_bar.dart';
import 'package:noo/presentation/widgets/attachments/attachments_panel.dart';
import 'package:noo/presentation/widgets/task_editor/task_editor_panel.dart';
import 'package:noo/presentation/widgets/time_tracking/time_stats_panel.dart';
import 'package:noo/presentation/widgets/time_tracking/timeline_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The phone task screen carries everything about the node, because the status
/// bar that owns those controls on a desktop lives on the tree screen — one
/// route back from here. Without the tabs there is no way to reach a task's
/// time or files at all once you have opened it.
void main() {
  late NooDatabase db;
  late int taskId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = NooDatabase.memory();
    taskId = await db.createTask(
      worldId: WorldId.create().value,
      title: 'Budget review',
    );
  });

  tearDown(() async {
    await db.close();
  });

  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    // A phone: the screen only ever exists in a compact layout.
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    container.read(selectedTaskIdProvider.notifier).value = taskId;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [FlutterQuillLocalizations.delegate],
          home: TaskEditorScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  testWidgets('opens on the note, with the task title in the app bar', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Budget review'), findsOneWidget);
    expect(find.byType(TaskEditorPanel), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Time tab shows the totals and the individual records', (
    tester,
  ) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();

    expect(find.byType(TimeStatsPanel), findsOneWidget);
    expect(find.byType(TimelineView), findsOneWidget);
    // The timeline's own commands — on a desktop these sit in a column beside
    // the tree, which a phone has no width for.
    expect(find.widgetWithText(FilledButton, 'Add'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Remove'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the Files tab lists attachments and offers Add', (tester) async {
    await db.createAttachment(
      taskId: taskId,
      worldId: WorldId.create().value,
      filename: 'notes.md',
      content: Uint8List.fromList([1, 2, 3]),
    );

    await pumpScreen(tester);
    // The count rides on the tab label, as it did on the status bar chip.
    expect(find.text('Files (1)'), findsOneWidget);

    await tester.tap(find.text('Files (1)'));
    await tester.pumpAndSettle();

    expect(find.byType(AttachmentsPanel), findsOneWidget);
    expect(find.text('notes.md'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Add'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tracking starts and stops from the app bar', (tester) async {
    final container = await pumpScreen(tester);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pumpAndSettle();
    expect(container.read(activeTrackingTaskIdProvider), taskId);

    await tester.tap(find.byIcon(Icons.stop));
    await tester.pumpAndSettle();
    expect(container.read(activeTrackingTaskIdProvider), isNull);

    // The stopped session is a record on the node now, not just a cleared
    // provider — the Time tab is where the user goes to confirm that.
    final records = await db.getTimelineForTask(taskId);
    expect(records, hasLength(1));
    expect(records.single.endTime, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the tree screen\'s status bar opens the tab its chip describes',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    container.read(selectedTaskIdProvider.notifier).value = taskId;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [FlutterQuillLocalizations.delegate],
          home: Scaffold(body: Column(children: [Spacer(), StatusBar()])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Also guards the bar's own width: the node path used to run off the
    // screen, because only the ancestor half of it could ellipsize.
    expect(tester.takeException(), isNull);

    // On a phone the chip cannot fold a section out under an editor that is a
    // route away, so it navigates to that section instead.
    await tester.tap(find.byIcon(Icons.attach_file));
    await tester.pumpAndSettle();

    expect(find.byType(TaskEditorScreen), findsOneWidget);
    expect(find.byType(AttachmentsPanel), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // Typing on a phone: the keyboard takes about 300dp, and the chrome above
  // the note used to take most of what was left.
  group('while typing', () {
    void showKeyboard(WidgetTester tester) {
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    }

    testWidgets('the tab bar goes away on the Notes tab and comes back after',
        (tester) async {
      await pumpScreen(tester);
      expect(find.byType(TabBar), findsOneWidget);

      showKeyboard(tester);
      await tester.pumpAndSettle();
      expect(find.byType(TabBar), findsNothing);

      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(find.byType(TabBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the tab bar stays on the other tabs', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('Time'));
      await tester.pumpAndSettle();

      // The keyboard can still be up after a swipe away from the note — the
      // editor is kept alive, focus and all.
      showKeyboard(tester);
      await tester.pumpAndSettle();
      expect(find.byType(TabBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'the formatting toolbar shows only while the note has focus, '
        'under the text', (tester) async {
      await pumpScreen(tester);
      // Reading, not writing: no toolbar.
      expect(find.byType(QuillSimpleToolbar), findsNothing);

      await tester.tap(find.byType(QuillEditor));
      await tester.pumpAndSettle();
      expect(find.byType(QuillSimpleToolbar), findsOneWidget);
      // At the bottom, where the keyboard inset puts it on top of the keyboard.
      expect(
        tester.getTopLeft(find.byType(QuillSimpleToolbar)).dy,
        greaterThan(tester.getBottomLeft(find.byType(QuillEditor)).dy),
      );

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.byType(QuillSimpleToolbar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the toolbar outlives a route one of its buttons opened',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byType(QuillEditor));
      await tester.pumpAndSettle();

      // What the header menu, the colour picker and the link dialog all do:
      // push a route, which takes focus away from the editor.
      showDialog<void>(
        context: tester.element(find.byType(QuillSimpleToolbar)),
        builder: (_) => const AlertDialog(content: Text('picker')),
      );
      await tester.pumpAndSettle();
      expect(find.text('picker'), findsOneWidget);
      expect(FocusManager.instance.primaryFocus?.context?.widget,
          isNot(isA<QuillEditor>()));
      expect(find.byType(QuillSimpleToolbar), findsOneWidget);

      // And when the route closes without handing focus back, it goes.
      Navigator.of(tester.element(find.text('picker'))).pop();
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      expect(find.byType(QuillSimpleToolbar), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
