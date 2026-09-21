import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image/image.dart' as img;
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '../../../../core/comfyui/comfyui_models.dart';
import '../../../../core/comfyui/workflow_template.dart';
import '../../../../core/utils/focused_inpaint_utils.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/datasources/remote/nai_image_enhancement_api_service.dart';
import '../../../../data/models/image/image_params.dart';
import '../../../../data/models/image/image_operation.dart';
import '../../../../data/services/precise_ref_library_storage_service.dart';
import '../../../providers/comfyui/comfyui_provider.dart';
import '../../../providers/cost_estimate_provider.dart';
import '../../../providers/generation/generation_params_selectors.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../providers/image_save_settings_provider.dart';
import '../../../providers/generation/image_workflow_controller.dart';
import '../../../providers/precise_ref_library_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../../services/image_workflow_launcher.dart';
import '../../../utils/comfyui_workflow_l10n.dart';
import '../../../utils/dropped_file_reader.dart';
import '../../../utils/precise_ref_library_import_helper.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/collapsible_image_panel.dart';
import '../../../widgets/common/decoded_memory_image.dart';
import '../../../widgets/common/editable_double_field.dart';
import '../../../widgets/common/image_picker_card/image_picker_card.dart';
import '../../../widgets/common/themed_divider.dart';
import '../../../widgets/image_editor/painters/focused_overlay_painter.dart';
import '../../../widgets/image_editor/image_editor_screen.dart';
import '../../precise_ref_library/widgets/precise_ref_selector_dialog.dart';
import 'img2img_preview_cache.dart';
import 'comfyui_workflow_dialog.dart';

enum _UpscaleMetricLevel { low, medium, high }

extension _UpscaleMetricLevelX on _UpscaleMetricLevel {
  double get value {
    return switch (this) {
      _UpscaleMetricLevel.low => 0.34,
      _UpscaleMetricLevel.medium => 0.66,
      _UpscaleMetricLevel.high => 1.0,
    };
  }
}

class _UpscaleModuleProfile {
  const _UpscaleModuleProfile({
    required this.module,
    required this.speed,
    required this.vram,
    required this.quality,
  });

  final ComfyUpscaleModule module;
  final _UpscaleMetricLevel speed;
  final _UpscaleMetricLevel vram;
  final _UpscaleMetricLevel quality;
}

const _upscaleModuleProfiles = [
  _UpscaleModuleProfile(
    module: ComfyUpscaleModule.regular,
    speed: _UpscaleMetricLevel.medium,
    vram: _UpscaleMetricLevel.medium,
    quality: _UpscaleMetricLevel.medium,
  ),
  _UpscaleModuleProfile(
    module: ComfyUpscaleModule.seedvr2,
    speed: _UpscaleMetricLevel.low,
    vram: _UpscaleMetricLevel.high,
    quality: _UpscaleMetricLevel.high,
  ),
  _UpscaleModuleProfile(
    module: ComfyUpscaleModule.rtx,
    speed: _UpscaleMetricLevel.high,
    vram: _UpscaleMetricLevel.low,
    quality: _UpscaleMetricLevel.medium,
  ),
];

/// Img2Img 面板组件
class Img2ImgPanel extends ConsumerStatefulWidget {
  const Img2ImgPanel({super.key, this.toolOnly = false});
  final bool toolOnly;

  @override
  ConsumerState<Img2ImgPanel> createState() => _Img2ImgPanelState();
}

class _Img2ImgPanelState extends ConsumerState<Img2ImgPanel> {
  static const String _upscaleLogTag = 'Img2Img-Upscale';

  bool _naiUpscaling = false;
  bool _isFileDraggingOver = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final params = ref.watch(
      generationParamsNotifierProvider.select(selectImg2ImgPanelViewData),
    );
    final workflow = ref.watch(draftImageWorkflowProvider);
    if (widget.toolOnly) return _buildUpscalePanel(theme, workflow);
    final hasSourceImage = params.sourceImage != null;
    final showBackground = hasSourceImage && !workflow.isPanelExpanded;
    final supportsInpaint = ref.watch(
      generationParamsNotifierProvider.select(
        (params) => params.modelSpec.img2imgInpainting,
      ),
    );

