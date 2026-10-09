import 'package:flutter/foundation.dart';
import 'package:flutter_quill/internal.dart';

/// Keeps a failing clipboard probe from swallowing the whole paste.
///
/// flutter_quill pastes by trying the richest thing on the clipboard first:
/// HTML, then an HTML file, then a Markdown file, then an image, and only if
/// none of those answered does it fall back to `Clipboard.getData` and insert
/// the plain text. That chain has no error handling. An exception from any of
/// the rich probes propagates out of `QuillController.clipboardPaste()`,
/// past the plain-text fallback that never ran, and out through the editor's
/// `pasteText` — where it is an unhandled async error. What the user sees is a
/// Paste entry that is enabled, and a Ctrl+V that does nothing at all.
///
/// The rich probes reach the platform, and reaching the platform is exactly
/// where this fails. `quill_native_bridge_windows` reads the clipboard through
/// Win32 directly, and every failure branch of its `getClipboardHtml` — the
/// clipboard already open in another process, `RegisterClipboardFormat`
/// reporting a stale `GetLastError`, `GlobalLock` refusing — is an
/// `assert(false, …)`, which **throws in a debug or profile build**. A
/// platform with no implementation registered at all throws
/// `UnimplementedError` from `isSupported`.
///
/// A clipboard that will not say what rich content it holds means exactly one
/// thing: no rich content this app can use. That is what null means to every
/// caller here, so this wrapper turns a failure into null and lets quill get
/// on with the plain text.
///
/// Deliberately not a place to fix the paste itself — the whole chain below
/// still runs, so an internal copy still restores its own formatting and
/// external HTML still arrives as rich text. Only the failure stops being
/// fatal. Installed once from `main()`; see [installResilientClipboardService].
class ResilientClipboardService extends ClipboardService {
  /// The service this one guards — quill's own, unless a test supplies another.
  final ClipboardService _inner;

  ResilientClipboardService(this._inner);

  @override
  Future<String?> getHtmlText() => _guard('getHtmlText', _inner.getHtmlText);

  @override
  Future<String?> getHtmlFile() => _guard('getHtmlFile', _inner.getHtmlFile);

  @override
  Future<String?> getMarkdownFile() =>
      _guard('getMarkdownFile', _inner.getMarkdownFile);

  @override
  Future<Uint8List?> getImageFile() =>
      _guard('getImageFile', _inner.getImageFile);

  @override
  Future<Uint8List?> getGifFile() => _guard('getGifFile', _inner.getGifFile);

  @override
  Future<void> copyImage(Uint8List imageBytes) async {
    // No null to fall back to, but the reasoning holds: a copy that cannot
    // reach the clipboard is a failed copy, not a reason to take down whatever
    // the user was doing.
    try {
      await _inner.copyImage(imageBytes);
    } catch (error) {
      _report('copyImage', error);
    }
  }

  Future<T?> _guard<T>(String probe, Future<T?> Function() read) async {
    try {
      return await read();
    } catch (error) {
      _report(probe, error);
      return null;
    }
  }

  /// Logged rather than swallowed silently: this is the difference between a
  /// paste that quietly loses formatting and one that quietly does nothing,
  /// and only the log says which platform probe gave up.
  ///
  /// A debug print rather than `FlutterError.reportError`: this is a degraded
  /// paste, not an app error, and reporting it as one would fail every widget
  /// test that pastes — the platform bridge is unimplemented under
  /// `flutter test`, so the guard is doing its job there on every run.
  ///
  /// Once per probe per run, for the same reason: whichever probe is broken is
  /// broken for every paste, and a line per keystroke would bury the log it is
  /// meant to be.
  void _report(String probe, Object error) {
    if (!kDebugMode) return;
    if (!_reported.add(probe)) return;
    debugPrint('Clipboard $probe failed, treated as empty: $error');
  }

  /// Probes already logged this run.
  static final Set<String> _reported = <String>{};
}

/// Install [ResilientClipboardService] as the clipboard flutter_quill reads.
///
/// Call once, before any editor is built. Wraps whatever service is currently
/// installed — quill's own, unless something replaced it — and does nothing
/// when the guard is already in place, so calling it twice cannot nest it.
void installResilientClipboardService() {
  final current = ClipboardServiceProvider.instance;
  if (current is ResilientClipboardService) return;
  ClipboardServiceProvider.setInstance(ResilientClipboardService(current));
}
