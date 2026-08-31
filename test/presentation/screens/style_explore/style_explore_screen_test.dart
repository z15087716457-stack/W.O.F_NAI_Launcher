import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/style_explore_recipe_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/style_explore/style_explore_recipe.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
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

void main() {
  late _MemoryRecipeStorage recipeStorage;

  setUp(() {
    recipeStorage = _MemoryRecipeStorage();
  });

  PillDocument doc(String text) =>
      PillDocument(text: text, instances: const {});

  Future<StyleExploreRecipe> seedRecipe(String name, String positive) async {
    final recipe = StyleExploreRecipe.create(
      name: name,
      positiveDocument: doc(positive),
      negativeDocument: doc('lowres'),
    );
    await recipeStorage.putRecipe(recipe);
    return recipe;
  }

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWith(
          (ref) => _TestLocalStorageService(),
        ),
        styleExploreRecipeStorageProvider.overrideWithValue(recipeStorage),
        promptBlockLibraryNotifierProvider.overrideWith(
          () => _FakeLibraryNotifier(),
        ),
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

    // 左栏：探索任务占位 + Recipe 缩略列表。
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
    // 右栏候选画廊空态占位（宽窗默认展开）。
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

  testWidgets('new-run placeholder reports next-stage availability', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byKey(const Key('style-explore-new-run')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('探索任务将在下一阶段开放'), findsOneWidget);
    // 信息 toast 有自动关闭定时器，推进到结束。
    await tester.pump(const Duration(milliseconds: 3300));
  });
}
