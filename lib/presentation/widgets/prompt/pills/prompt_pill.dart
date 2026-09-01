import 'package:flutter/material.dart';

import 'dna_icon.dart';

/// 药丸编辑器中文本流内联渲染的块药丸（P0 原型）。
///
/// 纯视觉组件：颜色胶囊 + 标题；禁用态降透明度，异常态（块已删/失效标记）
/// 由 [variant] 区分。交互（点击/长按拖拽）由外层包装。
class PromptPill extends StatelessWidget {
  const PromptPill({
    super.key,
    required this.title,
    required this.color,
    this.enabled = true,
    this.icon,
    this.showRollBadge = false,
    this.evolutionEnabled = false,
    this.allowEvolutionToggle = false,
    this.variant = PromptPillVariant.normal,
  });

  final String title;
  final Color color;
  final bool enabled;

  /// 块自定义图标；null 时用默认模块图标（异常态图标不受此影响）。
  final IconData? icon;

  /// 随机抽取实例的骰子角标（P2.5）：标题后加小号骰子，区分固定/随机实例。
  final bool showRollBadge;

  /// 画风探索深度轮使用的实例级遗传角标；只影响 UI，不进入提示词文本。
  final bool evolutionEnabled;

  /// 当前页面是否允许操作遗传开关；探索页彩色，主生成页灰色。
  final bool allowEvolutionToggle;
  final PromptPillVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (borderColor, fillColor, textColor, icon) = switch (variant) {
      PromptPillVariant.normal => (
        color.withValues(alpha: enabled ? 0.85 : 0.35),
        color.withValues(alpha: enabled ? 0.20 : 0.07),
        enabled
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurfaceVariant,
        this.icon ?? Icons.view_module_outlined,
      ),
      PromptPillVariant.missing => (
        theme.colorScheme.error.withValues(alpha: 0.7),
        theme.colorScheme.error.withValues(alpha: 0.12),
        theme.colorScheme.error,
        Icons.error_outline,
      ),
      PromptPillVariant.unknown => (
        theme.colorScheme.outline.withValues(alpha: 0.6),
        theme.colorScheme.outline.withValues(alpha: 0.10),
        theme.colorScheme.onSurfaceVariant,
        Icons.help_outline,
      ),
    };

    final evolutionColor = allowEvolutionToggle
        ? color
        : theme.colorScheme.onSurfaceVariant;

    // 尺寸对齐主提示词正文（bodyMedium）：药丸曾用 labelSmall 明显小于正文字号
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: borderColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.1,
              ),
            ),
          ),
          if (showRollBadge) ...[
            const SizedBox(width: 2),
            Icon(Icons.casino_outlined, size: 11, color: borderColor),
          ],
          if (evolutionEnabled) ...[
            const SizedBox(width: 2),
            DnaIcon(size: 12, color: evolutionColor),
          ],
        ],
      ),
    );
  }
}

enum PromptPillVariant { normal, missing, unknown }
