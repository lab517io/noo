import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/byte_format.dart';
import '../../../core/utils/release_notes.dart';
import '../../../data/services/update_service.dart';
import '../markdown_text.dart';
import '../../../core/theme/noo_chrome.dart';
import '../../../l10n/l10n.dart';

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

/// `ready`: the update is downloaded and verified. For an AppImage it is
/// already in place; on Windows it is applied after the app exits.
enum _Stage { checking, failed, upToDate, available, installing, ready }

class _UpdateDialogState extends State<UpdateDialog> {
  late final UpdateService _service = widget.service ?? UpdateService();

  _Stage _stage = _Stage.checking;
  String _installed = '';
  ReleaseInfo? _release;
  String? _error;
  int _received = 0;
  int? _total;
  Completer<void>? _cancel;

  /// What [UpdateService.prepare] produced, until it is launched or
  /// discarded.
  PreparedUpdate? _prepared;
  bool _launching = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _cancelInstall();
    _discardPrepared();
    if (widget.service == null) _service.close();
    super.dispose();
  }

  /// Drop a downloaded update the user did not go through with (Later, Esc,
  /// a click outside). Not while it is being launched — the files are what
  /// the launched process runs from.
  void _discardPrepared() {
    final prepared = _prepared;
    if (prepared == null || _launching) return;
    _prepared = null;
    unawaited(_service.discard(prepared));
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
      _release != null && _service.canInstall(_release!);

  /// Whether the update is applied only after the app has exited (Windows),
  /// as opposed to being in place already (AppImage).
  bool get _appliesAfterExit => _service.method != UpdateMethod.appImage;

  Future<void> _install() async {
    final release = _release!;
    final cancel = _cancel = Completer<void>();
    setState(() {
      _stage = _Stage.installing;
      _received = 0;
      _total = null;
    });
    try {
      final prepared = await _service.prepare(
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
      if (!mounted) {
        unawaited(_service.discard(prepared));
        return;
      }
      setState(() {
        _prepared = prepared;
        _stage = _Stage.ready;
      });
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
    final prepared = _prepared;
    if (prepared == null) return;
    _launching = true;
    if (!await widget.onRestart()) {
      _launching = false;
      return;
    }
    await _service.launchAfterExit(prepared);
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
        _error = appL10n.appCouldNotOpen('$url');
        _stage = _Stage.failed;
      });
    }
  }

  String get _downloadLabel {
    final platform = UpdatePlatform.current;
    final hasAsset = platform != null && _release?.assetFor(platform) != null;
    if (!hasAsset) return context.l10n.appOpenReleasePage;
    return switch (platform) {
      UpdatePlatform.android => context.l10n.appDownloadApk,
      UpdatePlatform.macos => context.l10n.appDownloadDiskImage,
      _ => context.l10n.commonDownload,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // Release notes plus a large system font can outgrow a phone screen.
      scrollable: true,
      title: Text(context.l10n.appCheckForUpdateTitle),
      content: SizedBox(width: 440, child: _buildContent(context)),
      actions: _buildActions(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    switch (_stage) {
      case _Stage.checking:
        return Row(
          children: [
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            // Wraps rather than running off a phone-width dialog.
            Expanded(child: Text(context.l10n.appCheckingForUpdate)),
          ],
        );
      case _Stage.failed:
        return Text(
          _error ?? context.l10n.appUpdateCheckFailed,
          style: TextStyle(color: theme.colorScheme.error),
        );
      case _Stage.upToDate:
        return Text(
          context.l10n.appUpToDate(AppConstants.appName, _installed),
        );
      case _Stage.available:
        // The notes are Markdown written for the release page; the dialog
        // shows the prose, rendered, and leaves the download table and the
        // verification commands to Open Release Page.
        final notes = dialogReleaseNotes(_release!.notes);
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.appUpdateAvailable(
                AppConstants.appName,
                _release!.version,
                _installed,
              ),
              style: theme.textTheme.titleMedium,
            ),
            if (notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.dividerColor),
                    borderRadius: NooChrome.of(context).radius,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(8),
                    child: SelectionArea(
                      child: MarkdownText(
                        notes,
                        style: theme.textTheme.bodySmall,
                      ),
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
            Text(context.l10n.appDownloadingUpdate(
                AppConstants.appName, _release!.version)),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: total == null || total == 0 ? null : _received / total,
            ),
            const SizedBox(height: 8),
            Text(
              total == null
                  ? formatBytes(_received)
                  : context.l10n.appDownloadProgress(
                      formatBytes(_received), formatBytes(total)),
              style: theme.textTheme.bodySmall,
            ),
          ],
        );
      case _Stage.ready:
        final name = AppConstants.appName;
        final version = _release!.version;
        return Text(
          _appliesAfterExit
              ? context.l10n.appUpdateReadyToInstall(name, version)
              : context.l10n.appUpdateInstalled(name, version),
        );
    }
  }

  List<Widget> _buildActions(BuildContext context) {
    void close() => Navigator.of(context).pop();
    switch (_stage) {
      case _Stage.checking:
        return [TextButton(onPressed: close, child: Text(context.l10n.commonCancel))];
      case _Stage.failed:
        return [
          TextButton(onPressed: close, child: Text(context.l10n.commonClose)),
          if (_release != null)
            TextButton(
              onPressed: _openReleasePage,
              child: Text(context.l10n.appOpenReleasePage),
            ),
          FilledButton(onPressed: _check, child: Text(context.l10n.commonRetry)),
        ];
      case _Stage.upToDate:
        return [FilledButton(onPressed: close, child: Text(context.l10n.commonOk))];
      case _Stage.available:
        return [
          TextButton(onPressed: close, child: Text(context.l10n.appLater)),
          if (_canInstallInPlace) ...[
            TextButton(
              onPressed: _openReleasePage,
              child: Text(context.l10n.appOpenReleasePage),
            ),
            FilledButton(onPressed: _install, child: Text(context.l10n.appInstall)),
          ] else
            FilledButton(onPressed: _openDownload, child: Text(_downloadLabel)),
        ];
      case _Stage.installing:
        return [
          TextButton(onPressed: _cancelInstall, child: Text(context.l10n.commonCancel)),
        ];
      case _Stage.ready:
        return [
          TextButton(onPressed: close, child: Text(context.l10n.appLater)),
          FilledButton(
            onPressed: _restart,
            child: Text(
              _appliesAfterExit ? context.l10n.appInstallAndRestart : context.l10n.appRestartNow,
            ),
          ),
        ];
    }
  }
}
