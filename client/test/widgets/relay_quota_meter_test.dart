import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/services/sync_api_client.dart';
import 'package:noo/presentation/widgets/dialogs/relay_quota_meter.dart';

const _mib = 1024 * 1024;

RelayUsage _usage(int used) => RelayUsage(
      packets: 1,
      bytes: used,
      devices: const [],
      quotaBytes: 20 * _mib,
    );

Future<void> _pump(WidgetTester tester, int used) => tester.pumpWidget(
      MaterialApp(home: Scaffold(body: RelayQuotaMeter(usage: _usage(used)))),
    );

LinearProgressIndicator _bar(WidgetTester tester) =>
    tester.widget(find.byType(LinearProgressIndicator));

void main() {
  testWidgets('shows what is used of the quota', (tester) async {
    await _pump(tester, 5 * _mib);
    expect(find.text('5.0 MB of 20.0 MB used (25%)'), findsOneWidget);
    expect(_bar(tester).value, 0.25);
    expect(find.textContaining('Nearly full'), findsNothing);
  });

  testWidgets('warns when nearly full', (tester) async {
    await _pump(tester, 17 * _mib);
    expect(find.textContaining('Nearly full'), findsOneWidget);
    expect(_bar(tester).color, Colors.orange);
  });

  testWidgets('says what a full account means', (tester) async {
    await _pump(tester, 21 * _mib);
    expect(find.text('21.0 MB of 20.0 MB used (105%)'), findsOneWidget);
    expect(_bar(tester).value, 1.0);
    expect(find.textContaining('refuses new changes'), findsOneWidget);
  });
}
