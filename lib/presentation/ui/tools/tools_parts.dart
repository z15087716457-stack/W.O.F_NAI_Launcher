import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../gen/gen_parts.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_slider.dart';
import '../kit/ui_text.dart';

/// 画布工具原型里有、kit 里没有的图标路径（`mock.html` 的 `const P`）。
abstract final class ToolsGlyphs {
  static const back = 'M15 6l-6 6 6 6';
  static const fit = 'M4 9V4h5M20 9V4h-5M4 15v5h5M20 15v5h-5';
  static const drop = 'M12 3s6 7 6 11a6 6 0 01-12 0c0-4 6-11 6-11z';
  static const stamp = 'M9 4h6v6l-1 3h4v3H6v-3h4l-1-3zM6 19h12';
  static const blur =
      'M12 3s6 7 6 11a6 6 0 01-12 0c0-4 6-11 6-11zM9 14h6M10 17h4';
  static const rect = 'M5 5h14v14H5z';
  static const lasso =
      'M12 4c5 0 8 2.5 8 5.5S16 15 12 15 4 12.5 4 9.5 7 4 12 4zM7 14c-1 2 0 4 2 5';
  static const sun =
      'M12 4v2M12 18v2M4 12h2M18 12h2M6.3 6.3l1.4 1.4M16.3 16.3l1.4 1.4M6.3 17.7l1.4-1.4M16.3 7.7l1.4-1.4M12 9a3 3 0 100 6 3 3 0 000-6z';
  static const crop = 'M6 3v15h15M3 6h15v15';
  static const side = 'M4 5h16v14H4zM12 5v14';
  static const wipe = 'M4 5h16v14H4zM12 3v18M10 10l-2 2 2 2M14 10l2 2-2 2';
  static const one = 'M4 5h16v14H4z';
  static const swap = 'M7 7h11l-3-3M17 17H6l3 3';
  static const rotate = 'M20 11a8 8 0 10-2.3 5.7M20 5v6h-6';
  static const kbd = 'M3 7h18v10H3zM7 11h.01M11 11h.01M15 11h.01M8 14h8';
  static const sparkle =
      'M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8z';
  static const external = 'M14 4h6v6M20 4l-9 9';
  static const eye =
      'M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12zM12 9a3 3 0 100 6 3 3 0 000-6z';
  static const info = 'M12 8v.01M11 12h1v5h1M12 3a9 9 0 100 18 9 9 0 000-18z';
  static const panel = 'M4 5h16v14H4zM15 5v14';
  static const undo = 'M9 14L4 9l5-5M4 9h11a5 5 0 010 10h-4';
  static const redo = 'M15 14l5-5-5-5M20 9H9a5 5 0 000 10h4';
  static const download = 'M12 4v11M7 10l5 5 5-5M5 20h14';
}

/// 官方 / 编辑器 svg 图标（`assets/icons/<name>`）。
class ToolsIcon extends StatelessWidget {
  const ToolsIcon(this.name, {super.key, this.size = 16, this.color});
  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => GenNaiIcon(
    name.contains('.') ? name : '$name.svg',
    size: size,
    color: color,
  );
}

/// 价格：`N ⟡`；`0` 写“免费”、[local] 写“本机 · 免费”（成功色）；null 写“…”。
class ToolsPrice extends StatelessWidget {
  const ToolsPrice({
    super.key,
    required this.cost,
    this.local = false,
    this.size = 11,
    this.color,
  });

  final int? cost;
  final bool local;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    if (local || cost == 0) {
      return Text(
        local ? l.tools_localFree : l.tools_free,
        maxLines: 1,
        style: UiText.sans(
          size,
          weight: FontWeight.w600,
          color: c.ok,
          height: 1.2,
        ),
      );
    }
    final ink = color ?? c.muted;
    return GenAnlas(
      cost == null ? '…' : '$cost',
      size: size,
      iconSize: size - 1,
      color: ink,
      weight: FontWeight.w600,
    );
  }
}

enum ToolsButtonTone { normal, primary, ghost }

/// 按钮（原型 `.btn`）：32 高、圆角 8、13 / w500；[small] 28 高、12.5。
/// 主按钮品牌蓝 w600，可带价格段（左边一道 35% 白线）。
class ToolsButton extends StatelessWidget {
  const ToolsButton({
    super.key,
    required this.children,
    this.onTap,
    this.tone = ToolsButtonTone.normal,
    this.small = false,
    this.cost,
    this.padding,
    this.color,
    this.radius,
  });

