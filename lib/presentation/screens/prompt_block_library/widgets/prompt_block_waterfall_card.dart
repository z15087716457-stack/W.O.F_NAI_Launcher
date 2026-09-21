import 'package:nai_launcher/presentation/widgets/common/studio_icon.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../../../data/models/prompt_block/prompt_block.dart';
import '../../../widgets/prompt/blocks/prompt_block_colors.dart';
import '../../../widgets/prompt/blocks/prompt_block_icons.dart';

/// 图区宽高比钳制范围：竖图封顶 4:5（高≈1.25×列宽），超宽图裁到
/// 16:9；区间内保持真实比例不裁。
const double _kWaterfallMinImageAspectRatio = 4 / 5;
const double _kWaterfallMaxImageAspectRatio = 16 / 9;

/// 块库瀑布流卡片（FEAT-1）。
///
/// - 有图块：缩略图按真实宽高比撑高，但钳制在 [4:5, 16:9]——竖图封顶
///   4:5（高度≈1.25×列宽，仍比横图高但不压没标题条），超宽全景轻微裁
///   边；框内 cover 裁剪并按块的 offsetX/Y 平移取景（scale 是 2.5:1 横幅
///   参数，瀑布流不套用）。尺寸先入静态缓存，首帧即给正确占位比例，不
///   出现 0 高闪烁——BUG-3 教训。
/// - 无图块：老样子长条（块颜色底+图标+标题），宽度撑满列宽。
class PromptBlockWaterfallCard extends StatefulWidget {
  const PromptBlockWaterfallCard({
    super.key,
    required this.block,
    required this.displayTitle,
    required this.onTap,
    this.selected = false,
    this.multiSelected = false,
    this.onSecondaryTap,
  });

  final PromptBlock block;
  final String displayTitle;
  final VoidCallback onTap;
  final bool selected;
  final bool multiSelected;
  final void Function(TapUpDetails details)? onSecondaryTap;

  /// 缩略图尺寸静态缓存：path → 解码尺寸（null = 已确认不可读）。
  /// 瀑布流卡片重建频繁，尺寸只应解析一次。
  static final Map<String, Size?> thumbnailSizeCache = <String, Size?>{};

  /// 测试用：清掉跨用例共享的尺寸缓存。
  @visibleForTesting
  static void clearSizeCache() => thumbnailSizeCache.clear();

  /// 解析缩略图像素尺寸；读不出来记 null（卡片回落无图长条）。
  static Future<Size?> resolveThumbnailSize(String path) async {
    if (thumbnailSizeCache.containsKey(path)) {
      return thumbnailSizeCache[path];
    }
    Size? size;
    try {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final info = img.findDecoderForData(bytes)?.startDecode(bytes);
        if (info != null && info.width > 0 && info.height > 0) {
          size = Size(info.width.toDouble(), info.height.toDouble());
        }
      }
    } catch (_) {
      size = null;
    }
    thumbnailSizeCache[path] = size;
    return size;
  }

  @override
  State<PromptBlockWaterfallCard> createState() =>
      _PromptBlockWaterfallCardState();
}

class _PromptBlockWaterfallCardState extends State<PromptBlockWaterfallCard> {
  int _sizeRequestId = 0;

  @override
  void initState() {
    super.initState();
    _ensureSize();
  }

