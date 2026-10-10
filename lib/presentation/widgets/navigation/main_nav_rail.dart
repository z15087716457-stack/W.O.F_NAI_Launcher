import 'package:nai_launcher/presentation/widgets/common/studio_animated_icon.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

import '../../../data/models/auth/saved_account.dart';
import '../../providers/account_manager_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/layout_state_provider.dart';
import '../../providers/settings_navigation_provider.dart';
import '../../providers/update_provider.dart';
import '../../providers/canvas_settings_provider.dart';
import '../../router/app_branch.dart';
import '../auth/account_avatar.dart';
import '../auth/account_switch_helper.dart';
import '../auth/add_account_dialog.dart';
import '../auth/account_popover.dart';

class MainNavRail extends ConsumerWidget {
  static const double collapsedWidth = 48;
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
        decoration: BoxDecoration(color: theme.colorScheme.surface),
        // 分隔线只绘制，不挤占图标的居中空间。
        foregroundDecoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
              width: 1,
            ),
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
                      icon: StudioIcons.tagWiki,
                      reducedMotion: ref.watch(
                        canvasReducedMotionNotifierProvider,
                      ),
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
            const SizedBox(height: 8),
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
    height: 16,
    thickness: 1,
    indent: 16,
    endIndent: 16,
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.6),
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

    return Tooltip(
      message: label,
      preferBelow: false,
      child: Container(
        height: 44,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('main-nav-toggle'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            hoverColor: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            focusColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: LayoutBuilder(
                builder: (context, constraints) => Row(
                  children: [
                    SizedBox(
                      width: constraints.maxWidth.clamp(0.0, 36.0),
                      height: 36,
                      child: Icon(
                        isExpanded
                            ? Icons.keyboard_double_arrow_left
                            : Icons.keyboard_double_arrow_right,
                        color: theme.colorScheme.onSurfaceVariant,
                        size: 18,
                      ),
                    ),
                    if (constraints.maxWidth > 60)
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
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
  final bool reducedMotion;

  const _NavIcon({
    this.icon,
    this.customIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.showBadge = false,
    this.reducedMotion = false,
  }) : assert(
         icon != null || customIcon != null,
         '_NavIcon requires either icon or customIcon',
       );

  @override
  State<_NavIcon> createState() => _NavIconState();
}

class _NavIconState extends State<_NavIcon> {
  bool _isPressed = false;
  bool _isHovered = false;
  bool _isFocused = false;
  int _motionTrigger = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.isSelected
        ? theme.colorScheme.primary
        : theme.iconTheme.color?.withValues(alpha: 0.9);
    // 自绘图标吃非空色：与 Icon(color: null) 的 IconTheme 兜底同口径解出实色。
    final resolvedColor =
        color ?? IconTheme.of(context).color ?? theme.colorScheme.onSurface;

    final backgroundColor = widget.isSelected
        ? theme.colorScheme.primary.withValues(alpha: _isHovered ? 0.16 : 0.1)
        : (_isHovered || _isFocused)
        ? theme.colorScheme.onSurface.withValues(alpha: 0.06)
        : Colors.transparent;

    return Semantics(
      selected: widget.isSelected,
      child: Tooltip(
        message: widget.label,
        preferBelow: false,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
          height: 44,
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
              onHover: (value) => setState(() => _isHovered = value),
              onFocusChange: (value) => setState(() => _isFocused = value),
              borderRadius: BorderRadius.circular(12),
              hoverColor: Colors.transparent,
              focusColor: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: AnimatedScale(
                  scale: _isPressed ? 0.97 : 1.0,
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOutCubic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    foregroundDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: _isFocused
                          ? Border.all(
                              color: theme.colorScheme.primary,
                              width: 1.5,
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
                              width: constraints.maxWidth.clamp(0.0, 36.0),
                              height: 36,
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
                                          size: 20,
                                          reducedMotion: widget.reducedMotion,
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
        ? AccountAvatarSmall(account: currentAccount, size: 40)
        : Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: avatarBorderRadius(40),
            ),
            child: Icon(
              Icons.person,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          );

    return Tooltip(
      message: currentAccount?.displayName ?? context.l10n.settings_account,
      preferBelow: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        height: 44,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showAccountMenu(context),
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            borderRadius: BorderRadius.circular(12),
            hoverColor: theme.colorScheme.onSurface.withValues(alpha: 0.06),
            focusColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: AnimatedScale(
                scale: _isPressed ? 0.97 : 1.0,
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final showLabel = constraints.maxWidth > 80;
                    final labelOpacity = ((constraints.maxWidth - 80) / 48)
                        .clamp(0.0, 1.0);
                    return Row(
                      children: [
                        SizedBox(
                          width: constraints.maxWidth.clamp(0.0, 40.0),
                          height: 40,
                          child: Center(
                            child: SizedBox(
                              key: const Key('main-nav-avatar'),
                              width: 40,
                              height: 40,
                              child: avatar,
                            ),
                          ),
                        ),
                        if (showLabel) ...[
                          const SizedBox(width: 8),
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
        ),
      ),
    );
  }

  Future<void> _showAccountMenu(BuildContext context) async {
    final button = context.findRenderObject()! as RenderBox;
    final navigatorBox =
        Navigator.of(context, rootNavigator: true).context.findRenderObject()!
            as RenderBox;
    final offset = navigatorBox.globalToLocal(
      button.localToGlobal(Offset.zero),
    );
    final railWidth = _NavRailExpansionScope.isExpandedOf(context)
        ? MainNavRail.expandedWidth
        : MainNavRail.collapsedWidth;
    final value = await showAccountPopover(
      context,
      anchor: Offset(offset.dx + railWidth + 8, offset.dy),
    );
    if (value == null || !mounted || !context.mounted) return;
    // Finish removing the dialog before auth listeners can change routes.
    await SchedulerBinding.instance.endOfFrame;
    if (!mounted || !context.mounted) return;
    if (value.command != AccountPopoverCommand.manage &&
        widget.ref.read(authNotifierProvider).isLoading) {
      return;
    }
    switch (value.command) {
      case AccountPopoverCommand.add:
        _showAddAccountDialog(context);
      case AccountPopoverCommand.manage:
        widget.ref.read(settingsAccountOpenRequestProvider.notifier).state++;
        context.go('/settings');
      case AccountPopoverCommand.logout:
        widget.ref.read(authNotifierProvider.notifier).logout();
      case AccountPopoverCommand.switchAccount:
        final id = value.accountId;
        if (id != null) await _switchAccount(id);
    }
  }

  /// 切换账号
  Future<void> _switchAccount(String accountId) async {
    final accounts = widget.ref.read(accountManagerNotifierProvider).accounts;
    final account = accounts.where((a) => a.id == accountId).firstOrNull;
    final auth = widget.ref.read(authNotifierProvider);
    if (!mounted ||
        account == null ||
        (auth.isAuthenticated && auth.accountId == accountId)) {
      return;
    }
    await AccountSwitchHelper.switchToAccount(context, widget.ref, account);
  }

  /// 显示添加账号对话框
  void _showAddAccountDialog(BuildContext context) {
    AddAccountDialog.show(context, widget.ref);
  }
}
