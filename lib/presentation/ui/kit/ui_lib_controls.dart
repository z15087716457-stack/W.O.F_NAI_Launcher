import 'package:flutter/material.dart';

import 'ui_colors.dart';
import 'ui_controls.dart';
import 'ui_glyph.dart';
import 'ui_text.dart';

/// 库页（在线画廊、Vibe 库、块库……）共用的小控件，尺寸照库页原型的通用控件。

enum UiBtnSize {
  /// 26 高、圆角 6、12 号字。
  small,

  /// 30 高、圆角 7、12.5 号字。
  normal,

  /// 36 高、圆角 8、13.5 号字。
  large,
}

enum UiBtnTone {
  /// 抬起底 + 描边。
  normal,

  /// 品牌蓝实心。
  primary,

  /// 透明、次要文字色。
  ghost,

  /// 强调色描边和文字（“完成多选”这类正在进行的状态）。
  accent,

  /// 进化紫实心（画风探索的“开始进化 / 培育下一代”）。
  evo,
}

/// 按钮：图标 + 文字，间距 6，500 字重。
class UiBtn extends StatelessWidget {
  const UiBtn({
    super.key,
    required this.children,
    this.onTap,
    this.size = UiBtnSize.normal,
    this.tone = UiBtnTone.normal,
    this.color,
    this.expand = false,
    this.padding,
    this.tooltip,
  });

  final List<Widget> children;
  final VoidCallback? onTap;
  final UiBtnSize size;
  final UiBtnTone tone;

  /// 覆盖文字和图标色（例如“已收藏”的红色）。
  final Color? color;

  /// 撑满宽度、内容居中。
  final bool expand;
  final EdgeInsets? padding;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final (h, pad, radius, font) = switch (size) {
      UiBtnSize.small => (26.0, 9.0, 6.0, 12.0),
      UiBtnSize.normal => (30.0, 11.0, 7.0, 12.5),
      UiBtnSize.large => (36.0, 14.0, 8.0, 13.5),
    };
    final button = UiPressable(
      onTap: onTap,
      builder: (context, hover) {
        final (bg, border, fg) = switch (tone) {
          UiBtnTone.primary => (
            hover ? Color.lerp(c.brand, Colors.black, .08)! : c.brand,
            c.brand,
            c.onBrand,
          ),
          UiBtnTone.ghost => (
            hover ? c.hover : Colors.transparent,
            Colors.transparent,
            hover ? c.ink : c.muted,
          ),
          UiBtnTone.accent => (hover ? c.hover : c.raised, c.accent, c.accent),
          UiBtnTone.evo => (
            hover ? Color.lerp(c.evo, Colors.black, .08)! : c.evo,
            c.evo,
            c.onEvo,
          ),
          UiBtnTone.normal => (hover ? c.hover : c.raised, c.line, c.ink),
        };
        final ink = color ?? fg;
        return Container(
          height: h,
          padding: padding ?? EdgeInsets.symmetric(horizontal: pad),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: IconTheme.merge(
            data: IconThemeData(color: ink),
            child: DefaultTextStyle.merge(
              style: UiText.sans(font, weight: FontWeight.w500, color: ink),
              maxLines: 1,
              child: Row(
                mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 6,
                children: children,
              ),
            ),
          ),
        );
      },
    );
    // 不可点（onTap 为 null）时整体 45% 不透明度。
    final shown = onTap == null ? Opacity(opacity: .45, child: button) : button;
    return tooltip == null ? shown : Tooltip(message: tooltip, child: shown);
  }
}

enum UiIconBoxTone {
  /// 透明底、次要色。
  plain,

  /// 强调色 10% 底 + 强调色图标（开关打开）。
  on,

  /// 描边 + 抬起底。
  bordered,
}

/// 方形图标按钮：默认 30、圆角 7。
class UiIconBox extends StatelessWidget {
  const UiIconBox({
    super.key,
    required this.glyph,
    this.onTap,
    this.tooltip,
    this.size = 30,
    this.glyphSize = 15,
    this.tone = UiIconBoxTone.plain,
    this.color,
    this.filled = false,
  });

