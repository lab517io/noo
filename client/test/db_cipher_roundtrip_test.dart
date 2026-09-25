// Regression test for "newly created database cannot be reopened with the
// same password".
//
// Since package:sqlite3 3.x the SQLCipher build is selected by the build hook
// (`hooks.user_defines.sqlite3.source: sqlcipher` in pubspec.yaml) and supplied
// as a code asset, so the test loads exactly the library production loads with
// no framework probing. That also makes the test platform-independent — it used
// to be mac-only and skipped unless the .app had already been built.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';

void main() {
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
