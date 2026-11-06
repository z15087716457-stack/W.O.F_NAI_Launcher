import 'nai_prompt_syntax.dart';
import 'nai_weight_syntax.dart';

class NaiPromptFormatter {
  static final RegExp _horizontalWhitespace = RegExp(r'[ \t\u3000]+');
  static final RegExp _leadingSpaces = RegExp(r'^ +');
  static final RegExp _trailingSpaces = RegExp(r' +$');
  static final RegExp _unitWeightEnd = RegExp(r'\s*(?:[,，]|::|$)');

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

  /// Remove 1x delimiters only when they leave emphasis and text boundaries
  /// intact. A 1x prefix inside an active weight is an explicit reset.
  static String _removeUnitWeights(String prompt) {
    final tokens = NaiPromptSyntax.scan(prompt);
    final prefixes = <int?>[];
    final remove = <int>{};
    var neutral = true;
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token.kind == NaiPromptTokenKind.prefix) {
        final weight = double.tryParse(
          prompt.substring(token.start, token.end - 2),
        );
        prefixes.add(neutral && weight == 1 ? i : null);
        neutral = weight == 1;
      } else if (token.kind == NaiPromptTokenKind.closure) {
        neutral = true;
        final prefix = prefixes.isEmpty ? null : prefixes.removeLast();
        if (prefix != null &&
            _unitWeightEnd.matchAsPrefix(prompt, token.end) != null) {
          remove.add(prefix);
          remove.add(i);
        }
      } else if ((token.kind == NaiPromptTokenKind.group ||
              token.kind == NaiPromptTokenKind.literal &&
                  prompt.startsWith('||', token.start)) &&
          token.source(prompt).contains('::')) {
        // These tokens can hide a numeric action that changes the active weight.
        prefixes.clear();
        neutral = false;
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
