import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/fonts.dart';
import '../../../core/theme/noo_chrome.dart';
import '../../../core/utils/app_log.dart';
import '../../../core/utils/platform_info.dart';
import '../../../core/utils/save_dialog.dart';
import '../../../core/utils/share_utils.dart';
import 'classic_form.dart';

/// Help → Logs → App Log: the app's own log for this run ([AppLog]) —
/// debug messages, framework errors and uncaught errors, newest first. It
/// follows the log live while open.
Future<void> showAppLogDialog(BuildContext context, {AppLog? log}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => AppLogDialog(log: log ?? AppLog.instance),
  );
}

enum _LevelFilter { all, warnings, errors }

class AppLogDialog extends StatefulWidget {
  const AppLogDialog({super.key, required this.log});

  final AppLog log;

  @override
  State<AppLogDialog> createState() => _AppLogDialogState();
}

class _AppLogDialogState extends State<AppLogDialog> {
  final _search = TextEditingController();
  _LevelFilter _level = _LevelFilter.all;

  @override
  void initState() {
    super.initState();
    widget.log.addListener(_changed);
    _search.addListener(_changed);
  }

  @override
  void dispose() {
    widget.log.removeListener(_changed);
    _search.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  List<AppLogEntry> get _visible {
    final query = _search.text.trim().toLowerCase();
    return widget.log.entries.reversed.where((e) {
      final levelOk = switch (_level) {
        _LevelFilter.all => true,
        _LevelFilter.warnings => e.level != AppLogLevel.info,
        _LevelFilter.errors => e.level == AppLogLevel.error,
      };
      return levelOk &&
          (query.isEmpty || e.message.toLowerCase().contains(query));
    }).toList();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.log.toText()));
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      const SnackBar(content: Text('App log copied to clipboard')),
    );
  }

  Future<void> _save() async {
    final text = widget.log.toText();
    final name =
        'noo-log-${DateFormat('yyyyMMdd-HHmmss').format(DateTime.now())}.txt';
    // Scoped storage has no arbitrary save paths — share the file instead.
    if (isMobilePlatform) {
      await shareBytes(filename: name, bytes: utf8.encode(text), title: 'App Log');
      return;
    }
    final path = await pickSavePath(
      dialogTitle: 'Save App Log',
      fileName: name,
      type: FileType.custom,
      allowedExtensions: const ['txt', 'log'],
      requiredExtension: '.txt',
    );
    if (path == null) return;
    String message;
    try {
      await File(path).writeAsString(text);
      message = 'Saved to $path';
    } catch (e) {
      message = 'Failed to save: $e';
    }
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)
        ?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    final hasEntries = widget.log.entries.isNotEmpty;
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _toolbar(context),
        const SizedBox(height: 8),
        Expanded(child: _list(context)),
      ],
    );

    if (compact) {
      return Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('App Log'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.copy_all_outlined),
                tooltip: 'Copy',
                onPressed: hasEntries ? _copy : null,
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share',
                onPressed: hasEntries ? _save : null,
              ),
              IconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: 'Clear log',
                onPressed: hasEntries ? widget.log.clear : null,
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: body,
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final scale = classicUiScale(context);
    return AlertDialog(
      title: const Text('App Log'),
      titleTextStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      shape: NooChrome.of(context).dialogShape,
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      content: SizedBox(
        width: (960 * scale).clamp(0, size.width - 80),
        height: (640 * scale).clamp(0, size.height - 180),
        child: body,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      actions: [
        OutlinedButton(
          style: classicButtonStyle(context),
          onPressed: hasEntries ? widget.log.clear : null,
          child: const Text('Clear Log'),
        ),
        OutlinedButton(
          style: classicButtonStyle(context),
          onPressed: hasEntries ? _copy : null,
          child: const Text('Copy'),
        ),
        OutlinedButton(
          style: classicButtonStyle(context),
          onPressed: hasEntries ? _save : null,
          child: const Text('Save...'),
        ),
        FilledButton(
          style: classicButtonStyle(context),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _toolbar(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _search,
            decoration: const InputDecoration(
              isDense: true,
              prefixIcon: Icon(Icons.search, size: 18),
              hintText: 'Search',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        DropdownButton<_LevelFilter>(
          value: _level,
          onChanged: (v) => setState(() => _level = v ?? _level),
          items: const [
            DropdownMenuItem(value: _LevelFilter.all, child: Text('All')),
            DropdownMenuItem(
              value: _LevelFilter.warnings,
              child: Text('Warnings and errors'),
            ),
            DropdownMenuItem(value: _LevelFilter.errors, child: Text('Errors')),
          ],
        ),
      ],
    );
  }

  Widget _list(BuildContext context) {
    final theme = Theme.of(context);
    final entries = _visible;
    if (entries.isEmpty) {
      return Center(
        child: Text(
          widget.log.entries.isEmpty
              ? 'Nothing has been logged yet.'
              : 'No lines match.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      );
    }
    final mono = theme.textTheme.bodySmall?.copyWith(
      fontFamily: kMonospaceFont,
      height: 1.35,
    );
    final stamp = DateFormat('HH:mm:ss.SSS');
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
      ),
      child: SelectionArea(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final e = entries[i];
            final color = switch (e.level) {
              AppLogLevel.info => theme.colorScheme.onSurfaceVariant,
              AppLogLevel.warning => Colors.orange.shade700,
              AppLogLevel.error => theme.colorScheme.error,
            };
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stamp.format(e.time), style: mono?.copyWith(color: color)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.message,
                      style: e.level == AppLogLevel.info
                          ? mono
                          : mono?.copyWith(color: color),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
