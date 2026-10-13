import '../../../helpers/fetch_test_server.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/nai_agent/pi_host_client.dart';
import 'package:nai_launcher/core/nai_agent/studio_tools.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/utils/image_save_utils.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/models/upscale/local_upscale_models.dart';
import 'package:nai_launcher/data/services/local_upscale_model_manager.dart';
import 'package:nai_launcher/data/services/local_upscale_service.dart';
import 'package:nai_launcher/data/services/metadata/unified_metadata_parser.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_files.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/cloud_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/director_tools_notifier.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_image_tool_binding.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_studio_provider.dart';
import '../krita/agent_bridge_draft_test.dart' show MemoryDraftSettings;

Uint8List png(int w, int h) => Uint8List.fromList(
  img.encodePng(img.Image(width: w, height: h, numChannels: 4)),
);

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() =>
      const ImageParams(prompt: 'unrelated draft', seed: 999);
}

class _History extends ImageGenerationNotifier {
  _History(this.bytes);
  final Uint8List bytes;
  @override
  ImageGenerationState build() {
    final source = GeneratedImage(
      id: 'source',
      bytes: bytes,
      width: 48,
      height: 32,
    );
    return ImageGenerationState(
      currentImages: [source],
      displayImages: [source],
      history: [source],
    );
  }
}

class _Service extends Mock implements LocalUpscaleService {
  final calls = <Map<String, dynamic>>[];
  Future<LocalUpscaleResult> Function(int)? respond;
  @override
  Future<LocalUpscaleResult> upscale(
    Uint8List source, {
    required String modelId,
    required double scale,
    required LocalUpscaleCancellation cancellation,
    Seedvr2Options seedvr2Options = const Seedvr2Options(),
    void Function(LocalUpscaleProgress)? onProgress,
  }) async {
    calls.add({
      'source': source,
      'model': modelId,
      'scale': scale,
      'cancellation': cancellation,
      'options': seedvr2Options,
    });
    onProgress?.call(
      const LocalUpscaleProgress(LocalUpscalePhase.inference, 0.5),
    );
    if (respond != null) return respond!(calls.length);
    final original = img.decodeImage(source)!;
    final w = (original.width * scale).round(),
        h = (original.height * scale).round();
    return LocalUpscaleResult(png(w, h), w, h);
  }
}

class _Process extends Mock implements Process {}

class _BusyDirector extends DirectorToolsNotifier {
  @override
  DirectorToolsState build() => const DirectorToolsState(isRunning: true);
}

class _BusyCloud extends CloudUpscaleTask {
  @override
  CloudUpscaleState build() => const CloudUpscaleState(running: true);
}

