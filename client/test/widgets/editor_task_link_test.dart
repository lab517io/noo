import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/task_link.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/widgets/task_editor/quill_editor_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Typing `[[` in a note offers the other tasks, and the one picked becomes
/// a link that opens it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NooDatabase db;
  late ProviderContainer container;
  late int here, report, annual, groceries;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = NooDatabase.memory();
    here = await db.createTask(worldId: 'w-here', title: 'Here');
    report = await db.createTask(worldId: 'w-report', title: 'Report Q3', orderId: 1);
    annual = await db.createTask(
        worldId: 'w-annual', title: 'Annual report', parentId: report);
    groceries =
        await db.createTask(worldId: 'w-groceries', title: 'Groceries', orderId: 2);
  });

  tearDown(() => db.close());

  Future<void> pumpEditor(WidgetTester tester, {String text = ''}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          localizationsDelegates: const [FlutterQuillLocalizations.delegate],
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: QuillEditorWrapper(
                contentKey: here,
                taskId: here,
                initialContent: text.isEmpty
                    ? null
                    : jsonEncode([
                        {'insert': '$text\n'},
                      ]),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
        tester.element(find.byType(QuillEditorWrapper)));
    // The list is only offered to a focused editor.
    tester.widget<QuillEditor>(find.byType(QuillEditor)).focusNode.requestFocus();
    await tester.pumpAndSettle();
  }

  QuillController controllerOf(WidgetTester tester) =>
      tester.widget<QuillEditor>(find.byType(QuillEditor)).controller;

  /// Types [text] at the caret the way the keyboard does, then lets the
  /// database answer.
  Future<void> type(WidgetTester tester, String text) async {
    final controller = controllerOf(tester);
    final at = controller.selection.extentOffset;
    controller.replaceText(
        at, 0, text, TextSelection.collapsed(offset: at + text.length));
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
  }

  List<dynamic> ops(WidgetTester tester) =>
      controllerOf(tester).document.toDelta().toJson();

  testWidgets('[[ lists the other tasks, narrowed by what follows',
      (tester) async {
    await pumpEditor(tester);

    await type(tester, 'see [[');
    // Once as a row, once as the path under its child.
    expect(find.text('Report Q3'), findsNWidgets(2));
    expect(find.text('Annual report'), findsOneWidget);
    expect(find.text('Groceries'), findsOneWidget);
    expect(find.text('Here'), findsNothing, reason: 'the note itself');

    await type(tester, 'rep');
    expect(find.text('Groceries'), findsNothing);
    // The ancestor path tells same-titled tasks apart.
    expect(find.text('Report Q3'), findsNWidgets(2));
  });

  testWidgets('Enter replaces the query with a link to the highlighted task',
      (tester) async {
    await pumpEditor(tester);
    await type(tester, 'see [[rep');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(ops(tester), [
      {'insert': 'see '},
      {
        'insert': 'Annual report',
        'attributes': {'link': taskLinkUri('w-annual')},
      },
      {'insert': '\n'},
    ]);
    expect(controllerOf(tester).selection,
        const TextSelection.collapsed(offset: 17));
    expect(find.text('Report Q3'), findsNothing, reason: 'the list is gone');

    // What is typed next is not part of the link.
    await type(tester, '!');
    expect((ops(tester)[2] as Map)['insert'], '!\n');
  });

  testWidgets('a tap picks a task too', (tester) async {
    await pumpEditor(tester);
    await type(tester, '[[gro');

    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();

    expect((ops(tester).first as Map)['attributes'],
        {'link': taskLinkUri('w-groceries')});
    expect(
        tester.widget<QuillEditor>(find.byType(QuillEditor)).focusNode.hasFocus,
        isTrue,
        reason: 'the caret stays in the note');
  });

  testWidgets('Escape dismisses the list for that query', (tester) async {
    await pumpEditor(tester);
    await type(tester, '[[re');
    expect(find.text('Report Q3'), findsWidgets);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Report Q3'), findsNothing);

    await type(tester, 'p');
    expect(find.text('Report Q3'), findsNothing);
    expect(controllerOf(tester).document.toPlainText(), '[[rep\n');
  });

  testWidgets('nothing matching shows nothing and leaves Enter alone',
      (tester) async {
    await pumpEditor(tester);
    await type(tester, '[[zzz');
    expect(find.byType(ListView), findsNothing);
  });

  testWidgets('brackets already in the note open nothing', (tester) async {
    await pumpEditor(tester, text: 'x = [[rep');
    controllerOf(tester).updateSelection(
        const TextSelection.collapsed(offset: 9), ChangeSource.local);
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
    expect(find.text('Report Q3'), findsNothing);
  });

  group('opening a link', () {
    Future<void> open(WidgetTester tester, String url) async {
      final launch = tester
          .widget<QuillEditor>(find.byType(QuillEditor))
          .config
          .onLaunchUrl!;
      await tester.runAsync(() async {
        launch(url);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
    }

    testWidgets('selects the linked task', (tester) async {
      await pumpEditor(tester);
      await open(tester, taskLinkUri('w-annual'));
      expect(container.read(selectedTaskIdProvider), annual);
    });

    testWidgets('says so when the task is gone', (tester) async {
      await pumpEditor(tester);
      await tester.runAsync(() => db.deleteTask(groceries));

      await open(tester, taskLinkUri('w-groceries'));
      expect(find.text('The linked task no longer exists.'), findsOneWidget);
      expect(container.read(selectedTaskIdProvider), isNot(groceries));

      await open(tester, taskLinkUri('never-existed'));
      expect(container.read(selectedTaskIdProvider), isNull);
    });
  });
}
