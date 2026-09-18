import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../data/services/database_manager.dart';
import '../../platform/biometric_gate.dart';
import '../providers/providers.dart';
import '../providers/settings_provider.dart';
import '../widgets/dialogs/password_dialog.dart';
import 'main_screen.dart';
import 'welcome_screen.dart';

/// Startup screen that handles database initialization and password prompt
class StartupScreen extends ConsumerStatefulWidget {
  const StartupScreen({super.key});

  @override
  ConsumerState<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends ConsumerState<StartupScreen> {
  bool _initialized = false;
  bool _showWelcome = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Delay initialization to avoid modifying providers during build
    Future.microtask(_initializeDatabase);
  }

  Future<void> _initializeDatabase() async {
    final dbManager = ref.read(databaseManagerProvider);
    final initialPath = ref.read(initialDatabasePathProvider);

    // First-run detection: no CLI arg, and either no saved path or the saved
    // path no longer exists on disk. Show the welcome screen instead of
    // silently falling back to the default location.
    final hasCliPath = initialPath != null && initialPath.isNotEmpty;
    if (!hasCliPath) {
      final savedPath = await dbManager.getLastUsedDatabasePath();
      final shouldShowWelcome = savedPath == null || !await _fileExists(savedPath);
      if (shouldShowWelcome) {
        if (mounted) {
          setState(() {
            _showWelcome = true;
          });
        }
        return;
      }
    }

    // Initialize database manager with optional initial path from command line
    final success = await dbManager.initialize(initialPath: initialPath);

    if (success) {
      // Database opened without password
      _navigateToMain();
      return;
    }

    // Check if password is needed
    if (dbManager.needsPassword && mounted) {
      await _handlePasswordRequired(dbManager);
    } else if (dbManager.error != null) {
      setState(() {
        _error = dbManager.error;
      });
    }
  }

  Future<void> _onWelcomePathChosen(String path, {bool? create}) async {
    final dbManager = ref.read(databaseManagerProvider);

    setState(() {
      _showWelcome = false;
      _error = null;
    });

    // Seed the manager with the chosen path and route into the existing
    // password-required flow, which handles both create and open paths.
    dbManager.setPendingPath(path);

    if (!mounted) return;
    await _handlePasswordRequired(dbManager, createNew: create);
  }

  /// [createNew] carries explicit user intent from the welcome screen.
  /// When null (startup with a saved path, CLI path), fall back to detection
  /// by file existence. Explicit intent must win: "Create new database…" over
  /// an existing file would otherwise be routed to the single-field open
  /// dialog, bypassing password confirmation.
  Future<void> _handlePasswordRequired(DatabaseManager dbManager,
      {bool? createNew}) async {
    final path = dbManager.currentPath;
    if (path == null) return;

    final isNew = createNew ??
        (dbManager.database == null && !await _fileExists(path));

    final secureStorage = ref.read(secureStorageServiceProvider);

    // Read rememberPassword directly from SharedPreferences to ensure it's loaded
    final prefs = await SharedPreferences.getInstance();
    final rememberPassword = prefs.getBool(SettingsKeys.rememberPassword) ?? false;

    String? errorMessage;
    bool success = false;

    // Don't save as default if path was specified via CLI
    final saveAsDefault = !dbManager.isCliPath;

    // Try saved password first for existing databases
    if (!isNew && rememberPassword) {
      final savedPassword = await secureStorage.getPassword(dbPath: path);
      if (savedPassword != null) {
        // Opt-in biometric gate (Android): the remembered password may only
        // be used after the OS confirms the user. Failure or cancel falls
        // through to typing the password — it must never auto-unlock, and it
        // must not delete the (correct) saved password either.
        final biometricUnlock =
            prefs.getBool(SettingsKeys.biometricUnlock) ?? false;
        if (biometricUnlock && !await BiometricGate.authenticate()) {
          errorMessage = 'Biometric check failed. Please enter password.';
        } else {
          success = await dbManager.openDatabase(path, password: savedPassword, saveAsDefault: saveAsDefault);
          if (success) {
            _navigateToMain();
            return;
          }
          // Saved password failed, clear it and prompt user
          await secureStorage.deletePassword(dbPath: path);
          errorMessage = 'Saved password is incorrect. Please enter password.';
        }
      }
    }

    while (!success && mounted) {
      final passwordResult = isNew
          ? await PasswordDialog.showCreate(context, databasePath: path)
          : await PasswordDialog.showOpen(
              context,
              errorMessage: errorMessage,
              databasePath: path,
            );

      if (passwordResult == null) {
        // User cancelled - offer an escape hatch instead of trapping them.
        // Without this, a forgotten password on the saved database loops
        // forever: the error view only offers "Retry", which re-opens the
        // same password dialog. Routing to the welcome screen lets the user
        // open or create a different database.
        if (mounted) {
          setState(() {
            _showWelcome = true;
          });
        }
        return;
      }

      if (isNew) {
        success = await dbManager.createDatabase(
          path,
          password: passwordResult.password,
          saveAsDefault: saveAsDefault,
        );
      } else {
        success = await dbManager.openDatabase(
          path,
          password: passwordResult.password,
          saveAsDefault: saveAsDefault,
        );
      }

      if (success) {
        // Save password if setting is enabled
        if (rememberPassword) {
          await secureStorage.savePassword(passwordResult.password, dbPath: path);
        }
      } else if (dbManager.errorType == DatabaseError.wrongPassword) {
        errorMessage = 'Incorrect password. Please try again.';
      }
    }

    if (success) {
      _navigateToMain();
    } else if (dbManager.error != null) {
      setState(() {
        _error = dbManager.error;
      });
    }
  }

  /// True when [path] holds an actual database. A zero-length file is a
  /// leftover from a failed open (sqlite creates the file on first contact),
  /// not a database — treating it as one would route the user to the
  /// single-prompt "open" dialog instead of the create flow.
  Future<bool> _fileExists(String path) async {
    try {
      final file = File(path);
      return await file.exists() && await file.length() > 0;
    } catch (_) {
      return false;
    }
  }

  void _navigateToMain() {
    if (!mounted) return;
    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized) {
      return const MainScreen();
    }

    if (_showWelcome) {
      return WelcomeScreen(onPathChosen: _onWelcomePathChosen);
    }

    return Scaffold(
      body: Center(
        child: _error != null
            ? _buildErrorView()
            : _buildLoadingView(),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.account_tree,
          size: 64,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        const CircularProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          'Loading...',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: Theme.of(context).colorScheme.error,
        ),
        const SizedBox(height: 24),
        Text(
          'Failed to Open Database',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _error = null;
                  _showWelcome = true;
                });
              },
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('Open another database…'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _error = null;
                });
                _initializeDatabase();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ],
    );
  }
}
