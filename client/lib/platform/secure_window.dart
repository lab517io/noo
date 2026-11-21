import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Toggles Android's FLAG_SECURE on the activity window, which blanks the
/// app in screenshots, screen recordings, and the recents-screen thumbnail.
///
/// Backed by a MethodChannel handled in MainActivity.kt; a no-op everywhere
/// but Android (desktop OSes have no equivalent window flag, and tests run
/// on the host).
class SecureWindow {
  SecureWindow._();

  static const _channel = MethodChannel('io.lab517.noo/secure_window');

  static Future<void> apply(bool enabled) async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('setSecure', enabled);
    } on MissingPluginException {
      // Running under `flutter test` with an Android target, or an engine
      // without the host handler — nothing to secure.
    }
  }
}
