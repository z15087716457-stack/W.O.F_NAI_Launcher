import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/core/services/prompt_token_counter_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/style_explore_recipe_storage.dart';
import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/data/models/style_explore/style_explore_recipe.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/data/services/explore_run_image_store.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_cooldown_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_token_counter_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';
import 'package:nai_launcher/presentation/providers/style_explore_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
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
  T? getSetting<T>(String key, {T? defaultValue}) => defaultValue;

  @override
  Future<void> setSetting<T>(String key, T value) async {}

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

/// 记录删除调用的假候选图存储（testWidgets 的 fakeAsync 区里真文件
/// I/O 永不完成，删图落盘由 service 层测试覆盖）。
class _FakeRunImageStore extends ExploreRunImageStore {
  _FakeRunImageStore() : super(rootPathResolver: () async => null);

  final List<String> deletedPaths = [];

  @override
  Future<bool> deleteCandidateImage(String filePath) async {
    deletedPaths.add(filePath);
    return true;
  }
}

/// 记录 createBlock 调用参数的假块库（收编为块测试用）。
class _RecordingLibraryNotifier extends PromptBlockLibraryNotifier {
  final List<({String title, String content, String color, String? iconName})>
  created = [];

  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: const [], folders: const []);

  @override
  Future<PromptBlock> createBlock({
    required String title,
    required String content,
    String? folderId,
    String color = '#FF607D8B',
    String? iconName,
    int? sortOrder,
  }) async {
    created.add((
      title: title,
      content: content,
      color: color,
      iconName: iconName,
    ));
    return PromptBlock.create(
      title: title,
      content: content,
      folderId: folderId,
      color: color,
      iconName: iconName,
    );
  }
}

/// 冷却永不生效的假实现（真实现会读 Hive 设置，widget 测试不准备）。
class _FakeCooldownNotifier extends GenerationCooldownNotifier {
  @override
  GenerationCooldownState build() => const GenerationCooldownState();
}

class _TestCharacterPromptNotifier extends CharacterPromptNotifier {
  @override
  CharacterPromptConfig build() => const CharacterPromptConfig();
}

class _TestKritaBridgeNotifier extends KritaBridgeNotifier {
  @override
  Future<void> close() async {}
}

class _TestSubscriptionNotifier extends SubscriptionNotifier {
  @override
  SubscriptionState build() => const SubscriptionState.initial();
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

