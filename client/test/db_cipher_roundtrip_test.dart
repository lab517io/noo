// Regression test for "newly created database cannot be reopened with the
// same password".
//
// Since package:sqlite3 3.x the cipher build is selected by the build hook
// (`hooks.user_defines.sqlite3` in pubspec.yaml) and supplied as a code asset,
// so the test loads exactly the library production loads with no framework
// probing. That also makes the test platform-independent — it used to be
// mac-only and skipped unless the .app had already been built.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';

void main() {
  // Written by Noo 1.2.16, the last release linking SQLCipher 4.18 itself
  // (`source: sqlcipher`), password `fixture-password`: two tasks, "Written by
  // SQLCipher 4.18" and its child "child". Every database in users' hands is in
  // this format, so the sqlite3mc build that replaced SQLCipher has to open it.
  test('opens a database written by SQLCipher 4', () async {
    final dir = await Directory.systemTemp.createTemp('noo_cipher_test');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/db.noo';
    await File('test/fixtures/sqlcipher4-v1.2.16.noo').copy(path);

    final wrong = NooDatabase.fromPath(path, password: 'other-password');
    expect(await wrong.verifyAccess(), isFalse);
    await wrong.close();

    final db = NooDatabase.fromPath(path, password: 'fixture-password');
    expect(await db.verifyAccess(), isTrue,
        reason: 'a SQLCipher 4 database must open with its password');
    final titles = (await db.getAllTasks()).map((t) => t.title).toSet();
    expect(titles, containsAll(['Written by SQLCipher 4.18', 'child']));
    final added = await db.createTask(worldId: 'w-new', title: 'after');
    await db.close();

    final reopened = NooDatabase.fromPath(path, password: 'fixture-password');
    expect(await reopened.verifyAccess(), isTrue);
    expect((await reopened.getTaskById(added))?.title, 'after');
    await reopened.close();
  });

  test('create with password, reopen with same password', () async {
    final dir = await Directory.systemTemp.createTemp('noo_cipher_test');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/db.noo';
    const password = 'test-password-123';

    // Create (mirrors DatabaseManager.createDatabase -> openDatabase).
    final created = NooDatabase.fromPath(path, password: password);
    expect(await created.verifyAccess(), isTrue,
        reason: 'freshly created database must be accessible');
    final taskId = await created.createTask(worldId: 'w1', title: 'hello');
    expect(taskId, greaterThan(0));
    await created.close();

    expect(await File(path).length(), greaterThan(0),
        reason: 'database file must be written on close');

    // Reopen with the same password.
    final reopened = NooDatabase.fromPath(path, password: password);
    expect(await reopened.verifyAccess(), isTrue,
        reason: 'same password must reopen the database');
    final task = await reopened.getTaskById(taskId);
    expect(task?.title, 'hello');
    await reopened.close();

    // Wrong password must be rejected.
    final wrong = NooDatabase.fromPath(path, password: 'other-password');
    expect(await wrong.verifyAccess(), isFalse,
        reason: 'wrong password must not open the database');
    await wrong.close();

    // Passwordless open must be rejected (file is actually encrypted).
    final plain = NooDatabase.fromPath(path);
    expect(await plain.verifyAccess(), isFalse,
        reason: 'encrypted database must not open without password');
    await plain.close();
  });

  test('failed passwordless open attempt does not break later keyed open',
      () async {
    final dir = await Directory.systemTemp.createTemp('noo_cipher_test');
    addTearDown(() => dir.delete(recursive: true));
    final path = '${dir.path}/db.noo';
    const password = 'test-password-123';

    final created = NooDatabase.fromPath(path, password: password);
    expect(await created.verifyAccess(), isTrue);
    await created.close();

    // Mirrors DatabaseManager.initialize: first try without password...
    final attempt = NooDatabase.fromPath(path);
    expect(await attempt.verifyAccess(), isFalse);
    await attempt.close();

    // ...then with the password the user enters.
    final reopened = NooDatabase.fromPath(path, password: password);
    expect(await reopened.verifyAccess(), isTrue,
        reason: 'keyed open after failed passwordless attempt must work');
    await reopened.close();
  });
}
