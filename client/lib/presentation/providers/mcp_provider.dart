import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/database.dart';
import '../../data/services/mcp/mcp_server.dart';
import '../../data/services/mcp/mcp_tools.dart';
import 'providers.dart';
import 'settings_provider.dart';

/// The MCP preferences the server actually reacts to, as one comparable value.
///
/// [Equatable] deliberately: settings are rewritten on every preference edit,
/// so a config object without value equality would report a change each time
/// the user nudged the font size, and this server binds a *fixed* port — the
/// resulting rebind would intermittently fail on a socket still in TIME_WAIT.
/// (`SyncConfig` has no `==` and does exactly that to the LAN coordinator.)
class McpConfig extends Equatable {
  final bool enabled;
  final int port;
  final bool readOnly;
  final String? token;
  final String databaseLabel;

  const McpConfig({
    required this.enabled,
    required this.port,
    required this.readOnly,
    required this.token,
    required this.databaseLabel,
  });

  @override
  List<Object?> get props => [enabled, port, readOnly, token, databaseLabel];
}

final mcpConfigProvider = Provider<McpConfig>((ref) {
  final settings = ref.watch(settingsProvider);

  return McpConfig(
    enabled: settings.mcpEnabled,
    port: settings.mcpPort,
    readOnly: settings.mcpReadOnly,
    token: settings.mcpToken,
    databaseLabel: ref.watch(currentDatabaseFileNameProvider) ?? '',
  );
});

/// Holds the one [McpServer] for the process.
///
/// Long-lived on purpose. Rebuilding it whenever the database changed would
/// hand teardown to `ref.onDispose`, which does not await the Future that
/// closes the socket — so the replacement would race the old socket for a
/// fixed port and fail intermittently. Instead the single instance is
/// reconfigured, and it decides for itself whether anything needs rebinding.
class McpServerNotifier extends Notifier<McpServer> {
  @override
  McpServer build() {
    final server = McpServer();

    // Bridge ChangeNotifier updates to Riverpod so the preferences tab sees
    // the bind state and the request counters move.
    void listener() => ref.notifyListeners();
    server.addListener(listener);
    ref.onDispose(() {
      server.removeListener(listener);
      server.dispose();
    });

    return server;
  }
}

final mcpServerProvider =
    NotifierProvider<McpServerNotifier, McpServer>(McpServerNotifier.new);

/// Applies settings to the server and refreshes the UI after an agent writes.
///
/// Lazily initialized, exactly like [lanSyncListenerProvider]: nothing here
/// runs until something watches it, which [MainScreen] does. Forget that watch
/// and the server never starts.
final mcpServerListenerProvider = Provider<void>((ref) {
  final server = ref.watch(mcpServerProvider);
  final config = ref.watch(mcpConfigProvider);
  final db = ref.watch(databaseProvider);

  // An agent's write has to land on top of whatever the user has typed rather
  // than race the editor's auto-save timer, which is why sync flushes the
  // editor before it reads the database too.
  server.beforeWrite = () async {
    final flush = ref.read(editorFlushProvider);
    if (flush != null) await flush();
  };

  server.configure(
    db: db,
    enabled: config.enabled,
    port: config.port,
    token: config.token,
    readOnly: config.readOnly,
    databaseLabel: config.databaseLabel,
  );

  final sub = server.onChanged.listen((_) {
    // Same three refreshes the sync paths do: a stale editor would otherwise
    // overwrite the agent's change on its next auto-save.
    ref.read(taskTreeControllerProvider)?.loadTree();
    ref.read(timelineRefreshProvider.notifier).value++;
    ref.invalidate(taskByIdProvider);
  });

  ref.onDispose(() {
    sub.cancel();
    server.beforeWrite = null;
  });
});

/// A branch the user has hidden from the MCP server, as the preferences tab
/// lists it.
class McpExcludedBranch {
  final int taskId;
  final String title;

  /// Ancestor titles from the root down to the branch's parent.
  ///
  /// The title alone is not enough to recognise a branch — outlines are full
  /// of tasks called "Notes" — and the tree gives no other way to find what
  /// was hidden weeks ago.
  final List<String> path;

  const McpExcludedBranch({
    required this.taskId,
    required this.title,
    required this.path,
  });
}

/// The hidden branches of the open database, outermost first.
///
/// `autoDispose` so re-opening preferences re-reads: the tree can hide or
/// reveal a branch while the dialog is closed, and a cached list would show
/// the state from whenever it was last built.
final mcpExcludedBranchesProvider =
    FutureProvider.autoDispose<List<McpExcludedBranch>>((ref) async {
  final db = ref.watch(databaseProvider);
  if (db == null) return const <McpExcludedBranch>[];

  final rows = await db.getMcpExcludedTasks();
  final cache = <int, TaskRow?>{};
  final branches = <McpExcludedBranch>[];

  for (final row in rows) {
    final path = <String>[];
    var parentId = row.parentId;
    var hops = 0;
    // Same depth cap the MCP path walk uses: a corrupt parent cycle must not
    // hang the preferences dialog.
    while (parentId != null && hops < McpLimits.maxPathDepth) {
      final TaskRow? parent;
      if (cache.containsKey(parentId)) {
        parent = cache[parentId];
      } else {
        parent = await db.getTaskById(parentId);
        cache[parentId] = parent;
      }
      if (parent == null) break;
      path.insert(0, parent.title.isEmpty ? '(untitled)' : parent.title);
      parentId = parent.parentId;
      hops++;
    }

    branches.add(McpExcludedBranch(
      taskId: row.id,
      title: row.title.isEmpty ? '(untitled)' : row.title,
      path: path,
    ));
  }

  branches.sort((a, b) {
    final depth = a.path.length.compareTo(b.path.length);
    return depth != 0 ? depth : a.title.compareTo(b.title);
  });
  return branches;
});
