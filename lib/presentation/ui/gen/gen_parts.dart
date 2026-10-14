import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/common/studio_glass_surface.dart';
import '../../widgets/common/studio_animated_icon.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_slider.dart';
import '../kit/ui_svg_icon.dart';
import '../kit/ui_text.dart';
import '../kit/ui_tip.dart';
import 'gen_contract.dart';
import 'gen_format.dart';

/// 生图页原型里有、kit 里没有的图标路径（`mock.html` 的 `const P`）。
abstract final class GenGlyphs {
  static const save2 = 'M5 4h11l3 3v13H5zM8 4v5h7V4M8 20v-6h8v6';
  static const autosave = 'M5 4h11l3 3v13H5zM8 4v4h7V4M12 12v6M9 15h6';
  static const multi = 'M8 4h12v12H8zM4 8v12h12M11 10l2 2 4-4';
  static const pinMap =
      'M12 21s-6-5.5-6-10a6 6 0 0112 0c0 4.5-6 10-6 10zM12 11h.01';
  static const sliders = 'M4 7h9M17 7h3M4 17h3M11 17h9M15 5v4M9 15v4';
  static const minWin = 'M6 12h18';
  static const maxWin = 'M6 6h12v12H6z';
  static const brush = 'M4 20c3 0 4-1.5 4-3.5a2.5 2.5 0 015 0M13 13l7-9-9 7';
  static const sparkle =
      'M12 3l1.6 4.4L18 9l-4.4 1.6L12 15l-1.6-4.4L6 9l4.4-1.6zM18 15l.8 2.2L21 18l-2.2.8L18 21l-.8-2.2L15 18l2.2-.8z';
  static const history = 'M4 12a8 8 0 108-8 8 8 0 00-6.3 3M4 4v4h4M12 8v4l3 2';
  static const editNote = 'M4 6h10M4 11h7M4 16h5M14 19l6-6-3-3-6 6v3z';
  static const female = 'M12 14a5 5 0 100-10 5 5 0 000 10zM12 14v7M9 18h6';
  static const male =
      'M10 20a6 6 0 100-12 6 6 0 000 12zM14.5 9.5L20 4M15 4h5v5';
  static const reveal = 'M3 6h6l2 2h10v11H3zM12 11v5M9.5 13.5L12 16l2.5-2.5';
  static const zip = 'M6 3h8l4 4v14H6zM11 7h2M11 10h2M11 13h2M11 16h2v2h-2z';
}

/// NAI 官方图标（`assets/icons/nai-icon-*.svg`），按 [color] 着色。
class GenNaiIcon extends StatelessWidget {
  const GenNaiIcon(this.name, {super.key, this.size = 16, this.color});
  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => UiSvgIcon.asset(
    'assets/icons/${name.contains('.') ? name : 'nai-icon-$name.svg'}',
    size: size,
    colorFilter: ColorFilter.mode(color ?? context.ui.ink, BlendMode.srcIn),
  );
}

