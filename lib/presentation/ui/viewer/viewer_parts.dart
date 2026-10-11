import 'package:flutter/material.dart';

import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_text.dart';

/// 舞台（大图区）不跟主题，始终黑底；控件颜色都是白色透明度（原型的 #1c1c1c、#2c2c2c 这类灰换算过来）。
abstract final class ViewerInk {
  static const stage = Colors.black;
  static const text = Color(0xE6FFFFFF);
  static const strong = Colors.white;
  static const dim = Color(0xB8FFFFFF);
  static const faint = Color(0x73FFFFFF);
  static const icon = Color(0xC7FFFFFF);
  static const fill = Color(0x14FFFFFF);
  static const fillHover = Color(0x24FFFFFF);
  static const on = Color(0x26FFFFFF);
  static const border = Color(0x1FFFFFFF);
  static const divider = Color(0x24FFFFFF);

  /// 玻璃浮层（全屏角标、小地图、放大提示）：不用 BackdropFilter（Windows 上有崩溃风险），半透明实底。
  static const glass = Color(0xBD121212);
  static const glassBorder = Color(0x14FFFFFF);

  /// 删除后的浅色提示条（压在黑底上）。
  static const toast = Color(0xFFF2F2F2);
  static const toastInk = Color(0xFF171717);
  static const toastMuted = Color(0xFF777777);
  static const toastBorder = Color(0xFFCCCCCC);

  /// 胶片条钉住 / 未保存这类琥珀色。
  static const amber = Color(0xFFFFB547);
  static const amberBg = Color(0xFF3A2A10);
}

/// 深色键帽（舞台、快捷键表）：18 高、描边 + 2px 底边。
class ViewerKeycap extends StatelessWidget {
  const ViewerKeycap(this.label, {super.key, this.color, this.border});
  final String label;
  final Color? color;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final side = BorderSide(color: border ?? const Color(0x33FFFFFF));
    return Container(
      height: 18,
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          top: side,
          left: side,
          right: side,
          bottom: side.copyWith(width: 2),
        ),
      ),
      child: Center(
        widthFactor: 1,
        child: Text(
          label,
          style: UiText.mono(
            10.5,
            weight: FontWeight.w500,
            height: 1,
            color: color ?? const Color(0xBFFFFFFF),
          ),
        ),
      ),
    );
  }
}

class ViewerKeycaps extends StatelessWidget {
  const ViewerKeycaps(this.keys, {super.key, this.gap = 3});
  final List<String> keys;
  final double gap;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: gap,
    children: [for (final k in keys) ViewerKeycap(k)],
  );
}

/// 舞台上的文字按钮：30 高、圆角 7，[bordered] 时带底和描边（返回）。
class ViewerDarkButton extends StatelessWidget {
  const ViewerDarkButton({
    super.key,
    required this.children,
    this.onTap,
    this.bordered = true,
  });
  final List<Widget> children;
  final VoidCallback? onTap;
  final bool bordered;

  @override
  Widget build(BuildContext context) => UiPressable(
    onTap: onTap,
    builder: (context, hover) => Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: hover
            ? ViewerInk.fillHover
            : bordered
            ? ViewerInk.fill
            : null,
        border: bordered ? Border.all(color: ViewerInk.border) : null,
        borderRadius: BorderRadius.circular(7),
      ),
      child: DefaultTextStyle.merge(
        style: UiText.sans(
          12.5,
          weight: FontWeight.w500,
          color: ViewerInk.text,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: children,
        ),
      ),
    ),
  );
}

/// 舞台上的 30 × 30 图标按钮；[on] 时浅白底（信息栏开着、1:1）。
class ViewerDarkIcon extends StatelessWidget {
  const ViewerDarkIcon({
    super.key,
    required this.tooltip,
    this.glyph,
    this.label,
    this.onTap,
    this.on = false,
    this.size = 16,
  });
  final String tooltip;
  final String? glyph;

  /// 文字图标（“1:1”）。
  final String? label;
  final VoidCallback? onTap;
  final bool on;
  final double size;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: UiPressable(
      onTap: onTap,
      builder: (context, hover) {
        final ink = on || hover ? ViewerInk.strong : ViewerInk.icon;
        return Container(
          height: 30,
          constraints: const BoxConstraints(minWidth: 30),
          padding: label == null
              ? null
              : const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on
                ? ViewerInk.on
                : hover
                ? ViewerInk.fill
                : null,
            borderRadius: BorderRadius.circular(7),
          ),
          child: label != null
              ? Text(
                  label!,
                  style: UiText.mono(11.5, weight: FontWeight.w500, color: ink),
                )
              : UiGlyph(glyph!, size: size, color: ink),
        );
      },
    ),
  );
}

/// 舞台竖分隔线 1 × 18。
class ViewerDarkSep extends StatelessWidget {
  const ViewerDarkSep({super.key, this.margin = 2});
  final double margin;

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 18,
    margin: EdgeInsets.symmetric(horizontal: margin),
    color: ViewerInk.divider,
  );
}

/// 玻璃浮层：半透明深底、细白边、圆角 12、投影。
class ViewerGlass extends StatelessWidget {
  const ViewerGlass({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.height,
  });
  final Widget child;
  final EdgeInsets padding;
  final double? height;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    padding: padding,
    decoration: BoxDecoration(
      color: ViewerInk.glass,
      border: Border.all(color: ViewerInk.glassBorder),
      borderRadius: BorderRadius.circular(12),
      boxShadow: const [
        BoxShadow(
          color: Color(0x59000000),
          blurRadius: 26,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: DefaultTextStyle.merge(
      style: UiText.sans(12, color: ViewerInk.dim),
      child: child,
    ),
  );
}
