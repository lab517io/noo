import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/constants/app_constants.dart';

/// Whether the app draws its own title bar — menu, window title and caption
/// buttons on a single strip — instead of letting the OS draw one above the
/// menu.
///
/// Windows and Linux only. On macOS the menu belongs in the system menu bar at
/// the top of the screen and the traffic lights are placed by the OS, so
/// hiding the title bar there would gain nothing and cost the standard look.
bool get usesCustomTitleBar =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux);

/// The window title, shown in the custom bar and — via `setTitle` — in the
/// taskbar and alt-tab switcher, which still read the OS title even when the
/// native bar is hidden.
String windowTitleText(String? databaseFileName) => databaseFileName == null
    ? AppConstants.appName
    : '${AppConstants.appName} — $databaseFileName';

/// Height of the custom title bar at the default chrome font scale. Matches
/// window_manager's `kWindowCaptionHeight`, which is also the natural size of
/// its caption buttons.
const double kTitleBarHeight = 32;

/// Height of the custom title bar for the given chrome font scale, so a larger
/// UI font doesn't get clipped by the strip it sits in.
double titleBarHeightFor(double chromeFontScale) =>
    kTitleBarHeight * chromeFontScale.clamp(1.0, 1.5);

/// Title bar drawn by the app itself: the [menu] on the left, the window title
/// in the middle doubling as the drag handle, and minimize / maximize / close
/// on the right.
///
/// Only rendered when [usesCustomTitleBar] is true and `main` has hidden the
/// native bar via `setTitleBarStyle(TitleBarStyle.hidden)`.
class WindowTitleBar extends StatefulWidget {
  const WindowTitleBar({
    super.key,
    required this.menu,
    required this.title,
    this.height = kTitleBarHeight,
  });

  /// The application menu bar, laid out at its intrinsic width.
  final Widget menu;

  /// Text drawn in the middle of the bar.
  final String title;

  /// Height of the strip.
  final double height;

  @override
  State<WindowTitleBar> createState() => _WindowTitleBarState();
}

class _WindowTitleBarState extends State<WindowTitleBar> with WindowListener {
  /// Drives the maximize/restore icon. Seeded from the window because the app
  /// may start maximized, then kept current by the window events below.
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    unawaited(_syncMaximizedState());
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => setState(() => _isMaximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _isMaximized = false);

  Future<void> _syncMaximizedState() async {
    final maximized = await windowManager.isMaximized();
    if (mounted && maximized != _isMaximized) {
      setState(() => _isMaximized = maximized);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        // Stretch so the caption buttons' hover highlight fills the strip and
        // the menu's own buttons are vertically centred against it.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.menu,
          Expanded(
            child: DragToMoveArea(
              // DragToMoveArea also handles double-click to maximize/restore.
              child: Center(
                child: Text(
                  widget.title,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          WindowCaptionButton.minimize(
            brightness: brightness,
            onPressed: () => unawaited(windowManager.minimize()),
          ),
          if (_isMaximized)
            WindowCaptionButton.unmaximize(
              brightness: brightness,
              onPressed: () => unawaited(windowManager.unmaximize()),
            )
          else
            WindowCaptionButton.maximize(
              brightness: brightness,
              onPressed: () => unawaited(windowManager.maximize()),
            ),
          WindowCaptionButton.close(
            brightness: brightness,
            // close(), not destroy(): `preventClose` is on, so this takes the
            // same shutdown path as the native X and the Exit menu item —
            // NooApp's WindowListener runs the exit sequence first.
            onPressed: () => unawaited(windowManager.close()),
          ),
        ],
      ),
    );
  }
}
