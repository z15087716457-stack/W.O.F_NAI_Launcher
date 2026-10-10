import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_view_state.dart';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_artist_text.dart';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_candidate_card.dart';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_folder_assign_bar.dart';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_inspector.dart';
import 'explore_candidate_wall_test.dart';

class InspectorBlocks extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async {
    final now = DateTime(2026, 10, 9);
    return PromptBlockLibraryState(
      blocks: [
        PromptBlock(
          id: 'pool',
          title: '400精选画师池',
          content: '',
          color: '#ec4899',
          createdAt: now,
          updatedAt: now,
        ),
        PromptBlock(
          id: 'favorite',
          title: '收藏艺术家池',
          content: '',
          color: '#3b82f6',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      folders: [],
    );
  }
}

ExploreRun inspectorFixture({String scene = 'single'}) {
  final base = wallFixture(
    count: 12,
    scene: scene == 'pending' ? 'runner' : scene,
  );
  return base.copyWith(
    paramsSnapshot: base.paramsSnapshot.copyWith(model: 'nai-diffusion-5-full'),
    folders: [
      ExploreCandidateFolder(id: 'f0', name: '冷色调', createdAt: base.createdAt),
      ExploreCandidateFolder(id: 'f1', name: '厚涂', createdAt: base.createdAt),
    ],
    candidates: [
      for (var i = 0; i < base.candidates.length; i++)
        base.candidates[i].copyWith(
          folderId: i == 0 ? 'f0' : null,
          generation: base.candidates[i].generation.copyWith(
            seed: 3274348526,
            elapsedMs: 14800,
          ),
          rollSnapshot: i == 0
              ? const ExploreRollSnapshot(
                  positive: 'scenery, 0.6::artist:ciloranko::',
                  negative: 'lowres',
                  instanceRolls: [
                    ExploreInstanceRoll(
                      lane: 'pos',
                      marker: 'a',
                      blockId: 'pool',
                      blockTitle: '400精选画师池',
                      rolledText: '',
                    ),
                    ExploreInstanceRoll(
                      lane: 'pos',
                      marker: 'b',
                      blockId: 'favorite',
                      blockTitle: '收藏艺术家池',
                      rolledText: '0.6::artist:ciloranko::',
                    ),
                  ],
                )
              : base.candidates[i].rollSnapshot,
        ),
    ],
  );
}

Widget inspectorFixtureApp(
  ExploreRun run, {
  String scene = 'single',
  double width = 312,
  String locale = 'zh',
  bool dark = false,
  Key? captureKey,
}) => wallFixtureApp(
  run,
  width: width,
  locale: locale,
  dark: dark,
  captureKey: captureKey,
  scene: scene == 'pending' ? 'runner' : scene,
  child: const ExploreInspector(),
  extraOverrides: [
    promptBlockLibraryNotifierProvider.overrideWith(InspectorBlocks.new),
  ],
);

Future<ProviderContainer> focusInspector(
  WidgetTester tester,
  ExploreRun run, {
  String? focus = 'c1',
  String scene = 'single',
  double width = 312,
}) async {
  await tester.pumpWidget(inspectorFixtureApp(run, width: width, scene: scene));
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(ExploreInspector)),
  );
  container.read(exploreFocusedCandidateIdProvider.notifier).state = focus;
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets(
    'group hint reaches the content edge and parameters use intrinsic label width',
    (tester) async {
      await focusInspector(tester, inspectorFixture());
      await tester.ensureVisible(find.byType(ExploreFolderAssignBar));
      expect(tester.getTopRight(find.text('按 1–9 快速归组')).dx, 298);
      expect(
        tester.getTopLeft(find.text('3274348526')).dx -
            tester.getTopLeft(find.text('种子')).dx,
        36,
      );
      expect(
        tester
            .getSize(find.byKey(const Key('explore-assign-folder-f0')))
            .height,
        26,
      );
      expect(find.text('新分组'), findsOneWidget);
    },
  );
  test('merged atoms deduplicate the raw text, preserve order and weights', () {
    final c = wallFixture(count: 1).candidates.first;
    final other = c.copyWith(
      id: 'other',
      rollSnapshot: const ExploreRollSnapshot(
        positive: '',
        negative: '',
        instanceRolls: [
          ExploreInstanceRoll(
            lane: 'neg',
            marker: 'b',
            blockId: 'favorite',
            blockTitle: 'Favorite',
            rolledText: 'artist:kantoku, 1.4::artist:wanke::',
          ),
        ],
      ),
    );
    expect(exploreMergedArtistAtoms([c, other]), [
      '0.8::artist:wanke::',
      'artist:kantoku',
      '1.2::artist:quasarcake::',
      '1.4::artist:wanke::',
    ]);
    expect(parseExploreArtistAtom('1.4::artist:wanke::'), (
      weight: '1.4',
      text: 'wanke',
    ));
  });
  testWidgets(
    'single uses snapshot block order, empty draw and copies raw weighted text',
    (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await focusInspector(tester, inspectorFixture());
      expect(
        find.byKey(const ValueKey('explore-inspector-roll-pos-a')),
        findsOneWidget,
      );
      expect(
        tester
            .getTopLeft(
              find.byKey(const ValueKey('explore-inspector-roll-pos-a')),
            )
            .dy,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(const ValueKey('explore-inspector-roll-pos-b')),
              )
              .dy,
        ),
      );
      expect(find.text('这次没有抽中（池里有空项）'), findsOneWidget);
      expect(find.text('0.6'), findsOneWidget);
      expect(find.text('ciloranko'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const Key('explore-inspector-copy-artists')),
      );
      await tester.tap(find.byKey(const Key('explore-inspector-copy-artists')));
      await tester.pump();
      expect(copied, '0.6::artist:ciloranko::');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'heart and group toggle share notifier; paging follows visible round order',
    (tester) async {
      final run = inspectorFixture();
      final container = await focusInspector(tester, run);
      await tester.ensureVisible(
        find.byKey(const Key('explore-inspector-heart')),
      );
      await tester.tap(find.byKey(const Key('explore-inspector-heart')));
      await tester.pumpAndSettle();
      expect(
        container
            .read(exploreActiveRunProvider)!
            .candidateById('c1')!
            .review
            .heart,
        isFalse,
      );
      final group = find.byKey(const Key('explore-assign-folder-f0'));
      await tester.ensureVisible(group);
      await tester.tap(group);
      await tester.pumpAndSettle();
      expect(tester.widget<ExploreGroupChip>(group).selected, isFalse);
      await tester.tap(group);
      await tester.pumpAndSettle();
      expect(tester.widget<ExploreGroupChip>(group).selected, isTrue);
      await tester.tap(group);
      await tester.pumpAndSettle();
      expect(
        container.read(exploreActiveRunProvider)!.candidateById('c1')!.folderId,
        isNull,
      );
      await tester.ensureVisible(
        find.byKey(const Key('explore-inspector-image-chevR')),
      );
      await tester.tap(find.byKey(const Key('explore-inspector-image-chevR')));
      await tester.pumpAndSettle();
      expect(container.read(exploreFocusedCandidateIdProvider), 'c2');
      expect(tester.getTopLeft(find.byType(ExploreCandidateImage)).dy, 64);
      await tester.tap(find.byKey(const Key('explore-inspector-image-chevL')));
      await tester.pumpAndSettle();
      expect(container.read(exploreFocusedCandidateIdProvider), 'c1');
    },
  );
  testWidgets(
    'multi displays eight images, remainder and exact deduplicated chips',
    (tester) async {
      final run = inspectorFixture();
      final container = await focusInspector(tester, run);
      container.read(exploreSelectionModeProvider.notifier).state = true;
      container
          .read(exploreSelectionProvider.notifier)
          .selectAll(run.candidates.map((c) => c.id));
      await tester.pumpAndSettle();
      expect(find.byType(ExploreCandidateImage), findsNWidgets(8));
      expect(find.text('+4'), findsOneWidget);
      await tester.ensureVisible(find.text('合在一起的画师（去重）'));
      expect(find.byType(ExploreArtistChip), findsNWidgets(4));
      expect(find.byKey(const Key('explore-inspector-delete')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'pending, failed and empty states hide completed-only operations',
    (tester) async {
      for (final scene in ['pending', 'failed', 'empty']) {
        await tester.pumpWidget(const SizedBox.shrink());
        await focusInspector(
          tester,
          inspectorFixture(scene: scene),
          focus: scene == 'empty' ? null : 'c11',
          scene: scene,
        );
        expect(find.byKey(const Key('explore-inspector-heart')), findsNothing);
        expect(
          find.text(
            scene == 'empty'
                ? '选一张候选查看详情'
                : scene == 'pending'
                ? '生成完成后显示'
                : 'fixture failure',
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'confirmed deletion of image-less completed candidate moves focus within round',
    (tester) async {
      final container = await focusInspector(tester, inspectorFixture());
      await tester.tap(find.byKey(const Key('explore-inspector-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, '删除'));
      await tester.pumpAndSettle();
      expect(
        container.read(exploreActiveRunProvider)!.candidateById('c1'),
        isNull,
      );
      expect(container.read(exploreFocusedCandidateIdProvider), 'c2');
    },
  );
}
