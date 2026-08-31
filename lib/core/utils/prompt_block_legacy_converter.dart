import '../../data/models/prompt_block/pill_document.dart';
import '../../data/models/prompt_block/prompt_block_document.dart';
import '../../data/models/prompt_block/prompt_block_segment.dart';
import 'pill_document_editor.dart';

/// 旧段式 [PromptBlockDocument] → 药丸 [PillDocument] 的读时迁移转换器。
///
/// 规则（画风探索 Recipe 换芯用）：
/// - text 段：文本原样拼接；
/// - block 段有 sourceBlockId：在拼接位置插入一个私用区标记字符并建活
///   [PillInstance]（blockId = sourceBlockId，enabled 保留，settings 固定
///   模式默认，currentRoll = null）。块已从库中删除时不做特判——投影查库
///   落空自然展开为空串、渲染层显示失效药丸（与既有 missing 语义一致）；
/// - block 段无 sourceBlockId：contentSnapshot 当纯文本拍平拼接。
abstract final class PromptBlockLegacyConverter {
  /// 把旧文档转换为药丸文档；标记字符复用 [PillDocumentEditor.allocateMarker]
  /// 的顺次分配（U+E000 起）。
  static PillDocument convert(PromptBlockDocument legacy) {
    final buffer = StringBuffer();
    final instances = <String, PillInstance>{};

    for (final segment in legacy.segments) {
      switch (segment) {
        case TextSegment(:final text):
          buffer.write(text);
        case BlockSegment(
          :final sourceBlockId,
          :final contentSnapshot,
          :final enabled,
        ):
          if (sourceBlockId == null) {
            buffer.write(contentSnapshot);
            continue;
          }
          // allocateMarker 只读实例表，直接以累积中的实例充当探测文档。
          final marker = PillDocumentEditor.allocateMarker(
            PillDocument(text: '', instances: instances),
          );
          buffer.write(marker);
          instances[marker] = PillInstance(
            blockId: sourceBlockId,
            enabled: enabled,
          );
      }
    }

    return PillDocument(text: buffer.toString(), instances: instances);
  }
}
