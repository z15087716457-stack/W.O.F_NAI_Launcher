import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_folder_assign_bar.dart';
// ignore: depend_on_referenced_packages
import 'package:irondash_message_channel/irondash_message_channel.dart';
// ignore: implementation_imports, depend_on_referenced_packages
import 'package:super_native_extensions/src/native/context.dart';
import 'package:nai_launcher/presentation/themes/presets/geist_theme.dart';
import 'package:nai_launcher/presentation/widgets/common/update_capsule.dart';
import 'package:nai_launcher/presentation/widgets/navigation/integrated_title_bar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_controls.dart';
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
import 'package:nai_launcher/presentation/screens/style_explore/ui/explore_editor.dart';
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
  Future<void> putRun(ExploreRun run, {void Function()? beforeWrite}) async {
    beforeWrite?.call();
    _store[run.id] = run;
  }

  @override
  ExploreRun? currentRun(String id) => _store[id];

  @override
  Future<ExploreRun> transformRun(
    String id,
    ExploreRun Function(ExploreRun) update,
  ) async {
    final next = update(_store[id]!);
    _store[id] = next;
    return next;
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

class _OneBlockLibraryNotifier extends PromptBlockLibraryNotifier {
  _OneBlockLibraryNotifier(this.block);
  final PromptBlock block;
  @override
  Future<PromptBlockLibraryState> build() async =>
      PromptBlockLibraryState(blocks: [block], folders: const []);
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
    String appearance = 'classic',
    String? readingTranslationZh,
    List<Map<String, dynamic>>? readingTranslationMarks,
    bool readingTranslationNeedsReview = false,
    bool readingTranslationEdited = false,
    String readingTranslationLanguageCode = 'zh',
    String? iconName,
    String? thumbnail,
    double thumbnailOffsetX = 0.0,
    double thumbnailOffsetY = 0.0,
    double thumbnailScale = 1.0,
    int? sortOrder,
    List<String>? atoms,
    String negativeContent = '',
    List<String>? negativeAtoms,
    PromptBlockGenerationSettings? generationSettings,
    List<PromptBlockTag> tags = const [],
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
      appearance: appearance,
      readingTranslationZh: readingTranslationZh,
      readingTranslationMarks: readingTranslationMarks,
      readingTranslationNeedsReview: readingTranslationNeedsReview,
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
  TestWidgetsFlutterBinding.ensureInitialized();
  setContextOverride(
    MockMessageChannelContext()
      ..registerMockMethodCallHandler('DropManager', (_) async => null)
      ..registerMockMethodCallHandler('DragManager', (_) async => null),
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('dev.irondash.engine_context'),
        (_) async => 1,
      );

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
    final run =
        ExploreRun.create(
          name: name,
          recipeSnapshot: ExploreRecipeSnapshot(
            positive: doc('pos'),
            negative: doc('neg'),
          ),
          paramsSnapshot: testSnapshot(),
          targetCount: targetCount,
        ).copyWith(
          status: status,
          candidates: candidates,
          rounds: [
            for (final id in candidates.map((c) => c.roundId).toSet())
              ExploreRound(
                id: id,
                number:
                    candidates
                        .map((c) => c.roundId)
                        .toSet()
                        .toList()
                        .indexOf(id) +
                    1,
                phase: ExploreRoundPhase.manual,
                status: ExploreRoundStatus.generated,
                createdAt: DateTime(2026, 9, 14),
                targetCount: candidates.where((c) => c.roundId == id).length,
                candidateIds: candidates
                    .where((c) => c.roundId == id)
                    .map((c) => c.id)
                    .toList(),
              ),
          ],
        );
    await runStorage.putRun(run);
    return run;
  }

  Widget buildScreen({
    List<Override> extraOverrides = const [],
    Offset appOffset = Offset.zero,
    bool? dark,
    bool update = false,
    GlobalKey? captureKey,
  }) {
    final app = ProviderScope(
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
      child: MaterialApp(
        theme: dark == null
            ? null
            : (dark ? GeistTheme.dark : GeistTheme.light).copyWith(
                textTheme: (dark ? GeistTheme.dark : GeistTheme.light).textTheme
                    .apply(fontFamily: 'HarmonyOS Sans SC'),
              ),
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RepaintBoundary(
          key: captureKey,
          child: IntegratedTitleBarShell(
            accessoryWidth: update ? UpdateCapsule.width : 0,
            accessory: update ? UpdateCapsule(onPressed: () {}) : null,
            child: const StyleExploreScreen(),
          ),
        ),
      ),
    );
    if (appOffset == Offset.zero) return app;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          Positioned(
            left: appOffset.dx,
            top: appOffset.dy,
            right: 0,
            bottom: 0,
            child: app,
          ),
        ],
      ),
    );
  }

  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    double width = 1600,
    List<Override> extraOverrides = const [],
    Offset appOffset = Offset.zero,
    bool populated = false,
  }) async {
    // 宽窗：左栏 + 右栏画廊都展开（画廊默认断点 1100）。
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      buildScreen(extraOverrides: extraOverrides, appOffset: appOffset),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    if (populated) {
      final run = await seedRun(
        'Pane layout',
        status: ExploreRunStatus.generated,
        candidates: [
          ExploreCandidate.shell(
            roundId: 'pane-round',
            id: 'pane-candidate',
          ).copyWith(
            generation: const ExploreCandidateGeneration(
              status: ExploreCandidateGenerationStatus.done,
            ),
          ),
        ],
      );
      await container.read(exploreRunListNotifierProvider.notifier).refresh();
      container.read(exploreActiveRunIdProvider.notifier).state = run.id;
      await tester.pumpAndSettle();
    }
    return container;
  }

  Rect mainRect(WidgetTester tester) =>
      tester.getRect(find.byKey(const Key('style-explore-main-editor')));

  Rect stageRect(WidgetTester tester) =>
      tester.getRect(find.byKey(const Key('style-explore-stage')));

  Rect inspectorRect(WidgetTester tester) =>
      tester.getRect(find.byKey(const Key('style-explore-inspector')));

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

  testWidgets('three panes and top bar replace the old sidebar', (
    tester,
  ) async {
    await pumpScreen(tester, populated: true);
    expect(mainRect(tester).width, 384);
    expect(stageRect(tester).width, 904);
    expect(inspectorRect(tester).width, 312);
    expect(
      tester.getSize(find.byKey(const Key('explore-stage-header'))).height,
      52,
    );
    expect(
      find.byKey(const Key('explore-run-switcher-button')),
      findsOneWidget,
    );
    expect(find.text('选一张候选查看详情'), findsOneWidget);
    expect(find.byKey(const Key('style-explore-run-sidebar')), findsNothing);
    expect(find.byKey(const Key('explore-run-start')), findsNothing);
    expect(find.byType(ExploreGenerateButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('first use keeps the stage open and omits the empty inspector', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(mainRect(tester).width, 384);
    expect(stageRect(tester).width, 1216);
    expect(find.byKey(const Key('style-explore-inspector')), findsNothing);
    expect(find.byKey(const Key('explore-onboarding-step-2')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow auto inspector does not store a manual preference', (
    tester,
  ) async {
    final container = await pumpScreen(tester, width: 1000);
    expect(find.byKey(const Key('style-explore-inspector')), findsNothing);
    expect(stageRect(tester).width, 616);
    expect(
      container.read(layoutStateNotifierProvider).styleExploreInspectorVisible,
      isNull,
    );
    await tester.ensureVisible(
      find.byKey(const Key('explore-onboarding-previous')),
    );
    await tester.tap(find.byKey(const Key('explore-onboarding-previous')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('style-explore-inspector-menu-toggle')),
    );
    await tester.pumpAndSettle();
    // Docking would crush the editor below 352, so the inspector floats.
    expect(find.byKey(const Key('style-explore-inspector')), findsOneWidget);
    expect(stageRect(tester).width, 616);
    expect(mainRect(tester).width, 384);
    expect(inspectorRect(tester), const Rect.fromLTWH(688, 0, 312, 900));
    expect(
      container.read(layoutStateNotifierProvider).styleExploreEditorWidth,
      384,
    );
    tester.view.physicalSize = const Size(900, 900);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('style-explore-inspector')), findsOneWidget);
    expect(stageRect(tester).width, 516);
    expect(mainRect(tester).width, 384);
    expect(
      container.read(layoutStateNotifierProvider).styleExploreInspectorVisible,
      true,
    );
    await tester.tap(find.byKey(const Key('style-explore-inspector-close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('style-explore-inspector')), findsNothing);
    expect(
      container.read(layoutStateNotifierProvider).styleExploreInspectorVisible,
      false,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'manual inspector preference persists across a new provider scope',
    (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('explore-onboarding-previous')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('style-explore-inspector-menu-toggle')),
      );
      await tester.pumpAndSettle();
      expect(
        localStorage.settings[StorageKeys.styleExploreInspectorVisible],
        true,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('style-explore-inspector')), findsOneWidget);
    },
  );

  testWidgets('stored old sidebar values are ignored', (tester) async {
    localStorage.settings.addAll({
      'style_explore_run_sidebar_width': 999.0,
      'style_explore_gallery_width': 888.0,
      'style_explore_run_sidebar_visible': false,
    });
    await pumpScreen(tester, populated: true);
    expect(mainRect(tester).width, 384);
    expect(inspectorRect(tester).width, 312);
  });

  testWidgets('pane resizing clamps without redistributing the other pane', (
    tester,
  ) async {
    final container = await pumpScreen(tester, populated: true);
    await tester.drag(
      find.byKey(const Key('style-explore-editor-resize-handle')),
      const Offset(400, 0),
    );
    await tester.pumpAndSettle();
    expect(
      container.read(layoutStateNotifierProvider).styleExploreEditorWidth,
      560,
    );
    expect(inspectorRect(tester).width, 312);
    await tester.drag(
      find.byKey(const Key('style-explore-inspector-resize-handle')),
      const Offset(-400, 0),
    );
    await tester.pumpAndSettle();
    expect(
      container.read(layoutStateNotifierProvider).styleExploreInspectorWidth,
      420,
    );
    expect(mainRect(tester).width, 560);
    expect(localStorage.settings[StorageKeys.styleExploreEditorWidth], 560);
    expect(localStorage.settings[StorageKeys.styleExploreInspectorWidth], 420);
  });

  testWidgets(
    'block library overlays the stage and its resize leaves panes fixed',
    (tester) async {
      final container = await pumpScreen(tester, populated: true);
      final before = [
        mainRect(tester),
        stageRect(tester),
        inspectorRect(tester),
      ];
      final notifier = container.read(layoutStateNotifierProvider.notifier);
      await notifier.setBlockLibraryPanelExpanded(true);
      await tester.pumpAndSettle();
      expect([
        mainRect(tester),
        stageRect(tester),
        inspectorRect(tester),
      ], before);
      expect(
        tester.getRect(find.byType(BlockLibraryPanelSlot)).left,
        stageRect(tester).left,
      );
      expect(
        tester.getRect(find.byType(BlockLibraryPanelSlot)).height,
        stageRect(tester).height,
      );
      await tester.drag(
        find.byKey(const Key('block-library-panel-resize-handle')),
        const Offset(60, 0),
      );
      await tester.pumpAndSettle();
      expect(
        container.read(layoutStateNotifierProvider).blockLibraryPanelWidth,
        closeTo(380, 1),
      );
      expect([
        mainRect(tester),
        stageRect(tester),
        inspectorRect(tester),
      ], before);
      await notifier.setBlockLibraryPanelExpanded(false);
      await tester.pumpAndSettle();
      expect([
        mainRect(tester),
        stageRect(tester),
        inspectorRect(tester),
      ], before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('overlay block can still be dragged into the main prompt', (
    tester,
  ) async {
    final block = PromptBlock.create(
      title: '拖入画师池',
      content: 'artist:ciloranko',
    );
    final container = await pumpScreen(
      tester,
      populated: true,
      extraOverrides: [
        promptBlockLibraryNotifierProvider.overrideWith(
          () => _OneBlockLibraryNotifier(block),
        ),
      ],
    );
    await container
        .read(layoutStateNotifierProvider.notifier)
        .setBlockLibraryPanelExpanded(true);
    await tester.pumpAndSettle();
    final chip = find.byKey(ValueKey('block-library-chip-${block.id}'));
    expect(chip, findsOneWidget);
    final input = find
        .descendant(
          of: find.byKey(const Key('generation_prompt_positive_input')),
          matching: find.byType(EditableText),
        )
        .first;
    final gesture = await tester.startGesture(tester.getCenter(chip));
    await gesture.moveBy(const Offset(-30, 0));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(input));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      container
          .read(pillWorkspaceProvider(PillScopes.main))
          .document
          .instances
          .values
          .any((i) => i.blockId == block.id),
      true,
    );
    expect(
      container.read(generationParamsNotifierProvider).prompt,
      contains('artist:ciloranko'),
    );
    expect(mainRect(tester).width, 384);
    expect(inspectorRect(tester).width, 312);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'oversized overlay fits the stage without changing stored dock width',
    (tester) async {
      final container = await pumpScreen(tester, width: 1280);
      final layout = container.read(layoutStateNotifierProvider.notifier);
      await layout.setBlockLibraryPanelWidth(999);
      await layout.setBlockLibraryPanelExpanded(true);
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(BlockLibraryPanelSlot)).width,
        stageRect(tester).width,
      );
      expect(
        container.read(layoutStateNotifierProvider).blockLibraryPanelWidth,
        999,
      );
      await tester.drag(
        find.byKey(const Key('block-library-panel-resize-handle')),
        const Offset(-40, 0),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(BlockLibraryPanelSlot)).width,
        closeTo(stageRect(tester).width - 40, 1),
      );
      expect(mainRect(tester).width, 384);
      expect(find.byKey(const Key('style-explore-inspector')), findsNothing);
      expect(
        container.read(layoutStateNotifierProvider).styleExploreInspectorWidth,
        312,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('1280 inspector hides automatically and manual opening wins', (
    tester,
  ) async {
    final container = await pumpScreen(tester, width: 1280);
    expect(find.byKey(const Key('style-explore-inspector')), findsNothing);
    expect(stageRect(tester).width, greaterThanOrEqualTo(480));
    expect(
      container.read(layoutStateNotifierProvider).styleExploreInspectorVisible,
      isNull,
    );
    await container
        .read(layoutStateNotifierProvider.notifier)
        .setStyleExploreInspectorVisible(true);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('style-explore-inspector')), findsOneWidget);
    expect(stageRect(tester).width, greaterThanOrEqualTo(480));
  });

  for (final dark in [false, true]) {
    testWidgets(
      'inspector caption region preserves 52 high header (${dark ? 'dark' : 'light'})',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildScreen(dark: dark, update: true));
        final container = ProviderScope.containerOf(
          tester.element(find.byType(MaterialApp)),
        );
        await container
            .read(layoutStateNotifierProvider.notifier)
            .setStyleExploreInspectorVisible(true);
        await tester.pumpAndSettle();
        final captions = tester.getRect(
          find.byKey(const Key('window-caption-controls')),
        );
        final title = tester.getRect(find.text('详情'));
        expect(title.top, lessThan(52));
        expect(title.overlaps(captions), false);
        expect(
          title.overlaps(
            tester.getRect(find.byKey(const Key('window-update-capsule'))),
          ),
          false,
        );
        expect(
          tester.getSize(find.byKey(const Key('explore-stage-header'))).height,
          52,
        );
        expect(captions.right, 1600);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'new exploration snapshots current editor and enters inline naming without a dialog',
    (tester) async {
      final container = await pumpScreen(tester);
      container
          .read(pillWorkspaceProvider(PillScopes.main).notifier)
          .replaceWithPlainText('fresh main');
      container
          .read(pillWorkspaceProvider(PillScopes.negative).notifier)
          .replaceWithPlainText('fresh negative');
      await tester.pump();
      await tester.tap(find.byKey(const Key('explore-onboarding-previous')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('style-explore-new-run')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      final list = container.read(exploreRunListNotifierProvider).requireValue;
      final run = list.runs.single;
      expect(run.targetCount, 10);
      expect(run.recipeSnapshot.positive.text, 'fresh main');
      expect(run.recipeSnapshot.negative.text, 'fresh negative');
      expect(container.read(exploreActiveRunIdProvider), run.id);
      expect(find.byKey(const Key('explore-run-inline-name')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('explore-run-inline-name')),
        '',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(find.text('名称不能为空'), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('explore-run-inline-name')),
        '新探索甲',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(
        container
            .read(exploreRunListNotifierProvider)
            .requireValue
            .runs
            .single
            .name,
        '新探索甲',
      );
      expect(find.byKey(const Key('explore-run-inline-name')), findsNothing);
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

  testWidgets('main prompt wraps within the actual editor pane width', (
    tester,
  ) async {
    final container = await pumpScreen(tester, width: 1200);
    final layoutNotifier = container.read(layoutStateNotifierProvider.notifier);
    await layoutNotifier.setBlockLibraryPanelExpanded(true);
    await layoutNotifier.setBlockLibraryPanelWidth(220);
    await layoutNotifier.setStyleExploreEditorWidth(384);
    await layoutNotifier.setStyleExploreInspectorWidth(312);
    await layoutNotifier.setStyleExploreInspectorVisible(true);

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
    expect(find.byKey(const Key('style-explore-stage')), findsOneWidget);
    expect(find.byKey(const Key('style-explore-inspector')), findsOneWidget);
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
    expect(find.byKey(const Key('explore-onboarding-step-1')), findsOneWidget);

    container.read(exploreActiveRunIdProvider.notifier).state = run.id;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 两张候选卡 + 序号文本。
    expect(find.byKey(const Key('explore-candidate-cand-a')), findsOneWidget);
    expect(find.byKey(const Key('explore-candidate-cand-b')), findsOneWidget);
    expect(find.text('图片已删除'), findsOneWidget);
    expect(find.text('生成失败'), findsOneWidget);
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
    final pointer = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await pointer.addPointer(
      location: tester.getCenter(
        find.byKey(const Key('explore-candidate-cand-a')),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('explore-candidate-heart-cand-a')));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final stored = runStorage._store[run.id]!;
    expect(stored.candidateById('cand-a')!.review.heart, isTrue);
    // 另一张不受影响。
    expect(stored.candidateById('cand-b')!.review.heart, isFalse);

    // 再点一次取消收藏。
    await tester.tap(find.byKey(const Key('explore-candidate-heart-cand-a')));
    await tester.pump(const Duration(milliseconds: 350));
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
    expect(find.byKey(const Key('explore-round-r-1')), findsOneWidget);

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
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const Key('explore-candidate-cand-d')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('explore-candidate-cand-d')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const Key('explore-candidate-detail')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('explore-candidate-detail')),
        matching: find.text('画风探索'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('explore-candidate-detail')),
        matching: find.text('987654'),
      ),
      findsOneWidget,
    );
    expect(find.text('4.3 s'), findsOneWidget);
    expect(find.text('soft light, watercolor'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('explore-candidate-detail')),
        matching: find.text('画风池'),
      ),
      findsOneWidget,
    );
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
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));

    // 基础轮出图数、draft 开始和 generated 再来一轮均由主生成控制条承载。
    expect(find.byKey(const Key('explore-run-target-count')), findsNothing);
    expect(find.byKey(const Key('explore-run-another-round')), findsNothing);
    expect(find.byKey(const Key('explore-run-start')), findsNothing);
    expect(
      find.byKey(const Key('explore-run-switcher-button')),
      findsOneWidget,
    );
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
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));

    // 打开 cand-2：翻页序 = 打开瞬间的筛选快照，按轮内生成顺序→ 序列 [cand-1, cand-2, cand-3]，
    // cand-2 在 index 1 = 第 2/3 张；← 到 cand-1、→ 到 cand-3。
    await tester.tap(find.byKey(const Key('explore-candidate-cand-2')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('explore-candidate-cand-2')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('explore-candidate-detail')), findsOneWidget);
    expect(find.textContaining('第 2 张 / 共 3 张'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('explore-candidate-detail')),
        matching: find.byWidgetPredicate(
          (w) =>
              w is SelectableText &&
              w.runtimeType == SelectableText &&
              (w.data ?? w.textSpan?.toPlainText()) == 'pos-2',
        ),
      ),
      findsOneWidget,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.textContaining('第 1 张 / 共 3 张'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('explore-candidate-detail')),
        matching: find.byWidgetPredicate(
          (w) =>
              w is SelectableText &&
              w.runtimeType == SelectableText &&
              (w.data ?? w.textSpan?.toPlainText()) == 'pos-1',
        ),
      ),
      findsOneWidget,
    );
    // 已到首张：左箭头按钮消失且再按 ← 原地不动（不循环）。
    expect(find.byKey(const Key('viewer-previous')), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.textContaining('第 1 张 / 共 3 张'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('explore-candidate-detail')),
        matching: find.byWidgetPredicate(
          (w) =>
              w is SelectableText &&
              w.runtimeType == SelectableText &&
              (w.data ?? w.textSpan?.toPlainText()) == 'pos-1',
        ),
      ),
      findsOneWidget,
    );

    // 小键盘 → 与普通 → 等价。
    await tester.sendKeyEvent(LogicalKeyboardKey.numpad6);
    await tester.pumpAndSettle();
    expect(find.textContaining('第 2 张 / 共 3 张'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('explore-candidate-detail')),
        matching: find.byWidgetPredicate(
          (w) =>
              w is SelectableText &&
              w.runtimeType == SelectableText &&
              (w.data ?? w.textSpan?.toPlainText()) == 'pos-2',
        ),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('viewer-next')));
    await tester.pumpAndSettle();
    expect(find.textContaining('第 3 张 / 共 3 张'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('explore-candidate-detail')),
        matching: find.byWidgetPredicate(
          (w) =>
              w is SelectableText &&
              w.runtimeType == SelectableText &&
              (w.data ?? w.textSpan?.toPlainText()) == 'pos-3',
        ),
      ),
      findsOneWidget,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.textContaining('第 3 张 / 共 3 张'), findsOneWidget);
    expect(find.byKey(const Key('viewer-next')), findsNothing);
  });

  testWidgets('detail dialog assigns folder, persists and jumps to next '
      'uncategorized', (tester) async {
    final folder = ExploreCandidateFolder(
      id: 'folder-a',
      name: '暖光',
      createdAt: DateTime.utc(2026, 9, 14),
    );
    // 各配独立 roll 串作探针：翻页序 = 轮内生成顺序→
    // 序列 [cand-1, cand-2, cand-3]，「下一张未分类」沿序列向更旧方向推进。
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
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));

    // 从最新的 cand-1（序列 index 0）开始连续归类。
    await tester.tap(find.byKey(const Key('explore-candidate-cand-1')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('explore-candidate-cand-1')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    final assignChip = find.byKey(const Key('explore-assign-folder-folder-a'));
    expect(assignChip, findsOneWidget);
    expect(tester.widget<ExploreGroupChip>(assignChip).selected, isFalse);
    expect(find.textContaining('第 1 张 / 共 3 张'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('explore-candidate-detail')),
        matching: find.byWidgetPredicate(
          (w) =>
              w is SelectableText &&
              w.runtimeType == SelectableText &&
              (w.data ?? w.textSpan?.toPlainText()) == 'pos-1',
        ),
      ),
      findsOneWidget,
    );

    // 点文件夹即归类落盘 + 自动跳序列下一张未分类（更旧方向）。
    await tester.tap(assignChip);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      runStorage._store[run.id]!.candidateById('cand-1')!.folderId,
      'folder-a',
    );
    expect(find.textContaining('第 2 张 / 共 3 张'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('explore-candidate-detail')),
        matching: find.byWidgetPredicate(
          (w) =>
              w is SelectableText &&
              w.runtimeType == SelectableText &&
              (w.data ?? w.textSpan?.toPlainText()) == 'pos-2',
        ),
      ),
      findsOneWidget,
    );

    // 再归类第二张 → 跳到第三张（最旧的 cand-3）。
    await tester.tap(assignChip);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      runStorage._store[run.id]!.candidateById('cand-2')!.folderId,
      'folder-a',
    );
    expect(find.textContaining('第 3 张 / 共 3 张'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('explore-candidate-detail')),
        matching: find.byWidgetPredicate(
          (w) =>
              w is SelectableText &&
              w.runtimeType == SelectableText &&
              (w.data ?? w.textSpan?.toPlainText()) == 'pos-3',
        ),
      ),
      findsOneWidget,
    );

    // 回看第二张：归属态在弹窗内高亮。
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.textContaining('第 2 张 / 共 3 张'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('explore-candidate-detail')),
        matching: find.byWidgetPredicate(
          (w) =>
              w is SelectableText &&
              w.runtimeType == SelectableText &&
              (w.data ?? w.textSpan?.toPlainText()) == 'pos-2',
        ),
      ),
      findsOneWidget,
    );
    expect(tester.widget<ExploreGroupChip>(assignChip).selected, isTrue);

    // 再点当前文件夹 = 移回未分类（不删图、不跳页）。
    await tester.tap(assignChip);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));
    expect(
      runStorage._store[run.id]!.candidateById('cand-2')!.folderId,
      isNull,
    );
    expect(find.textContaining('第 2 张 / 共 3 张'), findsOneWidget);
  });

  testWidgets('round candidates retain generation order', (tester) async {
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

    // 轮内保持生成顺序：首张候选排最前。
    final newest = tester.getTopLeft(
      find.byKey(const Key('explore-candidate-cand-1')),
    );
    final oldest = tester.getTopLeft(
      find.byKey(const Key('explore-candidate-cand-3')),
    );
    expect(
      newest.dy < oldest.dy ||
          (newest.dy == oldest.dy && newest.dx < oldest.dx),
      isTrue,
      reason: '轮内生成顺序保持不变',
    );
    expect(find.byKey(const Key('explore-round-r-1')), findsOneWidget);
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

    expect(find.text('暖光'), findsWidgets);
    expect(find.byKey(const Key('explore-round-r-1')), findsOneWidget);
    expect(
      find.byKey(const Key('explore-folder-rename-folder-a')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('explore-folder-delete-folder-a')),
      findsNothing,
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
    expect(find.byKey(const Key('explore-round-r-1')), findsOneWidget);
    expect(runStorage._store[run.id]!.folders.map((f) => f.name), ['暖光', '冷光']);
  });

  testWidgets(
    'folder right-click menu anchors to click without Overlay offset',
    (tester) async {
      final folder = ExploreCandidateFolder(
        id: 'folder-a',
        name: '暖光',
        createdAt: DateTime.utc(2026, 9, 14),
      );
      final run = await seedRun(
        '菜单定位任务',
        status: ExploreRunStatus.generated,
        candidates: [doneCandidate('cand-1', folderId: 'folder-a')],
      );
      await runStorage.putRun(run.copyWith(folders: [folder]));
      final container = await pumpScreen(
        tester,
        appOffset: const Offset(240, 120),
      );
      container.read(exploreActiveRunIdProvider.notifier).state = run.id;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final chip = find.byKey(const Key('explore-filter-folder-folder-a'));
      final clickPosition = tester.getCenter(chip);
      await tester.tap(chip, buttons: kSecondaryMouseButton);
      await tester.pumpAndSettle();

      final renameText = find.text('重命名分组');
      expect(renameText, findsOneWidget);
      final menuItemRect = tester.getRect(renameText);
      expect((menuItemRect.center.dx - clickPosition.dx).abs(), lessThan(220));
      expect(menuItemRect.top, lessThan(clickPosition.dy + 100));
      expect(
        tester.getSize(find.byKey(const Key('explore-folder-menu-rename'))),
        const Size(168, 40),
      );
      expect(
        tester.getSize(find.byKey(const Key('explore-folder-menu-delete'))),
        const Size(168, 40),
      );
    },
  );

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

    await tester.tap(
      find.byKey(const Key('explore-filter-folder-folder-a')),
      buttons: kSecondaryMouseButton,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('explore-folder-menu-delete')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('删除分组'), findsWidgets);
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3300));

    final stored = runStorage._store[run.id]!;
    expect(stored.folders, isEmpty);
    expect(stored.candidateById('cand-1')!.folderId, isNull);
    expect(stored.candidateById('cand-1')!.generation.filePath, isNull);
    expect(find.byKey(const Key('explore-candidate-cand-1')), findsOneWidget);
    expect(find.byKey(const Key('explore-round-r-1')), findsOneWidget);
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
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('explore-candidate-cand-1')));
    await tester.pumpAndSettle();
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
    expect(created.color, '#FF6E56CF');
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
      width: 1920,
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
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const Key('explore-candidate-cand-2')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('已选 2 张'), findsNWidgets(2));
    // 多选模式同走牌堆分组（无视图切换）。
    expect(find.byKey(const Key('explore-round-r-1')), findsOneWidget);

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
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('explore-candidate-cand-1')));
    await tester.pumpAndSettle();
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
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('explore-candidate-cand-no-copy')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('explore-candidate-delete-image')),
      findsNothing,
    );
    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('explore-candidate-detail')),
        matching: find.byKey(const Key('viewer-back')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 有副本候选：删除图片 → 确认 → 副本删除 + 记录连删（FEAT-55）。
    await tester.tap(find.byKey(const Key('explore-candidate-cand-1')));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('explore-candidate-cand-1')));
    await tester.pumpAndSettle();
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
      width: 1920,
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
    expect(find.byKey(deleteKey), findsNothing, reason: '空选择隐藏浮条');
    await tester.tap(find.byKey(const Key('explore-candidate-cand-no-copy')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      tester.widget<ExploreIconButton>(find.byKey(deleteKey)).onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('explore-candidate-cand-1')));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.byKey(const Key('explore-candidate-cand-2')));
    await tester.pump(const Duration(milliseconds: 350));
    expect(
      tester.widget<ExploreIconButton>(find.byKey(deleteKey)).onPressed,
      isNotNull,
    );

    // 取消流：确认框计数只含有副本张数（2），取消不动。
    await tester.tap(find.byKey(deleteKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('删除候选'), findsOneWidget);
    expect(find.text('将删除 3 张候选及其图片副本，图库源图保留。'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '取消'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(imageStore.deletedPaths, isEmpty);
    expect(find.text('已选 3 张'), findsNWidgets(2), reason: '取消保留多选');

    // 确认流：逐张删副本 + 清 filePath + 成功退多选。
    await tester.tap(find.byKey(deleteKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 3300));

    expect(imageStore.deletedPaths, [copyPath1, copyPath2]);
    final stored = runStorage._store[run.id]!;
    // FEAT-55：连记录删——候选整条移除，画廊卡消失。
    expect(stored.candidateById('cand-1'), isNull);
    expect(stored.candidateById('cand-2'), isNull);
    expect(stored.candidateById('cand-no-copy'), isNull);
    expect(find.byKey(const Key('explore-candidate-cand-1')), findsNothing);
    expect(
      find.byKey(const Key('explore-gallery-select-toggle')),
      findsOneWidget,
      reason: '删成功退多选（照合并收编先例）',
    );
  });
}
