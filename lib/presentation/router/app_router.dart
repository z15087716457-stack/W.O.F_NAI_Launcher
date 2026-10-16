import 'dart:async';
import '../wiring/style_explore_platform.dart';
import '../widgets/navigation/integrated_title_bar.dart';
import 'package:nai_launcher/presentation/widgets/navigation/window_chrome_layout.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

import '../../core/utils/localization_extension.dart';
import '../../core/shortcuts/default_shortcuts.dart';
import '../providers/auth_provider.dart' show authNotifierProvider, AuthStatus;
import '../providers/guest_session_provider.dart';
import '../providers/update_provider.dart';
import '../screens/auth/login_screen.dart';
import '../wiring/generation_wiring.dart';
import '../wiring/generation_viewer_wiring.dart';
import '../screens/local_gallery/local_gallery_screen.dart';
import '../wiring/image_viewer_session.dart';
import '../wiring/image_viewer_wiring.dart';
import '../wiring/online_wiring.dart';
import '../wiring/settings/settings_wiring.dart';
import '../screens/settings/widgets/settings_typography_scope.dart';
import '../screens/slideshow_screen.dart';
import '../screens/image_comparison_screen.dart';
import '../wiring/statistics_wiring.dart';
import 'gallery_navigation_request.dart';
import '../wiring/style_explore_wiring.dart';
import '../wiring/refs_library_wiring.dart';
import '../wiring/blocks_library_wiring.dart';

import '../screens/tag_wiki/tag_wiki_screen.dart';
import '../widgets/common/update_notice_banner.dart';
import '../widgets/drop/global_drop_handler.dart';
import '../wiring/nav_wiring.dart';
import '../providers/nav_activity_provider.dart';

import '../widgets/shortcuts/shortcut_aware_widget.dart';
import '../widgets/shortcuts/shortcut_help_dialog.dart';
import 'app_branch.dart';

part 'app_router.g.dart';

/// Navigator Keys for StatefulShellRoute branches
final _homeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _localGalleryKey = GlobalKey<NavigatorState>(debugLabel: 'localGallery');
final _onlineGalleryKey = GlobalKey<NavigatorState>(
  debugLabel: 'onlineGallery',
);
final _settingsKey = GlobalKey<NavigatorState>(debugLabel: 'settings');
final _statisticsKey = GlobalKey<NavigatorState>(debugLabel: 'statistics');
final _vibeLibraryKey = GlobalKey<NavigatorState>(debugLabel: 'vibeLibrary');
final _preciseRefLibraryKey = GlobalKey<NavigatorState>(
  debugLabel: 'preciseRefLibrary',
);
final _promptBlockLibraryKey = GlobalKey<NavigatorState>(
  debugLabel: 'promptBlockLibrary',
);
final _styleExploreKey = GlobalKey<NavigatorState>(debugLabel: 'styleExplore');
final _tagWikiKey = GlobalKey<NavigatorState>(debugLabel: 'tagWiki');

/// 路由路径常量
class PromptBlockLibraryLocation {
  PromptBlockLibraryLocation(this.id);
  final String id;
}

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String home = '/';
  static const String generation = '/generation';
  static const String localGallery = '/local-gallery';
  static const String onlineGallery = '/online-gallery';
  static const String settings = '/settings';
  static const String slideshow = '/slideshow';
  static const String comparison = '/comparison';
  static const String statistics = '/statistics';
  static const String tagLibraryPage = '/tag-library';
  static const String vibeLibrary = '/vibe-library';
  static const String preciseRefLibrary = '/precise-ref-library';
  static const String promptBlockLibrary = '/prompt-block-library';
  static const String styleExplore = '/style-explore';
  static const String tagWiki = '/tag-wiki';
}

