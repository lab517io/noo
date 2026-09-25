import 'dart:async';
import 'dart:convert';

import '../../../core/utils/content_utils.dart';
import '../../../domain/entities/task.dart';
import '../../../domain/entities/world_id.dart';
import '../../database/database.dart';
import 'mcp_tools.dart';

/// One tool call's outcome, already shaped for a `tools/call` result.
class McpToolResult {
  /// The body an agent reads. JSON for a success, prose for a failure.
  final String text;

  /// True for anything the agent got wrong or asked for that cannot be done.
  ///
  /// A refusal is *not* a JSON-RPC error: agents surface protocol errors far
  /// worse than they surface `isError`, and every failure here is something
  /// the model can read and act on.
  final bool isError;

  /// True when the call changed the database, so the UI needs a refresh.
  final bool mutated;

  const McpToolResult.ok(this.text)
      : isError = false,
        mutated = false;

  const McpToolResult.wrote(this.text)
      : isError = false,
        mutated = true;

  const McpToolResult.failed(this.text)
      : isError = true,
        mutated = false;
}

/// Runs MCP tool calls against the open database.
///
/// The only part of the MCP feature that touches [NooDatabase], and it knows
/// nothing about HTTP or JSON-RPC — so the semantics can be tested without a
/// socket.
///
/// Every write goes through the ordinary [NooDatabase] methods rather than
/// straight to drift. Those methods record history rows in the same
/// transaction as the row itself, and the history rows are what sync reads, so
/// an agent's edit reaches the user's other devices by the same path as one
/// typed into the app.
///
/// **Excluded branches.** A task carrying [TaskFlags.mcpExcluded] — and its
/// whole subtree — is withheld from every tool here. This is the only place
/// that boundary is enforced, deliberately: the server layer speaks JSON-RPC
/// and never sees a row, so a tool added later that forgets the check is a bug
/// in this file rather than a hole spread across two. Hidden tasks are
/// reported as *not found* rather than as hidden, so a caller holding an id it
/// got out of band learns nothing from the difference.
class McpTaskApi {
  final NooDatabase _db;

  /// Serialises tool calls.
  ///
  /// `create` and `move` both read the sibling list, decide an order, and write
  /// it back. Two of those interleaved — one agent issuing parallel calls, or
  /// two agents at once — would each compute an order from the state before the
  /// other's write and leave two siblings sharing an orderId. Same device
  /// [LanSyncCoordinator] uses to keep exchanges from overlapping.
  Future<void> _chain = Future.value();

  McpTaskApi(this._db);

