import 'nai_prompt_syntax.dart';
import 'nai_weight_syntax.dart';

class NaiPromptFormatter {
  static final RegExp _horizontalWhitespace = RegExp(r'[ \t\u3000]+');
  static final RegExp _leadingSpaces = RegExp(r'^ +');
  static final RegExp _trailingSpaces = RegExp(r' +$');

  static String formatTag(String tag) => format(tag);

  static String format(String prompt) {
    prompt = _removeUnitWeights(prompt);
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

  /// A complete 1x NAI weight has the same effect as its contents. Work from
  /// syntax tokens so quoted text, aliases, escapes, and unfinished weights
  /// keep their original spelling.
  static String _removeUnitWeights(String prompt) {
    final tokens = NaiPromptSyntax.scan(prompt);
    final prefixes = <int>[];
    final remove = <int>{};
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token.kind == NaiPromptTokenKind.prefix) {
        prefixes.add(i);
      } else if (token.kind == NaiPromptTokenKind.closure &&
          prefixes.isNotEmpty) {
        final prefix = prefixes.removeLast();
        final source = tokens[prefix].source(prompt);
        if (double.tryParse(source.substring(0, source.length - 2)) == 1) {
          remove.add(prefix);
          remove.add(i);
        }
      }
    }
    if (remove.isEmpty) return prompt;
    final buffer = StringBuffer();
    for (var i = 0; i < tokens.length; i++) {
      if (!remove.contains(i)) buffer.write(tokens[i].source(prompt));
    }
    return buffer.toString();
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
