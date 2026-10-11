import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_keycap.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'nav_contract.dart';
import 'nav_panel.dart';
import 'nav_popovers.dart';
import 'nav_rail.dart';

enum _Popup { account, tasks, menu, customize }

/// 主导航外框：左边是 48 宽图标栏（钉住时换成 236 宽常驻栏），右边是页面 [child]。
///
/// 界面自己管理的交互（不需要接线）：展开浮层的开关（点外面 / Esc / 选了某页收起）、
/// 账号 / 后台任务 / 右键菜单 / 自定义面板这几个弹层、悬停提示、按住 Ctrl 显示编号。
class NavShell extends StatefulWidget {
  const NavShell({
    super.key,
    required this.data,
    required this.actions,
    required this.child,
  });

  final NavViewData data;
  final NavActions actions;

  /// 页面内容（路由的 IndexedStack 等）。
  final Widget child;

  @override
  State<NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<NavShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _expand;
  var _opened = false;
  _Popup? _popup;
  UiPopoverAnchor? _anchor;
  var _ctrl = false;
  Timer? _ctrlTimer;

  NavViewData get _d => widget.data;
  NavActions get _a => widget.actions;

  bool get _reduce =>
      _d.reducedMotion || MediaQuery.disableAnimationsOf(context);

  @override
  void initState() {
    super.initState();
    _expand = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void didUpdateWidget(covariant NavShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_d.pinned && _opened) _setOpen(false, instant: true);
    if (!_d.ctrlNumbers && _ctrl) _ctrl = false;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _ctrlTimer?.cancel();
    _expand.dispose();
    super.dispose();
  }

  bool _isCtrl(LogicalKeyboardKey k) =>
      k == LogicalKeyboardKey.controlLeft ||
      k == LogicalKeyboardKey.controlRight;

  bool _onKey(KeyEvent e) {
    final k = e.logicalKey;
    if (e is KeyDownEvent &&
        k == LogicalKeyboardKey.escape &&
        _opened &&
        _popup == null) {
      _setOpen(false);
      return true;
    }
    if (_isCtrl(k)) {
      if (e is KeyDownEvent && _d.ctrlNumbers) {
        final alone = HardwareKeyboard.instance.logicalKeysPressed.every(
          _isCtrl,
        );
        if (alone) {
          _ctrlTimer?.cancel();
          _ctrlTimer = Timer(const Duration(milliseconds: 400), () {
            if (mounted) setState(() => _ctrl = true);
          });
        }
      } else if (e is KeyUpEvent) {
        _ctrlTimer?.cancel();
        if (_ctrl) {
          setState(() => _ctrl = false);
          if (!_d.ctrlHintSeen) _a.onCtrlHintSeen();
        }
      }
    } else if (e is KeyDownEvent && !_ctrl) {
      // Ctrl+C 这类组合键按得快，不出编号。
      _ctrlTimer?.cancel();
    }
    return false;
  }

  void _setOpen(bool open, {bool instant = false}) {
    setState(() => _opened = open);
    if (instant || _reduce) {
      _expand.value = open ? 1 : 0;
    } else if (open) {
      _expand.forward();
    } else {
      _expand.reverse();
    }
  }

  void _show(_Popup p, UiPopoverAnchor anchor) => setState(() {
    _popup = p;
    _anchor = anchor;
  });

  void _dismiss() => setState(() {
    _popup = null;
    _anchor = null;
  });

  /// 先关弹层，等这一帧结束再回调：回调里改账号状态不会拆掉正在处理点击的弹层。
  void _after(VoidCallback action) {
    _dismiss();
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }

  void _open(NavPage p) {
    if (_opened) _setOpen(false);
    _a.onOpenPage(p);
  }

  void _openCustomize(Offset at) {
    final box = context.findRenderObject()! as RenderBox;
    final railRight = box.localToGlobal(
      Offset(_d.pinned ? NavPanel.width : NavRail.width, 0),
    );
    _show(
      _Popup.customize,
      UiPopoverAnchor(Offset(railRight.dx + 12, at.dy - 40)),
    );
  }

