import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/fonts.dart';
import '../../../core/utils/content_utils.dart';
import '../../../core/utils/menu_shortcuts.dart';
import '../../../core/utils/platform_info.dart';
import '../../providers/providers.dart';
import '../../providers/settings_provider.dart';
import '../../screens/task_editor_screen.dart';

bool _searchDialogOpen = false;

/// Opens the search over the whole database as a modal dialog centred over
/// the main screen; the matches are listed in the dialog itself.
///
/// Picking a match closes the dialog, reveals the task in the tree and
/// selects it (and opens it full-screen on a phone, which has no editor
/// pane). The last query is kept, selected, for the next time it opens.
///
/// A second call while the dialog is up does nothing: Find is reachable from
/// a menu as well as a shortcut, and two stacked search dialogs would be
/// nonsense.
Future<void> showSearchDialog(BuildContext context) async {
  if (_searchDialogOpen) return;
  _searchDialogOpen = true;
  try {
    await showDialog<void>(
      context: context,
      builder: (_) => const SearchDialog(),
    );
  } finally {
    _searchDialogOpen = false;
  }
}

/// Search across task titles and note content. See [showSearchDialog].
class SearchDialog extends ConsumerStatefulWidget {
  const SearchDialog({super.key});

  @override
  ConsumerState<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends ConsumerState<SearchDialog> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _itemKeys = <int, GlobalKey>{};
  Timer? _debounce;
  List<_SearchResult> _results = [];
  bool _isSearching = false;
  int _searchSeq = 0;

  /// The match Enter opens, moved with Up/Down.
  int _highlighted = 0;

  @override
  void initState() {
    super.initState();
    // Restore the previous query, selected so typing replaces it.
    final previous = ref.read(searchQueryProvider);
    if (previous.isNotEmpty) {
      _controller.value = TextEditingValue(
        text: previous,
        selection: TextSelection(baseOffset: 0, extentOffset: previous.length),
      );
      _performSearch(previous);
    }
  }

