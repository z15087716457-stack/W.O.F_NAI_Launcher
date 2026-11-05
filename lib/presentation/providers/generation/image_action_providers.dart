import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/anlas_calculator.dart';
import '../../../core/utils/nai_resolution_adapter.dart';
import '../../../data/models/gallery/nai_image_metadata.dart';
import '../../../data/models/image/image_params.dart';
import '../../../data/models/user/user_subscription.dart';
import '../../../data/services/image_metadata_service.dart';
import '../../utils/official_image_variations.dart';
import '../cost_estimate_provider.dart';
import '../image_generation_provider.dart';
import '../subscription_provider.dart';
import 'image_workflow_controller.dart';

// Retain parsed metadata, not quotes or image bytes. Auto-disposed image
// providers can then return synchronously when scrolling back to a recent image.
final _generatedImageMetadataCacheProvider = Provider(
  (ref) => _GeneratedImageMetadataCache(),
);

class _GeneratedImageMetadataCache {
  static const capacity = 64;
  final _entries = <String, _GeneratedImageMetadataEntry>{};

  _GeneratedImageMetadataEntry? get(GeneratedImage image) {
    final entry = _entries.remove(image.id);
    if (entry == null ||
        !identical(entry.bytes.target, image.bytes) ||
        !identical(entry.fallback, image.metadata)) {
      return null;
    }
    _entries[image.id] = entry;
    return entry;
  }

  void put(GeneratedImage image, NaiImageMetadata? metadata) {
    _entries.remove(image.id);
    _entries[image.id] = _GeneratedImageMetadataEntry(image, metadata);
    if (_entries.length > capacity) _entries.remove(_entries.keys.first);
  }
}

class _GeneratedImageMetadataEntry {
  _GeneratedImageMetadataEntry(GeneratedImage image, this.value)
    : bytes = WeakReference(image.bytes),
      fallback = image.metadata;

  final WeakReference<Uint8List> bytes;
  final NaiImageMetadata? fallback;
  final NaiImageMetadata? value;
}

/// The PNG is authoritative even when the in-memory image has not been hydrated.
final generatedImageMetadataProvider = FutureProvider.autoDispose
    .family<NaiImageMetadata?, GeneratedImage>((ref, image) {
      if (image.bytes.isEmpty) return image.metadata;
      final cache = ref.watch(_generatedImageMetadataCacheProvider);
      final cached = cache.get(image);
      if (cached != null) return cached.value;
      return ImageMetadataService().getMetadataFromBytes(image.bytes).then((
        metadata,
      ) {
        final result = metadata ?? image.metadata;
        cache.put(image, result);
        return result;
      });
    });

int variationRequestCost(ImageParams request, UserSubscription? subscription) =>
    generationRequestCost(
      request,
      const ImageWorkflowState(),
      subscription,
      OfficialImageVariations.count,
    );

/// Only quote a variation when the selected image has sufficient request data.
final imageVariationCostProvider = Provider.autoDispose
    .family<int?, GeneratedImage>((ref, image) {
      final metadata = ref
          .watch(generatedImageMetadataProvider(image))
          .valueOrNull;
      if (metadata == null || !metadata.hasData) return null;
      final (width, height) =
          NaiResolutionAdapter.readImageSize(image.bytes) ??
          (image.width, image.height);
      if (!OfficialImageVariations.supportsSize(width, height)) return null;
      final current = ref.watch(generationParamsNotifierProvider);
      final params = OfficialImageVariations.project(
        current: current,
        source: image.bytes,
        width: width,
        height: height,
        metadata: metadata,
      );
      final subscription = ref.watch(subscriptionNotifierProvider).subscription;
      return variationRequestCost(params, subscription);
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
      if (backend != UpscaleBackend.novelai) return 0;
      final cost = AnlasCalculator.calculateNovelAiUpscaleCost(
        inputWidth: image.width,
        inputHeight: image.height,
      );
      return cost < 0 ? null : cost;
    });
