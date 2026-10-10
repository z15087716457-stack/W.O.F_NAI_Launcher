import 'package:flutter/material.dart';

import '../../themes/studio_typography.dart';

/// 新界面的文字样式。
///
/// 正文 HarmonyOS Sans SC，数字用 Geist Mono 并开等宽数字；行高按 CSS 的
/// 半行距分配（`leadingDistribution: even`），所以和 HTML 原型里同字号、同行高的
/// 文字落在同一位置。[height] 传 null 等价于 CSS `line-height: normal`（原型里 `font:` 简写的地方）。
abstract final class UiText {
  static TextStyle sans(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height = 1.45,
    double letterSpacing = 0,
  }) => StudioTypography.body.copyWith(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  static TextStyle mono(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height = 1.45,
    double letterSpacing = 0,
  }) => StudioTypography.data.copyWith(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
    fontFeatures: const [FontFeature.tabularFigures()],
  );
}
