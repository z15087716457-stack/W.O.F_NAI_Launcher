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
    test('逐张展示沿用批内排序，纵向排列且不改真实批次', () {
      final second = _img(id: 'second', runId: 3, batchIndex: 1);
      final first = _img(id: 'first', runId: 3, batchIndex: 0);
      final groups = groupCanvasImages([second, first], singleImages: true);
      expect(groups.map((group) => group.key), ['img:first', 'img:second']);
      expect(groups.map((group) => group.images.single), [first, second]);
      expect(groups.every((group) => group.requestedCount == 1), isTrue);
      final items = layoutCanvasFeed(groups).items;
      expect(items[0].worldRect.center.dx, items[1].worldRect.center.dx);
      expect(
        items[1].worldRect.top - items[0].worldRect.bottom,
        kCanvasGroupSpacing,
      );
      expect(first.generationRunId, 3);
      expect(second.generationRunId, 3);
      expect(groupCanvasImages([second, first]).single.tiles, hasLength(2));
    });

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
        _img(id: 'c', runId: 1, createdAt: t.add(const Duration(seconds: 1))),
      ];
      final groups = groupCanvasImages(images);
      expect(groups[0].images.map((e) => e.id), ['b', 'a', 'c']);
    });

    test('保持传入的组顺序（mergedPanelImages 新→旧）', () {
      final images = [_img(id: 'new', runId: 9), _img(id: 'old', runId: 1)];
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

  group('layoutCanvasFeed（官网逐字）', () {
    test('组纵向堆叠：组间 340、单图组水平居中于 x=0', () {
      final g1 = CanvasFeedGroup(
        key: 'run:1',
        runId: 1,
        tiles: [CanvasTileSpec.image(_img(id: 'a'))],
      );
      final g2 = CanvasFeedGroup(
        key: 'run:2',
        runId: 2,
        tiles: [CanvasTileSpec.image(_img(id: 'b'))],
      );
      final result = layoutCanvasFeed([g1, g2]);
      final items = result.items;

      expect(items.length, 2);
      // 单图 832 宽 → 居中 x=-416
      expect(items[0].worldRect.left, -416);
      expect(items[0].worldRect.top, 0);
      expect(items[1].worldRect.top, 1216 + kCanvasGroupSpacing);
      expect(items[1].worldRect.left, -416);
      // 官网 bounds.height = cursorY-340（i 含尾随 340）：
      // (1216+340)+(1216+340)-340 = 2772
      expect(result.bounds.height, 2772);
    });

    test('4 张走 ceil(sqrt(4))=2 列近方阵，行/列 48px 间隙，互不重叠', () {
      final g = CanvasFeedGroup(
        key: 'run:1',
        runId: 1,
        tiles: [
          CanvasTileSpec.image(_img(id: 'a')),
          CanvasTileSpec.image(_img(id: 'b')),
          CanvasTileSpec.image(_img(id: 'c')),
          CanvasTileSpec.image(_img(id: 'd')),
        ],
      );
      final items = layoutCanvasFeed([g]).items;
      expect(items.length, 4);
      for (var i = 0; i < 4; i++) {
        expect(items[i].subimageIndex, i);
        for (var j = i + 1; j < 4; j++) {
          expect(
            items[i].worldRect.overlaps(items[j].worldRect),
            false,
            reason: 'tile $i 与 $j 重叠',
          );
        }
      }
      // 2×2：a,b 同排（top=0），c,d 第二排 top=1216+48
      expect(items[0].worldRect.top, 0);
      expect(items[1].worldRect.top, 0);
      expect(items[2].worldRect.top, 1216 + kCanvasGridGap);
      // b 的 left = a.right + 48（组内坐标系，组整体居中）
      expect(
        items[1].worldRect.left - items[0].worldRect.right,
        kCanvasGridGap,
      );
    });

    test('3 张走哈希三角：同 id 结果确定、无重叠', () {
      CanvasFeedGroup make() => CanvasFeedGroup(
        key: 'run:7',
        runId: 7,
        tiles: [
          CanvasTileSpec.image(_img(id: 'a')),
          CanvasTileSpec.image(_img(id: 'b')),
          CanvasTileSpec.image(_img(id: 'c')),
        ],
      );
      final items1 = layoutCanvasFeed([make()]).items;
      final items2 = layoutCanvasFeed([make()]).items;
      // 确定性：同 key 两次布局一致
      for (var i = 0; i < 3; i++) {
        expect(items1[i].worldRect, items2[i].worldRect);
        for (var j = i + 1; j < 3; j++) {
          expect(items1[i].worldRect.overlaps(items1[j].worldRect), false);
        }
      }
    });
  });
}
