import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';
import 'package:nai_launcher/presentation/widgets/common/translation_icon.dart';
import 'package:nai_launcher/presentation/widgets/common/uiux_prototype_icon.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/dna_icon.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool settle = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: IconTheme(
            data: const IconThemeData(
              size: 16,
              color: Colors.blue,
              opacity: .5,
            ),
            child: child,
          ),
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

void main() {
  testWidgets('HTML path icons keep theme size, alpha and semantics', (
    tester,
  ) async {
    await _pump(
      tester,
      const UiuxPrototypeIcon(Icons.add, semanticLabel: 'Add'),
    );
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.bySemanticsLabel('Add'), findsOneWidget);
    expect(tester.getSize(find.byType(UiuxPrototypeIcon)), const Size(16, 16));
    expect(
      tester.widget<SvgPicture>(find.byType(SvgPicture)).colorFilter,
      ColorFilter.mode(Colors.blue.withValues(alpha: .5), BlendMode.srcIn),
    );
    expect(
      const UiuxPrototypeIcon(Icons.add).prototypePath,
      'M12 5v14M5 12h14',
    );
  });

  testWidgets('prototype source distinguishes the two dice drawings', (
    tester,
  ) async {
    const block = UiuxPrototypeIcon(Icons.casino_outlined);
    const generation = UiuxPrototypeIcon(
      Icons.casino_outlined,
      source: UiuxPrototypeIconSource.generation,
    );
    expect(block.prototypePath, isNot(generation.prototypePath));
    expect(block.prototypePath, contains('M12 12h.01'));
    await _pump(tester, block);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'HTML font references and unmatched choices keep their host glyph',
    (tester) async {
      await _pump(tester, const UiuxPrototypeIcon(StudioIcons.promptBlocks));
      expect(find.byIcon(StudioIcons.promptBlocks), findsOneWidget);
      expect(find.byType(SvgPicture), findsNothing);
      await _pump(tester, const UiuxPrototypeIcon(Icons.build_outlined));
      expect(find.byIcon(Icons.build_outlined), findsOneWidget);
    },
  );

  testWidgets('DNA uses the new helix even after a trigger change', (
    tester,
  ) async {
    for (final trigger in [0, 1]) {
      await _pump(
        tester,
        DnaIcon(size: 11, color: Colors.green, trigger: trigger),
      );
      expect(find.byIcon(StudioIcons.inherit), findsNothing);
      final icon = tester.widget<UiuxPrototypeIcon>(
        find.byType(UiuxPrototypeIcon),
      );
      expect(
        icon.prototypePath,
        'M8 3c0 5 8 5 8 9s-8 4-8 9M16 3c0 5-8 5-8 9s8 4 8 9M9.5 7h5M9.5 17h5',
      );
      expect(tester.getSize(find.byType(DnaIcon)), const Size(11, 11));
      expect(tester.binding.hasScheduledFrame, isFalse);
    }
  });

  testWidgets(
    'pill translation uses the prototype glyph in both activity states',
    (tester) async {
      for (final busy in [false, true]) {
        await _pump(
          tester,
          TranslationIcon(
            size: 12,
            busy: busy,
            style: TranslationIconStyle.pill,
          ),
          settle: !busy,
        );
        final slot = tester.getSize(find.byType(TranslationIcon));
        expect(slot.height, 12);
        final glyph = tester
            .widgetList<RichText>(find.byType(RichText))
            .singleWhere((widget) => widget.text.toPlainText() == '译');
        expect(slot.width, tester.getSize(find.byWidget(glyph)).width);
        final style = glyph.text.style!;
        expect(style.fontSize, 10);
        expect(style.fontWeight, FontWeight.w700);
        final fade = tester.widget<FadeTransition>(
          find.descendant(
            of: find.byType(TranslationIcon),
            matching: find.byType(FadeTransition),
          ),
        );
        expect(fade.opacity.value, 1);
        if (busy) {
          await tester.pump(const Duration(milliseconds: 350));
          expect(fade.opacity.value, lessThan(1));
        }
        expect(tester.takeException(), isNull);
      }
      await _pump(
        tester,
        const TranslationIcon(size: 12, style: TranslationIconStyle.pill),
      );
      expect(tester.binding.hasScheduledFrame, isFalse);
    },
  );
}
