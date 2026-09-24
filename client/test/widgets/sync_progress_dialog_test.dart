import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/data/services/sync_service.dart';
import 'package:noo/presentation/providers/sync_provider.dart';
import 'package:noo/presentation/widgets/dialogs/sync_progress_dialog.dart';

/// Renders the dialog inside a real modal route, after [seed] has put the
/// progress provider into the state under test.
Future<void> _showDialog(
  WidgetTester tester, {
  void Function(SyncProgressController controller)? seed,
  Size? size,
  // An active stage shows a spinner, which never settles.
  bool settle = true,
}) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  seed?.call(container.read(syncProgressProvider.notifier));

  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showSyncProgressDialog(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

void main() {
  testWidgets('idle state offers Sync Now beside Close', (tester) async {
    await _showDialog(tester);

    expect(find.text('Sync'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Sync Now'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Close'), findsOneWidget);
  });

  testWidgets('successful sync lists summary and changes', (tester) async {
    await _showDialog(tester, seed: (controller) {
      controller.start();
      controller.update(const SyncProgress(
        SyncStage.applying,
        SyncStageState.done,
        detail: '2 changes applied',
      ));
      controller.finish(const SyncResult(
        success: true,
        changesPushed: 1,
        changesApplied: 2,
        applied: [
          SyncEntityChange(
            entityType: 'task',
            kind: SyncEntityChangeKind.created,
            label: 'Node "Groceries"',
          ),
          SyncEntityChange(
            entityType: 'task',
            kind: SyncEntityChangeKind.updated,
            label: 'Node "Project X"',
            detail: 'title → "Project X"',
          ),
        ],
        pushed: [
          SyncEntityChange(
            entityType: 'file',
            kind: SyncEntityChangeKind.created,
            label: 'File "notes.md"',
          ),
        ],
      ));
    });

    expect(find.text('Sync complete'), findsOneWidget);
    expect(find.text('Summary'), findsOneWidget);
    expect(find.text('Changes pushed:'), findsOneWidget);
    expect(find.text('Applied — from other devices'), findsOneWidget);
    expect(find.text('Pushed — from this device'), findsOneWidget);
    expect(find.text('2 changes applied'), findsOneWidget);
    // A finished run only offers dismissal.
    expect(find.widgetWithText(FilledButton, 'Close'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Close'), findsNothing);
  });

  testWidgets('failed sync shows the error and a Retry button', (tester) async {
    await _showDialog(tester, seed: (controller) {
      controller.start();
      controller.finish(const SyncResult(
        success: false,
        error: 'Sync is not configured. Open Sync Settings first.',
      ));
    });

    expect(find.text('Sync failed'), findsOneWidget);
    expect(find.text('Error'), findsOneWidget);
    expect(
      find.text('Sync is not configured. Open Sync Settings first.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Close'), findsOneWidget);
  });

  testWidgets('a running sync offers Cancel and Hide', (tester) async {
    await _showDialog(tester, seed: (controller) => controller.start());

    expect(find.text('Synchronizing…'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Cancel'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Hide'), findsOneWidget);
    expect(find.text('Close'), findsNothing);
  });

  testWidgets('Cancel is disabled while the run winds down', (tester) async {
    await _showDialog(tester, seed: (controller) {
      controller.start();
      controller.markCancelling();
    });

    expect(find.text('Cancelling…'), findsNWidgets(2)); // title + button
    final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Cancelling…'));
    expect(button.onPressed, isNull);
    expect(find.widgetWithText(FilledButton, 'Hide'), findsOneWidget);
  });

  testWidgets('a cancelled sync is not reported as a failure', (tester) async {
    await _showDialog(tester, seed: (controller) {
      controller.start();
      controller.update(const SyncProgress(
          SyncStage.pushing, SyncStageState.skipped,
          detail: 'Cancelled'));
      controller.finish(const SyncResult(
          success: false, cancelled: true, error: 'Sync cancelled'));
    });

    expect(find.text('Sync cancelled'), findsOneWidget);
    expect(find.text('Sync failed'), findsNothing);
    expect(find.text('Error'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Sync Now'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Close'), findsOneWidget);
  });

  testWidgets('the active stage draws a bar when it knows its progress',
      (tester) async {
    await _showDialog(tester, settle: false, seed: (controller) {
      controller.start();
      controller.update(const SyncProgress(
          SyncStage.applying, SyncStageState.active,
          detail: '4,200 of 10,000 changes', fraction: 0.42));
    });

    expect(find.text('4,200 of 10,000 changes'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator));
    expect(bar.value, 0.42);
  });

  testWidgets('a long change list is capped', (tester) async {
    await _showDialog(tester, seed: (controller) {
      controller.start();
      controller.finish(SyncResult(
        success: true,
        changesApplied: 1000,
        applied: [
          for (var i = 0; i < 1000; i++)
            SyncEntityChange(
              entityType: 'task',
              kind: SyncEntityChangeKind.created,
              label: 'Node "Task $i"',
            ),
        ],
      ));
    });

    expect(find.text('…and 800 more — see Show Full Log'), findsOneWidget);
  });

  // ---------- Phone widths ----------
  //
  // Below 600dp the dialog is already full-screen, but the stage rows carry
  // the widest label column in the app (168dp for "Validating credentials").
  // On a 360dp phone that leaves the stage detail about a word per line, and
  // at 320dp the glyph alone no longer fits — so the rows have to stack.
  for (final width in [320.0, 360.0]) {
    testWidgets('a finished sync fits a ${width}dp screen', (tester) async {
      await _showDialog(
        tester,
        size: Size(width, 800),
        seed: (controller) {
          controller.start();
          controller.update(const SyncProgress(
            SyncStage.authenticating,
            SyncStageState.done,
            // The longest detail the dialog produces, against its longest
            // stage label.
            detail: 'Signed in as alice',
          ));
          controller.finish(const SyncResult(
            success: true,
            changesPushed: 3,
            changesApplied: 12,
            applied: [
              SyncEntityChange(
                entityType: 'task',
                kind: SyncEntityChangeKind.updated,
                label: 'Node "Quarterly planning / Budget review"',
                detail: 'title \u2192 "Budget review"',
              ),
            ],
          ));
        },
      );

      expect(find.text('Sync complete'), findsOneWidget);
      expect(find.text('Validating credentials:'), findsOneWidget);
      expect(find.text('Changes applied:'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed sync fits a ${width}dp screen', (tester) async {
      await _showDialog(
        tester,
        size: Size(width, 800),
        seed: (controller) {
          controller.start();
          controller.finish(const SyncResult(
            success: false,
            error: 'Could not reach https://sync.example.com: '
                'connection timed out after 30s',
          ));
        },
      );

      expect(find.text('Sync failed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
