import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/utils/duration_formatter.dart';
import '../../../core/utils/platform_info.dart';
import '../../../platform/minimize_intercept.dart';
import '../../../platform/window_state.dart';
import '../../providers/providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/tracking_indicator_provider.dart';
import '../../providers/value_controller.dart';
import '../window_title_bar.dart';
import 'time_tracking_actions.dart';
import '../../../l10n/l10n.dart';

/// The mini tracker: the main window shrunk to a small always-on-top pill
/// showing the running clock, which can be dragged anywhere on screen and put
/// back with a double-click.
///
/// It is the main window itself, not a second one. A second native window
/// would be a second Flutter engine with its own isolate, sharing none of
/// the providers and none of the database; shrinking the window keeps one of
/// everything. The full app stays mounted underneath, offstage and laid out
/// at its old size ([MiniTrackerHost]), so the editor, the tree's scroll
/// position and any unsaved text are exactly where they were.
///
/// Where the platform allows. Windows, macOS and X11 honour always-on-top and
/// a chosen position; a Wayland compositor decides both itself, so there the
/// pill is small and draggable but goes behind the next window clicked.

/// The size the full app had when the mini tracker opened, or null while it
/// is not open. The app is laid out at this size underneath the pill.
final miniTrackerProvider = valueProvider<Size?>(null);

/// The pill's window size, in logical pixels.
const Size kMiniTrackerSize = Size(320, 44);

/// Whether this platform can have a mini tracker at all.
bool get offersMiniTracker => isDesktopPlatform;

/// Whether a minimize right now should become the pill: the preference is
/// on, a clock is running in an open database, and the pill is not up.
final _minimizeTakesPillProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider);
  return offersMiniTracker &&
      settings.timeTrackingEnabled &&
      settings.miniTrackerOnMinimize &&
      ref.watch(databaseProvider) != null &&
      ref.watch(activeTrackingTaskIdProvider) != null &&
      ref.watch(miniTrackerProvider) == null;
});

class _Restore {
  const _Restore(this.bounds, this.maximized, this.fullScreen);
  final Rect? bounds;
  final bool maximized;
  final bool fullScreen;
}

/// Opens and closes the mini tracker. Static, because the window's minimize
/// paths (the caption button, the OS) and its close handler all reach it.
///
/// There is no command that opens it: it takes the place of minimizing,
/// while a clock runs and Preferences → Behavior → Time tracking → *Show mini
/// window while tracking* is on ([AppSettings.miniTrackerOnMinimize]).
class MiniTracker {
  MiniTracker._();

  /// Set by the mounted [MiniTrackerHost]: whether a minimize right now
  /// should become the pill, and how to open it. Null while no host is up.
  static bool Function()? _takesMinimize;
  static Future<void> Function()? _enterInstead;

  /// The caption button's minimize. Goes straight to the pill when the
  /// preference applies, rather than minimizing and coming back (which
  /// [MiniTrackerHost] does for a minimize the OS started).
  static Future<void> minimize() async {
    final enter = _enterInstead;
    if (enter != null && (_takesMinimize?.call() ?? false)) {
      await enter();
      return;
    }
    await _minimizeForReal();
  }

  /// Past the runner's intercept, which would otherwise hand a minimize the
  /// app itself asked for straight back.
  static Future<void> _minimizeForReal() async {
    if (await MinimizeIntercept.minimizeNow()) return;
    try {
      await windowManager.minimize();
    } catch (_) {}
  }

  static const _keyX = 'mini_tracker_x';
  static const _keyY = 'mini_tracker_y';

  static _Restore? _restore;
  static Future<void>? _pending;

  /// Shrink the window to the pill. [context] is any context inside the app,
  /// read for the size the app is to keep underneath.
  static Future<void> enter(BuildContext context, WidgetRef ref) async {
    if (!offersMiniTracker) return;
    final appSize = MediaQuery.sizeOf(context);
    await _serialize(() => _enter(ref, appSize));
  }

  /// Put the window back as it was. Returns whether the mini tracker was open.
  static Future<bool> leave(WidgetRef ref) async {
    var wasOpen = false;
    await _serialize(() async {
      wasOpen = ref.read(miniTrackerProvider) != null;
      if (wasOpen) await _leave(ref);
    });
    return wasOpen;
  }

