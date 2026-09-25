import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/platform_info.dart';
import '../../../data/database/database.dart';
import '../../../domain/entities/task.dart';
import '../../providers/providers.dart';
import 'classic_form.dart';

/// Picks the branches the MCP server may not see.
///
/// A tree with a checkbox per task rather than a per-task command in the
/// outline's own context menu: hiding a branch is a rare, deliberate act, and
/// it is done while thinking about what agents may read — which is here, next
/// to the token and the read-only switch, not in the menu the user opens
/// twenty times a day to rename something.
///
/// Nothing is written until OK. The flag is document data — it syncs, and the
/// Preferences dialog's own Cancel restores preferences, not the outline — so
/// a user who ticks four boxes and thinks better of it needs a way back that
/// does not depend on what the dialog behind this one does next.
Future<bool> showMcpExcludedBranchesDialog(BuildContext context) async {
  final changed = await showDialog<bool>(
    context: context,
    builder: (context) => const _McpExcludedBranchesDialog(),
  );
  return changed ?? false;
}

class _McpExcludedBranchesDialog extends ConsumerStatefulWidget {
  const _McpExcludedBranchesDialog();

  @override
  ConsumerState<_McpExcludedBranchesDialog> createState() =>
      _McpExcludedBranchesDialogState();
}