class _ExportHook extends AgentWorkspaceFiles {
  _ExportHook(super.workspace, this.after);
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
  late Directory workspace;
  late ProviderContainer container;
  late _Service service;
  late NaiAgentStudioTools studio;
  late NaiAgentImageToolBinding tool;
  late Uint8List source;
  late bool alive, blocked;
  Matcher error(String code) =>
      throwsA(isA<NaiAgentToolError>().having((e) => e.code, 'code', code));
  Future<Map<String, dynamic>> run(
    Map<String, dynamic> params, {
    NaiAgentCancellation? token,
  }) async => Map<String, dynamic>.from(
    (await tool.execute(params, token ?? NaiAgentCancellation()))['details']
        as Map,
  );
  Future<Map<String, dynamic>> upscale({
    Map<String, dynamic> extra = const {},
    NaiAgentCancellation? token,
  }) => run({
    'action': 'upscale',
    'image_id': 'source',
    'model_id': 'anime',
    'scale': 1.5,
    ...extra,
  }, token: token);
  setUp(() async {
    alive = true;
    blocked = false;
    workspace = await Directory.systemTemp.createTemp('nai-agent-image-tool-');
    Hive.init(p.join(workspace.path, 'hive'));
    await Hive.openBox(StorageKeys.settingsBox);
    source = await ImageSaveUtils.rebuildImageBytesWithMetadata(
      imageBytes: png(48, 32),
      params: const ImageParams(
        prompt: 'original source',
        seed: 123,
        width: 48,
        height: 32,
      ),
    );
    service = _Service();
    container = ProviderContainer(
      overrides: [
        generationParamsNotifierProvider.overrideWith(_Params.new),
        imageGenerationNotifierProvider.overrideWith(() => _History(source)),
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        localUpscaleServiceProvider.overrideWithValue(service),
        localUpscaleModelsProvider.overrideWith(
          (ref) async => [
            localUpscaleCatalog.first.withInstalled(true),
            localUpscaleCatalog[1],
            advancedUpscaleCatalog.first.withInstalled(true),
            advancedUpscaleCatalog[5].withInstalled(true),
          ],
        ),
      ],
    );
    studio = NaiAgentStudioTools(
      workspaceDirectory: workspace,
      readDraft: () => throw UnimplementedError(),
      readSummary: () => {},
      isGenerating: () => blocked,
      backupDraft: (_) async => 'unused',
      writeDraft: (_) => [],
      allowsImages: true,
      isAlive: () => alive,
      readImage: (id) {
        final state = container.read(imageGenerationNotifierProvider);
        final actual = state.history
            .where((image) => image.id == id)
            .firstOrNull;
        return actual == null
            ? null
            : NaiAgentImage(id: actual.id, bytes: actual.bytes);
      },
    );
    tool = container.read(
      Provider(
        (ref) => NaiAgentImageToolBinding(
          ref,
          workspace,
          studio.loadImage,
          () =>
              blocked ||
              (ref.exists(localUpscaleTaskProvider) &&
                  ref.read(localUpscaleTaskProvider).running),
          () => alive,
        ),
      ),
    );
    container
        .read(generationPreviewSelectionProvider.notifier)
        .select('source');
  });
  tearDown(() async {
    alive = false;
    container.dispose();
    await Hive.close();
    assert(workspace.path.contains('nai-agent-image-tool-'));
    await workspace.delete(recursive: true);
  });
  Future<void> started() async {
    for (var i = 0; i < 100 && service.calls.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(service.calls, isNotEmpty);
  }

  test(
    'installed model list and idle status do not run inference or change Studio',
    () async {
      final history = container.read(imageGenerationNotifierProvider);
      final listing = await run({'action': 'list'});
      expect(listing['models'], hasLength(4));
      expect(listing['models'][3]['max_blocks_to_swap'], 36);
      expect(listing['models'][1]['installed'], false);
      expect(listing['downloads'], false);
      expect((await run({'action': 'status'}))['job_id'], null);
      expect(service.calls, isEmpty);
      expect(container.read(imageGenerationNotifierProvider), same(history));
      expect(
        await Directory(p.join(workspace.path, 'outputs')).exists(),
        false,
      );
    },
  );

  test(
    'upscale exports exact original, metadata and history without replacing draft/display',
    () async {
      final before = container.read(imageGenerationNotifierProvider);
      final draft = container.read(generationParamsNotifierProvider);
      final result = await upscale();
      expect(result['ok'], true);
      expect(result['history_registered'], true);
      final after = container.read(imageGenerationNotifierProvider);
      expect(after.currentImages, same(before.currentImages));
      expect(after.displayImages, same(before.displayImages));
      expect(container.read(generationParamsNotifierProvider), same(draft));
      expect(container.read(generationPreviewSelectionProvider), 'source');
      expect(after.history, hasLength(2));
      final image = after.history.first;
      expect(image.id, result['image_id']);
      expect(image.originalBytes, source);
      final bytes = await File(
        p.join(workspace.path, result['path'] as String),
      ).readAsBytes();
      expect(bytes, image.bytes);
      final meta = UnifiedMetadataParser.parseFromImageBytes(bytes).metadata!;
      expect(meta.prompt, 'original source');
      expect(meta.seed, 123);
      expect((meta.width, meta.height), (72, 48));
      expect(
        await File(
          p.join(workspace.path, result['source_path'] as String),
        ).readAsBytes(),
        source,
      );
      expect(result['artifacts'].single['path'], result['path']);
      expect(jsonEncode(result), isNot(contains(base64Encode(source))));
    },
  );

  test(
    'plain JPEG input remains byte-exact with its format and no unrelated draft metadata',
    () async {
      final bytes = Uint8List.fromList(
        img.encodeJpg(img.Image(width: 48, height: 32)),
      );
      await File(p.join(workspace.path, 'input.jpg')).writeAsBytes(bytes);
      final result = await run({
        'action': 'upscale',
        'path': 'input.jpg',
        'model_id': 'anime',
        'scale': 1.5,
      });
      expect(result['source_path'], endsWith('source.jpg'));
      expect(
        await File(
          p.join(workspace.path, result['source_path'] as String),
        ).readAsBytes(),
        bytes,
      );
      final output = await File(
        p.join(workspace.path, result['path'] as String),
      ).readAsBytes();
      expect(UnifiedMetadataParser.parseFromImageBytes(output).metadata, null);
    },
  );

  test(
    'INT8 Sharp native options and source remain frozen during inference',
    () async {
      final pending = Completer<LocalUpscaleResult>();
      service.respond = (_) => pending.future;
      final options = {
        'seed': 42,
        'blocksToSwap': 36,
        'vaeTileSize': 512,
        'vaeTileOverlap': 64,
        'colorCorrection': 'none',
        'inputNoise': 0.25,
      };
      final future = upscale(
        extra: {'model_id': 'seedvr2-7b-sharp-int8', 'seedvr2': options},
      );
      await started();
      final received = service.calls.single;
      expect(received['model'], 'seedvr2-7b-sharp-int8');
      expect((received['options'] as Seedvr2Options).blocksToSwap, 36);
      expect((await run({'action': 'status'}))['fraction'], 0.5);
      container
          .read(generationParamsNotifierProvider.notifier)
          .updatePrompt('new user draft');
      await container.read(promptBlockLibraryNotifierProvider.future);
      options['seed'] = 100;
      pending.complete(LocalUpscaleResult(png(72, 48), 72, 48));
      final result = await future;
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        'new user draft',
      );
      expect((received['options'] as Seedvr2Options).seed, 42);
      expect(
        await File(
          p.join(workspace.path, result['source_path'] as String),
        ).readAsBytes(),
        source,
      );
    },
  );