String? appAuthRedirect({
  required AuthStatus authStatus,
  required bool isAuthenticated,
  required bool isGuest,
  required String matchedLocation,
}) {
  final isLoading =
      authStatus == AuthStatus.loading || authStatus == AuthStatus.initial;
  final isLoggingIn = matchedLocation == AppRoutes.login;

  if (isLoading) return null;
  if ((isAuthenticated || isGuest) && isLoggingIn) return AppRoutes.home;
  if (!isAuthenticated && !isGuest && !isLoggingIn) return AppRoutes.login;
  return null;
}

/// 应用路由 Provider
///
/// 使用 ref.listen 监听认证状态变化并通知 GoRouter
/// 避免使用 ref.watch 导致 GoRouter 实例频繁重建
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // 创建 ValueNotifier 作为 refreshListenable
  // 初始值无关紧要，只要变化就会触发重定向
  final authStateNotifier = ValueNotifier<int>(0);

  // 监听认证和游客会话变化，触发 GoRouter 刷新
  ref.listen(authNotifierProvider.select((value) => value.status), (
    previous,
    next,
  ) {
    authStateNotifier.value++;
  });
  ref.listen(guestSessionNotifierProvider, (previous, next) {
    authStateNotifier.value++;
  });

  // 当 provider 被销毁时清理
  ref.onDispose(() {
    authStateNotifier.dispose();
  });

  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,

    // 使用 refreshListenable 监听状态变化，触发 redirect 重新评估
    refreshListenable: authStateNotifier,

    // 重定向逻辑
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      return appAuthRedirect(
        authStatus: authState.status,
        isAuthenticated: authState.isAuthenticated,
        isGuest: ref.read(guestSessionNotifierProvider),
        matchedLocation: state.matchedLocation,
      );
    },

    // 路由配置
    routes: [
      // 登录页 - 使用自定义页面过渡动画
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        pageBuilder: (context, state) => _buildFadeSlidePage(
          state: state,
          child: const LoginScreen(),
          slideOffset: const Offset(0.0, 0.05),
        ),
      ),

      // 旧词库页路由：重定向到 Prompt 块库（保留深链/旧快捷键目标兼容）
      GoRoute(
        path: AppRoutes.tagLibraryPage,
        redirect: (context, state) => AppRoutes.promptBlockLibrary,
      ),

      // 主页 Shell - 使用 StatefulShellRoute 实现混合保活
      StatefulShellRoute(
        navigatorContainerBuilder: (context, navigationShell, children) {
          return MainShell(
            navigationShell: navigationShell,
            children: children,
          );
        },
        builder: (context, state, navigationShell) => navigationShell,
        branches: [
          // Branch 0: 生成页 (首页) - 不保活
          StatefulShellBranch(
            navigatorKey: _homeKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                pageBuilder: (context, state) => _buildFadePage(
                  state: state,
                  child: const GenerationRoute(),
                ),
              ),
              GoRoute(
                path: AppRoutes.generation,
                name: 'generation',
                pageBuilder: (context, state) => _buildFadePage(
                  state: state,
                  child: const GenerationRoute(),
                ),
                routes: [
                  GoRoute(
                    path: 'viewer',
                    builder: (context, state) =>
                        state.extra is GenerationViewerRequest
                        ? GenerationViewerWiring(
                            request: state.extra as GenerationViewerRequest,
                          )
                        : const GenerationRoute(),
                  ),
                ],
              ),
            ],
          ),

          // Branch 1: 本地画廊 - 保活
          StatefulShellBranch(
            navigatorKey: _localGalleryKey,
            routes: [
              GoRoute(
                path: AppRoutes.localGallery,
                name: 'localGallery',
                builder: (context, state) => WindowChromePage(
                  child: LocalGalleryScreen(
                    navigationRequest: state.extra is GalleryNavigationRequest
                        ? state.extra as GalleryNavigationRequest
                        : null,
                  ),
                ),
                routes: [
                  // 幻灯片子路由
                  GoRoute(
                    path: AppRoutes.slideshow,
                    name: 'slideshow',
                    pageBuilder: (context, state) {
                      // 从查询参数获取初始索引
                      final initialIndex =
                          int.tryParse(
                            state.uri.queryParameters['initialIndex'] ?? '0',
                          ) ??
                          0;

                      return MaterialPage(
                        key: state.pageKey,
                        child: WindowChromePage(
                          child: SlideshowScreen(
                            images: const [],
                            initialIndex: initialIndex,
                          ),
                        ),
                      );
                    },
                  ),
                  // 图片对比子路由
                  GoRoute(
                    path: AppRoutes.comparison,
                    name: 'comparison',
                    pageBuilder: (context, state) {
                      return MaterialPage(
                        key: state.pageKey,
                        child: const WindowChromePage(
                          child: ImageComparisonScreen(images: []),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),

          // Branch 2: 在线画廊 - 保活
          StatefulShellBranch(
            navigatorKey: _onlineGalleryKey,
            routes: [
              GoRoute(
                path: AppRoutes.onlineGallery,
                name: 'onlineGallery',
                builder: (context, state) =>
                    const WindowChromePage(child: OnlineWiring()),
              ),
            ],
          ),

          // Branch 3: 设置页 - 不保活
          StatefulShellBranch(
            navigatorKey: _settingsKey,
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                name: 'settings',
                builder: (context, state) => WindowChromePage(
                  child: SettingsTypographyScope(
                    child: SettingsWiring(
                      initialPage: settingsPageFromUri(state.uri),
                      initialQuery: state.uri.queryParameters['q'] ?? '',
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Branch 4: 统计页 - 不保活
          StatefulShellBranch(
            navigatorKey: _statisticsKey,
            routes: [
              GoRoute(
                path: AppRoutes.statistics,
                name: 'statistics',
                builder: (context, state) =>
                    const WindowChromePage(child: StatisticsWiring()),
              ),
            ],
          ),

          // Branch 5: Vibe库页 - 保活
          StatefulShellBranch(
            navigatorKey: _vibeLibraryKey,
            routes: [
              GoRoute(
                path: AppRoutes.vibeLibrary,
                name: 'vibeLibrary',
                builder: (context, state) =>
                    const WindowChromePage(child: VibeLibraryWiring()),
              ),
            ],
          ),

          // Branch 6: 精准参考库页 - 保活
          StatefulShellBranch(
            navigatorKey: _preciseRefLibraryKey,
            routes: [
              GoRoute(
                path: AppRoutes.preciseRefLibrary,
                name: 'preciseRefLibrary',
                builder: (context, state) =>
                    const WindowChromePage(child: PreciseRefLibraryWiring()),
              ),
            ],
          ),

          // Branch 7: 全局 Prompt 块库 - 保活
          StatefulShellBranch(
            navigatorKey: _promptBlockLibraryKey,
            routes: [
              GoRoute(
                path: AppRoutes.promptBlockLibrary,
                name: 'promptBlockLibrary',
                builder: (context, state) => WindowChromePage(
                  child: BlocksLibraryWiring(
                    initialBlockId: (state.extra is PromptBlockLibraryLocation)
                        ? (state.extra as PromptBlockLibraryLocation).id
                        : null,
                    initialRequest: state.extra,
                  ),
                ),
              ),
            ],
          ),

          // Branch 8: 画风探索页 - 不保活（工作区状态在 provider 层保持）
          StatefulShellBranch(
            navigatorKey: _styleExploreKey,
            routes: [
              GoRoute(
                path: AppRoutes.styleExplore,
                name: 'styleExplore',
                builder: (context, state) => const StyleExploreWiring(),
              ),
            ],
          ),
          // Branch 9: 标签百科 - 保活，维持阅读位置和目录展开状态。
          StatefulShellBranch(
            navigatorKey: _tagWikiKey,
            routes: [
              GoRoute(
                path: AppRoutes.tagWiki,
                name: 'tagWiki',
                builder: (context, state) => WindowChromePage(
                  child: TagWikiScreen(
                    initialTag: state.uri.queryParameters['tag'],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],

    // 错误页面
    errorBuilder: (context, state) => WindowChromePage(
      child: Scaffold(
        body: Center(
          child: Text(context.l10n.router_pageNotFound('${state.error}')),
        ),
      ),
    ),
  );
}

/// 主布局 Shell - 包含导航 (StatefulShellRoute 版本)
///
/// 使用混合保活策略：
/// - 画廊页面（本地/在线）使用 Offstage 保活
/// - Vibe库、精准参考库和 Prompt 块库使用 Offstage 保活
/// - 其他页面不保活
class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  const MainShell({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int? _previousIndex;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.navigationShell.currentIndex;
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentIndex = widget.navigationShell.currentIndex;

    // 页面切换检测（已移除互锁逻辑，不再需要重置标志）
    if (_previousIndex != null && _previousIndex != currentIndex) {
      // 不同页面间的图像详情页不再互锁
      final session = ref.read(imageViewerSessionProvider);
      if (session != null) {
        scheduleMicrotask(() {
          if (!mounted || ref.read(imageViewerSessionProvider) != session) {
            return;
          }
          ref.read(imageViewerSessionProvider.notifier).state = null;
          ref.read(imageViewerWindowProvider.notifier).state = (
            fullscreen: false,
            captionOverStage: false,
          );
        });
      }
    }
    _previousIndex = currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    final activity = ref.read(navActivityProvider.notifier);
    if (activity.currentBranch != AppBranch.values[currentIndex]) {
      Future.microtask(() {
        if (mounted) {
          activity.setCurrentBranch(
            AppBranch.values[widget.navigationShell.currentIndex],
          );
        }
      });
    }

    // 构建混合保活内容栈
    // - 画廊、Vibe 库、精准参考库和块库使用 Offstage 保活
    // - 其他索引不保活，切换时销毁重建
    // 索引随 AppBranch 枚举顺序联动，插入/删除分支时无需改字面量
    const keepAliveBranches = {
      AppBranch.localGallery,
      AppBranch.onlineGallery,
      AppBranch.vibeLibrary,
      AppBranch.preciseRefLibrary,
      AppBranch.promptBlockLibrary,
      AppBranch.tagWiki,
    };
    final contentStack = IndexedStack(
      index: currentIndex,
      children: widget.children.asMap().entries.map((entry) {
        final index = entry.key;
        final child = entry.value;
        final isActive = index == currentIndex;

        // 保活页面始终保持在树中，通过 TickerMode 控制动画
        if (keepAliveBranches.any((branch) => branch.index == index)) {
          return TickerMode(enabled: isActive, child: child);
        }

        // 其他索引：非活动时显示空容器（不保活）
        if (!isActive) {
          return const SizedBox.shrink();
        }
        return child;
      }).toList(),
    );

    // 使用 GlobalDropHandler 包装内容，支持拖拽图片到任意页面
    final dropEnabledContent = ImageViewerHost(
      child: GlobalDropHandler(child: contentStack),
    );

    // 定义全局快捷键动作映射（使用 ShortcutIds 常量）
    final globalShortcuts = <String, VoidCallback>{
      for (final entry in globalNavigationShortcutBranches.entries)
        entry.key: () {
          ref.read(navActivityProvider.notifier).setCurrentBranch(entry.value);
          widget.navigationShell.goBranch(entry.value.index);
        },
      // 显示快捷键帮助
      ShortcutIds.showShortcutHelp: () {
        ShortcutHelpDialog.show(context);
      },
    };

    // 使用 ShortcutAwareWidget 包装全局快捷键
    final shortcutEnabledContent = ShortcutAwareWidget(
      contextType: ShortcutContext.global,
      shortcuts: globalShortcuts,
      autofocus: true,
      child: dropEnabledContent,
    );

    if (ref.watch(imageViewerWindowProvider).fullscreen ||
        currentIndex == AppBranch.styleExplore.index &&
            ref.watch(styleExploreWindowProvider).fullscreen ||
        currentIndex == AppBranch.generation.index &&
            ref.watch(generationViewerWindowProvider).fullscreen) {
      return shortcutEnabledContent;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // 桌面端：使用侧边导航
        if (constraints.maxWidth >= 800) {
          return DesktopShell(
            navigationShell: widget.navigationShell,
            content: shortcutEnabledContent,
          );
        }

        // 移动端：使用底部导航
        return MobileShell(
          navigationShell: widget.navigationShell,
          content: shortcutEnabledContent,
        );
      },
    );
  }
}

/// 桌面端布局
class DesktopShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  final Widget content;

  const DesktopShell({
    super.key,
    required this.navigationShell,
    required this.content,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: NavWiring(
        // 侧边导航栏
        navigationShell: navigationShell,
        // 主内容区
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              clipBehavior: Clip.none,
              children: [
                content,
                if (!WindowChromeScope.activeOf(context))
                  const Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: UpdateNoticeBanner(),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// 移动端布局
class MobileShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  final Widget content;

  const MobileShell({
    super.key,
    required this.navigationShell,
    required this.content,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showUpdateBadge = ref.watch(
      updateStateProvider.select((state) => state.hasNewVersion),
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              content,
              Positioned(
                top: WindowChromeScope.activeOf(context) ? 36 : 0,
                left: 0,
                right: 0,
                child: const UpdateNoticeBanner(),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: mobileNavigationIndexForBranch(
          navigationShell.currentIndex,
        ),
        onDestinationSelected: (index) => _onNavigate(index),
        destinations: [
          NavigationDestination(
            icon: const Icon(StudioIcons.generation),
            selectedIcon: const Icon(StudioIcons.generation),
            label: context.l10n.nav_generate,
          ),
          NavigationDestination(
            icon: const Icon(StudioIcons.localGallery),
            selectedIcon: const Icon(StudioIcons.localGallery),
            label: context.l10n.nav_gallery,
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: showUpdateBadge,
              smallSize: 7,
              child: const Icon(StudioIcons.settings),
            ),
            selectedIcon: Badge(
              isLabelVisible: showUpdateBadge,
              smallSize: 7,
              child: const Icon(StudioIcons.settings),
            ),
            label: context.l10n.nav_settings,
          ),
        ],
      ),
    );
  }

  /// 映射 mobile navigation index 到 branch index
  void _onNavigate(int mobileIndex) {
    final branch =
        mobileIndex >= 0 && mobileIndex < mobileNavigationBranches.length
        ? mobileNavigationBranches[mobileIndex]
        : AppBranch.generation;
    navigationShell.goBranch(branch.index);
  }
}

// ============================================
// 页面过渡动画辅助方法
// ============================================

const _defaultTransitionDuration = Duration(milliseconds: 300);
const _defaultCurve = Curves.easeOutCubic;

/// 构建淡入页面过渡
CustomTransitionPage<void> _buildFadePage({
  required GoRouterState state,
  required Widget child,
  Duration duration = _defaultTransitionDuration,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // GenerationRoute owns captions and the Agent entry, including fullscreen.
      return FadeTransition(
        opacity: CurveTween(curve: _defaultCurve).animate(animation),
        child: child,
      );
    },
  );
}

/// 构建淡入+滑动页面过渡
CustomTransitionPage<void> _buildFadeSlidePage({
  required GoRouterState state,
  required Widget child,
  Offset slideOffset = Offset.zero,
  Duration duration = _defaultTransitionDuration,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurveTween(
        curve: _defaultCurve,
      ).animate(animation);
      return WindowChromePage(
        child: FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: slideOffset,
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        ),
      );
    },
  );
}
