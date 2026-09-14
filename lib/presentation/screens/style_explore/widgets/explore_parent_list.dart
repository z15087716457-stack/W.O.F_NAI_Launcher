import 'package:flutter/material.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/style_explore/explore_run.dart';
import '../../../../l10n/app_localizations.dart';

/// 父本区转两列的可用宽阈值：每列保底 ~150px（含 8px 列距）。
///
/// 画廊默认宽 360px、卡内容区 ~328px，默认即两列；更窄回落单列。
const exploreParentListTwoColumnMinWidth = 320.0;

/// 父本区限高：超出后内部滚动，未超出时取内容自然高（不出现滚动条）。
const exploreParentListMaxHeight = 120.0;

/// 父本集卡的父本行列表：响应式两列 + 限高内部滚动。
///
/// 从 `explore_lineage_panel.dart` 抽出的小件：只吃 `parents` 列表即可做
/// 组件级测试（列数阈值 / 限高滚动 / 内容少不滚），不必构造整个 run 与家族。
/// 行结构（缩略图 + `artistString` 两行省略 + 偏好值）由调用方传入缩略图构建器
/// 保持原样。宽度需由调用方约束（谱系区卡内容区即如此）。
class ExploreParentList extends StatelessWidget {
  const ExploreParentList({
    super.key,
    required this.parents,
    required this.thumbBuilder,
    this.maxHeight = exploreParentListMaxHeight,
  });

  final List<ExploreParent> parents;

  /// 来源候选缩略图（无来源/无图时由调用方渲染占位）。
  final Widget Function(ExploreParent parent) thumbBuilder;

  /// 内部滚动区的最大高度。
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    if (parents.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns =
            constraints.hasBoundedWidth &&
                constraints.maxWidth >= exploreParentListTwoColumnMinWidth
            ? 2
            : 1;
        // 同时用于外层 Wrap 的列距与列宽折算。
        const spacing = 8.0;
        final itemWidth = switch (columns) {
          2 => (constraints.maxWidth - spacing) / 2,
          _ => constraints.maxWidth,
        };

        return ConstrainedBox(
          // shrinkWrap + 限高：内容少取自然高、内容多才滚（固定高度会留空）。
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: ListView(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            children: [
              // Wrap 便于奇数父本时末行空位不拉伸、不居中。
              Wrap(
                spacing: spacing,
                runSpacing: 4,
                children: [
                  for (final parent in parents)
                    SizedBox(
                      width: itemWidth,
                      child: _ParentRow(
                        theme: theme,
                        l10n: l10n,
                        parent: parent,
                        thumb: thumbBuilder(parent),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 单行父本：缩略图 + 串（两行省略）+ 偏好值（非 1.0 才显示）。
class _ParentRow extends StatelessWidget {
  const _ParentRow({
    required this.theme,
    required this.l10n,
    required this.parent,
    required this.thumb,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final ExploreParent parent;
  final Widget thumb;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        thumb,
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            parent.artistString,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ),
        if (parent.preference != 1.0)
          Text(
            l10n.styleExplore_preferenceValue(
              parent.preference.toStringAsFixed(2),
            ),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
