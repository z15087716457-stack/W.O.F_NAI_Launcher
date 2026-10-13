import '../../../helpers/fetch_test_server.dart';
import 'dart:async';
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_model_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_session_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/core/nai_agent/studio_tools.dart';
import 'package:nai_launcher/core/utils/image_save_utils.dart';
import 'package:nai_launcher/core/utils/max_enhance_utils.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_snapshot.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/generation_tools.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/prompt_block_storage.dart';
import 'package:nai_launcher/data/datasources/remote/nai_image_generation_api_service.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/image/image_stream_chunk.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/image_save_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/notification_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_generation_approvals.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_studio_provider.dart';
import '../krita/agent_bridge_draft_test.dart'
    show MemoryDraftSettings, MemoryCharacters;
import 'generation_binding_test.dart'
    show GenerationTestAuth, GenerationTestLibrary, GenerationTestVibes;
import '../../../helpers/prompt_normalization_fixture.dart';

class _Api extends Mock implements NAIImageGenerationApiService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    registerFallbackValue(const ImageParams());
  });
  late Directory root;
  late ProviderContainer container;
  late _Api api;
  late NaiAgentStudioTools service;
  late NaiAgentModelConnection connection;
  late List<ImageParams> requests;
  late Uint8List bytes;
  void Function()? onRequest;
  setUp(() async {
    root = await Directory.systemTemp.createTemp(
      'nai-agent-source-generation-',
    );
    Hive.init(root.path);
    for (final box in [
      StorageKeys.settingsBox,
      StorageKeys.historyBox,
      StorageKeys.statisticsCacheBox,
    ]) {
      await Hive.openBox(box);
    }
    final storage = PromptBlockStorage(hivePath: root.path);
    await storage.init();
    api = _Api();
    requests = [];
    onRequest = null;
    bytes = Uint8List.fromList(img.encodePng(img.Image(width: 32, height: 48)));
    when(() => api.generateImageStream(any())).thenAnswer((invocation) {
      final params = invocation.positionalArguments.single as ImageParams;
      requests.add(params);
      onRequest?.call();
      return Stream.fromIterable([
        for (var i = 0; i < params.nSamples; i++)
          ImageStreamChunk.complete(bytes, sampleIndex: i),
      ]);
    });
    when(() => api.cancelGeneration()).thenReturn(null);
    container = ProviderContainer(
      overrides: [
        naiAgentModelResolverProvider.overrideWithValue(
          (_, __) async => connection,
        ),
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockRepositoryProvider.overrideWithValue(
          PromptBlockRepository(storage),
        ),
        promptBlockLibraryNotifierProvider.overrideWith(
          GenerationTestLibrary.new,
        ),
        vibeLibraryStorageServiceProvider.overrideWithValue(
          GenerationTestVibes(),
        ),
        authNotifierProvider.overrideWith(GenerationTestAuth.new),
        naiImageGenerationApiServiceProvider.overrideWithValue(api),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    await container
        .read(notificationSettingsNotifierProvider.notifier)
        .setSoundEnabled(false);
    await container
        .read(imageSaveSettingsNotifierProvider.notifier)
        .setAutoSave(false);
  });
  tearDown(() async {
    container.dispose();
    await Future<void>.delayed(Duration.zero);
    await Hive.close();
    await root.delete(recursive: true);
  });
  Future<Map<String, dynamic>> quote(
    Map<String, dynamic> options, {
    int width = 256,
    int height = 384,
    bool metadata = false,
  }) async {
    var source = Uint8List.fromList(
      img.encodePng(img.Image(width: width, height: height)),
    );
    if (metadata) {
      source = await ImageSaveUtils.buildPrebuiltMetadataBytes(
        imageBytes: source,
        metadata: {
          'Source': 'DiffusionModelMetaName.NAIv5 E32849CC',
          'prompt': 'source portrait',
          'uc': 'source uc',
          'steps': 23,
          'scale': 7,
          'sampler': 'k_euler_ancestral',
          'model': 'nai-diffusion-5-full',
          'seed': 42,
          'width': width,
          'height': height,
          'noise_schedule': 'karras',
        },
      );
    }
    await File('${root.path}/input.png').writeAsBytes(source);
    final result = await service.execute('image_generate', {
      'action': 'prepare',
      'path': 'input.png',
      ...options,
    }, NaiAgentCancellation());
    return Map<String, dynamic>.from(result['details']['quote']);
  }

  // Keep one production factory binding per chat; quotes are not transferable.
  setUp(() {
    service = container.read(naiAgentStudioFactoryProvider)(
      root,
      root,
      true,
      owner: const NaiAgentConversationOwner('workspace', 'chat'),
    );
  });

  Future<Map<String, dynamic>> run(Map<String, dynamic> q) async {
    final pending = service.execute('image_generate', {
      'action': 'run',
      'quote_id': q['quote_id'],
    }, NaiAgentCancellation());
    expect(requests, isEmpty);
    final broker = container.read(naiAgentGenerationApprovalsProvider);
    final card = broker.forChat('chat').single;
    expect(card.quote.input.raw.sourceImage, isNotEmpty);
    broker.decide(card.id, generate: true);
    return Map<String, dynamic>.from(
      (await pending.timeout(const Duration(seconds: 20)))['details'],
    );
  }

  test(
    'official variants freeze source metadata, use the native three-image seed relation and export originals',
    () async {
      final draft = await configurePromptComposition(container);
      final beforeWorkflow = encodeImageWorkflowConfiguration(
        container.read(imageWorkflowControllerProvider),
        draft,
      );
      final q = await quote({'operation': 'variations'}, metadata: true);
      expect(q['samples'], 3);
      expect(q['prompt'], 'source portrait');
      expect(q['model'], 'nai-diffusion-5-full');
      expect(q['steps'], 23);
      expect(q['strength'], .8);
      expect(q['noise'], .1);
      expect(requests, isEmpty);
      // Changing or deleting the original file cannot replace frozen pixels.
      final frozen = await File('${root.path}/input.png').readAsBytes();
      await File('${root.path}/input.png').delete();
      final result = await run(q);
      expect(result['status'], 'completed');
      expect(requests, hasLength(1));
      final request = requests.single;
      expect(request.nSamples, 3);
      expect(request.seed, request.extraNoiseSeed! + 1);
      expect(request.prompt, 'source portrait');
      expect(request.sourceImage, frozen);
      expect(container.read(generationParamsNotifierProvider), draft);
      expect(
        encodeImageWorkflowConfiguration(
          container.read(imageWorkflowControllerProvider),
          draft,
        ),
        beforeWorkflow,
      );
      final state = container.read(imageGenerationNotifierProvider);
      expect(
        state.currentImages.where((i) => i.canSave && !i.isVariationOriginal),
        hasLength(3),
      );
      expect(
        state.currentImages.where((i) => i.isVariationOriginal),
        hasLength(1),
      );
      expect(result['images'], hasLength(3));
      expect(result['artifacts'], hasLength(3));
      for (final artifact in result['artifacts']) {
        final path = artifact['path'] as String;
        expect(await File('${root.path}/$path').readAsBytes(), bytes);
        expect(
          await File(
            '${root.path}/${path.replaceAll('image.png', 'source.png')}',
          ).readAsBytes(),
          frozen,
        );
      }
      await expectLater(
        service.execute('image_generate', {
          'action': 'run',
          'quote_id': q['quote_id'],
        }, NaiAgentCancellation()),
        throwsA(
          isA<NaiAgentToolError>().having(
            (e) => e.code,
            'code',
            'quote_missing',
          ),
        ),
      );
    },
  );

  test(
    'enhance freezes composed prompt/characters and magnitude while newer draft edits remain untouched',
    () async {
      await configurePromptComposition(container);
      final q = await quote({
        'operation': 'enhance',
        'magnitude': 5,
        'scale': 1.5,
      });
      expect(q['samples'], 1);
      expect(q['width'], 384);
      expect(q['height'], 576);
      expect(q['strength'], .7);
      expect(q['noise'], .1);
      container
          .read(generationParamsNotifierProvider.notifier)
          .updatePromptImmediately('new user draft');
      final latest = container.read(generationParamsNotifierProvider);
      final result = await run(q);
      expect(result['status'], 'completed');
      final request = requests.single;
      expectComposedPromptParams(
        request.copyWith(width: 832, height: 1216, nSamples: 1),
      );
      expect(request.prompt, q['prompt']);
      expect(request.enhanceWorkflow, isTrue);
      expect(request.upscaledEnhance, isFalse);
      expect(request.strength, .7);
      expect(request.noise, .1);
      expect(result['artifacts'], hasLength(1));
      expect(container.read(generationParamsNotifierProvider), latest);
    },
  );

  test(
    'Max target dimensions and Anlas remain aligned with native enhancement rather than source-size free pricing',
    () async {
      container
          .read(generationParamsNotifierProvider.notifier)
          .updateModel('nai-diffusion-5-curated');
      final q = await quote(
        {'operation': 'enhance', 'max': true},
        width: 832,
        height: 1216,
      );
      final target = MaxEnhanceMath.targetSize(832, 1216);
      expect(q['width'], target.width);
      expect(q['height'], target.height);
      expect(q['estimated_anlas'], greaterThan(0));
      final result = await run(q);
      expect(result['status'], 'completed');
      expect(requests.single.width, 832);
      expect(requests.single.height, 1216);
      expect(requests.single.upscaledEnhance, isTrue);
      expect(result['estimated_anlas'], q['estimated_anlas']);
    },
  );

  test(
    'decline and Stop during confirmation never call generation or create source backups',
    () async {
      for (final stop in [false, true]) {
        final q = await quote({'operation': 'variations'});
        final token = NaiAgentCancellation();
        final pending = service.execute('image_generate', {
          'action': 'run',
          'quote_id': q['quote_id'],
        }, token);
        final broker = container.read(naiAgentGenerationApprovalsProvider);
        if (stop) {
          final check = expectLater(pending, throwsA(isA<NaiAgentToolError>()));
          token.cancel();
          await check;
        } else {
          broker.decide(broker.forChat('chat').single.id, generate: false);
          expect((await pending)['details']['status'], 'cancelled');
        }
      }
      expect(requests, isEmpty);
      expect(await Directory('${root.path}/outputs').exists(), isFalse);
    },
  );

  test(
    'source bounds, incompatible options, model flags and cross-chat quotes are rejected locally',
    () async {
      final q = await quote({'operation': 'variations'});
      final other = container.read(naiAgentStudioFactoryProvider)(
        root,
        root,
        true,
        owner: const NaiAgentConversationOwner('workspace', 'other'),
      );
      await expectLater(
        other.execute('image_generate', {
          'action': 'run',
          'quote_id': q['quote_id'],
        }, NaiAgentCancellation()),
        throwsA(
          isA<NaiAgentToolError>().having(
            (e) => e.code,
            'code',
            'quote_missing',
          ),
        ),
      );
      for (final options in [
        {'operation': 'variations', 'strength': .2},
        {'operation': 'enhance', 'magnitude': 5, 'noise': .2},
        {'operation': 'enhance', 'max': true},
        {'operation': 'enhance', 'max': false, 'scale': 1.25},
        {'operation': 'enhance', 'authorized': true},
      ]) {
        await expectLater(quote(options), throwsA(isA<NaiAgentToolError>()));
      }
      await expectLater(
        quote({'operation': 'variations'}, width: 2048, height: 2048),
        throwsA(
          isA<NaiAgentToolError>().having(
            (e) => e.code,
            'code',
            'invalid_source_size',
          ),
        ),
      );
      expect(requests, isEmpty);
    },
  );

  test(
    'account changes invalidate source approval before a native request or backup',
    () async {
      final q = await quote({'operation': 'variations'});
      final pending = service.execute('image_generate', {
        'action': 'run',
        'quote_id': q['quote_id'],
      }, NaiAgentCancellation());
      final checked = expectLater(
        pending,
        throwsA(
          isA<NaiAgentToolError>().having(
            (e) => e.code,
            'code',
            'quote_changed',
          ),
        ),
      );
      (container.read(authNotifierProvider.notifier) as GenerationTestAuth)
          .setAuth(const AuthState());
      final broker = container.read(naiAgentGenerationApprovalsProvider);
      broker.decide(broker.forChat('chat').single.id, generate: true);
      await checked;
      expect(requests, isEmpty);
      expect(await Directory('${root.path}/outputs').exists(), isFalse);
    },
  );
  for (final operation in ['variations', 'enhance']) {
    test(
      '$operation leaves a real random prompt block instance and its draft projection unchanged',
      () async {
        final block = await container
            .read(promptBlockLibraryNotifierProvider.notifier)
            .createBlock(
              title: 'random hair',
              content: 'red hair, blue hair',
              atoms: ['red hair', 'blue hair'],
            );
        final pills = container.read(pillWorkspaceProvider('main').notifier);
        pills.insertBlockAt(offset: 0, blockId: block.id);
        final instance = container
            .read(pillWorkspaceProvider('main'))
            .document
            .instances
            .keys
            .single;
        pills.updateInstanceSettings(
          instance,
          const PillInstanceSettings(mode: PillRollMode.random),
        );
        container
            .read(generationParamsNotifierProvider.notifier)
            .updatePromptFromPill(
              container.read(pillWorkspaceProvider('main')).projection,
            );
        await Future<void>.delayed(Duration.zero);
        final before = jsonEncode(
          container.read(pillWorkspaceProvider('main')).document.toJson(),
        );
        final draft = container.read(generationParamsNotifierProvider);
        final q = await quote({'operation': operation});
        final result = await run(q);
        expect(result['status'], 'completed');
        expect(
          jsonEncode(
            container.read(pillWorkspaceProvider('main')).document.toJson(),
          ),
          before,
        );
        expect(container.read(generationParamsNotifierProvider), draft);
        expect(requests.single.prompt, q['prompt']);
      },
    );
  }

  test(
    'Agent Stop interrupts its admitted native source stream and consumes the quote',
    () async {
      final stream = StreamController<ImageStreamChunk>();
      when(() => api.generateImageStream(any())).thenAnswer((invocation) {
        requests.add(invocation.positionalArguments.single as ImageParams);
        stream.add(ImageStreamChunk.progress(progress: .2));
        return stream.stream;
      });
      when(() => api.cancelGeneration()).thenAnswer((_) {
        unawaited(stream.close());
      });
      final q = await quote({'operation': 'variations'});
      final token = NaiAgentCancellation();
      final pending = service.execute('image_generate', {
        'action': 'run',
        'quote_id': q['quote_id'],
      }, token);
      final broker = container.read(naiAgentGenerationApprovalsProvider);
      broker.decide(broker.forChat('chat').single.id, generate: true);
      for (var i = 0; i < 200 && requests.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(requests, hasLength(1));
      final status = (await service.execute('image_generate', {
        'action': 'status',
      }, NaiAgentCancellation()))['details'];
      expect(status['owned'], true);
      await expectLater(
        service.execute('image_generate', {
          'action': 'cancel',
          'run_id': 'other-run',
        }, NaiAgentCancellation()),
        throwsA(
          isA<NaiAgentToolError>().having(
            (e) => e.code,
            'code',
            'run_not_owned',
          ),
        ),
      );
      token.cancel();
      final result = (await pending.timeout(
        const Duration(seconds: 20),
      ))['details'];
      expect(result['status'], 'cancelled');
      expect(result['artifacts'], isEmpty);
      expect(
        container.read(imageGenerationNotifierProvider).isGenerating,
        false,
      );
      expect(
        (await service.execute('image_generate', {
          'action': 'status',
        }, NaiAgentCancellation()))['details']['owned'],
        false,
      );
      await expectLater(
        service.execute('image_generate', {
          'action': 'run',
          'quote_id': q['quote_id'],
        }, NaiAgentCancellation()),
        throwsA(
          isA<NaiAgentToolError>().having(
            (e) => e.code,
            'code',
            'quote_missing',
          ),
        ),
      );
    },
  );

  test(
    'native source failure keeps the request backup and never replays an admitted quote',
    () async {
      when(() => api.generateImageStream(any())).thenAnswer((invocation) {
        requests.add(invocation.positionalArguments.single as ImageParams);
        return Stream.error(StateError('synthetic request failure'));
      });
      final q = await quote({'operation': 'enhance'});
      final result = await run(q);
      expect(result['status'], 'error');
      expect(result['images'], isEmpty);
      expect(result['artifacts'], isEmpty);
      expect(
        await File('${root.path}/${result['backup_path']}').exists(),
        true,
      );
      await expectLater(
        service.execute('image_generate', {
          'action': 'run',
          'quote_id': q['quote_id'],
        }, NaiAgentCancellation()),
        throwsA(
          isA<NaiAgentToolError>().having(
            (e) => e.code,
            'code',
            'quote_missing',
          ),
        ),
      );
      expect(requests, hasLength(1));
    },
  );
  test(
    'official Pi tool loop waits for a source confirmation, executes the native batch and reads exported pixels',
    () async {
      await File('${root.path}/input.png').writeAsBytes(
        Uint8List.fromList(img.encodePng(img.Image(width: 256, height: 384))),
      );
      final server = await bindFetchTestServer();
      final modelRequests = <Map<String, dynamic>>[];
      var quoteId = '', outputPath = '';
      Map<String, dynamic> call(
        String id,
        Map<String, dynamic> args, {
        String name = 'image_generate',
      }) => {
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
              'arguments': jsonEncode(args),
            },
          },
        ],
      };
      final serving = server.listen((request) async {
        final body =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        modelRequests.add(body);
        final turn = modelRequests.length;
        if (turn == 2 || turn == 3) {
          final raw = (body['messages'] as List).lastWhere(
            (m) => m['role'] == 'tool',
          )['content'];
          final data = jsonDecode(raw is String ? raw : raw[0]['text']);
          if (turn == 2) quoteId = data['quote']['quote_id'] as String;
          if (turn == 3) outputPath = data['artifacts'].first['path'] as String;
        }
        final delta = switch (turn) {
          1 => call('source-quote', {
            'action': 'prepare',
            'operation': 'variations',
            'path': 'input.png',
          }),
          2 => call('source-run', {'action': 'run', 'quote_id': quoteId}),
          3 => call('source-look', {'path': outputPath}, name: 'image_read'),
          _ => {'content': '已完成源图变体并读取实际输出。'},
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
          workspaceId: 'workspace',
          chatId: 'pi-source-chat',
          workspace: root,
          data: Directory('${root.path}/agent'),
          nodeExecutable:
              Platform.environment['NAI_AGENT_NODE'] ?? 'E:/node/node.exe',
          hostScript: File('tool/nai_agent/host.mjs').absolute.path,
          systemPrompt: '你是 NAI Agent。按需使用工具。',
        );
        final before = container.read(generationParamsNotifierProvider);
        final pending = client
            .prompt('按官方方式生成变体，然后查看输出。')
            .timeout(const Duration(seconds: 30));
        final broker = container.read(naiAgentGenerationApprovalsProvider);
        for (
          var i = 0;
          i < 800 && broker.forChat('pi-source-chat').isEmpty;
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        final approval = broker.forChat('pi-source-chat').single;
        expect(modelRequests, hasLength(2));
        expect(requests, isEmpty);
        expect(approval.quote.input.sourceOperation, 'variations');
        broker.decide(approval.id, generate: true);
        await pending;
        expect(requests, hasLength(1));
        expect(requests.single.nSamples, 3);
        expect(modelRequests, hasLength(4));
        final last = jsonEncode(modelRequests.last);
        expect(last, contains(base64Encode(bytes)));
        expect(last, isNot(contains('synthetic-private-key')));
        expect(await File('${root.path}/$outputPath').readAsBytes(), bytes);
        expect(container.read(generationParamsNotifierProvider), before);
        expect(broker.forChat('pi-source-chat'), isEmpty);
      } finally {
        await client?.close();
        await serving.cancel();
        await server.close(force: true);
      }
    },
  );
}
