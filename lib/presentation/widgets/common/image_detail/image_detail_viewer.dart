import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';

import '../../../../core/shortcuts/shortcuts.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/image_share_sanitizer.dart';
import '../../../../core/utils/window_focus_tracker.dart';
import '../../../providers/share_image_settings_provider.dart';
import '../../../utils/clipboard_image.dart';
import '../../shortcuts/shortcuts.dart';
import '../app_toast.dart';
import '../prototype_typography_scope.dart';
import 'components/detail_image_page.dart';
import 'components/detail_metadata_panel.dart';
import 'components/viewer_filmstrip.dart';
import 'components/viewer_icon.dart';
import 'components/viewer_top_bar.dart';
import 'components/viewer_stage.dart';
import 'package:intl/intl.dart';
import 'image_detail_data.dart';

/// 图像详情查看器回调函数
class ImageDetailCallbacks {
  /// 收藏切换回调
  final void Function(ImageDetailData image)? onFavoriteToggle;

  /// 复用元数据回调。调用方完成全量导入后才返回。
  final Future<void> Function(ImageDetailData image)? onReuseMetadata;

  /// 保存回调
  final Future<void> Function(ImageDetailData image)? onSave;

  /// 复制图像回调
  final Future<void> Function(ImageDetailData image)? onCopyImage;

  /// 发送到图生图回调
  final Future<void> Function(ImageDetailData image)? onSendToImg2Img;

  /// 删除当前图片回调（返回是否删除成功；查看器据此从列表移除并翻页）
  final Future<bool> Function(ImageDetailData image)? onDelete;

  const ImageDetailCallbacks({
    this.onFavoriteToggle,
    this.onReuseMetadata,
    this.onSave,
    this.onCopyImage,
    this.onSendToImg2Img,
    this.onDelete,
  });
}

/// 通用图像详情查看器
///
/// 支持两种使用模式:
/// 1. 单图模式: 显示单张图片 + 元数据
/// 2. 多图模式: 支持翻页、缩略图导航
///
/// 功能特性:
/// - 左右滑动/箭头切换图片
/// - 支持缩放平移和双击缩放
/// - 底部缩略图条快速跳转
/// - 键盘导航支持
/// - 桌面端右侧元数据面板
class ImageDetailViewer extends ConsumerStatefulWidget {
  /// 图像数据列表
  final List<ImageDetailData> images;

  /// 初始显示索引
  final int initialIndex;

  /// 是否显示元数据面板（桌面端）
  final bool showMetadataPanel;

  /// 是否显示缩略图条
  final bool showThumbnails;

  /// 回调函数
  final ImageDetailCallbacks? callbacks;

  /// Hero 标签前缀
  final String? heroTagPrefix;

  final String? backLabel;

  const ImageDetailViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
    this.showMetadataPanel = true,
    this.showThumbnails = true,
    this.callbacks,
    this.heroTagPrefix,
    this.backLabel,
  });

  /// 打开图像详情查看器
  static Future<void> show(
    BuildContext context, {
    required List<ImageDetailData> images,
    int initialIndex = 0,
    bool showMetadataPanel = true,
    bool showThumbnails = true,
    ImageDetailCallbacks? callbacks,
    String? heroTagPrefix,
    String? backLabel,
  }) {
    final isWindows = Platform.isWindows;
    final transitionDuration = isWindows
        ? Duration.zero
        : const Duration(milliseconds: 300);
    final reverseTransitionDuration = isWindows
        ? Duration.zero
        : const Duration(milliseconds: 250);

    return Navigator.of(context).push(
      PageRouteBuilder(
        // Windows + 外部截图工具 + 焦点切换下，透明路由和快照过渡更容易触发
        // Flutter 引擎原生崩溃；Windows 走纯黑不透明且无动画路径。
        opaque: isWindows,
        barrierColor: Colors.black,
        allowSnapshotting: !isWindows,
        transitionDuration: transitionDuration,
        reverseTransitionDuration: reverseTransitionDuration,
        pageBuilder: (context, animation, secondaryAnimation) {
          final viewer = ImageDetailViewer(
            images: images,
            initialIndex: initialIndex,
            showMetadataPanel: showMetadataPanel,
            showThumbnails: showThumbnails,
            callbacks: callbacks,
            heroTagPrefix: heroTagPrefix,
            backLabel: backLabel,
          );
          if (isWindows) {
            return viewer;
          }
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: viewer,
          );
        },
      ),
    );
  }

  /// 打开单图模式（无缩略图条）
  static Future<void> showSingle(
    BuildContext context, {
    required ImageDetailData image,
    bool showMetadataPanel = true,
    ImageDetailCallbacks? callbacks,
    String? heroTag,
    String? backLabel,
  }) {
    return show(
      context,
      images: [image],
      initialIndex: 0,
      showMetadataPanel: showMetadataPanel,
      showThumbnails: false,
      callbacks: callbacks,
      heroTagPrefix: heroTag,
      backLabel: backLabel,
    );
  }

  @override
  ConsumerState<ImageDetailViewer> createState() => _ImageDetailViewerState();
}

