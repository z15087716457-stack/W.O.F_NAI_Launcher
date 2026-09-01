import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/style_explore_recipe_storage.dart';
import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/data/models/style_explore/style_explore_recipe.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_cooldown_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';
import 'package:nai_launcher/presentation/providers/style_explore_provider.dart';
import 'package:nai_launcher/presentation/screens/style_explore/style_explore_screen.dart';

/// 内存版 Recipe 存储。
///
/// testWidgets 的 fakeAsync 区里 Hive 的异步写盘永不完成，
/// 因此 widget 测试不落盘，只验证 UI 与 provider 协作。
class _MemoryRecipeStorage extends StyleExploreRecipeStorage {
  final Map<String, StyleExploreRecipe> _store = {};

  @override
  Future<List<StyleExploreRecipe>> getRecipes() async {
    final recipes = _store.values.toList()
      ..sort((a, b) {
        final comparison = b.updatedAt.compareTo(a.updatedAt);
        if (comparison != 0) return comparison;
        return a.id.compareTo(b.id);
      });
    return recipes;
  }

  @override
  Future<StyleExploreRecipe?> getRecipe(String id) async => _store[id];

  @override
  Future<void> putRecipe(StyleExploreRecipe recipe) async {
    _store[recipe.id] = recipe;
  }

  @override
  Future<void> deleteRecipe(String id) async {
    _store.remove(id);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }
}

/// 内存版 Run 存储（同上，不落盘）。
class _MemoryRunStorage extends StyleExploreRunStorage {
  final Map<String, ExploreRun> _store = {};

  @override
  Future<List<ExploreRun>> getRuns() async {
    final runs = _store.values.toList()
      ..sort((a, b) {
        final comparison = b.updatedAt.compareTo(a.updatedAt);
        if (comparison != 0) return comparison;
        return a.id.compareTo(b.id);
      });
    return runs;
  }

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

class _TestLocalStorageService extends LocalStorageService {
  @override
  bool getEnablePromptWeightScroll() => false;

  @override
  bool getEnableAutocomplete() => false;

  @override
  bool getAutoFormatPrompt() => false;

  @override
  bool getHighlightEmphasis() => false;

  @override
  bool getSdSyntaxAutoConvert() => false;

  @override
  String getLastPrompt() => '';

  @override
  String getLastNegativePrompt() => '';

  @override
  String getDefaultModel() => 'nai-diffusion-4-5-full';

  @override
  String getDefaultSampler() => 'k_euler_ancestral';

  @override
  int getDefaultSteps() => 28;

  @override
  double getDefaultScale() => 5.0;

  @override
  int getDefaultWidth() => 832;

  @override
  int getDefaultHeight() => 1216;

  @override
  bool getLastSmea() => false;

  @override
  bool getLastSmeaDyn() => false;

  @override
  double getLastCfgRescale() => 0.0;

  @override
  String getLastNoiseSchedule() => 'native';

  @override
  bool getLastVarietyPlus() => false;

  @override
  bool getSeedLocked() => false;

  @override
  int? getLockedSeedValue() => null;
}

class _FakeLibraryNotifier extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: const [], folders: const []);
}

/// 冷却永不生效的假实现（真实现会读 Hive 设置，widget 测试不准备）。
class _FakeCooldownNotifier extends GenerationCooldownNotifier {
  @override
  GenerationCooldownState build() => const GenerationCooldownState();
}

