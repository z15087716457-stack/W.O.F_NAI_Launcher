import 'package:nai_launcher/presentation/providers/simple_viewer_group_batches_provider.dart';

/// Existing batch-focused canvas fixtures explicitly exercise grouped mode.
/// The real setting defaults to individual images in both output viewers.
final groupedCanvasBatchesOverride = simpleViewerGroupBatchesProvider
    .overrideWith(_GroupedCanvasBatches.new);

class _GroupedCanvasBatches extends SimpleViewerGroupBatches {
  @override
  bool build() => true;
}
