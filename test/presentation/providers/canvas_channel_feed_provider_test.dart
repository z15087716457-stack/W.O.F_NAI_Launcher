import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/providers/canvas_channel_feed_provider.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';

void main() {
  final now = DateTime(2026, 10, 15, 12);
  GeneratedImage image(String id, int run) => GeneratedImage(
    id: id,
    bytes: Uint8List(0),
    width: 512,
    height: 768,
    generationRunId: run,
    createdAt: now.subtract(Duration(days: run)),
  );
  test(
    'feed projection follows actual world rectangles and excludes the pinboard',
    () {
      final pending = CanvasFeedGroup(
        key: 'run:3',
        runId: 3,
        tiles: [
          const CanvasTileSpec.slot(
            StreamPreviewSlot(imageNumber: 1, totalImages: 1, progress: 0),
            slotWidth: 512,
            slotHeight: 768,
          ),
        ],
      );
      final groups = [
        pending,
        CanvasFeedGroup(
          key: 'run:2',
          runId: 2,
          tiles: [
            CanvasTileSpec.image(image('b', 2)),
            CanvasTileSpec.image(image('c', 2)),
          ],
        ),
        CanvasFeedGroup(
          key: 'pin:a',
          runId: null,
          tiles: [CanvasTileSpec.image(image('a', 1))],
        ),
        CanvasFeedGroup(
          key: 'pin:b',
          runId: null,
          tiles: [CanvasTileSpec.image(image('d', 1))],
        ),
      ];
      final laid = layoutCanvasFeed(groups);
      final layout = CanvasFeedLayoutResult(
        items: laid.items,
        groups: groups,
        bounds: laid.bounds,
      );
      final data = CanvasChannelFeed.fromLayout(
        layout,
        now: now,
        generating: true,
        activeRun: 3,
      );
      expect(data.batches.map((b) => b.id), ['run:3', 'run:2']);
      expect(data.batches.first.pending, isTrue);
      expect(data.batches.first.time, isNull);
      expect(data.batches.last.count, 2);
      expect(data.batches.last.time, groups[1].images.first.createdAt);
      expect(data.top, layout.items.first.groupRect.top);
      final pinRects = layout.items
          .where((item) => item.group.isPinnedGroup)
          .map((item) => item.groupRect);
      expect(data.pinboard, pinRects.reduce((a, b) => a.expandToInclude(b)));
      expect(data.now, now);
    },
  );
  test('empty feed has no phantom batches, timestamps or pinboard', () {
    final data = CanvasChannelFeed.fromLayout(
      const CanvasFeedLayoutResult(items: [], groups: [], bounds: Rect.zero),
      now: now,
    );
    expect(data.batches, isEmpty);
    expect(data.pinboard, isNull);
    expect(data.top, 0);
  });
}
