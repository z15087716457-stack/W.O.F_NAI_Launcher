import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/localization_extension.dart';
import '../../../../services/image_workflow_launcher.dart';
import '../../../../providers/generation/generation_models.dart';
import '../../../../providers/local_gallery_provider.dart';
import '../../../../widgets/common/selectable_image_card.dart';
import '../../../../widgets/image_editor/image_editor_screen.dart';
import 'generated_image_actions.dart';

/// NAI5 tile 工具条注册表（对标官网 `md`/`mc` 逆向）。
///
/// 布局：top 居中条（enhance/variations/upscale | set-init/edit/inpaint/send-to-tools）
/// + bottom 左条（resolution/settings/seed）+ bottom 右条（pin/copy/download/info）。
/// contest / old-compare / explore-upload 无本地对应功能，不注册。
///
/// 塌缩：可用宽度不足时按优先级降序隐藏；孤立 divider 自动消失。
/// 反缩放：渲染在画布世界层时外层套 `Transform.scale(1/camScale)`，
/// 保持屏幕恒定尺寸（对应官网 `--canvas-ui-scale`）。
///
/// 所有动作委托 [GeneratedImageActions] / [ImageWorkflowLauncher]，
/// 图粒度（per-tile）。

/// 工具条单项描述符。
class CanvasToolbarItem {
  const CanvasToolbarItem({
    required this.id,
    required this.icon,
    required this.tooltip,
    required this.priority,
    required this.onTap,
    this.dividerBefore = false,
    this.enabled = true,
    this.visible = true,
  });

  /// 唯一 id（对应官网注册表键名）。
  final String id;

  /// 图标。
  final IconData icon;

  /// 悬停提示。
  final String tooltip;

  /// 塌缩优先级：数字越大越先被藏（官网 `mc` 表顺序）。
  final int priority;

  /// 点击回调。
  final VoidCallback onTap;

  /// 此项前渲染分隔竖线（塌缩后孤立 divider 自动消失）。
  final bool dividerBefore;

  /// 禁用态（灰显、不响应）。
  final bool enabled;

  /// 条件不满足时不渲染（如 inpaint 仅支持 inpainting 模型）。
  final bool visible;
}

/// 生成单个 tile 的完整工具条项序列（top + bottom 合并返回，
/// 由 [CanvasTileToolbar] 拆成两条）。
///
/// [image] 当前 tile 的图；[canUseAsInput] 决定加工类项可用性。
List<CanvasToolbarItem> buildCanvasToolbarItems({
  required BuildContext context,
  required WidgetRef ref,
  required GeneratedImage image,
}) {
  final actions = GeneratedImageActions(ref);
  final l10n = context.l10n;
  final canUse = image.canUseAsGenerationInput;

  VoidCallback fn(void Function() f) => f;

  return [
    // ===== top 条 =====
    CanvasToolbarItem(
      id: 'enhance',
      icon: Icons.auto_fix_high,
      tooltip: l10n.img2img_enhance,
      priority: 10,
      enabled: canUse,
      onTap: fn(() => ImageWorkflowLauncher.openEnhance(ref, image.bytes)),
    ),
    CanvasToolbarItem(
      id: 'variations',
      icon: Icons.shuffle,
      tooltip: l10n.img2img_generateVariations,
      priority: 9,
      enabled: canUse,
      onTap: fn(
        () => ImageWorkflowLauncher.generateVariations(
          context,
          ref,
          image.bytes,
        ),
      ),
    ),
    CanvasToolbarItem(
      id: 'upscale',
      icon: Icons.zoom_in_map,
      tooltip: l10n.image_upscale,
      priority: 8,
      enabled: canUse,
      onTap: fn(() => ImageWorkflowLauncher.openUpscale(ref, image.bytes)),
    ),
    CanvasToolbarItem(
      id: 'set-init',
      icon: Icons.image_outlined,
      tooltip: l10n.img2img_title,
      priority: 5,
      dividerBefore: true,
      enabled: canUse,
      onTap: fn(
        () => actions.sendToImageToImage(context, image),
      ),
    ),
    CanvasToolbarItem(
      id: 'edit',
      icon: Icons.edit_outlined,
      tooltip: l10n.common_edit,
      priority: 6,
      enabled: canUse,
      onTap: fn(
        () => ImageWorkflowLauncher.openEditor(
          context,
          ref,
          image.bytes,
          mode: ImageEditorMode.edit,
        ),
      ),
    ),
    CanvasToolbarItem(
      id: 'inpaint',
      icon: Icons.brush_outlined,
      tooltip: l10n.img2img_inpaint,
      priority: 4,
      enabled: canUse,
      onTap: fn(
        () => ImageWorkflowLauncher.openInpaint(context, ref, image.bytes),
      ),
    ),
    CanvasToolbarItem(
      id: 'send-to-tools',
      icon: Icons.construction_outlined,
      tooltip: l10n.img2img_directorTools,
      priority: 3,
      enabled: canUse,
      onTap: fn(
        () => ImageWorkflowLauncher.openDirectorTools(context, ref, image.bytes),
      ),
    ),

    // ===== bottom 条 =====
    CanvasToolbarItem(
      id: 'pin',
      icon: Icons.push_pin_outlined,
      tooltip: l10n.common_favorite,
      priority: 8,
      // 钉板未实现前落到本地图库收藏；仅已落盘（有 filePath）的图可收藏。
      enabled: image.canSave &&
          image.filePath != null &&
          image.filePath!.isNotEmpty,
      onTap: fn(() {
        final path = image.filePath;
        if (path == null || path.isEmpty) return;
        unawaited(
          ref.read(localGalleryNotifierProvider.notifier).toggleFavorite(path),
        );
      }),
    ),
    CanvasToolbarItem(
      id: 'copy',
      icon: Icons.copy_outlined,
      tooltip: l10n.image_copy,
      priority: 9,
      enabled: image.canSave,
      onTap: fn(
        () => unawaited(
          SelectableImageCard.copyImageBytesToClipboard(
            context,
            ref,
            image.bytes,
          ),
        ),
      ),
    ),
    CanvasToolbarItem(
      id: 'download',
      icon: Icons.download_outlined,
      tooltip: l10n.image_save,
      priority: 10,
      enabled: image.canSave,
      onTap: fn(
        () => unawaited(
          SelectableImageCard.saveImageBytesToGallery(context, image.bytes),
        ),
      ),
    ),
    CanvasToolbarItem(
      id: 'info',
      icon: Icons.info_outline,
      tooltip: l10n.image_viewDetail,
      priority: 2,
      onTap: fn(() => actions.showFullscreenImage(context, image)),
    ),
  ];
}

