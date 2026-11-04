import 'dart:async';

import 'core/services/app_visibility.dart';
import 'core/services/desktop_app_shutdown_service.dart';
import 'core/utils/studio_sandbox.dart';
import 'presentation/widgets/navigation/integrated_title_bar.dart';
import 'presentation/widgets/branding/entry_language_button.dart';
import 'package:nai_launcher/core/constants/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';

import 'core/shortcuts/default_shortcuts.dart';
import 'core/utils/desktop_platform.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/nai_agent/nai_agent_window_controller.dart';
import 'presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'presentation/widgets/common/app_toast.dart';
import 'presentation/providers/guest_session_provider.dart';
import 'presentation/providers/new_badge_provider.dart';
import 'presentation/router/app_router.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/widgets/common/workspace_typography_scope.dart';
import 'presentation/widgets/common/workspace_text_scale_scope.dart';
import 'presentation/widgets/common/numpad_editing_shortcuts.dart';
import 'presentation/widgets/common/text_editing_shortcuts.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/background_refresh_provider.dart';
import 'presentation/providers/krita/krita_bridge_notifier.dart';
import 'presentation/providers/notification_settings_provider.dart';
import 'presentation/providers/prompt_block_library_provider.dart';
import 'presentation/providers/subscription_provider.dart'
    hide anlasBalanceProvider;
import 'presentation/widgets/shortcuts/shortcut_aware_widget.dart';
import 'presentation/widgets/shortcuts/shortcut_help_dialog.dart';
import 'presentation/wiring/nai_agent_generation_host.dart';
import 'presentation/widgets/common/macos_app_integration.dart';
import 'presentation/widgets/common/studio_scroll_behavior.dart';
import 'presentation/wiring/clipboard_history_paste.dart';
import 'presentation/wiring/floating_resource_window.dart';
import 'presentation/wiring/floating_resource_windows_host.dart';
import 'presentation/providers/floating_resource_windows_provider.dart';
import 'presentation/wiring/resource_window_wiring.dart';

double windowCaptionHeightForRoute(String path) => switch (path) {
  AppRoutes.localGallery => 62,
  AppRoutes.onlineGallery ||
  AppRoutes.vibeLibrary ||
  AppRoutes.preciseRefLibrary ||
  AppRoutes.promptBlockLibrary => 61,
  _ => 36,
};

/// 全局副作用挂载层
///
/// 只负责启动需要常驻的 provider 监听，不让它们把根部 MaterialApp 一起拖着重建。
class AppBootstrapEffects extends ConsumerStatefulWidget {
  final Widget child;
  final ProviderListenable<dynamic>? anlasWatcher;
  final ProviderListenable<dynamic>? backgroundRefresh;
  final ProviderListenable<dynamic>? kritaBridge;
  final ProviderListenable<dynamic>? generationCompletionWatcher;
  final ProviderListenable<dynamic>? promptBlockLibrary;

  const AppBootstrapEffects({
    super.key,
    required this.child,
    this.anlasWatcher,
    this.backgroundRefresh,
    this.kritaBridge,
    this.generationCompletionWatcher,
    this.promptBlockLibrary,
  });

  @override
  ConsumerState<AppBootstrapEffects> createState() =>
      _AppBootstrapEffectsState();
}

class _AppBootstrapEffectsState extends ConsumerState<AppBootstrapEffects> {
  final _clipboardHistoryPaste = ClipboardHistoryPaste();
  ProviderSubscription<dynamic>? _anlasWatcherSubscription;
  ProviderSubscription<dynamic>? _backgroundRefreshSubscription;
  ProviderSubscription<dynamic>? _kritaBridgeSubscription;
  ProviderSubscription<dynamic>? _generationCompletionSubscription;
  ProviderSubscription<dynamic>? _promptBlockLibrarySubscription;

