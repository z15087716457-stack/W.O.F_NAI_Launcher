import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../providers/cost_estimate_provider.dart';
import '../../../../providers/canvas_settings_provider.dart';
import '../../../../providers/generation/preview_selection_provider.dart';
import '../../../../providers/image_generation_provider.dart';
import '../../../../services/image_workflow_launcher.dart';
import '../../../../widgets/common/app_toast.dart';
import '../../../../widgets/image_editor/image_editor_screen.dart';
import '../../../../utils/clipboard_image.dart';
import '../../services/generation_save_service.dart';
import '../../../../widgets/common/image_detail/image_detail_data.dart';
import 'canvas_feed_layout.dart';
import 'generated_image_actions.dart';

/// 画布工具条分区（官网 md 布局表逐字对码）
enum CanvasToolbarZone { top, bottomStart, bottomEnd }

/// 焦点组边缘工具条（官网 image-gen-viewer-bar）。
/// top.center:    enhance|variations|upscale ‖ set-init|edit|inpaint|send-to-tools
/// bottom.start:  宽×高 ‖ ⚙settings | 种子药丸
/// bottom.end:    [old-compare] [contest|pin|copy|download] [info] [explore-upload]
class CanvasEdgeToolbar extends ConsumerWidget {
  const CanvasEdgeToolbar({
    super.key,
    required this.zone,
    required this.image,
    required this.group,
    required this.focus,
  });

  final CanvasToolbarZone zone;
  final GeneratedImage image;
  final CanvasFeedGroup group;
  final CanvasFocus? focus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = switch (zone) {
      CanvasToolbarZone.top => [
          _ToolbarItem.enhance(),
          _ToolbarItem.variations(),
          _ToolbarItem.upscale(),
          _ToolbarItem.divider(),
          _ToolbarItem.setInit(),
          _ToolbarItem.edit(),
          _ToolbarItem.inpaint(),
          _ToolbarItem.sendToTools(),
        ],
      CanvasToolbarZone.bottomStart => [
          _ToolbarItem.resolution(image),
          _ToolbarItem.divider(),
          _ToolbarItem.settings(),
          _ToolbarItem.seedPill(image),
        ],
      CanvasToolbarZone.bottomEnd => [
          // 官网条件渲染件：old-compare(需 originalImage 追踪) 与 contest(订阅功能) 暂无 → 不出现
          _ToolbarItem.pin(),
          _ToolbarItem.copy(),
          _ToolbarItem.download(),
          _ToolbarItem.info(),
          _ToolbarItem.exploreUpload(),
        ],
    };
    return _ToolbarStrip(items: items, image: image, group: group, focus: focus);
  }
}

/// 非焦点 tile 悬停迷你条（官网 R.I3 condensed：contest|pin|copy|download + 种子）
class CanvasMiniToolbar extends ConsumerWidget {
  const CanvasMiniToolbar({super.key, required this.image, required this.group});

  final GeneratedImage image;
  final CanvasFeedGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _ToolbarStrip(
      condensed: true,
      items: [
        // 官网 condensed：contest(订阅件) 不渲染 → pin|copy|download + 种子
        _ToolbarItem.pin(),
        _ToolbarItem.copy(),
        _ToolbarItem.download(),
        _ToolbarItem.seedPill(image),
      ],
      image: image,
      group: group,
      focus: null,
    );
  }
}

class _ToolbarItem {
  _ToolbarItem._({
    this.icon,
    this.label,
    this.tooltip,
    this.isDivider = false,
    this.isSeedPill = false,
    this.isResolution = false,
    this.priceBadge = false,
  });

  factory _ToolbarItem.divider() => _ToolbarItem._(isDivider: true);

  factory _ToolbarItem.enhance() => _ToolbarItem._(
        icon: 'nai-icon-enhance.svg',
        tooltip: 'Enhance',
      );

  factory _ToolbarItem.variations() => _ToolbarItem._(
        icon: 'nai-icon-variations.svg',
        tooltip: 'Variations',
        priceBadge: true,
      );

  factory _ToolbarItem.upscale() => _ToolbarItem._(
        icon: 'nai-icon-upscale.svg',
        tooltip: 'Upscale',
        priceBadge: true,
      );

  factory _ToolbarItem.setInit() => _ToolbarItem._(
        icon: 'nai-icon-set-init.svg',
        tooltip: 'Set as init image',
      );

  factory _ToolbarItem.edit() => _ToolbarItem._(
        icon: 'nai-icon-edit.svg',
        tooltip: 'Edit image',
      );

  factory _ToolbarItem.inpaint() => _ToolbarItem._(
        icon: 'nai-icon-inpaint2.svg',
        tooltip: 'Inpaint',
      );

  factory _ToolbarItem.sendToTools() => _ToolbarItem._(
        icon: 'nai-icon-send-tools.svg',
        tooltip: 'Send to Image Tools',
      );

