import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noo/core/theme/app_theme.dart';
import 'package:noo/presentation/widgets/window_title_bar.dart';

/// The app-drawn title bar in each style: Modern keeps the menu in a muted
/// strip with the title centred; Classic draws the strip in the accent
/// colour, sets the title bold at the left, and greys it out while the
/// window is inactive.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('window_manager');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'isMaximized') return false;
      return null;
    });
  });
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  Future<void> pumpBar(WidgetTester tester, ThemeData theme,
      {Widget? menu}) async {
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Column(children: [
          WindowTitleBar(title: 'Noo — work.noo', menu: menu),
        ]),
      ),
    ));
    await tester.pumpAndSettle();
  }

  Color barColor(WidgetTester tester) {
    final container = tester.widget<Container>(find
        .descendant(
            of: find.byType(WindowTitleBar), matching: find.byType(Container))
        .first);
    return (container.decoration! as BoxDecoration).color!;
  }

  /// What window_manager delivers when the window gains or loses focus.
  Future<void> windowEvent(WidgetTester tester, String name) async {
    await messenger.handlePlatformMessage(
      'window_manager',
      const StandardMethodCodec()
          .encodeMethodCall(MethodCall('onEvent', {'eventName': name})),
      (_) {},
    );
    await tester.pump();
  }

  testWidgets('modern: a muted strip, title centred', (tester) async {
    final theme = AppTheme.light;
    await pumpBar(tester, theme, menu: const Text('File'));

    expect(barColor(tester), theme.colorScheme.surfaceContainerLow);
    expect(find.text('File'), findsOneWidget);
    expect(find.ancestor(of: find.text('Noo — work.noo'), matching: find.byType(Center)),
        findsWidgets);
  });

  testWidgets('classic: the accent while active, grey while not',
      (tester) async {
    final theme = AppTheme.build(Brightness.light,
        style: UiStyle.classic, accent: AccentColor.green);
    await pumpBar(tester, theme);

    expect(barColor(tester), theme.colorScheme.primary);
    final title = tester.widget<Text>(find.text('Noo — work.noo'));
    expect(title.style!.fontWeight, FontWeight.w600);
    expect(title.style!.color, theme.colorScheme.onPrimary);

    await windowEvent(tester, 'blur');
    expect(barColor(tester), theme.colorScheme.surfaceContainerHighest);

    await windowEvent(tester, 'focus');
    expect(barColor(tester), theme.colorScheme.primary);
  });
}