  Widget _popover(BuildContext context) => switch (_popup) {
    _Popup.account => NavAccountPopover(
      data: _d.account,
      onSwitch: (id) => _after(() => _a.onSwitchAccount(id)),
      onAdd: () => _after(_a.onAddAccount),
      onManage: () => _after(_a.onManageAccounts),
      onLogout: () => _after(_a.onLogout),
    ),
    _Popup.tasks => NavTasksPopover(
      data: _d,
      onViewGeneration: () => _after(() => _open(NavPage.generation)),
      onCancel: _a.onCancelTask,
      onUndo: _a.onUndoTask,
    ),
    _Popup.menu => NavContextMenu(
      onCustomize: () => _openCustomize(_anchor!.point),
    ),
    _Popup.customize => NavCustomizePanel(
      data: _d,
      onHiddenChanged: _a.onHiddenChanged,
      onCtrlNumbersChanged: _a.onCtrlNumbersChanged,
      onDone: _dismiss,
    ),
    null => const SizedBox.shrink(),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final rail = NavRail(
      data: _d,
      ctrlHeld: _ctrl,
      tipsEnabled: _popup == null && !_opened,
      onOpenPage: _open,
      onAvatar: (ctx) =>
          _show(_Popup.account, UiPopoverAnchor.beside(ctx, dx: 5, dy: 1)),
      onTasks: (ctx) => _show(
        _Popup.tasks,
        UiPopoverAnchor.beside(ctx, dx: 6, dy: 6, alignBottom: true),
      ),
      onExpand: () => _setOpen(true),
      onContextMenu: (p) => _show(_Popup.menu, UiPopoverAnchor(p)),
    );
    NavPanel panel() => NavPanel(
      data: _d,
      onOpenPage: _open,
      onAccount: (ctx) =>
          _show(_Popup.account, UiPopoverAnchor.beside(ctx, dx: 8)),
      onPinnedChanged: (v) {
        if (v) _setOpen(false, instant: true);
        _a.onPinnedChanged(v);
      },
      onCollapse: () => _d.pinned ? _a.onPinnedChanged(false) : _setOpen(false),
    );
    final scrim = Colors.black.withValues(alpha: c.dark ? .35 : .08);

    final body = Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_d.pinned)
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onSecondaryTapUp: (e) =>
                    _show(_Popup.menu, UiPopoverAnchor(e.globalPosition)),
                child: panel(),
              )
            else
              rail,
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  widget.child,
                  if (_ctrl && !_d.ctrlHintSeen)
                    const Positioned(left: 14, top: 14, child: _CtrlHint()),
                ],
              ),
            ),
          ],
        ),
        if (!_d.pinned)
          AnimatedBuilder(
            animation: _expand,
            builder: (context, _) {
              final t = Curves.easeOutCubic.transform(_expand.value);
              if (t == 0) return const SizedBox.shrink();
              return Positioned.fill(
                child: Stack(
                  children: [
                    Positioned(
                      left: NavRail.width,
                      top: 0,
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        key: const Key('main-nav-scrim'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _setOpen(false),
                        child: ColoredBox(
                          color: scrim.withValues(alpha: scrim.a * t),
                        ),
                      ),
                    ),
                    // 从图标栏下面滑出：右边缘从 48 走到 236，投影不被裁掉。
                    Positioned(
                      left: lerpDouble(NavRail.width - NavPanel.width, 0, t),
                      top: 0,
                      bottom: 0,
                      width: NavPanel.width,
                      child: panel(),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );

    return UiPopover(
      anchor: _anchor,
      onDismiss: _dismiss,
      builder: _popover,
      child: body,
    );
  }
}

/// 第一次按住 Ctrl 时的说明条。
class _CtrlHint extends StatelessWidget {
  const _CtrlHint();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return IgnorePointer(
      child: UiPopoverSurface(
        key: const Key('main-nav-ctrl-hint'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            const UiKeycap('Ctrl'),
            Text(
              context.l10n.navShell_ctrlHint,
              style: UiText.sans(12, color: c.ink),
            ),
          ],
        ),
      ),
    );
  }
}
