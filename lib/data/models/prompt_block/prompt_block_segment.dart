import 'package:freezed_annotation/freezed_annotation.dart';

part 'prompt_block_segment.freezed.dart';
part 'prompt_block_segment.g.dart';

/// Prompt 工作区文档中的一个有序段。
@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.none)
class PromptBlockSegment with _$PromptBlockSegment {
  const PromptBlockSegment._();

  /// 用户直接编辑的普通文本段。
  @FreezedUnionValue('text')
  const factory PromptBlockSegment.text({
    required String id,
    required String text,
  }) = TextSegment;

  /// 从全局 Prompt 块创建的独立快照。
  @FreezedUnionValue('block')
  const factory PromptBlockSegment.block({
    required String id,
    String? sourceBlockId,
    required String titleSnapshot,
    required String colorSnapshot,
    required String contentSnapshot,
    @Default(true) bool enabled,
  }) = BlockSegment;

  factory PromptBlockSegment.fromJson(Map<String, dynamic> json) =>
      _$PromptBlockSegmentFromJson(json);
}
