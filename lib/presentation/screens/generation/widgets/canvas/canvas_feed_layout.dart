import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/image_generation_provider.dart';
import 'generation_canvas_controller.dart';

// ── 官网逐字常量（chunk 5285 布局函数对码）──────────────────────────

/// 组间垂直间距（官网 `i += n.height + 340`）。
const double kCanvasGroupSpacing = 340.0;

/// 默认网格行内/行间间隙（官网 row-major 48px）。
const double kCanvasGridGap = 48.0;

/// gridXLength>0（网格生成）列紧凑模式的间隙（官网 24px）。
const double kCanvasGridColumnsGap = 24.0;

/// feed 水平居中轴（官网 `s = -n.width/2`，`0*o` 错动是死代码）。
const double kCanvasFeedCenterX = 0.0;

/// N=3 三角排布的哈希散列偏移表（官网 `mG=[0,2,-1,1,-2]`，仅参与错位，
/// 但 `0*o` 使其实际不生效；保留常量作文档化）。
// const List<int> _kTriStagger = [0, 2, -1, 1, -2]; // 官网死代码，不用

/// 组内单 tile 描述符：已完成图 或 生成中占位槽二选一。
///
/// 官网 dummy 语义：组内每个槽位先渲染 `image-grid-generating` 三点
/// 弹跳占位，`finished` 后换实图。占位 tile 尺寸 = 批参数宽高。
class CanvasTileSpec {
  const CanvasTileSpec.image(GeneratedImage this.image)
    : slot = null,
      slotWidth = 0,
      slotHeight = 0;

  const CanvasTileSpec.slot(
    StreamPreviewSlot this.slot, {
    required this.slotWidth,
    required this.slotHeight,
  }) : image = null;

  final GeneratedImage? image;
  final StreamPreviewSlot? slot;
  final double slotWidth;
  final double slotHeight;

  bool get isInFlight => slot != null;

  /// tile 世界尺寸（官网用编码/批参数自然像素尺寸）。
  double get resolvedWidth => image?.width.toDouble() ?? slotWidth;
  double get resolvedHeight => image?.height.toDouble() ?? slotHeight;

  /// 供选中联动定位用：image.id 或 'slot:<imageNumber>'。
  String get stableId => image?.id ?? 'slot:${slot!.imageNumber}';
}

/// 一批图/一个生成中槽位组。
///
/// - key `run:<generationRunId>`：正常完成批；inflight 批在建组时直接
///   用 `run:<activeRunId>`，完成图与占位共存于一组（官网同组混合渲染）。
/// - key `img:<imageId>`：无 runId 的外部登记图，各自成组。
/// - `deferFocus`：官网真值——组内存在未 finished 图时该组**不参与**
///   自动夺焦/自动飞行（流式开启时除外：官网流式组创建即夺焦）。
class CanvasFeedGroup {
  CanvasFeedGroup({
    required this.key,
    required this.runId,
    required this.tiles,
    this.deferFocus = false,
    this.requestedCount = 1,
  });

  final String key;
  final int? runId;
  final List<CanvasTileSpec> tiles;

  /// 官网 deferFocus：含未完成槽位的组不自动夺焦。
  bool deferFocus;

  /// 组内张数（完成图数量；占位不计入）。
  int requestedCount;

  /// 兼容旧代码访问：组内已完成图（占位槽剔除）。
  List<GeneratedImage> get images => [
    for (final t in tiles)
      if (t.image != null) t.image!,
  ];

  bool get isInFlight => deferFocus && tiles.any((t) => t.isInFlight);
}

/// 已布局 tile（世界坐标）。
class CanvasFeedItem {
  const CanvasFeedItem({
    required this.group,
    required this.tile,
    required this.subimageIndex,
    required this.worldRect,
    required this.groupRect,
  });

  final CanvasFeedGroup group;
  final CanvasTileSpec tile;
  final int subimageIndex;
  final Rect worldRect;
  final Rect groupRect;

  /// 兼容旧代码：完成图引用（占位槽为 null，调用方需判空）。
  GeneratedImage? get image => tile.image;

