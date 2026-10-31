import '../../../helpers/fetch_test_server.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/core/utils/novelai_vibe_codec.dart';
import 'package:nai_launcher/core/utils/vibe_library_path_helper.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_files.dart';
import 'package:nai_launcher/data/services/precise_ref_library_storage_service.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/data/services/vibe_file_storage_service.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/vibe_library_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_studio_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_reference_binding.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_reference_library_binding.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_model_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_session_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_questions.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import '../krita/agent_bridge_draft_test.dart'
    show MemoryDraftSettings, MemoryCharacters, IdleGeneration;
import 'generation_binding_test.dart' show GenerationTestLibrary;
import 'studio_host_integration_test.dart' show tool;

class _Files extends VibeFileStorageService {
  bool retain = false;
  @override
  Future<bool> deleteVibeFile(String path) async =>
      retain ? false : super.deleteVibeFile(path);
}

class _Storage extends VibeLibraryStorageService {
  _Storage(this.files) : super(fileStorage: files);
  final _Files files;
  bool failFavorite = false;
  @override
  Future<void> saveGenerationStateJson(String value) async {}
  @override
  Future<String?> loadGenerationStateJson() async => null;
  @override
  Future<VibeLibraryEntry?> toggleFavorite(String id) {
    if (failFavorite) throw StateError('favorite_fixture_failure');
    return super.toggleFavorite(id);
  }
}

class _AfterExport extends AgentWorkspaceFiles {
  _AfterExport(super.workspace, this.after);
  final Future<void> Function() after;
  @override
  Future<String> export(
    String name,
    Uint8List bytes,
    void Function() check, {
    Map<String, Uint8List> companions = const {},
  }) async {
    final result = await super.export(
      name,
      bytes,
      check,
      companions: companions,
    );
    await after();
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late ProviderContainer container;
  late _Storage storage;
  late PreciseRefLibraryStorageService precise;
  late Uint8List pixels;
  late NaiAgentModelConnection connection;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp(
      'nai-agent-reference-management-',
    );
    Hive.init(root.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await VibeLibraryPathHelper.instance.setPath('${root.path}/vibes');
    storage = _Storage(_Files());
    precise = PreciseRefLibraryStorageService(
      overrideDirectory: '${root.path}/precise',
    );
    final blocks = PromptBlockStorage(hivePath: root.path);
    await blocks.init();
    pixels = Uint8List.fromList(
      img.encodePng(img.Image(width: 128, height: 128)),
    );
    await File('${root.path}/image.png').writeAsBytes(pixels);
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockRepositoryProvider.overrideWithValue(
          PromptBlockRepository(blocks),
        ),
        promptBlockLibraryNotifierProvider.overrideWith(
          GenerationTestLibrary.new,
        ),
        imageGenerationNotifierProvider.overrideWith(IdleGeneration.new),
        vibeLibraryStorageServiceProvider.overrideWithValue(storage),
        preciseRefLibraryStorageServiceProvider.overrideWithValue(precise),
        naiAgentModelResolverProvider.overrideWithValue(
          (_, __) async => connection,
        ),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
  });
  tearDown(() async {
    container.dispose();
    await Future<void>.delayed(Duration.zero);
    await storage.close();
    await Hive.close();
    await root.delete(recursive: true);
  });
  Future<Map> run(Map<String, dynamic> p) async =>
      (await container
              .read(naiAgentStudioFactoryProvider)(root, root, false)
              .execute(
                'reference_library',
                p,
                NaiAgentCancellation(),
              ))['details']
          as Map;
  Matcher error(String code) =>
      throwsA(isA<NaiAgentToolError>().having((e) => e.code, 'code', code));
  Future<Map> read(String id, {String kind = 'vibe'}) =>
      run({'action': 'read', 'kind': kind, 'id': id});
  Future<Map> update(
    String id,
    Map<String, dynamic> changes, {
    String kind = 'vibe',
    int? child,
  }) async => run({
    'action': 'update',
    'kind': kind,
    'id': id,
    'changes': changes,
    'expected_entry_version': (await read(id, kind: kind))['entry_version'],
    if (child != null) 'child_index': child,
  });
  Future<Map> category(
    Map<String, dynamic> changes, {
    String? id,
    String action = 'category_create',
  }) async => run({
    'action': action,
    'changes': changes,
    if (id != null) 'id': id,
    'expected_category_version': (await run({
      'action': 'categories',
    }))['category_version'],
  });
  Future<Map> importVibe({
    bool bundle = false,
    bool variants = false,
    bool raw = false,
  }) async {
    final values = [
      for (var i = 0; i < (bundle ? 2 : 1); i++)
        VibeReference(
          displayName: 'child-$i',
          vibeEncoding: raw ? '' : 'primary-$i',
          encodingModel: 'nai-diffusion-4-5-full',
          rawImageData: pixels,
          thumbnail: pixels,
          strength: 0.4,
          infoExtracted: 0.6,
        ),
    ];
    final map = bundle
        ? NovelAiVibeCodec.buildBundleMap(values)
        : NovelAiVibeCodec.buildSingleMap(values.single);
    if (variants) {
      for (final single in bundle ? map['vibes'] as List : [map]) {
        single['encodings']['v4full'] = {
          'other': {
            'encoding': 'other-model',
            'params': {'information_extracted': 0.6},
          },
        };
        single['encodings']['v4-5full']['additional'] = {
          'encoding': 'info-0.8',
          'params': {'information_extracted': 0.8},
        };
      }
    }
    final name = bundle ? 'source.naiv4vibebundle' : 'source.naiv4vibe';
    await File('${root.path}/$name').writeAsString(jsonEncode(map));
    return (await run({
          'action': 'import',
          'path': name,
          'name': 'Original',
        }))['saved']
        as Map;
  }