/// 模块外框（原型 `.mod`）：提示词底、1px 描边、圆角 8，内容按圆角裁。
class GenModule extends StatelessWidget {
  const GenModule({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    // 和 CSS 一样，内容在 1px 描边里面。
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(1),
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(8),
      ),
      decoration: BoxDecoration(
        color: GenFormat.promptBg(c),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

/// 模块标题行（原型 `.mh`）：38 高、左 12 右 6、间距 6；标题 13 / w700。
class GenModuleHeader extends StatelessWidget {
  const GenModuleHeader({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    height: 38,
    padding: const EdgeInsets.only(left: 12, right: 6),
    child: DefaultTextStyle.merge(
      style: UiText.sans(13, weight: FontWeight.w700, color: context.ui.ink),
      child: Row(spacing: 6, children: children),
    ),
  );
}

/// 数量徽标（原型 `.cnt`）：18 高、最小宽 18、左右 5、圆角 9；11 / w600。
class GenCount extends StatelessWidget {
  const GenCount(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 18,
      constraints: const BoxConstraints(minWidth: 18),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        text,
        style: UiText.sans(
          11,
          weight: FontWeight.w600,
          color: c.muted,
          height: 1,
        ),
      ),
    );
  }
}

/// 28 方图标按钮（原型 `.ib`）：圆角 5、次要色，悬停控件底。
class GenIb extends StatefulWidget {
  const GenIb({
    super.key,
    this.glyph,
    this.icon,
    this.onTap,
    this.tooltip,
    this.size = 28,
    this.width,
    this.glyphSize = 15,
    this.strokeWidth = 1.8,
    this.color,
    this.active = false,
    this.dim = false,
    this.bordered = false,
    this.filled = false,
    this.animatedIcon,
    this.animateOnTap = false,
    this.plain = false,
  });

  final String? glyph;

  /// 代替 [glyph] 的任意图标（NAI 图标、字体图标）。
  final Widget? icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final double? width;
  final double glyphSize;
  final double strokeWidth;
  final Color? color;

  /// 打开中（菜单开着 / 开关打开）：控件底 + 正文色。
  final bool active;

  /// 原型 `.ib.dim`：35% 不透明（不可用的上下移）。
  final bool dim;

  /// 描边（参数条右端的展开钮）。
  final bool bordered;
  final bool filled;
  final IconData? animatedIcon;
  final bool animateOnTap;
  final bool plain;

  @override
  State<GenIb> createState() => _GenIbState();
}

class _GenIbState extends State<GenIb> with SingleTickerProviderStateMixin {
  int _trigger = 0;
  late final AnimationController _tap = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) ||
        !TickerMode.valuesOf(context).enabled) {
      _tap.stop();
      _tap.value = 0;
    }
  }

  void _activate() {
    if (widget.onTap == null) return;
    setState(() => _trigger++);
    if (widget.animateOnTap &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled) {
      _tap.forward(from: 0);
    }
    widget.onTap!();
  }

  @override
  void dispose() {
    _tap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final onTap = widget.onTap;
    final width = widget.width;
    final size = widget.size;
    final active = widget.active;
    final bordered = widget.bordered;
    final filled = widget.filled;
    final dim = widget.dim;
    final tooltip = widget.tooltip;
    final glyph = widget.glyph;
    final glyphSize = widget.glyphSize;
    final strokeWidth = widget.strokeWidth;
    final color = widget.color;
    final icon = widget.icon;
    final box = UiPressable(
      onTap: onTap == null ? null : _activate,
      builder: (context, hover) => Container(
        width: width ?? size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.plain
              ? null
              : active
              ? c.control
              : (hover ? c.control : null),
          border: bordered ? Border.all(color: c.line) : null,
          borderRadius: BorderRadius.circular(bordered ? 6 : 5),
        ),
        child: AnimatedBuilder(
          animation: _tap,
          builder: (_, child) => Transform.scale(
            scale: 1 - .16 * (1 - (2 * _tap.value - 1).abs()),
            child: child,
          ),
          child: widget.animatedIcon != null
              ? StudioAnimatedIcon(
                  icon: widget.animatedIcon!,
                  trigger: _trigger,
                  size: glyphSize,
                  color: color ?? (hover || active ? c.ink : c.muted),
                )
              : icon ??
                    UiGlyph(
                      glyph!,
                      size: glyphSize,
                      strokeWidth: strokeWidth,
                      filled: filled,
                      color: color ?? (hover || active ? c.ink : c.muted),
                    ),
        ),
      ),
    );
    final shown = dim ? Opacity(opacity: .35, child: box) : box;
    return tooltip == null || tooltip.isEmpty
        ? shown
        : Tooltip(
            message: tooltip,
            waitDuration: const Duration(milliseconds: 400),
            child: shown,
          );
  }
}

/// 轨道式分段（原型 `.mseg` / `.oseg` / `.nseg`）：控件底、内边距 2、段间距 2、圆角 6；
/// 选中段圆角 4，浅色抬起底 + `0 1px 2px` 8% 黑影，深色悬停底、无影。
class GenTrack<T> extends StatelessWidget {
  const GenTrack({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.itemBuilder,
    this.height = 28,
    this.itemWidth,
    this.itemPadding = 9,
    this.expand = false,
    this.tooltipOf,
    this.keyOf,
  });

