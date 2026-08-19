import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/utils/localization_extension.dart';
import '../../../../../data/models/tag_library/tag_library_entry.dart';
import '../../../../widgets/common/app_toast.dart';
import '../entry_card.dart';

/// 词库条目瀑布流卡片 - 图片按原始宽高比显示，名称叠加在图上
///
/// 布局：
/// - 正常：完整缩略图（自然高度）+ 顶部渐变名称条
/// - 悬浮：暗化遮罩 + 操作按钮居中显示
///
/// 注意：瀑布流忽略 thumbnailOffsetX/Y/Scale 裁剪参数，始终显示完整图片
class WaterfallEntryCard extends StatefulWidget {
  final TagLibraryEntry entry;

  /// 列宽（用于图片解码缓存与拖拽反馈尺寸）
  final double width;

  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final VoidCallback? onEdit;
  final VoidCallback? onSend;

  /// 是否启用拖拽到分类功能
  final bool enableDrag;

  /// 是否处于选择模式
  final bool isSelectionMode;

  /// 是否被选中
  final bool isSelected;

  /// 切换选择状态回调
  final VoidCallback? onToggleSelection;

  const WaterfallEntryCard({
    super.key,
    required this.entry,
    required this.width,
    required this.onTap,
    required this.onDelete,
    required this.onToggleFavorite,
    this.onEdit,
    this.onSend,
    this.enableDrag = false,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onToggleSelection,
  });

  @override
  State<WaterfallEntryCard> createState() => _WaterfallEntryCardState();
}

