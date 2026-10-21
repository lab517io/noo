/// Database-related constants
class DatabaseConstants {
  DatabaseConstants._();

  /// Current database schema version
  static const int schemaVersion = 1;

  /// Property keys stored in the properties table
  static const String propertyVersion = 'version';

  /// Table names
  static const String tableTask = 'task';
  static const String tableTimeline = 'timeline';
  static const String tableFile = 'file';
  static const String tableProperties = 'properties';
  static const String tableHistoryTask = 'history_task';
  static const String tableHistoryFile = 'history_file';
  static const String tableSyncs = 'syncs';
}
