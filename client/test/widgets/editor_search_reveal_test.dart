import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/content_utils.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/widgets/task_editor/quill_editor_wrapper.dart';
import 'package:noo/presentation/widgets/task_editor/search_hint.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A match picked in the search dialog opens the note at the found text, not
/// at its top.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('findTextMatch', () {
    test('is case-insensitive and reports offsets into the text', () {
      final m = findTextMatch('Buy an APPLE tomorrow', 'apple')!;
      expect([m.start, m.end], [7, 12]);
    });

    test('treats the query literally, not as a pattern', () {
      expect(findTextMatch('costs 3.50 (net)', '(net)')!.start, 11);
      expect(findTextMatch('abc', 'a.c'), isNull);
    });

    test('falls back to the trimmed query', () {
      expect(findTextMatch('an apple', 'apple ')!.start, 3);
    });

    test('null when absent or empty', () {
      expect(findTextMatch('pear', 'apple'), isNull);
      expect(findTextMatch('pear', ''), isNull);
    });
  });

  late NooDatabase db;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = NooDatabase.memory();
  });

  tearDown(() => db.close());

  String note(String text) => jsonEncode([
        {'insert': '$text\n'},
      ]);

  final a = note('First note, nothing here.');
  final b = note('Second note.\nThe line with the apple is here.');

  /// The editor the way the panel drives it: one widget, reused across tasks.
  final props = ValueNotifier<({int taskId, String content, bool frozen})>(
      (taskId: 1, content: '', frozen: false));

  Future<void> pumpEditor(WidgetTester tester,
      {required int taskId, required String content}) async {
    props.value = (taskId: taskId, content: content, frozen: false);

    // Owned by the tree, so it outlives the editor's dispose — which still
    // reads it — instead of going first in the teardown.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          localizationsDelegates: const [FlutterQuillLocalizations.delegate],
          home: Scaffold(
            body: SizedBox(
              width: 600,
              height: 400,
              child: ValueListenableBuilder(
                valueListenable: props,
                builder: (context, p, _) => QuillEditorWrapper(
                  contentKey: p.taskId,
                  taskId: p.taskId,
                  initialContent: p.content,
                  frozen: p.frozen,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
        tester.element(find.byType(QuillEditorWrapper)));
  }

  QuillController controllerOf(WidgetTester tester) =>
      tester.widget<QuillEditor>(find.byType(QuillEditor)).controller;

  bool editorHasFocus(WidgetTester tester) =>
      tester.widget<QuillEditor>(find.byType(QuillEditor)).focusNode.hasFocus;

  void request(int taskId, String query) =>
      container.read(editorRevealProvider.notifier).value =
          EditorRevealRequest(taskId: taskId, query: query);

  TextSelection selectionOf(String text, String found) {
    final start = text.indexOf(found);
    return TextSelection(baseOffset: start, extentOffset: start + found.length);
  }

  testWidgets('switching to the requested task selects the match',
      (tester) async {
    await pumpEditor(tester, taskId: 1, content: a);

    request(2, 'APPLE');
    // The panel freezes the old document while the new one loads...
    props.value = (taskId: 1, content: a, frozen: true);
    await tester.pumpAndSettle();
    expect(controllerOf(tester).selection.isCollapsed, isTrue,
        reason: 'nothing to select in the document still on screen');

    // ...then hands over the requested one.
    props.value = (taskId: 2, content: b, frozen: false);
    await tester.pumpAndSettle();

    final controller = controllerOf(tester);
    expect(controller.selection,
        selectionOf(controller.document.toPlainText(), 'apple'));
    expect(editorHasFocus(tester), isTrue);
    expect(container.read(editorRevealProvider), isNull);
  });

  testWidgets('a match in the note already open is selected at once',
      (tester) async {
    await pumpEditor(tester, taskId: 2, content: b);

    request(2, 'line');
    await tester.pumpAndSettle();

    final controller = controllerOf(tester);
    expect(controller.selection,
        selectionOf(controller.document.toPlainText(), 'line'));
  });

  testWidgets('a title-only match leaves the caret at the top',
      (tester) async {
    await pumpEditor(tester, taskId: 1, content: a);

    request(2, 'Second note title');
    props.value = (taskId: 2, content: b, frozen: false);
    await tester.pumpAndSettle();

    expect(controllerOf(tester).selection,
        const TextSelection.collapsed(offset: 0));
    expect(container.read(editorRevealProvider), isNull);
  });

  testWidgets('a request for another task is left for that task',
      (tester) async {
    await pumpEditor(tester, taskId: 1, content: a);

    request(2, 'note');
    await tester.pumpAndSettle();

    expect(controllerOf(tester).selection.isCollapsed, isTrue);
    expect(container.read(editorRevealProvider), isNotNull);
  });

  Finder hint() => find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is SearchHintPainter);

  testWidgets('a match far down the note is scrolled to the middle',
      (tester) async {
    final lines = [for (var i = 0; i < 120; i++) 'line $i'];
    lines[80] = 'the needle is here';
    final long = note(lines.join('\n'));
    await pumpEditor(tester, taskId: 1, content: a);

    request(3, 'needle');
    props.value = (taskId: 3, content: long, frozen: false);
    await tester.pumpAndSettle();

    final editor = tester.getRect(find.byType(QuillEditor));
    final needle = tester.getRect(find.textContaining('needle',
        findRichText: true));
    expect((needle.center.dy - editor.center.dy).abs(), lessThan(40),
        reason: 'the found line sits near the vertical centre, '
            'not on the bottom edge');
  });

  testWidgets('a hint marks the match, then goes away', (tester) async {
    await pumpEditor(tester, taskId: 1, content: a);

    request(2, 'apple');
    props.value = (taskId: 2, content: b, frozen: false);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(hint(), findsOneWidget);

    await tester.pump(kSearchHintDuration);
    await tester.pumpAndSettle();
    expect(hint(), findsNothing);
  });

  testWidgets('typing drops the hint at once', (tester) async {
    await pumpEditor(tester, taskId: 2, content: b);

    request(2, 'apple');
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(hint(), findsOneWidget);

    controllerOf(tester).replaceText(0, 0, 'x', null);
    await tester.pump();
    expect(hint(), findsNothing);
  });
}
