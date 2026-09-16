import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../../../../core/utils/localization_extension.dart';
import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../../data/models/prompt_block/prompt_block_folder.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../widgets/common/themed_divider.dart';
import '../../../widgets/common/thumbnail_display.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../../../widgets/prompt/blocks/prompt_block_icons.dart';

const promptBlockLibraryWideHeaderHeight = 64.0;

/// 「全部块 / 文件夹A / 文件夹B」式位置路径（对应词库浮层的分类名位置）。
String promptBlockLocationLabel(
  PromptBlock block,
  List<PromptBlockFolder> folders,
  AppLocalizations l10n,
) {
  final byId = {for (final folder in folders) folder.id: folder};
  final names = <String>[];
  final visited = <String>{};
  var current = block.folderId == null ? null : byId[block.folderId];
  while (current != null && visited.add(current.id)) {
    names.insert(
      0,
      current.name.isEmpty
          ? l10n.promptBlockLibrary_unnamedFolder
          : current.name,
    );
    final parentId = current.parentId;
    current = parentId == null ? null : byId[parentId];
  }
  return [l10n.promptBlockLibrary_allBlocks, ...names].join(' / ');
}

/// 块详情两态共用版式：图片区 → 标题 → 内容 → 使用次数 → 位置路径 → 操作行。
///
/// 悬停预览与点击详情面板共用同一份布局；[actions] 为空即为纯预览态。
class PromptBlockDetailView extends StatelessWidget {
  const PromptBlockDetailView({
    super.key,
    required this.block,
    required this.displayTitle,
    required this.locationLabel,
    this.contentMaxLines = 8,
    this.actions = const <Widget>[],
  });

  final PromptBlock block;
  final String displayTitle;
  final String locationLabel;

  /// 内容行数上限；null = 完整展示（点击态），预览态由调用方给 8。
  final int? contentMaxLines;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final blockColor = promptBlockColorFromString(block.color);
    final content = block.content.isEmpty
        ? l10n.detail_noContent
        : block.content;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BlockDetailImage(block: block),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      displayTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (block.isFavorite)
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Icon(Icons.star, size: 18, color: blockColor),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              const ThemedDivider(height: 1),
              const SizedBox(height: 8),
              Text(
                content,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
                maxLines: contentMaxLines,
                overflow: contentMaxLines == null
                    ? null
                    : TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              _MetaRow(
                icon: Icons.repeat,
                label: l10n.promptBlockLibrary_useCount(block.useCount),
              ),
              const SizedBox(height: 6),
              _MetaRow(icon: Icons.folder_outlined, label: locationLabel),
              if (block.sourcePath != null) ...[
                const SizedBox(height: 6),
                _MetaRow(
                  icon: Icons.insert_drive_file_outlined,
                  label:
                      '${l10n.promptBlockLibrary_sourceFile}: '
                      '${_sourceFileName(block.sourcePath!)}',
                ),
                if (block.importedAt != null) ...[
                  const SizedBox(height: 6),
                  _MetaRow(
                    icon: Icons.access_time,
                    label:
                        '${l10n.promptBlockLibrary_importedAt}: '
                        '${_formatDateTime(block.importedAt!)}',
                  ),
                ],
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(spacing: 8, runSpacing: 8, children: actions),
              ],
            ],
          ),
        ),
      ],
    );
  }

  static String _sourceFileName(String sourcePath) {
    final normalized = sourcePath.replaceAll('\\', '/');
    final segments = normalized
        .split('/')
        .where((segment) => segment.isNotEmpty);
    return segments.isEmpty ? sourcePath : segments.last;
  }

  static String _formatDateTime(DateTime time) {
    final local = time.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.outline),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
          ),
        ),
      ],
    );
  }
}

/// 详情版式图片区：横图按裁剪参数横幅显示；竖图 letterbox 两侧留空；
/// 无图块 = 老样子（块图标 + 块颜色）。
class _BlockDetailImage extends StatefulWidget {
  const _BlockDetailImage({required this.block});

  final PromptBlock block;

  static const double landscapeHeight = 180;

  @override
  State<_BlockDetailImage> createState() => _BlockDetailImageState();
}

