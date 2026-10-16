/// Utility class for date operations
class NooDateUtils {
  NooDateUtils._();

  /// Check if two dates are on the same day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Check if two dates are in the same month
  static bool isSameMonth(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month;
  }

  /// Check if two dates are in the same year
  static bool isSameYear(DateTime a, DateTime b) {
    return a.year == b.year;
  }

  /// Get start of day (00:00:00)
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day (23:59:59.999)
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Get start of month
  static DateTime startOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get end of month
  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);
  }

  /// Get today's date at midnight (UTC)
  static DateTime today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Parse ISO 8601 string to DateTime (UTC)
  static DateTime? parseUtc(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toUtc();
  }

  /// Format DateTime to ISO 8601 string (UTC)
  static String toUtcString(DateTime date) {
    return date.toUtc().toIso8601String();
  }
}
