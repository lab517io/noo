/// Resolving a stored device name back to a device.
///
/// Small, but it is the whole reason the preference stores a name: an index is
/// only true of the enumeration it came from, and getting this wrong records
/// from a device the user never chose without saying so.
@TestOn('vm')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/services/audio/audio_devices.dart';
import 'package:voice_audio/voice_audio.dart' as va;

void main() {
  const devices = [
    va.AudioDevice(index: 0, name: 'Built-in mic', isDefault: true),
    va.AudioDevice(index: 1, name: 'USB headset'),
    va.AudioDevice(index: 2, name: 'Loopback'),
  ];

  group('resolveAudioDevice', () {
    test('finds the device by name, with its current index', () {
      final device = resolveAudioDevice(devices, 'USB headset');
      expect(device?.index, 1);
      expect(device?.name, 'USB headset');
    });

    test('an empty name means the system default', () {
      expect(resolveAudioDevice(devices, ''), isNull);
    });

    test('a name that has gone means the system default', () {
      // Not index 0, and not a throw: the headset was unplugged, and the right
      // answer is to let the platform pick rather than to guess.
      expect(resolveAudioDevice(devices, 'Podcast mic'), isNull);
    });

    test('an empty machine means the system default', () {
      expect(resolveAudioDevice(const [], 'USB headset'), isNull);
    });

    test('picks up an index that moved since the name was stored', () {
      // The case the whole scheme exists for: the same name, one device
      // earlier in the list than it used to be.
      const rearranged = [
        va.AudioDevice(index: 0, name: 'USB headset'),
        va.AudioDevice(index: 1, name: 'Built-in mic', isDefault: true),
      ];
      expect(resolveAudioDevice(rearranged, 'USB headset')?.index, 0);
    });
  });
}
