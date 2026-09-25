import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../database/database.dart';

/// Error types for database operations
enum DatabaseError {
  none,
  wrongPassword,
  fileNotFound,
  corruptedFile,
  unknown,
}

/// Manages database lifecycle: opening, creating, and switching databases.
class DatabaseManager extends ChangeNotifier {
  static const String _lastDatabasePathKey = 'last_database_path';

  NooDatabase? _database;
  String? _currentPath;
  String? _currentPassword;
  bool _isLoading = false;
  String? _error;
  DatabaseError _errorType = DatabaseError.none;
  bool _needsPassword = false;
  bool _isCliPath = false; // Track if current path was specified via command line

  /// Current database instance
  NooDatabase? get database => _database;

  /// Current database file path
  String? get currentPath => _currentPath;

  /// Password of the currently open database (null if none or passwordless).
  /// Needed to derive the end-to-end sync encryption key.
  String? get currentPassword => _currentPassword;

  /// Just the filename without directory
  String? get currentFileName => _currentPath != null ? p.basename(_currentPath!) : null;

  /// Whether database is currently being opened/created
  bool get isLoading => _isLoading;

  /// Last error message, if any
  String? get error => _error;

  /// Type of last error
  DatabaseError get errorType => _errorType;

  /// Whether a database is currently open
  bool get isOpen => _database != null;

  /// Whether the database needs a password to open
  bool get needsPassword => _needsPassword;

  /// Whether the current database was opened via command line argument
  /// When true, the path won't be saved as the default database
  bool get isCliPath => _isCliPath;

  /// Initialize the database manager with the specified, last used, or default database
  /// [initialPath] - Optional path from command line argument
  /// Returns true if database was opened successfully without password
  /// Returns false if password is required (check needsPassword) or error occurred
  Future<bool> initialize({String? initialPath}) async {
    _isLoading = true;
    _error = null;
    _errorType = DatabaseError.none;
    notifyListeners();

    try {
      String? dbPath = initialPath;

      // Track if path was specified via command line
      _isCliPath = initialPath != null && initialPath.isNotEmpty;

      // If no initial path, try to get the last used database path
      if (dbPath == null || dbPath.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        dbPath = prefs.getString(_lastDatabasePathKey);
      }

      // If no last path, use default location
      if (dbPath == null || dbPath.isEmpty) {
        dbPath = await getDefaultDatabasePath();
      }

      // Check if file exists (a zero-length leftover counts as new, see
      // openDatabase)
      final file = File(dbPath);
      final isNewDatabase = !await file.exists() || await file.length() == 0;

      if (isNewDatabase) {
        // New database - will be created, needs password for encryption
        _needsPassword = true;
        _currentPath = dbPath;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Try to open existing database without password first
      // Don't save as default if path was specified via CLI
      final result = await openDatabase(dbPath, saveAsDefault: !_isCliPath);
      return result;
    } catch (e) {
      _error = e.toString();
      _errorType = DatabaseError.unknown;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Open a database at the given path with optional password
  /// [saveAsDefault] - If true, save this path as the default database (defaults to true)
  ///                   Set to false when opening via command line argument
  /// Returns true if opened successfully, false otherwise
  Future<bool> openDatabase(String path, {String? password, bool saveAsDefault = true}) async {
    _isLoading = true;
    _error = null;
    _errorType = DatabaseError.none;
    _needsPassword = false;
    notifyListeners();

    // A zero-length file is "new": sqlite creates the file on first contact,
    // so an aborted/failed open leaves an empty file behind. Treating it as
    // existing would route the UI to the single-prompt "open" dialog and let
    // an unconfirmed password silently become the new database's key.
    final file = File(path);
    var isNewDatabase = false;

    try {
      // Close existing database if open
      await _closeCurrentDatabase();

      // Ensure directory exists
      final dir = Directory(p.dirname(path));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      isNewDatabase = !await file.exists() || await file.length() == 0;

      if (isNewDatabase) {
        debugPrint('Creating new database at: $path');
      } else {
        debugPrint('Opening existing database at: $path');
        // Fail with an honest error when the file can't be read at all
        // (e.g. filesystem permissions). Without this probe an unreadable
        // file surfaces as a failed test query, which the code below
        // misreports as a wrong password.
        try {
          final raf = await file.open();
          await raf.close();
        } on FileSystemException catch (e) {
          _error = 'Cannot read database file: ${e.osError?.message ?? e.message}';
          _errorType = DatabaseError.unknown;
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      // Open the database with password
      _database = NooDatabase.fromPath(path, password: password);
      _currentPath = path;

      // Verify the database is accessible (password is correct)
      final isValid = await _database!.verifyAccess();
      if (!isValid) {
        // Password is wrong or database is corrupted
        await _database!.close();
        _database = null;
        _currentPassword = null;
        await _deleteIfLeftoverNewFile(isNewDatabase, file);
        _needsPassword = true;
        _error = 'Incorrect password or corrupted database';
        _errorType = DatabaseError.wrongPassword;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentPassword = password;

      // Save as last used path (unless opened via CLI argument)
      if (saveAsDefault) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastDatabasePathKey, path);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (_database != null) {
        try {
          await _database!.close();
        } catch (_) {}
        _database = null;
        _currentPassword = null;
      }
      await _deleteIfLeftoverNewFile(isNewDatabase, file);
      _error = 'Failed to open database: $e';
      _errorType = DatabaseError.unknown;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Removes the file a failed open just created, so the next attempt is
  /// still recognized as database creation (two-field password dialog)
  /// instead of an open of a pre-existing database.
  Future<void> _deleteIfLeftoverNewFile(bool isNewDatabase, File file) async {
    if (!isNewDatabase) return;
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Best effort; the zero-length check on next open covers the rest.
    }
  }

  /// Create a new database at the given path with password
  /// [saveAsDefault] - If true, save this path as the default database (defaults to true)
  Future<bool> createDatabase(String path, {String? password, bool saveAsDefault = true}) async {
    // Delete existing file if it exists
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }

    return openDatabase(path, password: password, saveAsDefault: saveAsDefault);
  }

  /// Close the current database (internal use, doesn't notify)
  Future<void> _closeCurrentDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _currentPassword = null;
      // Don't clear _currentPath here - we need it for retry logic
      // Don't notify here - we'll notify after new database is ready
    }
  }

  /// Get the default database path
  Future<String> getDefaultDatabasePath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final nooDir = Directory(p.join(appDir.path, AppConstants.appNameLower));
    if (!await nooDir.exists()) {
      await nooDir.create(recursive: true);
    }
    return p.join(nooDir.path, AppConstants.databaseName);
  }

  /// Get the default database directory
  Future<String> getDefaultDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, AppConstants.appNameLower);
  }

  /// Seed the manager with a chosen path that has not been opened yet.
  /// Used by the welcome/first-run flow to hand off to the existing
  /// password prompt logic without touching disk.
  void setPendingPath(String path) {
    _currentPath = path;
    _needsPassword = true;
    _isCliPath = false;
    _error = null;
    _errorType = DatabaseError.none;
    notifyListeners();
  }

  /// Read the saved last-used database path from preferences, if any.
  Future<String?> getLastUsedDatabasePath() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_lastDatabasePathKey);
    if (path == null || path.isEmpty) return null;
    return path;
  }

  @override
  void dispose() {
    _closeCurrentDatabase();
    super.dispose();
  }
}
