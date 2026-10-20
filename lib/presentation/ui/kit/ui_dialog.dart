import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui_colors.dart';
import 'ui_text.dart';

/// 弹窗宿主：[dialog] 非 null 时在应用浮层里画遮罩（浅色黑 45%、深色黑 60%）和居中的弹窗。
/// 按 Esc 调 [onDismiss]；[barrierDismissible] 时点遮罩也关。弹窗尺寸由 [dialog] 自己定，
/// 窗口放不下时夹在窗口内（四周留 16）。
class UiModal extends StatefulWidget {
  const UiModal({
    super.key,
    required this.child,
    required this.dialog,
    required this.onDismiss,
    this.barrierDismissible = true,
    this.contained = false,
  });

  final Widget child;
  final WidgetBuilder? dialog;
  final VoidCallback onDismiss;
  final bool barrierDismissible;

  /// 遮罩和弹窗只盖住 [child] 自己的区域（例如侧栏），而不是整个窗口。
  final bool contained;

  @override
  State<UiModal> createState() => _UiModalState();
}

class _UiModalState extends State<UiModal> {
  final _portal = OverlayPortalController();
  final _focus = FocusNode(debugLabel: 'ui-modal');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  @override
  void didUpdateWidget(covariant UiModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dialog == null && widget.dialog != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open());
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  /// 弹窗里没有 autofocus 的控件时，出来后把焦点拉到弹窗上，Esc 才归弹窗（页面自己拿着焦点时
  /// autofocus 不会生效）。外层不设 autofocus，免得抢掉弹窗内部的 autofocus。
  void _open() {
    if (!mounted) return;
    _portal.show();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.dialog != null && !_focus.hasFocus) {
        _focus.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.contained) {
      return OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) =>
            widget.dialog == null ? const SizedBox.shrink() : _layer(context),
        child: widget.child,
      );
    }
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _portal,
      overlayChildBuilder: (context, info) {
        if (widget.dialog == null) return const SizedBox.shrink();
        final rect = MatrixUtils.transformRect(
          info.childPaintTransform,
          Offset.zero & info.childSize,
        );
        return Positioned.fromRect(rect: rect, child: _layer(context));
      },
      child: widget.child,
    );
  }

  Widget _layer(BuildContext context) {
    final dialog = widget.dialog!;
    final c = context.ui;
    // 弹窗自带一个焦点域：里面的 autofocus（例如大图详情的方向键）不会被页面的焦点挡掉。
    return SizedBox.expand(
      child: FocusScope(
        child: Focus(
          focusNode: _focus,
          onKeyEvent: (_, e) {
            if (e is KeyDownEvent &&
                e.logicalKey == LogicalKeyboardKey.escape) {
              widget.onDismiss();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.barrierDismissible ? widget.onDismiss : null,
                  child: ColoredBox(
                    color: c.dark
                        ? const Color(0x99000000)
                        : const Color(0x730A0A0A),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: FocusTraversalGroup(child: Builder(builder: dialog)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 弹窗标题行：52 高、左 18 右 10、间距 8、下边线；标题 15 / w700。
class UiDialogHeader extends StatelessWidget {
  const UiDialogHeader({super.key, required this.children, this.height = 52});
  final List<Widget> children;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: height,
      padding: const EdgeInsets.only(left: 18, right: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: DefaultTextStyle.merge(
        style: UiText.sans(15, weight: FontWeight.w700, color: c.ink),
        child: Row(spacing: 8, children: children),
      ),
    );
  }
}

/// 弹窗底栏：上 12 下 12、左 18 右 16、间距 8、上边线、面板底。
class UiDialogFooter extends StatelessWidget {
  const UiDialogFooter({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 16, 12),
      decoration: BoxDecoration(
        color: c.panel,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: Row(spacing: 8, children: children),
    );
  }
}
