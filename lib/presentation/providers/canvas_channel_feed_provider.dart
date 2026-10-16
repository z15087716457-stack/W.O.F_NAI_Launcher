import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../screens/generation/widgets/canvas/canvas_feed_layout.dart';
import '../ui/channel/channel_contract.dart';
import 'image_generation_provider.dart';

final canvasChannelClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Project once per feed change, never once per animation/camera frame.
final canvasChannelFeedProvider = Provider<CanvasChannelFeed>((ref) {
  final layout = ref.watch(canvasFeedGeometryProvider);
  final generation = ref.watch(
    imageGenerationNotifierProvider.select(
      (state) => (state.isGenerating, state.generationRunId),
    ),
  );
  return CanvasChannelFeed.fromLayout(
    layout,
    generating: generation.$1,
    activeRun: generation.$2,
    now: ref.read(canvasChannelClockProvider)(),
  );
});

class CanvasChannelFeed {
  const CanvasChannelFeed({
    required this.batches,
    required this.now,
    this.pinboard,
    this.generating = false,
  });

  factory CanvasChannelFeed.fromLayout(
    CanvasFeedLayoutResult layout, {
    required DateTime now,
    bool generating = false,
    int? activeRun,
  }) {
    final rects = {
      for (final item in layout.items) item.group.key: item.groupRect,
    };
    final batches = <ChannelBatch>[];
    Rect? pinboard;
    for (final group in layout.groups) {
      final rect = rects[group.key];
      if (rect == null || rect.isEmpty) continue;
      if (group.isPinnedGroup) {
        pinboard = pinboard?.expandToInclude(rect) ?? rect;
        continue;
      }
      final images = group.images;
      batches.add(
        ChannelBatch(
          id: group.key,
          rect: rect,
          time: images.firstOrNull?.createdAt,
          count: group.tiles.length,
          pending: generating && group.runId == activeRun && images.isEmpty,
        ),
      );
    }
    return CanvasChannelFeed(
      batches: List.unmodifiable(batches),
      pinboard: pinboard,
      now: now,
      generating: generating,
    );
  }

  final List<ChannelBatch> batches;
  final Rect? pinboard;
  final DateTime now;
  final bool generating;
  double get top => batches.firstOrNull?.rect.top ?? 0;
}
