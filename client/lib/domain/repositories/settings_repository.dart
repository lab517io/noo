/// Abstract repository for application settings
abstract class SettingsRepository {
  /// Database file path
  Future<String?> getDatabasePath();
  Future<void> setDatabasePath(String path);

  /// Auto-save password in keychain
  Future<bool> getAutosavePassword();
  Future<void> setAutosavePassword(bool value);

  /// Show seconds in time display
  Future<bool> getShowSeconds();
  Future<void> setShowSeconds(bool value);

  /// Time counter display type
  Future<TimeCounterType> getTimeCounterType();
  Future<void> setTimeCounterType(TimeCounterType type);

  /// Smart tracking settings
  Future<bool> getSmartStart();
  Future<void> setSmartStart(bool value);

  Future<bool> getSmartStop();
  Future<void> setSmartStop(bool value);

  Future<int> getSmartStopIntervalMinutes();
  Future<void> setSmartStopIntervalMinutes(int minutes);

  /// Confirmation dialogs
  Future<bool> getAskBeforeStart();
  Future<void> setAskBeforeStart(bool value);

  Future<bool> getAskBeforeStop();
  Future<void> setAskBeforeStop(bool value);

  Future<bool> getAskBeforeDelete();
  Future<void> setAskBeforeDelete(bool value);

  /// UI settings
  Future<bool> getShowTrayIcon();
  Future<void> setShowTrayIcon(bool value);

  Future<bool> getDarkTheme();
  Future<void> setDarkTheme(bool value);

  Future<bool> getCumulativeReport();
  Future<void> setCumulativeReport(bool value);

  /// Window geometry
  Future<WindowGeometry> getWindowGeometry();
  Future<void> setWindowGeometry(WindowGeometry geometry);

  /// Task state persistence
  Future<List<int>> getExpandedTaskIds();
  Future<void> setExpandedTaskIds(List<int> ids);

  Future<int?> getSelectedTaskId();
  Future<void> setSelectedTaskId(int? id);

  Future<List<int>> getRecentTaskIds();
  Future<void> setRecentTaskIds(List<int> ids);
}

/// Time counter display types
enum TimeCounterType {
  thisDay,
  thisSession,
  allTime,
}

/// Window geometry settings
class WindowGeometry {
  final double left;
  final double top;
  final double width;
  final double height;
  final bool maximized;
  final double splitterOffset1;
  final double splitterOffset2;

  const WindowGeometry({
    this.left = 100,
    this.top = 100,
    this.width = 1024,
    this.height = 768,
    this.maximized = false,
    this.splitterOffset1 = 300,
    this.splitterOffset2 = 0,
  });

  WindowGeometry copyWith({
    double? left,
    double? top,
    double? width,
    double? height,
    bool? maximized,
    double? splitterOffset1,
    double? splitterOffset2,
  }) {
    return WindowGeometry(
      left: left ?? this.left,
      top: top ?? this.top,
      width: width ?? this.width,
      height: height ?? this.height,
      maximized: maximized ?? this.maximized,
      splitterOffset1: splitterOffset1 ?? this.splitterOffset1,
      splitterOffset2: splitterOffset2 ?? this.splitterOffset2,
    );
  }
}
