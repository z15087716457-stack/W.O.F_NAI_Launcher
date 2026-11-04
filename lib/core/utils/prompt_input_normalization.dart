import 'nai_prompt_formatter.dart';
import 'nai_prompt_syntax.dart';
import 'sd_to_nai_converter.dart';

class PromptInputNormalization {
  const PromptInputNormalization({
    required this.text,
    required this.sdConverted,
    required this.formatted,
  });

  final String text;
  final bool sdConverted;
  final bool formatted;

  bool get changed => sdConverted || formatted;

  /// A translated pill can own the whitespace and separator before its neighbour.
  static String normalizeTranslationFragment(
    String source, {
    required bool autoFormat,
    bool preserveLeading = true,
    bool preserveTrailing = true,
  }) {
    if (!autoFormat) return source;
    final prefix = !preserveLeading
        ? ''
        : RegExp(r'^\s+').stringMatch(source) ?? '';
    var bodyEnd = source.length;
    if (preserveTrailing) {
      for (final token in NaiPromptSyntax.scan(source).reversed) {
        if (token.kind == NaiPromptTokenKind.comma) {
          bodyEnd = token.start;
        } else if (token.kind == NaiPromptTokenKind.text) {
          final trailing = RegExp(r'\s+$').firstMatch(token.source(source));
          if (trailing == null) break;
          bodyEnd = token.start + trailing.start;
          if (trailing.start != 0) break;
        } else {
          break;
        }
      }
    }
    if (bodyEnd <= prefix.length) return source;
    final body = normalize(
      source.substring(prefix.length, bodyEnd),
      autoFormat: true,
      sdAutoConvert: false,
    ).text;
    return '$prefix$body${source.substring(bodyEnd)}';
  }

  static PromptInputNormalization normalize(
    String text, {
    required bool autoFormat,
    required bool sdAutoConvert,
  }) {
    final converted = sdAutoConvert ? SdToNaiConverter.convert(text) : text;
    final formatted = autoFormat
        ? sdAutoConvert
              ? NaiPromptFormatter.format(converted)
              : _formatWithoutSdConversion(converted)
        : converted;
    return PromptInputNormalization(
      text: formatted,
      sdConverted: converted != text,
      formatted: formatted != converted,
    );
  }

  static String _formatWithoutSdConversion(String text) {
    // 格式化器兼容 SD 转换，但不能绕过独立的 SD 设置开关。
    final protected = <String, String>{};
    final buffer = StringBuffer();
    var cursor = 0;
    var marker = '\uE000';
    while (text.contains(marker)) {
      marker += '\uE000';
    }
    for (final token in NaiPromptSyntax.scan(text)) {
      if (token.kind != NaiPromptTokenKind.group) continue;
      final source = token.source(text);
      if (!SdToNaiConverter.hasSDWeightSyntax(source)) continue;
      final key = '$marker${protected.length}\uE001';
      protected[key] = source;
      buffer.write(text.substring(cursor, token.start));
      buffer.write(key);
      cursor = token.end;
    }
    buffer.write(text.substring(cursor));
    var result = NaiPromptFormatter.format(buffer.toString());
    for (final entry in protected.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }
}