class _ImageDetailViewerState extends ConsumerState<ImageDetailViewer> {
  static const Duration _windowsEscFocusCooldown = Duration(milliseconds: 1200);
  static const Duration _windowsEscBounceCooldown = Duration(seconds: 4);
  static const Duration _closeRequestThrottle = Duration(milliseconds: 700);

  late PageController _pageController;
  late int _currentIndex;

  /// 可变的图像列表副本：查看器内删除图片后从列表移除并翻页
  late List<ImageDetailData> _images;

  // Null follows the responsive default until the user explicitly toggles it.
  bool? _panelVisible;
  bool _narrowWindow = false;

  bool get _effectivePanelVisible =>
      widget.showMetadataPanel && (_panelVisible ?? !_narrowWindow);

  void _toggleInfoPanel() {
    if (widget.showMetadataPanel) {
      setState(() => _panelVisible = !_effectivePanelVisible);
    }
  }

  final _focusNode = FocusNode();
  final Map<int, TransformationController> _transformationControllers = {};
  bool _isClosing = false;
  DateTime? _lastCloseRequestedAt;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _images = List.of(widget.images);
    _pageController = PageController(initialPage: _currentIndex);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _goToPage(int index) {
    if (index < 0 || index >= _images.length) return;

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowLeft:
        _goToPage(_currentIndex - 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowRight:
        _goToPage(_currentIndex + 1);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.escape:
        _handleKeyboardCloseRequest();
        return KeyEventResult.handled;
      case LogicalKeyboardKey.home:
        _goToPage(0);
        return KeyEventResult.handled;
      case LogicalKeyboardKey.end:
        _goToPage(_images.length - 1);
        return KeyEventResult.handled;
      default:
        return KeyEventResult.ignored;
    }
  }

  void _handleKeyboardCloseRequest() {
    if (_narrowWindow && _effectivePanelVisible) {
      _toggleInfoPanel();
      return;
    }
    if (_shouldSuppressEscCloseOnWindows()) {
      final elapsedFocus = WindowFocusTracker.elapsedSinceFocus();
      final elapsedBlur = WindowFocusTracker.elapsedSinceBlur();
      AppLogger.w(
        'Suppressed ESC close after focus bounce '
            '(focus=${elapsedFocus?.inMilliseconds ?? -1}ms, '
            'blur=${elapsedBlur?.inMilliseconds ?? -1}ms)',
        'ImageDetailViewer',
      );
      return;
    }
    _requestClose('keyboard-escape');
  }

  bool _shouldSuppressEscCloseOnWindows() {
    if (!Platform.isWindows) return false;
    if (WindowFocusTracker.isWithinCooldown(_windowsEscFocusCooldown)) {
      return true;
    }
    return WindowFocusTracker.hadRecentFocusBounce(
      maxSinceFocus: _windowsEscBounceCooldown,
    );
  }

