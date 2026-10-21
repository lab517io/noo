import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Which app installed this copy of Noo, read once at startup ([load]).
///
/// The F-Droid build and the APK on GitHub are one and the same file — F-Droid
/// builds from source, checks that its build is identical to ours, and then
/// ships ours, signature included (docs/FDROID.md). So nothing decided at build
/// time can tell them apart; the installer can.
class InstallSource {
  InstallSource._();

  static String? _installer;

  /// App stores, by package name. A copy one of them installed is updated by
  /// it: F-Droid's inclusion policy refuses an app that fetches its own updates
  /// past the store, and Play's does too.
  @visibleForTesting
  static const storeInstallers = {
    'org.fdroid.fdroid', // F-Droid
    'org.fdroid.basic', // F-Droid Basic
    'org.fdroid.fdroid.privileged', // F-Droid Privileged Extension
    'com.looker.droidify', // Droid-ify
    'com.machiav3lli.fdroid', // Neo Store
    'eu.bubu1.fdroidclassic', // F-Droid Classic
    'com.aurora.store', // Aurora Store (installs from Play)
    'com.android.vending', // Google Play
  };

  /// Reads the installer. Android only — elsewhere nothing installs Noo that
  /// would object to Check for Update. Never throws: an unreadable installer
  /// counts as a sideload, which is what the GitHub APK is.
  static Future<void> load() async {
    if (!Platform.isAndroid) return;
    try {
      _installer = (await PackageInfo.fromPlatform()).installerStore;
    } catch (_) {
      _installer = null;
    }
  }

  /// Whether Help → Check for Update is offered: not when a store installed
  /// this copy (macOS is excluded separately, in the menus).
  static bool get offersUpdateCheck => !storeInstallers.contains(_installer);

  @visibleForTesting
  static set installerForTesting(String? installer) => _installer = installer;
}
