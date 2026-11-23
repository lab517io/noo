import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/utils/app_log.dart';
import 'package:noo/presentation/widgets/dialogs/app_log_dialog.dart';

void main() {
  Future<void> open(WidgetTester tester, AppLog log) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showAppLogDialog(context, log: log),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the lines, filters by level and follows new lines',
      (tester) async {
    final log = AppLog()
      ..info('opened the database')
      ..warning('sync did not complete')
      ..error('something broke');
    await open(tester, log);

    expect(find.text('opened the database'), findsOneWidget);
    expect(find.text('sync did not complete'), findsOneWidget);
    expect(find.text('something broke'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Errors').last);
    await tester.pumpAndSettle();
    expect(find.text('opened the database'), findsNothing);
    expect(find.text('sync did not complete'), findsNothing);
    expect(find.text('something broke'), findsOneWidget);

    log.error('another failure');
    await tester.pumpAndSettle();
    expect(find.text('another failure'), findsOneWidget);
  });

  testWidgets('search narrows the list; Clear Log empties it', (tester) async {
    final log = AppLog()
      ..info('alpha')
      ..info('beta');
    await open(tester, log);

    await tester.enterText(find.byType(TextField), 'bet');
    await tester.pumpAndSettle();
    expect(find.text('alpha'), findsNothing);
    expect(find.text('beta'), findsOneWidget);

    await tester.tap(find.text('Clear Log'));
    await tester.pumpAndSettle();
    expect(log.entries, isEmpty);
    expect(find.text('Nothing has been logged yet.'), findsOneWidget);
  });
}
