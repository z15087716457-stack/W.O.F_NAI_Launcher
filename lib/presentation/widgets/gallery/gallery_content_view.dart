import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/utils/justified_layout.dart';
import '../../../core/utils/mosaic_layout.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/models/gallery/local_image_record.dart';
import '../../../data/services/gallery/gallery_view_mode.dart';
import '../../providers/krita/krita_bridge_notifier.dart';
import '../../providers/local_gallery_provider.dart';
import '../../providers/reverse_prompt_provider.dart';
import '../../router/app_router.dart';
import '../../services/image_workflow_launcher.dart';
import '../../providers/selection_mode_provider.dart';
import '../common/app_toast.dart';
import '../../widgets/grouped_grid_view.dart';
import '../../utils/image_detail_opener.dart';
import '../../../data/services/gallery/gallery_filter_service.dart'
    show FilterCriteria;
import '../../../data/services/gallery/gallery_sort.dart'
    show GallerySortDirection, GallerySortField;
import 'local_image_card_3d.dart';
import 'draggable_image_card.dart';
import 'gallery_favorite_menu.dart';
import '../common/image_detail/image_detail_viewer.dart';
import '../common/image_detail/image_detail_data.dart';
import '../common/shimmer_skeleton.dart';
import 'gallery_grid.dart';
import 'gallery_state_views.dart';
import 'local_image_context_menu.dart';

/// 画廊项目构建函数类型
typedef GalleryItemBuilder<T> =
    Widget Function(
      BuildContext context,
      T item,
      int index,
      GalleryItemConfig config,
    );

/// 画廊项目配置
class GalleryItemConfig {
  final bool selectionMode;
  final bool isSelected;
  final double itemWidth;
  final double aspectRatio;
  final bool isVisible;
  final VoidCallback? onTap;
  final VoidCallback? onSelectionToggle;
  final VoidCallback? onLongPress;

  const GalleryItemConfig({
    required this.selectionMode,
    required this.isSelected,
    required this.itemWidth,
    required this.aspectRatio,
    this.isVisible = false,
    this.onTap,
    this.onSelectionToggle,
    this.onLongPress,
  });
}

/// 通用画廊状态接口
abstract class GalleryState<T> {
  List<T> get currentImages;
  List<LocalImageRecord> get groupedImages;
  bool get isGroupedView;
  bool get isPageLoading;
  bool get isGroupedLoading;
  int get currentPage;
  bool get hasFilters;
  List<T> get filteredFiles;

  /// 当前过滤条件（数据集重挂判定用：条件内容变化=新数据集）
  FilterCriteria get filterCriteria;

  /// 当前排序（滚动复位判定用：排序变化=新数据集）
  GallerySortField get sortField;
  GallerySortDirection get sortDirection;
}

/// 通用选择状态接口
abstract class SelectionState {
  bool get isActive;
  Set<String> get selectedIds;
}

/// 画廊内容空态类型
enum GalleryContentEmptyKind {
  /// 有过滤条件但无结果（显示「无结果 + 清除过滤」）
  noResults,

  /// 无过滤条件且库为空（显示空库视图）
  emptyLibrary,
}

/// 判定当前是否为空态（纯逻辑，便于单元测试）。
///
/// 返回 null = 非空态，正常渲染；否则为对应的空态类型。
/// 有过滤时以 `filteredFiles` 为准；无过滤时 `filteredFiles` 恒为空
/// （适配器语义），必须改用 `currentImages`，且页面加载中不视为空库。
GalleryContentEmptyKind? galleryContentEmptyKind({
  required bool hasFilters,
  required bool filteredFilesEmpty,
  required bool currentImagesEmpty,
  required bool isPageLoading,
}) {
  if (hasFilters) {
    return filteredFilesEmpty ? GalleryContentEmptyKind.noResults : null;
  }
  if (currentImagesEmpty && !isPageLoading) {
    return GalleryContentEmptyKind.emptyLibrary;
  }
  return null;
}

/// 数据集重挂判定：同一页、同一过滤条件下当前页条目数变化（删除/恢复）
/// 时，瀑布流/网格需要整体重挂载——条目增减若只靠 itemBuilder 的
/// diff 链，渲染层旧卡片可能残留（实测：删除后卡片钉在屏上，
/// 直到切换文件夹/全量刷新才消失；物理文件已删仍显示）。
/// 翻页/切换筛选/切换排序是全新数据集，不重挂；滚动复位见
/// [galleryShouldResetScroll]。
bool galleryNeedsRemount({
  required int oldLength,
  required int newLength,
  required bool samePage,
  required bool sameFilters,
}) {
  return samePage && sameFilters && oldLength != newLength;
}

/// 滚动复位判定：页码/过滤/排序任一变化都是全新数据集，滚动位置应弹回
/// 顶部——瀑布流与固定网格共用持久 ScrollController 且不重挂，旧数据集
/// 的滚动偏移会原样带进新数据集（典型症状：滚到中途点下一页，新页不从
/// 顶部开始，停在上一页滚到的位置）。同页同过滤同排序（删除/恢复走重挂
/// 的偏移保存恢复，元数据原地刷新不动偏移）不复位。
bool galleryShouldResetScroll({
  required bool samePage,
  required bool sameFilters,
  required bool sameSort,
}) {
  return !(samePage && sameFilters && sameSort);
}

/// 等高行渲染参数的公共接口：火车流 JustifiedRow 与混排 MosaicRow
/// 共用单行渲染（顶格/欠填两分支一一对应；justified_layout.dart 不动，
/// 故用适配器而非在源文件加 implements）
abstract class _EqualHeightRow {
  int get startIndex;
  int get endIndex;
  double get height;
  bool get isUnderfilled;
}

