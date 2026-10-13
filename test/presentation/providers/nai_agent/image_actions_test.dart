import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/nai_agent/agent_tool.dart';
import 'package:nai_launcher/core/nai_agent/generation_tools.dart';
import 'package:nai_launcher/core/nai_agent/studio_tools.dart';
import 'package:nai_launcher/core/network/nai_api_endpoint.dart';
import 'package:nai_launcher/core/network/nai_api_endpoint_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/utils/image_save_utils.dart';
import 'package:nai_launcher/data/datasources/remote/nai_image_enhancement_api_service.dart';
import 'package:nai_launcher/data/models/director/director_tool_type.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/data/services/metadata/unified_metadata_parser.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/director_tools_notifier.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_image_approvals.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_studio_provider.dart';
import 'generation_binding_test.dart' show GenerationTestAuth;
import '../krita/agent_bridge_draft_test.dart' show MemoryDraftSettings;

Uint8List png(int w, int h) =>
    Uint8List.fromList(img.encodePng(img.Image(width: w, height: h)));

class _Params extends GenerationParamsNotifier {
  @override
  ImageParams build() =>
      const ImageParams(prompt: 'unrelated draft', seed: 999);
}

class _Images extends ImageGenerationNotifier {
  _Images(this.source);
  final Uint8List source;
  @override
  ImageGenerationState build() {
    final image = GeneratedImage(
      id: 'source',
      bytes: source,
      width: 64,
      height: 48,
    );
    return ImageGenerationState(
      currentImages: [image],
      displayImages: [image],
      history: [image],
    );
  }
}

class _Api extends NAIImageEnhancementApiService {
  _Api() : super(Dio());
  final calls =
      <
        ({
          String type,
          Uint8List source,
          String? prompt,
          int defry,
          CancelToken? token,
        })
      >[];
  Completer<List<Uint8List>>? pending;
  Uint8List? cloudResult;
  List<Uint8List> result = [png(64, 48), png(64, 48), png(64, 48)];
  @override
  Future<List<Uint8List>> augmentImages(
    Uint8List image, {
    required String reqType,
    String? prompt,
    int defry = 0,
    CancelToken? cancelToken,
  }) async {
    calls.add((
      type: reqType,
      source: Uint8List.fromList(image),
      prompt: prompt,
      defry: defry,
      token: cancelToken,
    ));
    return pending == null ? result : pending!.future;
  }

  @override
  Future<Uint8List> upscaleImage(
    Uint8List image, {
    void Function(int, int)? onProgress,
    CancelToken? cancelToken,
  }) async {
    calls.add((
      type: 'cloud_upscale',
      source: Uint8List.fromList(image),
      prompt: null,
      defry: 0,
      token: cancelToken,
    ));
    return pending == null
        ? (cloudResult ?? png(128, 96))
        : (await pending!.future).first;
  }
}

