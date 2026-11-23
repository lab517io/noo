import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/data/services/time_report_service.dart';
import 'package:noo/domain/entities/world_id.dart';
import 'package:noo/l10n/l10n.dart';

void main() {
  group('language', () {
    late NooDatabase db;

    setUp(() => db = NooDatabase.memory());
    tearDown(() => db.close());

    /// A parent with 30m of its own and a child with 2h, as a tree report.
    Future<String> treeIn(String? lang, {TimeReportFormat? format}) async {
      final parent = await db.createTask(
        worldId: WorldId.create().value,
        title: 'Project',
      );
      final child = await db.createTask(
        worldId: WorldId.create().value,
        title: '',
        parentId: parent,
      );
      Future<void> track(int task, int hour, Duration d) {
        final start = DateTime(2026, 3, 10, hour).toUtc();
        return db.createTimeRecord(
          taskId: task,
          worldId: WorldId.create().value,
          startTime: start.toIso8601String(),
          endTime: start.add(d).toIso8601String(),
        );
      }

      await track(parent, 9, const Duration(minutes: 30));
      await track(child, 10, const Duration(hours: 2));
      final service = TimeReportService(
        db,
        l10n: lang == null ? null : lookupAppLocalizations(Locale(lang)),
      );
      final result = await service.generate(TimeReportConfig(
        selectedTaskIds: {parent},
        includeDescendants: true,
        fromDate: DateTime(2026, 3, 10),
        toDate: DateTime(2026, 3, 10),
        format: format ?? TimeReportFormat.tree,
        showEmptyTasks: false,
      ));
      return result.text;
    }

    test('is English when none is given', () async {
      final text = await treeIn(null);
      expect(text, startsWith('# Time Report\n'));
      expect(text, contains('**Total:** 2h 30m'));
      expect(text, contains('- **Project** — 2h 30m _(self: 30m)_'));
      expect(text, contains('  - **(untitled)** — 2h'));
    });

    test('follows the language it is given', () async {
      final text = await treeIn('ru');
      expect(text, startsWith('# ${lookupAppLocalizations(const Locale('ru')).timeReportTitle}\n'));
      expect(text, contains('**Итого:** 2 ч 30 мин'));
      expect(text, contains('- **Project** — 2 ч 30 мин _(собственное: 30 мин)_'));
      // Dates stay ISO in every language.
      expect(text, contains('2026-03-10 — 2026-03-10'));
    });

    test('CSV stays a machine format', () async {
      final text = await treeIn('ja', format: TimeReportFormat.csv);
      expect(text, startsWith('task_path,task_id,date,start_time,end_time,duration_seconds,ongoing\n'));
      expect(text, contains(',1800,false'));
    });
  });

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