  final List<T> values;
  final T? selected;
  final ValueChanged<T>? onChanged;
  final Widget Function(BuildContext context, T value, bool on) itemBuilder;
  final double height;

  /// 固定段宽（方向 34）；null 按内容 + [itemPadding]。
  final double? itemWidth;
  final double itemPadding;

  /// 撑满可用宽、各段等分（张数）。
  final bool expand;
  final String? Function(T value)? tooltipOf;
  final Key? Function(T value)? keyOf;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    Widget item(T v) {
      final on = v == selected;
      final seg = UiPressable(
        key: keyOf?.call(v),
        onTap: on || onChanged == null ? null : () => onChanged!(v),
        builder: (context, hover) => Container(
          width: itemWidth,
          height: height,
          padding: itemWidth == null && !expand
              ? EdgeInsets.symmetric(horizontal: itemPadding)
              : null,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? (c.dark ? c.hover : c.raised) : null,
            borderRadius: BorderRadius.circular(4),
            boxShadow: on && !c.dark
                ? const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: itemBuilder(context, v, on || hover),
        ),
      );
      final tip = tooltipOf?.call(v);
      final shown = tip == null ? seg : Tooltip(message: tip, child: seg);
      return expand ? Expanded(child: shown) : shown;
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        spacing: 2,
        children: [for (final v in values) item(v)],
      ),
    );
  }
}

/// 页签（原型 `.tab`）：28 高、左右 10、圆角 3；13 / w500 弱 55%，选中 `--sel` 底 + w700 正文色。
class GenTab extends StatelessWidget {
  const GenTab({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: selected ? null : onTap,
      builder: (context, hover) => Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? GenFormat.selected(c)
              : (hover ? c.control.withValues(alpha: .6) : null),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: UiText.sans(
              13,
              weight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected || hover ? c.ink : GenFormat.ink55(c),
            ),
          ),
        ),
      ),
    );
  }
}

/// token 条（原型 `.tok`）：3 高、圆角 2、控件底；用量 85% 正文色，超过 90% 琥珀、超限红。
class GenTokenBar extends StatelessWidget {
  const GenTokenBar({
    super.key,
    required this.tokens,
    this.margin = const EdgeInsets.fromLTRB(12, 0, 12, 10),
  });
  final GenTokens tokens;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final t = tokens.limit <= 0 ? 0.0 : tokens.used / tokens.limit;
    final fill = t > 1
        ? c.error
        : t > .9
        ? c.warn
        : c.ink.withValues(alpha: .85);
    return Tooltip(
      message: '${tokens.used} / ${tokens.limit} tokens',
      child: Container(
        height: 3,
        margin: margin,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.control,
          borderRadius: BorderRadius.circular(2),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: t.clamp(0.0, 1.0),
          heightFactor: 1,
          child: ColoredBox(color: fill),
        ),
      ),
    );
  }
}

/// 字段标签（原型 `.flab`）：12 号次要色。
class GenLabel extends StatelessWidget {
  const GenLabel(this.text, {super.key, this.width});
  final String text;
  final double? width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: UiText.sans(12, color: context.ui.muted),
    ),
  );
}

/// 一行滑杆：标签（定宽）+ 滑杆 + 数字框。拖动时界面实时显示，松手才回调 [onChanged]。
class GenSliderRow extends StatefulWidget {
  const GenSliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.decimals = 2,
    this.defaultValue,
    this.labelWidth = 64,
    this.tooltip,
    this.enabled = true,
    this.compact = false,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int decimals;
  final double? defaultValue;
  final double labelWidth;
  final String? tooltip;
  final bool enabled;

  /// 参考图卡片里的小号：24 高数字框。
  final bool compact;

  @override
  State<GenSliderRow> createState() => _GenSliderRowState();
}

class _GenSliderRowState extends State<GenSliderRow> {
  double? _drag;

