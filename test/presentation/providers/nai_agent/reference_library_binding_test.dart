import '../../../helpers/fetch_test_server.dart';
import 'dart:convert';
import 'dart:async';
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
import 'package:nai_launcher/core/enums/precise_ref_type.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/core/utils/nai_api_utils.dart';
import 'package:nai_launcher/core/utils/novelai_vibe_codec.dart';
import 'package:nai_launcher/core/utils/vibe_library_path_helper.dart';
import 'package:nai_launcher/data/models/vibe/vibe_reference.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_snapshot_files.dart';
import 'package:nai_launcher/data/services/precise_ref_library_storage_service.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_studio_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_model_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_session_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_reference_binding.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_reference_library_binding.dart';
import 'package:nai_launcher/presentation/providers/vibe_library_provider.dart';
import '../krita/agent_bridge_draft_test.dart'
    show MemoryDraftSettings, MemoryCharacters, IdleGeneration;
import 'generation_binding_test.dart' show GenerationTestLibrary;
import 'studio_host_integration_test.dart' show tool;

class _Vibes extends VibeLibraryStorageService {
  @override
  Future<void> saveGenerationStateJson(String value) async {}
  @override
  Future<String?> loadGenerationStateJson() async => null;
}

class _AfterBackup extends AgentSnapshotFiles {
  _AfterBackup(super.workspace, this.after);
  final Future<void> Function() after;
  @override
  Future<Map<String, dynamic>> save(
    String name,
    Map<String, dynamic> snapshot, {
    bool backup = false,
  }) async {
    final result = await super.save(name, snapshot, backup: backup);
    await after();
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late ProviderContainer container;
  late VibeLibraryStorageService storage;
  late PreciseRefLibraryStorageService precise;
  late Uint8List pixels;
  late NaiAgentModelConnection connection;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp(
      'nai-agent-reference-library-',
    );
    Hive.init(root.path);
    await Hive.openBox(StorageKeys.settingsBox);
    await VibeLibraryPathHelper.instance.setPath('${root.path}/vibes');
    storage = _Vibes();
    precise = PreciseRefLibraryStorageService(
      overrideDirectory: '${root.path}/precise',
    );
    final blocks = PromptBlockStorage(hivePath: root.path);
    await blocks.init();
    pixels = Uint8List.fromList(
      img.encodePng(img.Image(width: 128, height: 128)),
    );
    await File('${root.path}/input.png').writeAsBytes(pixels);
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
  Future<Map> run(Map<String, dynamic> p, {bool vision = true}) async =>
      (await container
              .read(naiAgentStudioFactoryProvider)(root, root, vision)
              .execute(
                'reference_library',
                p,
                NaiAgentCancellation(),
              ))['details']
          as Map;
  Future<String> version() async =>
      (await container
              .read(naiAgentStudioFactoryProvider)(root, root, true)
              .execute(
                'reference_manage',
                {},
                NaiAgentCancellation(),
              ))['details']['draft_version']
          as String;
  Future<Map> importVibe({String name = 'encoded', int count = 1}) async {
    final values = [
      for (var i = 0; i < count; i++)
        VibeReference(
          displayName: '$name-$i',
          vibeEncoding: 'native-encoding-$i',
          encodingModel: 'nai-diffusion-4-5-full',
          sourceType: VibeSourceType.naiv4vibe,
          rawImageData: pixels,
          thumbnail: pixels,
          strength: 0.42,
          infoExtracted: 0.63,
        ),
    ];
    final fileName = count == 1 ? 'bundle.naiv4vibe' : 'bundle.naiv4vibebundle';
    final map = count == 1
        ? NovelAiVibeCodec.buildSingleMap(values.single)
        : NovelAiVibeCodec.buildBundleMap(values);
    await File('${root.path}/$fileName').writeAsString(jsonEncode(map));
    return (await run({
          'action': 'import',
          'path': fileName,
          'name': name,
        }))['saved']
        as Map;
  }

  Future<void> apply(Map entry, {String kind = 'vibe', int? child}) async {
    final full = await run({'action': 'read', 'kind': kind, 'id': entry['id']});
    await run({
      'action': 'apply',
      'kind': kind,
      'id': entry['id'],
      'expected_entry_version': full['entry_version'],
      'expected_draft_version': await version(),
      if (child != null) 'child_index': child,
    });
  }

  Matcher error(String code) =>
      throwsA(isA<NaiAgentToolError>().having((e) => e.code, 'code', code));

  test(
    'native Vibe import/read/apply preserves original pixels, encoding model and parameters without draft side effects during import',
    () async {
      final before = container.read(generationParamsNotifierProvider);
      final entry = await importVibe();
      expect(container.read(generationParamsNotifierProvider), same(before));
      final full = await run({'action': 'read', 'id': entry['id']});
      expect(full['vibes'].single['encoding_model'], 'nai-diffusion-4-5-full');
      expect(full['vibes'].single['strength'], 0.42);
      expect(jsonEncode(full), isNot(contains('native-encoding-0')));
      expect(jsonEncode(full), isNot(contains(base64Encode(pixels))));
      await apply(entry);
      final actual = container
          .read(generationParamsNotifierProvider)
          .vibeReferencesV4
          .single;
      expect(
        (actual.vibeEncoding, actual.encodingModel, actual.infoExtracted),
        ('native-encoding-0', 'nai-diffusion-4-5-full', 0.63),
      );
      expect(actual.rawImageData, pixels);
      expect((await storage.getAllEntries()).single.usedCount, 1);
      expect(
        await Directory('${root.path}/.W.O.F/snapshot-backups').exists(),
        isTrue,
      );
    },
  );
  test(
    'native bundle is paged, applied completely and rejects capacity rather than silently dropping children',
    () async {
      final entry = await importVibe(count: 3);
      final page = await run({
        'action': 'read',
        'id': entry['id'],
        'offset': 1,
        'limit': 1,
      });
      expect(page['vibe_count'], 3);
      expect(page['next_offset'], 2);
      expect(page['vibes'].single['index'], 1);
      final child = await run({
        'action': 'read',
        'id': entry['id'],
        'child_index': 2,
      });
      expect(child['vibes'].single['index'], 2);
      expect(child['next_offset'], isNull);
      await apply(entry);
      expect(
        container
            .read(generationParamsNotifierProvider)
            .vibeReferencesV4
            .map((e) => e.displayName),
        ['encoded-0', 'encoded-1', 'encoded-2'],
      );
      final writer = container.read(generationParamsNotifierProvider.notifier);
      for (var i = 0; i < 12; i++) {
        writer.addVibeReference(
          VibeReference(displayName: 'old-$i', vibeEncoding: 'old-$i'),
        );
      }
      await expectLater(apply(entry), error('invalid_reference'));
      expect(
        container
            .read(generationParamsNotifierProvider)
            .vibeReferencesV4
            .length,
        15,
      );
      await apply(entry, child: 1);
      expect(
        container
            .read(generationParamsNotifierProvider)
            .vibeReferencesV4
            .last
            .vibeEncoding,
        'native-encoding-1',
      );
    },
  );
  test(
    'precise import/apply/export uses native default settings and original bytes with a text-only model',
    () async {
      final entry =
          (await run({
                'kind': 'precise',
                'action': 'import',
                'path': 'input.png',
                'name': 'character',
                'type': 'character',
                'strength': 0.72,
                'fidelity': 0.81,
              }, vision: false))['saved']
              as Map;
      await apply(entry, kind: 'precise');
      final actual = container
          .read(generationParamsNotifierProvider)
          .preciseReferences
          .single;
      expect(
        (actual.type, actual.strength, actual.fidelity),
        (PreciseRefType.character, 0.72, 0.81),
      );
      // Applying a precise reference uses the same target canvas as Studio.
      // The library and exported file retain the original below.
      expect(actual.image, await NAIApiUtils.ensurePngFormatAsync(pixels));
      expect(
        NAIApiUtils.isKnownNormalizedPreciseReferencePng(actual.image),
        true,
      );
      final exported = await run({
        'kind': 'precise',
        'action': 'export',
        'id': entry['id'],
      }, vision: false);
      expect(
        await File('${root.path}/${exported['path']}').readAsBytes(),
        pixels,
      );
      expect(await precise.readImageBytes(entry['id'] as String), pixels);
    },
  );
  test(
    'library image IDs resolve native original pixels; missing encoding-only pixels remain unavailable',
    () async {
      final entry = await importVibe(count: 2);
      final tools = container.read(naiAgentStudioFactoryProvider)(
        root,
        root,
        true,
      );
      final picture = await tools.loadImage({
        'image_id': 'reference:vibe:${entry['id']}:1',
      }, NaiAgentCancellation());
      expect(picture.bytes, pixels);
      const encoded = VibeReference(
        displayName: 'no pixels',
        vibeEncoding: 'encoding-only',
        encodingModel: 'nai-diffusion-4-5-full',
        sourceType: VibeSourceType.naiv4vibe,
      );
      await File(
        '${root.path}/encoding.naiv4vibe',
      ).writeAsString(jsonEncode(NovelAiVibeCodec.buildSingleMap(encoded)));
      final noPixels =
          (await run({
                'action': 'import',
                'path': 'encoding.naiv4vibe',
              }))['saved']
              as Map;
      await expectLater(
        tools.loadImage({
          'image_id': noPixels['image_id'],
        }, NaiAgentCancellation()),
        error('image_missing'),
      );
      await apply(noPixels);
      expect(
        container
            .read(generationParamsNotifierProvider)
            .vibeReferencesV4
            .last
            .vibeEncoding,
        'encoding-only',
      );
    },
  );
  test(
    'queries preserve native UI filters/sort and importing refreshes an open library',
    () async {
      await importVibe(name: 'first');
      await importVibe(name: 'second');
      final notifier = container.read(vibeLibraryNotifierProvider.notifier);
      await notifier.reload();
      await notifier.setSearchQuery('first');
      final before = container.read(vibeLibraryNotifierProvider);
      final query = await run({'query': 'second', 'limit': 1});
      expect(query['entries'].single['name'], 'second');
      expect(container.read(vibeLibraryNotifierProvider), same(before));
      await importVibe(name: 'third');
      expect(container.read(vibeLibraryNotifierProvider).searchQuery, 'first');
      expect(container.read(vibeLibraryNotifierProvider).entries.length, 3);
    },
  );
  test(
    'saving current references appends native library entries and never replaces the draft',
    () async {
      final writer = container.read(generationParamsNotifierProvider.notifier);
      writer.addVibeReference(
        VibeReference(
          displayName: 'raw',
          vibeEncoding: '',
          rawImageData: pixels,
          thumbnail: pixels,
        ),
      );
      writer.addPreciseReference(
        pixels,
        type: PreciseRefType.style,
        strength: 0.44,
        fidelity: 0.55,
      );
      final before = container.read(generationParamsNotifierProvider);
      final entry = (await run({
        'action': 'save',
        'name': 'draft Vibe',
        'expected_draft_version': await version(),
      }))['saved'];
      final other = (await run({
        'kind': 'precise',
        'action': 'save',
        'index': 0,
        'name': 'draft precise',
        'expected_draft_version': await version(),
      }))['saved'];
      expect(await storage.getEntry(entry['id']), isNotNull);
      expect((await precise.getAllEntries()).single.id, other['id']);
      expect(container.read(generationParamsNotifierProvider), same(before));
      await expectLater(
        run({
          'action': 'save',
          'name': 'stale',
          'expected_draft_version': 'old',
        }),
        error('draft_conflict'),
      );
    },
  );
  test(
    'multi-model Vibe import and export preserve the complete original file rather than just selected encodings',
    () async {
      final map = NovelAiVibeCodec.buildSingleMap(
        VibeReference(
          displayName: 'models',
          vibeEncoding: 'first encoding',
          encodingModel: 'nai-diffusion-4-5-full',
          rawImageData: pixels,
          thumbnail: pixels,
          sourceType: VibeSourceType.naiv4vibe,
        ),
      );
      (map['encodings'] as Map)['v4full'] = {
        'second': {
          'encoding': 'second model encoding',
          'params': {'information_extracted': 0.7},
        },
      };
      final original = Uint8List.fromList(utf8.encode(jsonEncode(map)));
      await File('${root.path}/models.naiv4vibe').writeAsBytes(original);
      final entry =
          (await run({'action': 'import', 'path': 'models.naiv4vibe'}))['saved']
              as Map;
      final native = await storage.getEntry(entry['id']);
      expect(await File(native!.filePath!).readAsBytes(), original);
      final exported = await run({'action': 'export', 'id': entry['id']});
      expect(
        await File('${root.path}/${exported['path']}').readAsBytes(),
        original,
      );
      expect(
        await File('${root.path}/models.naiv4vibe').readAsBytes(),
        original,
      );
    },
  );
  test(
    'stale library versions, draft versions, invalid actions and filters do not change draft or library',
    () async {
      final entry = await importVibe();
      final before = container.read(generationParamsNotifierProvider);
      await expectLater(
        run({
          'action': 'apply',
          'id': entry['id'],
          'expected_entry_version': 'wrong',
          'expected_draft_version': await version(),
        }),
        error('entry_conflict'),
      );
      await expectLater(
        run({
          'action': 'apply',
          'id': entry['id'],
          'expected_entry_version': (await run({
            'action': 'read',
            'id': entry['id'],
          }))['entry_version'],
          'expected_draft_version': 'wrong',
        }),
        error('draft_conflict'),
      );
      for (final p in [
        {'action': 'query', 'limit': 101},
        {'action': 'query', 'favorites_only': 'yes'},
        {'action': 'import', 'path': 'input.png', 'image_id': 'selected'},
        {'kind': 'vibe', 'action': 'query', 'type': 'style'},
        {
          'action': 'save',
          'index': -1,
          'expected_draft_version': await version(),
        },
        {'action': 'unknown_action', 'id': entry['id']},
      ]) {
        await expectLater(
          run(Map<String, dynamic>.from(p)),
          error('invalid_reference'),
        );
      }
      expect(container.read(generationParamsNotifierProvider), same(before));
      expect((await storage.getDisplayEntries()).length, 1);
      await expectLater(
        run({'action': 'delete', 'id': entry['id']}),
        error('entry_conflict'),
      );
    },
  );
  test(
    'source changed during real backup rejects applying its old pixels or encoding',
    () async {
      final entry = await importVibe();
      final full = await run({'action': 'read', 'id': entry['id']});
      final tools = container.read(naiAgentStudioFactoryProvider)(
        root,
        root,
        true,
      );
      var alive = true;
      final provider = Provider(
        (ref) => NaiAgentReferenceLibraryBinding(
          ref,
          root,
          NaiAgentReferenceBinding(
            ref,
            root,
            tools.loadImage,
            () => false,
            () => alive,
            snapshots: _AfterBackup(root, () async {
              await storage.saveEntryParams(
                entry['id'] as String,
                strength: 0.91,
                infoExtracted: 0.63,
              );
            }),
          ),
          tools.loadImage,
          () => false,
          () => alive,
        ),
      );
      await expectLater(
        container.read(provider).execute({
          'action': 'apply',
          'id': entry['id'],
          'expected_entry_version': full['entry_version'],
          'expected_draft_version': await version(),
        }, NaiAgentCancellation()),
        error('entry_conflict'),
      );
      expect(
        container.read(generationParamsNotifierProvider).vibeReferencesV4,
        isEmpty,
      );
      expect((await storage.getEntry(entry['id'] as String))!.strength, 0.91);
      alive = false;
    },
  );
  test('Stop during real backup preserves draft and complete backup', () async {
    final entry = await importVibe();
    final full = await run({'action': 'read', 'id': entry['id']});
    final tools = container.read(naiAgentStudioFactoryProvider)(
          root,
          root,
          true,
        ),
        token = NaiAgentCancellation();
    final provider = Provider(
      (ref) => NaiAgentReferenceLibraryBinding(
        ref,
        root,
        NaiAgentReferenceBinding(
          ref,
          root,
          tools.loadImage,
          () => false,
          () => true,
          snapshots: _AfterBackup(root, () async {
            token.cancel();
          }),
        ),
        tools.loadImage,
        () => false,
        () => true,
      ),
    );
    await expectLater(
      container.read(provider).execute({
        'action': 'apply',
        'id': entry['id'],
        'expected_entry_version': full['entry_version'],
        'expected_draft_version': await version(),
      }, token),
      error('cancelled'),
    );
    expect(
      container.read(generationParamsNotifierProvider).vibeReferencesV4,
      isEmpty,
    );
    final backups = await Directory(
      '${root.path}/.W.O.F/snapshot-backups',
    ).list().where((e) => e.path.endsWith('.json')).toList();
    expect(
      jsonDecode(
        await File(backups.single.path).readAsString(),
      )['generation']['image_workflow'],
      isNotNull,
    );
  });
  test(
    'workspace file inputs and exports reject traversal or a redirected outputs directory',
    () async {
      await expectLater(
        run({'action': 'import', 'path': '../outside.naiv4vibe'}),
        throwsA(anything),
      );
      await expectLater(
        run({
          'action': 'import',
          'path': File('${root.path}/input.png').absolute.path,
        }),
        error('path_outside_workspace'),
      );
      final entry = await importVibe();
      final outside = await Directory.systemTemp.createTemp(
        'nai-agent-reference-outside-',
      );
      try {
        await Directory('${root.path}/.W.O.F').create(recursive: true);
        final link = Link('${root.path}/.W.O.F/outputs');
        try {
          await link.create(outside.path);
        } on FileSystemException {
          // Windows junctions do not require the symbolic-link privilege.
          expect(Platform.isWindows, true);
          final result = await Process.run('cmd.exe', [
            '/c',
            'mklink',
            '/J',
            link.path,
            outside.path,
          ]);
          expect(
            result.exitCode,
            0,
            reason: '${result.stdout}${result.stderr}',
          );
        }
        await expectLater(
          run({'action': 'export', 'id': entry['id']}),
          error('path_outside_workspace'),
        );
        expect(await outside.list().toList(), isEmpty);
      } finally {
        await outside.delete(recursive: true);
      }
    },
  );
  test(
    'official Pi uses the real reference library from import to original export',
    () async {
      final raw = utf8.encode(
        jsonEncode(
          NovelAiVibeCodec.buildSingleMap(
            VibeReference(
              displayName: 'Pi library reference',
              vibeEncoding: 'native-library-encoding',
              encodingModel: 'nai-diffusion-4-5-full',
              sourceType: VibeSourceType.naiv4vibe,
              rawImageData: pixels,
              thumbnail: pixels,
              strength: 0.38,
              infoExtracted: 0.64,
            ),
          ),
        ),
      );
      await File('${root.path}/pi-reference.naiv4vibe').writeAsBytes(raw);
      final requests = <Map<String, dynamic>>[];
      final events = <Map<String, dynamic>>[];
      String? id, entryVersion, imageId, exportedPath;
      final server = await bindFetchTestServer();
      final serving = server.listen((request) async {
        final body =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        requests.add(body);
        final turn = requests.length;
        Map? previous;
        if (turn > 1 && turn != 7) {
          final content = (body['messages'] as List).lastWhere(
            (m) => m['role'] == 'tool',
          )['content'];
          previous =
              jsonDecode(content is String ? content : content[0]['text'])
                  as Map;
        }
        if (turn == 2) {
          id = previous!['saved']['id'] as String;
        } else if (turn == 3) {
          expect(previous!['entries'].single['id'], id);
        } else if (turn == 4) {
          entryVersion = previous!['entry_version'] as String;
          imageId = previous['image_id'] as String;
        } else if (turn == 8) {
          exportedPath = previous!['path'] as String;
        }
        final delta = switch (turn) {
          1 => tool('import-ref', 'reference_library', {
            'action': 'import',
            'path': 'pi-reference.naiv4vibe',
            'name': 'Pi library reference',
          }),
          2 => tool('query-ref', 'reference_library', {
            'action': 'query',
            'query': 'Pi library',
          }),
          3 => tool('read-ref', 'reference_library', {
            'action': 'read',
            'id': id,
          }),
          4 => tool('draft-context', 'studio_context', {'scope': 'draft'}),
          5 => tool('apply-ref', 'reference_library', {
            'action': 'apply',
            'id': id,
            'expected_entry_version': entryVersion,
            'expected_draft_version': previous!['draft']['draft_version'],
          }),
          6 => tool('view-ref', 'image_read', {'image_id': imageId}),
          7 => tool('export-ref', 'reference_library', {
            'action': 'export',
            'id': id,
          }),
          8 => tool('read-export', 'reference_library', {
            'action': 'read',
            'path': exportedPath,
          }),
          _ => {'content': '参考库原文件已导出，原始编码和参数已保留。'},
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
            'finish_reason': turn < 9 ? 'tool_calls' : 'stop',
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
          allowImageInput: true,
        ),
        const ModelConfig(
          providerId: 'local',
          name: 'synthetic',
          displayName: 'Synthetic',
          supportsTools: true,
          supportsVision: true,
        ),
        apiKey: 'synthetic-private-key',
      );
      PiHostClient? client;
      StreamSubscription<Map<String, dynamic>>? subscription;
      try {
        client = await container.read(naiAgentSessionStarterProvider)(
          mcp: const {'builtinExposure': 'direct'},
          providerId: 'local',
          modelId: 'synthetic',
          workspaceId: 'real-reference-library',
          workspace: root,
          data: Directory('${root.path}/agent'),
          nodeExecutable:
              Platform.environment['NAI_AGENT_NODE'] ?? 'E:/node/node.exe',
          hostScript: File('tool/nai_agent/host.mjs').absolute.path,
          systemPrompt: '你是 NAI Agent。按需读取真实参考库。',
        );
        subscription = client.events.listen(events.add);
        await client
            .prompt('导入参考，查看并应用后导出。')
            .timeout(const Duration(seconds: 30));
        expect(requests, hasLength(9));
        final end = events
            .where((e) => e['event']?['type'] == 'tool_execution_end')
            .toList();
        expect(end, hasLength(8));
        expect(end.every((e) => e['event']['isError'] == false), true);
        final actual = container
            .read(generationParamsNotifierProvider)
            .vibeReferencesV4
            .single;
        expect(actual.vibeEncoding, 'native-library-encoding');
        expect((actual.strength, actual.infoExtracted), (0.38, 0.64));
        expect(actual.rawImageData, pixels);
        expect(
          (await storage.getEntry(id!))!.vibeEncoding,
          'native-library-encoding',
        );
        expect(await File('${root.path}/$exportedPath').readAsBytes(), raw);
        final imageMessages = (requests[6]['messages'] as List).where(
          (m) => m['role'] == 'user',
        );
        expect(
          imageMessages.any(
            (m) =>
                m['content'] is List &&
                (m['content'] as List).any((v) => v['type'] == 'image_url'),
          ),
          true,
        );
        final last = (requests.last['messages'] as List).lastWhere(
          (m) => m['role'] == 'tool',
        )['content'];
        final summary = last is String ? last : last[0]['text'];
        expect(summary, isNot(contains(base64Encode(pixels))));
        expect(summary, isNot(contains('native-library-encoding')));
        expect(
          jsonEncode(requests.last),
          isNot(contains('synthetic-private-key')),
        );
      } finally {
        await subscription?.cancel();
        await client?.close();
        await serving.cancel();
        await server.close(force: true);
      }
    },
  );
}
