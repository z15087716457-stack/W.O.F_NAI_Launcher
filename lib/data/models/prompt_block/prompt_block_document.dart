import 'package:freezed_annotation/freezed_annotation.dart';

import 'prompt_block_segment.dart';

part 'prompt_block_document.freezed.dart';
part 'prompt_block_document.g.dart';

/// 一个 Prompt lane 的有序、不可变编辑文档。
@freezed
class PromptBlockDocument with _$PromptBlockDocument {
  @JsonSerializable(explicitToJson: true)
  const factory PromptBlockDocument({
    required String documentId,
    required List<PromptBlockSegment> segments,
    required DateTime updatedAt,
  }) = _PromptBlockDocument;

  factory PromptBlockDocument.fromJson(Map<String, dynamic> json) =>
      _$PromptBlockDocumentFromJson(json);
}
