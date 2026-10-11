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

  /// 把 [color] 按 [t] 混到卡片底色上，等价于 CSS `color-mix(color t, card)`。
  Color onCard(Color color, double t) => Color.lerp(card, color, t)!;
}

extension UiColorsContext on BuildContext {
  UiColors get ui => UiColors.of(this);
}
