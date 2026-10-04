import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/thumbnail_cache_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/image_share_sanitizer.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../data/models/gallery/local_image_record.dart';
import '../../../data/services/thumbnail_service.dart';
import '../../providers/canvas_settings_provider.dart';
import '../../providers/local_gallery_provider.dart';
import '../../providers/share_image_settings_provider.dart';
import '../../utils/clipboard_image.dart';
import '../common/app_toast.dart';
import 'gallery_nai_versions.dart';
import 'local_image_context_menu.dart';
import '../common/studio_icons.dart';

/// 缩略图失败后的自动重试延迟（蓝图 P5：失败不再永久回退解码原图）。
const Duration _thumbnailFailureRetryDelay = Duration(seconds: 30);

/// 失败重试延迟的可覆写值（仅测试用；生产恒为 [_thumbnailFailureRetryDelay]）。
@visibleForTesting
Duration thumbnailFailureRetryDelayForTesting = _thumbnailFailureRetryDelay;

enum _ImageLoadState { idle, loading, loaded, error, failed }

/// 本地画廊图片卡片。
///
/// 平时只显示图片本身；悬停在底部渐变上显示版本、尺寸与收藏/复制/发送，
/// 左上角出现选择圈。查看中的图片有强调色内描边，多选中的图片再加实心勾。
class LocalImageCard extends ConsumerStatefulWidget {
  final LocalImageRecord record;
  final double width;
  final double height;

  /// 图片原始尺寸（来自索引；记录未加载时也能显示）
  final int? imageWidth;
  final int? imageHeight;

  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLongPress;
  final void Function(TapDownDetails)? onSecondaryTapDown;

  /// 点击左上角选择圈（进入多选并切换本图）
  final VoidCallback? onSelectionToggle;
  final bool isSelected;
  final bool isFocused;

  /// 多选进行中：所有卡片显示选择圈
  final bool selectionMode;
  final void Function(Offset anchor)? onFavoriteToggle;
  final Future<void> Function(LocalImageContextAction action)? onSendAction;
  final bool isKritaConnected;
  final bool isVisible;
  final int priority;

  /// 可选的拖拽包装器，用于将卡片内容包装在 DragItemWidget 中
  final Widget Function(Widget child)? dragWrapper;

  const LocalImageCard({
    super.key,
    required this.record,
    required this.width,
    required this.height,
    this.imageWidth,
    this.imageHeight,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.onSecondaryTapDown,
    this.onSelectionToggle,
    this.isSelected = false,
    this.isFocused = false,
    this.selectionMode = false,
    this.onFavoriteToggle,
    this.onSendAction,
    this.isKritaConnected = false,
    this.isVisible = false,
    this.priority = 5,
    this.dragWrapper,
  });

  @override
  ConsumerState<LocalImageCard> createState() => _LocalImageCardState();
}

class _LocalImageCardState extends ConsumerState<LocalImageCard> {
  static const _radius = 6.0;

  bool _isHovered = false;
  String? _displayPath;
  ThumbnailCacheService? _thumbnailService;
  _ImageLoadState _loadState = _ImageLoadState.idle;
  bool _isLoadingThumbnail = false;
  double _devicePixelRatio = 1.0;

  /// 最近一次请求的缩略图档位（用于检测尺寸/质量变化后是否需要换档重载）
  ThumbnailSize? _requestedSize;
  GalleryThumbnailQuality? _requestedQuality;

  /// 尺寸变化换档重载的防抖器：拖动大小滑块期间只记目标档位，
  /// 停止 ~300ms 后才真正换档重载，避免拖动过程反复入队。
  Timer? _reloadDebounceTimer;

  /// 缩略图失败后的延迟重试器（30s 后重新走一次完整加载）。
  Timer? _failureRetryTimer;

  /// 本次挂载是否已安排过自动重试（保证失败文件不会形成无界重试循环）。
  bool _failureRetryScheduled = false;

  /// 手动双击判定：单击立即生效（查看/选择），第二下在时限内再打开大图，
  /// 不挂 onDoubleTap 识别器——它会让每次单击等满 300ms。
  DateTime? _lastTapAt;
  Offset? _lastTapPosition;

  @override
  void initState() {
    super.initState();
    _initAndLoadThumbnail();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _devicePixelRatio = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
  }

  @override
  void didUpdateWidget(LocalImageCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.record.path != widget.record.path) {
      _displayPath = null;
      _loadState = _ImageLoadState.idle;
      _failureRetryScheduled = false;
      _failureRetryTimer?.cancel();
      unawaited(_loadThumbnail());
      return;
    }

    final widthChanged = oldWidget.width != widget.width;
    final sizeChanged =
        widthChanged &&
        _displayPath != null &&
        _pickSizeForCurrentWidth() != _requestedSize;