  double _norm(double v) =>
      ((v - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);

  double _denorm(double t) {
    final v = widget.min + t * (widget.max - widget.min);
    final k = widget.decimals == 0 ? 1 : (widget.decimals == 1 ? 10 : 100);
    return (v * k).roundToDouble() / k;
  }

  @override
  Widget build(BuildContext context) {
    final v = _drag ?? widget.value;
    final label = GenLabel(widget.label, width: widget.labelWidth);
    return Row(
      spacing: 10,
      children: [
        if (widget.tooltip == null)
          label
        else
          Tooltip(message: widget.tooltip, child: label),
        Expanded(
          child: UiSlider(
            value: _norm(v),
            compact: widget.compact,
            defaultValue: widget.defaultValue == null
                ? null
                : _norm(widget.defaultValue!),
            onChanged: widget.enabled
                ? (t) => setState(() => _drag = _denorm(t))
                : null,
            onChangeEnd: widget.enabled
                ? (t) {
                    final value = _drag ?? _denorm(t);
                    setState(() => _drag = null);
                    widget.onChanged(value);
                  }
                : null,
          ),
        ),
        UiNumBox(
          value: v,
          min: widget.min,
          max: widget.max,
          decimals: widget.decimals,
          compact: widget.compact,
          onSubmitted: widget.enabled ? widget.onChanged : null,
        ),
      ],
    );
  }
}

/// 三条画布工具条：沿用新控件布局，恢复旧玻璃背景、颗粒与边缘高光。
class GenFloat extends StatelessWidget {
  const GenFloat({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    const radius = BorderRadius.all(Radius.circular(11));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: GenFormat.shadow(c),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: StudioGlassSurface(
        borderRadius: radius,
        backdropBlur: true,
        useGradient: false,
        child: Padding(
          // Former Container padding also included its 1px border. The glass
          // edge is painted, so keep that space explicitly for stable geometry.
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          child: DefaultTextStyle.merge(
            style: UiText.sans(13, weight: FontWeight.w500, color: c.ink),
            child: Row(mainAxisSize: MainAxisSize.min, children: children),
          ),
        ),
      ),
    );
  }
}

/// 工具条价格胶囊：旧版半透明内胆，按当前主题和字体显示价格或“免费”。
class GenFloatCost extends StatelessWidget {
  const GenFloatCost({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    height: 22,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: context.ui.control.withValues(alpha: .6),
      borderRadius: BorderRadius.circular(3),
    ),
    child: child,
  );
}

/// 浮动工具条里的按钮（原型 `.fb`）：32 × 30、圆角 6、正文色。
class GenFloatButton extends StatelessWidget {
  const GenFloatButton({
    super.key,
    required this.child,
    this.onTap,
    this.tooltip,
    this.width = 32,
    this.padding,
    this.active = false,
    this.selected = false,
    this.richTip,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;
  final double? width;
  final EdgeInsets? padding;
  final bool active;

  /// 从这个按钮落下的面板开着（原型 `.tb.on`）：强调色 14% 底。
  final bool selected;

  /// 富内容悬停提示（名字 + 一句说明 + 价格），代替 [tooltip]，落在按钮正下方。
  final Widget? richTip;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final b = UiPressable(
      onTap: onTap,
      builder: (context, hover) => Container(
        width: width,
        height: 30,
        padding: padding,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? c.accent.withValues(alpha: .14)
              : (active || hover ? c.control : null),
          borderRadius: BorderRadius.circular(6),
        ),
        child: child,
      ),
    );
    final shown = onTap == null ? Opacity(opacity: .35, child: b) : b;
    if (richTip != null) return GenHoverTip(tip: richTip!, child: shown);
    return tooltip == null
        ? shown
        : Tooltip(
            message: tooltip,
            waitDuration: const Duration(milliseconds: 300),
            child: shown,
          );
  }
}

/// 悬停 300ms 后在组件正下方（间距 [gap]）显示富内容提示；移开立即收起。
class GenHoverTip extends StatefulWidget {
  const GenHoverTip({
    super.key,
    required this.tip,
    required this.child,
    this.width = 250,
    this.gap = 14,
  });

