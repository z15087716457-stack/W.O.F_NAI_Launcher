import '../utils/alias_parser.dart';
import '../utils/nai_weight_syntax.dart';
import '../utils/tag_normalizer.dart';
import 'completion_models.dart';

class PromptTokenParser {
  const PromptTokenParser._();

  static final RegExp _weightNumberSuffix = RegExp(r':\s*-?\d+(?:\.\d+)?$');
  static final RegExp _syntaxSuffix = RegExp(
    r'^(?:(?:\s*::)|(?::\s*-?\d+(?:\.\d+)?)|[\}\]\)])*',
  );

  static CompletionQuery parse({
    required String text,
    required int cursorPosition,
    required int limit,
    required String locale,
    bool splitOnSpaces = false,
  }) {
    final cursor = cursorPosition.clamp(0, text.length);
    final (isTypingAlias, partialAlias, aliasStart) =
        AliasParser.detectPartialAlias(text, cursor);
    if (isTypingAlias && !splitOnSpaces) {
      var replacementEnd = cursor;
      final closingBracket = text.indexOf('>', cursor);
      final nextLineBreak = text.indexOf(RegExp(r'[\r\n]'), cursor);
      if (closingBracket >= 0 &&
          (nextLineBreak < 0 || closingBracket < nextLineBreak)) {
        replacementEnd = closingBracket + 1;
      }
      return CompletionQuery(
        fullText: text,
        cursorPosition: cursor,
        token: partialAlias.trim().toLowerCase(),
        replacementRange: TextReplacementRange(
          start: aliasStart,
          end: replacementEnd,
        ),
        existingTags: const {},
        limit: limit.clamp(1, CompletionResultLimits.all),
        locale: locale,
        kind: CompletionQueryKind.libraryAlias,
      );
    }

    final segments = _segments(text, splitOnSpaces);
    final segment = segments.firstWhere(
      (range) => range.start <= cursor && cursor <= range.end,
    );
    final range = _contentRange(text, segment, splitOnSpaces);
    final token = TagNormalizer.normalize(
      text.substring(range.start, range.end),
    );
    final existingTags = <String>{};
    for (final other in segments) {
      if (identical(segment, other)) continue;
      final content = _contentRange(text, other, splitOnSpaces);
      final value = text.substring(content.start, content.end);
      if (!splitOnSpaces && value.contains('<')) continue;
      final normalized = TagNormalizer.normalize(value);
      if (normalized.isNotEmpty) existingTags.add(normalized);
    }

    return CompletionQuery(
      fullText: text,
      cursorPosition: cursor,
      token: token,
      replacementRange: range,
      existingTags: existingTags,
      limit: limit.clamp(1, CompletionResultLimits.all),
      locale: locale,
    );
  }

  /// Inserts after the source tag and its closing syntax, without rewriting it.
  static CompletionQuery? parseRelated({
    required String text,
    required int cursorPosition,
    required int limit,
    required String locale,
    bool splitOnSpaces = false,
  }) {
    final parsed = parse(
      text: text,
      cursorPosition: cursorPosition,
      limit: limit,
      locale: locale,
      splitOnSpaces: splitOnSpaces,
    );
    if (parsed.kind == CompletionQueryKind.libraryAlias) return null;
    if (parsed.token.isEmpty) {
      final before = text
          .substring(0, parsed.replacementRange.start)
          .trimRight();
      if (!before.endsWith(',') && !before.endsWith('，')) return null;
      final previous = parse(
        text: text,
        cursorPosition: before.length - 1,
        limit: limit,
        locale: locale,
        splitOnSpaces: splitOnSpaces,
      );
      if (previous.token.length < 2 ||
          previous.kind == CompletionQueryKind.libraryAlias ||
          previous.token.contains('<')) {
        return null;
      }
      return parsed.copyWith(relatedTag: previous.token);
    }
    if (parsed.token.length < 2 || parsed.token.contains('<')) return null;

    var insertionPosition = parsed.replacementRange.end;
    if (!splitOnSpaces) {
      insertionPosition += _syntaxSuffix
          .firstMatch(text.substring(insertionPosition))!
          .end;
    }
    while (insertionPosition < text.length &&
        _isHorizontalSpace(text[insertionPosition])) {
      insertionPosition++;
    }
    if (insertionPosition < text.length &&
        (text[insertionPosition] == ',' || text[insertionPosition] == '，')) {
      insertionPosition++;
      while (insertionPosition < text.length &&
          _isHorizontalSpace(text[insertionPosition])) {
        insertionPosition++;
      }
    }

    return CompletionQuery(
      fullText: text,
      cursorPosition: insertionPosition,
      token: '',
      replacementRange: TextReplacementRange(
        start: insertionPosition,
        end: insertionPosition,
      ),
      existingTags: {...parsed.existingTags, parsed.token},
      limit: parsed.limit,
      locale: parsed.locale,
      relatedTag: parsed.token,
    );
  }

