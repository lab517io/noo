import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/domain/entities/world_id.dart';
import 'package:noo/presentation/widgets/task_tree/task_tree_controller.dart';

/// The tree remembers which nodes are expanded and which node has the focus,
/// per database, across runs of the app.
///
/// The interesting case is the focused node disappearing while it is stored:
/// sync applies deletions made on another device, so the node the user was
/// last on may simply not be there any more — at restore time, or live, in the
/// middle of a session. Both must land the focus on the nearest surviving
/// ancestor instead of leaving it pointing at a row that is gone.
void main() {
  late NooDatabase db;

  setUp(() => db = NooDatabase.memory());
  tearDown(() => db.close());

  Future<int> createTask(String title, {int? parent}) => db.createTask(
        parentId: parent,
        worldId: WorldId.create().toString(),
        title: title,
      );

  /// A controller wired the way the provider wires it, with the selection held
  /// in [selection] instead of Riverpod.
  ({TaskTreeController controller, List<int?> selectionRequests})
      buildController(int? Function() readSelection) {
    final requests = <int?>[];
    final controller = TaskTreeController(db)
      ..selectionReader = readSelection
      ..onSelectionChangeRequired = requests.add;
    addTearDown(controller.dispose);
    return (controller: controller, selectionRequests: requests);
  }

  test('restores the expansion set and the focused node', () async {
    final rootId = await createTask('root');
    final childId = await createTask('child', parent: rootId);
    final otherId = await createTask('other');

    int? selection;
    final first = buildController(() => selection);
    await first.controller.loadTree();
    first.controller.expand(first.controller.findNode(rootId)!);
    selection = childId;
    await first.controller.flushUiState();

    // Next run of the app, same database file.
    int? restoredSelection;
    final second = buildController(() => restoredSelection);
    await second.controller.loadTree();

    expect(second.controller.isExpanded(second.controller.findNode(rootId)!), isTrue);
    expect(second.controller.isExpanded(second.controller.findNode(otherId)!), isFalse);
    expect(second.selectionRequests, [childId]);
  });

  test('does not overrule a selection made before the load finished', () async {
    final rootId = await createTask('root');
    final childId = await createTask('child', parent: rootId);

    int? selection;
    final first = buildController(() => selection);
    await first.controller.loadTree();
    selection = childId;
    await first.controller.flushUiState();

    // A database opened from the command line can have a task selected (e.g.
    // by a search deep link) before the tree finishes loading.
    int? restoredSelection = rootId;
    final second = buildController(() => restoredSelection);
    await second.controller.loadTree();

    expect(second.selectionRequests, isEmpty);
  });

  test('falls back to the nearest surviving ancestor when the focus was '
      'deleted while the app was closed', () async {
    final rootId = await createTask('root');
    final branchId = await createTask('branch', parent: rootId);
    final leafId = await createTask('leaf', parent: branchId);

    int? selection;
    final first = buildController(() => selection);
    await first.controller.loadTree();
    selection = leafId;
    await first.controller.flushUiState();

    // A sync run pulls a remote deletion of the branch (and with it the leaf)
    // straight into the database, exactly as SyncService applies it.
    await db.deleteTask(branchId);

    int? restoredSelection;
    final second = buildController(() => restoredSelection);
    await second.controller.loadTree();

    expect(second.selectionRequests, [rootId]);
    expect(second.controller.findNode(branchId), isNull);
  });

  test('asks for no focus when the whole stored ancestry is gone', () async {
    final rootId = await createTask('root');
    final childId = await createTask('child', parent: rootId);
    await createTask('survivor');

    int? selection;
    final first = buildController(() => selection);
    await first.controller.loadTree();
    selection = childId;
    await first.controller.flushUiState();

    await db.deleteTask(rootId);

    int? restoredSelection;
    final second = buildController(() => restoredSelection);
    await second.controller.loadTree();

    // Nothing to focus, and nothing was focused: the tree opens with an empty
    // selection rather than asking for a change it cannot make.
    expect(second.selectionRequests, isEmpty);
    expect(second.controller.findNode(rootId), isNull);
    expect(second.controller.findNode(childId), isNull);
  });

  test('moves the focus off a node a sync deletes mid-session', () async {
    final rootId = await createTask('root');
    final branchId = await createTask('branch', parent: rootId);
    final leafId = await createTask('leaf', parent: branchId);

    int? selection;
    final subject = buildController(() => selection);
    await subject.controller.loadTree();
    selection = leafId;

    // Remote deletion applied under the running app, then the post-sync
    // reload that SyncService triggers.
    await db.deleteTask(leafId);
    await subject.controller.loadTree();

    expect(subject.selectionRequests, [branchId]);
    // The ancestor is expanded, so the new focus is actually visible.
    expect(
      subject.controller.isExpanded(subject.controller.findNode(rootId)!),
      isTrue,
    );
  });

  test('leaves the focus alone when the node survives a reload', () async {
    final rootId = await createTask('root');
    final childId = await createTask('child', parent: rootId);

    int? selection;
    final subject = buildController(() => selection);
    await subject.controller.loadTree();
    selection = childId;

    await subject.controller.loadTree();

    expect(subject.selectionRequests, isEmpty);
  });

  test('keeps the stored focus when the selection is cleared on close',
      () async {
    final rootId = await createTask('root');
    final childId = await createTask('child', parent: rootId);

    int? selection;
    final first = buildController(() => selection);
    await first.controller.loadTree();
    selection = childId;
    await first.controller.flushUiState();
    // Closing a database clears the selection before the controller is torn
    // down; that must not wipe where the user was.
    selection = null;
    await first.controller.flushUiState();

    int? restoredSelection;
    final second = buildController(() => restoredSelection);
    await second.controller.loadTree();

    expect(second.selectionRequests, [childId]);
  });

  test('survives a corrupt stored payload', () async {
    final rootId = await createTask('root');
    await db.setProperty('ui_tree_state', 'not json at all');

    int? selection;
    final subject = buildController(() => selection);
    await subject.controller.loadTree();

    expect(subject.controller.findNode(rootId), isNotNull);
    expect(subject.selectionRequests, isEmpty);
  });
}
