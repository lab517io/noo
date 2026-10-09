import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/presentation/providers/settings_provider.dart';
import 'package:noo/presentation/widgets/task_editor/paste_formatting.dart';
import 'package:noo/presentation/widgets/task_editor/quill_editor_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pasting rich text into task content.
///
/// Text copied out of a browser arrives with the source page's colours, fonts
/// and sizes attached; `Preferences → Behavior → Editor → Paste` decides how
/// much of that survives, and Ctrl+Shift+V drops all of it regardless.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('stripAppearanceAttributes', () {
    test('drops colour, background, font and size', () {
      final delta = Delta()
        ..insert('coloured', {
          'color': '#ff0000',
          'background': '#00ff00',
          'font': 'Comic Sans MS',
          'size': '32',
        })
        ..insert('\n');

      final stripped = stripAppearanceAttributes(delta);

      // The trailing newline merges into the run once both are unstyled.
      expect(stripped.toList().single.attributes, isNull);
      expect(stripped.toList().single.data, 'coloured\n');
    });

    test('keeps emphasis, links and block structure', () {
      final delta = Delta()
        ..insert('bold link', {
          'bold': true,
          'italic': true,
          'link': 'https://example.com',
          'color': '#123456',
        })
        ..insert('\n', {'list': 'bullet', 'header': 2});

      final stripped = stripAppearanceAttributes(delta);
      final ops = stripped.toList();

      expect(ops.first.attributes, {
        'bold': true,
        'italic': true,
        'link': 'https://example.com',
      });
      expect(ops.last.attributes, {'list': 'bullet', 'header': 2});
    });

    test('leaves a delta with nothing to strip untouched', () {
      final delta = Delta()..insert('plain\n');
      expect(identical(stripAppearanceAttributes(delta), delta), isTrue);
    });

    test('keeps embeds and their display width', () {
      final delta = Delta()
        ..insert({'image': 'noo-attachment://abc'}, {'style': 'width: 240px'})
        ..insert('after', {'color': '#ff0000'})
        ..insert('\n');

      final ops = stripAppearanceAttributes(delta).toList();

      expect(ops.first.data, {'image': 'noo-attachment://abc'});
      expect(ops.first.attributes, {'style': 'width: 240px'});
      expect(ops[1].attributes, isNull);
    });
  });

  test('deltaToPlainText keeps the text and drops the embeds', () {
    final delta = Delta()
      ..insert('before', {'bold': true})
      ..insert({'image': 'noo-attachment://abc'})
      ..insert('after\n');

    expect(deltaToPlainText(delta), 'beforeafter\n');
  });

  group('in the editor', () {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    // Settings load through the keychain (sync password, MCP token). Left
    // unmocked the channel throws, the load never finishes, and every
    // preference silently reads as its default — including this one.
    const secureStorageChannel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

    setUp(() {
      messenger.setMockMethodCallHandler(secureStorageChannel, (call) async {
        return switch (call.method) {
          'readAll' => <String, String>{},
          'containsKey' => false,
          _ => null,
        };
      });
    });

    void mockClipboardText(String? text) {
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.getData') {
          return text == null ? null : <String, dynamic>{'text': text};
        }
        return null;
      });
    }

    tearDown(() {
      messenger.setMockMethodCallHandler(SystemChannels.platform, null);
      messenger.setMockMethodCallHandler(secureStorageChannel, null);
    });

    /// Pumps an editor with [mode] configured and returns the content saved
    /// after a paste driven by [pressKeys].
    Future<String?> pumpAndPaste(
      WidgetTester tester, {
      required PasteFormatting mode,
      required Future<void> Function(WidgetTester tester) pressKeys,
    }) async {
      SharedPreferences.setMockInitialValues(
        {SettingsKeys.editorPasteFormatting: mode.name},
      );

      String? saved;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: const [FlutterQuillLocalizations.delegate],
            home: Scaffold(
              body: SizedBox(
                width: 600,
                height: 400,
                child: QuillEditorWrapper(
                  contentKey: 1,
                  onContentChanged: (content) => saved = content,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(QuillEditor));
      await tester.pumpAndSettle();

      // Reading the clipboard is real async work the fake clock never
      // advances, hence runAsync — as in the image paste tests.
      await tester.runAsync(() async {
        await pressKeys(tester);
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      return saved;
    }

    Future<void> pressCtrlV(WidgetTester tester) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    }

    Future<void> pressCtrlShiftV(WidgetTester tester) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyV);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    }

    testWidgets('plain-text mode pastes the clipboard text itself',
        (tester) async {
      mockClipboardText('copied text');

      final saved = await pumpAndPaste(
        tester,
        mode: PasteFormatting.plainText,
        pressKeys: pressCtrlV,
      );

      // Claiming the paste is the point: left to Quill it would go looking for
      // HTML on the clipboard, which is where the formatting comes from.
      expect(saved, isNotNull);
      expect(saved, contains('copied text'));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Ctrl+Shift+V pastes plain text whatever the preference says',
        (tester) async {
      mockClipboardText('copied text');

      final saved = await pumpAndPaste(
        tester,
        mode: PasteFormatting.keep,
        pressKeys: pressCtrlShiftV,
      );

      expect(saved, contains('copied text'));
      expect(tester.takeException(), isNull);
    });
  });
}
