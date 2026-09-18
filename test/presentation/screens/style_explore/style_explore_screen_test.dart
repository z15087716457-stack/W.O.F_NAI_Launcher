import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/core/services/prompt_token_counter_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/style_explore_run_storage.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/style_explore/explore_run.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/services/explore_run_image_store.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_cooldown_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_params_notifier.dart';
import 'package:nai_launcher/presentation/providers/krita/krita_bridge_notifier.dart';
import 'package:nai_launcher/presentation/providers/layout_state_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_token_counter_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore/explore_run_runner.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/providers/vibe_library_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/block_library_panel_slot.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/generation_controls/generate_button.dart';
import 'package:nai_launcher/presentation/screens/style_explore/style_explore_screen.dart';

/// 内存版 Run 存储（testWidgets 的 fakeAsync 区里 Hive 的异步写盘永不完成，
/// 因此 widget 测试不落盘，只验证 UI 与 provider 协作）。
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
  _TestLocalStorageService({Map<String, Object?>? initial}) {
    if (initial != null) settings.addAll(initial);
  }

  /// 已写入的设置值（含布局 provider 落盘的 toggle 状态）。
  final Map<String, Object?> settings = {};

  @override
  T? getSetting<T>(String key, {T? defaultValue}) {
    final value = settings[key];
    if (value is T) return value;
    return defaultValue;
  }

  @override
  Future<void> setSetting<T>(String key, T value) async {
    settings[key] = value;
  }

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

}

class _TestVibeLibraryNotifier extends VibeLibraryNotifier {
  @override
  VibeLibraryState build() => const VibeLibraryState();
}

class _TestVibeStorageService extends VibeLibraryStorageService {
  @override
  Future<List<VibeLibraryEntry>> getRecentDisplayEntries({
    int limit = 20,
  }) async => const [];
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
    String? thumbnail,
    double thumbnailOffsetX = 0.0,
    double thumbnailOffsetY = 0.0,
    double thumbnailScale = 1.0,
    int? sortOrder,
    List<String>? atoms,
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
  late _MemoryRunStorage runStorage;
  late _TestLocalStorageService localStorage;

  setUp(() {
    runStorage = _MemoryRunStorage();
    localStorage = _TestLocalStorageService();
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
        localStorageServiceProvider.overrideWith((ref) => localStorage),
        // 提示词区可拖矮后参数面板视口变大，Vibe 参考面板会进入视口；
        // 其 initState 直读真 Hive/计时器，测试环境必须断掉这两条链。
        vibeLibraryNotifierProvider.overrideWith(_TestVibeLibraryNotifier.new),
        vibeLibraryStorageServiceProvider.overrideWithValue(
          _TestVibeStorageService(),
        ),
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
    double width = 1600,
    List<Override> extraOverrides = const [],
  }) async {
    // 宽窗：左栏 + 右栏画廊都展开（画廊默认断点 1100）。
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(buildScreen(extraOverrides: extraOverrides));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
  }

