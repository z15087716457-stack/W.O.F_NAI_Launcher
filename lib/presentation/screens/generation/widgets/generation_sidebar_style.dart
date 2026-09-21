import 'package:flutter/material.dart';

/// 官网式生成左栏共享视觉规格。
///
/// 官网实测（live DOM）：小节标签 14px/400/line21、弱色；
/// 模块标题 16px/600/line24（Character Prompts / Resolution /
/// Number of Images / Vibe Transfer）；Base/Undesired 页签 14px/600；
/// 左栏横向沟槽 12、卡片内沟槽 12。中文客户端采用紧凑等效档：
/// 标签 13/400、标题 15/600、页签 13/600，两级字号差保持可见层级。
final class GenSidebarStyle {
  GenSidebarStyle._();

  /// 左栏滚动区横向沟槽（官网 12px）。
  static const double paneGutter = 12;

  /// 卡片内容横向沟槽（官网 12px）。
  static const double cardGutter = 12;

  /// 滚动列中相邻模块间距。
  static const double sectionGap = 12;

  /// 同一小节内相邻卡片间距。
  static const double cardGap = 8;

  /// A single darker writing surface, shared by the main and character cards.
  static Color promptSurface(ThemeData theme) => Color.lerp(
    theme.colorScheme.surface,
    theme.brightness == Brightness.dark ? Colors.black : Colors.white,
    theme.brightness == Brightness.dark ? 0.3 : 0.6,
  )!;

  static Color border(ThemeData theme) =>
      theme.colorScheme.outlineVariant;

  static Color selectedSurface(ThemeData theme) => Color.alphaBlend(
    theme.colorScheme.onSurface.withValues(alpha: .08),
    theme.colorScheme.surface,
  );

  /// Custom themes may alias all surfaceContainer slots to the same color.
  static Color panelSurface(ThemeData theme) => Color.alphaBlend(
    theme.colorScheme.onSurface.withValues(alpha: .035),
    theme.colorScheme.surface,
  );

  /// 小节标签（官网 `Reference Images` / `Image Settings` 同款：
  /// 小字、常规字重、弱色，只做分组提示）。
  static TextStyle sectionLabel(ThemeData theme) =>
      (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
      );

  /// 小节标签下方的辅助说明行（官网 `Create a separate prompt...` 同款）。
  static TextStyle sectionSubtitle(ThemeData theme) =>
      (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
        fontSize: 12,
        height: 1.4,
        color: theme.colorScheme.onSurfaceVariant,
      );

  /// 模块标题（官网 `Character Prompts` / `Resolution` /
  /// `Number of Images` / `Vibe Transfer` 同款：明显大于小节标签、半粗）。
  static TextStyle sectionTitle(ThemeData theme) =>
      (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.45,
        color: theme.colorScheme.onSurface,
      );

  /// 提示词页签（官网 `Base` / `Undesired Content` 同款：选中半粗、
  /// 未选中弱色，中性底色高亮、不带主题色）。
  static TextStyle tabLabel(ThemeData theme, {required bool selected}) =>
      (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
        fontSize: 13,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: selected
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurface.withValues(alpha: 0.55),
      );

  /// 次级字段标签（Position 行等控件前缀）。
  static TextStyle fieldLabel(ThemeData theme) =>
      (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
      );
}

/// 把 `titleSmall` 提升为模块标题规格的作用域。
///
/// 仍输出 `ParamSectionTitle`（titleSmall + w600）的分节控件
/// （SizeSelector 标题行、ImageCountSection 等）包一层即套用
/// 官网式 15/600 标题档，无需改动控件自身。
class SidebarTitleScope extends StatelessWidget {
  final Widget child;

  const SidebarTitleScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.copyWith(
          titleSmall: GenSidebarStyle.sectionTitle(theme),
        ),
      ),
      child: child,
    );
  }
}

/// A neutral inset segment with its own ink surface. This keeps hover/focus
/// visible even when the surrounding theme uses identical surface colors.
class SidebarSegmentButton extends StatelessWidget {
  const SidebarSegmentButton({
    super.key,
    required this.selected,
    required this.onPressed,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
    this.backgroundColor,
  });

  final bool selected;
  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(3);
    return Semantics(
      selected: selected,
      button: true,
      enabled: onPressed != null,
      child: Material(
        color:
            backgroundColor ??
            (selected
                ? GenSidebarStyle.selectedSurface(theme)
                : Colors.transparent),
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          borderRadius: radius,
          hoverColor: theme.colorScheme.onSurface.withValues(alpha: .07),
          focusColor: theme.colorScheme.onSurface.withValues(alpha: .10),
          highlightColor: theme.colorScheme.onSurface.withValues(alpha: .14),
          splashFactory: NoSplash.splashFactory,
          child: SizedBox(
            height: 28,
            child: Padding(
              padding: padding,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
