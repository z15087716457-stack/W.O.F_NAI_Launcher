import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_candidate_card.dart';
import '../../test/helpers/studio_capture_fonts.dart';
import '../../test/presentation/screens/style_explore/explore_candidate_wall_test.dart';

void main() {
  setUpAll(loadStudioCaptureFonts);
  testWidgets('same 198 wide prototype card with matching image and snapshot', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(206, 337);
    addTearDown(tester.view.reset);
    final fixture = wallFixture(count: 4);
    final candidate = fixture.candidates.first.copyWith(
      folderId: 'cool',
      generation: fixture.candidates.first.generation.copyWith(
        filePath: 'E:/A.I/NovelAI/.devin/mockups/style-explore/assets/u1.jpg',
      ),
      rollSnapshot: const ExploreRollSnapshot(
        positive: 'artist:ciloranko',
        negative: '',
        instanceRolls: [
          ExploreInstanceRoll(
            lane: 'pos',
            marker: 'a',
            blockId: 'favorite',
            blockTitle: '收藏艺术家池',
            rolledText: '0.6::artist:ciloranko::',
          ),
        ],
      ),
    );
    final run = fixture.copyWith(
      candidates: [candidate],
      folders: [
        ExploreCandidateFolder(
          id: 'cool',
          name: '冷色调',
          createdAt: fixture.createdAt,
        ),
      ],
    );
    for (final dark in [false, true]) {
      final boundary = GlobalKey();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        wallFixtureApp(
          run,
          width: 206,
          dark: dark,
          captureKey: boundary,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: ExploreCandidateCard(
              run: run,
              candidate: candidate,
              sequenceNumber: 27,
              focused: true,
              generating: false,
              onFocus: () {},
              onOpenDetail: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (var attempt = 0; attempt < 20; attempt++) {
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        });
        await tester.pumpAndSettle();
        if (tester.renderObject<RenderImage>(find.byType(RawImage)).image !=
            null) {
          break;
        }
      }
      expect(
        tester.renderObject<RenderImage>(find.byType(RawImage)).image,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
      final render =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final image = await render.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        return data!;
      });
      File(
        '.dart_tool/uiux-explore-task03/compare/implementation-card-${dark ? 'dark' : 'light'}.png',
      ).writeAsBytesSync(bytes!.buffer.asUint8List());
    }
  });
}
