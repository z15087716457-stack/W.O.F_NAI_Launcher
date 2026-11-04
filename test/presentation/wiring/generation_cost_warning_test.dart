import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:image/image.dart' as img;

import 'package:nai_launcher/data/models/gallery/nai_image_metadata.dart';
import 'package:nai_launcher/core/utils/image_save_utils.dart';
import 'package:nai_launcher/data/services/metadata/unified_metadata_parser.dart';
import 'package:nai_launcher/data/models/user/user_subscription.dart';
import 'package:nai_launcher/data/models/image/image_params.dart';
import 'package:nai_launcher/presentation/providers/generation/image_action_providers.dart';
import 'package:nai_launcher/presentation/providers/history_click_behavior_provider.dart';
import 'package:nai_launcher/presentation/providers/simple_output_viewer_provider.dart';
import 'package:nai_launcher/presentation/providers/simple_viewer_group_batches_provider.dart';
import 'package:nai_launcher/presentation/providers/generation/image_workflow_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/data/repositories/character_prompt_repository.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/providers/cost_estimate_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/providers/share_image_settings_provider.dart';
import 'package:nai_launcher/presentation/providers/shortcuts_provider.dart';
import 'package:nai_launcher/presentation/providers/subscription_provider.dart';
import 'package:nai_launcher/presentation/providers/tips_provider.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_contract.dart';
import 'package:nai_launcher/presentation/ui/gen/gen_page.dart';
import 'package:nai_launcher/presentation/widgets/common/anlas_cost_dialog.dart';
import 'package:nai_launcher/presentation/wiring/generation_backend.dart';
import 'package:nai_launcher/presentation/wiring/generation_wiring.dart';
import '../../helpers/studio_capture_fonts.dart';
import '../providers/krita/agent_bridge_draft_test.dart'
    show EmptyBlocks, MemoryCharacters, MemoryDraftSettings;
import '../screens/generation/widgets/reference_module_test.dart'
    show prepareGenerationDropTestPlatform;
import 'generation_backend_test.dart'
    show MemoryGenerationPlatform, RecordingGeneration, SwitchingAuth;
import 'generation_data_wiring_test.dart' show DataShortcuts, DataSubscription;

class _VariationQuota extends DataSubscription {
  int checks = 0;
  OpusUsage answer = const OpusUsage(percent: 60);
  void cache(OpusUsage usage) => publish(
    SubscriptionState.loaded(state.subscription!.copyWith(usage: usage)),
  );
  @override
  Future<bool> recheckBalance() async {
    checks++;
    applyFetchedSubscription(state.subscription!.copyWith(usage: answer));
    return true;
  }
}

class _Variations extends RecordingGeneration {
  void publish(ImageGenerationState value) => state = value;

  void select(GeneratedImage image) {
    state = ImageGenerationState(
      currentImages: [image],
      displayImages: [image],
      history: [image],
    );
  }

  @override
  Future<void> generateOfficialVariations(
    ImageParams params, {
    required GeneratedImage original,
  }) async {
    requests.add(params);
  }
}