  test(
    'invalid options/models/actions and busy state reject before inference',
    () async {
      for (final item in <(Map<String, dynamic>, String)>[
        ({'model_id': 'anime-fast'}, 'model_missing'),
        ({'scale': double.nan}, 'invalid_scale'),
        ({'scale': 5}, 'invalid_scale'),
        (
          {
            'seedvr2': {'seed': 1},
          },
          'invalid_options',
        ),
        (
          {
            'model_id': 'seedvr2-3b',
            'seedvr2': {'blocksToSwap': 36},
          },
          'invalid_options',
        ),
        (
          {
            'model_id': 'seedvr2-3b',
            'seedvr2': {'vaeTileSize': 129},
          },
          'invalid_options',
        ),
        (
          {
            'model_id': 'seedvr2-3b',
            'seedvr2': {'seed': 0.0},
          },
          'invalid_options',
        ),
        ({'unknown': true}, 'invalid_image_tool'),
      ]) {
        await expectLater(upscale(extra: item.$1), error(item.$2));
      }
      blocked = true;
      await expectLater(upscale(), error('busy'));
      expect(service.calls, isEmpty);
      expect(
        await Directory(p.join(workspace.path, 'outputs')).exists(),
        false,
      );
    },
  );

  test(
    'workspace path traversal is rejected by the production original-image loader',
    () async {
      final outside = File('${workspace.path}-outside.png');
      await outside.writeAsBytes(source);
      try {
        await expectLater(
          run({
            'action': 'upscale',
            'path': '../${p.basename(outside.path)}',
            'model_id': 'anime',
            'scale': 2,
          }),
          error('path_outside_workspace'),
        );
        expect(service.calls, isEmpty);
        expect(await outside.readAsBytes(), source);
      } finally {
        await outside.delete();
      }
    },
  );

