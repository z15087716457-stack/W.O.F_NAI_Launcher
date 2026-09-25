import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/services/titlebar_region_service.dart';
import '../../../core/services/window_material_service.dart';
import '../common/studio_glass_surface.dart';

/// FEAT-23 内置一体标题栏。
///
/// 挂在 `MaterialApp.router` 的 `builder` 上，以 Column 包住全部
/// 路由内容（splash / login / 主屏共享同一条栏）。栏高 36 逻辑像素，
/// 左侧 W.O.F logo + 标题，右侧自绘最小化/最大化/关闭三钮。
///
/// 原生窗口行为（拖拽移动、双击最大化、Aero Snap）不依赖 Flutter
/// 手势：Dart 侧把栏高与右侧按钮保留宽上报给 runner 的
/// `titlebar_region`，由 `WM_NCHITTEST` 命中返回 `HTCAPTION`。
///
/// 栏与内容之间有一条 0.5px `outlineVariant` 细线，默认透明，
/// 任意顶层滚动内容离开顶部（pixels > 0）时浮现。
class IntegratedTitleBarShell extends StatefulWidget {
  const IntegratedTitleBarShell({super.key, required this.child});

  final Widget child;

  /// 栏高（逻辑像素），与原生命中区换算共用。
  static const double barHeight = 36;

  /// 单个窗口按钮宽 ×3 = 右侧保留宽（逻辑像素）。
  static const double buttonWidth = 46;
  static const double reservedRight = buttonWidth * 3;

  @override
  State<IntegratedTitleBarShell> createState() =>
      _IntegratedTitleBarShellState();
}

