import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/constants/fonts.dart';
import 'package:noo/presentation/widgets/task_editor/editor_font_buttons.dart';

void main() {
  QuillController controllerFor() => QuillController(
        document: Document.fromJson([
          {'insert': 'plain '},
          {
            'insert': 'mono',
            'attributes': {'font': 'JetBrains Mono'}
          },
          {'insert': ' '},
          {
            'insert': 'pasted',
            'attributes': {'font': 'Arial'}
          },
          {'insert': '\n'},
        ]),
        selection: const TextSelection.collapsed(offset: 2),
      );

  Future<void> pump(WidgetTester tester, QuillController controller,
      {String? contentFamily, bool monospaceOnly = false}) {
    return tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [FlutterQuillLocalizations.delegate],
      home: Scaffold(
        body: EditorFontFamilyButton(
          controller: controller,
          items: editorFontFamilies(monospaceOnly: monospaceOnly),
          contentFamily: contentFamily,
        ),
      ),
    ));
  }

  void moveTo(QuillController c, int offset) => c.updateSelection(
      TextSelection.collapsed(offset: offset), ChangeSource.local);

  testWidgets('text without a font attribute names the content font',
      (tester) async {
    final c = controllerFor();
    await pump(tester, c, contentFamily: 'Noto Serif');
    expect(find.text('Noto Serif'), findsOneWidget);

    await pump(tester, c);
    expect(find.text('System default'), findsOneWidget);
  });

  testWidgets('follows the caret through attributed text', (tester) async {
    final c = controllerFor();
    await pump(tester, c, contentFamily: 'Roboto');
    expect(find.text('Roboto'), findsOneWidget);

    moveTo(c, 8);
    await tester.pump();
    expect(find.text('JetBrains Mono'), findsOneWidget);

    // A family the menu does not offer is still named.
    moveTo(c, 14);
    await tester.pump();
    expect(find.text('Arial'), findsOneWidget);

    moveTo(c, 1);
    await tester.pump();
    expect(find.text('Roboto'), findsOneWidget);
  });

  testWidgets('a family hidden by monospace-only is still named',
      (tester) async {
    final c = QuillController(
      document: Document.fromJson([
        {
          'insert': 'serif',
          'attributes': {'font': 'Noto Serif'}
        },
        {'insert': '\n'},
      ]),
      selection: const TextSelection.collapsed(offset: 2),
    );
    await pump(tester, c, monospaceOnly: true);
    expect(find.text('Noto Serif'), findsOneWidget);
  });

  testWidgets('picking from the menu formats the selection', (tester) async {
    // The menu lists every family and Clear underneath; taller than the
    // default test viewport, which would put Clear out of reach of a tap.
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final c = controllerFor();
    c.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 5), ChangeSource.local);
    await pump(tester, c);
    await tester.tap(find.byType(EditorFontFamilyButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Inconsolata').last);
    await tester.pumpAndSettle();
    expect(c.getSelectionStyle().attributes['font']?.value, 'Inconsolata');
    expect(find.text('Inconsolata'), findsOneWidget);

    await tester.tap(find.byType(EditorFontFamilyButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear').last);
    await tester.pumpAndSettle();
    expect(c.getSelectionStyle().attributes['font'], isNull);
    expect(find.text('System default'), findsOneWidget);
  });

  group('Size', () {
    final styles = DefaultStyles(
      paragraph: DefaultTextBlockStyle(
        const TextStyle(fontSize: 15),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
      h1: DefaultTextBlockStyle(
        const TextStyle(fontSize: 34),
        const HorizontalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        const VerticalSpacing(0, 0),
        null,
      ),
      sizeLarge: const TextStyle(fontSize: 18),
    );

    QuillController sizedController() => QuillController(
          document: Document.fromJson([
            {'insert': 'plain '},
            {
              'insert': 'big',
              'attributes': {'size': 24.0}
            },
            {'insert': ' '},
            {
              'insert': 'odd',
              'attributes': {'size': '13.5'}
            },
            {'insert': ' '},
            {
              'insert': 'named',
              'attributes': {'size': 'large'}
            },
            {'insert': '\nTitle'},
            {
              'insert': '\n',
              'attributes': {'header': 1}
            },
          ]),
          selection: const TextSelection.collapsed(offset: 2),
        );

    Future<void> pumpSize(WidgetTester tester, QuillController c) =>
        tester.pumpWidget(MaterialApp(
          home: Scaffold(
            body: EditorFontSizeButton(
              controller: c,
              items: kEditorFontSizes,
              styles: styles,
            ),
          ),
        ));

    String labelOf(WidgetTester tester) => tester
        .widget<Text>(find.descendant(
            of: find.byType(EditorFontSizeButton), matching: find.byType(Text)))
        .data!;

    testWidgets('names the size the text is drawn in', (tester) async {
      final c = sizedController();
      await pumpSize(tester, c);
      expect(labelOf(tester), '15', reason: 'the paragraph size');

      for (final (offset, expected) in [
        (8, '24'),
        (12, '13.5'),
        (18, '18'),
        (24, '34'),
        (1, '15'),
      ]) {
        moveTo(c, offset);
        await tester.pump();
        expect(labelOf(tester), expected, reason: 'at offset $offset');
      }
    });

    testWidgets('picking a size formats the selection', (tester) async {
      final c = sizedController();
      c.updateSelection(const TextSelection(baseOffset: 0, extentOffset: 5),
          ChangeSource.local);
      await pumpSize(tester, c);
      await tester.tap(find.byType(EditorFontSizeButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20').last);
      await tester.pumpAndSettle();
      expect(c.getSelectionStyle().attributes['size']?.value, 20);
      expect(labelOf(tester), '20');

      await tester.tap(find.byType(EditorFontSizeButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Clear').last);
      await tester.pumpAndSettle();
      expect(c.getSelectionStyle().attributes['size'], isNull);
      expect(labelOf(tester), '15');
    });
  });
}
