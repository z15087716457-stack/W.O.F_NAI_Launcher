/// NovelAI 原生质量词预设。
enum QualityTagPreset {
  standard,
  light,
  none;

  /// Krita bridge 使用的稳定字符串值。
  String get bridgeValue => name;

  static QualityTagPreset? tryParse(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'standard' => QualityTagPreset.standard,
      'light' => QualityTagPreset.light,
      'none' => QualityTagPreset.none,
      _ => null,
    };
  }

  static QualityTagPreset? fromTagHintValue(int? value) {
    return switch (value) {
      1 => QualityTagPreset.standard,
      3 => QualityTagPreset.light,
      0 => QualityTagPreset.none,
      _ => null,
    };
  }
}