  bool get isInFlight => tile.isInFlight;
}

class CanvasFeedLayoutResult {
  const CanvasFeedLayoutResult({
    required this.items,
    required this.groups,
    required this.bounds,
  });

  final List<CanvasFeedItem> items;
  final List<CanvasFeedGroup> groups;

  /// 世界内容包围盒（官网 bounds.height = cursorY-340 截尾距）。
  final Rect bounds;
}

// ── 官网 FNV-1a 32bit 哈希（mX/mJ 同式）─────────────────────────────
int _fnv1a32(String s) {
  var h = 0x811c9dc5;
  for (var i = 0; i < s.length; i++) {
    h ^= s.codeUnitAt(i);
    h = (h * 0x1000193) & 0xFFFFFFFF; // Math.imul 低 32 位
  }
  return h;
}

double _fnvUnit(String s) => _fnv1a32(s) / 0x100000000;

// ── 组内布局（官网逐字）────────────────────────────────────────────

class _TileSize {
  const _TileSize(this.width, this.height);
  final double width;
  final double height;
}

class _GroupLayout {
  const _GroupLayout({required this.rects, required this.size});
  final List<Rect> rects;
  final Size size;
}

/// 官网 mY：纵向三角——`flip` true=[单上,双下]，false=[双上,单下]。
_GroupLayout _triVertical(List<_TileSize> t, bool flip) {
  final single = flip ? t[0] : t[2];
  final pair = flip ? [t[1], t[2]] : [t[0], t[1]];
  final pairW = pair[0].width + kCanvasGridGap + pair[1].width;
  final totalW = math.max(pairW, single.width);
  final singleX = (totalW - single.width) / 2;
  final pairX = (totalW - pairW) / 2;
  final pairY = flip ? single.height + kCanvasGridGap : 0.0;
  final pairH = math.max(pair[0].height, pair[1].height);
  final singleY = flip ? 0.0 : pairH + kCanvasGridGap;
  return _GroupLayout(
    rects: flip
        ? [
            Rect.fromLTWH(singleX, singleY, single.width, single.height),
            Rect.fromLTWH(pairX, pairY, pair[0].width, pair[0].height),
            Rect.fromLTWH(
              pairX + pair[0].width + kCanvasGridGap,
              pairY,
              pair[1].width,
              pair[1].height,
            ),
          ]
        : [
            Rect.fromLTWH(pairX, pairY, pair[0].width, pair[0].height),
            Rect.fromLTWH(
              pairX + pair[0].width + kCanvasGridGap,
              pairY,
              pair[1].width,
              pair[1].height,
            ),
            Rect.fromLTWH(singleX, singleY, single.width, single.height),
          ],
    size: Size(totalW, pairH + kCanvasGridGap + single.height),
  );
}

/// 官网 mQ：横向三角——`flip` true=[左单,右双]，false=[左双,右单]。
_GroupLayout _triHorizontal(List<_TileSize> t, bool flip) {
  final single = flip ? t[0] : t[2];
  final pair = flip ? [t[1], t[2]] : [t[0], t[1]];
  final pairH = pair[0].height + kCanvasGridGap + pair[1].height;
  final pairW = math.max(pair[0].width, pair[1].width);
  final totalH = math.max(pairH, single.height);
  final totalW = single.width + kCanvasGridGap + pairW;
  final singleX = flip ? 0.0 : pairW + kCanvasGridGap;
  final pairX = flip ? single.width + kCanvasGridGap : 0.0;
  final pairY = (totalH - pairH) / 2;
  final singleY = (totalH - single.height) / 2;
  return _GroupLayout(
    rects: flip
        ? [
            Rect.fromLTWH(singleX, singleY, single.width, single.height),
            Rect.fromLTWH(pairX, pairY, pair[0].width, pair[0].height),
            Rect.fromLTWH(
              pairX,
              pairY + pair[0].height + kCanvasGridGap,
              pair[1].width,
              pair[1].height,
            ),
          ]
        : [
            Rect.fromLTWH(
              pairX + (pairW - pair[0].width) / 2,
              pairY,
              pair[0].width,
              pair[0].height,
            ),
            Rect.fromLTWH(
              pairX + (pairW - pair[1].width) / 2,
              pairY + pair[0].height + kCanvasGridGap,
              pair[1].width,
              pair[1].height,
            ),
            Rect.fromLTWH(singleX, singleY, single.width, single.height),
          ],
    size: Size(totalW, totalH),
  );
}

