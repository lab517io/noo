import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/widgets/task_tree/task_tree_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Opening a search result: the path to the task is expanded and its row is
/// scrolled on screen — including when the branch starts far below the fold,
/// where the expand animation of an unbuilt row would never finish and keep
/// the branch hidden.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NooDatabase db;
  late int deepId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = NooDatabase.memory();
    int? last;
    for (var i = 0; i < 80; i++) {
      last = await db.createTask(
        worldId: WorldId.create().value,
        title: 'Top $i',
        orderId: i,
      );
    }
    var parent = last!;
    for (var depth = 1; depth <= 3; depth++) {
      parent = await db.createTask(
        worldId: WorldId.create().value,
        parentId: parent,
        title: depth == 3 ? 'Deep match' : 'Level $depth',
        orderId: 0,
      );
    }
    deepId = parent;
  });

  tearDown(() async => db.close());

  testWidgets('a revealed task far down a collapsed branch ends up on screen',
      (tester) async {
    tester.view.physicalSize = const Size(400, 500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en')],
          home: Scaffold(body: TaskTreePanel()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Deep match'), findsNothing);

    final reveal = container.read(taskRevealProvider);
    expect(reveal, isNotNull, reason: 'the mounted tree publishes it');
    reveal!(deepId);
    await tester.pumpAndSettle();

    final row = find.text('Deep match');
    expect(row, findsOneWidget);
    final screen = Offset.zero & tester.view.physicalSize;
    expect(screen.contains(tester.getCenter(row)), isTrue,
        reason: 'the row is scrolled into view');
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Level 2'), findsOneWidget);
  });
}
