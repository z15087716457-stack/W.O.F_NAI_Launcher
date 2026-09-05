import 'nai_prompt_syntax.dart';
import 'nai_weight_syntax.dart';
import 'tag_normalizer.dart';

/// SD权重语法到NAI V4数值语法的转换工具
///
/// 转换规则：
/// - SD格式: (text:1.5) 或 [text:0.8]
/// - NAI V4格式: 1.5::text::
/// - 不带数值权重的 `(text)`、`[text]` 保持原样
///
/// 参考: https://github.com/Metachs/sdwebui-nai-api
class SdToNaiConverter {
  SdToNaiConverter._();

  /// 检测文本是否包含带数值的 SD 权重语法。
  ///
  /// 普通圆括号和方括号也可用于 NAI 提示词，因此不据此推断 SD 权重。
  static bool hasSDWeightSyntax(String text) {
    return _chunks(
      text,
    ).any((chunk) => chunk.convertible && _hasExplicitWeightSyntax(chunk.text));
  }

  /// 检测明确的权重语法：(text:weight) 或 [text:weight]
  static bool _hasExplicitWeightSyntax(String text) {
    for (var index = 0; index < text.length; index++) {
      final openChar = text[index];
      if ((openChar != '(' && openChar != '[') || _isEscaped(text, index)) {
        continue;
      }

      final closeChar = openChar == '(' ? ')' : ']';
      final closeIndex = _findMatchingCloseBracket(
        text,
        index,
        openChar,
        closeChar,
      );
      if (closeIndex < 0) continue;

      final content = text.substring(index + 1, closeIndex);
      if (_extractExplicitWeight(content) != null) {
        return true;
      }
    }
    return false;
  }

  /// 检查字符是否被转义
  static bool _isEscaped(String text, int index) {
    if (index == 0) return false;
    var backslashCount = 0;
    for (var j = index - 1; j >= 0 && text[j] == r'\'; j--) {
      backslashCount++;
    }
    return backslashCount % 2 == 1;
  }