  Widget buildScreen({List<Override> extraOverrides = const []}) {
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
        characterPromptNotifierProvider.overrideWith(
          () => _TestCharacterPromptNotifier(),
        ),
        promptTokenUsageProvider(PromptTokenCountTarget.positive).overrideWith(
          (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
        ),
        promptTokenUsageProvider(PromptTokenCountTarget.negative).overrideWith(
          (ref) async => const PromptTokenUsage(usedTokens: 0, limit: 512),
        ),
        kritaBridgeNotifierProvider.overrideWith(
          (ref) => _TestKritaBridgeNotifier(),
        ),
        subscriptionNotifierProvider.overrideWith(
          () => _TestSubscriptionNotifier(),
        ),
        estimatedCostProvider.overrideWith((ref) => 0),
        isFreeGenerationProvider.overrideWith((ref) => true),
        ...extraOverrides,
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StyleExploreScreen(),
      ),
    );
  }

  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    List<Override> extraOverrides = const [],
  }) async {
    // 宽窗：左栏 + 右栏画廊都展开（画廊默认断点 1100）。
    tester.view.physicalSize = const Size(1600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildScreen(extraOverrides: extraOverrides));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  }

  testWidgets('renders sidebar, toolbar, and shared main-lane center panel', (
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
    // 中栏 = 主生成页左栏整套面板（数据同源 main/negative lane）。
    expect(
      find.byKey(const Key('generation_prompt_positive_input')),
      findsOneWidget,
    );
    // 旧的独立探索编辑器已退役。
    expect(
      find.byKey(const Key('style-explore-positive-editor')),
      findsNothing,
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
    'tapping a recipe in the sidebar preview loads it into the main lanes',
    (tester) async {
      final recipe = await seedRecipe('载入目标', 'loaded content');
      final container = await pumpScreen(tester);

      await tester.tap(find.text('载入目标'));
      await tester.pump();
      // AppToast.success 内部有 3 秒自动关闭定时器，推进到它结束。
      await tester.pump(const Duration(milliseconds: 3300));

      expect(
        container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
        'loaded content',
      );
      expect(
        container.read(styleExploreSessionNotifierProvider).activeRecipeId,
        recipe.id,
      );
    },
  );

  testWidgets('editing in the explore page writes main lane and params', (
    tester,
  ) async {
    final container = await pumpScreen(tester);

    final textField = find.descendant(
      of: find.byKey(const Key('generation_prompt_positive_input')),
      matching: find.byType(TextField),
    );
    await tester.enterText(textField.first, '探索页输入');
    await tester.pump();
    // updatePrompt 走 microtask，推进一拍让参数落位。
    await tester.pump();

    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
      '探索页输入',
    );
    expect(container.read(generationParamsNotifierProvider).prompt, '探索页输入');
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
      container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
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
      container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
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

    // 正式筛选按钮：有可审查候选（done）时可用（阶段 C）。
    final formalChip = tester.widget<ActionChip>(
      find.byKey(const Key('explore-formal-review')),
    );
    expect(formalChip.onPressed, isNotNull);
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

  testWidgets('generated run shows target count input and another-round', (
    tester,
  ) async {
    final run = await seedRun(
      '追加轮任务',
      targetCount: 6,
      status: ExploreRunStatus.generated,
    );
    final container = await pumpScreen(tester);
    container.read(exploreActiveRunIdProvider.notifier).state = run.id;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // B2：generated 态控制条给出图数输入 + 再来一轮。
    expect(find.byKey(const Key('explore-run-target-count')), findsOneWidget);
    expect(find.byKey(const Key('explore-run-another-round')), findsOneWidget);
    // draft 专属的开始按钮不出现。
    expect(find.byKey(const Key('explore-run-start')), findsNothing);
  });

  testWidgets('recipe load over non-empty main lane asks before overwrite', (
    tester,
  ) async {
    await seedRecipe('覆盖目标', 'recipe content');
    final container = await pumpScreen(tester);

    // 主 lane 写入未备份内容。
    container
        .read(pillWorkspaceProvider(PillScopes.main).notifier)
        .setText('未备份内容');
    await tester.pump();

    // 点 Recipe → 覆盖确认弹窗（不直接灌 lane）。
    await tester.tap(find.text('覆盖目标'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('放弃未保存的修改？'), findsOneWidget);
    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
      '未备份内容',
    );

    // 确认后才灌入 main lane。
    await tester.tap(find.text('继续并丢弃'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3300));
    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
      'recipe content',
    );
  });

  testWidgets('recipe load overwrite confirm can be cancelled', (tester) async {
    await seedRecipe('取消目标', 'recipe content');
    final container = await pumpScreen(tester);

    container
        .read(pillWorkspaceProvider(PillScopes.main).notifier)
        .setText('未备份内容');
    await tester.pump();

    await tester.tap(find.text('取消目标'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('取消'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
      '未备份内容',
    );
    expect(
      container.read(styleExploreSessionNotifierProvider).activeRecipeId,
      isNull,
    );
  });

  // ==================== 阶段 C：正式筛选与出口 ====================

  ExploreCandidate doneCandidate(
    String id, {
    ExploreRollSnapshot? roll,
    ExploreReviewLabel? label,
    ExploreReviewLabel? preliminaryLabel,
    String? filePath,
  }) {
    return ExploreCandidate.shell(roundId: 'r-1', id: id).copyWith(
      rollSnapshot: roll,
      generation: ExploreCandidateGeneration(
        status: ExploreCandidateGenerationStatus.done,
        filePath: filePath,
        seed: 42,
      ),
      review: ExploreCandidateReview(
        label: label,
        preliminaryLabel: preliminaryLabel,
      ),
    );
  }

  testWidgets('formal review overlay: keyboard T/S/R, undo, gated complete', (
    tester,
  ) async {
    final run = await seedRun(
      '键盘筛选任务',
      status: ExploreRunStatus.generated,
      candidates: [doneCandidate('cand-1'), doneCandidate('cand-2')],
    );
    final container = await pumpScreen(tester);
    container.read(exploreActiveRunIdProvider.notifier).state = run.id;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 进入正式筛选 → run 状态 reviewing，覆盖层打开。
    await tester.tap(find.byKey(const Key('explore-formal-review')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('explore-review-complete')), findsOneWidget);
    expect(runStorage._store[run.id]!.status, ExploreRunStatus.reviewing);
    expect(find.text('第 1/2 张'), findsOneWidget);

    // 未归类完：完成按钮禁用。
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('explore-review-complete')),
          )
          .onPressed,
      isNull,
    );

    // T → 第一张珍宝 + 归类时间，自动前进到第 2/2 张。
    await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    var review = runStorage._store[run.id]!.candidateById('cand-1')!.review;
    expect(review.label, ExploreReviewLabel.treasure);
    expect(review.formalReviewedAt, isNotNull);
    expect(find.text('第 2/2 张'), findsOneWidget);

    // S → 第二张特殊；全部归类 → 完成可用。
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      runStorage._store[run.id]!.candidateById('cand-2')!.review.label,
      ExploreReviewLabel.special,
    );
    expect(find.text('已归类 2/2'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('explore-review-complete')),
          )
          .onPressed,
      isNotNull,
    );

    // Backspace 撤销：回到第二张并清标签，完成重新禁用。
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    review = runStorage._store[run.id]!.candidateById('cand-2')!.review;
    expect(review.label, isNull);
    expect(review.formalReviewedAt, isNull);
    expect(find.text('第 2/2 张'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const Key('explore-review-complete')),
          )
          .onPressed,
      isNull,
    );

    // R → 拒绝，点完成 → 覆盖层关闭，run 状态 completed。
    await tester.sendKeyEvent(LogicalKeyboardKey.keyR);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('explore-review-complete')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // 完成 toast 自动关闭。
    await tester.pump(const Duration(milliseconds: 3300));
    expect(find.byKey(const Key('explore-review-complete')), findsNothing);
    expect(runStorage._store[run.id]!.status, ExploreRunStatus.completed);
  });

  testWidgets('arrow keys and prev/next buttons navigate in review overlay', (
    tester,
  ) async {
    final run = await seedRun(
      '导航任务',
      status: ExploreRunStatus.generated,
      candidates: [doneCandidate('cand-1'), doneCandidate('cand-2')],
    );
    final container = await pumpScreen(tester);
    container.read(exploreActiveRunIdProvider.notifier).state = run.id;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('explore-formal-review')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('第 1/2 张'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.text('第 2/2 张'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(find.text('第 1/2 张'), findsOneWidget);
    await tester.tap(find.byKey(const Key('explore-review-next')));
    await tester.pump();
    expect(find.text('第 2/2 张'), findsOneWidget);
    await tester.tap(find.byKey(const Key('explore-review-prev')));
    await tester.pump();
    expect(find.text('第 1/2 张'), findsOneWidget);
  });

  testWidgets('Esc keeps labels and reviewing status; re-entry resumes at '
      'first unlabeled', (tester) async {
    final run = await seedRun(
      '续筛任务',
      status: ExploreRunStatus.generated,
      candidates: [doneCandidate('cand-1'), doneCandidate('cand-2')],
    );
    final container = await pumpScreen(tester);
    container.read(exploreActiveRunIdProvider.notifier).state = run.id;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('explore-formal-review')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 打第一张后 Esc 退出：标签保留、状态留 reviewing（对话框退出动画
    // 150ms，等足再断言）。
    await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('explore-review-complete')), findsNothing);
    final stored = runStorage._store[run.id]!;
    expect(stored.status, ExploreRunStatus.reviewing);
    expect(
      stored.candidateById('cand-1')!.review.label,
      ExploreReviewLabel.treasure,
    );

    // 再进入续筛：定位到第一个未归类（第 2 张）。
    await tester.tap(find.byKey(const Key('explore-formal-review')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('第 2/2 张'), findsOneWidget);

    // 按钮与键盘等价：点 S 按钮给第二张打特殊。
    await tester.tap(find.byKey(const Key('explore-review-label-special')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      runStorage._store[run.id]!.candidateById('cand-2')!.review.label,
      ExploreReviewLabel.special,
    );
    expect(find.text('已归类 2/2'), findsOneWidget);
  });

  testWidgets('deck view groups candidates by formal label with counts', (
    tester,
  ) async {
    final run = await seedRun(
      '牌堆任务',
      status: ExploreRunStatus.generated,
      candidates: [
        doneCandidate('cand-t', label: ExploreReviewLabel.treasure),
        doneCandidate('cand-r', label: ExploreReviewLabel.reject),
        doneCandidate('cand-p'),
        // 预标记不转正：仍归未归类组。
        doneCandidate('cand-pre', preliminaryLabel: ExploreReviewLabel.special),
      ],
    );
    final container = await pumpScreen(tester);
    container.read(exploreActiveRunIdProvider.notifier).state = run.id;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 切到牌堆视图。
    await tester.tap(find.byKey(const Key('explore-gallery-view-toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('珍宝 · 1'), findsOneWidget);
    expect(find.text('拒绝 · 1'), findsOneWidget);
    expect(find.text('未归类 · 2'), findsOneWidget);
    // 空组不显示。
    expect(find.byKey(const Key('explore-deck-header-special')), findsNothing);
    // 四张卡都在。
    for (final id in const ['cand-t', 'cand-r', 'cand-p', 'cand-pre']) {
      expect(find.byKey(Key('explore-candidate-$id')), findsOneWidget);
    }

    // 切回网格。
    await tester.tap(find.byKey(const Key('explore-gallery-view-toggle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('珍宝 · 1'), findsNothing);
  });

  testWidgets('detail dialog adopt-as-block passes roll positive to '
      'createBlock', (tester) async {
    final recording = _RecordingLibraryNotifier();
    final run = await seedRun(
      '收编任务',
      status: ExploreRunStatus.generated,
      candidates: [
        doneCandidate(
          'cand-1',
          roll: const ExploreRollSnapshot(
            positive: 'soft light, watercolor',
            negative: 'lowres',
          ),
        ),
      ],
    );
    final container = await pumpScreen(
      tester,
      extraOverrides: [
        promptBlockLibraryNotifierProvider.overrideWith(() => recording),
      ],
    );
    container.read(exploreActiveRunIdProvider.notifier).state = run.id;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('explore-candidate-cand-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('explore-candidate-adopt-block')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 默认名 = run 名 + 候选序号。
    expect(find.byKey(const Key('explore-adopt-block-dialog')), findsOneWidget);
    final nameField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('explore-adopt-block-dialog')),
        matching: find.byType(TextField),
      ),
    );
    expect(nameField.controller!.text, '收编任务 #1');

    await tester.tap(find.byKey(const Key('explore-adopt-block-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3300));

    expect(recording.created, hasLength(1));
    final created = recording.created.single;
    expect(created.title, '收编任务 #1');
    expect(created.content, 'soft light, watercolor');
    expect(created.color, '#FF607D8B');
    expect(created.iconName, isNull);
  });

  testWidgets('multi-select merge adopt combines roll positives with dedup', (
    tester,
  ) async {
    final recording = _RecordingLibraryNotifier();
    final run = await seedRun(
      '合并任务',
      status: ExploreRunStatus.generated,
      candidates: [
        doneCandidate(
          'cand-1',
          roll: const ExploreRollSnapshot(positive: 'a, b', negative: 'n'),
        ),
        doneCandidate(
          'cand-2',
          roll: const ExploreRollSnapshot(positive: 'b, c,', negative: 'n'),
        ),
      ],
    );
    final container = await pumpScreen(
      tester,
      extraOverrides: [
        promptBlockLibraryNotifierProvider.overrideWith(() => recording),
      ],
    );
    container.read(exploreActiveRunIdProvider.notifier).state = run.id;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 进入多选并选两张。
    await tester.tap(find.byKey(const Key('explore-gallery-select-toggle')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('explore-candidate-cand-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('explore-candidate-cand-2')));
    await tester.pump();
    expect(find.text('已选 2 张'), findsOneWidget);

    // 合并收编 → 默认名 ×2 → 确认。
    await tester.tap(find.byKey(const Key('explore-gallery-merge-adopt')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('explore-adopt-block-dialog')), findsOneWidget);
    final nameField = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('explore-adopt-block-dialog')),
        matching: find.byType(TextField),
      ),
    );
    expect(nameField.controller!.text, '合并任务 ×2');
    await tester.tap(find.byKey(const Key('explore-adopt-block-confirm')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3300));

    expect(recording.created.single.content, 'a, b, c');
    // 收编成功后退出多选。
    expect(find.text('已选 2 张'), findsNothing);
    expect(
      find.byKey(const Key('explore-gallery-select-toggle')),
      findsOneWidget,
    );
  });

  testWidgets('fixate as template overwrites main lane after confirm, '
      'negative untouched', (tester) async {
    final run = await seedRun(
      '固化任务',
      status: ExploreRunStatus.generated,
      candidates: [
        doneCandidate(
          'cand-1',
          roll: const ExploreRollSnapshot(
            positive: 'fixed prompt, abc',
            negative: 'neg-roll',
          ),
        ),
      ],
    );
    final container = await pumpScreen(tester);
    container.read(exploreActiveRunIdProvider.notifier).state = run.id;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 主 lane 有未备份内容 → 覆盖前确认。
    container
        .read(pillWorkspaceProvider(PillScopes.main).notifier)
        .setText('未备份内容');
    container
        .read(pillWorkspaceProvider(PillScopes.negative).notifier)
        .setText('neg-keep');
    await tester.pump();

    await tester.tap(find.byKey(const Key('explore-candidate-cand-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('explore-candidate-fixate')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('放弃未保存的修改？'), findsOneWidget);

    await tester.tap(find.text('继续并丢弃'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3300));

    expect(
      container.read(pillWorkspaceProvider(PillScopes.main)).document.text,
      'fixed prompt, abc',
    );
    expect(
      container.read(pillWorkspaceProvider(PillScopes.negative)).document.text,
      'neg-keep',
      reason: '固化只动正向 lane',
    );
  });

  testWidgets('reject candidate delete image removes copy and keeps record', (
    tester,
  ) async {
    final imageStore = _FakeRunImageStore();
    const rejectPath = '/tmp/style_explore_runs/run-1/cand-reject.png';

    final run = await seedRun(
      '删图任务',
      status: ExploreRunStatus.generated,
      candidates: [
        doneCandidate('cand-keep', label: ExploreReviewLabel.treasure),
        doneCandidate(
          'cand-reject',
          label: ExploreReviewLabel.reject,
          filePath: rejectPath,
        ),
      ],
    );
    final container = await pumpScreen(
      tester,
      extraOverrides: [
        exploreRunImageStoreProvider.overrideWithValue(imageStore),
      ],
    );
    container.read(exploreActiveRunIdProvider.notifier).state = run.id;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 非 reject 候选不提供删除图片。
    await tester.tap(find.byKey(const Key('explore-candidate-cand-keep')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      find.byKey(const Key('explore-candidate-delete-image')),
      findsNothing,
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('explore-candidate-detail')),
        matching: find.byIcon(Icons.close),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // reject 候选：删除图片 → 确认 → 副本删除、记录保留（filePath 清空）。
    await tester.tap(find.byKey(const Key('explore-candidate-cand-reject')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('explore-candidate-delete-image')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('删除候选图'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, '删除图片'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 3300));

    expect(imageStore.deletedPaths, [rejectPath]);
    final stored = runStorage._store[run.id]!.candidateById('cand-reject')!;
    expect(stored.generation.filePath, isNull);
    expect(stored.generation.status, ExploreCandidateGenerationStatus.done);
    expect(stored.generation.seed, 42, reason: '记录保留，仅清副本路径');
  });
}
