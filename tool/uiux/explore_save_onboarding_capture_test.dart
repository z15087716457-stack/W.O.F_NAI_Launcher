import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_adopt_block_dialog.dart';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_onboarding.dart';
import '../../test/helpers/studio_capture_fonts.dart';
import '../../test/presentation/screens/style_explore/explore_adopt_block_dialog_test.dart';
import '../../test/presentation/screens/style_explore/explore_candidate_wall_test.dart';
import '../../test/presentation/screens/style_explore/explore_random_variables_module_test.dart'
    show variableFixtureLibrary;
import 'explore_dialogs_capture_test.dart' show dialogCaptureFixture;

void main() {
  final output = Directory('.dart_tool/uiux-explore-task09/captures');
  setUpAll(() async {
    await loadStudioCaptureFonts();
    output.createSync(recursive: true);
  });
  testWidgets('save and onboarding production widgets with real fonts', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1600, 1000);
    addTearDown(tester.view.reset);
    final geometry = <String, Object>{};
    final candidates = [
      for (final c in dialogCaptureFixture().candidates.take(3))
        c.copyWith(
          rollSnapshot: c.rollSnapshot!.copyWith(
            positive: '${c.rollSnapshot!.positive}, scenery, year 2025',
            instanceRolls: [
              ExploreInstanceRoll(
                lane: 'pos',
                marker: 'draw',
                blockId: 'pool',
                blockTitle: '画师池',
                rolledText: c.rollSnapshot!.positive,
              ),
            ],
          ),
        ),
    ];
    for (final scene in [
      'single',
      'multi',
      'removed',
      'full',
      'no-blocks',
      'blocks',
    ]) {
      for (final locale in ['zh', 'en', 'ja', 'ko']) {
        for (final dark in [false, true]) {
          await tester.pumpWidget(const SizedBox.shrink());
          final boundary = GlobalKey();
          final onboarding = scene == 'no-blocks' || scene == 'blocks';
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundary,
              child: onboarding
                  ? wallFixtureApp(
                      wallFixture(count: 0),
                      locale: locale,
                      dark: dark,
                      child: ExploreOnboardingView(
                        blocks: scene == 'blocks'
                            ? variableFixtureLibrary().blocks.take(2).toList()
                            : const [],
                        count: 10,
                        generating: false,
                        hasPrevious: true,
                        onOpenLibrary: () {},
                        onGenerate: () async {},
                        onOpenPrevious: () {},
                      ),
                    )
                  : saveDialogApp(
                      scene == 'single' ? [candidates.first] : candidates,
                      locale: locale,
                      dark: dark,
                    ),
            ),
          );
          await tester.pumpAndSettle();
          if (!onboarding) {
            await tester.tap(find.byKey(const Key('open-save')));
            await tester.pumpAndSettle();
            if (scene == 'removed') {
              await tester.tap(
                find.byKey(
                  ValueKey(
                    'explore-adopt-remove-${exploreAdoptArtists(candidates).first}',
                  ),
                ),
              );
              await tester.pumpAndSettle();
            }
            if (scene == 'full') {
              await tester.tap(find.byKey(const Key('explore-adopt-full')));
              await tester.pumpAndSettle();
            }
          }
          for (var i = 0; i < 20; i++) {
            await tester.runAsync(
              () async =>
                  Future<void>.delayed(const Duration(milliseconds: 50)),
            );
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
            final Rect rect;
            if (onboarding) {
              final first = tester.getRect(
                    find.byKey(const Key('explore-onboarding-step-1')),
                  ),
                  last = tester.getRect(
                    find.byKey(const Key('explore-onboarding-step-3')),
                  );
              rect = Rect.fromLTRB(
                first.left - 24,
                first.top - 170,
                last.right + 24,
                last.bottom + 65,
              );
            } else {
              rect = tester.getRect(
                find
                    .descendant(
                      of: find.byType(Dialog),
                      matching: find.byType(Material),
                    )
                    .first,
              );
            }
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
      '.dart_tool/uiux-explore-task09/geometry.json',
    ).writeAsStringSync(jsonEncode(geometry));
  });
}