  /// The window was minimized by something other than [minimize] — the
  /// taskbar, Cmd+M, the Window menu: bring it back and shrink it to the pill.
  static Future<void> _enterFromMinimized(WidgetRef ref, Size appSize) =>
      _serialize(() async {
        if (ref.read(miniTrackerProvider) != null) return;
        await _run(windowManager.restore);
        // Bounds and maximized state read during the de-miniaturize
        // animation are the icon's, not the window's.
        await Future<void>.delayed(
          Duration(milliseconds: Platform.isMacOS ? 500 : 150),
        );
        await _enter(ref, appSize);
      });

  /// One transition at a time: a leave asked for while the window is still
  /// shrinking (the close button pressed at once) runs after it, so it
  /// restores the geometry the enter recorded rather than racing it.
  static Future<void> _serialize(Future<void> Function() body) {
    final previous = _pending ?? Future<void>.value();
    final next = previous.then((_) => body());
    final guarded = next.catchError((Object _) {});
    _pending = guarded;
    return next.whenComplete(() {
      if (identical(_pending, guarded)) _pending = null;
    });
  }

  static Future<void> _enter(WidgetRef ref, Size appSize) async {
    if (ref.read(miniTrackerProvider) != null) return;

    final fullScreen = await _ask(windowManager.isFullScreen, false);
    final maximized = await _ask(windowManager.isMaximized, false);
    final bounds = await _ask<Rect?>(windowManager.getBounds, null);
    _restore = _Restore(bounds, maximized, fullScreen);

    // Before the window changes: the moves and resizes below are not the
    // user's geometry, and the app is frozen at its size before the window
    // gets small enough to squeeze it.
    WindowStateStore.suspended = true;
    ref.read(miniTrackerProvider.notifier).value = appSize;

    if (fullScreen) {
      await _run(() => windowManager.setFullScreen(false));
      // macOS animates out of full screen and ignores a resize meanwhile.
      if (Platform.isMacOS) {
        await Future<void>.delayed(const Duration(milliseconds: 800));
      }
    }
    if (maximized) await _run(windowManager.unmaximize);
    await _run(
      () => windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: false,
      ),
    );
    await _run(() => windowManager.setAlwaysOnTop(true));
    if (Platform.isMacOS) {
      await _run(() => windowManager.setVisibleOnAllWorkspaces(true));
    }
    final position = await _pillPosition(bounds);
    await _run(
      () => windowManager.setBounds(
        null,
        position: position,
        size: kMiniTrackerSize,
      ),
    );
    // The pill's size is its layout: no resize edges, and no maximize from
    // a double-click, Win+Up or a window-manager shortcut.
    await _run(() => windowManager.setResizable(false));
    await _run(() => windowManager.setMaximizable(false));
  }

  static Future<void> _leave(WidgetRef ref) async {
    final restore = _restore;
    _restore = null;

    // Where the user dragged the pill is where it opens next time.
    final position = await _ask<Offset?>(windowManager.getPosition, null);
    if (position != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(_keyX, position.dx);
        await prefs.setDouble(_keyY, position.dy);
      } catch (_) {}
    }

    await _run(() => windowManager.setResizable(true));
    await _run(() => windowManager.setMaximizable(true));
    if (Platform.isMacOS) {
      await _run(() => windowManager.setVisibleOnAllWorkspaces(false));
    }
    await _run(() => windowManager.setAlwaysOnTop(false));
    if (offersSystemTitleBarChoice) {
      await _run(
        () => applySystemTitleBar(ref.read(settingsProvider).useSystemTitleBar),
      );
    } else {
      await _run(() => windowManager.setTitleBarStyle(TitleBarStyle.normal));
    }
    if (restore?.bounds case final bounds?) {
      await _run(() => windowManager.setBounds(bounds));
    }
    if (restore?.maximized ?? false) await _run(windowManager.maximize);
    if (restore?.fullScreen ?? false) {
      await _run(() => windowManager.setFullScreen(true));
    }

    ref.read(miniTrackerProvider.notifier).value = null;
    WindowStateStore.suspended = false;
    // Written from what was recorded, not read back: the window may not have
    // reported its restored size yet, and a read now could store the pill's.
    if (restore != null) {
      final maximized = restore.maximized || restore.fullScreen;
      await WindowStateStore.saveGeometry(
        maximized ? null : restore.bounds,
        maximized: maximized,
      );
    }
    await _run(windowManager.focus);
    restoreEditorFocus(ref);
  }

  /// The pill's last position, while it still lands on a display; otherwise
  /// the top-right corner of the display the window is on.
  static Future<Offset?> _pillPosition(Rect? windowBounds) async {
    final displays = await WindowStateStore.visibleDisplayRects();
    try {
      final prefs = await SharedPreferences.getInstance();
      final x = prefs.getDouble(_keyX);
      final y = prefs.getDouble(_keyY);
      if (x != null && y != null) {
        final saved = Offset(x, y);
        if (displays.isEmpty || pillFits(saved, displays)) return saved;
      }
    } catch (_) {}
    if (displays.isEmpty) return null;
    final center = windowBounds?.center;
    final display = displays.firstWhere(
      (d) => center != null && d.contains(center),
      orElse: () => displays.first,
    );
    return Offset(
      display.right - kMiniTrackerSize.width - 24,
      display.top + 24,
    );
  }

  /// Whether enough of a pill at [position] is on one of [displays] to grab.
  @visibleForTesting
  static bool pillFits(Offset position, List<Rect> displays) {
    final pill = position & kMiniTrackerSize;
    for (final d in displays) {
      final w = math.min(pill.right, d.right) - math.max(pill.left, d.left);
      final h = math.min(pill.bottom, d.bottom) - math.max(pill.top, d.top);
      if (w >= 64 && h >= kMiniTrackerSize.height / 2) return true;
    }
    return false;
  }

  /// A window call that must not stop the sequence: a platform that lacks
  /// one of them (setVisibleOnAllWorkspaces off macOS, anything under a
  /// Wayland compositor that refuses) still gets the rest.
  static Future<void> _run(Future<void> Function() call) async {
    try {
      await call();
    } catch (_) {}
  }

  static Future<T> _ask<T>(Future<T> Function() call, T fallback) async {
    try {
      return await call();
    } catch (_) {
      return fallback;
    }
  }
}

