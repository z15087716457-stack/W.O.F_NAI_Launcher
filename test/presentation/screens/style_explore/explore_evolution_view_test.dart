import 'package:flutter/gestures.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'explore_inspector_test.dart' show InspectorBlocks;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_candidate_wall.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_view_state.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_lineage_info.dart';

/// 内存版 Run 存储（testWidgets 的 fakeAsync 区里 Hive 异步写盘不落定）。
class _MemoryRunStorage extends StyleExploreRunStorage {
  final Map<String, ExploreRun> _store = {};

  @override
  Future<List<ExploreRun>> getRuns() async => _store.values.toList();

  @override
  Future<ExploreRun?> getRun(String id) async => _store[id];

  @override
  Future<void> putRun(ExploreRun run, {void Function()? beforeWrite}) async {
    beforeWrite?.call();
    _store[run.id] = run;
  }

  @override
  Future<void> deleteRun(String id) async {
    _store.remove(id);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }
}

/// 记录深度轮调用参数的 runner 替身（不跑真实生成链）。
class _RecordingRunner extends ExploreRunRunner {
  final List<({String familyId, String parentSetId, int count})> calls = [];
  ExploreDeepRoundRejection? rejection;
  bool accepts = true;

  @override
  Future<bool> startDeepRound(
    String runId, {
    required String familyId,
    required String parentSetId,
    required int count,
    void Function(ImageParams)? beforeGenerate,
  }) async {
    calls.add((familyId: familyId, parentSetId: parentSetId, count: count));
    if (rejection case final reason?) throw ExploreDeepRoundException(reason);
    return accepts;
  }

  void setRunning({String? runId, required bool isRunning}) {
    state = ExploreRunRunnerState(runId: runId, isRunning: isRunning);
  }
}

/// 跟随 provider 的宿主：建分支后以新 run 重建谱系区（与候选画廊同源用法）。
class _PanelHost extends ConsumerWidget {
  const _PanelHost({required this.runId, required this.opened});

  final String runId;
  final List<ExploreCandidate> opened;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final run = ref
        .watch(exploreRunListNotifierProvider)
        .valueOrNull
        ?.runById(runId);
    if (run == null) return const SizedBox.shrink();
    return const ExploreCandidateWall();
  }
}

