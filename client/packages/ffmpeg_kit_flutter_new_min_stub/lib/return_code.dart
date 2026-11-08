/// Mirrors the real package's `ReturnCode`: a thin wrapper over an ffmpeg exit
/// status, where 0 means success and 255 means the session was cancelled.
class ReturnCode {
  ReturnCode(this._value);

  static const int success = 0;
  static const int cancel = 255;

  final int _value;

  static bool isSuccess(ReturnCode? returnCode) =>
      returnCode?.getValue() == success;

  static bool isCancel(ReturnCode? returnCode) =>
      returnCode?.getValue() == cancel;

  int getValue() => _value;

  bool isValueSuccess() => _value == success;

  bool isValueCancel() => _value == cancel;

  bool isValueError() => _value != success && _value != cancel;

  @override
  String toString() => _value.toString();
}