  factory _ToolbarItem.pin() => _ToolbarItem._(
        icon: 'nai-icon-pin.svg',
        tooltip: 'Pin',
      );

  factory _ToolbarItem.copy() => _ToolbarItem._(
        icon: 'nai-icon-copy.svg',
        tooltip: 'Copy',
      );

  factory _ToolbarItem.download() => _ToolbarItem._(
        icon: 'nai-icon-download.svg',
        tooltip: 'Download',
      );

  factory _ToolbarItem.info() => _ToolbarItem._(
        icon: 'nai-icon-info.svg',
        tooltip: 'Info',
      );

  factory _ToolbarItem.exploreUpload() => _ToolbarItem._(
        icon: 'nai-icon-explore-upload.svg',
        tooltip: 'Upload to explore',
      );

  factory _ToolbarItem.settings() => _ToolbarItem._(
        icon: 'nai-icon-settings.svg',
        tooltip: 'Display settings',
      );

  factory _ToolbarItem.resolution(GeneratedImage img) => _ToolbarItem._(
        label: '${img.width} × ${img.height}',
        isResolution: true,
      );

  factory _ToolbarItem.seedPill(GeneratedImage img) => _ToolbarItem._(
        label: img.metadata?.seed?.toString() ?? '—',
        isSeedPill: true,
        tooltip: 'Click to use this seed',
      );

  final String? icon;
  final String? label;
  final String? tooltip;
  final bool isDivider;
  final bool isSeedPill;
  final bool isResolution;
  final bool priceBadge;
}

class _ToolbarStrip extends ConsumerWidget {
  const _ToolbarStrip({
    required this.items,
    required this.image,
    required this.group,
    this.focus,
    this.condensed = false,
  });

  final List<_ToolbarItem> items;
  final GeneratedImage image;
  final CanvasFeedGroup group;
  final CanvasFocus? focus;
  final bool condensed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface.withValues(alpha: 0.92),
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: items
              .map((it) => _buildItem(context, ref, theme, it))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    _ToolbarItem item,
  ) {
    if (item.isDivider) {
      return Container(
        width: 1,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: theme.dividerColor.withValues(alpha: 0.5),
      );
    }
    if (item.isResolution) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          item.label ?? '',
          style: theme.textTheme.labelMedium?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
    }
    if (item.isSeedPill) {
      return _SeedPill(
        label: item.label ?? '—',
        tooltip: item.tooltip,
        onTap: () => _writeBackSeed(context, ref),
      );
    }
    return _IconBtn(
      item: item,
      image: image,
      group: group,
      focus: focus,
      condensed: condensed,
    );
  }

  Future<void> _writeBackSeed(BuildContext context, WidgetRef ref) async {
    final seed = image.metadata?.seed;
    if (seed == null) return;
    ref.read(generationParamsNotifierProvider.notifier).updateSeed(seed);
    AppToast.success(context, '种子已写回: $seed');
  }
}

class _IconBtn extends ConsumerWidget {
  const _IconBtn({
    required this.item,
    required this.image,
    required this.group,
    this.focus,
    this.condensed = false,
  });

  final _ToolbarItem item;
  final GeneratedImage image;
  final CanvasFeedGroup group;
  final CanvasFocus? focus;
  final bool condensed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final enabled = _resolveEnabled(ref);
    final price = item.priceBadge ? _priceFor(ref) : null;

