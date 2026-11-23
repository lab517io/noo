import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/duration_formatter.dart';
import 'package:noo/l10n/l10n.dart';

void main() {
  String fmt(String lang, Duration d) =>
      formatDurationShort(lookupAppLocalizations(Locale(lang)), d);

  const cases = [
    Duration(hours: 2, minutes: 30),
    Duration(hours: 3),
    Duration(minutes: 42),
    Duration(seconds: 17),
    Duration.zero,
  ];

  test('English matches formatHuman, which the time report keeps', () {
    for (final d in cases) {
      expect(fmt('en', d), DurationFormatter.formatHuman(d));
    }
  });

  test('other languages use their own units', () {
    const d = Duration(hours: 2, minutes: 30);
    expect(fmt('de', d), '2 h 30 min');
    expect(fmt('ru', d), '2 ч 30 мин');
    expect(fmt('tr', d), '2 sa 30 dk');
    expect(fmt('zh', d), '2小时30分钟');
    expect(fmt('ja', d), '2時間30分');
    expect(fmt('ru', const Duration(seconds: 17)), '17 с');
  });
}
