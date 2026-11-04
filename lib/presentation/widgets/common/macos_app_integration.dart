import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Brightness, Theme;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../core/services/desktop_app_shutdown_service.dart';
import '../../../l10n/app_localizations.dart';

/// Mac 原生菜单和 Dart 之间的通道：应用菜单「设置…」（⌘,）点了要打开设置页。
/// 原生一侧在 macos/Runner/AppDelegate.swift 的 showSettings(_:)。
const macOSAppMenuChannel = MethodChannel('com.nailauncher/app_menu');

/// Keeps the system title bar in the same palette as the Flutter workspace.
/// The native Agent control lives in that existing row, outside the page.
class MacOSNativeTitleBar extends StatefulWidget {
  const MacOSNativeTitleBar({
    super.key,
    required this.child,
    this.agentExpanded = false,
    this.onToggleAgent,
  });

  final bool agentExpanded;
  final VoidCallback? onToggleAgent;
  final Widget child;

  @override
  State<MacOSNativeTitleBar> createState() => _MacOSNativeTitleBarState();
}

class _MacOSNativeTitleBarState extends State<MacOSNativeTitleBar> {
  static const _channel = MethodChannel('com.wof.naiStudio/window_chrome');
  static _MacOSNativeTitleBarState? _current;
  ({int surface, bool dark, String? agent, bool expanded})? _published;

  @override
  void initState() {
    super.initState();
    _current = this;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'toggleAgent') _current?.widget.onToggleAgent?.call();
      return null;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _publish();
  }

  @override
  void didUpdateWidget(MacOSNativeTitleBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _publish();
  }

  void _publish() {
    final theme = Theme.of(context);
    final next = (
      surface: theme.colorScheme.surface.toARGB32(),
      dark: theme.brightness == Brightness.dark,
      agent: widget.onToggleAgent == null
          ? null
          : AppLocalizations.of(context)?.naiAgent_title,
      expanded: widget.agentExpanded,
    );
    if (next == _published) return;
    _published = next;
    unawaited(
      _configure({
        'surface': next.surface,
        'dark': next.dark,
        'agent': next.agent,
        'expanded': next.expanded,
      }),
    );
  }

  Future<void> _configure(Map<String, Object?> arguments) async {
    try {
      await _channel.invokeMethod<void>('configure', arguments);
    } on MissingPluginException {
      // Only the main macOS runner owns the native title bar.
    }
  }

  @override
  void dispose() {
    if (identical(_current, this)) _current = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Mac 系统集成：
/// - 应用菜单「设置…」→ [onOpenSettings]
/// - 系统发来的退出请求（菜单「退出」⌘Q、程序坞「退出」、注销关机）走
///   [onExitRequested]，默认是 W.O.F 托盘「退出」用的正规关闭流程（先关数据库、Hive 再退）。
///   原来 Dart 没接这个请求，从菜单退出时不关数据库。
///
/// 只在 macOS 上生效，其他平台原样返回 [child]。
class MacOSAppIntegration extends StatefulWidget {
  const MacOSAppIntegration({
    super.key,
    required this.onOpenSettings,
    this.onExitRequested = DesktopAppShutdownService.prepareForTermination,
    required this.child,
  });

  final VoidCallback onOpenSettings;
  final Future<void> Function() onExitRequested;
  final Widget child;

  @override
  State<MacOSAppIntegration> createState() => _MacOSAppIntegrationState();
}

class _MacOSAppIntegrationState extends State<MacOSAppIntegration> {
  // 启动时这个组件会先后建两份（启动页、主界面），旧的 dispose 晚于新的 initState。
  // 所以通道处理函数是静态的、销毁时不清掉，消息转给当前在树上的那一份。
  static _MacOSAppIntegrationState? _current;

  AppLifecycleListener? _lifecycle;

  bool get _isMac => defaultTargetPlatform == TargetPlatform.macOS;

  @override
  void initState() {
    super.initState();
    if (!_isMac) return;
    _current = this;
    macOSAppMenuChannel.setMethodCallHandler(_dispatchMenuCall);
    _lifecycle = AppLifecycleListener(onExitRequested: _handleExitRequest);
  }

  static Future<Object?> _dispatchMenuCall(MethodCall call) async {
    final state = _current;
    if (state == null || !state.mounted) return null;
    if (call.method == 'openSettings') state.widget.onOpenSettings();
    return null;
  }

  Future<AppExitResponse> _handleExitRequest() async {
    // AppKit waits for this response before completing its pending request.
    await widget.onExitRequested();
    return AppExitResponse.exit;
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    if (identical(_current, this)) _current = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
