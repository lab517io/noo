import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/noo_chrome.dart';

/// Whether the app draws its own title bar — menu, window title and caption
/// buttons on a single strip — instead of letting the OS draw one above the
/// menu.
///
/// Windows and Linux only. On macOS the menu belongs in the system menu bar at
/// the top of the screen and the traffic lights are placed by the OS, so
/// hiding the title bar there would gain nothing and cost the standard look.
///
/// Off, too, when the user asked for the desktop's own title bar and frame
/// ([applySystemTitleBar]): the menu bar then sits under the native bar as a
/// plain strip of its own.
bool get usesCustomTitleBar =>
    !kIsWeb && (Platform.isWindows || Platform.isLinux) && !_systemTitleBar;

bool _systemTitleBar = false;

/// Switches the window between the desktop's own title bar and frame
/// ([system]) and the app-drawn strip, and records which for
/// [usesCustomTitleBar].
///
/// Called by `main` before the window is first shown, and again by the app
/// whenever the preference changes — window_manager swaps the frame of a
/// running window on both platforms (Linux re-decorates it or shows the GTK
/// header bar; Windows recomputes the non-client area), so the choice applies
/// at once. The record is updated synchronously, before the native call, so
/// widgets rebuilt for the same change already lay out for the new frame.
Future<void> applySystemTitleBar(bool system) async {
  if (!offersSystemTitleBarChoice) return;
  _systemTitleBar = system;
  await windowManager.setTitleBarStyle(
    system ? TitleBarStyle.normal : TitleBarStyle.hidden,
    windowButtonVisibility: system,
  );
}

/// Records the frame without touching the window — for tests, which have no
/// native window to switch.
@visibleForTesting
void debugSetSystemTitleBar(bool system) => _systemTitleBar = system;

/// Whether this platform offers the choice at all.
bool get offersSystemTitleBarChoice =>
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
    this.menu,
    required this.title,
    this.height = kTitleBarHeight,
  });

  /// The application menu bar, laid out at its intrinsic width. Null when the
  /// style puts the menu on a row of its own ([NooChrome.menuBelowTitle]).
  final Widget? menu;

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

  /// Whether the window has the keyboard focus. A traditional title bar is
  /// drawn in the accent colour only while its window is the active one,
  /// which is how the user tells which window typing goes to.
  bool _isActive = true;

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

  @override
  void onWindowFocus() => setState(() => _isActive = true);

  @override
  void onWindowBlur() => setState(() => _isActive = false);

  Future<void> _syncMaximizedState() async {
    final maximized = await windowManager.isMaximized();
    if (mounted && maximized != _isMaximized) {
      setState(() => _isMaximized = maximized);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chrome = NooChrome.of(context);
    final background =
        _isActive ? chrome.titleBarColor : chrome.titleBarInactiveColor;
    final foreground = _isActive
        ? chrome.titleBarForeground
        : chrome.titleBarInactiveForeground;
    // The caption buttons draw dark or light glyphs; pick by what they sit on,
    // not by the theme — a classic bar is dark in the light theme.
    final brightness = ThemeData.estimateBrightnessForColor(background);
    final menu = widget.menu;

    final titleText = Text(
      widget.title,
      overflow: TextOverflow.ellipsis,
      style: chrome.titleBarBoldTitle
          ? theme.textTheme.labelLarge
              ?.copyWith(color: foreground, fontWeight: FontWeight.w600)
          : theme.textTheme.labelMedium?.copyWith(color: foreground),
    );

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: background,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        // Stretch so the caption buttons' hover highlight fills the strip and
        // the menu's own buttons are vertically centred against it.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?menu,
          Expanded(
            child: DragToMoveArea(
              // DragToMoveArea also handles double-click to maximize/restore.
              child: chrome.titleBarBoldTitle
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: titleText,
                      ),
                    )
                  : Center(child: titleText),
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
