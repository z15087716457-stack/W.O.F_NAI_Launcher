import 'package:nai_launcher/presentation/widgets/common/studio_icon.dart';
import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../../../core/enums/precise_ref_type.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/file_explorer_utils.dart';
import '../../../../core/utils/image_save_utils.dart';
import '../../../../core/utils/image_share_sanitizer.dart';
import '../../../../core/utils/vibe_file_parser.dart';
import '../../../../core/utils/zip_utils.dart';
import '../../../../data/services/alias_resolver_service.dart';
import '../../../providers/layout_state_provider.dart';

import '../../../../data/services/image_metadata_service.dart';
import '../../../../data/repositories/gallery_folder_repository.dart';
import '../../../providers/canvas_settings_provider.dart';
import 'canvas/canvas_feed_layout.dart';
import 'history_batch.dart';
import 'image_operation_badge.dart';
import '../../../providers/generation/generation_params_selectors.dart';
import '../../../providers/generation/preview_selection_provider.dart';
import '../../../providers/history_click_behavior_provider.dart';
import '../../../providers/image_generation_provider.dart';
import '../../../providers/local_gallery_provider.dart';
import '../../../providers/share_image_settings_provider.dart';
import '../../../services/image_workflow_launcher.dart';
import '../../../widgets/common/app_toast.dart';
import '../../../widgets/common/image_detail/file_image_detail_data.dart';
import '../../../widgets/common/image_detail/image_detail_data.dart';
import '../../../widgets/common/image_detail/image_detail_viewer.dart';
import '../../../widgets/common/draggable_memory_image.dart';
import '../../../widgets/common/selectable_image_card.dart';
import '../../../widgets/generation/auto_save_toggle_chip.dart';
import '../../../widgets/image_editor/image_editor_screen.dart';
import '../../../utils/image_detail_opener.dart';
import '../../../utils/krita_send_helper.dart';
import '../../../utils/precise_ref_library_import_helper.dart';
import '../../../widgets/common/themed_confirm_dialog.dart';
import '../services/generation_save_service.dart';
import '../../../widgets/common/themed_divider.dart';
import '../../prompt_block_library/widgets/prompt_block_edit_dialog.dart';

double resolveHistoryPreviewAspectRatio(
  double aspectRatio, {
  double fallback = 1.0,
}) {
  if (!aspectRatio.isFinite || aspectRatio <= 0) {
    return fallback;
  }
  return aspectRatio;
}

double resolveCurrentHistoryPreviewAspectRatio(
  double batchAspectRatio, {
  double? completedImageAspectRatio,
}) {
  return resolveHistoryPreviewAspectRatio(
    completedImageAspectRatio ?? batchAspectRatio,
    fallback: resolveHistoryPreviewAspectRatio(batchAspectRatio),
  );
}

class _HistoryRowDescriptor {
  const _HistoryRowDescriptor({required this.batch, required this.extent});

  final HistoryBatch batch;
  final double extent;
}

/// 历史面板组件
class HistoryPanel extends ConsumerStatefulWidget {
  const HistoryPanel({super.key});

  @override
  ConsumerState<HistoryPanel> createState() => _HistoryPanelState();
}

class _HistoryPanelState extends ConsumerState<HistoryPanel> {
  final Set<String> _selectedIds = {};
  final Set<String> _selectedBatchKeys = {};
  List<HistoryBatch> _batches = const [];
  final ShareImagePreparationService _sharePreparationService =
      ShareImagePreparationService.instance;
  Timer? _historyScrollIdleTimer;
  Timer? _historyPreheatTimer;
  Timer? _hoverPreheatTimer;
  bool _isHistoryScrolling = false;
  String? _lastSharePreparationMaintenanceKey;
  Uint8List? _lastStreamPreviewBytes;
  int? _lastStreamPreviewRunId;
  final Map<String, Uint8List> _completionPreviewPlaceholders = {};
  final Map<String, bool> _favoriteStates = {};
  final Map<String, String?> _favoriteStatePaths = {};
  final Set<String> _favoriteStatusLoadingIds = {};
  final Set<String> _favoriteToggleLoadingIds = {};
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _imageKeys = {};
  List<_HistoryRowDescriptor> _rowDescriptors = const [];
  ProviderSubscription<String?>? _selectionSubscription;
  int _scrollRequestEpoch = 0;

  /// 官网底栏「lock history scrolling」：开启后点选不再自动滚动历史列表
  bool _historyScrollLocked = false;

  /// 显式多选模式（自研）：头部多选钮开启后，即使清空选中也不自动
  /// 退出，需点关闭钮或再点多选钮退出。Ctrl+点击隐式多选仍走
  /// _selectedIds 自动显隐。
  bool _multiSelectMode = false;

