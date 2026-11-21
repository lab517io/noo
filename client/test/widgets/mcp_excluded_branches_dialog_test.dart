import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/domain/entities/task.dart';
import 'package:noo/domain/entities/world_id.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/widgets/dialogs/mcp_excluded_branches_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Picking the branches the MCP server may not see.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NooDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = NooDatabase.memory();
  });

  tearDown(() => db.close());

  Future<int> makeTask({required String title, int? parentId}) => db.createTask(
        parentId: parentId,
        worldId: WorldId.create().toString(),
        title: title,
        orderId: 0,
      );

  /// Opens the picker over a bare page, the way the MCP tab does.
  Future<void> openDialog(WidgetTester tester) async {
    final container = ProviderContainer(
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
                  onPressed: () => showMcpExcludedBranchesDialog(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder checkboxFor(String title) => find.ancestor(
        of: find.text(title),
        matching: find.byType(Row),
      );

  Future<void> tapRow(WidgetTester tester, String title) async {
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
  }

  Future<bool> isExcluded(int id) async =>
      ((await db.getTaskById(id))!.flags & TaskFlags.mcpExcluded) != 0;

  testWidgets('ticking a task and accepting hides that branch', (tester) async {
    final work = await makeTask(title: 'Work');

    await openDialog(tester);
    await tapRow(tester, 'Work');
    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await tester.pumpAndSettle();

    expect(await isExcluded(work), isTrue);
  });

  testWidgets('cancel writes nothing', (tester) async {
    final work = await makeTask(title: 'Work');

    await openDialog(tester);
    await tapRow(tester, 'Work');
    await tester.tap(find.widgetWithText(OutlinedButton, 'Cancel'));
    await tester.pumpAndSettle();

    // The whole point of staging: the Preferences dialog behind this one
    // restores preferences on its own Cancel, not the outline.
    expect(await isExcluded(work), isFalse);
  });

  testWidgets('unticking reveals a branch again', (tester) async {
    final work = await makeTask(title: 'Work');
    await db.setTaskMcpExcluded(work, true);

    await openDialog(tester);
    await tapRow(tester, 'Work');
    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await tester.pumpAndSettle();

    expect(await isExcluded(work), isFalse);
  });

  testWidgets('a hidden branch opens with its path expanded', (tester) async {
    final work = await makeTask(title: 'Work');
    final pay = await makeTask(title: 'Salaries', parentId: work);
    await db.setTaskMcpExcluded(pay, true);

    await openDialog(tester);

    // Collapsed, the dialog would answer "what did I hide" with a blank
    // screen.
    expect(find.text('Salaries'), findsOneWidget);
  });

  testWidgets('a descendant is ticked and locked by its hidden ancestor',
      (tester) async {
    final work = await makeTask(title: 'Work');
    final pay = await makeTask(title: 'Salaries', parentId: work);

    await openDialog(tester);
    await tapRow(tester, 'Work');

    // Hiding the parent reveals the subtree, so the greyed rows explain why
    // they cannot be ticked.
    expect(find.text('hidden with parent'), findsOneWidget);
    final child = tester.widget<Checkbox>(
      find.descendant(of: checkboxFor('Salaries'), matching: find.byType(Checkbox)),
    );
    expect(child.value, isTrue);
    expect(child.onChanged, isNull, reason: 'the flag belongs to the ancestor');

    // Tapping it does nothing, and only the ancestor is written.
    await tapRow(tester, 'Salaries');
    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await tester.pumpAndSettle();

    expect(await isExcluded(work), isTrue);
    expect(await isExcluded(pay), isFalse);
  });

  testWidgets('an untouched task is not rewritten', (tester) async {
    final work = await makeTask(title: 'Work');
    final other = await makeTask(title: 'Personal');
    final before = (await db.getTaskById(other))!.timestamp;

    await openDialog(tester);
    await tapRow(tester, 'Work');
    await tester.tap(find.widgetWithText(FilledButton, 'OK'));
    await tester.pumpAndSettle();

    expect(await isExcluded(work), isTrue);
    // Every write is a history row and a sync change; a dialog that rewrote
    // the whole outline on OK would put one on the wire per task.
    expect((await db.getTaskById(other))!.timestamp, before);
    expect(
      await db.getTaskHistory(other),
      isNot(contains(predicate((dynamic h) =>
          h.field == 'flags' && h.oldValue != null))),
    );
  });

  testWidgets('an empty outline says so rather than showing a blank list',
      (tester) async {
    await openDialog(tester);
    expect(find.text('This outline has no tasks yet.'), findsOneWidget);
  });
}