  NaiAgentReferenceLibraryBinding binding(
    Future<void> Function() after, {
    bool busy = false,
    bool alive = true,
  }) {
    final tools = container.read(naiAgentStudioFactoryProvider)(
      root,
      root,
      false,
    );
    final provider = Provider(
      (ref) => NaiAgentReferenceLibraryBinding(
        ref,
        root,
        NaiAgentReferenceBinding(
          ref,
          root,
          tools.loadImage,
          () => busy,
          () => alive,
        ),
        tools.loadImage,
        () => busy,
        () => alive,
        workspaceFiles: _AfterExport(root, after),
      ),
    );
    return container.read(provider);
  }

  test(
    'Vibe metadata and strength edits use native storage, original backup and leave the draft alone',
    () async {
      final entry = await importVibe(variants: true);
      final id = entry['id'] as String;
      final original = await File(
        (await storage.getEntryRecord(id))!.filePath!,
      ).readAsBytes();
      final folder = (await category({'name': 'Styles'}))['category'] as Map;
      final before = container.read(generationParamsNotifierProvider);
      await container.read(vibeLibraryNotifierProvider.notifier).reload();
      await container
          .read(vibeLibraryNotifierProvider.notifier)
          .setSearchQuery('Updated');
      final result = await update(id, {
        'name': 'Updated',
        'favorite': true,
        'category_id': folder['id'],
        'tags': ['blue', ' blue ', 'white'],
        'strength': 0.75,
      });
      expect(result['ok'], true);
      expect(result['entry_version'], (await read(id))['entry_version']);
      final actual = (await storage.getEntry(id))!;
      expect(
        (actual.name, actual.isFavorite, actual.categoryId, actual.strength),
        ('Updated', true, folder['id'], 0.75),
      );
      expect(actual.tags, ['blue', 'white']);
      expect(actual.usedCount, 0);
      expect(actual.rawImageData, pixels);
      final saved = jsonDecode(await File(actual.filePath!).readAsString());
      expect(saved['encodings']['v4full']['other']['encoding'], 'other-model');
      expect(
        saved['encodings']['v4-5full']['additional']['encoding'],
        'info-0.8',
      );
      expect(
        await File(
          '${root.path}/${result['backup']['original_path']}',
        ).readAsBytes(),
        original,
      );
      expect(container.read(generationParamsNotifierProvider), same(before));
      expect(
        container.read(vibeLibraryNotifierProvider).searchQuery,
        'Updated',
      );
      expect(container.read(vibeLibraryNotifierProvider).entries.single.id, id);
      final cleared = await update(id, {
        'category_id': null,
        'favorite': false,
        'tags': [],
      });
      expect(cleared['entry']['category_id'], isNull);
      expect(cleared['entry']['favorite'], false);
    },
  );
  test(
    'precise metadata edits retain native free-form strengths and original bytes',
    () async {
      final entry =
          (await run({
                'kind': 'precise',
                'action': 'import',
                'path': 'image.png',
              }))['saved']
              as Map;
      final before = container.read(generationParamsNotifierProvider);
      final result = await update(entry['id'] as String, {
        'name': 'Precise new',
        'favorite': true,
        'type': 'style',
        'strength': 1.4,
        'fidelity': -0.1,
      }, kind: 'precise');
      expect(result['ok'], true);
      final actual = (await precise.getAllEntries()).single;
      expect(
        (
          actual.name,
          actual.type.name,
          actual.strength,
          actual.fidelity,
          actual.isFavorite,
        ),
        ('Precise new', 'style', 1.4, -0.1, true),
      );
      expect(await File(actual.imagePath).readAsBytes(), pixels);
      expect(
        await File(
          '${root.path}/${result['backup']['original_path']}',
        ).readAsBytes(),
        pixels,
      );
      expect(container.read(generationParamsNotifierProvider), same(before));
      await expectLater(
        update(entry['id'] as String, {
          'tags': ['unsupported'],
        }, kind: 'precise'),
        error('invalid_reference'),
      );
    },
  );
  test(
    'an exact existing information variant is reused and all compatible model encodings survive',
    () async {
      final id = (await importVibe(variants: true))['id'] as String;
      final result = await update(id, {'info_extracted': 0.8});
      expect(result['ok'], true);
      final actual = (await storage.getEntry(id))!;
      expect((actual.infoExtracted, actual.vibeEncoding), (0.8, 'info-0.8'));
      final json = jsonDecode(await File(actual.filePath!).readAsString());
      expect(json['encodings']['v4full']['other']['encoding'], 'other-model');
      expect(
        (json['encodings']['v4-5full'] as Map).values.any(
          (v) => v['encoding'] == 'primary-0',
        ),
        true,
      );
      expect(result['paid_encoding'], false);
    },
  );
  test(
    'editing one native bundle child retains other children and all model variants',
    () async {
      final id =
          (await importVibe(bundle: true, variants: true))['id'] as String;
      await expectLater(
        update(id, {'strength': 0.9}),
        error('invalid_reference'),
      );
      final result = await update(id, {'strength': 0.9}, child: 1);
      expect(result['ok'], true);
      final json = jsonDecode(
        await File(
          (await storage.getEntryRecord(id))!.filePath!,
        ).readAsString(),
      );
      expect(json['vibes'][0]['importInfo']['strength'], 0.4);
      expect(json['vibes'][1]['importInfo']['strength'], 0.9);
      for (final child in json['vibes'] as List) {
        expect(
          child['encodings']['v4full']['other']['encoding'],
          'other-model',
        );
        expect(
          child['encodings']['v4-5full']['additional']['encoding'],
          'info-0.8',
        );
      }
    },
  );
  test(
    'uncached paid encoding is rejected before any library change; raw information edits remain free',
    () async {
      final id = (await importVibe())['id'] as String;
      final original = await File(
        (await storage.getEntryRecord(id))!.filePath!,
      ).readAsBytes();
      await expectLater(
        update(id, {'name': 'Must not rename', 'info_extracted': 0.81}),
        error('encoding_required'),
      );
      expect((await storage.getEntryRecord(id))!.name, 'Original');
      expect(
        await File((await storage.getEntryRecord(id))!.filePath!).readAsBytes(),
        original,
      );
      expect(await Directory('${root.path}/.W.O.F/outputs').exists(), false);
      final raw = (await importVibe(raw: true))['id'] as String;
      expect((await update(raw, {'info_extracted': 0.83}))['ok'], true);
      expect((await read(raw))['vibes'].single['info_extracted'], 0.83);
    },
  );
  for (final kind in ['vibe', 'precise']) {
    test(
      '$kind deletion removes the native entry/file but retains the original backup and current draft references',
      () async {
        final entry = kind == 'vibe'
            ? await importVibe(variants: true)
            : (await run({
                    'kind': kind,
                    'action': 'import',
                    'path': 'image.png',
                  }))['saved']
                  as Map;
        final id = entry['id'] as String;
        final source = kind == 'vibe'
            ? (await storage.getEntryRecord(id))!.filePath!
            : (await precise.getAllEntries()).single.imagePath;
        final original = await File(source).readAsBytes();
        final full = await read(id, kind: kind);
        final tools = container.read(naiAgentStudioFactoryProvider)(
          root,
          root,
          false,
        );
        final context = await tools.execute('studio_context', {
          'scope': 'draft',
        }, NaiAgentCancellation());
        await run({
          'action': 'apply',
          'kind': kind,
          'id': id,
          'expected_entry_version': full['entry_version'],
          'expected_draft_version':
              context['details']['draft']['draft_version'],
        });
        final current = container.read(generationParamsNotifierProvider);
        final version = (await read(id, kind: kind))['entry_version'];
        expect(
          version,
          full['entry_version'],
        ); // Usage alone never expires an entry acknowledgement.
        final result = await run({
          'action': 'delete',
          'kind': kind,
          'id': id,
          'expected_entry_version': version,
        });
        expect(result['deleted'], true);
        expect(await File(source).exists(), false);
        expect(
          await File(
            '${root.path}/${result['backup']['original_path']}',
          ).readAsBytes(),
          original,
        );
        final metadata = jsonDecode(
          await File(
            '${root.path}/${result['backup']['metadata_path']}',
          ).readAsString(),
        );
        expect(metadata['entry']['used_count'], 1);
        expect(container.read(generationParamsNotifierProvider), same(current));
        await expectLater(read(id, kind: kind), error('entry_missing'));
      },
    );
    test(
      '$kind missing-file entries remain readable and can be cleaned up without inventing an original',
      () async {
        final entry = kind == 'vibe'
            ? await importVibe()
            : (await run({
                    'kind': kind,
                    'action': 'import',
                    'path': 'image.png',
                  }))['saved']
                  as Map;
        final id = entry['id'] as String;
        final source = kind == 'vibe'
            ? (await storage.getEntryRecord(id))!.filePath!
            : (await precise.getAllEntries()).single.imagePath;
        await File(source).delete();
        final full = await read(id, kind: kind);
        expect(full['file_missing'], true);
        await expectLater(
          run({'action': 'export', 'kind': kind, 'id': id}),
          error('file_missing'),
        );
        final result = await run({
          'action': 'delete',
          'kind': kind,
          'id': id,
          'expected_entry_version': full['entry_version'],
        });
        expect(result['deleted'], true);
        expect(result['backup']['original_path'], isNull);
        final metadata = jsonDecode(
          await File(
            '${root.path}/${result['backup']['metadata_path']}',
          ).readAsString(),
        );
        if (kind == 'vibe') {
          expect(
            base64Decode(metadata['native_record']['raw_image_data'] as String),
            pixels,
          );
          expect(metadata['native_record']['vibe_encoding'], 'primary-0');
        }
        expect(
          jsonDecode(
            await File(
              '${root.path}/${result['backup']['metadata_path']}',
            ).readAsString(),
          )['file_missing'],
          true,
        );
      },
    );
    test(
      '$kind damaged-file entries report their state and retain damaged bytes in the deletion backup',
      () async {
        final entry = kind == 'vibe'
            ? await importVibe()
            : (await run({
                    'kind': kind,
                    'action': 'import',
                    'path': 'image.png',
                  }))['saved']
                  as Map;
        final id = entry['id'] as String;
        final source = kind == 'vibe'
            ? (await storage.getEntryRecord(id))!.filePath!
            : (await precise.getAllEntries()).single.imagePath;
        final damaged = Uint8List.fromList([1, 2, 3]);
        await File(source).writeAsBytes(damaged);
        final full = await read(id, kind: kind);
        expect(full['file_invalid'], true);
        await expectLater(
          run({'action': 'apply', 'kind': kind, 'id': id}),
          error('file_invalid'),
        );
        final result = await run({
          'action': 'delete',
          'kind': kind,
          'id': id,
          'expected_entry_version': full['entry_version'],
        });
        expect(result['deleted'], true);
        expect(
          await File(
            '${root.path}/${result['backup']['original_path']}',
          ).readAsBytes(),
          damaged,
        );
        final metadata = jsonDecode(
          await File(
            '${root.path}/${result['backup']['metadata_path']}',
          ).readAsString(),
        );
        expect(metadata['file_invalid'], true);
        if (kind == 'vibe') {
          expect(
            base64Decode(metadata['native_record']['raw_image_data'] as String),
            pixels,
          );
        }
      },
    );
  }
  test(
    'a native failed file deletion reports the remaining file even when the index entry was removed',
    () async {
      final id = (await importVibe())['id'] as String;
      final source = (await storage.getEntryRecord(id))!.filePath!;
      storage.files.retain = true;
      final result = await run({
        'action': 'delete',
        'id': id,
        'expected_entry_version': (await read(id))['entry_version'],
      });
      expect(result['ok'], false);
      expect(result['deleted'], true);
      expect(result['error'], 'reference_file_remains');
      expect(result['residual_reference_file'], true);
      expect(result['residual_file_path'], source);
      expect(await storage.getEntryRecord(id), isNull);
      expect(await File(source).exists(), true);
      expect(
        await File(
          '${root.path}/${result['backup']['original_path']}',
        ).exists(),
        true,
      );
    },
  );
  test(
    'native category creation, rename, ordering and reparenting protect the tree against cycles and stale versions',
    () async {
      final parent =
          (await category({'name': 'Parent'}))['category']['id'] as String;
      final child =
          (await category({
                'name': 'Child',
                'parent_id': parent,
                'sort_order': 2,
              }))['category']['id']
              as String;
      await expectLater(
        category({'parent_id': child}, id: parent, action: 'category_update'),
        error('category_cycle'),
      );
      await expectLater(
        category({'name': ' child ', 'parent_id': parent}),
        error('name_conflict'),
      );
      await expectLater(
        category({'name': 'Unknown parent', 'parent_id': 'no-category'}),
        error('category_missing'),
      );
      await category(
        {'name': 'Renamed', 'parent_id': null, 'sort_order': 1},
        id: child,
        action: 'category_update',
      );
      expect((await storage.getCategory(child))!.parentId, isNull);
      final page = await run({
        'action': 'categories',
        'query': 'rename',
        'limit': 1,
      });
      expect(page['categories'].single['name'], 'Renamed');
      final old = page['category_version'];
      await category({'name': 'New'});
      await expectLater(
        run({
          'action': 'category_delete',
          'id': parent,
          'expected_category_version': old,
        }),
        error('category_conflict'),
      );
      await expectLater(
        run({'kind': 'precise', 'action': 'categories'}),
        error('unsupported_reference'),
      );
    },
  );
  test(
    'deleting a native category moves membership and children and clears only its obsolete active filter',
    () async {
      final parent =
          (await category({'name': 'Parent'}))['category']['id'] as String;
      final folder =
          (await category({
                'name': 'Folder',
                'parent_id': parent,
              }))['category']['id']
              as String;
      final child =
          (await category({
                'name': 'Child',
                'parent_id': folder,
              }))['category']['id']
              as String;
      final id = (await importVibe())['id'] as String;
      await update(id, {'category_id': folder});
      await container.read(vibeLibraryNotifierProvider.notifier).reload();
      final ui = container.read(vibeLibraryNotifierProvider.notifier);
      await ui.setSearchQuery('Original');
      await ui.setCategoryFilter(folder);
      final result = await run({
        'action': 'category_delete',
        'id': folder,
        'expected_category_version': (await run({
          'action': 'categories',
        }))['category_version'],
      });
      expect(result['deleted'], true);
      expect((await storage.getEntryRecord(id))!.categoryId, parent);
      expect((await storage.getCategory(child))!.parentId, parent);
      expect(await storage.getCategory(folder), isNull);
      expect(
        container.read(vibeLibraryNotifierProvider).selectedCategoryId,
        isNull,
      );
      expect(
        container.read(vibeLibraryNotifierProvider).searchQuery,
        'Original',
      );
      final backup = jsonDecode(
        await File('${root.path}/${result['backup_path']}').readAsString(),
      );
      expect((backup['members'] as List).single['category_id'], folder);
      expect(
        (backup['categories'] as List).where((c) => c['id'] == folder),
        hasLength(1),
      );
      expect(
        await File((await storage.getEntryRecord(id))!.filePath!).exists(),
        true,
      );
    },
  );
  test(
    'real backup source edits and Stop prevent a stale native deletion',
    () async {
      final id = (await importVibe())['id'] as String;
      final version = (await read(id))['entry_version'];
      final changed = binding(() async {
        await storage.toggleFavorite(id);
      });
      await expectLater(
        changed.execute({
          'action': 'delete',
          'id': id,
          'expected_entry_version': version,
        }, NaiAgentCancellation()),
        error('entry_conflict'),
      );
      expect((await storage.getEntryRecord(id))!.isFavorite, true);
      final token = NaiAgentCancellation();
      final stopped = binding(() async {
        token.cancel();
      });
      await expectLater(
        stopped.execute({
          'action': 'delete',
          'id': id,
          'expected_entry_version': (await read(id))['entry_version'],
        }, token),
        error('cancelled'),
      );
      expect(await storage.getEntryRecord(id), isNotNull);
      expect(
        await File((await storage.getEntryRecord(id))!.filePath!).exists(),
        true,
      );
    },
  );
  test(
    'busy/closed management refuses before backup; invalid changes preserve entry and file',
    () async {
      final id = (await importVibe())['id'] as String;
      final version = (await read(id))['entry_version'];
      for (final changes in [
        {'favorite': 'yes'},
        {
          'tags': [null],
        },
        {'strength': double.infinity},
        {'info_extracted': 0},
        {'category_id': 1},
        {'name': ''},
        {'type': 'style'},
      ]) {
        await expectLater(
          run({
            'action': 'update',
            'id': id,
            'expected_entry_version': version,
            'changes': changes,
          }),
          error('invalid_reference'),
        );
      }
      await expectLater(
        update(id, {'category_id': 'unknown'}),
        error('category_missing'),
      );
      await expectLater(
        binding(() async {}, busy: true).execute({
          'action': 'delete',
          'id': id,
          'expected_entry_version': version,
        }, NaiAgentCancellation()),
        error('busy'),
      );
      await expectLater(
        binding(() async {}, alive: false).execute({
          'action': 'delete',
          'id': id,
          'expected_entry_version': version,
        }, NaiAgentCancellation()),
        error('closed'),
      );
      expect(await Directory('${root.path}/.W.O.F/outputs').exists(), false);
    },
  );
  test(
    'partial native failure reports applied fields and an actual backup without rollback or false success',
    () async {
      final id = (await importVibe())['id'] as String;
      storage.failFavorite = true;
      final result = await update(id, {
        'name': 'Committed name',
        'tags': ['committed'],
        'favorite': true,
      });
      expect(result['ok'], false);
      expect(result['applied_fields'], ['name', 'tags']);
      expect(result['error'], 'favorite_fixture_failure');
      final actual = (await storage.getEntryRecord(id))!;
      expect((actual.name, actual.isFavorite), ('Committed name', false));
      expect(actual.tags, ['committed']);
      expect(
        await File(
          '${root.path}/${result['backup']['original_path']}',
        ).exists(),
        true,
      );
      expect(result['entry_version'], (await read(id))['entry_version']);
    },
  );
  test(
    'official Pi manages and deletes real native entries through the advertised schema',
    () async {
      final original = utf8.encode(
        jsonEncode(
          NovelAiVibeCodec.buildSingleMap(
            VibeReference(
              displayName: 'Pi reference',
              vibeEncoding: 'native-Pi-encoding',
              encodingModel: 'nai-diffusion-4-5-full',
              rawImageData: pixels,
              thumbnail: pixels,
              strength: 0.55,
              infoExtracted: 0.65,
            ),
          ),
        ),
      );
      await File('${root.path}/pi.naiv4vibe').writeAsBytes(original);
      final requests = <Map<String, dynamic>>[];
      final events = <Map<String, dynamic>>[];
      String? id, categoryId;
      final server = await bindFetchTestServer();
      final serving = server.listen((request) async {
        final body =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        requests.add(body);
        final turn = requests.length;
        Map? previous;
        if (turn > 1) {
          final content = (body['messages'] as List).lastWhere(
            (m) => m['role'] == 'tool',
          )['content'];
          previous =
              jsonDecode(content is String ? content : content[0]['text'])
                  as Map;
        }
        if (turn == 2) id = previous!['saved']['id'] as String;
        if (turn == 6) categoryId = previous!['category']['id'] as String;
        final delta = switch (turn) {
          1 => tool('import', 'reference_library', {
            'action': 'import',
            'path': 'pi.naiv4vibe',
            'name': 'Pi original',
          }),
          2 => tool('read', 'reference_library', {'action': 'read', 'id': id}),
          3 => tool('update', 'reference_library', {
            'action': 'update',
            'id': id,
            'expected_entry_version': previous!['entry_version'],
            'changes': {
              'name': 'Pi renamed',
              'favorite': true,
              'tags': ['Pi-test'],
            },
          }),
          4 => tool('categories', 'reference_library', {
            'action': 'categories',
          }),
          5 => tool('category-create', 'reference_library', {
            'action': 'category_create',
            'expected_category_version': previous!['category_version'],
            'changes': {'name': 'Pi styles'},
          }),
          6 => tool('read-fresh', 'reference_library', {
            'action': 'read',
            'id': id,
          }),
          7 => tool('categorize', 'reference_library', {
            'action': 'update',
            'id': id,
            'expected_entry_version': previous!['entry_version'],
            'changes': {'category_id': categoryId},
          }),
          8 => tool('read-again', 'reference_library', {
            'action': 'read',
            'id': id,
          }),
          9 => tool('delete', 'reference_library', {
            'action': 'delete',
            'id': id,
            'expected_entry_version': previous!['entry_version'],
          }),
          10 => tool('query-after-delete', 'reference_library', {
            'action': 'query',
            'favorites_only': true,
          }),
          _ => {'content': '参考已整理并删除，原文件和设置备份保留。'},
        };
        request.response.headers.set(
          'content-type',
          'text/event-stream; charset=utf-8',
        );
        for (final item in [
          {'index': 0, 'delta': delta, 'finish_reason': null},
          {
            'index': 0,
            'delta': {},
            'finish_reason': turn < 11 ? 'tool_calls' : 'stop',
          },
        ]) {
          request.response.write(
            'data: ${jsonEncode({
              'id': 'synthetic',
              'object': 'chat.completion.chunk',
              'model': 'synthetic',
              'choices': [item],
            })}\n\n',
          );
        }
        request.response.write('data: [DONE]\n\n');
        await request.response.close();
      });
      connection = mapNaiAgentModel(
        ProviderConfig(
          id: 'local',
          name: 'Synthetic',
          baseUrl: 'http://127.0.0.1:${server.port}',
        ),
        const ModelConfig(
          providerId: 'local',
          name: 'synthetic',
          displayName: 'Synthetic',
          supportsTools: true,
        ),
        apiKey: 'synthetic-private-key',
      );
      PiHostClient? client;
      StreamSubscription<Map<String, dynamic>>? subscription;
      final before = container.read(generationParamsNotifierProvider);
      final broker = container.read(naiAgentQuestionsProvider);
      var approvals = 0;
      void approve() {
        for (final request in broker.forChat('native-reference-management')) {
          if (request.kind != 'tool_approval') continue;
          approvals++;
          final question = request.questions.single;
          broker.answer(request.id, {question.id: question.options.first});
        }
      }

      broker.addListener(approve);
      try {
        client = await container.read(naiAgentSessionStarterProvider)(
          mcp: const {'builtinExposure': 'direct'},
          providerId: 'local',
          modelId: 'synthetic',
          workspaceId: 'native-reference-management',
          workspace: root,
          data: Directory('${root.path}/agent'),
          nodeExecutable:
              Platform.environment['NAI_AGENT_NODE'] ?? 'E:/node/node.exe',
          hostScript: File('tool/nai_agent/host.mjs').absolute.path,
          systemPrompt: '你是 NAI Agent。使用真实库并核对当前版本。',
          executeExtraTool: (name, params, cancel) => broker.askExtensionUi(
            'native-reference-management',
            'native-reference-management',
            params,
            cancel,
          ),
        );
        subscription = client.events.listen(events.add);
        await client
            .prompt('整理这个参考，备份后删除。')
            .timeout(const Duration(seconds: 30));
        expect(requests, hasLength(11));
        expect(approvals, greaterThan(0));
        final ends = events
            .where((e) => e['event']?['type'] == 'tool_execution_end')
            .toList();
        expect(ends, hasLength(10));
        expect(ends.every((e) => e['event']['isError'] == false), true);
        expect(await storage.getEntryRecord(id!), isNull);
        expect((await storage.getCategory(categoryId!))!.name, 'Pi styles');
        expect(container.read(generationParamsNotifierProvider), same(before));
        final backups = await Directory(
          '${root.path}/.W.O.F/outputs',
        ).list().where((f) => f is Directory).toList();
        expect(backups, hasLength(4));
        for (final dir in backups.where(
          (d) => File('${d.path}/original.naiv4vibe').existsSync(),
        )) {
          expect(
            await File('${dir.path}/original.naiv4vibe').readAsBytes(),
            original,
          );
        }
        final result = requests.last['messages'].lastWhere(
          (m) => m['role'] == 'tool',
        )['content'];
        expect(
          jsonDecode(
            result is String ? result : result[0]['text'],
          )['total_count'],
          0,
        );
        expect(await File('${root.path}/pi.naiv4vibe').readAsBytes(), original);
        expect(
          jsonEncode(requests.last),
          isNot(contains('synthetic-private-key')),
        );
        expect(
          jsonEncode(requests.last),
          isNot(contains('native-Pi-encoding')),
        );
      } finally {
        broker.removeListener(approve);
        await subscription?.cancel();
        await client?.close();
        await serving.cancel();
        await server.close(force: true);
      }
    },
  );
}