  for (final domain in ['director', 'cloud']) {
    test('production factory protects an active $domain image task', () async {
      final busyContainer = ProviderContainer(
        overrides: [
          generationParamsNotifierProvider.overrideWith(_Params.new),
          imageGenerationNotifierProvider.overrideWith(() => _History(source)),
          localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
          localUpscaleServiceProvider.overrideWithValue(service),
          localUpscaleModelsProvider.overrideWith(
            (ref) async => [localUpscaleCatalog.first.withInstalled(true)],
          ),
          if (domain == 'director')
            directorToolsNotifierProvider.overrideWith(_BusyDirector.new),
          if (domain == 'cloud')
            cloudUpscaleTaskProvider.overrideWith(_BusyCloud.new),
        ],
      );
      try {
        if (domain == 'director') {
          busyContainer.read(directorToolsNotifierProvider);
        }
        if (domain == 'cloud') busyContainer.read(cloudUpscaleTaskProvider);
        final factory = busyContainer.read(naiAgentStudioFactoryProvider)(
          workspace,
          workspace,
          false,
        );
        await expectLater(
          factory.execute('image_tool', {
            'action': 'upscale',
            'image_id': 'source',
            'model_id': 'anime',
            'scale': 2,
          }, NaiAgentCancellation()),
          error('busy'),
        );
        expect(service.calls, isEmpty);
      } finally {
        busyContainer.dispose();
      }
    });
  }

  for (final condition in ['stop', 'cancel', 'closed']) {
    test(
      '$condition during native inference prevents output registration',
      () async {
        final pending = Completer<LocalUpscaleResult>(),
            token = NaiAgentCancellation();
        service.respond = (_) => pending.future;
        final future = upscale(token: token);
        final check = expectLater(
          future,
          error(condition == 'closed' ? 'closed' : 'cancelled'),
        );
        await started();
        if (condition == 'stop') token.cancel();
        if (condition == 'cancel') {
          final status = await run({'action': 'status'});
          await run({'action': 'cancel', 'job_id': status['job_id']});
        }
        if (condition == 'closed') alive = false;
        await Future<void>.delayed(Duration.zero);
        if (condition != 'closed') {
          expect(
            (service.calls.single['cancellation'] as LocalUpscaleCancellation)
                .isCancelled,
            true,
          );
        }
        pending.complete(LocalUpscaleResult(png(72, 48), 72, 48));
        await check;
        expect(
          container.read(imageGenerationNotifierProvider).history,
          hasLength(1),
        );
        expect(
          await Directory(p.join(workspace.path, 'outputs')).exists(),
          false,
        );
      },
    );
  }

  test(
    'other chat and late cancellation cannot stop an admitted manual native task',
    () async {
      final token = NaiAgentCancellation();
      await upscale(token: token);
      final manual = Completer<LocalUpscaleResult>();
      service.respond = (_) => manual.future;
      final task = container.read(localUpscaleTaskProvider.notifier);
      final future = task.processGenerated(source, modelId: 'anime', scale: 2);
      await expectLater(
        run({'action': 'cancel', 'job_id': 'other-chat'}),
        error('not_owned'),
      );
      token.cancel();
      await Future<void>.delayed(Duration.zero);
      expect(
        (service.calls.last['cancellation'] as LocalUpscaleCancellation)
            .isCancelled,
        false,
      );
      manual.complete(LocalUpscaleResult(png(96, 64), 96, 64));
      expect(await future, isNotNull);
    },
  );

