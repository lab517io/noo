import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/content_utils.dart';
import '../../../core/utils/platform_info.dart';
import '../../providers/providers.dart';
import '../../screens/task_editor_screen.dart';

/// Inline search panel shown below the toolbar.
class SearchPanel extends ConsumerStatefulWidget {
  const SearchPanel({super.key});

  @override
  ConsumerState<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends ConsumerState<SearchPanel> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _escKeyFocusNode = FocusNode(skipTraversal: true);
  Timer? _debounce;
  List<_SearchResult> _results = [];
  bool _isSearching = false;
  int _searchSeq = 0;

  @override
  void initState() {
    super.initState();
    // Autofocus on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    // Restore previous query if panel was reopened
    final currentQuery = ref.read(searchQueryProvider);
    if (currentQuery.isNotEmpty) {
      _controller.text = currentQuery;
      _performSearch(currentQuery);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _escKeyFocusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String query) {
    ref.read(searchQueryProvider.notifier).value = query;
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      // Invalidate any in-flight search so its results can't reappear
      // after the field was cleared.
      _searchSeq++;
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    final db = ref.read(databaseProvider);
    if (db == null) return;

    setState(() => _isSearching = true);

    // Only the most recent query may apply its results — a slower earlier
    // query completing last must not overwrite them.
    final searchSeq = ++_searchSeq;
    final rows = await db.searchTasks(query);
    if (!mounted || searchSeq != _searchSeq) return;

    final results = <_SearchResult>[];
    final lowerQuery = query.toLowerCase();

    for (final row in rows) {
      final plaintext = extractPlaintext(row.content);
      final titleMatch = row.title.toLowerCase().contains(lowerQuery);
      final contentMatch = plaintext.toLowerCase().contains(lowerQuery);

      // Skip false positives from JSON/HTML structure matching
      if (!titleMatch && !contentMatch) continue;

      final snippet = contentMatch ? extractSnippet(plaintext, query) : '';

      results.add(_SearchResult(
        taskId: row.id,
        parentId: row.parentId,
        title: row.title.isEmpty ? '(untitled)' : row.title,
        snippet: snippet,
        matchInTitle: titleMatch,
        matchInContent: contentMatch,
      ));
    }

    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }
  }

  void _close() {
    ref.read(searchVisibleProvider.notifier).value = false;
    ref.read(searchQueryProvider.notifier).value = '';
    // Disposing this panel's focus node would otherwise drop focus on the
    // enclosing scope, leaving the editor unfocused (and Ctrl+C dead) while it
    // still paints its selection.
    restoreEditorFocus(ref);
  }

  void _navigateToResult(int taskId) {
    final treeController = ref.read(taskTreeControllerProvider);
    if (treeController != null) {
      treeController.revealNode(taskId);
    }
    ref.read(selectedTaskIdProvider.notifier).value = taskId;
    // Compact layouts have no editor pane — open the result full-screen.
    if (isCompactLayout(context)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TaskEditorScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search input row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.search, size: 20, color: theme.colorScheme.outline),
                const SizedBox(width: 8),
                Expanded(
                  child: KeyboardListener(
                    focusNode: _escKeyFocusNode,
                    onKeyEvent: (event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.escape) {
                        _close();
                      }
                    },
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Search tasks...',
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      style: theme.textTheme.bodyMedium,
                      onChanged: _onQueryChanged,
                      onSubmitted: (_) {
                        // Navigate to first result on Enter
                        if (_results.isNotEmpty) {
                          _navigateToResult(_results.first.taskId);
                        }
                      },
                    ),
                  ),
                ),
                if (_isSearching)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_results.isNotEmpty)
                  Text(
                    '${_results.length} result${_results.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(4),
                  onTap: _close,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close, size: 18, color: theme.colorScheme.outline),
                  ),
                ),
              ],
            ),
          ),
          // Results list
          if (_results.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return _SearchResultTile(
                    result: result,
                    query: _controller.text,
                    onTap: () => _navigateToResult(result.taskId),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// A single search result tile with highlighted matches.
class _SearchResultTile extends StatelessWidget {
  final _SearchResult result;
  final String query;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.result,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with highlighted match
            _HighlightedText(
              text: result.title,
              query: query,
              style: theme.textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w500,
              ),
              highlightStyle: theme.textTheme.bodyMedium!.copyWith(
                fontWeight: FontWeight.w500,
                backgroundColor: theme.colorScheme.primaryContainer,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            // Content snippet with highlighted match
            if (result.snippet.isNotEmpty) ...[
              const SizedBox(height: 2),
              _HighlightedText(
                text: result.snippet,
                query: query,
                style: theme.textTheme.bodySmall!.copyWith(
                  color: theme.colorScheme.outline,
                ),
                highlightStyle: theme.textTheme.bodySmall!.copyWith(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Text widget that highlights occurrences of [query].
class _HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle style;
  final TextStyle highlightStyle;
  final int? maxLines;

  const _HighlightedText({
    required this.text,
    required this.query,
    required this.style,
    required this.highlightStyle,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(text, style: style, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }

    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int start = 0;

    while (true) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index < 0) {
        spans.add(TextSpan(text: text.substring(start), style: style));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index), style: style));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: highlightStyle,
      ));
      start = index + query.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _SearchResult {
  final int taskId;
  final int? parentId;
  final String title;
  final String snippet;
  final bool matchInTitle;
  final bool matchInContent;

  const _SearchResult({
    required this.taskId,
    required this.parentId,
    required this.title,
    required this.snippet,
    required this.matchInTitle,
    required this.matchInContent,
  });
}