    if (oldWidget.priority != widget.priority ||
        (oldWidget.isVisible != widget.isVisible && widget.isVisible)) {
      if (_displayPath == null) unawaited(_loadThumbnail());
    }

    if (sizeChanged || (widthChanged && _displayPath == null)) {
      _scheduleDebouncedReload();
    }
  }

  void _scheduleDebouncedReload() {
    _reloadDebounceTimer?.cancel();
    _reloadDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final quality = ref.read(localGalleryNotifierProvider).thumbnailQuality;
      if (_pickSizeForCurrentWidth() != _requestedSize ||
          quality != _requestedQuality) {
        unawaited(_loadThumbnail());
      }
    });
  }

  ThumbnailSize _pickSizeForCurrentWidth() => resolveThumbnailTier(
    widget.width,
    _devicePixelRatio,
    ref.read(localGalleryNotifierProvider).thumbnailQuality,
  );

  Future<void> _initAndLoadThumbnail() async {
    _thumbnailService = ThumbnailCacheService.instance;
    await _thumbnailService!.init();
    // 滚动会成批卸载卡片：init() 等待期间卡片可能已卸载
    if (!mounted) return;
    await _loadThumbnail();
  }

  Future<void> _loadThumbnail() async {
    if (_isLoadingThumbnail) return;

    _isLoadingThumbnail = true;
    final path = widget.record.path;
    final fileName = path.split(Platform.pathSeparator).last;
    final quality = ref.read(localGalleryNotifierProvider).thumbnailQuality;
    final size = resolveThumbnailTier(widget.width, _devicePixelRatio, quality);
    _requestedSize = size;
    _requestedQuality = quality;

    try {
      setState(() => _loadState = _ImageLoadState.loading);

      final originalFile = File(path);
      if (!await originalFile.exists()) {
        AppLogger.e(
          '[CardLoad] Original file NOT FOUND: $path',
          'LocalImageCard',
        );
        if (mounted) setState(() => _loadState = _ImageLoadState.error);
        return;
      }

      final existingPath = await _thumbnailService?.getThumbnailPath(
        path,
        size: size,
      );
      // getThumbnailPath 非空即保证文件存在（内部已做异步 exists 校验）
      if (existingPath != null) {
        _failureRetryTimer?.cancel();
        _failureRetryScheduled = false;
        if (mounted && widget.record.path == path) {
          setState(() {
            _displayPath = existingPath;
            _loadState = _ImageLoadState.loaded;
          });
        }
        return;
      }

      final thumbnailService = ThumbnailService.instance;
      await thumbnailService.initialize();
      thumbnailService.updateVisibility(
        path,
        isVisible: widget.isVisible,
        priority: widget.priority,
      );

      final generatedPath = await thumbnailService.getThumbnail(
        path,
        size: size,
        priority: widget.priority,
      );

      if (!mounted || widget.record.path != path) return;

      if (generatedPath != null) {
        _failureRetryTimer?.cancel();
        _failureRetryScheduled = false;
        setState(() {
          _displayPath = generatedPath;
          _loadState = _ImageLoadState.loaded;
        });
      } else {
        // 生成失败/超时不再回退解码原图（数 MB 内存尖峰），
        // 保持轻量占位并挂一次延迟重试。
        _markThumbnailFailed();
      }
    } catch (e, stack) {
      AppLogger.e('[CardLoad] ERROR: $fileName', e, stack, 'LocalImageCard');
      _markThumbnailFailed();
    } finally {
      _isLoadingThumbnail = false;
      if (mounted) {
        final currentQuality = ref
            .read(localGalleryNotifierProvider)
            .thumbnailQuality;
        if (currentQuality != _requestedQuality ||
            _pickSizeForCurrentWidth() != _requestedSize) {
          _scheduleDebouncedReload();
        }
      }
    }
  }

  /// 缩略图失败：保持轻量占位态（不回退解码原图），挂一次延迟重试。
  ///
  /// 每次挂载只自动重试一次，避免失败文件形成无界重试循环；滚动重新挂载
  /// 会再走一次完整加载。延迟后重试先走 `getThumbnailPath` 快速路径。
  void _markThumbnailFailed() {
    if (!mounted) return;
    setState(() => _loadState = _ImageLoadState.failed);
    _scheduleFailureRetry();
  }

  void _scheduleFailureRetry() {
    if (_failureRetryScheduled) return;
    _failureRetryScheduled = true;
    _failureRetryTimer?.cancel();
    _failureRetryTimer = Timer(thumbnailFailureRetryDelayForTesting, () {
      if (!mounted) return;
      unawaited(_loadThumbnail());
    });
  }

  void _handleTapUp(TapUpDetails details) {
    final now = DateTime.now();
    final last = _lastTapAt;
    final lastPosition = _lastTapPosition;
    final isDouble =
        last != null &&
        lastPosition != null &&
        now.difference(last) <= kDoubleTapTimeout &&
        (details.globalPosition - lastPosition).distance <= kDoubleTapSlop;
    widget.onTap?.call();
    if (isDouble) {
      _lastTapAt = null;
      _lastTapPosition = null;
      widget.onDoubleTap?.call();
    } else {
      _lastTapAt = now;
      _lastTapPosition = details.globalPosition;
    }
  }

  Future<void> _copyImageToClipboard() async {
    try {
      final sourceFile = File(widget.record.path);
      if (!await sourceFile.exists()) {
        if (mounted) AppToast.error(context, context.l10n.gallery_fileMissing);
        return;
      }

      final stripMetadata = ref
          .read(shareImageSettingsProvider)
          .effectiveStripMetadataForCopyAndDrag;
      final sourceParts = sourceFile.path.split(RegExp(r'[/\\]'));
      final sourceName = sourceParts.isNotEmpty
          ? sourceParts.last
          : 'shared.png';
      final originalBytes = await sourceFile.readAsBytes();
      final shareImage = await ImageShareSanitizer.prepareForCopyOrDrag(
        originalBytes,
        fileName: sourceName,
        stripMetadata: stripMetadata,
      );

      // 统一规范化为 PNG，避免 jpg/webp 原始字节被当成 PNG 导致粘贴失败。
      await writeImageBytesToClipboardAsPng(shareImage.bytes);

      if (mounted) {
        AppToast.success(context, context.l10n.gallery_copiedToClipboard);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, context.l10n.gallery_copyFailed('$e'));
      }
    }
  }

  /// 以卡片左上角为锚点打开收藏菜单（默认出现在卡片左侧）
  void _openFavoriteMenu() {
    final cardBox = context.findRenderObject() as RenderBox?;
    if (cardBox == null || !cardBox.attached) return;
    widget.onFavoriteToggle?.call(cardBox.localToGlobal(Offset.zero));
  }

  Future<void> _showSendMenu(Offset globalPosition) async {
    const menuWidth = 320.0;
    var left = globalPosition.dx - menuWidth - 8;
    if (left < 8) left = globalPosition.dx + 8;
    final action = await LocalImageContextMenu.showSendActions(
      context,
      position: Offset(left, globalPosition.dy),
      isKritaConnected: widget.isKritaConnected,
    );
    if (action == null || !mounted) return;
    await widget.onSendAction?.call(action);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<GalleryThumbnailQuality>(
      localGalleryNotifierProvider.select((state) => state.thumbnailQuality),
      (previous, next) {
        if (previous == null || previous == next) return;
        _scheduleDebouncedReload();
      },
    );
    final quality = ref.watch(
      localGalleryNotifierProvider.select((state) => state.thumbnailQuality),
    );
    final reducedMotion =
        ref.watch(canvasReducedMotionNotifierProvider) ||
        MediaQuery.disableAnimationsOf(context);
    final duration = reducedMotion
        ? Duration.zero
        : const Duration(milliseconds: 140);
    final colors = Theme.of(context).colorScheme;
    final highlighted = widget.isSelected || widget.isFocused;
    final showCheck = _isHovered || widget.selectionMode || widget.isSelected;

    // 手势层只包图像；选择圈、收藏/复制/发送按钮是它的兄弟节点，
    // 不在卡片手势子树里，点击立即响应。
    final Widget image = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: _handleTapUp,
      onLongPress: widget.onLongPress,
      onSecondaryTapDown: widget.onSecondaryTapDown,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: colors.surfaceContainerHighest),
          _buildImageLayer(quality),
          if (widget.record.isFavorite && !_isHovered)
            const Positioned(
              top: 8,
              right: 8,
              child: IgnorePointer(
                child: Icon(
                  StudioIcons.galleryHeartFilled,
                  size: 16,
                  color: Colors.white,
                  shadows: [Shadow(color: Color(0x8C000000), blurRadius: 3)],
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 64,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _isHovered ? 1 : 0,
                duration: duration,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0x9E000000)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (highlighted)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  key: const Key('gallery-card-highlight'),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_radius),
                    border: Border.all(color: colors.primary, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_radius - 2),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(_radius),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            image,
            if (showCheck && widget.onSelectionToggle != null)
              Positioned(
                top: 8,
                left: 8,
                child: _SelectionCircle(
                  selected: widget.isSelected,
                  onTap: widget.onSelectionToggle!,
                ),
              ),
            if (_isHovered) _buildHoverBar(context),
          ],
        ),
      ),
    );

    if (widget.dragWrapper != null) {
      card = widget.dragWrapper!(card);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: card,
    );
  }

  Widget _buildHoverBar(BuildContext context) {
    final l10n = context.l10n;
    final metadata = widget.record.metadata;
    final version = GalleryNaiVersions.labelForModel(metadata?.effectiveModel);
    final width = widget.imageWidth ?? metadata?.width;
    final height = widget.imageHeight ?? metadata?.height;
    final compact = widget.width < 150;
    return Positioned(
      left: 10,
      right: 6,
      bottom: 6,
      child: Row(
        children: [
          if (version != null && !compact)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _FrostedChip(
                radius: 4,
                opacity: 0.2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  child: Text(
                    version,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          if (width != null && height != null && widget.width >= 190)
            Flexible(
              child: Text(
                '$width×$height',
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 11.5,
                ),
              ),
            ),
          const Spacer(),
          if (widget.onFavoriteToggle != null)
            _HoverAction(
              icon: widget.record.isFavorite
                  ? StudioIcons.galleryHeartFilled
                  : StudioIcons.galleryHeart,
              tooltip: l10n.common_favorite,
              onTap: (_) => _openFavoriteMenu(),
            ),
          if (!compact)
            _HoverAction(
              icon: StudioIcons.galleryCopy,
              tooltip: l10n.common_copy,
              onTap: (_) => unawaited(_copyImageToClipboard()),
            ),
          if (widget.onSendAction != null)
            _HoverAction(
              icon: StudioIcons.gallerySend,
              tooltip: l10n.localGallery_sendTo,
              onTap: (position) => unawaited(_showSendMenu(position)),
            ),
        ],
      ),
    );
  }

  Widget _buildImageLayer(GalleryThumbnailQuality quality) {
    final path = _displayPath;
    return switch (_loadState) {
      _ImageLoadState.error => _buildPlaceholderIcon(
        Icons.broken_image_outlined,
        onRetry: () => unawaited(_loadThumbnail()),
      ),
      _ImageLoadState.failed => _buildPlaceholderIcon(
        Icons.image_not_supported_outlined,
      ),
      _ when path != null => _buildOptimizedImage(path, quality),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildPlaceholderIcon(IconData icon, {VoidCallback? onRetry}) {
    final colors = Theme.of(context).colorScheme;
    final iconWidget = Icon(icon, size: 24, color: colors.onSurfaceVariant);
    return Center(
      child: onRetry == null
          ? iconWidget
          : Tooltip(
              message: context.l10n.common_retry,
              child: IconButton(onPressed: onRetry, icon: iconWidget),
            ),
    );
  }

  Widget _buildOptimizedImage(
    String imagePath,
    GalleryThumbnailQuality quality,
  ) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final multiplier = quality == GalleryThumbnailQuality.hd ? 1.5 : 1.0;
    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      cacheWidth: (widget.width * pixelRatio * multiplier).toInt(),
      cacheHeight: (widget.height * pixelRatio * multiplier).toInt(),
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return const SizedBox.shrink();
      },
      errorBuilder: (context, error, stackTrace) {
        AppLogger.w(
          'Image load failed, attempting fallback: $imagePath',
          'LocalImageCard',
        );
        if (imagePath != widget.record.path) {
          return Image.file(
            File(widget.record.path),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) =>
                _buildPlaceholderIcon(Icons.broken_image_outlined),
          );
        }
        return _buildPlaceholderIcon(Icons.broken_image_outlined);
      },
    );
  }

  @override
  void dispose() {
    _reloadDebounceTimer?.cancel();
    _failureRetryTimer?.cancel();
    super.dispose();
  }
}

