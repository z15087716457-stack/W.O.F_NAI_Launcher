import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../kit/ui_colors.dart';
import '../kit/ui_popover.dart';
import 'online_contract.dart';
import 'online_inspector.dart';
import 'online_popovers.dart';
import 'online_sidebar.dart';
import 'online_toolbar.dart';
import 'online_viewer.dart';
import 'online_wall.dart';

/// 页面级的界面状态和命令，卡片、检查器、查看器通过 [OnlineScope] 拿到。
abstract class OnlineController {
  bool get picking;

  /// 勾选的卡片，按勾选顺序。
  Set<String> get picked;
  void setPicking(bool value);
  void togglePick(String key);
  void setPicked(Iterable<String> keys);

  void openViewer(String key);

  /// “发送到生图”主按钮：记住过方式就直接发，否则在 [anchor] 弹出选择。
  void requestSend(String key, UiPopoverAnchor anchor);

  /// 箭头：总是弹出选择。
  void chooseSend(String key, UiPopoverAnchor anchor);

  void openMenu(UiPopoverAnchor anchor, List<OnlineMenuItem> items);
  void openFavoriteTo(UiPopoverAnchor anchor, List<String> keys);
  void closePopover();

  FocusNode get searchFocus;
}

class OnlineScope extends InheritedWidget {
  const OnlineScope({
    super.key,
    required this.data,
    required this.actions,
    required this.controller,
    required super.child,
  });

  final OnlineViewData data;
  final OnlineActions actions;
  final OnlineController controller;

  static OnlineScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OnlineScope>()!;

  // 多选状态在页面 State 里，页面每次重建都通知（重建只在数据或界面状态变化时发生）。
  @override
  bool updateShouldNotify(OnlineScope old) => true;
}

/// 在线画廊：左栏 240 │ 卡片墙（≥ 560）│ 检查器 340。
/// 窗口不够宽时先临时收起检查器，再收起左栏（不回调，不改用户设置）。
class OnlineGalleryPage extends StatefulWidget {
  const OnlineGalleryPage({
    super.key,
    required this.data,
    required this.actions,
  });

  final OnlineViewData data;
  final OnlineActions actions;

  static const sidebarWidth = 240.0;
  static const inspectorWidth = 340.0;
  static const minWall = 560.0;

  @override
  State<OnlineGalleryPage> createState() => _OnlineGalleryPageState();
}

enum _Pop { none, send, menu, favoriteTo }

