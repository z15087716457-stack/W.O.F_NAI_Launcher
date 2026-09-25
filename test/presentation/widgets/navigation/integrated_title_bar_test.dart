import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.nailauncher/titlebar');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Widget buildShell({
    required Widget child,
    bool immersive = false,
    VoidCallback? onToggleTheme,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: IntegratedTitleBarShell(
        immersive: immersive,
        onToggleTheme: onToggleTheme,
        child: child,
      ),
    );
  }

  double? lastReservedRight() {
    final region = calls.lastWhere((c) => c.method == 'setRegion');
    return (region.arguments as Map)['reservedRight'] as double?;
  }

  Finder dividerFinder() => find.descendant(
    of: find.byType(IntegratedTitleBarShell),
    matching: find.byType(AnimatedContainer),
  );

  group('IntegratedTitleBarShell', () {
    testWidgets('renders logo, app title and three caption buttons', (
      tester,
    ) async {
      await tester.pumpWidget(buildShell(child: const SizedBox.expand()));
      await tester.pump();

      expect(find.text('NAI Studio'), findsOneWidget);

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is AssetImage &&
              (widget.image as AssetImage).assetName ==
                  'assets/images/wof_logo_block.png',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.crop_square), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      for (final icon in [Icons.remove, Icons.close]) {
        expect(tester.widget<Icon>(find.byIcon(icon)).size, 16);
      }
    });

    testWidgets('reports caption region on mount and clears on dispose', (
      tester,
    ) async {
      await tester.pumpWidget(buildShell(child: const SizedBox.expand()));
      await tester.pump();

      expect(
        calls,
        contains(
          isA<MethodCall>()
              .having((c) => c.method, 'method', 'setRegion')
              .having(
                (c) => (c.arguments as Map)['barHeight'],
                'barHeight',
                IntegratedTitleBarShell.barHeight,
              )
              .having(
                (c) => (c.arguments as Map)['reservedRight'],
                'reservedRight',
                IntegratedTitleBarShell.reservedRight,
              ),
        ),
      );

      calls.clear();
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(calls.map((c) => c.method), contains('clear'));
    });

    testWidgets('hairline divider appears only after content scrolls', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildShell(
          child: ListView.builder(
            itemCount: 50,
            itemBuilder: (_, i) => SizedBox(height: 60, child: Text('row $i')),
          ),
        ),
      );
      await tester.pump();

      Color dividerColor() =>
          (tester.widget<AnimatedContainer>(dividerFinder()).decoration
                  as BoxDecoration)
              .color!;

      expect(dividerColor(), Colors.transparent);

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(dividerColor(), isNot(Colors.transparent));

      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(dividerColor(), Colors.transparent);
    });

    testWidgets(
      'immersive bar drops logo and title, keeps theme toggle and captions',
      (tester) async {
        var toggles = 0;
        await tester.pumpWidget(
          buildShell(
            child: const SizedBox.expand(),
            immersive: true,
            onToggleTheme: () => toggles++,
          ),
        );
        await tester.pump();

        expect(find.text('NAI Studio'), findsNothing);
        expect(
          find.byKey(const ValueKey('immersive_title_bar')),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.close), findsOneWidget);
        // 明暗按钮也要留在可点击区
        expect(
          lastReservedRight(),
          IntegratedTitleBarShell.reservedRight +
              IntegratedTitleBarShell.themeButtonWidth +
              IntegratedTitleBarShell.themeSeparatorWidth,
        );
        await tester.tap(find.byKey(const Key('brand_appearance_toggle')));
        expect(toggles, 1);

        // 离开登录页：玻璃栏淡入，命中区恢复为三个窗口按钮
        await tester.pumpWidget(
          buildShell(child: const SizedBox.expand(), onToggleTheme: () {}),
        );
        await tester.pumpAndSettle();
        expect(find.text('NAI Studio'), findsOneWidget);
        expect(find.byKey(const Key('brand_appearance_toggle')), findsNothing);
        expect(lastReservedRight(), IntegratedTitleBarShell.reservedRight);
      },
    );

    testWidgets('caption buttons do not overflow a narrow window', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildShell(child: const SizedBox.expand()));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });
}
