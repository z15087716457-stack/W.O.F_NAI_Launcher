import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/widgets/common/hinted_scroll_view.dart';

void main() {
  testWidgets(
    'hint follows overflow, clicks, wheel position and collapsed content',
    (tester) async {
      final height = ValueNotifier<double>(620);
      addTearDown(height.dispose);
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 320,
                height: 200,
                child: ValueListenableBuilder<double>(
                  valueListenable: height,
                  builder: (_, value, _) => HintedScrollView(
                    child: SizedBox(
                      height: value,
                      child: const Text('advanced content'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final arrow = find.byKey(const ValueKey('settings-scroll-down'));
      expect(arrow, findsOneWidget);
      final scroll = tester
          .widget<SingleChildScrollView>(find.byType(SingleChildScrollView))
          .controller!;
      final hintRect = tester.getRect(arrow);
      final viewport = tester.getRect(find.byType(SingleChildScrollView));
      expect(hintRect.top, greaterThanOrEqualTo(viewport.bottom));
      await tester.tap(arrow);
      await tester.pumpAndSettle();
      expect(scroll.offset, greaterThan(0));
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(arrow, findsNothing);
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      expect(arrow, findsOneWidget);
      height.value = 190;
      await tester.pumpAndSettle();
      expect(arrow, findsNothing);
      expect(scroll.position.maxScrollExtent, 0);
      height.value = 200;
      await tester.pumpAndSettle();
      expect(arrow, findsNothing);
      height.value = 201;
      await tester.pumpAndSettle();
      expect(arrow, findsOneWidget);
      height.value = 700;
      await tester.pumpAndSettle();
      expect(arrow, findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('nested horizontal overflow does not show a vertical hint', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 200,
            child: HintedScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(width: 800, height: 50),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings-scroll-down')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
