import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/platform/biometric_gate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Tests run on a desktop, which is exactly the case that broke: the
  // preference defaults to on, every local_auth probe fails closed off
  // Android, and startup reported "Biometric check failed" on each
  // remembered-password unlock.
  group('BiometricGate off Android', () {
    test('does not apply', () {
      expect(Platform.isAndroid, isFalse);
      expect(BiometricGate.applies, isFalse);
    });

    test('is not required even with the preference on', () async {
      expect(await BiometricGate.isRequired(preference: true), isFalse);
      expect(await BiometricGate.isRequired(preference: false), isFalse);
    });

    test('is not offered in Preferences', () async {
      expect(await BiometricGate.isAvailable(), isFalse);
    });
  });
}
