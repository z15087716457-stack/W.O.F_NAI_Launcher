import 'package:flutter/material.dart';

import 'ui_colors.dart';
import 'ui_text.dart';

/// 一条悬停提示：贴在宿主组件内 [anchor] 这一点上，
/// [followerAnchor] 指定提示框自己的哪个角对齐这一点。
@immutable
class UiTip {
  const UiTip({
    required this.anchor,
    required this.followerAnchor,
    required this.child,
    this.width,
    this.targetAnchor = Alignment.topLeft,
    this.bare = false,
  });

  /// 相对 [targetAnchor] 的偏移。
  final Offset anchor;

  /// 宿主组件上的参照角，默认左上角。
  final Alignment targetAnchor;
  final Alignment followerAnchor;
  final Widget child;
  final double? width;

  /// true：[child] 自带外观（比如主导航的带尖角气泡），不再套 [UiTipBubble]。
  final bool bare;
}

/// 富内容悬停提示的宿主。提示画在应用浮层里，不会被相邻卡片盖住，也不挡鼠标。
class UiTipHost extends StatefulWidget {
  const UiTipHost({super.key, required this.child, this.tip});

  final Widget child;

  /// 为 null 时不显示。
  final UiTip? tip;

  @override
  State<UiTipHost> createState() => _UiTipHostState();
}

class _UiTipHostState extends State<UiTipHost> {
  final _link = LayerLink();
  final _portal = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    // 浮层层常驻（不能在构建期间 show / hide）；没有提示时浮层里什么都不画。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _portal.show();
    });
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) {
        final tip = widget.tip;
        if (tip == null) return const SizedBox.shrink();
        return Positioned(
          left: 0,
          top: 0,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: tip.targetAnchor,
            followerAnchor: tip.followerAnchor,
            offset: tip.anchor,
            child: IgnorePointer(
              child: tip.bare
                  ? tip.child
                  : UiTipBubble(width: tip.width, child: tip.child),
            ),
          ),
        );
      },
      child: CompositedTransformTarget(link: _link, child: widget.child),
    );
  }
}

/// 提示框外观：深底浅字（深色主题反过来）、圆角 9、内边距 9 / 12、投影。
class UiTipBubble extends StatelessWidget {
  const UiTipBubble({super.key, required this.child, this.width});
  final Widget child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: c.tipBg,
        borderRadius: BorderRadius.circular(9),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 30,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: DefaultTextStyle(
        style: UiText.sans(12, color: c.tipInk),
        child: child,
      ),
    );
  }
}

/// 提示框里的样式。
abstract final class UiTipStyle {
  /// 次要说明行。
  static TextStyle secondary(BuildContext context) =>
      UiText.sans(11.5, color: context.ui.tipInk.withValues(alpha: .62));

  /// 加粗数字。
  static TextStyle number(BuildContext context) =>
      UiText.mono(12, weight: FontWeight.w600, color: context.ui.tipInk);

  /// 加粗正文。
  static TextStyle strong(BuildContext context) =>
      UiText.sans(12, weight: FontWeight.w600, color: context.ui.tipInk);
}
