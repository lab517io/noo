import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/install_source.dart';

void main() {
  tearDown(() => InstallSource.installerForTesting = null);

  test('a sideloaded copy offers Check for Update', () {
    for (final installer in [null, 'com.google.android.packageinstaller']) {
      InstallSource.installerForTesting = installer;
      expect(InstallSource.offersUpdateCheck, isTrue, reason: '$installer');
    }
  });

  test('a copy a store installed does not', () {
    for (final installer in ['org.fdroid.fdroid', 'com.android.vending']) {
      InstallSource.installerForTesting = installer;
      expect(InstallSource.offersUpdateCheck, isFalse, reason: installer);
    }
  });
}
