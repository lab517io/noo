import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/domain/entities/world_id.dart';
import 'package:noo/presentation/widgets/task_tree/task_tree_controller.dart';

/// Moving a task one step at a time: up, down, out to its parent's level and
/// in under the sibling above — the tree's context menu and Alt+Shift+arrows.
void main() {
  late NooDatabase db;

  setUp(() => db = NooDatabase.memory());
  tearDown(() => db.close());

  Future<int> createTask(String title, {int? parent, int order = 0}) =>
      db.createTask(
        parentId: parent,
        worldId: WorldId.create().toString(),
        title: title,
        orderId: order,
      );

  Future<TaskTreeController> loadedController() async {
    final controller = TaskTreeController(db);
    addTearDown(controller.dispose);
    await controller.loadTree();
    return controller;
  }

  List<String> titles(List<dynamic> nodes) =>
      [for (final n in nodes) n.title as String];

  /// Order as the database has it, read through a fresh controller — what the
  /// next run of the app (or another device) would see.
  Future<List<String>> persistedRoots() async =>
      titles((await loadedController()).roots);

  test('up and down swap with the neighbouring sibling and persist', () async {
    await createTask('a', order: 0);
    final b = await createTask('b', order: 1);
    await createTask('c', order: 2);
    final controller = await loadedController();

    expect(await controller.moveUp(b), isTrue);
    expect(titles(controller.roots), ['b', 'a', 'c']);
    expect(await persistedRoots(), ['b', 'a', 'c']);

    expect(await controller.moveDown(b), isTrue);
    expect(await controller.moveDown(b), isTrue);
    expect(titles(controller.roots), ['a', 'c', 'b']);
    expect(await persistedRoots(), ['a', 'c', 'b']);
  });

  test('moves that would do nothing are reported unavailable', () async {
    final a = await createTask('a', order: 0);
    final b = await createTask('b', order: 1);
    final child = await createTask('child', parent: a);
    final controller = await loadedController();

    expect(controller.canMove(a, TaskMove.up), isFalse);
    expect(controller.canMove(a, TaskMove.underPrevious), isFalse);
    expect(controller.canMove(a, TaskMove.toParentLevel), isFalse);
    expect(controller.canMove(b, TaskMove.down), isFalse);
    expect(controller.canMove(child, TaskMove.up), isFalse);
    expect(controller.canMove(child, TaskMove.down), isFalse);
    expect(controller.canMove(child, TaskMove.toParentLevel), isTrue);

    expect(await controller.moveUp(a), isFalse);
    expect(await controller.moveDown(b), isFalse);
    expect(await controller.moveToParentLevel(a), isFalse);
    expect(titles(controller.roots), ['a', 'b']);
  });

  test('to parent level lands right after the old parent', () async {
    final a = await createTask('a', order: 0);
    await createTask('b', order: 1);
    await createTask('first', parent: a, order: 0);
    final second = await createTask('second', parent: a, order: 1);
    final controller = await loadedController();

    expect(await controller.moveToParentLevel(second), isTrue);

    expect(titles(controller.roots), ['a', 'second', 'b']);
    expect(titles(controller.findNode(a)!.children), ['first']);
    expect(controller.findNode(second)!.parentId, isNull);
    expect(await persistedRoots(), ['a', 'second', 'b']);
  });

  test('under previous appends to the sibling above and shows it', () async {
    final a = await createTask('a', order: 0);
    final b = await createTask('b', order: 1);
    await createTask('existing', parent: a);
    final controller = await loadedController();
    expect(controller.isExpanded(controller.findNode(a)!), isFalse);

    expect(await controller.moveUnderPrevious(b), isTrue);

    expect(titles(controller.roots), ['a']);
    expect(titles(controller.findNode(a)!.children), ['existing', 'b']);
    expect(controller.isExpanded(controller.findNode(a)!), isTrue,
        reason: 'the moved task must not disappear into a collapsed parent');

    // And back out again: the inverse, for a last child.
    expect(await controller.moveToParentLevel(b), isTrue);
    expect(titles(controller.roots), ['a', 'b']);
  });

  test('a moved node and the sibling it displaced keep their expansion',
      () async {
    final a = await createTask('a', order: 0);
    final b = await createTask('b', order: 1);
    await createTask('a-child', parent: a);
    await createTask('b-child', parent: b);
    final controller = await loadedController();
    controller.expand(controller.findNode(a)!);
    controller.expand(controller.findNode(b)!);

    await controller.moveUp(b);

    // Nodes are replaced on every move, and expansion is keyed by node
    // identity — this used to collapse both.
    expect(controller.isExpanded(controller.findNode(a)!), isTrue);
    expect(controller.isExpanded(controller.findNode(b)!), isTrue);
  });
}
