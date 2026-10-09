import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_manual_capture.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_view_state.dart';
import 'package:nai_launcher/presentation/providers/layout_state_provider.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_candidate_card.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_candidate_wall.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';

ExploreRun wallFixture({
  String id = 'wall',
  int count = 12,
  String scene = 'idle',
}) {
  final now = DateTime(2026, 10, 9, 18, 54);
  final candidates = [
    for (var i = 1; i <= count; i++)
      ExploreCandidate(
        id: 'c$i',
        roundId: 'r${((i - 1) / 4).floor() + 1}',
        generation: ExploreCandidateGeneration(
          status: scene == 'failed' && i == count - 1
              ? ExploreCandidateGenerationStatus.failed
              : (scene == 'runner' || scene == 'manual') && i > count - 2
              ? ExploreCandidateGenerationStatus.pending
              : ExploreCandidateGenerationStatus.done,
          error: scene == 'failed' && i == count - 1 ? 'fixture failure' : null,
        ),
        rollSnapshot: const ExploreRollSnapshot(
          positive: 'scenery, artist:ciloranko',
          negative: 'lowres',
          instanceRolls: [
            ExploreInstanceRoll(
              lane: 'pos',
              marker: 'a',
              blockId: 'pool',
              blockTitle: '400精选画师池',
              rolledText: '0.8::artist:wanke::, artist:kantoku',
            ),
            ExploreInstanceRoll(
              lane: 'pos',
              marker: 'b',
              blockId: 'favorite',
              blockTitle: '收藏艺术家池',
              rolledText: '1.2::artist:quasarcake::',
            ),
          ],
        ),
        review: ExploreCandidateReview(heart: i == 1 || i == count),
        lineage: const ExploreLineage(
          operation: ExploreLineageOperation.manual,
        ),
      ),
  ];
  return ExploreRun(
    id: id,
    name: '柔光画风 · 400 池',
    status: ExploreRunStatus.generated,
    createdAt: now,
    updatedAt: now,
    targetCount: count,
    recipeSnapshot: ExploreRecipeSnapshot(
      positive: PillDocument.empty(),
      negative: PillDocument.empty(),
    ),
    paramsSnapshot: const ExploreParamsSnapshot(
      model: 'nai-diffusion-5',
      width: 832,
      height: 1216,
      steps: 28,
      scale: 5,
      sampler: 'k_euler_ancestral',
      seed: -1,
      ucPreset: 0,
      qualityToggle: true,
      smea: false,
      smeaDyn: false,
      cfgRescale: 0,
      noiseSchedule: 'karras',
      varietyPlus: false,
      decrisp: false,
    ),
    rounds: [
      for (var i = 1; i <= (count / 4).ceil(); i++)
        ExploreRound(
          id: 'r$i',
          number: i,
          phase: ExploreRoundPhase.manual,
          status: scene == 'runner' && i == (count / 4).ceil()
              ? ExploreRoundStatus.generating
              : ExploreRoundStatus.generated,
          createdAt: now.subtract(Duration(minutes: (3 - i) * 20)),
          targetCount: 4,
          candidateIds: [
            for (final c in candidates)
              if (c.roundId == 'r$i') c.id,
          ],
        ),
    ],
    candidates: candidates,
  );
}

class WallRunList extends ExploreRunListNotifier {
  WallRunList(this.runs);
  List<ExploreRun> runs;
  @override
  Future<ExploreRunListState> build() async => ExploreRunListState(runs: runs);
  @override
  Future<ExploreRun> overwrite(ExploreRun run) async {
    runs = [
      for (final previous in runs) previous.id == run.id ? run : previous,
    ];
    state = AsyncData(ExploreRunListState(runs: runs));
    return run;
  }

  @override
  Future<ExploreRun> updateReview(
    String runId,
    String candidateId, {
    bool? heart,
  }) {
    final run = runs.firstWhere((r) => r.id == runId);
    return overwrite(
      run.copyWith(
        candidates: [
          for (final c in run.candidates)
            c.id == candidateId
                ? c.copyWith(
                    review: c.review.copyWith(heart: heart ?? c.review.heart),
                  )
                : c,
        ],
      ),
    );
  }

  @override
  Future<ExploreRun> assignCandidateFolder(
    String runId,
    String candidateId,
    String? folderId,
  ) => assignCandidatesFolder(runId, [candidateId], folderId);

  @override
  Future<ExploreRun> assignCandidatesFolder(
    String runId,
    List<String> candidateIds,
    String? folderId,
  ) {
    final run = runs.firstWhere((r) => r.id == runId);
    return overwrite(
      run.copyWith(
        candidates: [
          for (final c in run.candidates)
            candidateIds.contains(c.id) ? c.copyWith(folderId: folderId) : c,
        ],
      ),
    );
  }

