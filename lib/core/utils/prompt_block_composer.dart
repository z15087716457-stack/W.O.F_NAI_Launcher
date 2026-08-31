import 'package:uuid/uuid.dart';

import '../../data/models/prompt_block/prompt_block.dart';
import '../../data/models/prompt_block/prompt_block_document.dart';
import '../../data/models/prompt_block/prompt_block_segment.dart';

/// 可注入的 UUID 生成器。
typedef PromptBlockUuidGenerator = String Function();

/// 可注入的当前时间来源。
typedef PromptBlockClock = DateTime Function();

/// Prompt 块文档的不可变编辑与纯文本投影工具。
class PromptBlockComposer {
  PromptBlockComposer({
    PromptBlockUuidGenerator? uuidGenerator,
    PromptBlockClock? clock,
  }) : _uuidGenerator = uuidGenerator ?? const Uuid().v4,
       _clock = clock ?? DateTime.now;

  final PromptBlockUuidGenerator _uuidGenerator;
  final PromptBlockClock _clock;

  /// 从旧式纯文本创建只含一个文本段的新文档。
  PromptBlockDocument createDocumentFromPlainText(String text) {
    return PromptBlockDocument(
      documentId: _uuidGenerator(),
      segments: [PromptBlockSegment.text(id: _uuidGenerator(), text: text)],
      updatedAt: _clock(),
    );
  }

  /// 从全局块创建与源对象后续修改完全隔离的快照段。
  PromptBlockSegment createBlockSnapshot(
    PromptBlock block, {
    bool enabled = true,
  }) {
    return PromptBlockSegment.block(
      id: _uuidGenerator(),
      sourceBlockId: block.id,
      titleSnapshot: block.title,
      colorSnapshot: block.color,
      contentSnapshot: block.content,
      enabled: enabled,
    );
  }

  /// 按 segment 索引插入一个新的块快照。
  PromptBlockDocument insertBlock(
    PromptBlockDocument document, {
    required int index,
    required PromptBlock block,
  }) {
    if (index < 0 || index > document.segments.length) {
      throw RangeError.range(index, 0, document.segments.length, 'index');
    }

    final segments = [...document.segments];
    segments.insert(index, createBlockSnapshot(block));
    return _withSegments(document, segments);
  }

  /// 在指定文本段偏移处分裂为前文、块和后文三个段。
  ///
  /// 前文保留原文本段 ID；块与后文获得新 ID。空前文或空后文也会保留，
  /// 从而不丢失用户输入位置和原始文本。
  PromptBlockDocument insertBlockAtTextOffset(
    PromptBlockDocument document, {
    required String textSegmentId,
    required int offset,
    required PromptBlock block,
  }) {
    final index = _segmentIndex(document, textSegmentId);
    final segment = document.segments[index];
    if (segment is! TextSegment) {
      throw StateError('Segment is not a text segment: $textSegmentId');
    }
    if (offset < 0 || offset > segment.text.length) {
      throw RangeError.range(offset, 0, segment.text.length, 'offset');
    }

    final replacement = <PromptBlockSegment>[
      PromptBlockSegment.text(
        id: segment.id,
        text: segment.text.substring(0, offset),
      ),
      createBlockSnapshot(block),
      PromptBlockSegment.text(
        id: _uuidGenerator(),
        text: segment.text.substring(offset),
      ),
    ];
    final segments = [...document.segments]
      ..removeAt(index)
      ..insertAll(index, replacement);
    return _withSegments(document, segments);
  }

  /// 更新指定普通文本段，不改变其他段。
  PromptBlockDocument updateText(
    PromptBlockDocument document, {
    required String segmentId,
    required String text,
  }) {
    final index = _segmentIndex(document, segmentId);
    final segment = document.segments[index];
    if (segment is! TextSegment) {
      throw StateError('Segment is not a text segment: $segmentId');
    }

    final segments = [...document.segments];
    segments[index] = segment.copyWith(text: text);
    return _withSegments(document, segments);
  }

