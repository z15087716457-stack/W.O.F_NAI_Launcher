enum NaiPromptTokenKind { text, comma, prefix, closure, group, literal, opaque }

class NaiPromptToken {
  const NaiPromptToken(this.kind, this.start, this.end);

  final NaiPromptTokenKind kind;
  final int start;
  final int end;

  String source(String text) => text.substring(start, end);
}

abstract final class NaiPromptSyntax {
  static final RegExp _weight = RegExp(r'[-+]?(?:\d+(?:\.\d*)?|\.\d+)::');
  static final RegExp _xml = RegExp(r'<\s*(?:[!?/]|[\w:.-]+\s+[^<>]*=)');

  static bool isXml(String text) => _xml.hasMatch(text);

  static bool _isBoundary(String text, int index) =>
      index == 0 ||
      text[index - 1].trim().isEmpty ||
      ',，{[(|:'.contains(text[index - 1]);

  static bool _isQuote(String text, int index) {
    if (text[index] == '"') return true;
    return text[index] == "'" &&
        (index == 0 || !RegExp(r'[\w]').hasMatch(text[index - 1]));
  }

  static int _quotedEnd(String text, int start) {
    for (var i = start + 1; i < text.length; i++) {
      if (text[i] == r'\') {
        i++;
      } else if (text[i] == text[start]) {
        return i + 1;
      }
    }
    return -1;
  }

  static int _angleEnd(String text, int start) {
    var depth = 1;
    for (var i = start + 1; i < text.length; i++) {
      if (text[i] == r'\') {
        i++;
      } else if (_isQuote(text, i)) {
        final end = _quotedEnd(text, i);
        if (end < 0) return -1;
        i = end - 1;
      } else if (text[i] == '<') {
        depth++;
      } else if (text[i] == '>' && --depth == 0) {
        return i + 1;
      }
    }
    return -1;
  }

  static int _pipeEnd(String text, int start) {
    for (var i = start + 2; i < text.length; i++) {
      if (text[i] == r'\') {
        i++;
      } else if (_isQuote(text, i)) {
        final end = _quotedEnd(text, i);
        if (end < 0) return -1;
        i = end - 1;
      } else if (text.startsWith('||', i)) {
        return i + 2;
      }
    }
    return -1;
  }

  static int _groupEnd(String text, int start) {
    const pairs = {'(': ')', '[': ']', '{': '}'};
    final stack = <String>[pairs[text[start]]!];
    for (var i = start + 1; i < text.length; i++) {
      final char = text[i];
      if (char == r'\') {
        i++;
      } else if (_isQuote(text, i) || char == '<' || text.startsWith('||', i)) {
        final end = char == '<'
            ? _angleEnd(text, i)
            : text.startsWith('||', i)
            ? _pipeEnd(text, i)
            : _quotedEnd(text, i);
        if (end < 0) return -1;
        i = end - 1;
      } else if (pairs.containsKey(char)) {
        stack.add(pairs[char]!);
      } else if (')]}'.contains(char)) {
        if (stack.last != char) return -1;
        stack.removeLast();
        if (stack.isEmpty) return i + 1;
      }
    }
    return -1;
  }

  static List<NaiPromptToken> scan(String text) {
    if (text.isEmpty) return const [];
    if (isXml(text)) {
      return [NaiPromptToken(NaiPromptTokenKind.opaque, 0, text.length)];
    }
    final tokens = <NaiPromptToken>[];
    var plainStart = 0;
    var i = 0;
    while (i < text.length) {
      final char = text[i];
      NaiPromptTokenKind? kind;
      var end = i + 1;
      if (char == r'\') {
        kind = NaiPromptTokenKind.literal;
        end = i + 1 < text.length ? i + 2 : text.length;
      } else if (_isQuote(text, i) || char == '<' || text.startsWith('||', i)) {
        kind = NaiPromptTokenKind.literal;
        end = char == '<'
            ? _angleEnd(text, i)
            : text.startsWith('||', i)
            ? _pipeEnd(text, i)
            : _quotedEnd(text, i);
      } else if ('({['.contains(char)) {
        kind = NaiPromptTokenKind.group;
        end = _groupEnd(text, i);
      } else if (')]}>'.contains(char)) {
        kind = NaiPromptTokenKind.opaque;
        end = text.length;
      } else if (char == ',' || char == '，') {
        kind = NaiPromptTokenKind.comma;
      } else if (_isBoundary(text, i) &&
          _weight.matchAsPrefix(text, i) != null) {
        kind = NaiPromptTokenKind.prefix;
        end = _weight.matchAsPrefix(text, i)!.end;
      } else if (text.startsWith('::', i)) {
        kind = NaiPromptTokenKind.closure;
        end = i + 2;
      }
      if (kind == null) {
        i++;
        continue;
      }
      if (plainStart < i) {
        tokens.add(NaiPromptToken(NaiPromptTokenKind.text, plainStart, i));
      }
      if (end < 0) {
        kind = NaiPromptTokenKind.opaque;
        end = text.length;
      }
      tokens.add(NaiPromptToken(kind, i, end));
      i = end;
      plainStart = i;
    }
    if (plainStart < text.length) {
      tokens.add(
        NaiPromptToken(NaiPromptTokenKind.text, plainStart, text.length),
      );
    }
    return tokens;
  }
}