class _IntegratedTitleBarShellState extends State<IntegratedTitleBarShell> {
  final ValueNotifier<bool> _contentScrolled = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _contentScrolled.dispose();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    // 只看最内层可滚动组件的偏移；对话框等嵌套滚动不触发。
    if (notification.depth == 0) {
      final scrolled = notification.metrics.pixels > 0;
      if (_contentScrolled.value != scrolled) {
        _contentScrolled.value = scrolled;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!TitleBarRegionService.isSupported) {
      return widget.child;
    }
    // Stack 布局：内容在下、标题栏最后画——按钮浮签（_CaptionButton 树内
    // 实现）需要盖在内容之上，Column 的「标题栏先画」顺序做不到。
    const double barH = IntegratedTitleBarShell.barHeight;
    return Stack(
      children: [
        // Content starts flush with the bar; a gap would expose raw acrylic.
        Positioned(
          top: barH,
          left: 0,
          right: 0,
          bottom: 0,
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScrollNotification,
            child: widget.child,
          ),
        ),
        const Positioned(top: 0, left: 0, right: 0, child: _TitleBar()),
        Positioned(
          top: barH,
          left: 0,
          right: 0,
          child: ValueListenableBuilder<bool>(
            valueListenable: _contentScrolled,
            builder: (context, scrolled, _) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: 0.5,
                color: scrolled
                    ? Theme.of(
                        context,
                      ).colorScheme.outlineVariant.withValues(alpha: 0.5)
                    : Colors.transparent,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TitleBar extends StatefulWidget {
  const _TitleBar();

  @override
  State<_TitleBar> createState() => _TitleBarState();
}

class _TitleBarState extends State<_TitleBar> with WindowListener {
  bool _isMaximized = false;
  (bool, bool)? _materialSettings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = (
      Theme.of(context).brightness == Brightness.dark,
      !MediaQuery.highContrastOf(context),
    );
    if (_materialSettings != settings) {
      _materialSettings = settings;
      unawaited(
        WindowMaterialService.configure(
          dark: settings.$1,
          enabled: settings.$2,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    TitleBarRegionService.retain();
    _reportRegion();
    unawaited(_syncMaximized());
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    // 引用计数：builder 重建时本实例会被「先挂新再拆旧」，计数不为
    // 零就不下发 clear，不会误清新实例上报的命中区。
    TitleBarRegionService.release();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    // 热重载后原生侧状态仍在，重新上报命中区。
    _reportRegion();
  }

  void _reportRegion() {
    unawaited(
      TitleBarRegionService.setRegion(
        barHeight: IntegratedTitleBarShell.barHeight,
        reservedRight: IntegratedTitleBarShell.reservedRight,
      ),
    );
  }

  Future<void> _syncMaximized() async {
    try {
      final maximized = await windowManager.isMaximized();
      if (mounted && maximized != _isMaximized) {
        setState(() => _isMaximized = maximized);
      }
    } on MissingPluginException {
      // 测试环境无原生实现，忽略。
    }
  }

  Future<void> _safeWindowCall(Future<void> Function() call) async {
    try {
      await call();
    } on MissingPluginException {
      // 测试环境无原生实现，忽略。
    }
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    // 首帧 l10n 可能未就绪（builder 层早于路由内容），用兜底文案。
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final content = SizedBox(
      height: IntegratedTitleBarShell.barHeight,
      child: Row(
        children: [
          const SizedBox(width: 12),
          Image.asset(
            'assets/images/wof_logo_block.png',
            height: 20,
            filterQuality: FilterQuality.medium,
            // 资产缺失/测试环境加载失败时退化为图标，不炸布局。
            errorBuilder: (context, error, stackTrace) =>
                Icon(Icons.auto_awesome, size: 18, color: colorScheme.primary),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'NAI Studio',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFFFFFF00),
                decorationStyle: TextDecorationStyle.double,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withValues(alpha: 0.9),
              ),
            ),
          ),
          _CaptionButton(
            icon: Icons.remove,
            tooltip: l10n?.titleBar_minimize ?? 'Minimize',
            onTap: () => _safeWindowCall(windowManager.minimize),
          ),
          _CaptionButton(
            icon: _isMaximized ? Icons.filter_none : Icons.crop_square,
            iconSize: _isMaximized ? 14 : 15,
            tooltip: _isMaximized
                ? (l10n?.titleBar_restore ?? 'Restore')
                : (l10n?.titleBar_maximize ?? 'Maximize'),
            onTap: () => _safeWindowCall(
              _isMaximized ? windowManager.unmaximize : windowManager.maximize,
            ),
          ),
          _CaptionButton(
            icon: Icons.close,
            tooltip: l10n?.titleBar_close ?? 'Close',
            isClose: true,
            // windowManager.close() 发 SC_CLOSE → WM_CLOSE；
            // setPreventClose(true) 下走 onWindowClose → 隐藏托盘。
            onTap: () => _safeWindowCall(windowManager.close),
          ),
        ],
      ),
    );
    return ValueListenableBuilder<bool>(
      valueListenable: WindowMaterialService.available,
      child: content,
      builder: (context, available, child) => StudioGlassSurface(
        // Caption hints extend below the title bar, outside Navigator overlays.
        clipBehavior: Clip.none,
        borderRadius: BorderRadius.zero,
        nativeBackdrop: available,
        child: child!,
      ),
    );
  }
}

/// Windows 风格扁平窗口按钮：悬停铺底色，关闭钮悬停变红。
class _CaptionButton extends StatefulWidget {
  const _CaptionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconSize = 16,
    this.isClose = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double iconSize;
  final bool isClose;

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _hover = false;
  bool _tipVisible = false;
  Timer? _tipTimer;

  void _setHover(bool hover) {
    setState(() => _hover = hover);
    _tipTimer?.cancel();
    if (hover) {
      _tipTimer = Timer(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _tipVisible = true);
      });
    } else if (_tipVisible) {
      setState(() => _tipVisible = false);
    }
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hovered = _hover;
    final Color bg = !hovered
        ? Colors.transparent
        : widget.isClose
        ? const Color(0xFFE81123)
        : colorScheme.onSurface.withValues(alpha: 0.08);
    final Color fg = widget.isClose && hovered
        ? Colors.white
        : colorScheme.onSurface.withValues(alpha: 0.9);
    // 注意：本组件挂在 MaterialApp.router builder 之上（Navigator/Overlay
    // 的兄弟），不能用 Tooltip——它在树内找不到 Overlay 会直接红屏。
    // 浮签用 Stack 内联实现。
    return Semantics(
      label: widget.tooltip,
      button: true,
      child: MouseRegion(
        onEnter: (_) => _setHover(true),
        onExit: (_) => _setHover(false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: IntegratedTitleBarShell.buttonWidth,
                height: IntegratedTitleBarShell.barHeight,
                color: bg,
                child: Icon(widget.icon, size: widget.iconSize, color: fg),
              ),
              if (_tipVisible)
                Positioned(
                  top: IntegratedTitleBarShell.barHeight + 4,
                  left: 0,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.inverseSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.tooltip,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onInverseSurface,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
