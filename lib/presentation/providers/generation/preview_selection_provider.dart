import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../history_click_behavior_provider.dart';
import '../image_generation_provider.dart';

part 'preview_selection_provider.g.dart';

@Riverpod(keepAlive: true)
class GenerationPreviewSelection extends _$GenerationPreviewSelection {
  @override
  String? build() {
    ref.listen(imageGenerationNotifierProvider, (previous, next) {
      if (previous?.status != GenerationStatus.generating &&
          next.status == GenerationStatus.generating) {
        state = null;
      }
    });
    ref.listen(historyClickBehaviorNotifierProvider, (previous, next) {
      if (next == HistoryClickBehavior.openDetail) state = null;
    });
    return null;
  }

  void select(String imageId) => state = imageId;

  void clear() => state = null;

  void selectNext() => _move(1);

  void selectPrevious() => _move(-1);

  void _move(int delta) {
    final images = ref.read(imageGenerationNotifierProvider).mergedPanelImages;
    if (images.isEmpty) return;
    if (state == null) {
      state = images.first.id;
      return;
    }

    final currentIndex = images.indexWhere((image) => image.id == state);
    if (currentIndex < 0) {
      state = images.first.id;
      return;
    }
    final targetIndex = (currentIndex + delta).clamp(0, images.length - 1);
    state = images[targetIndex].id;
  }
}

@Riverpod(keepAlive: true)
FocusNode generationPreviewFocusNode(Ref ref) {
  final node = FocusNode(debugLabel: 'generation-preview');
  ref.onDispose(node.dispose);
  return node;
}

/// 画布组级选中（G11 V3）：官网真值 {group, subimage, variation}。
///
/// - group: 'run:<generationRunId>' 或 'img:<imageId>'（无 runId 单图组）
/// - subimage: 组内焦点图索引；null=整组焦点（展开态）
/// - variation: 多变体索引（GeneratedImage.data 变体槽；本工程多为 0）
///
/// 对标官网「自动选图=选中 tile 所属组 + 点击夺焦 subimage + 再点展开组」，
/// 工具条/展开态/q 跳组都以此驱动。
class CanvasFocus {
  const CanvasFocus({required this.group, this.subimage, this.variation = 0});

  final String group;
  final int? subimage;
  final int variation;

  CanvasFocus copyWith({
    String? group,
    int? Function()? subimage,
    int? variation,
  }) {
    return CanvasFocus(
      group: group ?? this.group,
      subimage: subimage != null ? subimage() : this.subimage,
      variation: variation ?? this.variation,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CanvasFocus &&
          other.group == group &&
          other.subimage == subimage &&
          other.variation == variation;

  @override
  int get hashCode => Object.hash(group, subimage, variation);
}

@Riverpod(keepAlive: true)
class GenerationCanvasGroupSelection
    extends _$GenerationCanvasGroupSelection {
  @override
  CanvasFocus? build() => null;

  /// 夺焦到组（subimage=null = 整组展开态入口）
  void selectGroup(String groupKey) =>
      state = CanvasFocus(group: groupKey);

  /// 夺焦到组内某图（subimage=组内索引）
  void selectTile(String groupKey, int subimage, {int variation = 0}) =>
      state = CanvasFocus(group: groupKey, subimage: subimage, variation: variation);

  /// 在焦点组内切换 subimage（官网 subimage 点击/箭头逻辑）
  void setSubimage(int? subimage) {
    final s = state;
    if (s == null) return;
    state = s.copyWith(subimage: () => subimage);
  }

  void setVariation(int variation) {
    final s = state;
    if (s == null) return;
    state = s.copyWith(variation: variation);
  }

  void clear() => state = null;
}
