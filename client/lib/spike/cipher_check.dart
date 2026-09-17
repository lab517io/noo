// Phase-0 spike entrypoint (docs/ANDROID_PORT.md): proves the SQLCipher code
// asset works on a real Android device/emulator. Run with:
//   flutter run -t lib/spike/cipher_check.dart
// Prints CIPHER_CHECK lines to the log; not part of the app proper.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final results = <String>[];
  void report(String line) {
    results.add(line);
    // ignore: avoid_print
    print('CIPHER_CHECK: $line');
  }

  try {
    report('sqlite version: ${sqlite3.version}');

    final mem = sqlite3.openInMemory();
    final cipherVersion =
        mem.select('PRAGMA cipher_version').firstOrNull?.columnAt(0);
    mem.close();
    report('cipher_version: $cipherVersion');
    if (cipherVersion == null) {
      report('FAIL: PRAGMA cipher_version returned nothing — plain SQLite?');
    }

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'spike_cipher.db');
    final file = File(dbPath);
    if (file.existsSync()) file.deleteSync();

    var db = sqlite3.open(dbPath);
    db.execute("PRAGMA key = 'spike-password'");
    db.execute('CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT)');
    db.execute("INSERT INTO t (v) VALUES ('hello-android')");
    db.close();

    // Reopen with the right key.
    db = sqlite3.open(dbPath);
    db.execute("PRAGMA key = 'spike-password'");
    final v = db.select('SELECT v FROM t').first.columnAt(0);
    db.close();
    report('reopen with key: $v');

    // Wrong key must fail.
    var wrongKeyRejected = false;
    db = sqlite3.open(dbPath);
    try {
      db.execute("PRAGMA key = 'wrong-password'");
      db.select('SELECT v FROM t');
    } catch (_) {
      wrongKeyRejected = true;
    } finally {
      db.close();
    }
    report('wrong key rejected: $wrongKeyRejected');
    file.deleteSync();

    final ok = cipherVersion != null &&
        v == 'hello-android' &&
        wrongKeyRejected;
    report(ok ? 'RESULT: PASS' : 'RESULT: FAIL');
  } catch (e, st) {
    report('RESULT: FAIL exception: $e\n$st');
  }

  runApp(MaterialApp(
    home: Scaffold(
      body: Center(child: Text(results.join('\n'))),
    ),
  ));
}
