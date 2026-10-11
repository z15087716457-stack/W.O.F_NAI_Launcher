import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui_colors.dart';

/// 弹层贴在哪：[point] 是全局坐标；[alignBottom] 为 true 时弹层底边对齐这一点（向上长）。
/// 弹层整体夹在窗口内、四周留 4。
@immutable
class UiPopoverAnchor {
  const UiPopoverAnchor(this.point, {this.alignBottom = false});
  final Offset point;
  final bool alignBottom;

  /// 贴在 [context] 对应组件的右侧：[dx] 是离右边缘的距离，[dy] 是相对顶边（或底边）的偏移。
  static UiPopoverAnchor beside(
    BuildContext context, {
    double dx = 12,
    double dy = 0,
    bool alignBottom = false,
  }) {
    final box = context.findRenderObject()! as RenderBox;
    final corner = alignBottom
        ? box.size.bottomRight(Offset.zero)
        : box.size.topRight(Offset.zero);
    return UiPopoverAnchor(
      box.localToGlobal(corner + Offset(dx, dy)),
      alignBottom: alignBottom,
    );
  }
}

/// 点击式弹层的宿主：[anchor] 非 null 时在应用浮层里画 [builder]。
/// 点弹层外面（吞掉这次点击）或按 Esc 调 [onDismiss]。
class UiPopover extends StatefulWidget {
  const UiPopover({
    super.key,
    required this.child,
    required this.anchor,
    required this.onDismiss,
    required this.builder,
  });

  final Widget child;
  final UiPopoverAnchor? anchor;
  final VoidCallback onDismiss;
  final WidgetBuilder builder;

  @override
  State<UiPopover> createState() => _UiPopoverState();
}

class _UiPopoverState extends State<UiPopover> {
  final _portal = OverlayPortalController();

  @override
  void initState() {
    super.initState();
    // 浮层层常驻（不能在构建期间 show / hide）；关着时浮层里什么都不画。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _portal.show();
    });
  }

  @override
  void didUpdateWidget(covariant UiPopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 再次打开时提到最上层（多个浮层宿主、或大图查看器也在浮层里时，后打开的在上面）。
    if (oldWidget.anchor == null && widget.anchor != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _portal.show();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) {
        final anchor = widget.anchor;
        if (anchor == null) return const SizedBox.shrink();
        final overlay = Overlay.of(context).context.findRenderObject();
        final point = overlay is RenderBox
            ? overlay.globalToLocal(anchor.point)
            : anchor.point;
        final reduce = MediaQuery.disableAnimationsOf(context);
        return Positioned.fill(
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => widget.onDismiss(),
                  onSecondaryTapDown: (_) => widget.onDismiss(),
                ),
              ),
              CustomSingleChildLayout(
                delegate: _ClampedLayout(point, anchor.alignBottom),
                child: Focus(
                  autofocus: true,
                  onKeyEvent: (_, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.escape) {
                      widget.onDismiss();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: FocusTraversalGroup(
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(anchor),
                      tween: Tween(begin: reduce ? 1 : 0, end: 1),
                      duration: const Duration(milliseconds: 140),
                      curve: Curves.easeOutCubic,
                      builder: (context, t, child) => Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset(-6 * (1 - t), 0),
                          child: child,
                        ),
                      ),
                      child: Builder(builder: widget.builder),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: widget.child,
    );
  }
}

class _ClampedLayout extends SingleChildLayoutDelegate {
  const _ClampedLayout(this.point, this.alignBottom);
  final Offset point;
  final bool alignBottom;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(
        constraints.biggest,
      ).deflate(const EdgeInsets.all(4));

  @override
  Offset getPositionForChild(Size size, Size child) {
    final top = alignBottom ? point.dy - child.height : point.dy;
    return Offset(
      point.dx.clamp(4, math.max(4, size.width - child.width - 4)),
      top.clamp(4, math.max(4, size.height - child.height - 4)),
    );
  }

  @override
  bool shouldRelayout(_ClampedLayout old) =>
      old.point != point || old.alignBottom != alignBottom;
}

/// 弹层外观：抬起底、1px 描边、圆角 12、外圈细线 + 三层投影。
/// 原型只有 `0 18px 48px` 一层大散影，压在图片上只剩一团灰雾、边缘发飘；
/// 这里改成：外圈 1px 半透明黑线（图片上也能看出边）、贴边影和中距影撑出利落的下沿，
/// 远影只保留一点抬起感。Flutter 的 blurRadius ≈ CSS 模糊 × 0.85。
class UiPopoverSurface extends StatelessWidget {
  const UiPopoverSurface({
    super.key,
    required this.child,
    this.width,
    this.padding = EdgeInsets.zero,
    this.radius = 12,
    this.color,
  });

  final Widget child;
  final double? width;
  final EdgeInsets padding;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? c.raised,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: c.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: c.dark ? .32 : .07),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: c.dark ? .36 : .12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: c.dark ? .4 : .14),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: c.dark ? .5 : .08),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(type: MaterialType.transparency, child: child),
    );
  }
}
