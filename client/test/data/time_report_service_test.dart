import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/time_report_service.dart';
import 'package:noo/domain/entities/world_id.dart';

void main() {
  group('CSV', () {
    late NooDatabase db;

    setUp(() => db = NooDatabase.memory());
    tearDown(() => db.close());

    /// One task with one hour tracked on 2026-03-10, reported as CSV.
    Future<List<String>> csvFor(String title) async {
      final taskId = await db.createTask(
        worldId: WorldId.create().value,
        title: title,
      );
      final start = DateTime(2026, 3, 10, 9).toUtc();
      await db.createTimeRecord(
        taskId: taskId,
        worldId: WorldId.create().value,
        startTime: start.toIso8601String(),
        endTime: start.add(const Duration(hours: 1)).toIso8601String(),
      );
      final result = await TimeReportService(db).generate(TimeReportConfig(
        selectedTaskIds: {taskId},
        includeDescendants: false,
        fromDate: DateTime(2026, 3, 10),
        toDate: DateTime(2026, 3, 10),
        format: TimeReportFormat.csv,
        showEmptyTasks: false,
      ));
      return result.text.trimRight().split('\n');
    }

    test('a title opening like a formula is defused, inside quotes', () async {
      // Titles arrive from sync and from MCP agents, so a spreadsheet
      // executing one is not a problem the user chose.
      final lines = await csvFor('=HYPERLINK("http://evil","click")');
      expect(lines, hasLength(2));
      final cells = lines[1];
      expect(cells, startsWith('"\'=HYPERLINK(""http://evil"",""click"")",'));
      // The numeric columns are untouched: the duration is a plain number.
      expect(cells, endsWith(',09:00,10:00,3600,false'));
    });

    test('every formula lead is guarded, a plain title is not', () async {
      // A leading tab or CR never reaches the path (titles are trimmed), so
      // the printable leads are the ones to check.
      for (final lead in ['+', '-', '@']) {
        final lines = await csvFor('${lead}sum');
        expect(lines[1], startsWith('"\'${lead}sum",'), reason: 'lead $lead');
      }
      final lines = await csvFor('Plain title');
      expect(lines[1], startsWith('Plain title,'));
    });

    test('a carriage return forces quoting', () async {
      final lines = await csvFor('line\rbreak');
      expect(lines[1], startsWith('"line\rbreak",'));
    });
  });

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
