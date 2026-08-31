/// 拖入生成页时使用的最小块引用。
///
/// 正文和标题必须从当前块库读取，避免拖拽快照与库状态分叉。
class PromptBlockDragData {
  const PromptBlockDragData({required this.blockId, this.instanceMarker});

  final String blockId;

  /// 药丸编辑器专用：文内拖动时已存在实例的定位信息。
  /// null 表示从块库拖入的新块。
  final PillInstanceDragRef? instanceMarker;
}

/// 文内拖动药丸的定位信息：标记字符 + 第几次出现
/// （粘贴会产生同一字符的多处出现，仅靠字符无法区分拖的是哪一份）。
class PillInstanceDragRef {
  const PillInstanceDragRef({required this.marker, required this.occurrence});

  final String marker;
  final int occurrence;
}
