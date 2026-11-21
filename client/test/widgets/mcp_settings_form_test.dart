import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/theme/app_theme.dart';
import 'package:noo/data/database/database.dart';
import 'package:noo/presentation/providers/providers.dart';
import 'package:noo/presentation/providers/settings_provider.dart';
import 'package:noo/presentation/widgets/dialogs/classic_form.dart';
import 'package:noo/presentation/widgets/dialogs/mcp_settings_form.dart';
import 'package:noo/presentation/widgets/dialogs/mcp_setup_hints.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The controls a user actually touches to get an agent connected.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The MCP token lives in the keychain, so enabling the server goes through
  // this channel. Left unmocked it never answers inside fake async and the
  // write hangs forever rather than failing.
  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  /// Stands in for the keychain, so a token written can be read back — which
  /// is how the form tells "no token" from "the keyring refused it".
  late Map<String, String> keychain;

  setUp(() {
    keychain = {};
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
      final key = call.arguments is Map ? call.arguments['key'] as String? : null;
      return switch (call.method) {
        'readAll' => keychain,
        'read' => keychain[key],
        'write' => keychain[key!] = call.arguments['value'] as String,
        'delete' => keychain.remove(key),
        'containsKey' => keychain.containsKey(key),
        _ => null,
      };
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  /// Pumps the form, optionally over a container the caller has already
  /// configured — [ProviderContainer] is taken whole rather than a list of
  /// overrides because `Override` is not part of flutter_riverpod's exports.
  Future<ProviderContainer> pumpForm(
    WidgetTester tester, {
    ProviderContainer? withContainer,
  }) async {
    final container = withContainer ?? ProviderContainer();
    addTearDown(container.dispose);

    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          // No Scaffold on purpose: the form reports a copy with an inline
          // label rather than a SnackBar, because on desktop it lives inside
          // an AlertDialog where a SnackBar would appear behind the dialog.
          home: const Material(
            child: SingleChildScrollView(child: McpSettingsForm()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// Taps the label rather than the ClassicCheckbox itself: the widget is a
  /// column of a narrow tappable row plus a wider hint, so its centre lands in
  /// the hint text and the tap misses.
  Future<void> enable(WidgetTester tester) async {
    await tester.tap(find.text('Enable MCP server'));
    await tester.pumpAndSettle();
  }

  testWidgets('enabling mints a token even with no database open',
      (tester) async {
    final container = await pumpForm(tester);
    expect(container.read(settingsProvider).mcpToken, isNull);

    await enable(tester);

    final token = container.read(settingsProvider).mcpToken;
    expect(token, isNotNull);
    expect(token, hasLength(64));
    expect(token, matches(RegExp(r'^[0-9a-f]+$')));
    expect(container.read(settingsProvider).mcpEnabled, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the server waits for a database rather than reporting an error',
      (tester) async {
    await pumpForm(tester);
    await enable(tester);

    expect(find.text('Waiting for a database to be opened.'), findsOneWidget);
  });

  testWidgets('read-only cannot be changed until the server is enabled',
      (tester) async {
    await pumpForm(tester);

    ClassicCheckbox readOnly() => tester.widget<ClassicCheckbox>(
          find.widgetWithText(ClassicCheckbox, 'Read-only'),
        );

    // A null onChanged is how this dialog greys a control out.
    expect(readOnly().onChanged, isNull);

    await enable(tester);
    expect(readOnly().onChanged, isNotNull);
  });

  testWidgets('the token is masked until revealed', (tester) async {
    final container = await pumpForm(tester);
    await enable(tester);
    final token = container.read(settingsProvider).mcpToken!;

    TextField tokenField() => tester.widget<TextField>(
          find.descendant(
            of: find.byType(ClassicTextField).at(1),
            matching: find.byType(TextField),
          ),
        );

    expect(tokenField().obscureText, isTrue);
    expect(tokenField().controller!.text, token);

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pumpAndSettle();
    expect(tokenField().obscureText, isFalse);
  });

  testWidgets('regenerating is behind a confirmation', (tester) async {
    final container = await pumpForm(tester);
    await enable(tester);
    final original = container.read(settingsProvider).mcpToken;

    await tester.tap(find.widgetWithText(TextButton, 'Regenerate'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(container.read(settingsProvider).mcpToken, original);

    await tester.tap(find.widgetWithText(TextButton, 'Regenerate'));
    await tester.pumpAndSettle();
    // The dialog's own button, not the row's.
    await tester.tap(find.widgetWithText(TextButton, 'Regenerate').last);
    await tester.pumpAndSettle();

    final rotated = container.read(settingsProvider).mcpToken;
    expect(rotated, isNotNull);
    expect(rotated, isNot(original));
  });

  testWidgets('the snippet follows the port and the selected client',
      (tester) async {
    await pumpForm(tester);
    await enable(tester);

    expect(find.textContaining('claude mcp add'), findsOneWidget);
    expect(find.textContaining('127.0.0.1:8737/mcp'), findsWidgets);

    // Raise the port and the printed endpoint has to follow, or the user
    // pastes a config pointing at nothing.
    await tester.tap(find.byIcon(Icons.arrow_drop_up).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('127.0.0.1:8738/mcp'), findsWidgets);
    // The URL field is driven from a controller whose text changes here, so
    // this also covers not marking a mounted TextField dirty mid-build.
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(DropdownButton<McpClientHint>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OpenCode').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('"type": "remote"'), findsOneWidget);
  });

  testWidgets('a keychain that refuses the token says so', (tester) async {
    // Simulates a locked keyring: SecureStorageService swallows the failure,
    // so without reading the value back the tab would sit at "not running"
    // with nothing to explain it.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
      if (call.method == 'write') {
        throw PlatformException(code: 'locked');
      }
      return call.method == 'readAll' ? <String, String>{} : null;
    });

    await pumpForm(tester);
    await enable(tester);

    expect(find.textContaining('system keychain'), findsOneWidget);
  });

  group('excluded branches', () {
    /// A real database rather than a mock: the list is built from
    /// `getMcpExcludedTasks` and the ancestor walk that follows it, and both
    /// are the parts worth exercising.
    Future<ProviderContainer> pumpWithDatabase(
      WidgetTester tester,
      NooDatabase db,
    ) =>
        pumpForm(
          tester,
          withContainer: ProviderContainer(
            overrides: [databaseProvider.overrideWithValue(db)],
          ),
        );

    Future<int> makeTask(
      NooDatabase db, {
      required String title,
      int? parentId,
    }) =>
        db.createTask(
          parentId: parentId,
          worldId: WorldId.create().toString(),
          title: title,
        );

    testWidgets('nothing hidden says so', (tester) async {
      final db = NooDatabase.memory();
      addTearDown(db.close);
      await makeTask(db, title: 'Visible');

      await pumpWithDatabase(tester, db);

      expect(
        find.text('Nothing is excluded — agents can see the whole outline.'),
        findsOneWidget,
      );
    });

    testWidgets('a hidden branch is named with its path', (tester) async {
      final db = NooDatabase.memory();
      addTearDown(db.close);
      final parent = await makeTask(db, title: 'Work');
      final secret = await makeTask(db, title: 'Salaries', parentId: parent);
      await db.setTaskMcpExcluded(secret, true);

      await pumpWithDatabase(tester, db);

      // The title alone would not distinguish one "Notes" from another.
      expect(find.text('Work › Salaries'), findsOneWidget);
    });

    testWidgets('choosing needs a database to choose from', (tester) async {
      await pumpForm(tester);

      final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Choose…'),
      );
      // The tab is reachable before a database is open, to set the port and
      // token up front — but there is no outline to pick from yet.
      expect(button.onPressed, isNull);
    });

    testWidgets('Choose… opens the branch picker', (tester) async {
      final db = NooDatabase.memory();
      addTearDown(db.close);
      await makeTask(db, title: 'Work');

      await pumpWithDatabase(tester, db);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Choose…'));
      await tester.pumpAndSettle();

      // Scoped to the dialog: the tab's own checkboxes are still mounted
      // behind it.
      final inDialog = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Checkbox),
      );
      expect(find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Work'),
      ), findsOneWidget);
      expect(inDialog, findsOneWidget);
    });
  });

}
