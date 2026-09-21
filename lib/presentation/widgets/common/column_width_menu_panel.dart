import 'package:nai_launcher/presentation/widgets/common/studio_icon.dart';
import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../data/services/gallery/gallery_column_width_store.dart';

/// 列宽调节按钮：图标点开 MenuAnchor 弹层，Slider 实时生效、松手持久化。
///
/// 本地画廊分页栏与候选堆管理弹窗（FEAT-42）共用；范围/步进/默认值统一走
/// [GalleryColumnWidthStore] 常量（140~480 / 步进 20 / 默认 260）。
class ColumnWidthMenuButton extends StatelessWidget {
  const ColumnWidthMenuButton({
    super.key,
    required this.width,
    this.onChanged,
    this.onChangeEnd,
  });

  final double width;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return MenuAnchor(
      builder: (context, controller, child) => Tooltip(
        message: l10n.localGallery_columnWidth,
        child: IconButton(
          icon: StudioIcon(
            Icons.view_column_outlined,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          tooltip: l10n.localGallery_columnWidth,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: const EdgeInsets.all(6),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        ),
      ),
      style: const MenuStyle(padding: WidgetStatePropertyAll(EdgeInsets.zero)),
      menuChildren: [
        ColumnWidthMenuPanel(
          width: width,
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ],
    );
  }
}

/// 列宽设置弹层：Slider（140~480，步进 20）+ 实时「约 N 列」
class ColumnWidthMenuPanel extends StatelessWidget {
  final double width;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;

  const ColumnWidthMenuPanel({
    super.key,
    required this.width,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    // 「约 N 列」按屏幕宽度估算（列宽越窄列数越多）
    final approxColumns = (MediaQuery.of(context).size.width / width)
        .round()
        .clamp(1, 99);

    return Container(
      width: 280,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.localGallery_columnWidth,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                l10n.localGallery_aboutColumns(approxColumns),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          Slider(
            value: width,
            min: GalleryColumnWidthStore.minColumnWidth,
            max: GalleryColumnWidthStore.maxColumnWidth,
            divisions: 17,
            label: '${width.round()}',
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ],
      ),
    );
  }
}
