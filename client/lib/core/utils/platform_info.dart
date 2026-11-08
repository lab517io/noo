import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Desktop OS: window chrome, menu bar, file-system paths, exit sequence.
bool get isDesktopPlatform =>
    !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

/// Forces [isMobilePlatform] in widget tests. Widget tests run on the host OS,
/// so touch-only branches are otherwise unreachable from a desktop machine.
@visibleForTesting
bool? debugIsMobilePlatformOverride;

/// Mobile OS: system-managed lifecycle, scoped storage, touch-first input.
bool get isMobilePlatform =>
    debugIsMobilePlatformOverride ??
    (!kIsWeb && (Platform.isAndroid || Platform.isIOS));

/// Phone-sized window: single pane with screen navigation instead of the
/// tree+editor split. 600dp is the Material compact-width breakpoint; a
/// desktop window narrowed below it deliberately gets the same treatment.
bool isCompactLayout(BuildContext context) =>
    MediaQuery.sizeOf(context).width < 600;

/// macOS: the application menu belongs in the system menu bar at the top of
/// the screen, not inside the window. There the app hands its menu to the OS
/// via `PlatformMenuBar`; Windows and Linux keep the in-window `MenuBar`.
bool get usesPlatformMenuBar => !kIsWeb && Platform.isMacOS;
