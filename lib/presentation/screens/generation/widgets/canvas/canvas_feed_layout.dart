import 'dart:math' as math;
import 'dart:ui';

import '../../../../providers/generation/generation_models.dart';

/// 画布 feed 布局纯函数（对标 NAI5：组竖向堆叠、组内网格、x=0 居中、
/// 新批置顶旧批在下）。
///
/// 世界坐标系：原点在 feed 首组中心上方，组间 340px 间距，
/// 各组以 x=0 水平居中。tile 以自然像素尺寸摆放（生成中槽位按批参数尺寸）。

/// 组内单 tile 的描述符：已完成图（image）或生成中槽位（slot）二选一。
class CanvasTileSpec {
  const CanvasTileSpec.image(GeneratedImage this.image)
    : slot = null,
      width = 0,
      height = 0;

  const CanvasTileSpec.slot(
    StreamPreviewSlot this.slot, {
    required this.width,
    required this.height,
  }) : image = null;

  final GeneratedImage? image;
  final StreamPreviewSlot? slot;

  /// tile 世界尺寸：image 取编码尺寸；slot 取批参数宽高。
  final double width;
  final double height;

  bool get isInFlight => slot != null;

  double get resolvedWidth => image?.width.toDouble() ?? width;
  double get resolvedHeight => image?.height.toDouble() ?? height;

  /// 供选中联动/自动选中定位用：image.id 或 'slot:<imageNumber>'。
  String get stableId => image?.id ?? 'slot:${slot!.imageNumber}';
}

/// 一批图/一个生成中槽位组。
class CanvasGroup {
  const CanvasGroup({required this.key, required this.tiles});

  /// 分组键：'run:<generationRunId>'、'img:<id>'（无 runId 单图）、
  /// 'inflight'（生成中占位组）。
  final String key;
  final List<CanvasTileSpec> tiles;

  bool get isInFlight => key == 'inflight';
}

/// 画布上的已布局图块（世界坐标矩形 + 数据源）。
class CanvasPlacement {
  const CanvasPlacement({
    required this.tile,
    required this.rect,
    required this.group,
    required this.groupRect,
  });

  final CanvasTileSpec tile;
  final Rect rect;
  final CanvasGroup group;
  final Rect groupRect;

  bool get isInFlight => tile.isInFlight;
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
/// 传入顺序即 feed 顺序（调用方保证 新→旧）。
List<CanvasGroup> groupCanvasImages(List<GeneratedImage> images) {
  final groups = <CanvasGroup>[];
  final byRun = <String, CanvasGroup>{};
  for (final image in images) {
    final key = image.generationRunId != null
        ? 'run:${image.generationRunId}'
        : 'img:${image.id}';
    final existing = byRun[key];
    if (existing == null) {
      final group = CanvasGroup(
        key: key,
        tiles: [CanvasTileSpec.image(image)],
      );
      byRun[key] = group;
      groups.add(group);
    } else {
      existing.tiles.add(CanvasTileSpec.image(image));
    }
  }
  // 组内按 batchIndex 稳定排序，缺失按 createdAt
  for (final group in groups) {
    group.tiles.sort((a, b) {
      final ai = a.image?.batchIndex;
      final bi = b.image?.batchIndex;
      if (ai != null && bi != null && ai != bi) return ai.compareTo(bi);
      if (ai != null && bi == null) return -1;
      if (ai == null && bi != null) return 1;
      final at = a.image?.createdAt;
      final bt = b.image?.createdAt;
      if (at != null && bt != null) return at.compareTo(bt);
      return 0;
    });
  }
  return groups;
}

/// 生成中占位组（feed 置顶）：slots 按 imageNumber 升序成 tile。
/// [tileWidth]/[tileHeight] = 批参数宽高（batchWidth/batchHeight）。
CanvasGroup inflightGroup({
  required List<StreamPreviewSlot> slots,
  required double tileWidth,
  required double tileHeight,
}) {
  final sorted = [...slots]
    ..sort((a, b) => a.imageNumber.compareTo(b.imageNumber));
  return CanvasGroup(
    key: 'inflight',
    tiles: [
      for (final slot in sorted)
        CanvasTileSpec.slot(slot, width: tileWidth, height: tileHeight),
    ],
  );
}

/// 计算整个 feed 的世界布局。
///
/// [groups] 按 feed 顺序（索引 0 = 顶端 = 最新批）。
/// [expandedGroupKey] 命中的组内 tile 改单行横排（组展开态：变体横排）；
/// 组高按原网格高保持，避免选中切换时 feed 垂直跳动。
/// 返回 placements（世界坐标）与总内容 bounds。
({List<CanvasPlacement> placements, Rect bounds}) layoutCanvasFeed(
  List<CanvasGroup> groups, {
  double spacing = kCanvasGroupSpacing,
  String? expandedGroupKey,
}) {
  final placements = <CanvasPlacement>[];
  var cursorY = 0.0;
  Rect? bounds;

  for (final group in groups) {
    final tiles = group.tiles;
    if (tiles.isEmpty) continue;

    final (cols, rows) = canvasGridShape(tiles.length);
    // 组内 tile 以各自尺寸排网格；同批图通常同尺寸，
    // 取组内最大 tile 高为行高、最大 tile 宽为列宽。
    var tileW = 0.0;
    var tileH = 0.0;
    for (final t in tiles) {
      tileW = math.max(tileW, t.resolvedWidth);
      tileH = math.max(tileH, t.resolvedHeight);
    }
    const gap = 12.0;

    final expanded = group.key == expandedGroupKey && tiles.length > 1;
    // 展开态：单行横排（cols=count）；收起态按网格。
    final effCols = expanded ? tiles.length : cols;
    final groupW = effCols * tileW + (effCols - 1) * gap;
    // 组高取原网格高（展开态不增组高，tile 在行内居中）
    final groupH = rows * tileH + (rows - 1) * gap;
    final groupLeft = kCanvasFeedCenterX - groupW / 2;
    final groupRect = Rect.fromLTWH(groupLeft, cursorY, groupW, groupH);

    for (var i = 0; i < tiles.length; i++) {
      final col = i % effCols;
      final row = expanded ? 0 : i ~/ effCols;
      final tile = tiles[i];
      final w = tile.resolvedWidth;
      final h = tile.resolvedHeight;
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
          tile: tile,
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
