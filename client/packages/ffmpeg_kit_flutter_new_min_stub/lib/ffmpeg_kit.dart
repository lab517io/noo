import 'ffmpeg_session.dart';
import 'return_code.dart';

/// Exit status reported for every invocation.
///
/// Deliberately neither [ReturnCode.success] nor [ReturnCode.cancel], so
/// callers take their ordinary "conversion failed" branch — the same one the
/// real package produces when ffmpeg is unavailable.
const int _unavailable = 1;

/// Entry point for running ffmpeg commands, with no ffmpeg behind it.
///
/// See this package's README for why the real implementation is shadowed.
class FFmpegKit {
  /// Reports failure without running anything. [command] is ignored.
  static Future<FFmpegSession> execute(String command) async =>
      FFmpegSession(ReturnCode(_unavailable));
}
