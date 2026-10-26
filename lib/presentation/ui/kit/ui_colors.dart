import 'package:flutter/material.dart';

/// 新界面唯一的取色入口。
///
/// 界面组件只从这里拿颜色：不写十六进制，也不直接读 `colorScheme`。
/// 控件底、悬停、正文色取自当前主题；页面 / 卡片 / 描边按原型；
/// 主题里没有对应角色的（更弱的说明色、浮层底、品牌蓝、涨跌色等）按 HTML 原型的取值。
@immutable
class UiColors {
  const UiColors._({
    required this.dark,
    required this.bg,
    required this.page,
    required this.card,
    required this.control,
    required this.hover,
    required this.border,
    required this.strong,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.accent,
    required this.onAccent,
    required this.brand,
    required this.onBrand,
    required this.error,
    required this.ok,
    required this.amber,
    required this.quotaReserve,
    required this.selectedSegment,
    required this.tipBg,
    required this.tipInk,
    required this.panel,
    required this.raised,
    required this.line,
    required this.avatar,
    required this.subWarn,
    required this.fav,
    required this.warn,
    required this.warnBg,
    required this.star,
    required this.weightUp,
    required this.weightUpInk,
    required this.weightDown,
    required this.weightDownInk,
    required this.weightNeg,
    required this.weightNegInk,
    required this.evo,
    required this.evoBg,
    required this.onEvo,
  });

  factory UiColors.of(BuildContext context) =>
      UiColors.fromTheme(Theme.of(context));

  factory UiColors.fromTheme(ThemeData theme) {
    final s = theme.colorScheme;
    final dark = s.brightness == Brightness.dark;
    // 页面 / 卡片 / 描边三层按原型取值（深色是 页面 0e < 顶栏 11 < 卡片 16），
    // 不改共用的 GeistTheme，旧界面不受影响。
    return UiColors._(
      dark: dark,
      bg: s.surface,
      page: dark ? const Color(0xFF0E0E0E) : const Color(0xFFFAFAFA),
      card: dark ? const Color(0xFF161616) : Colors.white,
      control: s.surfaceContainerHighest,
      hover: s.surfaceContainerHigh,
      border: dark ? const Color(0xFF262626) : const Color(0xFFE8E8E8),
      strong: s.outline,
      ink: s.onSurface,
      muted: s.onSurfaceVariant,
      faint: dark ? const Color(0xFF7A7A7A) : const Color(0xFF8F8F8F),
      accent: s.primary,
      onAccent: s.onPrimary,
      brand: const Color(0xFF005DFF),
      onBrand: Colors.white,
      error: s.error,
      ok: dark ? const Color(0xFF3DD68C) : const Color(0xFF2B9A66),
      amber: dark ? const Color(0xFFF5B546) : const Color(0xFFF0A020),
      quotaReserve: dark ? const Color(0xFFB49AFF) : const Color(0xFF7C3AED),
      selectedSegment: dark ? const Color(0xFF333333) : s.surfaceContainer,
      tipBg: dark ? const Color(0xFFECECEC) : const Color(0xFF1F1F1F),
      tipInk: dark ? const Color(0xFF171717) : const Color(0xFFF2F2F2),
      panel: s.surfaceContainerLow,
      raised: s.surfaceContainer,
      line: s.outlineVariant,
      avatar: const Color(0xFF0160FB),
      subWarn: dark ? const Color(0xFFD9A441) : const Color(0xFF98691D),
      fav: dark ? const Color(0xFFFF6369) : const Color(0xFFE5484D),
      warn: dark ? const Color(0xFFF1A10D) : const Color(0xFFB86E00),
      warnBg: dark ? const Color(0xFF2A2110) : const Color(0xFFFFF6E5),
      star: dark ? const Color(0xFFFFB224) : const Color(0xFFF5A400),
      weightUp: dark ? const Color(0xFF3A2A10) : const Color(0xFFFFF1DC),
      weightUpInk: dark ? const Color(0xFFFFB547) : const Color(0xFFA85B00),
      weightDown: dark ? const Color(0xFF10264A) : const Color(0xFFE6F0FF),
      weightDownInk: dark ? const Color(0xFF7CB8FF) : const Color(0xFF0057C2),
      weightNeg: dark ? const Color(0xFF3D1418) : const Color(0xFFFFE8EA),
      weightNegInk: dark ? const Color(0xFFFF7A80) : const Color(0xFFC80029),
      evo: dark ? const Color(0xFF9E8CFC) : const Color(0xFF6E56CF),
      evoBg: dark ? const Color(0xFF1D1830) : const Color(0xFFF3F0FF),
      onEvo: dark ? const Color(0xFF140F2B) : Colors.white,
    );
  }

