@TestOn('linux')
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/platform/playback_proxy.dart';

typedef _GetenvNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _GetenvDart = Pointer<Utf8> Function(Pointer<Utf8>);

String? _env(String name) {
  final getenv = DynamicLibrary.process()
      .lookupFunction<_GetenvNative, _GetenvDart>('getenv');
  final key = name.toNativeUtf8();
  try {
    final value = getenv(key);
    return value == nullptr ? null : value.toDartString();
  } finally {
    calloc.free(key);
  }
}

void main() {
  // Guards the fix for loopback playback being routed through the desktop
  // proxy: on a libproxy-backed GIO — the Ubuntu default — the lookup returns
  // the configured proxy even for 127.0.0.1, and every memo fails to play with
  // "Bad Gateway". Dart caches its own copy of the environment at startup, so
  // this has to be read back through getenv to see the change at all.
  test('the GIO proxy resolver is disabled for the process', () {
    final preset = _env('GIO_USE_PROXY_RESOLVER');
    bypassProxyForLocalPlayback();
    // A value already in the environment is the user's choice and is kept.
    expect(_env('GIO_USE_PROXY_RESOLVER'), preset ?? 'dummy');
  });
}
