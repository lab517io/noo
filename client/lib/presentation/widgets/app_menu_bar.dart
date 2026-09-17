import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/utils/byte_format.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/platform_info.dart';
import '../../core/utils/save_dialog.dart';
import '../../core/utils/share_utils.dart';
import '../../core/utils/zip_host_os.dart';
import '../../data/database/database.dart';
import '../../data/services/database_manager.dart';
import '../../data/services/obsidian_export_service.dart';
import '../../data/services/obsidian_import_service.dart';
import '../../data/services/sync_service.dart';
import '../../data/services/test_data_generator.dart';
import '../../domain/entities/time_line.dart';
import '../../domain/entities/time_record.dart';
import '../providers/providers.dart';
import '../providers/settings_provider.dart';
import 'dialogs/about_dialog.dart';
import 'dialogs/history_viewer_dialog.dart';
import 'dialogs/password_dialog.dart';
import 'dialogs/p2p_sync_dialog.dart';
import 'dialogs/preferences_dialog.dart';
import 'dialogs/sync_log_dialog.dart';
import 'dialogs/sync_progress_dialog.dart';
import 'dialogs/time_report_dialog.dart';
import 'time_tracking/timeline_dialog.dart';
import 'window_title_bar.dart';

/// User's answer to the sync-on-exit prompt.
enum _ExitSyncChoice {
  /// Sync pending changes, then close.
  sync,

  /// Close without syncing.
  discard,

  /// Abort the close and keep the app open.
  cancel,
}

/// Navigator key for the app's root navigator, wired into [MaterialApp] in
/// `app.dart`. Lets code without a live `BuildContext` — notably the OS
/// window-close handler — still surface dialogs (e.g. the exit-sync prompt).
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Main application menu bar
class AppMenuBar extends ConsumerWidget {
  final Widget child;

