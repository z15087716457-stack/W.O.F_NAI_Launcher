import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_lineage_panel.dart';

/// 内存版 Run 存储（testWidgets 的 fakeAsync 区里 Hive 异步写盘不落定）。
class _MemoryRunStorage extends StyleExploreRunStorage {
  final Map<String, ExploreRun> _store = {};

  @override
  Future<List<ExploreRun>> getRuns() async => _store.values.toList();

  @override
  Future<ExploreRun?> getRun(String id) async => _store[id];

  @override
  Future<void> putRun(ExploreRun run) async {
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

  @override
  Future<bool> startDeepRound(
    String runId, {
    required String familyId,
    required String parentSetId,
    required int count,
  }) async {
    calls.add((familyId: familyId, parentSetId: parentSetId, count: count));
    return true;
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
    return ExploreLineagePanel(run: run, onOpenCandidate: opened.add);
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
    double? width,
  }) async {
    await storage.putRun(run);
    // 谱系区高度上限为窗口高的 0.6：拉高窗口让两代卡片全部落在视口内。
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          styleExploreRunStorageProvider.overrideWithValue(storage),
          exploreLineagePanelHeightProvider.overrideWith((ref) => 600.0),
          if (runner != null)
            exploreRunRunnerProvider.overrideWith(() => runner),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: width == null
                ? _PanelHost(runId: run.id, opened: opened)
                : Align(
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  /// 某代候选堆卡的标题文本（计数用堆内候选数，不随选择变）。
  ///
  /// `parentSetGeneration` 传父本集代际号；卡片标题按「父本代 + 1」显示
  /// （见 `_buildPileCard` 的 `parentSet.generation + 1`）。
  Finder pileTitle(int parentSetGeneration, int count) => find.text(
    l10n.styleExplore_candidatePileTitle(parentSetGeneration + 1, count),
  );

  Finder pileCard(int parentSetGeneration, int count) => find
      .ancestor(
        of: pileTitle(parentSetGeneration, count),
        matching: find.byType(Card),
      )
      .first;

  Finder pileThumbs(int parentSetGeneration, int count) => find.descendant(
    of: pileCard(parentSetGeneration, count),
    matching: find.byIcon(Icons.broken_image_outlined),
  );

  Future<void> enterBranchSelection(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('explore-branch-select')));
    await tester.pump();
  }

