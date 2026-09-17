import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/menu_shortcuts.dart';
import '../../core/utils/platform_info.dart';
import '../providers/mcp_provider.dart';
import '../providers/providers.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_menu_bar.dart';
import '../widgets/dialogs/about_dialog.dart';
import '../widgets/dialogs/sync_log_dialog.dart';
import '../widgets/dialogs/sync_progress_dialog.dart';
import '../widgets/search/search_panel.dart';
import '../widgets/status_bar/status_bar.dart';
import '../widgets/task_tree/task_tree_panel.dart';
import '../widgets/task_editor/task_editor_panel.dart';

/// Main application screen with task tree and editor
class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  double _splitterPosition = 300;

  /// Guards against re-entrant sync triggers (e.g. F5 mashing) so a second
  /// press while a sync is in flight is ignored rather than stacking dialogs.
  bool _syncShortcutBusy = false;

  @override
  void initState() {
    super.initState();
    // Sync (F5) is a global shortcut: register it at the keyboard level so it
    // fires regardless of where focus sits. A focus-scoped CallbackShortcuts
    // misses F5 whenever focus is inside the editor, the tree, a text field or
    // any open dialog — which is most of the time — so route it here instead.
    HardwareKeyboard.instance.addHandler(_handleGlobalKeyEvent);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _resumeActiveTracking();
      await _autoSyncOnStart();
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalKeyEvent);
    super.dispose();
  }

  /// Global key handler for app-wide shortcuts that must work irrespective of
  /// focus. Returns true only for keys it consumes so everything else keeps
  /// propagating normally.
  bool _handleGlobalKeyEvent(KeyEvent event) {
    // KeyDownEvent only: ignore key-up and auto-repeat so a held F5 triggers
    // a single sync.
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.f5) {
      _triggerSyncShortcut();
      return true;
    }
    return false;
  }

  /// Run a manual sync from the F5 shortcut, ignoring the press if the screen
  /// is gone or a sync triggered this way is already in flight.
  Future<void> _triggerSyncShortcut() async {
    if (!mounted || _syncShortcutBusy) return;
    _syncShortcutBusy = true;
    try {
      await AppMenuBar.syncNow(context, ref);
    } finally {
      _syncShortcutBusy = false;
    }
  }

  /// Autosync on start (Preferences → Sync): pull remote changes as soon as
  /// the database is open. Runs after tracking resume so a just-finalized
  /// record is part of the push. Settings are already loaded here — app.dart
  /// watches settingsProvider from the first frame, long before the password
  /// flow completes and this screen mounts.
  Future<void> _autoSyncOnStart() async {
    if (!mounted) return;
    final settings = ref.read(settingsProvider);
    if (!settings.syncEnabled || !settings.syncOnStart) return;
    // Server sync only — see AppMenuBar.syncNow. A LAN-only device would
    // otherwise open a progress dialog on a run that cannot succeed.
    final service = ref.read(syncServiceProvider);
    if (service == null || !service.hasRelay) return;
    // Surface the staged progress dialog, as for a manual sync; it dismisses
    // itself on success and stays open on failure. Not awaited — the dialog
    // only renders provider state, runSyncWithProgress drives it.
    unawaited(showSyncProgressDialog(context, autoCloseOnSuccess: true));
    await runSyncWithProgress(ref);
  }

  /// Resume a tracking session whose open-ended record survived an app
  /// exit or crash (the record is persisted at start with endTime = null).
  Future<void> _resumeActiveTracking() async {
    if (!mounted) return;
    final db = ref.read(databaseProvider);
    if (db == null) return;
    if (ref.read(activeTrackingTaskIdProvider) != null) return;

    final open = await db.getActiveTimeRecord();
    if (open == null || !mounted) return;

    // Only resume for a task that still exists and isn't deleted.
    final task = await db.getTaskById(open.taskId);
    if (task == null || task.removed != 0 || !mounted) return;

    ref.read(activeTrackingTaskIdProvider.notifier).value = open.taskId;
    ref.read(activeTrackingStartTimeProvider.notifier).value =
        DateTime.parse(open.startTime).toUtc();
    ref.read(activeTrackingRecordIdProvider.notifier).value = open.id;
    ref.read(timelineRefreshProvider.notifier).value++;
  }

  @override
  Widget build(BuildContext context) {
    // Activate the watcher that flips the indicator to "pending changes" as
    // soon as the user edits after a sync, the interval auto-sync timer, the
    // LAN peer sync machinery (server + discovery + refresh listener), and the
    // MCP server. All are lazily initialized providers: nothing in them runs
    // until they are watched from here.
    ref.watch(syncPendingWatcherProvider);
    ref.watch(autoSyncSchedulerProvider);
    ref.watch(lanSyncListenerProvider);
    ref.watch(mcpServerListenerProvider);

    // Re-check for an interrupted tracking session when a (different)
    // database is opened.
    ref.listen(databaseProvider, (previous, next) {
      if (next != null) _resumeActiveTracking();
    });

    return CallbackShortcuts(
      bindings: {
        findActivator: () {
          final isVisible = ref.read(searchVisibleProvider);
          if (isVisible) {
            ref.read(searchVisibleProvider.notifier).value = false;
            ref.read(searchQueryProvider.notifier).value = '';
            restoreEditorFocus(ref);
          } else {
            ref.read(searchVisibleProvider.notifier).value = true;
          }
        },
        // Menu shortcuts. Neither menu invokes them on its own: Flutter's
        // MenuBar shows the `shortcut:` labels but does NOT act on them (see
        // menu_anchor.dart "shortcuts are not automatically handled"), and on
        // macOS the framework claims the key before AppKit can offer it to the
        // system menu (FlutterViewController.performKeyEquivalent). So each is
        // wired here to the same action the menu item calls — keep them in sync
        // with the shortcuts declared in AppMenuBar and MacosMenuBar.
        primaryActivator(LogicalKeyboardKey.keyO): () =>
            AppMenuBar.openDatabase(context, ref),
        // Task creation, routed to the tree panel via taskCreationProvider so
        // the shortcuts do what the tree's toolbar buttons do — select the new
        // task and open its title for renaming — rather than just inserting a
        // row. No-ops while no tree is mounted.
        primaryActivator(LogicalKeyboardKey.keyN): () =>
            ref.read(taskCreationProvider)?.createTask(),
        primaryActivator(LogicalKeyboardKey.keyN, shift: true): () =>
            ref.read(taskCreationProvider)?.createChildTask(),
        primaryActivator(LogicalKeyboardKey.keyE): () =>
            AppMenuBar.exportObsidian(context, ref),
        // F5 (Sync) is handled globally via HardwareKeyboard in initState so it
        // works regardless of focus; it is intentionally not bound here.
        primaryActivator(LogicalKeyboardKey.comma): () =>
            AppMenuBar.showPreferences(context, ref),
        primaryActivator(LogicalKeyboardKey.keyQ): () =>
            AppMenuBar.exitApp(context, ref),
        primaryActivator(LogicalKeyboardKey.keyT, shift: true): () =>
            AppMenuBar.showTimeline(context, ref),
        primaryActivator(LogicalKeyboardKey.keyR, shift: true): () =>
            AppMenuBar.showTimeReport(context),
      },
      child: Focus(
        autofocus: true,
        child: isCompactLayout(context)
            ? _buildCompact(context)
            : _buildWide(context),
      ),
    );
  }

  /// Phone layout: app bar with the menu actions, tree as the single pane.
  /// Tapping a task pushes [TaskEditorScreen]; the desktop menu bar, splitter
  /// and editor pane don't exist here.
  Widget _buildCompact(BuildContext context) {
    final fileName = ref.watch(currentDatabaseFileNameProvider);
    final isSearchVisible = ref.watch(searchVisibleProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(fileName ?? AppConstants.appName),
        actions: [
          IconButton(
            icon: Icon(isSearchVisible ? Icons.search_off : Icons.search),
            tooltip: 'Find',
            onPressed: () {
              final notifier = ref.read(searchVisibleProvider.notifier);
              if (isSearchVisible) {
                notifier.value = false;
                ref.read(searchQueryProvider.notifier).value = '';
              } else {
                notifier.value = true;
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sync now',
            onPressed: () => AppMenuBar.syncNow(context, ref),
          ),
          PopupMenuButton<_CompactMenuAction>(
            onSelected: (action) => _onCompactMenuAction(context, action),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: _CompactMenuAction.openDatabase,
                child: Text('Open Database...'),
              ),
              const PopupMenuItem(
                value: _CompactMenuAction.newDatabase,
                child: Text('New Database...'),
              ),
              const PopupMenuItem(
                value: _CompactMenuAction.syncLog,
                child: Text('Sync Log...'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _CompactMenuAction.timeline,
                child: Text('Timeline...'),
              ),
              const PopupMenuItem(
                value: _CompactMenuAction.timeReport,
                child: Text('Time Report...'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _CompactMenuAction.exportObsidian,
                child: Text('Export to Obsidian...'),
              ),
              const PopupMenuItem(
                value: _CompactMenuAction.importObsidian,
                child: Text('Import from Obsidian...'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _CompactMenuAction.theme,
                child: Text('Theme...'),
              ),
              const PopupMenuItem(
                value: _CompactMenuAction.preferences,
                child: Text('Preferences...'),
              ),
              const PopupMenuItem(
                value: _CompactMenuAction.about,
                child: Text('About ${AppConstants.appName}'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (isSearchVisible) const SearchPanel(),
            const Expanded(child: TaskTreePanel()),
            const StatusBar(),
          ],
        ),
      ),
    );
  }

  void _onCompactMenuAction(BuildContext context, _CompactMenuAction action) {
    switch (action) {
      case _CompactMenuAction.openDatabase:
        AppMenuBar.openDatabase(context, ref);
      case _CompactMenuAction.newDatabase:
        AppMenuBar.newDatabase(context, ref);
      case _CompactMenuAction.syncLog:
        showSyncLogDialog(context);
      case _CompactMenuAction.timeline:
        AppMenuBar.showTimeline(context, ref);
      case _CompactMenuAction.timeReport:
        AppMenuBar.showTimeReport(context);
      case _CompactMenuAction.exportObsidian:
        AppMenuBar.exportObsidian(context, ref);
      case _CompactMenuAction.importObsidian:
        AppMenuBar.importObsidian(context, ref);
      case _CompactMenuAction.theme:
        _showThemePicker(context);
      case _CompactMenuAction.preferences:
        AppMenuBar.showPreferences(context, ref);
      case _CompactMenuAction.about:
        showDialog(
          context: context,
          builder: (context) => const NooAboutDialog(),
        );
    }
  }

  /// Mobile stand-in for the desktop View → Theme submenu.
  void _showThemePicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Consumer(
        builder: (context, ref, _) {
          final current = ref.watch(themeModeProvider);
          return SimpleDialog(
            title: const Text('Theme'),
            children: [
              RadioGroup<ThemeMode>(
                groupValue: current,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(settingsProvider.notifier).setThemeMode(value);
                  }
                  Navigator.of(dialogContext).pop();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (mode, label) in [
                      (ThemeMode.system, 'System'),
                      (ThemeMode.light, 'Light'),
                      (ThemeMode.dark, 'Dark'),
                    ])
                      RadioListTile<ThemeMode>(
                        title: Text(label),
                        value: mode,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Desktop/tablet layout: menu bar (inside the custom title bar where one is
  /// drawn), resizable tree+editor split, status bar. On mobile OSes the menu
  /// bar is a plain strip, so a SafeArea keeps it clear of the system UI.
  Widget _buildWide(BuildContext context) {
    final content = AppMenuBar(
      child: Column(
        children: [
          // Search panel (conditionally shown)
          Consumer(builder: (context, ref, _) {
            final isSearchVisible = ref.watch(searchVisibleProvider);
            if (!isSearchVisible) return const SizedBox.shrink();
            return const SearchPanel();
          }),
          // Main content
          Expanded(
            child: Row(
              children: [
                // Task tree panel (left)
                SizedBox(
                  width: _splitterPosition,
                  child: const TaskTreePanel(),
                ),
                // Draggable divider
                MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _splitterPosition += details.delta.dx;
                        _splitterPosition = _splitterPosition.clamp(200.0, 600.0);
                      });
                    },
                    child: Container(
                      width: 4,
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                ),
                // Task editor panel (right)
                const Expanded(
                  child: TaskEditorPanel(),
                ),
              ],
            ),
          ),
          // Status bar: task section toggles, node path, database, sync
          const StatusBar(),
        ],
      ),
    );

    return Scaffold(
      body: isMobilePlatform ? SafeArea(child: content) : content,
    );
  }
}

/// Actions in the compact layout's overflow menu — the items that live in the
/// desktop menu bar. Theme switching stays desktop-only for now (Preferences
/// covers appearance).
enum _CompactMenuAction {
  openDatabase,
  newDatabase,
  syncLog,
  timeline,
  timeReport,
  exportObsidian,
  importObsidian,
  theme,
  preferences,
  about,
}