  final Widget tip;
  final Widget child;
  final double width;
  final double gap;

  @override
  State<GenHoverTip> createState() => _GenHoverTipState();
}

class _GenHoverTipState extends State<GenHoverTip> {
  var _show = false;
  Timer? _wait;

  @override
  void dispose() {
    _wait?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) {
      _wait?.cancel();
      _wait = Timer(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _show = true);
      });
    },
    onExit: (_) {
      _wait?.cancel();
      if (_show) setState(() => _show = false);
    },
    child: Listener(
      onPointerDown: (_) {
        _wait?.cancel();
        if (_show) setState(() => _show = false);
      },
      child: UiTipHost(
        tip: _show
            ? UiTip(
                targetAnchor: Alignment.bottomCenter,
                followerAnchor: Alignment.topCenter,
                anchor: Offset(0, widget.gap),
                width: widget.width,
                child: widget.tip,
              )
            : null,
        child: widget.child,
      ),
    ),
  );
}

/// 工具条悬停提示的内容（原型 `varTip`）：名字（加粗）+ 价格靠右，下面一句说明。
class GenBarTipContent extends StatelessWidget {
  const GenBarTipContent({
    super.key,
    required this.title,
    required this.body,
    this.price,
  });

  final String title;
  final String body;

  /// 价格块（Anlas 数字 + 图标 / “免费”）；null = 不显示。
  final Widget? price;

  @override
  Widget build(BuildContext context) => Column(
    key: const Key('gen-bar-tip'),
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        spacing: 6,
        children: [
          Expanded(child: Text(title, style: UiTipStyle.strong(context))),
          ?price,
        ],
      ),
      const SizedBox(height: 3),
      Text(body, style: UiTipStyle.secondary(context)),
    ],
  );
}

/// 浮动工具条分隔（原型 `.fdiv`）：1 × 20、左右 4。
class GenFloatDivider extends StatelessWidget {
  const GenFloatDivider({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 20,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: context.ui.line,
  );
}

/// 价格小块：数字 + Anlas 图标。
class GenAnlas extends StatelessWidget {
  const GenAnlas(
    this.value, {
    super.key,
    this.size = 12,
    this.iconSize = 10,
    this.color,
    this.weight = FontWeight.w700,
  });
  final String value;
  final double size;
  final double iconSize;
  final Color? color;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? context.ui.ink;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 3,
      children: [
        Text(
          value,
          style: UiText.sans(size, weight: weight, color: ink, height: 1),
        ),
        GenNaiIcon('anlas', size: iconSize, color: ink),
      ],
    );
  }
}

/// 拖文件进来时的高亮框（参考图行、空态投放区）。
class GenDropHighlight extends StatelessWidget {
  const GenDropHighlight({
    super.key,
    required this.active,
    required this.child,
  });
  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    final c = context.ui;
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: .08),
                border: Border.all(color: c.accent, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 确认弹窗：宽 400；标题 + 说明 + 取消 / 确认（危险操作红色）。
class GenConfirmDialog extends StatelessWidget {
  const GenConfirmDialog({
    super.key,
    required this.title,
    required this.body,
    required this.confirm,
    required this.cancel,
    required this.onConfirm,
    required this.onCancel,
    this.danger = true,
  });

  final String title;
  final String body;
  final String confirm;
  final String cancel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPopoverSurface(
      key: const Key('gen-confirm'),
      width: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Text(
              title,
              style: UiText.sans(15, weight: FontWeight.w700, color: c.ink),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Text(
              body,
              style: UiText.sans(13, color: c.muted, height: 1.55),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: c.panel,
              border: Border(top: BorderSide(color: c.line)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                UiBtn(
                  key: const Key('gen-confirm-cancel'),
                  onTap: onCancel,
                  children: [Text(cancel)],
                ),
                UiBtn(
                  key: const Key('gen-confirm-ok'),
                  tone: danger ? UiBtnTone.normal : UiBtnTone.primary,
                  color: danger ? c.error : null,
                  onTap: onConfirm,
                  children: [Text(confirm)],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