  testWidgets('两代家族下点活跃堆缩略图：计数与勾选圈同步（BUG-5 回归）', (tester) async {
    await pumpPanel(tester, twoGenerationRun(), []);

    // 建分支入口只在活跃（最新代）堆卡；非活跃堆没有。
    expect(find.byKey(const Key('explore-branch-select')), findsOneWidget);
    // FEAT-44：堆卡的「新增一轮」已删除，生成入口只在活跃父本集卡的按钮行。
    expect(find.byKey(const Key('explore-pile-another-ps-1')), findsNothing);
    expect(find.byKey(const Key('explore-pile-another-ps-2')), findsNothing);
    expect(find.byKey(const Key('explore-deep-round-ps-2')), findsOneWidget);
    expect(find.byKey(const Key('explore-deep-round-ps-1')), findsNothing);

    await enterBranchSelection(tester);
    expect(find.text('${l10n.styleExplore_createBranch} (0)'), findsOneWidget);

    final thumbs = pileThumbs(2, 3);
    expect(thumbs, findsNWidgets(3));

    // 连点两张：计数逐个累加（修复前每次重建被旧代卡片清空，恒 (0)）。
    await tester.tap(thumbs.at(0));
    await tester.pump();
    expect(find.text('${l10n.styleExplore_createBranch} (1)'), findsOneWidget);

    await tester.tap(thumbs.at(1));
    await tester.pump();
    expect(find.text('${l10n.styleExplore_createBranch} (2)'), findsOneWidget);
    expect(
      find.descendant(
        of: pileCard(2, 3),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsNWidgets(2),
    );

    // 再点已选项取消勾选。
    await tester.tap(thumbs.at(0));
    await tester.pump();
    expect(find.text('${l10n.styleExplore_createBranch} (1)'), findsOneWidget);

    // 确认钮随选择启用。
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('explore-branch-confirm')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('分支模式下非活跃堆不显示勾选圈、点击打开详情', (tester) async {
    final opened = <ExploreCandidate>[];
    await pumpPanel(tester, twoGenerationRun(), opened);
    await enterBranchSelection(tester);

    expect(
      find.descendant(
        of: pileCard(1, 3),
        matching: find.byIcon(Icons.radio_button_unchecked),
      ),
      findsNothing,
    );

    await tester.tap(pileThumbs(1, 3).at(0));
    await tester.pump();

    expect(opened.map((candidate) => candidate.id), ['c-1']);
    expect(find.text('${l10n.styleExplore_createBranch} (0)'), findsOneWidget);
    expect(
      find.descendant(
        of: pileCard(1, 3),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsNothing,
    );
  });

  testWidgets('取消分支选择清空计数，切家族同步退出分支模式', (tester) async {
    await pumpPanel(tester, twoFamiliesRun(), []);
    // 默认展示最后一个家族（家族乙，单代）：先验单代家族行为不回归。
    await enterBranchSelection(tester);
    await tester.tap(pileThumbs(1, 2).at(0));
    await tester.pump();
    expect(find.text('${l10n.styleExplore_createBranch} (1)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('explore-branch-cancel')));
    await tester.pump();
    expect(find.byKey(const Key('explore-branch-select')), findsOneWidget);
    expect(find.text('${l10n.styleExplore_createBranch} (1)'), findsNothing);

    // 重新进入分支模式：上一次的选择不残留。
    await enterBranchSelection(tester);
    expect(find.text('${l10n.styleExplore_createBranch} (0)'), findsOneWidget);
    await tester.tap(pileThumbs(1, 2).at(0));
    await tester.pump();
    expect(find.text('${l10n.styleExplore_createBranch} (1)'), findsOneWidget);

    // 切家族：选择清空、退出分支模式。
    await tester.tap(find.byKey(const Key('explore-family-chip-fam-1')));
    await tester.pump();
    expect(find.byKey(const Key('explore-branch-select')), findsOneWidget);
    expect(find.text('${l10n.styleExplore_createBranch} (1)'), findsNothing);
  });

  testWidgets('确认建分支：provider 校验通过，新父本集落入谱系', (tester) async {
    final run = twoGenerationRun();
    await pumpPanel(tester, run, []);
    await enterBranchSelection(tester);

    final thumbs = pileThumbs(2, 3);
    await tester.tap(thumbs.at(0));
    await tester.pump();
    await tester.tap(thumbs.at(1));
    await tester.pump();
    expect(find.text('${l10n.styleExplore_createBranch} (2)'), findsOneWidget);

    await tester.tap(find.byKey(const Key('explore-branch-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // 卡内已有出图数输入框：分支名输入框按弹窗内定位。
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '甲分支',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, l10n.common_confirm));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final stored = (await storage.getRun(run.id))!;
    final newSets = stored.parentSets
        .where((set) => set.generation == 3)
        .toList();
    expect(newSets, hasLength(1));
    expect(newSets.single.branchName, '甲分支');
    // 选中 2 张子代 + 第一代 2 个父本回交。
    expect(newSets.single.parents, hasLength(4));
    expect(
      newSets.single.parents.map((parent) => parent.artistString),
      containsAll(<String>['mut:a', 'mut:b', 'root:a', 'root:b']),
    );
    expect(stored.familyById('fam-1')!.activeParentSetId, newSets.single.id);
    expect(stored.parentSetById('ps-2')!.status, ExploreParentSetStatus.used);

    // 谱系区随之重建：新代父本集卡（活跃 + 分支名）已渲染，分支模式退出。
    expect(find.text(l10n.styleExplore_parentSetTitle(3)), findsOneWidget);
    expect(find.text(l10n.styleExplore_branchLabel('甲分支')), findsOneWidget);
    expect(find.text('${l10n.styleExplore_createBranch} (2)'), findsNothing);

    // 新代候选堆卡在列表尾（懒构建窗口外），滚动到它再断言空堆。
    final generationsScrollable = find
        .ancestor(of: pileTitle(1, 3), matching: find.byType(Scrollable))
        .first;
    await tester.dragUntilVisible(
      pileTitle(3, 0),
      generationsScrollable,
      const Offset(0, -120),
    );
    expect(pileTitle(3, 0), findsOneWidget);
    expect(find.text(l10n.styleExplore_pileEmpty), findsOneWidget);

    // AppToast.success 内部有 3 秒自动关闭定时器，推进到它结束。
    await tester.pump(const Duration(milliseconds: 3300));
  });

  // ==================== FEAT-44：生成候选图 ====================

  Finder countField(String parentSetId) =>
      find.byKey(Key('explore-deep-round-count-$parentSetId'));

  Finder generateButton(String parentSetId) =>
      find.byKey(Key('explore-deep-round-$parentSetId'));

  String countText(WidgetTester tester, String parentSetId) =>
      tester.widget<TextField>(countField(parentSetId)).controller!.text;

  testWidgets('活跃父本卡：出图数默认父本数+1，非活跃集无该行', (tester) async {
    await pumpPanel(tester, twoGenerationRun(), []);

    // 活跃集 ps-2 有 1 个父本 → 默认 2；已用集 ps-1 无生成控件。
    expect(countText(tester, 'ps-2'), '2');
    expect(generateButton('ps-1'), findsNothing);
    expect(countField('ps-1'), findsNothing);
  });

  testWidgets('生成候选图：有效数字直调 startDeepRound，超 50 被 clamp', (tester) async {
    final runner = _RecordingRunner();
    await pumpPanel(tester, twoGenerationRun(), [], runner: runner);

    await tester.enterText(countField('ps-2'), '9');
    await tester.tap(generateButton('ps-2'));
    await tester.pump();

    expect(runner.calls, [(familyId: 'fam-1', parentSetId: 'ps-2', count: 9)]);

    await tester.enterText(countField('ps-2'), '99');
    await tester.tap(generateButton('ps-2'));
    await tester.pump();

    expect(runner.calls.last.count, 50);
  });

  testWidgets('低于父本数：弹「出图数至少 N」且不启动生成', (tester) async {
    final runner = _RecordingRunner();
    await pumpPanel(tester, twoGenerationRun(), [], runner: runner);

    await tester.enterText(countField('ps-2'), '0');
    await tester.tap(generateButton('ps-2'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(runner.calls, isEmpty);
    expect(find.text(l10n.styleExplore_deepRoundCountHint(1)), findsOneWidget);

    // AppToast.warning 的 3 秒自动关闭定时器。
    await tester.pump(const Duration(milliseconds: 3300));
  });

  testWidgets('生成中按钮禁用：只认当前 run 的运行态', (tester) async {
    final runner = _RecordingRunner();
    await pumpPanel(tester, twoGenerationRun(), [], runner: runner);

    FilledButton button() =>
        tester.widget<FilledButton>(generateButton('ps-2'));

    expect(button().onPressed, isNotNull);

    // 别的 run 在跑：不误伤。
    runner.setRunning(runId: 'run-other', isRunning: true);
    await tester.pump();
    expect(button().onPressed, isNotNull);

    runner.setRunning(runId: 'run-1', isRunning: true);
    await tester.pump();
    expect(button().onPressed, isNull);

    // 跑完即复位（不做点击后的局部禁用）。
    runner.setRunning(runId: 'run-1', isRunning: false);
    await tester.pump();
    expect(button().onPressed, isNotNull);
  });

  testWidgets('默认画廊宽 360px：生成钮 + 数字框 + A/B 组对照同排不折行', (tester) async {
    await pumpPanel(tester, twoGenerationRun(), [], width: 360);

    final generate = tester.getCenter(generateButton('ps-2'));
    final field = tester.getCenter(countField('ps-2'));
    final sort = tester.getCenter(
      find.byKey(const Key('explore-sort-parents-ps-2')),
    );

    expect(field.dy, closeTo(generate.dy, 1));
    expect(sort.dy, closeTo(generate.dy, 1));
    expect(generate.dx, lessThan(field.dx));
    expect(field.dx, lessThan(sort.dx));
  });
}
