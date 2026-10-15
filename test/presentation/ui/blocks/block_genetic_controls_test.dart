import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_fixture.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_instance.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_menu.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_glyph.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'blocks_test_harness.dart';

Future<void> captureGenetic(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_GENETIC_CONTROLS'] != '1') return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('blocks-capture')),
    );
    final bitmap = await boundary.toImage(pixelRatio: 1);
    final bytes = await bitmap.toByteData(format: ui.ImageByteFormat.png);
    bitmap.dispose();
    final file = File(
      '.dart_tool/explore-genetic-controls-20261015/captures/$name.png',
    );
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
}

void main() {
  setUpAll(loadStudioCaptureFonts);
  for (final language in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets(
        'genetic control random sequence fixed $language dark=$dark',
        (tester) async {
          var mode = BlockMode.random;
          var genetic = false;
          var enabled = true;
          var calls = 0;
          await pumpBlocks(
            tester,
            StatefulBuilder(
              builder: (context, update) => Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: BlockInstanceCard(
                    data: BlockInstanceViewData(
                      block: BlocksFixture.byId('pk'),
                      settings: BlockRollSettings(mode: mode),
                      evolution: genetic,
                      enabled: enabled,
                      send: 'artist:a',
                      drawn: const [BlockDrawn('artist:a')],
                    ),
                    actions: BlockInstanceActions(
                      onReroll: () {},
                      onLockChanged: (_) {},
                      onModeChanged: (value) => update(() => mode = value),
                      onStep: (_) {},
                      onSideChanged: (_) {},
                      onEnabledChanged: (value) =>
                          update(() => enabled = value),
                      onEditBlock: () {},
                      onRemove: () {},
                      onApplyParams: () {},
                      onSaveSettings: (_) {},
                      sample: (_, _) => [],
                      onShowInLibrary: () {},
                      onCopySend: () {},
                      onEvolutionChanged: (value) => update(() {
                        genetic = value;
                        calls++;
                      }),
                    ),
                  ),
                ),
              ),
            ),
            locale: language,
            dark: dark,
            rail: false,
            window: 460,
            height: 760,
          );
          final control = find.byKey(const Key('block-card-genetic'));
          expect(control, findsOneWidget);
          expect(
            tester.getRect(control).right,
            lessThanOrEqualTo(
              tester.getRect(find.byKey(const Key('block-card-modes'))).left,
            ),
          );
          Semantics state() => tester.widget<Semantics>(control);
          expect(state().properties.enabled, isTrue);
          expect(state().properties.toggled, isFalse);
          await tester.tap(control);
          await tester.pumpAndSettle();
          expect(genetic, isTrue);
          expect(state().properties.toggled, isTrue);
          await captureGenetic(tester, 'random-$language-$dark');
          await tester.tap(find.byKey(const Key('block-card-mode-fixed')));
          await tester.pumpAndSettle();
          expect(state().properties.enabled, isFalse);
          expect(state().properties.toggled, isFalse);
          await tester.tap(control);
          await tester.pumpAndSettle();
          expect(calls, 1);
          expect(genetic, isTrue);
          await captureGenetic(tester, 'fixed-$language-$dark');
          await tester.tap(find.byKey(const Key('block-card-mode-sequential')));
          await tester.pumpAndSettle();
          expect(state().properties.enabled, isTrue);
          expect(state().properties.toggled, isTrue);
          await captureGenetic(tester, 'sequence-$language-$dark');
          await tester.tap(control);
          await tester.pumpAndSettle();
          expect(genetic, isFalse);
          expect(calls, 2);
          await tester.tap(find.byKey(const Key('block-card-toggle')));
          await tester.pumpAndSettle();
          expect(state().properties.enabled, isFalse);
          await tester.tap(control);
          await tester.pumpAndSettle();
          expect(calls, 2);
          await tester.tap(find.byKey(const Key('block-card-more')));
          await tester.pumpAndSettle();
          final menu = tester.widget<UiMenu>(find.byType(UiMenu));
          expect(menu.items.any((item) => item.glyph == UiGlyphs.evo), isFalse);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('ordinary block card has no genetic entry', (tester) async {
    final rec = RecordingBlocks();
    final data = BlocksFixture.instanceRandom();
    await pumpBlocks(
      tester,
      Align(
        alignment: Alignment.topLeft,
        child: BlockInstanceCard(data: data, actions: rec.instance(data)),
      ),
    );
    expect(find.byKey(const Key('block-card-genetic')), findsNothing);
    await tester.tap(find.byKey(const Key('block-card-more')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<UiMenu>(find.byType(UiMenu))
          .items
          .any((item) => item.glyph == UiGlyphs.evo),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
}