class _JustifiedRowView extends _EqualHeightRow {
  final JustifiedRow row;
  _JustifiedRowView(this.row);
  @override
  int get startIndex => row.startIndex;
  @override
  int get endIndex => row.endIndex;
  @override
  double get height => row.height;
  @override
  bool get isUnderfilled => row.isUnderfilled;
}

class _MosaicRowView extends _EqualHeightRow {
  final MosaicRow row;
  _MosaicRowView(this.row);
  @override
  int get startIndex => row.startIndex;
  @override
  int get endIndex => row.endIndex;
  @override
  double get height => row.height;
  @override
  bool get isUnderfilled => !row.isJustified;
}

/// 画廊内容视图（含分组/3D/瀑布流切换）- 泛型版本
class GenericGalleryContentView<T> extends ConsumerStatefulWidget {
  final bool use3DCardView;

  /// true=瀑布流（Masonry，卡片按真实宽高比），false=固定网格
  final bool useMasonryView;

  /// 视图模式枚举（可空）：justified 走火车流、mosaic 走混排拼块墙；
  /// null 时沿用 useMasonryView
  final GalleryViewMode? galleryViewMode;
  final int columns;
  final double itemWidth;

  /// 逻辑列宽（px）：瀑布流按「可用宽度 / 列宽」实时算列数，默认 200 保持旧行为
  final double columnWidth;
  final GalleryState<T> state;
  final SelectionState selectionState;
  final GalleryItemBuilder<T> itemBuilder;
  final String Function(T item) idExtractor;
  final void Function(T item, int index)? onTap;
  final void Function(T item, int index)? onDoubleTap;
  final void Function(T item, int index)? onLongPress;
  final void Function(T item, Offset position)? onContextMenu;
  final void Function(T item, Offset anchor)? onFavoriteToggle;
  final void Function(T item)? onSelectionToggle;
  final void Function(T item)? onEnterSelection;
  final VoidCallback? onDeleted;
  final VoidCallback? onClearFilters;
  final VoidCallback? onRefresh;
  final void Function(int page)? onLoadPage;
  final GlobalKey<GroupedGridViewState>? groupedGridViewKey;
  final Gallery3DViewConfig<T>? view3DConfig;
  final Future<void> Function(
    LocalImageRecord record,
    LocalImageContextAction action,
  )?
  onSendAction;
  final bool isKritaConnected;
  final String? emptyTitle;
  final String? emptySubtitle;
  final IconData? emptyIcon;

  const GenericGalleryContentView({
    super.key,
    this.use3DCardView = true,
    this.useMasonryView = false,
    this.galleryViewMode,
    required this.columns,
    required this.itemWidth,
    this.columnWidth = 200.0,
    required this.state,
    required this.selectionState,
    required this.itemBuilder,
    required this.idExtractor,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onContextMenu,
    this.onFavoriteToggle,
    this.onSelectionToggle,
    this.onEnterSelection,
    this.onDeleted,
    this.onClearFilters,
    this.onRefresh,
    this.onLoadPage,
    this.groupedGridViewKey,
    this.view3DConfig,
    this.onSendAction,
    this.isKritaConnected = false,
    this.emptyTitle,
    this.emptySubtitle,
    this.emptyIcon,
  });

  @override
  ConsumerState<GenericGalleryContentView<T>> createState() =>
      _GenericGalleryContentViewState<T>();
}

/// 3D视图配置
class Gallery3DViewConfig<T> {
  final List<T> images;
  final void Function(List<T> images, int initialIndex) showDetailViewer;

  const Gallery3DViewConfig({
    required this.images,
    required this.showDetailViewer,
  });
}

