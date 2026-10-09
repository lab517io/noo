import 'package:file_picker/file_picker.dart';

/// Platform options every native file dialog in this app is opened with.
///
/// On Windows and Linux a file dialog is a separate top-level window, and
/// without `lockParentWindow` the app window underneath stays fully
/// interactive while it is up: the user can select another task while
/// choosing an image to insert, and the embed lands in a document that is no
/// longer the one on screen. Locking the parent makes the dialog modal, as it
/// already is on macOS (a sheet) and on mobile (a full-screen picker).
///
/// `WindowsOptions` only applies on Windows and `LinuxOptions` only on Linux,
/// so both are passed unconditionally and the platform picks its own.
const WindowsOptions kModalWindowsOptions = WindowsOptions(
  lockParentWindow: true,
);

const LinuxOptions kModalLinuxOptions = LinuxOptions(lockParentWindow: true);
