import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

/// Remembers the desktop window's geometry across runs.
///
/// This lives in SharedPreferences rather than the database: the window is
/// created and positioned in `main`, long before a database is chosen (the
/// password prompt is itself drawn in that window), and its geometry belongs
/// to the machine, not to the file being edited.
///
/// A restored position is never trusted blindly — the display it was saved on
/// may be gone (undocked laptop, unplugged monitor), which would place the
/// window somewhere the user cannot reach. See [sanitizeWindowBounds].
class WindowStateStore {
  WindowStateStore._();

  static const String _keyX = 'window_x';
  static const String _keyY = 'window_y';
  static const String _keyWidth = 'window_width';
  static const String _keyHeight = 'window_height';
  static const String _keyMaximized = 'window_maximized';

  /// Never restore a window smaller than this; a stored 1×1 (or a garbage
  /// value from a crashed session) would be impossible to grab.
  @visibleForTesting
  static const Size minWindowSize = Size(480, 360);

  /// How much of the window has to overlap a display for the position to be
  /// considered usable — roughly "enough title bar to drag it back".
  static const Size _minVisible = Size(160, 32);

  static Timer? _saveTimer;

  static bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  /// Apply the stored geometry. Call once from `main`, after
  /// `windowManager.ensureInitialized()` and before the first frame.
  static Future<void> restore() async {
    if (!_isDesktop) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final width = prefs.getDouble(_keyWidth);
      final height = prefs.getDouble(_keyHeight);
      // Nothing stored yet: leave the platform default alone.
      if (width == null || height == null) return;

      final x = prefs.getDouble(_keyX);
      final y = prefs.getDouble(_keyY);
      final displays = await _visibleDisplayRects();

      final saved = (x == null || y == null)
          ? null
          : Rect.fromLTWH(x, y, width, height);
      final bounds =
          saved == null ? null : sanitizeWindowBounds(saved, displays);

      if (bounds != null) {
        await windowManager.setBounds(bounds);
      } else {
        // The saved position is off every current display. Keep the size the
        // user chose, but put the window back where it can be seen.
        await windowManager.setSize(
          clampWindowSize(Size(width, height), displays),
        );
        await windowManager.setAlignment(Alignment.center);
      }

      if (prefs.getBool(_keyMaximized) ?? false) {
        await windowManager.maximize();
      }
    } catch (_) {
      // A window that opens at its default size is a far better outcome than
      // an app that fails to start.
    }
  }

  /// Store the geometry after a short delay, so dragging or resizing costs one
  /// write at the end instead of one per frame of the drag.
  static void scheduleSave() {
    if (!_isDesktop) return;
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () => unawaited(save()));
  }

  /// Store the geometry now. Called on the close path, where the debounce
  /// timer would never fire.
  static Future<void> save() async {
    if (!_isDesktop) return;
    _saveTimer?.cancel();
    _saveTimer = null;

    try {
      // A minimized window has no meaningful geometry to record.
      if (await windowManager.isMinimized()) return;

      final prefs = await SharedPreferences.getInstance();
      final maximized =
          await windowManager.isMaximized() || await windowManager.isFullScreen();
      await prefs.setBool(_keyMaximized, maximized);
      // While maximized, getBounds reports the screen. Keep the last normal
      // geometry so unmaximizing after a restart lands where the user left it.
      if (maximized) return;

      final bounds = await windowManager.getBounds();
      if (bounds.width < 1 || bounds.height < 1) return;

      await prefs.setDouble(_keyX, bounds.left);
      await prefs.setDouble(_keyY, bounds.top);
      await prefs.setDouble(_keyWidth, bounds.width);
      await prefs.setDouble(_keyHeight, bounds.height);
    } catch (_) {
      // Best-effort: losing the geometry costs a default-sized window.
    }
  }

  /// The saved bounds made safe for the displays currently attached, or null
  /// when the position cannot be used at all and the caller should re-center.
  ///
  /// [displays] are the work areas (screen minus taskbar/panels). An empty
  /// list means the platform told us nothing, in which case the saved values
  /// are taken at face value apart from the size floor.
  @visibleForTesting
  static Rect? sanitizeWindowBounds(Rect saved, List<Rect> displays) {
    final size = clampWindowSize(saved.size, displays);
    final candidate = Rect.fromLTWH(saved.left, saved.top, size.width, size.height);
    if (displays.isEmpty) return candidate;

    for (final display in displays) {
      final overlapWidth = math.min(candidate.right, display.right) -
          math.max(candidate.left, display.left);
      final overlapHeight = math.min(candidate.bottom, display.bottom) -
          math.max(candidate.top, display.top);
      if (overlapWidth >= _minVisible.width &&
          overlapHeight >= _minVisible.height) {
        return candidate;
      }
    }
    return null;
  }

  /// Clamp a stored size to something that fits on the largest display and is
  /// still big enough to use.
  @visibleForTesting
  static Size clampWindowSize(Size size, List<Rect> displays) {
    var maxWidth = double.infinity;
    var maxHeight = double.infinity;
    for (final display in displays) {
      maxWidth = maxWidth.isInfinite
          ? display.width
          : math.max(maxWidth, display.width);
      maxHeight = maxHeight.isInfinite
          ? display.height
          : math.max(maxHeight, display.height);
    }
    return Size(
      size.width.clamp(minWindowSize.width, math.max(maxWidth, minWindowSize.width)),
      size.height
          .clamp(minWindowSize.height, math.max(maxHeight, minWindowSize.height)),
    );
  }

  /// Work areas of all attached displays, in the same logical-pixel space
  /// `window_manager` reports bounds in. Empty when the platform channel is
  /// unavailable (headless test host, unsupported desktop).
  static Future<List<Rect>> _visibleDisplayRects() async {
    try {
      final displays = await screenRetriever.getAllDisplays();
      return [
        for (final display in displays)
          (display.visiblePosition ?? Offset.zero) &
              (display.visibleSize ?? display.size),
      ];
    } catch (_) {
      return const <Rect>[];
    }
  }
}