  const AppMenuBar({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // macOS draws no menu inside the window: the same commands live in the
    // system menu bar, installed by [MacosMenuBar] from `app.dart` so they are
    // there before any database is open and stay there in a narrow window.
    if (usesPlatformMenuBar) return child;

    final themeMode = ref.watch(themeModeProvider);
    final menuBar = MenuBar(
      children: [
        // File menu
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              onPressed: () => openDatabase(context, ref),
              shortcut: const SingleActivator(LogicalKeyboardKey.keyO, control: true),
              child: const Text('Open...'),
            ),
            MenuItemButton(
              onPressed: () => newDatabase(context, ref),
              child: const Text('New Database...'),
            ),
            const Divider(),
            MenuItemButton(
              onPressed: () => exportObsidian(context, ref),
              shortcut: const SingleActivator(LogicalKeyboardKey.keyE, control: true),
              child: const Text('Export to Obsidian...'),
            ),
            MenuItemButton(
              onPressed: () => importObsidian(context, ref),
              child: const Text('Import from Obsidian...'),
            ),
            const Divider(),
            MenuItemButton(
              onPressed: () => exitApp(context, ref),
              shortcut: const SingleActivator(LogicalKeyboardKey.keyQ, control: true),
              child: const Text('Exit'),
            ),
          ],
          child: const Text('File'),
        ),

        // View menu
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              onPressed: () {
                ref.read(searchVisibleProvider.notifier).value = true;
              },
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyF, control: true, shift: true,
              ),
              child: const Text('Find...'),
            ),
            const Divider(),
            // Theme submenu
            SubmenuButton(
              menuChildren: [
                MenuItemButton(
                  onPressed: () => ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.system),
                  leadingIcon: themeMode == ThemeMode.system
                      ? const Icon(Icons.check, size: 18)
                      : const SizedBox(width: 18),
                  child: const Text('System'),
                ),
                MenuItemButton(
                  onPressed: () => ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.light),
                  leadingIcon: themeMode == ThemeMode.light
                      ? const Icon(Icons.check, size: 18)
                      : const SizedBox(width: 18),
                  child: const Text('Light'),
                ),
                MenuItemButton(
                  onPressed: () => ref.read(settingsProvider.notifier).setThemeMode(ThemeMode.dark),
                  leadingIcon: themeMode == ThemeMode.dark
                      ? const Icon(Icons.check, size: 18)
                      : const SizedBox(width: 18),
                  child: const Text('Dark'),
                ),
              ],
              child: const Text('Theme'),
            ),
          ],
          child: const Text('View'),
        ),

        // Tools menu
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              onPressed: () => showTimeline(context, ref),
              shortcut: const SingleActivator(LogicalKeyboardKey.keyT, control: true, shift: true),
              child: const Text('Timeline...'),
            ),
            MenuItemButton(
              onPressed: () => showTimeReport(context),
              shortcut: const SingleActivator(LogicalKeyboardKey.keyR, control: true, shift: true),
              child: const Text('Time Report...'),
            ),
            const Divider(),
            MenuItemButton(
              onPressed: () => compactDatabase(context, ref),
              child: const Text('Compact Database...'),
            ),
            const Divider(),
            MenuItemButton(
              onPressed: () => syncNow(context, ref),
              shortcut: const SingleActivator(LogicalKeyboardKey.f5),
              child: const Text('Sync Now'),
            ),
            MenuItemButton(
              onPressed: () => syncWithPeers(context, ref),
              shortcut: const SingleActivator(
                LogicalKeyboardKey.f5,
                shift: true,
              ),
              child: const Text('Sync P2P...'),
            ),
            // The recorded history of every sync, including past sessions —
            // available whenever a database is open, not only after a run.
            if (ref.watch(databaseProvider) != null)
              MenuItemButton(
                onPressed: () => showSyncLogDialog(context),
                child: const Text('Sync Log...'),
              ),
            const Divider(),
            MenuItemButton(
              onPressed: () => showPreferences(context, ref),
              shortcut: const SingleActivator(LogicalKeyboardKey.comma, control: true),
              child: const Text('Preferences...'),
            ),
          ],
          child: const Text('Tools'),
        ),

        // Debug menu (only in debug mode)
        if (kDebugMode)
          SubmenuButton(
            menuChildren: [
              MenuItemButton(
                onPressed: () => viewChangeHistory(context),
                child: const Text('View Change History...'),
              ),
              const Divider(),
              MenuItemButton(
                onPressed: () => generateTestData(context, ref),
                child: const Text('Generate Test Data'),
              ),
              MenuItemButton(
                onPressed: () => generateLargeTestData(context, ref),
                child: const Text('Generate Large Dataset'),
              ),
              const Divider(),
              MenuItemButton(
                onPressed: () => clearAllData(context, ref),
                child: const Text('Clear All Data'),
              ),
            ],
            child: const Text('Debug'),
          ),

        // Help menu
        SubmenuButton(
          menuChildren: [
            MenuItemButton(
              onPressed: () => showRegistration(context, ref),
              child: const Text('Registration...'),
            ),
            const Divider(),
            MenuItemButton(
              onPressed: () => showAbout(context),
              child: const Text('About ${AppConstants.appName}'),
            ),
          ],
          child: const Text('Help'),
        ),
      ],
    );

    return Column(
      children: [
        // Menu bar — merged into the app-drawn title bar where the native one
        // is hidden (Windows/Linux), standalone otherwise.
        if (usesCustomTitleBar)
          _titleBar(context, ref, menuBar)
        else
          menuBar,
        // Main content
        Expanded(child: child),
      ],
    );
  }

  /// The menu sitting inside the custom title bar, alongside the window title
  /// and caption buttons.
  Widget _titleBar(BuildContext context, WidgetRef ref, Widget menuBar) {
    final height = titleBarHeightFor(ref.watch(settingsProvider).chromeFontScale);
    return WindowTitleBar(
      height: height,
      title: windowTitleText(ref.watch(currentDatabaseFileNameProvider)),
      // Drop the menu bar's own surface and elevation so it reads as part of
      // the title strip rather than a second bar stacked on it, and pin it to
      // the strip's height so the top-level buttons don't force it taller.
      menu: MenuBarTheme(
        data: const MenuBarThemeData(
          style: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(Colors.transparent),
            elevation: WidgetStatePropertyAll(0),
            shadowColor: WidgetStatePropertyAll(Colors.transparent),
            surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
            padding: WidgetStatePropertyAll(EdgeInsets.zero),
          ),
        ),
        child: SizedBox(height: height, child: menuBar),
      ),
    );
  }

  /// Finalize any active tracking session against the current database and
  /// clear the in-memory tracking state. Used before switching databases and
  /// on exit, so a session is never recorded against the wrong database or
  /// silently lost.
  static Future<void> _stopActiveTracking(WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final recordId = ref.read(activeTrackingRecordIdProvider);
    final taskId = ref.read(activeTrackingTaskIdProvider);
    final startTime = ref.read(activeTrackingStartTimeProvider);

    if (db != null && taskId != null) {
      final now = DateTime.now().toUtc().toIso8601String();
      if (recordId != null) {
        await db.updateTimeRecord(recordId, endTime: now);
      } else if (startTime != null) {
        await db.createTimeRecord(
          taskId: taskId,
          worldId: WorldId.create().value,
          startTime: startTime.toIso8601String(),
          endTime: now,
        );
      }
    }

    ref.read(activeTrackingTaskIdProvider.notifier).value = null;
    ref.read(activeTrackingStartTimeProvider.notifier).value = null;
    ref.read(activeTrackingRecordIdProvider.notifier).value = null;
  }

  static Future<void> openDatabase(BuildContext context, WidgetRef ref) async {
    final dbManager = ref.read(databaseManagerProvider);
    final defaultDir = await dbManager.getDefaultDirectory();

    final result = await FilePicker.pickFiles(
      dialogTitle: 'Open Database',
      type: FileType.custom,
      allowedExtensions: ['noo', 'sqlite', 'db'],
      initialDirectory: defaultDir,
    );

    if (result.isNotEmpty) {
      final path = result.first.path;
      if (path != null) {
        // Finalize tracking against the current database and clear selection
        // before switching databases
        await _stopActiveTracking(ref);
        ref.read(selectedTaskIdProvider.notifier).value = null;

        // First try opening without password
        var success = await dbManager.openDatabase(path);

        // If password is needed, show dialog
        if (!success && dbManager.needsPassword && context.mounted) {
          String? errorMessage;

          while (!success && context.mounted) {
            final passwordResult = await PasswordDialog.showOpen(
              context,
              errorMessage: errorMessage,
              databasePath: path,
            );

            if (passwordResult == null) {
              // User cancelled
              return;
            }

            success = await dbManager.openDatabase(
              path,
              password: passwordResult.password,
            );

            if (!success && dbManager.errorType == DatabaseError.wrongPassword) {
              errorMessage = 'Incorrect password. Please try again.';
            }
          }
        }

        if (success) {
          // Tree controller will auto-recreate when database changes
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Opened: ${p.basename(path)}')),
            );
          }
        } else if (context.mounted && !dbManager.needsPassword) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to open database: ${dbManager.error}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  static Future<void> newDatabase(BuildContext context, WidgetRef ref) async {
    final dbManager = ref.read(databaseManagerProvider);
    final defaultDir = await dbManager.getDefaultDirectory();

    final path = await pickSavePath(
      dialogTitle: 'Create New Database',
      fileName: 'database.noo',
      type: FileType.custom,
      allowedExtensions: ['noo'],
      initialDirectory: defaultDir,
      requiredExtension: '.noo',
    );

    if (path != null) {
      // Request password for new database
      if (!context.mounted) return;

      final passwordResult = await PasswordDialog.showCreate(
        context,
        databasePath: path,
      );
      if (passwordResult == null) {
        // User cancelled
        return;
      }

      // Finalize tracking against the current database and clear selection
      // before switching databases
      await _stopActiveTracking(ref);
      ref.read(selectedTaskIdProvider.notifier).value = null;

      final success = await dbManager.createDatabase(
        path,
        password: passwordResult.password,
      );

      if (success) {
        // Tree controller will auto-recreate when database changes
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Created: ${p.basename(path)}')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create database: ${dbManager.error}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  static Future<void> exportObsidian(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    if (db == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open a database first')),
      );
      return;
    }

    // Scoped storage makes writing a vault directory tree impractical on
    // mobile — build the vault in the temp dir, zip it, and share the archive.
    if (isMobilePlatform) {
      return _exportObsidianAsZip(context, db);
    }

    final result = await FilePicker.getDirectoryPath(
      dialogTitle: 'Export to Obsidian Directory',
    );

    if (result == null || !context.mounted) return;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Exporting to Obsidian format...'),
          ],
        ),
      ),
    );

    final exportService = ObsidianExportService(db);
    final exportResult = await exportService.export(result);

    // Close progress dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    if (context.mounted) {
      if (exportResult.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Exported ${exportResult.tasksExported} tasks, '
              '${exportResult.timelineFilesExported} timeline files, '
              '${exportResult.imagesExported} images',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${exportResult.error}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Mobile export path: vault tree → temp dir → .zip → share sheet.
  static Future<void> _exportObsidianAsZip(
    BuildContext context,
    NooDatabase db,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Exporting to Obsidian format...'),
          ],
        ),
      ),
    );

    String? zipPath;
    String? error;
    var tasksExported = 0;
    try {
      final tmp = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final vaultDir = Directory(p.join(tmp.path, 'obsidian_export_$stamp'));
      await vaultDir.create(recursive: true);

      final exportResult = await ObsidianExportService(db).export(vaultDir.path);
      if (exportResult.success) {
        tasksExported = exportResult.tasksExported;
        zipPath = p.join(tmp.path, 'noo-obsidian-export.zip');
        await ZipFileEncoder().zipDirectory(vaultDir, filename: zipPath);
        // Non-ASCII task titles become directory names; without this the
        // archive claims a DOS host and extractors mangle them.
        await markZipEntriesAsUnixHost(zipPath);
      } else {
        error = exportResult.error;
      }
      await vaultDir.delete(recursive: true);
    } catch (e) {
      error = e.toString();
    }

    if (!context.mounted) return;
    Navigator.of(context).pop(); // progress dialog

    if (zipPath != null) {
      await shareFile(zipPath, title: 'Obsidian export ($tasksExported tasks)');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  static Future<void> importObsidian(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    if (db == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open a database first')),
      );
      return;
    }

    // Mobile counterpart of the zip export: pick a .zip, unpack to the temp
    // dir, and import the extracted vault.
    if (isMobilePlatform) {
      return _importObsidianFromZip(context, ref, db);
    }

    final result = await FilePicker.getDirectoryPath(
      dialogTitle: 'Import from Obsidian Directory',
    );

    if (result == null || !context.mounted) return;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Importing from Obsidian format...'),
          ],
        ),
      ),
    );

    final importService = ObsidianImportService(db);
    final importResult = await importService.import(result);

    // Close progress dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // Refresh the tree
    ref.read(taskTreeControllerProvider)?.loadTree();

    if (context.mounted) {
      if (importResult.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Imported ${importResult.tasksImported} tasks, '
              '${importResult.timeRecordsImported} time records',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: ${importResult.error}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Mobile import path: pick a .zip, extract to the temp dir, import the
  /// vault root inside it.
  static Future<void> _importObsidianFromZip(
    BuildContext context,
    WidgetRef ref,
    NooDatabase db,
  ) async {
    final picked = await FilePicker.pickFiles(
      dialogTitle: 'Import Obsidian .zip',
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final zipPath = picked.firstOrNull?.path;
    if (zipPath == null || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Importing from Obsidian format...'),
          ],
        ),
      ),
    );

    ObsidianImportResult? importResult;
    String? error;
    Directory? extractDir;
    try {
      final tmp = await getTemporaryDirectory();
      final stamp = DateTime.now().millisecondsSinceEpoch;
      extractDir = Directory(p.join(tmp.path, 'obsidian_import_$stamp'));
      await extractDir.create(recursive: true);
      await extractFileToDisk(zipPath, extractDir.path);

      // Zips often wrap the vault in a single top-level folder — descend into
      // it so the importer sees the vault root itself.
      var root = extractDir;
      final entries = root.listSync();
      if (entries.length == 1 && entries.single is Directory) {
        root = entries.single as Directory;
      }

      importResult = await ObsidianImportService(db).import(root.path);
    } catch (e) {
      error = e.toString();
    } finally {
      try {
        await extractDir?.delete(recursive: true);
      } catch (_) {}
    }

    if (!context.mounted) return;
    Navigator.of(context).pop(); // progress dialog

    // Refresh the tree
    ref.read(taskTreeControllerProvider)?.loadTree();

    if (importResult != null && importResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${importResult.tasksImported} tasks, '
            '${importResult.timeRecordsImported} time records',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: ${importResult?.error ?? error}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  static Future<void> syncNow(BuildContext context, WidgetRef ref) async {
    final service = ref.read(syncServiceProvider);
    if (service == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync not configured. Open Sync Settings first.')),
      );
      return;
    }
    // Server sync only. Without one this is not an error state to open a
    // staged progress dialog over — the device still syncs, just with nearby
    // devices instead, which is Shift+F5.
    if (!service.hasRelay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No sync server configured. Use Sync P2P... '
            '(Shift+F5), or add a server in Preferences.',
          ),
        ),
      );
      return;
    }

    // Surface the detailed, staged progress view. The run is driven by
    // runSyncWithProgress (which feeds syncProgressProvider and keeps the
    // toolbar indicator + task tree in sync), so this dialog stays purely
    // presentational and dismissing it does not interrupt the sync.
    final alreadyRunning =
        ref.read(syncStatusProvider.notifier).value == SyncStatus.syncing;
    showSyncProgressDialog(context);

    // If a sync is already in flight (e.g. an auto-sync tick), just show its
    // progress instead of starting a competing run.
    if (alreadyRunning) return;
    await runSyncWithProgress(ref);
  }

  /// Sync directly with this account's devices on the same network.
  ///
  /// Like the relay's Sync Now, nothing moves until someone asks: the dialog
  /// starts discovery and the peer server, syncs with every device that also
  /// has it open, and stops both when closed.
  static Future<void> syncWithPeers(BuildContext context, WidgetRef ref) =>
      showP2pSyncDialog(context);

  static void showPreferences(
    BuildContext context,
    WidgetRef ref, {
    int initialTab = 0,
  }) {
    showDialog(
      context: context,
      builder: (context) => PreferencesDialog(initialTab: initialTab),
    );
  }

  static Future<void> exitApp(BuildContext context, WidgetRef ref) async {
    if (await runExitSequence(ref)) exit(0);
  }

  /// Shared shutdown work run before the process terminates, from both the
  /// Exit menu action and the OS window-close button. Finalizes any active
  /// tracking session and, when the user has opted in and there are unsynced
  /// changes, asks whether to sync them first. Never throws — a shutdown must
  /// always be able to complete.
  ///
  /// Returns `true` if the app should proceed to close, or `false` if the user
  /// cancelled the exit from the prompt (so the window stays open).
  static Future<bool> runExitSequence(WidgetRef ref) async {
    // Flush the editor's debounced auto-save first: destroy() tears the
    // process down without disposing widgets, so content typed since the
    // last auto-save tick would otherwise be lost.
    final flushEditor = ref.read(editorFlushProvider);
    if (flushEditor != null) {
      try {
        await flushEditor();
      } catch (_) {
        // Exit must complete even if the final save fails.
      }
    }

    // Persist the tree's expansion set and focused node while the database is
    // still open — the last change may still be in flight.
    try {
      await ref.read(taskTreeControllerProvider)?.flushUiState();
    } catch (_) {
      // View state is disposable; never hold up an exit for it.
    }

    // Finalize any running tracking session before terminating, otherwise
    // the open-ended record stays open and gets resumed on next launch. Do this
    // first so its finalized record counts as a pending change below.
    await _stopActiveTracking(ref);

    // Sync-on-exit prompt: if the user opted in and there are unsynced local
    // changes, ask whether to sync before closing. This does no automatic
    // syncing — the user decides. Any failure here must never block the exit.
    final settings = ref.read(settingsProvider);
    final syncService = ref.read(syncServiceProvider);
    if (settings.syncEnabled && settings.syncOnExit && syncService != null) {
      try {
        if (await syncService.hasPendingLocalChanges()) {
          final choice = await _promptSyncOnExit();
          switch (choice) {
            case _ExitSyncChoice.cancel:
              return false; // Abort the close; keep the app open.
            case _ExitSyncChoice.sync:
              await runSyncWithProgress(ref);
            case _ExitSyncChoice.discard:
              break; // Close without syncing.
          }
        }
      } catch (_) {
        // Ignore: exit must not be prevented by a sync problem.
      }
    }

    return true;
  }

  /// Ask the user whether to sync unsynced changes before the app closes.
  /// Rendered via the root navigator so it works even when the exit is driven
  /// by the OS window-close button (no live widget [BuildContext]). Returns
  /// [_ExitSyncChoice.discard] if no navigator/context is available.
  static Future<_ExitSyncChoice> _promptSyncOnExit() async {
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return _ExitSyncChoice.discard;

    final choice = await showDialog<_ExitSyncChoice>(
      context: navContext,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Unsynced changes'),
        content: const Text(
          'There are unsynced changes; do you want to sync them?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_ExitSyncChoice.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_ExitSyncChoice.discard),
            child: const Text("Don't sync"),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(_ExitSyncChoice.sync),
            child: const Text('Sync'),
          ),
        ],
      ),
    );

    // A dismissed dialog (barrier tap is disabled, but guard anyway) is treated
    // as "cancel" so we never close behind the user's back.
    return choice ?? _ExitSyncChoice.cancel;
  }

  static void showRegistration(BuildContext context, WidgetRef ref) {
    // TODO: Implement registration dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registration: Not implemented yet')),
    );
  }

  static void showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NooAboutDialog(),
    );
  }

  static Future<void> showTimeline(BuildContext context, WidgetRef ref) async {
    final selectedId = ref.read(selectedTaskIdProvider);
    if (selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a task first')),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    if (db == null) return;

    final entries = await db.getTimelineForTask(selectedId);
    final records = entries.map((e) => TimeRecord(
      id: e.id,
      taskId: e.taskId,
      worldId: WorldId.fromString(e.worldId),
      startTime: DateTime.parse(e.startTime).toUtc(),
      endTime: e.endTime != null ? DateTime.parse(e.endTime!).toUtc() : null,
      saved: true,
    )).toList();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => TimelineDialog(
        taskId: selectedId,
        timeLine: TimeLine(records: records),
        onChanged: () {
          ref.read(timelineRefreshProvider.notifier).value++;
        },
      ),
    );
  }

  static void showTimeReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TimeReportDialog(),
    );
  }

  static void viewChangeHistory(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const HistoryViewerDialog(),
    );
  }

  static Future<void> generateTestData(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    if (db == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No database open')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Test Data'),
        content: const Text(
          'This will create sample tasks with hierarchy and time records.\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final generator = TestDataGenerator(db);
    await generator.generateTestData(
      topLevelTasks: 5,
      maxDepth: 3,
      maxChildrenPerTask: 4,
    );

    // Refresh the tree
    ref.read(taskTreeControllerProvider)?.loadTree();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test data generated successfully')),
      );
    }
  }

  static Future<void> generateLargeTestData(
      BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    if (db == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No database open')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Large Dataset'),
        content: const Text(
          'This will create a large dataset with:\n'
          '- 20 top-level tasks\n'
          '- Up to 5 levels deep\n'
          '- Up to 6 children per task\n'
          '- Time records for many tasks\n\n'
          'This may take a moment. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Generating data...'),
          ],
        ),
      ),
    );

    final generator = TestDataGenerator(db);
    await generator.generateTestData(
      topLevelTasks: 20,
      maxDepth: 5,
      maxChildrenPerTask: 6,
    );

    // Close loading dialog
    if (context.mounted) {
      Navigator.of(context).pop();
    }

    // Refresh the tree
    ref.read(taskTreeControllerProvider)?.loadTree();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Large dataset generated successfully')),
      );
    }
  }

  /// Shrink the open database file: drop the redundant old text still held by
  /// legacy history rows, then `VACUUM` so the freed pages leave the file.
  ///
  /// Both steps are content-preserving, so this only ever costs time — which
  /// is why the run is behind a modal barrier: the vacuum holds the single
  /// connection, and letting the user keep editing would only queue writes
  /// behind it.
  static Future<void> compactDatabase(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    final path = ref.read(currentDatabasePathProvider);
    if (db == null || path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No database open')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compact Database'),
        content: const Text(
          'Rewrites the database file so the space held by deleted tasks, '
          'attachments and old change history is returned to the disk.\n\n'
          'The contents of deleted attachments are released too, and are '
          'downloaded again from the server if you ever restore one.\n\n'
          'Nothing you can still see is removed. On a large database this '
          'takes a while, and the app cannot be used until it finishes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Compact'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Compacting database...'),
          ],
        ),
      ),
    );

    final file = File(path);
    // A file we cannot stat still compacts fine; we just skip the savings
    // figure rather than failing the whole operation over it.
    final before = await _fileSizeOrNull(file);
    Object? failure;
    String? blocked;
    try {
      await db.compactTaskHistoryOldValues();
      // Legacy content rows can reappear from a database merged in behind our
      // back (the same reason the task-history compaction runs here and not
      // only in the migration).
      await db.compactFileHistoryContent();
      // Deleted attachments are the largest thing a device holds on to, but
      // their bytes may be the last copy — the sync service is what knows
      // whether the fleet can give them back.
      final sync = ref.read(syncServiceProvider);
      if (sync != null) {
        final collected = await sync.collectRemovedBlobs();
        blocked = collected.blocked;
      }
      await db.vacuum();
    } catch (e) {
      failure = e;
    }
    final after = await _fileSizeOrNull(file);

    if (!context.mounted) return;
    // Close the progress dialog.
    Navigator.of(context).pop();

    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Compacting failed: $failure'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final String message;
    if (before == null || after == null) {
      message = 'Database compacted';
    } else if (before - after > 0) {
      message = 'Database compacted — ${formatBytes(before - after)} freed '
          '(now ${formatBytes(after)})';
    } else {
      message = 'Database compacted — already compact '
          '(${formatBytes(after)})';
    }
    // The file still shrank; say separately that deleted attachments were
    // kept, so the reason is visible rather than guessed at.
    if (blocked != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$message. $blocked')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  static Future<int?> _fileSizeOrNull(File file) async {
    try {
      return await file.length();
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearAllData(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    if (db == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No database open')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all tasks, time records, and attachments.\n\n'
          'This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Clear selection first
    ref.read(selectedTaskIdProvider.notifier).value = null;

    final generator = TestDataGenerator(db);
    await generator.clearAllData();

    // Refresh the tree
    ref.read(taskTreeControllerProvider)?.loadTree();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared')),
      );
    }
  }
}