/// 官网 gridXLength>0 列紧凑模式：固定列数、列内逐张堆叠、24px 间隙、
/// 列内水平居中；返回 (rects, size)。
_GroupLayout _columnsLayout(List<_TileSize> tiles, int columns) {
  final cols = List.generate(columns, (_) => <Rect>[]);
  final colWidths = List.filled(columns, 0.0);
  final colHeights = List.filled(columns, 0.0);
  for (var i = 0; i < tiles.length; i++) {
    final c = i % columns;
    final t = tiles[i];
    colWidths[c] = math.max(colWidths[c], t.width);
  }
  // 先算列 x 偏移
  final colX = List.filled(columns, 0.0);
  var x = 0.0;
  for (var c = 0; c < columns; c++) {
    colX[c] = x;
    x += colWidths[c] + kCanvasGridColumnsGap;
  }
  final totalW = x - kCanvasGridColumnsGap;
  var maxH = 0.0;
  for (var i = 0; i < tiles.length; i++) {
    final c = i % columns;
    final t = tiles[i];
    final rect = Rect.fromLTWH(
      colX[c] + (colWidths[c] - t.width) / 2,
      colHeights[c],
      t.width,
      t.height,
    );
    cols[c].add(rect);
    colHeights[c] += t.height + kCanvasGridColumnsGap;
    maxH = math.max(maxH, colHeights[c]);
  }
  return _GroupLayout(
    rects: [for (final col in cols) ...col],
    size: Size(totalW, maxH - kCanvasGridColumnsGap),
  );
}

/// 组内布局分派（官网逐字）：gridColumns>0 走列紧凑；3 张走哈希三角；
/// 其余走 ceil(sqrt) 行主网格（48px）。
_GroupLayout _layoutGroupTiles(
  List<_TileSize> tiles,
  String groupId,
  int? gridColumns,
) {
  if (gridColumns != null && gridColumns > 0 && tiles.isNotEmpty) {
    return _columnsLayout(tiles, gridColumns.clamp(1, tiles.length));
  }
  if (tiles.length == 3) {
    switch ((4 * _fnvUnit('$groupId:tri')).floor()) {
      case 0:
        return _triVertical(tiles, true);
      case 1:
        return _triVertical(tiles, false);
      case 2:
        return _triHorizontal(tiles, true);
      default:
        return _triHorizontal(tiles, false);
    }
  }
  // 默认近方阵：ceil(sqrt(N)) 列，row-major，48px，行内不居中
  final cols = math.max(1, math.sqrt(tiles.length).ceil());
  final rects = <Rect>[];
  var x = 0.0, y = 0.0, rowH = 0.0, maxW = 0.0;
  for (var i = 0; i < tiles.length; i++) {
    if (i > 0 && i % cols == 0) {
      y += rowH + kCanvasGridGap;
      x = 0;
      rowH = 0;
    }
    final t = tiles[i];
    rects.add(Rect.fromLTWH(x, y, t.width, t.height));
    x += t.width + kCanvasGridGap;
    rowH = math.max(rowH, t.height);
    maxW = math.max(maxW, x - kCanvasGridGap);
  }
  return _GroupLayout(rects: rects, size: Size(maxW, y + rowH));
}

// ── 归组 ──────────────────────────────────────────────────────────