  @override
  void didUpdateWidget(covariant PromptBlockWaterfallCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.thumbnail != widget.block.thumbnail) {
      _ensureSize();
    }
  }

  @override
  void dispose() {
    _sizeRequestId++;
    super.dispose();
  }

  void _ensureSize() {
    final path = widget.block.thumbnail;
    if (path == null ||
        PromptBlockWaterfallCard.thumbnailSizeCache.containsKey(path)) {
      return;
    }
    final requestId = ++_sizeRequestId;
    unawaited(
      PromptBlockWaterfallCard.resolveThumbnailSize(path).then((_) {
        if (mounted && requestId == _sizeRequestId) {
          setState(() {});
        }
      }),
    );
  }

  Size? get _imageSize {
    final path = widget.block.thumbnail;
    if (path == null) return null;
    return PromptBlockWaterfallCard.thumbnailSizeCache[path];
  }

  /// 有缩略图路径即走图片卡：尺寸解析中先按 4:3 占位（首帧非 0 高），
  /// 仅当缓存确认不可读时才回落无图长条。
  bool get _hasImage {
    final path = widget.block.thumbnail;
    if (path == null) return false;
    final cache = PromptBlockWaterfallCard.thumbnailSizeCache;
    return !(cache.containsKey(path) && cache[path] == null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blockColor = promptBlockColorFromString(widget.block.color);

    return GestureDetector(
      onSecondaryTapUp: widget.onSecondaryTap,
      child: Stack(
        children: [
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            elevation: widget.selected ? 2 : 0,
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: widget.selected
                    ? theme.colorScheme.primary
                    : blockColor.withValues(alpha: 0.55),
                width: widget.selected ? 1.5 : 1,
              ),
            ),
            child: InkWell(
              key: ValueKey('prompt-block-waterfall-body-${widget.block.id}'),
              onTap: widget.onTap,
              child: _hasImage
                  ? _buildImageCard(theme)
                  : _buildPlainBar(theme, blockColor),
            ),
          ),
          if (widget.multiSelected)
            Positioned(
              top: 6,
              right: 6,
              child: StudioIcon(
                Icons.check_circle,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
    );
  }

  /// 有图卡：缩略图按钳制后的宽高比（未读出时 4:3 占位）+ 素色标题条。
  Widget _buildImageCard(ThemeData theme) {
    final size = _imageSize;
    final block = widget.block;
    final ratio = size == null
        ? 4 / 3
        : (size.width / size.height).clamp(
            _kWaterfallMinImageAspectRatio,
            _kWaterfallMaxImageAspectRatio,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          key: ValueKey('prompt-block-waterfall-image-${block.id}'),
          aspectRatio: ratio,
          child: size == null
              ? _buildPlaceholder(theme)
              : Image.file(
                  File(block.thumbnail!),
                  // 框比真实比例窄时 cover 裁掉溢出边；offset 参数把取景窗
                  // 平移到用户在横幅裁剪里选定的位置（-1..1 → Alignment）。
                  fit: BoxFit.cover,
                  alignment: Alignment(
                    block.thumbnailOffsetX.clamp(-1.0, 1.0),
                    block.thumbnailOffsetY.clamp(-1.0, 1.0),
                  ),
                  filterQuality: FilterQuality.medium,
                  gaplessPlayback: true,
                  cacheWidth: (320 * MediaQuery.devicePixelRatioOf(context))
                      .round(),
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholder(theme),
                ),
        ),
        _buildTitleBar(theme),
      ],
    );
  }

  /// 无图块：老样子长条（块颜色底+图标+标题），宽度撑满列宽。
  Widget _buildPlainBar(ThemeData theme, Color blockColor) {
    return Container(
      key: ValueKey('prompt-block-waterfall-plain-${widget.block.id}'),
      color: blockColor.withValues(alpha: 0.16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          StudioIcon(
            promptBlockIconFromName(widget.block.iconName),
            size: 16,
            color: blockColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (widget.block.isFavorite) ...[
            const SizedBox(width: 6),
            StudioIcon(Icons.star, size: 15, color: blockColor),
          ],
        ],
      ),
    );
  }

  /// 素色标题条：图标 + 名称 + 块颜色小圆点（不整片染色）。
  Widget _buildTitleBar(ThemeData theme) {
    final blockColor = promptBlockColorFromString(widget.block.color);
    return Padding(
      key: ValueKey('prompt-block-waterfall-title-${widget.block.id}'),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Row(
        children: [
          StudioIcon(
            promptBlockIconFromName(widget.block.iconName),
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              widget.displayTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            key: ValueKey('prompt-block-waterfall-dot-${widget.block.id}'),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: blockColor,
              shape: BoxShape.circle,
            ),
          ),
          if (widget.block.isFavorite) ...[
            const SizedBox(width: 6),
            StudioIcon(Icons.star, size: 15, color: blockColor),
          ],
        ],
      ),
    );
  }

  /// 尺寸未读出/解码失败时的中性占位（固定 4:3，非 0 高）。
  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: StudioIcon(
          Icons.image_outlined,
          size: 28,
          color: theme.colorScheme.outline.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
