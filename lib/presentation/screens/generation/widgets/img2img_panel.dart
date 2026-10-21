import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../providers/generation/generation_params_selectors.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../services/image_workflow_launcher.dart';
import '../../../providers/generation/image_workflow_controller.dart';
import '../../../utils/dropped_file_reader.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/collapsible_image_panel.dart';
import '../../../widgets/common/uiux_prototype_icon.dart';
import '../../../themes/studio_typography.dart';
import '../../../widgets/common/decoded_memory_image.dart';
import '../../../widgets/common/image_picker_card/image_picker_card.dart';
import '../../../widgets/common/themed_divider.dart';
import '../../../widgets/image_editor/image_editor_screen.dart';
import '../../../ui/refs/refs_contract.dart';
import '../../../wiring/refs_generation_target.dart';
import '../../../wiring/refs_picker_wiring.dart';
import '../../../wiring/refs_platform.dart';
import 'local_upscale_panel.dart';
import '../../../providers/generation/cloud_upscale_provider.dart';
import 'img2img_preview_cache.dart';

/// Img2Img 面板组件
class Img2ImgPanel extends ConsumerStatefulWidget {
  const Img2ImgPanel({super.key, this.toolOnly = false});
  final bool toolOnly;

  @override
  ConsumerState<Img2ImgPanel> createState() => _Img2ImgPanelState();
}

class _Img2ImgPanelState extends ConsumerState<Img2ImgPanel> {
  bool _isFileDraggingOver = false;
  int _headerIconTrigger = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _buildPanel(
        context,
        compactHeader:
            constraints.maxWidth <
            (ReferenceModuleScope.of(context) ? 420 : 360),
      ),
    );
  }

  Widget _buildPanel(BuildContext context, {required bool compactHeader}) {
    final theme = Theme.of(context);
    final params = ref.watch(
      generationParamsNotifierProvider.select(selectImg2ImgPanelViewData),
    );
    final workflow = ref.watch(draftImageWorkflowProvider);
    if (widget.toolOnly) return _buildUpscalePanel(theme, workflow);
    final embedded = ReferenceModuleScope.of(context);
    final hasSourceImage = params.sourceImage != null;
    final showBackground = hasSourceImage && !workflow.isPanelExpanded;

    return CollapsibleImagePanel(
      frosted: true,
      title: context.l10n.img2img_title,
      subtitle: context.l10n.img2img_subtitle,
      icon: StudioIcons.imageToImage,
      iconAsset: 'assets/icons/nai-icon-img2img.svg',
      isExpanded: workflow.isPanelExpanded,
      iconTrigger: _headerIconTrigger,
      onToggle: () {
        setState(() => _headerIconTrigger++);
        ref
            .read(imageWorkflowControllerProvider.notifier)
            .setPanelExpanded(!workflow.isPanelExpanded);
      },
      hasData: hasSourceImage,
      headerActions: hasSourceImage
          ? _buildLoadedHeaderActions(
              params: params,
              showBackground: showBackground,
              compactHeader: compactHeader,
            )
          : [
              _buildImportDropTarget(
                child: TextButton.icon(
                  onPressed: _pickImage,
                  icon: embedded
                      ? UiuxPrototypeIcon(
                          Icons.upload_outlined,
                          size: 15,
                          color: theme.colorScheme.primary,
                          source: UiuxPrototypeIconSource.generation,
                        )
                      : SvgPicture.asset(
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
                        : embedded
                        ? context.l10n.generation_referenceUpload
                        : context.l10n.img2img_uploadImage,
                    style: TextStyle(
                      fontFamily: embedded ? StudioTypography.cjk : null,
                      fontSize: embedded ? 13 : 12,
                      fontWeight: embedded ? FontWeight.w500 : null,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: EdgeInsets.symmetric(
                      horizontal: embedded ? 10 : 8,
                    ),
                    minimumSize: Size(0, embedded ? 28 : 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
      backgroundImage: hasSourceImage
          ? DecodedMemoryImage(
              bytes: params.sourceImage!,
              fit: BoxFit.cover,
              decodeForCover: true,
              filterQuality: FilterQuality.medium,
            )
          : null,
      badge: compactHeader
          ? null
          : Container(
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
  /// 微倾斜缩略图 + 放入画布 / 换图 / 清除。
  List<Widget> _buildLoadedHeaderActions({
    required Img2ImgPanelViewData params,
    required bool showBackground,
    required bool compactHeader,
  }) {
    final sourceImage = params.sourceImage!;
    final foreground = showBackground ? Colors.white : null;
    final isGenerating = ref.watch(
      imageGenerationNotifierProvider.select((state) => state.isGenerating),
    );

    return [
      if (!compactHeader) ...[
        _buildTiltedThumbnail(sourceImage),
        const SizedBox(width: 4),
      ],
      PanelHeaderIconButton(
        key: const Key('img2img-action-place-on-canvas'),
        iconAsset: 'assets/icons/nai-icon-send-tools.svg',
        tooltip: context.l10n.img2img_placeOnCanvas,
        color: foreground,
        onPressed: isGenerating ? null : _placeSourceOnCanvas,
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

  void _placeSourceOnCanvas() {
    final source = ref.read(generationParamsNotifierProvider).sourceImage;
    if (source == null) return;
    final generation = ref.read(imageGenerationNotifierProvider);
    if (generation.isGenerating) return;
    if (!ImageWorkflowLauncher.placeOnCanvas(ref, source)) {
      AppToast.error(context, context.l10n.img2img_decodeSourceFailed);
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
                icon: StudioIcons.localGallery,
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

  /// 从精准参考库选一张图作为图生图底图
  Future<void> _importSourceFromPreciseRefLibrary() async {
    final selection = await RefsPickerWiring.show(
      context,
      kind: RefsKind.precise,
      single: true,
    );
    if (selection == null || selection.keys.isEmpty || !mounted) return;
    final platform = ref.read(refsPlatformProvider);
    try {
      await ref
          .read(refsGenerationTargetProvider)
          .sendImg2Img(selection.keys.first, alive: () => mounted);
    } catch (error) {
      if (mounted) platform.error(context, error);
    }
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

  Widget _buildUpscalePanel(ThemeData theme, ImageWorkflowState workflow) =>
      LocalUpscalePanel(
        onCloudStart: _runUpscale,
        cloudRunning: ref.watch(cloudUpscaleTaskProvider).running,
        framed: !widget.toolOnly,
      );

  Future<void> _runUpscale() async {
    await ref.read(cloudUpscaleTaskProvider.notifier).start();
    if (!mounted) return;
    final result = ref.read(cloudUpscaleTaskProvider);
    if (result.error != null) {
      AppToast.error(context, result.error!);
    } else if (result.completed) {
      AppToast.success(context, context.l10n.img2img_novelAiUpscaleComplete);
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
  });

  final Uint8List sourceBytes;
  final Uint8List? maskBytes;
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
    _derivedData = _previewCache.resolve(maskImage: widget.maskBytes);
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
