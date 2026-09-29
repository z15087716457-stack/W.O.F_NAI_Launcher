import 'package:nai_launcher/presentation/widgets/common/studio_animated_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

import '../../../data/models/auth/saved_account.dart';
import '../../providers/account_manager_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/layout_state_provider.dart';
import '../../providers/update_provider.dart';
import '../../router/app_branch.dart';
import '../auth/account_avatar.dart';
import '../auth/account_switch_helper.dart';
import '../auth/add_account_dialog.dart';
import '../auth/subscription_expiry_text.dart';

class MainNavRail extends ConsumerWidget {
  static const double collapsedWidth = 60;
  static const double expandedWidth = 196;
  static const Duration animationDuration = Duration(milliseconds: 240);

  final StatefulNavigationShell navigationShell;

  const MainNavRail({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isExpanded = ref.watch(
      layoutStateNotifierProvider.select((state) => state.mainNavRailExpanded),
    );

    final showUpdateBadge = ref.watch(
      updateStateProvider.select((state) => state.hasNewVersion),
    );
    final currentIndex = navigationShell.currentIndex;

    return _NavRailExpansionScope(
      isExpanded: isExpanded,
      child: AnimatedContainer(
        key: const Key('main-nav-rail'),
        duration: animationDuration,
        curve: Curves.easeInOutCubic,
        width: isExpanded ? expandedWidth : collapsedWidth,
        height: double.infinity,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            right: BorderSide(color: theme.dividerColor, width: 1),
          ),
        ),
        child: Column(
          children: [
            // 账户固定在顶部，导航内容单独滚动。
            const SizedBox(height: 8),
            _AccountAvatarButton(ref: ref),
            const _NavGroupDivider(),

            Expanded(
              child: SingleChildScrollView(
                key: const Key('main-nav-primary-scroll'),
                child: Column(
                  children: [
                    // 创作：主生图、画风探索。
                    _NavIcon(
                      icon: StudioIcons.generation,
                      label: context.l10n.nav_canvas,
                      isSelected: currentIndex == AppBranch.generation.index,
                      onTap: () =>
                          navigationShell.goBranch(AppBranch.generation.index),
                    ),

                    // 画风探索
                    _NavIcon(
                      icon: StudioIcons.styleExplore,
                      label: context.l10n.nav_styleExplore,
                      isSelected: currentIndex == AppBranch.styleExplore.index,
                      onTap: () => navigationShell.goBranch(
                        AppBranch.styleExplore.index,
                      ),
                    ),

                    const _NavGroupDivider(),

                    // 素材：本地图库、在线画廊、块库及参考仓库。
                    _NavIcon(
                      icon: StudioIcons.localGallery,
                      label: context.l10n.localGallery_title,
                      isSelected: currentIndex == AppBranch.localGallery.index,
                      onTap: () => navigationShell.goBranch(
                        AppBranch.localGallery.index,
                      ),
                    ),

                    _NavIcon(
                      icon: StudioIcons.onlineGallery,
                      label: context.l10n.nav_onlineGallery,
                      isSelected: currentIndex == AppBranch.onlineGallery.index,
                      onTap: () => navigationShell.goBranch(
                        AppBranch.onlineGallery.index,
                      ),
                    ),

                    _NavIcon(
                      icon: StudioIcons.promptBlocks,
                      label: context.l10n.nav_promptBlockLibrary,
                      isSelected:
                          currentIndex == AppBranch.promptBlockLibrary.index,
                      onTap: () => navigationShell.goBranch(
                        AppBranch.promptBlockLibrary.index,
                      ),
                    ),

                    // Vibe库
                    _NavIcon(
                      icon: StudioIcons.vibeLibrary,
                      label: context.l10n.vibeLibrary_title,
                      isSelected: currentIndex == AppBranch.vibeLibrary.index,
                      onTap: () =>
                          navigationShell.goBranch(AppBranch.vibeLibrary.index),
                    ),

                    // 精准参考库
                    _NavIcon(
                      icon: StudioIcons.preciseReference,
                      label: context.l10n.nav_preciseRefLibrary,
                      isSelected:
                          currentIndex == AppBranch.preciseRefLibrary.index,
                      onTap: () => navigationShell.goBranch(
                        AppBranch.preciseRefLibrary.index,
                      ),
                    ),

                    _NavIcon(
                      icon: Icons.menu_book_outlined,
                      label: context.l10n.nav_tagWiki,
                      isSelected: currentIndex == AppBranch.tagWiki.index,
                      onTap: () =>
                          navigationShell.goBranch(AppBranch.tagWiki.index),
                    ),

                    const _NavGroupDivider(),

                    // 统计独立分组。
                    _NavIcon(
                      icon: StudioIcons.statistics,
                      label: context.l10n.statistics_title,
                      isSelected: currentIndex == AppBranch.statistics.index,
                      onTap: () =>
                          navigationShell.goBranch(AppBranch.statistics.index),
                    ),
                  ],
                ),
              ),
            ),

            // 收起/展开按钮
            _NavRailToggle(
              isExpanded: isExpanded,
              onTap: () {
                ref
                    .read(layoutStateNotifierProvider.notifier)
                    .toggleMainNavRail();
              },
            ),
            const SizedBox(height: 2),

            // Bottom Settings（最底，符合主流前端惯例）
            _NavIcon(
              icon: StudioIcons.settings,
              label: context.l10n.nav_settings,
              isSelected: currentIndex == AppBranch.settings.index,
              showBadge: showUpdateBadge,
              onTap: () => navigationShell.goBranch(AppBranch.settings.index),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _NavGroupDivider extends StatelessWidget {
  const _NavGroupDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 17,
    thickness: 1,
    indent: 16,
    endIndent: 16,
    color: Theme.of(context).brightness == Brightness.light
        ? Theme.of(context).colorScheme.outline
        : Theme.of(context).dividerColor,
  );
}

class _NavRailExpansionScope extends InheritedWidget {
  const _NavRailExpansionScope({
    required this.isExpanded,
    required super.child,
  });

  final bool isExpanded;

  static bool isExpandedOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_NavRailExpansionScope>()
            ?.isExpanded ??
        false;
  }

  @override
  bool updateShouldNotify(_NavRailExpansionScope oldWidget) {
    return isExpanded != oldWidget.isExpanded;
  }
}

class _NavRailToggle extends StatelessWidget {
  const _NavRailToggle({required this.isExpanded, required this.onTap});

  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = isExpanded
        ? context.l10n.nav_collapseSidebar
        : context.l10n.nav_expandSidebar;

    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: isExpanded
              ? Align(
                  key: const ValueKey('expanded-nav-toggle'),
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    key: const Key('main-nav-toggle'),
                    onPressed: onTap,
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      minimumSize: const Size(0, 36),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(
                      Icons.keyboard_double_arrow_left,
                      size: 18,
                    ),
                    label: Text(label),
                  ),
                )
              : Center(
                  key: const ValueKey('collapsed-nav-toggle'),
                  child: IconButton(
                    key: const Key('main-nav-toggle'),
                    onPressed: onTap,
                    tooltip: label,
                    visualDensity: VisualDensity.compact,
                    style: IconButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurfaceVariant,
                      hoverColor: theme.colorScheme.surfaceContainerHighest,
                      highlightColor: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                    ),
                    icon: const Icon(
                      Icons.keyboard_double_arrow_right,
                      size: 20,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatefulWidget {
  final IconData? icon;
  final Widget Function(Color color)? customIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showBadge;

  const _NavIcon({
    this.icon,
    this.customIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.showBadge = false,
  }) : assert(
         icon != null || customIcon != null,
         '_NavIcon requires either icon or customIcon',
       );

  @override
  State<_NavIcon> createState() => _NavIconState();
}

class _NavIconState extends State<_NavIcon> {
  bool _isPressed = false;
  int _motionTrigger = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpanded = _NavRailExpansionScope.isExpandedOf(context);
    final color = widget.isSelected
        ? theme.colorScheme.primary
        : theme.iconTheme.color?.withValues(alpha: 0.9);
    // 自绘图标吃非空色：与 Icon(color: null) 的 IconTheme 兜底同口径解出实色。
    final resolvedColor =
        color ?? IconTheme.of(context).color ?? theme.colorScheme.onSurface;

    final backgroundColor = widget.isSelected
        ? theme.colorScheme.primary.withValues(alpha: 0.1)
        : Colors.transparent;

    return Tooltip(
      message: isExpanded ? '' : widget.label,
      preferBelow: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        height: 48,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() => _motionTrigger++);
              widget.onTap();
            },
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            borderRadius: BorderRadius.circular(8),
            child: AnimatedScale(
              scale: _isPressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                  border: widget.isSelected
                      ? Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.5,
                          ),
                          width: 1,
                        )
                      : null,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final showLabel = constraints.maxWidth > 60;
                    final labelOpacity = ((constraints.maxWidth - 60) / 48)
                        .clamp(0.0, 1.0);
                    return Row(
                      children: [
                        SizedBox(
                          width: constraints.maxWidth.clamp(0.0, 48.0),
                          height: 48,
                          child: Center(
                            child: Badge(
                              isLabelVisible: widget.showBadge,
                              smallSize: 7,
                              child: widget.customIcon != null
                                  ? widget.customIcon!(resolvedColor)
                                  : StudioAnimatedIcon(
                                      icon: widget.icon!,
                                      trigger: _motionTrigger,
                                      color: color,
                                      size: 24,
                                    ),
                            ),
                          ),
                        ),
                        if (showLabel)
                          Expanded(
                            child: Opacity(
                              opacity: labelOpacity,
                              child: Text(
                                widget.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: widget.isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                  fontWeight: widget.isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        if (showLabel) const SizedBox(width: 12),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 账户头像按钮组件
class _AccountAvatarButton extends StatefulWidget {
  final WidgetRef ref;

  const _AccountAvatarButton({required this.ref});

  @override
  State<_AccountAvatarButton> createState() => _AccountAvatarButtonState();
}

class _AccountAvatarButtonState extends State<_AccountAvatarButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = widget.ref.watch(authNotifierProvider);
    final accounts = widget.ref.watch(accountManagerNotifierProvider).accounts;

    // 获取当前账户
    SavedAccount? currentAccount;
    if (authState.accountId != null) {
      try {
        currentAccount = accounts.firstWhere(
          (a) => a.id == authState.accountId,
        );
      } catch (_) {
        currentAccount = accounts.isNotEmpty ? accounts.first : null;
      }
    } else if (accounts.isNotEmpty) {
      currentAccount = accounts.first;
    }

    final avatar = currentAccount != null
        ? AccountAvatarSmall(account: currentAccount, size: 46)
        : Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: avatarBorderRadius(46),
            ),
            child: Icon(
              Icons.person,
              color: theme.colorScheme.primary,
              size: 26,
            ),
          );

    return Container(
      margin: const EdgeInsets.fromLTRB(7, 0, 6, 0),
      height: 50,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAccountMenu(context, currentAccount),
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          borderRadius: BorderRadius.circular(25),
          child: AnimatedScale(
            scale: _isPressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showLabel = constraints.maxWidth > 80;
                final labelOpacity = ((constraints.maxWidth - 80) / 48).clamp(
                  0.0,
                  1.0,
                );
                return Row(
                  children: [
                    SizedBox(
                      width: constraints.maxWidth.clamp(0.0, 46.0),
                      height: 50,
                      child: Center(
                        child: SizedBox(
                          key: const Key('main-nav-avatar'),
                          width: 46,
                          height: 46,
                          child: avatar,
                        ),
                      ),
                    ),
                    if (showLabel) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Opacity(
                          opacity: labelOpacity,
                          child: Text(
                            currentAccount?.displayName ??
                                context.l10n.settings_account,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: labelOpacity,
                        child: Icon(
                          Icons.expand_more,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 显示账户菜单
  Future<void> _showAccountMenu(
    BuildContext context,
    SavedAccount? currentAccount,
  ) async {
    final theme = Theme.of(context);
    final accounts = widget.ref.read(accountManagerNotifierProvider).accounts;
    final authState = widget.ref.read(authNotifierProvider);

    // 获取按钮的位置用于定位菜单
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;

    // 使用 Rect 定义菜单弹出的锚点位置
    final railWidth = _NavRailExpansionScope.isExpandedOf(context)
        ? MainNavRail.expandedWidth
        : MainNavRail.collapsedWidth;
    final menuAnchor = Rect.fromLTWH(
      railWidth + 8,
      offset.dy,
      1,
      button.size.height,
    );

    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(menuAnchor, Offset.zero & screenSize),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        // 当前账号标题
        if (currentAccount != null)
          PopupMenuItem<String>(
            enabled: false,
            height: 40,
            child: Text(
              '${context.l10n.auth_currentAccount}: ${currentAccount.displayName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),

        // 分割线
        if (currentAccount != null && accounts.length > 1)
          const PopupMenuDivider(),

        // 账号列表
        ...accounts.map(
          (account) => PopupMenuItem<String>(
            value: 'switch_${account.id}',
            height: account.subscriptionExpiresAt != null ? 56 : 48,
            child: Row(
              children: [
                AccountAvatarSmall(account: account, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        account.displayName,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (account.subscriptionExpiresAt != null)
                        SubscriptionExpiryText(
                          expiresAt: account.subscriptionExpiresAt!,
                        ),
                    ],
                  ),
                ),
                if (account.id == authState.accountId)
                  Icon(Icons.check, color: theme.colorScheme.primary, size: 20),
              ],
            ),
          ),
        ),

        const PopupMenuDivider(),

        // 添加账号
        PopupMenuItem<String>(
          value: 'add',
          child: Row(
            children: [
              Icon(Icons.add, color: theme.colorScheme.onSurface, size: 20),
              const SizedBox(width: 12),
              Text(context.l10n.auth_addAccount),
            ],
          ),
        ),

        // 退出登录
        PopupMenuItem<String>(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: theme.colorScheme.error, size: 20),
              const SizedBox(width: 12),
              Text(
                context.l10n.auth_logout,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ),
        ),
      ],
    );

    if (value == null || !mounted) return;

    if (value == 'add') {
      if (mounted) {
        // ignore: use_build_context_synchronously
        _showAddAccountDialog(context);
      }
    } else if (value == 'logout') {
      // Use SchedulerBinding.endOfFrame to ensure logout happens AFTER the menu is fully disposed
      // This prevents the "ref.listen can only be used within build method" error that occurs when
      // ref.listen in app_router.dart is triggered during menu disposal. endOfFrame is more reliable
      // than addPostFrameCallback because it waits for the entire frame to complete, including all
      // post-frame callbacks and microtasks, ensuring the widget tree is stable.
      SchedulerBinding.instance.endOfFrame.then((_) {
        if (mounted) {
          widget.ref.read(authNotifierProvider.notifier).logout();
        }
      });
    } else if (value.startsWith('switch_')) {
      final accountId = value.substring(7);
      _switchAccount(accountId);
    }
  }

  /// 切换账号
  Future<void> _switchAccount(String accountId) async {
    final accounts = widget.ref.read(accountManagerNotifierProvider).accounts;
    final account = accounts.firstWhere((a) => a.id == accountId);
    if (!mounted) return;
    await AccountSwitchHelper.switchToAccount(context, widget.ref, account);
  }

  /// 显示添加账号对话框
  void _showAddAccountDialog(BuildContext context) {
    AddAccountDialog.show(context, widget.ref);
  }
}
