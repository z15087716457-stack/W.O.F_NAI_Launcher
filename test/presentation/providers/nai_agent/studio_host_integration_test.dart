import '../../../helpers/fetch_test_server.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/core/nai_agent/tool_catalog.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_generation_approvals.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_snapshot.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_model_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_session_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_studio_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import '../krita/agent_bridge_draft_test.dart'
    show MemoryDraftSettings, MemoryCharacters, OfflineAuth;
import 'generation_binding_test.dart'
    show
        GenerationTestAuth,
        ControlledAgentGeneration,
        GenerationTestVibes,
        waitForAgentStart;

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

class SyntheticGeneration extends ImageGenerationNotifier {
  static late Uint8List pixels;
  @override
  ImageGenerationState build() => ImageGenerationState(
    currentImages: [
      GeneratedImage(id: 'test-image', bytes: pixels, width: 3, height: 2),
    ],
  );
}

void main() {
  late Directory root;
  late ProviderContainer container;
  late MemoryCharacters characters;
  late NaiAgentModelConnection connection;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('nai-agent-production-');
    Hive.init(root.path);
    await Hive.openBox(StorageKeys.settingsBox);
    final blocks = PromptBlockStorage(hivePath: root.path);
    await blocks.init();
    characters = MemoryCharacters();
    SyntheticGeneration.pixels = Uint8List.fromList(
      img.encodePng(img.Image(width: 3, height: 2)),
    );
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(characters),
        promptBlockRepositoryProvider.overrideWithValue(
          PromptBlockRepository(blocks),
        ),
        promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
        imageGenerationNotifierProvider.overrideWith(SyntheticGeneration.new),
        authNotifierProvider.overrideWith(OfflineAuth.new),
        vibeLibraryStorageServiceProvider.overrideWithValue(
          GenerationTestVibes(),
        ),
        naiAgentModelResolverProvider.overrideWithValue(
          (_, __) async => connection,
        ),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    container
        .read(generationPreviewSelectionProvider.notifier)
        .select('test-image');
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await root.delete(recursive: true);
  });

  for (final supportsVision in [true, false]) {
    test(
      'image_read uses model vision=$supportsVision despite provider flag=false in production session',
      () async {
        final requests = <Map<String, dynamic>>[];
        final server = await bindFetchTestServer();
        final serving = server.listen((request) async {
          requests.add(
            Map<String, dynamic>.from(
              jsonDecode(await utf8.decoder.bind(request).join()) as Map,
            ),
          );
          final delta = requests.length == 1
              ? tool('look', 'image_read', {'image_id': 'selected'})
              : <String, dynamic>{'role': 'assistant', 'content': 'done'};
          request.response.headers.set('content-type', 'text/event-stream');
          request.response.write(
            'data: ${jsonEncode({
              'id': 'vision-test',
              'object': 'chat.completion.chunk',
              'model': 'test',
              'choices': [
                {'index': 0, 'delta': delta, 'finish_reason': requests.length == 1 ? 'tool_calls' : 'stop'},
              ],
            })}\n\ndata: [DONE]\n\n',
          );
          await request.response.close();
        });
        connection = mapNaiAgentModel(
          ProviderConfig(
            id: 'vision-local',
            name: 'Synthetic Vision Provider',
            baseUrl: 'http://127.0.0.1:${server.port}',
            allowImageInput: false,
          ),
          ModelConfig(
            providerId: 'vision-local',
            name: 'test',
            displayName: 'Test model',
            supportsTools: true,
            supportsVision: supportsVision,
          ),
        );
        PiHostClient? client;
        try {
          client = await container.read(naiAgentSessionStarterProvider)(
            providerId: 'vision-local',
            modelId: 'test',
            workspaceId: 'vision-test',
            workspace: root,
            data: Directory('${root.path}/agent'),
            nodeExecutable:
                Platform.environment['NAI_AGENT_NODE'] ?? 'E:/node/node.exe',
            hostScript: File('tool/nai_agent/host.mjs').absolute.path,
            systemPrompt: 'Synthetic image-read test',
            mcp: const {'builtinExposure': 'direct'},
          );
          expect(client.visionAccess.providerName, 'Synthetic Vision Provider');
          final state = await client.prompt('inspect selected image');
          expect(state['streaming'], isFalse);
          expect(requests, hasLength(2));
          final error = (requests.last['messages'] as List).lastWhere(
            (m) => m['role'] == 'tool',
          )['content'];
          final text = error is String ? error : jsonEncode(error);
          if (supportsVision) {
            expect(text, isNot(contains('vision_unavailable')));
            expect(
              jsonEncode(requests.last),
              contains('data:image/png;base64,'),
            );
          } else {
            expect(text, contains('vision_unavailable'));
            expect(
              text,
              contains(
                currentL10n.naiAgent_visionModelUnsupported(
                  'Synthetic Vision Provider',
                ),
              ),
            );
            expect(
              jsonEncode(requests.last),
              isNot(contains('data:image/png;base64,')),
            );
          }
          expect(text, isNot(contains('Image input is not enabled')));
        } finally {
          await client?.close();
          await serving.cancel();
          await server.close(force: true);
        }
      },
    );
  }

  test(
    'official Pi invokes public settings, block organization and exploration bindings',
    () async {
      final requests = <Map<String, dynamic>>[];
      final server = await bindFetchTestServer();
      final serving = server.listen((request) async {
        final body =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        requests.add(body);
        final turn = requests.length;
        Map? previous;
        if (turn > 1) {
          final raw = (body['messages'] as List).lastWhere(
            (m) => m['role'] == 'tool',
          )['content'];
          previous = jsonDecode(raw is String ? raw : raw[0]['text']) as Map;
        }
        final delta = switch (turn) {
          1 => tool('preferences', 'settings_read', {}),
          2 => tool('update-preferences', 'settings_update', {
            'expected_version': previous!['version'],
            'changes': {StorageKeys.fontScale: 1.2},
          }),
          3 => tool('library-tree', 'block_query', {'kind': 'tree'}),
          4 => tool('create-folder', 'block_manage', {
            'action': 'folder_create',
            'expected_library_version': previous!['library_version'],
            'changes': {'name': 'SDK folder'},
          }),
          5 => tool('explorations', 'explore_manage', {'action': 'list'}),
          _ => {'content': '设置、积木目录与探索读取已完成。'},
        };
        request.response.headers.set(
          'content-type',
          'text/event-stream; charset=utf-8',
        );
        for (final choice in [
          {'index': 0, 'delta': delta, 'finish_reason': null},
          {
            'index': 0,
            'delta': {},
            'finish_reason': turn < 6 ? 'tool_calls' : 'stop',
          },
        ]) {
          request.response.write(
            'data: ${jsonEncode({
              'id': 'synthetic',
              'object': 'chat.completion.chunk',
              'model': 'synthetic',
              'choices': [choice],
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
      try {
        client = await container.read(naiAgentSessionStarterProvider)(
          mcp: const {'builtinExposure': 'direct'},
          providerId: 'local',
          modelId: 'synthetic',
          workspaceId: 'synthetic-remaining',
          workspace: root,
          data: Directory('${root.path}/agent'),
          nodeExecutable:
              Platform.environment['NAI_AGENT_NODE'] ?? 'E:/node/node.exe',
          hostScript: File('tool/nai_agent/host.mjs').absolute.path,
          systemPrompt: '你是 NAI Agent。',
        );
        final before = container.read(generationParamsNotifierProvider);
        await client
            .prompt('测试公共设置与积木目录，读取探索列表。')
            .timeout(const Duration(seconds: 30));
        expect(requests, hasLength(6));
        expect(
          container
              .read(localStorageServiceProvider)
              .getSetting<double>(StorageKeys.fontScale),
          1.2,
        );
        expect(
          (await container.read(promptBlockRepositoryProvider).load())
              .folders
              .single
              .name,
          'SDK folder',
        );
        expect(container.read(generationParamsNotifierProvider), before);
        expect(
          container.read(generationPreviewSelectionProvider),
          'test-image',
        );
        final schemas = (requests.first['tools'] as List)
            .map((t) => t['function']['name'])
            .toSet();
        expect(
          schemas,
          containsAll([
            'mcp__nai_studio__settings_read',
            'mcp__nai_studio__settings_update',
            'mcp__nai_studio__explore_manage',
          ]),
        );
        final raw = (requests.last['messages'] as List).lastWhere(
          (m) => m['role'] == 'tool',
        )['content'];
        expect(
          jsonDecode(raw is String ? raw : raw[0]['text'])['runs'],
          isEmpty,
        );
      } finally {
        await client?.close();
        await serving.cancel();
        await server.close(force: true);
      }
    },
  );

  test(
    'production Studio binding preserves role identity, pill document and post-write versions',
    () async {
      final tools = container.read(naiAgentStudioFactoryProvider)(
        root,
        root,
        true,
      );
      final lane = container.read(
        pillWorkspaceProvider(PillScopes.charPos('kept')).notifier,
      );
      lane.insertTranslationAt(offset: 0, source: 'raw character', zh: '原文');
      final document = container
          .read(pillWorkspaceProvider(PillScopes.charPos('kept')))
          .document;
      final before = await tools.execute('studio_context', {
        'scope': 'draft',
      }, NaiAgentCancellation());
      final draft = before['details']['draft'] as Map;
      final patch = {
        ...(draft['fields']['characters'] as List).single as Map,
        'uc': 'agent negative',
      };
      final result = await tools.execute('prompt_update', {
        'changes': {
          'characters': [patch],
        },
        'expected': draft['field_versions'],
      }, NaiAgentCancellation());
      expect(characters.value.characters.single.gender.name, 'female');
      expect(
        characters.value.characters.single.thumbnailPath,
        'local-thumbnail',
      );
      expect(characters.value.characters.single.enabled, isFalse);
      expect(
        container.read(generationParamsNotifierProvider).characters,
        isEmpty,
      );
      expect(
        container
            .read(pillWorkspaceProvider(PillScopes.charPos('kept')))
            .document,
        document,
      );
      expect(
        container
            .read(pillWorkspaceProvider(PillScopes.charNeg('kept')))
            .projection,
        'agent negative',
      );
      final backup = jsonDecode(
        await File(result['details']['backup_path']).readAsString(),
      );
      expect(backup['fields']['characters'][0]['uc'], 'raw uc');
      expect(
        result['details']['draft']['fields']['characters'][0]['uc'],
        'agent negative',
      );
      final actual = await tools.execute('studio_context', {
        'scope': 'draft',
      }, NaiAgentCancellation());
      expect(result['details']['draft'], actual['details']['draft']);
      expect(actual['details']['selected_image']['image_id'], 'test-image');
      expect(
        actual['details']['page'],
        isNull,
      ); // Unmounted router is never fabricated.
    },
  );

  test(
    'real Dart → Node/Pi → streamed HTTP → draft, native references and actual image lookup/read',
    () async {
      final requests = <Map<String, dynamic>>[];
      final server = await bindFetchTestServer();
      final serving = server.listen((request) async {
        final body =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        requests.add(body);
        final turn = requests.length;
        Map<String, dynamic> delta;
        if (turn == 1) {
          delta = tool('context', 'studio_context', {'scope': 'draft'});
        } else if (turn == 2) {
          final raw = (body['messages'] as List).lastWhere(
            (m) => m['role'] == 'tool',
          )['content'];
          final state = jsonDecode(raw is String ? raw : raw[0]['text']);
          delta = tool('update', 'prompt_update', {
            'changes': {'prompt': 'synthetic agent update'},
            'expected': state['draft']['field_versions'],
          });
        } else if (turn == 3) {
          final raw = (body['messages'] as List).lastWhere(
            (m) => m['role'] == 'tool',
          )['content'];
          final result = jsonDecode(raw is String ? raw : raw[0]['text']);
          delta = tool('vibe-add', 'reference_manage', {
            'action': 'add_vibe',
            'image_id': 'selected',
            'expected_draft_version': result['draft']['draft_version'],
          });
        } else if (turn == 4) {
          delta = tool('references', 'reference_manage', {'action': 'list'});
        } else if (turn == 5) {
          final raw = (body['messages'] as List).lastWhere(
            (m) => m['role'] == 'tool',
          )['content'];
          final result = jsonDecode(raw is String ? raw : raw[0]['text']);
          delta = tool('vibe-image', 'image_read', {
            'image_id': result['vibes'].single['image']['image_id'],
          });
        } else if (turn == 6) {
          delta = tool('lookup', 'gallery_query', {'image_id': 'selected'});
        } else if (turn == 7) {
          final raw = (body['messages'] as List).lastWhere(
            (m) => m['role'] == 'tool',
          )['content'];
          final result = jsonDecode(raw is String ? raw : raw[0]['text']);
          delta = tool('image', 'image_read', {
            'image_id': result['images'].single['image_id'],
          });
        } else {
          delta = {'content': '工具闭环完成。'};
        }
        request.response.headers.set(
          'content-type',
          'text/event-stream; charset=utf-8',
        );
        request.response.write(
          'data: ${jsonEncode({
            'id': 'local',
            'object': 'chat.completion.chunk',
            'model': 'synthetic',
            'choices': [
              {'index': 0, 'delta': delta, 'finish_reason': null},
            ],
          })}\n\n',
        );
        request.response.write(
          'data: ${jsonEncode({
            'id': 'local',
            'object': 'chat.completion.chunk',
            'model': 'synthetic',
            'choices': [
              {'index': 0, 'delta': {}, 'finish_reason': turn < 8 ? 'tool_calls' : 'stop'},
            ],
          })}\n\ndata: [DONE]\n\n',
        );
        await request.response.close();
      });
      const model = ModelConfig(
        providerId: 'local',
        name: 'synthetic',
        displayName: 'Synthetic',
        supportsTools: true,
        supportsVision: true,
      );
      connection = mapNaiAgentModel(
        ProviderConfig(
          id: 'local',
          name: 'Synthetic',
          baseUrl: 'http://127.0.0.1:${server.port}',
          allowImageInput: true,
        ),
        model,
        apiKey: 'synthetic-private-key',
      );
      PiHostClient? client;
      StreamSubscription<Map<String, dynamic>>? subscription;
      final events = <Map<String, dynamic>>[];
      try {
        client = await container.read(naiAgentSessionStarterProvider)(
          mcp: const {'builtinExposure': 'direct'},
          providerId: 'local',
          modelId: 'synthetic',
          nodeExecutable:
              Platform.environment['NAI_AGENT_NODE'] ?? 'E:/node/node.exe',
          hostScript: File('tool/nai_agent/host.mjs').absolute.path,
          workspaceId: 'synthetic-workspace',
          workspace: root,
          data: Directory('${root.path}/agent'),
          systemPrompt: '你是 NAI Agent。按需调用工具。',
        );
        subscription = client.events.listen(events.add);
        await client.prompt('执行合成测试。').timeout(const Duration(seconds: 30));
        expect(requests.length, 8);
        expect(
          container.read(generationParamsNotifierProvider).prompt,
          'synthetic agent update',
        );
        expect(
          events.where((event) => event['type'] == 'tool_request').length,
          7,
        );
        expect(
          events.any((event) => event['event']?['type'] == 'message_update'),
          isTrue,
        );
        final end = events.where(
          (e) => e['event']?['type'] == 'tool_execution_end',
        );
        expect(end.length, 7);
        expect(end.every((e) => e['event']['isError'] == false), isTrue);
        expect(
          container
              .read(generationParamsNotifierProvider)
              .vibeReferencesV4
              .single
              .vibeEncoding,
          '',
        );
        expect(
          container
              .read(generationParamsNotifierProvider)
              .vibeReferencesV4
              .single
              .rawImageData,
          SyntheticGeneration.pixels,
        );
        expect(
          jsonEncode(requests.last),
          contains(base64Encode(SyntheticGeneration.pixels)),
        );
        final sessions = Directory(
          '${root.path}/agent/sessions',
        ).listSync().whereType<File>();
        expect(sessions.length, 1);
        expect(
          await sessions.single.readAsString(),
          isNot(contains('synthetic-private-key')),
        );
      } finally {
        await client?.close();
        await subscription?.cancel();
        await serving.cancel();
        await server.close(force: true);
      }
    },
  );

  test(
    'official Pi advertises actual domain schemas and dispatches workspace snapshots through the production owner',
    () async {
      final requests = <Map<String, dynamic>>[];
      String? savedId;
      String? restoreVersion;
      final source = Uint8List.fromList(
        img.encodePng(img.Image(width: 128, height: 128)),
      );
      final workflow = container.read(imageWorkflowControllerProvider.notifier);
      workflow.replaceSourceImage(source, autoAdapt: false);
      workflow.applyInpaintEditorResult(
        maskImage: source,
        sourceIsOutpaint: false,
      );
      final server = await bindFetchTestServer();
      final serving = server.listen((request) async {
        final body =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        requests.add(body);
        final turn = requests.length;
        if (turn == 2) {
          final raw = (body['messages'] as List).lastWhere(
            (m) => m['role'] == 'tool',
          )['content'];
          final result = jsonDecode(raw is String ? raw : raw[0]['text']);
          savedId = result['saved']['id'] as String;
        }
        if (turn == 3) workflow.clearSourceImage();
        if (turn == 4) {
          final raw = (body['messages'] as List).lastWhere(
            (m) => m['role'] == 'tool',
          )['content'];
          final result = jsonDecode(raw is String ? raw : raw[0]['text']);
          restoreVersion = result['draft']['draft_version'] as String;
        }
        final delta = switch (turn) {
          1 => tool('save', 'snapshot', {
            'action': 'save',
            'name': 'SDK domain snapshot',
          }),
          2 => tool('read', 'snapshot', {'action': 'read', 'id': savedId}),
          3 => tool('context', 'studio_context', {'scope': 'draft'}),
          4 => tool('load', 'snapshot', {
            'action': 'load',
            'id': savedId,
            'expected_version': restoreVersion,
          }),
          5 => tool('verify', 'snapshot', {'action': 'read', 'id': savedId}),
          _ => {'content': '快照已保存、恢复原生重绘并读取。'},
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
            'finish_reason': turn < 6 ? 'tool_calls' : 'stop',
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
      try {
        client = await container.read(naiAgentSessionStarterProvider)(
          mcp: const {'builtinExposure': 'direct'},
          providerId: 'local',
          modelId: 'synthetic',
          workspaceId: 'synthetic-domain',
          workspace: root,
          data: Directory('${root.path}/agent'),
          nodeExecutable:
              Platform.environment['NAI_AGENT_NODE'] ?? 'E:/node/node.exe',
          hostScript: File('tool/nai_agent/host.mjs').absolute.path,
          systemPrompt: '你是 NAI Agent。按需使用工具。',
        );
        final before = container.read(generationParamsNotifierProvider);
        final beforeWorkflow = encodeImageWorkflowConfiguration(
          container.read(imageWorkflowControllerProvider),
          before,
        );
        final completed = await client
            .prompt('保存并读取测试配置。')
            .timeout(const Duration(seconds: 30));
        expect(
          requests,
          hasLength(6),
          reason: 'Completed Pi state: ${piStateSummary(completed)}',
        );
        final names = (requests.first['tools'] as List)
            .map((t) => t['function']['name'])
            .cast<String>()
            .toSet();
        expect(names, {
          'codemode',
          ...naiAgentToolNames
              .where((name) => name != 'ask_user')
              .map(
                (name) =>
                    [
                      'read',
                      'write',
                      'edit',
                      'bash',
                      'studio_context',
                    ].contains(name)
                    ? name
                    : 'mcp__nai_studio__$name',
              ),
        });
        expect(container.read(generationParamsNotifierProvider), before);
        expect(
          encodeImageWorkflowConfiguration(
            container.read(imageWorkflowControllerProvider),
            container.read(generationParamsNotifierProvider),
          ),
          beforeWorkflow,
        );
        expect(
          container.read(imageWorkflowControllerProvider).mode,
          ImageWorkflowMode.inpaint,
        );
        expect(
          await File('${root.path}/snapshots/$savedId.json').exists(),
          isTrue,
        );
        final message = (requests.last['messages'] as List).lastWhere(
          (m) => m['role'] == 'tool',
        );
        final raw = message['content'];
        final result = jsonDecode(raw is String ? raw : raw[0]['text']);
        final reply = jsonEncode(result);
        expect(reply, contains('SDK domain snapshot'));
        expect(result['image_workflow']['sourceImageWidth'], 128);
        expect(result['workflow_settings_saved'], isTrue);
        expect(result['has_source_image'], isTrue);
        expect(reply, isNot(contains(base64Encode(source))));
        expect(reply, isNot(contains('synthetic-private-key')));
      } finally {
        await client?.close();
        await serving.cancel();
        await server.close(force: true);
      }
    },
  );

  test(
    'official Pi creates, reads and inserts real library blocks and edits the returned instance',
    () async {
      final requests = <Map<String, dynamic>>[];
      String? id, blockVersion;
      final server = await bindFetchTestServer();
      final serving = server.listen((request) async {
        final body =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        requests.add(body);
        final turn = requests.length;
        Map? previous;
        if (turn > 1) {
          final raw = (body['messages'] as List).lastWhere(
            (m) => m['role'] == 'tool',
          )['content'];
          previous = jsonDecode(raw is String ? raw : raw[0]['text']) as Map;
        }
        if (turn == 2) id = previous!['id'] as String;
        if (turn == 3) blockVersion = previous!['block']['version'] as String;
        final delta = switch (turn) {
          1 => tool('create-block', 'block_manage', {
            'action': 'create',
            'changes': {
              'title': 'Synthetic SDK block',
              'content': 'blue eyes, white hair',
            },
          }),
          2 => tool('read-block', 'block_query', {'id': id}),
          3 => tool('context', 'studio_context', {'scope': 'draft'}),
          4 => tool('insert-block', 'block_manage', {
            'action': 'insert',
            'id': id,
            'expected_version': blockVersion,
            'expected_draft_version': previous!['draft']['draft_version'],
          }),
          5 => tool('disable-instance', 'block_manage', {
            'action': 'instance_update',
            'marker': previous!['lanes']['main']['inserted_markers'].single,
            'expected_draft_version': previous['draft_version'],
            'instance': {'enabled': false},
          }),
          6 => tool('read-library-again', 'block_query', {'id': id}),
          _ => {'content': '积木已插入并停用，库中原文保留。'},
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
            'finish_reason': turn < 7 ? 'tool_calls' : 'stop',
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
      try {
        client = await container.read(naiAgentSessionStarterProvider)(
          mcp: const {'builtinExposure': 'direct'},
          providerId: 'local',
          modelId: 'synthetic',
          workspaceId: 'synthetic-block-tools',
          workspace: root,
          data: Directory('${root.path}/agent'),
          nodeExecutable:
              Platform.environment['NAI_AGENT_NODE'] ?? 'E:/node/node.exe',
          hostScript: File('tool/nai_agent/host.mjs').absolute.path,
          systemPrompt: '你是 NAI Agent。按需使用工具。',
        );
        await client
            .prompt('测试积木创建、插入与实例设置。')
            .timeout(const Duration(seconds: 30));
        expect(requests.length, 7);
        final real = await container
            .read(promptBlockRepositoryProvider)
            .getBlock(id!);
        expect(real!.content, 'blue eyes, white hair');
        final doc = container
            .read(pillWorkspaceProvider(PillScopes.main))
            .document;
        expect(doc.instances.values.single.enabled, false);
        expect(container.read(generationParamsNotifierProvider).prompt, '');
        final names = (requests.first['tools'] as List)
            .map((t) => t['function']['name'])
            .toSet();
        expect(
          names,
          containsAll([
            'mcp__nai_studio__block_query',
            'mcp__nai_studio__block_manage',
          ]),
        );
        final backups = Directory(
          '${root.path}/.agent/snapshot-backups',
        ).listSync().whereType<File>();
        expect(backups.length, 3);
        expect(jsonEncode(requests.last), contains('Synthetic SDK block'));
        expect(
          jsonEncode(requests.last),
          isNot(contains('synthetic-private-key')),
        );
      } finally {
        await client?.close();
        await serving.cancel();
        await server.close(force: true);
      }
    },
  );
  test(
    'official Pi generation tools wait for visible approval then read actual native image bytes',
    () async {
      final blockRepository = container.read(promptBlockRepositoryProvider);
      container.dispose();
      container = ProviderContainer(
        overrides: [
          localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
          characterPromptRepositoryProvider.overrideWithValue(characters),
          promptBlockRepositoryProvider.overrideWithValue(blockRepository),
          promptBlockLibraryNotifierProvider.overrideWith(_Library.new),
          imageGenerationNotifierProvider.overrideWith(
            ControlledAgentGeneration.new,
          ),
          authNotifierProvider.overrideWith(GenerationTestAuth.new),
          naiAgentModelResolverProvider.overrideWithValue(
            (_, __) async => connection,
          ),
        ],
      );
      await container.read(promptBlockLibraryNotifierProvider.future);
      final requests = <Map<String, dynamic>>[];
      String? quoteId;
      final server = await bindFetchTestServer();
      final serving = server.listen((request) async {
        final body =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        requests.add(body);
        final turn = requests.length;
        if (turn == 2) {
          final raw = (body['messages'] as List).lastWhere(
            (m) => m['role'] == 'tool',
          )['content'];
          quoteId =
              jsonDecode(
                    raw is String ? raw : raw[0]['text'],
                  )['quote']['quote_id']
                  as String;
        }
        final delta = switch (turn) {
          1 => tool('quote', 'generation_prepare', {}),
          2 => tool('run', 'generation_run', {'quote_id': quoteId}),
          3 => tool('look', 'image_read', {'image_id': 'native-image'}),
          _ => {'content': '已按按钮授权生成并读取实际图片。'},
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
            'finish_reason': turn < 4 ? 'tool_calls' : 'stop',
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
      try {
        client = await container.read(naiAgentSessionStarterProvider)(
          mcp: const {'builtinExposure': 'direct'},
          providerId: 'local',
          modelId: 'synthetic',
          workspaceId: 'synthetic-domain',
          chatId: 'generation-chat',
          workspace: root,
          data: Directory('${root.path}/agent'),
          nodeExecutable:
              Platform.environment['NAI_AGENT_NODE'] ?? 'E:/node/node.exe',
          hostScript: File('tool/nai_agent/host.mjs').absolute.path,
          systemPrompt: '你是 NAI Agent。按需使用工具。',
        );
        final before = container.read(generationParamsNotifierProvider);
        final pending = client
            .prompt('准备报价，等待按钮授权，然后读取结果。')
            .timeout(const Duration(seconds: 30));
        final broker = container.read(naiAgentGenerationApprovalsProvider);
        for (
          var i = 0;
          i < 400 && broker.forChat('generation-chat').isEmpty;
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        expect(
          broker.forChat('generation-chat'),
          hasLength(1),
          reason: 'Pi approval state: ${piStateSummary(await client.state())}',
        );
        final approval = broker.forChat('generation-chat').single;
        expect(approval.owner.workspaceId, 'synthetic-domain');
        expect(requests, hasLength(2));
        final native =
            container.read(imageGenerationNotifierProvider.notifier)
                as ControlledAgentGeneration;
        expect(native.requests, isEmpty);
        broker.decide(approval.id, generate: true);
        await waitForAgentStart(native);
        native.finish();
        await pending;
        expect(requests, hasLength(4));
        final data = jsonEncode(requests.last);
        expect(data, contains(base64Encode(ControlledAgentGeneration.pixels)));
        expect(data, isNot(contains('vision_unavailable')));
        expect(data, contains('native-image'));
        expect(data, isNot(contains('synthetic-private-key')));
        expect(container.read(generationParamsNotifierProvider), before);
        expect(broker.forChat('generation-chat'), isEmpty);
      } finally {
        await client?.close();
        await serving.cancel();
        await server.close(force: true);
      }
    },
  );
}

String piStateSummary(Map<String, dynamic> state) => jsonEncode({
  'streaming': state['streaming'],
  'assistant': (state['messages'] as List?)
      ?.where((message) => message['role'] == 'assistant')
      .map(
        (message) => {
          'stopReason': message['stopReason'],
          'errorMessage': message['errorMessage'],
        },
      )
      .toList(),
});

Map<String, dynamic> tool(
  String id,
  String name,
  Map<String, dynamic> arguments,
) => {
  'role': 'assistant',
  'tool_calls': [
    {
      'index': 0,
      'id': id,
      'type': 'function',
      'function': {
        'name':
            [
              'read',
              'write',
              'edit',
              'bash',
              'studio_context',
              'ask_user',
            ].contains(name)
            ? name
            : 'mcp__nai_studio__$name',
        'arguments': jsonEncode(arguments),
      },
    },
  ],
};
