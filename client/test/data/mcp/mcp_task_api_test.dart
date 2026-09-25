import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/content_utils.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/mcp/mcp_task_api.dart';
import 'package:noo/data/services/mcp/mcp_tools.dart';
import 'package:noo/domain/entities/task.dart';
import 'package:noo/domain/entities/world_id.dart';

/// The semantics an agent actually sees, exercised without a socket so a
/// failure points at the tool rather than the transport.
void main() {
  late NooDatabase db;
  late McpTaskApi api;

  setUp(() {
    db = NooDatabase.memory();
    api = McpTaskApi(db);
  });

  tearDown(() => db.close());

  /// Create a task and return its worldId, the id everything MCP speaks in.
  Future<String> makeTask({
    String title = 'Task',
    String? parentWorldId,
    String? content,
    int orderId = 0,
  }) async {
    final worldId = WorldId.create().toString();
    int? parentId;
    if (parentWorldId != null) {
      parentId = (await db.getTaskByWorldId(parentWorldId))!.id;
    }
    await db.createTask(
      parentId: parentId,
      worldId: worldId,
      orderId: orderId,
      title: title,
      content: content,
    );
    return worldId;
  }

  Future<Map<String, dynamic>> callOk(
    String tool,
    Map<String, Object?> args, {
    bool readOnly = false,
  }) async {
    final result = await api.call(tool, args, readOnly: readOnly);
    expect(result.isError, isFalse, reason: result.text);
    return jsonDecode(result.text) as Map<String, dynamic>;
  }

  Future<McpToolResult> callRaw(
    String tool,
    Map<String, Object?> args, {
    bool readOnly = false,
  }) =>
      api.call(tool, args, readOnly: readOnly);

  group('argument handling', () {
    test('an unknown tool is an error the agent can read, not an exception',
        () async {
      final result = await callRaw('noo_nope', {});
      expect(result.isError, isTrue);
      expect(result.text, contains('Unknown tool'));
    });

    test('a missing required argument names the argument', () async {
      final result = await callRaw(McpToolNames.getTask, {});
      expect(result.isError, isTrue);
      expect(result.text, contains('"id"'));
    });

    test('an out-of-range limit is refused', () async {
      final result =
          await callRaw(McpToolNames.searchTasks, {'query': 'x', 'limit': 500});
      expect(result.isError, isTrue);
      expect(result.text, contains('at most'));
    });

    test('an unknown argument is refused rather than ignored', () async {
      final result =
          await callRaw(McpToolNames.getTask, {'id': 'x', 'colour': 'red'});
      expect(result.isError, isTrue);
      expect(result.text, contains('colour'));
    });

    test('an unknown id is reported as not found', () async {
      final result = await callRaw(McpToolNames.getTask, {'id': 'nope'});
      expect(result.isError, isTrue);
      expect(result.text, contains('No task with id'));
    });
  });

  group('reading', () {
    test('get_task returns plaintext for delta content', () async {
      final id = await makeTask(
        title: 'Notes',
        content: jsonEncode([
          {'insert': 'hello world\n'},
        ]),
      );

      final task = await callOk(McpToolNames.getTask, {'id': id});
      expect(task['title'], 'Notes');
      expect(task['content'], 'hello world\n');
      expect(task['contentIsPlain'], isTrue);
    });

    test('get_task returns plaintext for a legacy HTML row', () async {
      // Rows written before the editor moved to Quill still hold HTML.
      final id = await makeTask(content: '<p>hi there</p>');

      final task = await callOk(McpToolNames.getTask, {'id': id});
      expect(task['content'], 'hi there');
      // Rewriting HTML as a delta is a format conversion, not an edit, so it
      // is not offered as plain.
      expect(task['contentIsPlain'], isFalse);
    });

    test('get_task reports formatted content as not plain', () async {
      final id = await makeTask(
        content: jsonEncode([
          {
            'insert': 'bold',
            'attributes': {'bold': true},
          },
          {'insert': '\n'},
        ]),
      );

      final task = await callOk(McpToolNames.getTask, {'id': id});
      expect(task['contentIsPlain'], isFalse);
    });

    test('get_task reports the ancestor path and children', () async {
      final root = await makeTask(title: 'Work');
      final mid = await makeTask(title: 'Q3', parentWorldId: root);
      final leaf = await makeTask(title: 'Ship it', parentWorldId: mid);

      final task = await callOk(McpToolNames.getTask, {'id': leaf});
      expect(task['path'], ['Work', 'Q3']);
      expect(task['parentId'], mid);

      final parent = await callOk(McpToolNames.getTask, {'id': mid});
      expect((parent['children'] as List).single, {
        'id': leaf,
        'title': 'Ship it',
      });
    });

    test('search drops a task that matches only the delta structure', () async {
      // "insert" is a Delta JSON key, so the SQL prefilter matches this row on
      // structure alone. Only the plaintext pass can tell that apart.
      await makeTask(
        title: 'Unrelated',
        content: jsonEncode([
          {'insert': 'nothing to see\n'},
        ]),
      );
      await makeTask(
        title: 'Real hit',
        content: jsonEncode([
          {'insert': 'please insert here\n'},
        ]),
      );

      final found = await callOk(McpToolNames.searchTasks, {'query': 'insert'});
      final titles = [
        for (final r in found['results'] as List) (r as Map)['title'],
      ];
      expect(titles, ['Real hit']);
      expect(found['total'], 1);
    });

    test('search honours limit and reports truncation', () async {
      for (var i = 0; i < 5; i++) {
        await makeTask(title: 'match $i');
      }

      final found =
          await callOk(McpToolNames.searchTasks, {'query': 'match', 'limit': 2});
      expect((found['results'] as List), hasLength(2));
      expect(found['total'], 5);
      expect(found['truncated'], isTrue);
    });

    test('get_tree nests children and marks a depth cut-off', () async {
      final root = await makeTask(title: 'Root');
      final child = await makeTask(title: 'Child', parentWorldId: root);
      await makeTask(title: 'Grandchild', parentWorldId: child);

      final shallow =
          await callOk(McpToolNames.getTree, {'rootId': root, 'depth': 1});
      final shallowRoot = (shallow['tree'] as List).single as Map;
      expect(shallowRoot['children'], isEmpty);
      expect(shallowRoot['truncated'], isTrue);
      expect(shallow['truncated'], isTrue);

      final deep =
          await callOk(McpToolNames.getTree, {'rootId': root, 'depth': 3});
      final deepRoot = (deep['tree'] as List).single as Map;
      final deepChild = (deepRoot['children'] as List).single as Map;
      expect((deepChild['children'] as List).single, isA<Map>());
      expect(deep['truncated'], isFalse);
    });

    test('get_tree omits content unless asked', () async {
      final root = await makeTask(
        content: jsonEncode([
          {'insert': 'body\n'},
        ]),
      );

      final without = await callOk(McpToolNames.getTree, {'rootId': root});
      expect((without['tree'] as List).single, isNot(contains('content')));

      final with_ = await callOk(
        McpToolNames.getTree,
        {'rootId': root, 'includeContent': true},
      );
      expect(((with_['tree'] as List).single as Map)['content'], 'body\n');
    });

    test('a soft-deleted task reads as absent', () async {
      final id = await makeTask();
      await db.deleteTask((await db.getTaskByWorldId(id))!.id);

      final result = await callRaw(McpToolNames.getTask, {'id': id});
      expect(result.isError, isTrue);
    });
  });

  group('creating', () {
    test('create records history, so sync will carry it', () async {
      final created = await callOk(McpToolNames.createTask, {'title': 'New'});
      final row = await db.getTaskByWorldId(created['id'] as String);

      expect(row, isNotNull);
      expect(row!.title, 'New');
      // The whole reason writes go through NooDatabase rather than raw drift:
      // no history row means the edit never leaves this device.
      expect(await db.getTaskHistory(row.id), isNotEmpty);
    });

    test('create appends after existing siblings', () async {
      final parent = await makeTask(title: 'Parent');
      await callOk(
        McpToolNames.createTask,
        {'title': 'First', 'parentId': parent},
      );
      final second = await callOk(
        McpToolNames.createTask,
        {'title': 'Second', 'parentId': parent},
      );

      expect(second['order'], 1);
    });

    test('create with afterId inserts mid-list and renumbers', () async {
      final parent = await makeTask(title: 'Parent');
      final a = await callOk(
        McpToolNames.createTask,
        {'title': 'A', 'parentId': parent},
      );
      await callOk(McpToolNames.createTask, {'title': 'B', 'parentId': parent});

      final inserted = await callOk(
        McpToolNames.createTask,
        {'title': 'A2', 'parentId': parent, 'afterId': a['id']},
      );
      expect(inserted['order'], 1);

      final parentId = (await db.getTaskByWorldId(parent))!.id;
      final children = await db.getChildTasks(parentId);
      expect([for (final c in children) c.title], ['A', 'A2', 'B']);
      // Contiguous, so nothing ties and the order survives a reload.
      expect([for (final c in children) c.orderId], [0, 1, 2]);
    });

    test('create stores content as a delta ending in a newline', () async {
      final created = await callOk(
        McpToolNames.createTask,
        {'title': 'T', 'content': 'no trailing newline'},
      );
      final row = await db.getTaskByWorldId(created['id'] as String);

      // Document.fromJson throws without the trailing newline, so a task
      // written without one would break the editor rather than merely lose
      // formatting.
      expect(jsonDecode(row!.content!), isA<List<dynamic>>());
      expect(extractPlaintext(row.content), 'no trailing newline\n');
    });

    test('an unknown afterId is not found rather than silently appended',
        () async {
      final result = await callRaw(
        McpToolNames.createTask,
        {'title': 'T', 'afterId': 'nope'},
      );
      expect(result.isError, isTrue);
    });
  });

  group('updating', () {
    test('update round-trips plain text', () async {
      final id = await makeTask();
      await callOk(
        McpToolNames.updateTask,
        {'id': id, 'content': 'first line\nsecond line'},
      );

      final task = await callOk(McpToolNames.getTask, {'id': id});
      expect(task['content'], 'first line\nsecond line\n');
    });

    test('appendContent keeps what was already there', () async {
      final id = await makeTask(
        content: jsonEncode([
          {'insert': 'start\n'},
        ]),
      );
      await callOk(
        McpToolNames.updateTask,
        {'id': id, 'appendContent': 'more'},
      );

      final task = await callOk(McpToolNames.getTask, {'id': id});
      expect(task['content'], 'start\nmore\n');
    });

    test('content and appendContent together are refused', () async {
      final id = await makeTask();
      final result = await callRaw(
        McpToolNames.updateTask,
        {'id': id, 'content': 'a', 'appendContent': 'b'},
      );
      expect(result.isError, isTrue);
    });

    test('a formatted note is not flattened without force', () async {
      final formatted = jsonEncode([
        {
          'insert': 'important',
          'attributes': {'bold': true},
        },
        {'insert': '\n'},
      ]);
      final id = await makeTask(title: 'Design', content: formatted);

      final refused = await callRaw(
        McpToolNames.updateTask,
        {'id': id, 'content': 'plain'},
      );
      expect(refused.isError, isTrue);
      expect(refused.text, contains('Design'));
      expect((await db.getTaskByWorldId(id))!.content, formatted);

      await callOk(
        McpToolNames.updateTask,
        {'id': id, 'content': 'plain', 'force': true},
      );
      expect(extractPlaintext((await db.getTaskByWorldId(id))!.content),
          'plain\n');
    });

    test('a note holding an inline image is not flattened without force',
        () async {
      // Inline images are embeds, and extractPlaintext drops them, so an
      // unguarded round trip would delete the user's image.
      final withImage = jsonEncode([
        {'insert': 'before\n'},
        {
          'insert': {'image': 'noo-attachment://abc'},
        },
        {'insert': '\n'},
      ]);
      final id = await makeTask(content: withImage);

      final refused = await callRaw(
        McpToolNames.updateTask,
        {'id': id, 'content': 'plain'},
      );
      expect(refused.isError, isTrue);
      expect((await db.getTaskByWorldId(id))!.content, withImage);
    });

    test('update with nothing to change is refused', () async {
      final id = await makeTask();
      final result = await callRaw(McpToolNames.updateTask, {'id': id});
      expect(result.isError, isTrue);
    });
  });

  group('moving', () {
    test('moveToRoot clears the parent', () async {
      final parent = await makeTask(title: 'Parent');
      final child = await makeTask(title: 'Child', parentWorldId: parent);

      await callOk(McpToolNames.moveTask, {'id': child, 'moveToRoot': true});
      expect((await db.getTaskByWorldId(child))!.parentId, isNull);
    });

    test('omitting parentId keeps the current parent', () async {
      final parent = await makeTask(title: 'Parent');
      final a = await makeTask(title: 'A', parentWorldId: parent, orderId: 0);
      final b = await makeTask(title: 'B', parentWorldId: parent, orderId: 1);
      final parentId = (await db.getTaskByWorldId(parent))!.id;

      // A reorder among siblings must not double as a move to the top level.
      await callOk(McpToolNames.moveTask, {'id': b, 'afterId': null});
      expect((await db.getTaskByWorldId(b))!.parentId, parentId);

      await callOk(McpToolNames.moveTask, {'id': a, 'afterId': b});
      expect((await db.getTaskByWorldId(a))!.parentId, parentId);
      expect(
        [for (final c in await db.getChildTasks(parentId)) c.title],
        ['B', 'A'],
      );
    });

    test('parentId and moveToRoot together are refused', () async {
      final parent = await makeTask();
      final child = await makeTask(parentWorldId: parent);

      final result = await callRaw(
        McpToolNames.moveTask,
        {'id': child, 'parentId': parent, 'moveToRoot': true},
      );
      expect(result.isError, isTrue);
    });

    test('moving a task under its own descendant is refused', () async {
      final root = await makeTask(title: 'Root');
      final child = await makeTask(title: 'Child', parentWorldId: root);
      final grandchild =
          await makeTask(title: 'Grandchild', parentWorldId: child);

      final rootRow = await db.getTaskByWorldId(root);
      final result = await callRaw(
        McpToolNames.moveTask,
        {'id': root, 'parentId': grandchild},
      );

      // Left unchecked this detaches the whole subtree from every root-walked
      // load, with no error anywhere.
      expect(result.isError, isTrue);
      expect(result.text, contains('loop'));
      expect((await db.getTaskByWorldId(root))!.parentId, rootRow!.parentId);
    });

    test('moving a task under itself is refused', () async {
      final id = await makeTask();
      final result =
          await callRaw(McpToolNames.moveTask, {'id': id, 'parentId': id});
      expect(result.isError, isTrue);
    });

    test('a move renumbers both the old and the new parent', () async {
      final from = await makeTask(title: 'From');
      final to = await makeTask(title: 'To');
      final a = await makeTask(title: 'A', parentWorldId: from, orderId: 0);
      await makeTask(title: 'B', parentWorldId: from, orderId: 1);
      await makeTask(title: 'C', parentWorldId: to, orderId: 0);

      await callOk(McpToolNames.moveTask, {'id': a, 'parentId': to});

      final fromId = (await db.getTaskByWorldId(from))!.id;
      final toId = (await db.getTaskByWorldId(to))!.id;
      expect([for (final c in await db.getChildTasks(fromId)) c.orderId], [0]);
      expect(
        [for (final c in await db.getChildTasks(toId)) c.title],
        ['C', 'A'],
      );
      expect([for (final c in await db.getChildTasks(toId)) c.orderId], [0, 1]);
    });
  });

  group('deleting', () {
    test('delete without confirm refuses and names the descendant count',
        () async {
      final root = await makeTask(title: 'Root');
      final child = await makeTask(parentWorldId: root);
      await makeTask(parentWorldId: child);

      final result = await callRaw(
        McpToolNames.deleteTask,
        {'id': root, 'confirm': false},
      );
      expect(result.isError, isTrue);
      expect(result.text, contains('2 tasks'));
      expect((await db.getTaskByWorldId(root))!.removed, 0);
    });

    test('delete cascades to the whole subtree as a soft delete', () async {
      final root = await makeTask(title: 'Root');
      final child = await makeTask(parentWorldId: root);
      final grandchild = await makeTask(parentWorldId: child);

      final result = await callOk(
        McpToolNames.deleteTask,
        {'id': root, 'confirm': true},
      );
      expect(result['descendantsDeleted'], 2);

      for (final id in [root, child, grandchild]) {
        final row = await db.getTaskByWorldId(id);
        // Soft: the row survives, which is what makes it recoverable and what
        // lets the deletion travel through sync.
        expect(row, isNotNull);
        expect(row!.removed, 1);
        expect(
          await db.getTaskHistory(row.id),
          contains(predicate((dynamic h) => h.field == 'removed')),
        );
      }
    });
  });

  group('excluded branches', () {
    /// Hide the branch rooted at [worldId] the way the tree's context menu
    /// does, so the tests exercise the same stored state the app writes.
    Future<void> hide(String worldId) async {
      final row = await db.getTaskByWorldId(worldId);
      await db.setTaskMcpExcluded(row!.id, true);
    }

    test('a hidden task and its subtree vanish from get_tree', () async {
      final visible = await makeTask(title: 'Visible', orderId: 0);
      final secret = await makeTask(title: 'Secret', orderId: 1);
      await makeTask(title: 'Under secret', parentWorldId: secret);
      await hide(secret);

      final tree = await callOk(McpToolNames.getTree, {'depth': 5});
      final roots = tree['tree'] as List;
      expect(roots.map((n) => (n as Map)['id']), [visible]);
      // Not merely absent: nothing marks the gap, or the caller would know
      // exactly where to press the user about.
      expect(tree['truncated'], isFalse);
      expect(tree['nodeCount'], 1);
    });

    test('a hidden child is dropped from its visible parent', () async {
      final parent = await makeTask(title: 'Parent');
      final shown = await makeTask(title: 'Shown', parentWorldId: parent);
      final hidden = await makeTask(title: 'Hidden', parentWorldId: parent);
      await hide(hidden);

      final task = await callOk(McpToolNames.getTask, {'id': parent});
      expect(
        (task['children'] as List).map((c) => (c as Map)['id']),
        [shown],
      );
    });

    test('hasChildren is false when every child is hidden', () async {
      final parent = await makeTask(title: 'Lonely');
      final hidden = await makeTask(title: 'Child', parentWorldId: parent);
      await hide(hidden);

      final found =
          await callOk(McpToolNames.searchTasks, {'query': 'Lonely'});
      expect(((found['results'] as List).single as Map)['hasChildren'], isFalse);
    });

    test('search hides matches and does not count them in the total',
        () async {
      await makeTask(title: 'apple pie');
      final secret = await makeTask(title: 'apple secret');
      await makeTask(title: 'apple deeper', parentWorldId: secret);
      await hide(secret);

      final found = await callOk(McpToolNames.searchTasks, {'query': 'apple'});
      expect((found['results'] as List), hasLength(1));
      expect(found['total'], 1);
      expect(found['truncated'], isFalse);
    });

    test('a descendant of a hidden task is hidden too', () async {
      final secret = await makeTask(title: 'Secret');
      final child = await makeTask(title: 'Child', parentWorldId: secret);
      final grandchild =
          await makeTask(title: 'Grandchild', parentWorldId: child);
      await hide(secret);

      for (final id in [secret, child, grandchild]) {
        final result = await callRaw(McpToolNames.getTask, {'id': id});
        expect(result.isError, isTrue, reason: id);
        // The same text an id that never existed gets: a caller holding one
        // out of band learns nothing from the difference.
        expect(result.text, contains('No task with id'), reason: id);
      }
    });

    test('every write tool refuses a hidden target', () async {
      final secret = await makeTask(title: 'Secret');
      final child = await makeTask(title: 'Child', parentWorldId: secret);
      final elsewhere = await makeTask(title: 'Elsewhere');
      await hide(secret);

      final refusals = <String, Map<String, Object?>>{
        McpToolNames.updateTask: {'id': child, 'title': 'changed'},
        McpToolNames.moveTask: {'id': child, 'moveToRoot': true},
        McpToolNames.deleteTask: {'id': child, 'confirm': true},
        // Nothing may be put inside a hidden branch either — the agent would
        // be writing where the user cannot see it happen.
        McpToolNames.createTask: {'title': 'New', 'parentId': secret},
      };

      for (final entry in refusals.entries) {
        final result = await callRaw(entry.key, entry.value);
        expect(result.isError, isTrue, reason: entry.key);
        expect(result.text, contains('No task with id'), reason: entry.key);
      }

      // And nothing may be moved into one.
      final moved = await callRaw(
        McpToolNames.moveTask,
        {'id': elsewhere, 'parentId': secret},
      );
      expect(moved.isError, isTrue);

      expect((await db.getTaskByWorldId(child))!.title, 'Child');
      expect((await db.getTaskByWorldId(elsewhere))!.parentId, isNull);
    });

    test('a hidden sibling cannot be named as afterId', () async {
      final visible = await makeTask(title: 'Visible', orderId: 0);
      final secret = await makeTask(title: 'Secret', orderId: 1);
      await hide(secret);

      final result = await callRaw(
        McpToolNames.createTask,
        {'title': 'New', 'afterId': secret},
      );
      expect(result.isError, isTrue);
      expect(result.text, contains('No task with id'));
      // The visible sibling still works, so this is the hidden flag talking
      // and not a broken afterId.
      await callOk(
          McpToolNames.createTask, {'title': 'New', 'afterId': visible});
    });

    test('an insert after a visible sibling keeps a hidden one in order',
        () async {
      final first = await makeTask(title: 'First', orderId: 0);
      final secret = await makeTask(title: 'Secret', orderId: 1);
      final last = await makeTask(title: 'Last', orderId: 2);
      await hide(secret);

      await callOk(
        McpToolNames.createTask,
        {'title': 'Inserted', 'afterId': first},
      );

      // Positions are ordinals of the real sibling list, hidden rows
      // included, so the hidden task keeps its place between them.
      final order = <String, int>{};
      for (final row in await db.getTopLevelTasks()) {
        order[row.title] = row.orderId;
      }
      expect(order['First'], 0);
      expect(order['Inserted'], 1);
      expect(order['Secret'], 2);
      expect(order['Last'], 3);
      expect(await db.getTaskByWorldId(secret), isNotNull);
      expect(await db.getTaskByWorldId(last), isNotNull);
    });

    test('deleting a visible ancestor of a hidden branch is refused',
        () async {
      final root = await makeTask(title: 'Root');
      final middle = await makeTask(title: 'Middle', parentWorldId: root);
      final secret = await makeTask(title: 'Secret', parentWorldId: middle);
      await hide(secret);

      final result = await callRaw(
        McpToolNames.deleteTask,
        {'id': root, 'confirm': true},
      );
      expect(result.isError, isTrue);
      expect(result.text, contains('excluded from agent access'));
      // Says something is there, but not what, where, or how much.
      expect(result.text, isNot(contains('Secret')));
      expect((await db.getTaskByWorldId(root))!.removed, 0);
      expect((await db.getTaskByWorldId(secret))!.removed, 0);
    });

    test('revealing a branch restores access to all of it', () async {
      final secret = await makeTask(title: 'Secret');
      final child = await makeTask(title: 'Child', parentWorldId: secret);
      await hide(secret);
      expect(
          (await callRaw(McpToolNames.getTask, {'id': child})).isError, isTrue);

      final row = await db.getTaskByWorldId(secret);
      await db.setTaskMcpExcluded(row!.id, false);

      final task = await callOk(McpToolNames.getTask, {'id': child});
      expect(task['title'], 'Child');
    });

    test('hiding is recorded as a flags change, so it syncs', () async {
      final secret = await makeTask(title: 'Secret');
      final row = await db.getTaskByWorldId(secret);
      await db.setTaskMcpExcluded(row!.id, true);

      final history = await db.getTaskHistory(row.id);
      final flagChanges = history.where((h) => h.field == 'flags').toList();
      // One from creation, one from hiding — and the latter is what the sync
      // packager reads.
      expect(flagChanges.last.newValue, TaskFlags.mcpExcluded.toString());
      expect(
          (await db.getTaskByWorldId(secret))!.flags, TaskFlags.mcpExcluded);
    });

    test('the flag survives alongside other flags', () async {
      final id = await makeTask(title: 'Tracked');
      final row = await db.getTaskByWorldId(id);
      await db.updateTask(row!.id, flags: TaskFlags.noTimeTracking);
      await db.setTaskMcpExcluded(row.id, true);

      var current = await db.getTaskByWorldId(id);
      expect(current!.flags, TaskFlags.noTimeTracking | TaskFlags.mcpExcluded);

      await db.setTaskMcpExcluded(row.id, false);
      current = await db.getTaskByWorldId(id);
      expect(current!.flags, TaskFlags.noTimeTracking);
      expect((await callOk(McpToolNames.getTask, {'id': id}))['title'],
          'Tracked');
    });
  });

  group('read-only mode', () {
    test('every write tool refuses and leaves the database untouched',
        () async {
      final id = await makeTask(title: 'Untouched');
      final before = await db.getAllTasks();

      for (final tool in McpToolNames.write) {
        final result = await callRaw(tool, {
          'id': id,
          'title': 'changed',
          'confirm': true,
        }, readOnly: true);
        expect(result.isError, isTrue, reason: tool);
        expect(result.text, contains('read-only'), reason: tool);
      }

      final after = await db.getAllTasks();
      expect([for (final t in after) '${t.id}:${t.title}:${t.removed}'],
          [for (final t in before) '${t.id}:${t.title}:${t.removed}']);
    });

    test('read tools still work', () async {
      await makeTask(title: 'Readable');
      final found = await callOk(
        McpToolNames.searchTasks,
        {'query': 'Readable'},
        readOnly: true,
      );
      expect((found['results'] as List), hasLength(1));
    });
  });
}
