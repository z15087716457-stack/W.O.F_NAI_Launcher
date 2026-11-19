import 'dart:async';
import 'dart:io';

import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/localization_extension.dart';
import '../../data/models/gallery/local_image_record.dart';

const int _maxSlideshowImageDimension = 4096;

ImageProvider buildSlideshowImageProvider(String path) {
  return ResizeImage(
    FileImage(File(path)),
    width: _maxSlideshowImageDimension,
    height: _maxSlideshowImageDimension,
    policy: ResizeImagePolicy.fit,
  );
}

/// 幻灯片屏幕
///
/// 全屏显示图片，支持键盘导航和自动播放
class SlideshowScreen extends ConsumerStatefulWidget {
  /// 图片列表
  final List<LocalImageRecord> images;

  /// 初始显示的图片索引
  final int initialIndex;

  const SlideshowScreen({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends ConsumerState<SlideshowScreen> {
  late int _currentIndex;
  final _focusNode = FocusNode();
  Timer? _autoPlayTimer;
  bool get _isPlaying => _autoPlayTimer != null;
  static const Duration _autoPlayInterval = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.images.isEmpty
        ? 0
        : widget.initialIndex.clamp(0, widget.images.length - 1);
  }

  @override
  void didUpdateWidget(covariant SlideshowScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.images.isEmpty) {
      _currentIndex = 0;
      _autoPlayTimer?.cancel();
      _autoPlayTimer = null;
    } else {
      final target = oldWidget.initialIndex == widget.initialIndex
          ? _currentIndex
          : widget.initialIndex;
      _currentIndex = target.clamp(0, widget.images.length - 1);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    super.dispose();
  }

  void _toggleAutoPlay() {
    if (widget.images.isEmpty) return;
    setState(() {
      if (_isPlaying) {
        _autoPlayTimer!.cancel();
        _autoPlayTimer = null;
      } else {
        _autoPlayTimer = Timer.periodic(
          _autoPlayInterval,
          (_) => _step(1, manual: false),
        );
      }
    });
  }

  void _step(int delta, {bool manual = true}) {
    if (widget.images.isEmpty) return;
    setState(() {
      if (manual) {
        _autoPlayTimer?.cancel();
        _autoPlayTimer = null;
      }
      _currentIndex = (_currentIndex + delta) % widget.images.length;
    });
  }

  /// 处理键盘事件
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _step(-1);
        break;
      case LogicalKeyboardKey.arrowRight:
        _step(1);
        break;
      case LogicalKeyboardKey.space:
        _toggleAutoPlay();
        break;
      case LogicalKeyboardKey.escape:
        Navigator.of(context).pop();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    // 无图片时显示提示
    if (widget.images.isEmpty) {
      return Scaffold(
        appBar: AppBar(leading: const CloseButton()),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: 64,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.slideshow_noImages,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentImage = widget.images[_currentIndex];

    return KeyboardListener(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 主图片显示区域
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image(
                  image: buildSlideshowImageProvider(currentImage.path),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: theme.colorScheme.surface,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            l10n.localGallery_progressiveLoadError,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

            // 顶部信息栏
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // 图片计数
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '${_currentIndex + 1} ${l10n.slideshow_of} ${widget.images.length}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // 退出按钮
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      tooltip: l10n.slideshow_exit,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),

            // 底部控制栏
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    // 上一张按钮
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      tooltip: l10n.slideshow_previous,
                      onPressed: () => _step(-1),
                    ),
                    const Spacer(),
                    // 播放/暂停按钮
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      tooltip: _isPlaying
                          ? l10n.slideshow_pause
                          : l10n.slideshow_play,
                      onPressed: _toggleAutoPlay,
                    ),
                    const Spacer(),
                    // 下一张按钮
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
                      tooltip: l10n.slideshow_next,
                      onPressed: () => _step(1),
                    ),
                  ],
                ),
              ),
            ),

            // 键盘提示（仅桌面端显示，项目仅发布 Windows）
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    l10n.slideshow_keyboardHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
