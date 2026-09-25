import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:noo/data/services/update_service.dart';
import 'package:noo/presentation/widgets/dialogs/update_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';

Map<String, dynamic> _release(String tag, {String notes = ''}) => {
  'tag_name': tag,
  'html_url': 'https://github.com/lab517io/noo/releases/tag/$tag',
  'body': notes,
  'assets': const [],
};

UpdateService _answering(http.Response response) => UpdateService(
  environment: const {},
  client: MockClient((_) async => response),
);

/// A GitHub that never answers, to hold the dialog in its checking state.
class _SilentClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      Completer<http.StreamedResponse>().future;
}

/// Open the dialog on a phone-sized portrait screen at [textScale] (Android's
/// font-size setting) and let it reach the state [service] leads to.
Future<void> _open(
  WidgetTester tester,
  UpdateService service, {
  required Size size,
  required double textScale,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: size,
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => UpdateDialog(
                    service: service,
                    onRestart: () async => false,
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  // Not pumpAndSettle: the checking state's spinner never settles.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(
    () => PackageInfo.setMockInitialValues(
      appName: 'Noo',
      packageName: 'io.lab517.noo',
      version: '1.2.7',
      buildNumber: '',
      buildSignature: '',
    ),
  );

  final states = <String, (UpdateService Function(), Finder)>{
    'checking': (
      () => UpdateService(environment: const {}, client: _SilentClient()),
      find.text('Checking for a new version...'),
    ),
    'up to date': (
      () => _answering(http.Response(jsonEncode(_release('v1.2.7')), 200)),
      find.textContaining('is the latest version'),
    ),
    'update available': (
      () => _answering(
        http.Response(
          jsonEncode(
            _release(
              'v1.3.0',
              notes: List.filled(
                40,
                'A fairly long release note line.',
              ).join('\n'),
            ),
          ),
          200,
        ),
      ),
      find.textContaining('is available'),
    ),
    'error': (() => _answering(http.Response('', 403)), find.text('Retry')),
  };

  for (final size in [const Size(360, 640), const Size(320, 568)]) {
    for (final textScale in [1.0, 1.6]) {
      for (final MapEntry(key: name, value: (service, shown))
          in states.entries) {
        testWidgets(
          '$name fits ${size.width.toInt()}dp portrait at ${textScale}x text',
          (tester) async {
            await _open(tester, service(), size: size, textScale: textScale);
            expect(shown, findsOneWidget);
            expect(tester.takeException(), isNull);
            // Run out the service's request timeout, which the silent client
            // leaves pending.
            await tester.pump(const Duration(seconds: 21));
          },
        );
      }
    }
  }
}
