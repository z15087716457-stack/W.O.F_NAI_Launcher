import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/style_explore_recipe_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore_provider.dart';

void main() {
  late Directory hiveDirectory;
  late StyleExploreRecipeStorage recipeStorage;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'style_explore_provider_test_',
    );
    Hive.init(hiveDirectory.path);
    recipeStorage = StyleExploreRecipeStorage();
    await recipeStorage.init();
    // 药丸工作区持久化与 Recipe 各自独立 Box；直接开 Box 即可，
    // PillWorkspaceStorage 无 init 流程。
    await Hive.openBox<String>(StorageKeys.promptWorkspaceStateBox);
  });

  setUp(() async {
    await recipeStorage.clear();
    await Hive.box<String>(StorageKeys.promptWorkspaceStateBox).clear();
  });

  tearDownAll(() async {
    await recipeStorage.close();
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  ProviderContainer container({List<Override> overrides = const []}) {
    final c = ProviderContainer(
      overrides: [
        styleExploreRecipeStorageProvider.overrideWithValue(recipeStorage),
        ...overrides,
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  PillDocument doc(String text) =>
      PillDocument(text: text, instances: const {});

  PillWorkspaceNotifier explorePos(ProviderContainer c) =>
      c.read(pillWorkspaceProvider(PillScopes.explorePos).notifier);

  PillWorkspaceNotifier exploreNeg(ProviderContainer c) =>
      c.read(pillWorkspaceProvider(PillScopes.exploreNeg).notifier);

  PillDocument explorePosDocument(ProviderContainer c) =>
      c.read(pillWorkspaceProvider(PillScopes.explorePos)).document;

  PillDocument exploreNegDocument(ProviderContainer c) =>
      c.read(pillWorkspaceProvider(PillScopes.exploreNeg)).document;

  group('recipe list notifier', () {
    test('create / rename / duplicate / delete keep list consistent', () async {
      final c = container();
      final notifier = c.read(styleExploreRecipeListNotifierProvider.notifier);

      final created = await notifier.create(
        name: '探索一',
        positiveDocument: doc('soft light'),
        negativeDocument: doc('lowres'),
      );
      var list = await c.read(styleExploreRecipeListNotifierProvider.future);
      expect(list.recipes, hasLength(1));
      expect(list.recipes.single.name, '探索一');

      await notifier.rename(created.id, '改名二');
      list = await c.read(styleExploreRecipeListNotifierProvider.future);
      expect(list.recipes.single.name, '改名二');

      final copy = await notifier.duplicate(created.id);
      list = await c.read(styleExploreRecipeListNotifierProvider.future);
      expect(list.recipes, hasLength(2));
      expect(copy.positiveDocument, created.positiveDocument);
      expect(copy.id, isNot(created.id));

      await notifier.delete(created.id);
      list = await c.read(styleExploreRecipeListNotifierProvider.future);
      expect(list.recipes.map((r) => r.id), [copy.id]);
    });
  });

  group('explore session', () {
    test(
      'saveAsNew links session and dirty flag tracks workspace edits',
      () async {
        final c = container();
        final session = c.read(styleExploreSessionNotifierProvider.notifier);

        explorePos(c).setText('start');
        expect(c.read(styleExploreDirtyProvider), isFalse);

        final created = await session.saveAsNew('配方A');
        expect(
          c.read(styleExploreSessionNotifierProvider).activeRecipeId,
          created.id,
        );
        expect(c.read(styleExploreActiveRecipeProvider)?.name, '配方A');
        expect(c.read(styleExploreDirtyProvider), isFalse);

        explorePos(c).setText('start, edited');
        expect(c.read(styleExploreDirtyProvider), isTrue);

        final saved = await session.saveActive();
        expect(saved, isNotNull);
        expect(c.read(styleExploreDirtyProvider), isFalse);
        final stored = await recipeStorage.getRecipe(created.id);
        expect(stored!.positiveDocument.text, 'start, edited');
      },
    );

    test('loadRecipe replaces both lanes; missing recipe is a no-op', () async {
      final c = container();
      final session = c.read(styleExploreSessionNotifierProvider.notifier);

      final listNotifier = c.read(
        styleExploreRecipeListNotifierProvider.notifier,
      );
      final created = await listNotifier.create(
        name: '载入目标',
        positiveDocument: doc('loaded positive'),
        negativeDocument: doc('loaded negative'),
      );

      explorePos(c).setText('本地未保存');
      final ok = await session.loadRecipe(created.id);
      expect(ok, isTrue);
      expect(explorePosDocument(c), created.positiveDocument);
      expect(exploreNegDocument(c).text, 'loaded negative');
      expect(c.read(styleExploreDirtyProvider), isFalse);

      final missing = await session.loadRecipe('no-such-id');
      expect(missing, isFalse);
      expect(explorePosDocument(c), created.positiveDocument);
    });

    test('handleRecipeDeleted unlinks only the active recipe', () async {
      final c = container();
      final session = c.read(styleExploreSessionNotifierProvider.notifier);
      final listNotifier = c.read(
        styleExploreRecipeListNotifierProvider.notifier,
      );
      final created = await listNotifier.create(
        name: '会被删',
        positiveDocument: doc('删除后仍在'),
        negativeDocument: doc('lowres'),
      );
      await session.loadRecipe(created.id);

      session.handleRecipeDeleted('other-id');
      expect(
        c.read(styleExploreSessionNotifierProvider).activeRecipeId,
        created.id,
      );

      session.handleRecipeDeleted(created.id);
      expect(
        c.read(styleExploreSessionNotifierProvider).activeRecipeId,
        isNull,
      );
      // 工作区内容保留，用户可另存。
      expect(explorePosDocument(c).text, isNot(''));
    });
  });

  group('workspace isolation and persistence', () {
    test('main and explore lanes are fully isolated', () {
      final c = container();
      final main = c.read(pillWorkspaceProvider(PillScopes.main).notifier);
      final explore = explorePos(c);

      main.setText('生成页内容');
      explore.setText('探索页内容');

      expect(
        c.read(pillWorkspaceProvider(PillScopes.main)).document.text,
        '生成页内容',
      );
      expect(explorePosDocument(c).text, '探索页内容');
    });

    test(
      'explore lane state survives provider rebuild via Hive snapshot',
      () async {
        final c = container();
        explorePos(c).setText('持久化 A');
        exploreNeg(c).setText('持久化负向');
        // 手动冲刷 fire-and-forget 的持久化。
        final storage = c.read(pillWorkspaceStorageProvider);
        await storage.persist(PillScopes.explorePos, explorePosDocument(c));
        await storage.persist(PillScopes.exploreNeg, exploreNegDocument(c));

        final rebuilt = container();
        expect(explorePosDocument(rebuilt).text, '持久化 A');
        expect(exploreNegDocument(rebuilt).text, '持久化负向');
        // 主 lane 不受探索 lane 影响。
        expect(
          rebuilt.read(pillWorkspaceProvider(PillScopes.main)).document.text,
          '',
        );
      },
    );
  });

  group('restoreDocument', () {
    test('restores a complete document snapshot verbatim', () {
      final c = container();
      const marker = '\uE000';
      const snapshot = PillDocument(
        text: 'head \uE000 tail',
        instances: {marker: PillInstance(blockId: 'block-1', enabled: false)},
      );

      explorePos(c).restoreDocument(snapshot);

      expect(explorePosDocument(c), snapshot);
      // 固定模式实例不触发 roll，enabled 原样保留。
      final restored = explorePosDocument(c).instances[marker]!;
      expect(restored.enabled, isFalse);
      expect(restored.currentRoll, isNull);
    });

    test(
      'random instance missing currentRoll is materialized on restore',
      () async {
        final c = container(
          overrides: [
            promptBlockLibraryNotifierProvider.overrideWith(
              () => _FakeLibraryNotifier(
                PromptBlockLibraryState(
                  blocks: [
                    PromptBlock(
                      id: 'block-1',
                      title: '画风',
                      content: 'A, B',
                      createdAt: DateTime.utc(2026, 8, 31),
                      updatedAt: DateTime.utc(2026, 8, 31),
                    ),
                  ],
                  folders: const [],
                ),
              ),
            ),
          ],
        );
        await c.read(promptBlockLibraryNotifierProvider.future);

        const marker = '\uE000';
        const snapshot = PillDocument(
          text: '\uE000',
          instances: {
            marker: PillInstance(
              blockId: 'block-1',
              settings: PillInstanceSettings(mode: PillRollMode.random),
            ),
          },
        );

        explorePos(c).restoreDocument(snapshot);

        final restored = explorePosDocument(c).instances[marker]!;
        expect(restored.currentRoll, isNotNull);
        expect(
          c.read(pillWorkspaceProvider(PillScopes.explorePos)).projection,
          restored.currentRoll,
        );
      },
    );
  });
}

class _FakeLibraryNotifier extends PromptBlockLibraryNotifier {
  _FakeLibraryNotifier(this.initialState);

  final PromptBlockLibraryState initialState;

  @override
  Future<PromptBlockLibraryState> build() async => initialState;
}
