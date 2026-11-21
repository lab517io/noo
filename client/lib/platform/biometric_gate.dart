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

  /// Whether this platform has a gate at all. Only Android does: local_auth is
  /// not wired up anywhere else here, and every probe below answers its
  /// fail-closed `false` on other platforms — which, asked at startup, would
  /// read as "the user failed the check".
  static bool get applies => !kIsWeb && Platform.isAndroid;

  /// Whether opening with the remembered password must first pass
  /// [authenticate]. [preference] is the user's *Biometric unlock* setting,
  /// which defaults to on everywhere but can only be changed on Android — so
  /// it alone must never decide this on a desktop, where it used to fail every
  /// remembered-password unlock with "Biometric check failed".
  static Future<bool> isRequired({required bool preference}) async {
    if (!applies || !preference) return false;
    return !await hasNoDeviceLock();
  }

  /// Whether the device can actually satisfy the gate: `isDeviceSupported()`
  /// is true when a biometric is *enrolled* or a secure screen lock is set —
  /// hardware alone doesn't count. Used to grey out the preference rather than
  /// let the user tick a setting that can only ever fail closed.
  ///
  /// Probe this each time the preference is shown instead of caching it: the
  /// user can enrol a fingerprint or set a screen lock in Android settings and
  /// come straight back.
  static Future<bool> isAvailable() async {
    if (!applies) return false;
    try {
      return await _auth.isDeviceSupported();
    } on LocalAuthException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  /// Whether the device definitely has nothing to check against: no enrolled
  /// biometric and no secure screen lock. Only a definite answer counts — a
  /// probe that fails reports `false`, so the gate stays closed.
  ///
  /// The gate is on by default, so without this a phone with no screen lock
  /// could never use its remembered password. Skipping it there gives nothing
  /// away: removing a screen lock takes the lock itself, and without one the
  /// phone is open to whoever holds it anyway.
  static Future<bool> hasNoDeviceLock() async {
    if (!applies) return false;
    try {
      return !await _auth.isDeviceSupported();
    } on LocalAuthException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    if (!applies) return false;
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
