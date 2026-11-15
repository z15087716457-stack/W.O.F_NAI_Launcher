import 'nai_prompt_syntax.dart';
import 'pill_document_editor.dart';

/// One comma-delimited reading, anchored to the unchanged UTF-16 source.
class PromptReadingUnit {
  const PromptReadingUnit({
    required this.start,
    required this.end,
    required this.textStart,
    required this.textEnd,
    required this.text,
  });

  final int start, end, textStart, textEnd;
  final String text;

  static List<PromptReadingUnit> parse(String source) {
    final removed = <int>{};
    final cuts = <int>{};
    _scan(source, 0, removed, cuts);
    final result = <PromptReadingUnit>[];
    var start = 0;
    for (final end in {...cuts, source.length}.toList()..sort()) {
      var first = -1, last = -1;
      final plain = StringBuffer();
      for (var i = start; i < end; i++) {
        if (removed.contains(i) ||
            (i == end - 1 && ',，\n'.contains(source[i]))) {
          continue;
        }
        plain.write(source[i]);
        if (source[i].trim().isNotEmpty) {
          if (first < 0) first = i;
          last = i + 1;
        }
      }
      if (first >= 0) {
        result.add(
          PromptReadingUnit(
            start: start,
            end: end,
            textStart: first,
            textEnd: last,
            text: plain.toString().trim(),
          ),
        );
      }
      start = end;
    }
    return result;
  }

  /// Only NAI weighting syntax is removed; counts, names and literals remain.
  static String clean(String text) {
    final removed = <int>{};
    _scan(text, 0, removed, <int>{});
    return [
      for (var i = 0; i < text.length; i++)
        if (!removed.contains(i)) text[i],
    ].join().trim().replaceFirst(RegExp(r'[,，]+\s*$'), '');
  }

  static void _scan(
    String source,
    int offset,
    Set<int> removed,
    Set<int> cuts,
  ) {
    for (final token in NaiPromptSyntax.scan(source)) {
      switch (token.kind) {
        case NaiPromptTokenKind.prefix:
        case NaiPromptTokenKind.closure:
          for (var i = token.start; i < token.end; i++) {
            removed.add(offset + i);
          }
        case NaiPromptTokenKind.comma:
          cuts.add(offset + token.end);
        case NaiPromptTokenKind.group:
          if ('[{'.contains(source[token.start])) {
            removed.add(offset + token.start);
            removed.add(offset + token.end - 1);
            _scan(
              source.substring(token.start + 1, token.end - 1),
              offset + token.start + 1,
              removed,
              cuts,
            );
          }
        case NaiPromptTokenKind.text:
          for (var i = token.start; i < token.end; i++) {
            if (source.codeUnitAt(i) == 10) cuts.add(offset + i + 1);
            if (isPillMarkerCodeUnit(source.codeUnitAt(i))) {
              cuts.add(offset + i);
              cuts.add(offset + i + 1);
              removed.add(offset + i);
            }
          }
        case NaiPromptTokenKind.literal:
          break;
        case NaiPromptTokenKind.opaque:
          // Incremental translation can start or end inside an existing group.
          if ('[{}]'.contains(source[token.start])) {
            removed.add(offset + token.start);
            _scan(
              source.substring(token.start + 1, token.end),
              offset + token.start + 1,
              removed,
              cuts,
            );
          }
          break;
      }
    }
  }
}
