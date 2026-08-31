import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:nai_launcher/core/storage/prompt_workspace_state_storage.dart';
import 'package:nai_launcher/core/storage/style_explore_recipe_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_segment.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/style_explore_provider.dart';

void main() {
  late Directory hiveDirectory;
  late StyleExploreRecipeStorage recipeStorage;
  late PromptWorkspaceStateStorage workspaceStorage;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'style_explore_provider_test_',
    );
    Hive.init(hiveDirectory.path);
    recipeStorage = StyleExploreRecipeStorage();
    await recipeStorage.init();
    workspaceStorage = PromptWorkspaceStateStorage();
    await workspaceStorage.init();
  });

  setUp(() async {
    await recipeStorage.clear();
    await workspaceStorage.clear();
  });

  tearDownAll(() async {
    await recipeStorage.close();
    await workspaceStorage.close();
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        styleExploreRecipeStorageProvider.overrideWithValue(recipeStorage),
        promptWorkspaceStateStorageProvider.overrideWithValue(workspaceStorage),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  PromptBlock block(String content) {
    return PromptBlock(
      id: 'source-${content.hashCode}',
      title: '块$content',
      content: content,
      color: '#FF123456',
      createdAt: DateTime.utc(2026, 8, 31),
      updatedAt: DateTime.utc(2026, 8, 31),
    );
  }

  group('recipe list notifier', () {
    test('create / rename / duplicate / delete keep list consistent', () async {
      final c = container();
      final notifier = c.read(styleExploreRecipeListNotifierProvider.notifier);

      final created = await notifier.create(
        name: '探索一',
        positiveDocument: _doc('doc-p', 'soft light'),
        negativeDocument: _doc('doc-n', 'lowres'),
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
        final workspace = c.read(
          styleExploreWorkspaceNotifierProvider.notifier,
        );

        workspace.replacePlainText(PromptBlockLane.positive, 'start');
        expect(c.read(styleExploreDirtyProvider), isFalse);

        final created = await session.saveAsNew('配方A');
        expect(
          c.read(styleExploreSessionNotifierProvider).activeRecipeId,
          created.id,
        );
        expect(c.read(styleExploreActiveRecipeProvider)?.name, '配方A');
        expect(c.read(styleExploreDirtyProvider), isFalse);

        workspace.replacePlainText(PromptBlockLane.positive, 'start, edited');
        expect(c.read(styleExploreDirtyProvider), isTrue);

        final saved = await session.saveActive();
        expect(saved, isNotNull);
        expect(c.read(styleExploreDirtyProvider), isFalse);
        final stored = await recipeStorage.getRecipe(created.id);
        expect(
          stored!.positiveDocument.segments.first,
          isA<TextSegment>().having(
            (segment) => segment.text,
            'text',
            'start, edited',
          ),
        );
      },
    );

    test('loadRecipe replaces both lanes; missing recipe is a no-op', () async {
      final c = container();
      final session = c.read(styleExploreSessionNotifierProvider.notifier);
      final workspace = c.read(styleExploreWorkspaceNotifierProvider.notifier);

      final listNotifier = c.read(
        styleExploreRecipeListNotifierProvider.notifier,
      );
      final created = await listNotifier.create(
        name: '载入目标',
        positiveDocument: _doc('rp', 'loaded positive'),
        negativeDocument: _doc('rn', 'loaded negative'),
      );

      workspace.replacePlainText(PromptBlockLane.positive, '本地未保存');
      final ok = await session.loadRecipe(created.id);
      expect(ok, isTrue);
      expect(
        c.read(styleExploreWorkspaceNotifierProvider).positiveDocument,
        created.positiveDocument,
      );
      expect(
        workspace.plainTextFor(PromptBlockLane.negative),
        'loaded negative',
      );
      expect(c.read(styleExploreDirtyProvider), isFalse);

      final missing = await session.loadRecipe('no-such-id');
      expect(missing, isFalse);
      expect(
        c.read(styleExploreWorkspaceNotifierProvider).positiveDocument,
        created.positiveDocument,
      );
    });

    test('handleRecipeDeleted unlinks only the active recipe', () async {
      final c = container();
      final session = c.read(styleExploreSessionNotifierProvider.notifier);
      final listNotifier = c.read(
        styleExploreRecipeListNotifierProvider.notifier,
      );
      final created = await listNotifier.create(
        name: '会被删',
        positiveDocument: _doc('dp', '删除后仍在'),
        negativeDocument: _doc('dn', 'lowres'),
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
      expect(workspaceText(c), isNot(''));
    });
  });

  group('workspace isolation and persistence', () {
    test('main and explore workspaces are fully isolated', () async {
      final c = container();
      final main = c.read(promptBlockWorkspaceNotifierProvider.notifier);
      final explore = c.read(styleExploreWorkspaceNotifierProvider.notifier);

      main.replacePlainText(PromptBlockLane.positive, '生成页内容');
      explore.replacePlainText(PromptBlockLane.positive, '探索页内容');

      expect(main.plainTextFor(PromptBlockLane.positive), '生成页内容');
      expect(explore.plainTextFor(PromptBlockLane.positive), '探索页内容');
      expect(
        c.read(promptBlockWorkspaceNotifierProvider).positiveDocument,
        isNot(c.read(styleExploreWorkspaceNotifierProvider).positiveDocument),
      );
    });

    test(
      'workspace state survives provider rebuild via Hive snapshot',
      () async {
        final c = container();
        final explore = c.read(styleExploreWorkspaceNotifierProvider.notifier);
        explore.replacePlainText(PromptBlockLane.positive, '持久化 A');
        explore.insertBlockAtTextOffset(
          PromptBlockLane.positive,
          textSegmentId: exploreTextSegmentId(c),
          offset: 3,
          block: block('[块]'),
        );
        // 手动冲刷 fire-and-forget 的持久化。
        await flushWorkspacePersist(c, 'styleExplore');

        final rebuilt = container();
        final state = rebuilt.read(styleExploreWorkspaceNotifierProvider);
        expect(state.positiveDocument.segments, hasLength(3));
        final restoredBlock = state.positiveDocument.segments[1];
        expect(restoredBlock, isA<BlockSegment>());
        expect(
          rebuilt
              .read(styleExploreWorkspaceNotifierProvider.notifier)
              .plainTextFor(PromptBlockLane.positive),
          '持久化[块] A',
        );

        // 生成页 scope 不受探索页影响。
        final mainState = rebuilt.read(promptBlockWorkspaceNotifierProvider);
        expect(mainState.positiveDocument.segments.single, isA<TextSegment>());
      },
    );

    test('main workspace state is restored under its own scope', () async {
      final c = container();
      final main = c.read(promptBlockWorkspaceNotifierProvider.notifier);
      main.replacePlainText(PromptBlockLane.negative, '生成页负向');
      await flushWorkspacePersist(c, 'main');

      final rebuilt = container();
      expect(
        rebuilt
            .read(promptBlockWorkspaceNotifierProvider.notifier)
            .plainTextFor(PromptBlockLane.negative),
        '生成页负向',
      );
      expect(
        rebuilt
            .read(styleExploreWorkspaceNotifierProvider.notifier)
            .plainTextFor(PromptBlockLane.negative),
        '',
      );
    });
  });
}

PromptBlockDocument _doc(String id, String text) {
  return PromptBlockDocument(
    documentId: id,
    segments: [PromptBlockSegment.text(id: '$id-seg', text: text)],
    updatedAt: DateTime.utc(2026, 8, 31),
  );
}

String workspaceText(ProviderContainer c) {
  return c
      .read(styleExploreWorkspaceNotifierProvider.notifier)
      .plainTextFor(PromptBlockLane.positive);
}

String exploreTextSegmentId(ProviderContainer c) {
  return c
      .read(styleExploreWorkspaceNotifierProvider)
      .positiveDocument
      .segments
      .single
      .id;
}

/// 手动执行一次同步持久化，等价于 notifier 内 fire-and-forget 的最终落盘。
Future<void> flushWorkspacePersist(ProviderContainer c, String scope) async {
  final storage = c.read(promptWorkspaceStateStorageProvider);
  final state = c.read(styleExploreWorkspaceNotifierProvider);
  final stateForScope = scope == 'main'
      ? c.read(promptBlockWorkspaceNotifierProvider)
      : state;
  await storage.persist(
    scope,
    PromptWorkspaceSnapshot(
      positiveDocument: stateForScope.positiveDocument,
      negativeDocument: stateForScope.negativeDocument,
    ),
  );
}
