import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// UUID-based distributed identifier for sync support.
/// Equivalent to Qt's WorldId class.
class WorldId extends Equatable {
  final String value;

  const WorldId(this.value);

  /// Create a new random WorldId
  factory WorldId.create() => WorldId(const Uuid().v4());

  /// Create WorldId from string
  factory WorldId.fromString(String s) => WorldId(s);

  /// Check if the WorldId is valid (non-empty UUID format)
  bool get isValid => value.isNotEmpty && _uuidRegex.hasMatch(value);

  static final _uuidRegex = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  @override
  List<Object?> get props => [value];

  @override
  String toString() => value;
}