  /// 把画廊筛选排滚到端点：chip 溢出时被懒加载回收，
  /// ensureVisible/scrollUntilVisible 找不到元素，须直接驱动 position。
  Future<void> scrollChipRowToEnd(
    WidgetTester tester, {
    bool toEnd = true,
  }) async {
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(ReorderableListView),
        matching: find.byType(Scrollable),
      ),
    );
    scrollable.position.jumpTo(
      toEnd
          ? scrollable.position.maxScrollExtent
          : scrollable.position.minScrollExtent,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('renders the run sidebar, toolbar, and center panel', (
    tester,
  ) async {
    await pumpScreen(tester);

    // 左栏：探索任务列表（键未设 → 首访默认展开，露新建引导）。
    expect(find.byKey(const Key('style-explore-run-sidebar')), findsOneWidget);
    expect(find.byKey(const Key('style-explore-new-run')), findsOneWidget);
    expect(find.text('还没有探索任务'), findsOneWidget);
    // 配方区整段已删。
    expect(find.text('未关联配方'), findsNothing);
    expect(find.byKey(const Key('style-explore-save')), findsNothing);
    expect(find.byKey(const Key('style-explore-save-as')), findsNothing);
    // 顶栏按钮。
    expect(
      find.byKey(const Key('style-explore-run-sidebar-toggle')),
      findsOneWidget,
    );
    // FEAT-54：指南针方块化 = 与「预览」同款 OutlinedButton.icon、
    // 图标+「探索任务」文字，激活态（侧栏默认开）填主题主色。
    expect(
      tester.widget(find.byKey(const Key('style-explore-run-sidebar-toggle'))),
      isA<OutlinedButton>(),
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('style-explore-run-sidebar-toggle')),
        matching: find.text('探索任务'),
      ),
      findsOneWidget,
    );
    final toggleElement = tester.element(
      find.byKey(const Key('style-explore-run-sidebar-toggle')),
    );
    expect(
      tester
          .widget<OutlinedButton>(
            find.byKey(const Key('style-explore-run-sidebar-toggle')),
          )
          .style!
          .backgroundColor!
          .resolve(const <WidgetState>{}),
      Theme.of(toggleElement).colorScheme.primary,
      reason: '激活态底 = colorScheme.primary',
    );
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
  });

  testWidgets('top bar toggle hides and shows the run sidebar', (tester) async {
    await pumpScreen(tester);
    final toggle = find.byKey(const Key('style-explore-run-sidebar-toggle'));

    await tester.tap(toggle);
    await tester.pump();

    expect(find.byKey(const Key('style-explore-run-sidebar')), findsNothing);
    expect(
      find.byKey(const Key('style-explore-run-sidebar-resize-handle')),
      findsNothing,
    );
    expect(
      localStorage.settings[StorageKeys.styleExploreRunSidebarVisible],
      isFalse,
    );
    // 收起后主编辑区吃满宽度：画廊拖拽手柄直接贴住主编辑区右缘。
    final main = tester.getRect(
      find.byKey(const Key('style-explore-main-editor')),
    );
    final galleryHandle = tester.getRect(
      find.byKey(const Key('style-explore-gallery-resize-handle')),
    );
    expect(main.right, closeTo(galleryHandle.left, 1.1));

    await tester.tap(toggle);
    await tester.pump();

    expect(find.byKey(const Key('style-explore-run-sidebar')), findsOneWidget);
    expect(
      localStorage.settings[StorageKeys.styleExploreRunSidebarVisible],
      isTrue,
    );
  });

  testWidgets('a hidden run sidebar stays collapsed across a restart', (
    tester,
  ) async {
    // 键已设 false = 用户手动关过：重开不回到默认展开。
    localStorage.settings[StorageKeys.styleExploreRunSidebarVisible] = false;
    await pumpScreen(tester);

    expect(find.byKey(const Key('style-explore-run-sidebar')), findsNothing);
    expect(
      find.byKey(const Key('style-explore-run-sidebar-resize-handle')),
      findsNothing,
    );
    // 开关本身仍在顶栏，可随时重新展开。
    expect(
      find.byKey(const Key('style-explore-run-sidebar-toggle')),
      findsOneWidget,
    );
    // 收起态下画廊手柄直接贴住主编辑区右缘。
    final main = tester.getRect(
      find.byKey(const Key('style-explore-main-editor')),
    );
    final galleryHandle = tester.getRect(
      find.byKey(const Key('style-explore-gallery-resize-handle')),
    );
    expect(main.right, closeTo(galleryHandle.left, 1.1));
  });

  testWidgets('preview dialog shows pill projections without titles', (
    tester,
  ) async {
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
    // 点选状态 = 新建的 run，控制条出现；基础轮入口统一由主生成控制条承载。
    expect(container.read(exploreActiveRunIdProvider), run.id);
    expect(find.byKey(const Key('explore-run-start')), findsNothing);
    expect(find.byKey(const Key('explore-run-target-count')), findsNothing);
    expect(find.text('共 0 张'), findsOneWidget);

    final topBar = tester.getRect(
      find.byKey(const Key('style-explore-top-bar-content')),
    );
    final runBar = tester.getRect(
      find.byKey(const Key('explore-run-control-bar-content')),
    );
    expect(runBar.width, closeTo(topBar.width, 0.1));
  });

  testWidgets(
    'run card shows candidate total instead of target progress and selects on tap',
    (tester) async {
      final run = await seedRun(
        '列表目标',
        targetCount: 10,
        candidates: [
          ExploreCandidate.shell(roundId: 'r-1', id: 'cand-1'),
          ExploreCandidate.shell(roundId: 'r-1', id: 'cand-2'),
        ],
      );
      final container = await pumpScreen(tester);

      expect(find.text('列表目标'), findsOneWidget);
      expect(find.textContaining('共 2 张'), findsOneWidget);
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
      // 控制条随 activeRun 出现，但基础轮入口由主生成控制条承载。
      expect(find.byKey(const Key('explore-run-start')), findsNothing);
      expect(find.text('共 2 张'), findsOneWidget);
    },
  );

  testWidgets('explore panes stay continuous without an artificial spacer', (
    tester,
  ) async {
    final container = await pumpScreen(tester);
    final main = tester.getRect(
      find.byKey(const Key('style-explore-main-editor')),
    );
    final sidebar = tester.getRect(
      find.byKey(const Key('style-explore-run-sidebar')),
    );
    final galleryHandle = tester.getRect(
      find.byKey(const Key('style-explore-gallery-resize-handle')),
    );
    final gallery = tester.getRect(
      find.byKey(const Key('style-explore-gallery-panel')),
    );

    expect(
      find.byKey(const Key('style-explore-main-editor-resize-handle')),
      findsNothing,
    );
    expect(main.right, closeTo(sidebar.left, 0.1));
    expect(sidebar.right, closeTo(galleryHandle.left, 1.1));
    expect(galleryHandle.right, closeTo(gallery.left, 1.1));

    await container
        .read(layoutStateNotifierProvider.notifier)
        .setBlockLibraryPanelExpanded(true);
    await tester.pump();

    final block = tester.getRect(find.byType(BlockLibraryPanelSlot));
    final mainWithBlock = tester.getRect(
      find.byKey(const Key('style-explore-main-editor')),
    );
    final sidebarWithBlock = tester.getRect(
      find.byKey(const Key('style-explore-run-sidebar')),
    );
    final galleryHandleWithBlock = tester.getRect(
      find.byKey(const Key('style-explore-gallery-resize-handle')),
    );
    final galleryWithBlock = tester.getRect(
      find.byKey(const Key('style-explore-gallery-panel')),
    );
    expect(mainWithBlock.right, closeTo(block.left, 0.1));
    expect(block.right, closeTo(sidebarWithBlock.left, 0.1));
    expect(sidebarWithBlock.right, closeTo(galleryHandleWithBlock.left, 1.1));
    expect(galleryHandleWithBlock.right, closeTo(galleryWithBlock.left, 1.1));
  });

  testWidgets('main prompt wraps within the actual editor pane width', (
    tester,
  ) async {
    final container = await pumpScreen(tester, width: 1200);
    final layoutNotifier = container.read(layoutStateNotifierProvider.notifier);
    await layoutNotifier.setBlockLibraryPanelExpanded(true);
    await layoutNotifier.setBlockLibraryPanelWidth(220);
    await layoutNotifier.setStyleExploreRunSidebarWidth(260);
    await layoutNotifier.setStyleExploreGalleryWidth(320);

    final prompt = List.filled(
      24,
      'artist:example, soft lighting, cinematic composition',
    ).join(', ');
    container
        .read(pillWorkspaceProvider(PillScopes.main).notifier)
        .replaceWithPlainText(prompt);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final main = tester.getRect(
      find.byKey(const Key('style-explore-main-editor')),
    );
    final editableFinder = find.descendant(
      of: find.byKey(const Key('generation_prompt_positive_input')),
      matching: find.byType(EditableText),
    );
    final editable = tester.getRect(editableFinder);
    final renderEditable = tester
        .state<EditableTextState>(editableFinder)
        .renderEditable;
    final lineTops = renderEditable
        .getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: prompt.length),
        )
        .map((box) => box.top.round())
        .toSet();

    expect(main.width, lessThan(500));
    expect(editable.width, lessThan(500));
    expect(lineTops.length, greaterThan(1));
    expect(find.byType(BlockLibraryPanelSlot), findsOneWidget);
    expect(find.byKey(const Key('style-explore-run-sidebar')), findsOneWidget);
    expect(
      find.byKey(const Key('style-explore-gallery-panel')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'expanded pane widths stay visible when the editor is exhausted',
    (tester) async {
      final container = await pumpScreen(tester, width: 1400);
      final notifier = container.read(layoutStateNotifierProvider.notifier);
      await notifier.setBlockLibraryPanelExpanded(true);
      await notifier.setBlockLibraryPanelWidth(600);
      await notifier.setStyleExploreRunSidebarWidth(500);
      await notifier.setStyleExploreGalleryWidth(700);
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(BlockLibraryPanelSlot), findsOneWidget);
      expect(
        find.byKey(const Key('style-explore-run-sidebar')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('style-explore-gallery-panel')),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byType(BlockLibraryPanelSlot)).width,
        greaterThan(480),
      );
      expect(
        tester
            .getSize(find.byKey(const Key('style-explore-run-sidebar')))
            .width,
        greaterThan(360),
      );
      expect(
        tester
            .getSize(find.byKey(const Key('style-explore-gallery-panel')))
            .width,
        greaterThan(560),
      );
      expect(
        tester
            .getSize(find.byKey(const Key('style-explore-main-editor')))
            .width,
        lessThan(160),
      );
    },
  );

  testWidgets('explicitly opened panes are not hidden by a narrow layout', (
    tester,
  ) async {
    final container = await pumpScreen(tester, width: 720);

    // 窄窗默认不展开画廊；用户明确打开后必须保持可见。
    await tester.tap(find.byKey(const Key('style-explore-gallery-toggle')));
    await tester.pump();
    await container
        .read(layoutStateNotifierProvider.notifier)
        .setBlockLibraryPanelExpanded(true);
    await tester.pump();

    expect(find.byType(BlockLibraryPanelSlot), findsOneWidget);
    expect(find.byKey(const Key('style-explore-run-sidebar')), findsOneWidget);
    expect(
      find.byKey(const Key('style-explore-gallery-panel')),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const Key('style-explore-main-editor'))).width,
      lessThan(160),
    );
    expect(
      container.read(layoutStateNotifierProvider).blockLibraryPanelExpanded,
      isTrue,
    );
  });

  testWidgets('explore pane resize handles update adjacent pane widths', (
    tester,
  ) async {
    final container = await pumpScreen(tester);
    final layoutNotifier = container.read(layoutStateNotifierProvider.notifier);

    await tester.drag(
      find.byKey(const Key('style-explore-run-sidebar-resize-handle')),
      const Offset(-30, 0),
    );
    await tester.pump();
    expect(
      container.read(layoutStateNotifierProvider).styleExploreRunSidebarWidth,
      270,
    );

    await tester.drag(
      find.byKey(const Key('style-explore-gallery-resize-handle')),
      const Offset(30, 0),
    );
    await tester.pump();
    expect(
      container.read(layoutStateNotifierProvider).styleExploreGalleryWidth,
      330,
    );

    await layoutNotifier.setBlockLibraryPanelExpanded(true);
    await tester.pump();
    final blockWidth = container
        .read(layoutStateNotifierProvider)
        .blockLibraryPanelWidth;
    await tester.drag(
      find.byKey(const Key('block-library-panel-resize-handle')),
      const Offset(-40, 0),
    );
    await tester.pump();
    expect(
      container.read(layoutStateNotifierProvider).blockLibraryPanelWidth,
      blockWidth + 40,
    );
    await tester.drag(
      find.byKey(const Key('block-library-panel-resize-handle')),
      const Offset(20, 0),
    );
    await tester.pump();
    expect(
      container.read(layoutStateNotifierProvider).blockLibraryPanelWidth,
      blockWidth + 20,
    );
  });

  testWidgets('gallery handle drag compensates sidebar, other panes fixed', (
    tester,
  ) async {
    final container = await pumpScreen(tester);
    final notifier = container.read(layoutStateNotifierProvider.notifier);
    await notifier.setBlockLibraryPanelExpanded(true);
    await notifier.setBlockLibraryPanelWidth(280);
    await tester.pump();

    final mainBefore = tester.getRect(
      find.byKey(const Key('style-explore-main-editor')),
    );
    final blockBefore = tester.getRect(find.byType(BlockLibraryPanelSlot));

    // 左拖画廊手柄：画廊变宽、侧栏等量变窄，其余分区宽度与左缘不动。
    await tester.drag(
      find.byKey(const Key('style-explore-gallery-resize-handle')),
      const Offset(-60, 0),
    );
    await tester.pump();

    var state = container.read(layoutStateNotifierProvider);
    expect(state.styleExploreGalleryWidth, 420);
    expect(state.styleExploreRunSidebarWidth, 180);
    expect(state.blockLibraryPanelWidth, 280);
    expect(
      tester.getRect(find.byKey(const Key('style-explore-main-editor'))),
      mainBefore,
    );
    expect(tester.getRect(find.byType(BlockLibraryPanelSlot)), blockBefore);

    // 右拖：反向等量补偿。
    await tester.drag(
      find.byKey(const Key('style-explore-gallery-resize-handle')),
      const Offset(20, 0),
    );
    await tester.pump();

    state = container.read(layoutStateNotifierProvider);
    expect(state.styleExploreGalleryWidth, 400);
    expect(state.styleExploreRunSidebarWidth, 200);
    expect(
      tester.getRect(find.byKey(const Key('style-explore-main-editor'))),
      mainBefore,
    );
  });

  testWidgets('gallery handle stalls once the sidebar is exhausted', (
    tester,
  ) async {
    final container = await pumpScreen(tester);
    final mainBefore = tester.getRect(
      find.byKey(const Key('style-explore-main-editor')),
    );

    // 左拖远超侧栏余量：侧栏只让出到 0，超出部分丢弃，主编辑不动。
    await tester.drag(
      find.byKey(const Key('style-explore-gallery-resize-handle')),
      const Offset(-400, 0),
    );
    await tester.pump();

    var state = container.read(layoutStateNotifierProvider);
    expect(state.styleExploreRunSidebarWidth, 0);
    expect(state.styleExploreGalleryWidth, 600);
    expect(
      tester.getRect(find.byKey(const Key('style-explore-main-editor'))),
      mainBefore,
    );

    // 侧栏已到 0：继续左拖整体 stall，不级联吸收主编辑。
    await tester.drag(
      find.byKey(const Key('style-explore-gallery-resize-handle')),
      const Offset(-50, 0),
    );
    await tester.pump();

    state = container.read(layoutStateNotifierProvider);
    expect(state.styleExploreRunSidebarWidth, 0);
    expect(state.styleExploreGalleryWidth, 600);
    expect(
      tester.getRect(find.byKey(const Key('style-explore-main-editor'))),
      mainBefore,
    );
  });

  testWidgets('run sidebar handle drags against the expanded block library', (
    tester,
  ) async {
    final container = await pumpScreen(tester);
    final notifier = container.read(layoutStateNotifierProvider.notifier);
    await notifier.setBlockLibraryPanelExpanded(true);
    await notifier.setBlockLibraryPanelWidth(280);
    await tester.pump();

    final mainBefore = tester.getRect(
      find.byKey(const Key('style-explore-main-editor')),
    );
    final galleryHandleBefore = tester.getRect(
      find.byKey(const Key('style-explore-gallery-resize-handle')),
    );

    // 左拖侧栏手柄：侧栏变宽、块库等量变窄，画廊与主编辑不动。
    await tester.drag(
      find.byKey(const Key('style-explore-run-sidebar-resize-handle')),
      const Offset(-30, 0),
    );
    await tester.pump();

    var state = container.read(layoutStateNotifierProvider);
    expect(state.styleExploreRunSidebarWidth, 270);
    expect(state.blockLibraryPanelWidth, 250);
    expect(state.styleExploreGalleryWidth, 360);
    expect(
      tester.getRect(find.byKey(const Key('style-explore-main-editor'))),
      mainBefore,
    );
    expect(
      tester.getRect(
        find.byKey(const Key('style-explore-gallery-resize-handle')),
      ),
      galleryHandleBefore,
    );

    // 右拖：反向等量补偿。
    await tester.drag(
      find.byKey(const Key('style-explore-run-sidebar-resize-handle')),
      const Offset(20, 0),
    );
    await tester.pump();

    state = container.read(layoutStateNotifierProvider);
    expect(state.styleExploreRunSidebarWidth, 250);
    expect(state.blockLibraryPanelWidth, 270);
    expect(
      tester.getRect(find.byKey(const Key('style-explore-main-editor'))),
      mainBefore,
    );
  });

  testWidgets(
    'run sidebar handle keeps the single-write path while collapsed',
    (tester) async {
      final container = await pumpScreen(tester);

      // 块库收起时左邻是主编辑（Expanded 吸收），只写侧栏。
      await tester.drag(
        find.byKey(const Key('style-explore-run-sidebar-resize-handle')),
        const Offset(-30, 0),
      );
      await tester.pump();

      final state = container.read(layoutStateNotifierProvider);
      expect(state.styleExploreRunSidebarWidth, 270);
      expect(state.blockLibraryPanelWidth, 320);
      expect(state.styleExploreGalleryWidth, 360);
    },
  );

  testWidgets('run sidebar handle stalls when the block library is exhausted', (
    tester,
  ) async {
    final container = await pumpScreen(tester);
    final notifier = container.read(layoutStateNotifierProvider.notifier);
    await notifier.setBlockLibraryPanelExpanded(true);
    await notifier.setBlockLibraryPanelWidth(280);
    await tester.pump();

    final mainBefore = tester.getRect(
      find.byKey(const Key('style-explore-main-editor')),
    );

    // 左拖远超块库余量：块库只让出到 0，侧栏增量为剩余值，主编辑不动。
    await tester.drag(
      find.byKey(const Key('style-explore-run-sidebar-resize-handle')),
      const Offset(-400, 0),
    );
    await tester.pump();

    final state = container.read(layoutStateNotifierProvider);
    expect(state.blockLibraryPanelWidth, 0);
    expect(state.styleExploreRunSidebarWidth, 520);
    expect(
      tester.getRect(find.byKey(const Key('style-explore-main-editor'))),
      mainBefore,
    );
  });

  testWidgets(
    'gallery handle compensates block library when the sidebar is hidden',
    (tester) async {
      final container = await pumpScreen(tester);
      final notifier = container.read(layoutStateNotifierProvider.notifier);
      await notifier.setBlockLibraryPanelExpanded(true);
      await notifier.setBlockLibraryPanelWidth(280);
      await notifier.setStyleExploreRunSidebarVisible(false);
      await tester.pump();

      final mainBefore = tester.getRect(
        find.byKey(const Key('style-explore-main-editor')),
      );

      // 侧栏隐藏时左邻是块库：画廊变宽、块库等量变窄，隐藏侧栏的存宽
      // 不被改写，主编辑不动。
      await tester.drag(
        find.byKey(const Key('style-explore-gallery-resize-handle')),
        const Offset(-60, 0),
      );
      await tester.pump();

      var state = container.read(layoutStateNotifierProvider);
      expect(state.styleExploreGalleryWidth, 420);
      expect(state.blockLibraryPanelWidth, 220);
      expect(state.styleExploreRunSidebarWidth, 240);
      expect(
        tester.getRect(find.byKey(const Key('style-explore-main-editor'))),
        mainBefore,
      );

      // 右拖：反向等量补偿，侧栏存宽依旧不动。
      await tester.drag(
        find.byKey(const Key('style-explore-gallery-resize-handle')),
        const Offset(20, 0),
      );
      await tester.pump();

      state = container.read(layoutStateNotifierProvider);
      expect(state.styleExploreGalleryWidth, 400);
      expect(state.blockLibraryPanelWidth, 240);
      expect(state.styleExploreRunSidebarWidth, 240);
    },
  );

  testWidgets(
    'gallery handle never stalls on a hidden sidebar and falls back to '
    'single-write when no pane neighbor remains',
    (tester) async {
      final container = await pumpScreen(tester);
      final notifier = container.read(layoutStateNotifierProvider.notifier);
      await notifier.setStyleExploreRunSidebarVisible(false);
      await tester.pump();

      final mainBefore = tester.getRect(
        find.byKey(const Key('style-explore-main-editor')),
      );

      // 块库默认收起、侧栏隐藏：左邻只剩主编辑（Expanded 吸收），
      // 单写画廊且不受隐藏侧栏存宽上限钳制。
      await tester.drag(
        find.byKey(const Key('style-explore-gallery-resize-handle')),
        const Offset(-400, 0),
      );
      await tester.pump();

      final state = container.read(layoutStateNotifierProvider);
      expect(state.styleExploreGalleryWidth, 760);
      expect(state.styleExploreRunSidebarWidth, 240);
      expect(state.blockLibraryPanelWidth, 320);
      final mainAfter = tester.getRect(
        find.byKey(const Key('style-explore-main-editor')),
      );
      expect(mainAfter.left, mainBefore.left);
      expect(mainAfter.width, mainBefore.width - 400);
    },
  );

  testWidgets(
    'gallery handle stalls on exhausted block library while the sidebar '
    'is hidden',
    (tester) async {
      final container = await pumpScreen(tester);
      final notifier = container.read(layoutStateNotifierProvider.notifier);
      await notifier.setBlockLibraryPanelExpanded(true);
      await notifier.setBlockLibraryPanelWidth(280);
      await notifier.setStyleExploreRunSidebarVisible(false);
      await tester.pump();

      // 左拖远超块库余量：块库只让出到 0，隐藏侧栏存宽不受牵连。
      await tester.drag(
        find.byKey(const Key('style-explore-gallery-resize-handle')),
        const Offset(-400, 0),
      );
      await tester.pump();

      var state = container.read(layoutStateNotifierProvider);
      expect(state.blockLibraryPanelWidth, 0);
      expect(state.styleExploreGalleryWidth, 640);
      expect(state.styleExploreRunSidebarWidth, 240);

      // 块库到 0 后继续左拖整体 stall，不级联吸收隐藏侧栏。
      await tester.drag(
        find.byKey(const Key('style-explore-gallery-resize-handle')),
        const Offset(-50, 0),
      );
      await tester.pump();

      state = container.read(layoutStateNotifierProvider);
      expect(state.blockLibraryPanelWidth, 0);
      expect(state.styleExploreGalleryWidth, 640);
      expect(state.styleExploreRunSidebarWidth, 240);
    },
  );

  testWidgets('prompt area resize handle grows and shrinks the prompt box', (
    tester,
  ) async {
    final container = await pumpScreen(tester);
    final notifier = container.read(layoutStateNotifierProvider.notifier);
    // 预置较低初值，确保 +60 不触碰按窗口高度算的上限。
    await notifier.setStyleExplorePromptAreaHeight(200);
    await tester.pump();

    final inputBefore = tester.getSize(
      find.byKey(const Key('generation_prompt_positive_input')),
    );

    await tester.drag(
      find.byKey(const Key('style-explore-prompt-area-resize-handle')),
      const Offset(0, 60),
    );
    await tester.pump();

    expect(
      container.read(layoutStateNotifierProvider).styleExplorePromptAreaHeight,
      260,
    );
    final inputAfterGrow = tester.getSize(
      find.byKey(const Key('generation_prompt_positive_input')),
    );
    expect(inputAfterGrow.height, greaterThan(inputBefore.height));

    await tester.drag(
      find.byKey(const Key('style-explore-prompt-area-resize-handle')),
      const Offset(0, -40),
    );
    await tester.pump();

    expect(
      container.read(layoutStateNotifierProvider).styleExplorePromptAreaHeight,
      220,
    );
    final inputAfterShrink = tester.getSize(
      find.byKey(const Key('generation_prompt_positive_input')),
    );
    expect(inputAfterShrink.height, lessThan(inputAfterGrow.height));
    // 面板 initState 里有 100ms 延迟恢复任务，推进时钟避免 pending timer。
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('prompt area resize handle clamps to the minimum height', (
    tester,
  ) async {
    final container = await pumpScreen(tester);
    await container
        .read(layoutStateNotifierProvider.notifier)
        .setStyleExplorePromptAreaHeight(150);
    await tester.pump();

    await tester.drag(
      find.byKey(const Key('style-explore-prompt-area-resize-handle')),
      const Offset(0, -500),
    );
    await tester.pump();

    expect(
      container.read(layoutStateNotifierProvider).styleExplorePromptAreaHeight,
      160,
    );
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('prompt area resize handle caps before starving lower panes', (
    tester,
  ) async {
    final container = await pumpScreen(tester);
    await container
        .read(layoutStateNotifierProvider.notifier)
        .setStyleExplorePromptAreaHeight(200);
    await tester.pump();

    await tester.drag(
      find.byKey(const Key('style-explore-prompt-area-resize-handle')),
      const Offset(0, 99999),
    );
    await tester.pump();

    final height = container
        .read(layoutStateNotifierProvider)
        .styleExplorePromptAreaHeight;
    // 停在按可用高度算出的上限：有限值、能比初值更高，但绝不吞掉
    // 参数面板与底部控制条的生存空间，也无渲染溢出。
    expect(height, greaterThan(200));
    expect(height, lessThan(99999 + 200));
    expect(
      find.byKey(const Key('style-explore-prompt-area-resize-handle')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 200));
  });

  testWidgets('narrow explore layout keeps panes and wraps controls', (
    tester,
  ) async {
    final container = await pumpScreen(tester, width: 420);

    // 画廊默认收起，但用户开关优先于窄窗断点。
    await tester.tap(find.byKey(const Key('style-explore-gallery-toggle')));
    await tester.pump();
    await container
        .read(layoutStateNotifierProvider.notifier)
        .setBlockLibraryPanelExpanded(true);
    await tester.pump();

    expect(
      find.byKey(const Key('generation_prompt_positive_input')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('style-explore-main-editor')), findsOneWidget);
    expect(find.byKey(const Key('style-explore-run-sidebar')), findsOneWidget);
    expect(
      find.byKey(const Key('style-explore-gallery-panel')),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const Key('style-explore-main-editor'))).width,
      lessThan(160),
    );
    expect(
      tester
          .widget<Wrap>(find.byKey(const Key('style-explore-top-bar-content')))
          .runSpacing,
      greaterThan(0),
    );
    // 生成控制条已改整条单排：极窄下整组等比缩小而不是换行。
    expect(find.byType(GenerateButtonWithCost), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('candidate gallery cards toggle heart from the overlay button', (
    tester,
  ) async {
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
    // 卡片内嵌标记钮（T/S/R）整行已拆除。
    expect(
      find.byKey(const Key('explore-candidate-treasure-cand-a')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('explore-candidate-special-cand-a')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('explore-candidate-reject-cand-a')),
      findsNothing,
    );

    // 右上角收藏钮写 heart 字段（不改状态、不动文件）。
    await tester.tap(find.byKey(const Key('explore-candidate-heart-cand-a')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final stored = runStorage._store[run.id]!;
    expect(stored.candidateById('cand-a')!.review.heart, isTrue);
    // 另一张不受影响。
    expect(stored.candidateById('cand-b')!.review.heart, isFalse);

    // 再点一次取消收藏。
    await tester.tap(find.byKey(const Key('explore-candidate-heart-cand-a')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      runStorage._store[run.id]!.candidateById('cand-a')!.review.heart,
      isFalse,
    );
  });

  testWidgets('filter chips narrow the deck', (tester) async {
    final hearted = ExploreCandidate.shell(roundId: 'r-1', id: 'cand-t')
        .copyWith(
          generation: const ExploreCandidateGeneration(
            status: ExploreCandidateGenerationStatus.done,
          ),
          review: const ExploreCandidateReview(heart: true),
        );
    final plain = ExploreCandidate.shell(roundId: 'r-1', id: 'cand-p').copyWith(
      generation: const ExploreCandidateGeneration(
        status: ExploreCandidateGenerationStatus.done,
      ),
    );
    final failed = ExploreCandidate.shell(roundId: 'r-1', id: 'cand-f')
        .copyWith(
          generation: const ExploreCandidateGeneration(
            status: ExploreCandidateGenerationStatus.failed,
            error: 'boom',
          ),
        );
    final inFolder = ExploreCandidate.shell(roundId: 'r-1', id: 'cand-d')
        .copyWith(
          generation: const ExploreCandidateGeneration(
            status: ExploreCandidateGenerationStatus.done,
          ),
          folderId: 'folder-a',
        );
    final run = await seedRun(
      '筛选任务',
      status: ExploreRunStatus.generated,
      candidates: [hearted, plain, failed, inFolder],
    );
    await runStorage.putRun(
      run.copyWith(
        folders: [
          ExploreCandidateFolder(
            id: 'folder-a',
            name: '暖光',
            createdAt: DateTime.utc(2026, 9, 16),
          ),
        ],
      ),
    );
    final container = await pumpScreen(tester);
    container.read(exploreActiveRunIdProvider.notifier).state = run.id;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('explore-candidate-cand-t')), findsOneWidget);
    expect(find.byKey(const Key('explore-candidate-cand-p')), findsOneWidget);
    expect(find.byKey(const Key('explore-candidate-cand-f')), findsOneWidget);
    expect(find.byKey(const Key('explore-candidate-cand-d')), findsOneWidget);
    // 「失败」chip 已退役（FEAT-58），失败候选只在「全部」可见。
    expect(find.byKey(const Key('explore-filter-failed')), findsNothing);

    // 收藏筛选。
    await tester.tap(find.byKey(const Key('explore-filter-hearted')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('explore-candidate-cand-t')), findsOneWidget);
    expect(find.byKey(const Key('explore-candidate-cand-p')), findsNothing);
    expect(find.byKey(const Key('explore-candidate-cand-f')), findsNothing);

    // 文件夹筛选：自建文件夹 chip 出现在收藏之后。
    await tester.tap(find.byKey(const Key('explore-filter-folder-folder-a')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('explore-candidate-cand-d')), findsOneWidget);
    expect(find.byKey(const Key('explore-candidate-cand-t')), findsNothing);
    expect(find.byKey(const Key('explore-candidate-cand-p')), findsNothing);

    // 未分类筛选：folderId 为空的候选（含失败占位）。chip 排在文件夹区
    // 末尾，窄面板下被横滚推出可视区，先把筛选排滚到底再点。
    await scrollChipRowToEnd(tester);
    await tester.tap(find.byKey(const Key('explore-filter-uncategorized')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('explore-candidate-cand-t')), findsOneWidget);
    expect(find.byKey(const Key('explore-candidate-cand-p')), findsOneWidget);
    expect(find.byKey(const Key('explore-candidate-cand-f')), findsOneWidget);
    expect(find.byKey(const Key('explore-candidate-cand-d')), findsNothing);
    // 筛选叠加在牌堆分组之上（牌堆常驻，无视图切换）。
    expect(
      find.byKey(const Key('explore-deck-header-uncategorized')),
      findsOneWidget,
    );

    // 回到全部（先滚回筛选排最左，「全部」chip 已被懒回收）。
    await scrollChipRowToEnd(tester, toEnd: false);
    await tester.tap(find.byKey(const Key('explore-filter-all')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('explore-candidate-cand-p')), findsOneWidget);
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

  testWidgets('generated run hides basic-round controls', (tester) async {
    final run = await seedRun(
      '追加轮任务',
      targetCount: 6,
      status: ExploreRunStatus.generated,
    );
    final container = await pumpScreen(tester);
    container.read(exploreActiveRunIdProvider.notifier).state = run.id;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 基础轮出图数、draft 开始和 generated 再来一轮均由主生成控制条承载。
    expect(find.byKey(const Key('explore-run-target-count')), findsNothing);
    expect(find.byKey(const Key('explore-run-another-round')), findsNothing);
    expect(find.byKey(const Key('explore-run-start')), findsNothing);
    expect(find.text('共 0 张'), findsOneWidget);
  });

  // ==================== 候选详情：翻页与归类 ====================

  ExploreCandidate doneCandidate(
    String id, {
    ExploreRollSnapshot? roll,
    String? folderId,
    String? filePath,
  }) {
    return ExploreCandidate.shell(roundId: 'r-1', id: id).copyWith(
      rollSnapshot: roll,
      folderId: folderId,
      generation: ExploreCandidateGeneration(
        status: ExploreCandidateGenerationStatus.done,
        filePath: filePath,
        seed: 42,
      ),
    );
  }

  testWidgets('detail dialog pages with arrows and keyboard, stops at ends', (
    tester,
  ) async {
    // 各配独立 roll 串，用详情弹窗的正向快照文本做「当前显示哪张」的探针。
    final run = await seedRun(
      '翻页任务',
      status: ExploreRunStatus.generated,
      candidates: [
        doneCandidate(
          'cand-1',
          roll: const ExploreRollSnapshot(positive: 'pos-1', negative: 'neg'),
        ),
        doneCandidate(
          'cand-2',
          roll: const ExploreRollSnapshot(positive: 'pos-2', negative: 'neg'),
        ),
        doneCandidate(
          'cand-3',
          roll: const ExploreRollSnapshot(positive: 'pos-3', negative: 'neg'),
        ),
      ],
    );
    final container = await pumpScreen(tester);
    container.read(exploreActiveRunIdProvider.notifier).state = run.id;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 打开 cand-2：翻页序 = 打开瞬间的筛选快照，按展示序（最新在前，
    // 与画廊 .reversed 对齐）→ 序列 [cand-3, cand-2, cand-1]，
    // cand-2 在 index 1 = 第 2/3 张；← 到 cand-3、→ 到 cand-1。
    await tester.tap(find.byKey(const Key('explore-candidate-cand-2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('explore-candidate-detail')), findsOneWidget);
    expect(find.text('第 2/3 张'), findsOneWidget);
    expect(find.text('pos-2'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(find.text('第 1/3 张'), findsOneWidget);
    expect(find.text('pos-3'), findsOneWidget);
    // 已到首张：左箭头按钮消失且再按 ← 原地不动（不循环）。
    expect(find.byKey(const Key('explore-candidate-prev')), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(find.text('第 1/3 张'), findsOneWidget);
    expect(find.text('pos-3'), findsOneWidget);

    // 小键盘 → 与普通 → 等价。
    await tester.sendKeyEvent(LogicalKeyboardKey.numpad6);
    await tester.pump();
    expect(find.text('第 2/3 张'), findsOneWidget);
    expect(find.text('pos-2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('explore-candidate-next')));
    await tester.pump();
    expect(find.text('第 3/3 张'), findsOneWidget);
    expect(find.text('pos-1'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.text('第 3/3 张'), findsOneWidget);
    expect(find.byKey(const Key('explore-candidate-next')), findsNothing);
  });

  testWidgets('detail dialog assigns folder, persists and jumps to next '
      'uncategorized', (tester) async {
    final folder = ExploreCandidateFolder(
      id: 'folder-a',
      name: '暖光',
      createdAt: DateTime.utc(2026, 9, 14),
    );
    // 各配独立 roll 串作探针：翻页序 = 展示序（最新在前）→
    // 序列 [cand-3, cand-2, cand-1]，「下一张未分类」沿序列向更旧方向推进。
    final run = await seedRun(
      '归类任务',
      status: ExploreRunStatus.generated,
      candidates: [
        doneCandidate(
          'cand-1',
          roll: const ExploreRollSnapshot(positive: 'pos-1', negative: 'neg'),
        ),
        doneCandidate(
          'cand-2',
          roll: const ExploreRollSnapshot(positive: 'pos-2', negative: 'neg'),
        ),
        doneCandidate(
          'cand-3',
          roll: const ExploreRollSnapshot(positive: 'pos-3', negative: 'neg'),
        ),
      ],
    );
    await runStorage.putRun(run.copyWith(folders: [folder]));
    final container = await pumpScreen(tester);
    container.read(exploreActiveRunIdProvider.notifier).state = run.id;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 从最新的 cand-3（序列 index 0）开始连续归档。
    await tester.tap(find.byKey(const Key('explore-candidate-cand-3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final assignChip = find.byKey(const Key('explore-assign-folder-folder-a'));
    expect(assignChip, findsOneWidget);
    expect(tester.widget<FilterChip>(assignChip).selected, isFalse);
    expect(find.text('第 1/3 张'), findsOneWidget);
    expect(find.text('pos-3'), findsOneWidget);

    // 点文件夹即归档落盘 + 自动跳序列下一张未分类（更旧方向）。
    await tester.tap(assignChip);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      runStorage._store[run.id]!.candidateById('cand-3')!.folderId,
      'folder-a',
    );
    expect(find.text('第 2/3 张'), findsOneWidget);
    expect(find.text('pos-2'), findsOneWidget);

    // 再归档第二张 → 跳到第三张（最旧的 cand-1）。
    await tester.tap(assignChip);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      runStorage._store[run.id]!.candidateById('cand-2')!.folderId,
      'folder-a',
    );
    expect(find.text('第 3/3 张'), findsOneWidget);
    expect(find.text('pos-1'), findsOneWidget);

    // 回看第二张：归属态在弹窗内高亮。
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(find.text('第 2/3 张'), findsOneWidget);
    expect(find.text('pos-2'), findsOneWidget);
    expect(tester.widget<FilterChip>(assignChip).selected, isTrue);

    // 再点当前文件夹 = 移回未分类（不删图、不跳页）。
    await tester.tap(assignChip);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      runStorage._store[run.id]!.candidateById('cand-2')!.folderId,
      isNull,
    );
    expect(find.text('第 2/3 张'), findsOneWidget);
  });

  testWidgets('newest candidate renders first with storage-bound numbering', (
    tester,
  ) async {
    final run = await seedRun(
      '排序任务',
      status: ExploreRunStatus.generated,
      candidates: [
        doneCandidate('cand-1'),
        doneCandidate('cand-2'),
        doneCandidate('cand-3'),
      ],
    );
    final container = await pumpScreen(tester);
    container.read(exploreActiveRunIdProvider.notifier).state = run.id;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 展示层反转：最后追加的候选排最前（组内同序）。
    final newest = tester.getTopLeft(
      find.byKey(const Key('explore-candidate-cand-3')),
    );
    final oldest = tester.getTopLeft(
      find.byKey(const Key('explore-candidate-cand-1')),
    );
    expect(
      newest.dy < oldest.dy ||
          (newest.dy == oldest.dy && newest.dx < oldest.dx),
      isTrue,
      reason: '首张卡 = 最后追加的候选',
    );
    // #N 绑存储序：最新那张拿最大序号，最早那张仍是 #1。
    expect(
      find.descendant(
        of: find.byKey(const Key('explore-candidate-cand-3')),
        matching: find.text('#3'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('explore-candidate-cand-1')),
        matching: find.text('#1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('toolbar creates a folder that groups the deck', (tester) async {
    final run = await seedRun(
      '牌堆任务',
      status: ExploreRunStatus.generated,
      candidates: [
        doneCandidate('cand-1', folderId: 'folder-a'),
        doneCandidate('cand-2'),
      ],
    );
    final folder = ExploreCandidateFolder(
      id: 'folder-a',
      name: '暖光',
      createdAt: DateTime.utc(2026, 9, 14),
    );
    await runStorage.putRun(run.copyWith(folders: [folder]));
    final container = await pumpScreen(tester);
    container.read(exploreActiveRunIdProvider.notifier).state = run.id;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 筛选排 = 全部/收藏 + 自建文件夹 chips + 末尾未分类；「失败」已退役。
    expect(find.byKey(const Key('explore-filter-all')), findsOneWidget);
    expect(find.byKey(const Key('explore-filter-hearted')), findsOneWidget);
    expect(find.byKey(const Key('explore-filter-failed')), findsNothing);
    expect(
      find.byKey(const Key('explore-filter-folder-folder-a')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('explore-filter-uncategorized')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('explore-formal-review')), findsNothing);
    // 视图切换已删：牌堆常驻，无切换钮。
    expect(find.byKey(const Key('explore-gallery-view-toggle')), findsNothing);

    expect(find.text('暖光 · 1'), findsOneWidget);
    expect(find.text('未分类 · 1'), findsOneWidget);
    expect(
      find.byKey(const Key('explore-deck-header-uncategorized')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('explore-folder-rename-folder-a')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('explore-folder-delete-folder-a')),
      findsOneWidget,
    );
    for (final id in const ['cand-1', 'cand-2']) {
      expect(find.byKey(Key('explore-candidate-$id')), findsOneWidget);
    }

    // 工具条新建文件夹：命名框 → 牌堆出现新组。
    await tester.tap(find.byKey(const Key('explore-gallery-new-folder')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '冷光',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '确定'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3300));
    expect(find.text('冷光 · 0'), findsNothing, reason: '空组不渲染');
    expect(
      find.byKey(const Key('explore-deck-header-uncategorized')),
      findsOneWidget,
    );
    expect(runStorage._store[run.id]!.folders.map((f) => f.name), ['暖光', '冷光']);
  });

  testWidgets('deleting a folder returns its candidates to uncategorized', (
    tester,
  ) async {
    final folder = ExploreCandidateFolder(
      id: 'folder-a',
      name: '暖光',
      createdAt: DateTime.utc(2026, 9, 14),
    );
    final run = await seedRun(
      '删组任务',
      status: ExploreRunStatus.generated,
      candidates: [doneCandidate('cand-1', folderId: 'folder-a')],
    );
    await runStorage.putRun(run.copyWith(folders: [folder]));
    final container = await pumpScreen(tester);
    container.read(exploreActiveRunIdProvider.notifier).state = run.id;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('explore-folder-delete-folder-a')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('删除文件夹'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3300));

    final stored = runStorage._store[run.id]!;
    expect(stored.folders, isEmpty);
    expect(stored.candidateById('cand-1')!.folderId, isNull);
    expect(stored.candidateById('cand-1')!.generation.filePath, isNull);
    expect(find.byKey(const Key('explore-candidate-cand-1')), findsOneWidget);
    expect(
      find.byKey(const Key('explore-deck-header-uncategorized')),
      findsOneWidget,
    );
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
    // 多选模式同走牌堆分组（无视图切换）。
    expect(
      find.byKey(const Key('explore-deck-header-uncategorized')),
      findsOneWidget,
    );

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

  testWidgets('any candidate with a copy can delete its image', (tester) async {
    final imageStore = _FakeRunImageStore();
    const copyPath = '/tmp/style_explore_runs/run-1/cand-1.png';

    final run = await seedRun(
      '删图任务',
      status: ExploreRunStatus.generated,
      candidates: [
        // 无副本：不提供删除图片。
        doneCandidate('cand-no-copy'),
        doneCandidate('cand-1', filePath: copyPath),
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

    await tester.tap(find.byKey(const Key('explore-candidate-cand-no-copy')));
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

    // 有副本候选：删除图片 → 确认 → 副本删除 + 记录连删（FEAT-55）。
    await tester.tap(find.byKey(const Key('explore-candidate-cand-1')));
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

    expect(imageStore.deletedPaths, [copyPath]);
    final storedRun = runStorage._store[run.id]!;
    expect(
      storedRun.candidateById('cand-1'),
      isNull,
      reason: 'FEAT-55 拍板 = 连记录删，候选整条移除',
    );
    expect(
      storedRun.candidateById('cand-no-copy'),
      isNotNull,
      reason: '未删的候选不受影响',
    );
    // 画廊卡消失（不再留破图占位）。
    expect(find.byKey(const Key('explore-candidate-cand-1')), findsNothing);
  });

  testWidgets('multi-select bar delete button batch-deletes copies '
      'and exits selection (FEAT-56)', (tester) async {
    final imageStore = _FakeRunImageStore();
    const copyPath1 = '/tmp/style_explore_runs/run-1/cand-1.png';
    const copyPath2 = '/tmp/style_explore_runs/run-1/cand-2.png';

    final run = await seedRun(
      '多选删图',
      status: ExploreRunStatus.generated,
      candidates: [
        doneCandidate('cand-1', filePath: copyPath1),
        doneCandidate('cand-2', filePath: copyPath2),
        // 无副本：不参与删除、不计数。
        doneCandidate('cand-no-copy'),
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

    const deleteKey = Key('explore-gallery-delete');
    // 多选未开 → 无删除钮。
    expect(find.byKey(deleteKey), findsNothing);

    await tester.tap(find.byKey(const Key('explore-gallery-select-toggle')));
    await tester.pump();
    // 无底色形制 = TextButton（key 挂在钮本体）+ error 前景。
    expect(find.byKey(deleteKey), findsOneWidget);
    expect(tester.widget(find.byKey(deleteKey)), isA<TextButton>());

    // 空选择 → 钮禁用；选无副本项 → 仍禁用；选有副本项 → 启用。
    expect(tester.widget<TextButton>(find.byKey(deleteKey)).onPressed, isNull);
    await tester.tap(find.byKey(const Key('explore-candidate-cand-no-copy')));
    await tester.pump();
    expect(tester.widget<TextButton>(find.byKey(deleteKey)).onPressed, isNull);
    await tester.tap(find.byKey(const Key('explore-candidate-cand-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('explore-candidate-cand-2')));
    await tester.pump();
    expect(
      tester.widget<TextButton>(find.byKey(deleteKey)).onPressed,
      isNotNull,
    );

    // 取消流：确认框计数只含有副本张数（2），取消不动。
    await tester.tap(find.byKey(deleteKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('删除所选候选图'), findsOneWidget);
    expect(find.text('将删除 2 张候选在 Run 目录中的图片副本与候选记录；图库源图不受影响。'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(imageStore.deletedPaths, isEmpty);
    expect(find.text('已选 3 张'), findsOneWidget, reason: '取消保留多选');

    // 确认流：逐张删副本 + 清 filePath + 成功退多选。
    await tester.tap(find.byKey(deleteKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.widgetWithText(FilledButton, '删除图片'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 3300));

    expect(imageStore.deletedPaths, [copyPath1, copyPath2]);
    final stored = runStorage._store[run.id]!;
    // FEAT-55：连记录删——候选整条移除，画廊卡消失。
    expect(stored.candidateById('cand-1'), isNull);
    expect(stored.candidateById('cand-2'), isNull);
    expect(stored.candidateById('cand-no-copy'), isNotNull);
    expect(find.byKey(const Key('explore-candidate-cand-1')), findsNothing);
    expect(
      find.byKey(const Key('explore-gallery-select-toggle')),
      findsOneWidget,
      reason: '删成功退多选（照合并收编先例）',
    );
  });
}
