import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/constants/editor_toolbar.dart';
import 'package:noo/presentation/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which editor toolbar buttons are shown is a preference: the hidden ones
/// are stored by name, survive a restart, and roll back with Cancel.
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

  Future<ProviderContainer> settingsFrom(Map<String, Object> prefs) async {
    SharedPreferences.setMockInitialValues(prefs);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(settingsProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return container;
  }

  test('every button is shown until it is unticked', () async {
    final container = await settingsFrom({});
    expect(container.read(settingsProvider).editorToolbarHidden, isEmpty);
  });

  test('fromNames ignores a name this build does not know', () {
    expect(
      EditorToolbarButton.fromNames(['bold', 'hologram', 'quote']),
      {EditorToolbarButton.bold, EditorToolbarButton.quote},
    );
    expect(EditorToolbarButton.fromNames(null), isEmpty);
  });

  test('unticking a button is stored by name and read back', () async {
    final container = await settingsFrom({});
    final notifier = container.read(settingsProvider.notifier);

    await notifier.setEditorToolbarButtonShown(
        EditorToolbarButton.voiceMemo, false);
    await notifier.setEditorToolbarButtonShown(
        EditorToolbarButton.headings, false);
    expect(container.read(settingsProvider).editorToolbarHidden,
        {EditorToolbarButton.voiceMemo, EditorToolbarButton.headings});

    final prefs = await SharedPreferences.getInstance();
    final reopened = await settingsFrom({
      'flutter.editor_toolbar_hidden':
          prefs.getStringList('editor_toolbar_hidden') ?? <String>[],
    });
    expect(reopened.read(settingsProvider).editorToolbarHidden,
        {EditorToolbarButton.voiceMemo, EditorToolbarButton.headings});

    await notifier.setEditorToolbarButtonShown(
        EditorToolbarButton.voiceMemo, true);
    expect(container.read(settingsProvider).editorToolbarHidden,
        {EditorToolbarButton.headings});
  });

  test('restorePreferences puts the hidden set back, on disk too', () async {
    final container = await settingsFrom({});
    final notifier = container.read(settingsProvider.notifier);
    final snapshot = container.read(settingsProvider);

    await notifier.setEditorToolbarButtonShown(EditorToolbarButton.link, false);
    await notifier.restorePreferences(snapshot);

    expect(container.read(settingsProvider).editorToolbarHidden, isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('editor_toolbar_hidden'), isEmpty);
  });
}
