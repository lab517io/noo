/// Builds the demo database the website's screenshots are taken from
/// (`noo-website`, `tools/screenshots/capture.py`).
///
/// Not a test, for the same reason [seed_playground_test.dart] is not one: a
/// real SQLCipher database with the app's own schema and migrations is only
/// convenient to build from inside the package, because the client's sqlite3
/// comes from a Dart build hook a plain `dart run` script cannot resolve. It
/// self-skips unless NOO_SCREENSHOT_SPEC points at a spec file, so it costs
/// the normal suite one skipped test and nothing else.
///
/// Seeding rather than typing into the UI is deliberate: the demo tree, the
/// note text *and* the time records are then one reviewable file, and the
/// same database comes back byte for byte on the next run. Time records in
/// particular could not be produced by actually running a timer — the report
/// on the page covers a fortnight of work.
///
/// The spec is the JSON the capture script writes:
///
///     {"db": "…/notebook.noo", "password": "…",
///      "tasks": [{"key": "noo", "parent": null, "title": "Noo",
///                 "content": "<h2>…</h2>"}],
///      "time":  [{"task": "sync", "date": "2026-09-03",
///                 "start": "09:15", "minutes": 95}]}
///
/// `key` is the spec's own handle for a task, used by `parent` and by `time`;
/// it never reaches the database. Order within a parent follows the list.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/domain/entities/world_id.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final specPath = Platform.environment['NOO_SCREENSHOT_SPEC'];

  test('seed the screenshot database', () async {
    final spec =
        jsonDecode(File(specPath!).readAsStringSync()) as Map<String, dynamic>;

    final path = spec['db'] as String;
    final password = spec['password'] as String;
    File(path).parent.createSync(recursive: true);
    for (final suffix in ['', '-wal', '-shm']) {
      final f = File('$path$suffix');
      if (f.existsSync()) f.deleteSync();
    }

    final db = NooDatabase.fromPath(path, password: password);
    // Force the schema to exist: drift builds it lazily on first use.
    await db.customSelect('SELECT 1').get();

    // Row ids by spec key, so `parent` and `time` can name tasks by hand.
    final ids = <String, int>{};
    final worldIds = <String, String>{};
    final orderInParent = <String, int>{};

    for (final entry in (spec['tasks'] as List).cast<Map<String, dynamic>>()) {
      final key = entry['key'] as String;
      final parentKey = entry['parent'] as String?;
      final parentId = parentKey == null ? null : ids[parentKey];
      if (parentKey != null && parentId == null) {
        fail('task "$key" names parent "$parentKey", which is not seeded yet');
      }
      final slot = parentKey ?? '';
      final order = orderInParent[slot] ?? 0;
      orderInParent[slot] = order + 1;

      final worldId = WorldId.create().value;
      ids[key] = await db.createTask(
        parentId: parentId,
        worldId: worldId,
        orderId: order,
        title: entry['title'] as String,
        content: entry['content'] as String?,
      );
      worldIds[key] = worldId;
    }

    for (final entry in (spec['time'] as List? ?? const [])
        .cast<Map<String, dynamic>>()) {
      final key = entry['task'] as String;
      final taskId = ids[key];
      if (taskId == null) fail('time record names unknown task "$key"');

      final start = DateTime.parse('${entry['date']} ${entry['start']}:00');
      final end = start.add(Duration(minutes: entry['minutes'] as int));
      await db.createTimeRecord(
        taskId: taskId,
        worldId: WorldId.create().value,
        startTime: start.toIso8601String(),
        endTime: end.toIso8601String(),
      );
    }

    await db.close();
    stdout.writeln('seeded $path: '
        '${ids.length} tasks, ${(spec['time'] as List? ?? const []).length} '
        'time records');
  }, skip: specPath == null ? 'NOO_SCREENSHOT_SPEC not set' : null);
}
