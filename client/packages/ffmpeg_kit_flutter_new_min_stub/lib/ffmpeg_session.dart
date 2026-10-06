import 'return_code.dart';

/// The result of an ffmpeg invocation.
///
/// In the real package this carries logs, statistics and session state pulled
/// back over a method channel. Callers here only ever ask for the return code,
/// so that is all this holds.
class FFmpegSession {
  FFmpegSession(this._returnCode);

  final ReturnCode? _returnCode;

  Future<ReturnCode?> getReturnCode() async => _returnCode;
}
