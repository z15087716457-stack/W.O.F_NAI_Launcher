import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

import '../prompt_block/prompt_block_document.dart';

part 'style_explore_recipe.freezed.dart';
part 'style_explore_recipe.g.dart';

/// 画风探索的一组 Prompt 快照（Recipe）。
///
/// 正负两份 [PromptBlockDocument] 是保存时刻的完整快照；公共块库后续
/// 的编辑不会影响已保存的 Recipe。Recipe 不回写公共块，也不携带采样、
/// 遗传等探索运行态——那些属于后续阶段的探索任务数据。
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
    required PromptBlockDocument positiveDocument,

    /// 保存时的负向文档快照。
    @JsonSerializable(explicitToJson: true)
    required PromptBlockDocument negativeDocument,

    /// 创建时间。
    required DateTime createdAt,

    /// 更新时间。
    required DateTime updatedAt,
  }) = _StyleExploreRecipe;

  factory StyleExploreRecipe.fromJson(Map<String, dynamic> json) =>
      _$StyleExploreRecipeFromJson(json);

  /// 从工作区快照创建新 Recipe；名称去除首尾空白。
  factory StyleExploreRecipe.create({
    required String name,
    required PromptBlockDocument positiveDocument,
    required PromptBlockDocument negativeDocument,
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