class _McpExcludedBranchesDialogState
    extends ConsumerState<_McpExcludedBranchesDialog> {
  /// Children by parent id; the top level is keyed by null.
  final Map<int?, List<TaskOutlineRow>> _children = {};

  /// Every task by id, so an ancestor walk needs no further queries.
  final Map<int, TaskOutlineRow> _byId = {};

  /// Task ids whose own exclusion flag is currently ticked.
  final Set<int> _excluded = {};

  /// What [_excluded] held when the outline was read, so OK writes only what
  /// actually moved — every write is a history row and a sync change.
  final Set<int> _initial = {};

  final Set<int> _expanded = {};

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    if (db == null) {
      setState(() => _loading = false);
      return;
    }

    // One read of the whole outline, titles and flags only. The alternative —
    // a query per expanded node, as the main tree does — would be paid again
    // on every toggle here, because a toggle changes what the rows below it
    // are allowed to show.
    final rows = await db.getTaskOutline();
    if (!mounted) return;

    setState(() {
      for (final row in rows) {
        _byId[row.id] = row;
        _children.putIfAbsent(row.parentId, () => []).add(row);
        if ((row.flags & TaskFlags.mcpExcluded) != 0) _excluded.add(row.id);
      }
      _initial.addAll(_excluded);
      // Open the path down to everything already hidden: the first thing this
      // dialog has to answer is "what did I hide", and a collapsed tree
      // answers it with a blank screen.
      for (final id in _excluded) {
        var parentId = _byId[id]?.parentId;
        var hops = 0;
        while (parentId != null && hops < NooDatabase.maxAncestorWalk) {
          _expanded.add(parentId);
          parentId = _byId[parentId]?.parentId;
          hops++;
        }
      }
      _loading = false;
    });
  }

  bool get _dirty => !_setEquals(_excluded, _initial);

  static bool _setEquals(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);

  void _toggle(TaskOutlineRow row, bool excluded) {
    setState(() {
      if (excluded) {
        _excluded.add(row.id);
        // Reveal what was just hidden, so the greyed-out subtree explains
        // itself instead of the checkbox seeming to do nothing.
        if ((_children[row.id] ?? const []).isNotEmpty) _expanded.add(row.id);
      } else {
        _excluded.remove(row.id);
      }
    });
  }

  Future<void> _accept() async {
    final navigator = Navigator.of(context);
    final db = ref.read(databaseProvider);

    if (db != null && _dirty) {
      for (final row in _byId.values) {
        final wanted = _excluded.contains(row.id);
        if (wanted == _initial.contains(row.id)) continue;
        await db.setTaskMcpExcluded(row.id, wanted);
      }
      // The tree holds its own copy of every row's flags, so the badges are
      // stale until it reloads.
      await ref.read(taskTreeControllerProvider)?.loadTree();
    }

    navigator.pop(_dirty);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scale = classicUiScale(context);

    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _buildTree(theme);

    if (isCompactLayout(context)) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Excluded branches'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
              onPressed: () => Navigator.of(context).pop(false),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.check),
                tooltip: 'OK',
                onPressed: _accept,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildIntro(theme),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      );
    }

    return AlertDialog(
      title: const Text('Excluded branches'),
      titleTextStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      contentPadding: EdgeInsets.zero,
      content: SizedBox(
        width: 480 * scale,
        height: 460 * scale,
        child: Column(
          children: [
            _buildIntro(theme),
            Expanded(child: body),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
      actions: [
        FilledButton(
          style: classicButtonStyle(context),
          onPressed: _accept,
          child: const Text('OK'),
        ),
        OutlinedButton(
          style: classicButtonStyle(context),
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildIntro(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      child: Text(
        'A ticked task is hidden from the MCP server together with everything '
        'under it — agents cannot read it, change it, or delete anything that '
        'contains it.',
        style: theme.textTheme.bodySmall,
      ),
    );
  }

  Widget _buildTree(ThemeData theme) {
    final roots = _children[null] ?? const <TaskOutlineRow>[];
    if (roots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            ref.read(databaseProvider) == null
                ? 'No database is open.'
                : 'This outline has no tasks yet.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      );
    }

    // Flattened here rather than nested widgets, so the list stays lazy: only
    // the rows an expanded path actually reaches are built.
    final rows = <_VisibleRow>[];
    void walk(List<TaskOutlineRow> siblings, int depth, bool ancestorExcluded) {
      for (final row in siblings) {
        rows.add(_VisibleRow(row, depth, ancestorExcluded));
        if (!_expanded.contains(row.id)) continue;
        walk(
          _children[row.id] ?? const [],
          depth + 1,
          ancestorExcluded || _excluded.contains(row.id),
        );
      }
    }

    walk(roots, 0, false);

    return Scrollbar(
      child: ListView.builder(
        primary: false,
        padding: const EdgeInsets.only(bottom: 8),
        itemCount: rows.length,
        itemBuilder: (context, index) => _buildRow(theme, rows[index]),
      ),
    );
  }

  Widget _buildRow(ThemeData theme, _VisibleRow visible) {
    final row = visible.row;
    final children = _children[row.id] ?? const <TaskOutlineRow>[];
    final expanded = _expanded.contains(row.id);
    final excluded = _excluded.contains(row.id);
    final inherited = visible.ancestorExcluded;

    final title = row.title.isEmpty ? '(untitled)' : row.title;
    final muted = inherited
        ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
        : null;

    return InkWell(
      // The whole row toggles: a 20px checkbox is a poor target, and on a
      // phone it is the only one there is.
      onTap: inherited ? null : () => _toggle(row, !excluded),
      child: Padding(
        padding: EdgeInsets.only(left: 12.0 + visible.depth * 16, right: 12),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 32,
              child: children.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(
                        expanded ? Icons.expand_more : Icons.chevron_right,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      tooltip: expanded ? 'Collapse' : 'Expand',
                      onPressed: () => setState(() {
                        if (!_expanded.remove(row.id)) _expanded.add(row.id);
                      }),
                    ),
            ),
            SizedBox(
              width: 32,
              child: Checkbox(
                // Ticked by inheritance too, because that is what is true of
                // the task; disabled because the flag that hides it belongs to
                // an ancestor, and the way back is to untick that one.
                value: excluded || inherited,
                onChanged:
                    inherited ? null : (value) => _toggle(row, value ?? false),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: muted,
                    fontStyle: row.title.isEmpty ? FontStyle.italic : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (inherited)
              Text(
                'hidden with parent',
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
          ],
        ),
      ),
    );
  }
}

/// One row of the flattened tree.
class _VisibleRow {
  final TaskOutlineRow row;
  final int depth;

  /// True when something above this row is excluded, so it is hidden whatever
  /// its own checkbox says.
  final bool ancestorExcluded;

  const _VisibleRow(this.row, this.depth, this.ancestorExcluded);
}
