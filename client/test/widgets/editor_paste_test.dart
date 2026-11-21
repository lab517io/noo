import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/internal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/widgets/task_editor/quill_editor_wrapper.dart';
import 'package:noo/presentation/widgets/task_editor/resilient_clipboard_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pasting plain text.
///
/// flutter_quill probes the clipboard for rich content — HTML, an HTML file, a
/// Markdown file, an image — before it falls back to inserting plain text, and
/// that chain has no error handling: an exception from any probe escapes
/// `clipboardPaste()` and the fallback never runs. The paste then does nothing
/// at all while the Paste menu entry stays enabled, and only plain text is
/// affected, because rich content is answered before the failing probe is
/// reached. `ResilientClipboardService` is what keeps that from happening.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// A clipboard that fails every question about rich content, the way an
  /// unimplemented platform bridge does (`UnimplementedError` from
  /// `isSupported`) and the way the Windows one does in a debug build, where
  /// each of its failure branches is an `assert(false, …)`.
  ClipboardService throwingClipboard() => _ThrowingClipboardService();

  group('ResilientClipboardService', () {
    test('turns a failing probe into "nothing rich on the clipboard"',
        () async {
      final service = ResilientClipboardService(throwingClipboard());

      expect(await service.getHtmlText(), isNull);
      expect(await service.getHtmlFile(), isNull);
      expect(await service.getMarkdownFile(), isNull);
      expect(await service.getImageFile(), isNull);
      expect(await service.getGifFile(), isNull);
      // A copy that cannot reach the clipboard is a failed copy, not a crash.
      await expectLater(
        service.copyImage(Uint8List.fromList([1, 2, 3])),
        completes,
      );
    });

    test('passes a working clipboard straight through', () async {
      final service = ResilientClipboardService(_FakeClipboardService('<b>x'));
      expect(await service.getHtmlText(), '<b>x');
    });
  });

  group('editor', () {
    late NooDatabase db;
    late int taskId;
    String? clipboardText;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      db = NooDatabase.memory();
      taskId = await db.createTask(worldId: 'task-world-id', title: 'Task');
      clipboardText = null;

      // What main() does before any editor is built.
      installResilientClipboardService();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        switch (call.method) {
          case 'Clipboard.getData':
            return clipboardText == null ? null : {'text': clipboardText};
          case 'Clipboard.hasStrings':
            return {'value': clipboardText != null};
          case 'Clipboard.setData':
            clipboardText = (call.arguments as Map)['text'] as String?;
            return null;
        }
        return null;
      });
    });

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
      ClipboardServiceProvider.setInstanceToDefault();
      await db.close();
    });

    final content = jsonEncode([
      {'insert': 'hello world\n'},
    ]);

    Future<void> pumpEditor(WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [FlutterQuillLocalizations.delegate],
            home: Scaffold(
              body: SizedBox(
                width: 600,
                height: 400,
                child: QuillEditorWrapper(
                  contentKey: taskId,
                  taskId: taskId,
                  initialContent: content,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    QuillController controllerOf(WidgetTester tester) =>
        tester.widget<QuillEditor>(find.byType(QuillEditor)).controller;

    testWidgets('plain text lands at the caret when no probe can answer',
        (tester) async {
      await pumpEditor(tester);
      final controller = controllerOf(tester);
      controller.updateSelection(
        const TextSelection.collapsed(offset: 5),
        ChangeSource.local,
      );

      clipboardText = ' there,';
      await controller.clipboardPaste();
      await tester.pumpAndSettle();

      expect(controller.document.toPlainText(), 'hello there, world\n\n');
    });

    testWidgets('a plain-text paste replaces the selection', (tester) async {
      await pumpEditor(tester);
      final controller = controllerOf(tester);
      controller.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 5),
        ChangeSource.local,
      );

      clipboardText = 'goodbye';
      await controller.clipboardPaste();
      await tester.pumpAndSettle();

      expect(controller.document.toPlainText(), 'goodbye world\n\n');
    });

    testWidgets('a copy made inside the editor still pastes with its styles',
        (tester) async {
      // The guard must not shorten quill's fallback chain: an internal copy
      // puts only plain text on the system clipboard and keeps the delta in
      // memory, so its formatting is restored by the same plain-text branch
      // the fix makes reachable.
      await pumpEditor(tester);
      final controller = controllerOf(tester);

      controller.updateSelection(
        const TextSelection(baseOffset: 0, extentOffset: 5),
        ChangeSource.local,
      );
      controller.formatSelection(Attribute.bold);
      controller.clipboardSelection(true);
      expect(clipboardText, 'hello');

      controller.updateSelection(
        const TextSelection.collapsed(offset: 11),
        ChangeSource.local,
      );
      await controller.clipboardPaste();
      await tester.pumpAndSettle();

      expect(controller.document.toPlainText(), 'hello worldhello\n\n');
      final pasted = controller.document
          .toDelta()
          .toList()
          .where((op) => op.data == 'hello')
          .toList();
      expect(pasted, hasLength(2));
      expect(pasted.last.attributes?['bold'], isTrue);
    });

    testWidgets('the document is untouched while the paste is answered',
        (tester) async {
      // flutter_quill reveals the caret the instant the paste answers:
      // `pasteText` calls `bringIntoView` as soon as `clipboardPaste()` returns
      // true, in the same turn, before the editor has rebuilt. The lookup
      // behind it resolves the caret's node through the document — updated —
      // and then hunts for it among the render children — not updated — so a
      // paste that adds lines sends it off the end of the list and into
      // `childAtOffset(Offset(0, 0))`, the first line of the document. The
      // editor jumps to the top and scrolls back after the next layout, which
      // is the flicker this deferral exists to stop.
      //
      // The invariant that prevents it: nothing has changed yet when
      // `clipboardPaste()` answers.
      await pumpEditor(tester);
      final controller = controllerOf(tester);
      controller.updateSelection(
        const TextSelection.collapsed(offset: 5),
        ChangeSource.local,
      );

      clipboardText = '\nfirst\nsecond\n';
      expect(await controller.clipboardPaste(), isTrue);
      expect(
        controller.document.toPlainText(),
        'hello world\n\n',
        reason: 'the paste must not land until the caret reveal is behind us',
      );

      await tester.pumpAndSettle();
      expect(
        controller.document.toPlainText(),
        'hello\nfirst\nsecond\n world\n\n',
      );
    });
  });
}

class _ThrowingClipboardService extends ClipboardService {
  @override
  Future<void> copyImage(Uint8List imageBytes) async =>
      throw UnimplementedError();

  @override
  Future<Uint8List?> getGifFile() async => throw UnimplementedError();

  @override
  Future<String?> getHtmlFile() async => throw UnimplementedError();

  @override
  Future<String?> getHtmlText() async => throw UnimplementedError();

  @override
  Future<Uint8List?> getImageFile() async => throw UnimplementedError();

  @override
  Future<String?> getMarkdownFile() async => throw UnimplementedError();
}

class _FakeClipboardService extends ClipboardService {
  final String? html;

  _FakeClipboardService(this.html);

  @override
  Future<void> copyImage(Uint8List imageBytes) async {}

  @override
  Future<Uint8List?> getGifFile() async => null;

  @override
  Future<String?> getHtmlFile() async => null;

  @override
  Future<String?> getHtmlText() async => html;

  @override
  Future<Uint8List?> getImageFile() async => null;

  @override
  Future<String?> getMarkdownFile() async => null;
}
