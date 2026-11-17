
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/app_log.dart';

void main() {
  test('keeps the newest lines up to its capacity and counts the rest', () {
    final log = AppLog(capacity: 3);
    for (var i = 0; i < 5; i++) {
      log.info('line $i');
    }
    expect(log.entries.map((e) => e.message), ['line 2', 'line 3', 'line 4']);
    expect(log.dropped, 2);
    expect(log.toText(), startsWith('(2 earlier lines dropped)\n'));

    log.clear();
    expect(log.entries, isEmpty);
    expect(log.dropped, 0);
  });

  test('an error carries its exception and stack, indented in the text', () {
    final log = AppLog();
    log.error('Sync failed', StateError('boom'), StackTrace.fromString('#0 a\n#1 b'));
    final entry = log.entries.single;
    expect(entry.level, AppLogLevel.error);
    expect(entry.message, 'Sync failed: Bad state: boom\n#0 a\n#1 b');
    expect(log.toText(), contains('ERROR Sync failed: Bad state: boom\n    #0 a\n    #1 b'));
  });

  test('listeners hear of lines a microtask later, once per burst', () async {
    final log = AppLog();
    var calls = 0;
    log.addListener(() => calls++);
    log.info('a');
    log.info('b');
    expect(calls, 0);
    await Future<void>.delayed(Duration.zero);
    expect(calls, 1);
  });

  test('install records debugPrint, framework and uncaught errors and keeps '
      'the previous handlers', () {
    final savedPrint = debugPrint;
    final savedFlutterError = FlutterError.onError;
    final savedPlatformError = PlatformDispatcher.instance.onError;
    addTearDown(() {
      debugPrint = savedPrint;
      FlutterError.onError = savedFlutterError;
      PlatformDispatcher.instance.onError = savedPlatformError;
    });

    final printed = <String?>[];
    debugPrint = (message, {wrapWidth}) => printed.add(message);
    final reported = <FlutterErrorDetails>[];
    FlutterError.onError = reported.add;
    PlatformDispatcher.instance.onError = (_, _) => true;

    final log = AppLog();
    log.install(header: 'hello');
    debugPrint('from debugPrint');
    final details = FlutterErrorDetails(exception: Exception('layout'));
    FlutterError.onError!(details);
    final handled = PlatformDispatcher.instance.onError!(
        StateError('async'), StackTrace.empty);

    expect(log.entries.map((e) => e.message), [
      'hello',
      'from debugPrint',
      'Exception: layout',
      'Uncaught error: Bad state: async',
    ]);
    expect(printed, ['from debugPrint']);
    expect(reported, [details]);
    expect(handled, isTrue);
  });
}
