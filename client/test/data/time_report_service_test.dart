import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/services/time_report_service.dart';

void main() {
  group('exclusiveEndOfDay', () {
    test('is the next local midnight on every day of the year (DEEPSEEK M1)',
        () {
      // Scan a year in the machine's zone. On a zone with daylight saving
      // two of these days are 23 and 25 hours long, and a fixed 24-hour add
      // lands at 01:00 or 23:00 instead of midnight.
      var transitions = 0;
      for (var day = DateTime(2026, 1, 1);
          day.year == 2026;
          day = DateTime(day.year, day.month, day.day + 1)) {
        final end = exclusiveEndOfDay(day);
        expect(end.hour, 0, reason: 'end of $day');
        expect(end.minute, 0);
        expect(end.difference(day).inHours >= 23, isTrue);
        expect(end, DateTime(day.year, day.month, day.day + 1));
        if (end != day.add(const Duration(days: 1))) transitions++;
      }
      // Informational: zero in a zone without daylight saving (UTC on CI).
      expect(transitions, anyOf(0, 2));
    });

    test('ignores the time of day it is given', () {
      expect(exclusiveEndOfDay(DateTime(2026, 3, 15, 17, 45)),
          DateTime(2026, 3, 16));
    });
  });
}