  test(
    'stopping during export preserves a newer manual inference and its display',
    () async {
      final token = NaiAgentCancellation(),
          pending = Completer<LocalUpscaleResult>();
      Future<LocalUpscaleResult?>? manual;
      tool = container.read(
        Provider(
          (ref) => NaiAgentImageToolBinding(
            ref,
            workspace,
            studio.loadImage,
            () => blocked || ref.read(localUpscaleTaskProvider).running,
            () => alive,
            workspaceFiles: _ExportHook(workspace, () async {
              service.respond = (_) => pending.future;
              manual = ref
                  .read(localUpscaleTaskProvider.notifier)
                  .processGenerated(source, modelId: 'anime', scale: 2);
              token.cancel();
              await Future<void>.delayed(Duration.zero);
            }),
          ),
        ),
      );
      await expectLater(upscale(token: token), error('cancelled'));
      expect(
        (service.calls.last['cancellation'] as LocalUpscaleCancellation)
            .isCancelled,
        false,
      );
      expect(
        container.read(imageGenerationNotifierProvider).history,
        hasLength(1),
      );
      pending.complete(LocalUpscaleResult(png(96, 64), 96, 64));
      expect(await manual, isNotNull);
    },
  );

  test(
    'native failure and mismatched output keep their failure codes without export',
    () async {
      service.respond = (_) async =>
          throw const LocalUpscaleException(LocalUpscaleError.noInt8);
      await expectLater(
        upscale(extra: {'model_id': 'seedvr2-7b-sharp-int8'}),
        error('noInt8'),
      );
      service.respond = (_) async => LocalUpscaleResult(png(48, 32), 72, 48);
      await expectLater(upscale(), error('invalid_result'));
      expect(
        await Directory(p.join(workspace.path, 'outputs')).exists(),
        false,
      );
      expect(
        container.read(imageGenerationNotifierProvider).history,
        hasLength(1),
      );
    },
  );

