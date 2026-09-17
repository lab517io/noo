import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/widgets/task_tree/task_tree_panel.dart';
import 'package:noo/presentation/widgets/task_tree/tree_node.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A newly created task has no title, so the tree hands it straight to the
/// user: selected and with its label in inline rename mode, keyboard focus
/// included. These tests cover both entry points — the tile does not exist yet
/// when a task is created, so the "already editing on first build" path is the
/// one that matters.
void main() {
  late NooDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = NooDatabase.memory();
  });

  tearDown(() async {
    await db.close();
  });

  Future<ProviderContainer> pumpPanel(
    WidgetTester tester, {
    double? height,
  }) async {
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
              width: 400,
              height: height,
              child: const TaskTreePanel(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// The tree's own scroll position (the inline editor has a scrollable of its
  /// own, so this deliberately looks inside the tree view).
  ScrollPosition treePosition(WidgetTester tester) {
    return tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byType(AnimatedTreeView<TaskTreeNode>),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position;
  }

  /// Fill the tree with [count] untitled roots without going through the
  /// panel, so the scroll position is left wherever the test put it.
  Future<void> seedRoots(
    WidgetTester tester,
    ProviderContainer container,
    int count,
  ) async {
    final controller = container.read(taskTreeControllerProvider)!;
    for (var i = 0; i < count; i++) {
      await controller.createTask();
    }
    await tester.pumpAndSettle();
  }

  /// Asserts the inline editor is inside the tree's viewport, i.e. the user can
  /// actually see the node they are being asked to name.
  void expectEditorOnScreen(WidgetTester tester) {
    final viewport = tester.getRect(find.byType(AnimatedTreeView<TaskTreeNode>));
    final editor = tester.getRect(find.byType(TextField));
    expect(editor.top, greaterThanOrEqualTo(viewport.top - 0.5));
    expect(
      editor.bottom,
      lessThanOrEqualTo(viewport.bottom + 0.5),
    );
  }

  /// The inline title editor, asserted to be the only one on screen.
  TextField editingField(WidgetTester tester) {
    final finder = find.byType(TextField);
    expect(finder, findsOneWidget);
    return tester.widget<TextField>(finder);
  }

  testWidgets('new top-level task opens its title for editing, focused',
      (tester) async {
    final container = await pumpPanel(tester);

    await tester.tap(find.byTooltip('New task (Ctrl+N)'));
    await tester.pumpAndSettle();

    expect(container.read(selectedTaskIdProvider), isNotNull);
    expect(editingField(tester).focusNode?.hasFocus, isTrue);

    // Typing names the new node without any extra click.
    await tester.enterText(find.byType(TextField), 'Groceries');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(find.text('Groceries'), findsOneWidget);
  });

  testWidgets('new child task opens its title for editing, focused',
      (tester) async {
    final container = await pumpPanel(tester);

    // Parent first.
    await tester.tap(find.byTooltip('New task (Ctrl+N)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Parent');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final parentId = container.read(selectedTaskIdProvider);
    expect(parentId, isNotNull);

    await tester.tap(find.byTooltip('New child task (Ctrl+Shift+N)'));
    await tester.pumpAndSettle();

    // The child is what's selected and what's being renamed — not the parent.
    expect(container.read(selectedTaskIdProvider), isNot(parentId));
    expect(editingField(tester).focusNode?.hasFocus, isTrue);

    await tester.enterText(find.byType(TextField), 'Milk');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Parent'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
  });

  testWidgets('Ctrl+N and Ctrl+Shift+N create through the same path',
      (tester) async {
    final container = await pumpPanel(tester);
    final actions = container.read(taskCreationProvider);
    expect(actions, isNotNull, reason: 'tree should publish its creation hooks');

    // Ctrl+N: a top-level task, selected and open for renaming.
    await actions!.createTask();
    await tester.pumpAndSettle();
    expect(editingField(tester).focusNode?.hasFocus, isTrue);
    await tester.enterText(find.byType(TextField), 'Parent');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    final parentId = container.read(selectedTaskIdProvider);

    // Ctrl+Shift+N: a child of the selection.
    await actions.createChildTask();
    await tester.pumpAndSettle();
    expect(container.read(selectedTaskIdProvider), isNot(parentId));
    expect(editingField(tester).focusNode?.hasFocus, isTrue);
    await tester.enterText(find.byType(TextField), 'Child');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Child'), findsOneWidget);
    expect(container.read(taskTreeControllerProvider)!.roots, hasLength(1));
  });

  testWidgets('creating while renaming keeps the in-progress name',
      (tester) async {
    final container = await pumpPanel(tester);
    final actions = container.read(taskCreationProvider)!;

    await actions.createTask();
    await tester.pumpAndSettle();

    // Type a name but don't commit it — then hit the shortcut again, which
    // moves edit mode to the new node.
    await tester.enterText(find.byType(TextField), 'Half typed');
    await actions.createTask();
    await tester.pumpAndSettle();

    // The first node kept what was typed, and the second one is now editing.
    expect(find.text('Half typed'), findsOneWidget);
    expect(editingField(tester).focusNode?.hasFocus, isTrue);
    expect(container.read(taskTreeControllerProvider)!.roots, hasLength(2));
  });

  testWidgets('a new node just below the fold is scrolled into view',
      (tester) async {
    final container = await pumpPanel(tester, height: 300);
    await seedRoots(tester, container, 10);

    treePosition(tester).jumpTo(0);
    await tester.pumpAndSettle();

    await container.read(taskCreationProvider)!.createTask();
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expectEditorOnScreen(tester);
    // The new node is the last row, so the smallest scroll that reveals it
    // lands at the very bottom of the list.
    final position = treePosition(tester);
    expect(position.pixels, closeTo(position.maxScrollExtent, 1));
  });

  testWidgets('a new node far outside the build window is scrolled into view',
      (tester) async {
    final container = await pumpPanel(tester, height: 300);
    // Far more rows than the viewport plus the sliver's cache extent, so the
    // tile for the new node does not exist until the tree scrolls to it.
    await seedRoots(tester, container, 60);

    treePosition(tester).jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);

    await container.read(taskCreationProvider)!.createTask();
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expectEditorOnScreen(tester);
    expect(treePosition(tester).pixels, greaterThan(0));
  });

  testWidgets('a new child of an off-screen parent is scrolled into view',
      (tester) async {
    final container = await pumpPanel(tester, height: 300);
    await seedRoots(tester, container, 60);

    final controller = container.read(taskTreeControllerProvider)!;
    final lastRootId = controller.roots.last.id!;
    container.read(selectedTaskIdProvider.notifier).value = lastRootId;

    treePosition(tester).jumpTo(0);
    await tester.pumpAndSettle();

    // Not awaited: creation waits for the frame that brings the parent's row
    // into the list, and only the tester produces frames here.
    unawaited(container.read(taskCreationProvider)!.createChildTask());
    await tester.pumpAndSettle();

    expect(container.read(selectedTaskIdProvider), isNot(lastRootId));
    expect(find.byType(TextField), findsOneWidget);
    expectEditorOnScreen(tester);
    expect(editingField(tester).focusNode?.hasFocus, isTrue);
  });

  testWidgets('renaming an already visible node does not move the tree',
      (tester) async {
    final container = await pumpPanel(tester, height: 300);
    await seedRoots(tester, container, 60);

    treePosition(tester).jumpTo(0);
    await tester.pumpAndSettle();

    // Double-tap the top row to rename it: it is already on screen, so
    // showOnScreen must leave the scroll position alone.
    await tester.tap(find.text('Untitled').first);
    await tester.pump(kDoubleTapMinTime);
    await tester.tap(find.text('Untitled').first);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(treePosition(tester).pixels, 0);
  });

  testWidgets('creation hooks are unregistered when the tree goes away',
      (tester) async {
    final container = await pumpPanel(tester);
    expect(container.read(taskCreationProvider), isNotNull);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: SizedBox())),
      ),
    );
    await tester.pumpAndSettle();

    expect(container.read(taskCreationProvider), isNull);
  });
}