/// 归组（纯函数）：generationRunId > 0 → run:<id>；否则 img:<imageId>。
/// 兜底：无 runId 的相邻图若宽高/种子一致且 createdAt 相差 ≤120s，
/// 视为同批并入上一组（覆盖外部登记/桥接等漏打 runId 的路径）。
/// 保持传入顺序（mergedPanelImages 新→旧），组内按 batchIndex 升序，
/// 缺失回退 createdAt。
List<CanvasFeedGroup> groupCanvasImages(List<GeneratedImage> images) {
  final groups = <String, CanvasFeedGroup>{};
  final order = <String>[];
  CanvasFeedGroup? lastGroup;
  for (final img in images) {
    final runId = img.generationRunId;
    var key = (runId != null && runId > 0) ? 'run:$runId' : 'img:${img.id}';
    // 无 runId 兜底：与相邻前一组同尺寸且时间接近 → 归同组
    if (runId == null || runId <= 0) {
      final prev = lastGroup;
      final prevImg = prev?.images.firstOrNull;
      if (prev != null &&
          prev.runId == null &&
          prevImg != null &&
          prevImg.width == img.width &&
          prevImg.height == img.height &&
          prevImg.createdAt.difference(img.createdAt).abs().inSeconds <= 120) {
        key = prev.key;
      }
    }
    var g = groups[key];
    if (g == null) {
      g = CanvasFeedGroup(key: key, runId: runId, tiles: []);
      groups[key] = g;
      order.add(key);
    }
    g.tiles.add(CanvasTileSpec.image(img));
    lastGroup = g;
  }
  for (final g in groups.values) {
    g.tiles.sort((a, b) {
      final ai = a.image?.batchIndex;
      final bi = b.image?.batchIndex;
      if (ai != null && bi != null) return ai.compareTo(bi);
      if (ai != null) return -1;
      if (bi != null) return 1;
      final at = a.image?.createdAt;
      final bt = b.image?.createdAt;
      if (at != null && bt != null) return at.compareTo(bt);
      return 0;
    });
    g.requestedCount = g.images.length;
  }
  return order.map((k) => groups[k]!).toList();
}

/// 生成中占位组（feed 置顶）：slots 按 imageNumber 升序成 tile。
///
/// 官网语义：组内完成图与未完成槽位同组混合；占位槽渲染
/// `image-grid-generating` 三点弹跳动画。`runKey` 用当前 runId 使
/// inflight 组与完成后 run:<id> 组无缝衔接。
CanvasFeedGroup inflightGroup({
  required String runKey,
  required List<StreamPreviewSlot> slots,
  required double tileWidth,
  required double tileHeight,
  required List<GeneratedImage> doneImages,
}) {
  final sorted = [...slots]
    ..sort((a, b) => a.imageNumber.compareTo(b.imageNumber));
  // 槽位映射到批内序号（1-based imageNumber → 0-based tile index）
  final tiles = <CanvasTileSpec>[];
  for (final slot in sorted) {
    final doneIdx = slot.imageNumber - 1;
    if (doneIdx >= 0 && doneIdx < doneImages.length) {
      // 该槽位已完成 → 用实图占位（官网 finished 语义）
      tiles.add(CanvasTileSpec.image(doneImages[doneIdx]));
    } else {
      tiles.add(
        CanvasTileSpec.slot(slot, slotWidth: tileWidth, slotHeight: tileHeight),
      );
    }
  }
  // 完成图多于槽位（边界情形）→ 补在尾部
  for (var i = sorted.length; i < doneImages.length; i++) {
    tiles.add(CanvasTileSpec.image(doneImages[i]));
  }
  return CanvasFeedGroup(
    key: runKey,
    runId: null,
    tiles: tiles,
    deferFocus: true,
  )..requestedCount = tiles.length;
}

// ── feed 布局（官网逐字）──────────────────────────────────────────

