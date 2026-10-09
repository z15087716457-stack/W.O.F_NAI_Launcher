import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_candidate_wall.dart';
import '../../test/helpers/studio_capture_fonts.dart';
import '../../test/presentation/screens/style_explore/explore_candidate_wall_test.dart';

void main() {
  final output = Directory('.dart_tool/uiux-explore-task03/captures');
  setUpAll(() async {
    await loadStudioCaptureFonts();
    output.createSync(recursive: true);
  });
  testWidgets(
    'production wall with prototype materials, real fonts and responsive states',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final cards =
          jsonDecode(
                File(
                  '.dart_tool/uiux-explore-task03/prototype-cards.json',
                ).readAsStringSync(),
              )
              as List;
      for (final scene in ['idle', 'runner', 'manual', 'failed', 'empty']) {
        for (final width in [640, 900, 1200]) {
          for (final large in [true, false]) {
            for (final locale in ['zh', 'en', 'ja', 'ko']) {
              for (final dark in [false, true]) {
                tester.view.physicalSize = Size(width.toDouble(), 900);
                await tester.pumpWidget(const SizedBox.shrink());
                final boundary = GlobalKey();
                final fixture = wallFixture(scene: scene);
                final run = fixture.copyWith(
                  candidates: [
                    for (var i = 0; i < fixture.candidates.length; i++)
                      fixture.candidates[i].copyWith(
                        generation: fixture.candidates[i].generation.copyWith(
                          filePath:
                              'E:/A.I/NovelAI/.devin/mockups/style-explore/${cards[i]['image']}',
                        ),
                        rollSnapshot: ExploreRollSnapshot(
                          positive: 'scenery, artist:ciloranko',
                          negative: 'lowres',
                          instanceRolls: [
                            ExploreInstanceRoll(
                              lane: 'pos',
                              marker: 'a',
                              blockId: 'pool',
                              blockTitle: '400精选画师池',
                              rolledText:
                                  cards[i]['atoms'].join(', ') as String,
                            ),
                          ],
                        ),
                        review: ExploreCandidateReview(
                          heart: cards[i]['hearted'] as bool,
                        ),
                      ),
                  ],
                );
                await tester.pumpWidget(
                  wallFixtureApp(
                    run,
                    width: width.toDouble(),
                    large: large,
                    locale: locale,
                    dark: dark,
                    scene: scene,
                    captureKey: boundary,
                  ),
                );
                await tester.pumpAndSettle();
                if (scene == 'empty') {
                  final container = ProviderScope.containerOf(
                    tester.element(find.byType(ExploreCandidateWall)),
                  );
                  container.read(exploreGalleryFilterProvider.notifier).state =
                      const ExploreGalleryFilterFolder('absent');
                  await tester.pumpAndSettle();
                }
                // Image.file resolves through real asynchronous file IO.
                for (var attempt = 0; attempt < 20; attempt++) {
                  await tester.runAsync(() async {
                    await Future<void>.delayed(
                      const Duration(milliseconds: 50),
                    );
                  });
                  await tester.pumpAndSettle();
                  final rendered = tester.renderObjectList<RenderImage>(
                    find.byType(RawImage),
                  );
                  if (rendered.every((image) => image.image != null)) break;
                }
                expect(
                  tester
                      .renderObjectList<RenderImage>(find.byType(RawImage))
                      .every((image) => image.image != null),
                  isTrue,
                );
                expect(
                  tester.takeException(),
                  isNull,
                  reason: '$scene/$width/$large/$locale/$dark',
                );
                final render =
                    boundary.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary;
                final bytes = await tester.runAsync(() async {
                  final image = await render.toImage(pixelRatio: 1);
                  final data = await image.toByteData(
                    format: ui.ImageByteFormat.png,
                  );
                  image.dispose();
                  return data!;
                });
                File(
                  '${output.path}/wall-$scene-$width-${large ? 'large' : 'small'}-$locale-${dark ? 'dark' : 'light'}.png',
                ).writeAsBytesSync(bytes!.buffer.asUint8List());
              }
            }
          }
        }
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
