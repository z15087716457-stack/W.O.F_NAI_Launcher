import 'package:flutter/foundation.dart';

import '../../../core/constants/api_constants.dart';

/// 本地画廊的 NAI 模型版本分组（筛选条与卡片版本标签共用）。
abstract final class GalleryNaiVersions {
  /// 筛选条展示顺序
  static const List<String> labels = ['3', '4', '4.5', '5'];

  /// 版本 → 该版本包含的模型 ID（含 inpainting 变体；V3 只列基础模型）
  static const Map<String, List<String>> modelIds = {
    '3': [
      ImageModels.animeFull,
      ImageModels.animeV2,
      ImageModels.animeDiffusionV3,
      ImageModels.furryDiffusionV3,
    ],
    '4': [
      ImageModels.animeDiffusionV4Full,
      ImageModels.animeDiffusionV4Curated,
      ImageModels.animeDiffusionV4FullInpainting,
      ImageModels.animeDiffusionV4CuratedInpainting,
    ],
    '4.5': [
      ImageModels.animeDiffusionV45Full,
      ImageModels.animeDiffusionV45Curated,
      ImageModels.animeDiffusionV45FullInpainting,
      ImageModels.animeDiffusionV45CuratedInpainting,
    ],
    '5': [
      ImageModels.animeDiffusionV5Full,
      ImageModels.animeDiffusionV5Curated,
      ImageModels.animeDiffusionV5FullInpainting,
      ImageModels.animeDiffusionV5CuratedInpainting,
    ],
  };

  /// 版本 → Full 变体子集（V3 无变体之分）
  static const Map<String, List<String>> fullIds = {
    '4': [
      ImageModels.animeDiffusionV4Full,
      ImageModels.animeDiffusionV4FullInpainting,
    ],
    '4.5': [
      ImageModels.animeDiffusionV45Full,
      ImageModels.animeDiffusionV45FullInpainting,
    ],
    '5': [
      ImageModels.animeDiffusionV5Full,
      ImageModels.animeDiffusionV5FullInpainting,
    ],
  };

  /// 版本 → Curated 变体子集
  static const Map<String, List<String>> curatedIds = {
    '4': [
      ImageModels.animeDiffusionV4Curated,
      ImageModels.animeDiffusionV4CuratedInpainting,
    ],
    '4.5': [
      ImageModels.animeDiffusionV45Curated,
      ImageModels.animeDiffusionV45CuratedInpainting,
    ],
    '5': [
      ImageModels.animeDiffusionV5Curated,
      ImageModels.animeDiffusionV5CuratedInpainting,
    ],
  };

  /// 当前模型筛选命中的版本与变体（'F' / 'C'；全部变体为 null）。
  static ({String version, String? variant})? match(List<String> models) {
    if (models.isEmpty) return null;
    final current = models.toSet();
    for (final version in labels) {
      if (setEquals(current, modelIds[version]!.toSet())) {
        return (version: version, variant: null);
      }
    }
    for (final version in labels) {
      final full = fullIds[version];
      if (full != null && setEquals(current, full.toSet())) {
        return (version: version, variant: 'F');
      }
      final curated = curatedIds[version];
      if (curated != null && setEquals(current, curated.toSet())) {
        return (version: version, variant: 'C');
      }
    }
    return null;
  }

  /// 模型 ID → 卡片版本标签（如 V4.5）；非 NAI 或未知返回 null。
  static String? labelForModel(String? model) {
    if (model == null || model.isEmpty) return null;
    for (final version in labels) {
      if (modelIds[version]!.contains(model)) return 'V$version';
    }
    return null;
  }
}