void main() {
  late _MemoryRecipeStorage recipeStorage;
  late _MemoryRunStorage runStorage;

  setUp(() {
    recipeStorage = _MemoryRecipeStorage();
    runStorage = _MemoryRunStorage();
  });

  PillDocument doc(String text) =>
      PillDocument(text: text, instances: const {});

  ExploreParamsSnapshot testSnapshot() => const ExploreParamsSnapshot(
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

  Future<StyleExploreRecipe> seedRecipe(String name, String positive) async {
    final recipe = StyleExploreRecipe.create(
      name: name,
      positiveDocument: doc(positive),
      negativeDocument: doc('lowres'),
    );
    await recipeStorage.putRecipe(recipe);
    return recipe;
  }

  Future<ExploreRun> seedRun(
    String name, {
    int targetCount = 10,
    ExploreRunStatus status = ExploreRunStatus.draft,
    List<ExploreCandidate> candidates = const [],
  }) async {
    final run = ExploreRun.create(
      name: name,
      recipeSnapshot: ExploreRecipeSnapshot(
        positive: doc('pos'),
        negative: doc('neg'),
      ),
      paramsSnapshot: testSnapshot(),
      targetCount: targetCount,
    ).copyWith(status: status, candidates: candidates);
    await runStorage.putRun(run);
    return run;
  }

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWith(
          (ref) => _TestLocalStorageService(),
        ),
        styleExploreRecipeStorageProvider.overrideWithValue(recipeStorage),
        styleExploreRunStorageProvider.overrideWithValue(runStorage),
        promptBlockLibraryNotifierProvider.overrideWith(
          () => _FakeLibraryNotifier(),
        ),
        generationCooldownProvider.overrideWith(() => _FakeCooldownNotifier()),
        exploreGenerateFnProvider.overrideWithValue((params) async => null),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StyleExploreScreen(),
      ),
    );
  }

  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    // 宽窗：左栏 + 右栏画廊都展开（画廊默认断点 1100）。
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  }

  testWidgets('renders sidebar placeholders, toolbar, and both lane editors', (
    tester,
  ) async {
    await seedRecipe('柔和光影', 'soft lighting');
    await seedRecipe('厚重色彩', 'vivid colors');
    final container = await pumpScreen(tester);

    // 左栏：探索任务列表（空态）+ Recipe 缩略列表。
    expect(find.text('柔和光影'), findsOneWidget);
    expect(find.text('厚重色彩'), findsOneWidget);
    expect(find.byKey(const Key('style-explore-new-run')), findsOneWidget);
    expect(
      find.byKey(const Key('style-explore-recipe-manager')),
      findsOneWidget,
    );
    // 顶栏按钮。
    expect(find.byKey(const Key('style-explore-save')), findsOneWidget);
    expect(find.byKey(const Key('style-explore-save-as')), findsOneWidget);
    expect(find.byKey(const Key('style-explore-preview')), findsOneWidget);
    expect(
      find.byKey(const Key('style-explore-gallery-toggle')),
      findsOneWidget,
    );
    // 中栏两个药丸编辑器。
    expect(
      find.byKey(const Key('style-explore-positive-editor')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('style-explore-negative-editor')),
      findsOneWidget,
    );
    // 右栏候选画廊（宽窗默认展开）。
    expect(
      find.byKey(const Key('style-explore-gallery-panel')),
      findsOneWidget,
    );
    expect(find.text('未关联配方'), findsOneWidget);
    expect(
      container.read(styleExploreSessionNotifierProvider).activeRecipeId,
      isNull,
    );
  });

  testWidgets(
    'tapping a recipe in the sidebar preview loads it into the pill lanes',
    (tester) async {
      final recipe = await seedRecipe('载入目标', 'loaded content');
      final container = await pumpScreen(tester);

      await tester.tap(find.text('载入目标'));
      await tester.pump();
      // AppToast.success 内部有 3 秒自动关闭定时器，推进到它结束。
      await tester.pump(const Duration(milliseconds: 3300));

      expect(
        container
            .read(pillWorkspaceProvider(PillScopes.explorePos))
            .document
            .text,
        'loaded content',
      );
      expect(
        container.read(styleExploreSessionNotifierProvider).activeRecipeId,
        recipe.id,
      );
    },
  );

  testWidgets('editing in the explore page does not touch the main lane', (
    tester,
  ) async {
    final container = await pumpScreen(tester);

    final textField = find.descendant(
      of: find.byKey(const Key('style-explore-positive-editor')),
      matching: find.byType(TextField),
    );
    await tester.enterText(textField.first, '探索页输入');
    await tester.pump();

    expect(
      container
          .read(pillWorkspaceProvider(PillScopes.explorePos))
          .document
          .text,
      '探索页输入',
    );
    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
      '',
    );
  });

  testWidgets('preview dialog shows pill projections without titles', (
    tester,
  ) async {
    await seedRecipe('预览配方', 'preview, content');
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('style-explore-preview')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Prompt 预览'), findsOneWidget);
    expect(find.text('负向'), findsWidgets);
    // 正负两路均为空文档，各显示一个占位。
    expect(find.text('（空）'), findsNWidgets(2));
    expect(
      find.byKey(const Key('style-explore-preview-copy-positive')),
      findsOneWidget,
    );
  });

  testWidgets('recipe manager dialog reuses the full list panel', (
    tester,
  ) async {
    await seedRecipe('管理目标', 'managed content');
    final container = await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('style-explore-recipe-manager')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.byKey(const Key('style-explore-recipe-dialog')),
      findsOneWidget,
    );
    // 弹窗内完整列表交互：点击载入后弹窗关闭、会话关联。
    // （侧栏缩略列表有同名条目，必须限定在弹窗内查找。）
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('style-explore-recipe-dialog')),
        matching: find.text('管理目标'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3300));

    expect(find.byKey(const Key('style-explore-recipe-dialog')), findsNothing);
    expect(
      container.read(styleExploreSessionNotifierProvider).activeRecipeId,
      isNotNull,
    );
    expect(
      container
          .read(pillWorkspaceProvider(PillScopes.explorePos))
          .document
          .text,
      'managed content',
    );
  });

  // ==================== 阶段 B：Run 数据层 + 候选画廊 ====================

  testWidgets('new-run dialog creates a draft run and selects it', (
    tester,
  ) async {
    final container = await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('style-explore-new-run')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 名称输入对话框。
    expect(find.text('任务名称'), findsOneWidget);
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '新任务甲',
    );
    // 确认按钮的可用态随输入重建，先 pump 再点。
    await tester.pump();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, '确定'),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // 成功 toast 自动关闭。
    await tester.pump(const Duration(milliseconds: 3300));

    final list = await container.read(exploreRunListNotifierProvider.future);
    expect(list.runs, hasLength(1));
    final run = list.runs.single;
    expect(run.name, '新任务甲');
    expect(run.status, ExploreRunStatus.draft);
    expect(run.recipeSnapshot.negative.text, isA<String>());
    // 点选状态 = 新建的 run，控制条出现（draft 显示开始按钮与出图数）。
    expect(container.read(exploreActiveRunIdProvider), run.id);
    expect(find.byKey(const Key('explore-run-start')), findsOneWidget);
    expect(find.byKey(const Key('explore-run-target-count')), findsOneWidget);
    expect(find.byKey(const Key('explore-run-sync-params')), findsOneWidget);
  });

  testWidgets('run card shows status dot, progress and selects on tap', (
    tester,
  ) async {
    final run = await seedRun('列表目标', targetCount: 10);
    final container = await pumpScreen(tester);

    expect(find.text('列表目标'), findsOneWidget);
    expect(find.textContaining('0/10'), findsOneWidget);
    expect(find.textContaining('草稿'), findsWidgets);

    // 点选只切换 activeRun，不把快照载入编辑器（档案语义）。
    await tester.tap(find.text('列表目标'));
    await tester.pump();
    expect(container.read(exploreActiveRunIdProvider), run.id);
    expect(
      container
          .read(pillWorkspaceProvider(PillScopes.explorePos))
          .document
          .text,
      '',
      reason: '点选 run 不自动覆盖正在编辑的 lane',
    );
    // 控制条随 activeRun 出现。
    expect(find.byKey(const Key('explore-run-start')), findsOneWidget);
  });

  testWidgets(
    'candidate gallery grid renders and pre-mark buttons write review',
    (tester) async {
      final candidateA = ExploreCandidate.shell(roundId: 'r-1', id: 'cand-a')
          .copyWith(
            generation: const ExploreCandidateGeneration(
              status: ExploreCandidateGenerationStatus.done,
              seed: 12345,
            ),
          );
      final candidateB = ExploreCandidate.shell(roundId: 'r-1', id: 'cand-b')
          .copyWith(
            generation: const ExploreCandidateGeneration(
              status: ExploreCandidateGenerationStatus.failed,
              error: 'boom',
            ),
          );
      final run = await seedRun(
        '画廊任务',
        status: ExploreRunStatus.generated,
        candidates: [candidateA, candidateB],
      );
      final container = await pumpScreen(tester);

      // 无 activeRun 时是空态。
      expect(find.textContaining('暂无候选'), findsOneWidget);

      container.read(exploreActiveRunIdProvider.notifier).state = run.id;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 两张候选卡 + 序号文本。
      expect(find.byKey(const Key('explore-candidate-cand-a')), findsOneWidget);
      expect(find.byKey(const Key('explore-candidate-cand-b')), findsOneWidget);
      expect(find.textContaining('#1'), findsOneWidget);
      expect(find.textContaining('#2'), findsOneWidget);

      // 心形 + T 预标记写 review 字段。
      await tester.tap(find.byKey(const Key('explore-candidate-heart-cand-a')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(
        find.byKey(const Key('explore-candidate-treasure-cand-a')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final stored = runStorage._store[run.id]!;
      final review = stored.candidateById('cand-a')!.review;
      expect(review.heart, isTrue);
      expect(review.preliminaryLabel, ExploreReviewLabel.treasure);
      // 另一张不受影响。
      expect(stored.candidateById('cand-b')!.review.heart, isFalse);
    },
  );

  testWidgets('filter chips narrow the grid', (tester) async {
    final treasure = ExploreCandidate.shell(roundId: 'r-1', id: 'cand-t')
        .copyWith(
          generation: const ExploreCandidateGeneration(
            status: ExploreCandidateGenerationStatus.done,
          ),
          review: const ExploreCandidateReview(
            preliminaryLabel: ExploreReviewLabel.treasure,
          ),
        );
    final plain = ExploreCandidate.shell(roundId: 'r-1', id: 'cand-p').copyWith(
      generation: const ExploreCandidateGeneration(
        status: ExploreCandidateGenerationStatus.done,
      ),
    );
    final run = await seedRun(
      '筛选任务',
      status: ExploreRunStatus.generated,
      candidates: [treasure, plain],
    );
    final container = await pumpScreen(tester);
    container.read(exploreActiveRunIdProvider.notifier).state = run.id;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('explore-candidate-cand-t')), findsOneWidget);
    expect(find.byKey(const Key('explore-candidate-cand-p')), findsOneWidget);

    // 珍宝筛选。
    await tester.tap(find.byKey(const Key('explore-filter-treasure')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('explore-candidate-cand-t')), findsOneWidget);
    expect(find.byKey(const Key('explore-candidate-cand-p')), findsNothing);

    // 待审筛选：只有无标记候选。
    await tester.tap(find.byKey(const Key('explore-filter-pendingReview')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('explore-candidate-cand-t')), findsNothing);
    expect(find.byKey(const Key('explore-candidate-cand-p')), findsOneWidget);

    // 正式筛选按钮置灰（阶段 C）。
    final formalChip = tester.widget<ActionChip>(
      find.byKey(const Key('explore-formal-review')),
    );
    expect(formalChip.onPressed, isNull);
  });

  testWidgets('detail dialog shows seed, params and roll snapshot', (
    tester,
  ) async {
    final candidate = ExploreCandidate.shell(roundId: 'r-1', id: 'cand-d')
        .copyWith(
          rollSnapshot: const ExploreRollSnapshot(
            positive: 'soft light, watercolor',
            negative: 'lowres',
            instanceRolls: [
              ExploreInstanceRoll(
                lane: 'pos',
                marker: '',
                blockId: 'b-1',
                blockTitle: '画风池',
                rolledText: 'watercolor',
              ),
            ],
          ),
          generation: const ExploreCandidateGeneration(
            status: ExploreCandidateGenerationStatus.done,
            seed: 987654,
            elapsedMs: 4321,
          ),
        );
    final run = await seedRun(
      '详情任务',
      status: ExploreRunStatus.generated,
      candidates: [candidate],
    );
    final container = await pumpScreen(tester);
    container.read(exploreActiveRunIdProvider.notifier).state = run.id;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('explore-candidate-cand-d')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('explore-candidate-detail')), findsOneWidget);
    expect(find.text('候选详情'), findsOneWidget);
    expect(find.text('Seed 987654'), findsOneWidget);
    expect(find.text('4321 ms'), findsOneWidget);
    expect(find.text('soft light, watercolor'), findsOneWidget);
    expect(find.text('[pos] 画风池: watercolor'), findsOneWidget);
    expect(
      find.byKey(const Key('explore-candidate-copy-snapshot')),
      findsOneWidget,
    );
  });
}
