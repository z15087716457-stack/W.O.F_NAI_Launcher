import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_view_state.dart';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_inspector.dart';
import '../../test/helpers/studio_capture_fonts.dart';
import '../../test/presentation/screens/style_explore/explore_inspector_test.dart';

void main() {
  final output = Directory('.dart_tool/uiux-explore-task05/captures');
  setUpAll(() async {
    await loadStudioCaptureFonts();
    output.createSync(recursive: true);
  });
  testWidgets(
    'real-font production inspector across states, widths and languages',
    (tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final cards =
          jsonDecode(
                File(
                  '.dart_tool/uiux-explore-task03/prototype-cards.json',
                ).readAsStringSync(),
              )
              as List;
      for (final scene in ['single', 'multi', 'pending', 'empty']) {
        final base = inspectorFixture(scene: scene);
        final candidates = [
          for (
            var i = 0;
            i < (scene == 'single' ? 38 : base.candidates.length);
            i++
          )
            base
                .candidates[scene == 'single' && i == 26
                    ? 0
                    : i % base.candidates.length]
                .copyWith(
                  id: 'c${i + 1}',
                  rollSnapshot: scene == 'multi'
                      ? ExploreRollSnapshot(
                          positive: '',
                          negative: '',
                          instanceRolls: [
                            ExploreInstanceRoll(
                              lane: 'pos',
                              marker: 'a',
                              blockId: 'pool',
                              blockTitle: '400精选画师池',
                              rolledText:
                                  (cards[i % cards.length]['atoms'] as List)
                                      .join(', '),
                            ),
                          ],
                        )
                      : base
                            .candidates[scene == 'single' && i == 26
                                ? 0
                                : i % base.candidates.length]
                            .rollSnapshot,
                  roundId: scene == 'single'
                      ? (i < 14
                            ? 'r1'
                            : i < 26
                            ? 'r2'
                            : 'r3')
                      : base.candidates[i].roundId,
                  generation: base
                      .candidates[scene == 'single' && i == 26
                          ? 0
                          : i % base.candidates.length]
                      .generation
                      .copyWith(
                        filePath:
                            'E:/A.I/NovelAI/.devin/mockups/style-explore/${cards[scene == 'single' && i == 26 ? 0 : i % cards.length]['image']}',
                      ),
                ),
        ];
        final run = base.copyWith(
          candidates: candidates,
          rounds: [
            for (final round in base.rounds)
              round.copyWith(
                candidateIds: candidates
                    .where((c) => c.roundId == round.id)
                    .map((c) => c.id)
                    .toList(),
              ),
          ],
        );
        for (final width in [280, 312, 420]) {
          for (final locale in ['zh', 'en', 'ja', 'ko']) {
            for (final dark in [false, true]) {
              await tester.pumpWidget(const SizedBox.shrink());
              final boundary = GlobalKey();
              await tester.pumpWidget(
                inspectorFixtureApp(
                  run,
                  scene: scene,
                  width: width.toDouble(),
                  locale: locale,
                  dark: dark,
                  captureKey: boundary,
                ),
              );
              await tester.pumpAndSettle();
              final container = ProviderScope.containerOf(
                tester.element(find.byType(ExploreInspector)),
              );
              container
                  .read(exploreFocusedCandidateIdProvider.notifier)
                  .state = scene == 'empty'
                  ? null
                  : scene == 'pending'
                  ? 'c11'
                  : scene == 'single'
                  ? 'c27'
                  : 'c1';
              if (scene == 'multi') {
                container.read(exploreSelectionModeProvider.notifier).state =
                    true;
                container.read(exploreSelectionProvider.notifier).selectAll([
                  'c1',
                  'c3',
                  'c4',
                  'c7',
                ]);
              }
              await tester.pumpAndSettle();
              for (var i = 0; i < 20; i++) {
                await tester.runAsync(() async {
                  await Future<void>.delayed(const Duration(milliseconds: 50));
                });
                await tester.pumpAndSettle();
                if (tester
                    .renderObjectList<RenderImage>(find.byType(RawImage))
                    .every((r) => r.image != null)) {
                  break;
                }
              }
              expect(
                tester.takeException(),
                isNull,
                reason: '$scene/$width/$locale/$dark',
              );
              final render =
                  boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary;
              final bytes = await tester.runAsync(() async {
                final image = await render.toImage();
                final data = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                image.dispose();
                return data!;
              });
              File(
                '${output.path}/inspector-$scene-$width-$locale-${dark ? 'dark' : 'light'}.png',
              ).writeAsBytesSync(bytes!.buffer.asUint8List());
            }
          }
        }
      }
    },
  );
}