    return CollapsibleImagePanel(
      frosted: true,
      title: context.l10n.img2img_title,
      subtitle: context.l10n.img2img_subtitle,
      icon: Icons.image,
      iconAsset: 'assets/icons/nai-icon-img2img.svg',
      isExpanded: workflow.isPanelExpanded,
      onToggle: () => ref
          .read(imageWorkflowControllerProvider.notifier)
          .setPanelExpanded(!workflow.isPanelExpanded),
      hasData: hasSourceImage,
      headerActions: hasSourceImage
          ? _buildLoadedHeaderActions(
              params: params,
              workflow: workflow,
              supportsInpaint: supportsInpaint,
              showBackground: showBackground,
            )
          : [
              _buildImportDropTarget(
                child: TextButton.icon(
                  onPressed: _pickImage,
                  icon: SvgPicture.asset(
                    'assets/icons/nai-icon-import.svg',
                    width: 12,
                    height: 12,
                    colorFilter: ColorFilter.mode(
                      theme.colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: Text(
                    _isFileDraggingOver
                        ? context.l10n.img2img_dropToAdd
                        : context.l10n.img2img_uploadImage,
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
      backgroundImage: hasSourceImage
          ? DecodedMemoryImage(
              bytes: params.sourceImage!,
              fit: BoxFit.cover,
              decodeScale: 0.5,
            )
          : null,
      badge: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: showBackground
              ? Colors.white.withValues(alpha: 0.2)
              : theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          context.l10n.img2img_enabled,
          style: theme.textTheme.labelSmall?.copyWith(
            color: showBackground
                ? Colors.white
                : theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ThemedDivider(),
            _buildSourceImageSection(theme, params, workflow),
            if (hasSourceImage) ...[
              const SizedBox(height: 16),
              if (workflow.isEnhance || workflow.isUpscale)
                const SizedBox.shrink()
              else if (workflow.isInpaint)
                _buildInpaintPanel(theme, params)
              else ...[
                _buildStrengthSlider(theme, params),
                const SizedBox(height: 12),
                _buildNoiseSlider(theme, params),
              ],
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _clearImg2Img,
                icon: const Icon(Icons.clear, size: 18),
                label: Text(context.l10n.img2img_clearSettings),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSourceImageSection(
    ThemeData theme,
    Img2ImgPanelViewData params,
    ImageWorkflowState workflow,
  ) {
    final hasSourceImage = params.sourceImage != null;
    if (!hasSourceImage) {
      return _buildEmptySourceSection(theme);
    }

    final isInpaintReady = workflow.isInpaint && params.maskImage != null;
    final sourceDimensions = _resolveSourceDimensions(
      workflow,
      params.sourceImage!,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 280,
            child: _SourceImagePreview(
              sourceBytes: params.sourceImage!,
              maskBytes: params.maskImage,
              focusedInpaintEnabled:
                  workflow.isInpaint && workflow.focusedInpaintEnabled,
              focusedSelectionRect: workflow.focusedSelectionRect,
              minimumContextMegaPixels: workflow.minimumContextMegaPixels,
              imageWidth: sourceDimensions.$1,
              imageHeight: sourceDimensions.$2,
            ),
          ),
        ),
        if (workflow.isInpaint) ...[
          const SizedBox(height: 10),
          _buildInpaintStatus(theme, isInpaintReady),
        ],
      ],
    );
  }

  /// 已载入底图时的头部操作列（官网式）：
  /// 微倾斜缩略图 + 重绘 / 编辑 / 换图 / 清除 四个图标 + 更多操作菜单。
  List<Widget> _buildLoadedHeaderActions({
    required Img2ImgPanelViewData params,
    required ImageWorkflowState workflow,
    required bool supportsInpaint,
    required bool showBackground,
  }) {
    final sourceImage = params.sourceImage!;
    final foreground = showBackground ? Colors.white : null;

    return [
      _buildTiltedThumbnail(sourceImage),
      const SizedBox(width: 4),
      if (supportsInpaint)
        PanelHeaderIconButton(
          key: const Key('img2img-action-inpaint'),
          iconAsset: 'assets/icons/nai-icon-inpaint.svg',
          tooltip: context.l10n.img2img_inpaint,
          selected: workflow.isInpaint,
          color: foreground,
          onPressed: () => ImageWorkflowLauncher.openEditor(
            context,
            ref,
            sourceImage,
            mode: ImageEditorMode.inpaint,
          ),
        ),
      PanelHeaderIconButton(
        key: const Key('img2img-action-edit'),
        icon: Icons.edit_outlined,
        tooltip: context.l10n.img2img_editImage,
        color: foreground,
        onPressed: () => ImageWorkflowLauncher.openEditor(
          context,
          ref,
          sourceImage,
          mode: ImageEditorMode.edit,
        ),
      ),
      PanelHeaderIconButton(
        key: const Key('img2img-action-replace'),
        iconAsset: 'assets/icons/nai-icon-swap.svg',
        tooltip: context.l10n.img2img_changeImage,
        color: foreground,
        onPressed: _pickImage,
      ),
      PanelHeaderIconButton(
        key: const Key('img2img-action-clear'),
        icon: Icons.close,
        tooltip: context.l10n.img2img_removeImage,
        color: foreground,
        onPressed: _removeSourceImage,
      ),
      Builder(
        builder: (buttonContext) => PanelHeaderIconButton(
          key: const Key('img2img-overflow-menu'),
          icon: Icons.more_vert,
          tooltip: context.l10n.img2img_moreActions,
          color: foreground,
          onPressed: () => _showOverflowMenu(
            buttonContext,
            params: params,
            workflow: workflow,
          ),
        ),
      ),
    ];
  }

  /// 官网式微倾斜缩略图：角度由图片内容散列导出，落在 ±2° 内。
  Widget _buildTiltedThumbnail(Uint8List sourceImage) {
    final tiltRadians =
        ((sourceImage.hashCode % 41) - 20) / 10 * (math.pi / 180);
    return Transform.rotate(
      angle: tiltRadians,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: 28,
          height: 28,
          child: DecodedMemoryImage(
            bytes: sourceImage,
            fit: BoxFit.cover,
            maxLogicalWidth: 28,
            maxLogicalHeight: 28,
          ),
        ),
      ),
    );
  }

  /// “更多”溢出菜单：低频操作（变体/导演工具/增强/放大/存库/ComfyUI 工作流）
  /// 收进弹出菜单，保持行内只剩四个图标（官网式）。
  void _showOverflowMenu(
    BuildContext buttonContext, {
    required Img2ImgPanelViewData params,
    required ImageWorkflowState workflow,
  }) {
    final sourceImage = params.sourceImage!;
    final comfyItems = _buildComfyUIMenuItems(params);
    final overlayBox =
        Overlay.of(buttonContext).context.findRenderObject() as RenderBox;
    final buttonBox = buttonContext.findRenderObject() as RenderBox;
    // 锚点矩形必须在 overlay 坐标系内（ancestor: overlayBox）；
    // 用全局坐标而 overlay 有偏移时菜单会整体向右下方漂移。
    final triggerRect = Rect.fromPoints(
      buttonBox.localToGlobal(Offset.zero, ancestor: overlayBox),
      buttonBox.localToGlobal(
        buttonBox.size.bottomRight(Offset.zero),
        ancestor: overlayBox,
      ),
    );

    showMenu<String>(
      context: buttonContext,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          triggerRect.left,
          triggerRect.bottom + 4,
          triggerRect.width,
          0,
        ),
        Offset.zero & overlayBox.size,
      ),
      items: [
        _overflowItem(
          value: 'variations',
          icon: Icons.auto_awesome_motion_outlined,
          label: context.l10n.img2img_generateVariations,
        ),
        _overflowItem(
          value: 'director',
          icon: Icons.auto_fix_high_outlined,
          label: context.l10n.img2img_directorTools,
        ),
        CheckedPopupMenuItem<String>(
          value: 'enhance',
          checked: workflow.isEnhance,
          height: 40,
          child: _overflowItemChild(
            icon: workflow.isEnhance
                ? Icons.auto_awesome
                : Icons.auto_awesome_outlined,
            label: context.l10n.img2img_enhance,
          ),
        ),
        CheckedPopupMenuItem<String>(
          value: 'upscale',
          checked: workflow.isUpscale,
          height: 40,
          child: _overflowItemChild(
            icon: workflow.isUpscale
                ? Icons.zoom_out_map
                : Icons.zoom_out_map_rounded,
            label: context.l10n.image_upscale,
          ),
        ),
        const PopupMenuDivider(),
        _overflowItem(
          key: const Key('img2img-save-source-to-library'),
          value: 'saveToLibrary',
          icon: Icons.bookmark_add_outlined,
          label: context.l10n.preciseRefLib_saveCurrentToLibrary,
        ),
        if (comfyItems.isNotEmpty) ...[const PopupMenuDivider(), ...comfyItems],
      ],
    ).then((value) {
      if (value == null || !mounted) return;
      _handleOverflowSelection(
        value,
        sourceImage: sourceImage,
        workflow: workflow,
      );
    });
  }

  PopupMenuItem<String> _overflowItem({
    Key? key,
    required String value,
    required IconData icon,
    required String label,
  }) {
    return PopupMenuItem<String>(
      key: key,
      value: value,
      height: 40,
      child: _overflowItemChild(icon: icon, label: label),
    );
  }

  Widget _overflowItemChild({required IconData icon, required String label}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  void _handleOverflowSelection(
    String value, {
    required Uint8List sourceImage,
    required ImageWorkflowState workflow,
  }) {
    switch (value) {
      case 'variations':
        ImageWorkflowLauncher.generateVariations(context, ref, sourceImage);
      case 'director':
        ImageWorkflowLauncher.openDirectorTools(context, ref, sourceImage);
      case 'enhance':
        _toggleEnhance(workflow);
      case 'upscale':
        _toggleUpscale(workflow);
      case 'saveToLibrary':
        _saveSourceToPreciseRefLibrary();
      case final String comfyId when comfyId.startsWith('comfy:'):
        _openComfyWorkflow(comfyId.substring(6), sourceImage);
    }
  }

  /// 行内“导入图片”落点：拖入图片即设为底图（官网式）。
  Widget _buildImportDropTarget({required Widget child}) {
    return DropRegion(
      formats: Formats.standardFormats,
      hitTestBehavior: HitTestBehavior.opaque,
      onDropOver: (event) {
        if (event.session.allowedOperations.contains(DropOperation.copy)) {
          if (!_isFileDraggingOver) {
            setState(() => _isFileDraggingOver = true);
          }
          return DropOperation.copy;
        }
        return DropOperation.none;
      },
      onDropLeave: (_) {
        if (_isFileDraggingOver) {
          setState(() => _isFileDraggingOver = false);
        }
      },
      onPerformDrop: (event) async {
        setState(() => _isFileDraggingOver = false);
        unawaited(_handleDroppedSource(event));
      },
      child: child,
    );
  }

  Future<void> _handleDroppedSource(PerformDropEvent event) async {
    for (final item in event.session.items) {
      final reader = item.dataReader;
      if (reader == null) {
        continue;
      }
      final file = await DroppedFileReader.read(reader, logTag: 'Img2ImgDrop');
      if (file != null && mounted) {
        unawaited(
          ref
              .read(imageWorkflowControllerProvider.notifier)
              .replaceSourceImageAsync(file.bytes),
        );
        return;
      }
    }
  }

  Widget _buildEmptySourceSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.l10n.img2img_sourceImage,
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // 上传入口已在标题行；这里放精准参考库导入（官网式）
            Expanded(
              child: ImagePickerCard(
                key: const Key('img2img-from-precise-ref-library'),
                icon: Icons.photo_library_outlined,
                label: context.l10n.img2img_fromPreciseRefLibrary,
                height: 80,
                enableDragDrop: false,
                onTap: () => unawaited(_importSourceFromPreciseRefLibrary()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ImagePickerCard(
                icon: Icons.brush,
                label: context.l10n.img2img_drawSketch,
                height: 80,
                enableDragDrop: false,
                onTap: _openBlankCanvas,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 把当前底图保存到精准参考库
  Future<void> _saveSourceToPreciseRefLibrary() async {
    final sourceImage = ref.read(generationParamsNotifierProvider).sourceImage;
    if (sourceImage == null) return;
    await saveBytesToPreciseRefLibrary(ref, context, sourceImage);
  }

  /// 从精准参考库选一张图作为图生图底图
  Future<void> _importSourceFromPreciseRefLibrary() async {
    final selected = await PreciseRefSelectorDialog.show(
      context,
      multiSelect: false,
    );
    if (selected == null || selected.isEmpty || !mounted) return;

    final entry = selected.first;
    final bytes = await ref
        .read(preciseRefLibraryStorageServiceProvider)
        .readImageBytes(entry.id);
    if (!mounted) return;
    if (bytes == null) {
      AppToast.error(context, context.l10n.preciseRefLib_imageMissing);
      return;
    }

    unawaited(
      ref
          .read(imageWorkflowControllerProvider.notifier)
          .replaceSourceImageAsync(bytes),
    );
    unawaited(
      ref
          .read(preciseRefLibraryNotifierProvider.notifier)
          .recordUsage(entry.id),
    );
  }

  Widget _buildInpaintStatus(ThemeData theme, bool isReady) {
    // 就绪用 primary、待处理用 tertiary：两组 container/onContainer 配对由
    // Material 3 保证对比度，在浅色与深色主题下都可读。
    final background = isReady
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.tertiaryContainer;
    final foreground = isReady
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onTertiaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: foreground.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isReady ? Icons.check_circle : Icons.info_outline,
            size: 16,
            color: foreground,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isReady
                  ? context.l10n.img2img_inpaintReadyHint
                  : context.l10n.img2img_inpaintPendingHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: foreground,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrengthSlider(ThemeData theme, Img2ImgPanelViewData params) {
    return _buildSliderSection(
      theme,
      label: context.l10n.img2img_strength,
      value: params.strength,
      hint: context.l10n.img2img_strengthHint,
      onChanged: (value) {
        ref
            .read(generationParamsNotifierProvider.notifier)
            .updateStrength(value);
      },
    );
  }

  Widget _buildNoiseSlider(ThemeData theme, Img2ImgPanelViewData params) {
    return _buildSliderSection(
      theme,
      label: context.l10n.img2img_noise,
      value: params.noise,
      hint: context.l10n.img2img_noiseHint,
      onChanged: (value) {
        ref.read(generationParamsNotifierProvider.notifier).updateNoise(value);
      },
    );
  }

  Widget _buildInpaintPanel(ThemeData theme, Img2ImgPanelViewData params) {
    final workflow = ref.watch(draftImageWorkflowProvider);
    final generationSize = ref.watch(
      generationParamsNotifierProvider.select(
        (generationParams) => (generationParams.width, generationParams.height),
      ),
    );
    final focusRect = workflow.focusedSelectionRect;
    final focusGeometry = focusRect == null
        ? null
        : FocusedInpaintUtils.resolveGeometryForSelection(
            sourceWidth:
                workflow.sourceImageWidth ??
                workflow.sourceWidth ??
                generationSize.$1,
            sourceHeight:
                workflow.sourceImageHeight ??
                workflow.sourceHeight ??
                generationSize.$2,
            selectionRect: focusRect,
            minContextMegaPixels: workflow.minimumContextMegaPixels,
          );
    final focusedCost = focusGeometry == null
        ? null
        : ref.watch(estimatedCostProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _subPanelDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSliderSection(
            theme,
            label: context.l10n.img2img_inpaintStrength,
            value: params.inpaintStrength,
            hint: context.l10n.img2img_inpaintStrengthHint,
            onChanged: (value) {
              ref
                  .read(generationParamsNotifierProvider.notifier)
                  .updateInpaintStrength(value);
            },
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              context.l10n.img2img_focusedInpaint,
              style: theme.textTheme.bodyMedium,
            ),
            subtitle: Text(
              workflow.focusedInpaintEnabled && focusGeometry != null
                  ? '${context.l10n.img2img_focusedInpaintEnabledHint}\n'
                        '${context.l10n.editor_focusRequestSummary(focusGeometry.contextCrop.width, focusGeometry.contextCrop.height, focusGeometry.requestWidth, focusGeometry.requestHeight, focusedCost ?? 0)}'
                  : workflow.focusedInpaintEnabled
                  ? context.l10n.img2img_focusedInpaintEnabledHint
                  : context.l10n.img2img_focusedInpaintDisabledHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: workflow.focusedInpaintEnabled
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.5,
                      ),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: workflow.focusedInpaintEnabled
                      ? theme.colorScheme.primary.withValues(alpha: 0.35)
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                workflow.focusedInpaintEnabled
                    ? context.l10n.img2img_enabled
                    : context.l10n.img2img_disabled,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: workflow.focusedInpaintEnabled
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  (int, int) _resolveSourceDimensions(
    ImageWorkflowState workflow,
    Uint8List sourceBytes,
  ) {
    return resolveSourcePreviewDimensions(
      sourceBytes: sourceBytes,
      sourceWidth: workflow.sourceImageWidth,
      sourceHeight: workflow.sourceImageHeight,
      fallbackWidth: workflow.sourceWidth,
      fallbackHeight: workflow.sourceHeight,
    );
  }

  /// 重绘 / 增强 / 放大三个子面板共用的容器装饰。
  ///
  /// 原先写死 `Colors.black26` + `Colors.white12`，在浅色主题下会变成
  /// 灰底配白字。改用主题槽位后两种亮度下都保持层次。
  BoxDecoration _subPanelDecoration(ThemeData theme) {
    return BoxDecoration(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildSliderSection(
    ThemeData theme, {
    required String label,
    required double value,
    ValueChanged<double>? onChanged,
    String? hint,
    double min = 0.0,
    double max = 1.0,
    int? divisions,
    String Function(double value)? valueLabelBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            const Spacer(),
            Text(
              valueLabelBuilder?.call(value) ?? value.toStringAsFixed(2),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions ?? ((max - min) * 100).round(),
          onChanged: onChanged,
        ),
        if (hint != null)
          Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _buildUpscalePanel(ThemeData theme, ImageWorkflowState workflow) {
    final comfyEnabled = ref.watch(
      comfyUISettingsProvider.select((s) => s.enabled),
    );
    final taskState = ref.watch(comfyUITaskProvider);
    final taskError = taskState.localizedError(context.l10n);
    final hasSourceImage = ref.watch(
      generationParamsNotifierProvider.select(
        (params) => params.sourceImage != null,
      ),
    );
    final controller = ref.read(imageWorkflowControllerProvider.notifier);
    final upscale = workflow.upscale;
    final isNai = upscale.backend == UpscaleBackend.novelai;
    final isComfy = upscale.backend == UpscaleBackend.comfyui;
    final comfyModule = upscale.comfyModule;
    final currentComfyModel = upscale.comfyModelForModule(comfyModule);

    final availableModels = ref.watch(comfyUISeedvr2ModelsProvider);
    final moduleModels = filterComfyUpscaleModelsForModule(
      availableModels,
      module: comfyModule,
    );
    final modelsFetchedFromServer = ref
        .read(comfyUISeedvr2ModelsProvider.notifier)
        .hasFetchedFromServer;
    final resolvedComfyModel = resolveComfyUpscaleModelForModule(
      availableModels,
      module: comfyModule,
      currentModel: currentComfyModel,
    );
    final isComfySeedvr2 = comfyModule == ComfyUpscaleModule.seedvr2;
    final isComfyRtx = comfyModule == ComfyUpscaleModule.rtx;

    if (resolvedComfyModel != null &&
        shouldAutoPersistResolvedUpscaleModel(
          isComfyBackend: isComfy,
          hasFetchedFromServer: modelsFetchedFromServer,
          availableModels: moduleModels,
          currentModel: currentComfyModel,
          resolvedModel: resolvedComfyModel,
        )) {
      Future.microtask(
        () => controller.updateUpscaleComfyModel(resolvedComfyModel),
      );
    }

    final bool canStart;
    if (isNai) {
      canStart = hasSourceImage && !_naiUpscaling;
    } else {
      final hasRequiredComfyModel = isComfyRtx || resolvedComfyModel != null;
      canStart =
          comfyEnabled &&
          hasSourceImage &&
          !taskState.isRunning &&
          hasRequiredComfyModel;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _subPanelDecoration(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.image_upscale,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<UpscaleBackend>(
            segments: [
              const ButtonSegment(
                value: UpscaleBackend.novelai,
                label: Text('NovelAI'),
                icon: Icon(Icons.cloud_outlined, size: 16),
              ),
              ButtonSegment(
                value: UpscaleBackend.comfyui,
                label: const Text('ComfyUI'),
                icon: const Icon(Icons.computer, size: 16),
                enabled: comfyEnabled,
              ),
            ],
            selected: {upscale.backend},
            onSelectionChanged: (v) => controller.updateUpscaleBackend(v.first),
            showSelectedIcon: false,
            style: const ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(height: 12),
          if (isNai) ...[
            Text(
              context.l10n.img2img_novelAiCloudUpscale,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ] else ...[
            if (!comfyEnabled)
              Text(
                context.l10n.img2img_comfyuiEnableHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              )
            else ...[
              Text(
                context.l10n.img2img_upscaleMode,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              SegmentedButton<ComfyUpscaleModule>(
                segments: [
                  ButtonSegment(
                    value: ComfyUpscaleModule.regular,
                    label: Text(context.l10n.img2img_upscaleRegularModel),
                    icon: const Icon(Icons.auto_fix_high_outlined, size: 16),
                  ),
                  const ButtonSegment(
                    value: ComfyUpscaleModule.seedvr2,
                    label: Text('SeedVR2'),
                    icon: Icon(Icons.video_settings_outlined, size: 16),
                  ),
                  const ButtonSegment(
                    value: ComfyUpscaleModule.rtx,
                    label: Text('RTX'),
                    icon: Icon(Icons.memory_outlined, size: 16),
                  ),
                ],
                selected: {comfyModule},
                onSelectionChanged: (v) =>
                    controller.updateComfyUpscaleModule(v.first),
                showSelectedIcon: false,
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(height: 12),
              _buildSelectedUpscaleMetrics(theme, selectedModule: comfyModule),
              const SizedBox(height: 12),
              if (!isComfyRtx) ...[
                Text(
                  context.l10n.img2img_upscaleModel,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  key: ValueKey(
                    'upscale_model_${comfyModule.name}_${moduleModels.length}',
                  ),
                  initialValue: moduleModels.contains(resolvedComfyModel)
                      ? resolvedComfyModel
                      : null,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  dropdownColor: theme.colorScheme.surfaceContainerHigh,
                  items: moduleModels
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(
                            _friendlyModelName(m),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: moduleModels.isEmpty
                      ? null
                      : (v) {
                          if (v != null) {
                            controller.updateUpscaleComfyModel(v);
                          }
                        },
                ),
                if (moduleModels.isEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    isComfySeedvr2
                        ? context.l10n.img2img_noSeedvr2Models
                        : context.l10n.img2img_noRegularUpscaleModels,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
              ],
              Text(
                switch (comfyModule) {
                  ComfyUpscaleModule.seedvr2 when upscale.seedvr2Tiled =>
                    context.l10n.img2img_useSeedvr2TiledWorkflow,
                  ComfyUpscaleModule.seedvr2 =>
                    context.l10n.img2img_useSeedvr2Workflow,
                  ComfyUpscaleModule.regular =>
                    context.l10n.img2img_useRegularUpscaleWorkflow,
                  ComfyUpscaleModule.rtx =>
                    context.l10n.img2img_useRtxUpscaleWorkflow,
                },
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (!isComfyRtx)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () =>
                        ref.read(comfyUISeedvr2ModelsProvider.notifier).fetch(),
                    icon: const Icon(Icons.refresh, size: 14),
                    label: Text(
                      context.l10n.img2img_refreshModelList,
                      style: theme.textTheme.labelSmall,
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 28),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              _buildScaleSlider(theme, upscale, controller),
              if (isComfySeedvr2) ...[
                const SizedBox(height: 8),
                _buildSeedvr2Controls(theme, upscale, controller),
              ],
              const SizedBox(height: 8),
              if (taskState.isRunning) ...[
                if (taskState.hasPreview) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      taskState.previewImage!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const LinearProgressIndicator(),
              ] else if (taskState.status == ComfyUITaskStatus.failed &&
                  taskError != null)
                Text(
                  taskError,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
            ],
          ],
          if (_naiUpscaling) ...[
            const SizedBox(height: 8),
            const LinearProgressIndicator(),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: canStart ? _runUpscale : null,
            icon: const Icon(Icons.play_arrow, size: 20),
            label: Text(context.l10n.img2img_startUpscale),
          ),
        ],
      ),
    );
  }

  Widget _buildScaleSlider(
    ThemeData theme,
    UpscaleWorkflowSettings upscale,
    ImageWorkflowController controller,
  ) {
    final value = upscale.comfyScale.clamp(
      UpscaleWorkflowSettings.minScale,
      UpscaleWorkflowSettings.maxScale,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.upscale_scale,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            EditableDoubleField(
              value: value,
              min: UpscaleWorkflowSettings.minScale,
              max: UpscaleWorkflowSettings.maxScale,
              decimals: 1,
              width: 60,
              onChanged: controller.updateUpscaleComfyScale,
              textStyle: theme.textTheme.bodySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: value,
            min: UpscaleWorkflowSettings.minScale,
            max: UpscaleWorkflowSettings.maxScale,
            divisions: 10,
            onChanged: controller.updateUpscaleComfyScale,
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedUpscaleMetrics(
    ThemeData theme, {
    required ComfyUpscaleModule selectedModule,
  }) {
    final profile = _profileForModule(selectedModule);
    final borderRadius = BorderRadius.circular(10);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.25,
        ),
      ),
      child: Column(
        children: [
          _buildUpscaleMetricBar(
            theme,
            label: context.l10n.img2img_metricSpeed,
            level: profile.speed,
            higherIsBetter: true,
            animationKey: '${profile.module.name}_speed',
          ),
          const SizedBox(height: 6),
          _buildUpscaleMetricBar(
            theme,
            label: context.l10n.img2img_metricVram,
            level: profile.vram,
            higherIsBetter: false,
            animationKey: '${profile.module.name}_vram',
          ),
          const SizedBox(height: 6),
          _buildUpscaleMetricBar(
            theme,
            label: context.l10n.img2img_metricQuality,
            level: profile.quality,
            higherIsBetter: true,
            animationKey: '${profile.module.name}_quality',
          ),
        ],
      ),
    );
  }

  _UpscaleModuleProfile _profileForModule(ComfyUpscaleModule module) {
    return _upscaleModuleProfiles.firstWhere(
      (profile) => profile.module == module,
      orElse: () => _upscaleModuleProfiles.first,
    );
  }

  Widget _buildUpscaleMetricBar(
    ThemeData theme, {
    required String label,
    required _UpscaleMetricLevel level,
    required bool higherIsBetter,
    required String animationKey,
  }) {
    final gradientColors = _metricGradientColors(
      level,
      higherIsBetter: higherIsBetter,
    );
    return Row(
      children: [
        SizedBox(
          width: 34,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TweenAnimationBuilder<double>(
            key: ValueKey(animationKey),
            tween: Tween<double>(begin: 0, end: level.value),
            duration: const Duration(milliseconds: 460),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: value.clamp(0.0, 1.0).toDouble(),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradientColors),
                          boxShadow: [
                            BoxShadow(
                              color: gradientColors.last.withValues(
                                alpha: 0.32,
                              ),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Color> _metricGradientColors(
    _UpscaleMetricLevel level, {
    required bool higherIsBetter,
  }) {
    if (higherIsBetter) {
      return switch (level) {
        _UpscaleMetricLevel.low => const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
        _UpscaleMetricLevel.medium => const [
          Color(0xFF38BDF8),
          Color(0xFF22D3EE),
        ],
        _UpscaleMetricLevel.high => const [
          Color(0xFF34D399),
          Color(0xFFA3E635),
        ],
      };
    }
    return switch (level) {
      _UpscaleMetricLevel.low => const [Color(0xFF34D399), Color(0xFF2DD4BF)],
      _UpscaleMetricLevel.medium => const [
        Color(0xFFF59E0B),
        Color(0xFFFBBF24),
      ],
      _UpscaleMetricLevel.high => const [Color(0xFFFB7185), Color(0xFFF43F5E)],
    };
  }

  Widget _buildSeedvr2Controls(
    ThemeData theme,
    UpscaleWorkflowSettings upscale,
    ImageWorkflowController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildIntegerSliderSection(
          theme,
          label: context.l10n.img2img_seedvr2BlocksToSwap,
          value: upscale.seedvr2BlocksToSwap,
          min: UpscaleWorkflowSettings.minSeedvr2BlocksToSwap,
          max: UpscaleWorkflowSettings.maxSeedvr2BlocksToSwap,
          step: 1,
          onChanged: controller.updateSeedvr2BlocksToSwap,
          hint: context.l10n.img2img_seedvr2BlocksToSwapHint,
        ),
        _buildIntegerSliderSection(
          theme,
          label: 'VAE Tile Size',
          value: upscale.seedvr2VaeTileSize,
          min: UpscaleWorkflowSettings.minSeedvr2VaeTileSize,
          max: UpscaleWorkflowSettings.maxSeedvr2VaeTileSize,
          step: 64,
          onChanged: controller.updateSeedvr2VaeTileSize,
          hint: context.l10n.img2img_seedvr2VaeTileHint,
        ),
        Material(
          type: MaterialType.transparency,
          child: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              context.l10n.img2img_seedvr2UseTiledUpscale,
              style: theme.textTheme.bodyMedium,
            ),
            subtitle: Text(
              context.l10n.img2img_seedvr2UseTiledUpscaleHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            value: upscale.seedvr2Tiled,
            onChanged: controller.updateSeedvr2Tiled,
          ),
        ),
        if (upscale.seedvr2Tiled)
          _buildIntegerSliderSection(
            theme,
            label: context.l10n.img2img_seedvr2TileSize,
            value: upscale.seedvr2TileSize,
            min: UpscaleWorkflowSettings.minSeedvr2TileSize,
            max: UpscaleWorkflowSettings.maxSeedvr2TileSize,
            step: 64,
            onChanged: controller.updateSeedvr2TileSize,
            hint: context.l10n.img2img_seedvr2TileSizeHint,
          ),
      ],
    );
  }

  Widget _buildIntegerSliderSection(
    ThemeData theme, {
    required String label,
    required int value,
    required int min,
    required int max,
    required int step,
    required ValueChanged<double> onChanged,
    String? hint,
  }) {
    final clamped = value.clamp(min, max).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            EditableDoubleField(
              value: clamped.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              decimals: 0,
              width: 72,
              onChanged: onChanged,
              textStyle: theme.textTheme.bodySmall?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: clamped.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: ((max - min) / step).round(),
            onChanged: onChanged,
          ),
        ),
        if (hint != null)
          Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  static String _friendlyModelName(String filename) {
    return filename
        .replaceAll('.safetensors', '')
        .replaceAll('.ckpt', '')
        .replaceAll('.pth', '')
        .replaceAll('.pt', '');
  }

  static String _sourceLogSummary(ImageParams params, Uint8List src) {
    return 'sourceBytes=${src.length}, paramsSize=${params.width}x${params.height}, '
        'action=${params.action.name}, model=${params.model}';
  }

  static String _workflowLogSummary(ImageWorkflowState wf) {
    final upscale = wf.upscale;
    return 'backend=${upscale.backend.name}, module=${upscale.comfyModule.name}, '
        'scale=${upscale.comfyScale}, comfyModel=${upscale.comfyModel}, '
        'seedvr2Tiled=${upscale.seedvr2Tiled}, '
        'seedvr2VaeTileSize=${upscale.seedvr2VaeTileSize}, '
        'seedvr2TileSize=${upscale.seedvr2TileSize}, '
        'seedvr2BlocksToSwap=${upscale.seedvr2BlocksToSwap}, '
        'fileLogging=${AppLogger.fileLoggingEnabled}';
  }

  static String _resultLogSummary(List<Uint8List>? results) {
    if (results == null) return 'null';
    return 'count=${results.length}, bytes=[${results.map((r) => r.length).join(', ')}]';
  }

  Future<void> _runUpscale() async {
    final controller = ref.read(imageWorkflowControllerProvider.notifier);
    if (ref.read(imageWorkflowControllerProvider).isToolRunning) return;
    final params = ref.read(generationParamsNotifierProvider);
    final src = params.sourceImage;
    if (src == null) {
      AppLogger.w(
        'Start requested but source image is missing',
        _upscaleLogTag,
      );
      return;
    }

    final wf = ref.read(imageWorkflowControllerProvider);
    AppLogger.i(
      'Start requested: ${_sourceLogSummary(params, src)}; '
      '${_workflowLogSummary(wf)}',
      _upscaleLogTag,
    );

    controller.setToolRunning(true);
    try {
      if (wf.upscale.backend == UpscaleBackend.novelai) {
        AppLogger.d('Dispatching to NovelAI upscale', _upscaleLogTag);
        await _runNaiUpscale(params, src);
      } else {
        AppLogger.d('Dispatching to ComfyUI upscale', _upscaleLogTag);
        await _runComfyUpscale(params, src, wf);
      }
    } finally {
      controller.setToolRunning(false);
    }
  }

  Future<void> _runComfyUpscale(
    ImageParams params,
    Uint8List src,
    ImageWorkflowState wf,
  ) async {
    AppLogger.d(
      'ComfyUI module selected: ${wf.upscale.comfyModule.name}',
      _upscaleLogTag,
    );
    switch (wf.upscale.comfyModule) {
      case ComfyUpscaleModule.regular:
        await _runComfyModelUpscale(params, src, wf);
        break;
      case ComfyUpscaleModule.seedvr2:
        await _runComfySeedvr2Upscale(params, src, wf);
        break;
      case ComfyUpscaleModule.rtx:
        await _runComfyRtxUpscale(params, src, wf);
        break;
    }
  }

  Future<void> _runNaiUpscale(ImageParams params, Uint8List src) async {
    AppLogger.i(
      'NovelAI upscale begin: ${_sourceLogSummary(params, src)}',
      _upscaleLogTag,
    );
    final subscriptionNotifier = ref.read(
      subscriptionNotifierProvider.notifier,
    );
    setState(() => _naiUpscaling = true);
    try {
      final apiService = ref.read(naiImageEnhancementApiServiceProvider);
      AppLogger.d('NovelAI upscale API request start', _upscaleLogTag);
      final result = await apiService.upscaleImage(src, scale: 4);
      AppLogger.i(
        'NovelAI upscale API returned: bytes=${result.length}',
        _upscaleLogTag,
      );
      if (!mounted) return;

      final saveSettings = ref.read(imageSaveSettingsNotifierProvider);
      AppLogger.d(
        'Registering NovelAI upscale result: autoSave=${saveSettings.autoSave}',
        _upscaleLogTag,
      );
      await ref
          .read(imageGenerationNotifierProvider.notifier)
          .registerExternalImage(
            result,
            params: params,
            operation: ImageOperation.upscale,
            originalBytes: src,
            saveToLocal: saveSettings.autoSave,
            replaceCurrentDisplay: true,
          );
      AppLogger.i('NovelAI upscale result registered', _upscaleLogTag);
      if (mounted) {
        AppToast.success(context, context.l10n.img2img_novelAiUpscaleComplete);
      }
    } catch (e) {
      AppLogger.w('NovelAI upscale failed: $e', _upscaleLogTag);
      if (mounted) AppToast.error(context, e.toString());
    } finally {
      subscriptionNotifier.schedulePostBillingRefresh();
      AppLogger.d('NovelAI upscale end', _upscaleLogTag);
      if (mounted) setState(() => _naiUpscaling = false);
    }
  }

  Future<void> _runComfySeedvr2Upscale(
    ImageParams params,
    Uint8List src,
    ImageWorkflowState wf,
  ) async {
    final scale = wf.upscale.comfyScale;
    final seedvr2Models = ref.read(comfyUISeedvr2ModelsProvider);
    AppLogger.i(
      'SeedVR2 upscale begin: ${_sourceLogSummary(params, src)}; '
      '${_workflowLogSummary(wf)}',
      _upscaleLogTag,
    );
    final model = resolveComfyUpscaleModelForModule(
      seedvr2Models,
      module: ComfyUpscaleModule.seedvr2,
      currentModel: wf.upscale.comfyModel,
    );
    AppLogger.d(
      'SeedVR2 model resolved: available=${seedvr2Models.length}, '
      'selected=${model ?? '<none>'}',
      _upscaleLogTag,
    );
    if (model == null) {
      AppLogger.w('SeedVR2 model is missing', _upscaleLogTag);
      if (mounted) {
        AppToast.error(context, context.l10n.img2img_noAvailableSeedvr2Model);
      }
      return;
    }
    AppLogger.d('SeedVR2 source decode start', _upscaleLogTag);
    final decodedSource = img.decodeImage(src);
    if (decodedSource == null) {
      AppLogger.w('SeedVR2 source decode failed', _upscaleLogTag);
      if (mounted) {
        AppToast.error(context, context.l10n.img2img_decodeSourceFailed);
      }
      return;
    }
    AppLogger.d(
      'SeedVR2 source decoded: ${decodedSource.width}x${decodedSource.height}',
      _upscaleLogTag,
    );
    final targetResolution = wf.upscale.seedvr2Tiled
        ? calculateComfySeedvr2TiledTargetResolution(
            sourceWidth: decodedSource.width,
            sourceHeight: decodedSource.height,
            scale: scale,
          )
        : calculateComfySeedvr2TargetResolution(
            sourceWidth: decodedSource.width,
            sourceHeight: decodedSource.height,
            scale: scale,
          );
    final templateId = wf.upscale.seedvr2Tiled
        ? comfySeedvr2TiledUpscaleTemplateId
        : comfySeedvr2UpscaleTemplateId;
    final tileUpscaleResolution = math.max(
      64,
      math.min(8192, (wf.upscale.seedvr2TileSize * scale).round()),
    );

    AppLogger.i(
      'SeedVR2 execute start: template=$templateId, model=$model, '
      'targetResolution=$targetResolution, tileUpscaleResolution=$tileUpscaleResolution',
      _upscaleLogTag,
    );
    final results = await ref
        .read(comfyUITaskProvider.notifier)
        .execute(
          templateId: templateId,
          inputImages: {'input_image': src},
          paramValues: {
            'target_resolution': targetResolution,
            'dit_model': model,
            'vae_encode_tile_size': wf.upscale.seedvr2VaeTileSize,
            'vae_decode_tile_size': wf.upscale.seedvr2VaeTileSize,
            'blocks_to_swap': wf.upscale.seedvr2BlocksToSwap,
            'swap_io_components': resolveSeedvr2SwapIoComponents(
              wf.upscale.seedvr2BlocksToSwap,
            ),
            if (wf.upscale.seedvr2Tiled) ...{
              'tile_size': wf.upscale.seedvr2TileSize,
              'tile_upscale_resolution': tileUpscaleResolution,
            },
            'seed': -1,
          },
        );
    AppLogger.i(
      'SeedVR2 execute returned: ${_resultLogSummary(results)}',
      _upscaleLogTag,
    );

    if (!mounted || results == null || results.isEmpty) {
      AppLogger.w(
        'SeedVR2 result ignored: mounted=$mounted, '
        'results=${_resultLogSummary(results)}',
        _upscaleLogTag,
      );
      return;
    }

    final bytes = results.last;

    AppLogger.d(
      'SeedVR2 result decode start: bytes=${bytes.length}',
      _upscaleLogTag,
    );
    final decoded = img.decodeImage(bytes);
    final outW = decoded?.width ?? (decodedSource.width * scale).round();
    final outH = decoded?.height ?? (decodedSource.height * scale).round();
    AppLogger.d('SeedVR2 result size: ${outW}x$outH', _upscaleLogTag);

    final saveSettings = ref.read(imageSaveSettingsNotifierProvider);
    AppLogger.d(
      'Registering SeedVR2 result: autoSave=${saveSettings.autoSave}',
      _upscaleLogTag,
    );
    await ref
        .read(imageGenerationNotifierProvider.notifier)
        .registerExternalImage(
          bytes,
          params: params,
          operation: ImageOperation.upscale,
          originalBytes: src,
          width: outW,
          height: outH,
          saveToLocal: saveSettings.autoSave,
          replaceCurrentDisplay: true,
        );
    AppLogger.i('SeedVR2 result registered: ${outW}x$outH', _upscaleLogTag);

    if (mounted) {
      AppToast.success(
        context,
        context.l10n.img2img_upscaleComplete(outW, outH),
      );
    }
  }

  Future<void> _runComfyModelUpscale(
    ImageParams params,
    Uint8List src,
    ImageWorkflowState wf,
  ) async {
    final scale = wf.upscale.comfyScale;
    final upscaleModels = ref.read(comfyUISeedvr2ModelsProvider);
    AppLogger.i(
      'Regular ComfyUI upscale begin: ${_sourceLogSummary(params, src)}; '
      '${_workflowLogSummary(wf)}',
      _upscaleLogTag,
    );
    final model = resolveComfyUpscaleModelForModule(
      upscaleModels,
      module: ComfyUpscaleModule.regular,
      currentModel: wf.upscale.comfyModel,
    );
    AppLogger.d(
      'Regular ComfyUI model resolved: available=${upscaleModels.length}, '
      'selected=${model ?? '<none>'}',
      _upscaleLogTag,
    );
    if (model == null) {
      AppLogger.w('Regular ComfyUI model is missing', _upscaleLogTag);
      if (mounted) {
        AppToast.error(
          context,
          context.l10n.img2img_noAvailableRegularUpscaleModel,
        );
      }
      return;
    }
    AppLogger.d('Regular ComfyUI source decode start', _upscaleLogTag);
    final decodedSource = img.decodeImage(src);
    if (decodedSource == null) {
      AppLogger.w('Regular ComfyUI source decode failed', _upscaleLogTag);
      if (mounted) {
        AppToast.error(context, context.l10n.img2img_decodeSourceFailed);
      }
      return;
    }
    AppLogger.d(
      'Regular ComfyUI source decoded: ${decodedSource.width}x${decodedSource.height}',
      _upscaleLogTag,
    );

    final targetWidth = math.max(1, (decodedSource.width * scale).round());
    final targetHeight = math.max(1, (decodedSource.height * scale).round());

    AppLogger.i(
      'Regular ComfyUI execute start: template=$comfyModelUpscaleTemplateId, '
      'model=$model, target=${targetWidth}x$targetHeight',
      _upscaleLogTag,
    );
    final results = await ref
        .read(comfyUITaskProvider.notifier)
        .execute(
          templateId: comfyModelUpscaleTemplateId,
          inputImages: {'input_image': src},
          paramValues: {
            'upscale_model': model,
            'target_width': targetWidth,
            'target_height': targetHeight,
          },
        );
    AppLogger.i(
      'Regular ComfyUI execute returned: ${_resultLogSummary(results)}',
      _upscaleLogTag,
    );

    if (!mounted || results == null || results.isEmpty) {
      AppLogger.w(
        'Regular ComfyUI result ignored: mounted=$mounted, '
        'results=${_resultLogSummary(results)}',
        _upscaleLogTag,
      );
      return;
    }

    final bytes = results.last;
    AppLogger.d(
      'Regular ComfyUI result decode start: bytes=${bytes.length}',
      _upscaleLogTag,
    );
    final decoded = img.decodeImage(bytes);
    final outW = decoded?.width ?? targetWidth;
    final outH = decoded?.height ?? targetHeight;
    AppLogger.d('Regular ComfyUI result size: ${outW}x$outH', _upscaleLogTag);

    final saveSettings = ref.read(imageSaveSettingsNotifierProvider);
    AppLogger.d(
      'Registering regular ComfyUI result: autoSave=${saveSettings.autoSave}',
      _upscaleLogTag,
    );
    await ref
        .read(imageGenerationNotifierProvider.notifier)
        .registerExternalImage(
          bytes,
          params: params,
          operation: ImageOperation.upscale,
          originalBytes: src,
          width: outW,
          height: outH,
          saveToLocal: saveSettings.autoSave,
          replaceCurrentDisplay: true,
        );
    AppLogger.i(
      'Regular ComfyUI result registered: ${outW}x$outH',
      _upscaleLogTag,
    );

    if (mounted) {
      AppToast.success(
        context,
        context.l10n.img2img_regularUpscaleComplete(outW, outH),
      );
    }
  }

  Future<void> _runComfyRtxUpscale(
    ImageParams params,
    Uint8List src,
    ImageWorkflowState wf,
  ) async {
    final scale = wf.upscale.comfyScale;
    AppLogger.i(
      'RTX upscale begin: ${_sourceLogSummary(params, src)}; '
      '${_workflowLogSummary(wf)}',
      _upscaleLogTag,
    );
    AppLogger.d('RTX source decode start', _upscaleLogTag);
    final decodedSource = img.decodeImage(src);
    if (decodedSource == null) {
      AppLogger.w('RTX source decode failed', _upscaleLogTag);
      if (mounted) {
        AppToast.error(context, context.l10n.img2img_decodeSourceFailed);
      }
      return;
    }
    AppLogger.d(
      'RTX source decoded: ${decodedSource.width}x${decodedSource.height}',
      _upscaleLogTag,
    );

    AppLogger.i(
      'RTX execute start: template=$comfyRtxUpscaleTemplateId, scale=$scale',
      _upscaleLogTag,
    );
    final results = await ref
        .read(comfyUITaskProvider.notifier)
        .execute(
          templateId: comfyRtxUpscaleTemplateId,
          inputImages: {'input_image': src},
          paramValues: {'rtx_scale': scale},
        );
    AppLogger.i(
      'RTX execute returned: ${_resultLogSummary(results)}',
      _upscaleLogTag,
    );

    if (!mounted || results == null || results.isEmpty) {
      AppLogger.w(
        'RTX result ignored: mounted=$mounted, results=${_resultLogSummary(results)}',
        _upscaleLogTag,
      );
      return;
    }

    final bytes = results.last;
    AppLogger.d(
      'RTX result decode start: bytes=${bytes.length}',
      _upscaleLogTag,
    );
    final decoded = img.decodeImage(bytes);
    final outW =
        decoded?.width ??
        math.max(8, ((decodedSource.width * scale) / 8).round() * 8);
    final outH =
        decoded?.height ??
        math.max(8, ((decodedSource.height * scale) / 8).round() * 8);
    AppLogger.d('RTX result size: ${outW}x$outH', _upscaleLogTag);

    final saveSettings = ref.read(imageSaveSettingsNotifierProvider);
    AppLogger.d(
      'Registering RTX result: autoSave=${saveSettings.autoSave}',
      _upscaleLogTag,
    );
    await ref
        .read(imageGenerationNotifierProvider.notifier)
        .registerExternalImage(
          bytes,
          params: params,
          operation: ImageOperation.upscale,
          originalBytes: src,
          width: outW,
          height: outH,
          saveToLocal: saveSettings.autoSave,
          replaceCurrentDisplay: true,
        );
    AppLogger.i('RTX result registered: ${outW}x$outH', _upscaleLogTag);

    if (mounted) {
      AppToast.success(
        context,
        context.l10n.img2img_rtxUpscaleComplete(outW, outH),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        Uint8List? bytes;

        if (file.bytes != null) {
          bytes = file.bytes;
        } else if (file.path != null) {
          bytes = await File(file.path!).readAsBytes();
        }

        if (bytes != null) {
          await ref
              .read(imageWorkflowControllerProvider.notifier)
              .replaceSourceImageAsync(bytes);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          context.l10n.img2img_selectFailed(e.toString()),
        );
      }
    }
  }

  void _removeSourceImage() {
    ref.read(imageWorkflowControllerProvider.notifier).clearSourceImage();
  }

  void _clearImg2Img() {
    _removeSourceImage();
  }

  List<PopupMenuEntry<String>> _buildComfyUIMenuItems(
    Img2ImgPanelViewData params,
  ) {
    final bool comfyEnabled;
    try {
      comfyEnabled = ref.watch(
        comfyUISettingsProvider.select((s) => s.enabled),
      );
    } catch (_) {
      return [];
    }
    if (!comfyEnabled) return [];

    final List<WorkflowTemplate> workflows;
    try {
      workflows = ref.watch(comfyUIWorkflowsProvider);
    } catch (_) {
      return [];
    }
    final eligibleWorkflows = workflows
        .where(
          (t) =>
              t.id != comfySeedvr2UpscaleTemplateId &&
              t.id != comfySeedvr2TiledUpscaleTemplateId &&
              t.id != comfyModelUpscaleTemplateId &&
              t.id != comfyRtxUpscaleTemplateId &&
              t.requiresInputImage,
        )
        .toList();

    if (eligibleWorkflows.isEmpty) return [];

    return eligibleWorkflows.map<PopupMenuEntry<String>>((template) {
      final icon = switch (template.category) {
        WorkflowCategory.img2img => Icons.image_outlined,
        WorkflowCategory.inpaint => Icons.draw_outlined,
        WorkflowCategory.enhance => Icons.auto_fix_high_outlined,
        _ => Icons.account_tree_outlined,
      };
      return PopupMenuItem<String>(
        value: 'comfy:${template.id}',
        height: 40,
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(template.localizedName(context)),
          ],
        ),
      );
    }).toList();
  }

  void _openComfyWorkflow(String templateId, Uint8List sourceImage) {
    final List<WorkflowTemplate> workflows;
    try {
      workflows = ref.read(comfyUIWorkflowsProvider);
    } catch (_) {
      return;
    }
    final template = workflows.where((t) => t.id == templateId).firstOrNull;
    if (template == null) return;

    ComfyUIWorkflowDialog.show(context, template: template, image: sourceImage);
  }

  void _toggleEnhance(ImageWorkflowState workflow) {
    final controller = ref.read(imageWorkflowControllerProvider.notifier);
    if (workflow.isEnhance) {
      controller.closeTemporaryTool();
    } else {
      final source = ref.read(generationParamsNotifierProvider).sourceImage;
      if (source != null) {
        controller.openTemporaryTool(source, ImageWorkflowMode.enhance);
      }
    }
  }

  void _toggleUpscale(ImageWorkflowState workflow) {
    final controller = ref.read(imageWorkflowControllerProvider.notifier);
    if (workflow.isUpscale) {
      controller.closeTemporaryTool();
    } else {
      final source = ref.read(generationParamsNotifierProvider).sourceImage;
      if (source != null) {
        controller.openTemporaryTool(source, ImageWorkflowMode.upscale);
      }
    }
  }

  Future<void> _openBlankCanvas() async {
    final params = ref.read(generationParamsNotifierProvider);
    final canvasSize = Size(params.width.toDouble(), params.height.toDouble());

    final result = await ImageEditorScreen.show(
      context,
      initialSize: canvasSize,
      mode: ImageEditorMode.edit,
      title: context.l10n.img2img_drawSketch,
    );

    if (result != null && result.modifiedImage != null && mounted) {
      ref
          .read(imageWorkflowControllerProvider.notifier)
          .replaceSourceImage(result.modifiedImage!);
      ref.read(imageWorkflowControllerProvider.notifier).setPanelExpanded(true);
    }
  }
}

class _SourceImagePreview extends StatefulWidget {
  const _SourceImagePreview({
    required this.sourceBytes,
    required this.imageWidth,
    required this.imageHeight,
    this.maskBytes,
    this.focusedInpaintEnabled = false,
    this.focusedSelectionRect,
    this.minimumContextMegaPixels = 88.0,
  });

  final Uint8List sourceBytes;
  final Uint8List? maskBytes;
  final bool focusedInpaintEnabled;
  final Rect? focusedSelectionRect;
  final double minimumContextMegaPixels;
  final int imageWidth;
  final int imageHeight;

  @override
  State<_SourceImagePreview> createState() => _SourceImagePreviewState();
}

class _SourceImagePreviewState extends State<_SourceImagePreview> {
  final Img2ImgPreviewCache _previewCache = Img2ImgPreviewCache();
  Img2ImgPreviewDerivedData _derivedData = const Img2ImgPreviewDerivedData();

  @override
  void initState() {
    super.initState();
    _syncDerivedData();
  }

  @override
  void didUpdateWidget(covariant _SourceImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncDerivedData();
  }

  void _syncDerivedData() {
    _derivedData = _previewCache.resolve(
      sourceImage: widget.sourceBytes,
      maskImage: widget.maskBytes,
      focusedInpaintEnabled: widget.focusedInpaintEnabled,
      focusedSelectionRect: widget.focusedSelectionRect,
      minContextMegaPixels: widget.minimumContextMegaPixels,
      sourceWidth: widget.imageWidth,
      sourceHeight: widget.imageHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // 图片 letterbox 底色：跟随主题，浅色主题下不再是突兀的深灰块
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final containedSize = _resolveContainedSize(
            imageWidth: widget.imageWidth.toDouble(),
            imageHeight: widget.imageHeight.toDouble(),
            maxWidth: constraints.maxWidth,
            maxHeight: constraints.maxHeight,
          );

          return Center(
            child: SizedBox(
              width: containedSize.width,
              height: containedSize.height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DecodedMemoryImage(
                    bytes: widget.sourceBytes,
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                    maxLogicalWidth: containedSize.width,
                    maxLogicalHeight: containedSize.height,
                  ),
                  if (_derivedData.maskOverlayBytes != null)
                    IgnorePointer(
                      child: DecodedMemoryImage(
                        bytes: _derivedData.maskOverlayBytes!,
                        fit: BoxFit.fill,
                        gaplessPlayback: true,
                        maxLogicalWidth: containedSize.width,
                        maxLogicalHeight: containedSize.height,
                      ),
                    ),
                  if (_derivedData.focusedFrame?.contextCrop != null)
                    IgnorePointer(
                      child: CustomPaint(
                        painter: _FocusedCropOverlayPainter(
                          crop: _derivedData.focusedFrame!.contextCrop,
                          focusBounds: _derivedData.focusedFrame!.focusBounds,
                          imageWidth: widget.imageWidth,
                          imageHeight: widget.imageHeight,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Size _resolveContainedSize({
    required double imageWidth,
    required double imageHeight,
    required double maxWidth,
    required double maxHeight,
  }) {
    if (imageWidth <= 0 || imageHeight <= 0) {
      return Size(maxWidth, maxHeight);
    }

    final scale = math.min(maxWidth / imageWidth, maxHeight / imageHeight);
    return Size(imageWidth * scale, imageHeight * scale);
  }
}

class _FocusedCropOverlayPainter extends CustomPainter {
  const _FocusedCropOverlayPainter({
    required this.crop,
    required this.focusBounds,
    required this.imageWidth,
    required this.imageHeight,
  });

  final FocusedInpaintCrop crop;
  final FocusedInpaintCrop? focusBounds;
  final int imageWidth;
  final int imageHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final contextRect = Rect.fromLTWH(
      crop.x / imageWidth * size.width,
      crop.y / imageHeight * size.height,
      crop.width / imageWidth * size.width,
      crop.height / imageHeight * size.height,
    );
    final contextPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(contextRect, const Radius.circular(2)),
      );

    if (focusBounds != null) {
      final selectionRect = Rect.fromLTWH(
        focusBounds!.x / imageWidth * size.width,
        focusBounds!.y / imageHeight * size.height,
        focusBounds!.width / imageWidth * size.width,
        focusBounds!.height / imageHeight * size.height,
      );
      final focusPath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(selectionRect, const Radius.circular(2)),
        );
      FocusedOverlayPainter(
        contextPath: contextPath,
        focusPath: focusPath,
      ).paint(canvas, size);
      return;
    }

    FocusedOverlayPainter(contextPath: contextPath).paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _FocusedCropOverlayPainter oldDelegate) {
    return crop.x != oldDelegate.crop.x ||
        crop.y != oldDelegate.crop.y ||
        crop.width != oldDelegate.crop.width ||
        crop.height != oldDelegate.crop.height ||
        focusBounds?.x != oldDelegate.focusBounds?.x ||
        focusBounds?.y != oldDelegate.focusBounds?.y ||
        focusBounds?.width != oldDelegate.focusBounds?.width ||
        focusBounds?.height != oldDelegate.focusBounds?.height ||
        imageWidth != oldDelegate.imageWidth ||
        imageHeight != oldDelegate.imageHeight;
  }
}