  /// Run [name] with [args], one call at a time.
  Future<McpToolResult> call(
    String name,
    Map<String, Object?> args, {
    required bool readOnly,
  }) {
    final result = _chain.then((_) => _dispatch(name, args, readOnly: readOnly));
    // Keep the chain alive whatever happens: a failed call must not wedge
    // every later one.
    _chain = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<McpToolResult> _dispatch(
    String name,
    Map<String, Object?> args, {
    required bool readOnly,
  }) async {
    if (!McpToolNames.all.contains(name)) {
      return McpToolResult.failed(
        'Unknown tool "$name". Call tools/list for the available tools.',
      );
    }

    // Belt and braces: the write tools are already absent from tools/list in
    // read-only mode, but a client caches that list from initialize time and
    // this server sends no listChanged notification, so a stale plan can still
    // arrive here.
    if (readOnly && McpToolNames.write.contains(name)) {
      return const McpToolResult.failed(
        'Noo is in read-only mode. Turn off Preferences → MCP → '
        'Read-only to allow writes.',
      );
    }

    final problems = validateToolArgs(name, args);
    if (problems.isNotEmpty) {
      return McpToolResult.failed(problems.join('\n'));
    }

    try {
      return switch (name) {
        McpToolNames.searchTasks => await _searchTasks(args),
        McpToolNames.getTree => await _getTree(args),
        McpToolNames.getTask => await _getTask(args),
        McpToolNames.createTask => await _createTask(args),
        McpToolNames.updateTask => await _updateTask(args),
        McpToolNames.moveTask => await _moveTask(args),
        McpToolNames.deleteTask => await _deleteTask(args),
        _ => McpToolResult.failed('Unknown tool "$name".'),
      };
    } catch (error) {
      // The agent gets something it can report; the alternative is a JSON-RPC
      // internal error carrying a Dart stack trace.
      return McpToolResult.failed('The tool failed: $error');
    }
  }

  // ============================================================
  // Read tools
  // ============================================================

  Future<McpToolResult> _searchTasks(Map<String, Object?> args) async {
    final query = args['query'] as String;
    final limit = (args['limit'] as int?) ?? McpLimits.defaultSearchLimit;

    // getTaskById is the hot call in _path; one map for the whole request
    // keeps a deep, wide result set from re-reading the same ancestors.
    final ancestors = <int, TaskRow?>{};
    final lowerQuery = query.toLowerCase();
    final results = <Map<String, Object?>>[];
    var matched = 0;

    // db.searchTasks is a prefilter that LIKEs against raw content — which is
    // Delta JSON, so a query like "insert" or "attributes" matches structure
    // rather than text. Repeat the authoritative plaintext pass the search
    // panel does before counting anything as a hit.
    for (final row in await _db.searchTasks(query)) {
      final plaintext = extractPlaintext(row.content);
      final titleMatch = row.title.toLowerCase().contains(lowerQuery);
      final contentMatch = plaintext.toLowerCase().contains(lowerQuery);
      if (!titleMatch && !contentMatch) continue;
      // Before `matched++`, not after: `total` is reported to the caller, and
      // counting a hit that is then withheld would announce how much the user
      // has hidden.
      if (await _isHidden(row, ancestors)) continue;

      matched++;
      if (results.length >= limit) continue;

      results.add({
        'id': row.worldId,
        'title': row.title,
        'snippet': contentMatch ? extractSnippet(plaintext, query) : '',
        'parentId': await _worldIdOf(row.parentId, ancestors),
        'path': await _path(row, ancestors),
        'hasChildren': (await _visibleChildren(row.id)).isNotEmpty,
      });
    }

    return McpToolResult.ok(_json({
      'results': results,
      'total': matched,
      'truncated': matched > results.length,
    }));
  }

  Future<McpToolResult> _getTree(Map<String, Object?> args) async {
    final rootWorldId = args['rootId'] as String?;
    final depth = (args['depth'] as int?) ?? McpLimits.defaultTreeDepth;
    final includeContent = (args['includeContent'] as bool?) ?? false;

    List<TaskRow> roots;
    if (rootWorldId == null) {
      roots = await _db.getTopLevelTasks();
    } else {
      final root = await _resolve(rootWorldId);
      if (root == null) return _notFound(rootWorldId);
      roots = [root];
    }

    var budget = McpLimits.maxTreeNodes;
    var truncated = false;

    Future<List<Map<String, Object?>>> build(
      List<TaskRow> rows,
      int remaining,
    ) async {
      final out = <Map<String, Object?>>[];
      for (final row in rows) {
        // A hidden node is skipped whole: not emitted, not counted against the
        // budget, and never marked truncated. Marking it would tell the caller
        // exactly where the user's hidden branches sit, which is the one thing
        // this flag exists to withhold. Only the row's own flag is consulted —
        // the walk starts at a root [_resolve] has already cleared, so an
        // ancestor of anything reached here is by construction visible.
        if ((row.flags & TaskFlags.mcpExcluded) != 0) continue;

        if (budget <= 0) {
          truncated = true;
          break;
        }
        budget--;

        final children = await _visibleChildren(row.id);
        final node = <String, Object?>{
          'id': row.worldId,
          'title': row.title,
          'order': row.orderId,
        };
        if (includeContent) {
          node['content'] = extractPlaintext(row.content);
        }

        if (children.isEmpty) {
          node['children'] = const <Object?>[];
        } else if (remaining > 1) {
          node['children'] = await build(children, remaining - 1);
        } else {
          // Cut off by depth rather than by size, but the agent's next move is
          // the same either way: call again with this node as rootId.
          node['children'] = const <Object?>[];
          node['truncated'] = true;
          truncated = true;
        }
        out.add(node);
      }
      return out;
    }

    final tree = await build(roots, depth);
    return McpToolResult.ok(_json({
      'tree': tree,
      'nodeCount': McpLimits.maxTreeNodes - budget,
      'truncated': truncated,
    }));
  }

  Future<McpToolResult> _getTask(Map<String, Object?> args) async {
    final worldId = args['id'] as String;
    final row = await _resolve(worldId);
    if (row == null) return _notFound(worldId);

    final children = await _visibleChildren(row.id);
    final ancestors = <int, TaskRow?>{};

    return McpToolResult.ok(_json({
      'id': row.worldId,
      'title': row.title,
      'content': extractPlaintext(row.content),
      'contentFormat': 'text',
      // Tells the agent, before it tries, whether writing content back would
      // flatten formatting or drop inline images.
      'contentIsPlain': contentIsPlain(row.content),
      'parentId': await _worldIdOf(row.parentId, ancestors),
      'path': await _path(row, ancestors),
      'order': row.orderId,
      'children': [
        for (final child in children)
          {'id': child.worldId, 'title': child.title},
      ],
      'attachmentCount': await _db.getAttachmentCount(row.id),
      'timeTrackingEnabled': (row.flags & TaskFlags.noTimeTracking) == 0,
    }));
  }

  // ============================================================
  // Write tools
  // ============================================================

  Future<McpToolResult> _createTask(Map<String, Object?> args) async {
    final title = args['title'] as String;
    final parentWorldId = args['parentId'] as String?;
    final content = args['content'] as String?;
    final afterWorldId = args['afterId'] as String?;

    int? parentId;
    if (parentWorldId != null) {
      final parent = await _resolve(parentWorldId);
      if (parent == null) return _notFound(parentWorldId);
      parentId = parent.id;
    }

    final siblings = await _siblingsOf(parentId);
    final position = await _positionAfter(afterWorldId, siblings);
    if (position == null) return _notFound(afterWorldId!);

    // The worldId is minted here and never taken from the caller: the column
    // carries a non-unique index only, so a duplicate would quietly break the
    // by-worldId lookups sync resolves every remote change through.
    final worldId = WorldId.create().toString();
    final newId = await _db.createTask(
      parentId: parentId,
      worldId: worldId,
      orderId: position,
      title: title,
      content: content == null ? null : plaintextToDelta(content),
    );

    if (position < siblings.length) {
      await _renumberSiblings(parentId, movedId: newId, movedTo: position);
    }

    return McpToolResult.wrote(_json({
      'id': worldId,
      'parentId': parentWorldId,
      'order': position,
    }));
  }

  Future<McpToolResult> _updateTask(Map<String, Object?> args) async {
    final worldId = args['id'] as String;
    final title = args['title'] as String?;
    final content = args['content'] as String?;
    final appendContent = args['appendContent'] as String?;
    final force = (args['force'] as bool?) ?? false;

    if (content != null && appendContent != null) {
      return const McpToolResult.failed(
        'Pass either content or appendContent, not both.',
      );
    }
    if (title == null && content == null && appendContent == null) {
      return const McpToolResult.failed(
        'Nothing to update. Pass title, content or appendContent.',
      );
    }

    final row = await _resolve(worldId);
    if (row == null) return _notFound(worldId);

    String? newContent;
    if (content != null || appendContent != null) {
      // extractPlaintext drops formatting and embeds alike, and inline images
      // are embeds, so a read-modify-write through plain text would delete the
      // user's images without saying so. Refuse rather than warn.
      if (!force && !contentIsPlain(row.content)) {
        return McpToolResult.failed(
          'The note on "${_label(row)}" is formatted or contains images, and '
          'writing plain text would discard them. Ask the user to edit it in '
          'the app, or pass force: true to overwrite it anyway.',
        );
      }
      newContent = plaintextToDelta(
        content ?? '${extractPlaintext(row.content)}$appendContent',
      );
    }

    await _db.updateTask(row.id, title: title, content: newContent);

    return McpToolResult.wrote(_json({
      'id': worldId,
      'updated': [
        if (title != null) 'title',
        if (newContent != null) 'content',
      ],
    }));
  }

  Future<McpToolResult> _moveTask(Map<String, Object?> args) async {
    final worldId = args['id'] as String;
    final parentWorldId = args['parentId'] as String?;
    final moveToRoot = (args['moveToRoot'] as bool?) ?? false;
    final afterWorldId = args['afterId'] as String?;

    if (parentWorldId != null && moveToRoot) {
      return const McpToolResult.failed(
        'Pass either parentId or moveToRoot, not both.',
      );
    }

    final row = await _resolve(worldId);
    if (row == null) return _notFound(worldId);

    // Three states, not two: a new parent, explicitly the root, or leave the
    // parent alone. updateTask carries a separate clearParent flag for exactly
    // this reason, and collapsing "omitted" into "null" would make every
    // reorder-in-place also move the task to the top level.
    final oldParentId = row.parentId;
    int? newParentId = oldParentId;
    var reparenting = false;

    if (moveToRoot) {
      newParentId = null;
      reparenting = oldParentId != null;
    } else if (parentWorldId != null) {
      final parent = await _resolve(parentWorldId);
      if (parent == null) return _notFound(parentWorldId);
      if (parent.id == row.id) {
        return const McpToolResult.failed('A task cannot be its own parent.');
      }
      if (await _db.wouldCreateCycle(row.id, parent.id)) {
        return McpToolResult.failed(
          'Cannot move "${_label(row)}" under "${_label(parent)}": that task '
          'is inside the one being moved, so the outline would form a loop.',
        );
      }
      newParentId = parent.id;
      reparenting = oldParentId != parent.id;
    }

    final siblings = await _siblingsOf(newParentId);
    final position = await _positionAfter(
      afterWorldId,
      siblings,
      excludingId: reparenting ? null : row.id,
    );
    if (position == null) return _notFound(afterWorldId!);

    await _db.updateTask(
      row.id,
      parentId: newParentId,
      clearParent: newParentId == null,
      orderId: position,
    );

    await _renumberSiblings(newParentId, movedId: row.id, movedTo: position);
    if (reparenting) {
      await _renumberSiblings(oldParentId);
    }

    return McpToolResult.wrote(_json({
      'id': worldId,
      'parentId': newParentId == null
          ? null
          : (await _db.getTaskById(newParentId))?.worldId,
      'order': position,
    }));
  }

  Future<McpToolResult> _deleteTask(Map<String, Object?> args) async {
    final worldId = args['id'] as String;
    final confirm = args['confirm'] as bool;

    final row = await _resolve(worldId);
    if (row == null) return _notFound(worldId);

    final subtree = await _countDescendants(row.id);

    // The task itself is visible or [_resolve] would have refused, but the
    // delete cascades, and somewhere below it there may be a branch the user
    // put out of reach. Deleting through it would destroy exactly the content
    // the flag protects, so this is the one refusal that has to admit
    // something is there — without saying what, where, or how much.
    if (subtree.hidden) {
      return McpToolResult.failed(
        'Cannot delete "${_label(row)}": something underneath it has been '
        'excluded from agent access, and deleting the task would delete that '
        'too. Ask the user to do it in the app.',
      );
    }

    final descendants = subtree.total;

    if (!confirm) {
      return McpToolResult.failed(
        descendants == 0
            ? 'Pass confirm: true to delete "${_label(row)}".'
            : 'Deleting "${_label(row)}" also deletes the $descendants '
                '${descendants == 1 ? 'task' : 'tasks'} underneath it. Pass '
                'confirm: true if that is intended.',
      );
    }

    await _db.deleteTask(row.id);

    return McpToolResult.wrote(_json({
      'id': worldId,
      'deleted': true,
      'descendantsDeleted': descendants,
      'note': 'Soft delete: the rows remain in the database and the user can '
          'recover them.',
    }));
  }

  // ============================================================
  // Helpers
  // ============================================================

  /// Look a task up by worldId, treating a soft-deleted or hidden row as
  /// absent.
  ///
  /// Every tool resolves its ids through here, which is what makes one check
  /// cover reads and writes alike: a hidden task cannot be read, updated,
  /// moved, deleted, or named as a parent or a sibling, because none of those
  /// ever get a row back for it.
  Future<TaskRow?> _resolve(String worldId) async {
    final row = await _db.getTaskByWorldId(worldId);
    if (row == null || row.removed != 0) return null;
    if (await _isHidden(row)) return null;
    return row;
  }

  /// Whether [row] sits in a branch the user has excluded from agent access.
  ///
  /// Walks ancestors because the flag marks only the root of a hidden branch:
  /// storing it on every descendant would need rewriting the subtree on each
  /// toggle and would drift out of step the moment a task was moved.
  ///
  /// [cache] is the same ancestor-row map [_path] fills, so a wide result set
  /// walks each shared ancestor once rather than once per row.
  Future<bool> _isHidden(TaskRow row, [Map<int, TaskRow?>? cache]) async {
    if ((row.flags & TaskFlags.mcpExcluded) != 0) return true;

    final rows = cache ?? <int, TaskRow?>{};
    var parentId = row.parentId;
    var hops = 0;

    while (parentId != null && hops < McpLimits.maxPathDepth) {
      final parent = await _cachedRow(parentId, rows);
      if (parent == null) break;
      if ((parent.flags & TaskFlags.mcpExcluded) != 0) return true;
      parentId = parent.parentId;
      hops++;
    }
    return false;
  }

  /// Children of [parentId] with hidden branches dropped.
  ///
  /// Their own flag is enough: a caller only reaches this having descended
  /// from a row already found visible.
  Future<List<TaskRow>> _visibleChildren(int parentId) async {
    final children = await _db.getChildTasks(parentId);
    return [
      for (final child in children)
        if ((child.flags & TaskFlags.mcpExcluded) == 0) child,
    ];
  }

  Future<TaskRow?> _cachedRow(int id, Map<int, TaskRow?> cache) async {
    if (cache.containsKey(id)) return cache[id];
    final row = await _db.getTaskById(id);
    cache[id] = row;
    return row;
  }

  McpToolResult _notFound(String worldId) => McpToolResult.failed(
        'No task with id "$worldId". Ids are the worldId values returned by '
        'noo_search_tasks and noo_get_tree.',
      );

  String _label(TaskRow row) => row.title.isEmpty ? '(untitled)' : row.title;

  Future<List<TaskRow>> _siblingsOf(int? parentId) => parentId == null
      ? _db.getTopLevelTasks()
      : _db.getChildTasks(parentId);

  /// Where a task placed after [afterWorldId] lands among [siblings].
  ///
  /// Null means [afterWorldId] named something that is not one of them, which
  /// the caller reports as not-found. Appends when it is omitted.
  ///
  /// [excludingId] discounts the task being moved when it is already in this
  /// list, so "leave it where it is" does not drift by one each time.
  ///
  /// [siblings] keeps its hidden members: the index returned is a position in
  /// the real sibling order, and dropping them would make an insert land
  /// somewhere else entirely. A hidden sibling simply cannot be *named* as
  /// [afterWorldId] — matching one would confirm it exists.
  Future<int?> _positionAfter(
    String? afterWorldId,
    List<TaskRow> siblings, {
    int? excludingId,
  }) async {
    final ordered = excludingId == null
        ? siblings
        : [
            for (final sibling in siblings)
              if (sibling.id != excludingId) sibling,
          ];

    if (afterWorldId == null) return ordered.length;

    final index = ordered.indexWhere((s) => s.worldId == afterWorldId);
    if (index < 0) return null;
    if ((ordered[index].flags & TaskFlags.mcpExcluded) != 0) return null;
    return index + 1;
  }

  /// Give every child of [parentId] a contiguous orderId matching its position.
  ///
  /// [movedId] is placed at [movedTo] and the rest close up around it, which is
  /// what makes an insert land where the caller asked rather than tying with
  /// whoever already held that index.
  ///
  /// Rows whose index is already right are skipped. The tree widget's
  /// equivalent does the same, and here it matters twice over: every write goes
  /// into the history table and from there onto the wire, so renumbering a
  /// hundred untouched siblings would put a hundred pointless changes into the
  /// next sync packet.
  ///
  /// Hidden siblings are renumbered along with the rest — they hold positions
  /// in the same list, and skipping them would leave the order full of holes.
  /// Nothing about them is read out or disclosed; only `orderId` moves.
  Future<void> _renumberSiblings(
    int? parentId, {
    int? movedId,
    int? movedTo,
  }) async {
    final siblings = await _siblingsOf(parentId);

    final ordered = <TaskRow>[];
    TaskRow? moved;
    for (final sibling in siblings) {
      if (sibling.id == movedId) {
        moved = sibling;
      } else {
        ordered.add(sibling);
      }
    }
    if (moved != null) {
      ordered.insert((movedTo ?? ordered.length).clamp(0, ordered.length), moved);
    }

    for (var i = 0; i < ordered.length; i++) {
      if (ordered[i].orderId != i) {
        await _db.updateTask(ordered[i].id, orderId: i);
      }
    }
  }

  /// How many tasks sit below [id], and whether any of them starts a branch
  /// excluded from agent access.
  ///
  /// Both in one walk because the caller — delete — needs both, and the whole
  /// subtree has to be visited either way.
  Future<({int total, bool hidden})> _countDescendants(int id) async {
    var total = 0;
    var hidden = false;
    final queue = <int>[id];
    // Bounded by the visited set rather than by trust in the tree shape: a
    // cycle here would otherwise spin forever while holding the call chain.
    final visited = <int>{id};

    while (queue.isNotEmpty) {
      for (final child in await _db.getChildTasks(queue.removeLast())) {
        if (!visited.add(child.id)) continue;
        total++;
        if ((child.flags & TaskFlags.mcpExcluded) != 0) hidden = true;
        queue.add(child.id);
      }
    }
    return (total: total, hidden: hidden);
  }

  Future<String?> _worldIdOf(int? id, Map<int, TaskRow?> cache) async {
    if (id == null) return null;
    return (await _cachedRow(id, cache))?.worldId;
  }

  /// Titles from the root down to [row]'s parent.
  Future<List<String>> _path(TaskRow row, Map<int, TaskRow?> cache) async {
    final titles = <String>[];
    var parentId = row.parentId;
    var hops = 0;

    while (parentId != null && hops < McpLimits.maxPathDepth) {
      final parent = await _cachedRow(parentId, cache);
      if (parent == null) break;
      titles.insert(0, _label(parent));
      parentId = parent.parentId;
      hops++;
    }
    return titles;
  }

  static String _json(Object? value) =>
      const JsonEncoder.withIndent('  ').convert(value);
}
