import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_view_state.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_candidate_wall.dart';
import '../../test/helpers/studio_capture_fonts.dart';
import '../../test/presentation/screens/style_explore/explore_candidate_wall_test.dart';

void main() {
  final output = Directory('.dart_tool/uiux-explore-task04/captures');
  setUpAll(() async {
    await loadStudioCaptureFonts();
    output.createSync(recursive: true);
  });
  testWidgets('production filtering, selection and group menu across languages', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final cards =
        jsonDecode(
              File(
                '.dart_tool/uiux-explore-task03/prototype-cards.json',
              ).readAsStringSync(),
            )
            as List;
    for (final scene in ['filters', 'many-groups', 'selected', 'group-menu']) {
      final base = wallFixture();
      final folders = [
        for (var i = 0; i < (scene == 'many-groups' ? 24 : 2); i++)
          ExploreCandidateFolder(
            id: 'f$i',
            name: i == 0
                ? '冷色调'
                : i == 1
                ? '厚涂'
                : 'Group ${i + 1}',
            createdAt: base.createdAt,
          ),
      ];
      final run = base.copyWith(
        folders: folders,
        candidates: [
          for (var i = 0; i < base.candidates.length; i++)
            base.candidates[i].copyWith(
              folderId: i % 4 == 0
                  ? 'f0'
                  : i % 5 == 0
                  ? 'f1'
                  : null,
              generation: base.candidates[i].generation.copyWith(
                filePath:
                    'E:/A.I/NovelAI/.devin/mockups/style-explore/${cards[i]['image']}',
              ),
            ),
        ],
      );
      for (final locale in ['zh', 'en', 'ja', 'ko']) {
        for (final dark in [false, true]) {
          await tester.pumpWidget(const SizedBox.shrink());
          final boundary = GlobalKey();
          await tester.pumpWidget(
            RepaintBoundary(
              key: boundary,
              child: wallFixtureApp(run, dark: dark, locale: locale),
            ),
          );
          await tester.pumpAndSettle();
          final container = ProviderScope.containerOf(
            tester.element(find.byType(ExploreCandidateWall)),
          );
          if (scene == 'selected' || scene == 'group-menu') {
            container.read(exploreSelectionModeProvider.notifier).state = true;
            container.read(exploreSelectionProvider.notifier).selectAll([
              'c9',
              'c10',
              'c11',
              'c12',
            ]);
            await tester.pumpAndSettle();
          }
          if (scene == 'group-menu') {
            await tester.tap(
              find.widgetWithText(
                TextButton,
                tester
                    .element(find.byType(ExploreCandidateWall))
                    .l10n
                    .styleExplore_groupLabel,
              ),
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
                .every((image) => image.image != null))
              break;
          }
          expect(
            tester.takeException(),
            isNull,
            reason: '$scene/$locale/$dark',
          );
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final bytes = await tester.runAsync(() async {
            final image = await render.toImage();
            final data = await image.toByteData(format: ui.ImageByteFormat.png);
            image.dispose();
            return data!;
          });
          File(
            '${output.path}/selection-$scene-$locale-${dark ? 'dark' : 'light'}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
        }
      }
    }
  });
}
