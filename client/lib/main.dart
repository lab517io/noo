import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unix_single_instance/unix_single_instance.dart';
import 'package:window_manager/window_manager.dart';
import 'package:windows_single_instance/windows_single_instance.dart';
import 'app.dart';
import 'platform/app_registration.dart';
import 'platform/playback_proxy.dart';
import 'platform/window_state.dart';
import 'presentation/providers/providers.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/widgets/task_editor/resilient_clipboard_service.dart';
import 'presentation/widgets/window_title_bar.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  final isDesktop = Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  // Before anything can touch GLib: audio playback goes through a loopback
  // HTTP server, and GStreamer would otherwise route it via the desktop proxy.
  bypassProxyForLocalPlayback();

  // On desktop, intercept the window-close button so the app can run its
  // shutdown sequence (finalize tracking, autosync on exit) before quitting.
  // The actual close is performed by NooApp's WindowListener via destroy().
  if (isDesktop) {
    await windowManager.ensureInitialized();

    // Single-instance enforcement (opt-in via Preferences → Behavior). Read the
    // flag straight from SharedPreferences: the settings provider isn't wired up
    // this early, and we must decide before ever showing a second window.
    final prefs = await SharedPreferences.getInstance();
    final singleInstance =
        prefs.getBool(SettingsKeys.singleInstance) ?? false;
    if (singleInstance) {
      await _enforceSingleInstance(args);
    }

    await windowManager.setPreventClose(true);

    // Hide the OS title bar where the app draws its own (Windows/Linux): the
    // menu, window title and caption buttons then share one strip instead of
    // stacking the menu under a native bar. The native frame — and with it the
    // resize borders — survives on Windows; on Linux the decorations go away
    // entirely, so app.dart adds its own resize edges there.
    if (usesCustomTitleBar) {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: false,
      );
    }

    // Put the window back where it was last time. After the title-bar style,
    // which itself resizes the frame, and before the first frame is drawn.
    await WindowStateStore.restore();
  }

  // SQLCipher needs no setup here any more. package:sqlite3 3.x resolves its
  // native library through a Dart build hook, and `hooks.user_defines.sqlite3.
  // source: sqlcipher` in pubspec.yaml selects the SQLCipher build for every
  // platform — so the cipher symbols are the only sqlite3 symbols in the bundle
  // and there is no plain-libsqlite3 fallback left to guard against.
  // database.dart still asserts `PRAGMA cipher_version` before keying, which is
  // what catches a misconfigured build.

  // ToDo: configure logging

  // Before any editor exists: flutter_quill probes the clipboard for rich
  // content before falling back to plain text, and an exception from one of
  // those probes takes the whole paste down with it. See
  // ResilientClipboardService.
  installResilientClipboardService();

  // Register app in system application list (best-effort, non-blocking)
  registerApp();

  // Parse command line arguments for database path
  String? initialDbPath;
  if (args.isNotEmpty) {
    final path = args.first;
    // Check if file exists or parent directory exists (for new databases)
    final file = File(path);
    final parentDir = file.parent;
    if (await file.exists() || await parentDir.exists()) {
      initialDbPath = path;
    }
  }

  // Create provider container with overrides if needed
  final container = ProviderContainer(
    overrides: [
      if (initialDbPath != null)
        initialDatabasePathProvider.overrideWithValue(initialDbPath),
    ],
  );

  // Database initialization is handled by StartupScreen
  // to allow for password prompts

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const NooApp(),
    ),
  );
}

/// Enforce a single running instance on desktop.
///
/// Windows and Unix (Linux/macOS) use different plugins, but the behavior is
/// the same: a second launch forwards its args to the already-running process
/// and then exits, and the running process surfaces its window. Both plugins
/// exit the duplicate themselves; on Unix we also guard on the return value.
Future<void> _enforceSingleInstance(List<String> args) async {
  const identifier = 'io_lab517_noo';

  if (Platform.isWindows) {
    // The plugin forwards args over a named pipe, brings the primary window to
    // front natively, and exits the duplicate. onSecondWindow additionally
    // restores/focuses via window_manager (covers a minimized window).
    await WindowsSingleInstance.ensureSingleInstance(
      args,
      identifier,
      onSecondWindow: (_) => _bringWindowToFront(),
    );
    return;
  }

  // Linux + macOS: unix-domain socket. Returns false for a duplicate (which it
  // also exits internally); the guard is belt-and-suspenders. This plugin does
  // not raise the window itself, so the primary does it from the callback.
  final isPrimary = await unixSingleInstance(
    args,
    (_) => _bringWindowToFront(),
  );
  if (!isPrimary) exit(0);
}

/// Restore and focus this (primary) instance's window when a second launch
/// hands off to it. Each step is best-effort so a platform that doesn't support
/// one of them still surfaces the window as far as it can.
Future<void> _bringWindowToFront() async {
  try {
    if (await windowManager.isMinimized()) {
      await windowManager.restore();
    }
    await windowManager.show();
    await windowManager.focus();
  } catch (_) {
    // Never let a focus attempt crash the running instance.
  }
}