  final bool dark;

  /// 顶栏等“窗口底色”。
  final Color bg;

  /// 页面内容区底色（卡片下面那层）。
  final Color page;

  /// 卡片底色。
  final Color card;

  /// 控件底：分段控件、小格子、进度条底槽。
  final Color control;

  /// 悬停底。
  final Color hover;

  /// 1px 描边、分隔线。
  final Color border;

  /// 较深的描边，也用作“次要”的图形色。
  final Color strong;

  /// 正文。
  final Color ink;

  /// 次要文字。
  final Color muted;

  /// 更弱的说明文字。
  final Color faint;

  /// 强调色（选中、可点链接、主数据色）。
  final Color accent;
  final Color onAccent;

  /// 品牌蓝，只用于主按钮。
  final Color brand;
  final Color onBrand;

  final Color error;

  /// 上涨。
  final Color ok;

  /// Anlas 色。
  final Color amber;

  /// 已激活的备用额度，独立于 Anlas 与普通告警色。
  final Color quotaReserve;

  Color quotaAccent(double percent, {bool usingReserve = false}) => usingReserve
      ? quotaReserve
      : percent < 5
      ? error
      : percent < 20
      ? warn
      : accent;

  /// 分段控件选中项的底。
  final Color selectedSegment;

  /// 悬停提示浮层。
  final Color tipBg;
  final Color tipInk;

  /// 面板底（账号弹窗等大浮层）。
  final Color panel;

  /// 抬起的浮层底（后台任务、自定义面板、菜单）。
  final Color raised;

  /// 主题描边（主导航、浮层用 Geist 原值；统计页卡片用 [border]）。
  final Color line;

  /// 首字头像底色（W.O.F 品牌蓝，所有账号同色）。
  final Color avatar;

  /// 订阅快到期 / 已过期的琥珀色。
  final Color subWarn;

  /// 收藏心形。
  final Color fav;

  /// 提醒（未登录等）的琥珀色文字。
  final Color warn;

  /// 提醒横幅 / 提示框的浅琥珀底。
  final Color warnBg;

  /// 收藏星。
  final Color star;

  /// 提示词权重高亮（大图信息栏）：权重大于 1 暖色、小于 1 冷色、负数红色；底色 + 权重数字色。
  final Color weightUp;
  final Color weightUpInk;
  final Color weightDown;
  final Color weightDownInk;
  final Color weightNeg;
  final Color weightNegInk;

  /// 进化（画风探索）：紫色主色、浅紫底、紫底上的字色。
  final Color evo;
  final Color evoBg;
  final Color onEvo;

  /// 把 [color] 按 [t] 混到卡片底色上，等价于 CSS `color-mix(color t, card)`。
  Color onCard(Color color, double t) => Color.lerp(card, color, t)!;
}

extension UiColorsContext on BuildContext {
  UiColors get ui => UiColors.of(this);
}

/// 可框选文字的行内底色：半透明色叠在 [base] 上与不透明的 [target] 看起来一样。
/// Flutter 的段落先画选区、再画带 `background` 的文字，不透明底色会盖住选区，
/// 框选时像“穿过”了这些词（10-24 反馈）；按 [alpha] 透出选区。
Color uiSelectableTint(Color target, Color base, [double alpha = .35]) {
  int ch(double t, double b) =>
      ((t - (1 - alpha) * b) / alpha * 255).round().clamp(0, 255);
  return Color.fromARGB(
    (alpha * 255).round(),
    ch(target.r, base.r),
    ch(target.g, base.g),
    ch(target.b, base.b),
  );
}
