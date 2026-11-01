import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

/// A short piece of Markdown as Flutter text.
///
/// Built for release notes: headings, paragraphs, bullet and numbered lists,
/// emphasis, inline code, links and block quotes — what prose uses. Fenced
/// code is set in monospace and a table is flattened to one line per row,
/// which is legible but no more; a caller with a narrow box strips those
/// first (`dialogReleaseNotes`). `flutter_markdown` is discontinued, and a
/// renderer for this much is smaller than any replacement package.
///
/// Links open in the browser. Every block is an ordinary [Text], so wrapping
/// the widget in a [SelectionArea] makes the whole thing selectable.
class MarkdownText extends StatefulWidget {
  const MarkdownText(this.source, {super.key, this.style});

  final String source;

  /// The body style; headings and code derive from it. Defaults to the
  /// theme's `bodyMedium`.
  final TextStyle? style;

  @override
  State<MarkdownText> createState() => _MarkdownTextState();
}

class _MarkdownTextState extends State<MarkdownText> {
  final List<GestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Recognizers belong to the spans of one build; the next build makes
    // new ones.
    _disposeRecognizers();
    final theme = Theme.of(context);
    final base =
        widget.style ?? theme.textTheme.bodyMedium ?? const TextStyle();
    final nodes = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
    ).parse(widget.source.replaceAll('\r\n', '\n'));
    final blocks = _blocks(nodes, base, theme);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < blocks.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          blocks[i],
        ],
      ],
    );
  }

  List<Widget> _blocks(List<md.Node> nodes, TextStyle base, ThemeData theme) {
    final out = <Widget>[];
    for (final node in nodes) {
      final widget = _block(node, base, theme);
      if (widget != null) out.add(widget);
    }
    return out;
  }

  Widget? _block(md.Node node, TextStyle base, ThemeData theme) {
    if (node is md.Text) {
      final text = node.text.trim();
      return text.isEmpty ? null : Text(text, style: base);
    }
    final element = node as md.Element;
    final children = element.children ?? const <md.Node>[];
    switch (element.tag) {
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        final level = int.parse(element.tag.substring(1));
        final size =
            (base.fontSize ?? 14) *
            switch (level) {
              1 => 1.4,
              2 => 1.25,
              3 => 1.1,
              _ => 1.0,
            };
        final style = base.copyWith(
          fontSize: size,
          fontWeight: FontWeight.bold,
        );
        return Padding(
          padding: EdgeInsets.only(top: level <= 2 ? 4 : 2),
          child: Text.rich(_inline(children, style, theme), style: style),
        );
      case 'p':
        return Text.rich(_inline(children, base, theme), style: base);
      case 'ul':
      case 'ol':
        final start = int.tryParse(element.attributes['start'] ?? '') ?? 1;
        final items = <Widget>[];
        var n = start;
        for (final item in children) {
          if (item is! md.Element || item.tag != 'li') continue;
          final marker = element.tag == 'ol' ? '${n++}.' : '•';
          items.add(
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: element.tag == 'ol' ? 22 : 14,
                    child: Text(marker, style: base),
                  ),
                  Expanded(child: _listItem(item, base, theme)),
                ],
              ),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: items,
        );
      case 'blockquote':
        return Container(
          padding: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: theme.dividerColor, width: 3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: _blocks(children, base, theme),
          ),
        );
      case 'hr':
        return const Divider(height: 12);
      case 'pre':
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(6),
          color: theme.colorScheme.surfaceContainerHighest,
          child: Text(element.textContent.trimRight(), style: _code(base)),
        );
      case 'table':
        final rows = <Widget>[];
        for (final section in children) {
          if (section is! md.Element) continue;
          for (final row in section.children ?? const <md.Node>[]) {
            if (row is! md.Element) continue;
            final cells = [
              for (final cell in row.children ?? const <md.Node>[])
                if (cell is md.Element) cell.children ?? const <md.Node>[],
            ];
            final spans = <InlineSpan>[];
            for (var i = 0; i < cells.length; i++) {
              if (i > 0) spans.add(const TextSpan(text: '  ·  '));
              spans.add(_inline(cells[i], base, theme));
            }
            rows.add(Text.rich(TextSpan(children: spans), style: base));
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: rows,
        );
      default:
        return Text.rich(_inline(children, base, theme), style: base);
    }
  }

  /// A list item holds either inline content (a tight list) or blocks (a
  /// loose one, or an item with a nested list).
  Widget _listItem(md.Element item, TextStyle base, ThemeData theme) {
    final children = item.children ?? const <md.Node>[];
    final hasBlocks = children.any(
      (n) => n is md.Element && _blockTags.contains(n.tag),
    );
    if (!hasBlocks) {
      return Text.rich(_inline(children, base, theme), style: base);
    }
    final blocks = <Widget>[];
    final run = <md.Node>[];
    void flush() {
      if (run.isEmpty) return;
      final span = _inline(run, base, theme);
      if (span.toPlainText().trim().isNotEmpty) {
        blocks.add(Text.rich(span, style: base));
      }
      run.clear();
    }

    for (final child in children) {
      if (child is md.Element && _blockTags.contains(child.tag)) {
        flush();
        final w = _block(child, base, theme);
        if (w != null) blocks.add(w);
      } else {
        run.add(child);
      }
    }
    flush();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: blocks,
    );
  }

  static const _blockTags = {
    'p', 'ul', 'ol', 'blockquote', 'pre', 'hr', 'table',
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6', //
  };

  TextSpan _inline(List<md.Node> nodes, TextStyle style, ThemeData theme) =>
      TextSpan(children: [for (final n in nodes) _span(n, style, theme)]);

  InlineSpan _span(md.Node node, TextStyle style, ThemeData theme) {
    if (node is md.Text) return TextSpan(text: node.text, style: style);
    final element = node as md.Element;
    final children = element.children ?? const <md.Node>[];
    switch (element.tag) {
      case 'strong':
        return _inline(
          children,
          style.copyWith(fontWeight: FontWeight.bold),
          theme,
        );
      case 'em':
        return _inline(
          children,
          style.copyWith(fontStyle: FontStyle.italic),
          theme,
        );
      case 'del':
        return _inline(
          children,
          style.copyWith(decoration: TextDecoration.lineThrough),
          theme,
        );
      case 'code':
        return TextSpan(
          text: element.textContent,
          style: _code(style).copyWith(
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        );
      case 'a':
        final href = element.attributes['href'];
        final recognizer = href == null
            ? null
            : (TapGestureRecognizer()..onTap = () => _open(href));
        if (recognizer != null) _recognizers.add(recognizer);
        return _inline(
          children,
          style.copyWith(
            color: theme.colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
          theme,
        ).withRecognizer(recognizer);
      case 'br':
        return TextSpan(text: '\n', style: style);
      case 'img':
        return TextSpan(text: element.attributes['alt'] ?? '', style: style);
      default:
        return _inline(children, style, theme);
    }
  }

  static TextStyle _code(TextStyle style) => style.copyWith(
    fontFamily: 'monospace',
    fontFamilyFallback: const ['Source Code Pro', 'Consolas', 'Menlo'],
  );

  Future<void> _open(String href) async {
    final url = Uri.tryParse(href);
    if (url == null) return;
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

extension on TextSpan {
  /// The same span with [recognizer] on it. A recognizer on an outer span
  /// covers the children, which have none of their own.
  TextSpan withRecognizer(GestureRecognizer? recognizer) => TextSpan(
    text: text,
    children: children,
    style: style,
    recognizer: recognizer,
  );
}
