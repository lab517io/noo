import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

typedef _SetenvNative = Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Int32);
typedef _SetenvDart = int Function(Pointer<Utf8>, Pointer<Utf8>, int);
typedef _GetenvNative = Pointer<Utf8> Function(Pointer<Utf8>);
typedef _GetenvDart = Pointer<Utf8> Function(Pointer<Utf8>);

const _resolverVariable = 'GIO_USE_PROXY_RESOLVER';

/// Keep GStreamer from sending loopback playback requests to an HTTP proxy.
///
/// Audio attachments are served by `AttachmentMediaServer` over
/// `http://127.0.0.1:<port>/`, and `audioplayers` on Linux hands that URL to a
/// GStreamer `playbin`, whose `souphttpsrc` resolves the proxy for it through
/// GIO. On a machine where GIO resolves proxies with libproxy — the default on
/// Ubuntu — that lookup returns the configured proxy *even for 127.0.0.1*, the
/// desktop's "ignore hosts" list notwithstanding. The memo is then requested
/// from the user's proxy, which has no idea what to do with a port on the
/// user's own machine: playback fails with `Bad Gateway`.
///
/// `GIO_USE_PROXY_RESOLVER=dummy` picks GLib's no-op resolver, which answers
/// `direct://` for everything. Nothing in this app reaches the network through
/// GIO — the model download and sync are Dart `HttpClient`, which never
/// consults it — so the only traffic this changes is the loopback request that
/// must not be proxied anyway. An explicit value in the environment is left
/// alone, so anyone who needs the real resolver can still ask for it.
///
/// Call once, before the first frame: `setenv` is only safe while the process
/// is still effectively single-threaded.
void bypassProxyForLocalPlayback() {
  if (!Platform.isLinux) return;
  if (Platform.environment.containsKey(_resolverVariable)) return;

  final name = _resolverVariable.toNativeUtf8();
  final value = 'dummy'.toNativeUtf8();
  try {
    final process = DynamicLibrary.process();
    final setenv = process.lookupFunction<_SetenvNative, _SetenvDart>('setenv');
    setenv(name, value, 1);

    // Read it back through libc rather than trusting the return code: Dart's
    // own view of the environment is a copy taken at startup and would show
    // nothing either way, so this is the only way to know the process really
    // carries the setting a C library will look for.
    final getenv = process.lookupFunction<_GetenvNative, _GetenvDart>('getenv');
    final Pointer<Utf8> current = getenv(name);
    if (current == nullptr || current.toDartString() != 'dummy') {
      debugPrint('Could not disable the GIO proxy resolver; '
          'audio playback may fail behind a proxy.');
    }
  } on ArgumentError {
    // No `setenv` to call — nothing to do but leave the resolver alone.
  } finally {
    calloc.free(name);
    calloc.free(value);
  }
}
