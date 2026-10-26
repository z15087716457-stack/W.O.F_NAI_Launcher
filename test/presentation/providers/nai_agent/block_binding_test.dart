import 'dart:convert';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/core/storage/pill_workspace_storage.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/enums/quality_tag_preset.dart';
import 'package:nai_launcher/presentation/providers/quality_preset_provider.dart';
import 'package:nai_launcher/presentation/providers/uc_preset_provider.dart';
import 'package:nai_launcher/presentation/wiring/blocks_actions.dart';
import 'package:nai_launcher/presentation/wiring/blocks_mapping.dart';
import 'package:nai_launcher/presentation/utils/prompt_block_generation_settings_applier.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/presentation/wiring/blocks_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/core/krita/bridge_draft_guard.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_folder.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/character_prompt_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/bridge_draft_snapshot.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_studio_provider.dart';
import '../krita/agent_bridge_draft_test.dart'
    show MemoryDraftSettings, MemoryCharacters, OfflineAuth, IdleGeneration;

class _Library extends PromptBlockLibraryNotifier {
  @override
  Future<PromptBlockLibraryState> build() async {
    final data = await ref.read(promptBlockRepositoryProvider).load();
    return PromptBlockLibraryState(
      blocks: data.blocks,
      folders: data.folders,
      collections: data.collections,
    );
  }
}

class _Preferences extends BlocksPreferencesNotifier {
  bool fail = false;
  int calls = 0;

  @override
  Future<void> recordUse(String id) {
    calls++;
    if (fail) return Future.error(StateError('Synthetic preference failure'));
    return super.recordUse(id);
  }
}

class _Vibes extends VibeLibraryStorageService {
  @override
  Future<void> saveGenerationStateJson(String value) async {}
  @override
  Future<String?> loadGenerationStateJson() async => null;
}

class _Blocks extends PromptBlockRepository {
  _Blocks(super.storage);
  Future<void> Function()? afterUsage;
  void Function()? beforeOrganizationWrite;
  @override
  Future<PromptBlockFolder> createFolder({
    required String name,
    String? parentId,
    int? sortOrder,
    void Function()? beforeWrite,
  }) => super.createFolder(
    name: name,
    parentId: parentId,
    sortOrder: sortOrder,
    beforeWrite: () {
      beforeOrganizationWrite?.call();
      beforeWrite?.call();
    },
  );
  @override
  Future<PromptBlock?> incrementUseCount(String id) async {
    final actual = await super.incrementUseCount(id);
    await afterUsage?.call();
    return actual;
  }
}

final _draftProvider = Provider<BridgeDraftSnapshot Function()>(
  (ref) =>
      () => readBridgeDraft(ref),
);
Matcher toolError(String code) =>
    isA<NaiAgentToolError>().having((e) => e.code, 'code', code);