void main() {
  prepareGenerationDropTestPlatform();
  setUpAll(loadStudioCaptureFonts);
  late Directory directory;
  late ProviderContainer container;
  late Completer<NaiImageMetadata?> metadata;
  var elapsed = Duration.zero;
  setUp(() async {
    elapsed = Duration.zero;
    SharedPreferences.setMockInitialValues({});
    directory = await Directory.systemTemp.createTemp('generation-cost-');
    Hive.init(directory.path);
    await Hive.openBox(StorageKeys.settingsBox);
    metadata = Completer<NaiImageMetadata?>();
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(MemoryDraftSettings()),
        characterPromptRepositoryProvider.overrideWithValue(MemoryCharacters()),
        promptBlockLibraryNotifierProvider.overrideWith(EmptyBlocks.new),
        authNotifierProvider.overrideWith(SwitchingAuth.new),
        imageGenerationNotifierProvider.overrideWith(_Variations.new),
        generatedImageMetadataProvider.overrideWith(
          (ref, image) => image.metadata ?? metadata.future,
        ),
        subscriptionNotifierProvider.overrideWith(_VariationQuota.new),
        opusPriceClockProvider.overrideWithValue(() => elapsed),
        shortcutConfigNotifierProvider.overrideWith(DataShortcuts.new),
        tipEpochProvider.overrideWith((_) => Stream.value(0)),
        generationPlatformProvider.overrideWithValue(
          MemoryGenerationPlatform(),
        ),
      ],
    );
    await container.read(promptBlockLibraryNotifierProvider.future);
    container
        .read(generationParamsNotifierProvider.notifier)
        .updatePromptImmediately('geometric fixture');
  });
  tearDown(() async {
    container.dispose();
    await Hive.close();
    await directory.delete(recursive: true);
  });
  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const Scaffold(body: GenerationWiring()),
        ),
      ),
    );
    await tester.pump();
  }

  for (final browseHistory in [true, false]) {
    testWidgets(
      'simple viewer prices the visible variation after completion (history selection: $browseHistory)',
      (tester) async {
        final generation =
            container.read(imageGenerationNotifierProvider.notifier)
                as _Variations;
        final quota =
            container.read(subscriptionNotifierProvider.notifier)
                as _VariationQuota;
        quota.cache(const OpusUsage(isNegative: true));
        final settings = container.read(shareImageSettingsProvider.notifier);
        await settings.setWarnHighAnlasCost(true);
        await settings.setHighAnlasCostThreshold(1);
        // The existing select-preview preference is available on upstream 2.2.6.
        await container
            .read(historyClickBehaviorNotifierProvider.notifier)
            .setBehavior(HistoryClickBehavior.selectPreview);
        await container
            .read(simpleViewerGroupBatchesProvider.notifier)
            .setGrouped(false);
        await container
            .read(simpleOutputViewerNotifierProvider.notifier)
            .setSimple(true);
        Future<GeneratedImage> source(
          int run,
          int width,
          int height,
          String prompt,
          String model,
          int steps, {
          bool usageOnly = false,
        }) async {
          final bytes = await ImageSaveUtils.buildPrebuiltMetadataBytes(
            imageBytes: img.encodePng(img.Image(width: width, height: height)),
            metadata: {
              'Software': 'NovelAI',
              'Source': model == ImageModels.animeDiffusionV5Full
                  ? 'DiffusionModelMetaName.NAIv5 E32849CC'
                  : 'NovelAI Diffusion V4.5 4BDE2A90',
              'Comment': jsonEncode({
                'prompt': prompt,
                'model': model,
                'steps': steps,
                'width': width,
                'height': height,
                if (usageOnly) ...{
                  'reference_strength_multiple': [0.6],
                  'use_precise_ref': true,
                  'request_type': 'NativeInfillingRequest',
                },
              }),
            },
          );
          final parsed = UnifiedMetadataParser.parseFromImageBytes(
            bytes,
          ).metadata!;
          return GeneratedImage(
            id: 'source-$run',
            bytes: bytes,
            width: width,
            height: height,
            generationRunId: run,
            batchIndex: 0,
            metadata: parsed,
          );
        }

        final old = await source(
          1,
          832,
          1216,
          'history A',
          ImageModels.animeDiffusionV5Full,
          28,
          usageOnly: true,
        );
        final latest = await source(
          2,
          512,
          768,
          'latest B',
          ImageModels.animeDiffusionV45Full,
          40,
        );
        expect(
          (
            old.metadata!.usedVibeTransfer,
            old.metadata!.usedPreciseReference,
            old.metadata!.usedInpainting,
          ),
          (true, true, true),
        );
        expect(old.metadata!.effectiveModel, ImageModels.animeDiffusionV5Full);
        expect(
          latest.metadata!.effectiveModel,
          ImageModels.animeDiffusionV45Full,
        );
        generation.select(old);
        await pump(tester);
        generation.publish(
          ImageGenerationState(
            status: GenerationStatus.generating,
            generationRunId: 2,
            currentImage: 1,
            totalImages: 1,
            batchWidth: latest.width,
            batchHeight: latest.height,
            history: [old],
            displayImages: [old],
          ),
        );
        await tester.pump();
        if (browseHistory) {
          final history = tester
              .widget<GenerationPage>(find.byType(GenerationPage))
              .data
              .history;
          final group = history.batches.singleWhere(
            (batch) => batch.images.any((item) => item.id == old.id),
          );
          await tester.tap(find.byKey(Key('gen-batch-${group.id}')));
          await tester.pump();
        }
        generation.publish(
          ImageGenerationState(
            status: GenerationStatus.completed,
            generationRunId: 2,
            currentImages: [latest],
            history: [latest, old],
            displayImages: [latest],
          ),
        );
        await tester.pumpAndSettle();
        final expected = browseHistory ? old : latest;
        final page = tester.widget<GenerationPage>(find.byType(GenerationPage));
        expect(page.data.canvas.info!.tileId, expected.id);
        expect(quota.checks, 0);
        await tester.tap(find.byKey(const Key('gen-variations')));
        await tester.pumpAndSettle();
        final confirmed = tester
            .widget<AnlasCostDialog>(find.byType(AnlasCostDialog))
            .cost;
        expect(quota.checks, browseHistory ? 1 : 0);
        expect(generation.requests, isEmpty);
        await tester.tap(find.text('继续生成'));
        await tester.pumpAndSettle();
        final sent = generation.requests.single;
        expect(sent.sourceImage, same(expected.bytes));
        expect(
          (sent.width, sent.height, sent.model, sent.steps, sent.prompt),
          (
            expected.width,
            expected.height,
            expected.metadata!.model,
            expected.metadata!.steps,
            expected.metadata!.prompt,
          ),
        );
        expect(sent.vibeReferencesV4, isEmpty);
        expect(sent.preciseReferences, isEmpty);
        expect(sent.maskImage, isNull);
        expect(
          confirmed,
          variationRequestCost(
            sent,
            container.read(subscriptionNotifierProvider).subscription,
          ),
        );
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final (label, steps, usage, expectedChecks) in [
    ('depleted and eligible', 28, const OpusUsage(isNegative: true), 1),
    ('depleted approval expires', 28, const OpusUsage(isNegative: true), 1),
    ('depleted but paid-only', 40, const OpusUsage(isNegative: true), 0),
    ('existing low-quota preview behavior', 28, const OpusUsage(percent: 3), 0),
  ]) {
    testWidgets('variation checks the selected quote before approval: $label', (
      tester,
    ) async {
      metadata = Completer<NaiImageMetadata?>();
      final generation =
          container.read(imageGenerationNotifierProvider.notifier)
              as _Variations;
      final draft = container.read(generationParamsNotifierProvider.notifier);
      draft.updateSteps(40);
      final selected = GeneratedImage.create(
        Uint8List.fromList(img.encodePng(img.Image(width: 832, height: 1216))),
        width: 832,
        height: 1216,
      );
      generation.select(selected);
      final settings = container.read(shareImageSettingsProvider.notifier);
      await settings.setWarnHighAnlasCost(true);
      await settings.setHighAnlasCostThreshold(1);
      final quota =
          container.read(subscriptionNotifierProvider.notifier)
              as _VariationQuota;
      final held = label == 'depleted approval expires';
      if (held) quota.answer = usage;
      quota.cache(usage);
      await pump(tester);
      metadata.complete(
        NaiImageMetadata(
          prompt: 'frozen source',
          model: ImageModels.animeDiffusionV5Full,
          steps: steps,
        ),
      );
      await tester.pumpAndSettle();
      expect(quota.checks, 0);
      final actions = tester
          .widget<GenerationPage>(find.byType(GenerationPage))
          .actions;
      actions.onVariations(selected.id);
      await tester.pumpAndSettle();
      expect(quota.checks, expectedChecks);
      final cost = tester
          .widget<AnlasCostDialog>(find.byType(AnlasCostDialog))
          .cost;
      expect(generation.requests, isEmpty);
      if (held) {
        elapsed = const Duration(seconds: 31);
        quota.answer = const OpusUsage(percent: 60);
      }
      await tester.tap(find.text('继续生成'));
      await tester.pumpAndSettle();
      if (held) {
        expect(quota.checks, 2);
        expect(generation.requests, isEmpty);
        await tester.pumpWidget(const SizedBox.shrink());
        return;
      }
      final sent = generation.requests.single;
      expect(sent.steps, steps);
      final account = container
          .read(subscriptionNotifierProvider)
          .subscription!;
      expect(cost, variationRequestCost(sent, account));
      if (expectedChecks == 1) {
        expect(
          cost,
          lessThan(variationRequestCost(sent, account.copyWith(usage: usage))),
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final fromPng in [false, true]) {
    testWidgets(
      'variations wait for metadata and confirm the submitted snapshot (from PNG: $fromPng)',
      (tester) async {
        metadata = Completer<NaiImageMetadata?>();
        final generation =
            container.read(imageGenerationNotifierProvider.notifier)
                as _Variations;
        final draft = container.read(generationParamsNotifierProvider.notifier);
        draft.updateModel(ImageModels.animeDiffusionV5Full);
        draft.updateSize(512, 512);
        draft.updateSteps(28);
        final selected = GeneratedImage.create(
          Uint8List.fromList(
            img.encodePng(img.Image(width: 832, height: 1216)),
          ),
          width: 832,
          height: 1216,
        );
        generation.select(selected);
        final settings = container.read(shareImageSettingsProvider.notifier);
        await settings.setWarnHighAnlasCost(true);
        await settings.setHighAnlasCostThreshold(1);
        await pump(tester);
        final action = tester
            .widget<GenerationPage>(find.byType(GenerationPage))
            .actions
            .onVariations;
        final dialog = find.byType(AnlasCostDialog);
        action(selected.id);
        await tester.pump();
        expect(dialog, findsNothing);
        expect(generation.requests, isEmpty);
        metadata.complete(
          fromPng
              ? const NaiImageMetadata(
                  prompt: 'from selected PNG',
                  model: ImageModels.animeDiffusionV45Full,
                  steps: 36,
                )
              : null,
        );
        await tester.pumpAndSettle();
        expect(dialog, findsOneWidget);
        final confirmedCost = tester.widget<AnlasCostDialog>(dialog).cost;
        expect(confirmedCost, greaterThan(0));
        expect(generation.requests, isEmpty);
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();
        expect(generation.requests, isEmpty);
        action(selected.id);
        await tester.pumpAndSettle();
        await tester.tap(find.text('继续生成'));
        await tester.pumpAndSettle();
        final sent = generation.requests.single;
        expect((sent.width, sent.height), (832, 1216));
        expect(
          sent.model,
          fromPng
              ? ImageModels.animeDiffusionV45Full
              : ImageModels.animeDiffusionV5Full,
        );
        expect(sent.steps, fromPng ? 36 : 28);
        expect(
          sent.prompt,
          fromPng ? 'from selected PNG' : contains('geometric fixture'),
        );
        expect(
          confirmedCost,
          generationRequestCost(
            sent,
            const ImageWorkflowState(),
            container.read(subscriptionNotifierProvider).subscription,
            3,
          ),
        );
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final model in [
    ImageModels.animeDiffusionV5Full,
    ImageModels.animeDiffusionV45Full,
  ]) {
    testWidgets('Generate asks before submitting a high quote on $model', (
      tester,
    ) async {
      final generation =
          container.read(imageGenerationNotifierProvider.notifier)
              as RecordingGeneration;
      final params = container.read(generationParamsNotifierProvider.notifier);
      params.updateModel(model);
      params.updateSize(1536, 1024);
      params.updateSteps(40);
      final quoted = container.read(estimatedCostProvider);
      expect(quoted, greaterThan(0));
      final settings = container.read(shareImageSettingsProvider.notifier);
      await settings.setWarnHighAnlasCost(true);
      await settings.setHighAnlasCostThreshold(quoted);
      await pump(tester);
      final state = tester
          .widget<GenerationPage>(find.byType(GenerationPage))
          .data
          .generate;
      expect(state.state, GenRunState.ready);
      expect(state.highCost, isTrue);
      final button = find.byKey(const Key('gen-generate'));
      await tester.tap(button);
      await tester.pumpAndSettle();
      final dialog = find.byType(AnlasCostDialog);
      expect(dialog, findsOneWidget);
      expect(tester.widget<AnlasCostDialog>(dialog).cost, quoted);
      expect(generation.requests, isEmpty);
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
      expect(generation.requests, isEmpty);
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.text('继续生成'));
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
      expect(generation.requests.single.model, model);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