/// Keeps the app mounted while the mini tracker is up, and shows the pill
/// over it. Installed once around the whole app (`MaterialApp.builder`).
///
/// The widget structure is the same either way — only the parameters change
/// — so turning the pill on and off never rebuilds the app from scratch.
/// Underneath, the app is laid out at the size it had ([miniTrackerProvider])
/// rather than at the pill's: a 44px-high window would otherwise switch it to
/// the phone layout and tear the editor down. It is offstage (not painted, not
/// hit), its tickers are paused, and focus is kept out of it so its keyboard
/// shortcuts cannot open dialogs nobody can see.
class MiniTrackerHost extends ConsumerStatefulWidget {
  const MiniTrackerHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MiniTrackerHost> createState() => _MiniTrackerHostState();
}

class _MiniTrackerHostState extends ConsumerState<MiniTrackerHost>
    with WindowListener {
  /// The app's size the last time it was laid out full, kept because a
  /// minimized window may report no size at all.
  Size? _appSize;

  @override
  void initState() {
    super.initState();
    if (!offersMiniTracker) return;
    MiniTracker._takesMinimize = _takesMinimize;
    MiniTracker._enterInstead = _enterNow;
    // The runner holds a system minimize back only while this is true, so
    // the window never leaves for the Dock or taskbar just to come back.
    ref.listenManual<bool>(
      _minimizeTakesPillProvider,
      (_, takes) => unawaited(MinimizeIntercept.setIntercept(takes)),
      fireImmediately: true,
    );
    MinimizeIntercept.onRequested = () {
      if (_takesMinimize()) {
        unawaited(_enterNow());
      } else {
        // Held back on a state that has changed since: minimize after all.
        unawaited(MiniTracker._minimizeForReal());
      }
    };
    try {
      windowManager.addListener(this);
    } catch (_) {}
  }

  Future<void> _enterNow() =>
      MiniTracker._serialize(() => MiniTracker._enter(ref, _currentAppSize));

  @override
  void dispose() {
    if (offersMiniTracker) {
      MiniTracker._takesMinimize = null;
      MiniTracker._enterInstead = null;
      MinimizeIntercept.onRequested = null;
      unawaited(MinimizeIntercept.setIntercept(false));
      try {
        windowManager.removeListener(this);
      } catch (_) {}
    }
    super.dispose();
  }

  Size get _currentAppSize => _appSize ?? MediaQuery.sizeOf(context);

  /// A clock is running, the user asked for the pill in its place, and there
  /// is a database to track in.
  bool _takesMinimize() => mounted && ref.read(_minimizeTakesPillProvider);

  /// The fallback, for a minimize nothing could hold back: Linux under a
  /// system title bar, or one that slipped in before the runner was told.
  @override
  void onWindowMinimize() {
    if (_takesMinimize()) {
      unawaited(MiniTracker._enterFromMinimized(ref, _currentAppSize));
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    final frozen = ref.watch(miniTrackerProvider);
    final mini = frozen != null;

    // Nothing left to track: a closed or swapped-out database, or time
    // tracking turned off.
    ref.listen(databaseProvider, (previous, next) {
      if (previous != next && ref.read(miniTrackerProvider) != null) {
        unawaited(MiniTracker.leave(ref));
      }
    });
    ref.listen(settingsProvider.select((s) => s.timeTrackingEnabled), (
      _,
      enabled,
    ) {
      if (!enabled && ref.read(miniTrackerProvider) != null) {
        unawaited(MiniTracker.leave(ref));
      }
    });

    final media = MediaQuery.of(context);
    if (!mini && !media.size.isEmpty) _appSize = media.size;
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Offstage(
          offstage: mini,
          child: ExcludeFocus(
            excluding: mini,
            child: TickerMode(
              enabled: !mini,
              child: MediaQuery(
                data: mini ? media.copyWith(size: frozen) : media,
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: frozen?.width,
                  maxWidth: frozen?.width,
                  minHeight: frozen?.height,
                  maxHeight: frozen?.height,
                  child: child,
                ),
              ),
            ),
          ),
        ),
        if (mini) const Positioned.fill(child: MiniTrackerBar()),
      ],
    );
  }
}