  final String glyph;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final double glyphSize;
  final UiIconBoxTone tone;
  final Color? color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final box = UiPressable(
      onTap: onTap,
      builder: (context, hover) {
        final on = tone == UiIconBoxTone.on;
        return Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on
                ? c.accent.withValues(alpha: .10)
                : hover
                ? c.hover
                : tone == UiIconBoxTone.bordered
                ? c.raised
                : null,
            border: tone == UiIconBoxTone.bordered
                ? Border.all(color: c.line)
                : null,
            borderRadius: BorderRadius.circular(7),
          ),
          child: UiGlyph(
            glyph,
            size: glyphSize,
            filled: filled,
            color: color ?? (on ? c.accent : (hover ? c.ink : c.muted)),
          ),
        );
      },
    );
    return tooltip == null ? box : Tooltip(message: tooltip, child: box);
  }
}

/// 分段控件（库页小号）：控件底、内边距 2、圆角 7；项高 24、圆角 5、12 号字。
/// 选中项浅色是抬起底 + 细阴影，深色是悬停底、无阴影。
class UiSeg<T> extends StatelessWidget {
  const UiSeg({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
    this.labelOf,
    this.glyphOf,
    this.tooltipOf,
    this.small = true,
  });

  final List<T> values;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T value)? labelOf;

  /// 只有图标的项（例如卡片大小的“小”）。
  final String? Function(T value)? glyphOf;
  final String? Function(T value)? tooltipOf;

  /// false 时项高 26、内边距 10、12.5 号字（排行的日 / 周 / 月）。
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.control,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          for (final v in values)
            _SegItem(
              key: ValueKey(v),
              label: labelOf?.call(v),
              glyph: glyphOf?.call(v),
              tooltip: tooltipOf?.call(v),
              selected: v == selected,
              small: small,
              onTap: () => onChanged(v),
            ),
        ],
      ),
    );
  }
}

class _SegItem extends StatelessWidget {
  const _SegItem({
    super.key,
    required this.label,
    required this.glyph,
    required this.tooltip,
    required this.selected,
    required this.small,
    required this.onTap,
  });

  final String? label;
  final String? glyph;
  final String? tooltip;
  final bool selected;
  final bool small;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final item = UiPressable(
      onTap: selected ? null : onTap,
      builder: (context, hover) {
        final fg = selected || hover ? c.ink : c.muted;
        return Container(
          height: small ? 24 : 26,
          padding: EdgeInsets.symmetric(horizontal: small ? 8 : 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? (c.dark ? c.hover : c.raised) : null,
            borderRadius: BorderRadius.circular(5),
            boxShadow: selected && !c.dark
                ? const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: glyph != null
              ? UiGlyph(glyph!, size: 13, color: fg)
              : Text(
                  label ?? '',
                  maxLines: 1,
                  style: UiText.sans(
                    small ? 12 : 12.5,
                    weight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: fg,
                  ),
                ),
        );
      },
    );
    return tooltip == null ? item : Tooltip(message: tooltip, child: item);
  }
}

/// 筛选胶囊：28 高、圆角 14、描边；打开时强调色描边 / 浅底 / 加粗。
class UiFilterChip extends StatelessWidget {
  const UiFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.leading,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
    this.gap = 6,
    this.showCheck = false,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? leading;

  /// 文字后面的计数（Geist Mono 11，弱一级）。
  final int? count;
  final EdgeInsets padding;
  final double gap;

