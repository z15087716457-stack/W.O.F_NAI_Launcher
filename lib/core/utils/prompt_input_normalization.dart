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
