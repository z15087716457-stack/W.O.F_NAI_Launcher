import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../providers/generation/image_action_providers.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../providers/canvas_settings_provider.dart';
import '../../../../providers/generation/preview_selection_provider.dart';
import '../../../../providers/image_generation_provider.dart';
import '../../../../services/image_workflow_launcher.dart';
import '../../../../widgets/common/app_toast.dart';
import '../../../../widgets/image_editor/image_editor_screen.dart';
import '../../../../utils/clipboard_image.dart';
import '../../services/generation_save_service.dart';
import '../../../../../core/utils/localization_extension.dart';
import '../../../../widgets/common/image_detail/image_detail_data.dart';
import 'canvas_feed_layout.dart';
import 'canvas_display_settings.dart';
import 'generated_image_actions.dart';
import '../generation_sidebar_style.dart';

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
      ],
    };
    return _ToolbarStrip(
      items: items,
      image: image,
      group: group,
      focus: focus,
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
    tooltip: (l10n) => l10n.img2img_enhance,
  );

  factory _ToolbarItem.variations() => _ToolbarItem._(
    icon: 'nai-icon-variations.svg',
    tooltip: (l10n) => l10n.img2img_generateVariations,
    priceBadge: true,
  );

  factory _ToolbarItem.upscale() => _ToolbarItem._(
    icon: 'nai-icon-upscale.svg',
    tooltip: (l10n) => l10n.image_upscale,
    priceBadge: true,
  );

  factory _ToolbarItem.setInit() => _ToolbarItem._(
    icon: 'nai-icon-set-init.svg',
    tooltip: (l10n) => l10n.generation_canvasSetInitImage,
  );

  factory _ToolbarItem.edit() => _ToolbarItem._(
    icon: 'nai-icon-edit.svg',
    tooltip: (l10n) => l10n.img2img_editImage,
  );

  factory _ToolbarItem.inpaint() => _ToolbarItem._(
    icon: 'nai-icon-inpaint2.svg',
    tooltip: (l10n) => l10n.img2img_inpaint,
  );

  factory _ToolbarItem.sendToTools() => _ToolbarItem._(
    icon: 'nai-icon-send-tools.svg',
    tooltip: (l10n) => l10n.generation_canvasSendToTools,
  );

  factory _ToolbarItem.pin() => _ToolbarItem._(
    icon: 'nai-icon-pin.svg',
    tooltip: (l10n) => l10n.generation_canvasPinImage,
  );

  factory _ToolbarItem.copy() => _ToolbarItem._(
    icon: 'nai-icon-copy.svg',
    tooltip: (l10n) => l10n.image_copy,
  );

  factory _ToolbarItem.download() => _ToolbarItem._(
    icon: 'nai-icon-download.svg',
    tooltip: (l10n) => l10n.image_save,
  );

  factory _ToolbarItem.info() => _ToolbarItem._(
    icon: 'nai-icon-info.svg',
    tooltip: (l10n) => l10n.image_viewDetail,
  );

  factory _ToolbarItem.settings() => _ToolbarItem._(
    icon: 'nai-icon-settings.svg',
    tooltip: (l10n) => l10n.generation_canvasDisplaySettings,
  );

  factory _ToolbarItem.resolution(GeneratedImage img) =>
      _ToolbarItem._(label: '${img.width} × ${img.height}', isResolution: true);

  factory _ToolbarItem.seedPill(GeneratedImage img) => _ToolbarItem._(
    label: img.metadata?.seed?.toString() ?? '—',
    isSeedPill: true,
    tooltip: (l10n) => l10n.generation_canvasUseSeed,
  );

  final String? icon;
  final String? label;
  final String Function(AppLocalizations)? tooltip;
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
  });

  final List<_ToolbarItem> items;
  final GeneratedImage image;
  final CanvasFeedGroup group;
  final CanvasFocus? focus;

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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: items
                .map((it) => _buildItem(context, ref, theme, it))
                .toList(),
          ),
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
        label:
            ref
                .watch(generatedImageMetadataProvider(image))
                .valueOrNull
                ?.seed
                ?.toString() ??
            '—',
        tooltip: item.tooltip?.call(context.l10n),
        onTap: () => _writeBackSeed(context, ref),
      );
    }
    if (item.icon == 'nai-icon-settings.svg') {
      return const CanvasDisplaySettingsButton();
    }
    return _IconBtn(item: item, image: image, group: group, focus: focus);
  }

  Future<void> _writeBackSeed(BuildContext context, WidgetRef ref) async {
    final seed = (await ref.read(
      generatedImageMetadataProvider(image).future,
    ))?.seed;
    if (!context.mounted) return;
    if (seed == null) return;
    ref.read(generationParamsNotifierProvider.notifier).updateSeed(seed);
    AppToast.success(context, context.l10n.generation_seedWrittenBack(seed));
  }
}

class _IconBtn extends ConsumerWidget {
  const _IconBtn({
    required this.item,
    required this.image,
    required this.group,
    this.focus,
  });