  static ({String text, int cursorPosition}) apply({
    required String text,
    required CompletionQuery query,
    required String canonicalTag,
    required bool autoInsertComma,
    bool splitOnSpaces = false,
    bool closeOpenWeight = false,
  }) {
    final tag = query.kind == CompletionQueryKind.libraryAlias
        ? '<$canonicalTag>'
        : splitOnSpaces
        ? canonicalTag
        : TagNormalizer.toDisplay(canonicalTag);
    final range = query.replacementRange;
    final before = text.substring(0, range.start);
    var after = text.substring(range.end);

    if (query.relatedTag != null && range.start == range.end) {
      final trimmedBefore = before.trimRight();
      final alreadySeparated =
          trimmedBefore.endsWith(',') ||
          trimmedBefore.endsWith('，') ||
          before.endsWith('\n') ||
          before.endsWith('\r') ||
          (splitOnSpaces && before.endsWith(' '));
      final separator = splitOnSpaces ? ' ' : ', ';
      final prefix = before.isEmpty || alreadySeparated ? '' : separator;
      final leadingSpace =
          before.isNotEmpty &&
              alreadySeparated &&
              !RegExp(r'\s$').hasMatch(before)
          ? ' '
          : '';
      var syntaxSuffix = splitOnSpaces
          ? ''
          : _syntaxSuffix.firstMatch(after)!.group(0)!;
      after = after.substring(syntaxSuffix.length);
      if (syntaxSuffix.startsWith('::')) {
        syntaxSuffix =
            '${NaiWeightSyntax.close(tag).substring(tag.length)}${syntaxSuffix.substring(2)}';
      }
      final hasFollowingTag = after.trimLeft().isNotEmpty;
      final suffix = autoInsertComma || hasFollowingTag ? separator : '';
      final insertion = '$prefix$leadingSpace$tag$syntaxSuffix$suffix';
      return (
        text: '$before$insertion$after',
        cursorPosition: before.length + insertion.length,
      );
    }

    var syntaxSuffix = splitOnSpaces
        ? ''
        : _syntaxSuffix.firstMatch(after)!.group(0)!;
    after = after.substring(syntaxSuffix.length);
    if (closeOpenWeight && !splitOnSpaces && after.isEmpty) {
      final segment = _segments(text, false).last;
      final prefix = text.substring(segment.start, range.start);
      syntaxSuffix = _closeOpenWeight(prefix, syntaxSuffix);
    }
    if (syntaxSuffix.startsWith('::')) {
      syntaxSuffix =
          '${NaiWeightSyntax.close(tag).substring(tag.length)}${syntaxSuffix.substring(2)}';
    }

    var insertion = '$tag$syntaxSuffix';
    if (autoInsertComma) {
      final existingSeparator =
          (splitOnSpaces ? RegExp(r'^\s+') : RegExp(r'^\s*[,，][ \t]*'))
              .firstMatch(after);
      if (existingSeparator == null) {
        insertion += splitOnSpaces ? ' ' : ', ';
      } else {
        insertion += existingSeparator.group(0)!;
        after = after.substring(existingSeparator.end);
      }
    }
    return (
      text: '$before$insertion$after',
      cursorPosition: before.length + insertion.length,
    );
  }

  static List<TextReplacementRange> _segments(String text, bool splitOnSpaces) {
    final result = <TextReplacementRange>[];
    var start = 0;
    var inAlias = false;
    for (var i = 0; i < text.length; i++) {
      final char = text[i];
      if (!splitOnSpaces && char == '<') inAlias = true;
      if (char == '\n' || char == '\r') inAlias = false;
      final separator =
          !inAlias &&
          (char == ',' ||
              char == '，' ||
              char == '\n' ||
              char == '\r' ||
              (splitOnSpaces && _isHorizontalSpace(char)) ||
              (char == '|' &&
                  (i == 0 || text[i - 1] != '|') &&
                  (i + 1 == text.length || text[i + 1] != '|')));
      if (separator) {
        result.add(TextReplacementRange(start: start, end: i));
        start = i + 1;
      }
      if (char == '>') inAlias = false;
    }
    result.add(TextReplacementRange(start: start, end: text.length));
    return result;
  }

  static TextReplacementRange _contentRange(
    String text,
    TextReplacementRange segment,
    bool splitOnSpaces,
  ) {
    var start = segment.start;
    var end = segment.end;
    while (start < end && text[start].trim().isEmpty) {
      start++;
    }
    while (start < end && text[end - 1].trim().isEmpty) {
      end--;
    }
    if (splitOnSpaces) return TextReplacementRange(start: start, end: end);

    while (start < end) {
      final weight = TagNormalizer.weightPrefixPattern.firstMatch(
        text.substring(start, end),
      );
      if (weight != null) {
        start += weight.end;
      } else if ('{[('.contains(text[start]) || text[start].trim().isEmpty) {
        start++;
      } else {
        break;
      }
    }
    while (start < end) {
      final content = text.substring(start, end);
      if (text[end - 1].trim().isEmpty) {
        end--;
      } else if (content.endsWith('::')) {
        end -= 2;
      } else if (_isUnmatchedCloser(content)) {
        end--;
      } else {
        final weight = _weightNumberSuffix.firstMatch(content);
        if (weight == null) break;
        end = start + weight.start;
      }
    }
    return TextReplacementRange(start: start, end: end);
  }

  static bool _isUnmatchedCloser(String content) {
    final index = '}])'.indexOf(content[content.length - 1]);
    if (index < 0) return false;
    final opener = '{[('[index];
    final closer = '}])'[index];
    var depth = 0;
    for (var i = content.length - 1; i >= 0; i--) {
      if (content[i] == closer) depth++;
      if (content[i] == opener) depth--;
      if (depth == 0) return false;
    }
    return true;
  }

  static String _closeOpenWeight(String prefix, String suffix) {
    if (suffix.contains('::')) return suffix;
    final weight = TagNormalizer.weightPattern.firstMatch(prefix);
    if (weight == null) return suffix;
    final outerBrackets = RegExp(
      r'[\{\[\(]',
    ).allMatches(prefix.substring(0, weight.start)).length;
    var index = suffix.length;
    var remaining = outerBrackets;
    while (index > 0 && remaining > 0) {
      index--;
      if ('}])'.contains(suffix[index])) remaining--;
    }
    return '${suffix.substring(0, index)}::${suffix.substring(index)}';
  }

  static bool _isHorizontalSpace(String char) => char == ' ' || char == '\t';
}
