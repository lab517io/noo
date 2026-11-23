import 'dart:convert';

import '../database/database.dart';

/// Per-database UI state of the task tree: which nodes are expanded and which
/// node is focused.
///
/// Nodes are addressed by **world id**, never by the local row id: the row id
/// is a local autoincrement that a re-import or a database copy renumbers,
/// while the world id is the identity sync itself uses.
///
/// The focused node is stored as the full root→node world-id *path* rather
/// than a single id. Sync can delete the focused node between two runs of the
/// app (another device removed it), and a path degrades gracefully — the
/// deepest ancestor that still exists becomes the focus instead of losing it
/// altogether. See [TreeUiState.selectedPath].
class TreeUiState {
  const TreeUiState({
    this.expanded = const <String>[],
    this.selectedPath = const <String>[],
  });

  /// World ids of the expanded nodes. Ids that no longer resolve are ignored
  /// on restore, so a deleted subtree simply drops out.
  final List<String> expanded;

  /// World ids from the root down to the focused node (inclusive). Empty when
  /// nothing was focused.
  final List<String> selectedPath;

  bool get isEmpty => expanded.isEmpty && selectedPath.isEmpty;

  Map<String, dynamic> toJson() => {
        'version': 1,
        'expanded': expanded,
        'selectedPath': selectedPath,
      };

  /// Parse a stored payload, tolerating anything that isn't the shape we
  /// wrote — UI state is disposable, so a malformed value must never fail the
  /// tree load. Returns null when nothing usable is in [json].
  static TreeUiState? fromJson(Object? json) {
    if (json is! Map) return null;
    final expanded = _stringList(json['expanded']);
    final selectedPath = _stringList(json['selectedPath']);
    if (expanded.isEmpty && selectedPath.isEmpty) return null;
    return TreeUiState(expanded: expanded, selectedPath: selectedPath);
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const <String>[];
    return [
      for (final item in value)
        if (item is String && item.isNotEmpty) item,
    ];
  }
}

/// Reads and writes [TreeUiState] in the database's `properties` table.
///
/// The properties table is deliberate: this is per-device *view* state of one
/// specific database, so it belongs to the file it describes (and inherits its
/// encryption) rather than to SharedPreferences, which would have to key it by
/// a file path that the user can move at any time. Property writes are not
/// history-tracked, so none of this reaches the sync stream.
class UiStateStore {
  UiStateStore(this._db);

  /// Property key holding the JSON payload.
  static const String propertyKey = 'ui_tree_state';

  final NooDatabase _db;

  Future<TreeUiState?> load() async {
    try {
      final raw = await _db.getProperty(propertyKey);
      if (raw == null || raw.isEmpty) return null;
      return TreeUiState.fromJson(jsonDecode(raw));
    } catch (_) {
      // Unreadable state is no state: fall back to a fully collapsed tree.
      return null;
    }
  }

  Future<void> save(TreeUiState state) async {
    try {
      await _db.setProperty(propertyKey, jsonEncode(state.toJson()));
    } catch (_) {
      // Best-effort. A failed write (database closing under us, disk full)
      // costs the user a collapsed tree next launch, nothing more.
    }
  }
}
