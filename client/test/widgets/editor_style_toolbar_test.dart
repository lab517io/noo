import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/constants/fonts.dart';
import 'package:noo/presentation/providers/settings_provider.dart';
import 'package:noo/presentation/widgets/task_editor/quill_editor_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The toolbar's appearance controls: font family, font size, text and
/// highlight colour, and clear-formatting.
///
/// Content pasted from a browser arrives carrying all of these, so the editor
/// has to be able to set and unset them too. Neither dropdown may be given a
/// `width`: that switches its label to an `Expanded` inside a `Row`, and the
/// single-row toolbar lays out unbounded — which asserts rather than clipping.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// What the toolbar's Font menu offers, as the button was configured.
  Map<String, String> fontMenuOf(WidgetTester tester) => tester
      .widget<QuillToolbarFontFamilyButton>(
          find.byType(QuillToolbarFontFamilyButton))
      .options
      .items!;

  final content = jsonEncode([
    {'insert': 'hello\n'},
  ]);

  Future<QuillController> pumpEditor(
    WidgetTester tester, {
    double width = 600,
    ProviderContainer? container,
  }) async {
    final key = GlobalKey<QuillEditorWrapperState>();

    Widget scope({required Widget child}) => container == null
        ? ProviderScope(child: child)
        : UncontrolledProviderScope(container: container, child: child);

    await tester.pumpWidget(
      scope(
        child: MaterialApp(
          localizationsDelegates: const [FlutterQuillLocalizations.delegate],
          home: Scaffold(
            body: SizedBox(
              width: width,
              height: 400,
              child: QuillEditorWrapper(
                key: key,
                contentKey: 1,
                initialContent: content,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    return tester
        .widget<QuillEditor>(find.byType(QuillEditor))
        .controller;
  }

  testWidgets('the toolbar offers font, size, colour and clear format',
      (tester) async {
    await pumpEditor(tester);

    expect(find.byType(QuillToolbarFontFamilyButton), findsOneWidget);
    expect(find.byType(QuillToolbarFontSizeButton), findsOneWidget);
    expect(find.byType(QuillToolbarColorButton), findsNWidgets(2));
    expect(find.byType(QuillToolbarClearFormatButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the toolbar lays out in a narrow editor panel', (tester) async {
    await pumpEditor(tester, width: 320);
    expect(tester.takeException(), isNull);
  });

  testWidgets('picking a font family formats the selection', (tester) async {
    final controller = await pumpEditor(tester);
    controller.updateSelection(
      const TextSelection(baseOffset: 0, extentOffset: 5),
      ChangeSource.local,
    );
    await tester.pump();

    await tester.tap(find.byType(QuillToolbarFontFamilyButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Noto Serif').last);
    await tester.pumpAndSettle();

    expect(
      controller.getSelectionStyle().attributes['font']?.value,
      'Noto Serif',
    );
  });

  testWidgets('picking a size, then Clear, removes it again', (tester) async {
    final controller = await pumpEditor(tester);
    controller.updateSelection(
      const TextSelection(baseOffset: 0, extentOffset: 5),
      ChangeSource.local,
    );
    await tester.pump();

    await tester.tap(find.byType(QuillToolbarFontSizeButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('24').last);
    await tester.pumpAndSettle();
    expect(controller.getSelectionStyle().attributes['size']?.value, 24);

    await tester.tap(find.byType(QuillToolbarFontSizeButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear').last);
    await tester.pumpAndSettle();
    expect(
      controller.getSelectionStyle().attributes.containsKey('size'),
      isFalse,
    );
  });

  testWidgets('the Font menu offers every family by default', (tester) async {
    await pumpEditor(tester);

    final menu = fontMenuOf(tester);
    expect(menu.values, containsAll(['sans-serif', 'serif', 'monospace']));
    expect(menu.values, contains('Roboto'));
  });

  testWidgets('Monospace fonts only narrows the Font menu', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await pumpEditor(tester, container: container);

    await container.read(settingsProvider.notifier).setMonospaceFontsOnly(true);
    await tester.pumpAndSettle();

    expect(fontMenuOf(tester).values, [...kMonospaceFonts, 'Clear'],
        reason: 'the bundled families, and Clear — which is not a family');
  });
}