/// The pill: a dot, the tracked task and its running time, stop, and the way
/// back. Not tracking, it offers to start on the selected task instead.
///
/// The whole bar but its buttons is the drag handle; a double-click on it
/// restores the window, as do the button and Escape.
class MiniTrackerBar extends ConsumerWidget {
  const MiniTrackerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final trackedId = ref.watch(activeTrackingTaskIdProvider);
    final selectedId = ref.watch(selectedTaskIdProvider);
    final tracking = trackedId != null;
    final title = tracking
        ? ref.watch(trackedTaskTitleProvider) ?? context.l10n.commonUntitled
        : ref.watch(selectedTaskTitleProvider) ?? context.l10n.timeNotTracking;
    final elapsed = ref.watch(trackingElapsedProvider) ?? Duration.zero;
    final showSeconds = ref.watch(
      settingsProvider.select((s) => s.showSeconds),
    );
    final hint = theme.colorScheme.outline;

    void back() => unawaited(MiniTracker.leave(ref));

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): back,
      },
      child: Focus(
        autofocus: true,
        child: Material(
          color: theme.colorScheme.surfaceContainerHigh,
          shape: Border.all(color: theme.colorScheme.outlineVariant),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  key: const ValueKey('mini-tracker-handle'),
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (_) => unawaited(
                    windowManager.startDragging().catchError((_) {}),
                  ),
                  onDoubleTap: back,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: tracking ? theme.colorScheme.error : hint,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: tracking ? null : hint,
                            ),
                          ),
                        ),
                        if (tracking) ...[
                          const SizedBox(width: 8),
                          Text(
                            DurationFormatter.formatHMS(
                              elapsed,
                              showSeconds: showSeconds,
                            ),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // No tooltips here: the window is too short to show one.
              if (tracking)
                _PillButton(
                  key: const ValueKey('mini-tracker-stop'),
                  icon: Icons.stop,
                  color: theme.colorScheme.error,
                  label: context.l10n.timeStopTracking,
                  onPressed: () => toggleTracking(ref, trackedId),
                )
              else if (selectedId != null)
                _PillButton(
                  key: const ValueKey('mini-tracker-start'),
                  icon: Icons.play_arrow,
                  label: context.l10n.timeStartTracking,
                  onPressed: () => toggleTracking(ref, selectedId),
                ),
              _PillButton(
                key: const ValueKey('mini-tracker-restore'),
                icon: Icons.open_in_full,
                label: context.l10n.timeBackToFullWindow,
                onPressed: back,
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }
}
