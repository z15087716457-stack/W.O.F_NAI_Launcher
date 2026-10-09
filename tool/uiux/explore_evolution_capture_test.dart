import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_view_state.dart';
import '../../test/helpers/studio_capture_fonts.dart';
import '../../test/presentation/screens/style_explore/explore_candidate_wall_test.dart';
import '../../test/presentation/screens/style_explore/explore_inspector_test.dart'
    show InspectorBlocks;

ExploreRun evolutionCaptureFixture({String scene = 'three'}) {
  final cards =
      jsonDecode(
            File(
              '.dart_tool/uiux-explore-task03/prototype-cards.json',
            ).readAsStringSync(),
          )
          as List;
  final base = wallFixture(count: 40), generations = scene == 'one' ? 1 : 3;
  final sets = [
    for (var g = 1; g <= generations; g++)
      ExploreParentSet(
        id: 'set$g',
        familyId: 'line',
        generation: g,
        status: g == generations
            ? ExploreParentSetStatus.active
            : ExploreParentSetStatus.used,
        parents: [
          for (var p = 0; p < (g == 1 ? 2 : 3); p++)
            ExploreParent(
              id: 'p$g-$p',
              sourceCandidateId:
                  'c${g == 1 ? p + 1 : 4 + (g - 2) * 12 + p + 1}',
              artistString: g == 1
                  ? '${p == 0 ? '0.8::artist:sincos::' : 'artist:ciloranko'}, artist:tiv'
                  : 'artist:child$p, artist:new',
              preference: [3.0, 2.0, 1.5, 1.0][p],
            ),
          if (g > 1)
            for (var p = 0; p < 2; p++)
              ExploreParent(
                id: 'back$g-$p',
                sourceCandidateId: 'c${p + 1}',
                artistString:
                    '${p == 0 ? '0.8::artist:sincos::' : 'artist:ciloranko'}, artist:tiv',
                preference: .75,
              ),
        ],
      ),
  ];
  final candidates = [
    for (var i = 0; i < 4 + generations * 12; i++)
      base.candidates[i].copyWith(
        roundId: i < 4 ? 'roots' : 'round${1 + (i - 4) ~/ 12}',
        generation: base.candidates[i].generation.copyWith(
          filePath:
              'E:/A.I/NovelAI/.devin/mockups/style-explore/${cards[i % cards.length]['image']}',
          status: scene == 'generating' && i >= 4 + generations * 12 - 3
              ? ExploreCandidateGenerationStatus.pending
              : ExploreCandidateGenerationStatus.done,
        ),
        lineage: ExploreLineage(
          operation: i < 4
              ? ExploreLineageOperation.basicRoll
              : [
                  ExploreLineageOperation.crossover,
                  ExploreLineageOperation.mutation,
                  ExploreLineageOperation.injection,
                ][i % 3],
          parentCandidateIds: i < 4 ? [] : ['c1', 'c2'],
          generation: i < 4 ? 1 : 1 + (i - 4) ~/ 12,
          mutatedText: 'artist:sincos, artist:tiv, artist:new',
        ),
      ),
  ];
  return base.copyWith(
    candidates: candidates,
    families: scene == 'empty'
        ? []
        : [
            ExploreFamily(
              id: 'line',
              name: '冷色·厚涂',
              createdAt: base.createdAt,
              rootParentSetId: 'set1',
              activeParentSetId: 'set$generations',
            ),
          ],
    parentSets: scene == 'empty' ? [] : sets,
    rounds: [
      ExploreRound(
        id: 'roots',
        number: 1,
        phase: ExploreRoundPhase.basic,
        status: ExploreRoundStatus.generated,
        createdAt: base.createdAt,
        targetCount: 4,
        candidateIds: [for (var i = 1; i <= 4; i++) 'c$i'],
      ),
      for (var g = 1; g <= generations; g++)
        ExploreRound(
          id: 'round$g',
          number: g + 1,
          phase: ExploreRoundPhase.deep,
          status: scene == 'generating' && g == generations
              ? ExploreRoundStatus.generating
              : ExploreRoundStatus.generated,
          createdAt: base.createdAt,
          targetCount: 12,
          parentSetId: 'set$g',
          familyId: 'line',
          generation: g,
          candidateIds: [
            for (var i = 0; i < 12; i++) 'c${5 + (g - 1) * 12 + i}',
          ],
        ),
    ],
  );
}

void main() {
  final out = Directory('.dart_tool/uiux-explore-task07/captures');
  setUpAll(() async {
    await loadStudioCaptureFonts();
    out.createSync(recursive: true);
  });
  testWidgets('64 production evolution renders with real fonts', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final scene in ['one', 'three', 'generating', 'empty']) {
      final run = evolutionCaptureFixture(scene: scene);
      for (final width in [900, 1200]) {
        tester.view.physicalSize = Size(width.toDouble(), 1400);
        for (final locale in ['zh', 'en', 'ja', 'ko']) {
          for (final dark in [false, true]) {
            await tester.pumpWidget(const SizedBox.shrink());
            final boundary = GlobalKey();
            await tester.pumpWidget(
              wallFixtureApp(
                run,
                width: width.toDouble(),
                locale: locale,
                dark: dark,
                captureKey: boundary,
                scene: scene == 'generating' ? 'runner' : 'idle',
                extraOverrides: [
                  exploreStageTabProvider.overrideWith(
                    (ref) => ExploreStageTab.evolution,
                  ),
                  exploreActiveFamilyIdProvider.overrideWith((ref) => 'line'),
                  promptBlockLibraryNotifierProvider.overrideWith(
                    InspectorBlocks.new,
                  ),
                ],
              ),
            );
            if (scene == 'generating') {
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 400));
            } else {
              await tester.pumpAndSettle();
            }
            if (scene == 'three') {
              await tester.ensureVisible(
                find.byKey(const Key('explore-generation-expand-set2')),
              );
              await tester.tap(
                find.byKey(const Key('explore-generation-expand-set2')),
              );
              await tester.pumpAndSettle();
            }
            for (var i = 0; i < 20; i++) {
              await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 50)),
              );
              await tester.pump(const Duration(milliseconds: 100));
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
              final b = await image.toByteData(format: ui.ImageByteFormat.png);
              image.dispose();
              return b!.buffer.asUint8List();
            });
            await tester.runAsync(
              () => File(
                '${out.path}/evolution-$scene-$width-$locale-${dark ? 'dark' : 'light'}.png',
              ).writeAsBytes(bytes!),
            );
          }
        }
      }
    }
  });
}
