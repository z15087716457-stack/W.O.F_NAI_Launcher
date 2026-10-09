import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_preference_sort_dialog.dart';
import '../../test/helpers/studio_capture_fonts.dart';
import '../../test/presentation/screens/style_explore/explore_candidate_wall_test.dart';
import '../../test/presentation/screens/style_explore/explore_start_evolution_dialog_test.dart';

ExploreRun dialogCaptureFixture({bool custom = false}) {
  final cards =
      jsonDecode(
            File(
              '.dart_tool/uiux-explore-task03/prototype-cards.json',
            ).readAsStringSync(),
          )
          as List;
  final base = wallFixture(count: 5), indexes = [0, 2, 3, 6, 5];
  final candidates = [
    for (var i = 0; i < 5; i++)
      base.candidates[i].copyWith(
        generation: base.candidates[i].generation.copyWith(
          filePath:
              'E:/A.I/NovelAI/.devin/mockups/style-explore/${cards[indexes[i]]['image']}',
        ),
        rollSnapshot: ExploreRollSnapshot(
          positive: (cards[indexes[i]]['atoms'] as List).join(', '),
          negative: '',
        ),
      ),
  ];
  final set = ExploreParentSet(
    id: 'set',
    familyId: 'line',
    generation: 3,
    status: ExploreParentSetStatus.active,
    parents: [
      for (final i in [0, 2, 4, 3, 1])
        ExploreParent(
          id: 'p$i',
          sourceCandidateId: custom ? null : candidates[i].id,
          artistString: candidates[i].rollSnapshot!.positive,
          preference: [3.0, 2.0, 1.0, 1.0, .75][[0, 2, 4, 3, 1].indexOf(i)],
        ),
    ],
  );
  return base.copyWith(
    candidates: candidates,
    parentSets: [set],
    families: [
      ExploreFamily(
        id: 'line',
        name: '冷色支线',
        createdAt: base.createdAt,
        rootParentSetId: set.id,
        activeParentSetId: set.id,
      ),
    ],
  );
}

void main() {
  final output = Directory('.dart_tool/uiux-explore-task08/captures');
  setUpAll(() async {
    await loadStudioCaptureFonts();
    output.createSync(recursive: true);
  });
  testWidgets('evolution and pair-comparison production dialogs, real fonts', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final geometry = <String, Object>{};
    for (final scene in [
      'new',
      'join',
      'no-target',
      'compare',
      'custom',
      'narrow',
    ]) {
      final compare = ['compare', 'custom', 'narrow'].contains(scene),
          width = scene == 'narrow' ? 1100 : 1600;
      tester.view.physicalSize = Size(width.toDouble(), 1000);
      for (final locale in ['zh', 'en', 'ja', 'ko']) {
        for (final dark in [false, true]) {
          await tester.pumpWidget(const SizedBox.shrink());
          final run = dialogCaptureFixture(custom: scene == 'custom'),
              boundary = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundary,
              child: evolutionDialogApp(
                EvolutionDialogStorage(run),
                EvolutionDialogRunner(),
                target: scene != 'no-target',
                locale: locale,
                dark: dark,
                dialog: compare
                    ? ExplorePreferenceSortDialog(
                        runId: run.id,
                        parentSet: run.parentSets.single,
                      )
                    : null,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('open-evolution')));
          await tester.pumpAndSettle();
          if (scene == 'join') {
            await tester.tap(
              find.byKey(const Key('explore-evolution-mode-join')),
            );
            await tester.pumpAndSettle();
          }
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
            reason: '$scene/$locale/$dark',
          );
          if (locale == 'zh' && !dark) {
            final dialog = find.byType(Dialog),
                rect = tester.getRect(
                  find
                      .descendant(of: dialog, matching: find.byType(Material))
                      .first,
                );
            geometry[scene] = {
              'x': rect.left,
              'y': rect.top,
              'width': rect.width,
              'height': rect.height,
            };
          }
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final data = await tester.runAsync(() async {
            final image = await render.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            image.dispose();
            return data!;
          });
          File(
            '${output.path}/$scene-$locale-${dark ? 'dark' : 'light'}.png',
          ).writeAsBytesSync(data!.buffer.asUint8List());
        }
      }
    }
    File(
      '.dart_tool/uiux-explore-task08/geometry.json',
    ).writeAsStringSync(jsonEncode(geometry));
  });
}
