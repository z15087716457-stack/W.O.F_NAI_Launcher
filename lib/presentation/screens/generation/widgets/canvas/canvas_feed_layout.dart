import 'dart:math' as math;
import 'dart:ui';

import '../../../../providers/generation/generation_models.dart';

/// 画布 feed 布局纯函数（对标 NAI5：组竖向堆叠、组内网格、x=0 居中）。
///
/// 世界坐标系：原点在 feed 首组中心上方，组间 340px 间距，
/// 各组以 x=0 水平居中。tile 以自然像素尺寸摆放。
class CanvasGroup {
  const CanvasGroup({required this.key, required this.images});

  /// 分组键（generationRunId 或 'img:<id>' 单图组）。
  final String key;
  final List<GeneratedImage> images;
}

/// 画布上的已布局图块（世界坐标矩形 + 数据源）。
class CanvasPlacement {
  const CanvasPlacement({
    required this.image,
    required this.rect,
    required this.group,
    required this.groupRect,
  });

  final GeneratedImage image;
  final Rect rect;
  final CanvasGroup group;
  final Rect groupRect;
}

/// 组间垂直间距（世界像素，官网 340）。
const double kCanvasGroupSpacing = 340.0;

/// feed 水平居中轴（x=0）。
const double kCanvasFeedCenterX = 0.0;

/// 组内网格排布：穷举 columns×rows 使 c*r>=count 且余量≤1，
/// 按与参考宽高比（feed 宽/视口高近似取 16/10）分差最小取胜。
/// 返回值 (columns, rows)。
(int, int) canvasGridShape(int count, {double aspect = 1.6}) {
  if (count <= 1) return (1, 1);
  (int, int) best = (count, 1);
  var bestScore = double.infinity;
  for (var cols = 1; cols <= count; cols++) {
    final rows = (count + cols - 1) ~/ cols;
    if (cols * rows - count > 1) continue; // 余量≤1
    // 网格整体宽高比 = cols/rows（tile 同尺寸时），与 aspect 求分差
    final score = ((cols / rows) - aspect).abs() + (cols * rows - count) * 0.5;
    if (score < bestScore) {
      bestScore = score;
      best = (cols, rows);
    }
  }
  return best;
}

/// 把图像列表按批分组：generationRunId 相同为一组；
/// 无 runId（外部登记/旧数据）按 id 各自成组。
/// 传入顺序即 feed 顺序（调用方保证 新→旧 或 旧→新，由 feedDirection 解释）。
List<CanvasGroup> groupCanvasImages(List<GeneratedImage> images) {
  final groups = <CanvasGroup>[];
  final byRun = <String, CanvasGroup>{};
  for (final image in images) {
    final key = image.generationRunId != null
        ? 'run:${image.generationRunId}'
        : 'img:${image.id}';
    final existing = byRun[key];
    if (existing == null) {
      final group = CanvasGroup(key: key, images: [image]);
      byRun[key] = group;
      groups.add(group);
    } else {
      existing.images.add(image);
    }
  }
  // 组内按 batchIndex 稳定排序，缺失按 createdAt
  for (final group in groups) {
    group.images.sort((a, b) {
      final ai = a.batchIndex;
      final bi = b.batchIndex;
      if (ai != null && bi != null && ai != bi) return ai.compareTo(bi);
      if (ai != null && bi == null) return -1;
      if (ai == null && bi != null) return 1;
      return a.createdAt.compareTo(b.createdAt);
    });
  }
  return groups;
}

/// 计算整个 feed 的世界布局。
///
/// [groups] 按 feed 顺序（索引 0 = 最顶端 = 最旧）。
/// 返回 placements（世界坐标）与总内容 bounds。
({List<CanvasPlacement> placements, Rect bounds}) layoutCanvasFeed(
  List<CanvasGroup> groups, {
  double spacing = kCanvasGroupSpacing,
}) {
  final placements = <CanvasPlacement>[];
  var cursorY = 0.0;
  Rect? bounds;

  for (final group in groups) {
    final images = group.images;
    if (images.isEmpty) continue;

    final (cols, rows) = canvasGridShape(images.length);
    // 组内 tile 以各自自然像素尺寸排网格；同批图通常同尺寸，
    // 取组内最大 tile 高为行高、最大 tile 宽为列宽。
    var tileW = 0.0;
    var tileH = 0.0;
    for (final img in images) {
      tileW = math.max(tileW, img.width.toDouble());
      tileH = math.max(tileH, img.height.toDouble());
    }
    const gap = 12.0;
    final groupW = cols * tileW + (cols - 1) * gap;
    final groupH = rows * tileH + (rows - 1) * gap;
    final groupLeft = kCanvasFeedCenterX - groupW / 2;
    final groupRect = Rect.fromLTWH(groupLeft, cursorY, groupW, groupH);

    for (var i = 0; i < images.length; i++) {
      final col = i % cols;
      final row = i ~/ cols;
      final img = images[i];
      final w = img.width.toDouble();
      final h = img.height.toDouble();
      // tile 在格内居中（组内尺寸不一致时）
      final cellLeft = groupLeft + col * (tileW + gap);
      final cellTop = cursorY + row * (tileH + gap);
      final rect = Rect.fromLTWH(
        cellLeft + (tileW - w) / 2,
        cellTop + (tileH - h) / 2,
        w,
        h,
      );
      placements.add(
        CanvasPlacement(
          image: img,
          rect: rect,
          group: group,
          groupRect: groupRect,
        ),
      );
    }

    bounds = bounds == null ? groupRect : bounds.expandToInclude(groupRect);
    cursorY += groupH + spacing;
  }

  return (placements: placements, bounds: bounds ?? Rect.zero);
}
