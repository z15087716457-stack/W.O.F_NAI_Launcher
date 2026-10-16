import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/shortcuts/shortcut_config.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/core/services/prompt_token_counter_service.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/l10n/app_localizations_zh.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:nai_launcher/presentation/providers/generation/image_action_providers.dart';
import 'package:nai_launcher/presentation/providers/generation/local_upscale_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/preview_selection_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/krita/bridge_draft_snapshot.dart';
import 'package:nai_launcher/presentation/providers/pill_workspace_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_token_counter_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/wiring/generation_data_wiring.dart';
import '../providers/krita/agent_bridge_draft_test.dart'
    show MemoryCharacters, MemoryDraftSettings, EmptyBlocks, OfflineAuth;

class DataGeneration extends ImageGenerationNotifier {
  @override
  ImageGenerationState build() => const ImageGenerationState();
  void publish(ImageGenerationState value) => state = value;
}

class DataSubscription extends SubscriptionNotifier {
  void publish(SubscriptionState value) => state = value;

  @override
  SubscriptionState build() => const SubscriptionState.loaded(
    UserSubscription(
      tier: 3,
      active: true,
      trainingStepsLeft: TrainingStepsInfo(
        fixedTrainingStepsLeft: 70,
        purchasedTrainingSteps: 20,
      ),
      usage: OpusUsage(percent: 27.5),
    ),
  );
}

class DataShortcuts extends ShortcutConfigNotifier {
  @override
  Future<ShortcutConfig> build() async => ShortcutConfig.createDefault();
}

class DataRecents extends ReferencePanelNotifier {
  @override
  ReferencePanelState build() => const ReferencePanelState();
}

