import 'package:flutter/material.dart';

/// 官网式小节标题（官网 `Character Prompts` / `Image Settings` 同款）。
///
/// 滚动列内容上方的灰调标题行：小字号、低透明度，只做分组提示，
/// 不带交互；各面板内嵌的标题行不套此件。
class SectionHeader extends StatelessWidget {
  final String title;

  /// 标题下方的辅助说明行（官网 `Create a separate prompt...` 同款），可选。
  final String? subtitle;

  /// 右侧对齐的尾部控件（如小节级操作按钮），可选。
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ],
    );
  }
}
