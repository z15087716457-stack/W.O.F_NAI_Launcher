import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_models.dart';
import 'package:nai_launcher/presentation/screens/generation/widgets/canvas/canvas_feed_layout.dart';

GeneratedImage _img({
  required String id,
  int width = 832,
  int height = 1216,
  int? runId,
  int? batchIndex,
  DateTime? createdAt,
}) {
  return GeneratedImage(
    id: id,
    bytes: Uint8List(0),
    width: width,
    height: height,
    createdAt: createdAt ?? DateTime(2025, 1, 1),
    kind: GeneratedImageKind.completed,
    generationRunId: runId,
    batchIndex: batchIndex,
  );
}

void main() {
  group('groupCanvasImages', () {
    test('同 runId 归一组，无 runId 各自成组', () {
      final images = [
        _img(id: 'a', runId: 1, batchIndex: 0),
        _img(id: 'b', runId: 1, batchIndex: 1),
        _img(id: 'c', runId: 2, batchIndex: 0),
        _img(id: 'd'),
      ];
      final groups = groupCanvasImages(images);
      expect(groups.length, 3);
      expect(groups[0].key, 'run:1');
      expect(groups[0].images.map((e) => e.id), ['a', 'b']);
      expect(groups[1].key, 'run:2');
      expect(groups[2].key, 'img:d');
    });

    test('组内按 batchIndex 排序，缺失回退 createdAt', () {
      final t = DateTime(2025, 1, 1);
      final images = [
        _img(id: 'a', runId: 1, batchIndex: 2, createdAt: t),
        _img(id: 'b', runId: 1, batchIndex: 0, createdAt: t),
        _img(
          id: 'c',
          runId: 1,
          createdAt: t.add(const Duration(seconds: 1)),
        ),
      ];
      final groups = groupCanvasImages(images);
      expect(groups[0].images.map((e) => e.id), ['b', 'a', 'c']);
    });

    test('保持传入的组顺序（mergedPanelImages 新→旧）', () {
      final images = [
        _img(id: 'new', runId: 9),
        _img(id: 'old', runId: 1),
      ];
      final groups = groupCanvasImages(images);
      expect(groups.map((g) => g.key), ['run:9', 'run:1']);
    });

    test('requestedCount 回填为组内张数', () {
      final groups = groupCanvasImages([
        _img(id: 'a', runId: 1),
        _img(id: 'b', runId: 1),
        _img(id: 'c'),
      ]);
      expect(groups[0].requestedCount, 2);
      expect(groups[1].requestedCount, 1);
    });
  });

  group('layoutCanvasFeed', () {
    test('组纵向堆叠：组间 50、原点 (0,0)、左对齐', () {
      final g1 = CanvasFeedGroup(
        key: 'run:1',
        runId: 1,
        images: [_img(id: 'a')],
      );
      final g2 = CanvasFeedGroup(
        key: 'run:2',
        runId: 2,
        images: [_img(id: 'b')],
      );
      final items = layoutCanvasFeed([g1, g2]);

      expect(items.length, 2);
      expect(items[0].worldRect.left, 0);
      expect(items[0].worldRect.top, 0);
      expect(
        items[1].worldRect.top,
        1216 + kCanvasGroupSpacing,
      );
      expect(items[1].worldRect.left, 0);
    });

    test('组内子图纵向堆叠间距 40，互不重叠', () {
      final g = CanvasFeedGroup(
        key: 'run:1',
        runId: 1,
        images: [
          _img(id: 'a'),
          _img(id: 'b'),
          _img(id: 'c'),
          _img(id: 'd'),
        ],
      );
      final items = layoutCanvasFeed([g]);
      expect(items.length, 4);
      for (var i = 0; i < 4; i++) {
        expect(items[i].subimageIndex, i);
        if (i > 0) {
          expect(
            items[i].worldRect.top,
            items[i - 1].worldRect.bottom + kCanvasSubimageSpacing,
          );
        }
        for (var j = i + 1; j < 4; j++) {
          expect(
            items[i].worldRect.overlaps(items[j].worldRect),
            false,
            reason: 'tile $i 与 $j 重叠',
          );
        }
      }
    });
  });
}