void main() {
  late Directory workspace;
  late ProviderContainer container;
  late NaiAgentStudioTools studio;
  late _Api api;
  late Uint8List source;
  const owner = NaiAgentConversationOwner('workspace', 'chat');
  Matcher error(String code) =>
      throwsA(isA<NaiAgentToolError>().having((e) => e.code, 'code', code));
  Future<Map<String, dynamic>> run(
    Map<String, dynamic> p, {
    NaiAgentCancellation? token,
  }) async => Map<String, dynamic>.from(
    (await studio.execute(
      'image_tool',
      p,
      token ?? NaiAgentCancellation(),
    ))['details'],
  );
  Future<Map<String, dynamic>> quote(
    String tool, {
    Map<String, dynamic> extra = const {},
  }) async => Map<String, dynamic>.from(
    (await run({
      'action': 'prepare',
      'tool': tool,
      'image_id': 'source',
      ...extra,
    }))['quote'],
  );
  Future<AgentImageApproval> waiting() async {
    final broker = container.read(naiAgentImageApprovalsProvider);
    for (var i = 0; i < 100 && broker.forChat('chat').isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    return broker.forChat('chat').single;
  }

  Future<void> called() async {
    for (var i = 0; i < 100 && api.calls.isEmpty; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(api.calls, isNotEmpty);
  }

  Future<Map<String, dynamic>> accepted(Map<String, dynamic> q) async {
    final future = run({'action': 'run', 'quote_id': q['quote_id']});
    final request = await waiting();
    container
        .read(naiAgentImageApprovalsProvider)
        .decide(request.id, run: true);
    return future;
  }

  setUp(() async {
    workspace = await Directory.systemTemp.createTemp(
      'nai-agent-image-actions-',
    );
    Hive.init('${workspace.path}/hive');
    await Hive.openBox(StorageKeys.settingsBox);
    source = await ImageSaveUtils.rebuildImageBytesWithMetadata(
      imageBytes: png(64, 48),
      params: const ImageParams(
        prompt: 'source prompt',
        seed: 123,
        width: 64,
        height: 48,
      ),
    );
    api = _Api();
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        generationParamsNotifierProvider.overrideWith(_Params.new),
        imageGenerationNotifierProvider.overrideWith(() => _Images(source)),
        authNotifierProvider.overrideWith(GenerationTestAuth.new),
        naiImageEnhancementApiServiceProvider.overrideWithValue(api),
      ],
    );
    studio = container.read(naiAgentStudioFactoryProvider)(
      workspace,
      workspace,
      false,
      owner: owner,
    );
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    assert(workspace.path.contains('nai-agent-image-actions-'));
    await workspace.delete(recursive: true);
  });
  test(
    'native quote is offline; model authorization flags and decline cannot spend',
    () async {
      final q = await quote('removeBackground');
      expect(q['estimated_anlas'], greaterThan(0));
      expect(q['balance_anlas'], 10000);
      expect(api.calls, isEmpty);
      await expectLater(
        run({'action': 'run', 'quote_id': q['quote_id'], 'authorized': true}),
        error('invalid_image_tool'),
      );
      final future = run({'action': 'run', 'quote_id': q['quote_id']});
      final r = await waiting();
      expect(r.sourceBytes, source);
      expect(api.calls, isEmpty);
      expect(Directory('${workspace.path}/outputs').existsSync(), false);
      container.read(naiAgentImageApprovalsProvider).decide(r.id, run: false);
      expect((await future)['cancelled'], true);
      expect(api.calls, isEmpty);
    },
  );
  test(
    'all background variants retain source metadata/output/history without changing workbench or display',
    () async {
      final director = container.read(directorToolsNotifierProvider.notifier);
      director.addSource(png(24, 24));
      director.selectTool(DirectorToolType.colorize);
      director.updatePrompt('workbench');
      director.updateDefry(4);
      final before = container.read(directorToolsNotifierProvider),
          display = container
              .read(imageGenerationNotifierProvider)
              .displayImages;
      final result = await accepted(await quote('removeBackground'));
      expect(api.calls.single.source, source);
      expect(api.calls.single.type, 'bg-removal');
      expect(result['artifacts'], hasLength(3));
      expect(result['image_ids'], hasLength(3));
      expect(result['display_changed'], false);
      for (final artifact in result['artifacts']) {
        final bytes = await File(
          '${workspace.path}/${artifact['path']}',
        ).readAsBytes();
        final m = UnifiedMetadataParser.parseFromImageBytes(bytes).metadata;
        expect(m?.prompt, 'source prompt');
        expect(m?.seed, 123);
      }
      final state = container.read(directorToolsNotifierProvider);
      expect(state.sources, before.sources);
      expect(state.selectedTool, before.selectedTool);
      expect(state.prompt, 'workbench');
      expect(state.defry, 4);
      expect(state.runs, isEmpty);
      expect(
        identical(
          container.read(imageGenerationNotifierProvider).displayImages,
          display,
        ),
        true,
      );
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        'unrelated draft',
      );
      expect(
        File('${workspace.path}/${result['request_backup']}').existsSync(),
        true,
      );
    },
  );
  test(
    'cloud upscale is frozen 2x and one admitted quote cannot replay',
    () async {
      final q = await quote('cloud_upscale');
      expect(q['estimated_anlas'], 1);
      final result = await accepted(q);
      expect(result['artifacts'].single['width'], 128);
      expect(result['artifacts'].single['height'], 96);
      await expectLater(
        run({'action': 'run', 'quote_id': q['quote_id']}),
        error('quote_missing'),
      );
      expect(api.calls, hasLength(1));
    },
  );
  test(
    'Stop while waiting for confirmation never calls native API or creates backups',
    () async {
      final q = await quote('cloud_upscale'), token = NaiAgentCancellation();
      final pending = run({
        'action': 'run',
        'quote_id': q['quote_id'],
      }, token: token);
      final expected = expectLater(pending, error('cancelled'));
      await waiting();
      token.cancel();
      await expected;
      expect(api.calls, isEmpty);
      expect(Directory('${workspace.path}/outputs').existsSync(), false);
    },
  );
  test(
    'zero-balance Opus free operation still requires confirmation and can execute',
    () async {
      (container.read(authNotifierProvider.notifier) as GenerationTestAuth)
          .setAuth(
            const AuthState(
              status: AuthStatus.authenticated,
              accountId: 'synthetic-account',
              subscriptionInfo: {
                'tier': 3,
                'active': true,
                'trainingStepsLeft': 0,
              },
            ),
          );
      final q = await quote(
        'colorize',
        extra: {'prompt': 'blue dress', 'defry': 1},
      );
      expect(q['estimated_anlas'], 0);
      await accepted(q);
      expect(api.calls.single.type, 'colorize');
      expect(api.calls.single.prompt, 'blue dress');
    },
  );
  test(
    'wrong cloud dimensions refuse history and consume the admitted quote',
    () async {
      api.cloudResult = png(64, 48);
      final q = await quote('cloud_upscale');
      await expectLater(accepted(q), error('invalid_result'));
      expect(
        container.read(imageGenerationNotifierProvider).history,
        hasLength(1),
      );
      await expectLater(
        run({'action': 'run', 'quote_id': q['quote_id']}),
        error('quote_missing'),
      );
    },
  );
  for (final change in ['account', 'endpoint', 'price', 'balance']) {
    test(
      'changed $change refuses live confirmation and no API executes',
      () async {
        final q = await quote(
          change == 'balance' ? 'removeBackground' : 'colorize',
          extra: change == 'balance' ? {} : {'prompt': 'red dress', 'defry': 3},
        );
        final future = run({'action': 'run', 'quote_id': q['quote_id']});
        final expectError = expectLater(
          future,
          error(change == 'balance' ? 'insufficient_balance' : 'quote_changed'),
        );
        final r = await waiting();
        final auth =
            container.read(authNotifierProvider.notifier) as GenerationTestAuth;
        if (change == 'endpoint') {
          container
              .read(naiApiEndpointServiceProvider)
              .setCurrent(
                const NaiApiEndpointConfig(
                  mainBaseUrl: 'https://api.novelai.net',
                  imageBaseUrl: 'https://invalid.local',
                ),
              );
        } else {
          auth.setAuth(
            AuthState(
              status: AuthStatus.authenticated,
              accountId: change == 'account' ? 'other' : 'synthetic-account',
              subscriptionInfo: {
                'tier': change == 'price' ? 0 : 3,
                'active': true,
                'trainingStepsLeft': change == 'balance' ? 0 : 10000,
              },
            ),
          );
        }
        container.read(naiAgentImageApprovalsProvider).decide(r.id, run: true);
        await expectError;
        expect(api.calls, isEmpty);
      },
    );
  }
  test('owned cancel and late Stop never touch a new native job', () async {
    api.pending = Completer<List<Uint8List>>();
    final token = NaiAgentCancellation(),
        q = await quote(
          'fixEmotion',
          extra: {'emotion': 'happy', 'prompt': 'extra', 'defry': 4},
        );
    final future = run({
          'action': 'run',
          'quote_id': q['quote_id'],
        }, token: token),
        expected = expectLater(future, error('cancelled'));
    final r = await waiting();
    container.read(naiAgentImageApprovalsProvider).decide(r.id, run: true);
    await called();
    expect(api.calls.single.prompt, 'happy;;extra');
    expect(api.calls.single.defry, 4);
    final status = await run({'action': 'status'});
    await expectLater(
      run({'action': 'cancel', 'job_id': 'wrong'}),
      error('not_owned'),
    );
    await run({'action': 'cancel', 'job_id': status['job_id']});
    await Future<void>.delayed(Duration.zero);
    expect(api.calls.single.token!.isCancelled, true);
    api.pending!.complete([png(64, 48)]);
    await expected;
    api.pending = Completer<List<Uint8List>>();
    final manual = container
        .read(directorToolsNotifierProvider.notifier)
        .processGenerated(source, tool: DirectorToolType.toSketch);
    await Future<void>.delayed(Duration.zero);
    token.cancel();
    await Future<void>.delayed(Duration.zero);
    expect(api.calls.last.token!.isCancelled, false);
    api.pending!.complete([png(64, 48)]);
    await manual;
  });
  test(
    'native Pixel Snap runs without account/vision, preserves original bytes and has no paid requests',
    () async {
      (container.read(authNotifierProvider.notifier) as GenerationTestAuth)
          .setAuth(const AuthState());
      final grid = img.Image(width: 80, height: 80, numChannels: 4);
      for (final p in grid) {
        p.setRgba(
          (37 + (p.x ~/ 8) * 23 + (p.y ~/ 8) * 11) % 256,
          (91 + (p.x ~/ 8) * 7 + (p.y ~/ 8) * 29) % 256,
          (153 + (p.x ~/ 8) * 41 + (p.y ~/ 8) * 3) % 256,
          255,
        );
      }
      final original = Uint8List.fromList(img.encodePng(grid));
      await File('${workspace.path}/pixel.png').writeAsBytes(original);
      final result = await run({
        'action': 'pixel_snap',
        'path': 'pixel.png',
        'pixel': {'paletteMode': 'off', 'avoidOverRefining': true},
      });
      expect(result['estimated_anlas'], 0);
      expect(result['artifacts'], hasLength(1));
      expect(result['history_registered'], true);
      expect(api.calls, isEmpty);
      final path = result['artifacts'].single['path'] as String;
      expect(
        File(
          '${workspace.path}/${path.replaceFirst('image.png', 'source.png')}',
        ).readAsBytesSync(),
        original,
      );
      await expectLater(
        run({
          'action': 'pixel_snap',
          'path': 'pixel.png',
          'pixel': {'colors': 300},
        }),
        error('invalid_options'),
      );
    },
  );
}
