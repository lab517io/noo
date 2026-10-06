import 'package:flutter_test/flutter_test.dart';
import 'package:noo/presentation/providers/quick_sync.dart';

/// Real timers at millisecond scale: the scheduler is plain Dart, and the
/// durations are parameters.
void main() {
  late int runs;
  late bool pending;
  late bool succeed;
  late DateTime clock;
  DateTime? lastSync;

  QuickSyncScheduler make() => QuickSyncScheduler(
        run: () async {
          runs++;
          pending = false;
          return succeed;
        },
        hasPending: () async => pending,
        lastSync: () => lastSync,
        debounce: const Duration(milliseconds: 30),
        pullInterval: const Duration(seconds: 30),
        backoff: const Duration(minutes: 2),
        now: () => clock,
      );

  Future<void> settle() => Future.delayed(const Duration(milliseconds: 80));

  setUp(() {
    runs = 0;
    pending = true;
    succeed = true;
    clock = DateTime(2026, 10, 5, 12);
    lastSync = null;
  });

  test('a burst of edits costs one run, after the debounce', () async {
    final s = make();
    for (var i = 0; i < 5; i++) {
      s.localChange();
      await Future.delayed(const Duration(milliseconds: 5));
    }
    expect(runs, 0);
    await settle();
    expect(runs, 1);
    s.dispose();
  });

  test('a change with nothing pending (a sync applying remote edits) '
      'does not run', () async {
    final s = make();
    pending = false;
    s.localChange();
    await settle();
    expect(runs, 0);
    s.dispose();
  });

  test('opening notes syncs at most once per pull interval', () async {
    final s = make();
    s.freshenUp();
    await settle();
    expect(runs, 1);

    clock = clock.add(const Duration(seconds: 10));
    s.freshenUp();
    await settle();
    expect(runs, 1);

    clock = clock.add(const Duration(seconds: 25));
    s.freshenUp();
    await settle();
    expect(runs, 2);
    s.dispose();
  });

  test('a recent sync by another path counts', () async {
    final s = make();
    lastSync = clock.subtract(const Duration(seconds: 5));
    s.freshenUp();
    await settle();
    expect(runs, 0);
    s.dispose();
  });

  test('after a failure nothing runs until the backoff ends', () async {
    final s = make();
    succeed = false;
    s.freshenUp();
    await settle();
    expect(runs, 1);

    pending = true;
    clock = clock.add(const Duration(minutes: 1));
    s.localChange();
    s.freshenUp();
    await settle();
    expect(runs, 1);

    clock = clock.add(const Duration(minutes: 2));
    s.localChange();
    await settle();
    expect(runs, 2);
    s.dispose();
  });

  test('nothing runs after dispose', () async {
    final s = make();
    s.localChange();
    s.dispose();
    s.freshenUp();
    await settle();
    expect(runs, 0);
  });
}
