import 'package:flutter/material.dart';

import '../kit/ui_colors.dart';

/// 按页面实际可用宽度排版：≥ 1150 三列，≥ 710 两列，再窄一列（窗口宽 1200 / 760 减去主导航）。
class StatsLayout {
  const StatsLayout(this.pageWidth);
  final double pageWidth;

  int get columns => pageWidth >= 1150
      ? 3
      : pageWidth >= 710
      ? 2
      : 1;

  /// 三列时的宽排版：日历小结和模型排行放右侧、总数行显示迷你图。
  bool get wide => columns == 3;

  /// 小卡片网格里一张卡片的外宽。
  double get cardWidth {
    final content = (pageWidth - 48).clamp(0.0, maxContentWidth);
    return (content - gap * (columns - 1)) / columns;
  }

  static const maxContentWidth = 1440.0;
  static const gap = 16.0;
}

/// 页面内容区：上 20、左右 24、下 24，最大宽 1440 居中，卡片间距 16。
class StatsPageFrame extends StatelessWidget {
  const StatsPageFrame({super.key, required this.builder, this.footer});

  final List<Widget> Function(StatsLayout layout) builder;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = StatsLayout(constraints.maxWidth);
        final children = builder(layout);
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: StatsLayout.maxContentWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, child) in children.indexed) ...[
                    if (i > 0) const SizedBox(height: StatsLayout.gap),
                    child,
                  ],
                  if (footer case final footer?) footer,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 小卡片网格：按列数分行，同一行等高、内容顶对齐。
class StatsCardGrid extends StatelessWidget {
  const StatsCardGrid({
    super.key,
    required this.columns,
    required this.children,
  });

  final int columns;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (columns == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, child) in children.indexed) ...[
            if (i > 0) const SizedBox(height: StatsLayout.gap),
            child,
          ],
        ],
      );
    }
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += columns) {
      final row = children.sublist(i, (i + columns).clamp(0, children.length));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var j = 0; j < columns; j++) ...[
                if (j > 0) const SizedBox(width: StatsLayout.gap),
                Expanded(
                  child: j < row.length ? row[j] : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, row) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: StatsLayout.gap),
          row,
        ],
      ],
    );
  }
}

/// 总数行的五格：格间 1px 竖线，每格内边距 16 / 18 / 14。
class StatsKpiFrame extends StatelessWidget {
  const StatsKpiFrame({super.key, required this.cells});
  final List<Widget> cells;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, cell) in cells.indexed)
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                decoration: i == 0
                    ? null
                    : BoxDecoration(
                        border: Border(left: BorderSide(color: c.border)),
                      ),
                child: cell,
              ),
            ),
        ],
      ),
    );
  }
}