  test(
    'official Pi and production Studio factory use real native preprocessing/output with no vision',
    () async {
      final manager = LocalUpscaleModelManager(
        rootDirectory: () async => Directory(p.join(workspace.path, 'native')),
        loadAsset: (name) =>
            File(p.join('assets', 'local_upscale', name)).readAsBytes(),
      );
      var workers = 0;
      final native = LocalUpscaleService(
        manager,
        supportedPlatform: true,
        startProcess: (exe, args) async {
          workers++;
          expect(p.isWithin(workspace.path, exe), true);
          expect(args[args.indexOf('-s') + 1], '4');
          final input = img.decodeImage(
            await File(args[args.indexOf('-i') + 1]).readAsBytes(),
          )!;
          await File(args[args.indexOf('-o') + 1]).writeAsBytes(
            img.encodePng(
              img.copyResize(
                input,
                width: input.width * 4,
                height: input.height * 4,
              ),
            ),
          );
          final process = _Process();
          when(() => process.stdout).thenAnswer((_) => const Stream.empty());
          when(() => process.stderr).thenAnswer((_) => const Stream.empty());
          when(() => process.exitCode).thenAnswer((_) async => 0);
          return process;
        },
      );
      final nativeContainer = ProviderContainer(
        overrides: [
          generationParamsNotifierProvider.overrideWith(_Params.new),
          imageGenerationNotifierProvider.overrideWith(() => _History(source)),
          localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
          localUpscaleServiceProvider.overrideWithValue(native),
          localUpscaleModelsProvider.overrideWith((ref) => manager.models()),
        ],
      );
      final production = nativeContainer.read(naiAgentStudioFactoryProvider)(
        workspace,
        workspace,
        false,
      );
      final server = await bindFetchTestServer();
      final requests = <Map<String, dynamic>>[],
          events = <Map<String, dynamic>>[];
      final serving = server.listen((request) async {
        final body =
            jsonDecode(await utf8.decoder.bind(request).join())
                as Map<String, dynamic>;
        requests.add(body);
        final turn = requests.length;
        Map? previous;
        if (turn > 1) {
          final content = (body['messages'] as List).lastWhere(
            (message) => message['role'] == 'tool',
          )['content'];
          previous =
              jsonDecode(content is String ? content : content[0]['text'])
                  as Map;
        }
        final args = switch (turn) {
          1 => {'action': 'list'},
          2 => {
            'action': 'upscale',
            'image_id': 'source',
            'model_id': previous!['models'][0]['model_id'],
            'scale': 1.5,
          },
          _ => {'action': 'status'},
        };
        final delta = turn < 4
            ? {
                'role': 'assistant',
                'tool_calls': [
                  {
                    'index': 0,
                    'id': 'call-$turn',
                    'type': 'function',
                    'function': {
                      'name': 'mcp__nai_studio__image_tool',
                      'arguments': jsonEncode(args),
                    },
                  },
                ],
              }
            : {'content': '本地超分完成，结果保存在工作区。'};
        request.response.headers.set(
          'content-type',
          'text/event-stream; charset=utf-8',
        );
        for (final choice in [
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
              'choices': [choice],
            })}\n\n',
          );
        }
        request.response.write('data: [DONE]\n\n');
        await request.response.close();
      });
      PiHostClient? client;
      StreamSubscription<Map<String, dynamic>>? subscription;
      try {
        client = await PiHostClient.start(
          mcp: const {'builtinExposure': 'direct'},
          nodeExecutable:
              Platform.environment['NAI_AGENT_NODE'] ?? 'E:/node/node.exe',
          hostScript: File('tool/nai_agent/host.mjs').absolute.path,
          workspaceId: 'native-agent-upscale',
          workspaceDirectory: workspace,
          agentDirectory: Directory(p.join(workspace.path, '.agent')),
          systemPrompt:
              'Use native local tools without modifying the Studio draft.',
          privateModelConfig: {
            'providerId': 'local',
            'modelId': 'synthetic',
            'protocol': 'openaiChatCompletions',
            'baseUrl': 'http://127.0.0.1:${server.port}',
            'apiKey': 'synthetic-private-key',
            'tools': true,
            'vision': false,
            'maxConcurrentRequests': 1,
          },
          extraToolNames: production.domainToolNames,
          executeTool: production.execute,
        );
        subscription = client.events.listen(events.add);
        await client
            .prompt('把这张图在本地放大一倍半。')
            .timeout(const Duration(seconds: 30));
        expect(requests, hasLength(4));
        expect(workers, 1);
        final ends = events
            .where((event) => event['event']?['type'] == 'tool_execution_end')
            .toList();
        expect(ends, hasLength(3));
        expect(ends.every((event) => event['event']['isError'] == false), true);
        final result =
            ends[1]['event']['result']['structuredContent']['structuredContent']
                as Map;
        final bytes = await File(
          p.join(workspace.path, result['path'] as String),
        ).readAsBytes();
        expect(
          (img.decodePng(bytes)!.width, img.decodePng(bytes)!.height),
          (72, 48),
        );
        expect(
          UnifiedMetadataParser.parseFromImageBytes(bytes).metadata!.prompt,
          'original source',
        );
        expect(
          await File(
            p.join(workspace.path, result['source_path'] as String),
          ).readAsBytes(),
          source,
        );
        expect(
          nativeContainer.read(generationParamsNotifierProvider).prompt,
          'unrelated draft',
        );
        expect(
          nativeContainer
              .read(imageGenerationNotifierProvider)
              .currentImages
              .single
              .id,
          'source',
        );
        expect(
          nativeContainer.read(imageGenerationNotifierProvider).history,
          hasLength(2),
        );
        expect(jsonEncode(requests), isNot(contains('synthetic-private-key')));
        expect(jsonEncode(requests), isNot(contains(base64Encode(source))));
        expect(
          await Directory(
            p.join(manager.directory.path, 'jobs'),
          ).list().toList(),
          isEmpty,
        );
        manager.claimInference('anime');
        manager.releaseInference();
      } finally {
        await subscription?.cancel();
        await client?.close();
        await serving.cancel();
        await server.close(force: true);
        nativeContainer.dispose();
        manager.dispose();
      }
    },
  );
}
