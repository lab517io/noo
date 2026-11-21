import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/constants/app_constants.dart';

/// About dialog showing application information
class NooAboutDialog extends StatefulWidget {
  const NooAboutDialog({super.key});

  @override
  State<NooAboutDialog> createState() => _NooAboutDialogState();
}

class _NooAboutDialogState extends State<NooAboutDialog> {
  /// Version string sourced from the build metadata (pubspec.yaml),
  /// loaded asynchronously in [initState]. Empty until the load completes.
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _version = info.version);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.account_tree,
            size: 32,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Text('About ${AppConstants.appName}'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App name and version
            Text(
              '${AppConstants.appName} $_version'.trim(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tiny outliner with time tracking',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Description
            Text(
              'A cross-platform desktop outliner application for organizing '
              'your thoughts, tasks, and projects with built-in time tracking.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Copyright and credits
            const Divider(),
            const SizedBox(height: 12),
            Text(
              '© 2025-2026 ${AppConstants.companyName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Built with Flutter',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
