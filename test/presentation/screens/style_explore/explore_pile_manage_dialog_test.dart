import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/data/services/explore_run_image_store.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/screens/style_explore/widgets/explore_pile_manage_dialog.dart';
import 'package:nai_launcher/presentation/widgets/common/themed_confirm_dialog.dart';

/// 替身图库副本存储：记录删图调用、不碰真盘（真实删除行为由
/// explore_run_image_store_test 覆盖；Windows 上 Image.file 会持文件锁）。
class _FakeImageStore extends ExploreRunImageStore {
  _FakeImageStore() : super(rootPathResolver: () async => null);

  final List<String> deleted = [];

  @override
  Future<bool> deleteCandidateImage(String filePath) async {
    deleted.add(filePath);
    return true;
  }

  @override
  Future<void> deleteRunDir(String runId) async {}
}

/// 内存版 Run 存储（避开 Hive 异步写盘在测试里的不落定问题）。
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

/// 经 `show` 打开弹窗的宿主（验证入口与自动收窗需要真 Navigator）。
class _DialogHost extends StatelessWidget {
  const _DialogHost({
    required this.runId,
    required this.familyId,
    required this.parentSetId,
  });

  final String runId;
  final String familyId;
  final String parentSetId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => ExplorePileManageDialog.show(
            context,
            runId: runId,
            familyId: familyId,
            parentSetId: parentSetId,
          ),
          child: const Text('open'),
        ),
      ),
    );
  }
}