class _WaterfallEntryCardState extends State<WaterfallEntryCard>
    with SingleTickerProviderStateMixin {
  bool _isHovering = false;
  bool _isDragging = false;
  OverlayEntry? _overlayEntry;
  final _layerLink = LayerLink();

  late final AnimationController _animationController;
  late final Animation<double> _elevationAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _elevationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _hidePreviewOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _showPreviewOverlay() {
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final cardSize = renderBox.size;
    final cardPosition = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => EntryPreviewOverlay(
        entry: widget.entry,
        layerLink: _layerLink,
        cardSize: cardSize,
        cardPosition: cardPosition,
        onDismiss: _hidePreviewOverlay,
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _hidePreviewOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onEnter() {
    if (!_isDragging && !widget.isSelectionMode) {
      setState(() => _isHovering = true);
      _animationController.forward();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_isHovering && mounted && !_isDragging) {
          _showPreviewOverlay();
        }
      });
    }
  }

  void _onExit() {
    setState(() => _isHovering = false);
    _animationController.reverse();
    _hidePreviewOverlay();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entry = widget.entry;

    // 选中/悬停边框色
    final borderColor = widget.isSelected
        ? theme.colorScheme.primary
        : (_isHovering
            ? theme.colorScheme.primary.withValues(alpha: 0.5)
            : Colors.transparent);

    // 卡片主体内容（高度由图片/占位图自然撑开）
    final cardBody = GestureDetector(
      onTap: widget.isSelectionMode ? widget.onToggleSelection : widget.onTap,
      onLongPress: widget.isSelectionMode
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onToggleSelection?.call();
            },
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  // 光晕效果
                  if (widget.isSelected || _isHovering)
                    BoxShadow(
                      color: widget.isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.5)
                          : theme.colorScheme.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  // 悬浮阴影（动态）
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.15 + (0.15 * _elevationAnimation.value),
                    ),
                    blurRadius: 10 + (12 * _elevationAnimation.value),
                    offset: Offset(
                      0,
                      4 + (8 * _elevationAnimation.value),
                    ),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // 内容层（图片决定卡片高度）
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        // 1. 完整图片（或占位图）
                        _buildImage(entry),

                        // 2. 顶部名称条（悬浮操作态隐藏，多选时仍保留）
                        if (widget.isSelectionMode || !_isHovering)
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: _buildNameBar(entry),
                          ),

                        // 3. 收藏图标（常驻右上角）
                        if (!widget.isSelectionMode &&
                            !_isHovering &&
                            widget.entry.isFavorite)
                          const Positioned(
                            top: 8,
                            right: 8,
                            child: _FavoriteIndicator(),
                          ),

                        // 4. 选择模式 Checkbox（右上角）
                        if (widget.isSelectionMode)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: _SelectionCheckbox(
                              isSelected: widget.isSelected,
                              onTap: widget.onToggleSelection,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // 边框层（最上层）
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: borderColor,
                          width: widget.isSelected ? 2.5 : 2,
                        ),
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

    // 外层包装：MouseRegion + 悬浮按钮层
    final cardContent = CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _onEnter(),
        onExit: (_) => _onExit(),
        child: Stack(
          children: [
            // 卡片主体（可点击）
            cardBody,

            // 悬浮按钮层（在GestureDetector外面，独立响应事件）
            if (!widget.isSelectionMode && _isHovering)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: _buildFloatingButtons(theme, entry),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return Draggable<TagLibraryEntry>(
      data: entry,
      maxSimultaneousDrags: widget.enableDrag ? null : 0,
      feedback: widget.enableDrag
          ? _buildDragFeedback(theme, entry)
          : const SizedBox.shrink(),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: cardContent,
      ),
      onDragStarted: () {
        HapticFeedback.mediumImpact();
        _hidePreviewOverlay();
        setState(() {
          _isDragging = true;
          _isHovering = false;
        });
        _animationController.reverse();
      },
      onDragEnd: (_) {
        setState(() {
          _isDragging = false;
        });
      },
      child: cardContent,
    );
  }

  /// 构建完整图片（按原始宽高比，宽度撑满列宽，高度自适应）
  Widget _buildImage(TagLibraryEntry entry) {
    if (entry.hasThumbnail && entry.thumbnail != null) {
      final cacheWidth =
          (widget.width * MediaQuery.devicePixelRatioOf(context)).round();
      return Image.file(
        File(entry.thumbnail!),
        fit: BoxFit.fitWidth,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
        cacheWidth: cacheWidth,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  /// 构建占位图（无缩略图条目，固定 4:3）
  Widget _buildPlaceholder() {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.grey.shade700,
              Colors.grey.shade900,
            ],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.image_outlined,
            size: 32,
            color: Colors.white38,
          ),
        ),
      ),
    );
  }

  /// 构建顶部渐变名称条
  Widget _buildNameBar(TagLibraryEntry entry) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.65),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Text(
        entry.displayName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 14,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// 构建悬浮操作按钮
  Widget _buildFloatingButtons(ThemeData theme, TagLibraryEntry entry) {
    final l10n = context.l10n;
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.onSend != null)
            EntryActionIcon(
              icon: Icons.send_outlined,
              tooltip: l10n.sendToHome_dialogTitle,
              onTap: widget.onSend!,
            ),
          if (widget.onSend != null) const SizedBox(width: 8),
          EntryActionIcon(
            icon: Icons.delete_outline,
            tooltip: l10n.common_delete,
            onTap: widget.onDelete,
            isDestructive: true,
          ),
          const SizedBox(width: 8),
          if (widget.onEdit != null)
            EntryActionIcon(
              icon: Icons.edit_outlined,
              tooltip: l10n.common_edit,
              onTap: widget.onEdit!,
            ),
          if (widget.onEdit != null) const SizedBox(width: 8),
          EntryActionIcon(
            icon: entry.isFavorite ? Icons.favorite : Icons.favorite_border,
            tooltip: entry.isFavorite
                ? l10n.common_unfavorite
                : l10n.common_favorite,
            onTap: widget.onToggleFavorite,
            color: entry.isFavorite ? Colors.redAccent : null,
          ),
          const SizedBox(width: 8),
          EntryActionIcon(
            icon: Icons.content_copy,
            tooltip: l10n.common_copy,
            onTap: () => _copyToClipboard(entry.content),
          ),
        ],
      ),
    );
  }

  /// 构建拖拽反馈UI
  Widget _buildDragFeedback(ThemeData theme, TagLibraryEntry entry) {
    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(16),
      color: Colors.transparent,
      shadowColor: Colors.black54,
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.8),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              if (entry.hasThumbnail && entry.thumbnail != null)
                Image.file(
                  File(entry.thumbnail!),
                  fit: BoxFit.fitWidth,
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholder(),
                )
              else
                _buildPlaceholder(),
              // 拖拽提示
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.drive_file_move_outline,
                        size: 12,
                        color: theme.colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        context.l10n.tagLibrary_moveToCategoryTitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    AppToast.success(context, context.l10n.common_copied);
  }
}

/// 收藏指示器（常驻小红心）
class _FavoriteIndicator extends StatelessWidget {
  const _FavoriteIndicator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.redAccent,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: const Icon(
        Icons.favorite,
        size: 12,
        color: Colors.white,
      ),
    );
  }
}

/// 选择复选框
class _SelectionCheckbox extends StatelessWidget {
  final bool isSelected;
  final VoidCallback? onTap;

  const _SelectionCheckbox({
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.white.withValues(alpha: 0.8),
            width: 2,
          ),
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                size: 14,
                color: theme.colorScheme.onPrimary,
              )
            : null,
      ),
    );
  }
}
