import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/byte_format.dart';
import '../../../data/services/update_service.dart';

/// Help → Check for Update. Checks on open; see [UpdateService] for what each
/// platform does with a newer release.
///
/// [onRestart] runs the app's exit sequence and returns whether it may proceed
/// (the user can still cancel from the sync-on-exit prompt).
class UpdateDialog extends StatefulWidget {
  const UpdateDialog({super.key, this.service, required this.onRestart});

  /// Injected by tests; a fresh one is created (and closed) otherwise.
  final UpdateService? service;

  final Future<bool> Function() onRestart;

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

enum _Stage { checking, failed, upToDate, available, installing, installed }

class _UpdateDialogState extends State<UpdateDialog> {
  late final UpdateService _service = widget.service ?? UpdateService();

  _Stage _stage = _Stage.checking;
  String _installed = '';
  ReleaseInfo? _release;
  String? _error;
  int _received = 0;
  int? _total;
  Completer<void>? _cancel;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _cancelInstall();
    if (widget.service == null) _service.close();
    super.dispose();
  }

  Future<void> _check() async {
    setState(() {
      _stage = _Stage.checking;
      _error = null;
    });
    try {
      final info = await PackageInfo.fromPlatform();
      final release = await _service.fetchLatest();
      if (!mounted) return;
      setState(() {
        _installed = info.version;
        _release = release;
        _stage = release.isNewerThan(info.version)
            ? _Stage.available
            : _Stage.upToDate;
      });
    } on UpdateException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _stage = _Stage.failed;
      });
    }
  }

  bool get _canInstallInPlace =>
      UpdatePlatform.current == UpdatePlatform.linuxAppImage &&
      _service.appImagePath != null &&
      _release?.assetFor(UpdatePlatform.linuxAppImage) != null;

  Future<void> _install() async {
    final release = _release!;
    final cancel = _cancel = Completer<void>();
    setState(() {
      _stage = _Stage.installing;
      _received = 0;
      _total = null;
    });
    try {
      await _service.installAppImage(
        release,
        cancel: cancel.future,
        onProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _received = received;
            _total = total;
          });
        },
      );
      if (!mounted) return;
      setState(() => _stage = _Stage.installed);
    } on UpdateCancelled {
      if (!mounted) return;
      setState(() => _stage = _Stage.available);
    } on UpdateException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _stage = _Stage.failed;
      });
    } finally {
      if (identical(_cancel, cancel)) _cancel = null;
    }
  }

  Future<void> _restart() async {
    if (!await widget.onRestart()) return;
    await _service.scheduleRelaunch();
    exit(0);
  }

  void _cancelInstall() {
    final cancel = _cancel;
    if (cancel != null && !cancel.isCompleted) cancel.complete();
  }

  /// The platform's asset if the release has one, else the release page.
  Future<void> _openDownload() {
    final release = _release!;
    final platform = UpdatePlatform.current;
    final asset = platform == null ? null : release.assetFor(platform);
    return _open(asset?.downloadUrl ?? release.pageUrl);
  }

  Future<void> _openReleasePage() => _open(_release!.pageUrl);

  Future<void> _open(String link) async {
    final url = Uri.parse(link);
    final ok = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      setState(() {
        _error = 'Could not open $url';
        _stage = _Stage.failed;
      });
    }
  }

  String get _downloadLabel {
    final platform = UpdatePlatform.current;
    final hasAsset = platform != null && _release?.assetFor(platform) != null;
    if (!hasAsset) return 'Open Release Page';
    return platform == UpdatePlatform.android ? 'Download APK' : 'Download';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Release notes plus a large system font can outgrow a phone screen.
      scrollable: true,
      title: const Text('Check for Update'),
      content: SizedBox(width: 440, child: _buildContent(context)),
      actions: _buildActions(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    switch (_stage) {
      case _Stage.checking:
        return const Row(
          children: [
            SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            // Wraps rather than running off a phone-width dialog.
            Expanded(child: Text('Checking for a new version...')),
          ],
        );
      case _Stage.failed:
        return Text(
          _error ?? 'Update check failed',
          style: TextStyle(color: theme.colorScheme.error),
        );
      case _Stage.upToDate:
        return Text(
          '${AppConstants.appName} $_installed is the latest version.',
        );
      case _Stage.available:
        final notes = _release!.notes;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${AppConstants.appName} ${_release!.version} is available '
              '(you have $_installed).',
              style: theme.textTheme.titleMedium,
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: SelectableText(
                      notes,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      case _Stage.installing:
        final total = _total;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Downloading ${AppConstants.appName} ${_release!.version}...'),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: total == null || total == 0 ? null : _received / total,
            ),
            const SizedBox(height: 8),
            Text(
              total == null
                  ? formatBytes(_received)
                  : '${formatBytes(_received)} of ${formatBytes(total)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        );
      case _Stage.installed:
        return Text(
          '${AppConstants.appName} ${_release!.version} is installed. '
          'Restart to start using it.',
        );
    }
  }

  List<Widget> _buildActions(BuildContext context) {
    void close() => Navigator.of(context).pop();
    switch (_stage) {
      case _Stage.checking:
        return [TextButton(onPressed: close, child: const Text('Cancel'))];
      case _Stage.failed:
        return [
          TextButton(onPressed: close, child: const Text('Close')),
          if (_release != null)
            TextButton(
              onPressed: _openReleasePage,
              child: const Text('Open Release Page'),
            ),
          FilledButton(onPressed: _check, child: const Text('Retry')),
        ];
      case _Stage.upToDate:
        return [FilledButton(onPressed: close, child: const Text('OK'))];
      case _Stage.available:
        return [
          TextButton(onPressed: close, child: const Text('Later')),
          if (_canInstallInPlace) ...[
            TextButton(
              onPressed: _openReleasePage,
              child: const Text('Open Release Page'),
            ),
            FilledButton(onPressed: _install, child: const Text('Install')),
          ] else
            FilledButton(onPressed: _openDownload, child: Text(_downloadLabel)),
        ];
      case _Stage.installing:
        return [
          TextButton(onPressed: _cancelInstall, child: const Text('Cancel')),
        ];
      case _Stage.installed:
        return [
          TextButton(onPressed: close, child: const Text('Later')),
          FilledButton(onPressed: _restart, child: const Text('Restart Now')),
        ];
    }
  }
}