  @override
  Future<ExploreRun> removeCandidates(String runId, List<String> candidateIds) {
    final run = runs.firstWhere((r) => r.id == runId);
    return overwrite(
      run.copyWith(
        candidates: run.candidates
            .where((c) => !candidateIds.contains(c.id))
            .toList(),
        rounds: [
          for (final r in run.rounds)
            r.copyWith(
              candidateIds: r.candidateIds
                  .where((id) => !candidateIds.contains(id))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class WallRunner extends ExploreRunRunner {
  WallRunner(this.initial);
  final ExploreRunRunnerState initial;
  @override
  ExploreRunRunnerState build() => initial;
}

class WallManual extends ExploreManualCaptureNotifier {
  WallManual(this.initial);
  final ExploreManualCaptureState initial;
  @override
  ExploreManualCaptureState build() => initial;
}

class WallStorage extends LocalStorageService {
  WallStorage([this.large = true]);
  bool large;
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      key == 'style_explore_grid_large' ? large as T : defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    if (key == 'style_explore_grid_large') large = value as bool;
  }
}

Widget wallFixtureApp(
  ExploreRun run, {
  String scene = 'idle',
  bool dark = false,
  String locale = 'zh',
  double width = 900,
  Key? captureKey,
  bool large = true,
  Widget? child,
  List<Override> extraOverrides = const [],
}) => ProviderScope(
  overrides: [
    exploreRunListNotifierProvider.overrideWith(() => WallRunList([run])),
    exploreActiveRunIdProvider.overrideWith((ref) => run.id),
    localStorageServiceProvider.overrideWith((ref) => WallStorage(large)),
    exploreRunRunnerProvider.overrideWith(
      () => WallRunner(
        ExploreRunRunnerState(runId: run.id, isRunning: scene == 'runner'),
      ),
    ),
    exploreManualCaptureProvider.overrideWith(
      () => WallManual(
        ExploreManualCaptureState(
          armed: scene == 'manual',
          runId: run.id,
          candidateIds: run.candidates.map((c) => c.id).toList(),
        ),
      ),
    ),
    ...extraOverrides,
  ],
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: dark ? GeistTheme.dark : GeistTheme.light,
    locale: Locale(locale),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: true),
      child: child!,
    ),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: RepaintBoundary(
          key: captureKey,
          child: ColoredBox(
            color: (dark ? GeistTheme.dark : GeistTheme.light)
                .scaffoldBackgroundColor,
            child: SizedBox(
              width: width,
              child: child ?? const ExploreCandidateWall(),
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  test(
    'atom display separates weights and keeps both original roll blocks',
    () {
      final candidate = wallFixture().candidates.first;
      expect(exploreCandidateArtistAtoms(candidate), [
        (weight: '0.8', text: 'wanke'),
        (weight: null, text: 'kantoku'),
        (weight: '1.2', text: 'quasarcake'),
      ]);
      expect(
        candidate.rollSnapshot!.instanceRolls.first.rolledText,
        '0.8::artist:wanke::, artist:kantoku',
      );
      expect(
        exploreCandidateArtistAtoms(
          candidate.copyWith(
            rollSnapshot: const ExploreRollSnapshot(
              positive: 'artist:legacy',
              negative: '',
            ),
          ),
        ).single.text,
        'artist:legacy',
      );
      expect(
        exploreCandidateArtistAtoms(candidate.copyWith(rollSnapshot: null)),
        isEmpty,
      );
    },
  );
  test(
    'three rounds retain their stored order internally, newest round first',
    () {
      final run = wallFixture();
      expect(
        exploreWallCandidates(
          run,
          const ExploreGalleryFilterAll(),
        ).map((c) => c.id),
        [
          'c9',
          'c10',
          'c11',
          'c12',
          'c5',
          'c6',
          'c7',
          'c8',
          'c1',
          'c2',
          'c3',
          'c4',
        ],
      );
      expect(
        exploreWallCandidates(
          run,
          const ExploreGalleryFilterAll(),
          newestFirst: false,
        ).first.id,
        'c1',
      );
    },
  );
  test(
    'deleting focus picks next then previous candidate of the same round',
    () {
      final run = wallFixture();
      ExploreRun without(List<String> ids) => run.copyWith(
        candidates: run.candidates.where((c) => !ids.contains(c.id)).toList(),
      );
      expect(focusAfterCandidateDeletion(run, without(['c2']), 'c2'), 'c3');
      expect(focusAfterCandidateDeletion(run, without(['c4']), 'c4'), 'c3');
      expect(
        focusAfterCandidateDeletion(
          run,
          without(['c1', 'c2', 'c3', 'c4']),
          'c2',
        ),
        isNull,
      );
    },
  );
  testWidgets(
    'single click focuses, heart preserves focus, double click opens detail',
    (tester) async {
      final run = wallFixture(count: 4);
      await tester.pumpWidget(wallFixtureApp(run));
      await tester.pumpAndSettle();
      final wall = find.byType(ExploreCandidateWall);
      final container = ProviderScope.containerOf(tester.element(wall));
      await tester.tap(find.byKey(const Key('explore-candidate-c2')));
      await tester.pump(const Duration(milliseconds: 350));
      expect(container.read(exploreFocusedCandidateIdProvider), 'c2');
      await tester.tap(find.byKey(const Key('explore-candidate-heart-c1')));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(container.read(exploreFocusedCandidateIdProvider), 'c2');
      expect(
        container
            .read(exploreActiveRunProvider)!
            .candidateById('c1')!
            .review
            .heart,
        isFalse,
      );
      final target = find.byKey(const Key('explore-candidate-c2'));
      await tester.tap(target);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('explore-candidate-detail')), findsOneWidget);
    },
  );
  for (final scene in ['runner', 'manual', 'failed']) {
    testWidgets('$scene status is scoped to the actual pending slot', (
      tester,
    ) async {
      await tester.pumpWidget(
        wallFixtureApp(wallFixture(count: 4, scene: scene), scene: scene),
      );
      await tester.pumpAndSettle();
      if (scene == 'failed') {
        expect(find.text('生成失败'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (w) => w is Tooltip && w.message == 'fixture failure',
          ),
          findsOneWidget,
        );
      } else {
        expect(find.text('生成中 #3'), findsOneWidget);
        expect(find.text('排队 #4'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'favorite filter hides empty rounds; candidate size changes columns',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(wallFixtureApp(wallFixture()));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ExploreCandidateWall)),
      );
      final first = tester.getTopLeft(
        find.byKey(const Key('explore-candidate-c9')),
      );
      final fourth = tester.getTopLeft(
        find.byKey(const Key('explore-candidate-c12')),
      );
      expect(first.dy, fourth.dy);
      final largeCardWidth = tester
          .getSize(find.byKey(const Key('explore-candidate-c9')))
          .width;
      container
          .read(layoutStateNotifierProvider.notifier)
          .setStyleExploreGridLarge(false);
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const Key('explore-candidate-c9'))).width,
        lessThan(largeCardWidth),
      );
      container.read(exploreGalleryFilterProvider.notifier).state =
          const ExploreGalleryFilterHearted();
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('explore-round-r2')), findsNothing);
      expect(find.text('图片已删除'), findsNWidgets(2));
    },
  );
  testWidgets('switching exploration resets focus, round order and tab', (
    tester,
  ) async {
    await tester.pumpWidget(wallFixtureApp(wallFixture(count: 4)));
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ExploreCandidateWall)),
    );
    container.read(exploreFocusedCandidateIdProvider.notifier).state = 'c2';
    container.read(exploreRoundOrderNewestFirstProvider.notifier).state = false;
    container.read(exploreStageTabProvider.notifier).state =
        ExploreStageTab.evolution;
    container.read(exploreActiveRunIdProvider.notifier).state = 'other';
    await tester.pumpAndSettle();
    expect(container.read(exploreFocusedCandidateIdProvider), isNull);
    expect(container.read(exploreRoundOrderNewestFirstProvider), isTrue);
    expect(container.read(exploreStageTabProvider), ExploreStageTab.candidates);
  });
  testWidgets('deep round identifies evolution line and operation', (
    tester,
  ) async {
    final run = wallFixture(count: 4);
    final deep = run.copyWith(
      rounds: [
        run.rounds.single.copyWith(
          phase: ExploreRoundPhase.deep,
          familyId: 'f',
          generation: 3,
        ),
      ],
      families: [
        ExploreFamily(
          id: 'f',
          name: '冷光',
          createdAt: run.createdAt,
          rootParentSetId: 'p',
          activeParentSetId: 'p',
        ),
      ],
      candidates: [
        for (final c in run.candidates)
          c.copyWith(
            lineage: const ExploreLineage(
              operation: ExploreLineageOperation.mutation,
            ),
          ),
      ],
    );
    await tester.pumpWidget(wallFixtureApp(deep));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('进化 · 冷光 第 3 代', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('变异'), findsNWidgets(4));
    expect(tester.takeException(), isNull);
  });
}
