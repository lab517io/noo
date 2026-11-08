/// Base exception for Noo application
class NooException implements Exception {
  final String message;
  final dynamic cause;

  NooException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'NooException: $message (cause: $cause)';
    }
    return 'NooException: $message';
  }
}

/// Exception thrown when database operations fail
class DatabaseException extends NooException {
  DatabaseException(super.message, [super.cause]);

  @override
  String toString() => 'DatabaseException: $message';
}

/// Exception thrown when encryption/decryption fails
class EncryptionException extends NooException {
  EncryptionException(super.message, [super.cause]);

  @override
  String toString() => 'EncryptionException: $message';
}

/// Exception thrown when a task is not found
class TaskNotFoundException extends NooException {
  final int taskId;

  TaskNotFoundException(this.taskId) : super('Task not found: $taskId');

  @override
  String toString() => 'TaskNotFoundException: Task ID $taskId not found';
}

/// Exception thrown when invalid password is provided
class InvalidPasswordException extends NooException {
  InvalidPasswordException() : super('Invalid password');

  @override
  String toString() => 'InvalidPasswordException: Invalid password provided';
}

/// Exception thrown when time intervals overlap
class TimeIntervalOverlapException extends NooException {
  TimeIntervalOverlapException(super.message);

  @override
  String toString() => 'TimeIntervalOverlapException: $message';
}
