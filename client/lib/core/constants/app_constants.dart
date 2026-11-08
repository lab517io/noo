/// Application constants matching the Qt version (config.h)
class AppConstants {
  AppConstants._();

  static const String appName = 'Noo';
  static const String appNameLower = 'noo';
  static const String companyName = 'lab517.io';

  static const String databaseName = 'database.noo';
  static const String settingsFile = 'noo.ini';
  static const String logFile = 'noo-log.txt';

  /// MIME type for drag-drop operations
  static const String mimeType = 'application/noo-node';

  /// Interval in seconds to flush timeline to database
  static const int timelineFlushIntervalSeconds = 300;

  /// Interval in seconds to flush text editor content
  static const int textFlushIntervalSeconds = 10;

  /// Update timer interval for UI refresh
  static const Duration updateInterval = Duration(seconds: 1);
}