/// 计算整个 feed 的世界布局（官网逐字）：
/// 组纵向堆叠、组间 [kCanvasGroupSpacing]=340、组水平居中于 x=0、
/// 组内按 gridXLength/三角/近方阵规则排列。
({List<CanvasFeedItem> items, Rect bounds}) layoutCanvasFeed(
  List<CanvasFeedGroup> groups,
) {
  final items = <CanvasFeedItem>[];
  var cursorY = 0.0;
  double? minX, maxX;
  final groupRects = <String, Rect>{};

  for (final group in groups) {
    if (group.tiles.isEmpty) continue;
    final sizes = [
      for (final t in group.tiles)
        _TileSize(t.resolvedWidth, t.resolvedHeight),
    ];
    // gridXLength 由首图带出（官网 images[0].gridXLength）；本项目无网格
    // 生成入口，恒 null → 走三角/近方阵。
    final layout = _layoutGroupTiles(sizes, group.key, null);
    // 官网 s = -n.width/2 + 0*o：水平居中（错动死代码）
    final left = kCanvasFeedCenterX - layout.size.width / 2;
    final groupRect = Rect.fromLTWH(
      left,
      cursorY,
      layout.size.width,
      layout.size.height,
    );
    groupRects[group.key] = groupRect;
    for (var i = 0; i < group.tiles.length; i++) {
      final r = layout.rects[i];
      items.add(
        CanvasFeedItem(
          group: group,
          tile: group.tiles[i],
          subimageIndex: i,
          worldRect: r.translate(left, cursorY),
          groupRect: groupRect,
        ),
      );
    }
    minX = minX == null ? left : math.min(minX, left);
    maxX = math.max(maxX ?? 0, left + layout.size.width);
    cursorY += layout.size.height + kCanvasGroupSpacing;
  }

  final bounds = groupRects.isEmpty
      ? Rect.zero
      : Rect.fromLTRB(
          minX ?? 0,
          0,
          maxX ?? 0,
          cursorY - kCanvasGroupSpacing, // 官网 height = i-340 截尾距
        );
  return (items: items, bounds: bounds);
}

// ── Provider ──────────────────────────────────────────────────────

/// feed 分组与布局（官网 grid 栈）：current+history 去重按 runId 归组；
/// 生成中 inflight 组置顶（deferFocus：未完成槽位组不自动夺焦）。
class CanvasFeedLayoutNotifier extends Notifier<CanvasFeedLayoutResult> {
  @override
  CanvasFeedLayoutResult build() {
    final state = ref.watch(imageGenerationNotifierProvider);
    final done = state.currentImages;
    final doneIds = {for (final img in done) img.id};
    // 生成期：本批已完成图归 inflight 组统一渲染（与未完成槽位同组），
    // 不再重复进 run:<id> 组——官网是同组混合。
    final merged = [
      for (final img in state.mergedPanelImages)
        if (!state.isGenerating || !doneIds.contains(img.id)) img,
    ];
    final groups = groupCanvasImages(merged);

    // inflight 组置顶（官网 deferFocus 门控——含未完成槽位的组不自动
    // 夺焦不自动飞）。槽位 = totalImages 全槽：已完成的渲染实图，未
    // 完成的渲染三点占位（有流式槽时带进度帧）。
    if (state.isGenerating) {
      final bw = state.batchWidth;
      final bh = state.batchHeight;
      final total = math.max(state.totalImages, done.length);
      if (bw != null && bh != null && bw > 0 && bh > 0 && total > 0) {
        final slotByNumber = {
          for (final s in state.streamPreviewSlots) s.imageNumber: s,
        };
        final slots = [
          for (var n = 1; n <= total; n++)
            slotByNumber[n] ??
                StreamPreviewSlot(
                  imageNumber: n,
                  totalImages: total,
                  progress: 0.0,
                ),
        ];
        groups.insert(
          0,
          inflightGroup(
            runKey: 'inflight',
            slots: slots,
            tileWidth: bw.toDouble(),
            tileHeight: bh.toDouble(),
            doneImages: done,
          ),
        );
      }
    }

    final laid = layoutCanvasFeed(groups);
    return CanvasFeedLayoutResult(
      items: laid.items,
      groups: groups,
      bounds: laid.bounds,
    );
  }
}

final canvasFeedLayoutProvider =
    NotifierProvider<CanvasFeedLayoutNotifier, CanvasFeedLayoutResult>(
      CanvasFeedLayoutNotifier.new,
    );

/// 画布相机 Provider（Notifier 持有动画控制器与惯性）
final generationCanvasCameraProvider =
    NotifierProvider<GenerationCanvasCameraNotifier, CanvasCamera>(
      GenerationCanvasCameraNotifier.new,
    );
