import 'dart:async';

/// When to run the relay sync behind "Sync while editing" (Preferences →
/// Sync). The point is to shrink the window in which two devices can edit
/// the same note without seeing each other's change — the only edits that
/// end up merged or kept as a conflict copy (docs/P2P_SYNC.md §8.3).
///
/// - **After an edit**: a sync [debounce] after the last local change, so a
///   burst of typing costs one run, and only when something is still pending
///   — the history tables also change when a sync *applies* remote edits,
///   and those must not set off another run.
/// - **On opening a note, or the app coming back**: a sync so the note is
///   edited from its latest version, at most once per [pullInterval].
/// - **After a failure**: nothing for [backoff], so an offline laptop does
///   not try the relay after every keystroke. Edits made meanwhile go out
///   with the first run after it.
///
/// Free of Flutter and Riverpod so the timing can be tested on its own; the
/// provider supplies [run], which reports whether the run succeeded.
class QuickSyncScheduler {
  QuickSyncScheduler({
    required this.run,
    required this.hasPending,
    this.lastSync,
    this.debounce = const Duration(seconds: 10),
    this.pullInterval = const Duration(seconds: 30),
    this.backoff = const Duration(minutes: 2),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final Future<bool> Function() run;
  final Future<bool> Function() hasPending;

  /// The last successful sync by any path (manual, scheduled, this one), so a
  /// note opened just after F5 does not sync again.
  final DateTime? Function()? lastSync;

  final Duration debounce;
  final Duration pullInterval;
  final Duration backoff;
  final DateTime Function() _now;

  Timer? _timer;
  bool _running = false;
  bool _disposed = false;
  DateTime? _lastRun;
  DateTime? _backoffUntil;

  /// A local change was recorded.
  void localChange() => _arm(debounce);

  /// A note was opened, or the app came back to the foreground.
  void freshenUp() {
    final now = _now();
    final last = _latest(_lastRun, lastSync?.call());
    if (last != null && now.difference(last) < pullInterval) return;
    unawaited(_run());
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
  }

  void _arm(Duration delay) {
    if (_disposed) return;
    _timer?.cancel();
    _timer = Timer(delay, () => unawaited(_pushIfPending()));
  }

  Future<void> _pushIfPending() async {
    if (_disposed) return;
    if (!await hasPending()) return;
    await _run();
  }

  Future<void> _run() async {
    if (_disposed) return;
    final until = _backoffUntil;
    if (until != null) {
      final wait = until.difference(_now());
      if (wait > Duration.zero) {
        // Come back when the backoff ends rather than dropping the request:
        // the edit that asked for it is still unsent.
        if (!(_timer?.isActive ?? false)) _arm(wait);
        return;
      }
    }
    if (_running) {
      // One run at a time. Edits made during it are past its watermark, so
      // look again once it is done.
      _arm(debounce);
      return;
    }
    _running = true;
    try {
      final ok = await run();
      _lastRun = _now();
      _backoffUntil = ok ? null : _lastRun!.add(backoff);
    } finally {
      _running = false;
    }
  }

  static DateTime? _latest(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }
}
