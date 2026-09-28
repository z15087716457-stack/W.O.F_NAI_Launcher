import 'generation_welcome.dart';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/shortcuts/default_shortcuts.dart';
import '../../../../core/shortcuts/shortcut_config.dart';
import '../../../../core/shortcuts/shortcut_manager.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/image/image_stream_chunk.dart';
import '../../../providers/generation/generation_params_selectors.dart';
import '../../../providers/generation/preview_selection_provider.dart';
import '../../../providers/history_click_behavior_provider.dart';
import '../../../providers/character_position_canvas_provider.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../providers/shortcuts_provider.dart';
import '../../../providers/simple_output_viewer_provider.dart';
import '../../../widgets/character/character_position_canvas.dart';
import '../../../widgets/common/selectable_image_card.dart';
import '../../../widgets/navigation/window_chrome_layout.dart';
import 'canvas/generated_image_card.dart' as canvas_card;
import 'canvas/canvas_pixel_background.dart';
import 'canvas/generation_canvas_view.dart';
import 'generation_tool_panel.dart';

class PreviewNavShortcuts extends ConsumerWidget {
  const PreviewNavShortcuts({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = ref.watch(generationPreviewFocusNodeProvider);
    final behavior = ref.watch(historyClickBehaviorNotifierProvider);
    if (behavior != HistoryClickBehavior.selectPreview) {
      return Focus(focusNode: focusNode, child: child);
    }

    final config = ref
        .watch(shortcutConfigNotifierProvider)
        .when(
          data: (value) => value,
          loading: ShortcutConfig.createDefault,
          error: (_, _) => ShortcutConfig.createDefault(),
        );
    final bindings = <ShortcutActivator, VoidCallback>{};
    if (config.enableShortcuts) {
      void register(String id, VoidCallback callback) {
        final binding = config.bindings[id];
        if (binding == null ||
            !binding.enabled ||
            binding.context != ShortcutContext.generation) {
          return;
        }
        final activator = AppShortcutManager.parseActivator(
          binding.effectiveShortcut,
        );
        if (activator != null) bindings.putIfAbsent(activator, () => callback);
      }

      register(
        ShortcutIds.generationPrevImage,
        ref.read(generationPreviewSelectionProvider.notifier).selectPrevious,
      );
      register(
        ShortcutIds.generationNextImage,
        ref.read(generationPreviewSelectionProvider.notifier).selectNext,
      );
    }

    final focusedChild = Focus(focusNode: focusNode, child: child);
    if (bindings.isEmpty) return focusedChild;
    return CallbackShortcuts(bindings: bindings, child: focusedChild);
  }
}

/// 图像预览组件
class ImagePreviewWidget extends ConsumerStatefulWidget {
  const ImagePreviewWidget({super.key});

  @override
  ConsumerState<ImagePreviewWidget> createState() => _ImagePreviewWidgetState();
}

class _ImagePreviewWidgetState extends ConsumerState<ImagePreviewWidget> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(imageGenerationNotifierProvider);
    final theme = Theme.of(context);
    final simpleViewer = ref.watch(simpleOutputViewerNotifierProvider);
    final content = _buildContent(context, ref, state, theme);