class _OnlineGalleryPageState extends State<OnlineGalleryPage>
    implements OnlineController {
  var _picking = false;
  final _picked = <String>{};
  String? _viewerKey;
  final _focus = FocusNode(debugLabel: 'online-gallery');
  final _searchFocus = FocusNode(debugLabel: 'online-search');

  var _pop = _Pop.none;
  UiPopoverAnchor? _anchor;
  String? _sendKey;
  List<OnlineMenuItem> _menu = const [];
  List<String> _favoriteKeys = const [];

  OnlineViewData get _data => widget.data;
  OnlineActions get _actions => widget.actions;

  @override
  void didUpdateWidget(covariant OnlineGalleryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final keys = {for (final w in _data.list.items) w.key};
    if (_picked.any((k) => !keys.contains(k))) {
      _picked.removeWhere((k) => !keys.contains(k));
    }
    if (_viewerKey != null && !keys.contains(_viewerKey)) _viewerKey = null;
    if (oldWidget.data.source != _data.source ||
        oldWidget.data.mode != _data.mode) {
      _picking = false;
      _picked.clear();
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  bool get picking => _picking;

  @override
  Set<String> get picked => _picked;

  @override
  FocusNode get searchFocus => _searchFocus;

  @override
  void setPicking(bool value) => setState(() {
    _picking = value;
    if (!value) _picked.clear();
  });

  @override
  void togglePick(String key) => setState(() {
    if (!_picked.remove(key)) _picked.add(key);
  });

  @override
  void setPicked(Iterable<String> keys) => setState(() {
    _picked
      ..clear()
      ..addAll(keys);
  });

  @override
  void openViewer(String key) {
    if (_data.selectedKey != key) _actions.onSelect(key);
    setState(() => _viewerKey = key);
  }

  @override
  void requestSend(String key, UiPopoverAnchor anchor) {
    final remembered = _data.send.remembered;
    final detail = _data.detail?.key == key ? _data.detail : null;
    if (remembered != null &&
        (remembered != OnlineSendMode.withParams ||
            (detail?.canSendParams ?? false))) {
      _actions.onSend(key, remembered);
    } else {
      chooseSend(key, anchor);
    }
  }

  @override
  void chooseSend(String key, UiPopoverAnchor anchor) => setState(() {
    _pop = _Pop.send;
    _anchor = anchor;
    _sendKey = key;
  });

  @override
  void openMenu(UiPopoverAnchor anchor, List<OnlineMenuItem> items) =>
      setState(() {
        _pop = _Pop.menu;
        _anchor = anchor;
        _menu = items;
      });

  @override
  void openFavoriteTo(UiPopoverAnchor anchor, List<String> keys) =>
      setState(() {
        _pop = _Pop.favoriteTo;
        _anchor = anchor;
        _favoriteKeys = keys;
      });

  @override
  void closePopover() {
    if (_pop == _Pop.none) return;
    setState(() {
      _pop = _Pop.none;
      _anchor = null;
    });
  }

  bool _typing() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    return ctx != null &&
        (ctx.widget is EditableText ||
            ctx.findAncestorWidgetOfExactType<EditableText>() != null);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final k = e.logicalKey;
    final ctrl = HardwareKeyboard.instance.isControlPressed;
    if (ctrl && k == LogicalKeyboardKey.keyF) {
      _searchFocus.requestFocus();
      return KeyEventResult.handled;
    }
    if (_typing() || _viewerKey != null) return KeyEventResult.ignored;
    final items = _data.list.items;
    final sel = _data.selectedKey;
    if (k == LogicalKeyboardKey.escape && _picking) {
      setPicking(false);
      return KeyEventResult.handled;
    }
    if (items.isEmpty) return KeyEventResult.ignored;
    final dir = switch (k) {
      LogicalKeyboardKey.arrowLeft => AxisDirection.left,
      LogicalKeyboardKey.arrowRight => AxisDirection.right,
      LogicalKeyboardKey.arrowUp => AxisDirection.up,
      LogicalKeyboardKey.arrowDown => AxisDirection.down,
      _ => null,
    };
    if (dir != null) {
      final next = OnlineWall.neighbor(context, sel, dir) ?? items.first.key;
      if (next != sel) _actions.onSelect(next);
      return KeyEventResult.handled;
    }
    if (sel == null) return KeyEventResult.ignored;
    if (k == LogicalKeyboardKey.space) {
      openViewer(sel);
    } else if (k == LogicalKeyboardKey.enter ||
        (ctrl && k == LogicalKeyboardKey.keyR)) {
      final box = context.findRenderObject()! as RenderBox;
      requestSend(
        sel,
        UiPopoverAnchor(
          box.localToGlobal(box.size.bottomRight(const Offset(-396, -102))),
          alignBottom: true,
        ),
      );
    } else if (k == LogicalKeyboardKey.keyF && !ctrl) {
      if (_data.status.favoritesWritable) _actions.onToggleFavorite(sel);
    } else if (ctrl && k == LogicalKeyboardKey.keyC) {
      _actions.onCopyPrompt([sel]);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  Widget _popover(BuildContext context) => switch (_pop) {
    _Pop.send => OnlineSendPopover(workKey: _sendKey!, onClose: closePopover),
    _Pop.menu => OnlineMenu(items: _menu, onClose: closePopover),
    _Pop.favoriteTo => OnlineFavoriteToPopover(
      keys: _favoriteKeys,
      onClose: closePopover,
    ),
    _Pop.none => const SizedBox.shrink(),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final data = _data;
    final status = data.status;
    final login =
        data.mode == OnlineMode.favorites &&
        !status.favoritesLocal &&
        status.needsLogin;
    return OnlineScope(
      data: data,
      actions: _actions,
      controller: this,
      child: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: UiPopover(
          anchor: _pop == _Pop.none ? null : _anchor,
          onDismiss: closePopover,
          builder: _popover,
          child: OnlineViewerHost(
            viewerKey: _viewerKey,
            onClose: () {
              setState(() => _viewerKey = null);
              _focus.requestFocus();
            },
            onWorkChanged: (key) => setState(() => _viewerKey = key),
            child: ColoredBox(
              color: c.bg,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  var sidebar = data.sidebarOpen;
                  var inspector = data.inspectorOpen && !_picking && !login;
                  if (inspector &&
                      w -
                              (sidebar ? OnlineGalleryPage.sidebarWidth : 0) -
                              OnlineGalleryPage.inspectorWidth <
                          OnlineGalleryPage.minWall) {
                    inspector = false;
                  }
                  if (sidebar &&
                      w - OnlineGalleryPage.sidebarWidth <
                          OnlineGalleryPage.minWall) {
                    sidebar = false;
                  }
                  // 用 Listener：子控件赢下手势时也能把键盘焦点收回页面（Esc / 方向键）。
                  return Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (_) {
                      if (!_typing()) _focus.requestFocus();
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (sidebar) const OnlineSidebar(),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OnlineToolbar(
                                inspectorShown: inspector,
                                sidebarShown: sidebar,
                                login: login,
                              ),
                              if (login)
                                const Expanded(child: OnlineLoginState())
                              else ...[
                                const OnlineFilterRow(),
                                const Expanded(child: OnlineWallArea()),
                              ],
                            ],
                          ),
                        ),
                        if (inspector) const OnlineInspector(),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
