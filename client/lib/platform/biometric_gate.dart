import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Biometric confirmation in front of the remembered-password auto-unlock.
///
/// The database key itself stays password-derived; this only decides whether
/// the copy saved in the Keystore may be used without re-typing it. Fail
/// closed: any error, cancellation, or missing hardware reports `false`, and
/// the caller falls back to the manual password prompt.
class BiometricGate {
  BiometricGate._();

  static final _auth = LocalAuthentication();

  /// Whether the device can actually satisfy the gate: `isDeviceSupported()`
  /// is true when a biometric is *enrolled* or a secure screen lock is set —
  /// hardware alone doesn't count. Used to grey out the preference rather than
  /// let the user tick a setting that can only ever fail closed.
  ///
  /// Probe this each time the preference is shown instead of caching it: the
  /// user can enrol a fingerprint or set a screen lock in Android settings and
  /// come straight back.
  static Future<bool> isAvailable() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return await _auth.isDeviceSupported();
    } on LocalAuthException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock your Noo database',
        // Deliberately false: BiometricPrompt keeps its "Use PIN" button, so a
        // wet or unreadable finger falls back to the screen lock instead of
        // forcing the database password to be retyped. The screen lock is the
        // same trust level as the Keystore entry it protects, so nothing is
        // weakened by accepting it.
        biometricOnly: false,
        // A startup gate: there is no in-app state to keep alive across an app
        // switch, and the cancel path is simpler without sticky auth.
        persistAcrossBackgrounding: false,
      );
    } on LocalAuthException {
      // local_auth 3.x reports every failure this way — userCanceled,
      // timeout, noCredentialsSet, uiUnavailable… — and all of them mean the
      // same thing for the gate: no auto-unlock, fall back to the password
      // dialog.
      return false;
    } on PlatformException {
      return false;
    }
  }
}