  final List<Widget> children;
  final VoidCallback? onTap;
  final ToolsButtonTone tone;
  final bool small;

  /// 主按钮右边的价格段（`ToolsPrice` 白字版、或“免费”文字）。
  final Widget? cost;
  final EdgeInsets? padding;

  /// 覆盖文字色（幽灵按钮的强调色链接）。
  final Color? color;
  final BorderRadius? radius;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final primary = tone == ToolsButtonTone.primary;
    final b = UiPressable(
      onTap: onTap,
      builder: (context, hover) {
        final (bg, border, fg) = switch (tone) {
          ToolsButtonTone.primary => (
            hover ? Color.lerp(c.brand, Colors.black, .08)! : c.brand,
            c.brand,
            c.onBrand,
          ),
          ToolsButtonTone.ghost => (
            hover ? c.hover : Colors.transparent,
            Colors.transparent,
            hover ? c.ink : c.muted,
          ),
          ToolsButtonTone.normal => (hover ? c.hover : c.raised, c.line, c.ink),
        };
        final ink = color ?? fg;
        return Container(
          height: small ? 28 : 32,
          padding: padding ?? EdgeInsets.symmetric(horizontal: small ? 10 : 14),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: radius ?? BorderRadius.circular(small ? 7 : 8),
          ),
          child: IconTheme.merge(
            data: IconThemeData(color: ink),
            child: DefaultTextStyle.merge(
              style: UiText.sans(
                small ? 12.5 : 13,
                weight: primary ? FontWeight.w600 : FontWeight.w500,
                color: ink,
              ),
              maxLines: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 7,
                children: [
                  ...children,
                  if (cost != null)
                    Container(
                      padding: const EdgeInsets.only(left: 9),
                      margin: const EdgeInsets.only(left: 2),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Colors.white.withValues(alpha: .35),
                          ),
                        ),
                      ),
                      child: cost,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return onTap == null ? Opacity(opacity: .4, child: b) : b;
  }
}

/// 主按钮上的价格段：白字 `N ⟡` / “免费”。
class ToolsButtonCost extends StatelessWidget {
  const ToolsButtonCost(this.cost, {super.key, this.insufficient = false});
  final int? cost;
  final bool insufficient;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    const ink = Colors.white;
    if (cost == 0) {
      return Text(
        l.tools_free,
        style: UiText.sans(
          12.5,
          weight: FontWeight.w600,
          color: ink,
          height: 1.2,
        ),
      );
    }
    return GenAnlas(
      cost == null ? '…' : '$cost',
      size: 12.5,
      iconSize: 12,
      weight: FontWeight.w600,
      color: insufficient ? const Color(0xFFFFB3B8) : ink,
    );
  }
}

/// 方形图标按钮（原型 `.ib`）：32、圆角 8、次要色；[on] 强调色 12% 底。
class ToolsIb extends StatelessWidget {
  const ToolsIb({
    super.key,
    this.glyph,
    this.icon,
    this.onTap,
    this.tooltip,
    this.size = 32,
    this.glyphSize = 16,
    this.on = false,
    this.color,
  });

  final String? glyph;

  /// svg 图标（`assets/icons/`）代替 [glyph]。
  final String? icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final double glyphSize;
  final bool on;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final b = UiPressable(
      onTap: onTap,
      builder: (context, hover) {
        final ink = color ?? (on ? c.accent : (hover ? c.ink : c.muted));
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on
                ? c.accent.withValues(alpha: .12)
                : (hover ? c.control : null),
            borderRadius: BorderRadius.circular(size >= 32 ? 8 : 6),
          ),
          child: icon != null
              ? ToolsIcon(icon!, size: glyphSize, color: ink)
              : UiGlyph(glyph!, size: glyphSize, color: ink),
        );
      },
    );
    final shown = onTap == null ? Opacity(opacity: .35, child: b) : b;
    return tooltip == null
        ? shown
        : Tooltip(
            message: tooltip,
            waitDuration: const Duration(milliseconds: 400),
            child: shown,
          );
  }
}

/// 竖分隔（原型 `.vdiv`）：1 × 22、左右 6。
class ToolsVDiv extends StatelessWidget {
  const ToolsVDiv({super.key, this.height = 22, this.margin = 6});
  final double height;
  final double margin;

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: height,
    margin: EdgeInsets.symmetric(horizontal: margin),
    color: context.ui.line,
  );
}

