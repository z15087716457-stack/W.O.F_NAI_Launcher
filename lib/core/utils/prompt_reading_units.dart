import 'nai_prompt_syntax.dart';
import 'pill_document_editor.dart';

/// Local lookup hints, anchored to the unchanged UTF-16 source. The translation
/// model may split or combine these within a structural section.
class PromptReadingUnit {
  static final _markup = RegExp(r'^<\s*/?\s*[\w:.-]+(?:\s[^<>]*)?\s*/?>$');
  static final _separators = RegExp(r'[\s,，;；:：.!?。！？]+');

  static bool isSyntaxOnly(String source, {bool? structuralMarkup}) => clean(
    source,
    structuralMarkup: structuralMarkup,
  ).replaceAll(_separators, '').isEmpty;
  const PromptReadingUnit({
    required this.start,
    required this.end,
    required this.textStart,
    required this.textEnd,
    required this.text,
    this.section = 0,
  });

  final int start, end, textStart, textEnd;
  final String text;
  final int section;

  PromptReadingUnit shifted(int offset) => PromptReadingUnit(
    start: start + offset,
    end: end + offset,
    textStart: textStart + offset,
    textEnd: textEnd + offset,
    text: text,
    section: section,
  );

  /// One display range for an already anchored semantic reading.
  static PromptReadingUnit? cover(String source) {
    final units = parse(source);
    if (units.isEmpty) return null;
    return PromptReadingUnit(
      start: 0,
      end: source.length,
      textStart: units.first.textStart,
      textEnd: units.last.textEnd,
      text: clean(source),
    );
  }

  static bool isSingleSection(String source, {bool? structuralMarkup}) {
    final markup = structuralMarkup ?? NaiPromptSyntax.isXml(source);
    final units = parse(source, structuralMarkup: markup);
    return units.isNotEmpty &&
        units.first.section == units.last.section &&
        !(markup &&
            NaiPromptSyntax.scan(source, protectXml: false).any(
              (token) =>
                  token.kind == NaiPromptTokenKind.literal &&
                  _markup.hasMatch(token.source(source)),
            ));
  }

  static List<PromptReadingUnit> parse(
    String source, {
    bool? structuralMarkup,
  }) {
    final removed = <int>{};
    final cuts = <int>{};
    final breaks = <int>{};
    _scan(
      source,
      0,
      removed,
      cuts,
      breaks,
      structuralMarkup ?? NaiPromptSyntax.isXml(source),
    );
    final result = <PromptReadingUnit>[];
    var start = 0;
    var section = 0;
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
            section: section,
          ),
        );
      }
      start = end;
      if (breaks.contains(end)) section++;
    }
    return result;
  }

  /// Remove weighting and structural markup; counts, names and literals remain.
  static String clean(String text, {bool? structuralMarkup}) {
    final removed = <int>{};
    _scan(
      text,
      0,
      removed,
      <int>{},
      <int>{},
      structuralMarkup ?? NaiPromptSyntax.isXml(text),
    );
    return [
      for (var i = 0; i < text.length; i++)
        if (!removed.contains(i)) text[i],
    ].join().trim().replaceFirst(RegExp(r'[,，]+\s*$'), '');
  }

  /// Match model echoes without requiring whitespace or weighting syntax to
  /// be copied verbatim. Offsets always point into the unchanged source.
  static ({String text, List<int> offsets}) alignmentText(
    String source, {
    required bool structuralMarkup,
  }) {
    final removed = <int>{};
    _scan(source, 0, removed, <int>{}, <int>{}, structuralMarkup);
    final text = StringBuffer();
    final offsets = <int>[];
    var space = false;
    for (var i = 0; i < source.length; i++) {
      if (removed.contains(i)) continue;
      final whitespace = source[i].trim().isEmpty;
      if (whitespace && space) continue;
      text.write(whitespace ? ' ' : source[i]);
      offsets.add(i);
      space = whitespace;
    }
    return (text: text.toString(), offsets: offsets);
  }

  static void _scan(
    String source,
    int offset,
    Set<int> removed,
    Set<int> cuts,
    Set<int> breaks,
    bool structuralMarkup,
  ) {
    for (final token in NaiPromptSyntax.scan(source, protectXml: false)) {
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
              breaks,
              structuralMarkup,
            );
          }
        case NaiPromptTokenKind.text:
          for (var i = token.start; i < token.end; i++) {
            if (source.codeUnitAt(i) == 10) {
              cuts.add(offset + i + 1);
              breaks.add(offset + i + 1);
            }
            if (isPillMarkerCodeUnit(source.codeUnitAt(i))) {
              cuts.add(offset + i);
              cuts.add(offset + i + 1);
              removed.add(offset + i);
            }
          }
        case NaiPromptTokenKind.literal:
          if (structuralMarkup && _markup.hasMatch(token.source(source))) {
            cuts.addAll([offset + token.start, offset + token.end]);
            breaks.addAll([offset + token.start, offset + token.end]);
            for (var i = token.start; i < token.end; i++) {
              removed.add(offset + i);
            }
          }
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
              breaks,
              structuralMarkup,
            );
          }
          break;
      }
    }
  }
}
