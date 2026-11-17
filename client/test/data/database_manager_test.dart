import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/services/database_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [DatabaseManager] runs one open or create at a time. Two overlapping
/// opens used to interleave: both closed the current database, the second
/// closed the first's fresh instance in the middle of its access check, and
/// the first's error path then nulled the instance the second had installed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late DatabaseManager manager;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dir = await Directory.systemTemp.createTemp('noo_manager_test');
    manager = DatabaseManager();
  });

  tearDown(() async {
    manager.dispose();
    await dir.delete(recursive: true);
  });

  String path(String name) => '${dir.path}/$name.noo';

  test('overlapping opens run one after the other; the last one asked for '
      'is the one left open', () async {
    const password = 'pw';
    await manager.createDatabase(path('one'), password: password);
    await manager.database!.createTask(worldId: 'w-1', title: 'in one');
    await manager.createDatabase(path('two'), password: password);
    await manager.database!.createTask(worldId: 'w-2', title: 'in two');

    // Not awaited one at a time: both are in flight together.
    final first = manager.openDatabase(path('one'), password: password);
    final second = manager.openDatabase(path('two'), password: password);
    expect(await first, isTrue);
    expect(await second, isTrue);

    expect(manager.isLoading, isFalse);
    expect(manager.error, isNull);
    expect(manager.currentPath, path('two'));
    final db = manager.database!;
    expect((await db.getTaskByWorldId('w-2'))!.title, 'in two');
    expect(await db.verifyAccess(), isTrue,
        reason: 'the instance left behind is the open one, not a closed one');
  });

  test('an open queued behind a failing one still runs in full', () async {
    const password = 'pw';
    await manager.createDatabase(path('good'), password: password);

    final failing = manager.openDatabase(path('good'), password: 'wrong');
    final following = manager.openDatabase(path('good'), password: password);
    expect(await failing, isFalse);
    expect(await following, isTrue);

    expect(manager.isOpen, isTrue);
    expect(manager.error, isNull, reason: 'the later open clears the error');
    expect(await manager.database!.verifyAccess(), isTrue);
  });

  test('a create queued behind an open does not lose its delete step', () async {
    const password = 'pw';
    await manager.createDatabase(path('db'), password: password);
    await manager.database!.createTask(worldId: 'w-old', title: 'old');

    final open = manager.openDatabase(path('db'), password: password);
    final create = manager.createDatabase(path('db'), password: password);
    expect(await open, isTrue);
    expect(await create, isTrue);

    expect(await manager.database!.getTaskByWorldId('w-old'), isNull,
        reason: 'the create replaced the file after the open finished');
  });
}
