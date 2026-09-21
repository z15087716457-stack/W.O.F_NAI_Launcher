import '../../../providers/image_generation_provider.dart';

/// One history entry per request. Source images remain available for canvas,
/// detail navigation, saving and bulk actions.
class HistoryBatch {
  const HistoryBatch({
    required this.key,
    required this.images,
    required this.isGenerating,
    required this.count,
  });

  final String key;
  final List<GeneratedImage> images;
  final bool isGenerating;
  final int count;

  GeneratedImage? get cover {
    if (images.isEmpty) return null;
    // Parallel responses may deliver slot 2 before slot 1. Keep waiting for
    // the first slot rather than showing a changing series of covers.
    final first = images.first;
    return isGenerating && first.batchIndex != null && first.batchIndex != 0
        ? null
        : first;
  }

  bool contains(String? id) =>
      id != null && images.any((image) => image.id == id);
  List<GeneratedImage> get selectableImages =>
      images.where((image) => image.canBulkSelect).toList();
}

List<HistoryBatch> buildHistoryBatches(ImageGenerationState state) {
  final activeKey = state.isGenerating ? 'run:${state.generationRunId}' : null;
  final grouped = <String, List<GeneratedImage>>{
    if (activeKey != null) activeKey: [],
  };
  for (final image in state.mergedPanelImages) {
    final run = image.generationRunId;
    final key = run != null && run > 0 ? 'run:$run' : 'img:${image.id}';
    grouped.putIfAbsent(key, () => []).add(image);
  }
  return [
    for (final entry in grouped.entries)
      HistoryBatch(
        key: entry.key,
        images: List.unmodifiable(
          entry.value..sort((a, b) {
            final index = (a.batchIndex ?? 0).compareTo(b.batchIndex ?? 0);
            if (index != 0) return index;
            final created = a.createdAt.compareTo(b.createdAt);
            return created != 0 ? created : a.id.compareTo(b.id);
          }),
        ),
        isGenerating: entry.key == activeKey,
        count: entry.key == activeKey && state.totalImages > entry.value.length
            ? state.totalImages
            : entry.value.length,
      ),
  ];
}
