import 'presentation/widgets/common/update_capsule.dart';
import 'presentation/widgets/common/update_check_dialog.dart';
import 'package:nai_launcher/core/constants/brand.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:window_manager/window_manager.dart';

import 'core/shortcuts/default_shortcuts.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/guest_session_provider.dart';
import 'presentation/router/app_router.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/widgets/common/workspace_typography_scope.dart';
import 'presentation/providers/locale_provider.dart';
import 'presentation/providers/background_refresh_provider.dart';
import 'presentation/providers/krita/krita_bridge_notifier.dart';
import 'presentation/providers/notification_settings_provider.dart';
import 'presentation/providers/prompt_block_library_provider.dart';
import 'presentation/providers/subscription_provider.dart'
    hide anlasBalanceProvider;
import 'presentation/widgets/shortcuts/shortcut_aware_widget.dart';
import 'presentation/widgets/shortcuts/shortcut_help_dialog.dart';

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
  ProviderSubscription<dynamic>? _anlasWatcherSubscription;
  ProviderSubscription<dynamic>? _backgroundRefreshSubscription;
  ProviderSubscription<dynamic>? _kritaBridgeSubscription;
  ProviderSubscription<dynamic>? _generationCompletionSubscription;
  ProviderSubscription<dynamic>? _promptBlockLibrarySubscription;

  @override
  void initState() {
    super.initState();
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
      // 页面导航快捷键
      ShortcutIds.navigateToGeneration: () {
        router.go(AppRoutes.generation);
      },
      ShortcutIds.navigateToLocalGallery: () {
        router.go(AppRoutes.localGallery);
      },
      ShortcutIds.navigateToOnlineGallery: () {
        router.go(AppRoutes.onlineGallery);
      },
      ShortcutIds.navigateToTagLibrary: () {
        router.go(AppRoutes.promptBlockLibrary);
      },
      ShortcutIds.navigateToStatistics: () {
        router.go(AppRoutes.statistics);
      },
      ShortcutIds.navigateToSettings: () {
        router.go(AppRoutes.settings);
      },
      ShortcutIds.navigateToVibeLibrary: () {
        router.go(AppRoutes.vibeLibrary);
      },

      // 全局应用快捷键
      ShortcutIds.showShortcutHelp: () {
        final dialogContext = router.routerDelegate.navigatorKey.currentContext;
        if (dialogContext != null) ShortcutHelpDialog.show(dialogContext);
      },
      ShortcutIds.minimizeToTray: () {
        windowManager.hide();
      },
      ShortcutIds.quitApp: () {
        windowManager.close();
      },
      ShortcutIds.toggleTheme: () {
        ref.read(themeNotifierProvider.notifier).nextTheme();
      },
    };

    return AppBootstrapEffects(
      child: GlobalShortcuts(
        shortcuts: globalShortcuts,
        child: MaterialApp.router(
          title: Brand.name,
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

          // 工作区保持 100% 字号；设置页面在自身范围内独立缩放。
          builder: (context, child) {
            // builder 只下发窗口配置；窗口按钮在各页面内绘制，
            // 让 Navigator 的菜单、提示与对话框位于按钮上方。
            // child 作为普通子组件直传，保证 element 在 MaterialApp
            // rebuild 时原地更新、不拆树重建。
            return WorkspaceTypographyScope(
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
                child: child ?? const SizedBox.shrink(),
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
class _RouteAwareTitleBar extends StatefulWidget {
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
  State<_RouteAwareTitleBar> createState() => _RouteAwareTitleBarState();
}

class _RouteAwareTitleBarState extends State<_RouteAwareTitleBar> {
  late bool _immersive = _resolve();
  late double _captionHeight = _resolveCaptionHeight();
  bool _refreshQueued = false;
  bool _updateDialogOpen = false;

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
      _immersive = _resolve();
      _captionHeight = _resolveCaptionHeight();
    }
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_onRouteChanged);
    super.dispose();
  }

  bool _resolve() {
    final config = widget.router.routerDelegate.currentConfiguration;
    if (config.isEmpty) return widget.initialImmersive();
    return config.uri.path == AppRoutes.login;
  }

  double _resolveCaptionHeight() =>
      switch (widget.router.routerDelegate.currentConfiguration.uri.path) {
        AppRoutes.localGallery ||
        AppRoutes.onlineGallery ||
        AppRoutes.vibeLibrary ||
        AppRoutes.preciseRefLibrary ||
        AppRoutes.promptBlockLibrary => 62,
        _ => 36,
      };

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
    final next = _resolve();
    final height = _resolveCaptionHeight();
    if (next != _immersive || height != _captionHeight) {
      setState(() {
        _immersive = next;
        _captionHeight = height;
      });
    }
  }

  Future<void> _showUpdate() async {
    final navigatorContext =
        widget.router.routerDelegate.navigatorKey.currentContext;
    if (_updateDialogOpen || navigatorContext == null) return;
    _updateDialogOpen = true;
    try {
      await UpdateCheckDialog.show(navigatorContext);
    } finally {
      _updateDialogOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return UpdateAwareWindowShell(
      deferToRoute: true,
      immersive: _immersive,
      captionHeight: _captionHeight,
      onShowUpdate: _showUpdate,
      onToggleTheme: widget.onToggleTheme,
      child: widget.child,
    );
  }
}
