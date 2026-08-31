import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/style_explore_recipe_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_segment.dart';
import 'package:nai_launcher/data/models/style_explore/style_explore_recipe.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_workspace_provider.dart';
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

void main() {
  late _MemoryRecipeStorage recipeStorage;

  setUp(() {
    recipeStorage = _MemoryRecipeStorage();
  });

  PromptBlockDocument doc(String id, String text) {
    return PromptBlockDocument(
      documentId: id,
      segments: [PromptBlockSegment.text(id: '$id-seg', text: text)],
      updatedAt: DateTime.utc(2026, 8, 31),
    );
  }

  Future<StyleExploreRecipe> seedRecipe(String name, String positive) async {
    final recipe = StyleExploreRecipe.create(
      name: name,
      positiveDocument: doc(name.hashCode.toString(), positive),
      negativeDocument: doc('${name.hashCode}-neg', 'lowres'),
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
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StyleExploreScreen(),
      ),
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(buildScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('renders recipes, toolbar, and both lane editors', (
    tester,
  ) async {
    await seedRecipe('柔和光影', 'soft lighting');
    await seedRecipe('厚重色彩', 'vivid colors');
    await pumpScreen(tester);

    expect(find.text('柔和光影'), findsOneWidget);
    expect(find.text('厚重色彩'), findsOneWidget);
    expect(find.byKey(const Key('style-explore-save')), findsOneWidget);
    expect(find.byKey(const Key('style-explore-save-as')), findsOneWidget);
    expect(find.byKey(const Key('style-explore-preview')), findsOneWidget);
    expect(
      find.byKey(const Key('style-explore-positive-editor')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('style-explore-negative-editor')),
      findsOneWidget,
    );
    expect(find.text('未关联配方'), findsOneWidget);
  });

  testWidgets(
    'tapping a recipe loads its snapshot into the explore workspace',
    (tester) async {
      final recipe = await seedRecipe('载入目标', 'loaded content');
      await pumpScreen(tester);

      await tester.tap(find.text('载入目标'));
      await tester.pump();
      // AppToast.success 内部有 3 秒自动关闭定时器，推进到它结束。
      await tester.pump(const Duration(milliseconds: 3300));

      final element = tester.element(find.byType(StyleExploreScreen));
      final container = ProviderScope.containerOf(element);
      expect(
        container
            .read(styleExploreWorkspaceNotifierProvider.notifier)
            .plainTextFor(PromptBlockLane.positive),
        'loaded content',
      );
      expect(
        container.read(styleExploreSessionNotifierProvider).activeRecipeId,
        recipe.id,
      );
    },
  );

  testWidgets('editing in the explore page does not touch the main workspace', (
    tester,
  ) async {
    await pumpScreen(tester);

    final textField = find.descendant(
      of: find.byKey(const Key('style-explore-positive-editor')),
      matching: find.byType(TextField),
    );
    await tester.enterText(textField.first, '探索页输入');
    await tester.pump();

    final element = tester.element(find.byType(StyleExploreScreen));
    final container = ProviderScope.containerOf(element);
    expect(
      container
          .read(styleExploreWorkspaceNotifierProvider.notifier)
          .plainTextFor(PromptBlockLane.positive),
      '探索页输入',
    );
    expect(
      container
          .read(promptBlockWorkspaceNotifierProvider.notifier)
          .plainTextFor(PromptBlockLane.positive),
      '',
    );
  });

  testWidgets('preview dialog shows plain-text projection without titles', (
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
}
