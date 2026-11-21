import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Lets the app take a minimize over *before* the window moves.
///
/// window_manager reports a minimize only once it has happened, and undoing
/// it afterwards means the window flies into the Dock or taskbar and straight
/// back out. The macOS and Windows runners (`MainFlutterWindow.swift`,
/// `flutter_window.cpp`) can instead hold a minimize the system asked for —
/// the yellow button, Cmd+M, Window → Minimize; the taskbar, Win+Down, the
/// system menu — and report it here, while [setIntercept] is on.
///
/// Linux has no such hook: there the window manager iconifies the window
/// itself. The app's own caption button goes through `MiniTracker.minimize`
/// on every platform, so only a minimize from a system title bar there still
/// takes the round trip.
class MinimizeIntercept {
  MinimizeIntercept._();

  static const _channel = MethodChannel('io.lab517.noo/minimize');

  static bool get supported =>
      !kIsWeb && (Platform.isMacOS || Platform.isWindows);

  static bool _installed = false;
  static bool? _intercepting;
  static VoidCallback? _onRequested;

  /// Called for each minimize held back while intercepting.
  static set onRequested(VoidCallback? callback) {
    _onRequested = callback;
    if (_installed || !supported) return;
    _installed = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'minimizeRequested') _onRequested?.call();
    });
  }

  /// Whether a system minimize is held back and reported. Only sent when it
  /// changes.
  static Future<void> setIntercept(bool on) async {
    if (!supported || _intercepting == on) return;
    _intercepting = on;
    try {
      await _channel.invokeMethod<void>('setIntercept', on);
    } on MissingPluginException {
      // Tests, or a runner built before the channel existed.
    } on PlatformException {
      // Nothing to hold back with; the after-the-fact path still works.
    }
  }

  /// Minimize for real, past the intercept. False when the runner has no
  /// channel, so the caller falls back to window_manager.
  static Future<bool> minimizeNow() async {
    if (!supported) return false;
    try {
      await _channel.invokeMethod<void>('minimize');
      return true;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }
}
