import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// How bad a line in the app log is.
enum AppLogLevel { info, warning, error }

/// One line of the app log.
class AppLogEntry {
  AppLogEntry(this.time, this.level, this.message);

  final DateTime time;
  final AppLogLevel level;

  /// The text, possibly several lines (an error with its stack trace).
  final String message;

  /// `HH:mm:ss.mmm LEVEL message`, the form Copy and Save write.
  String format() {
    String two(int n) => n.toString().padLeft(2, '0');
    final t = time;
    final stamp = '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}:${two(t.second)}.'
        '${t.millisecond.toString().padLeft(3, '0')}';
    final tag = switch (level) {
      AppLogLevel.info => 'INFO ',
      AppLogLevel.warning => 'WARN ',
      AppLogLevel.error => 'ERROR',
    };
    return '$stamp $tag $message';
  }
}

/// The app's internal log: what Help → Logs → App Log shows.
///
/// In memory only, for the current run, and bounded ([capacity] lines, the
/// oldest dropped first). Nothing is written to disk: messages can name files
/// and tasks, and a log file would be one more place the app leaves readable
/// text outside the encrypted database. The user takes it out explicitly with
/// Copy or Save.
///
/// [install] routes into it everything the app already reports: every
/// `debugPrint`, framework errors (`FlutterError.onError`) and uncaught
/// asynchronous errors (`PlatformDispatcher.onError`). Each previous handler
/// is still called, so console output and Flutter's own error reporting are
/// unchanged.
class AppLog extends ChangeNotifier {
  AppLog({this.capacity = 5000});

  /// The process-wide log.
  static final AppLog instance = AppLog();

  final int capacity;
  final Queue<AppLogEntry> _entries = Queue<AppLogEntry>();
  bool _notifyScheduled = false;
  bool _installed = false;

  /// Lines dropped because the log was full, since start or the last [clear].
  int get dropped => _dropped;
  int _dropped = 0;

  /// The lines, oldest first.
  List<AppLogEntry> get entries => List.unmodifiable(_entries);

  void info(String message) => add(AppLogLevel.info, message);

  void warning(String message, [Object? error, StackTrace? stack]) =>
      add(AppLogLevel.warning, _withError(message, error, stack));

  void error(String message, [Object? error, StackTrace? stack]) =>
      add(AppLogLevel.error, _withError(message, error, stack));

  void add(AppLogLevel level, String message, {DateTime? time}) {
    _entries.addLast(AppLogEntry(time ?? DateTime.now(), level, message));
    while (_entries.length > capacity) {
      _entries.removeFirst();
      _dropped++;
    }
    _scheduleNotify();
  }

  void clear() {
    _entries.clear();
    _dropped = 0;
    _scheduleNotify();
  }

  /// The whole log as text, one entry per line (continuation lines indented).
  String toText() {
    final buffer = StringBuffer();
    if (_dropped > 0) {
      buffer.writeln('($_dropped earlier lines dropped)');
    }
    for (final e in _entries) {
      buffer.writeln(e.format().replaceAll('\n', '\n    '));
    }
    return buffer.toString();
  }

  /// Hook the log into debugPrint and the framework's error handlers. Called
  /// once from `main`; a second call does nothing.
  void install({String? header}) {
    if (_installed) return;
    _installed = true;

    info(header ??
        'Started on ${Platform.operatingSystem} '
            '${Platform.operatingSystemVersion}');

    final previousPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) info(message);
      previousPrint(message, wrapWidth: wrapWidth);
    };

    final previousFlutterError = FlutterError.onError;
    FlutterError.onError = (details) {
      error(
        details.exceptionAsString(),
        null,
        details.stack,
      );
      previousFlutterError?.call(details);
    };

    final dispatcher = PlatformDispatcher.instance;
    final previousPlatformError = dispatcher.onError;
    dispatcher.onError = (exception, stack) {
      error('Uncaught error', exception, stack);
      return previousPlatformError?.call(exception, stack) ?? false;
    };
  }

  // Lines arrive from build and layout (a framework error, a debugPrint in a
  // build method), where a listener's setState would throw. So listeners hear
  // of them a microtask later, once per burst.
  void _scheduleNotify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    scheduleMicrotask(() {
      _notifyScheduled = false;
      notifyListeners();
    });
  }

  static String _withError(String message, Object? error, StackTrace? stack) {
    final buffer = StringBuffer(message);
    if (error != null) buffer.write(': $error');
    if (stack != null) {
      final text = stack.toString().trimRight();
      if (text.isNotEmpty) buffer.write('\n$text');
    }
    return buffer.toString();
  }
}
