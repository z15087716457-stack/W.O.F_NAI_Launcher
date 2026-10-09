import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/data/services/explore_run_image_store.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_view_state.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_candidate_detail_dialog.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_highlighted_prompt.dart';
import 'package:nai_launcher/presentation/widgets/common/image_detail/components/viewer_stage.dart';
import 'explore_candidate_wall_test.dart';
import 'explore_inspector_test.dart';

class ViewerImages extends ExploreRunImageStore {
  ViewerImages() : super(rootPathResolver: () async => null);
  final deleted = <String>[];
  @override
  Future<bool> deleteCandidateImage(String filePath) async {
    deleted.add(filePath);
    return true;
  }
}

Widget viewerFixtureApp(
  ExploreRun run, {
  List<String> ids = const ['c1', 'c2', 'c3'],
  int index = 0,
  ViewerImages? images,
  String locale = 'zh',
  bool dark = false,
}) => wallFixtureApp(
  run,
  locale: locale,
  dark: dark,
  width: 1280,
  extraOverrides: [
    promptBlockLibraryNotifierProvider.overrideWith(InspectorBlocks.new),
    if (images != null) exploreRunImageStoreProvider.overrideWithValue(images),
  ],
  child: Builder(
    builder: (context) => TextButton(
      key: const Key('open-viewer'),
      onPressed: () => ExploreCandidateDetailDialog.show(
        context,
        runId: run.id,
        candidateIds: ids,
        initialIndex: index,
      ),
      child: const Text('Open'),
    ),
  ),
);

void main() {
  test(
    'highlight matches weighted raw text and safely ignores rewritten or empty draws',
    () {
      const snapshot = ExploreRollSnapshot(
        positive: 'a, 0.6::artist:ciloranko::, b',
        negative: '',
        instanceRolls: [
          ExploreInstanceRoll(
            lane: 'pos',
            marker: 'a',
            blockId: 'pool',
            blockTitle: 'Pool',
            rolledText: '0.6::artist:ciloranko::',
          ),
          ExploreInstanceRoll(
            lane: 'pos',
            marker: 'b',
            blockId: 'favorite',
            blockTitle: 'Other',
            rolledText: 'no longer present',
          ),
          ExploreInstanceRoll(
            lane: 'pos',
            marker: 'c',
            blockId: 'pool',
            blockTitle: 'Empty',
            rolledText: '',
          ),
        ],
      );
      expect(explorePromptMatches(snapshot), [
        (
          start: 3,
          end: 3 + snapshot.instanceRolls.first.rolledText.length,
          blockId: 'pool',
        ),
      ]);
    },
  );
  testWidgets(
    'filtered sequence, page bounds, favorite, grouping override, fit and close focus',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        viewerFixtureApp(inspectorFixture(), ids: ['c1', 'c3'], index: 1),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(const Key('open-viewer'))),
      );
      await tester.tap(find.byKey(const Key('open-viewer')));
      await tester.pumpAndSettle();
      expect(tester.widget<ViewerStage>(find.byType(ViewerStage)).itemCount, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(
        tester.widget<ViewerStage>(find.byType(ViewerStage)).currentIndex,
        1,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.pumpAndSettle();
      expect(
        container
            .read(exploreActiveRunProvider)!
            .candidateById('c3')!
            .review
            .heart,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.pumpAndSettle();
      expect(
        container.read(exploreActiveRunProvider)!.candidateById('c3')!.folderId,
        'f1',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
      await tester.pumpAndSettle();
      expect(
        container.read(exploreActiveRunProvider)!.candidateById('c3')!.folderId,
        isNull,
      );
      await tester.tap(find.byKey(const Key('viewer-zoom-in')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<InteractiveViewer>(find.byType(InteractiveViewer).first)
            .transformationController!
            .value
            .getMaxScaleOnAxis(),
        greaterThan(1),
      );
      await tester.tap(find.byKey(const Key('viewer-fit')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<InteractiveViewer>(find.byType(InteractiveViewer).first)
            .transformationController!
            .value
            .getMaxScaleOnAxis(),
        1,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(
        tester.widget<ViewerStage>(find.byType(ViewerStage)).currentIndex,
        0,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(ViewerStage), findsNothing);
      expect(container.read(exploreFocusedCandidateIdProvider), 'c1');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Delete keeps existing file deletion, advances and closes on final candidate',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final base = inspectorFixture(), images = ViewerImages();
      final run = base.copyWith(
        candidates: [
          for (final c in base.candidates)
            c.copyWith(
              generation: c.generation.copyWith(
                filePath:
                    'E:/A.I/NovelAI/.devin/mockups/style-explore/assets/u1.jpg',
              ),
            ),
        ],
      );
      await tester.pumpWidget(
        viewerFixtureApp(run, ids: ['c1', 'c2'], images: images),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('open-viewer')));
      await tester.pumpAndSettle();
      for (var i = 0; i < 2; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.delete);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, '删除图片'));
        await tester.pumpAndSettle();
      }
      expect(images.deleted, hasLength(2));
      expect(find.byType(ViewerStage), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
