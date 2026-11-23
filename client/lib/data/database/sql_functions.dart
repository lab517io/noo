import 'package:sqlite3/sqlite3.dart';

import '../../core/utils/fold_case.dart';

/// Name of the SQL function folding text for case-insensitive search.
const kFoldCaseSqlFunction = 'noo_fold';

/// Register the app's own SQL functions on a freshly opened connection.
///
/// `noo_fold(text)` is [foldCase]: search uses it for tokens outside ASCII,
/// where SQLite's built-in `LIKE` would compare case-sensitively.
void registerSqlFunctions(Database db) {
  db.createFunction(
    functionName: kFoldCaseSqlFunction,
    argumentCount: const AllowedArgumentCount(1),
    deterministic: true,
    directOnly: false,
    function: (args) {
      final value = args[0];
      return value is String ? foldCase(value) : value;
    },
  );
}
