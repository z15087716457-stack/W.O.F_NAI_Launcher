import 'dart:convert';

import '../../data/models/prompt_block/pill_document.dart';
import 'nai_prompt_syntax.dart';
import 'tag_normalizer.dart';
import 'prompt_translation_document.dart';

enum PromptTranslationDirection { toChinese, toSource }

class PromptTranslationEditRequest {
  const PromptTranslationEditRequest({
    required this.direction,
    required this.source,
    required this.zh,
    required this.baselineSource,
    required this.baselineZh,
    this.selectedTerms = const [],
  });

  final PromptTranslationDirection direction;
  final String source;
  final String zh;
  final String baselineSource;
  final String baselineZh;
  final List<PromptSelectedTerm> selectedTerms;

  String get input =>
      direction == PromptTranslationDirection.toChinese ? source : zh;

  String requestJson(List<Map<String, String>> glossary) => jsonEncode({
    'direction': direction.name,
    'original_source': baselineSource,
    'original_zh': baselineZh,
    'current_source': source,
    'current_zh': zh,
    'glossary': glossary,
    'selected_terms': [
      for (final term in selectedTerms)
        if (term.start >= 0 &&
            term.end <= zh.length &&
            zh.substring(term.start, term.end) == term.text)
          term.toJson(),
    ],
  });
}

/// A picked term is tied to its exact inserted range, not to a stale label.
class PromptSelectedTerm {
  const PromptSelectedTerm({
    required this.start,
    required this.text,
    required this.tag,
  });
  final int start;
  final String text;
  final String tag;
  int get end => start + text.length;
  Map<String, Object> toJson() => {'text': text, 'tag': tag, 'start': start};

  static List<PromptSelectedTerm> afterEdit(
    List<PromptSelectedTerm> terms,
    String before,
    String after,
  ) {
    if (before == after) return terms;
    var prefix = 0;
    while (prefix < before.length &&
        prefix < after.length &&
        before[prefix] == after[prefix]) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < before.length - prefix &&
        suffix < after.length - prefix &&
        before[before.length - suffix - 1] ==
            after[after.length - suffix - 1]) {
      suffix++;
    }
    final removedEnd = before.length - suffix;
    final delta = after.length - before.length;
    return [
          for (final term in terms)
            if (term.end <= prefix)
              term
            else if (term.start >= removedEnd &&
                (removedEnd > prefix || term.start >= prefix))
              PromptSelectedTerm(
                start: term.start + delta,
                text: term.text,
                tag: term.tag,
              ),
        ]
        .where(
          (term) =>
              term.start >= 0 &&
              term.end <= after.length &&
              after.substring(term.start, term.end) == term.text,
        )
        .toList(growable: false);
  }
}

class PromptTranslationEditResult {
  const PromptTranslationEditResult(this.text, {this.marks = const []});
  final String text;
  final List<TranslationTagMark> marks;

  static PromptTranslationEditResult parse(
    String raw,
    PromptTranslationEditRequest request,
    List<Map<String, String>> glossary,
  ) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const FormatException('转换结果格式不正确，草稿已保留');
    }
    if (decoded is! Map ||
        decoded['text'] is! String ||
        (decoded['text'] as String).trim().isEmpty) {
      throw const FormatException('模型没有返回有效文字，草稿已保留');
    }
    final text = (decoded['text'] as String).trim();
    if (text.contains('```') || RegExp(r'[\uE000-\uF8FF]').hasMatch(text)) {
      throw const FormatException('转换结果包含无效格式，草稿已保留');
    }
    if (request.direction == PromptTranslationDirection.toSource &&
        _structureErrors(text) > _structureErrors(request.source)) {
      throw const FormatException('转换结果的权重或分组不完整，草稿已保留');
    }
    final marks = <TranslationTagMark>[];
    if (request.direction == PromptTranslationDirection.toChinese &&
        decoded['parts'] is List) {
      final tags = {for (final item in glossary) item['tag']: item};
      final sourceTags = PromptTranslationBatch.prepare({
        'draft': PillDocument(text: request.source, instances: const {}),
      }).tagCandidates.toSet();
      final combined = StringBuffer();
      for (final part in decoded['parts'] as List) {
        if (part is! Map || part['text'] is! String) {
          return PromptTranslationEditResult(text);
        }
        final fragment = part['text'] as String;
        final start = combined.length;
        combined.write(fragment);
        final item = tags[part['tag']];
        final tag = item?['tag'];
        final category = item?['icon_id'];
        if (tag != null &&
            category != null &&
            category != 'general' &&
            sourceTags.contains(TagNormalizer.normalize(tag)) &&
            fragment.isNotEmpty) {
          marks.add(
            TranslationTagMark(
              start: start,
              end: combined.length,
              tag: tag,
              iconId: category,
            ),
          );
        }
      }
      if (combined.toString() != text) return PromptTranslationEditResult(text);
    }
    return PromptTranslationEditResult(text, marks: List.unmodifiable(marks));
  }

  static int _structureErrors(String text) {
    final tokens = NaiPromptSyntax.scan(text);
    var errors = tokens
        .where((token) => token.kind == NaiPromptTokenKind.opaque)
        .length;
    // Prefixes and closures cover NAI numeric weight syntax; grouped/literal
    // text is checked recursively without treating escaped punctuation as syntax.
    var depth = 0;
    for (final token in tokens) {
      if (token.kind == NaiPromptTokenKind.prefix) depth++;
      if (token.kind == NaiPromptTokenKind.closure) {
        if (depth > 0) {
          depth--;
        } else {
          errors++;
        }
      }
      if (token.kind == NaiPromptTokenKind.group) {
        errors += _structureErrors(
          token.source(text).substring(1, token.end - token.start - 1),
        );
      }
    }
    return errors + depth;
  }
}