final _variationQuotes = StateProvider<Map<String, int?>>((ref) => {});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ProviderContainer container;
  final l = AppLocalizationsZh();
  final provider = generationViewDataProvider(l);
  late ProviderSubscription<GenViewData> subscription;
  late Completer<NaiImageMetadata?> pendingMetadata;
  setUp(() async {
    pendingMetadata = Completer<NaiImageMetadata?>();
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('generation-data-');
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
        authNotifierProvider.overrideWith(OfflineAuth.new),
        imageGenerationNotifierProvider.overrideWith(DataGeneration.new),
        subscriptionNotifierProvider.overrideWith(DataSubscription.new),
        shortcutConfigNotifierProvider.overrideWith(DataShortcuts.new),
        referencePanelNotifierProvider.overrideWith(DataRecents.new),
        localUpscaleModelsProvider.overrideWith((ref) async => []),
        generationFavoriteImagesProvider.overrideWith((ref) async => {}),
        generationTranslationRouteLabelProvider.overrideWithValue(
          'Local · test-model',
        ),
        promptTokenUsageProvider.overrideWith(
          (ref, target) async =>
              const PromptTokenUsage(usedTokens: 12, limit: 1471),
        ),
        characterPromptTokenUsageProvider.overrideWith(
          (ref, target) async =>
              const PromptTokenUsage(usedTokens: 5, limit: 1471),
        ),
        generationClockProvider.overrideWithValue(
          () => DateTime(2026, 10, 12, 12),
        ),
        estimatedCostProvider.overrideWithValue(12),
        imageVariationCostProvider.overrideWith(
          (ref, image) => ref.watch(_variationQuotes)[image.id],
        ),
        generatedImageMetadataProvider.overrideWith(
          (ref, image) => image.id == 'quote-loading'
              ? pendingMetadata.future
              : image.metadata,
        ),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately('user prompt');
    subscription = container.listen(provider, (_, _) {});
  });
  tearDown(() async {
    subscription.close();
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  test('整页绑定真实 provider 值而非假数据默认值', () {
    final params = container.read(generationParamsNotifierProvider.notifier);
    params.updateModel(ImageModels.animeDiffusionV5Full);
    params.updateNSamples(7);
    container.read(imagesPerRequestProvider.notifier).set(3);
    final data = container.read(provider);
    expect(data.model, ImageModels.animeDiffusionV5Full);
    expect(data.quota.anlas, 90);
    expect(data.quota.subscriptionAnlas, 70);
    expect(data.quota.purchasedAnlas, 20);
    expect(data.quota.opusPercent, 27.5);
    expect(data.quota.opusTip, contains('27.5'));
    expect(data.image.count, 3);
    expect(data.image.repeat, 7);
    expect(data.generate.total, 21);
    expect(data.generate.cost, 12);
    expect(data.characters!.max, 32);
    expect(data.characters!.freeform, isTrue);
    expect(data.prompt.transparent, isFalse);
    expect(data.refs.vibes, isNull);
    expect(data.refs.precise, isNull);
    expect(data.prompt.translate.route, 'Local · test-model');

    final account = container.read(subscriptionNotifierProvider).subscription!;
    for (final (usage, expected) in <(OpusUsage?, double?)>[
      (const OpusUsage(percent: 141), 141),
      (const OpusUsage(percent: 275.5), 275.5),
      (const OpusUsage(percent: 12345), 12345),
      (const OpusUsage(percent: 0), 0),
      (const OpusUsage(percent: 141, isNegative: true), 0),
      (const OpusUsage(percent: -4), 0),
      (null, null),
    ]) {
      (container.read(subscriptionNotifierProvider.notifier)
              as DataSubscription)
          .publish(SubscriptionState.loaded(account.copyWith(usage: usage)));
      final quota = container.read(provider).quota;
      expect(quota.opusPercent, expected, reason: '$usage');
      expect(quota.opusTip, usage == null ? null : generationOpusTip(l, usage));
      expect(quota.anlas, 90);
      if (usage != null) {
        expect(usage.displayPercent, expected!.clamp(0, 100));
      }
    }
  });
  test('V4.5 有参考、网格与六角色，V3 隐藏角色且 Opus 格不误显示', () {
    final params = container.read(generationParamsNotifierProvider.notifier);
    params.updateModel(ImageModels.animeDiffusionV45Full);
    var data = container.read(provider);
    expect(data.characters!.max, 6);
    expect(data.characters!.freeform, isFalse);
    expect(data.refs.vibes, isNotNull);
    expect(data.refs.precise, isNotNull);
    expect(data.prompt.transparent, isNull);
    expect(data.quota.opusPercent, isNull);
    params.updateModel(ImageModels.animeDiffusionV3);
    data = container.read(provider);
    expect(data.characters, isNull);
    expect(data.refs.precise, isNull);
    expect(data.params.smea, isNotNull);
  });
  test('读整页与最终提示词预览不初始化未打开负面 lane', () {
    expect(
      container.exists(pillWorkspaceProvider(PillScopes.negative)),
      isFalse,
    );
    final data = container.read(provider);
    expect(data.prompt.positivePreview.first.text, contains('user prompt'));
    expect(data.prompt.negativePreview, isNotEmpty);
    expect(
      container.exists(pillWorkspaceProvider(PillScopes.negative)),
      isFalse,
    );
  });
  test('焦点组切换保持历史图，历史计数和来源不拿当前请求覆盖', () {
    final image = GeneratedImage(
      id: 'history',
      bytes: Uint8List.fromList([1]),
      width: 64,
      height: 128,
      generationRunId: 3,
    );
    (container.read(imageGenerationNotifierProvider.notifier) as DataGeneration)
        .publish(
          ImageGenerationState(
            status: GenerationStatus.generating,
            generationRunId: 4,
            totalImages: 2,
            currentImage: 1,
            history: [image],
            batchWidth: 512,
            batchHeight: 512,
          ),
        );
    container
        .read(generationCanvasGroupSelectionProvider.notifier)
        .selectGroup('run:3');
    final data = container.read(provider);
    expect(data.canvas.focus!.id, 'run:3');
    expect(data.canvas.info!.tileId, 'history');
    expect(data.canvas.info!.width, 64);
    expect(data.canvas.locked, isTrue);
    expect(data.generate.state, GenRunState.generating);
    expect(data.generate.total, 2);
    expect(data.history.batches.first.pending, 2);
  });
  test('变体报价跟随当前图片和异步报价更新，0 保留，草稿不变', () async {
    final before = container.read(generationParamsNotifierProvider);
    GeneratedImage source(String id, int run) => GeneratedImage(
      id: id,
      bytes: Uint8List(0),
      width: 832,
      height: 1216,
      generationRunId: run,
    );
    void focus(GeneratedImage image) {
      (container.read(imageGenerationNotifierProvider.notifier)
              as DataGeneration)
          .publish(
            ImageGenerationState(history: [image], displayImages: [image]),
          );
      container
          .read(generationCanvasGroupSelectionProvider.notifier)
          .selectGroup('run:${image.generationRunId}');
    }

    container.read(_variationQuotes.notifier).state = {
      'quote-a': 0,
      'quote-b': 12,
    };
    focus(source('quote-a', 30));
    expect(container.read(provider).canvas.info!.variationsCost, 0);
    expect(
      container.read(provider).canvas.info!.variationsCostLoading,
      isFalse,
    );
    container.read(_variationQuotes.notifier).state = {
      'quote-a': 9,
      'quote-b': 12,
    };
    await container.pump();
    expect(container.read(provider).canvas.info!.variationsCost, 9);
    focus(source('quote-b', 31));
    expect(container.read(provider).canvas.info!.tileId, 'quote-b');
    expect(container.read(provider).canvas.info!.variationsCost, 12);
    container.read(_variationQuotes.notifier).state = {};
    await container.pump();
    expect(container.read(provider).canvas.info!.variationsCost, isNull);
    expect(container.read(generationParamsNotifierProvider), before);
  });

  test('报价加载与解析结束但无参数分开，换图不沿用旧价', () async {
    final image = GeneratedImage(
      id: 'quote-loading',
      bytes: Uint8List(0),
      width: 1024,
      height: 1024,
      generationRunId: 32,
    );
    (container.read(imageGenerationNotifierProvider.notifier) as DataGeneration)
        .publish(
          ImageGenerationState(history: [image], displayImages: [image]),
        );
    container
        .read(generationCanvasGroupSelectionProvider.notifier)
        .selectGroup('run:32');
    expect(container.read(provider).canvas.info!.variationsCost, isNull);
    expect(container.read(provider).canvas.info!.variationsCostLoading, isTrue);
    pendingMetadata.complete(null);
    await container.read(generatedImageMetadataProvider(image).future);
    await container.pump();
    expect(container.read(provider).canvas.info!.variationsCost, isNull);
    expect(
      container.read(provider).canvas.info!.variationsCostLoading,
      isFalse,
    );
  });
  test('图生图停用不隐去草稿图和蒙版；数据开关与请求一致', () {
    final params = container.read(generationParamsNotifierProvider.notifier);
    params.setSourceImage(Uint8List.fromList([1]));
    params.setMaskImage(Uint8List.fromList([2]));
    container.read(generationImg2ImgEnabledProvider.notifier).set(false);
    final data = container.read(provider);
    expect(data.refs.img2img.hasImage, isTrue);
    expect(data.refs.img2img.enabled, isFalse);
    expect(data.refs.img2img.mask, GenMask.ready);
    expect(container.read(generationRequestParamsProvider).sourceImage, isNull);
  });
  test('图生图启用状态属于草稿确认世代，改回旧值也不能恢复旧确认', () {
    final before = container.read(bridgeDraftVersionProvider);
    final flag = container.read(generationImg2ImgEnabledProvider.notifier);
    flag.set(false);
    final disabled = container.read(bridgeDraftVersionProvider);
    flag.set(true);
    expect(disabled, isNot(before));
    expect(container.read(bridgeDraftVersionProvider), isNot(before));
  });
}
