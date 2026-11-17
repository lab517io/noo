import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/platform/window_state.dart';

/// A single 1920×1080 display with a taskbar strip at the bottom.
const _primary = Rect.fromLTWH(0, 0, 1920, 1040);

/// A second display to the left of the primary one, as an undocked laptop
/// would have had.
const _secondary = Rect.fromLTWH(-1920, 0, 1920, 1040);

void main() {
  group('sanitizeWindowBounds', () {
    test('keeps bounds that sit on an attached display', () {
      const saved = Rect.fromLTWH(100, 80, 1200, 800);
      expect(
        WindowStateStore.sanitizeWindowBounds(saved, const [_primary]),
        saved,
      );
    });

    test('accepts a window hanging off the edge while still grabbable', () {
      // Only the left ~200px are on screen — enough title bar to drag back.
      const saved = Rect.fromLTWH(1720, 500, 1200, 800);
      expect(
        WindowStateStore.sanitizeWindowBounds(saved, const [_primary]),
        saved,
      );
    });

    test('rejects a position on a display that is no longer attached', () {
      const saved = Rect.fromLTWH(-1500, 200, 1200, 800);
      expect(
        WindowStateStore.sanitizeWindowBounds(saved, const [_primary]),
        isNull,
      );
      // Plug the monitor back in and the same position is fine again.
      expect(
        WindowStateStore.sanitizeWindowBounds(saved, const [_primary, _secondary]),
        saved,
      );
    });

    test('rejects a position with only a sliver on screen', () {
      // 20px wide overlap: not enough to aim at with a mouse.
      const saved = Rect.fromLTWH(1900, 400, 1200, 800);
      expect(
        WindowStateStore.sanitizeWindowBounds(saved, const [_primary]),
        isNull,
      );
    });

    test('grows a degenerate size back to the floor', () {
      const saved = Rect.fromLTWH(10, 10, 1, 1);
      final result =
          WindowStateStore.sanitizeWindowBounds(saved, const [_primary]);
      expect(result, isNotNull);
      expect(result!.size, WindowStateStore.minWindowSize);
      expect(result.topLeft, const Offset(10, 10));
    });

    test('shrinks a window larger than every display', () {
      const saved = Rect.fromLTWH(0, 0, 5000, 4000);
      final result =
          WindowStateStore.sanitizeWindowBounds(saved, const [_primary]);
      expect(result, isNotNull);
      expect(result!.size, const Size(1920, 1040));
    });

    test('trusts the stored bounds when no display info is available', () {
      const saved = Rect.fromLTWH(-4000, -4000, 1200, 800);
      expect(
        WindowStateStore.sanitizeWindowBounds(saved, const []),
        saved,
      );
    });
  });

  group('clampWindowSize', () {
    test('leaves a reasonable size alone', () {
      expect(
        WindowStateStore.clampWindowSize(const Size(1000, 700), const [_primary]),
        const Size(1000, 700),
      );
    });

    test('clamps to the largest display, not the smallest', () {
      const small = Rect.fromLTWH(0, 0, 800, 600);
      expect(
        WindowStateStore.clampWindowSize(
          const Size(1600, 900),
          const [small, _primary],
        ),
        const Size(1600, 900),
      );
    });
  });
}
