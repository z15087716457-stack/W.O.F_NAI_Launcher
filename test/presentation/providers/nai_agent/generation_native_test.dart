import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
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
  late List<ImageParams> requests;
  late Uint8List bytes;
  void Function()? onRequest;
  setUp(() async {
    root = await Directory.systemTemp.createTemp(
      'nai-agent-native-generation-',
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
  test(
    'visible authorization runs the actual native batch/preset/history pipeline with synthetic stream bytes',
    () async {
      final original = await configurePromptComposition(container);
      final service = container.read(naiAgentStudioFactoryProvider)(
        root,
        root,
        true,
        owner: const NaiAgentConversationOwner('workspace', 'chat'),
      );
      final q = (await service.execute('generation_prepare', {
        'requests': 2,
        'images_per_request': 2,
      }, NaiAgentCancellation()))['details']['quote'];
      final run = service.execute('generation_run', {
        'quote_id': q['quote_id'],
      }, NaiAgentCancellation());
      expect(requests, isEmpty);
      final broker = container.read(naiAgentGenerationApprovalsProvider);
      broker.decide(broker.forChat('chat').single.id, generate: true);
      final result = (await run.timeout(
        const Duration(seconds: 20),
      ))['details'];
      expect(result['status'], 'completed');
      expect(requests, hasLength(2));
      for (final request in requests) {
        expectComposedPromptParams(request.copyWith(nSamples: 1));
        expect(request.nSamples, 2);
        expect(request.seed, isNonNegative);
      }
      final state = container.read(imageGenerationNotifierProvider);
      expect(state.currentImages, hasLength(4));
      expect(result['images'], hasLength(4));
      expect(
        (result['images'] as List).map((r) => r['image_id']).toSet(),
        state.currentImages.map((i) => i.id).toSet(),
      );
      expect(result['images'].first['width'], 32);
      // These synthetic PNGs carry no metadata. Do not invent output seeds.
      expect(result['images'].first['seed'], null);
      expect(
        container.read(generationParamsNotifierProvider).prompt,
        original.prompt,
      );
      expect(
        container.read(generationParamsNotifierProvider).nSamples,
        original.nSamples,
      );
      expect(result['actual_anlas'], null);
      verifyNever(
        () => api.generateImage(any(), onProgress: any(named: 'onProgress')),
      );
    },
  );

  test(
    'Turbo native quote and synthetic request use fixed settings without editing drafts',
    () async {
      await configurePromptComposition(container);
      final notifier = container.read(
        generationParamsNotifierProvider.notifier,
      );
      notifier.updateModel(ImageModels.animeDiffusionV5FullMedium);
      notifier.updateSteps(37);
      notifier.updateSampler(Samplers.kDpmpp2m);
      notifier.updateCfgRescale(.65);
      final raw = container.read(generationParamsNotifierProvider);
      final service = container.read(naiAgentStudioFactoryProvider)(
        root,
        root,
        true,
        owner: const NaiAgentConversationOwner('workspace', 'chat'),
      );
      final q = (await service.execute(
        'generation_prepare',
        {},
        NaiAgentCancellation(),
      ))['details']['quote'];
      expect(q['model'], ImageModels.animeDiffusionV5FullMedium);
      expect(q['steps'], 14);
      expect(q['sampler'], Samplers.kEulerAncestral);
      expect(q['model_constraints']['custom_negative_prompt'], isFalse);
      final run = service.execute('generation_run', {
        'quote_id': q['quote_id'],
      }, NaiAgentCancellation());
      final broker = container.read(naiAgentGenerationApprovalsProvider);
      broker.decide(broker.forChat('chat').single.id, generate: true);
      expect((await run)['details']['status'], 'completed');
      final request = requests.single;
      expect(request.model, ImageModels.animeDiffusionV5FullMedium);
      expect(request.steps, 14);
      expect(request.sampler, Samplers.kEulerAncestral);
      expect(request.cfgRescale, 0);
      expect(request.negativePrompt, isEmpty);
      expect(request.characters.every((c) => c.negativePrompt.isEmpty), isTrue);
      final after = container.read(generationParamsNotifierProvider);
      expect(after.steps, raw.steps);
      expect(after.sampler, raw.sampler);
      expect(after.cfgRescale, raw.cfgRescale);
      expect(after.negativePrompt, raw.negativePrompt);
    },
  );
  test(
    'real native Stop cancels only the admitted request and does not auto retry it',
    () async {
      final service = container.read(naiAgentStudioFactoryProvider)(
        root,
        root,
        true,
        owner: const NaiAgentConversationOwner('workspace', 'chat'),
      );
      final q = (await service.execute(
        'generation_prepare',
        {},
        NaiAgentCancellation(),
      ))['details']['quote'];
      final token = NaiAgentCancellation();
      onRequest = () {
        token.cancel();
      };
      final run = service.execute('generation_run', {
        'quote_id': q['quote_id'],
      }, token);
      final broker = container.read(naiAgentGenerationApprovalsProvider);
      broker.decide(broker.forChat('chat').single.id, generate: true);
      final result = (await run.timeout(
        const Duration(seconds: 20),
      ))['details'];
      expect(result['status'], 'cancelled');
      expect(requests, hasLength(1));
      verify(() => api.cancelGeneration()).called(1);
      expect(result['actual_anlas'], null);
    },
  );
}
