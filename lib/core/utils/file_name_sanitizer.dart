/// 文件名清洗工具。
///
/// 默认替换 Windows/Unix 文件系统非法字符和 ASCII 控制字符，并去掉首尾空白。
class FileNameSanitizer {
  FileNameSanitizer._();

  static final RegExp _invalidFileNameChars = RegExp(r'[<>:"/\\|?*\x00-\x1F]');
  static final RegExp _invalidFileNameCharsWithoutControls = RegExp(
    r'[<>:"/\\|?*]',
  );
  static final RegExp _whitespacePattern = RegExp(r'\s+');

  static String sanitize(
    String value, {
    String fallback = 'file',
    int? maxLength,
    bool collapseWhitespace = false,
    bool replaceControlChars = true,
  }) {
    final invalidPattern = replaceControlChars
        ? _invalidFileNameChars
        : _invalidFileNameCharsWithoutControls;

    var sanitized = value;
    if (collapseWhitespace) {
      sanitized = sanitized.replaceAll(_whitespacePattern, ' ');
    }
    sanitized = sanitized.replaceAll(invalidPattern, '_');
    sanitized = sanitized.trim();

    if (maxLength != null && maxLength > 0 && sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }

    if (sanitized.isEmpty) return fallback;
    return sanitized;
  }
}
