/// Creates the databases the multi-client playground runs on
/// (`scripts/playground/playground.py`).
///
/// Not a test — it is the only convenient way to build a real SQLCipher
/// database with the app's own schema and migrations, since the client's
/// sqlite3 comes from a Dart build hook that a plain `dart run` script cannot
/// resolve. It self-skips unless NOO_PLAYGROUND_SPEC points at a spec file, so
/// it costs the normal suite one skipped test and nothing else.
///
/// The spec is the JSON the orchestrator writes:
///
///     {"clients": [
///        {"db": "/…/alice.noo", "password": "…", "deviceId": "playground-a",
///         "seedTask": "Alice's note"}
///     ]}
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/domain/entities/world_id.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final specPath = Platform.environment['NOO_PLAYGROUND_SPEC'];

  test('seed the playground databases', () async {
    final spec = jsonDecode(File(specPath!).readAsStringSync())
        as Map<String, dynamic>;

    for (final entry in (spec['clients'] as List).cast<Map<String, dynamic>>()) {
      final path = entry['db'] as String;
      final password = entry['password'] as String;
      File(path).parent.createSync(recursive: true);
      if (File(path).existsSync()) File(path).deleteSync();

      final db = NooDatabase.fromPath(path, password: password);
      // Force the schema to exist: drift builds it lazily on first use.
      await db.customSelect('SELECT 1').get();

      final seedTask = entry['seedTask'] as String?;
      if (seedTask != null) {
        await db.createTask(worldId: WorldId.create().value, title: seedTask);
      }

      await db.close();
      stdout.writeln('seeded ${entry['deviceId']}: $path');
    }
  }, skip: specPath == null ? 'NOO_PLAYGROUND_SPEC not set' : null);
}
