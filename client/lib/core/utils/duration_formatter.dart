/// Utility class for formatting durations
class DurationFormatter {
  DurationFormatter._();

  /// Format duration as HH:MM:SS
  static String formatHMS(Duration duration, {bool showSeconds = true}) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (showSeconds) {
      return '${_pad(hours)}:${_pad(minutes)}:${_pad(seconds)}';
    } else {
      return '${_pad(hours)}:${_pad(minutes)}';
    }
  }

  /// Format a media position the way players do: `1:02`, `12:07`, `1:03:20`.
  /// Hours appear only once there are any, and minutes carry no leading zero
  /// unless hours are shown.
  static String formatMediaPosition(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${_pad(minutes)}:${_pad(seconds)}';
    }
    return '$minutes:${_pad(seconds)}';
  }

  /// Format duration as human readable (e.g., "2h 30m")
  static String formatHuman(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      final seconds = duration.inSeconds;
      return '${seconds}s';
    }
  }

  /// Format duration for display in task tree (compact)
  static String formatCompact(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours:${_pad(minutes)}';
    } else {
      return '${minutes}m';
    }
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');
}