  final _ToolbarItem item;
  final GeneratedImage image;
  final CanvasFeedGroup group;
  final CanvasFocus? focus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final enabled = _resolveEnabled(ref);
    final price = item.priceBadge ? _priceFor(ref) : null;
    // 官网：已钉住换实心 pin（save.pin 双态）
    final icon =
        item.icon == 'nai-icon-pin.svg' &&
            ref.watch(
              canvasPinnedNotifierProvider.select(
                (pins) => pins.contains(image.id),
              ),
            )
        ? 'nai-icon-pin-filled.svg'
        : item.icon;

    final btn = InkWell(
      onTap: enabled ? () => _dispatch(context, ref) : null,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              SvgPicture.asset(
                'assets/icons/$icon',
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(
                  enabled
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.35),
                  BlendMode.srcIn,
                ),
              ),
            if (price != null && price >= 0) ...[
              const SizedBox(width: 4),
              Ink(
                key: ValueKey('canvas-cost-${item.icon}'),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: GenSidebarStyle.selectedSurface(theme),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$price',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: enabled ? 1 : .35,
                        ),
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 3),
                    SvgPicture.asset(
                      'assets/icons/nai-icon-anlas.svg',
                      width: 12,
                      height: 12,
                      colorFilter: ColorFilter.mode(
                        theme.colorScheme.onSurface.withValues(
                          alpha: enabled ? 1 : .35,
                        ),
                        BlendMode.srcIn,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
    final tooltip = icon == 'nai-icon-pin-filled.svg'
        ? context.l10n.generation_canvasUnpinImage
        : item.tooltip?.call(context.l10n);
    return tooltip != null ? Tooltip(message: tooltip, child: btn) : btn;
  }

  bool _resolveEnabled(WidgetRef ref) {
    switch (item.icon) {
      case 'nai-icon-info.svg':
        return true;
      case 'nai-icon-copy.svg':
      case 'nai-icon-download.svg':
      case 'nai-icon-pin.svg':
        return image.canSave;
      default:
        if (!image.canUseAsGenerationInput ||
            ref.watch(
              imageGenerationNotifierProvider.select((s) => s.isGenerating),
            )) {
          return false;
        }
        if (item.icon == 'nai-icon-inpaint2.svg') {
          return ImageModels.supportsImg2ImgInpainting(
            ref.watch(generationParamsNotifierProvider.select((p) => p.model)),
          );
        }
        if (item.icon == 'nai-icon-variations.svg') {
          return !ref.watch(generationCooldownProvider).isActive;
        }
        return true;
    }
  }

  int? _priceFor(WidgetRef ref) => switch (item.icon) {
    'nai-icon-variations.svg' => ref.watch(imageVariationCostProvider(image)),
    'nai-icon-upscale.svg' => ref.watch(imageUpscaleCostProvider(image)),
    _ => null,
  };

  void _dispatch(BuildContext context, WidgetRef ref) {
    final bytes = image.bytes;
    final actions = GeneratedImageActions(ref);
    switch (item.icon) {
      case 'nai-icon-enhance.svg':
        ImageWorkflowLauncher.openEnhance(ref, bytes);
      case 'nai-icon-variations.svg':
        unawaited(
          ImageWorkflowLauncher.generateVariations(context, ref, bytes),
        );
      case 'nai-icon-upscale.svg':
        ImageWorkflowLauncher.openUpscale(ref, bytes);
      case 'nai-icon-set-init.svg':
        ImageWorkflowLauncher.openImageToImage(ref, bytes);
        AppToast.success(context, context.l10n.generation_setAsReferenceImage);
      case 'nai-icon-edit.svg':
        unawaited(
          ImageWorkflowLauncher.openEditor(
            context,
            ref,
            bytes,
            mode: ImageEditorMode.edit,
          ),
        );
      case 'nai-icon-inpaint2.svg':
        unawaited(ImageWorkflowLauncher.openInpaint(context, ref, bytes));
      case 'nai-icon-send-tools.svg':
        // 官网：push 队列头 + 切 ImageTools 视图；本工程走 DirectorTools 兜底
        unawaited(ImageWorkflowLauncher.openDirectorTools(context, ref, bytes));
      case 'nai-icon-pin.svg':
      case 'nai-icon-pin-filled.svg':
        unawaited(_togglePin(context, ref));
      case 'nai-icon-copy.svg':
        _copyImage(context, ref);
      case 'nai-icon-download.svg':
        unawaited(_saveImage(context, ref));
      case 'nai-icon-info.svg':
        actions.showFullscreenImage(context, image);
    }
  }

  Future<void> _togglePin(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(canvasPinnedNotifierProvider.notifier).toggle(image);
    } catch (error) {
      if (context.mounted) {
        AppToast.error(context, context.l10n.image_saveFailed('$error'));
      }
    }
  }

  Future<void> _copyImage(BuildContext context, WidgetRef ref) async {
    try {
      await writeImageBytesToClipboardAsPng(image.bytes);
      if (context.mounted) {
        AppToast.success(context, context.l10n.image_copiedToClipboard);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, context.l10n.image_copyFailed('$e'));
      }
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
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.6,
          ),
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