  /// 删除指定段。
  PromptBlockDocument removeSegment(
    PromptBlockDocument document, {
    required String segmentId,
  }) {
    final index = _segmentIndex(document, segmentId);
    final segments = [...document.segments]..removeAt(index);
    return _withSegments(document, segments);
  }

  /// 显式设置块段启用状态。
  PromptBlockDocument setBlockEnabled(
    PromptBlockDocument document, {
    required String segmentId,
    required bool enabled,
  }) {
    final index = _segmentIndex(document, segmentId);
    final segment = document.segments[index];
    if (segment is! BlockSegment) {
      throw StateError('Segment is not a block segment: $segmentId');
    }

    final segments = [...document.segments];
    segments[index] = segment.copyWith(enabled: enabled);
    return _withSegments(document, segments);
  }

  /// 切换块段启用状态。
  PromptBlockDocument toggleBlockEnabled(
    PromptBlockDocument document, {
    required String segmentId,
  }) {
    final index = _segmentIndex(document, segmentId);
    final segment = document.segments[index];
    if (segment is! BlockSegment) {
      throw StateError('Segment is not a block segment: $segmentId');
    }
    return setBlockEnabled(
      document,
      segmentId: segmentId,
      enabled: !segment.enabled,
    );
  }

  /// 将块展开为普通文本；展开后的文本段保留原 segment ID。
  PromptBlockDocument expandBlock(
    PromptBlockDocument document, {
    required String segmentId,
  }) {
    final index = _segmentIndex(document, segmentId);
    final segment = document.segments[index];
    if (segment is! BlockSegment) {
      throw StateError('Segment is not a block segment: $segmentId');
    }

    final segments = [...document.segments];
    segments[index] = PromptBlockSegment.text(
      id: segment.id,
      text: segment.contentSnapshot,
    );
    return _withSegments(document, segments);
  }

  /// 使用完整且不重复的 segment ID 列表重排整个文档。
  PromptBlockDocument reorderSegments(
    PromptBlockDocument document,
    List<String> orderedIds,
  ) {
    final currentIds = document.segments.map((segment) => segment.id).toList();
    if (currentIds.toSet().length != currentIds.length) {
      throw StateError('Document contains duplicate segment IDs');
    }
    if (orderedIds.length != currentIds.length) {
      throw ArgumentError.value(
        orderedIds,
        'orderedIds',
        'Reorder must contain every segment ID exactly once',
      );
    }
    if (orderedIds.toSet().length != orderedIds.length) {
      throw ArgumentError.value(
        orderedIds,
        'orderedIds',
        'Reorder contains duplicate segment IDs',
      );
    }
    if (!orderedIds.toSet().containsAll(currentIds) ||
        !currentIds.toSet().containsAll(orderedIds)) {
      throw ArgumentError.value(
        orderedIds,
        'orderedIds',
        'Reorder IDs must exactly match the document segment IDs',
      );
    }

    final byId = <String, PromptBlockSegment>{
      for (final segment in document.segments) segment.id: segment,
    };
    return _withSegments(document, orderedIds.map((id) => byId[id]!).toList());
  }

  /// 严格按文档顺序投影纯文本。
  ///
  /// 普通文本总是原样拼接；块段仅在启用时拼接 [BlockSegment.contentSnapshot]。
  /// 不做 trim、格式化、分隔符补全或去重。
  String composePlainText(PromptBlockDocument document) {
    final buffer = StringBuffer();
    for (final segment in document.segments) {
      switch (segment) {
        case TextSegment(:final text):
          buffer.write(text);
        case BlockSegment(:final contentSnapshot, :final enabled):
          if (enabled) buffer.write(contentSnapshot);
      }
    }
    return buffer.toString();
  }

  PromptBlockDocument _withSegments(
    PromptBlockDocument document,
    List<PromptBlockSegment> segments,
  ) {
    return document.copyWith(segments: segments, updatedAt: _clock());
  }

  int _segmentIndex(PromptBlockDocument document, String segmentId) {
    final index = document.segments.indexWhere(
      (segment) => segment.id == segmentId,
    );
    if (index == -1) {
      throw ArgumentError.value(
        segmentId,
        'segmentId',
        'Segment does not exist',
      );
    }
    return index;
  }
}