/// 分段（原型 `.seg`）：30 高、控件底、内边距 2、段间距 2、圆角 8；选中段圆角 6、抬起底 + 细影、w600。
class ToolsSeg<T> extends StatelessWidget {
  const ToolsSeg({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.label,
    this.height = 30,
    this.expand = false,
    this.disabled = false,
    this.keyOf,
    this.tooltipOf,
  });

  final List<T> values;
  final T? selected;
  final ValueChanged<T>? onChanged;
  final Widget Function(BuildContext context, T value, bool on) label;
  final double height;

  /// 撑满宽度、各段等分。
  final bool expand;

  /// 整组变灰（自定义强度时的幅度分段）。
  final bool disabled;
  final Key? Function(T value)? keyOf;
  final String? Function(T value)? tooltipOf;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    Widget item(T v) {
      final on = !disabled && v == selected;
      final seg = UiPressable(
        key: keyOf?.call(v),
        onTap: disabled || on || onChanged == null ? null : () => onChanged!(v),
        builder: (context, hover) => Container(
          height: height - 4,
          padding: expand ? null : const EdgeInsets.symmetric(horizontal: 11),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? (c.dark ? const Color(0xFF333333) : c.raised) : null,
            borderRadius: BorderRadius.circular(6),
            boxShadow: on
                ? const [
                    BoxShadow(
                      color: Color(0x24000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: DefaultTextStyle.merge(
            style: UiText.sans(
              12.5,
              weight: on ? FontWeight.w600 : FontWeight.w400,
              color: on || hover ? c.ink : c.muted,
            ),
            maxLines: 1,
            child: label(context, v, on),
          ),
        ),
      );
      final tip = tooltipOf?.call(v);
      final shown = tip == null ? seg : Tooltip(message: tip, child: seg);
      return expand ? Expanded(child: shown) : shown;
    }

    final box = Container(
      height: height,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        spacing: 2,
        children: [for (final v in values) item(v)],
      ),
    );
    return disabled ? Opacity(opacity: .4, child: box) : box;
  }
}

/// 一行“标签 + 内容”（原型 `.frow`）：最小高 34、间距 12；标签宽 56、12.5 次要色。
class ToolsFieldRow extends StatelessWidget {
  const ToolsFieldRow({
    super.key,
    required this.label,
    required this.children,
    this.labelWidth = 56,
  });
  final String label;
  final List<Widget> children;
  final double labelWidth;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 34),
    child: Row(
      spacing: 12,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: UiText.sans(12.5, color: context.ui.muted),
          ),
        ),
        ...children,
      ],
    ),
  );
}

/// 滑杆 + 数字框（选项条、右栏）：拖动时界面实时显示，松手才回调 [onChanged]（[live] 时拖动中也回调）。
class ToolsSlider extends StatefulWidget {
  const ToolsSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.decimals = 2,
    this.width,
    this.suffix,
    this.display,
    this.live = false,
    this.enabled = true,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int decimals;

  /// 滑杆宽（选项条里定宽）；null = 撑满。
  final double? width;
  final String? suffix;

  /// 数字框里的写法（`+8`、`85%`）；null = 按 [decimals]。
  final String Function(double v)? display;

  /// 拖动中也回调（调色实时预览）。
  final bool live;
  final bool enabled;

  @override
  State<ToolsSlider> createState() => _ToolsSliderState();
}

class _ToolsSliderState extends State<ToolsSlider> {
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
    final c = context.ui;
    final v = _drag ?? widget.value;
    final slider = UiSlider(
      value: _norm(v),
      onChanged: widget.enabled
          ? (t) {
              final next = _denorm(t);
              setState(() => _drag = next);
              if (widget.live) widget.onChanged(next);
            }
          : null,
      onChangeEnd: widget.enabled
          ? (t) {
              final value = _drag ?? _denorm(t);
              setState(() => _drag = null);
              widget.onChanged(value);
            }
          : null,
    );
    // 数值块（原型 `.num`）：26 高、最小宽 48、右对齐、等宽 12 / w500。
    final box = Container(
      height: 26,
      constraints: const BoxConstraints(minWidth: 48),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.centerRight,
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        widget.display?.call(v) ??
            '${v.toStringAsFixed(widget.decimals)}${widget.suffix ?? ''}',
        maxLines: 1,
        style: UiText.mono(
          12,
          weight: FontWeight.w500,
          color: c.ink,
          height: 1.2,
        ),
      ),
    );
    return Row(
      mainAxisSize: widget.width == null ? MainAxisSize.max : MainAxisSize.min,
      spacing: 10,
      children: [
        if (widget.width == null)
          Expanded(child: slider)
        else
          SizedBox(width: widget.width, child: slider),
        box,
      ],
    );
  }
}