class _GenericGalleryContentViewState<T>
    extends ConsumerState<GenericGalleryContentView<T>>
    with TickerProviderStateMixin {
  final Map<String, double> _aspectRatioCache = {};
  bool _showSkeleton = false;
  final Set<int> _visibleIndices = {};

  /// 数据集重挂计数：同页条目增减时 ++，掺进瀑布流/网格 key 强制重挂载
  int _gridRemountCounter = 0;

  /// 瀑布流滚动控制器（重挂后恢复滚动位置用）
  ScrollController? _masonryScrollController;
  double _savedScrollOffset = 0;
  late final AnimationController _emptyStateController;
  late final Animation<double> _emptyStateAnimation;

  @override
  void initState() {
    super.initState();
    _initSkeletonDelay();
    _initEmptyStateAnimation();
  }

  @override
  void didUpdateWidget(GenericGalleryContentView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.isPageLoading && !widget.state.isPageLoading) {
      _showSkeleton = false;
    }
    if (!oldWidget.state.isPageLoading && widget.state.isPageLoading) {
      _initSkeletonDelay();
    }
    final needsRemount = galleryNeedsRemount(
      oldLength: oldWidget.state.currentImages.length,
      newLength: widget.state.currentImages.length,
      samePage: oldWidget.state.currentPage == widget.state.currentPage,
      sameFilters:
          oldWidget.state.filterCriteria == widget.state.filterCriteria,
    );
    if (needsRemount) {
      // 重挂会把滚动位置弹回顶部：先记住当前位置，新 grid 挂载后跳回
      if (_masonryScrollController?.hasClients == true) {
        _savedScrollOffset = _masonryScrollController!.offset;
      }
      setState(() => _gridRemountCounter++);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final controller = _masonryScrollController;
        if (controller != null && controller.hasClients) {
          controller.jumpTo(
            _savedScrollOffset.clamp(0, controller.position.maxScrollExtent),
          );
        }
      });
    } else if (galleryShouldResetScroll(
      samePage: oldWidget.state.currentPage == widget.state.currentPage,
      sameFilters:
          oldWidget.state.filterCriteria == widget.state.filterCriteria,
      sameSort:
          oldWidget.state.sortField == widget.state.sortField &&
          oldWidget.state.sortDirection == widget.state.sortDirection,
    )) {
      // 全新数据集（翻页/换筛选/换排序）：滚动弹回顶部，不带旧偏移。
      // 跳帧执行：didUpdateWidget 阶段内容仍是旧数据集，直接 jumpTo
      // 可能撞上同帧布局；等本帧落地后再复位。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final controller = _masonryScrollController;
        if (controller != null &&
            controller.hasClients &&
            controller.offset != 0) {
          controller.jumpTo(0);
        }
      });
    }
  }

  @override
  void dispose() {
    _masonryScrollController?.dispose();
    _emptyStateController.dispose();
    super.dispose();
  }

  void _initEmptyStateAnimation() {
    _emptyStateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _emptyStateAnimation = CurvedAnimation(
      parent: _emptyStateController,
      curve: Curves.easeOut,
    );
    _emptyStateController.forward();
  }

  void _initSkeletonDelay() {
    _showSkeleton = false;
    if (widget.state.isPageLoading) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && widget.state.isPageLoading) {
          setState(() => _showSkeleton = true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (widget.state.isGroupedView) {
      return _buildGroupedView(widget.state, widget.selectionState, theme);
    }

    // 空态判定前置：masonry/grid 分支之前统一生效（瀑布流不再拦截空态）
    final emptyKind = galleryContentEmptyKind(
      hasFilters: widget.state.hasFilters,
      filteredFilesEmpty: widget.state.filteredFiles.isEmpty,
      currentImagesEmpty: widget.state.currentImages.isEmpty,
      isPageLoading: widget.state.isPageLoading,
    );
    if (emptyKind == GalleryContentEmptyKind.noResults) {
      return _buildAnimatedEmptyState(
        GalleryNoResultsView(
          onClearFilters: widget.onClearFilters,
          title: widget.emptyTitle,
          subtitle: widget.emptySubtitle,
          icon: widget.emptyIcon,
        ),
      );
    }
    if (emptyKind == GalleryContentEmptyKind.emptyLibrary) {
      return _buildAnimatedEmptyState(const GalleryEmptyView());
    }

    if (widget.galleryViewMode == GalleryViewMode.justified) {
      return _buildJustifiedView(widget.state, widget.selectionState);
    }

    if (widget.galleryViewMode == GalleryViewMode.mosaic) {
      return _buildMosaicView(widget.state, widget.selectionState);
    }

    if (widget.useMasonryView) {
      return _buildMasonryView(widget.state, widget.selectionState);
    }

    if (widget.state.isPageLoading && _showSkeleton) {
      return _buildLoadingSkeleton();
    }

    return _buildGalleryGrid(widget.state, widget.selectionState);
  }

  Widget _buildAnimatedEmptyState(Widget child) {
    return FadeTransition(
      opacity: _emptyStateAnimation,
      child: AnimatedBuilder(
        animation: _emptyStateAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - _emptyStateAnimation.value)),
            child: child,
          );
        },
        child: child,
      ),
    );
  }

  Widget _buildGroupedView(
    GalleryState<T> state,
    SelectionState selectionState,
    ThemeData theme,
  ) {
    if (state.isGroupedLoading) {
      return _buildGroupedLoadingSkeleton();
    }

    if (state.groupedImages.isEmpty) {
      return _buildAnimatedEmptyState(
        GalleryNoResultsView(onClearFilters: widget.onClearFilters),
      );
    }

    return GroupedGridView(
      key: widget.groupedGridViewKey,
      images: state.groupedImages,
      columns: widget.columns,
      itemWidth: widget.itemWidth,
      buildCard: (record) {
        final isSelected = selectionState.selectedIds.contains(record.path);
        final aspectRatio = _getCachedAspectRatio(record);
        final index = state.groupedImages.indexOf(record);
        final isVisible = _visibleIndices.contains(index);

        return VisibilityDetector(
          key: ValueKey('grouped_visibility_${record.path}_$index'),
          onVisibilityChanged: (visibilityInfo) {
            final isNowVisible = visibilityInfo.visibleFraction > 0.05;
            final wasVisible = _visibleIndices.contains(index);

            if (isNowVisible != wasVisible && mounted) {
              setState(() {
                if (isNowVisible) {
                  _visibleIndices.add(index);
                } else {
                  _visibleIndices.remove(index);
                }
              });
            }
          },
          child: LocalImageCard3D(
            record: record,
            width: widget.itemWidth,
            height: widget.itemWidth / aspectRatio,
            isSelected: isSelected,
            isVisible: isVisible,
            priority: isVisible ? 1 : 5,
            onTap: () {
              if (selectionState.isActive) {
                widget.onSelectionToggle?.call(record as T);
              }
            },
            onLongPress: () {
              if (!selectionState.isActive) {
                widget.onEnterSelection?.call(record as T);
              }
            },
            onSecondaryTapDown: widget.onContextMenu != null
                ? (details) =>
                      widget.onContextMenu!(record as T, details.globalPosition)
                : null,
            onFavoriteToggle: (anchor) {
              widget.onFavoriteToggle?.call(record as T, anchor);
            },
            onSendAction: widget.onSendAction != null
                ? (action) => widget.onSendAction!(record, action)
                : null,
            isKritaConnected: widget.isKritaConnected,
            dragWrapper: selectionState.isActive
                ? null
                : DraggableImageCard.createDragWrapper(record: record),
          ),
        );
      },
    );
  }

  double _getCachedAspectRatio(LocalImageRecord record) {
    final cached = _aspectRatioCache[record.path];
    if (cached != null) {
      return cached;
    }

    // 元数据自带宽高时同步取值：否则首帧先按占位 1.0 排版、下一帧再改高，
    // 卡片进场瞬间变高（向上滚动时还会触发瀑布流位移校正，肉眼可见地抽动）
    final metadataWidth = record.metadata?.width;
    final metadataHeight = record.metadata?.height;
    if (metadataWidth != null &&
        metadataHeight != null &&
        metadataWidth > 0 &&
        metadataHeight > 0) {
      final ratio = metadataWidth / metadataHeight;
      _aspectRatioCache[record.path] = ratio;
      return ratio;
    }

    _calculateAspectRatioForRecord(record).then((value) {
      if (mounted && value != _aspectRatioCache[record.path]) {
        setState(() => _aspectRatioCache[record.path] = value);
      }
    });

    return 1.0;
  }

  Future<double> _calculateAspectRatioForRecord(LocalImageRecord record) async {
    final metadata = record.metadata;
    if (metadata?.width != null && metadata?.height != null) {
      final width = metadata!.width!;
      final height = metadata.height!;
      if (width > 0 && height > 0) return width / height;
    }

    try {
      final buffer = await ui.ImmutableBuffer.fromFilePath(record.path);
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width > 0 && descriptor.height > 0) {
        return descriptor.width / descriptor.height;
      }
    } catch (e) {
      AppLogger.d(
        'Failed to read gallery image aspect ratio: $e',
        'GalleryContent',
      );
    }

    return 1.0;
  }

  Widget _buildLoadingSkeleton() {
    return AnimatedOpacity(
      opacity: _showSkeleton ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: GridView.builder(
        key: const PageStorageKey<String>('gallery_grid_loading'),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.columns,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: widget.state.currentImages.isNotEmpty
            ? widget.state.currentImages.length
            : 20,
        itemBuilder: (_, __) => const Card(
          clipBehavior: Clip.antiAlias,
          child: ShimmerSkeleton(height: 250),
        ),
      ),
    );
  }

  Widget _buildGroupedLoadingSkeleton() {
    return const GalleryGroupedLoadingView();
  }

  /// 瀑布流视图：卡片按真实宽高比排列（固定网格不再裁/压横图）
  Widget _buildMasonryView(
    GalleryState<T> state,
    SelectionState selectionState,
  ) {
    final records = _convertToLocalImageRecords(state.currentImages);
    final selectedIndices = <int>{};
    for (int i = 0; i < records.length; i++) {
      if (selectionState.selectedIds.contains(
        widget.idExtractor(state.currentImages[i]),
      )) {
        selectedIndices.add(i);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        const padding = 16.0;
        // 列数由「可用宽度 / 逻辑列宽」实时推导（最少 1 列）
        final usableForColumns = constraints.maxWidth - padding * 2;
        final columns = (usableForColumns / widget.columnWidth).floor().clamp(
          1,
          100,
        );
        final usableWidth =
            constraints.maxWidth - padding * 2 - (columns - 1) * spacing;
        final itemWidth = (usableWidth / columns).clamp(1.0, 2000.0);

        return MasonryGridView.count(
          key: PageStorageKey<String>('gallery_masonry_$_gridRemountCounter'),
          controller: _masonryScrollController ??= ScrollController(),
          // 默认 cacheExtent（250px）不足一行卡片高，向上滚动时卡片频繁
          // 回收重建（缩略图重载 + 可见性回调风暴）；放大到 1.5 屏与固定网格对齐
          cacheExtent: constraints.maxHeight * 1.5,
          crossAxisCount: columns,
          mainAxisSpacing: spacing,
          crossAxisSpacing: spacing,
          padding: const EdgeInsets.all(padding),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            final isSelected = selectedIndices.contains(index);
            final aspectRatio = _getCachedAspectRatio(record);
            final isVisible = _visibleIndices.contains(index);

            return VisibilityDetector(
              key: ValueKey('masonry_v_${record.path}'),
              onVisibilityChanged: (info) {
                if (!mounted) return;
                final isNowVisible = info.visibleFraction > 0.05;
                final wasVisible = _visibleIndices.contains(index);
                if (isNowVisible != wasVisible) {
                  setState(() {
                    if (isNowVisible) {
                      _visibleIndices.add(index);
                    } else {
                      _visibleIndices.remove(index);
                    }
                  });
                }
              },
              // 与固定网格对齐补 RepaintBoundary：悬停光泽/解码完成的重绘
              // 只刷本卡片，不再整片网格重绘
              child: RepaintBoundary(
                child: LocalImageCard3D(
                  record: record,
                  width: itemWidth,
                  height: itemWidth / aspectRatio,
                  isSelected: isSelected,
                  isVisible: isVisible,
                  priority: isVisible ? 1 : 5,
                  onTap: () {
                    if (selectionState.isActive) {
                      widget.onSelectionToggle?.call(
                        state.currentImages[index],
                      );
                      return;
                    }
                    if (widget.onTap != null) {
                      widget.onTap!(state.currentImages[index], index);
                    } else if (widget.view3DConfig != null) {
                      widget.view3DConfig!.showDetailViewer(
                        widget.view3DConfig!.images,
                        index,
                      );
                    }
                  },
                  onDoubleTap: () {
                    if (widget.onDoubleTap != null) {
                      widget.onDoubleTap!(state.currentImages[index], index);
                    } else if (widget.view3DConfig != null) {
                      widget.view3DConfig!.showDetailViewer(
                        widget.view3DConfig!.images,
                        index,
                      );
                    }
                  },
                  onLongPress: () {
                    if (!selectionState.isActive) {
                      widget.onEnterSelection?.call(state.currentImages[index]);
                    } else {
                      widget.onLongPress?.call(
                        state.currentImages[index],
                        index,
                      );
                    }
                  },
                  onSecondaryTapDown: (details) {
                    widget.onContextMenu?.call(
                      state.currentImages[index],
                      details.globalPosition,
                    );
                  },
                  onFavoriteToggle: (anchor) {
                    widget.onFavoriteToggle?.call(
                      state.currentImages[index],
                      anchor,
                    );
                  },
                  onSendAction: widget.onSendAction != null
                      ? (action) => widget.onSendAction!(record, action)
                      : null,
                  isKritaConnected: widget.isKritaConnected,
                  dragWrapper: selectionState.isActive
                      ? null
                      : DraggableImageCard.createDragWrapper(record: record),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// 火车流视图：justified 等高行（顶格行撑满整行，欠填行左对齐留空）。
  /// 结构与瀑布流一致，宽高比探测到位触发 setState 时 build 内实时重排。
  Widget _buildJustifiedView(
    GalleryState<T> state,
    SelectionState selectionState,
  ) {
    final records = _convertToLocalImageRecords(state.currentImages);
    final selectedIndices = <int>{};
    for (int i = 0; i < records.length; i++) {
      if (selectionState.selectedIds.contains(
        widget.idExtractor(state.currentImages[i]),
      )) {
        selectedIndices.add(i);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        const padding = 16.0;
        final availableWidth = constraints.maxWidth - padding * 2;
        // 目标行高 = 逻辑列宽，行高容忍区间 [×0.8, ×1.8]
        final targetHeight = widget.columnWidth;
        final aspectRatios = [
          for (final record in records) _getCachedAspectRatio(record),
        ];
        final rows = computeJustifiedRows(
          aspectRatios: aspectRatios,
          availableWidth: availableWidth,
          targetHeight: targetHeight,
          minHeight: targetHeight * 0.8,
          maxHeight: targetHeight * 1.8,
          spacing: spacing,
        );

        return ListView.builder(
          key: PageStorageKey<String>('gallery_justified_$_gridRemountCounter'),
          controller: _masonryScrollController ??= ScrollController(),
          // 与瀑布流对齐放大 cacheExtent：减少卡片回收重建
          scrollCacheExtent: ScrollCacheExtent.pixels(
            constraints.maxHeight * 1.5,
          ),
          padding: const EdgeInsets.all(padding),
          itemCount: rows.length,
          itemBuilder: (context, rowIndex) => _buildJustifiedRowWidget(
            aspectRatios,
            _JustifiedRowView(rows[rowIndex]),
            availableWidth,
            spacing,
            cardBuilder: (index, width, height) => _buildJustifiedCard(
              state,
              selectionState,
              records,
              selectedIndices,
              index,
              width,
              height,
            ),
          ),
        );
      },
    );
  }

  /// 等高行单行渲染：顶格行撑满整行 / 欠填行左对齐留空两分支。
  /// 火车流（JustifiedRow）与混排（MosaicRow）共用，卡片由 cardBuilder
  /// 注入（两视图各自的全交互单卡）。
  Widget _buildJustifiedRowWidget(
    List<double> aspectRatios,
    _EqualHeightRow row,
    double availableWidth,
    double spacing, {
    required Widget Function(int index, double width, double height)
    cardBuilder,
  }) {
    final count = row.endIndex - row.startIndex + 1;
    final List<Widget> children;
    // 欠填行防溢出的等比缩率（1 = 不缩）；缩放行高同步收窄
    var rowHeight = row.height;
    if (row.isUnderfilled) {
      // 欠填行：图按行高×aspect 取自然宽、左对齐、右侧留空；
      // clamp 抬高的极端行（如单张全景）按 shrink 等比收窄防溢出——
      // 宽高必须同乘 shrink，只缩宽会把竖图横向压扁
      final widths = [
        for (var i = row.startIndex; i <= row.endIndex; i++)
          row.height * aspectRatios[i],
      ];
      final contentWidth =
          widths.fold<double>(0, (a, b) => a + b) + spacing * (count - 1);
      final shrink = contentWidth > availableWidth && contentWidth > 0
          ? ((availableWidth - spacing * (count - 1)) / contentWidth).clamp(
              0.0,
              1.0,
            )
          : 1.0;
      rowHeight = row.height * shrink;
      children = [
        for (var k = 0; k < count; k++) ...[
          if (k > 0) SizedBox(width: spacing),
          SizedBox(
            width: widths[k] * shrink,
            height: rowHeight,
            child: cardBuilder(
              row.startIndex + k,
              widths[k] * shrink,
              rowHeight,
            ),
          ),
        ],
      ];
    } else {
      // 顶格行：按宽高比 flex 分宽，正好撑满整行
      children = [
        for (var k = 0; k < count; k++) ...[
          if (k > 0) SizedBox(width: spacing),
          Expanded(
            flex: (aspectRatios[row.startIndex + k] * 1000).round(),
            child: cardBuilder(
              row.startIndex + k,
              row.height * aspectRatios[row.startIndex + k],
              row.height,
            ),
          ),
        ],
      ];
    }
    return Padding(
      padding: EdgeInsets.only(bottom: spacing),
      child: SizedBox(
        height: rowHeight,
        child: Row(children: children),
      ),
    );
  }

  /// 火车流单卡：完整镜像瀑布流 itemBuilder，仅 key 前缀与给定宽高不同
  Widget _buildJustifiedCard(
    GalleryState<T> state,
    SelectionState selectionState,
    List<LocalImageRecord> records,
    Set<int> selectedIndices,
    int index,
    double width,
    double height,
  ) {
    final record = records[index];
    final isSelected = selectedIndices.contains(index);
    final isVisible = _visibleIndices.contains(index);

    return VisibilityDetector(
      key: ValueKey('justified_v_${record.path}'),
      onVisibilityChanged: (info) {
        if (!mounted) return;
        final isNowVisible = info.visibleFraction > 0.05;
        final wasVisible = _visibleIndices.contains(index);
        if (isNowVisible != wasVisible) {
          setState(() {
            if (isNowVisible) {
              _visibleIndices.add(index);
            } else {
              _visibleIndices.remove(index);
            }
          });
        }
      },
      // 与瀑布流对齐补 RepaintBoundary：重绘只刷本卡片
      child: RepaintBoundary(
        child: LocalImageCard3D(
          record: record,
          width: width,
          height: height,
          isSelected: isSelected,
          isVisible: isVisible,
          priority: isVisible ? 1 : 5,
          onTap: () {
            if (selectionState.isActive) {
              widget.onSelectionToggle?.call(state.currentImages[index]);
              return;
            }
            if (widget.onTap != null) {
              widget.onTap!(state.currentImages[index], index);
            } else if (widget.view3DConfig != null) {
              widget.view3DConfig!.showDetailViewer(
                widget.view3DConfig!.images,
                index,
              );
            }
          },
          onDoubleTap: () {
            if (widget.onDoubleTap != null) {
              widget.onDoubleTap!(state.currentImages[index], index);
            } else if (widget.view3DConfig != null) {
              widget.view3DConfig!.showDetailViewer(
                widget.view3DConfig!.images,
                index,
              );
            }
          },
          onLongPress: () {
            if (!selectionState.isActive) {
              widget.onEnterSelection?.call(state.currentImages[index]);
            } else {
              widget.onLongPress?.call(state.currentImages[index], index);
            }
          },
          onSecondaryTapDown: (details) {
            widget.onContextMenu?.call(
              state.currentImages[index],
              details.globalPosition,
            );
          },
          onFavoriteToggle: (anchor) {
            widget.onFavoriteToggle?.call(state.currentImages[index], anchor);
          },
          onSendAction: widget.onSendAction != null
              ? (action) => widget.onSendAction!(record, action)
              : null,
          isKritaConnected: widget.isKritaConnected,
          dragWrapper: selectionState.isActive
              ? null
              : DraggableImageCard.createDragWrapper(record: record),
        ),
      ),
    );
  }

  /// 混排视图：面积均衡等高行（行高以目标面积 t² 为锚、与窗宽无关，
  /// 顶格/欠填两分支与火车流共用单行渲染）。
  /// 结构与火车流一致，宽高比探测到位触发 setState 时 build 内实时重排。
  Widget _buildMosaicView(
    GalleryState<T> state,
    SelectionState selectionState,
  ) {
    final records = _convertToLocalImageRecords(state.currentImages);
    final selectedIndices = <int>{};
    for (int i = 0; i < records.length; i++) {
      if (selectionState.selectedIds.contains(
        widget.idExtractor(state.currentImages[i]),
      )) {
        selectedIndices.add(i);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        const padding = 16.0;
        final availableWidth = constraints.maxWidth - padding * 2;
        // 目标边长 t = 逻辑列宽（目标面积 t² 的边长）
        final targetHeight = widget.columnWidth;
        final aspectRatios = [
          for (final record in records) _getCachedAspectRatio(record),
        ];
        final rows = computeMosaicRows(
          aspectRatios: aspectRatios,
          availableWidth: availableWidth,
          targetHeight: targetHeight,
          spacing: spacing,
        );

        return ListView.builder(
          key: PageStorageKey<String>('gallery_mosaic_$_gridRemountCounter'),
          controller: _masonryScrollController ??= ScrollController(),
          // 与瀑布流对齐放大 cacheExtent：减少卡片回收重建
          scrollCacheExtent: ScrollCacheExtent.pixels(
            constraints.maxHeight * 1.5,
          ),
          padding: const EdgeInsets.all(padding),
          itemCount: rows.length,
          itemBuilder: (context, rowIndex) => _buildJustifiedRowWidget(
            aspectRatios,
            _MosaicRowView(rows[rowIndex]),
            availableWidth,
            spacing,
            cardBuilder: (index, width, height) => _buildMosaicCard(
              state,
              selectionState,
              records,
              selectedIndices,
              index,
              width,
              height,
            ),
          ),
        );
      },
    );
  }

  /// 混排单卡：完整镜像火车流单卡，仅 key 前缀与给定宽高不同
  Widget _buildMosaicCard(
    GalleryState<T> state,
    SelectionState selectionState,
    List<LocalImageRecord> records,
    Set<int> selectedIndices,
    int index,
    double width,
    double height,
  ) {
    final record = records[index];
    final isSelected = selectedIndices.contains(index);
    final isVisible = _visibleIndices.contains(index);

    return VisibilityDetector(
      key: ValueKey('mosaic_v_${record.path}'),
      onVisibilityChanged: (info) {
        if (!mounted) return;
        final isNowVisible = info.visibleFraction > 0.05;
        final wasVisible = _visibleIndices.contains(index);
        if (isNowVisible != wasVisible) {
          setState(() {
            if (isNowVisible) {
              _visibleIndices.add(index);
            } else {
              _visibleIndices.remove(index);
            }
          });
        }
      },
      // 与瀑布流对齐补 RepaintBoundary：重绘只刷本卡片
      child: RepaintBoundary(
        child: LocalImageCard3D(
          record: record,
          width: width,
          height: height,
          isSelected: isSelected,
          isVisible: isVisible,
          priority: isVisible ? 1 : 5,
          onTap: () {
            if (selectionState.isActive) {
              widget.onSelectionToggle?.call(state.currentImages[index]);
              return;
            }
            if (widget.onTap != null) {
              widget.onTap!(state.currentImages[index], index);
            } else if (widget.view3DConfig != null) {
              widget.view3DConfig!.showDetailViewer(
                widget.view3DConfig!.images,
                index,
              );
            }
          },
          onDoubleTap: () {
            if (widget.onDoubleTap != null) {
              widget.onDoubleTap!(state.currentImages[index], index);
            } else if (widget.view3DConfig != null) {
              widget.view3DConfig!.showDetailViewer(
                widget.view3DConfig!.images,
                index,
              );
            }
          },
          onLongPress: () {
            if (!selectionState.isActive) {
              widget.onEnterSelection?.call(state.currentImages[index]);
            } else {
              widget.onLongPress?.call(state.currentImages[index], index);
            }
          },
          onSecondaryTapDown: (details) {
            widget.onContextMenu?.call(
              state.currentImages[index],
              details.globalPosition,
            );
          },
          onFavoriteToggle: (anchor) {
            widget.onFavoriteToggle?.call(state.currentImages[index], anchor);
          },
          onSendAction: widget.onSendAction != null
              ? (action) => widget.onSendAction!(record, action)
              : null,
          isKritaConnected: widget.isKritaConnected,
          dragWrapper: selectionState.isActive
              ? null
              : DraggableImageCard.createDragWrapper(record: record),
        ),
      ),
    );
  }

  Widget _buildGalleryGrid(
    GalleryState<T> state,
    SelectionState selectionState,
  ) {
    final selectedIndices = <int>{};
    for (int i = 0; i < state.currentImages.length; i++) {
      if (selectionState.selectedIds.contains(
        widget.idExtractor(state.currentImages[i]),
      )) {
        selectedIndices.add(i);
      }
    }

    return GalleryGrid(
      key: PageStorageKey<String>('gallery_grid_$_gridRemountCounter'),
      scrollController: _masonryScrollController ??= ScrollController(),
      images: _convertToLocalImageRecords(state.currentImages),
      columns: widget.columns,
      spacing: 12,
      padding: const EdgeInsets.all(16),
      selectedIndices: selectionState.isActive ? selectedIndices : null,
      enableDrag: !selectionState.isActive,
      onTap: (record, index) {
        if (selectionState.isActive) {
          widget.onSelectionToggle?.call(state.currentImages[index]);
          return;
        }
        if (widget.onTap != null) {
          widget.onTap!(state.currentImages[index], index);
        } else if (widget.view3DConfig != null) {
          widget.view3DConfig!.showDetailViewer(
            widget.view3DConfig!.images,
            index,
          );
        }
      },
      onDoubleTap: (record, index) {
        if (widget.onDoubleTap != null) {
          widget.onDoubleTap!(state.currentImages[index], index);
        } else if (widget.view3DConfig != null) {
          widget.view3DConfig!.showDetailViewer(
            widget.view3DConfig!.images,
            index,
          );
        }
      },
      onLongPress: (record, index) {
        if (!selectionState.isActive) {
          widget.onEnterSelection?.call(state.currentImages[index]);
        } else {
          widget.onLongPress?.call(state.currentImages[index], index);
        }
      },
      onSecondaryTapDown: (record, index, details) {
        widget.onContextMenu?.call(
          state.currentImages[index],
          details.globalPosition,
        );
      },
      onFavoriteToggle: (record, index, anchor) {
        widget.onFavoriteToggle?.call(state.currentImages[index], anchor);
      },
      onSendAction: widget.onSendAction != null
          ? (record, index, action) => widget.onSendAction!(record, action)
          : null,
      isKritaConnected: widget.isKritaConnected,
    );
  }

  List<LocalImageRecord> _convertToLocalImageRecords(List<T> items) {
    // ignore: avoid_as
    return items as List<LocalImageRecord>;
  }
}

// ============================================
// 向后兼容的 LocalImageRecord 专用版本
// ============================================

/// 本地画廊状态适配器
class _LocalGalleryStateAdapter implements GalleryState<LocalImageRecord> {
  final LocalGalleryState _state;

  _LocalGalleryStateAdapter(this._state);

  @override
  List<LocalImageRecord> get currentImages => _state.currentImages;

  @override
  List<LocalImageRecord> get groupedImages => _state.groupedImages;

  @override
  bool get isGroupedView => _state.isGroupedView;

  @override
  bool get isPageLoading => _state.isPageLoading;

  @override
  bool get isGroupedLoading => _state.isGroupedLoading;

  @override
  int get currentPage => _state.currentPage;

  @override
  FilterCriteria get filterCriteria => _state.filterCriteria;

  @override
  GallerySortField get sortField => _state.sortField;

  @override
  GallerySortDirection get sortDirection => _state.sortDirection;

  @override
  bool get hasFilters => _state.hasFilters;

  @override
  List<LocalImageRecord> get filteredFiles =>
      _state.hasFilters ? _state.currentImages : const [];
}

/// 本地选择状态适配器
class _LocalSelectionStateAdapter implements SelectionState {
  final SelectionModeState _state;

  _LocalSelectionStateAdapter(this._state);

  @override
  bool get isActive => _state.isActive;

  @override
  Set<String> get selectedIds => _state.selectedIds;
}

/// 向后兼容的画廊内容视图
class LocalGalleryContentView extends ConsumerWidget {
  final bool use3DCardView;
  final int columns;
  final double itemWidth;

  /// 逻辑列宽（px）：瀑布流按它算列数
  final double columnWidth;
  final Future<void> Function(LocalImageRecord record)? onReuseMetadata;
  final void Function(LocalImageRecord record, Offset position)? onContextMenu;
  final Future<void> Function(
    LocalImageRecord record,
    LocalImageContextAction action,
  )?
  onSendAction;
  final VoidCallback? onDeleted;

  /// 大图查看器内删除当前图片（返回是否删除成功，null=该入口不支持删除）
  final Future<bool> Function(LocalImageRecord record)? onViewerDelete;
  final GlobalKey<GroupedGridViewState>? groupedGridViewKey;

  const LocalGalleryContentView({
    super.key,
    this.use3DCardView = true,
    required this.columns,
    required this.itemWidth,
    required this.columnWidth,
    this.onReuseMetadata,
    this.onContextMenu,
    this.onSendAction,
    this.onDeleted,
    this.onViewerDelete,
    this.groupedGridViewKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(localGalleryNotifierProvider);
    final selectionState = ref.watch(localGallerySelectionNotifierProvider);
    final isKritaConnected = ref.watch(
      kritaBridgeNotifierProvider.select(
        (state) => state.status == KritaBridgeStatus.connected,
      ),
    );

    void showImageDetailViewer(
      List<LocalImageRecord> images,
      int initialIndex,
    ) {
      bool getFavoriteStatus(String path) {
        final providerState = ref.read(localGalleryNotifierProvider);
        final image = providerState.currentImages
            .cast<LocalImageRecord?>()
            .firstWhere((img) => img?.path == path, orElse: () => null);
        return image?.isFavorite ?? false;
      }

      ImageDetailOpener.showMultipleImmediate(
        context,
        images: images
            .map(
              (r) =>
                  LocalImageDetailData(r, getFavoriteStatus: getFavoriteStatus),
            )
            .toList(),
        initialIndex: initialIndex,
        showMetadataPanel: true,
        showThumbnails: images.length > 1,
        callbacks: ImageDetailCallbacks(
          onReuseMetadata: onReuseMetadata != null
              ? (data) =>
                    onReuseMetadata!((data as LocalImageDetailData).record)
              : null,
          onFavoriteToggle: (data) => ref
              .read(localGalleryNotifierProvider.notifier)
              .toggleFavorite((data as LocalImageDetailData).record.path),
          onSendToImg2Img: (data) async {
            try {
              final bytes = await data.getImageBytes();
              ImageWorkflowLauncher.openImageToImage(ref, bytes);
              if (!context.mounted) return;
              Navigator.of(context).pop();
              context.go(AppRoutes.home);
              AppToast.success(context, context.l10n.gallery_sentToImg2Img);
            } catch (e) {
              if (context.mounted) {
                AppToast.error(context, context.l10n.gallery_sendFailed('$e'));
              }
            }
          },
          onSendToReversePrompt: (data) async {
            try {
              await ref
                  .read(reversePromptProvider.notifier)
                  .addImage(
                    await data.getImageBytes(),
                    name: data.fileInfo?.fileName ?? 'gallery-image',
                  );
              if (!context.mounted) return;
              Navigator.of(context).pop();
              context.go(AppRoutes.home);
              AppToast.success(
                context,
                context.l10n.gallery_sentToReversePrompt,
              );
            } catch (e) {
              if (context.mounted) {
                AppToast.error(context, context.l10n.gallery_sendFailed('$e'));
              }
            }
          },
          onDelete: onViewerDelete != null
              ? (data) => onViewerDelete!((data as LocalImageDetailData).record)
              : null,
        ),
      );
    }

    return GenericGalleryContentView<LocalImageRecord>(
      use3DCardView: use3DCardView,
      useMasonryView: state.viewMode == GalleryViewMode.masonry,
      galleryViewMode: state.viewMode,
      columns: columns,
      itemWidth: itemWidth,
      columnWidth: columnWidth,
      state: _LocalGalleryStateAdapter(state),
      selectionState: _LocalSelectionStateAdapter(selectionState),
      idExtractor: (record) => record.path,
      itemBuilder: (context, record, index, config) => LocalImageCard3D(
        record: record,
        width: config.itemWidth,
        height: config.itemWidth / config.aspectRatio,
        isSelected: config.isSelected,
        isVisible: config.isVisible,
        priority: config.isVisible ? 1 : 5,
        onTap: config.selectionMode ? config.onSelectionToggle : config.onTap,
        onLongPress: config.onLongPress,
        onFavoriteToggle: (anchor) => showGalleryFavoriteMenu(
          context,
          ref: ref,
          record: record,
          anchor: anchor,
        ),
        onSendAction: onSendAction != null
            ? (action) => onSendAction!(record, action)
            : null,
        isKritaConnected: isKritaConnected,
      ),
      onSelectionToggle: (record) => ref
          .read(localGallerySelectionNotifierProvider.notifier)
          .toggle(record.path),
      onEnterSelection: (record) => ref
          .read(localGallerySelectionNotifierProvider.notifier)
          .enterAndSelect(record.path),
      onFavoriteToggle: (record, anchor) => showGalleryFavoriteMenu(
        context,
        ref: ref,
        record: record,
        anchor: anchor,
      ),
      onContextMenu: onContextMenu,
      onDeleted: onDeleted,
      onClearFilters: () =>
          ref.read(localGalleryNotifierProvider.notifier).clearAllFilters(),
      onRefresh: () =>
          ref.read(localGalleryNotifierProvider.notifier).refresh(),
      onLoadPage: (page) =>
          ref.read(localGalleryNotifierProvider.notifier).loadPage(page),
      groupedGridViewKey: groupedGridViewKey,
      view3DConfig: Gallery3DViewConfig<LocalImageRecord>(
        images: state.currentImages,
        showDetailViewer: showImageDetailViewer,
      ),
      onSendAction: onSendAction,
      isKritaConnected: isKritaConnected,
    );
  }
}

// 向后兼容的类型别名
typedef GalleryContentView = LocalGalleryContentView;
