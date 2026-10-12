import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import 'gen_contract.dart';

/// 生图页的取值：原型里主题没有的颜色和格式化（`.devin/mockups/generation/mock.html` 的 CSS 变量）。
abstract final class GenFormat {
  /// 提示词 / 模块底（`--prompt`）：浅色窗口白、深色比窗口更深一级。
  static Color promptBg(UiColors c) => c.dark ? const Color(0xFF0C0C0C) : c.bg;

  /// 浅一级的面（`--psurf`）：历史缩略图底、空态底。
  static Color softBg(UiColors c) =>
      c.dark ? const Color(0xFF161616) : const Color(0xFFF7F7F7);

  /// 页签选中底（`--sel`）。
  static Color selected(UiColors c) =>
      c.dark ? const Color(0xFF1E1E1E) : const Color(0xFFECECEC);

  /// 顶栏胶囊描边（`--capb`）。
  static Color capsuleBorder(UiColors c) =>
      c.dark ? const Color(0xFF262626) : const Color(0xFFE9E9E9);

  /// 浮动工具条投影（`--shadow`）。
  static Color shadow(UiColors c) =>
      c.dark ? const Color(0x52000000) : const Color(0x29000000);

  /// 权重高亮（原型 `.o` / `.b` / `.g`）：加强橙、减弱蓝、`::` 绿。深色多 0.1 不透明度。
  static Color up(UiColors c, double a) =>
      Color.fromRGBO(237, 88, 7, a + (c.dark ? .1 : 0));
  static Color down(UiColors c, double a) =>
      Color.fromRGBO(7, 156, 237, a + (c.dark ? .1 : 0));
  static const colons = Color.fromRGBO(122, 204, 41, .5);

  /// 弱 55% 正文（原型 `.m55`、页签、参数条小标题）。
  static Color ink55(UiColors c) => c.ink.withValues(alpha: .55);

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String clock(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

  /// 千分位（2,218）。
  static String thousands(int v) {
    final s = v.abs().toString();
    final b = StringBuffer(v < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  /// 引导 / 强度这类：5 → “5.0”，0.75 → “0.75”。
  static String decimal(double v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('0') ? v.toStringAsFixed(1) : s;
  }

  /// 百分比：147 → “147%”，12.5 → “12.5%”。
  static String percent(double v) =>
      v == v.roundToDouble() ? '${v.round()}%' : '${v.toStringAsFixed(1)}%';

  /// 历史批次标题前的日期：今天不写，其他“10月4日”。
  static String? day(BuildContext context, DateTime t, DateTime now) {
    final d = DateTime(t.year, t.month, t.day);
    final today = DateTime(now.year, now.month, now.day);
    if (d == today) return null;
    if (today.difference(d).inDays == 1) return context.l10n.gen_yesterday;
    return context.l10n.gen_monthDay(t.month, t.day);
  }

  static String genderLabel(BuildContext context, GenGender g) {
    final l = context.l10n;
    return switch (g) {
      GenGender.female => l.gen_genderFemale,
      GenGender.male => l.gen_genderMale,
      GenGender.other => l.gen_genderOther,
    };
  }

  static String sizeGroupLabel(BuildContext context, GenSizeGroup g) {
    final l = context.l10n;
    return switch (g) {
      GenSizeGroup.normal => l.gen_sizeNormal,
      GenSizeGroup.large => l.gen_sizeLarge,
      GenSizeGroup.wallpaper => l.gen_sizeWallpaper,
      GenSizeGroup.small => l.gen_sizeSmall,
      GenSizeGroup.custom => l.gen_sizeCustom,
    };
  }

  static String orientationLabel(BuildContext context, GenOrientation o) {
    final l = context.l10n;
    return switch (o) {
      GenOrientation.portrait => l.gen_portrait,
      GenOrientation.landscape => l.gen_landscape,
      GenOrientation.square => l.gen_square,
    };
  }

  static GenOrientation orientationOf(int w, int h) => w == h
      ? GenOrientation.square
      : (w > h ? GenOrientation.landscape : GenOrientation.portrait);

  static String preciseTypeLabel(BuildContext context, GenPreciseType t) {
    final l = context.l10n;
    return switch (t) {
      GenPreciseType.character => l.gen_preciseCharacter,
      GenPreciseType.style => l.gen_preciseStyle,
      GenPreciseType.both => l.gen_preciseBoth,
    };
  }

  static String opLabel(BuildContext context, GenOp op) {
    final l = context.l10n;
    return switch (op) {
      GenOp.upscale => l.gen_opUpscale,
      GenOp.enhance => l.gen_opEnhance,
      GenOp.variation => l.gen_opVariation,
      GenOp.inpaint => l.gen_opInpaint,
      GenOp.img2img => l.gen_opImg2Img,
    };
  }

  /// 5 × 5 格的格名（“C3”：列 A–E、行 1–5），V4.5 角色定位用。
  static String cell(Offset p) {
    final col = (p.dx * 5).floor().clamp(0, 4);
    final row = (p.dy * 5).floor().clamp(0, 4);
    return '${String.fromCharCode(65 + col)}${row + 1}';
  }

  /// 吸附到 5 × 5 格中心。
  static Offset snap(Offset p) => Offset(
    ((p.dx * 5).floor().clamp(0, 4) * 2 + 1) / 10,
    ((p.dy * 5).floor().clamp(0, 4) * 2 + 1) / 10,
  );
}
