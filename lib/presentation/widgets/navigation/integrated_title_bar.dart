import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';

import '../../../core/services/titlebar_region_service.dart';
import '../../../core/services/window_material_service.dart';
import 'window_chrome_layout.dart';

/// Borderless window shell: page surfaces reach the top, with a fixed caption
/// cluster. Existing headers reserve its footprint through WindowChromeScope.
class IntegratedTitleBarShell extends StatefulWidget {
  const IntegratedTitleBarShell({
    super.key,
    required this.child,
    this.immersive = false,
    this.onToggleTheme,
  });

  final Widget child;
  final bool immersive;

  /// 沉浸模式下明暗切换按钮的回调；为 null 时不显示该按钮。
  final VoidCallback? onToggleTheme;

  /// 栏高（逻辑像素），与原生命中区换算共用。
  static const double barHeight = 36;

  /// 单个窗口按钮宽 ×3 = 右侧保留宽（逻辑像素）。
  static const double buttonWidth = 46;
  static const double reservedRight = buttonWidth * 3;

  /// 沉浸模式的明暗切换按钮宽，及其与窗口按钮之间的分隔（1px + 两侧 4px）。
  static const double themeButtonWidth = 40;
  static const double themeSeparatorWidth = 9;

  @override
  State<IntegratedTitleBarShell> createState() =>
      _IntegratedTitleBarShellState();
}

class _IntegratedTitleBarShellState extends State<IntegratedTitleBarShell> {
  @override
  Widget build(BuildContext context) {
    if (!TitleBarRegionService.isSupported) return widget.child;
    return Stack(
      children: [
        Positioned.fill(
          child: WindowChromeScope(
            enabled: !widget.immersive,
            child: widget.child,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: _TitleBar(
            immersive: widget.immersive,
            onToggleTheme: widget.onToggleTheme,
          ),
        ),
      ],
    );
  }
}

class _TitleBar extends StatefulWidget {
  const _TitleBar({required this.immersive, this.onToggleTheme});

  final bool immersive;
  final VoidCallback? onToggleTheme;

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
      false, // All window surfaces are now opaque, including the top edge.
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
  void didUpdateWidget(_TitleBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.immersive != widget.immersive ||
        _showsThemeButton(oldWidget) != _showsThemeButton(widget)) {
      _reportRegion();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    // 热重载后原生侧状态仍在，重新上报命中区。
    _reportRegion();
  }

  static bool _showsThemeButton(_TitleBar bar) =>
      bar.immersive && bar.onToggleTheme != null;

  void _reportRegion() {
    // 沉浸模式多出的明暗按钮也要留在可点击区，不能被当成拖拽区。
    final extra = _showsThemeButton(widget)
        ? IntegratedTitleBarShell.themeButtonWidth +
              IntegratedTitleBarShell.themeSeparatorWidth
        : 0.0;
    unawaited(
      TitleBarRegionService.setRegion(
        barHeight: widget.immersive ? IntegratedTitleBarShell.barHeight : 0,
        reservedRight: IntegratedTitleBarShell.reservedRight + extra,
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
    final captionButtons = <Widget>[
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
    ];
    final dark = colorScheme.brightness == Brightness.dark;
    return ColoredBox(
      color: colorScheme.surface,
      child: SizedBox(
        key: const Key('window-caption-controls'),
        height: IntegratedTitleBarShell.barHeight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showsThemeButton(widget)) ...[
              _CaptionButton(
                key: const Key('brand_appearance_toggle'),
                icon: dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                iconSize: 15,
                width: IntegratedTitleBarShell.themeButtonWidth,
                tooltip: dark
                    ? (l10n?.brand_switchToLight ?? 'Light')
                    : (l10n?.brand_switchToDark ?? 'Dark'),
                onTap: widget.onToggleTheme!,
              ),
              const SizedBox(
                width: IntegratedTitleBarShell.themeSeparatorWidth,
              ),
            ],
            ...captionButtons,
          ],
        ),
      ),
    );
  }
}

/// Windows 风格扁平窗口按钮：悬停铺底色，关闭钮悬停变红。
class _CaptionButton extends StatefulWidget {
  const _CaptionButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconSize = 16,
    this.isClose = false,
    this.width = IntegratedTitleBarShell.buttonWidth,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double iconSize;
  final bool isClose;
  final double width;

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
                width: widget.width,
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
