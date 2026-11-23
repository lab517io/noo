import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:noo/l10n/l10n.dart';

/// Every translation must carry every message of `app_en.arb`, with the same
/// placeholders: gen-l10n falls back to English for a missing key silently,
/// and a translation that drops or renames a `{placeholder}` loses the value
/// it was meant to show.
void main() {
  final dir = Directory('lib/l10n');
  Map<String, dynamic> read(File f) =>
      jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;

  final template = read(File('lib/l10n/app_en.arb'));
  final keys = template.keys.where((k) => !k.startsWith('@')).toSet();

  // Placeholder names used in a message, ignoring plural/select branches'
  // literal text: `{count}` and `{count, plural, ...}` both name `count`.
  Set<String> placeholders(String message) => RegExp(r'\{(\w+)[,}]')
      .allMatches(message)
      .map((m) => m.group(1)!)
      .where((name) => !const {'zero', 'one', 'two', 'few', 'many', 'other'}
          .contains(name))
      .toSet();

  final translations = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb') && !f.path.endsWith('app_en.arb'))
      .toList();

  test('every interface language has a translation file', () {
    final locales = translations
        .map((f) => f.uri.pathSegments.last
            .replaceFirst('app_', '')
            .replaceFirst('.arb', ''))
        .toSet();
    for (final code in kAppLanguages.keys.where((c) => c != 'en')) {
      expect(locales, contains(code));
    }
  });

  for (final file in translations) {
    final name = file.uri.pathSegments.last;
    test('$name has every message, with the same placeholders', () {
      final arb = read(file);
      final missing = keys.where((k) => !arb.containsKey(k)).toList();
      expect(missing, isEmpty, reason: 'missing in $name');
      final extra = arb.keys
          .where((k) => !k.startsWith('@') && !keys.contains(k))
          .toList();
      expect(extra, isEmpty, reason: 'unknown keys in $name');
      for (final key in keys) {
        final expected = placeholders(template[key] as String);
        final actual = placeholders(arb[key] as String);
        expect(actual, expected, reason: '$name: $key');
      }
    });
  }

  test('every supported locale loads', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      expect(l10n.commonCancel, isNotEmpty);
    }
  });
}
