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

    test('保持传入的组顺序（feed 顺序）', () {
      final images = [
        _img(id: 'new', runId: 9),
        _img(id: 'old', runId: 1),
      ];
      final groups = groupCanvasImages(images);
      expect(groups.map((g) => g.key), ['run:9', 'run:1']);
    });
  });

  group('canvasGridShape', () {
    test('1 图单格', () => expect(canvasGridShape(1), (1, 1)));
    test('4 图 2x2', () => expect(canvasGridShape(4), (2, 2)));
    test('8 图 4x2（宽高比接近 1.6）', () => expect(canvasGridShape(8), (4, 2)));
    test('网格容量 >= 数量且余量 <= 1', () {
      for (var n = 1; n <= 16; n++) {
        final (c, r) = canvasGridShape(n);
        expect(c * r, greaterThanOrEqualTo(n), reason: 'n=$n');
        expect(c * r - n, lessThanOrEqualTo(1), reason: 'n=$n');
      }
    });
  });

  group('layoutCanvasFeed', () {
    test('组竖向堆叠间距 340，x=0 居中', () {
      final g1 = CanvasGroup(key: 'run:1', images: [_img(id: 'a')]);
      final g2 = CanvasGroup(key: 'run:2', images: [_img(id: 'b')]);
      final result = layoutCanvasFeed([g1, g2]);

      expect(result.placements.length, 2);
      final p1 = result.placements[0];
      final p2 = result.placements[1];

      // 单图组：组 rect 即 tile rect，水平居中于 x=0
      expect(p1.rect.left, -832 / 2);
      expect(p1.rect.top, 0);
      expect(p2.rect.top, 1216 + kCanvasGroupSpacing);
      expect(p2.rect.left, -832 / 2);
      expect(result.bounds.height, greaterThan(1216 * 2));
    });

    test('组内网格 tile 各自世界矩形且不重叠', () {
      final g = CanvasGroup(
        key: 'run:1',
        images: [
          _img(id: 'a'),
          _img(id: 'b'),
          _img(id: 'c'),
          _img(id: 'd'),
        ],
      );
      final result = layoutCanvasFeed([g]);
      expect(result.placements.length, 4);
      for (var i = 0; i < 4; i++) {
        for (var j = i + 1; j < 4; j++) {
          expect(
            result.placements[i].rect.overlaps(result.placements[j].rect),
            false,
            reason: 'tile $i 与 $j 重叠',
          );
        }
      }
      // 2x2 组整体居中
      final groupRect = result.placements.first.groupRect;
      expect(groupRect.center.dx, 0);
    });
  });
}
