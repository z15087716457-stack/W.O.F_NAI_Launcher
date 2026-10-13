import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
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
  setUp(() async {
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
