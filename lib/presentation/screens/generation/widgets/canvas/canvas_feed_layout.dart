import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/image_generation_provider.dart';
import 'generation_canvas_controller.dart';

/// 画布组间距（官网 grid 栈组间 50）
const double kCanvasGroupSpacing = 50;

/// 组内子图纵向间距（官网 subimage stack 40）
const double kCanvasSubimageSpacing = 40;

/// 画布组（G11 V3）：组 = 一次生成请求。
/// 官网真值：一次生成的多变体/多采样共享 groupId；连续单张各自成组。
/// 组内 tile 纵向堆叠、间距 [kCanvasSubimageSpacing]、子图顶边对齐。
class CanvasFeedGroup {
  CanvasFeedGroup({
    required this.key,
    required this.runId,
    required this.images,
    this.requestedCount = 1,
  });

  /// 'run:<id>' 或 'img:<imageId>'
  final String key;
  final int? runId;
  final List<GeneratedImage> images;

  /// 组内张数（无元数据 request 计数，分组后回填 = images.length）
  int requestedCount;
}

/// 布局产物（世界坐标系）
class CanvasFeedItem {
  const CanvasFeedItem({
    required this.group,
    required this.image,
    required this.subimageIndex,
    required this.worldRect,
  });

  final CanvasFeedGroup group;
  final GeneratedImage image;
  final int subimageIndex;
  final Rect worldRect;
}

class CanvasFeedLayoutResult {
  const CanvasFeedLayoutResult({required this.items, required this.groups});

  final List<CanvasFeedItem> items;
  final List<CanvasFeedGroup> groups;
}

/// 归组（纯函数）：generationRunId > 0 → run:<id>；否则 img:<imageId>。
/// 保持传入顺序（mergedPanelImages 新→旧），组内按 batchIndex 升序，
/// 缺失回退 createdAt。
List<CanvasFeedGroup> groupCanvasImages(List<GeneratedImage> images) {
  final groups = <String, CanvasFeedGroup>{};
  final order = <String>[];
  for (final img in images) {
    final runId = img.generationRunId;
    final key =
        (runId != null && runId > 0) ? 'run:$runId' : 'img:${img.id}';
    var g = groups[key];
    if (g == null) {
      g = CanvasFeedGroup(key: key, runId: runId, images: []);
      groups[key] = g;
      order.add(key);
    }
    g.images.add(img);
  }
  for (final g in groups.values) {
    g.images.sort((a, b) {
      final ai = a.batchIndex;
      final bi = b.batchIndex;
      if (ai != null && bi != null) return ai.compareTo(bi);
      if (ai != null) return -1;
      if (bi != null) return 1;
      return a.createdAt.compareTo(b.createdAt);
    });
    g.requestedCount = g.images.length;
  }
  return order.map((k) => groups[k]!).toList();
}

/// 布局（纯函数）：组纵向堆叠、组间 [kCanvasGroupSpacing]、
/// 组内子图顶边对齐纵向排、子图间距 [kCanvasSubimageSpacing]，原点 (0,0)。
List<CanvasFeedItem> layoutCanvasFeed(List<CanvasFeedGroup> groups) {
  final items = <CanvasFeedItem>[];
  var cursorY = 0.0;
  for (final g in groups) {
    var subY = cursorY;
    for (var i = 0; i < g.images.length; i++) {
      final img = g.images[i];
      items.add(
        CanvasFeedItem(
          group: g,
          image: img,
          subimageIndex: i,
          worldRect: Rect.fromLTWH(
            0,
            subY,
            img.width.toDouble(),
            img.height.toDouble(),
          ),
        ),
      );
      subY += img.height + kCanvasSubimageSpacing;
    }
    cursorY = subY - kCanvasSubimageSpacing + kCanvasGroupSpacing;
  }
  return items;
}

/// feed 分组与布局（官网 grid 栈）：合并当前批次+历史、按 runId 分组、纵向堆叠
class CanvasFeedLayoutNotifier extends Notifier<CanvasFeedLayoutResult> {
  static const double groupSpacing = kCanvasGroupSpacing;
  static const double subimageSpacing = kCanvasSubimageSpacing;

  @override
  CanvasFeedLayoutResult build() {
    final state = ref.watch(imageGenerationNotifierProvider);
    final merged = state.mergedPanelImages;
    if (merged.isEmpty) {
      return const CanvasFeedLayoutResult(items: [], groups: []);
    }
    final groups = groupCanvasImages(merged);
    return CanvasFeedLayoutResult(
      items: layoutCanvasFeed(groups),
      groups: groups,
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
