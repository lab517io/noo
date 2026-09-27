import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/platform_info.dart';
import 'data/services/sync_service.dart';
import 'platform/window_state.dart';
import 'presentation/providers/providers.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/screens/startup_screen.dart';
import 'presentation/widgets/app_menu_bar.dart';
import 'presentation/widgets/macos_menu_bar.dart';
import 'presentation/widgets/window_title_bar.dart';

/// Main application widget.
///
/// Also owns the desktop window-close hook: [main] enables `preventClose`, and
/// this widget's [WindowListener] runs the shared exit sequence (finalize
/// tracking, autosync on exit) before actually destroying the window, so the
/// OS window "X" button takes the same shutdown path as the Exit menu action.
class NooApp extends ConsumerStatefulWidget {
  const NooApp({super.key});

  @override
  ConsumerState<NooApp> createState() => _NooAppState();
}

class _NooAppState extends ConsumerState<NooApp> with WindowListener {
  bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  bool _closing = false;

  /// Mobile only: Android may kill a backgrounded app at any time with no
  /// further callbacks, so `paused` is the last reliable moment to persist —
  /// the desktop window-close shutdown sequence has no equivalent there.
  AppLifecycleListener? _lifecycleListener;

  /// Guards against overlapping pause work when the user flips between apps
  /// quickly (each background transition fires `onPause` again).
  bool _pauseWorkRunning = false;

  @override
  void initState() {
    super.initState();
    if (_isDesktop) {
      windowManager.addListener(this);
      _updateWindowTitle(ref.read(currentDatabaseFileNameProvider));
    }
    if (isMobilePlatform) {
      _lifecycleListener = AppLifecycleListener(
        onPause: () => unawaited(_persistOnMobilePause()),
      );
    }
  }

  /// Best-effort persistence when the app leaves the foreground: flush the
  /// editor's debounced auto-save, checkpoint the WAL so the main DB file is
  /// current, and — when the user opted into sync-on-exit — push pending
  /// changes (silently; the desktop exit prompt makes no sense mid-pause).
  /// Tracking sessions are deliberately left running: the open-ended record
  /// is already persisted, so a timer survives backgrounding and process
  /// death by design.
  Future<void> _persistOnMobilePause() async {
    if (_pauseWorkRunning) return;
    _pauseWorkRunning = true;
    try {
      final flushEditor = ref.read(editorFlushProvider);
      if (flushEditor != null) {
        try {
          await flushEditor();
        } catch (_) {}
      }

      try {
        await ref.read(taskTreeControllerProvider)?.flushUiState();
      } catch (_) {}

      final db = ref.read(databaseProvider);
      if (db != null) {
        try {
          await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE)');
        } catch (_) {}
      }

      final settings = ref.read(settingsProvider);
      final syncService = ref.read(syncServiceProvider);
      // Server sync only: sync-on-exit pushes to the relay. A LAN-only
      // device has nothing to contact unattended — its peers sync on request.
      if (settings.syncEnabled &&
          settings.syncOnExit &&
          syncService != null &&
          syncService.hasRelay) {
        try {
          final syncing =
              ref.read(syncStatusProvider.notifier).value == SyncStatus.syncing;
          if (!syncing && await syncService.hasPendingLocalChanges()) {
            await runSyncWithProgress(ref);
          }
        } catch (_) {
          // Never let a failed background sync surface during pause.
        }
      }
    } finally {
      _pauseWorkRunning = false;
    }
  }

  /// Keep the window title showing the app name and the open database. Where
  /// the native title bar is hidden [WindowTitleBar] draws this same text, but
  /// the OS title still feeds the taskbar and the alt-tab switcher, so it is
  /// set either way.
  void _updateWindowTitle(String? fileName) {
    if (!_isDesktop) return;
    unawaited(windowManager.setTitle(windowTitleText(fileName)));
  }

  @override
  void dispose() {
    if (_isDesktop) windowManager.removeListener(this);
    _lifecycleListener?.dispose();
    super.dispose();
  }

  // Window geometry is remembered across runs: every move, resize and
  // maximize toggle schedules a (debounced) write. onWindowResized/Moved fire
  // once the drag ends, unlike their onWindowResize/Move counterparts which
  // fire continuously.
  @override
  void onWindowResized() => WindowStateStore.scheduleSave();

  @override
  void onWindowMoved() => WindowStateStore.scheduleSave();

  @override
  void onWindowMaximize() => WindowStateStore.scheduleSave();

  @override
  void onWindowUnmaximize() => WindowStateStore.scheduleSave();

  @override
  void onWindowEnterFullScreen() => WindowStateStore.scheduleSave();

  @override
  void onWindowLeaveFullScreen() => WindowStateStore.scheduleSave();

  @override
  void onWindowClose() async {
    // Guard against re-entrancy: a second close event while we're already
    // shutting down must not run the sequence twice.
    if (_closing) return;
    _closing = true;
    try {
      // Record the final geometry before anything can tear the window down.
      await WindowStateStore.save();
      final proceed = await AppMenuBar.runExitSequence(ref);
      if (proceed) {
        await windowManager.destroy();
      } else {
        // User cancelled the exit from the sync prompt; keep the window open
        // and allow a later close attempt to run the sequence again.
        _closing = false;
      }
    } catch (_) {
      // A shutdown must always be able to complete: if the sequence itself
      // throws, destroy the window anyway.
      await windowManager.destroy();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    ref.listen(currentDatabaseFileNameProvider,
        (_, fileName) => _updateWindowTitle(fileName));

    return MaterialApp(
      title: AppConstants.appName,
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: _withChromeFont(AppTheme.light, settings),
      darkTheme: _withChromeFont(AppTheme.dark, settings),
      themeMode: settings.themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        FlutterQuillLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
      ],
      builder: _withPlatformChrome,
      home: const StartupScreen(),
    );
  }

  /// Wraps the whole app in the platform's own chrome where it has any.
  ///
  /// macOS: the system menu bar, installed here rather than around the main
  /// screen so it exists for the app's whole life — the startup and welcome
  /// screens have no menu bar of their own, and a macOS app without a menu is
  /// not a macOS app.
  ///
  /// Linux: hiding the title bar there undecorates the window, which also
  /// removes the window manager's resize borders (GNOME keeps its client-side
  /// frame, other desktops do not). Overlay 8px drag-to-resize strips on the
  /// window edges so the window stays resizable everywhere. This is a Stack
  /// overlay, so it costs no layout space.
  Widget _withPlatformChrome(BuildContext context, Widget? child) {
    if (child == null) return const SizedBox.shrink();
    if (usesPlatformMenuBar) return MacosMenuBar(child: child);
    if (!usesCustomTitleBar || !Platform.isLinux) return child;
    return DragToResizeArea(child: child);
  }

  /// Apply the chrome font family and scale factor from [s] to a base theme.
  ThemeData _withChromeFont(ThemeData base, AppSettings s) => chromeScaledTheme(
        base,
        family: s.chromeFontFamily,
        scale: s.chromeFontScale,
      );
}