  @override
  void initState() {
    super.initState();
    _clipboardHistoryPaste.register();
    _anlasWatcherSubscription = ref.listenManual(
      widget.anlasWatcher ?? anlasBalanceWatcherProvider,
      (_, __) {},
    );
    _backgroundRefreshSubscription = ref.listenManual(
      widget.backgroundRefresh ?? backgroundRefreshNotifierProvider,
      (_, __) {},
    );
    _kritaBridgeSubscription = ref.listenManual(
      widget.kritaBridge ?? kritaBridgeNotifierProvider,
      (_, __) {},
    );
    _generationCompletionSubscription = ref.listenManual(
      widget.generationCompletionWatcher ?? generationCompletionWatcherProvider,
      (_, __) {},
    );
    // 启动即加载块库（含旧词库迁移），保证别名解析、预设查找等
    // 同步路径拿到已加载快照而不是空表。
    _promptBlockLibrarySubscription = ref.listenManual(
      widget.promptBlockLibrary ?? promptBlockLibraryNotifierProvider,
      (_, __) {},
    );
  }

  @override
  void dispose() {
    _clipboardHistoryPaste.dispose();
    _anlasWatcherSubscription?.close();
    _backgroundRefreshSubscription?.close();
    _kritaBridgeSubscription?.close();
    _generationCompletionSubscription?.close();
    _promptBlockLibrarySubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// NAI Launcher 主应用
/// 预加载已在 SplashScreen 完成
class NAILauncherApp extends ConsumerWidget {
  const NAILauncherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = ref.watch(themeNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);
    final router = ref.watch(appRouterProvider);

    // 定义全局快捷键映射
    final globalShortcuts = <String, VoidCallback>{
      ShortcutIds.openResourceWindow: () {
        unawaited(
          ref
              .read(resourceWindowOpenerProvider)
              .open(FloatingResourceKind.gallery),
        );
      },

      // 全局应用快捷键
      ShortcutIds.showShortcutHelp: () {
        final dialogContext = router.routerDelegate.navigatorKey.currentContext;
        if (dialogContext != null) ShortcutHelpDialog.show(dialogContext);
      },
      ShortcutIds.minimizeToTray: () {
        AppVisibilitySources.instance.markHidden();
        windowManager.hide();
      },
      ShortcutIds.quitApp: () {
        // windowManager.close() 在这里等于藏到托盘，「退出应用」并不会退出；
        // 走托盘「退出」同一套关闭流程
        unawaited(DesktopAppShutdownService.shutdownAndExit(0));
      },
      ShortcutIds.toggleTheme: () {
        ref.read(themeNotifierProvider.notifier).nextTheme();
      },
    };

    return AppBootstrapEffects(
      child: GlobalShortcuts(
        shortcuts: globalShortcuts,
        child: MaterialApp.router(
          title: studioWindowTitle(Brand.name),
          debugShowCheckedModeBanner: false,

          theme: ref.watch(studioLightThemeProvider),
          darkTheme: ref.watch(studioDarkThemeProvider),
          themeMode: brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          // 国际化
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,

          // 路由
          routerConfig: router,
          scrollBehavior: const StudioScrollBehavior(),

          // 工作区保持 100% 字号；设置页面在自身范围内独立缩放。
          builder: (context, child) {
            // builder 只下发窗口配置；窗口按钮在各页面内绘制，
            // 让 Navigator 的菜单、提示与对话框位于按钮上方。
            // child 作为普通子组件直传，保证 element 在 MaterialApp
            // rebuild 时原地更新、不拆树重建。
            // macOS：菜单「设置…」和系统退出请求（⌘Q、程序坞、注销关机）
            return MacOSAppIntegration(
              onOpenSettings: () => router.go(AppRoutes.settings),
              child: WorkspaceTextScaleHost(
                child: NaiAgentIntegrationScope(
                  child: WorkspaceTypographyScope(
                    child: _RouteAwareTitleBar(
                      router: router,
                      // 首个路由解析前按认证状态先行判断，未登录时不先闪 Logo 标题栏；
                      // 认证尚未建立（例如测试里）时不在这里触发它
                      initialImmersive: () =>
                          ref.exists(authNotifierProvider) &&
                          !ref.read(authNotifierProvider).isAuthenticated &&
                          !ref.read(guestSessionNotifierProvider),
                      onToggleTheme: () =>
                          ref.read(themeNotifierProvider.notifier).nextTheme(),
                      child: NumpadEditingShortcuts(
                        child: TextEditingShortcuts(
                          child: NewBadgeScope(
                            child: FloatingResourceWindowsHost(
                              builder: floatingResourceWindowBuilder,
                              child: ResourceWindowBridge(
                                child: child ?? const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 登录页使用沉浸标题栏（页面底色、只留窗口按钮），其余路由用玻璃栏。
///
/// 路由在首次构建期间就会通知变化，此时本组件正处于构建阶段之外的
/// 祖先位置，不能立即 setState，留到这一帧结束后再刷新。
class _RouteAwareTitleBar extends ConsumerStatefulWidget {
  const _RouteAwareTitleBar({
    required this.router,
    required this.initialImmersive,
    required this.onToggleTheme,
    required this.child,
  });

  final GoRouter router;
  final bool Function() initialImmersive;
  final VoidCallback onToggleTheme;
  final Widget child;

  @override
  ConsumerState<_RouteAwareTitleBar> createState() =>
      _RouteAwareTitleBarState();
}

class _RouteAwareTitleBarState extends ConsumerState<_RouteAwareTitleBar> {
  late String _path = _currentPath();
  bool _refreshQueued = false;

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_onRouteChanged);
  }

  @override
  void didUpdateWidget(_RouteAwareTitleBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router != widget.router) {
      oldWidget.router.routerDelegate.removeListener(_onRouteChanged);
      widget.router.routerDelegate.addListener(_onRouteChanged);
      _path = _currentPath();
    }
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  String _currentPath() {
    final config = widget.router.routerDelegate.currentConfiguration;
    return config.isEmpty ? '' : config.uri.path;
  }

  bool _supportsAgent(String path) =>
      path == AppRoutes.home ||
      path == AppRoutes.generation ||
      path == AppRoutes.styleExplore;

  Future<void> _toggleNativeAgent() async {
    if (!_supportsAgent(_currentPath())) return;
    try {
      await ref.read(naiAgentWindowControllerProvider).toggle();
    } catch (_) {
      if (!mounted) return;
      AppToast.errorOnOverlay(
        widget.router.routerDelegate.navigatorKey.currentState?.overlay,
        AppLocalizations.of(context)!.naiAgent_error,
      );
    }
  }

  void _onRouteChanged() {
    final building =
        SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks;
    if (!building) {
      _refresh();
    } else if (!_refreshQueued) {
      _refreshQueued = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _refreshQueued = false;
        _refresh();
      });
    }
  }

  void _refresh() {
    if (!mounted) return;
    final next = _currentPath();
    if (next != _path) setState(() => _path = next);
  }

  @override
  Widget build(BuildContext context) {
    final immersive = _path.isEmpty
        ? widget.initialImmersive()
        : _path == AppRoutes.login;
    final agent = usesMacOSConventions && _supportsAgent(_path);
    return IntegratedTitleBarShell(
      deferToRoute: true,
      immersive: immersive,
      captionHeight: windowCaptionHeightForRoute(_path),
      onToggleTheme: widget.onToggleTheme,
      entryLanguageButton: immersive ? const EntryLanguageButton() : null,
      onToggleNativeAgent: agent ? () => unawaited(_toggleNativeAgent()) : null,
      nativeAgentExpanded:
          agent &&
          (ref.watch(naiAgentWindowControllerProvider).presentationExpanded ??
              ref.watch(naiAgentUiPreferencesProvider).settings.panelExpanded),
      child: widget.child,
    );
  }
}
