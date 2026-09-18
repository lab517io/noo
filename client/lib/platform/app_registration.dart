import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/constants/app_constants.dart';

const _applicationId = 'io.lab517.noo';
const _categories = 'Utility;Office;ProjectManagement;';
const _comment = 'Tiny outliner with time tracking';

/// Register the app in the system's application list so it appears in launchers.
///
/// This is a best-effort operation — failures are silently ignored
/// so they never block app startup.
Future<void> registerApp() async {
  try {
    if (Platform.isLinux) {
      await _registerLinux();
    } else if (Platform.isWindows) {
      await _registerWindows();
    }
  } catch (_) {
    // Never block the app on registration failure
  }
}

// ---------------------------------------------------------------------------
// Linux: .desktop file + icon in XDG directories
// ---------------------------------------------------------------------------

Future<void> _registerLinux() async {
  final home = Platform.environment['HOME'];
  if (home == null) return;

  final execPath = _resolveLinuxExecPath();
  if (execPath == null) return;

  final applicationsDir = Directory(p.join(home, '.local', 'share', 'applications'));
  final desktopFile = File(p.join(applicationsDir.path, '$_applicationId.desktop'));

  // Check if .desktop file exists and already points to the current binary
  if (await desktopFile.exists()) {
    final content = await desktopFile.readAsString();
    if (content.contains('Exec=$execPath')) {
      // Already registered with correct path — also ensure icon is present
      await _installLinuxIcon(home);
      return;
    }
  }

  // Create .desktop file
  await applicationsDir.create(recursive: true);
  await desktopFile.writeAsString(
    '[Desktop Entry]\n'
    'Type=Application\n'
    'Name=${AppConstants.appName}\n'
    'Comment=$_comment\n'
    'Exec=$execPath %f\n'
    'Icon=$_applicationId\n'
    'Categories=$_categories\n'
    'Terminal=false\n'
    'StartupNotify=true\n'
    'StartupWMClass=${AppConstants.appNameLower}\n'
    'MimeType=application/x-noo-database;\n',
  );

  await _installLinuxIcon(home);

  // Update desktop database (best-effort)
  try {
    await Process.run('update-desktop-database', [applicationsDir.path]);
  } catch (_) {}
}

/// Resolve the executable path for the Exec= line.
///
/// - AppImage: use $APPIMAGE env var (points to the .AppImage file itself)
/// - Installed / dev: use Platform.resolvedExecutable
String? _resolveLinuxExecPath() {
  // When running as AppImage, $APPIMAGE points to the actual .AppImage file
  final appImagePath = Platform.environment['APPIMAGE'];
  if (appImagePath != null && appImagePath.isNotEmpty) {
    return appImagePath;
  }
  // Otherwise use the resolved binary path
  final resolved = Platform.resolvedExecutable;
  if (resolved.isNotEmpty) return resolved;
  return null;
}

/// Install the app icon to the XDG icon directory.
Future<void> _installLinuxIcon(String home) async {
  final iconSource = _findIconFile();
  if (iconSource == null) return;

  final iconDir = Directory(
    p.join(home, '.local', 'share', 'icons', 'hicolor', '256x256', 'apps'),
  );
  final iconDest = File(p.join(iconDir.path, '$_applicationId.png'));

  if (await iconDest.exists()) return;

  await iconDir.create(recursive: true);
  await iconSource.copy(iconDest.path);
}

/// Find the app icon file relative to the executable.
File? _findIconFile() {
  final exeDir = p.dirname(Platform.resolvedExecutable);

  // In a normal Flutter build or AppImage: <exe_dir>/data/flutter_assets/assets/icons/app_icon.png
  final flutterAssets = File(
    p.join(exeDir, 'data', 'flutter_assets', 'assets', 'icons', 'app_icon.png'),
  );
  if (flutterAssets.existsSync()) return flutterAssets;

  // Fallback: <exe_dir>/data/app_icon.png (installed by CMake)
  final cmakeIcon = File(p.join(exeDir, 'data', 'app_icon.png'));
  if (cmakeIcon.existsSync()) return cmakeIcon;

  return null;
}

// ---------------------------------------------------------------------------
// Windows: Start Menu shortcut via PowerShell
// ---------------------------------------------------------------------------

Future<void> _registerWindows() async {
  final appData = Platform.environment['APPDATA'];
  if (appData == null) return;

  final startMenuDir = Directory(
    p.join(appData, 'Microsoft', 'Windows', 'Start Menu', 'Programs'),
  );
  final shortcutFile = File(p.join(startMenuDir.path, '${AppConstants.appName}.lnk'));

  if (await shortcutFile.exists()) {
    // Shortcut already exists — assume it's correct
    // (verifying .lnk targets requires COM which is heavyweight)
    return;
  }

  final exePath = Platform.resolvedExecutable;

  // Create shortcut via PowerShell (available on all modern Windows)
  final script = '''
\$ws = New-Object -ComObject WScript.Shell
\$shortcut = \$ws.CreateShortcut("${shortcutFile.path.replaceAll('\\', '\\\\')}")
\$shortcut.TargetPath = "${exePath.replaceAll('\\', '\\\\')}"
\$shortcut.WorkingDirectory = "${p.dirname(exePath).replaceAll('\\', '\\\\')}"
\$shortcut.Description = "$_comment"
\$shortcut.Save()
''';

  await Process.run(
    'powershell',
    ['-NoProfile', '-NonInteractive', '-Command', script],
  );
}