void main() {
  late _MemoryRunStorage storage;
  late _FakeImageStore imageStore;
  late Directory tempRoot;
  final l10n = lookupAppLocalizations(const Locale('zh'));

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
  const recipeSnapshot = ExploreRecipeSnapshot(
    positive: PillDocument(text: 'pos', instances: {}),
    negative: PillDocument(text: 'neg', instances: {}),
  );

  setUp(() {
    storage = _MemoryRunStorage();
    imageStore = _FakeImageStore();
    SharedPreferences.setMockInitialValues({});
    tempRoot = Directory.systemTemp.createTempSync('explore_pile_test');
  });

  tearDown(() {
    if (tempRoot.existsSync()) tempRoot.deleteSync(recursive: true);
  });

  ExploreCandidate doneCandidate(
    String id,
    String roundId, {
    String? filePath,
    bool heart = false,
    String? folderId,
  }) {
    return ExploreCandidate(
      id: id,
      roundId: roundId,
      generation: ExploreCandidateGeneration(
        status: ExploreCandidateGenerationStatus.done,
        filePath: filePath,
      ),
      lineage: const ExploreLineage(
        operation: ExploreLineageOperation.mutation,
        generation: 2,
      ),
      review: ExploreCandidateReview(heart: heart),
      folderId: folderId,
    );
  }

  /// 单家族活跃堆：ps-1（gen1，used）产 c-1..c-2；ps-2（gen2，active）
  /// 产 c-3..c-5，轮次状态 generated（分支可建）。
  ExploreRun baseRun() {
    final createdAt = DateTime.utc(2026, 9, 1);
    return ExploreRun(
      id: 'run-1',
      name: '管理弹窗测试',
      status: ExploreRunStatus.generated,
      createdAt: createdAt,
      updatedAt: createdAt,
      targetCount: 3,
      recipeSnapshot: recipeSnapshot,
      paramsSnapshot: paramsSnapshot,
      folders: [
        ExploreCandidateFolder(id: 'f-1', name: '精选', createdAt: createdAt),
      ],
      rounds: [
        ExploreRound(
          id: 'dr-1',
          number: 1,
          phase: ExploreRoundPhase.deep,
          status: ExploreRoundStatus.generated,
          createdAt: createdAt,
          targetCount: 2,
          candidateIds: const ['c-1', 'c-2'],
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
          candidateIds: const ['c-3', 'c-4', 'c-5'],
          familyId: 'fam-1',
          parentSetId: 'ps-2',
          generation: 3,
        ),
      ],
      candidates: [
        doneCandidate('c-1', 'dr-1'),
        doneCandidate('c-2', 'dr-1'),
        doneCandidate('c-3', 'dr-2'),
        doneCandidate('c-4', 'dr-2'),
        doneCandidate('c-5', 'dr-2'),
      ],
      parentSets: const [
        ExploreParentSet(
          id: 'ps-1',
          familyId: 'fam-1',
          generation: 1,
          status: ExploreParentSetStatus.used,
          parents: [ExploreParent(id: 'rp-1', artistString: 'root:a')],
        ),
        ExploreParentSet(
          id: 'ps-2',
          familyId: 'fam-1',
          generation: 2,
          status: ExploreParentSetStatus.active,
          parents: [ExploreParent(id: 'rp-2', artistString: 'mut:seed')],
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

  List<Override> overrides() => [
    styleExploreRunStorageProvider.overrideWithValue(storage),
    exploreRunImageStoreProvider.overrideWithValue(imageStore),
  ];

  Future<void> pumpDialog(
    WidgetTester tester,
    ExploreRun run, {
    String parentSetId = 'ps-2',
  }) async {
    await storage.putRun(run);
    tester.view.physicalSize = const Size(1600, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(),
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _DialogHost(
            runId: run.id,
            familyId: 'fam-1',
            parentSetId: parentSetId,
          ),
        ),
      ),
    );
    await tester.pump();
    // 预热列表 provider：弹窗按 id 解析 run，须在打开前落定
    // （生产里谱系区先加载，按钮点击时必有值；测试里弹窗是首个 watcher）。
    final container = ProviderScope.containerOf(
      tester.element(find.byType(_DialogHost)),
    );
    await container.read(exploreRunListNotifierProvider.future);
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  ExploreRun currentRun() => storage._store['run-1']!;

  ExploreCandidate candidateOf(String id) =>
      currentRun().candidates.firstWhere((c) => c.id == id);

  Finder cardOf(String candidateId) =>
      find.byKey(Key('explore-pile-manage-$candidateId'));

  Finder checkOf(String candidateId) =>
      find.byKey(Key('explore-pile-manage-check-$candidateId'));

  testWidgets('打开弹窗：活跃堆候选最新在前，非活跃堆也有入口语义', (tester) async {
    await pumpDialog(tester, baseRun());

    expect(find.byKey(const Key('explore-pile-manage')), findsOneWidget);
    // ps-2 堆 3 张（c-3..c-5），登记序反转 → c-5 最前。
    expect(
      tester.getTopLeft(cardOf('c-5')).dx,
      lessThan(tester.getTopLeft(cardOf('c-4')).dx),
    );
    expect(
      tester.getTopLeft(cardOf('c-4')).dx,
      lessThan(tester.getTopLeft(cardOf('c-3')).dx),
    );
    // ps-1 的候选不在此堆。
    expect(cardOf('c-1'), findsNothing);
  });

  testWidgets('全选/取消全选：计数与勾选同步', (tester) async {
    await pumpDialog(tester, baseRun());

    await tester.tap(find.byKey(const Key('explore-pile-manage-select-all')));
    await tester.pump();
    expect(find.text(l10n.styleExplore_selectedCount(3)), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNWidgets(3));

    await tester.tap(find.byKey(const Key('explore-pile-manage-deselect-all')));
    await tester.pump();
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('点卡片复选框进入多选；有选择时点卡片切选择而非开详情', (tester) async {
    await pumpDialog(tester, baseRun());

    await tester.tap(checkOf('c-5'));
    await tester.pump();
    expect(find.text(l10n.styleExplore_selectedCount(1)), findsOneWidget);

    // 有选择集：点另一张卡 = 勾选它（不是开详情）。
    await tester.tap(cardOf('c-4'));
    await tester.pump();
    expect(find.text(l10n.styleExplore_selectedCount(2)), findsOneWidget);

    // 再点已选卡 = 取消勾选。
    await tester.tap(cardOf('c-4'));
    await tester.pump();
    expect(find.text(l10n.styleExplore_selectedCount(1)), findsOneWidget);
  });

  testWidgets('批量收藏：全选后一键上心，选择集清空', (tester) async {
    await pumpDialog(tester, baseRun());

    await tester.tap(find.byKey(const Key('explore-pile-manage-select-all')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('explore-pile-manage-heart')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    for (final id in ['c-3', 'c-4', 'c-5']) {
      expect(candidateOf(id).review.heart, isTrue);
    }
    expect(find.byIcon(Icons.check_circle), findsNothing);
    // 每张卡右上挂红心徽标（选择集已清空，按钮回到「收藏」态）。
    expect(find.byIcon(Icons.favorite), findsNWidgets(4));
  });

  testWidgets('批量归类：选中后归入既有文件夹', (tester) async {
    await pumpDialog(tester, baseRun());

    await tester.tap(checkOf('c-5'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('explore-pile-manage-assign')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('精选'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(candidateOf('c-5').folderId, 'f-1');
    expect(candidateOf('c-4').folderId, isNull);
  });

  testWidgets('批量删图：确认后删副本路径并清 filePath，取消不动', (tester) async {
    const pathC5 = r'C:\runs\style_explore_runs\run-1\c-5.png';
    final run = baseRun().copyWith(
      candidates: [
        doneCandidate('c-1', 'dr-1'),
        doneCandidate('c-2', 'dr-1'),
        doneCandidate('c-3', 'dr-2'),
        doneCandidate('c-4', 'dr-2'),
        doneCandidate('c-5', 'dr-2', filePath: pathC5),
      ],
    );
    await pumpDialog(tester, run);

    await tester.tap(checkOf('c-5'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('explore-pile-manage-delete')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 先取消：删图与记录都不动。
    await tester.tap(find.text(l10n.common_cancel));
    await tester.pump();
    expect(imageStore.deleted, isEmpty);
    expect(candidateOf('c-5').generation.filePath, pathC5);

    // 再确认：文件删、filePath 清空、候选记录保留。
    await tester.tap(find.byKey(const Key('explore-pile-manage-delete')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // 动作条按钮与确认框按钮文案相同——锁定确认框内的那个。
    await tester.tap(
      find.descendant(
        of: find.byType(ThemedConfirmDialog),
        matching: find.text(l10n.styleExplore_deleteImage),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(imageStore.deleted, [pathC5]);
    expect(candidateOf('c-5').generation.filePath, isNull);
    expect(
      candidateOf('c-5').generation.status,
      ExploreCandidateGenerationStatus.done,
    );
    // 泵过成功 toast 的自动消失计时（3s），避免测试结束时挂起 Timer。
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('无图候选（filePath 为空）删除钮不启用', (tester) async {
    await pumpDialog(tester, baseRun());

    await tester.tap(find.byKey(const Key('explore-pile-manage-select-all')));
    await tester.pump();
    final button = tester.widget<OutlinedButton>(
      find.byKey(const Key('explore-pile-manage-delete')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('非活跃堆：建分支钮禁用（needLatest 口径）', (tester) async {
    await pumpDialog(tester, baseRun(), parentSetId: 'ps-1');

    await tester.tap(find.byKey(const Key('explore-pile-manage-select-all')));
    await tester.pump();
    final button = tester.widget<OutlinedButton>(
      find.byKey(const Key('explore-pile-manage-branch')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('活跃堆轮次齐：建分支钮随选择启用', (tester) async {
    await pumpDialog(tester, baseRun());

    await tester.tap(checkOf('c-4'));
    await tester.pump();
    final button = tester.widget<OutlinedButton>(
      find.byKey(const Key('explore-pile-manage-branch')),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('空堆：占位文案且全选禁用', (tester) async {
    final createdAt = DateTime.utc(2026, 9, 3);
    final run = baseRun().copyWith(
      rounds: [
        ...baseRun().rounds,
        ExploreRound(
          id: 'dr-9',
          number: 9,
          phase: ExploreRoundPhase.deep,
          status: ExploreRoundStatus.generated,
          createdAt: createdAt,
          targetCount: 0,
          candidateIds: const [],
          familyId: 'fam-1',
          parentSetId: 'ps-9',
          generation: 3,
        ),
      ],
      parentSets: [
        ...baseRun().parentSets,
        const ExploreParentSet(
          id: 'ps-9',
          familyId: 'fam-1',
          generation: 3,
          status: ExploreParentSetStatus.used,
          parents: [ExploreParent(id: 'rp-9', artistString: 'x')],
        ),
      ],
    );
    await pumpDialog(tester, run, parentSetId: 'ps-9');

    expect(find.text(l10n.styleExplore_pileEmpty), findsOneWidget);
    final selectAll = tester.widget<TextButton>(
      find.byKey(const Key('explore-pile-manage-select-all')),
    );
    expect(selectAll.onPressed, isNull);
  });

  testWidgets('run 被删：弹窗自动收窗', (tester) async {
    await pumpDialog(tester, baseRun());
    expect(find.byKey(const Key('explore-pile-manage')), findsOneWidget);

    // 经 notifier 删除（直删 storage 不会触发 provider 重建）。
    final container = ProviderScope.containerOf(
      tester.element(find.byType(_DialogHost)),
    );
    await container
        .read(exploreRunListNotifierProvider.notifier)
        .delete('run-1');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('explore-pile-manage')), findsNothing);
  });

  testWidgets('缺失图候选渲染占位图而非崩溃', (tester) async {
    final run = baseRun().copyWith(
      candidates: [
        doneCandidate('c-1', 'dr-1'),
        doneCandidate('c-2', 'dr-1'),
        doneCandidate('c-3', 'dr-2'),
        doneCandidate('c-4', 'dr-2'),
        // 指向不存在路径：errorBuilder 占位。
        doneCandidate('c-5', 'dr-2', filePath: '${tempRoot.path}/gone.png'),
      ],
    );
    await pumpDialog(tester, run);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byIcon(Icons.broken_image_outlined), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
