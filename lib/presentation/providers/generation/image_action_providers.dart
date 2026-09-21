import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/anlas_calculator.dart';
import '../../../data/models/gallery/nai_image_metadata.dart';
import '../../../data/models/image/image_params.dart';
import '../../../data/services/image_metadata_service.dart';
import '../../utils/metadata_import_applier.dart';
import '../image_generation_provider.dart';
import '../subscription_provider.dart';
import 'image_workflow_controller.dart';

/// The PNG is authoritative even when the in-memory image has not been hydrated.
final generatedImageMetadataProvider = FutureProvider.autoDispose
    .family<NaiImageMetadata?, GeneratedImage>((ref, image) async {
      if (image.bytes.isEmpty) return image.metadata;
      return await ImageMetadataService().getMetadataFromBytes(image.bytes) ??
          image.metadata;
    });

/// Only quote a variation when the selected image has sufficient request data.
final imageVariationCostProvider = Provider.autoDispose
    .family<int?, GeneratedImage>((ref, image) {
      final metadata = ref
          .watch(generatedImageMetadataProvider(image))
          .valueOrNull;
      if (metadata == null ||
          metadata.width == null ||
          metadata.height == null) {
        return null;
      }
      final current = ref.watch(generationParamsNotifierProvider);
      final params = current.copyWith(
        model:
            MetadataImportApplier.resolveImportableModel(metadata) ??
            current.model,
        width: metadata.width!,
        height: metadata.height!,
        steps: metadata.steps ?? current.steps,
        smea: metadata.smea ?? current.smea,
        smeaDyn: metadata.smeaDyn ?? current.smeaDyn,
        strength: metadata.strength ?? 0.45,
      );
      final subscription = ref.watch(subscriptionNotifierProvider).subscription;
      return AnlasCalculator.calculateRequestCost(
        width: params.width,
        height: params.height,
        steps: params.steps,
        batchCount: params.nSamples,
        batchSize: ref.watch(imagesPerRequestProvider),
        smea: params.effectiveSmea,
        smeaDyn: params.effectiveSmeaDyn,
        model: params.model,
        subscriptionTier: subscription?.isOpus == true
            ? AnlasCalculator.opusTier
            : 0,
        strength: params.strength,
        extraPerSampleCost: AnlasCalculator.resolvePreciseReferenceExtraCost(
          params,
        ),
        extraPerRequestCost: AnlasCalculator.resolveVibeReferenceExtraCost(
          params,
        ),
        oneTimeCost: AnlasCalculator.resolveVibeEncodingCost(params),
        opusUsageExhausted: subscription?.isOpusUsageExhausted ?? false,
      );
    });

/// Estimate the selected image with the backend that the upscale panel will
/// open with. Opening the panel itself never submits a request.
final imageUpscaleCostProvider = Provider.autoDispose
    .family<int?, GeneratedImage>((ref, image) {
      final backend = ref.watch(
        imageWorkflowControllerProvider.select(
          (workflow) => workflow.upscale.backend,
        ),
      );
      if (backend == UpscaleBackend.comfyui) return 0;
      final subscription = ref.watch(subscriptionNotifierProvider).subscription;
      final cost = AnlasCalculator.calculateNovelAiUpscaleCost(
        inputWidth: image.width,
        inputHeight: image.height,
        scale: 4,
        subscriptionTier: subscription?.isOpus == true
            ? AnlasCalculator.opusTier
            : 0,
      );
      return cost < 0 ? null : cost;
    });
