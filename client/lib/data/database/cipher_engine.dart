import 'package:sqlite3/sqlite3.dart' show Database;

/// Which SQLCipher-format engine [db] runs on, or null when it cannot read and
/// write SQLCipher 4 files.
///
/// Two builds qualify. SQLCipher itself answers `PRAGMA cipher_version`.
/// SQLite3 Multiple Ciphers — what the app compiles from
/// `third_party/sqlite3mc` — does not; it qualifies only when its default
/// cipher is `sqlcipher` in legacy mode 4, the configuration that writes files
/// byte-compatible with SQLCipher 4. Any other sqlite3mc default (ChaCha20,
/// or `sqlcipher` without legacy) would encrypt, but in a format the
/// databases already in users' hands are not in.
String? sqlcipherCompatibleEngine(Database db) {
  final sqlcipher = db.select('PRAGMA cipher_version');
  if (sqlcipher.isNotEmpty) return 'SQLCipher ${sqlcipher.first.columnAt(0)}';

  // Pragmas, not sqlite3mc_version() / sqlite3mc_config(): this runs before
  // `PRAGMA key`, and on an encrypted file sqlite3mc reads the schema to
  // prepare any SELECT — which fails without the key. Plain SQLite answers
  // both unknown pragmas with no rows.
  final cipher = db.select('PRAGMA cipher');
  final legacy = db.select('PRAGMA legacy');
  if (cipher.isNotEmpty &&
      cipher.first.columnAt(0) == 'sqlcipher' &&
      legacy.isNotEmpty &&
      '${legacy.first.columnAt(0)}' == '4') {
    return 'SQLite3 Multiple Ciphers (SQLCipher 4 format)';
  }
  return null;
}
