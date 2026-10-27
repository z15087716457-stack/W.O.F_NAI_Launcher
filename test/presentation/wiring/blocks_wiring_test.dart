import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nai_launcher/presentation/wiring/blocks_actions.dart';
import 'package:nai_launcher/presentation/wiring/blocks_instance_wiring.dart';
import 'package:nai_launcher/presentation/widgets/common/prompt_block_picker_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/rag/rag_client.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/core/rag/rag_text_search.dart';
import 'package:nai_launcher/presentation/providers/rag_provider.dart';
import 'package:nai_launcher/presentation/providers/tips_provider.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/character/character_prompt.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_folder.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_collection.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_page.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_dock.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_instance.dart';
import 'package:nai_launcher/presentation/ui/kit/ui_block_pill.dart';
import 'package:nai_launcher/presentation/wiring/blocks_dock_wiring.dart';
import 'package:nai_launcher/presentation/wiring/blocks_library_wiring.dart';
import 'package:nai_launcher/presentation/wiring/blocks_library_backend.dart';
import 'package:nai_launcher/presentation/wiring/blocks_platform.dart';
import 'package:nai_launcher/presentation/wiring/blocks_preferences.dart';
import 'package:nai_launcher/presentation/wiring/blocks_quick_save_wiring.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import 'package:nai_launcher/presentation/widgets/prompt/pills/prompt_pill_editor.dart';
import 'package:nai_launcher/presentation/widgets/prompt/unified/unified_prompt_config.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';

class MemoryCharacters extends CharacterPromptNotifier {
  @override
  CharacterPromptConfig build() => const CharacterPromptConfig();
}

class MemoryRagSettings extends RagSettingsController {
  @override
  RagSettings build() => const RagSettings(blocksEnabled: true);
  @override
  Future<void> update(RagSettings value) async {
    state = value;
  }
}

class MemoryRag extends RagController {
  final ids = <String>[];
  final requests = <RagTextQuery>[];
  @override
  RagStatus build() => const RagStatus(
    sources: {
      RagSource.blocks: RagStatus(
        phase: 'ready',
        indexed: 10,
        total: 10,
        complete: true,
      ),
    },
  );
  @override
  Future<List<RagSearchHit>> searchText(
    RagTextQuery query, {
    required RagCancellation cancellation,
  }) async {
    requests.add(query);
    return [
      for (final id in ids)
        RagSearchHit(
          id: id,
          title: 'Saved',
          snippet: 'rain',
          section: 'positive',
        ),
    ];
  }
}

class MemorySettings extends LocalStorageService {
  final values = <String, Object?>{};
  @override
  T? getSetting<T>(String key, {T? defaultValue}) =>
      values[key] as T? ?? defaultValue;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    values[key] = value;
  }

  @override
  Future<void> deleteSetting(String key) async {
    values.remove(key);
  }
}

class MemoryBlockStorage extends PromptBlockStorage {
  final blocks = <String, PromptBlock>{};
  final folders = <String, PromptBlockFolder>{};
  final collections = <String, PromptBlockCollection>{};
  final meta = <String, String>{};
  List<String> palette = [];
  @override
  Future<void> init() async {}
  @override
  Future<List<PromptBlock>> getBlocks() async => blocks.values.toList();
  @override
  Future<PromptBlock?> getBlock(String id) async => blocks[id];
  @override
  Future<PromptBlock?> transformBlock(
    String id,
    PromptBlock? Function(PromptBlock?) transform,
  ) async {
    final next = transform(blocks[id]);
    if (next == null) {
      blocks.remove(id);
    } else {
      blocks[id] = next;
    }
    return next;
  }

  @override
  Future<void> putBlock(PromptBlock value) async {
    blocks[value.id] = value;
  }

  @override
  Future<void> putBlocks(
    Iterable<PromptBlock> values, {
    void Function()? beforeWrite,
  }) async {
    beforeWrite?.call();
    for (final value in values) {
      blocks[value.id] = value;
    }
  }

  @override
  Future<void> deleteBlock(String id) async {
    blocks.remove(id);
  }

  @override
  Future<void> deleteBlocks(Iterable<String> ids) async {
    for (final id in ids) {
      blocks.remove(id);
    }
  }