/// 画布 tile 工具条组件（屏幕恒定尺寸）。
///
/// 世界层内由父级以 [Transform.scale(1/camScale)] 反缩放；
/// 本组件只负责按可用宽度塌缩渲染 top 居中 + bottom 左右两段。
class CanvasTileToolbar extends StatelessWidget {
  const CanvasTileToolbar({
    super.key,
    required this.items,
    required this.maxWidth,
  });

  /// 全量注册项（含显隐/禁用已计算好的）。
  final List<CanvasToolbarItem> items;

  /// 可用屏幕宽度（已含反缩放换算），用于塌缩裁减。
  final double maxWidth;

  static const double _itemW = 30.0; // 图标钮占位宽（含 padding）
  static const double _dividerW = 9.0; // 分隔竖线占位宽

  /// 塌缩：可用宽不足时按优先级降序隐藏；孤立 divider 自动消失。
  /// 返回可见项（保持原顺序）。
  static List<CanvasToolbarItem> collapse(
    List<CanvasToolbarItem> items,
    double maxWidth,
  ) {
    var visible = items.where((e) => e.visible).toList();
    // 宽度预算：每项 _itemW，divider _dividerW
    double widthOf(List<CanvasToolbarItem> list) {
      var w = 0.0;
      for (final e in list) {
        w += _itemW + (e.dividerBefore ? _dividerW : 0);
      }
      return w;
    }

    // 按优先级降序藏，直到宽度够用
    final sorted = [...visible]..sort((a, b) => b.priority.compareTo(a.priority));
    for (final item in sorted) {
      if (widthOf(visible) <= maxWidth) break;
      visible = visible.where((e) => e.id != item.id).toList();
    }

    // 孤立 divider 消除：dividerBefore 且前一项被藏 → 该 divider 也藏。
    // 用 visible 集合判定「前一渲染项是否存在」。
    final result = <CanvasToolbarItem>[];
    for (final e in visible) {
      final withDivider = e.dividerBefore && result.isNotEmpty;
      result.add(
        CanvasToolbarItem(
          id: e.id,
          icon: e.icon,
          tooltip: e.tooltip,
          priority: e.priority,
          onTap: e.onTap,
          dividerBefore: withDivider,
          enabled: e.enabled,
        ),
      );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topIds = {
      'enhance',
      'variations',
      'upscale',
      'set-init',
      'edit',
      'inpaint',
      'send-to-tools',
    };
    final topItems = collapse(
      items.where((e) => topIds.contains(e.id)).toList(),
      maxWidth,
    );
    final bottomItems = collapse(
      items.where((e) => !topIds.contains(e.id)).toList(),
      maxWidth,
    );

    Widget bar(List<CanvasToolbarItem> barItems, {MainAxisAlignment align = MainAxisAlignment.center}) {
      if (barItems.isEmpty) return const SizedBox.shrink();
      return Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: align,
          children: [
            for (final item in barItems) ...[
              if (item.dividerBefore)
                Container(
                  width: 1,
                  height: 18,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              Tooltip(
                message: item.tooltip,
                child: InkWell(
                  onTap: item.enabled ? item.onTap : null,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      item.icon,
                      size: 15,
                      color: item.enabled
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.35,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (topItems.isNotEmpty) bar(topItems),
        if (topItems.isNotEmpty && bottomItems.isNotEmpty)
          const SizedBox(height: 6),
        if (bottomItems.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: bar(bottomItems, align: MainAxisAlignment.end),
          ),
      ],
    );
  }
}