    // 使用 GestureDetector 吸收整个区域的点击事件，避免 Windows 系统提示音
    return PreviewNavShortcuts(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (ref.read(historyClickBehaviorNotifierProvider) ==
              HistoryClickBehavior.selectPreview) {
            ref.read(generationPreviewFocusNodeProvider).requestFocus();
          }
        },
        child: Container(
          color: generationCanvasBackgroundColor(theme),
          // 自由画布只留细缝，避免预览区外围形成厚重的内框。
          padding: EdgeInsets.all(simpleViewer ? 16 : 4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(child: content),
              // The free canvas draws its own strip below its floating tools.
              // Other preview modes have no edge toolbar to protect here.
              if (content is! GenerationCanvasView &&
                  WindowChromeScope.activeOf(context))
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: WindowChromeScope.heightOf(context),
                  child: const WindowDragArea(),
                ),
              if (!ref.watch(characterPositionCanvasProvider))
                const GenerationToolPanel(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ImageGenerationState state,
    ThemeData theme,
  ) {
    // 错误状态
    if (state.status == GenerationStatus.error) {
      return _buildErrorState(theme, state.errorMessage, context);
    }

    // Position editing takes precedence over either idle output viewer, including
    // a canvas containing history. Availability keeps generation/error visible.
    final showCharacterCanvas =
        ref.watch(characterPositionCanvasProvider) &&
        ref.watch(characterPositionCanvasAvailableProvider);
    if (showCharacterCanvas) {
      return const CharacterPositionCanvasView();
    }

    // 使用批次分辨率（点击生成时捕获），fallback 到全局参数
    final previewDimensions = ref.watch(
      generationParamsNotifierProvider.select(selectPreviewDimensionsViewData),
    );
    final batchWidth = state.batchWidth ?? previewDimensions.width;
    final batchHeight = state.batchHeight ?? previewDimensions.height;

    // V2 自由画布（G11 FEAT-65 重写）：接管含生成期的全部预览态——
    // 生成中渲染 inflight 占位组置顶 + 流式帧，画布不卸载不回退。
    // simpleOutputViewer=true 时回退经典输出查看器。
    final simpleViewer = ref.watch(simpleOutputViewerNotifierProvider);
    if (!simpleViewer &&
        (state.mergedPanelImages.isNotEmpty || state.isGenerating)) {
      return GenerationCanvasView(generationState: state);
    }

    // 生成中状态
    if (state.isGenerating) {
      final previewSlots = _visibleStreamPreviewSlots(state);
      // 如果有已完成图像或当前请求有多个预览槽位，显示网格视图。
      if (state.currentImages.isNotEmpty || previewSlots.length > 1) {
        return _buildGeneratingWithCompletedImages(
          context,
          ref,
          state,
          theme,
          batchWidth,
          batchHeight,
        );
      }
      // 否则只显示生成中卡片
      return _buildSingleGeneratingState(
        context,
        state,
        theme,
        batchWidth,
        batchHeight,
      );
    }

    final behavior = ref.watch(historyClickBehaviorNotifierProvider);
    if (behavior == HistoryClickBehavior.selectPreview) {
      final selectedId = ref.watch(generationPreviewSelectionProvider);
      final selectedImage = state.findImageById(selectedId);
      if (selectedImage != null) {
        return _buildImageView(context, ref, selectedImage, theme);
      }
    }

    // 有图像：根据数量决定布局（使用 displayImages）
    if (state.hasImages) {
      if (state.displayImages.length == 1) {
        // 单图：居中显示
        return _buildImageView(context, ref, state.displayImages.first, theme);
      } else {
        // 多图：自适应网格
        return _buildMultiImageGrid(context, ref, state.displayImages, theme);
      }
    }

    // 空状态
    return _buildEmptyState(theme, context);
  }

  /// 计算自适应列数（基于可用宽度和最小/最大卡片尺寸）
  int _calculateColumnCount(int imageCount, double availableWidth) {
    // 最小卡片宽度: 150px，最大卡片宽度: 280px
    const minCardWidth = 150.0;
    const maxCardWidth = 280.0;
    const spacing = 12.0;

    // 计算基于图片数量的理想列数
    int idealColumns;
    if (imageCount <= 2) {
      idealColumns = 2;
    } else if (imageCount <= 4) {
      idealColumns = 2;
    } else if (imageCount <= 6) {
      idealColumns = 3;
    } else {
      idealColumns = 4;
    }

    // 根据可用宽度调整列数，确保卡片尺寸在合理范围内
    // 计算每种列数下的卡片宽度
    for (int cols = idealColumns; cols >= 2; cols--) {
      final cardWidth =
          (availableWidth - spacing * (cols - 1) - 16) / cols; // 16 = padding
      if (cardWidth >= minCardWidth && cardWidth <= maxCardWidth) {
        return cols;
      }
    }

    // 如果空间不足，尝试更多列数
    for (int cols = idealColumns + 1; cols <= 6; cols++) {
      final cardWidth = (availableWidth - spacing * (cols - 1) - 16) / cols;
      if (cardWidth >= minCardWidth) {
        return cols;
      }
    }

    // 回退到理想列数
    return idealColumns;
  }

  List<StreamPreviewSlot> _visibleStreamPreviewSlots(
    ImageGenerationState state,
  ) {
    final completedCount = state.currentImages.length;
    return [
      for (final slot in state.streamPreviewSlots)
        if (slot.imageNumber > completedCount) slot,
    ]..sort((a, b) => a.imageNumber.compareTo(b.imageNumber));
  }

  Widget _buildGeneratingCard({
    required int imageWidth,
    required int imageHeight,
    required int currentImage,
    required int totalImages,
    required double progress,
    Uint8List? streamPreview,
    InpaintStreamPreviewPlacement? inpaintPreviewPlacement,
  }) {
    return SelectableImageCard(
      isGenerating: true,
      currentImage: currentImage,
      totalImages: totalImages,
      progress: progress,
      streamPreview: streamPreview,
      inpaintPreviewPlacement: inpaintPreviewPlacement,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      enableSelection: false,
    );
  }

  /// 构建多图网格视图
  Widget _buildMultiImageGrid(
    BuildContext context,
    WidgetRef ref,
    List<GeneratedImage> images,
    ThemeData theme,
  ) {
    // 使用第一张图像的宽高比（同一批次图像分辨率相同）
    final aspectRatio = images.isNotEmpty ? images.first.aspectRatio : 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateColumnCount(
          images.length,
          constraints.maxWidth,
        );

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) {
            final image = images[index];
            return _buildGeneratedImageCard(
              context: context,
              ref: ref,
              image: image,
              index: index,
              showIndex: true,
            );
          },
        );
      },
    );
  }

  /// 生成中 + 有已完成图像的混合视图
  Widget _buildGeneratingWithCompletedImages(
    BuildContext context,
    WidgetRef ref,
    ImageGenerationState state,
    ThemeData theme,
    int imageWidth,
    int imageHeight,
  ) {
    final completedImages = state.currentImages;
    final previewSlots = _visibleStreamPreviewSlots(state);
    final generatingCount = previewSlots.isNotEmpty ? previewSlots.length : 1;
    final totalItems = completedImages.length + generatingCount;
    final aspectRatio = imageWidth / imageHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _calculateColumnCount(
          totalItems,
          constraints.maxWidth,
        );

        return GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: aspectRatio,
          ),
          itemCount: totalItems,
          itemBuilder: (context, index) {
            // 已完成的图像
            if (index < completedImages.length) {
              final image = completedImages[index];
              return _buildGeneratedImageCard(
                context: context,
                ref: ref,
                image: image,
                index: index,
                showIndex: true,
              );
            }

            final generationIndex = index - completedImages.length;
            if (previewSlots.isNotEmpty &&
                generationIndex < previewSlots.length) {
              final slot = previewSlots[generationIndex];
              return _buildGeneratingCard(
                imageWidth: imageWidth,
                imageHeight: imageHeight,
                currentImage: slot.imageNumber,
                totalImages: slot.totalImages,
                progress: slot.progress,
                streamPreview: slot.previewBytes,
                inpaintPreviewPlacement: slot.inpaintPreviewPlacement,
              );
            }

            return _buildGeneratingCard(
              imageWidth: imageWidth,
              imageHeight: imageHeight,
              currentImage: state.currentImage,
              totalImages: state.totalImages,
              progress: state.progress,
              streamPreview: state.streamPreview,
              inpaintPreviewPlacement: state.inpaintPreviewPlacement,
            );
          },
        );
      },
    );
  }

  /// 生成中的居中显示（无已完成图像时）
  Widget _buildSingleGeneratingState(
    BuildContext context,
    ImageGenerationState state,
    ThemeData theme,
    int imageWidth,
    int imageHeight,
  ) {
    final aspectRatio = imageWidth / imageHeight;
    final previewSlots = _visibleStreamPreviewSlots(state);
    final slot = previewSlots.isNotEmpty ? previewSlots.first : null;
    return _buildSingleAspectRatioCard(
      aspectRatio: aspectRatio,
      child: _buildGeneratingCard(
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        currentImage: slot?.imageNumber ?? state.currentImage,
        totalImages: slot?.totalImages ?? state.totalImages,
        progress: slot?.progress ?? state.progress,
        streamPreview: slot?.previewBytes ?? state.streamPreview,
        inpaintPreviewPlacement:
            slot?.inpaintPreviewPlacement ?? state.inpaintPreviewPlacement,
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, BuildContext context) {
    return const GenerationWelcome();
  }

  Widget _buildErrorState(
    ThemeData theme,
    String? message,
    BuildContext context,
  ) {
    // 解析错误代码和详情
    final (errorTitle, errorHint) = _parseApiError(message, context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        Text(
          errorTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        if (errorHint != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              errorHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  /// 解析 API 错误代码，返回 (标题, 提示)
  (String, String?) _parseApiError(String? message, BuildContext context) {
    if (message == null || message.isEmpty) {
      return (context.l10n.generation_generationFailed, null);
    }

    // 取消操作
    if (message == 'Cancelled') {
      return (context.l10n.generation_cancelGeneration, null);
    }

    // 解析错误代码格式: "ERROR_CODE|详情"
    final parts = message.split('|');
    final errorCode = parts[0];
    final details = parts.length > 1 ? parts.sublist(1).join('|') : null;

    // 固定文案后拼接服务端真实详情，避免所有错误只显示同一句兜底提示
    String? withDetails(String? localizedHint) {
      if (details == null || details.trim().isEmpty) return localizedHint;
      if (localizedHint == null) return details;
      return '$localizedHint\n$details';
    }

    switch (errorCode) {
      case 'API_ERROR_429':
        return (
          context.l10n.api_error_429,
          withDetails(context.l10n.api_error_429_hint),
        );
      case 'API_ERROR_401':
        return (
          context.l10n.api_error_401,
          withDetails(context.l10n.api_error_401_hint),
        );
      case 'API_ERROR_402':
        return (
          context.l10n.api_error_402,
          withDetails(context.l10n.api_error_402_hint),
        );
      case 'API_ERROR_400':
        return ('${context.l10n.common_error} (400)', details);
      case 'API_ERROR_500':
        return (
          context.l10n.api_error_500,
          withDetails(context.l10n.api_error_500_hint),
        );
      case 'API_ERROR_503':
        return (
          context.l10n.api_error_503,
          withDetails(context.l10n.api_error_503_hint),
        );
      case 'API_ERROR_TIMEOUT':
        return (
          context.l10n.api_error_timeout,
          withDetails(context.l10n.api_error_timeout_hint),
        );
      case 'API_ERROR_NETWORK':
        return (
          context.l10n.api_error_network,
          withDetails(context.l10n.api_error_network_hint),
        );
      default:
        // 未知错误或其他 HTTP 错误
        if (errorCode.startsWith('API_ERROR_HTTP_')) {
          final code = errorCode.replaceFirst('API_ERROR_HTTP_', '');
          return ('${context.l10n.common_error} (HTTP $code)', details);
        }
        if (errorCode.startsWith('API_ERROR_')) {
          // 已编码但无专属文案的错误：显示真实状态码+详情而非整段原始串
          final code = errorCode.replaceFirst('API_ERROR_', '');
          return ('${context.l10n.common_error} ($code)', details ?? message);
        }
        return (context.l10n.generation_generationFailed, message);
    }
  }

  Widget _buildImageView(
    BuildContext context,
    WidgetRef ref,
    GeneratedImage image,
    ThemeData theme,
  ) {
    return _buildSingleAspectRatioCard(
      aspectRatio: image.aspectRatio,
      child: _buildGeneratedImageCard(
        context: context,
        ref: ref,
        image: image,
        showIndex: false,
      ),
    );
  }

  Widget _buildGeneratedImageCard({
    required BuildContext context,
    required WidgetRef ref,
    required GeneratedImage image,
    required bool showIndex,
    int? index,
  }) {
    return canvas_card.buildGeneratedImageCard(
      context: context,
      ref: ref,
      image: image,
      showIndex: showIndex,
      index: index,
    );
  }

  Widget _buildSingleAspectRatioCard({
    required double aspectRatio,
    required Widget child,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardSize = _fitAspectRatio(
          aspectRatio: aspectRatio,
          maxSize: Size(constraints.maxWidth, constraints.maxHeight),
        );

        return Center(
          child: SizedBox(
            width: cardSize.width,
            height: cardSize.height,
            child: child,
          ),
        );
      },
    );
  }

  Size _fitAspectRatio({required double aspectRatio, required Size maxSize}) {
    final safeAspectRatio = aspectRatio.isFinite && aspectRatio > 0
        ? aspectRatio
        : 1.0;
    final maxWidth = maxSize.width.isFinite ? max(0.0, maxSize.width) : 500.0;
    final maxHeight = maxSize.height.isFinite
        ? max(0.0, maxSize.height)
        : 650.0;

    var width = maxWidth;
    var height = width / safeAspectRatio;
    if (height > maxHeight) {
      height = maxHeight;
      width = height * safeAspectRatio;
    }

    return Size(
      width.clamp(0.0, maxWidth).toDouble(),
      height.clamp(0.0, maxHeight).toDouble(),
    );
  }
}