  void _requestClose(String reason) {
    if (!mounted || _isClosing) return;
    final now = DateTime.now();
    final lastCloseAt = _lastCloseRequestedAt;
    if (lastCloseAt != null &&
        now.difference(lastCloseAt) <= _closeRequestThrottle) {
      AppLogger.d(
        'Ignored duplicated close request: $reason',
        'ImageDetailViewer',
      );
      return;
    }
    _lastCloseRequestedAt = now;

    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      AppLogger.d(
        'Ignored close request on non-current route: $reason',
        'ImageDetailViewer',
      );
      return;
    }

    _isClosing = true;
    AppLogger.d('Viewer close requested: $reason', 'ImageDetailViewer');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).maybePop().whenComplete(() {
        if (mounted) {
          _isClosing = false;
        }
      });
    });
  }

  ImageDetailData get _currentImage => _images[_currentIndex];

  /// 获取当前图片的 TransformationController
  TransformationController get _currentTransformController {
    if (!_transformationControllers.containsKey(_currentIndex)) {
      _transformationControllers[_currentIndex] = TransformationController();
    }
    return _transformationControllers[_currentIndex]!;
  }

  /// 放大
  void _zoomIn() {
    final controller = _currentTransformController;
    final currentScale = controller.value.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.2).clamp(0.5, 4.0);

    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;

    final matrix = Matrix4.identity()
      ..translateByDouble(
        centerX - centerX * newScale,
        centerY - centerY * newScale,
        0,
        1,
      )
      ..scaleByDouble(newScale, newScale, newScale, 1);

    controller.value = matrix;
  }

  /// 缩小
  void _zoomOut() {
    final controller = _currentTransformController;
    final currentScale = controller.value.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.2).clamp(0.5, 4.0);

    final screenSize = MediaQuery.of(context).size;
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;

    final matrix = Matrix4.identity()
      ..translateByDouble(
        centerX - centerX * newScale,
        centerY - centerY * newScale,
        0,
        1,
      )
      ..scaleByDouble(newScale, newScale, newScale, 1);

    controller.value = matrix;
  }

  /// 重置缩放
  void _resetZoom() {
    _currentTransformController.value = Matrix4.identity();
  }

  /// 切换全屏
  void _toggleFullscreen() {
    // 使用窗口管理器切换全屏
    // 由于查看器是弹窗形式，关闭查看器即可
    _requestClose('toggle-fullscreen');
  }

  /// 切换收藏
  void _toggleFavorite() {
    if (widget.callbacks?.onFavoriteToggle != null) {
      widget.callbacks!.onFavoriteToggle!(_currentImage);
      // 触发重建以更新收藏按钮状态
      setState(() {});
    }
  }

  /// 复制 Prompt
  void _copyPrompt() {
    final metadata = _currentImage.metadata;
    final prompt = metadata?.prompt;
    if (prompt != null && prompt.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: prompt));
      if (context.mounted) {
        AppToast.success(context, context.l10n.toast_imagePromptCopied);
      }
    } else {
      if (context.mounted) {
        AppToast.warning(context, context.l10n.toast_imageHasNoPrompt);
      }
    }
  }

  /// 复用参数
  void _reuseGalleryParams() {
    if (widget.callbacks?.onReuseMetadata != null) {
      unawaited(_handleReuseMetadata(context));
    }
  }

  /// 删除图片
  ///
  /// 有 onDelete 回调时执行真删除：成功后从列表移除当前项，补位项自动
  /// 成为当前页（删的是最后一张则回退一张；列表清空则关闭查看器）
  Future<void> _deleteImage() async {
    final onDelete = widget.callbacks?.onDelete;
    if (onDelete == null) {
      // 无删除回调的调用方（如生成历史）：保留原提示行为
      if (context.mounted) {
        AppToast.info(context, context.l10n.toast_useDeleteButton);
      }
      return;
    }

    final deleted = await onDelete(_currentImage);
    if (!mounted || !deleted) return;

    if (_images.length <= 1) {
      _requestClose('delete-last-image');
      return;
    }

    // 当前页的缩放控制器可能仍被页面持有：先移出并整体前移 key，
    // 待重建完成后再 dispose，避免 use-after-dispose
    final removed = _transformationControllers.remove(_currentIndex);
    final shifted = <int, TransformationController>{};
    _transformationControllers.forEach(
      (k, v) => shifted[k > _currentIndex ? k - 1 : k] = v,
    );
    setState(() {
      _images.removeAt(_currentIndex);
      _transformationControllers
        ..clear()
        ..addAll(shifted);
      if (_currentIndex >= _images.length) {
        _currentIndex = _images.length - 1;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      removed?.dispose();
      if (!mounted || !_pageController.hasClients) return;
      // 删最后一张后 controller 页码越界，跳回有效页
      _pageController.jumpToPage(_currentIndex);
    });
  }

  @override
  Widget build(BuildContext context) {
    // 定义快捷键映射
    final shortcuts = <String, VoidCallback>{
      // 上一张
      ShortcutIds.previousImage: () => _goToPage(_currentIndex - 1),
      // 下一张
      ShortcutIds.nextImage: () => _goToPage(_currentIndex + 1),
      // 放大
      ShortcutIds.zoomIn: _zoomIn,
      // 缩小
      ShortcutIds.zoomOut: _zoomOut,
      // 重置缩放
      ShortcutIds.resetZoom: _resetZoom,
      // 全屏切换
      ShortcutIds.toggleFullscreen: _toggleFullscreen,
      // 关闭查看器
      ShortcutIds.closeViewer: _handleKeyboardCloseRequest,
      ShortcutIds.toggleInfoPanel: _toggleInfoPanel,
      // 收藏切换
      ShortcutIds.toggleFavorite: _toggleFavorite,
      // 复制 Prompt
      ShortcutIds.copyPrompt: _copyPrompt,
      // 复用参数
      ShortcutIds.reuseGalleryParams: _reuseGalleryParams,
      // 删除图片
      ShortcutIds.deleteImage: _deleteImage,
    };

    return PrototypeTypographyScope(
      family: 'HarmonyOS Sans SC',
      child: PageShortcuts(
        contextType: ShortcutContext.viewer,
        shortcuts: shortcuts,
        child: Focus(
          focusNode: _focusNode,
          onKeyEvent: _handleKeyEvent,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: LayoutBuilder(
              builder: (context, box) {
                _narrowWindow = ViewerStage.isNarrow(box.maxWidth);
                final visible = _effectivePanelVisible;
                final format = NumberFormat.decimalPattern(
                  Localizations.localeOf(context).toLanguageTag(),
                );
                return ViewerStage(
                  itemCount: _images.length,
                  currentIndex: _currentIndex,
                  pageController: _pageController,
                  onIndexChanged: _onPageChanged,
                  handleInfoShortcut: false,
                  onEscape: _handleKeyboardCloseRequest,
                  previousLabel: context.l10n.shortcut_action_previous_image,
                  nextLabel: context.l10n.shortcut_action_next_image,
                  pageBuilder: (context, index) {
                    final data = _images[index];
                    final heroTag =
                        widget.heroTagPrefix != null && index == _currentIndex
                        ? '${widget.heroTagPrefix}_${data.identifier}'
                        : null;
                    return DetailImagePage(
                      data: data,
                      heroTag: heroTag,
                      transformationController: _transformationControllers
                          .putIfAbsent(index, TransformationController.new),
                    );
                  },
                  topBar: ViewerTopBar(
                    backLabel: widget.backLabel ?? context.l10n.common_close,
                    onBack: () => _requestClose('top-bar-close'),
                    position: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: format.format(_currentIndex + 1),
                            style: const TextStyle(color: Colors.white),
                          ),
                          TextSpan(text: ' / ${format.format(_images.length)}'),
                        ],
                      ),
                    ),
                    trailing: _buildActionsMenu(context),
                    onZoomOut: _zoomOut,
                    onZoomIn: _zoomIn,
                    panelVisible: visible,
                    onTogglePanel: _toggleInfoPanel,
                    showPanelToggle: widget.showMetadataPanel,
                    reserveWindowButtons: _narrowWindow || !visible,
                  ),
                  filmstrip: widget.showThumbnails && _images.length > 1
                      ? ViewerFilmstrip(
                          items: [
                            for (final image in _images)
                              ViewerFilmstripItem(
                                thumbnail: image.getImageProvider(),
                                aspectRatio: image.aspectRatio,
                                groupDate: image.groupDate,
                              ),
                          ],
                          currentIndex: _currentIndex,
                          onTap: _goToPage,
                        )
                      : null,
                  panel: widget.showMetadataPanel
                      ? ColoredBox(
                          color: Theme.of(context).colorScheme.surface,
                          child: WindowPaneInset(
                            enabled: !_narrowWindow,
                            child: DetailMetadataPanel(
                              currentImage: _currentImage,
                              expandedWidth: _narrowWindow ? 340 : 360,
                              onClose: _toggleInfoPanel,
                            ),
                          ),
                        )
                      : null,
                  panelVisible: visible,
                  onTogglePanel: _toggleInfoPanel,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildActionsMenu(BuildContext context) {
    final l10n = context.l10n;
    final callbacks = widget.callbacks;
    final image = _currentImage;
    final items = <(String, VoidCallback)>[
      if (callbacks?.onSave != null)
        (l10n.common_save, () => unawaited(callbacks!.onSave!(image))),
      if (callbacks?.onReuseMetadata != null)
        (l10n.shortcut_action_reuse_params, _reuseGalleryParams),
      if (callbacks?.onSendToImg2Img != null)
        (
          l10n.detail_sendToImg2Img,
          () => unawaited(callbacks!.onSendToImg2Img!(image)),
        ),
      if (image.showCopyButton)
        (
          l10n.shortcut_action_copy_image,
          () => unawaited(_copyImageToClipboard(context)),
        ),
      if (callbacks?.onFavoriteToggle != null)
        (
          image.isFavorite ? l10n.common_unfavorite : l10n.common_favorite,
          _toggleFavorite,
        ),
      if (callbacks?.onDelete != null)
        (l10n.common_delete, () => unawaited(_deleteImage())),
    ];
    if (items.isEmpty) return null;
    return PopupMenuButton<int>(
      key: const Key('viewer-actions-menu'),
      tooltip: l10n.imageMenu_more,
      position: PopupMenuPosition.under,
      padding: EdgeInsets.zero,
      onSelected: (i) => items[i].$2(),
      itemBuilder: (_) => [
        for (var i = 0; i < items.length; i++)
          PopupMenuItem(value: i, height: 32, child: Text(items[i].$1)),
      ],
      child: const SizedBox(
        width: 30,
        height: 30,
        child: Center(child: ViewerIcon('more', strokeWidth: 3)),
      ),
    );
  }

  /// 复制图像到剪贴板
  Future<void> _copyImageToClipboard(BuildContext context) async {
    final l10n = context.l10n;
    try {
      final imageBytes = await _currentImage.getImageBytes();
      final fileName = _currentImage.fileInfo?.fileName ?? 'shared.png';
      final stripMetadata = ref
          .read(shareImageSettingsProvider)
          .effectiveStripMetadataForCopyAndDrag;
      final shareImage = await ImageShareSanitizer.prepareForCopyOrDrag(
        imageBytes,
        fileName: fileName,
        stripMetadata: stripMetadata,
      );

      // 复制到剪贴板（原 Windows 端走 PowerShell + System.Drawing）。
      // 统一规范化为 PNG，避免 jpg/webp 原始字节被当成 PNG 导致粘贴失败。
      await writeImageBytesToClipboardAsPng(shareImage.bytes);

      if (context.mounted) {
        AppToast.success(context, l10n.image_copiedToClipboard);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, l10n.image_copyFailed(e.toString()));
      }
    }
  }

  /// 处理复用元数据
  Future<void> _handleReuseMetadata(BuildContext context) async {
    final onReuseMetadata = widget.callbacks?.onReuseMetadata;
    if (onReuseMetadata == null) return;

    await onReuseMetadata(_currentImage);

    // 关闭图像详情页
    if (context.mounted) {
      _requestClose('reuse-metadata');
    }
  }

  @override
  void dispose() {
    for (final controller in _transformationControllers.values) {
      controller.dispose();
    }
    _transformationControllers.clear();
    _pageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
