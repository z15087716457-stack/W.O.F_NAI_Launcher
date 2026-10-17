import 'package:nai_launcher/l10n/app_localizations.dart';

import 'api_constants.dart';

/// 模型下拉分组（官网式：NEW / LEGACY 两段）
enum ModelListGroup { newer, legacy }

/// 单个模型在下拉卡式菜单中的展示信息。
class ModelDisplayInfo {
  const ModelDisplayInfo({
    required this.id,
    required this.shortName,
    required this.group,

    /// 是否带 NEW 角标（官网仅最新 Curated 模型有）
    this.isNew = false,
  });

  final String id;
  final String shortName;
  final ModelListGroup group;
  final bool isNew;
}

/// 官网式模型显示层。
///
/// `shortName` = 胶囊上的缩写名（对齐官网 `V5 Full` 样式）；
/// 下拉项展示全名（`ImageModels.modelDisplayNames`）+ 简介文案
/// （l10n `generation_modelDesc_<id>`，见 arb）。
class ModelDisplay {
  ModelDisplay._();

  static const Map<String, ModelDisplayInfo> _infos = {
    ImageModels.animeDiffusionV5FullMedium: ModelDisplayInfo(
      id: ImageModels.animeDiffusionV5FullMedium,
      shortName: 'V5 Turbo',
      group: ModelListGroup.newer,
    ),
    ImageModels.animeDiffusionV5Curated: ModelDisplayInfo(
      id: ImageModels.animeDiffusionV5Curated,
      shortName: 'V5 Curated',
      group: ModelListGroup.newer,
      isNew: true,
    ),
    ImageModels.animeDiffusionV5Full: ModelDisplayInfo(
      id: ImageModels.animeDiffusionV5Full,
      shortName: 'V5 Full',
      group: ModelListGroup.newer,
    ),
    ImageModels.animeDiffusionV45Curated: ModelDisplayInfo(
      id: ImageModels.animeDiffusionV45Curated,
      shortName: 'V4.5 Curated',
      group: ModelListGroup.legacy,
    ),
    ImageModels.animeDiffusionV45Full: ModelDisplayInfo(
      id: ImageModels.animeDiffusionV45Full,
      shortName: 'V4.5 Full',
      group: ModelListGroup.legacy,
    ),
    ImageModels.animeDiffusionV4Curated: ModelDisplayInfo(
      id: ImageModels.animeDiffusionV4Curated,
      shortName: 'V4 Curated',
      group: ModelListGroup.legacy,
    ),
    ImageModels.animeDiffusionV4Full: ModelDisplayInfo(
      id: ImageModels.animeDiffusionV4Full,
      shortName: 'V4 Full',
      group: ModelListGroup.legacy,
    ),
    ImageModels.animeDiffusionV3: ModelDisplayInfo(
      id: ImageModels.animeDiffusionV3,
      shortName: 'V3',
      group: ModelListGroup.legacy,
    ),
    ImageModels.furryDiffusionV3: ModelDisplayInfo(
      id: ImageModels.furryDiffusionV3,
      shortName: 'Furry V3',
      group: ModelListGroup.legacy,
    ),
    ImageModels.furryDiffusion: ModelDisplayInfo(
      id: ImageModels.furryDiffusion,
      shortName: 'Furry',
      group: ModelListGroup.legacy,
    ),
  };

  /// 胶囊上显示的短名；未登记的模型回退全名，再退原始 id。
  static String shortNameOf(String model) =>
      _infos[model]?.shortName ?? ImageModels.modelDisplayNames[model] ?? model;

  /// 分组归属（未登记模型一律 LEGACY）
  static ModelListGroup groupOf(String model) =>
      _infos[model]?.group ?? ModelListGroup.legacy;

  /// 是否带 NEW 角标
  static bool isNewModel(String model) => _infos[model]?.isNew ?? false;

  /// 下拉项简介文案（无简介的模型返回 null）
  static String? descriptionOf(
    AppLocalizations l10n,
    String model,
  ) => switch (model) {
    ImageModels.animeDiffusionV5Curated => l10n.generation_modelDesc_v5Curated,
    ImageModels.animeDiffusionV5Full => l10n.generation_modelDesc_v5Full,
    ImageModels.animeDiffusionV5FullMedium => l10n.generation_modelDesc_v5Turbo,
    ImageModels.animeDiffusionV45Curated =>
      l10n.generation_modelDesc_v45Curated,
    ImageModels.animeDiffusionV45Full => l10n.generation_modelDesc_v45Full,
    ImageModels.animeDiffusionV4Curated => l10n.generation_modelDesc_v4Curated,
    ImageModels.animeDiffusionV4Full => l10n.generation_modelDesc_v4Full,
    _ => null,
  };
}
