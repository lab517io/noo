import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/duration_formatter.dart';

void main() {
  group('formatMediaPosition', () {
    test('drops the hour field until there is an hour to show', () {
      expect(DurationFormatter.formatMediaPosition(Duration.zero), '0:00');
      expect(
        DurationFormatter.formatMediaPosition(const Duration(seconds: 7)),
        '0:07',
      );
      expect(
        DurationFormatter.formatMediaPosition(
          const Duration(minutes: 1, seconds: 2),
        ),
        '1:02',
      );
      expect(
        DurationFormatter.formatMediaPosition(
          const Duration(minutes: 12, seconds: 7),
        ),
        '12:07',
      );
    });

    test('pads minutes only once hours are shown', () {
      expect(
        DurationFormatter.formatMediaPosition(
          const Duration(hours: 1, minutes: 3, seconds: 20),
        ),
        '1:03:20',
      );
      expect(
        DurationFormatter.formatMediaPosition(const Duration(hours: 2)),
        '2:00:00',
      );
    });
  });
}
