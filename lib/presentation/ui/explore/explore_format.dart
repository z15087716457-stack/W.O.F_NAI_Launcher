import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../l10n/app_localizations.dart';
import '../kit/ui_colors.dart';
import 'explore_contract.dart';

/// 画风探索页的取值：原型里主题没有的颜色和格式化。
abstract final class ExploreFormat {
  /// 提示词模块底（原型 `--prompt`）：浅色窗口白、深色比窗口更深一级。
  static Color promptBg(UiColors c) => c.dark ? const Color(0xFF0C0C0C) : c.bg;

  /// 页签选中底（原型 `--sel`）。
  static Color selected(UiColors c) =>
      c.dark ? const Color(0xFF1E1E1E) : const Color(0xFFECECEC);

  /// 编辑列胶囊描边（原型 `--capb`）。
  static Color capsuleBorder(UiColors c) =>
      c.dark ? const Color(0xFF262626) : const Color(0xFFE9E9E9);

  /// 投影色（原型 `--shadow`）。
  static Color shadow(UiColors c) =>
      c.dark ? const Color(0x66000000) : const Color(0x24000000);

  /// 子代来源角标：变异橙、交叉紫、注入青（深浅色同值，压在图上）。
  static Color opColor(ExploreOp op) => switch (op) {
    ExploreOp.mutation => const Color(0xFFC2410C),
    ExploreOp.crossover => const Color(0xFF6E56CF),
    ExploreOp.injection => const Color(0xFF0E7490),
  };

  static String opLabel(AppLocalizations l, ExploreOp op) => switch (op) {
    ExploreOp.mutation => l.explore_opMutation,
    ExploreOp.crossover => l.explore_opCrossover,
    ExploreOp.injection => l.explore_opInjection,
  };

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String clock(DateTime t) => '${_two(t.hour)}:${_two(t.minute)}';

  /// “今天 18:54 / 昨天 18:54 / 10月4日 21:03 / 2025年9月21日”。
  static String when(BuildContext context, DateTime t, DateTime now) {
    final l = context.l10n;
    final day = DateTime(t.year, t.month, t.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return l.explore_today(clock(t));
    if (diff == 1) return l.explore_yesterday(clock(t));
    if (t.year == now.year) {
      return l.explore_monthDay(t.month, t.day, clock(t));
    }
    return l.explore_fullDate(t.year, t.month, t.day);
  }

  /// 下拉分段：0 今天、1 本周（7 天内）、2 更早。
  static int bucket(DateTime t, DateTime now) {
    final day = DateTime(t.year, t.month, t.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    return diff <= 0 ? 0 : (diff < 7 ? 1 : 2);
  }

  static String seconds(Duration d) =>
      '${(d.inMilliseconds / 1000).toStringAsFixed(1)} s';

  static String scale(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(1) : '$v';

  /// 偏好值：两位以内小数，去掉多余的 0（3.0 → “3.0”，0.75 → “0.75”）。
  static String pref(double v) {
    final s = v.toStringAsFixed(2);
    return s.endsWith('0') ? v.toStringAsFixed(1) : s;
  }

  /// 画师串（复制、父本串）：原始片段逗号连接。
  static String atomsRaw(Iterable<ExploreAtom> atoms) =>
      atoms.map((a) => a.raw).join(', ');
}