  @override
  Future<List<PromptBlockFolder>> getFolders() async => folders.values.toList();
  @override
  Future<PromptBlockFolder?> getFolder(String id) async => folders[id];
  @override
  Future<void> putFolder(
    PromptBlockFolder value, {
    void Function()? beforeWrite,
  }) async {
    beforeWrite?.call();
    folders[value.id] = value;
  }

  @override
  Future<void> putFolders(
    Iterable<PromptBlockFolder> values, {
    void Function()? beforeWrite,
  }) async {
    beforeWrite?.call();
    for (final value in values) {
      folders[value.id] = value;
    }
  }

  @override
  Future<void> deleteFolder(String id, {void Function()? beforeWrite}) async {
    beforeWrite?.call();
    folders.remove(id);
  }

  @override
  Future<void> deleteFolders(Iterable<String> ids) async {
    for (final id in ids) {
      folders.remove(id);
    }
  }

  @override
  Future<List<PromptBlockCollection>> getCollections() async =>
      collections.values.toList();
  @override
  Future<PromptBlockCollection?> getCollection(String id) async =>
      collections[id];
  @override
  Future<void> putCollection(
    PromptBlockCollection value, {
    void Function()? beforeWrite,
  }) async {
    beforeWrite?.call();
    collections[value.id] = value;
  }

  @override
  Future<void> putCollections(
    Iterable<PromptBlockCollection> values, {
    void Function()? beforeWrite,
  }) async {
    beforeWrite?.call();
    for (final value in values) {
      collections[value.id] = value;
    }
  }

  @override
  Future<void> deleteCollection(String id) async {
    collections.remove(id);
  }

  @override
  Future<void> deleteCollections(
    Iterable<String> ids, {
    void Function()? beforeWrite,
  }) async {
    beforeWrite?.call();
    for (final id in ids) {
      collections.remove(id);
    }
  }

  @override
  Future<List<String>> getPaletteBlockIds() async => List.of(palette);
  @override
  Future<void> putPaletteBlockIds(List<String> ids) async {
    palette = List.of(ids);
  }

  @override
  Future<String?> getMeta(String name) async => meta[name];
  @override
  Future<void> putMeta(String name, String value) async {
    meta[name] = value;
  }
}

class TestPlatform extends BlocksPlatform {
  final calls = <String>[];
  final backups = <String>[];
  @override
  Future<void> backupDraft(String snapshot) async {
    backups.add(snapshot);
  }

  @override
  Future<BlockThumbPick?> pickThumbnail() async {
    calls.add('thumbnail');
    return null;
  }

  @override
  Future<List<String>> pickTxt(String title) async {
    calls.add('txt');
    return [];
  }

  @override
  Future<String?> pickDirectory(String title) async {
    calls.add('folder');
    return null;
  }

  @override
  Future<Map<String, dynamic>?> pickBackup(String title) async {
    calls.add('importBackup');
    return null;
  }

  @override
  Future<void> exportBackup(Map<String, dynamic> data, String title) async {
    calls.add('exportBackup');
  }

  @override
  Future<void> exportTxt(List<PromptBlock> blocks, String title) async {
    calls.add('export:${blocks.length}');
  }
}

