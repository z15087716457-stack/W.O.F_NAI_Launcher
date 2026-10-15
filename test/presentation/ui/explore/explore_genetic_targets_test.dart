import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_contract.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_fixture.dart';
import 'package:nai_launcher/presentation/ui/explore/explore_page.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_block_pill.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_lib_controls.dart';
import '../../../helpers/studio_capture_fonts.dart';
import 'explore_test_harness.dart';

const _variables = [
  ExploreVariable(title: 'Ordinary', color: Colors.blue, poolSize: 12),
  ExploreVariable(
    title: 'Genetic A',
    color: Colors.pink,
    poolSize: 20,
    evolution: true,
  ),
  ExploreVariable(
    title: 'Genetic B',
    color: Colors.teal,
    poolSize: 15,
    evolution: true,
  ),
];

Future<void> captureTargets(WidgetTester tester, String name) async {
  if (Platform.environment['CAPTURE_GENETIC_CONTROLS'] != '1') return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('explore-capture')),
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
  void open(WidgetTester tester) => ExploreScope.of(
    tester.element(find.byKey(const Key('explore-variables'))),
  ).controller.startEvolution(['c27']);
  for (final language in ['zh', 'zh_TW', 'en', 'ja', 'ko']) {
    for (final dark in [false, true]) {
      testWidgets(
        'all participating blocks are genetic targets $language dark=$dark',
        (tester) async {
          await pumpExplore(
            tester,
            data: ExploreFixture.view(vars: _variables),
            locale: language,
            dark: dark,
            window: dark ? 1200 : 1600,
          );
          final l = tester
              .element(find.byKey(const Key('explore-variables')))
              .l10n;
          expect(find.text('· ${l.explore_evolutionTarget}'), findsNWidgets(2));
          expect(
            find.byKey(const Key('explore-variable-genetic-0')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('explore-variable-genetic-1')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('explore-variable-genetic-2')),
            findsOneWidget,
          );
          if (language == 'zh') expect(l.explore_evolutionTarget, '遗传目标');
          await captureTargets(tester, 'variables-$language-$dark');
          open(tester);
          await tester.pumpAndSettle();
          final summary = find.byKey(const Key('explore-genetic-summary'));
          expect(
            find.descendant(of: summary, matching: find.byType(UiBlockPill)),
            findsNWidgets(2),
          );
          expect(
            find.descendant(of: summary, matching: find.text('Genetic A')),
            findsOneWidget,
          );
          expect(
            find.descendant(of: summary, matching: find.text('Genetic B')),
            findsOneWidget,
          );
          expect(
            find.descendant(of: summary, matching: find.text('Ordinary')),
            findsNothing,
          );
          await captureTargets(tester, 'targets-$language-$dark');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'ordinary variables never enable evolution without a genetic target',
    (tester) async {
      final record = RecordingExploreActions();
      await pumpExplore(
        tester,
        data: ExploreFixture.view(vars: [_variables.first]),
        actions: record.actions,
      );
      open(tester);
      await tester.pumpAndSettle();
      expect(
        tester.widget<UiBtn>(find.byKey(const Key('explore-evo-create'))).onTap,
        isNull,
      );
      expect(
        tester
            .widget<UiBtn>(find.byKey(const Key('explore-evo-create-generate')))
            .onTap,
        isNull,
      );
      expect(find.byKey(const Key('explore-genetic-summary')), findsOneWidget);
      await tester.tap(find.byKey(const Key('explore-evo-create-generate')));
      await tester.pumpAndSettle();
      expect(record.calls.where((c) => c.startsWith('evolution:')), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