/// 左上角选择圈：未选为白描边半透明圈，选中为实心强调色加白勾。
class _SelectionCircle extends StatelessWidget {
  const _SelectionCircle({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        key: const Key('gallery-card-select'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? colors.primary
                : Colors.black.withValues(alpha: 0.2),
            border: Border.all(
              color: selected
                  ? colors.primary
                  : Colors.white.withValues(alpha: 0.95),
              width: 1.5,
            ),
          ),
          child: selected
              ? Icon(
                  StudioIcons.galleryCheckBold,
                  size: 14,
                  color: colors.onPrimary,
                )
              : null,
        ),
      ),
    );
  }
}

/// 悬停底栏的小方按钮（半透明白底，白色图标）。
class _HoverAction extends StatelessWidget {
  const _HoverAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final ValueChanged<Offset> onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 500),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => onTap(details.globalPosition),
          child: _FrostedChip(
            radius: 5,
            opacity: 0.16,
            child: SizedBox(
              width: 26,
              height: 26,
              child: Icon(icon, size: 14, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

/// 悬停底栏的磨砂小块：模糊下方图像后叠半透明白底（原型 blur 6px）。
class _FrostedChip extends StatelessWidget {
  const _FrostedChip({
    required this.radius,
    required this.opacity,
    required this.child,
  });

  final double radius;
  final double opacity;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: DecoratedBox(
          key: const Key('gallery-card-frosted'),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: opacity),
            borderRadius: borderRadius,
          ),
          child: child,
        ),
      ),
    );
  }
}
