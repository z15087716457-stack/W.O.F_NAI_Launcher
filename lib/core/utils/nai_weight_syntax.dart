import 'nai_prompt_syntax.dart';

abstract final class NaiWeightSyntax {
  static final RegExp _unsafeTail = RegExp(r'[0-9.]$');

  static String wrap(String weight, String content) =>
      close('$weight::$content');

  static String close(String contentWithPrefix) =>
      '$contentWithPrefix${_unsafeTail.hasMatch(contentWithPrefix) ? ' ' : ''}::';

  static String guardClosures(String text) {
    final buffer = StringBuffer();
    var weighted = false;
    for (final token in NaiPromptSyntax.scan(text)) {
      final source = token.source(text);
      switch (token.kind) {
        case NaiPromptTokenKind.prefix:
          weighted = true;
        case NaiPromptTokenKind.closure:
          if (weighted &&
              token.start > 0 &&
              _unsafeTail.hasMatch(
                text.substring(token.start - 1, token.start),
              )) {
            buffer.write(' ');
          }
          weighted = false;
        case NaiPromptTokenKind.group:
          buffer.write(source[0]);
          buffer.write(guardClosures(source.substring(1, source.length - 1)));
          buffer.write(source[source.length - 1]);
          continue;
        case NaiPromptTokenKind.text:
        case NaiPromptTokenKind.comma:
        case NaiPromptTokenKind.literal:
        case NaiPromptTokenKind.opaque:
          break;
      }
      buffer.write(source);
    }
    return buffer.toString();
  }
}
