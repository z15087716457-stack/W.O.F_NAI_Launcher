import '../../core/utils/prompt_translation_language.dart';

enum PromptTranslationMode { inline, blocks }

/// Reading-only annotation in the original UTF-16 text. It never becomes a
/// block marker or contributes to the generation projection.
class PromptReading {
  const PromptReading({
    required this.start,
    required this.end,
    required this.source,
    required this.translation,
    this.languageCode = 'zh',
    this.needsReview = false,
    this.perSegment = false,
  });

  final int start, end;
  final String source, translation, languageCode;
  final bool needsReview;
  final bool perSegment;

  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
    'source': source,
    'translation': translation,
    'languageCode': languageCode,
    if (needsReview) 'needsReview': true,
    if (perSegment) 'perSegment': true,
  };

  static PromptReading? fromJson(Map<String, dynamic> json, String text) {
    final start = json['start'], end = json['end'];
    if (start is! int ||
        end is! int ||
        start < 0 ||
        end > text.length ||
        start >= end ||
        json['source'] != text.substring(start, end) ||
        json['translation'] is! String) {
      return null;
    }
    return PromptReading(
      start: start,
      end: end,
      source: json['source'] as String,
      translation: json['translation'] as String,
      languageCode: PromptTranslationLanguage.isCode(json['languageCode'])
          ? json['languageCode'] as String
          : 'zh',
      needsReview: json['needsReview'] == true,
      perSegment: json['perSegment'] == true,
    );
  }

  /// A text edit preserves unaffected annotations and replaces overlapping
  /// annotations with one pending range. Repeated text is anchored by offsets.
  static List<PromptReading> rebase(
    List<PromptReading> readings,
    String before,
    String after,
  ) {
    if (before == after || readings.isEmpty) return readings;
    var prefix = 0;
    while (prefix < before.length &&
        prefix < after.length &&
        before.codeUnitAt(prefix) == after.codeUnitAt(prefix)) {
      prefix++;
    }
    var suffix = 0;
    while (suffix < before.length - prefix &&
        suffix < after.length - prefix &&
        before.codeUnitAt(before.length - 1 - suffix) ==
            after.codeUnitAt(after.length - 1 - suffix)) {
      suffix++;
    }
    final oldEnd = before.length - suffix,
        newEnd = after.length - suffix,
        delta = after.length - before.length;
    final result = <PromptReading>[];
    PromptReading? pending;
    for (final item in readings) {
      final inserted = after.substring(prefix, newEnd);
      final extendsRange =
          item.end == prefix &&
          oldEnd == prefix &&
          !RegExp(r'[,，\n]\s*$').hasMatch(item.source) &&
          inserted.trim().isNotEmpty &&
          !RegExp(r'^[ \t]*[,，\n]').hasMatch(inserted);
      if (item.end <= prefix && !extendsRange) {
        result.add(item);
        continue;
      }
      if (item.start >= oldEnd && !extendsRange) {
        result.add(
          PromptReading(
            start: item.start + delta,
            end: item.end + delta,
            source: item.source,
            translation: item.translation,
            languageCode: item.languageCode,
            needsReview: item.needsReview,
            perSegment: item.perSegment,
          ),
        );
        continue;
      }
      final start = item.start < prefix ? item.start : prefix;
      final end = item.end > oldEnd ? item.end + delta : newEnd;
      if (start >= end) continue;
      pending = PromptReading(
        start: pending?.start ?? start,
        end: end,
        source: after.substring(pending?.start ?? start, end),
        translation: '',
        languageCode: item.languageCode,
        needsReview: true,
      );
    }
    if (pending != null) result.add(pending);
    result.sort((a, b) => a.start.compareTo(b.start));
    // Inserting a block splits the plain-text range; the next translation
    // request translates each side without retaining a cross-block annotation.
    return List.unmodifiable(
      result.where((r) => !RegExp(r'[\uE000-\uF8FF]').hasMatch(r.source)),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PromptReading &&
      other.start == start &&
      other.end == end &&
      other.source == source &&
      other.translation == translation &&
      other.languageCode == languageCode &&
      other.perSegment == perSegment &&
      other.needsReview == needsReview;
  @override
  int get hashCode => Object.hash(
    start,
    end,
    source,
    translation,
    languageCode,
    needsReview,
    perSegment,
  );
}