/// 开关 + 文字，整行可点。
class ToolsSwitchLabel extends StatelessWidget {
  const ToolsSwitchLabel({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.muted = false,
  });
  final bool value;
  final String label;
  final ValueChanged<bool>? onChanged;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      builder: (context, hover) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 7,
        children: [
          UiSwitch(value: value),
          Text(
            label,
            maxLines: 1,
            style: UiText.sans(12, color: muted ? c.muted : c.ink),
          ),
        ],
      ),
    );
  }
}

/// 灰底小胶囊（原型 `.chip`）：26 高、圆角 7、左右 9、12 号字。
class ToolsChip extends StatelessWidget {
  const ToolsChip({
    super.key,
    required this.children,
    this.onTap,
    this.height = 26,
    this.mono = false,
    this.background,
    this.foreground,
  });
  final List<Widget> children;
  final VoidCallback? onTap;
  final double height;
  final bool mono;
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) {
        final ink = foreground ?? c.ink;
        return Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: background ?? (hover ? c.hover : c.control),
            borderRadius: BorderRadius.circular(7),
          ),
          child: DefaultTextStyle.merge(
            style: mono
                ? UiText.mono(12, weight: FontWeight.w500, color: ink)
                : UiText.sans(12, color: ink),
            maxLines: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: children,
            ),
          ),
        );
      },
    );
  }
}

/// 右栏分节（原型 `.ps`）：内边距 14 / 16、底部分隔线；标题 12.5 / w600、下边距 10。
class ToolsPanelSection extends StatelessWidget {
  const ToolsPanelSection({
    super.key,
    this.title,
    this.badge,
    this.trailing = const [],
    required this.child,
    this.border = true,
    this.background,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 14),
    this.titleInset = 0,
    this.expand = false,
  });
  final String? title;

  /// 撑满父级高度，[child] 占标题下面的全部空间（图层列表、结果列表）。
  final bool expand;

  /// 紧跟标题的小标签（“当前图层”）。
  final Widget? badge;
  final List<Widget> trailing;
  final Widget child;
  final bool border;
  final Color? background;
  final EdgeInsets padding;

  /// 标题行再往里缩（列表行左右出血时，[padding] 给小、标题补回来）。
  final double titleInset;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        border: border ? Border(bottom: BorderSide(color: c.line)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: EdgeInsets.fromLTRB(titleInset, 0, titleInset, 10),
              child: SizedBox(
                // 原型 h4 跟着里面最高的走：右边有 26 的图标按钮时 26。
                height: trailing.isEmpty ? 18 : 26,
                child: Row(
                  spacing: 6,
                  children: [
                    Text(
                      title!,
                      style: UiText.sans(
                        12.5,
                        weight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                    ?badge,
                    if (trailing.isNotEmpty) ...[const Spacer(), ...trailing],
                  ],
                ),
              ),
            ),
          if (expand) Expanded(child: child) else child,
        ],
      ),
    );
  }
}

/// 小节标题（原型 `.sec`）：11.5 / w500 弱色、下边距 8。
class ToolsSec extends StatelessWidget {
  const ToolsSec(this.text, {super.key, this.trailing = const []});
  final String text;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        spacing: 6,
        children: [
          Text(
            text,
            style: UiText.sans(11.5, weight: FontWeight.w500, color: c.faint),
          ),
          ...trailing,
        ],
      ),
    );
  }
}

/// 图上的深色角标（原型 `.ptag`）：24 高、圆角 6、55% 黑底白字 11.5。
class ToolsPaneTag extends StatelessWidget {
  const ToolsPaneTag(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    height: 24,
    padding: const EdgeInsets.symmetric(horizontal: 9),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .55),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      maxLines: 1,
      style: UiText.sans(11.5, color: Colors.white, height: 1.2),
    ),
  );
}