  @override
  void initState() {
    super.initState();
    _sharePreparationService.addListener(_handleSharePreparationChanged);
    _selectionSubscription = ref.listenManual(
      generationPreviewSelectionProvider,
      (_, selectedId) => _scheduleScrollToSelection(selectedId),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _historyScrollIdleTimer?.cancel();
    _historyPreheatTimer?.cancel();
    _hoverPreheatTimer?.cancel();
    _selectionSubscription?.close();
    _scrollController.dispose();
    _sharePreparationService.removeListener(_handleSharePreparationChanged);
    super.dispose();
  }

  void _handleSharePreparationChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(imageGenerationNotifierProvider);
    _batches = buildHistoryBatches(state);
    final validKeys = _batches.map((batch) => batch.key).toSet();
    _selectedBatchKeys.removeWhere((key) => !validKeys.contains(key));
    _selectedIds.retainAll(
      state.selectableMergedImages.map((image) => image.id),
    );
    for (final batch in _batches) {
      if (_selectedBatchKeys.contains(batch.key)) {
        _selectedIds.addAll(batch.selectableImages.map((image) => image.id));
      }
    }
    final hasContent =
        state.history.isNotEmpty || state.currentImages.isNotEmpty;
    final stripMetadata = ref.watch(
      shareImageSettingsProvider.select(
        (settings) => settings.effectiveStripMetadataForCopyAndDrag,
      ),
    );
    final theme = Theme.of(context);
    final clickBehavior = ref.watch(historyClickBehaviorNotifierProvider);
    final selectedPreviewId =
        clickBehavior == HistoryClickBehavior.selectPreview
        ? ref.watch(generationPreviewSelectionProvider)
        : null;
    _syncCompletionPreviewPlaceholder(state);
    _scheduleSharePreparationMaintenance(state, stripMetadata);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题栏
        Padding(
          padding: const EdgeInsets.only(
            left: 8,
            right: 4,
            top: 12,
            bottom: 12,
          ),
          child: Row(
            children: [
              // 折叠按钮
              _buildCollapseButton(theme),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.l10n.generation_historyRecord,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // 官网顶栏 `History >` + Pins 计数（有钉住才显）
              Consumer(
                builder: (context, ref, _) {
                  final count = ref.watch(canvasPinnedNotifierProvider).length;
                  if (count == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: InkWell(
                      onTap: () => ref
                          .read(canvasPinboardFocusRequestProvider.notifier)
                          .state++,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          context.l10n.generation_canvasPinnedCount(count),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // 多选入口（自研，官网无）：点击进显式多选态；再点退出并清空。
              _BottomToolButton(
                icon: _multiSelectMode || _selectedIds.isNotEmpty
                    ? Icons.library_add_check
                    : Icons.library_add_check_outlined,
                tooltip: _multiSelectMode || _selectedIds.isNotEmpty
                    ? context.l10n.generation_deselectAll
                    : context.l10n.generation_selectMultiple,
                color: _multiSelectMode ? theme.colorScheme.primary : null,
                onPressed: hasContent
                    ? () => setState(() {
                        _multiSelectMode = !_multiSelectMode;
                        if (!_multiSelectMode) {
                          _selectedIds.clear();
                          _selectedBatchKeys.clear();
                        }
                      })
                    : null,
              ),
            ],
          ),
        ),
        const ThemedDivider(height: 1),

        // 历史列表
        Expanded(
          child: state.history.isEmpty && !_hasCurrentGeneration(state)
              ? _buildEmptyState(theme, context)
              : _buildHistoryGrid(
                  state,
                  theme,
                  ref,
                  stripMetadata: stripMetadata,
                  clickBehavior: clickBehavior,
                  selectedPreviewId: selectedPreviewId,
                ),
        ),

        // 官网底栏（常驻）：AutoSave | 锁滚动 | 全部下载 | 删除
        // 有选中或显式多选态时叠多选操作条（打包/保存/关闭）
        _buildBottomToolbar(context, state, theme),
        if (_selectedIds.isNotEmpty || _multiSelectMode)
          _buildBottomActions(context, state, theme),
      ],
    );
  }

  /// 官网底栏三件（38×28 图标钮）+ 本地 AutoSave 开关挪到底部。
  /// lock history scrolling | download all images | delete image(s)
  Widget _buildBottomToolbar(
    BuildContext context,
    ImageGenerationState state,
    ThemeData theme,
  ) {
    final hasContent =
        state.history.isNotEmpty || state.currentImages.isNotEmpty;
    final allImages = _getAllSelectableImages(state);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          const AutoSaveToggleIcon(),
          const Spacer(),
          _BottomToolButton(
            icon: _historyScrollLocked ? Icons.lock : Icons.lock_open,
            tooltip: _historyScrollLocked
                ? context.l10n.generation_unlockHistoryScroll
                : context.l10n.generation_lockHistoryScroll,
            color: _historyScrollLocked ? theme.colorScheme.primary : null,
            onPressed: () =>
                setState(() => _historyScrollLocked = !_historyScrollLocked),
          ),
          _BottomToolButton(
            icon: Icons.save_alt,
            tooltip: context.l10n.generation_downloadAllImages,
            onPressed: hasContent && allImages.isNotEmpty
                ? () => unawaited(
                    _saveImageIds(
                      context,
                      state,
                      allImages.map((img) => img.id).toSet(),
                    ),
                  )
                : null,
          ),
          _BottomToolButton(
            icon: Icons.delete_outline,
            tooltip: _selectedIds.isNotEmpty
                ? context.l10n.generation_deleteSelectedImages(
                    _selectedIds.length,
                  )
                : context.l10n.generation_clearHistory,
            color: theme.colorScheme.error,
            onPressed: hasContent
                ? () => _showDeleteDialog(context, ref)
                : null,
          ),
        ],
      ),
    );
  }

  /// 删除：有选中删选中（内存移除，磁盘文件保留）；无选中=清空历史
  void _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final hasSelection = _selectedIds.isNotEmpty;
    final confirmed = await ThemedConfirmDialog.show(
      context: context,
      title: hasSelection
          ? context.l10n.generation_deleteSelectedImagesTitle
          : context.l10n.generation_clearHistory,
      content: hasSelection
          ? context.l10n.generation_deleteSelectedImagesConfirm(
              _selectedIds.length,
            )
          : context.l10n.generation_clearHistoryConfirm,
      confirmText: context.l10n.common_clear,
      cancelText: context.l10n.common_cancel,
      type: ThemedConfirmDialogType.danger,
      icon: Icons.delete_sweep_outlined,
    );

    if (confirmed) {
      if (hasSelection) {
        ref
            .read(imageGenerationNotifierProvider.notifier)
            .removeImages(_selectedIds);
      } else {
        ref.read(imageGenerationNotifierProvider.notifier).clearHistory();
      }
      setState(() {
        _selectedIds.clear();
        _selectedBatchKeys.clear();
      });
    }
  }

  Widget _buildCollapseButton(ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ref
            .read(layoutStateNotifierProvider.notifier)
            .setRightPanelExpanded(false),
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: StudioIcon(
            Icons.chevron_right,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StudioIcon(
            Icons.history,
            size: 48,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.generation_noHistory,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取所有可选择的图像（当前批次已完成 + 去重后的历史）
  List<GeneratedImage> _getAllSelectableImages(ImageGenerationState state) {
    return state.selectableMergedImages;
  }

  /// 判断是否有当前正在生成的图像
  bool _hasCurrentGeneration(ImageGenerationState state) {
    return state.isGenerating || state.currentImages.isNotEmpty;
  }

  void _scheduleSharePreparationMaintenance(
    ImageGenerationState state,
    bool stripMetadata,
  ) {
    final images = _getAllSelectableImages(state);
    final imageIds = images.map((image) => image.id).toSet();
    final maintenanceKey =
        '${stripMetadata ? 'strip' : 'raw'}:'
        '${imageIds.join('|')}';

    if (_lastSharePreparationMaintenanceKey == maintenanceKey) {
      return;
    }
    _lastSharePreparationMaintenanceKey = maintenanceKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_sharePreparationService.retainHistoryImageIds(imageIds));
      if (!_isHistoryScrolling) {
        _scheduleHistoryPreheat(images, stripMetadata);
      }
    });
  }

  void _setHistoryScrolling(bool value) {
    if (_isHistoryScrolling == value) {
      return;
    }

    setState(() {
      _isHistoryScrolling = value;
    });
  }

  bool _handleHistoryScrollNotification(
    ScrollNotification notification,
    bool stripMetadata,
  ) {
    if (notification is ScrollStartNotification ||
        notification is ScrollUpdateNotification ||
        notification is OverscrollNotification) {
      _historyScrollIdleTimer?.cancel();
      _historyPreheatTimer?.cancel();
      _hoverPreheatTimer?.cancel();
      _setHistoryScrolling(true);
      return false;
    }

    if (notification is ScrollEndNotification ||
        (notification is UserScrollNotification &&
            notification.direction == ScrollDirection.idle)) {
      _historyScrollIdleTimer?.cancel();
      _historyScrollIdleTimer = Timer(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        _setHistoryScrolling(false);
        final currentState = ref.read(imageGenerationNotifierProvider);
        final currentStripMetadata = ref
            .read(shareImageSettingsProvider)
            .effectiveStripMetadataForCopyAndDrag;
        _scheduleHistoryPreheat(
          _getAllSelectableImages(currentState),
          currentStripMetadata,
          delay: const Duration(milliseconds: 150),
        );
      });
    }

    return false;
  }

  void _scheduleHistoryPreheat(
    List<GeneratedImage> images,
    bool stripMetadata, {
    Duration delay = const Duration(milliseconds: 600),
  }) {
    _historyPreheatTimer?.cancel();
    final draggableImages = images.where((image) => image.canDrag).toList();
    if (draggableImages.isEmpty) {
      return;
    }

    _historyPreheatTimer = Timer(delay, () {
      if (!mounted || _isHistoryScrolling) {
        return;
      }

      for (final image in draggableImages) {
        _sharePreparationService.enqueue(
          imageId: image.id,
          imageBytes: image.bytes,
          fileName: 'history_${image.id}.png',
          sourceFilePath: image.filePath,
          stripMetadata: stripMetadata,
        );
      }
    });
  }

  void _scheduleHoverPreheat(GeneratedImage image, bool stripMetadata) {
    if (!image.canDrag) {
      return;
    }

    if (_isHistoryScrolling) {
      return;
    }

    _hoverPreheatTimer?.cancel();
    _hoverPreheatTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted || _isHistoryScrolling) {
        return;
      }
      _sharePreparationService.enqueue(
        imageId: image.id,
        imageBytes: image.bytes,
        fileName: 'history_${image.id}.png',
        sourceFilePath: image.filePath,
        stripMetadata: stripMetadata,
      );
    });
  }

  String _dragDisabledReason(ShareImagePreparationSnapshot snapshot) {
    return switch (snapshot.status) {
      ShareImagePreparationStatus.failed =>
        context.l10n.history_dragFilePreparationFailed,
      ShareImagePreparationStatus.preparing =>
        context.l10n.history_dragFilePreparing,
      ShareImagePreparationStatus.notQueued =>
        context.l10n.history_dragFileNotReady,
      ShareImagePreparationStatus.ready => '',
    };
  }

  void _syncCompletionPreviewPlaceholder(ImageGenerationState state) {
    if (_lastStreamPreviewRunId != state.generationRunId) {
      _lastStreamPreviewRunId = state.generationRunId;
      _lastStreamPreviewBytes = null;
    }
    final first = state.currentImages
        .where((image) => image.batchIndex == 0 || image.batchIndex == null)
        .firstOrNull;
    final preview =
        state.streamPreviewSlots
            .where((slot) => slot.imageNumber == 1)
            .firstOrNull
            ?.previewBytes ??
        (state.currentImage <= 1 ? state.streamPreview : null);
    if (first == null && preview != null && preview.isNotEmpty) {
      _lastStreamPreviewBytes = preview;
    }
    if (_lastStreamPreviewBytes != null && first != null) {
      _completionPreviewPlaceholders.putIfAbsent(
        first.id,
        () => _lastStreamPreviewBytes!,
      );
      _lastStreamPreviewBytes = null;
    }

    final retainedIds = <String>{
      for (final image in state.currentImages) image.id,
      for (final image in state.history) image.id,
    };
    _completionPreviewPlaceholders.removeWhere(
      (imageId, _) => !retainedIds.contains(imageId),
    );
  }

  void _clearCompletionPreviewPlaceholder(String imageId) {
    if (_completionPreviewPlaceholders.remove(imageId) == null || !mounted) {
      return;
    }
    setState(() {});
  }

  Widget _buildHistoryGrid(
    ImageGenerationState state,
    ThemeData theme,
    WidgetRef ref, {
    required bool stripMetadata,
    required HistoryClickBehavior clickBehavior,
    required String? selectedPreviewId,
  }) {
    final previewDimensions = ref.watch(
      generationParamsNotifierProvider.select(selectPreviewDimensionsViewData),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final extent =
            (constraints.maxWidth - 16).clamp(1.0, double.infinity) + 8;
        _rowDescriptors = [
          for (final batch in _batches)
            _HistoryRowDescriptor(batch: batch, extent: extent),
        ];
        final retainedKeys = _batches.map((batch) => batch.key).toSet();
        _imageKeys.removeWhere((key, _) => !retainedKeys.contains(key));
        return NotificationListener<ScrollNotification>(
          onNotification: (notification) =>
              _handleHistoryScrollNotification(notification, stripMetadata),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: _batches.length,
            itemExtent: extent,
            itemBuilder: (context, index) {
              final batch = _batches[index];
              return KeyedSubtree(
                key: _imageKeyFor(batch.key),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _buildHistoryBatchItem(
                      context,
                      batch,
                      state,
                      state.batchWidth ?? previewDimensions.width,
                      state.batchHeight ?? previewDimensions.height,
                      stripMetadata: stripMetadata,
                      clickBehavior: clickBehavior,
                      selectedPreviewId: selectedPreviewId,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPreparedHistoryItem({
    required BuildContext context,
    required GeneratedImage image,
    required bool stripMetadata,
    required Widget Function(bool dragPreparationReady) childBuilder,
  }) {
    if (!image.canDrag) {
      return childBuilder(true);
    }

    final snapshot = _sharePreparationService.snapshotFor(
      image.id,
      stripMetadata: stripMetadata,
    );
    final preparedFile = snapshot.isReady ? snapshot.file : null;
    final dragPreparationReady = preparedFile != null;

    return MouseRegion(
      onEnter: (_) => _scheduleHoverPreheat(image, stripMetadata),
      onExit: (_) => _hoverPreheatTimer?.cancel(),
      child: DraggableMemoryImage(
        imageId: image.id,
        imageBytes: image.bytes,
        feedbackPixelWidth: image.width,
        feedbackPixelHeight: image.height,
        feedbackFormat: 'PNG',
        fileName: 'history_${image.id}.png',
        sourceFilePath: image.filePath,
        requirePreparedDragFile: true,
        preparedDragFile: preparedFile,
        preparedDragStripMetadata: preparedFile == null ? null : stripMetadata,
        disabledReason: preparedFile == null
            ? _dragDisabledReason(snapshot)
            : null,
        child: childBuilder(dragPreparationReady),
      ),
    );
  }

  /// 构建当前生成区块的单个项目
  Widget _buildHistoryBatchItem(
    BuildContext context,
    HistoryBatch batch,
    ImageGenerationState state,
    int imageWidth,
    int imageHeight, {
    required bool stripMetadata,
    required HistoryClickBehavior clickBehavior,
    required String? selectedPreviewId,
  }) {
    final image = batch.cover;
    if (image != null) {
      final imageBytes = image.bytes;
      final isFavorite = _favoriteStateFor(image);
      final isFailedSnapshot = image.isFailedStreamSnapshot;
      return _buildPreparedHistoryItem(
        context: context,
        image: image,
        stripMetadata: stripMetadata,
        childBuilder: (dragPreparationReady) => SelectableImageCard(
          key: ValueKey(image.id),
          imageBytes: imageBytes,
          sourceFilePath: image.filePath,
          index: state.mergedPanelImages.indexOf(image),
          showIndex: false,
          historyThumb: true,
          batchBadgeCount: batch.count,
          sourceBadge: image.operation == null || isFailedSnapshot
              ? null
              : ImageOperationBadge(operation: image.operation!),
          isSelected: _isBatchSelected(batch),
          isPreviewActive: batch.contains(selectedPreviewId),
          imageIdentity: image.id,
          allowRepeatedModifierTaps: true,
          isFavorite: isFavorite,
          dragPreparationReady: dragPreparationReady,
          completionPlaceholderBytes: _completionPreviewPlaceholders[image.id],
          onCompletionPlaceholderSettled: () =>
              _clearCompletionPreviewPlaceholder(image.id),
          enableSelection: batch.selectableImages.isNotEmpty,
          enableSaveAction: image.canSave,
          enableCopyAction: image.canSave,
          statusBadgeLabel: isFailedSnapshot
              ? context.l10n.generation_failedStreamSnapshot
              : null,
          statusBadgeTooltip: isFailedSnapshot
              ? context.l10n.generation_failedStreamSnapshotHint
              : null,
          onFavoriteToggle: image.canFavorite
              ? () => _toggleHistoryFavorite(context, image)
              : null,
          onSelectionChanged: (selected) => _setBatchSelected(batch, selected),
          onTap: () =>
              _handleImageTap(context, image, clickBehavior, batch: batch),
          onDoubleTap: clickBehavior == HistoryClickBehavior.selectPreview
              ? () => _showLinkedDetail(context, image)
              : null,
          onLongPress: clickBehavior == HistoryClickBehavior.selectPreview
              ? () => _showLinkedDetail(context, image)
              : null,
          onFullscreen: () =>
              _showDetailForBehavior(context, image, clickBehavior),
          enableContextMenu: true,
          enableHoverScale: true,
          hoverEffectsEnabled: !_isHistoryScrolling,
          shareWarmupEnabled: false,
          onImageToImage: image.canUseAsGenerationInput
              ? () => _sendHistoryImageToImageToImage(context, image)
              : null,
          onVibeTransfer: image.canUseAsGenerationInput
              ? () => unawaited(_sendHistoryImageToVibeTransfer(context, image))
              : null,
          onSaveToPreciseRefLibrary: image.canUseAsGenerationInput
              ? () => unawaited(
                  saveBytesToPreciseRefLibrary(ref, context, image.bytes),
                )
              : null,
          onPreciseReference: image.canUseAsGenerationInput
              ? () => unawaited(
                  _sendHistoryImageToPreciseReference(context, image),
                )
              : null,
          onEditImage: image.canUseAsGenerationInput
              ? () => ImageWorkflowLauncher.openEditor(
                  context,
                  ref,
                  imageBytes,
                  mode: ImageEditorMode.edit,
                )
              : null,
          onInpaint: image.canUseAsGenerationInput
              ? () =>
                    ImageWorkflowLauncher.openInpaint(context, ref, imageBytes)
              : null,
          onGenerateVariations: image.canUseAsGenerationInput
              ? () => ImageWorkflowLauncher.generateVariations(
                  context,
                  ref,
                  imageBytes,
                )
              : null,
          onDirectorTools: image.canUseAsGenerationInput
              ? () => ImageWorkflowLauncher.openDirectorTools(
                  context,
                  ref,
                  imageBytes,
                )
              : null,
          onEnhance: image.canUseAsGenerationInput
              ? () => ImageWorkflowLauncher.openEnhance(ref, imageBytes)
              : null,
          onUpscale: image.canUseAsGenerationInput
              ? () => ImageWorkflowLauncher.openUpscale(ref, imageBytes)
              : null,
          onSendToKrita: image.canUseAsGenerationInput
              ? () => KritaSendHelper.sendImageBytes(
                  context,
                  ref,
                  image.bytes,
                  name: 'history_${image.id}.png',
                )
              : null,
          onOpenInExplorer: image.canSave
              ? () => _openImageInExplorer(context, image)
              : null,
          onSaveToLibrary: image.canUseAsGenerationInput
              ? (bytes, _) => _showSaveToLibraryDialog(context, bytes)
              : null,
        ),
      );
    }

    final slot = state.streamPreviewSlots
        .where((slot) => slot.imageNumber == 1)
        .firstOrNull;
    final firstIsStreaming = state.currentImage <= 1;
    return GestureDetector(
      onTap: () => _requestBatchFocus(batch),
      child: Stack(
        fit: StackFit.expand,
        children: [
          SelectableImageCard(
            key: ValueKey('history-loading:${batch.key}'),
            isGenerating: true,
            historyThumb: true,
            batchBadgeCount: batch.count,
            currentImage: 1,
            totalImages: batch.count,
            progress:
                slot?.progress ?? (firstIsStreaming ? state.progress : null),
            streamPreview:
                slot?.previewBytes ??
                (firstIsStreaming ? state.streamPreview : null),
            focusedPreviewPlacement:
                slot?.focusedPreviewPlacement ??
                (firstIsStreaming ? state.focusedPreviewPlacement : null),
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            enableSelection: false,
            enableContextMenu: false,
          ),
          if (batch.count > 1)
            Positioned(
              right: 6,
              bottom: 6,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 3,
                    ),
                    child: Text(
                      '×${batch.count}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  GlobalKey _imageKeyFor(String imageId) =>
      _imageKeys.putIfAbsent(imageId, GlobalKey.new);

  void _scheduleScrollToSelection(String? imageId) {
    // 官网底栏 lock history scrolling：锁定后不跟随选区自动滚动
    if (_historyScrollLocked) return;
    final epoch = ++_scrollRequestEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || imageId == null) return;
      unawaited(_scrollToSelection(imageId, epoch));
    });
  }

  Future<void> _scrollToSelection(String imageId, int epoch) async {
    if (!_scrollController.hasClients) return;
    final index = _rowDescriptors.indexWhere(
      (row) => row.batch.contains(imageId),
    );
    if (index < 0) return;

    var precedingExtent = 8.0;
    for (var i = 0; i < index; i++) {
      precedingExtent += _rowDescriptors[i].extent;
    }
    final row = _rowDescriptors[index];
    final viewport = _scrollController.position.viewportDimension;
    final target = (precedingExtent + row.extent / 2 - viewport / 2).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    try {
      await _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
      );
    } catch (_) {
      return;
    }
    if (!mounted ||
        epoch != _scrollRequestEpoch ||
        ref.read(generationPreviewSelectionProvider) != imageId) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          epoch != _scrollRequestEpoch ||
          ref.read(generationPreviewSelectionProvider) != imageId) {
        return;
      }
      final itemContext = _imageKeys[row.batch.key]?.currentContext;
      if (itemContext != null) {
        unawaited(
          Scrollable.ensureVisible(
            itemContext,
            alignment: 0.5,
            duration: const Duration(milliseconds: 80),
          ),
        );
      }
    });
  }

  bool get _isMultiSelectModifierPressed {
    final keyboard = HardwareKeyboard.instance;
    return keyboard.isControlPressed || keyboard.isMetaPressed;
  }

  bool _isBatchSelected(HistoryBatch batch) =>
      batch.selectableImages.isNotEmpty &&
      batch.selectableImages.every((image) => _selectedIds.contains(image.id));

  void _setBatchSelected(HistoryBatch batch, bool selected) {
    if (batch.selectableImages.isEmpty) return;
    setState(() {
      final ids = batch.selectableImages.map((image) => image.id);
      if (selected) {
        _selectedBatchKeys.add(batch.key);
        _selectedIds.addAll(ids);
      } else {
        _selectedBatchKeys.remove(batch.key);
        _selectedIds.removeAll(ids);
        if (_selectedIds.isEmpty) _multiSelectMode = false;
      }
    });
  }

  void _requestBatchFocus(HistoryBatch batch) {
    final request = ref.read(canvasHistoryFocusRequestProvider.notifier);
    request.state = (
      group: batch.key,
      imageId: batch.cover?.id,
      revision: (request.state?.revision ?? 0) + 1,
    );
    final cover = batch.cover;
    if (cover != null) {
      ref.read(generationPreviewSelectionProvider.notifier).select(cover.id);
    }
    ref.read(generationPreviewFocusNodeProvider).requestFocus();
  }

  void _handleImageTap(
    BuildContext context,
    GeneratedImage image,
    HistoryClickBehavior behavior, {
    required HistoryBatch batch,
  }) {
    if ((_isMultiSelectModifierPressed || _multiSelectMode) &&
        batch.selectableImages.isNotEmpty) {
      _setBatchSelected(batch, !_isBatchSelected(batch));
      return;
    }
    if (behavior == HistoryClickBehavior.selectPreview) {
      _requestBatchFocus(batch);
      return;
    }
    _showSingleDetail(context, image);
  }

  void _showDetailForBehavior(
    BuildContext context,
    GeneratedImage image,
    HistoryClickBehavior behavior,
  ) {
    if (behavior == HistoryClickBehavior.selectPreview) {
      _showLinkedDetail(context, image);
    } else {
      _showSingleDetail(context, image);
    }
  }

  bool _favoriteStateFor(GeneratedImage image) {
    _ensureFavoriteStateLoaded(image);
    return _favoriteStates[image.id] ?? false;
  }

  void _ensureFavoriteStateLoaded(GeneratedImage image) {
    final filePath = image.filePath;
    if (filePath == null || filePath.isEmpty) {
      if (_favoriteStatePaths[image.id] != null ||
          _favoriteStates[image.id] == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _favoriteStatePaths[image.id] = null;
            _favoriteStates[image.id] = false;
          });
        });
      }
      return;
    }

    if (_favoriteStatePaths[image.id] == filePath &&
        (_favoriteStates.containsKey(image.id) ||
            _favoriteStatusLoadingIds.contains(image.id))) {
      return;
    }

    _favoriteStatePaths[image.id] = filePath;
    _favoriteStatusLoadingIds.add(image.id);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        () async {
          final isFavorite = await ref
              .read(localGalleryNotifierProvider.notifier)
              .isFavorite(filePath);
          if (!mounted || _favoriteStatePaths[image.id] != filePath) return;
          setState(() {
            _favoriteStates[image.id] = isFavorite;
            _favoriteStatusLoadingIds.remove(image.id);
          });
        }().catchError((Object error, StackTrace stack) {
          if (!mounted) return;
          setState(() {
            _favoriteStatusLoadingIds.remove(image.id);
          });
        }),
      );
    });
  }

  Future<void> _toggleHistoryFavorite(
    BuildContext context,
    GeneratedImage image,
  ) async {
    if (!_favoriteToggleLoadingIds.add(image.id)) return;

    try {
      final filePath = await _ensureHistoryImageSaved(image);
      final isFavorite = await ref
          .read(localGalleryNotifierProvider.notifier)
          .toggleFavorite(filePath);

      if (!mounted) return;
      setState(() {
        _favoriteStatePaths[image.id] = filePath;
        _favoriteStates[image.id] = isFavorite;
      });

      if (context.mounted) {
        AppToast.success(
          context,
          isFavorite
              ? context.l10n.toast_favorited
              : context.l10n.toast_unfavorited,
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(
          context,
          context.l10n.toast_favoriteUpdateFailed(e.toString()),
        );
      }
    } finally {
      _favoriteToggleLoadingIds.remove(image.id);
    }
  }

  Future<String> _ensureHistoryImageSaved(GeneratedImage image) async {
    final l10n = context.l10n;
    final existingPath = image.filePath;
    if (existingPath != null &&
        existingPath.isNotEmpty &&
        await File(existingPath).exists()) {
      return existingPath;
    }

    final saveDirPath = await GalleryFolderRepository.instance.getRootPath();
    if (saveDirPath == null || saveDirPath.isEmpty) {
      throw StateError(l10n.localGallery_saveDirectoryNotSet);
    }

    // 原子保存：日期分类路径 + 独占防冲突 + 失败清理，全部在工具内完成
    final filePath = await ImageSaveUtils.saveBytesToDatedPath(
      rootPath: saveDirPath,
      bytes: image.bytes,
      seed: await ImageSaveUtils.resolveSeed(
        metadata: image.metadata,
        bytes: image.bytes,
      ),
    );

    ref
        .read(imageGenerationNotifierProvider.notifier)
        .updateImageFilePath(image.id, filePath);
    await ref.read(localGalleryNotifierProvider.notifier).addNewlySavedImages([
      filePath,
    ]);

    return filePath;
  }

  String _historyImageFileName(GeneratedImage image) {
    final filePath = image.filePath;
    if (filePath != null && filePath.isNotEmpty) {
      return p.basename(filePath);
    }
    return 'history_${image.id}.png';
  }

  void _sendHistoryImageToImageToImage(
    BuildContext context,
    GeneratedImage image,
  ) {
    ImageWorkflowLauncher.openImageToImage(ref, image.bytes);
    AppToast.success(context, context.l10n.drop_addedToImg2Img);
  }

  Future<void> _sendHistoryImageToVibeTransfer(
    BuildContext context,
    GeneratedImage image,
  ) async {
    final l10n = context.l10n;

    try {
      final currentState = ref.read(generationParamsNotifierProvider);
      final currentCount = currentState.vibeReferencesV4.length;
      const maxCount = 16;
      final vibes = await VibeFileParser.parseFile(
        _historyImageFileName(image),
        image.bytes,
      );

      if (!context.mounted) return;
      if (currentCount + vibes.length > maxCount) {
        AppToast.warning(context, l10n.toast_styleReferenceLimit(maxCount));
        return;
      }

      ref
          .read(generationParamsNotifierProvider.notifier)
          .addVibeReferences(vibes);

      final message = currentCount > 0
          ? l10n.toast_appendedStyleReferences(vibes.length)
          : vibes.length == 1
          ? l10n.drop_addedToVibe
          : l10n.drop_addedMultipleToVibe(vibes.length);
      AppToast.success(context, message);
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, '${l10n.vibeParseFailed}: $e');
      }
    }
  }

  Future<void> _sendHistoryImageToPreciseReference(
    BuildContext context,
    GeneratedImage image,
  ) async {
    final l10n = context.l10n;

    try {
      await ref
          .read(generationParamsNotifierProvider.notifier)
          .addPreciseReferenceFromImage(
            image.bytes,
            type: PreciseRefType.character,
            strength: 1.0,
            fidelity: 1.0,
          );

      if (!context.mounted) return;
      AppToast.success(context, l10n.drop_addedToCharacterRef);
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, l10n.gallery_sendFailed(e.toString()));
      }
    }
  }

  Widget _buildBottomActions(
    BuildContext context,
    ImageGenerationState state,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final packButton = OutlinedButton.icon(
            onPressed: _selectedIds.isEmpty
                ? null
                : () => _packSelectedImages(context, state),
            icon: const StudioIcon(Icons.archive_outlined, size: 18),
            label: Text(
              '${context.l10n.common_pack} (${_selectedIds.length})',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          );
          final saveButton = FilledButton.icon(
            onPressed: _selectedIds.isEmpty
                ? null
                : () => _saveSelectedImages(context, state),
            icon: const StudioIcon(Icons.image_outlined, size: 18),
            label: Text(
              '${context.l10n.image_save} (${_selectedIds.length})',
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          );
          final closeButton = IconButton(
            tooltip: context.l10n.generation_deselectAll,
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() {
              _selectedIds.clear();
              _selectedBatchKeys.clear();
              _multiSelectMode = false;
            }),
            icon: const StudioIcon(Icons.close),
          );

          // 窄栏给每个操作完整一行，避免图标、文字及按钮内边距互相挤压。
          if (constraints.maxWidth < 280) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      packButton,
                      const SizedBox(height: 6),
                      saveButton,
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                closeButton,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: packButton),
              const SizedBox(width: 8),
              Expanded(child: saveButton),
              const SizedBox(width: 8),
              closeButton,
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveSelectedImages(
    BuildContext context,
    ImageGenerationState state,
  ) async {
    if (_selectedIds.isEmpty) return;
    await _saveImageIds(context, state, _selectedIds, clearSelection: true);
  }

  /// 按 id 集合保存图像（选中保存与「下载全部」共用）。
  Future<void> _saveImageIds(
    BuildContext context,
    ImageGenerationState state,
    Set<String> ids, {
    bool clearSelection = false,
  }) async {
    if (ids.isEmpty) return;

    try {
      final saveDirPath = await GalleryFolderRepository.instance.getRootPath();
      if (saveDirPath == null) return;

      // 从所有可选图像中查找目标图像
      final allImages = _getAllSelectableImages(state);
      final selectedImages = allImages
          .where((img) => ids.contains(img.id))
          .toList();

      // 原子保存：日期分类路径 + 独占防冲突 + 失败清理，全部在工具内完成
      for (int i = 0; i < selectedImages.length; i++) {
        final image = selectedImages[i];
        await ImageSaveUtils.saveBytesToDatedPath(
          rootPath: saveDirPath,
          bytes: image.bytes,
          seed: await ImageSaveUtils.resolveSeed(
            metadata: image.metadata,
            bytes: image.bytes,
          ),
        );
      }

      ref.read(localGalleryNotifierProvider.notifier).refresh();

      if (context.mounted) {
        AppToast.success(context, context.l10n.image_imageSaved(saveDirPath));
        if (clearSelection) {
          setState(() {
            _selectedIds.clear();
            _selectedBatchKeys.clear();
          });
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, context.l10n.image_saveFailed(e.toString()));
      }
    }
  }

  /// 打包选中的图片成压缩包
  Future<void> _packSelectedImages(
    BuildContext context,
    ImageGenerationState state,
  ) async {
    if (_selectedIds.isEmpty) return;

    // 直接使用保存文件对话框，用户可以选择路径并输入文件名
    final defaultName = 'images_${DateTime.now().millisecondsSinceEpoch}';
    final outputPath = await FilePicker.platform.saveFile(
      dialogTitle: context.l10n.localGallery_saveZipArchive,
      fileName: '$defaultName.zip',
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (outputPath == null || !context.mounted) return;

    // 确保文件名以 .zip 结尾
    final finalPath = outputPath.endsWith('.zip')
        ? outputPath
        : '$outputPath.zip';

    // 显示打包进度
    AppToast.info(
      context,
      context.l10n.toast_packingImages(_selectedIds.length),
    );

    try {
      // 先将选中的图片保存到临时目录
      final tempDir = await Directory.systemTemp.createTemp('nai_pack_');
      final imagePaths = <String>[];

      final allImages = _getAllSelectableImages(state);
      final selectedImages = allImages
          .where((img) => _selectedIds.contains(img.id))
          .toList();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      for (int i = 0; i < selectedImages.length; i++) {
        final fileName = 'NAI_${timestamp}_${i + 1}.png';
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(selectedImages[i].bytes);
        imagePaths.add(file.path);
      }

      // 执行打包
      final success = await ZipUtils.createZipFromImages(imagePaths, finalPath);

      // 清理临时文件
      await tempDir.delete(recursive: true);

      if (context.mounted) {
        if (success) {
          AppToast.success(
            context,
            context.l10n.toast_packedImages(selectedImages.length),
          );
          setState(() {
            _selectedIds.clear();
            _selectedBatchKeys.clear();
          });
        } else {
          AppToast.error(context, context.l10n.toast_packFailed);
        }
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(
          context,
          context.l10n.toast_packFailedWithError(e.toString()),
        );
      }
    }
  }

  /// 回读状态中同 id 且已带 filePath 的最新图像对象；没有则返回原对象。
  /// 构建期捕获的 image 可能早于自动保存的 filePath 回写，点击时应以状态为准。
  GeneratedImage _freshImageWithPath(GeneratedImage image) {
    final s = ref.read(imageGenerationNotifierProvider);
    for (final list in [s.currentImages, s.history, s.displayImages]) {
      for (final candidate in list) {
        if (candidate.id == image.id &&
            candidate.filePath != null &&
            candidate.filePath!.isNotEmpty) {
          return candidate;
        }
      }
    }
    return image;
  }

  /// 在文件夹中定位图片。已保存的图片直接定位原文件，未保存时先保存再定位。
  Future<void> _openImageInExplorer(
    BuildContext context,
    GeneratedImage image,
  ) async {
    try {
      final existingPath = _freshImageWithPath(image).filePath;
      if (existingPath != null &&
          existingPath.isNotEmpty &&
          await File(existingPath).exists()) {
        await FileExplorerUtils.revealFile(existingPath);
        return;
      }

      final saveDirPath = await GalleryFolderRepository.instance.getRootPath();
      if (saveDirPath == null) return;

      final seed = await ImageSaveUtils.resolveSeed(
        metadata: image.metadata,
        bytes: image.bytes,
      );

      // 兜底去重：同一 seed 且字节一致的文件今日已存在则直接定位，
      // 不再另存副本（覆盖 filePath 未回写/跨会话等一切缺路径场景）
      final identicalPath = await ImageSaveUtils.findIdenticalDatedFile(
        rootPath: saveDirPath,
        bytes: image.bytes,
        seed: seed,
      );
      if (identicalPath != null) {
        ref
            .read(imageGenerationNotifierProvider.notifier)
            .updateImageFilePath(image.id, identicalPath);
        await FileExplorerUtils.revealFile(identicalPath);
        return;
      }

      // 原子保存：日期分类路径 + 独占防冲突 + 失败清理，全部在工具内完成
      final filePath = await ImageSaveUtils.saveBytesToDatedPath(
        rootPath: saveDirPath,
        bytes: image.bytes,
        seed: seed,
      );

      // 回写保存路径，后续「打开文件夹」「保存图像」直接复用原文件
      ref
          .read(imageGenerationNotifierProvider.notifier)
          .updateImageFilePath(image.id, filePath);

      ref.read(localGalleryNotifierProvider.notifier).refresh();

      // 在文件夹中打开并选中文件
      await FileExplorerUtils.revealFile(filePath);

      if (context.mounted) {
        AppToast.success(context, context.l10n.image_imageSaved(saveDirPath));
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, context.l10n.image_saveFailed(e.toString()));
      }
    }
  }

  void _showSingleDetail(BuildContext context, GeneratedImage image) {
    final currentContext = context;

    // 简化逻辑：统一使用 FileImageDetailData 从 PNG 文件解析元数据
    // - 如果图像已保存（有 filePath），直接使用
    // - 如果图像未保存，使用 GeneratedImageDetailData 作为 fallback
    final ImageDetailData imageData;
    if (image.filePath != null && image.filePath!.isNotEmpty) {
      // 已保存的图像：使用 FileImageDetailData（异步解析元数据）
      // 加入预加载队列（如果尚未解析）
      ImageMetadataService().enqueuePreload(
        taskId: image.id,
        filePath: image.filePath,
      );
      imageData = FileImageDetailData(
        filePath: image.filePath!,
        cachedBytes: image.bytes,
        id: image.id,
        initialMetadata: image.metadata,
        showCopyButton: image.canSave,
      );
    } else {
      // 未保存的图像：使用 GeneratedImageDetailData，失败快照仅允许查看。
      imageData = GeneratedImageDetailData(
        imageBytes: image.bytes,
        metadata: image.metadata,
        id: image.id,
        showSaveButton: image.canSave,
        showCopyButton: image.canSave,
      );
    }

    if (!currentContext.mounted) return;

    // 使用 ImageDetailOpener 打开详情页（带防重复点击）
    ImageDetailOpener.showSingleImmediate(
      currentContext,
      image: imageData,
      showMetadataPanel: true,
      callbacks: ImageDetailCallbacks(
        onSave: image.canSave
            ? (img) => GenerationSaveService.saveImageFromDetail(
                currentContext,
                ref,
                img,
              )
            : null,
      ),
    );
  }

  void _showLinkedDetail(BuildContext context, GeneratedImage image) {
    final state = ref.read(imageGenerationNotifierProvider);
    final sequence = state.detailSequenceFor(image);
    final initialIndex = sequence.indexWhere((item) => item.id == image.id);
    final detailImages = sequence.map(_createDetailData).toList();
    if (!context.mounted || detailImages.isEmpty) return;

    ImageDetailOpener.showMultipleImmediate(
      context,
      images: detailImages,
      initialIndex: initialIndex < 0 ? 0 : initialIndex,
      showMetadataPanel: true,
      showThumbnails: detailImages.length > 1,
      callbacks: ImageDetailCallbacks(
        onSave: (detail) async {
          if (!detail.showSaveButton) return;
          await GenerationSaveService.saveImageFromDetail(context, ref, detail);
        },
      ),
    );
  }

  ImageDetailData _createDetailData(GeneratedImage image) {
    final filePath = image.filePath;
    if (filePath != null && filePath.isNotEmpty) {
      ImageMetadataService().enqueuePreload(
        taskId: image.id,
        filePath: filePath,
      );
      return FileImageDetailData(
        filePath: filePath,
        cachedBytes: image.bytes,
        id: image.id,
        initialMetadata: image.metadata,
        showCopyButton: image.canSave,
      );
    }
    return GeneratedImageDetailData(
      imageBytes: image.bytes,
      metadata: image.metadata,
      id: image.id,
      showSaveButton: image.canSave,
      showCopyButton: image.canSave,
    );
  }

  /// 显示保存到块库对话框
  Future<void> _showSaveToLibraryDialog(
    BuildContext context,
    Uint8List bytes,
  ) async {
    // 历史记录中的图像需要尝试从元数据解析提示词
    String prompt = '';

    try {
      final extractedMeta = await ImageMetadataService().getMetadataFromBytes(
        bytes,
      );
      if (extractedMeta != null && extractedMeta.prompt.isNotEmpty) {
        prompt = extractedMeta.prompt;
      }
    } catch (e) {
      debugPrint('解析图像元数据失败: $e');
    }

    // 解析别名引用，保存实际内容到块库
    final aliasResolver = ref.read(aliasResolverServiceProvider.notifier);
    final resolvedPrompt = aliasResolver.resolveAliases(prompt);

    if (!context.mounted) return;

    await PromptBlockEditDialog.createWithDialog(
      context,
      ref,
      initialContent: resolvedPrompt,
      initialImageBytes: bytes,
    );
  }
}

/// 官网底栏图标钮（38×28、紧凑密度）
class _BottomToolButton extends StatelessWidget {
  const _BottomToolButton({
    required this.icon,
    required this.tooltip,
    this.color,
    this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color? color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      onPressed: onPressed,
      icon: StudioIcon(icon, size: 18),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        foregroundColor: color ?? theme.colorScheme.onSurface,
        disabledForegroundColor: theme.colorScheme.onSurface.withValues(
          alpha: 0.3,
        ),
      ),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 38, minHeight: 28),
      padding: const EdgeInsets.all(4),
    );
  }
}
