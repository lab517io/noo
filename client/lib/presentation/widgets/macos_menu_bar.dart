import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/install_source.dart';
import '../../core/utils/menu_shortcuts.dart';
import '../providers/providers.dart';
import '../providers/settings_provider.dart';
import 'app_menu_bar.dart';
import 'dialogs/app_log_dialog.dart';
import 'dialogs/sync_log_dialog.dart';
import 'search/search_dialog.dart';
import '../../l10n/l10n.dart';

/// The application menu in the macOS system menu bar.
///
/// macOS puts one menu bar at the top of the screen for the active app, so the
/// commands [AppMenuBar] draws inside the window on Windows and Linux are
/// handed to the OS here instead, as a real `NSMenu`. Mounted from `app.dart`
/// around the whole app rather than around the main screen, because the system
/// menu bar must exist for as long as the app does — including on the startup
/// and welcome screens, and in a window narrow enough to fall back to the
/// compact layout, neither of which mounts [AppMenuBar].
///
/// Actions are the same statics the in-window menu calls. They need a
/// `BuildContext` below the navigator for dialogs and snack bars, which this
/// widget sits above, so they take [rootNavigatorKey]'s context — resolved at
/// selection time, when a route is always mounted.
class MacosMenuBar extends ConsumerWidget {
  const MacosMenuBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PlatformMenuBar(
      menus: _menus(ref),
      child: child,
    );
  }

  /// The navigator's context, or null before the first route is mounted.
  static BuildContext? get _context => rootNavigatorKey.currentContext;

  /// Wraps a handler for a menu item. A false [enabled] returns null, which is
  /// what greys the item out natively; a selection arriving before the first
  /// route is mounted is dropped rather than run without a context.
  static VoidCallback? _action(
    void Function(BuildContext context) run, {
    bool enabled = true,
  }) {
    if (!enabled) return null;
    return () {
      final context = _context;
      if (context != null) run(context);
    };
  }

  List<PlatformMenuItem> _menus(WidgetRef ref) {
    // A database gates everything that reads or writes one. Disabling those
    // items is the macOS way of saying so — better than the snack bar the
    // in-window menu shows after the fact.
    final hasDatabase = ref.watch(databaseProvider) != null;
    final themeMode = ref.watch(themeModeProvider);

    return <PlatformMenuItem>[
      _appMenu(ref),
      _fileMenu(ref, hasDatabase: hasDatabase),
      _editMenu(),
      _viewMenu(ref, themeMode: themeMode, hasDatabase: hasDatabase),
      _toolsMenu(ref, hasDatabase: hasDatabase),
      if (kDebugMode) _debugMenu(ref),
      _windowMenu(),
      _helpMenu(hasDatabase: hasDatabase),
    ];
  }

  /// The bold, leftmost menu named after the app. macOS expects About,
  /// Settings, the Services submenu, the hide/show items and Quit here — not
  /// in File or Help, where the other platforms keep them.
  PlatformMenu _appMenu(WidgetRef ref) {
    return PlatformMenu(
      label: AppConstants.appName,
      menus: <PlatformMenuItem>[
        PlatformMenuItemGroup(
          members: <PlatformMenuItem>[
            PlatformMenuItem(
              label: appL10n.appMenuAbout(AppConstants.appName),
              onSelected: _action(AppMenuBar.showAbout),
            ),
            // Where macOS apps put it, under About. The dialog only checks
            // and offers the disk image: nothing is replaced in place here.
            if (InstallSource.offersUpdateCheck)
              PlatformMenuItem(
                label: appL10n.appMacMenuCheckForUpdate,
                onSelected: _action(
                  (context) => AppMenuBar.checkForUpdate(context, ref),
                ),
              ),
          ],
        ),
        PlatformMenuItemGroup(
          members: <PlatformMenuItem>[
            PlatformMenuItem(
              // "Settings…" since macOS 13; the dialog itself is the app's
              // Preferences on every platform.
              label: appL10n.appMacMenuSettings,
              shortcut: primaryActivator(LogicalKeyboardKey.comma),
              onSelected:
                  _action((context) => AppMenuBar.showPreferences(context, ref)),
            ),
          ],
        ),
        const PlatformMenuItemGroup(
          members: <PlatformMenuItem>[
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.servicesSubmenu,
            ),
          ],
        ),
        const PlatformMenuItemGroup(
          members: <PlatformMenuItem>[
            PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.hide),
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.hideOtherApplications,
            ),
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.showAllApplications,
            ),
          ],
        ),
        PlatformMenuItemGroup(
          members: <PlatformMenuItem>[
            PlatformMenuItem(
              // Deliberately not PlatformProvidedMenuItemType.quit: that one
              // calls `terminate:` straight away, skipping the shutdown
              // sequence (finalize tracking, sync on exit) that every other
              // way out of the app runs.
              label: appL10n.appMacMenuQuit(AppConstants.appName),
              shortcut: primaryActivator(LogicalKeyboardKey.keyQ),
              onSelected: _action((context) => AppMenuBar.exitApp(context, ref)),
            ),
          ],
        ),
      ],
    );
  }

  PlatformMenu _fileMenu(WidgetRef ref, {required bool hasDatabase}) {
    return PlatformMenu(
      label: appL10n.appMenuFile,
      menus: <PlatformMenuItem>[
        PlatformMenuItemGroup(
          members: <PlatformMenuItem>[
            PlatformMenuItem(
              label: appL10n.appMacMenuOpen,
              shortcut: primaryActivator(LogicalKeyboardKey.keyO),
              onSelected:
                  _action((context) => AppMenuBar.openDatabase(context, ref)),
            ),
            PlatformMenuItem(
              label: appL10n.appMacMenuNewDatabase,
              onSelected:
                  _action((context) => AppMenuBar.newDatabase(context, ref)),
            ),
          ],
        ),
        PlatformMenuItemGroup(
          members: <PlatformMenuItem>[
            PlatformMenuItem(
              label: appL10n.appMacMenuExportObsidian,
              shortcut: primaryActivator(LogicalKeyboardKey.keyE),
              onSelected: _action(
                (context) => AppMenuBar.exportObsidian(context, ref),
                enabled: hasDatabase,
              ),
            ),
            PlatformMenuItem(
              label: appL10n.appMacMenuImportObsidian,
              onSelected: _action(
                (context) => AppMenuBar.importObsidian(context, ref),
                enabled: hasDatabase,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// The standard Edit menu. macOS expects it, and the items double as the
  /// discoverable list of the editor's clipboard commands.
  ///
  /// These dispatch intents rather than calling code directly: the key
  /// equivalents are handled by Flutter's own text-editing shortcuts before
  /// AppKit ever offers them to the menu, so the intents only run when the
  /// user picks the item with the mouse — and they then act on whatever has
  /// focus, exactly as the keys would have.
  PlatformMenu _editMenu() {
    return PlatformMenu(
      label: appL10n.appMenuEdit,
      menus: <PlatformMenuItem>[
        PlatformMenuItemGroup(
          members: <PlatformMenuItem>[
            PlatformMenuItem(
              label: appL10n.appMacMenuUndo,
              shortcut: primaryActivator(LogicalKeyboardKey.keyZ),
              onSelectedIntent:
                  const UndoTextIntent(SelectionChangedCause.keyboard),
            ),
            PlatformMenuItem(
              label: appL10n.appMacMenuRedo,
              shortcut: primaryActivator(LogicalKeyboardKey.keyZ, shift: true),
              onSelectedIntent:
                  const RedoTextIntent(SelectionChangedCause.keyboard),
            ),
          ],
        ),
        PlatformMenuItemGroup(
          members: <PlatformMenuItem>[
            PlatformMenuItem(
              label: appL10n.appMacMenuCut,
              shortcut: primaryActivator(LogicalKeyboardKey.keyX),
              onSelectedIntent:
                  const CopySelectionTextIntent.cut(SelectionChangedCause.keyboard),
            ),
            PlatformMenuItem(
              label: appL10n.commonCopy,
              shortcut: primaryActivator(LogicalKeyboardKey.keyC),
              onSelectedIntent: CopySelectionTextIntent.copy,
            ),
            PlatformMenuItem(
              label: appL10n.appMacMenuPaste,
              shortcut: primaryActivator(LogicalKeyboardKey.keyV),
              onSelectedIntent:
                  const PasteTextIntent(SelectionChangedCause.keyboard),
            ),
          ],
        ),
        PlatformMenuItemGroup(
          members: <PlatformMenuItem>[
            PlatformMenuItem(
              label: appL10n.appMacMenuSelectAll,
              shortcut: primaryActivator(LogicalKeyboardKey.keyA),
              onSelectedIntent:
                  const SelectAllTextIntent(SelectionChangedCause.keyboard),
            ),
          ],
        ),
      ],
    );
  }

  PlatformMenu _viewMenu(
    WidgetRef ref, {
    required ThemeMode themeMode,
    required bool hasDatabase,
  }) {
    return PlatformMenu(
      label: appL10n.appMenuView,
      menus: <PlatformMenuItem>[
        PlatformMenuItemGroup(
          members: <PlatformMenuItem>[
            PlatformMenuItem(
              label: appL10n.appMacMenuFind,
              shortcut: findActivator,
              onSelected: _action(showSearchDialog, enabled: hasDatabase),
            ),
          ],
        ),
        PlatformMenuItemGroup(
          members: <PlatformMenuItem>[
            PlatformMenu(
              label: appL10n.appMenuTheme,
              menus: <PlatformMenuItem>[
                for (final entry in <ThemeMode, String>{
                  ThemeMode.system: appL10n.appThemeSystem,
                  ThemeMode.light: appL10n.appThemeLight,
                  ThemeMode.dark: appL10n.appThemeDark,
                }.entries)
                  PlatformMenuItem(
                    // A platform menu item carries no checked state, so the
                    // active one is marked in its label instead.
                    label: themeMode == entry.key
                        ? appL10n.appMacMenuChecked(entry.value)
                        : entry.value,
                    onSelected: () => ref
                        .read(settingsProvider.notifier)
                        .setThemeMode(entry.key),
                  ),
              ],
            ),
          ],
        ),
        const PlatformMenuItemGroup(
          members: <PlatformMenuItem>[
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.toggleFullScreen,
            ),
          ],
        ),
      ],
    );
  }

  PlatformMenu _toolsMenu(WidgetRef ref, {required bool hasDatabase}) {
    return PlatformMenu(
      label: appL10n.appMenuTools,
      menus: <PlatformMenuItem>[
        if (ref.watch(settingsProvider.select((s) => s.timeTrackingEnabled)))
          PlatformMenuItemGroup(
            members: <PlatformMenuItem>[
              PlatformMenuItem(
                label: appL10n.appMacMenuTimeline,
                shortcut: primaryActivator(LogicalKeyboardKey.keyT, shift: true),
                onSelected: _action(
                  (context) => AppMenuBar.showTimeline(context, ref),
                  enabled: hasDatabase,
                ),
              ),
              PlatformMenuItem(
                label: appL10n.appMacMenuTimeReport,
                shortcut: primaryActivator(LogicalKeyboardKey.keyR, shift: true),
                onSelected: _action(
                  AppMenuBar.showTimeReport,
                  enabled: hasDatabase,
                ),
              ),
            ],
          ),
        PlatformMenuItemGroup(
          members: <PlatformMenuItem>[
            PlatformMenuItem(
              label: appL10n.appMacMenuCompactDatabase,
              onSelected: _action(
                (context) => AppMenuBar.compactDatabase(context, ref),
                enabled: hasDatabase,
              ),
            ),
          ],
        ),
        PlatformMenuItemGroup(
          members: <PlatformMenuItem>[
            PlatformMenuItem(
              label: appL10n.appMenuSyncNow,
              shortcut: const SingleActivator(LogicalKeyboardKey.f5),
              onSelected: _action(
                (context) => AppMenuBar.syncNow(context, ref),
                enabled: hasDatabase,
              ),
            ),
            PlatformMenuItem(
              label: appL10n.appMacMenuSyncP2p,
              shortcut:
                  const SingleActivator(LogicalKeyboardKey.f5, shift: true),
              onSelected: _action(
                (context) => AppMenuBar.syncWithPeers(context, ref),
                enabled: hasDatabase,
              ),
            ),
          ],
        ),
      ],
    );
  }

  PlatformMenu _debugMenu(WidgetRef ref) {
    return PlatformMenu(
      label: appL10n.appMenuDebug,
      menus: <PlatformMenuItem>[
        PlatformMenuItemGroup(
          members: <PlatformMenuItem>[
            PlatformMenuItem(
              label: appL10n.appMacMenuViewChangeHistory,
              onSelected: _action(AppMenuBar.viewChangeHistory),
            ),
          ],
        ),
        PlatformMenuItemGroup(
          members: <PlatformMenuItem>[
            PlatformMenuItem(
              label: appL10n.appMenuGenerateTestData,
              onSelected:
                  _action((context) => AppMenuBar.generateTestData(context, ref)),
            ),
            PlatformMenuItem(
              label: appL10n.appMenuGenerateLargeDataset,
              onSelected: _action(
                  (context) => AppMenuBar.generateLargeTestData(context, ref)),
            ),
          ],
        ),
        PlatformMenuItemGroup(
          members: <PlatformMenuItem>[
            PlatformMenuItem(
              label: appL10n.appMenuClearAllData,
              onSelected:
                  _action((context) => AppMenuBar.clearAllData(context, ref)),
            ),
          ],
        ),
      ],
    );
  }

  /// Help, last as on every Mac. About and Check for Update live in the app
  /// menu here; what Help holds is the Logs submenu.
  PlatformMenu _helpMenu({required bool hasDatabase}) {
    return PlatformMenu(
      label: appL10n.appMenuHelp,
      menus: <PlatformMenuItem>[
        PlatformMenu(
          label: appL10n.appMenuLogs,
          menus: <PlatformMenuItem>[
            PlatformMenuItem(
              label: appL10n.appMacMenuSyncLog,
              onSelected: _action(showSyncLogDialog, enabled: hasDatabase),
            ),
            PlatformMenuItem(
              label: appL10n.appMacMenuAppLog,
              onSelected: _action(showAppLogDialog),
            ),
          ],
        ),
      ],
    );
  }

  /// Minimize / Zoom / Bring All to Front, all handled by the window server.
  PlatformMenu _windowMenu() {
    return PlatformMenu(
      label: appL10n.appMenuWindow,
      menus: const <PlatformMenuItem>[
        PlatformMenuItemGroup(
          members: <PlatformMenuItem>[
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.minimizeWindow,
            ),
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.zoomWindow,
            ),
          ],
        ),
        PlatformMenuItemGroup(
          members: <PlatformMenuItem>[
            PlatformProvidedMenuItem(
              type: PlatformProvidedMenuItemType.arrangeWindowsInFront,
            ),
          ],
        ),
      ],
    );
  }
}