void main() {
  late _MemoryRunStorage storage;
  final l10n = lookupAppLocalizations(const Locale('zh'));

  const recipeSnapshot = ExploreRecipeSnapshot(
    positive: PillDocument(text: 'pos', instances: {}),
    negative: PillDocument(text: 'neg', instances: {}),
  );
  const paramsSnapshot = ExploreParamsSnapshot(
    model: 'nai-diffusion-4-5-full',
    width: 832,
    height: 1216,
    steps: 28,
    scale: 5.0,
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
  );

  setUp(() {
    storage = _MemoryRunStorage();
  });

  ExploreCandidate doneCandidate(
    String id,
    String roundId, {
    required int generation,
    required String mutatedText,
  }) {
    return ExploreCandidate(
      id: id,
      roundId: roundId,
      generation: const ExploreCandidateGeneration(
        status: ExploreCandidateGenerationStatus.done,
      ),
      lineage: ExploreLineage(
        operation: ExploreLineageOperation.mutation,
        generation: generation,
        mutatedText: mutatedText,
      ),
    );
  }

  /// 两代家族：ps-1（gen1 根）产 c-1..c-3，ps-2（gen2 活跃）产 c-4..c-6。
  ExploreRun twoGenerationRun() {
    final createdAt = DateTime.utc(2026, 9, 1);
    return ExploreRun(
      id: 'run-1',
      name: '两代家族',
      status: ExploreRunStatus.generated,
      createdAt: createdAt,
      updatedAt: createdAt,
      targetCount: 3,
      recipeSnapshot: recipeSnapshot,
      paramsSnapshot: paramsSnapshot,
      rounds: [
        ExploreRound(
          id: 'dr-1',
          number: 1,
          phase: ExploreRoundPhase.deep,
          status: ExploreRoundStatus.generated,
          createdAt: createdAt,
          targetCount: 3,
          candidateIds: const ['c-1', 'c-2', 'c-3'],
          familyId: 'fam-1',
          parentSetId: 'ps-1',
          generation: 2,
        ),
        ExploreRound(
          id: 'dr-2',
          number: 2,
          phase: ExploreRoundPhase.deep,
          status: ExploreRoundStatus.generated,
          createdAt: createdAt,
          targetCount: 3,
          candidateIds: const ['c-4', 'c-5', 'c-6'],
          familyId: 'fam-1',
          parentSetId: 'ps-2',
          generation: 3,
        ),
      ],
      candidates: [
        doneCandidate('c-1', 'dr-1', generation: 2, mutatedText: 'anc:a'),
        doneCandidate('c-2', 'dr-1', generation: 2, mutatedText: 'anc:b'),
        doneCandidate('c-3', 'dr-1', generation: 2, mutatedText: 'anc:c'),
        doneCandidate('c-4', 'dr-2', generation: 3, mutatedText: 'mut:a'),
        doneCandidate('c-5', 'dr-2', generation: 3, mutatedText: 'mut:b'),
        doneCandidate('c-6', 'dr-2', generation: 3, mutatedText: 'mut:c'),
      ],
      parentSets: const [
        ExploreParentSet(
          id: 'ps-1',
          familyId: 'fam-1',
          generation: 1,
          status: ExploreParentSetStatus.used,
          parents: [
            ExploreParent(id: 'rp-1', artistString: 'root:a'),
            ExploreParent(id: 'rp-2', artistString: 'root:b'),
          ],
        ),
        ExploreParentSet(
          id: 'ps-2',
          familyId: 'fam-1',
          generation: 2,
          status: ExploreParentSetStatus.active,
          parents: [ExploreParent(id: 'rp-3', artistString: 'mut:seed')],
        ),
      ],
      families: [
        ExploreFamily(
          id: 'fam-1',
          name: '家族甲',
          createdAt: createdAt,
          rootParentSetId: 'ps-1',
          activeParentSetId: 'ps-2',
        ),
      ],
    );
  }

  /// 两代家族 + 单代家族乙（切家族清空选择用）。
  ExploreRun twoFamiliesRun() {
    final base = twoGenerationRun();
    final createdAt = DateTime.utc(2026, 9, 2);
    return base.copyWith(
      rounds: [
        ...base.rounds,
        ExploreRound(
          id: 'dr-3',
          number: 3,
          phase: ExploreRoundPhase.deep,
          status: ExploreRoundStatus.generated,
          createdAt: createdAt,
          targetCount: 2,
          candidateIds: const ['c-7', 'c-8'],
          familyId: 'fam-2',
          parentSetId: 'ps-3',
          generation: 2,
        ),
      ],
      candidates: [
        ...base.candidates,
        doneCandidate('c-7', 'dr-3', generation: 2, mutatedText: 'b1:a'),
        doneCandidate('c-8', 'dr-3', generation: 2, mutatedText: 'b1:b'),
      ],
      parentSets: [
        ...base.parentSets,
        const ExploreParentSet(
          id: 'ps-3',
          familyId: 'fam-2',
          generation: 1,
          status: ExploreParentSetStatus.active,
          parents: [ExploreParent(id: 'rp-4', artistString: 'b:root')],
        ),
      ],
      families: [
        ...base.families,
        ExploreFamily(
          id: 'fam-2',
          name: '家族乙',
          createdAt: createdAt,
          rootParentSetId: 'ps-3',
          activeParentSetId: 'ps-3',
        ),
      ],
    );
  }

  Future<void> pumpPanel(
    WidgetTester tester,
    ExploreRun run,
    List<ExploreCandidate> opened, {
    _RecordingRunner? runner,
    double width = 1000,
  }) async {
    await storage.putRun(run);
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          styleExploreRunStorageProvider.overrideWithValue(storage),
          promptBlockLibraryNotifierProvider.overrideWith(InspectorBlocks.new),
          exploreActiveRunIdProvider.overrideWith((ref) => run.id),
          exploreActiveFamilyIdProvider.overrideWith(
            (ref) => run.families.firstOrNull?.id,
          ),
          exploreStageTabProvider.overrideWith(
            (ref) => ExploreStageTab.evolution,
          ),
          if (runner != null)
            exploreRunRunnerProvider.overrideWith(() => runner),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: _PanelHost(runId: run.id, opened: opened),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(_PanelHost)));
  Finder countField(String id) =>
      find.byKey(Key('explore-deep-round-count-$id'));
  Finder generateButton(String id) => find.byKey(Key('explore-deep-round-$id'));
  Future<void> choose(WidgetTester tester, String id) async {
    container(tester).read(exploreSelectionModeProvider.notifier).state = true;
    await tester.pump();
    await tester.tap(find.byKey(Key('explore-candidate-select-$id')));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(container(tester).read(exploreSelectionProvider), contains(id));
  }

  testWidgets('最新代展开、旧代64高，旧代展开只读', (tester) async {
    await pumpPanel(tester, twoGenerationRun(), []);
    expect(find.byKey(const Key('explore-generation-ps-2')), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const Key('explore-generation-collapsed-ps-1')))
          .height,
      64,
    );
    await tester.tap(find.byKey(const Key('explore-generation-expand-ps-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('explore-generation-ps-1')), findsOneWidget);
    expect(generateButton('ps-1'), findsNothing);
    expect(find.byKey(const Key('explore-breed-ps-1')), findsNothing);
    expect(generateButton('ps-2'), findsOneWidget);
  });
  testWidgets('切进化线清选择，切页签清选择；多选收藏和归组沿用', (tester) async {
    var run = twoFamiliesRun();
    run = run.copyWith(
      folders: [
        ExploreCandidateFolder(
          id: 'group',
          name: '冷色调',
          createdAt: DateTime(2026, 10, 9),
        ),
      ],
    );
    await pumpPanel(tester, run, []);
    await choose(tester, 'c-4');
    expect(find.text(l10n.styleExplore_breedNext), findsOneWidget);
    await tester.tap(find.byKey(const Key('explore-selection-heart')));
    await tester.pump();
    expect(
      (await storage.getRun(run.id))!.candidateById('c-4')!.review.heart,
      true,
    );
    await tester.tap(find.text(l10n.styleExplore_groupLabel).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('冷色调'));
    await tester.pumpAndSettle();
    expect(
      (await storage.getRun(run.id))!.candidateById('c-4')!.folderId,
      'group',
    );
    await tester.tap(find.byKey(const Key('explore-family-chip-fam-2')));
    await tester.pumpAndSettle();
    expect(container(tester).read(exploreSelectionProvider), isEmpty);
    await choose(tester, 'c-7');
    await tester.tap(find.byKey(const Key('explore-tab-candidates')));
    await tester.pumpAndSettle();
    expect(container(tester).read(exploreSelectionProvider), isEmpty);
  });
  testWidgets('名称允许留空，建分支带上第一代父本', (tester) async {
    await pumpPanel(tester, twoGenerationRun(), []);
    await choose(tester, 'c-4');
    await tester.tap(find.byKey(const Key('explore-breed-ps-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('explore-branch-confirm')));
    await tester.pumpAndSettle();
    final run = (await storage.getRun('run-1'))!, f = run.families.first;
    final next = run.parentSetById(f.activeParentSetId)!;
    expect(next.generation, 3);
    expect(next.branchName, isNull);
    expect(next.parents.map((p) => p.artistString), [
      'mut:a',
      'root:a',
      'root:b',
    ]);
    await tester.pump(const Duration(milliseconds: 3300));
  });
  testWidgets('重复串拒绝提示，确认后生成状态变化也重新校验', (tester) async {
    var run = twoGenerationRun();
    run = run.copyWith(
      candidates: [
        for (final c in run.candidates)
          c.id == 'c-4'
              ? c.copyWith(lineage: c.lineage.copyWith(mutatedText: 'root:a'))
              : c,
      ],
    );
    await pumpPanel(tester, run, []);
    await choose(tester, 'c-4');
    await tester.tap(find.byKey(const Key('explore-breed-ps-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('explore-branch-confirm')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.styleExplore_branchDuplicate), findsOneWidget);
    expect((await storage.getRun('run-1'))!.parentSets.length, 2);
    await tester.pump(const Duration(milliseconds: 3300));
    await tester.tap(find.byKey(const Key('explore-breed-ps-2')));
    await tester.pumpAndSettle();
    await container(tester)
        .read(exploreRunListNotifierProvider.notifier)
        .overwrite(
          run.copyWith(
            rounds: [
              for (final r in run.rounds)
                r.id == 'dr-2'
                    ? r.copyWith(status: ExploreRoundStatus.generating)
                    : r,
            ],
          ),
        );
    await tester.tap(find.byKey(const Key('explore-branch-confirm')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.styleExplore_branchRoundsIncomplete), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 3300));
  });
  testWidgets('0张或本代生成中时培育禁用', (tester) async {
    final run = twoGenerationRun();
    await pumpPanel(tester, run, []);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('explore-breed-ps-2')))
          .onPressed,
      isNull,
    );
    await choose(tester, 'c-4');
    await container(tester)
        .read(exploreRunListNotifierProvider.notifier)
        .overwrite(
          run.copyWith(
            rounds: [
              for (final r in run.rounds)
                r.id == 'dr-2'
                    ? r.copyWith(status: ExploreRoundStatus.generating)
                    : r,
            ],
          ),
        );
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('explore-breed-ps-2')))
          .onPressed,
      isNull,
    );
    expect(find.text(l10n.styleExplore_generationBusy), findsOneWidget);
  });
  testWidgets('深度轮默认父本数+1、上下限、当前run忙时禁用', (tester) async {
    final runner = _RecordingRunner();
    await pumpPanel(tester, twoGenerationRun(), [], runner: runner);
    expect(tester.widget<TextField>(countField('ps-2')).controller!.text, '2');
    await tester.enterText(countField('ps-2'), '99');
    await tester.tap(generateButton('ps-2'));
    await tester.pump();
    expect(runner.calls.last.count, 50);
    await tester.enterText(countField('ps-2'), '0');
    await tester.tap(generateButton('ps-2'));
    await tester.pump();
    expect(runner.calls.length, 1);
    expect(find.text(l10n.styleExplore_deepRoundCountHint(1)), findsOneWidget);
    runner.setRunning(runId: 'run-1', isRunning: true);
    await tester.pump();
    expect(
      tester.widget<GestureDetector>(generateButton('ps-2')).onTap,
      isNull,
    );
    runner.setRunning(runId: 'other', isRunning: true);
    await tester.pump();
    expect(
      tester.widget<GestureDetector>(generateButton('ps-2')).onTap,
      isNotNull,
    );
    await tester.pump(const Duration(milliseconds: 3300));
  });
  ExploreRun runWithActiveParents(int count) {
    final run = twoGenerationRun();
    return run.copyWith(
      parentSets: [
        run.parentSets.first,
        run.parentSets.last.copyWith(
          parents: [
            for (var i = 0; i < count; i++)
              ExploreParent(id: 'p$i', artistString: 'artist:$i'),
          ],
        ),
      ],
    );
  }

  testWidgets('深度轮拒绝原因和忙碌返回映射到提示', (tester) async {
    final runner = _RecordingRunner();
    await pumpPanel(tester, twoGenerationRun(), [], runner: runner);
    for (final reason in ExploreDeepRoundRejection.values) {
      runner.rejection = reason;
      await tester.tap(generateButton('ps-2'));
      await tester.pumpAndSettle();
      final text = switch (reason) {
        ExploreDeepRoundRejection.noRandomInstance =>
          l10n.styleExplore_deepRoundNoInstance,
        ExploreDeepRoundRejection.mutationEmpty =>
          l10n.styleExplore_deepRoundEmpty,
        _ => l10n.styleExplore_operationFailed,
      };
      expect(find.text(text), findsWidgets);
      await tester.pump(const Duration(milliseconds: 3300));
    }
    runner.rejection = null;
    runner.accepts = false;
    await tester.tap(generateButton('ps-2'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.styleExplore_runBusy), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 3300));
  });
  testWidgets('父本超过50时上下界不倒置；不足2个不能比较', (tester) async {
    final runner = _RecordingRunner();
    await pumpPanel(tester, runWithActiveParents(55), [], runner: runner);
    await tester.enterText(countField('ps-2'), '99');
    await tester.tap(generateButton('ps-2'));
    await tester.pump();
    expect(runner.calls.single.count, 55);
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpPanel(tester, twoGenerationRun(), []);
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('explore-sort-parents-ps-2')),
          )
          .onPressed,
      isNull,
    );
  });
  testWidgets('删除进化线确认；在途拒删', (tester) async {
    var run = twoGenerationRun();
    run = run.copyWith(
      rounds: [
        for (final r in run.rounds)
          r.id == 'dr-2'
              ? r.copyWith(status: ExploreRoundStatus.generating)
              : r,
      ],
    );
    await pumpPanel(tester, run, []);
    await tester.tap(
      find.byKey(const Key('explore-family-chip-fam-1')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('explore-family-menu-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.common_delete).last);
    await tester.pumpAndSettle();
    expect(find.text(l10n.styleExplore_familyBusy), findsOneWidget);
    expect((await storage.getRun(run.id))!.families.length, 1);
    await tester.pump(const Duration(milliseconds: 3300));
    await container(tester)
        .read(exploreRunListNotifierProvider.notifier)
        .overwrite(twoGenerationRun());
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('explore-family-chip-fam-1')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('explore-family-menu-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.common_delete).last);
    await tester.pumpAndSettle();
    expect((await storage.getRun(run.id))!.families, isEmpty);
  });
  testWidgets('空状态去候选开启多选且提示缺少随机实例', (tester) async {
    final run = twoGenerationRun().copyWith(families: [], parentSets: []);
    await pumpPanel(tester, run, []);
    expect(find.text(l10n.styleExplore_variablesEmpty), findsOneWidget);
    await tester.tap(find.byKey(const Key('explore-evolution-pick')));
    await tester.pumpAndSettle();
    expect(
      container(tester).read(exploreStageTabProvider),
      ExploreStageTab.candidates,
    );
    expect(container(tester).read(exploreSelectionModeProvider), true);
  });
  test('来源的新原子只标父本中没有的原文', () {
    final run = twoGenerationRun();
    final c = run.candidates.last.copyWith(
      lineage: run.candidates.last.lineage.copyWith(
        parentCandidateIds: ['c-1'],
        mutatedText: 'anc:a, artist:new',
      ),
    );
    expect(exploreNewLineageAtoms(run, c), ['artist:new']);
  });
  testWidgets('偏好排序双击连点不重计分', (tester) async {
    await pumpPanel(tester, runWithActiveParents(2), []);
    await tester.tap(find.byKey(const Key('explore-sort-parents-ps-2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const Key('explore-preference-sort-dialog')),
      findsOneWidget,
    );
    // 单配对场景连续两击：第二击在作答在飞期间被吞。
    await tester.tap(find.byKey(const Key('explore-sort-left')));
    await tester.tap(find.byKey(const Key('explore-sort-left')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final stored = (await storage.getRun('run-1'))!;
    final comparisons = stored.parentSetById('ps-2')!.comparisons;
    expect(comparisons, hasLength(1));
    expect(comparisons.single.result, ExploreComparisonResult.left);

    // AppToast.success 的 3 秒自动关闭定时器。
    await tester.pump(const Duration(milliseconds: 3300));
  });

  testWidgets('开窗期间 run 被删：作答提示失败并收窗，不推进配对', (tester) async {
    await pumpPanel(tester, runWithActiveParents(3), []);
    await tester.tap(find.byKey(const Key('explore-sort-parents-ps-2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await storage.deleteRun('run-1');
    await tester.pump();

    await tester.tap(find.byKey(const Key('explore-sort-left')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const Key('explore-preference-sort-dialog')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    // AppToast.error 的 3 秒自动关闭定时器。
    await tester.pump(const Duration(milliseconds: 3300));
  });
}
