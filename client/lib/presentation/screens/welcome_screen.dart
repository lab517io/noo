import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/save_dialog.dart';
import '../providers/providers.dart';
import '../widgets/dialogs/password_dialog.dart';

/// First-run welcome screen. Lets the user pick where their database lives
/// before any password dialog appears — except for "Create new database…",
/// which asks for the password *before* the save panel: that panel writes an
/// empty file at the chosen path as it closes (see [pickSavePath]), so a
/// password prompt after it would leave a database the user chose to replace,
/// and then thought better of, truncated to nothing.
///
/// Calls [onPathChosen] with the resolved absolute path. [create] carries the
/// user's intent: true for "Create new database…" (even if a file already
/// exists at that path — the save panel already confirmed replacing it),
/// false for "Open existing…", null for the default location (caller decides
/// by whether the file exists). Routing by intent, not by file existence,
/// is what guarantees creation always gets the confirm-password dialog.
/// [password] is set only for a creation, and is the one that dialog took.
class WelcomeScreen extends ConsumerStatefulWidget {
  final void Function(String path, {bool? create, String? password})
      onPathChosen;

  const WelcomeScreen({
    super.key,
    required this.onPathChosen,
  });

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  String? _defaultPath;

  @override
  void initState() {
    super.initState();
    _loadDefaultPath();
  }

  Future<void> _loadDefaultPath() async {
    final dbManager = ref.read(databaseManagerProvider);
    final path = await dbManager.getDefaultDatabasePath();
    if (mounted) {
      setState(() {
        _defaultPath = path;
      });
    }
  }

  void _useDefault() {
    final path = _defaultPath;
    if (path != null) {
      widget.onPathChosen(path);
    }
  }

  void _choseCreate(String path, String password) =>
      widget.onPathChosen(path, create: true, password: password);

  void _choseOpen(String path) => widget.onPathChosen(path, create: false);

  Future<void> _createCustom() async {
    // Password before location — see the class comment.
    final passwordResult = await PasswordDialog.showCreate(context);
    if (passwordResult == null || !mounted) return;

    final dbManager = ref.read(databaseManagerProvider);
    final defaultDir = await dbManager.getDefaultDirectory();

    final path = await pickSavePath(
      dialogTitle: 'Create New Database',
      fileName: AppConstants.databaseName,
      type: FileType.custom,
      allowedExtensions: ['noo'],
      initialDirectory: defaultDir,
      requiredExtension: '.noo',
    );

    if (path == null || !mounted) return;
    _choseCreate(path, passwordResult.password);
  }

  Future<void> _openExisting() async {
    final dbManager = ref.read(databaseManagerProvider);
    final defaultDir = await dbManager.getDefaultDirectory();

    final result = await FilePicker.pickFiles(
      dialogTitle: 'Open Database',
      type: FileType.custom,
      allowedExtensions: ['noo', 'sqlite', 'db'],
      initialDirectory: defaultDir,
    );

    if (result.isEmpty) return;
    final path = result.first.path;
    if (path == null) return;
    _choseOpen(path);
  }

  void _quit() {
    SystemNavigator.pop();
    // SystemNavigator.pop is a no-op on desktop; fall back to exit().
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      exit(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.account_tree,
                  size: 64,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome to ${AppConstants.appName}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose where to store your encrypted database. '
                  'You can change this later from the File menu.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 32),
                _OptionCard(
                  icon: Icons.home_outlined,
                  title: 'Use default location',
                  subtitle: _defaultPath ?? 'Resolving…',
                  subtitleIsPath: true,
                  onTap: _defaultPath == null ? null : _useDefault,
                ),
                const SizedBox(height: 12),
                _OptionCard(
                  icon: Icons.create_new_folder_outlined,
                  title: 'Create new database…',
                  subtitle: 'Pick a custom location for a new encrypted database.',
                  onTap: _createCustom,
                ),
                const SizedBox(height: 12),
                _OptionCard(
                  icon: Icons.folder_open_outlined,
                  title: 'Open existing database…',
                  subtitle: 'Use an existing .noo file from another location.',
                  onTap: _openExisting,
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: _quit,
                    icon: const Icon(Icons.close),
                    label: const Text('Quit'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool subtitleIsPath;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.subtitleIsPath = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Tooltip(
                      message: subtitleIsPath ? subtitle : '',
                      child: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontFamily: subtitleIsPath ? 'monospace' : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
