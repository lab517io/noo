import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/domain/entities/world_id.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/widgets/search/search_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Find over the whole database, as a modal dialog listing its matches.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NooDatabase db;
  late ProviderContainer container;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = NooDatabase.memory();
  });

  tearDown(() => db.close());

  Future<int> makeTask(String title, {String? content}) => db.createTask(
        worldId: WorldId.create().toString(),
        title: title,
        content: content,
      );

  Future<void> pumpHost(WidgetTester tester) async {
    container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showSearchDialog(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> search(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    // Past the debounce, then let the query land.
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
  }

  testWidgets('lists title and content matches in the dialog', (tester) async {
    await makeTask('Apple pie');
    await makeTask('Shopping',
        content: '[{"insert":"buy an apple tomorrow\\n"}]');
    await makeTask('Unrelated');

    await pumpHost(tester);
    await open(tester);
    expect(find.byType(SearchDialog), findsOneWidget);

    await search(tester, 'apple');

    expect(find.text('2 results'), findsOneWidget);
    expect(find.textContaining('Shopping', findRichText: true), findsOneWidget);
    expect(find.textContaining('Unrelated', findRichText: true), findsNothing);
  });

  testWidgets('says so when nothing matches', (tester) async {
    await makeTask('Apple pie');

    await pumpHost(tester);
    await open(tester);
    await search(tester, 'zebra');

    expect(find.text('No matches'), findsOneWidget);
  });

  testWidgets('Down then Enter opens the second match and closes the dialog',
      (tester) async {
    await makeTask('Apple one');
    final second = await makeTask('Apple two');

    await pumpHost(tester);
    await open(tester);
    await search(tester, 'apple');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.byType(SearchDialog), findsNothing);
    expect(container.read(selectedTaskIdProvider), second);
  });

  testWidgets('clicking a match selects that task', (tester) async {
    final id = await makeTask('Apple pie');

    await pumpHost(tester);
    await open(tester);
    await search(tester, 'apple');

    await tester.tap(find.textContaining('pie', findRichText: true));
    await tester.pumpAndSettle();

    expect(find.byType(SearchDialog), findsNothing);
    expect(container.read(selectedTaskIdProvider), id);
    // Left for the editor, which opens the note at the found text.
    final reveal = container.read(editorRevealProvider)!;
    expect(reveal.taskId, id);
    expect(reveal.query, 'apple');
  });

  testWidgets('reopening offers the last query again, with its matches',
      (tester) async {
    await makeTask('Apple pie');

    await pumpHost(tester);
    await open(tester);
    await search(tester, 'apple');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(SearchDialog), findsNothing);

    await open(tester);
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'apple');
    expect(field.controller!.selection,
        const TextSelection(baseOffset: 0, extentOffset: 5));
    expect(find.text('1 result'), findsOneWidget);
  });

  testWidgets('a second open while it is up does not stack another',
      (tester) async {
    await pumpHost(tester);
    await open(tester);

    final context = tester.element(find.byType(SearchDialog));
    showSearchDialog(context);
    await tester.pumpAndSettle();

    expect(find.byType(SearchDialog), findsOneWidget);
  });
}
