import 'package:flutter/material.dart';

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
    this.variant = PromptPillVariant.normal,
  });

  final String title;
  final Color color;
  final bool enabled;

  /// 块自定义图标；null 时用默认模块图标（异常态图标不受此影响）。
  final IconData? icon;
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
        ],
      ),
    );
  }
}

enum PromptPillVariant { normal, missing, unknown }
