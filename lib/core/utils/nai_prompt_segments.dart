import 'nai_prompt_syntax.dart';

List<String> splitNaiPromptSegments(String prompt) {
  final tokens = NaiPromptSyntax.scan(prompt);
  final segments = <String>[];
  var start = 0;
  var weighted = false;
  for (var i = 0; i < tokens.length; i++) {
    final token = tokens[i];
    if (token.kind == NaiPromptTokenKind.prefix) {
      weighted = true;
    } else if (token.kind == NaiPromptTokenKind.closure) {
      weighted = false;
    } else if (token.kind == NaiPromptTokenKind.comma) {
      var next = i + 1;
      while (next < tokens.length &&
          tokens[next].kind == NaiPromptTokenKind.text &&
          tokens[next].source(prompt).trim().isEmpty) {
        next++;
      }
      final implicitBoundary =
          weighted &&
          next < tokens.length &&
          tokens[next].kind == NaiPromptTokenKind.prefix;
      if (!weighted || implicitBoundary) {
        final segment = prompt.substring(start, token.start).trim();
        if (segment.isNotEmpty) segments.add(segment);
        start = token.end;
        weighted = false;
      }
    }
  }
  final last = prompt.substring(start).trim();
  if (last.isNotEmpty) segments.add(last);
  return segments;
}