void main() {
  late PromptBlockStorage storage;
  late ProviderContainer container;
  late BlocksLibraryBackend backend;
  late TestPlatform platform;
  late String blockId;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = MemoryBlockStorage();
    await storage.init();
    platform = TestPlatform();
    container = ProviderContainer(
      overrides: [
        promptBlockStorageProvider.overrideWithValue(storage),
        localStorageServiceProvider.overrideWithValue(MemorySettings()),
        characterPromptNotifierProvider.overrideWith(MemoryCharacters.new),
        blocksPlatformProvider.overrideWithValue(platform),
        ragSettingsProvider.overrideWith(MemoryRagSettings.new),
        ragControllerProvider.overrideWith(MemoryRag.new),
        tipEpochProvider.overrideWith((ref) => const Stream.empty()),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    await container.read(blocksPreferencesProvider.future);
    backend = container.read(blocksLibraryBackendProvider);
    blockId = (await backend.save(
      const BlockDraft(
        title: 'Style',
        atoms: ['a', 'b'],
        negativeAtoms: ['bad'],
        params: BlockParams(steps: 12),
      ),
    )).id;
  });
  tearDown(() async {
    container.dispose();
    await Future<void>.delayed(Duration.zero);
  });

  Future<void> mount(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: WindowChromeScope(child: child)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    await tester.pumpAndSettle();
  }

  BlocksLibraryPage page(WidgetTester t) =>
      t.widget<BlocksLibraryPage>(find.byType(BlocksLibraryPage));

  testWidgets('library mounts real data and preference callbacks persist', (
    tester,
  ) async {
    await mount(tester, const BlocksLibraryWiring());
    expect(page(tester).data.counts.all, 1);
    final actions = page(tester).actions;
    actions.onViewChanged(BlocksView.list);
    actions.onSidebarChanged(false);
    actions.onInspectorChanged(false);
    actions.onCardSizeChanged(.8);
    actions.onSortChanged(BlocksSort.title, descending: false);
    actions.onToggleFolder('folder', true);
    await flush(tester);
    expect(page(tester).data.view, BlocksView.list);
    expect(page(tester).data.sidebarOpen, isFalse);
    expect(page(tester).data.inspectorOpen, isFalse);
    expect(page(tester).data.cardSize, .8);
    actions.onSelect(blockId);
    actions.onQueryChanged('missing');
    await flush(tester);
    expect(page(tester).data.selectedId, isNull);
    page(tester).actions.onQueryChanged('');
    await flush(tester);
    expect(page(tester).data.selectedId, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'management mutation hooks use real storage and preserve other fields',
    (tester) async {
      await mount(tester, const BlocksLibraryWiring());
      await tester.runAsync(
        () => page(
          tester,
        ).actions.onCreate(const BlockDraft(title: 'New', atoms: ['x'])),
      );
      final actions = page(tester).actions;
      actions.onSetFavorite([blockId], true);
      actions.onUpdate(blockId, const BlockPatch(title: 'Updated'));
      actions.onBatchStyle(
        [blockId],
        color: Colors.red,
        look: BlockAppearance.dots,
      );
      actions.onAddTag([blockId], const BlockTag('tag', Colors.blue));
      await flush(tester);
      expect(backend.requireBlock(blockId).title, 'Updated');
      expect(backend.requireBlock(blockId).isFavorite, isTrue);
      expect(backend.requireBlock(blockId).appearance, 'dots');
      actions.onRenameTag('tag', 'renamed');
      actions.onSetTagColor('renamed', Colors.green);
      await flush(tester);
      expect(backend.requireBlock(blockId).tags.single.name, 'renamed');
      expect(backend.requireBlock(blockId).tags.single.color, '#FF4CAF50');
      actions.onRemoveTag([blockId], 'renamed');
      actions.onAddToPalette([blockId]);
      actions.onDuplicate(blockId);
      await flush(tester);
      expect(backend.requireBlock(blockId).tags, isEmpty);
      expect(
        await tester.runAsync(storage.getPaletteBlockIds),
        contains(blockId),
      );
      expect(backend.library.blocks, hasLength(3));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'folder and collection hooks create rename move reorder and add/remove references',
    (tester) async {
      await mount(tester, const BlocksLibraryWiring());
      final a = page(tester).actions;
      final folder = await tester.runAsync(() => a.onCreateFolder('Folder'));
      final parent = await tester.runAsync(() => a.onCreateFolder('Parent'));
      final collection = await tester.runAsync(
        () => a.onCreateCollection('Collection', isFolder: false),
      );
      a.onRenameFolder(folder!, 'Renamed');
      a.onMoveFolder(folder, parent);
      a.onRenameCollection(collection!, 'New collection');
      a.onDropToFolder([blockId], folder, BlocksDropMode.move);
      await flush(tester);
      a.onDropToCollection([blockId], collection, BlocksDropMode.copy);
      await flush(tester);
      expect(backend.library.folderById(folder)!.parentId, parent);
      expect(backend.requireBlock(blockId).folderId, folder);
      expect(backend.library.collectionById(collection)!.blockIds, [blockId]);
      a.onRemoveFromCollection([blockId], collection);
      a.onReorderFolder(folder, -1);
      await flush(tester);
      expect(backend.library.collectionById(collection)!.blockIds, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'import/export/thumbnail cancellation routes through injected platform',
    (tester) async {
      await mount(tester, const BlocksLibraryWiring());
      final a = page(tester).actions;
      a.onImportTxt();
      a.onImportFolder();
      a.onImportCuration();
      a.onImportBackup();
      a.onExportBackup();
      a.onExport([blockId]);
      await tester.runAsync(a.onPickThumbnail);
      final params = await tester.runAsync(a.onCaptureParams);
      await flush(tester);
      expect(
        platform.calls,
        containsAll([
          'txt',
          'folder',
          'folder',
          'importBackup',
          'exportBackup',
          'export:1',
          'thumbnail',
        ]),
      );
      expect(params, isNotNull);
      expect(backend.library.blocks, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'library insertion backs up before paired insertion and preserves existing drafts',
    (tester) async {
      final params = container.read(generationParamsNotifierProvider.notifier);
      params.updatePrompt('existing');
      params.updateNegativePrompt('existing bad');
      await mount(tester, const BlocksLibraryWiring());
      page(tester).actions.onInsert([blockId, blockId]);
      await flush(tester);
      expect(platform.backups, hasLength(1));
      final main = container.read(pillWorkspaceProvider(PillScopes.main));
      final negative = container.read(
        pillWorkspaceProvider(PillScopes.negative),
      );
      expect(main.projection, contains('existing'));
      expect(negative.projection, contains('existing bad'));
      expect(
        main.document.instances.values.single.bundleId,
        negative.document.instances.values.single.bundleId,
      );
      expect(container.read(blocksPreferencesProvider).requireValue.recentIds, [
        blockId,
      ]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'explicit resource lane overrides stale focus and preserves paired bundle insertion',
    (tester) async {
      final params = container.read(generationParamsNotifierProvider.notifier);
      params.updatePromptImmediately('keep positive');
      params.updateNegativePromptImmediately('keep negative');
      await mount(tester, const BlocksLibraryWiring());
      container.read(pillActiveEditorTargetProvider.notifier).state = (
        scope: PillScopes.main,
        caret: 0,
      );
      final host = tester.state<ConsumerState>(
        find.byType(BlocksLibraryWiring),
      );
      await tester.runAsync(
        () => BlocksActions(host.ref, host.context, () => host.mounted).insert(
          [blockId],
          targetScope: PillScopes.negative,
          propagateErrors: true,
        ),
      );
      await flush(tester);
      expect(platform.backups, hasLength(1));
      expect(
        container.read(pillWorkspaceProvider(PillScopes.main)).projection,
        contains('keep positive'),
      );
      expect(
        container.read(pillActiveEditorTargetProvider)?.scope,
        PillScopes.negative,
      );
      expect(
        container
            .read(pillWorkspaceProvider(PillScopes.negative))
            .document
            .instances,
        isNotEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('dock uses live data and persists expanded state', (
    tester,
  ) async {
    await mount(
      tester,
      const SizedBox(width: 300, child: BlocksDockWiring(allowPopOut: false)),
    );
    final dock = tester.widget<BlocksDock>(find.byType(BlocksDock));
    expect(dock.data.total, 1);
    dock.actions.onToggleGroup('', false);
    await flush(tester);
    expect(container.read(blocksPreferencesProvider).requireValue.collapsed, {
      '',
    });
    expect(dock.actions.dragDataOf(blockId), isNotNull);
    expect(tester.takeException(), isNull);
  });

  for (final dock in [false, true]) {
    testWidgets(
      '${dock ? 'dock' : 'library'} supplements literal search with saved semantic blocks',
      (tester) async {
        late String semanticId;
        await tester.runAsync(() async {
          semanticId = (await backend.save(
            const BlockDraft(title: 'Storm', text: 'umbrella, rain'),
          )).id;
          await container
              .read(ragSettingsProvider.notifier)
              .update(
                const RagSettings(
                  enabled: true,
                  tagsEnabled: false,
                  blocksEnabled: true,
                ),
              );
        });
        final rag = container.read(ragControllerProvider.notifier) as MemoryRag;
        rag.ids.addAll([semanticId, 'deleted']);
        await mount(
          tester,
          dock
              ? const SizedBox(
                  width: 300,
                  child: BlocksDockWiring(allowPopOut: false),
                )
              : const BlocksLibraryWiring(),
        );
        if (dock) {
          tester
              .widget<BlocksDock>(find.byType(BlocksDock))
              .actions
              .onQueryChanged('weather');
        } else {
          tester
              .widget<BlocksLibraryPage>(find.byType(BlocksLibraryPage))
              .actions
              .onQueryChanged('weather');
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await flush(tester);
        final results = dock
            ? tester.widget<BlocksDock>(find.byType(BlocksDock)).data.results
            : tester
                  .widget<BlocksLibraryPage>(find.byType(BlocksLibraryPage))
                  .data
                  .blocks;
        expect(results.map((b) => b.id), [semanticId]);
        expect(find.byKey(const Key('blocks-rag-badge')), findsOneWidget);
        expect(rag.requests.last.source, RagSource.blocks);
        expect(rag.requests.last.allowed, containsAll([blockId, semanticId]));
        if (dock) {
          tester
              .widget<BlocksDock>(find.byType(BlocksDock))
              .actions
              .onQueryChanged('Style');
        } else {
          tester
              .widget<BlocksLibraryPage>(find.byType(BlocksLibraryPage))
              .actions
              .onQueryChanged('Style');
        }
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await flush(tester);
        final mixed = dock
            ? tester.widget<BlocksDock>(find.byType(BlocksDock)).data.results
            : tester
                  .widget<BlocksLibraryPage>(find.byType(BlocksLibraryPage))
                  .data
                  .blocks;
        expect(mixed.map((b) => b.id), [blockId, semanticId]);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('block picker shows semantic results after literal matches', (
    tester,
  ) async {
    late String semanticId;
    await tester.runAsync(() async {
      semanticId = (await backend.save(
        const BlockDraft(title: 'Storm', text: 'umbrella, rain'),
      )).id;
      await container
          .read(ragSettingsProvider.notifier)
          .update(
            const RagSettings(
              enabled: true,
              tagsEnabled: false,
              blocksEnabled: true,
            ),
          );
    });
    final rag = container.read(ragControllerProvider.notifier) as MemoryRag;
    rag.ids.add(semanticId);
    await mount(tester, const PromptBlockPickerDialog());
    await tester.enterText(find.byType(TextField).first, 'weather');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await flush(tester);
    expect(find.text('Storm'), findsOneWidget);
    expect(find.text('Style'), findsNothing);
    expect(rag.requests.last.allowed, containsAll([blockId, semanticId]));
    await tester.enterText(find.byType(TextField).first, 'Style');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await flush(tester);
    final styleTitle = find.text('Style', findRichText: false).last;
    expect(styleTitle, findsOneWidget);
    expect(find.text('Storm'), findsOneWidget);
    expect(
      tester.getTopLeft(styleTitle).dx,
      lessThan(tester.getTopLeft(find.text('Storm')).dx),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dock folder filtering includes child-folder blocks', (
    tester,
  ) async {
    late String parentId;
    await tester.runAsync(() async {
      final parent = await backend.notifier.createFolder(name: 'Parent');
      parentId = parent.id;
      final child = await backend.notifier.createFolder(
        name: 'Child',
        parentId: parentId,
      );
      await backend.patch(blockId, BlockPatch(folderId: child.id));
    });
    await mount(
      tester,
      const SizedBox(width: 300, child: BlocksDockWiring(allowPopOut: false)),
    );
    tester
        .widget<BlocksDock>(find.byType(BlocksDock))
        .actions
        .onFilterChanged(BlocksDockFilter.folder(parentId));
    await flush(tester);
    final dock = tester.widget<BlocksDock>(find.byType(BlocksDock));
    expect(
      dock.data.groups.expand((g) => g.blocks).map((b) => b.id),
      contains(blockId),
    );
    expect(
      dock.data.groups.where((g) => g.id == parentId).expand((g) => g.blocks),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  for (final stale in [false, true]) {
    testWidgets(
      'quick save preserves surrounding text and refuses changed selection: $stale',
      (tester) async {
        final controller = TextEditingController.fromValue(
          const TextEditingValue(
            text: 'left selected right',
            selection: TextSelection(baseOffset: 5, extentOffset: 13),
          ),
        );
        addTearDown(controller.dispose);
        container
            .read(pillWorkspaceProvider(PillScopes.main).notifier)
            .setText(controller.text);
        await mount(
          tester,
          Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => showBlockQuickSave(
                context,
                ref,
                controller,
                scope: PillScopes.main,
              ),
              child: const Text('open'),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        if (stale) {
          controller.value = const TextEditingValue(
            text: 'new user edit',
            selection: TextSelection.collapsed(offset: 3),
          );
          container
              .read(pillWorkspaceProvider(PillScopes.main).notifier)
              .setText(controller.text);
        }
        await tester.tap(find.byKey(const Key('block-quick-save')));
        await flush(tester);
        expect(backend.library.blocks, hasLength(2));
        final lane = container.read(pillWorkspaceProvider(PillScopes.main));
        if (stale) {
          expect(controller.text, 'new user edit');
          expect(lane.document.instances, isEmpty);
          expect(platform.backups, isEmpty);
        } else {
          expect(lane.document.instances, hasLength(1));
          expect(lane.projection, 'left selected right');
          expect(platform.backups, hasLength(1));
          expect(controller.text, 'left \uE000 right');
          final notifier = container.read(
            pillWorkspaceProvider(PillScopes.main).notifier,
          );
          notifier.undo();
          final restored = container.read(
            pillWorkspaceProvider(PillScopes.main),
          );
          expect(
            restored.document.text,
            'left selected right',
            reason: 'selection-to-block must undo as a single operation',
          );
          expect(restored.document.instances, isEmpty);
          notifier.redo();
          expect(
            container.read(pillWorkspaceProvider(PillScopes.main)).document,
            lane.document,
          );
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('delete and undo operate only on this deletion snapshot', (
    tester,
  ) async {
    await mount(tester, const BlocksLibraryWiring());
    page(tester).actions.onDelete([blockId]);
    await flush(tester);
    expect(backend.library.blocks, isEmpty);
    await tester.tap(find.text('撤销'));
    await flush(tester);
    expect(backend.library.blocks.single.id, blockId);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delete undo notice dismisses itself after a few seconds', (
    tester,
  ) async {
    await mount(tester, const BlocksLibraryWiring());
    page(tester).actions.onDelete([blockId]);
    await flush(tester);
    expect(find.text('撤销'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('撤销'), findsNothing);
    expect(backend.library.blocks, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'repeated library reveal clears filters and reselects the same block',
    (tester) async {
      late BlocksActions host;
      final router = GoRouter(
        initialLocation: '/prompt-block-library',
        routes: [
          GoRoute(
            path: '/prompt-block-library',
            builder: (context, state) => Consumer(
              builder: (context, ref, _) {
                host = BlocksActions(ref, context, () => context.mounted);
                return const BlocksLibraryWiring();
              },
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await mount(
        tester,
        MaterialApp.router(
          routerConfig: router,
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
        ),
      );
      host.showInLibrary(blockId);
      await flush(tester);
      page(tester).actions.onQueryChanged('missing');
      await flush(tester);
      expect(page(tester).data.selectedId, isNull);
      host.showInLibrary(blockId);
      await flush(tester);
      expect(page(tester).data.query, '');
      expect(page(tester).data.selectedId, blockId);
      expect(tester.takeException(), isNull);
    },
  );

  for (final changedBeforeOpen in [false, true]) {
    testWidgets(
      'management editor matches its displayed revision: $changedBeforeOpen',
      (tester) async {
        await mount(tester, const BlocksLibraryWiring());
        if (changedBeforeOpen) {
          await tester.runAsync(
            () =>
                backend.patch(blockId, const BlockPatch(title: 'Latest title')),
          );
          await flush(tester);
        }
        tester
            .state<BlocksLibraryPageState>(find.byType(BlocksLibraryPage))
            .openEdit(blockId);
        await tester.pumpAndSettle();
        if (!changedBeforeOpen) {
          await tester.runAsync(
            () => backend.notifier.updateBlock(
              backend.requireBlock(blockId).copyWith(useCount: 7),
            ),
          );
          await flush(tester);
        }
        await tester.tap(find.byKey(const Key('block-edit-save')));
        await flush(tester);
        expect(
          backend.requireBlock(blockId).title,
          changedBeforeOpen ? 'Latest title' : 'Style',
        );
        expect(
          backend.requireBlock(blockId).useCount,
          changedBeforeOpen ? 0 : 7,
        );
        expect(platform.backups, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'management editor refuses a newer library edit and retains the rejected draft',
    (tester) async {
      await mount(tester, const BlocksLibraryWiring());
      page(tester).actions.onSelect(blockId);
      await tester.pump();
      tester
          .state<BlocksLibraryPageState>(find.byType(BlocksLibraryPage))
          .openEdit(blockId);
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => backend.patch(
          blockId,
          const BlockPatch(title: 'New external edit'),
        ),
      );
      await flush(tester);
      await tester.tap(find.byKey(const Key('block-edit-save')));
      await flush(tester);
      expect(backend.requireBlock(blockId).title, 'New external edit');
      expect(platform.backups, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'editor opens locked instance card and saves complete roll settings',
    (tester) async {
      await mount(
        tester,
        const SizedBox(
          width: 960,
          height: 360,
          child: PromptPillEditor(
            config: UnifiedPromptConfig(
              enableSyntaxHighlight: false,
              enableAutoFormat: false,
            ),
          ),
        ),
      );
      container
          .read(pillWorkspaceProvider(PillScopes.main).notifier)
          .insertBlockAt(offset: 0, blockId: blockId);
      await flush(tester);
      await tester.tap(find.byType(UiBlockPill).first);
      await tester.pumpAndSettle();
      expect(find.byType(BlockInstanceCard), findsOneWidget);
      expect(find.byKey(const Key('block-card-genetic')), findsNothing);
      final card = tester.widget<BlockInstanceCard>(
        find.byType(BlockInstanceCard),
      );
      card.actions.onSaveSettings(
        const BlockRollSettings(
          mode: BlockMode.random,
          countMin: 2,
          countMax: 2,
          probability: .7,
        ),
      );
      await flush(tester);
      final instance = container
          .read(pillWorkspaceProvider(PillScopes.main))
          .document
          .instances
          .values
          .single;
      expect(instance.settings.mode, PillRollMode.random);
      expect(instance.settings.triggerProbability, .7);
      expect(instance.settings.countMin, 2);
      final current = tester.widget<BlockInstanceCard>(
        find.byType(BlockInstanceCard),
      );
      final before = container
          .read(pillWorkspaceProvider(PillScopes.main))
          .document;
      current.actions.sample(
        const BlockRollSettings(mode: BlockMode.random),
        3,
      );
      expect(
        container.read(pillWorkspaceProvider(PillScopes.main)).document,
        before,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'exploration prompt instance backs up genetic toggle without changing rolls',
    (tester) async {
      final notifier = container.read(
        pillWorkspaceProvider(PillScopes.main).notifier,
      );
      notifier.insertBlockAt(offset: 0, blockId: blockId);
      final marker = container
          .read(pillWorkspaceProvider(PillScopes.main))
          .document
          .instances
          .keys
          .single;
      notifier.updateInstanceSettings(
        marker,
        const PillInstanceSettings(mode: PillRollMode.sequential),
      );
      final before = container
          .read(pillWorkspaceProvider(PillScopes.main))
          .document
          .instances[marker]!;
      await mount(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: BlockInstanceWiring(
            scope: PillScopes.main,
            marker: marker,
            onDismiss: () {},
            allowEvolutionToggle: true,
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('block-card-genetic')));
      await flush(tester);
      final after = container
          .read(pillWorkspaceProvider(PillScopes.main))
          .document
          .instances[marker]!;
      expect(after.evolutionEnabled, isTrue);
      expect(after.currentRoll, before.currentRoll);
      expect(after.sequenceCursor, before.sequenceCursor);
      expect(platform.backups, hasLength(1));
      await tester.tap(find.byKey(const Key('block-card-genetic')));
      await flush(tester);
      expect(
        container
            .read(pillWorkspaceProvider(PillScopes.main))
            .document
            .instances[marker]!
            .evolutionEnabled,
        isFalse,
      );
      expect(platform.backups, hasLength(2));
      expect(tester.takeException(), isNull);
    },
  );
}
