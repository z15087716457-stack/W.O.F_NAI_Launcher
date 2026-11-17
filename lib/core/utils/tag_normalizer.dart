import 'nai_prompt_syntax.dart';

/// 标签标准化工具函数
///
/// 统一处理标签的存储格式和显示格式转换
/// 解决项目中 "显示格式"（空格）和 "存储格式"（下划线）的不一致问题
class TagNormalizer {
  TagNormalizer._();

  static final RegExp weightPrefixPattern = RegExp(
    r'^[-+]?(?:\d+\.?\d*|\.\d+)::',
  );
  static final RegExp weightPattern = RegExp(r'[-+]?(?:\d+\.?\d*|\.\d+)::');
  static final RegExp _galleryClosurePattern = RegExp(
    r'::(?=$|[\s,，;；{}\[\]()<>])',
  );
  static final RegExp _leadingBracketPattern = RegExp(r'^[\{\[\(]+');
  static final RegExp _commaSeparatorPattern = RegExp(r'[,，]+');
  static final RegExp _searchSeparatorPattern = RegExp(r'[_/\\|,，;；\n\r\t]+');
  static final RegExp _delimitedSearchSeparatorPattern = RegExp(
    r'[/\\|,，;；\n\r\t]+',
  );
  static final RegExp _bracketPattern = RegExp(r'[\{\}\[\]\(\)]');
  static final RegExp _colonPattern = RegExp(r'[:]+');
  static final RegExp _whitespacePattern = RegExp(r'\s+');

  static RegExp get commaSeparatorPattern => _commaSeparatorPattern;

  /// 统一标准化标签（用于存储和查询）
  ///
  /// 转换规则：
  /// 1. 转为小写
  /// 2. 去除首尾空格
  /// 3. 空格替换为下划线
  ///
  /// 示例：
  /// ```dart
  /// TagNormalizer.normalize('Simple Background') // 'simple_background'
  /// TagNormalizer.normalize('simple background')  // 'simple_background'
  /// TagNormalizer.normalize('  SOLO  ')           // 'solo'
  /// ```
  static String normalize(String tag) {
    return tag.toLowerCase().trim().replaceAll(' ', '_');
  }

  /// 批量标准化标签
  static List<String> normalizeList(List<String> tags) {
    return tags.map(normalize).toList();
  }

  /// 转换为显示格式（下划线转空格）
  ///
  /// 示例：
  /// ```dart
  /// TagNormalizer.toDisplay('simple_background') // 'simple background'
  /// TagNormalizer.toDisplay('solo')              // 'solo'
  /// ```
  static String toDisplay(String tag) {
    return tag.replaceAll('_', ' ');
  }

  /// 批量转换为显示格式
  static List<String> toDisplayList(List<String> tags) {
    return tags.map(toDisplay).toList();
  }

  /// 检查标签是否已标准化
  ///
  /// 已标准化：全小写、无首尾空格、无空格字符
  static bool isNormalized(String tag) {
    return tag == tag.toLowerCase().trim() && !tag.contains(' ');
  }

  /// 标准化并去重
  static Set<String> normalizeToSet(List<String> tags) {
    return tags.map(normalize).toSet();
  }

  /// 去掉 NAI 权重前缀，如 `1.2::tag`。
  static String stripWeightPrefix(String tag) {
    final weightMatch = weightPrefixPattern.firstMatch(tag);
    if (weightMatch == null) return tag;
    return tag.substring(weightMatch.end);
  }

  /// 去掉自动补全输入开头的括号前缀，不改变大小写。
  static String normalizeAutocompleteTag(String tag) {
    return stripWeightPrefix(
      tag.trim(),
    ).replaceAll(_leadingBracketPattern, '').trim();
  }

  /// Gallery query identity: preserve literal punctuation except NAI weights.
  static String normalizeGalleryQuery(String value) {
    return _galleryContent(value).replaceAll(_whitespacePattern, ' ').trim();
  }

  static String _galleryContent(String value) {
    return value
        .toLowerCase()
        .replaceAll(weightPattern, '')
        .replaceAll(_galleryClosurePattern, '')
        .replaceAll(RegExp(r'[{}\[\]]'), '')
        .replaceAll('_', ' ');
  }

  /// Gallery text terms are ANDed; spaces retain phrase meaning. Literal
  /// commas inside parentheses or quotes remain part of that phrase.
  static List<String> parseGalleryQuery(String value) {
    final text = _galleryContent(value);
    final terms = <String>{};
    var start = 0;
    void collect(int end) {
      final term = text
          .substring(start, end)
          .replaceAll(_whitespacePattern, ' ')
          .trim();
      if (term.isNotEmpty) terms.add(term);
    }

    for (final token in NaiPromptSyntax.scan(text, protectXml: false)) {
      if (token.kind == NaiPromptTokenKind.comma) {
        collect(token.start);
        start = token.end;
      } else if (token.kind == NaiPromptTokenKind.text) {
        for (final line in RegExp(r'[\r\n]+').allMatches(token.source(text))) {
          collect(token.start + line.start);
          start = token.start + line.end;
        }
      }
    }
    collect(text.length);
    return terms.toList(growable: false);
  }

  /// Match a whole positive tag, not a prefix such as `blue eyes shadow`.
  static bool containsGalleryTag(String text, String tag) {
    return parseGalleryQuery(text.replaceAll('|', ',')).contains(tag);
  }

  /// 标准化画廊搜索文本；下划线按空格处理以便包含匹配。
  static String normalizeSearchText(String value) {
    return value
        .toLowerCase()
        .replaceAll(weightPattern, ' ')
        .replaceAll(_searchSeparatorPattern, ' ')
        .replaceAll(_bracketPattern, ' ')
        .replaceAll(_whitespacePattern, ' ')
        .trim();
  }

  /// 标准化标签匹配文本。
  static String normalizeTagForMatch(String value) {
    return normalizeSearchText(
      value,
    ).replaceAll(_colonPattern, ' ').replaceAll(_whitespacePattern, ' ').trim();
  }

  /// 标准化数据库逗号分段搜索；保留下划线以便生成空格/下划线两种变体。
  static String normalizeDelimitedSearchSegment(String value) {
    return value
        .toLowerCase()
        .trim()
        .replaceAll(weightPattern, ' ')
        .replaceAll(_delimitedSearchSeparatorPattern, ' ')
        .replaceAll(_bracketPattern, ' ')
        .replaceAll(_whitespacePattern, ' ')
        .trim();
  }

  static List<String> parseDelimitedSearchSegments(String value) {
    return value
        .split(_commaSeparatorPattern)
        .map(normalizeSearchText)
        .where((segment) => segment.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }
}