class _BlockDetailImageState extends State<_BlockDetailImage> {
  Size? _imageSize;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  @override
  void didUpdateWidget(covariant _BlockDetailImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.thumbnail != widget.block.thumbnail) {
      _loadImageSize();
    }
  }

  @override
  void dispose() {
    _requestId++;
    super.dispose();
  }

  Future<void> _loadImageSize() async {
    final requestId = ++_requestId;
    final path = widget.block.thumbnail;
    if (path == null) {
      if (mounted && requestId == _requestId) {
        setState(() => _imageSize = null);
      }
      return;
    }
    final size = await _readImageSize(path);
    if (!mounted || requestId != _requestId) return;
    setState(() => _imageSize = size);
  }

  Future<Size?> _readImageSize(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    try {
      final bytes = await file.readAsBytes();
      final info = img.findDecoderForData(bytes)?.startDecode(bytes);
      if (info == null) return null;
      return Size(info.width.toDouble(), info.height.toDouble());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final block = widget.block;
    final blockColor = promptBlockColorFromString(block.color);
    const radius = BorderRadius.vertical(top: Radius.circular(16));

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final thumbnail = block.thumbnail;

        if (thumbnail == null) {
          // 无图块：块图标 + 块颜色，与瀑布流无图卡同一观感。
          return Container(
            key: const Key('prompt-block-detail-image-placeholder'),
            width: width,
            height: 96,
            decoration: BoxDecoration(
              color: blockColor.withValues(alpha: 0.18),
              borderRadius: radius,
            ),
            child: Icon(
              promptBlockIconFromName(block.iconName),
              size: 40,
              color: blockColor,
            ),
          );
        }

        final size = _imageSize;
        if (size == null) {
          // 尺寸未读出前给固定高占位，避免 0 高首帧（BUG-3 教训）。
          return Container(
            key: const Key('prompt-block-detail-image-loading'),
            width: width,
            height: _BlockDetailImage.landscapeHeight,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: radius,
            ),
            child: const Center(
              child: Icon(
                Icons.image_outlined,
                size: 32,
                color: Colors.white38,
              ),
            ),
          );
        }

        if (size.height > size.width) {
          // 竖图：纵向更长、等比 letterbox，两侧留空不硬裁。
          final height = width * 1.25;
          final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
          return ClipRRect(
            key: const Key('prompt-block-detail-image-portrait'),
            borderRadius: radius,
            child: Container(
              width: width,
              height: height,
              color: Colors.grey.shade900,
              child: Image.file(
                File(thumbnail),
                width: width,
                height: height,
                fit: BoxFit.contain,
                cacheWidth: (width * devicePixelRatio).ceil(),
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }

        return ThumbnailDisplay(
          key: const Key('prompt-block-detail-image-landscape'),
          imagePath: thumbnail,
          offsetX: block.thumbnailOffsetX,
          offsetY: block.thumbnailOffsetY,
          scale: block.thumbnailScale,
          width: width,
          height: _BlockDetailImage.landscapeHeight,
          borderRadius: radius,
        );
      },
    );
  }
}

/// 悬停纯预览浮层：锚定卡片右侧（无空间则左侧），无任何操作按钮。
class PromptBlockPreviewOverlay extends StatelessWidget {
  const PromptBlockPreviewOverlay({
    super.key,
    required this.block,
    required this.folders,
    required this.layerLink,
    required this.cardSize,
    required this.cardPosition,
    required this.onDismiss,
  });

  final PromptBlock block;
  final List<PromptBlockFolder> folders;
  final LayerLink layerLink;
  final Size cardSize;
  final Offset cardPosition;
  final VoidCallback onDismiss;

  static const double previewWidth = 320;
  static const double previewMaxHeight = 460;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final screenSize = MediaQuery.of(context).size;

    final rightSpace = screenSize.width - (cardPosition.dx + cardSize.width);
    final showOnRight = rightSpace >= previewWidth + 16;

