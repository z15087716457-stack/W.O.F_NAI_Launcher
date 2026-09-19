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

  Widget buildShell({required Widget child}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: IntegratedTitleBarShell(child: child),
    );
  }

  Finder dividerFinder() => find.descendant(
        of: find.byType(IntegratedTitleBarShell),
        matching: find.byType(AnimatedContainer),
      );

  group('IntegratedTitleBarShell', () {
    testWidgets('renders logo, app title and three caption buttons',
        (tester) async {
      await tester.pumpWidget(buildShell(child: const SizedBox.expand()));
      await tester.pump();

      expect(find.text('NAI Launcher'), findsOneWidget);

      final image = tester.widget<Image>(find.byType(Image));
      expect(
        image.image,
        isA<AssetImage>().having(
          (a) => a.assetName,
          'assetName',
          'assets/images/wof_logo_block.png',
        ),
      );

      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.crop_square), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('reports caption region on mount and clears on dispose',
        (tester) async {
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

    testWidgets('hairline divider appears only after content scrolls',
        (tester) async {
      await tester.pumpWidget(
        buildShell(
          child: ListView.builder(
            itemCount: 50,
            itemBuilder: (_, i) => SizedBox(height: 60, child: Text('row $i')),
          ),
        ),
      );
      await tester.pump();

      Color dividerColor() => (tester
              .widget<AnimatedContainer>(dividerFinder())
              .decoration as BoxDecoration)
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

    testWidgets('caption buttons do not overflow a narrow window',
        (tester) async {
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
