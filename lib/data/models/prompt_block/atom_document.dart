import 'dart:math' as math;

import '../../../core/utils/pill_document_editor.dart';

/// 块内原子文档（FEAT-79）：单文本流 + 标记字符当原子。
///
/// `text` = 用户直接编辑的正文，原子 = 药丸同款私用区标记字符
/// （E000-F8FF，单 code unit）；`atoms` = 标记 → 原子原文。
/// 与 `PillDocument` 平行但更轻：原子是纯文本，无实例设置/投影。
/// 纯函数、零 Flutter 依赖，可独立单测。
class AtomDocument {
  const AtomDocument({required this.text, required this.atoms});

  final String text;
  final Map<String, String> atoms;

  /// 从纯文本原子列表播种（打开旧块/新建预填）：每个原子一个标记，
  /// 原子间用空格分隔保持流内可读性。
  static AtomDocument fromAtoms(List<String> atoms) {
    final map = <String, String>{};
    final buffer = StringBuffer();
    var code = kPillMarkerBase;
    for (final atom in atoms) {
      final trimmed = atom.trim();
      if (trimmed.isEmpty) continue;
      while (code <= kPillMarkerEnd &&
          map.containsKey(String.fromCharCode(code))) {
        code++;
      }
      final marker = String.fromCharCode(code);
      map[marker] = trimmed;
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(marker);
      code++;
    }
    return AtomDocument(text: buffer.toString(), atoms: map);
  }
}

/// 原子文档的不可变操作集。
abstract final class AtomDocumentEditor {
  /// 分配最小空闲标记字符（不在 atoms 表也不在正文里）。
  static String allocateMarker(AtomDocument document) {
    for (var code = kPillMarkerBase; code <= kPillMarkerEnd; code++) {
      final char = String.fromCharCode(code);
      if (!document.atoms.containsKey(char) &&
          !document.text.contains(char)) {
        return char;
      }
    }
    throw StateError('Atom marker space exhausted');
  }

  /// 回车成块：光标**前**的连续文本（从上一个标记后算起）trim 后
  /// 转成一个原子；光标**后**的文本原样保留。
  ///
  /// 返回 `(文档, 新光标)`——光标落在新标记之后。光标前无有效文本
  /// 时原样返回（不产生空原子）。
  static (AtomDocument, int) commitBeforeCaret(
    AtomDocument document,
    int caret,
  ) {
    caret = caret.clamp(0, document.text.length);
    // 光标前最近一个标记的下一字符 = 待提交段的起点
    var runStart = 0;
    for (var i = 0; i < caret; i++) {
      if (isPillMarkerCodeUnit(document.text.codeUnitAt(i))) {
        runStart = i + 1;
      }
    }
    final runText = document.text.substring(runStart, caret).trim();
    if (runText.isEmpty) return (document, caret);

    final marker = allocateMarker(document);
    final atoms = Map<String, String>.of(document.atoms)..[marker] = runText;
    final text = document.text.substring(0, runStart) +
        marker +
        document.text.substring(caret);
    return (AtomDocument(text: text, atoms: atoms), runStart + 1);
  }

  /// 点击原子：把 [marker] 的第 [occurrence] 次出现换回原文文本，
  /// 光标落在还原文本末尾；标记在正文中不再出现时同步清 atoms 表。
  static (AtomDocument, int) unAtomAt(
    AtomDocument document,
    String marker,
    int occurrence,
  ) {
    final atomText = document.atoms[marker] ?? '';
    var index = -1;
    for (var count = 0; count <= occurrence; count++) {
      index = document.text.indexOf(marker, index + 1);
      if (index < 0) return (document, document.text.length);
    }
    final text = document.text.substring(0, index) +
        atomText +
        document.text.substring(index + 1);
    final atoms = Map<String, String>.of(document.atoms);
    if (!text.contains(marker)) atoms.remove(marker);
    return (
      AtomDocument(text: text, atoms: atoms),
      index + atomText.length,
    );
  }

  /// 删除某个标记的该次出现之外的语义由文本编辑自然承担——
  /// 退格/选择删除移除字符即删原子。
  ///
  /// 文本被用户编辑后的对账：处理粘贴换行 + 清理正文已消失的标记
  /// 的 atoms 表条目。返回 `(文档, 新光标)`；无换行且表无孤儿时
  /// 直接返回原文档。
  static (AtomDocument, int) reconcile(
    AtomDocument document,
    String newText,
    int caret,
  ) {
    final atoms = Map<String, String>.of(document.atoms)
      ..removeWhere((marker, _) => !newText.contains(marker));
    var doc = AtomDocument(text: newText, atoms: atoms);
    if (!newText.contains('\n')) return (doc, caret);

    // 粘贴换行：每行切一个原子（跳过空行），最后一行保留为可编辑
    // 原文。光标补偿只累计光标之前的换行改写量。
    final buffer = StringBuffer();
    var start = 0;
    var caretDelta = 0;
    for (var i = 0; i < newText.length; i++) {
      if (newText[i] != '\n') continue;
      final line = newText.substring(start, i).trim();
      if (line.isNotEmpty) {
        final marker = allocateMarker(doc);
        doc = AtomDocument(
          text: doc.text,
          atoms: Map.of(doc.atoms)..[marker] = line,
        );
        buffer.write(marker);
        if (i < caret) {
          // 原文 i-start 长的一段被换成 1 个标记字符
          caretDelta += 1 - (i - start);
        }
      } else if (i < caret) {
        // 空行连换行一起丢弃，光标前移 1
        caretDelta -= 1;
      }
      start = i + 1;
    }
    buffer.write(newText.substring(start));
    final rebuilt = buffer.toString();
    return (
      AtomDocument(text: rebuilt, atoms: doc.atoms),
      math.min(caret + caretDelta, rebuilt.length).clamp(0, rebuilt.length),
    );
  }

  /// 保存口径：文档顺序扫描——标记 → atoms 表原文；连续原文段
  /// trim 后按序收尾成原子；空白段与孤儿标记丢弃。
  static List<String> extractAtoms(AtomDocument document) {
    final out = <String>[];
    final buffer = StringBuffer();
    void flush() {
      final text = buffer.toString().trim();
      buffer.clear();
      if (text.isNotEmpty) out.add(text);
    }

    for (var i = 0; i < document.text.length; i++) {
      final codeUnit = document.text.codeUnitAt(i);
      if (!isPillMarkerCodeUnit(codeUnit)) {
        buffer.writeCharCode(codeUnit);
        continue;
      }
      flush();
      final text = document.atoms[String.fromCharCode(codeUnit)];
      if (text != null && text.trim().isNotEmpty) out.add(text.trim());
    }
    flush();
    return out;
  }
}