    return Positioned(
      key: const Key('prompt-block-preview-overlay'),
      left: 0,
      top: 0,
      child: CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        offset: Offset(showOnRight ? cardSize.width + 8 : -previewWidth - 8, 0),
        child: MouseRegion(
          onExit: (_) => onDismiss(),
          child: Material(
            elevation: 16,
            borderRadius: BorderRadius.circular(16),
            color: theme.colorScheme.surfaceContainerHigh,
            child: Container(
              width: previewWidth,
              constraints: const BoxConstraints(maxHeight: previewMaxHeight),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  child: PromptBlockDetailView(
                    key: const Key('prompt-block-preview-view'),
                    block: block,
                    displayTitle: block.title.isEmpty
                        ? l10n.promptBlockLibrary_unnamedBlock
                        : block.title,
                    locationLabel: promptBlockLocationLabel(
                      block,
                      folders,
                      l10n,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 悬停 800ms 出纯预览的包装器；指针按下（点击/拖拽起手）即抑制。
class PromptBlockHoverPreview extends StatefulWidget {
  const PromptBlockHoverPreview({
    super.key,
    required this.block,
    required this.folders,
    required this.child,
    this.enabled = true,
    this.delay = const Duration(milliseconds: 800),
  });

  final PromptBlock block;
  final List<PromptBlockFolder> folders;
  final bool enabled;
  final Widget child;
  final Duration delay;

  @override
  State<PromptBlockHoverPreview> createState() =>
      _PromptBlockHoverPreviewState();
}

class _PromptBlockHoverPreviewState extends State<PromptBlockHoverPreview> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _timer;
  bool _pressed = false;

  @override
  void didUpdateWidget(covariant PromptBlockHoverPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) _hidePreview();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    if (!widget.enabled || _pressed) return;
    _timer = Timer(widget.delay, _showPreview);
  }

  void _showPreview() {
    if (!mounted || !widget.enabled || _pressed || _overlayEntry != null) {
      return;
    }
    final renderBox = context.findRenderObject() as RenderBox;
    _overlayEntry = OverlayEntry(
      builder: (context) => PromptBlockPreviewOverlay(
        block: widget.block,
        folders: widget.folders,
        layerLink: _layerLink,
        cardSize: renderBox.size,
        cardPosition: renderBox.localToGlobal(Offset.zero),
        onDismiss: _hidePreview,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _hidePreview() {
    _timer?.cancel();
    _timer = null;
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        onEnter: (_) => _schedule(),
        onExit: (_) {
          _pressed = false;
          _hidePreview();
        },
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) {
            _pressed = true;
            _hidePreview();
          },
          onPointerUp: (_) => _pressed = false,
          onPointerCancel: (_) => _pressed = false,
          child: widget.child,
        ),
      ),
    );
  }
}

/// 点击态详情面板（右侧栏）：同款版式 + 操作按钮行。
/// 编辑走 [onEdit]（由调用方打开完整编辑弹窗），浮层/面板内不做编辑。
class PromptBlockDetailPanel extends StatelessWidget {
  const PromptBlockDetailPanel({
    super.key,
    required this.block,
    required this.folders,
    required this.onEdit,
    required this.onToggleFavorite,
    required this.onCopy,
    required this.onExport,
    required this.onDelete,
    required this.onCollapse,
  });

  final PromptBlock block;
  final List<PromptBlockFolder> folders;
  final VoidCallback onEdit;
  final VoidCallback onToggleFavorite;
  final VoidCallback onCopy;
  final VoidCallback onExport;
  final VoidCallback onDelete;
  final VoidCallback onCollapse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 280) return const SizedBox.expand();
        return Material(
          key: const Key('prompt-block-detail-panel'),
          color: theme.colorScheme.surface,
          child: Column(
            children: [
              SizedBox(
                key: const Key('prompt-block-detail-header'),
                height: promptBlockLibraryWideHeaderHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 19,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.promptBlockLibrary_details,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('prompt-block-detail-collapse'),
                        tooltip: l10n.common_collapse,
                        visualDensity: VisualDensity.compact,
                        onPressed: onCollapse,
                        icon: const Icon(Icons.keyboard_arrow_right),
                      ),
                    ],
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Material(
                    borderRadius: BorderRadius.circular(16),
                    color: theme.colorScheme.surfaceContainerHigh,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: PromptBlockDetailView(
                          key: const Key('prompt-block-detail-view'),
                          block: block,
                          displayTitle: block.title.isEmpty
                              ? l10n.promptBlockLibrary_unnamedBlock
                              : block.title,
                          locationLabel: promptBlockLocationLabel(
                            block,
                            folders,
                            l10n,
                          ),
                          contentMaxLines: null,
                          actions: [
                            FilledButton.icon(
                              key: const Key('prompt-block-detail-action-edit'),
                              onPressed: onEdit,
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: Text(l10n.common_edit),
                            ),
                            OutlinedButton.icon(
                              onPressed: onToggleFavorite,
                              icon: Icon(
                                block.isFavorite
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 18,
                              ),
                              label: Text(
                                block.isFavorite
                                    ? l10n.common_unfavorite
                                    : l10n.common_favorite,
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _copyContent,
                              icon: const Icon(Icons.copy_outlined, size: 18),
                              label: Text(l10n.common_copy),
                            ),
                            OutlinedButton.icon(
                              onPressed: onExport,
                              icon: const Icon(
                                Icons.file_upload_outlined,
                                size: 18,
                              ),
                              label: Text(
                                l10n.promptBlockLibrary_exportBlockAsTxt,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: onDelete,
                              icon: Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: theme.colorScheme.error,
                              ),
                              label: Text(
                                l10n.common_delete,
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _copyContent() async {
    await Clipboard.setData(ClipboardData(text: block.content));
    onCopy();
  }
}

/// 右栏收拢细条（点击展开详情面板）。
class PromptBlockDetailRailCollapsed extends StatelessWidget {
  const PromptBlockDetailRailCollapsed({super.key, required this.onExpand});

  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('prompt-block-detail-collapsed'),
        onTap: onExpand,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline,
              size: 19,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            ),
            const SizedBox(height: 8),
            RotatedBox(
              quarterTurns: 1,
              child: Text(
                context.l10n.promptBlockLibrary_details,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