  /// 打开时前面画一个勾（“仅 NAI 图片”）。
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) {
        final fg = selected ? c.accent : (hover ? c.ink : c.muted);
        return Container(
          height: 28,
          padding: padding,
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(c.accent.withValues(alpha: .08), c.raised)
                : (hover ? c.hover : c.raised),
            border: Border.all(
              color: selected ? c.accent.withValues(alpha: .55) : c.line,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: gap,
            children: [
              if (showCheck && selected)
                UiGlyph(UiGlyphs.check, size: 13, strokeWidth: 2.4, color: fg),
              if (leading != null) leading!,
              Text(
                label,
                maxLines: 1,
                style: UiText.sans(
                  12,
                  weight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: fg,
                ),
              ),
              if (count != null)
                Text(
                  '$count',
                  style: UiText.mono(
                    11,
                    color: fg.withValues(alpha: .7),
                    height: 1.2,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 下拉胶囊：28 高、圆角 7、控件底；前面可放图标或说明，后面向下箭头。
class UiDropChip extends StatelessWidget {
  const UiDropChip({
    super.key,
    required this.label,
    this.onTap,
    this.glyph,
    this.prefix,
    this.expand = false,
  });

  final String label;
  final VoidCallback? onTap;
  final String? glyph;

  /// 撑满宽度：文字占满、箭头靠右（检查器里的分类下拉）。
  final bool expand;

  /// 弱色前缀文字（例如“排序”）。
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) => Container(
        height: 28,
        padding: const EdgeInsets.only(left: 10, right: 8),
        decoration: BoxDecoration(
          color: hover ? c.hover : c.control,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          spacing: 6,
          children: [
            if (glyph != null) UiGlyph(glyph!, size: 14, color: c.muted),
            if (prefix != null)
              Text(prefix!, style: UiText.sans(12.5, color: c.muted)),
            if (expand)
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiText.sans(12.5, color: c.ink),
                ),
              )
            else
              Text(label, maxLines: 1, style: UiText.sans(12.5, color: c.ink)),
            UiGlyph(UiGlyphs.chevronDown, size: 13, color: c.ink),
          ],
        ),
      ),
    );
  }
}

enum UiMiniTone { plain, ok, warn, accent, error }

/// 小标签：18 高、圆角 4、10.5 / w600；可带一个 10px 图标（间距 3）。
class UiMini extends StatelessWidget {
  const UiMini(
    this.text, {
    super.key,
    this.tone = UiMiniTone.plain,
    this.glyph,
    this.background,
    this.foreground,
  });
  final String text;
  final UiMiniTone tone;
  final String? glyph;

  /// 覆盖底色 / 字色（图片上的深色角标）。
  final Color? background;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final (bg, fg) = switch (tone) {
      UiMiniTone.plain => (c.control, c.muted),
      UiMiniTone.ok => (c.ok.withValues(alpha: .11), c.ok),
      UiMiniTone.warn => (c.warn.withValues(alpha: .13), c.warn),
      UiMiniTone.accent => (c.accent.withValues(alpha: .11), c.accent),
      UiMiniTone.error => (c.error.withValues(alpha: .10), c.error),
    };
    final ink = foreground ?? fg;
    final label = Text(
      text,
      maxLines: 1,
      style: UiText.sans(
        10.5,
        weight: FontWeight.w600,
        color: ink,
        height: 1.2,
      ),
    );
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: background ?? bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        widthFactor: 1,
        child: glyph == null
            ? label
            : Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 3,
                children: [
                  UiGlyph(glyph!, size: 10, strokeWidth: 2.4, color: ink),
                  label,
                ],
              ),
      ),
    );
  }
}

/// 竖分隔线：1 × 18。
class UiVSep extends StatelessWidget {
  const UiVSep({super.key, this.height = 18, this.color});
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: height, color: color ?? context.ui.line);
}

/// 复选框：16、圆角 4、1.5 描边；勾上是强调色实心 + 白勾。
class UiCheckBox extends StatelessWidget {
  const UiCheckBox({super.key, required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      width: 16,
      height: 16,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: value ? c.accent : null,
        border: Border.all(color: value ? c.accent : c.strong, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: value
          ? const UiGlyph(
              UiGlyphs.check,
              size: 11,
              strokeWidth: 3,
              color: Colors.white,
            )
          : null,
    );
  }
}

/// 单选圈：16、1.5 描边；选中是强调色描边 + 内圆点。
class UiRadio extends StatelessWidget {
  const UiRadio({super.key, required this.value});
  final bool value;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      width: 16,
      height: 16,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: value ? c.accent : c.strong, width: 1.5),
      ),
      child: value
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: c.accent,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}

/// 无边框输入框的装饰：不吃主题里的填充和描边，内容贴边（外框由调用方画）。
InputDecoration uiBareDecoration({String? hintText, TextStyle? hintStyle}) =>
    InputDecoration(
      isCollapsed: true,
      isDense: true,
      filled: false,
      hintText: hintText,
      hintStyle: hintStyle,
      contentPadding: EdgeInsets.zero,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
    );
