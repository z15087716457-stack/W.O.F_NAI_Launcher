import 'package:flutter/widgets.dart';

bool get _windowCanFocus => switch (WidgetsBinding.instance.lifecycleState) {
  null || AppLifecycleState.resumed => true,
  _ => false,
};

/// 保活页面（外壳 IndexedStack 里一直在树上）切回来时，把焦点还给这一页。
///
/// 页面切走时不销毁，IndexedStack 把它排除在焦点之外，焦点退到外面所有页面共用的范围；
/// 切回来时没有谁再要焦点（autofocus 只在第一次生效），按键到不了本页，本页的快捷键
/// （在线图库的 F、块库的 Delete、页面快捷键……）要点一下页面才恢复。这里给每个保活页面
/// 包一个焦点范围，切回来时让它恢复上次在这一页里的焦点。
class RefocusWhenActive extends StatefulWidget {
  const RefocusWhenActive({
    super.key,
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  State<RefocusWhenActive> createState() => _RefocusWhenActiveState();
}

class _RefocusWhenActiveState extends State<RefocusWhenActive> {
  final _scope = FocusScopeNode(debugLabel: 'RefocusWhenActive');

  @override
  void didUpdateWidget(RefocusWhenActive oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.active && _windowCanFocus) {
          _scope.requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _scope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FocusScope(node: _scope, child: widget.child);
}

/// 页面快捷键的焦点锚点：进页面时拿焦点，之后焦点只要退到它上面的焦点范围，就再拿回来。
///
/// 页面快捷键挂在这个节点的上面，焦点在它或它下面时按键才到得了。焦点会退到上面的范围：
/// 用鼠标在输入框外点一下（桌面端会取消输入框的焦点，退回所在范围）、拿着焦点的控件被移除、
/// 代码里取消某个节点的焦点。这时页面快捷键全部失灵，要点一下页面里能拿焦点的东西才恢复。
/// autofocus 只在第一次生效，所以这里自己盯着焦点变化；隐藏的保活页面（TickerMode 关着）不抢。
///
/// [autofocus] 为 false 时就是普通的 `Focus(skipTraversal: true)`。
class ShortcutFocusAnchor extends StatefulWidget {
  const ShortcutFocusAnchor({
    super.key,
    required this.autofocus,
    this.focusNode,
    required this.child,
  });

  final bool autofocus;
  final FocusNode? focusNode;
  final Widget child;

  @override
  State<ShortcutFocusAnchor> createState() => _ShortcutFocusAnchorState();
}

class _ShortcutFocusAnchorState extends State<ShortcutFocusAnchor> {
  final _ownedNode = FocusNode(debugLabel: 'ShortcutFocusAnchor');
  FocusNode get _node => widget.focusNode ?? _ownedNode;
  var _visible = true;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_reclaimFallenFocus);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_reclaimFallenFocus);
    _ownedNode.dispose();
    super.dispose();
  }

  void _reclaimFallenFocus() {
    // Flutter parks primary focus at the root until the window regains focus.
    // A request during that interval would discard the suspended editor/dialog.
    if (!widget.autofocus || !_visible || !mounted || !_windowCanFocus) return;
    final primary = FocusManager.instance.primaryFocus;
    // 焦点停在锚点上面的某个范围本身（所在范围或更外层），按键到不了页面快捷键
    if (primary is FocusScopeNode && _node.ancestors.contains(primary)) {
      _node.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    _visible = TickerMode.valuesOf(context).enabled;
    return Focus(
      focusNode: _node,
      autofocus: widget.autofocus,
      skipTraversal: true,
      child: widget.child,
    );
  }
}
