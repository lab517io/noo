import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

  final content = jsonEncode([
    {'insert': 'hello\n'},
  ]);

  Future<QuillController> pumpEditor(
    WidgetTester tester, {
    double width = 600,
  }) async {
    final key = GlobalKey<QuillEditorWrapperState>();

    await tester.pumpWidget(
      ProviderScope(
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
}
