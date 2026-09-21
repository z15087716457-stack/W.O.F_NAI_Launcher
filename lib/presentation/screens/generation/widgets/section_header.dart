import 'package:flutter/material.dart';

import 'generation_sidebar_style.dart';

/// 官网式小节标签（官网 `Reference Images` / `Image Settings` 同款）。
///
/// 滚动列内容上方的灰调小字行：13px、常规字重、低透明度，只做分组
/// 提示，不带交互；块级标题（`Character Prompts` 档）见
/// [GenSidebarStyle.sectionTitle] / [SidebarTitleScope]。
class SectionHeader extends StatelessWidget {
  final String title;

  /// 标签下方的辅助说明行（官网 `Create a separate prompt...` 同款），可选。
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GenSidebarStyle.sectionLabel(theme),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: GenSidebarStyle.sectionSubtitle(theme)),
        ],
      ],
    );
  }
}