void main() {
  late Directory root, workspace;
  late PromptBlockStorage storage;
  late _Blocks repository;
  late ProviderContainer container;
  late _Preferences preferences;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = _Preferences();
    root = await Directory.systemTemp.createTemp('nai-agent-blocks-');
    workspace = await Directory('${root.path}/workspace').create();
    Hive.init(root.path);
    await Hive.openBox(StorageKeys.settingsBox);
    storage = PromptBlockStorage(hivePath: root.path);
    await storage.init();
    repository = _Blocks(storage);
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockRepositoryProvider.overrideWithValue(repository),
        promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
        vibeLibraryStorageServiceProvider.overrideWithValue(_Vibes()),
        imageGenerationNotifierProvider.overrideWith(IdleGeneration.new),
        authNotifierProvider.overrideWith(OfflineAuth.new),
        blocksPreferencesProvider.overrideWith(() => preferences),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
  });
  tearDown(() async {
    container.dispose();
    await Future<void>.delayed(Duration.zero);
    await Hive.close();
    await root.delete(recursive: true);
  });
  Future<Map<String, dynamic>> run(
    String tool,
    Map<String, dynamic> params,
  ) async =>
      (await container
              .read(naiAgentStudioFactoryProvider)(workspace, root, true)
              .execute(tool, params, NaiAgentCancellation()))['details']
          as Map<String, dynamic>;
  Future<Map<String, dynamic>> block(String id) async =>
      (await run('block_query', {'id': id}))['block'] as Map<String, dynamic>;
  Future<Map<String, dynamic>> create(Map<String, dynamic> changes) async =>
      await run('block_manage', {'action': 'create', 'changes': changes});
  BridgeDraftSnapshot draft() => container.read(_draftProvider)();
  test(
    'quality and UC capture save reload apply round trip, native and custom',
    () async {
      final preset = await repository.createBlock(
        title: 'custom preset',
        content: 'custom words',
      );
      await container
          .read(promptBlockLibraryNotifierProvider.notifier)
          .refresh();
      for (final custom in [false, true]) {
        container
            .read(generationParamsNotifierProvider.notifier)
            .updateModel(ImageModels.animeDiffusionV5Full);
        container
            .read(generationParamsNotifierProvider.notifier)
            .updateQualityPreset(QualityTagPreset.light);
        container
            .read(generationParamsNotifierProvider.notifier)
            .updateUcPreset(UcPresets.toApiValue(UcPresetType.humanFocus));
        if (custom) {
          container
              .read(qualityPresetNotifierProvider.notifier)
              .setCustomEntry(preset.id);
          container
              .read(ucPresetNotifierProvider.notifier)
              .setCustomEntry(preset.id);
        }
        final captured = storedBlockParams(captureBlockParams(container.read))!;
        final created = await create({
          'title': 'saved',
          'content': 'prompt',
          'generationSettings': captured.toJson(),
        });
        final saved = await repository.getBlock(
          (created['block'] as Map)['id'] as String,
        );
        final reloaded = PromptBlock.fromJson(
          saved!.toJson(),
        ).generationSettings!;
        expect(reloaded, captured);
        container
            .read(generationParamsNotifierProvider.notifier)
            .updateQualityPreset(QualityTagPreset.none);
        container
            .read(generationParamsNotifierProvider.notifier)
            .updateUcPreset(3);
        applyPromptBlockGenerationSettingsWithReader(container.read, reloaded);
        expect(storedBlockParams(captureBlockParams(container.read)), captured);
      }
      expect(
        PromptBlockGenerationSettings.fromJson({'steps': 28}).qualityPreset,
        isNull,
      );
    },
  );

  Future<Map<String, dynamic>> insert(
    String id, {
    String scope = 'main',
    int? offset,
  }) async => run('block_manage', {
    'action': 'insert',
    'id': id,
    'expected_version': (await block(id))['version'],
    'expected_draft_version': draft().acknowledgementVersion,
    'scope': scope,
    if (offset != null) 'offset': offset,
  });

  test(
    'Agent temporary edits isolate one shared occurrence, persist, revert and save as new',
    () async {
      final created = await create({
        'title': 'original',
        'content': 'old',
        'negativeContent': 'old UC',
        'color': '#FF123456',
        'appearance': 'dots',
        'iconName': 'star',
        'tags': [
          {'name': 'tag'},
        ],
        'generationSettings': {'qualityPreset': 'light', 'ucPreset': 1},
      });
      final id = (created['block'] as Map)['id'] as String;
      await insert(id);
      const m = '\uE000';
      final pos = container.read(pillWorkspaceProvider('main').notifier);
      final neg = container.read(pillWorkspaceProvider('negative').notifier);
      pos.setText('$m / $m');
      neg.setText('$m / $m');
      final result = await run('block_manage', {
        'action': 'instance_update',
        'scope': 'main',
        'marker': m,
        'occurrence': 1,
        'expected_draft_version': draft().acknowledgementVersion,
        'instance': {'content': 'new', 'negative_content': 'new UC'},
      });
      final document = container.read(pillWorkspaceProvider('main')).document;
      final tempMarker = document.instances.keys.singleWhere((key) => key != m);
      expect(document.text, '$m / $tempMarker');
      expect(
        container.read(pillWorkspaceProvider('main')).projection,
        'old / new',
      );
      expect(
        container.read(pillWorkspaceProvider('negative')).projection,
        'old UC / new UC',
      );
      expect((await repository.getBlock(id))!.content, 'old');
      expect(document.instances[m]!.temp, isNull);
      expect(document.instances[tempMarker]!.temp!.editedBy, 'agent');
      expect(
        ((result['lanes'] as Map)['main'] as Map)['document'],
        document.toJson(),
      );
      final roundTrip = PillDocument.fromJson(
        jsonDecode(jsonEncode(document.toJson())) as Map<String, dynamic>,
      );
      expect(roundTrip, document);
      pos.restoreDocument(roundTrip);
      expect(
        container.read(pillWorkspaceProvider('main')).projection,
        'old / new',
      );
      final queried = await run('block_query', {'id': id});
      expect(
        (queried['instances'] as List).where(
          (e) => (e as Map)['temporary'] == true,
        ),
        hasLength(2),
      );
      pos.revertTemp(tempMarker);
      expect(
        container.read(pillWorkspaceProvider('main')).projection,
        'old / old',
      );
      expect(
        container.read(pillWorkspaceProvider('negative')).projection,
        'old UC / old UC',
      );
      pos.editTempContent(tempMarker, 'saved text', 'saved UC');
      final saved = await pos.saveTempAsNewBlock(
        tempMarker,
        title: 'new library block',
      );
      expect(saved!.id, isNot(id));
      expect(saved.content, 'saved text');
      expect(saved.negativeContent, 'saved UC');
      final original = (await repository.getBlock(id))!;
      expect(original.content, 'old');
      expect(saved.color, original.color);
      expect(saved.appearance, original.appearance);
      expect(saved.iconName, original.iconName);
      expect(saved.tags, original.tags);
      expect(saved.generationSettings, original.generationSettings);
      final actual = container.read(pillWorkspaceProvider('main'));
      expect(actual.document.instances[tempMarker]!.blockId, saved.id);
      expect(actual.document.instances[tempMarker]!.temporary, isFalse);
      expect(actual.projection, 'old / saved text');
      expect(
        container.read(pillWorkspaceProvider('negative')).projection,
        'old UC / saved UC',
      );
    },
  );

  test(
    'temporary draft survives provider restart and library edits, including a reading block',
    () async {
      await Hive.openBox<String>(PillWorkspaceStorage.boxName);
      final created = await create({
        'title': 'reading',
        'content': 'source',
        'negativeContent': 'UC',
        'readingTranslationZh': '译文',
      });
      final id = (created['block'] as Map)['id'] as String;
      await insert(id);
      final lane = container.read(pillWorkspaceProvider('main').notifier);
      lane.editTempContent(
        '\uE000',
        'local source',
        'local UC',
        editedBy: 'agent',
      );
      final expected = container.read(pillWorkspaceProvider('main')).document;
      await container
          .read(pillWorkspaceStorageProvider)
          .persist('main', expected);
      container.invalidate(pillWorkspaceProvider('main'));
      expect(container.read(pillWorkspaceProvider('main')).document, expected);
      expect(
        container.read(pillWorkspaceProvider('main')).projection,
        'local source',
      );
      final original = (await repository.getBlock(id))!;
      await repository.updateBlock(
        original.copyWith(content: 'library changed'),
      );
      await container
          .read(promptBlockLibraryNotifierProvider.notifier)
          .refresh();
      expect(
        container.read(pillWorkspaceProvider('main')).projection,
        'local source',
      );
      final saved = await container
          .read(pillWorkspaceProvider('main').notifier)
          .saveTempAsNewBlock('\uE000', title: 'new fixed');
      final actual = container.read(pillWorkspaceProvider('main'));
      expect(actual.document.instances.values.single.translation, isNull);
      expect(actual.projection, 'local source');
      expect(actual.document.instances.values.single.blockId, saved!.id);
      expect((await repository.getBlock(id))!.content, 'library changed');
    },
  );

  test(
    'negative-only Agent temp edit preserves the positive temporary content',
    () async {
      final created = await create({
        'title': 'two sides',
        'content': 'positive',
        'negativeContent': 'negative',
      });
      await insert((created['block'] as Map)['id'] as String);
      await run('block_manage', {
        'action': 'instance_update',
        'scope': 'negative',
        'marker': '\uE000',
        'expected_draft_version': draft().acknowledgementVersion,
        'instance': {'negative_content': 'new negative'},
      });
      expect(
        container.read(pillWorkspaceProvider('main')).projection,
        'positive',
      );
      expect(
        container.read(pillWorkspaceProvider('negative')).projection,
        'new negative',
      );
    },
  );

  test(
    'temporary random instance is fixed and independent of another instance of the same block',
    () async {
      final created = await create({'title': 'pool', 'content': 'one, two'});
      final id = (created['block'] as Map)['id'] as String;
      await insert(id, offset: 0);
      await insert(id, offset: 1);
      final lane = container.read(pillWorkspaceProvider('main').notifier);
      lane.updateInstanceSettings(
        '\uE000',
        const PillInstanceSettings(mode: PillRollMode.random),
      );
      final old = container
          .read(pillWorkspaceProvider('main'))
          .document
          .instances['\uE000']!;
      lane.editTempContent('\uE000', 'fixed', null);
      lane.rollMarker('\uE000');
      lane.rollAllRandom();
      final actual = container.read(pillWorkspaceProvider('main'));
      expect(actual.projection, 'fixedone, two');
      expect(actual.document.instances['\uE000']!.currentRoll, old.currentRoll);
      expect(actual.document.instances['\uE001']!.temporary, isFalse);
      lane.revertTemp('\uE000');
      expect(
        container
            .read(pillWorkspaceProvider('main'))
            .document
            .instances['\uE000']!
            .settings
            .mode,
        PillRollMode.random,
      );
    },
  );

  test(
    'partial temporary content edits freeze the other side current roll, not the whole library pool',
    () async {
      final created = await create({
        'title': 'rolled pair',
        'content': 'a, b',
        'negativeContent': 'c, d',
      });
      await insert((created['block'] as Map)['id'] as String);
      final pos = container.read(pillWorkspaceProvider('main').notifier);
      final neg = container.read(pillWorkspaceProvider('negative').notifier);
      pos.updateInstanceSettings(
        '\uE000',
        const PillInstanceSettings(mode: PillRollMode.sequential),
      );
      neg.updateInstanceSettings(
        '\uE000',
        const PillInstanceSettings(mode: PillRollMode.sequential),
      );
      final positive = container.read(pillWorkspaceProvider('main')).projection;
      await run('block_manage', {
        'action': 'instance_update',
        'scope': 'negative',
        'marker': '\uE000',
        'expected_draft_version': draft().acknowledgementVersion,
        'instance': {'negative_content': 'edited UC'},
      });
      expect(
        container.read(pillWorkspaceProvider('main')).projection,
        positive,
      );
      expect(
        container.read(pillWorkspaceProvider('negative')).projection,
        'edited UC',
      );
      pos.revertTemp('\uE000');
      await Future<void>.delayed(Duration.zero);
      final negative = container
          .read(pillWorkspaceProvider('negative'))
          .projection;
      await run('block_manage', {
        'action': 'instance_update',
        'scope': 'main',
        'marker': '\uE000',
        'expected_draft_version': draft().acknowledgementVersion,
        'instance': {'content': 'edited positive'},
      });
      expect(
        container.read(pillWorkspaceProvider('main')).projection,
        'edited positive',
      );
      expect(
        container.read(pillWorkspaceProvider('negative')).projection,
        negative,
      );
    },
  );

  Future<Map<String, dynamic>> organize(
    String action, [
    Map<String, dynamic> fields = const {},
  ]) async => run('block_manage', {
    'action': action,
    'expected_library_version': (await run('block_query', {
      'kind': 'tree',
    }))['library_version'],
    ...fields,
  });

  test(
    'folder CRUD, movement, complete reordering and deletion preserve native blocks and draft',
    () async {
      final before = draft();
      final parent = await organize('folder_create', {
        'changes': {'name': 'Parent'},
      });
      final child = await organize('folder_create', {
        'changes': {'name': 'Child', 'parentId': parent['id']},
      });
      await organize('folder_update', {
        'id': child['id'],
        'changes': {'name': 'Renamed'},
      });
      await organize('folder_move', {'id': child['id'], 'parent_id': null});
      await organize('folder_reorder', {
        'parent_id': null,
        'ordered_ids': [child['id'], parent['id']],
      });
      expect((await repository.getFolder(child['id'] as String))!.sortOrder, 0);
      final entry = await create({
        'title': 'Retained',
        'content': 'blue_eyes',
        'folderId': parent['id'],
      });
      await expectLater(
        organize('folder_delete', {'id': parent['id']}),
        throwsA(toolError('invalid_organization')),
      );
      await organize('folder_delete', {'id': child['id']});
      expect(await repository.getFolder(child['id'] as String), isNull);
      expect((await repository.load()).blocks.single.id, entry['block']['id']);
      expect(draft().acknowledgementVersion, before.acknowledgementVersion);
      expect(await File(parent['backup_path'] as String).exists(), isTrue);
    },
  );
  test(
    'collection hierarchy and explicit membership use native favorites without deleting blocks',
    () async {
      final entry = await create({'title': 'Member', 'content': 'blue_eyes'});
      final blockId = entry['block']['id'];
      final folder = await organize('collection_create', {
        'changes': {'name': 'Folder', 'isFolder': true},
      });
      final collection = await organize('collection_create', {
        'changes': {'name': 'Set', 'parentId': folder['id']},
      });
      await organize('collection_update', {
        'id': collection['id'],
        'changes': {'name': 'New set'},
      });
      await organize('collection_add', {
        'id': collection['id'],
        'block_id': blockId,
      });
      await organize('collection_add', {
        'id': collection['id'],
        'block_id': blockId,
      });
      expect(
        (await repository.load())
            .getCollection(collection['id'] as String)!
            .blockIds,
        [blockId],
      );
      expect(
        (await repository.getBlock(blockId as String))!.isFavorite,
        isTrue,
      );
      await organize('collection_remove', {
        'id': collection['id'],
        'block_id': blockId,
      });
      expect((await repository.getBlock(blockId))!.isFavorite, isTrue);
      await organize('collection_add', {
        'id': collection['id'],
        'block_id': blockId,
      });
      await organize('collection_delete', {'id': folder['id']});
      expect((await repository.load()).collections, isEmpty);
      expect(await repository.getBlock(blockId), isNotNull);
    },
  );
  test(
    'organization rejects stale library versions, cycles and incomplete reorder before overwriting',
    () async {
      final parent = await organize('folder_create', {
        'changes': {'name': 'Parent'},
      });
      final version = (await run('block_query', {
        'kind': 'tree',
      }))['library_version'];
      final child = await organize('folder_create', {
        'changes': {'name': 'Child', 'parentId': parent['id']},
      });
      await expectLater(
        run('block_manage', {
          'action': 'folder_update',
          'id': parent['id'],
          'changes': {'name': 'Stale'},
          'expected_library_version': version,
        }),
        throwsA(toolError('library_conflict')),
      );
      await expectLater(
        organize('folder_move', {'id': parent['id'], 'parent_id': child['id']}),
        throwsA(toolError('invalid_organization')),
      );
      await expectLater(
        organize('folder_reorder', {'parent_id': null, 'ordered_ids': []}),
        throwsA(toolError('invalid_organization')),
      );
      expect(
        (await repository.getFolder(parent['id'] as String))!.name,
        'Parent',
      );
    },
  );

  test(
    'late native organization edits and cancellation are checked at Hive admission',
    () async {
      final parent = await organize('folder_create', {
        'changes': {'name': 'Parent'},
      });
      final folder = (await repository.getFolder(parent['id'] as String))!;
      final version = (await run('block_query', {
        'kind': 'tree',
      }))['library_version'];
      repository.beforeOrganizationWrite = () {
        Hive.box<String>(StorageKeys.promptBlockLibraryBox).put(
          PromptBlockStorage.folderKey(folder.id),
          jsonEncode(folder.copyWith(name: 'User edit').toJson()),
        );
      };
      await expectLater(
        run('block_manage', {
          'action': 'folder_create',
          'changes': {'name': 'Rejected'},
          'expected_library_version': version,
        }),
        throwsA(toolError('library_conflict')),
      );
      expect((await repository.load()).folders.single.name, 'User edit');
      final token = NaiAgentCancellation();
      repository.beforeOrganizationWrite = token.cancel;
      final current = (await run('block_query', {
        'kind': 'tree',
      }))['library_version'];
      await expectLater(
        container
            .read(naiAgentStudioFactoryProvider)(workspace, root, true)
            .execute('block_manage', {
              'action': 'folder_create',
              'changes': {'name': 'Cancelled'},
              'expected_library_version': current,
            }, token),
        throwsA(toolError('cancelled')),
      );
      expect((await repository.load()).folders, hasLength(1));
    },
  );

  test(
    'real CRUD returns persisted fields and backs up the complete previous library/draft',
    () async {
      final folder = await repository.createFolder(name: '风格');
      final before = draft();
      final created = await create({
        'title': '冷色积木',
        'content': 'blue theme',
        'folderId': folder.id,
        'isFavorite': true,
        'atoms': ['blue', 'cyan'],
        'negativeContent': 'red theme',
        'generationSettings': {'width': 832, 'height': 1216},
      });
      final id = created['id'] as String;
      expect((await repository.getBlock(id))!.isFavorite, true);
      expect(draft().acknowledgementVersion, before.acknowledgementVersion);
      final row = await block(id);
      final updated = await run('block_manage', {
        'action': 'update',
        'id': id,
        'expected_version': row['version'],
        'changes': {'content': 'green theme', 'folderId': null},
      });
      expect(updated['block']['atoms'], null);
      expect(updated['block']['folderId'], null);
      final backup =
          jsonDecode(
                await File(updated['backup_path'] as String).readAsString(),
              )
              as Map;
      expect(backup['generation']['blocks'].single['content'], 'blue theme');
      expect(backup['generation']['draft']['fields'], before.fields);
      final deleted = await run('block_manage', {
        'action': 'delete',
        'id': id,
        'expected_version': updated['block']['version'],
      });
      expect(deleted['block'], null);
      expect(await repository.getBlock(id), null);
    },
  );

  test(
    'query pages, favorites, folders, collections and hidden dependencies use real library rows',
    () async {
      final folder = await repository.createFolder(name: 'Characters');
      final a = await repository.createBlock(
        title: 'Blue',
        content: 'blue eyes',
        folderId: folder.id,
        isFavorite: true,
      );
      await repository.createBlock(title: 'Green', content: 'green hair');
      final hidden = PromptBlock.create(
        title: 'Archived',
        content: 'blue archive',
        isArchived: true,
      );
      await repository.importBlocks([hidden]);
      final collection = await repository.createCollection(name: 'Favorites');
      await storage.putCollection(collection.copyWith(blockIds: [a.id]));
      final page = await run('block_query', {'limit': 1});
      expect(page['total'], 2);
      expect(page['next_offset'], 1);
      expect(
        (await run('block_query', {
          'folder_id': folder.id,
          'favorites': true,
        }))['blocks'].single['id'],
        a.id,
      );
      expect(
        (await run('block_query', {
          'collection_id': collection.id,
        }))['blocks'].single['id'],
        a.id,
      );
      expect(
        (await run('block_query', {
          'query': 'blue',
          'include_archived': true,
        }))['total'],
        2,
      );
      final tree = await run('block_query', {'kind': 'tree'});
      expect(tree['folders'].single['id'], folder.id);
      expect(tree['collections'].single['id'], collection.id);
      expect((await run('block_query', {'id': 'missing'}))['block'], null);
    },
  );

  test(
    'unopened prompt editors preserve saved text and pair both sides of a block',
    () async {
      final p = container.read(generationParamsNotifierProvider.notifier);
      p.restoreAgentSnapshot(
        container
            .read(generationParamsNotifierProvider)
            .copyWith(prompt: '1girl', negativePrompt: 'bad quality'),
      );
      expect(container.exists(pillWorkspaceProvider(PillScopes.main)), false);
      final created = await create({
        'title': '双面',
        'content': 'blue eyes',
        'negativeContent': 'red eyes',
      });
      final result = await insert(created['id'] as String);
      final params = container.read(generationParamsNotifierProvider);
      expect(params.prompt, '1girl, blue eyes');
      expect(params.negativePrompt, 'bad quality, red eyes');
      final lanes = result['lanes'] as Map;
      final pos = lanes['main']['document']['instances'] as Map;
      final neg = lanes['negative']['document']['instances'] as Map;
      expect(pos.values.single['bundleId'], neg.values.single['bundleId']);
      expect(neg.values.single['useNegativeContent'], true);
      expect(result['draft_version'], draft().acknowledgementVersion);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect((await repository.getBlock(created['id'] as String))!.useCount, 1);
    },
  );

  test(
    'Agent insert records LRU once per bundle and ignores preference failures',
    () async {
      final first = await create({
        'title': 'first',
        'content': 'one',
        'negativeContent': 'bad one',
      });
      final second = await create({'title': 'second', 'content': 'two'});
      final a = first['id'] as String, b = second['id'] as String;
      await container.read(blocksPreferencesProvider.future);
      await insert(a);
      await insert(b);
      await insert(a);
      // Drain the preference queue without recording an extra use.
      await preferences.change((p) => p);
      expect(preferences.calls, 3);
      expect(container.read(blocksPreferencesProvider).requireValue.recentIds, [
        a,
        b,
      ]);
      expect(
        (await SharedPreferences.getInstance()).getStringList(
          'blocks_recent_ids',
        ),
        [a, b],
      );

      final before = preferences.calls;
      await expectLater(
        run('block_manage', {
          'action': 'insert',
          'id': b,
          'expected_version': (await block(b))['version'],
          'expected_draft_version': 'stale',
        }),
        throwsA(toolError('draft_conflict')),
      );
      expect(preferences.calls, before);

      preferences.fail = true;
      final result = await insert(b);
      await Future<void>.delayed(Duration.zero);
      expect(result['action'], 'insert');
      expect(result['lanes']['main']['inserted_markers'], hasLength(1));
      expect(result['draft_version'], draft().acknowledgementVersion);
      expect(preferences.calls, before + 1);
    },
  );

  test(
    'negative-only blocks do not change the main prompt or open its empty editor',
    () async {
      container
          .read(generationParamsNotifierProvider.notifier)
          .restoreAgentSnapshot(
            container
                .read(generationParamsNotifierProvider)
                .copyWith(prompt: 'kept main'),
          );
      final created = await create({
        'title': '负面',
        'content': '',
        'negativeContent': 'bad anatomy',
      });
      final result = await insert(created['id'] as String);
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        'kept main',
      );
      expect(container.exists(pillWorkspaceProvider(PillScopes.main)), false);
      expect(result['lanes'].keys.toList(), ['negative']);
      expect(
        container.read(generationParamsNotifierProvider).negativePrompt,
        'bad anatomy',
      );
    },
  );

  for (final (input, prefix) in const [
    ('dress', 'dress, '),
    ('eyes', 'eyes, '),
    ('cat', 'cat, '),
    (r'cat$', r'cat$, '),
    ('cat ', 'cat , '),
    ('cat,', 'cat,'),
    ('cat,  ', 'cat,  '),
    ('', ''),
    (' \t ', ' \t '),
  ]) {
    test(
      'append keeps tag boundaries in both lanes: ${jsonEncode(input)}',
      () async {
        final created = await create({
          'title': 'Fixture',
          'content': 'blue_eyes',
          'negativeContent': 'bad_hands',
        });
        for (final scope in [PillScopes.main, PillScopes.negative]) {
          container
              .read(pillWorkspaceProvider(scope).notifier)
              .replaceWithPlainText(input);
        }
        container
            .read(generationParamsNotifierProvider.notifier)
            .updatePromptImmediately(input);
        container
            .read(generationParamsNotifierProvider.notifier)
            .updateNegativePromptImmediately(input);
        await insert(created['id'] as String);
        expect(
          container.read(pillWorkspaceProvider(PillScopes.main)).projection,
          '${prefix}blue_eyes',
        );
        expect(
          container.read(pillWorkspaceProvider(PillScopes.negative)).projection,
          '${prefix}bad_hands',
        );
      },
    );
  }

  test(
    'character insertion preserves identity/metadata and supports explicit raw offsets',
    () async {
      final created = await create({
        'title': '角色',
        'content': 'blue eyes',
        'negativeContent': 'red eyes',
      });
      final scope = PillScopes.charPos('kept');
      await insert(created['id'] as String, scope: scope, offset: 0);
      final config = container.read(characterPromptNotifierProvider);
      expect(config.characters.single.prompt, 'blue eyesraw character');
      expect(config.characters.single.negativePrompt, 'raw uc, red eyes');
      expect(config.characters.single.name, 'My character');
      expect(config.characters.single.thumbnailPath, 'local-thumbnail');
    },
  );

  test(
    'instance settings, locking and enabled state change the actual editor, not the library',
    () async {
      final created = await create({
        'title': '随机',
        'content': 'blue, green',
        'atoms': ['blue', 'green'],
      });
      final id = created['id'] as String;
      final inserted = await insert(id);
      final marker =
          inserted['lanes']['main']['inserted_markers'].single as String;
      final result = await run('block_manage', {
        'action': 'instance_update',
        'scope': 'main',
        'marker': marker,
        'expected_draft_version': draft().acknowledgementVersion,
        'instance': {
          'settings': {'mode': 'random', 'countMin': 1, 'countMax': 1},
          'locked': true,
        },
      });
      final actual =
          result['lanes']['main']['document']['instances'][marker] as Map;
      expect(actual['settings']['mode'], 'random');
      expect(actual['currentRoll'], anyOf('blue', 'green'));
      expect(actual['locked'], true);
      expect((await repository.getBlock(id))!.content, 'blue, green');
      await run('block_manage', {
        'action': 'instance_update',
        'marker': marker,
        'expected_draft_version': draft().acknowledgementVersion,
        'instance': {'enabled': false},
      });
      expect(container.read(generationParamsNotifierProvider).prompt, '');
    },
  );

  test(
    'updating a library block preserves mounted instances and immediately refreshes unmounted projections',
    () async {
      final created = await create({'title': '眼睛', 'content': 'blue eyes'});
      final id = created['id'] as String;
      final inserted = await insert(id, scope: 'negative');
      final document = container
          .read(pillWorkspaceProvider('negative'))
          .document;
      await run('block_manage', {
        'action': 'update',
        'id': id,
        'expected_version': (await block(id))['version'],
        'changes': {'content': 'green eyes'},
      });
      expect(
        container.read(pillWorkspaceProvider('negative')).document.text,
        document.text,
      );
      expect(
        container.read(generationParamsNotifierProvider).negativePrompt,
        'green eyes',
      );
      expect(inserted['lanes']['negative']['inserted_markers'].length, 1);
    },
  );

  test(
    'stale block and draft versions never overwrite newer changes',
    () async {
      final created = await create({'title': 'one', 'content': 'original'});
      final id = created['id'] as String,
          oldVersion = created['block']['version'] as String;
      final originalDraft = draft();
      await repository.updateBlock(
        (await repository.getBlock(id))!.copyWith(content: 'new user edit'),
      );
      await expectLater(
        run('block_manage', {
          'action': 'update',
          'id': id,
          'expected_version': oldVersion,
          'changes': {'content': 'stale model edit'},
        }),
        throwsA(toolError('block_conflict')),
      );
      container
          .read(generationParamsNotifierProvider.notifier)
          .updatePromptImmediately('new draft');
      await expectLater(
        run('block_manage', {
          'action': 'insert',
          'id': id,
          'expected_version': (await block(id))['version'],
          'expected_draft_version': originalDraft.acknowledgementVersion,
        }),
        throwsA(toolError('draft_conflict')),
      );
      expect((await repository.getBlock(id))!.content, 'new user edit');
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        'new draft',
      );
    },
  );

  test(
    'invalid block fields and instance scopes/markers/settings fail before a backup or mutation',
    () async {
      await expectLater(
        create({'title': 'bad', 'content': 'raw', 'id': 'invented'}),
        throwsA(toolError('invalid_changes')),
      );
      final created = await create({'title': 'good', 'content': 'raw'});
      final dir = Directory('${workspace.path}/.agent/snapshot-backups');
      final count = await dir.list().length;
      final id = created['id'] as String;
      for (final patch in [
        {'scope': 'unknown'},
        {'scope': 'char:deleted:pos'},
        {'offset': 999999},
      ]) {
        await expectLater(
          run('block_manage', {
            'action': 'insert',
            'id': id,
            'expected_version': (await block(id))['version'],
            'expected_draft_version': draft().acknowledgementVersion,
            ...patch,
          }),
          throwsA(isA<NaiAgentToolError>()),
        );
      }
      final inserted = await insert(id);
      final marker =
          inserted['lanes']['main']['inserted_markers'].single as String;
      final before = draft();
      await expectLater(
        run('block_manage', {
          'action': 'instance_update',
          'marker': marker,
          'expected_draft_version': before.acknowledgementVersion,
          'instance': {
            'settings': {'triggerProbability': 8},
          },
        }),
        throwsA(toolError('invalid_instance')),
      );
      expect(draft().acknowledgementVersion, before.acknowledgementVersion);
      expect(
        await dir.list().length,
        count + 1,
      ); // only the valid insertion added a backup
    },
  );

  test(
    'a thumbnail is backed up as bytes before deleting its library row',
    () async {
      final file = File('${root.path}/synthetic-thumbnail.png');
      final pixels = <int>[137, 80, 78, 71, 0, 1, 2, 3];
      await file.writeAsBytes(pixels);
      final original = await repository.createBlock(
        title: 'preview',
        content: 'raw',
        thumbnail: file.path,
      );
      final result = await run('block_manage', {
        'action': 'delete',
        'id': original.id,
        'expected_version': (await block(original.id))['version'],
      });
      final backup = jsonDecode(
        await File(result['backup_path'] as String).readAsString(),
      );
      expect(
        base64Decode(backup['generation']['affected_thumbnail']['data_base64']),
        pixels,
      );
      expect(await repository.getBlock(original.id), null);
      expect(await file.exists(), true);
    },
  );

  test(
    'a delayed usage reply cannot restore old content into a newer provider projection',
    () async {
      final created = await create({'title': 'live', 'content': 'old content'});
      final id = created['id'] as String;
      final reached = Completer<void>(), release = Completer<void>();
      repository.afterUsage = () async {
        if (!reached.isCompleted) reached.complete();
        await release.future;
      };
      try {
        await insert(id);
        await reached.future;
        await run('block_manage', {
          'action': 'update',
          'id': id,
          'expected_version': (await block(id))['version'],
          'changes': {'content': 'newer content'},
        });
        expect(
          container.read(pillWorkspaceProvider('main')).projection,
          'newer content',
        );
        release.complete();
        await Future<void>.delayed(Duration.zero);
        expect(
          container
              .read(promptBlockLibraryNotifierProvider)
              .valueOrNull!
              .blockById(id)!
              .content,
          'newer content',
        );
        expect(
          container.read(pillWorkspaceProvider('main')).projection,
          'newer content',
        );
        expect(
          container.read(generationParamsNotifierProvider).prompt,
          'newer content',
        );
        expect((await repository.getBlock(id))!.useCount, 1);
      } finally {
        if (!release.isCompleted) release.complete();
      }
    },
  );

  test(
    'stopping before a tool starts leaves the real repository unchanged',
    () async {
      final token = NaiAgentCancellation()..cancel();
      await expectLater(
        container
            .read(naiAgentStudioFactoryProvider)(workspace, root, true)
            .execute('block_manage', {
              'action': 'create',
              'changes': {'title': 'cancelled', 'content': 'raw'},
            }, token),
        throwsA(toolError('cancelled')),
      );
      expect((await repository.load()).blocks, isEmpty);
    },
  );
}
