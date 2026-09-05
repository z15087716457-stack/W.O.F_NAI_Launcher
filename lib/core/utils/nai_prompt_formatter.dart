import 'nai_prompt_syntax.dart';
import 'nai_weight_syntax.dart';

class NaiPromptFormatter {
  static final RegExp _horizontalWhitespace = RegExp(r'[ \t\u3000]+');
  static final RegExp _leadingSpaces = RegExp(r'^ +');
  static final RegExp _trailingSpaces = RegExp(r' +$');

  static String formatTag(String tag) => format(tag);

  static String format(String prompt) {
    final tokens = NaiPromptSyntax.scan(prompt);
    final buffer = StringBuffer();
    final segment = <NaiPromptToken>[];
    final lineBreaks = StringBuffer();
    var hasSegment = false;
    int? openWeight;

    void appendSegment() {
      final formatted = _formatSegment(prompt, segment, openWeight);
      segment.clear();
      if (formatted.trim().isEmpty) {
        lineBreaks.write(formatted.replaceAll(_horizontalWhitespace, ''));
        return;
      }
      if (hasSegment) {
        buffer.write(',');
        if (lineBreaks.isEmpty &&
            !formatted.startsWith('\n') &&
            !formatted.startsWith('\r')) {
          buffer.write(' ');
        }
      }
      buffer.write(lineBreaks);
      lineBreaks.clear();
      buffer.write(formatted);
      hasSegment = true;
    }

    for (final token in tokens) {
      if (token.kind == NaiPromptTokenKind.prefix) {
        openWeight = token.start;
      } else if (token.kind == NaiPromptTokenKind.closure) {
        openWeight = null;
      }
      if (token.kind == NaiPromptTokenKind.comma && openWeight == null) {
        appendSegment();
      } else {
        segment.add(token);
      }
    }
    appendSegment();
    buffer.write(lineBreaks);
    return NaiWeightSyntax.guardClosures(buffer.toString());
  }

  static String _formatSegment(
    String prompt,
    List<NaiPromptToken> tokens,
    int? openWeight,
  ) {
    final buffer = StringBuffer();
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      var source = token.source(prompt);
      if (token.kind == NaiPromptTokenKind.text &&
          (openWeight == null || token.start < openWeight)) {
        source = source.replaceAll(_horizontalWhitespace, ' ');
        if (i == 0) source = source.replaceFirst(_leadingSpaces, '');
        if (i == tokens.length - 1) {
          source = source.replaceFirst(_trailingSpaces, '');
        }
      }
      buffer.write(source);
    }
    return buffer.toString();
  }
}