  /// 找到匹配的闭括号位置
  static int _findMatchingCloseBracket(
    String text,
    int openIndex,
    String openChar,
    String closeChar,
  ) {
    var depth = 1;
    for (var i = openIndex + 1; i < text.length; i++) {
      if (text[i] == openChar && !_isEscaped(text, i)) {
        depth++;
      } else if (text[i] == closeChar && !_isEscaped(text, i)) {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1; // 未找到
  }

  /// 检测文本是否已经包含NAI语法
  static bool hasNAISyntax(String text) {
    // NAI V4数值语法: weight::text:: (数字后跟双冒号，支持 1.5:: 或 .5:: 格式)
    if (TagNormalizer.weightPattern.hasMatch(text)) return true;

    // NAI花括号语法: 检测成对的花括号 {...}
    // 简单检查：有 { 后面跟着 }（允许嵌套）
    var braceDepth = 0;
    var foundClosedBrace = false;
    for (var i = 0; i < text.length; i++) {
      if (text[i] == '{') {
        braceDepth++;
      } else if (text[i] == '}') {
        if (braceDepth > 0) {
          braceDepth--;
          foundClosedBrace = true;
        }
      }
    }
    if (foundClosedBrace) return true;

    return false;
  }

  /// SD语法转NAI V4数值语法
  ///
  /// 示例:
  /// - `(text:1.5)` → `1.5::text::`
  /// - `[text:0.8]` → `0.8::text::`
  /// - `(long hair)` → `(long hair)` (保留 NAI 可用的括号)
  /// - `[ugly]` → `[ugly]` (保留 NAI 弱化语法)
  /// - `\(text\)` → `(text)` (移除圆括号转义符)
  ///
  /// 仅转换明确的 SD 权重，保留其他文本的空格与语法作用域。
  static String convert(String text) {
    return _chunks(text).map((chunk) {
      if (!chunk.convertible) return chunk.text;
      if (_hasExplicitWeightSyntax(chunk.text)) {
        return _buildNaiV4(_parsePromptAttention(chunk.text));
      }
      return _processEscapedParentheses(chunk.text);
    }).join();
  }

  static bool _protectedToken(NaiPromptToken token, String text) {
    if (token.kind == NaiPromptTokenKind.opaque) return true;
    final source = token.source(text);
    if (token.kind == NaiPromptTokenKind.literal) {
      return !source.startsWith(r'\');
    }
    if (token.kind == NaiPromptTokenKind.group) {
      final inner = source.substring(1, source.length - 1);
      return NaiPromptSyntax.scan(inner).any(
        (token) =>
            _protectedToken(token, inner) ||
            token.kind == NaiPromptTokenKind.prefix ||
            token.kind == NaiPromptTokenKind.closure,
      );
    }
    return false;
  }

  static Iterable<({String text, bool convertible})> _chunks(
    String text,
  ) sync* {
    final buffer = StringBuffer();
    var weighted = false;
    for (final token in NaiPromptSyntax.scan(text)) {
      final source = token.source(text);
      final protected =
          weighted ||
          _protectedToken(token, text) ||
          token.kind == NaiPromptTokenKind.prefix;
      if (token.kind == NaiPromptTokenKind.prefix) weighted = true;
      if (token.kind == NaiPromptTokenKind.closure) weighted = false;
      if (protected) {
        if (buffer.isNotEmpty) {
          yield (text: buffer.toString(), convertible: true);
          buffer.clear();
        }
        yield (text: source, convertible: false);
      } else {
        buffer.write(source);
      }
    }
    if (buffer.isNotEmpty) {
      yield (text: buffer.toString(), convertible: true);
    }
  }

  /// 解析SD权重语法
  /// 返回 List<[text, weight]>
  static List<List<dynamic>> _parsePromptAttention(String text) {
    final res = <List<dynamic>>[];

    var i = 0;
    while (i < text.length) {
      final char = text[i];

      // 检查是否是转义序列
      if (char == r'\' && i + 1 < text.length) {
        final nextChar = text[i + 1];
        if (nextChar == '(' ||
            nextChar == ')' ||
            nextChar == '[' ||
            nextChar == ']') {
          // 转义括号：保留原字符，移除反斜杠
          res.add([nextChar, 1.0]);
          i += 2;
          continue;
        } else if (nextChar == r'\') {
          // 转义的反斜杠：保留一个反斜杠
          res.add([r'\', 1.0]);
          i += 2;
          continue;
        }
      }

      // 处理开括号
      if (char == '(' || char == '[') {
        final closeChar = char == '(' ? ')' : ']';

        // 找到对应的闭括号
        final closeIndex = _findMatchingCloseBracket(text, i, char, closeChar);
        if (closeIndex == -1) {
          // 未闭合，作为普通文本
          res.add([char, 1.0]);
          i++;
          continue;
        }

        final content = text.substring(i + 1, closeIndex);

        // 检查是否是 (text:weight) 明确权重格式
        final explicitWeight = _extractExplicitWeight(content);
        if (explicitWeight != null) {
          // 明确权重格式：直接添加带权重的文本
          var actualContent = content.substring(0, content.lastIndexOf(':'));
          // 处理内容中的转义字符
          actualContent = _processEscapes(actualContent.trim());
          res.add([actualContent, explicitWeight]);
          // 跳过整个括号
          i = closeIndex + 1;
          continue;
        }

        // 普通括号属于 NAI 提示词内容，逐字保留。
        res.add([char, 1.0]);
        i++;
        continue;
      }

      // 普通文本字符
      res.add([char, 1.0]);
      i++;
    }

    if (res.isEmpty) {
      res.add(['', 1.0]);
    }

    // 合并连续文本
    return _mergeConsecutiveChars(res);
  }

  /// 处理文本中的转义字符
  /// 将 \( \) \[ \] \\ 转换为 ( ) [ ] \
  static String _processEscapes(String text) {
    final buffer = StringBuffer();
    var i = 0;
    while (i < text.length) {
      if (text[i] == r'\' && i + 1 < text.length) {
        final nextChar = text[i + 1];
        if (nextChar == '(' ||
            nextChar == ')' ||
            nextChar == '[' ||
            nextChar == ']' ||
            nextChar == r'\') {
          buffer.write(nextChar);
          i += 2;
          continue;
        }
      }
      buffer.write(text[i]);
      i++;
    }
    return buffer.toString();
  }

  /// 处理不进入权重转换路径时的字面括号转义。
  ///
  /// 只解开用户明确要求的 `\(` 和 `\)`，避免在普通提示词早退路径中
  /// 顺带改写 `\[`、`\]` 或 `\\` 等其它内容。
  static String _processEscapedParentheses(String text) {
    final buffer = StringBuffer();
    var i = 0;
    while (i < text.length) {
      if (text[i] == r'\' && i + 1 < text.length) {
        final nextChar = text[i + 1];
        if (nextChar == '(' || nextChar == ')') {
          buffer.write(nextChar);
          i += 2;
          continue;
        }
      }
      buffer.write(text[i]);
      i++;
    }
    return buffer.toString();
  }

  /// 从括号内容中提取明确的权重值
  /// 匹配格式: "text:weight" 返回 weight
  /// 如果不是明确权重格式，返回 null
  static double? _extractExplicitWeight(String content) {
    // 查找最后一个冒号
    final colonIndex = content.lastIndexOf(':');
    if (colonIndex == -1 ||
        colonIndex == 0 ||
        colonIndex == content.length - 1) {
      return null;
    }

    final beforeColon = content.substring(0, colonIndex).trim();
    final afterColon = content.substring(colonIndex + 1).trim();

    // 检查冒号后面是否是有效的数字
    final weight = double.tryParse(afterColon);
    if (weight == null || !weight.isFinite) {
      return null;
    }

    // 检查冒号前面是否有内容
    if (beforeColon.isEmpty) {
      return null;
    }

    // 确保冒号前面没有嵌套的权重语法（避免误解析）
    // 如果前面还有冒号，可能是嵌套或其他格式，不处理
    if (beforeColon.contains(':')) {
      return null;
    }

    return weight;
  }

  /// 合并连续的字符为字符串
  static List<List<dynamic>> _mergeConsecutiveChars(List<List<dynamic>> chars) {
    if (chars.isEmpty) return chars;

    final res = <List<dynamic>>[];
    final buffer = StringBuffer();
    double currentWeight = 1.0;

    for (final item in chars) {
      final char = item[0] as String;
      final weight = item[1] as double;

      if ((weight - currentWeight).abs() < 0.00001) {
        // 权重相同，追加到缓冲区
        buffer.write(char);
      } else {
        // 权重不同，保存之前的缓冲区
        if (buffer.isNotEmpty) {
          res.add([buffer.toString(), currentWeight]);
          buffer.clear();
        }
        buffer.write(char);
        currentWeight = weight;
      }
    }

    // 保存最后的内容
    if (buffer.isNotEmpty) {
      res.add([buffer.toString(), currentWeight]);
    }

    // 合并相同权重的连续项（二次确认）
    var i = 0;
    while (i + 1 < res.length) {
      final w1 = res[i][1] as double;
      final w2 = res[i + 1][1] as double;
      if ((w1 - w2).abs() < 0.00001) {
        res[i][0] = '${res[i][0]}${res[i + 1][0]}';
        res.removeAt(i + 1);
      } else {
        i++;
      }
    }

    return res;
  }

  /// 构建NAI V4数值语法
  static String _buildNaiV4(List<List<dynamic>> parsed) {
    final buffer = StringBuffer();
    var isOpen = false;

    void closeWeight() {
      final content = buffer.toString();
      buffer.write(NaiWeightSyntax.close(content).substring(content.length));
    }

    for (final item in parsed) {
      var s = item[0] as String;
      final w = item[1] as double;

      var weightStr = w.toStringAsFixed(5);
      weightStr = weightStr.replaceAll(RegExp(r'0+$'), '');
      weightStr = weightStr.replaceAll(RegExp(r'\.$'), '');
      final hasWeight = weightStr != '1';
      s = _processEscapes(s);

      if (hasWeight) {
        s = s.trim();
        if (isOpen) closeWeight();

        var sep = '';
        final combined = '$buffer$weightStr';
        final match = RegExp(r'-?\d*\.?\d*$').firstMatch(combined);
        if (match != null && match.group(0) != weightStr) sep = ' ';

        buffer.write('$sep$weightStr::$s');
        isOpen = true;
      } else {
        if (isOpen) {
          closeWeight();
          isOpen = false;
        }
        buffer.write(s);
      }
    }

    if (isOpen) closeWeight();
    return buffer.toString();
  }
}
