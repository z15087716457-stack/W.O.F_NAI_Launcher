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

  PillWorkspaceNotifier mainLane(ProviderContainer c) =>
      c.read(pillWorkspaceProvider(PillScopes.main).notifier);

  PillWorkspaceNotifier negativeLane(ProviderContainer c) =>
      c.read(pillWorkspaceProvider(PillScopes.negative).notifier);

  PillDocument mainLaneDocument(ProviderContainer c) =>
      c.read(pillWorkspaceProvider(PillScopes.main)).document;

  PillDocument negativeLaneDocument(ProviderContainer c) =>
      c.read(pillWorkspaceProvider(PillScopes.negative)).document;

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

        mainLane(c).setText('start');
        expect(c.read(styleExploreDirtyProvider), isFalse);

        final created = await session.saveAsNew('配方A');
        expect(
          c.read(styleExploreSessionNotifierProvider).activeRecipeId,
          created.id,
        );
        expect(c.read(styleExploreActiveRecipeProvider)?.name, '配方A');
        expect(c.read(styleExploreDirtyProvider), isFalse);

        mainLane(c).setText('start, edited');
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

      mainLane(c).setText('本地未保存');
      final ok = await session.loadRecipe(created.id);
      expect(ok, isTrue);
      expect(mainLaneDocument(c), created.positiveDocument);
      expect(negativeLaneDocument(c).text, 'loaded negative');
      expect(c.read(styleExploreDirtyProvider), isFalse);

      final missing = await session.loadRecipe('no-such-id');
      expect(missing, isFalse);
      expect(mainLaneDocument(c), created.positiveDocument);
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
      expect(mainLaneDocument(c).text, isNot(''));
    });
  });

  group('workspace isolation and persistence', () {
    test('main and negative lanes are fully isolated', () {
      final c = container();
      final main = c.read(pillWorkspaceProvider(PillScopes.main).notifier);
      final negative = negativeLane(c);

      main.setText('正向内容');
      negative.setText('负向内容');

      expect(mainLaneDocument(c).text, '正向内容');
      expect(negativeLaneDocument(c).text, '负向内容');
    });

    test(
      'main lane state survives provider rebuild via Hive snapshot',
      () async {
        final c = container();
        mainLane(c).setText('持久化 A');
        negativeLane(c).setText('持久化负向');
        // 手动冲刷 fire-and-forget 的持久化。
        final storage = c.read(pillWorkspaceStorageProvider);
        await storage.persist(PillScopes.main, mainLaneDocument(c));
        await storage.persist(PillScopes.negative, negativeLaneDocument(c));

        final rebuilt = container();
        expect(mainLaneDocument(rebuilt).text, '持久化 A');
        expect(negativeLaneDocument(rebuilt).text, '持久化负向');
        // 无关 lane 不受影响。
        expect(rebuilt.read(pillWorkspaceProvider('other')).document.text, '');
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

      mainLane(c).restoreDocument(snapshot);

      expect(mainLaneDocument(c), snapshot);
      // 固定模式实例不触发 roll，enabled 原样保留。
      final restored = mainLaneDocument(c).instances[marker]!;
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

        mainLane(c).restoreDocument(snapshot);

        final restored = mainLaneDocument(c).instances[marker]!;
        expect(restored.currentRoll, isNotNull);
        expect(
          c.read(pillWorkspaceProvider(PillScopes.main)).projection,
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