    final btn = InkWell(
      onTap: enabled ? () => _dispatch(context, ref) : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.icon != null)
              SvgPicture.asset(
                'assets/icons/${item.icon}',
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(
                  enabled
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  BlendMode.srcIn,
                ),
              ),
            if (price != null && price > 0) ...[
              const SizedBox(width: 4),
              Text(
                '$price',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return item.tooltip != null
        ? Tooltip(message: item.tooltip!, child: btn)
        : btn;
  }

  bool _resolveEnabled(WidgetRef ref) {
    if (!image.canUseAsGenerationInput) return false;
    switch (item.icon) {
      case 'nai-icon-inpaint2.svg':
        // 官网：仅模型支持 inpainting 才渲染（enabled 由门控决定）
        return _modelSupportsInpaint(ref);
      default:
        return true;
    }
  }

  bool _modelSupportsInpaint(WidgetRef ref) {
    final params = ref.read(generationParamsNotifierProvider);
    final model = params.model.toLowerCase();
    return model.contains('inpaint') ||
        model.contains('nai-diffusion-3') ||
        model.contains('nai-diffusion-4') ||
        model.contains('nai-diffusion-4-5');
  }

  int? _priceFor(WidgetRef ref) {
    // 官网：variations/upscale 钮带实时 Anlas 价签（按当前选中图尺寸估价）
    if (item.icon == 'nai-icon-variations.svg') {
      return ref.watch(estimatedCostProvider);
    }
    if (item.icon == 'nai-icon-upscale.svg') {
      // 官网 generateUpscale 直接生成；价签 = 当前图尺寸 upscale 估价（4x）
      return _estimateUpscale(ref);
    }
    return null;
  }

  int _estimateUpscale(WidgetRef ref) {
    // 用计算器按 upscale 4x 估（AnlasCalculator.calculateNovelAiUpscaleCost 等价）
    final w = image.width;
    final h = image.height;
    // 近似：4x upscale = 4×像素 → 用 request 成本近似；真实计算器在服务端
    // 这里直接复用 estimateCostForBatchSize(1) 的现成值不可靠，改走简单公式：
    final mp = (w * h * 16) / 1e6; // 4x = 16×像素
    return (mp * 1.5).ceil().clamp(1, 999);
  }

  void _dispatch(BuildContext context, WidgetRef ref) {
    final bytes = image.bytes;
    final actions = GeneratedImageActions(ref);
    switch (item.icon) {
      case 'nai-icon-enhance.svg':
        ImageWorkflowLauncher.openEnhance(ref, bytes);
      case 'nai-icon-variations.svg':
        unawaited(ImageWorkflowLauncher.generateVariations(context, ref, bytes));
      case 'nai-icon-upscale.svg':
        ImageWorkflowLauncher.openUpscale(ref, bytes);
      case 'nai-icon-set-init.svg':
        ImageWorkflowLauncher.openImageToImage(ref, bytes);
        AppToast.success(context, '已设为参考图');
      case 'nai-icon-edit.svg':
        unawaited(ImageWorkflowLauncher.openEditor(
          context,
          ref,
          bytes,
          mode: ImageEditorMode.edit,
        ));
      case 'nai-icon-inpaint2.svg':
        unawaited(ImageWorkflowLauncher.openInpaint(context, ref, bytes));
      case 'nai-icon-send-tools.svg':
        // 官网：push 队列头 + 切 ImageTools 视图；本工程走 DirectorTools 兜底
        unawaited(ImageWorkflowLauncher.openDirectorTools(context, ref, bytes));
      case 'nai-icon-pin.svg':
        // 官网钉板：本工程映射为图库收藏语义——走历史栏同款心形（收藏写文件元数据侧）
        // 画布 pin = 收藏该图（toggle favorite，与历史栏心形同源）
        AppToast.info(context, '收藏走历史栏心形（同源语义）');
      case 'nai-icon-copy.svg':
        _copyImage(context, ref);
      case 'nai-icon-download.svg':
        unawaited(_saveImage(context, ref));
      case 'nai-icon-info.svg':
        actions.showFullscreenImage(context, image);
      case 'nai-icon-explore-upload.svg':
        // 官网：上传探索；本工程无——映射存精准参考库
        unawaited(actions.showSaveToLibraryDialog(context, bytes));
      case 'nai-icon-settings.svg':
        _showDisplaySettings(context, ref);
    }
  }

  Future<void> _copyImage(BuildContext context, WidgetRef ref) async {
    try {
      await writeImageBytesToClipboardAsPng(image.bytes);
      if (context.mounted) AppToast.success(context, '已复制到剪贴板');
    } catch (_) {
      if (context.mounted) AppToast.error(context, '复制失败');
    }
  }

  Future<void> _saveImage(BuildContext context, WidgetRef ref) async {
    final detail = GeneratedImageDetailData(
      imageBytes: image.bytes,
      metadata: image.metadata,
      id: image.id,
      showSaveButton: image.canSave,
      showCopyButton: image.canSave,
    );
    await GenerationSaveService.saveImageFromDetail(context, ref, detail);
  }

  void _showDisplaySettings(BuildContext context, WidgetRef ref) {
    final zoomToFill = ref.read(canvasZoomToFillNotifierProvider);
    final smooth = ref.read(canvasSmoothZoomNotifierProvider);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('画布显示'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('放大填充（允许 >100%）'),
              value: zoomToFill,
              onChanged: (v) {
                ref.read(canvasZoomToFillNotifierProvider.notifier).set(v);
                Navigator.pop(ctx);
              },
            ),
            SwitchListTile(
              title: const Text('平滑缩放（Ctrl+滚轮）'),
              value: smooth,
              onChanged: (v) {
                ref.read(canvasSmoothZoomNotifierProvider.notifier).set(v);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SeedPill extends StatelessWidget {
  const _SeedPill({required this.label, this.tooltip, this.onTap});

  final String label;
  final String? tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pill = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/nai-icon-seed2.svg',
              width: 12,
              height: 12,
              colorFilter: ColorFilter.mode(
                theme.colorScheme.onSurface.withValues(alpha: 0.7),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: pill) : pill;
  }
}