  @override
  void dispose() {
    // Also cleared here, not only when showDialog's future completes: a
    // navigator torn down under the dialog never completes it.
    _searchDialogOpen = false;
    _debounce?.cancel();
    _controller.dispose();
    _scrollController.dispose();
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
        _highlighted = 0;
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
        title: row.title.isEmpty ? '(untitled)' : row.title,
        snippet: snippet,
      ));
    }

    setState(() {
      _results = results;
      _isSearching = false;
      _highlighted = 0;
      _itemKeys.clear();
    });
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  void _open(int taskId) {
    final navigator = Navigator.of(context);
    final compact = isCompactLayout(context);
    // Before the selection moves, so the editor finds it when the note loads.
    ref.read(editorRevealProvider.notifier).value =
        EditorRevealRequest(taskId: taskId, query: _controller.text);
    ref.read(taskTreeControllerProvider)?.revealNode(taskId);
    ref.read(selectedTaskIdProvider.notifier).value = taskId;
    navigator.pop();
    // Compact layouts have no editor pane — open the result full-screen.
    if (compact) {
      navigator.push(
        MaterialPageRoute(builder: (_) => const TaskEditorScreen()),
      );
    }
  }

  void _moveHighlight(int delta) {
    if (_results.isEmpty) return;
    final next = (_highlighted + delta).clamp(0, _results.length - 1);
    if (next == _highlighted) return;
    setState(() => _highlighted = next);
    // Neighbouring rows are normally built already (cache extent), so their
    // context is there to scroll to.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _itemKeys[next]?.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignmentPolicy: delta > 0
              ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
              : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // The bytes being searched belong to the open database; a lock, swap or
    // close takes the dialog with it rather than leaving stale matches up.
    ref.listen(databaseProvider, (previous, next) {
      if (!identical(previous, next) && mounted) Navigator.of(context).pop();
    });

    final theme = Theme.of(context);
    final compact = isCompactLayout(context);
    final settings = ref.watch(settingsProvider);
    // Sized from the fonts the user chose for what is being searched: the
    // query and snippets in the editor's, the titles in the tree's. The
    // theme's body sizes are chrome sizes, and read as small next to a note.
    final queryStyle = fontSettingsToStyle(settings).copyWith(
      fontSize: settings.fontSize + 4,
      fontWeight: FontWeight.normal,
      fontStyle: FontStyle.normal,
      color: theme.colorScheme.onSurface,
    );
    final styles = _ResultStyles(
      title: treeFontSettingsToStyle(settings).copyWith(
        fontSize: settings.treeFontSize,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
      snippet: fontSettingsToStyle(settings).copyWith(
        fontSize: settings.fontSize,
        fontWeight: FontWeight.normal,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      highlightBackground: theme.colorScheme.primaryContainer,
      highlightColor: theme.colorScheme.onPrimaryContainer,
    );

    final field = CallbackShortcuts(
      // Nearer than the app-level text editing shortcuts, so Up/Down move
      // through the matches instead of the caret.
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _moveHighlight(1),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _moveHighlight(-1),
        const SingleActivator(LogicalKeyboardKey.pageDown): () =>
            _moveHighlight(8),
        const SingleActivator(LogicalKeyboardKey.pageUp): () =>
            _moveHighlight(-8),
        // Find again closes it, as it used to close the panel.
        findActivator: () => Navigator.of(context).pop(),
      },
      child: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Search tasks...',
          isDense: true,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
        style: queryStyle,
        textInputAction: TextInputAction.search,
        onChanged: _onQueryChanged,
        onSubmitted: (_) {
          if (_results.isNotEmpty) _open(_results[_highlighted].taskId);
        },
      ),
    );

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      child: Row(
        children: [
          Icon(Icons.search, size: 24, color: theme.colorScheme.outline),
          const SizedBox(width: 10),
          Expanded(child: field),
          if (_isSearching)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_results.isNotEmpty)
            Text(
              '${_results.length} result${_results.length == 1 ? '' : 's'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );

    final query = _controller.text;
    Widget? body;
    if (_results.isNotEmpty) {
      body = ListView.builder(
        controller: _scrollController,
        shrinkWrap: !compact,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final result = _results[index];
          return _SearchResultTile(
            key: _itemKeys.putIfAbsent(index, GlobalKey.new),
            result: result,
            query: query,
            styles: styles,
            highlighted: index == _highlighted,
            onTap: () => _open(result.taskId),
          );
        },
      );
    } else if (query.trim().isNotEmpty && !_isSearching) {
      body = Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'No matches',
          textAlign: TextAlign.center,
          style: styles.snippet.copyWith(color: theme.colorScheme.outline),
        ),
      );
    }

    final content = Column(
      mainAxisSize: compact ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (body != null) ...[
          const Divider(height: 1),
          compact ? Expanded(child: body) : Flexible(child: body),
        ],
      ],
    );

    if (compact) {
      return Dialog.fullscreen(child: SafeArea(child: content));
    }

    // A fixed top edge, not vertical centring: the field must not jump as the
    // list under it grows and shrinks with every keystroke.
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      alignment: Alignment.topCenter,
      insetPadding: EdgeInsets.fromLTRB(24, size.height * 0.12, 24, 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 760,
          minWidth: 760 < size.width - 48 ? 760 : size.width - 48,
          maxHeight: size.height * 0.7,
        ),
        child: content,
      ),
    );
  }
}

/// A single search result tile with highlighted matches.
class _SearchResultTile extends StatelessWidget {
  final _SearchResult result;
  final String query;
  final _ResultStyles styles;
  final bool highlighted;
  final VoidCallback onTap;

  const _SearchResultTile({
    super.key,
    required this.result,
    required this.query,
    required this.styles,
    required this.highlighted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: highlighted
          ? theme.colorScheme.secondaryContainer
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title with highlighted match
              _HighlightedText(
                text: result.title,
                query: query,
                style: styles.title,
                highlightStyle: styles.highlighted(styles.title),
                maxLines: 1,
              ),
              // Content snippet with highlighted match
              if (result.snippet.isNotEmpty) ...[
                const SizedBox(height: 4),
                _HighlightedText(
                  text: result.snippet,
                  query: query,
                  style: styles.snippet,
                  highlightStyle: styles.highlighted(styles.snippet),
                  maxLines: 2,
                ),
              ],
            ],
          ),
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

/// The text styles of a result row, worked out once per build.
class _ResultStyles {
  final TextStyle title;
  final TextStyle snippet;
  final Color highlightBackground;
  final Color highlightColor;

  const _ResultStyles({
    required this.title,
    required this.snippet,
    required this.highlightBackground,
    required this.highlightColor,
  });

  TextStyle highlighted(TextStyle style) =>
      style.copyWith(backgroundColor: highlightBackground, color: highlightColor);
}

class _SearchResult {
  final int taskId;
  final String title;
  final String snippet;

  const _SearchResult({
    required this.taskId,
    required this.title,
    required this.snippet,
  });
}
