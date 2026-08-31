import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/utils/prompt_block_legacy_converter.dart';
import '../prompt_block/pill_document.dart';
import '../prompt_block/prompt_block_document.dart';

part 'style_explore_recipe.freezed.dart';
part 'style_explore_recipe.g.dart';

/// 画风探索的一组 Prompt 快照（Recipe）。
///
/// 正负两份 [PillDocument] 保存的是药丸工作区文档（含块实例的活引用：
/// 公共块库后续的内容编辑会反映到载入后的投影，块被删除则对应药丸失效）。
/// Recipe 不回写公共块，也不携带采样、遗传等探索运行态——那些属于后续
/// 阶段的探索任务数据。
@freezed
class StyleExploreRecipe with _$StyleExploreRecipe {
  const StyleExploreRecipe._();

  const factory StyleExploreRecipe({
    /// 稳定唯一标识。
    required String id,

    /// 界面显示名称。
    required String name,

    /// 保存时的正向文档快照。
    @JsonSerializable(explicitToJson: true)
    required PillDocument positiveDocument,

    /// 保存时的负向文档快照。
    @JsonSerializable(explicitToJson: true)
    required PillDocument negativeDocument,

    /// 创建时间。
    required DateTime createdAt,

    /// 更新时间。
    required DateTime updatedAt,
  }) = _StyleExploreRecipe;

  /// 读时迁移：文档对象带 `segments` 键 = 旧段式 `PromptBlockDocument`
  /// 存档，先经 [PromptBlockLegacyConverter] 转换再按新格式解析。
  factory StyleExploreRecipe.fromJson(Map<String, dynamic> json) =>
      _$StyleExploreRecipeFromJson(_migrateLegacyDocuments(json));

  /// 把旧段式文档字段就地替换为转换后的药丸文档 JSON。
  static Map<String, dynamic> _migrateLegacyDocuments(
    Map<String, dynamic> json,
  ) {
    final normalized = Map<String, dynamic>.of(json);
    for (final key in const ['positiveDocument', 'negativeDocument']) {
      final raw = normalized[key];
      if (raw is Map && raw.containsKey('segments')) {
        normalized[key] = PromptBlockLegacyConverter.convert(
          PromptBlockDocument.fromJson(Map<String, dynamic>.from(raw)),
        ).toJson();
      }
    }
    return normalized;
  }

  /// 从工作区快照创建新 Recipe；名称去除首尾空白。
  factory StyleExploreRecipe.create({
    required String name,
    required PillDocument positiveDocument,
    required PillDocument negativeDocument,
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final created = createdAt ?? DateTime.now();
    return StyleExploreRecipe(
      id: id ?? const Uuid().v4(),
      name: name.trim(),
      positiveDocument: positiveDocument,
      negativeDocument: negativeDocument,
      createdAt: created,
      updatedAt: updatedAt ?? created,
    );
  }

  /// 用于空名称的界面兜底。
  String get displayName => name.isNotEmpty ? name : '未命名配方';
}
