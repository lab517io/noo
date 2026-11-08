import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/platform_info.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/screens/task_editor_screen.dart';
import 'package:noo/presentation/widgets/task_tree/task_tree_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// On a compact (phone) layout a tap on a tile opens the full-screen editor,
/// because there is no second pane to show it in. The expand/collapse chevron
/// lives inside that same tile and reacts on pointer-down, so its tap used to
/// reach the tile as well and every expand dropped the user into the editor.
void main() {
  late NooDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = NooDatabase.memory();
    // Tiles only take taps on touch platforms; elsewhere the whole-tile
    // Draggable claims the pointer and nothing here would fire.
    debugIsMobilePlatformOverride = true;
  });

  tearDown(() async {
    debugIsMobilePlatformOverride = null;
    await db.close();
  });

  /// Panel at phone width, so [TaskTreePanel] wires up editor navigation.
  Future<ProviderContainer> pumpCompactPanel(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          // The editor screen this navigates to is Quill-based and asserts on
          // its localizations, exactly as the real app supplies them.
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: MediaQuery(
            data: const MediaQueryData(size: Size(400, 800)),
            child: const Scaffold(
              body: SizedBox(width: 400, child: TaskTreePanel()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// A parent holding one child, both named, nothing left in rename mode.
  Future<void> buildParentWithChild(WidgetTester tester) async {
    await tester.tap(find.byTooltip('New task (Ctrl+N)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Parent');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('New child task (Ctrl+Shift+N)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Child');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  /// A tap completes only after [kDoubleTapTimeout], because the tile also
  /// listens for a double tap. That timer schedules no frame, so pumpAndSettle
  /// alone returns before the tap has been dispatched.
  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  }

  testWidgets('tapping the chevron collapses without opening the editor',
      (tester) async {
    await pumpCompactPanel(tester);
    await buildParentWithChild(tester);
    expect(find.text('Child'), findsOneWidget);

    await tapAndSettle(tester, find.byIcon(Icons.expand_more));

    expect(find.text('Child'), findsNothing, reason: 'node should collapse');
    expect(find.byType(TaskEditorScreen), findsNothing);

    // And back open, still without navigating.
    await tapAndSettle(tester, find.byIcon(Icons.chevron_right));

    expect(find.text('Child'), findsOneWidget);
    expect(find.byType(TaskEditorScreen), findsNothing);
  });

  testWidgets('tapping the title still opens the editor', (tester) async {
    await pumpCompactPanel(tester);
    await buildParentWithChild(tester);

    await tapAndSettle(tester, find.text('Child'));

    expect(find.byType(TaskEditorScreen), findsOneWidget);
  });

  testWidgets('double-tapping the chevron toggles instead of renaming',
      (tester) async {
    await pumpCompactPanel(tester);
    await buildParentWithChild(tester);

    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    expect(find.text('Child'), findsOneWidget, reason: 'expanded again');
    expect(find.byType(TextField), findsNothing, reason: 'no inline rename');
  });
}
