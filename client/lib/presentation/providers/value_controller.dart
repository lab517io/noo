import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A minimal, modern replacement for Riverpod's legacy `StateProvider`.
///
/// Holds a single mutable value. Read it with `ref.watch(provider)`; write it
/// with `ref.read(provider.notifier).value = ...`. Unlike the legacy
/// `StateController.state`, the mutable accessor is named [value] because the
/// inherited `Notifier.state` setter is `@protected`.
class ValueController<T> extends Notifier<T> {
  ValueController(this._initial);

  final T _initial;

  @override
  T build() => _initial;

  T get value => state;

  set value(T newValue) => state = newValue;
}

/// Builds a [NotifierProvider] backed by a [ValueController] holding [initial].
///
/// Drop-in equivalent of `StateProvider<T>((ref) => initial)`, except writes go
/// through `.notifier.value` instead of `.notifier.state`.
NotifierProvider<ValueController<T>, T> valueProvider<T>(T initial) {
  return NotifierProvider<ValueController<T>, T>(() => ValueController<T>(initial));
}
