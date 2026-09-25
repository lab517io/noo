import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/menu_shortcuts.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/widgets/task_editor/task_editor_panel.dart';
import 'package:noo/presentation/widgets/task_tree/task_tree_controller.dart';
import 'package:noo/presentation/widgets/task_tree/task_tree_panel.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The tree's move commands as the user reaches them: the row's context menu,
/// and Alt+Shift+arrows pressed while typing in the note.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late NooDatabase db;
  late int alphaId;
  late int betaId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = NooDatabase.memory();
    alphaId = await db.createTask(
      worldId: WorldId.create().value,
      title: 'Alpha',
      orderId: 0,
    );
    betaId = await db.createTask(
      worldId: WorldId.create().value,
      title: 'Beta',
      orderId: 1,
    );
  });

  tearDown(() async => db.close());

  Future<void> onDesktop(Future<void> Function() body) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      await body();
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  /// Tree and editor side by side, with the move shortcuts bound above them
  /// the way MainScreen binds them.
  Future<ProviderContainer> pumpWide(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(container.dispose);
    container.read(selectedTaskIdProvider.notifier).value = betaId;

    Future<void>? move(TaskMove m) => container.read(taskMoveProvider)?.call(m);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en')],
          home: CallbackShortcuts(
            bindings: {
              treeMoveActivator(LogicalKeyboardKey.arrowUp): () =>
                  move(TaskMove.up),
              treeMoveActivator(LogicalKeyboardKey.arrowDown): () =>
                  move(TaskMove.down),
              treeMoveActivator(LogicalKeyboardKey.arrowLeft): () =>
                  move(TaskMove.toParentLevel),
              treeMoveActivator(LogicalKeyboardKey.arrowRight): () =>
                  move(TaskMove.underPrevious),
            },
            child: const Scaffold(
              body: Row(
                children: [
                  SizedBox(width: 300, child: TaskTreePanel()),
                  Expanded(child: TaskEditorPanel()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// Titles of the top-level tasks, in the order they are drawn.
  List<String> drawnOrder(WidgetTester tester) {
    final rows = ['Alpha', 'Beta']
        .where((t) => find.text(t).evaluate().isNotEmpty)
        .toList()
      ..sort((a, b) => tester
          .getTopLeft(find.text(a))
          .dy
          .compareTo(tester.getTopLeft(find.text(b)).dy));
    return rows;
  }

  Future<void> rightClick(WidgetTester tester, Finder finder) async {
    final gesture = await tester.startGesture(
      tester.getCenter(finder),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();
  }

  testWidgets('the context menu moves the row it was opened on',
      (tester) async {
    await onDesktop(() async {
      final container = await pumpWide(tester);
      expect(drawnOrder(tester), ['Alpha', 'Beta']);

      await rightClick(tester, find.text('Alpha'));
      expect(find.text('Alt+Shift+↓'), findsOneWidget,
          reason: 'the menu names the shortcut');
      await tester.tap(find.text('Move down'));
      await tester.pumpAndSettle();

      expect(drawnOrder(tester), ['Beta', 'Alpha']);
      expect(container.read(selectedTaskIdProvider), betaId,
          reason: 'moving a row is not a reason to change the selection');
    });
  });

  testWidgets('entries that would do nothing are disabled', (tester) async {
    await onDesktop(() async {
      await pumpWide(tester);

      await rightClick(tester, find.text('Alpha'));

      PopupMenuItem<String> item(String label) =>
          tester.widget<PopupMenuItem<String>>(find.ancestor(
            of: find.text(label),
            matching: find.byType(PopupMenuItem<String>),
          ));
      expect(item('Move up').enabled, isFalse);
      expect(item('Move to parent level').enabled, isFalse);
      expect(item('Move under previous').enabled, isFalse);
      expect(item('Move down').enabled, isTrue);
    });
  });

  testWidgets('Alt+Shift+arrows move the selected task while the editor '
      'has focus', (tester) async {
    await onDesktop(() async {
      final container = await pumpWide(tester);
      final controller = container.read(taskTreeControllerProvider)!;

      // Focus the note, where the keyboard is while working in the tree.
      final editor = tester.getRect(find.byType(QuillEditor));
      final gesture = await tester.startGesture(
        Offset(editor.left + 20, editor.top + 20),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        tester.widget<QuillEditor>(find.byType(QuillEditor)).focusNode.hasFocus,
        isTrue,
      );

      Future<void> press(LogicalKeyboardKey arrow) async {
        await tester.runAsync(() async {
          await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyEvent(arrow);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
          // The move writes to the database before the tree updates.
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();
      }

      await press(LogicalKeyboardKey.arrowUp);
      expect(drawnOrder(tester), ['Beta', 'Alpha']);

      await press(LogicalKeyboardKey.arrowDown);
      expect(drawnOrder(tester), ['Alpha', 'Beta']);

      await press(LogicalKeyboardKey.arrowRight);
      expect(controller.findNode(betaId)!.parentId, alphaId);
      expect(find.text('Beta'), findsOneWidget,
          reason: 'Alpha is expanded so the moved task stays visible');

      await press(LogicalKeyboardKey.arrowLeft);
      expect(controller.findNode(betaId)!.parentId, isNull);
      expect(drawnOrder(tester), ['Alpha', 'Beta']);
    });
  });
}
