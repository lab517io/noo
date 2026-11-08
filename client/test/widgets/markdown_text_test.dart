import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/presentation/widgets/markdown_text.dart';

Future<void> _pump(WidgetTester tester, String source) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: SizedBox(width: 400, child: MarkdownText(source))),
  ),
);

/// Every leaf span under every [Text] on screen, with its resolved style.
List<TextSpan> _spans(WidgetTester tester) {
  final out = <TextSpan>[];
  void walk(InlineSpan span) {
    if (span is TextSpan) {
      if (span.text != null) out.add(span);
      span.children?.forEach(walk);
    }
  }

  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    if (text.textSpan != null) walk(text.textSpan!);
  }
  return out;
}

String _plain(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan!.toPlainText())
    .join('\n');

void main() {
  testWidgets('markers are rendered, not shown', (tester) async {
    await _pump(
      tester,
      '## What changed\n\n'
      'Paste is **faster** and `Ctrl+Shift+V` is *plain*.\n\n'
      '- one\n- two\n\n'
      '1. first\n2. second\n\n'
      'See [the notes](https://example.com/notes).',
    );
    final plain = _plain(tester);
    expect(plain, isNot(contains('#')));
    expect(plain, isNot(contains('*')));
    expect(plain, isNot(contains('`')));
    expect(plain, isNot(contains('[')));
    expect(plain, contains('What changed'));
    expect(plain, contains('Paste is faster and Ctrl+Shift+V is plain.'));
    expect(plain, contains('•'));
    expect(plain, contains('one'));
    expect(plain, contains('2.'));
    expect(plain, contains('the notes'));

    final spans = _spans(tester);
    TextSpan of(String text) => spans.firstWhere((s) => s.text == text);
    expect(of('faster').style?.fontWeight, FontWeight.bold);
    expect(of('plain').style?.fontStyle, FontStyle.italic);
    expect(of('Ctrl+Shift+V').style?.fontFamily, 'monospace');
    expect(of('the notes').style?.decoration, TextDecoration.underline);
    expect(of('What changed').style?.fontWeight, FontWeight.bold);
  });

  testWidgets('headings grow with level and inherit the base style', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MarkdownText(
            '# One\n\n## Two\n\nBody',
            style: TextStyle(fontSize: 10),
          ),
        ),
      ),
    );
    final spans = _spans(tester);
    double size(String text) =>
        spans.firstWhere((s) => s.text == text).style!.fontSize!;
    expect(size('One'), greaterThan(size('Two')));
    expect(size('Two'), greaterThan(size('Body')));
    expect(size('Body'), 10);
  });

  testWidgets('a nested list and a loose item render their blocks', (
    tester,
  ) async {
    await _pump(tester, '- outer\n  - inner\n\n- loose\n\n  second paragraph');
    final plain = _plain(tester);
    expect(plain, contains('outer'));
    expect(plain, contains('inner'));
    expect(plain, contains('second paragraph'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a block quote, a rule and a fence do not throw', (tester) async {
    await _pump(
      tester,
      '> quoted\n\n---\n\n```\ncode here\n```\n\n| a | b |\n|---|---|\n| 1 | 2 |',
    );
    final plain = _plain(tester);
    expect(plain, contains('quoted'));
    expect(plain, contains('code here'));
    expect(plain, contains('1  ·  2'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty source renders nothing and does not throw', (
    tester,
  ) async {
    await _pump(tester, '');
    expect(find.byType(Text), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
