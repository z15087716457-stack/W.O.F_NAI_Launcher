import '../../data/models/prompt_block/pill_document.dart';

/// 药丸标记字符区间（Unicode 私用区起始段）。
const int kPillMarkerBase = 0xE000;
const int kPillMarkerEnd = 0xF8FF;

/// 判断一个 UTF-16 code unit 是否为药丸标记字符。
///
/// 私用区全在 BMP 内，单 code unit 即单字符，无需处理代理对。
bool isPillMarkerCodeUnit(int codeUnit) {
  return codeUnit >= kPillMarkerBase && codeUnit <= kPillMarkerEnd;
}

/// 药丸文档的不可变纯操作集。不依赖 Flutter，可独立单测。
abstract final class PillDocumentEditor {
  /// 分配最小空闲标记字符；区间耗尽时抛 [StateError]（上限 6400 个实例）。
  static String allocateMarker(PillDocument document) {
    for (var code = kPillMarkerBase; code <= kPillMarkerEnd; code++) {
      final char = String.fromCharCode(code);
      if (!document.instances.containsKey(char)) return char;
    }
    throw StateError('Pill marker space exhausted');
  }

  /// 在 [offset] 处插入新实例标记，实例默认启用。
  static PillDocument insertBlock(
    PillDocument document, {
    required int offset,
    required String blockId,
  }) {
    final marker = allocateMarker(document);
    final safeOffset = offset.clamp(0, document.text.length);
    final text =
        document.text.substring(0, safeOffset) +
        marker +
        document.text.substring(safeOffset);
    final instances = Map<String, PillInstance>.of(document.instances);
    instances[marker] = PillInstance(blockId: blockId);
    return document.copyWith(text: text, instances: instances);
  }

  /// 把 [marker] 的第 [occurrence] 次出现移动到 [newOffset]。
  ///
  /// 粘贴会产生同一字符的多处出现（共享同一实例），拖动药丸时
  /// 由渲染层告知拖的是第几次出现，避免误移另一份。
  static PillDocument moveMarker(
    PillDocument document, {
    required String marker,
    required int occurrence,
    required int newOffset,
  }) {
    final index = _occurrenceIndex(document.text, marker, occurrence);
    if (index < 0) return document;
    var text =
        document.text.substring(0, index) + document.text.substring(index + 1);
    var target = newOffset;
    if (index < newOffset) target -= 1;
    target = target.clamp(0, text.length);
    text = text.substring(0, target) + marker + text.substring(target);
    return document.copyWith(text: text);
  }

  /// 删除 [marker] 的全部出现并移除实例。未知标记（无实例）同样删字符。
  static PillDocument removeMarker(PillDocument document, String marker) {
    final text = document.text.replaceAll(marker, '');
    final instances = Map<String, PillInstance>.of(document.instances)
      ..remove(marker);
    return document.copyWith(text: text, instances: instances);
  }

  /// 设置实例启用态；实例不存在时原样返回。
  static PillDocument setEnabled(
    PillDocument document,
    String marker, {
    required bool enabled,
  }) {
    final instance = document.instances[marker];
    if (instance == null || instance.enabled == enabled) return document;
    final instances = Map<String, PillInstance>.of(document.instances);
    instances[marker] = instance.copyWith(enabled: enabled);
    return document.copyWith(instances: instances);
  }

  /// 文本被用户直接编辑后的对账：
  /// 文本中已消失的字符移除其实例；文本内容本身原样保留
  /// （未知标记字符留给渲染层显示为「失效」药丸，由用户点击清除）。
  static PillDocument reconcile(PillDocument document, String newText) {
    if (newText == document.text) return document;
    final instances = Map<String, PillInstance>.of(document.instances);
    instances.removeWhere((marker, _) => !newText.contains(marker));
    return PillDocument(text: newText, instances: instances);
  }

  /// 投影为最终提示词：普通字符原样；标记字符按实例展开
  /// （启用 → [resolveInstance] 的内容；禁用/未知/已删块 → 空串）。
  /// 不做 trim、格式化、分隔符补全——与旧 Composer 的空串拼接语义一致。
  ///
  /// [resolveInstance] 收整个实例（P2.5）：固定模式解析块库内容，
  /// 随机模式读物化的 `currentRoll`——**投影永不 roll**（蓝图红线）。
  static String project(
    PillDocument document,
    String? Function(PillInstance instance) resolveInstance,
  ) {
    if (document.instances.isEmpty) return stripMarkers(document.text);
    final buffer = StringBuffer();
    final text = document.text;
    for (var i = 0; i < text.length; i++) {
      final codeUnit = text.codeUnitAt(i);
      if (!isPillMarkerCodeUnit(codeUnit)) {
        buffer.writeCharCode(codeUnit);
        continue;
      }
      final instance = document.instances[String.fromCharCode(codeUnit)];
      if (instance == null || !instance.enabled) continue;
      buffer.write(resolveInstance(instance) ?? '');
    }
    return buffer.toString();
  }

  /// 剥掉全部药丸标记（含未知标记），用于外部纯文本摄入。
  static String stripMarkers(String text) {
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (!isPillMarkerCodeUnit(text.codeUnitAt(i))) {
        buffer.writeCharCode(text.codeUnitAt(i));
      }
    }
    return buffer.toString();
  }

  /// 文本中 [marker] 的第 [occurrence]（0 起）次出现的下标；不存在返回 -1。
  static int _occurrenceIndex(String text, String marker, int occurrence) {
    var index = -1;
    for (var count = 0; count <= occurrence; count++) {
      index = text.indexOf(marker, index + 1);
      if (index < 0) return -1;
    }
    return index;
  }
}
