import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/duration_formatter.dart';
import '../../../core/utils/platform_info.dart';
import '../../../core/utils/save_dialog.dart';
import '../../../core/utils/share_utils.dart';
import '../../../data/services/time_report_service.dart';
import '../../providers/providers.dart';
import '../task_tree/task_tree_controller.dart';
import '../task_tree/tree_node.dart';

/// Wizard dialog for generating time-spent reports across selected tasks.
///
/// Layout: a left pane with task selection, date range and format options,
/// and a right pane with a live preview of the generated report. The user
/// can copy the report to the clipboard or save it to a file.
class TimeReportDialog extends ConsumerStatefulWidget {
  const TimeReportDialog({super.key});

  @override
  ConsumerState<TimeReportDialog> createState() => _TimeReportDialogState();
}

class _TimeReportDialogState extends ConsumerState<TimeReportDialog> {
  final Set<int> _selectedIds = <int>{};
  bool _includeDescendants = true;
  late DateTime _fromDate;
  late DateTime _toDate;
  TimeReportFormat _format = TimeReportFormat.tree;
  bool _showEmptyTasks = false;

  TimeReportResult? _result;
  bool _generating = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = DateTime(now.year, now.month + 1, 0);
    // Trigger an initial (empty) generation so the preview shows the hint.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleGenerate());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _scheduleGenerate() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), _generate);
  }

  Future<void> _generate() async {
    final db = ref.read(databaseProvider);
    if (db == null) return;

    setState(() {
      _generating = true;
    });

    final service = TimeReportService(db);
    final config = TimeReportConfig(
      selectedTaskIds: _selectedIds.toSet(),
      includeDescendants: _includeDescendants,
      fromDate: _fromDate,
      toDate: _toDate,
      format: _format,
      showEmptyTasks: _showEmptyTasks,
    );

    try {
      final result = await service.generate(config);
      if (!mounted) return;
      setState(() {
        _result = result;
        _generating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _generating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate report: $e')),
      );
    }
  }

  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        if (_toDate.isBefore(_fromDate)) _toDate = _fromDate;
      });
      _scheduleGenerate();
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _toDate = picked;
        if (_fromDate.isAfter(_toDate)) _fromDate = _toDate;
      });
      _scheduleGenerate();
    }
  }

  void _applyPreset(_DatePreset preset) {
    final now = DateTime.now();
    setState(() {
      switch (preset) {
        case _DatePreset.today:
          _fromDate = DateTime(now.year, now.month, now.day);
          _toDate = _fromDate;
          break;
        case _DatePreset.thisWeek:
          final monday = now.subtract(Duration(days: now.weekday - 1));
          _fromDate = DateTime(monday.year, monday.month, monday.day);
          _toDate = _fromDate.add(const Duration(days: 6));
          break;
        case _DatePreset.thisMonth:
          _fromDate = DateTime(now.year, now.month, 1);
          _toDate = DateTime(now.year, now.month + 1, 0);
          break;
        case _DatePreset.lastMonth:
          _fromDate = DateTime(now.year, now.month - 1, 1);
          _toDate = DateTime(now.year, now.month, 0);
          break;
        case _DatePreset.thisYear:
          _fromDate = DateTime(now.year, 1, 1);
          _toDate = DateTime(now.year, 12, 31);
          break;
      }
    });
    _scheduleGenerate();
  }

  void _toggleTask(int id, bool? value) {
    setState(() {
      if (value == true) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
      }
    });
    _scheduleGenerate();
  }

  Future<void> _copyToClipboard() async {
    final text = _result?.text ?? '';
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report copied to clipboard')),
    );
  }

  Future<void> _saveToFile() async {
    final text = _result?.text ?? '';
    if (text.isEmpty) return;

    final isCsv = _format == TimeReportFormat.csv;
    final defaultName = isCsv ? 'time-report.csv' : 'time-report.md';
    final extensions = isCsv ? ['csv'] : ['md'];

    // Scoped storage has no arbitrary save paths — share the report instead.
    if (isMobilePlatform) {
      await shareBytes(
        filename: defaultName,
        bytes: utf8.encode(text),
        title: 'Time Report',
      );
      return;
    }

    final path = await pickSavePath(
      dialogTitle: 'Save Time Report',
      fileName: defaultName,
      type: FileType.custom,
      allowedExtensions: extensions,
      requiredExtension: _format == TimeReportFormat.csv ? '.csv' : '.md',
    );

    if (path == null) return;

    try {
      final file = await _writeFile(path, text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to $file')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    }
  }

  Future<String> _writeFile(String path, String text) async {
    final f = await File(path).writeAsString(text);
    return f.path;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = ref.watch(taskTreeControllerProvider);

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 1100,
          maxHeight: 720,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.assessment_outlined,
                      color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('Time Report',
                      style: theme.textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                // The 380px controls pane + preview don't fit side by side on
                // a phone; stack them there instead.
                child: isCompactLayout(context)
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildLeftPane(theme, controller)),
                          const Divider(),
                          Expanded(child: _buildPreviewPane(theme)),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 380,
                            child: _buildLeftPane(theme, controller),
                          ),
                          const VerticalDivider(),
                          Expanded(child: _buildPreviewPane(theme)),
                        ],
                      ),
              ),
              const Divider(),
              _buildFooter(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPane(ThemeData theme, TaskTreeController? controller) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle(theme, 'Tasks'),
          if (controller == null || controller.roots.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'No tasks available.',
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            )
          else
            Container(
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Scrollbar(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final root in controller.roots)
                        _buildTreeNode(theme, root, 0),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          Row(
            children: [
              TextButton(
                onPressed: _selectedIds.isEmpty
                    ? null
                    : () {
                        setState(() => _selectedIds.clear());
                        _scheduleGenerate();
                      },
                child: const Text('Clear selection'),
              ),
              const Spacer(),
              Text(
                '${_selectedIds.length} selected',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          CheckboxListTile(
            value: _includeDescendants,
            onChanged: (v) {
              setState(() => _includeDescendants = v ?? false);
              _scheduleGenerate();
            },
            title: const Text('Include descendants'),
            subtitle: const Text(
                'Also report time from child tasks of each selected node.'),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          ),
          const SizedBox(height: 8),
          _buildSectionTitle(theme, 'Date range'),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text('From: ${_fmt(_fromDate)}'),
                  onPressed: _pickFromDate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text('To: ${_fmt(_toDate)}'),
                  onPressed: _pickToDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final preset in _DatePreset.values)
                ActionChip(
                  label: Text(preset.label),
                  onPressed: () => _applyPreset(preset),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionTitle(theme, 'Format'),
          RadioGroup<TimeReportFormat>(
            groupValue: _format,
            onChanged: (v) {
              if (v == null) return;
              setState(() => _format = v);
              _scheduleGenerate();
            },
            child: Column(
              children: [
                for (final format in TimeReportFormat.values)
                  RadioListTile<TimeReportFormat>(
                    value: format,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(format.label),
                  ),
              ],
            ),
          ),
          if (_format == TimeReportFormat.tree ||
              _format == TimeReportFormat.treeWithDays)
            CheckboxListTile(
              value: _showEmptyTasks,
              onChanged: (v) {
                setState(() => _showEmptyTasks = v ?? false);
                _scheduleGenerate();
              },
              title: const Text('Show empty tasks'),
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 6),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTreeNode(ThemeData theme, TaskTreeNode node, int depth) {
    final id = node.id;
    final selected = id != null && _selectedIds.contains(id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: id == null ? null : () => _toggleTask(id, !selected),
          child: Padding(
            padding: EdgeInsets.fromLTRB(8.0 + depth * 16.0, 2, 8, 2),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: selected,
                    onChanged: id == null ? null : (v) => _toggleTask(id, v),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    node.title.isEmpty ? '(untitled)' : node.title,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final child in node.children)
          _buildTreeNode(theme, child, depth + 1),
      ],
    );
  }

  Widget _buildPreviewPane(ThemeData theme) {
    final text = _result?.text ?? '';
    if (text.isEmpty && !_generating) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _selectedIds.isEmpty
                ? 'Select one or more tasks to generate a report.'
                : 'No time records in the selected period.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.outline),
          ),
        ),
      );
    }

    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(6),
            color: theme.colorScheme.surfaceContainerLowest,
          ),
          child: Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                text,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
        if (_generating)
          const Positioned(
            top: 8,
            right: 16,
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(ThemeData theme) {
    final result = _result;
    final hasOutput = result != null && result.text.isNotEmpty;
    final totalText = result == null
        ? ''
        : 'Total: ${DurationFormatter.formatHuman(result.totalDuration)}'
            '   •   ${result.recordsCount} record${result.recordsCount == 1 ? '' : 's'}';
    final buttons = [
      TextButton.icon(
        icon: const Icon(Icons.refresh),
        label: const Text('Regenerate'),
        onPressed: _generate,
      ),
      TextButton.icon(
        icon: Icon(isMobilePlatform ? Icons.share : Icons.save_outlined),
        label: Text(isMobilePlatform ? 'Share…' : 'Save…'),
        onPressed: hasOutput ? _saveToFile : null,
      ),
      FilledButton.icon(
        icon: const Icon(Icons.copy_all_outlined),
        label: const Text('Copy'),
        onPressed: hasOutput ? _copyToClipboard : null,
      ),
    ];

    // Phones don't fit total + three labeled buttons on one line; stack the
    // total above and let the buttons wrap.
    if (isCompactLayout(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (totalText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(totalText, style: theme.textTheme.bodyMedium),
            ),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            children: buttons,
          ),
        ],
      );
    }

    return Row(
      children: [
        Text(totalText, style: theme.textTheme.bodyMedium),
        const Spacer(),
        for (final b in buttons) ...[const SizedBox(width: 8), b],
      ],
    );
  }

  String _fmt(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

enum _DatePreset { today, thisWeek, thisMonth, lastMonth, thisYear }

extension _DatePresetX on _DatePreset {
  String get label {
    switch (this) {
      case _DatePreset.today:
        return 'Today';
      case _DatePreset.thisWeek:
        return 'This week';
      case _DatePreset.thisMonth:
        return 'This month';
      case _DatePreset.lastMonth:
        return 'Last month';
      case _DatePreset.thisYear:
        return 'This year';
    }
  }
}
