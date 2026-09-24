import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/constants/fonts.dart';
import 'package:noo/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The tree has its own font, separate from the editor's.
///
/// One setting used to dress both, so the split has to be invisible to anyone
/// upgrading: until the tree font is touched, it follows whatever the editor
/// font was. After that the two go their own ways.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
      return switch (call.method) {
        'readAll' => <String, String>{},
        'containsKey' => false,
        _ => null,
      };
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  /// A container whose settings have finished loading from [prefs].
  Future<ProviderContainer> settingsFrom(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(settingsProvider);
    // Three awaits stand between build() and the state being published.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return container;
  }

  test('an install that predates the split reads the editor font', () async {
    final container = await settingsFrom({
      'flutter.font_family': 'JetBrains Mono',
      'flutter.font_size': 18.0,
      'flutter.font_bold': true,
    });
    final settings = container.read(settingsProvider);

    expect(settings.treeFontFamily, 'JetBrains Mono');
    expect(settings.treeFontSize, 18.0);
    expect(settings.treeFontBold, isTrue,
        reason: 'nothing on screen moves the first time the app runs with '
            'the two settings separate');
  });

  test('a tree font of its own wins over the editor font', () async {
    final container = await settingsFrom({
      'flutter.font_family': 'JetBrains Mono',
      'flutter.font_size': 18.0,
      'flutter.tree_font_family': 'Noto Sans',
      'flutter.tree_font_size': 13.0,
    });
    final settings = container.read(settingsProvider);

    expect(settings.treeFontFamily, 'Noto Sans');
    expect(settings.treeFontSize, 13.0);
    expect(settings.fontFamily, 'JetBrains Mono',
        reason: 'the editor keeps its own');
  });

  test('setting one font leaves the other alone', () async {
    final container = await settingsFrom({
      'flutter.font_family': 'JetBrains Mono',
    });
    final notifier = container.read(settingsProvider.notifier);

    await notifier.setTreeFontFamily('Noto Sans');
    expect(container.read(settingsProvider).fontFamily, 'JetBrains Mono');
    expect(container.read(settingsProvider).treeFontFamily, 'Noto Sans');

    await notifier.setFontFamily('Noto Serif');
    expect(container.read(settingsProvider).treeFontFamily, 'Noto Sans');
  });

  test('choosing the system font for the tree outlives a restart', () async {
    final container = await settingsFrom({
      'flutter.font_family': 'JetBrains Mono',
    });

    await container.read(settingsProvider.notifier).setTreeFontFamily(null);
    expect(container.read(settingsProvider).treeFontFamily, isNull);

    // What a restart reads back: the choice is stored, not merely absent, so
    // it does not fall back to the editor's font again.
    final prefs = await SharedPreferences.getInstance();
    final reopened = await settingsFrom({
      'flutter.font_family': 'JetBrains Mono',
      'flutter.tree_font_family':
          prefs.getString('tree_font_family') ?? '(missing)',
    });
    expect(reopened.read(settingsProvider).treeFontFamily, isNull);
  });

  group('treeFontSettingsToStyle', () {
    test('dresses text in the tree font, not the editor one', () {
      const settings = AppSettings(
        fontFamily: 'JetBrains Mono',
        fontSize: 18,
        fontBold: true,
        treeFontFamily: 'Noto Sans',
        treeFontSize: 13,
        treeFontItalic: true,
      );

      final tree = treeFontSettingsToStyle(settings);
      expect(tree.fontFamily, 'Noto Sans');
      expect(tree.fontSize, 13);
      expect(tree.fontStyle, FontStyle.italic);
      expect(tree.fontWeight, isNot(FontWeight.bold),
          reason: "the editor's bold is not the tree's");

      final editor = fontSettingsToStyle(settings);
      expect(editor.fontFamily, 'JetBrains Mono');
      expect(editor.fontWeight, FontWeight.bold);
    });

    test('leaves the base style alone at the defaults', () {
      const settings = AppSettings();
      const base = TextStyle(fontFamily: 'Base', fontSize: 11);

      final style = treeFontSettingsToStyle(settings, base: base);
      expect(style.fontFamily, 'Base');
      expect(style.fontSize, 11);
    });
  });
}
