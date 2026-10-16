import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_svg_icon.dart';
import '../kit/ui_text.dart';
import 'settings_contract.dart';
import 'settings_scope.dart';

/// 设置页专用的小件，尺寸照 `.devin/mockups/settings/mock.html`。

/// 设置页额外的几种颜色（原型 `--line`、`--sunk`）。
extension SettingsColors on UiColors {
  /// 卡片里行与行之间的分隔线（比描边更淡）。
  Color get rowLine => dark ? const Color(0xFF212121) : const Color(0xFFEFEFEF);

  /// 下沉底：路径框、提示框、预览框。
  Color get sunk => dark ? const Color(0xFF131313) : const Color(0xFFF7F7F7);

  /// 搜索命中的底色。
  Color get mark => const Color(0x8CFFD21F);

  /// 存储占用分类色（数据图表色，浅深通用）。
  Color storage(SettingsStorageKind k) => switch (k) {
    SettingsStorageKind.images => accent,
    SettingsStorageKind.upscaleModels => const Color(0xFF8E4EC6),
    SettingsStorageKind.vibes => const Color(0xFF12A594),
    SettingsStorageKind.thumbnails => const Color(0xFFD48A00),
    SettingsStorageKind.ragIndex => const Color(0xFFE5484D),
    SettingsStorageKind.dictionaries => const Color(0xFFA8A8A8),
    SettingsStorageKind.agent => const Color(0xFF7A7A7A),
  };
}

/// 设置页里额外的线性图标（照抄原型 `const P`）。
abstract final class SettingsGlyphs {
  static const undo = 'M9 14L4 9l5-5M4 9h10a6 6 0 010 12h-3';
  static const key = 'M3 7h18v11H3zM7 11h.01M11 11h.01M15 11h.01M8 14.5h8';
  static const bell = 'M6 16v-5a6 6 0 0112 0v5l2 2H4zM10 21h4';
  static const spark =
      'M12 3l1.8 5.4L19 10l-5.2 1.6L12 17l-1.8-5.4L5 10l5.2-1.6zM19 16l.8 2.2L22 19l-2.2.8L19 22l-.8-2.2L16 19l2.2-.8z';
  static const hub =
      'M12 9.5a2.5 2.5 0 100 5 2.5 2.5 0 000-5zM5 5a2 2 0 100 .01M19 5a2 2 0 100 .01M5 19a2 2 0 100 .01M19 19a2 2 0 100 .01M6.5 6.5l3.6 3.6M17.5 6.5l-3.6 3.6M6.5 17.5l3.6-3.6M17.5 17.5l-3.6-3.6';
  static const globe =
      'M12 21a9 9 0 100-18 9 9 0 000 18zM3 12h18M12 3c3 3.5 3 14.5 0 18M12 3c-3 3.5-3 14.5 0 18';
  static const backup = 'M4 12a8 8 0 108-8 8 8 0 00-6 2.7M4 4v4h4M12 8v4l3 2';
  static const canvas = 'M3 5h18v12H3zM8 21h8M12 17v4';
  static const folder =
      'M3 7a2 2 0 012-2h4l2 2h8a2 2 0 012 2v8a2 2 0 01-2 2H5a2 2 0 01-2-2z';
  static const external = 'M14 4h6v6M20 4l-9 9M18 14v5H5V6h5';
  static const copy = 'M9 9h11v11H9zM5 15V4h11';
  static const trash = 'M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13';
  static const upload = 'M12 16V4M7 9l5-5 5 5M5 20h14';
  static const warn = 'M12 4l9 16H3zM12 10v4M12 17h.01';
  static const lock = 'M6 11h12v9H6zM9 11V8a3 3 0 016 0v3';
  static const gpu = 'M3 7h18v10H3zM7 17v3M17 17v3M8 10h3v4H8zM14 10h3v4h-3z';
  static const file = 'M6 3h8l4 4v14H6zM14 3v4h4';
  static const minimize = 'M5 12h14';
  static const maximize = 'M6 6h12v12H6z';
}

/// 服务商图标：已知厂商使用随包 SVG，自定义端点使用字母标记。
class SettingsLogo extends StatelessWidget {
  const SettingsLogo({
    super.key,
    required this.mark,
    required this.color,
    this.logoAsset,
    this.size = 28,
  });
  final String? mark;
  final int color;
  final String? logoAsset;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (logoAsset case final asset?) {
      return UiSvgIcon.asset(
        'assets/icons/providers/$asset.svg',
        size: size,
        colorFilter: ColorFilter.mode(context.ui.ink, BlendMode.srcIn),
        excludeFromSemantics: true,
      );
    }
    if (mark == null) {
      return UiGlyph(SettingsGlyphs.hub, size: size, color: context.ui.ink);
    }
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color(color),
        borderRadius: BorderRadius.circular(size * .25),
      ),
      child: Text(
        mark!,
        style: UiText.mono(
          size * .43,
          weight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

/// 搜索跳转的目标（不是 [SettingsRow] 的卡片、选项块）：滚到可见并闪一下强调色环。
class SettingsAnchor extends StatefulWidget {
  const SettingsAnchor({
    super.key,
    required this.anchor,
    required this.child,
    this.radius = 10,
  });
  final String anchor;
  final Widget child;
  final double radius;

  @override
  State<SettingsAnchor> createState() => _SettingsAnchorState();
}

class _SettingsAnchorState extends State<SettingsAnchor> {
  var _done = false;

  @override
  Widget build(BuildContext context) {
    final lit = SettingsScope.maybeOf(context)?.highlight == widget.anchor;
    if (lit && !_done) {
      _done = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Scrollable.ensureVisible(context, alignment: .3);
      });
    } else if (!lit) {
      _done = false;
    }
    if (!lit) return widget.child;
    final c = context.ui;
    return DecoratedBox(
      key: Key('settings-anchor-${widget.anchor}'),
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        border: Border.all(color: c.accent, width: 1.5),
      ),
      child: widget.child,
    );
  }
}

/// 账号头像：首字 + 底色。
class SettingsAvatar extends StatelessWidget {
  const SettingsAvatar({
    super.key,
    required this.name,
    this.color,
    this.size = 36,
    this.radius = 9,
    this.fontSize = 15,
  });

  final String name;
  final int? color;
  final double size;
  final double radius;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: color == null ? const Color(0xFF1F6BFF) : Color(color!),
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Text(
      name.characters.isEmpty ? '?' : name.characters.first,
      style: UiText.sans(
        fontSize,
        weight: FontWeight.w700,
        color: Colors.white,
        height: 1,
      ),
    ),
  );
}

/// 大号读数（原型 `.big`）：Geist Mono 500，行高 1。
TextStyle settingsBig(BuildContext context, {double size = 34}) => UiText.mono(
  size,
  weight: FontWeight.w500,
  color: context.ui.ink,
  height: 1,
  letterSpacing: -.02 * size,
);

/// 6px 圆点（状态色）。
class SettingsDot extends StatelessWidget {
  const SettingsDot(this.tone, {super.key, this.size = 7});
  final SettingsTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (tone) {
          SettingsTone.ok => c.ok,
          SettingsTone.warn => c.warn,
          SettingsTone.error => c.error,
          SettingsTone.idle => c.faint,
        },
      ),
    );
  }
}

/// 键帽（原型 `.kbd`）：高 20、圆角 5、1px 描边 + 2px 底边、Geist Mono 11。
class SettingsKey extends StatelessWidget {
  const SettingsKey(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final side = BorderSide(color: c.border);
    return Container(
      constraints: const BoxConstraints(
        minWidth: 20,
        minHeight: 20,
        maxHeight: 20,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(5),
        border: Border(
          left: side,
          top: side,
          right: side,
          bottom: side.copyWith(width: 2),
        ),
      ),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          label,
          style: UiText.mono(
            11,
            weight: FontWeight.w500,
            color: c.muted,
            height: 1,
          ),
        ),
      ),
    );
  }
}

/// 一组键帽，间距 3。
class SettingsKeys extends StatelessWidget {
  const SettingsKeys(this.keys, {super.key});
  final List<String> keys;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 3,
    children: [for (final k in keys) SettingsKey(k)],
  );
}

/// 文字里夹键帽：把 [text] 里的 `{keys}` 换成 [keys]。
class SettingsKeyText extends StatelessWidget {
  const SettingsKeyText({
    super.key,
    required this.text,
    required this.keys,
    this.style,
  });

  /// 已经把占位替换成 `\u0000` 的文案（见 [SettingsFormat.keyed]）。
  final String text;
  final List<String> keys;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final parts = text.split('\u0000');
    return Text.rich(
      TextSpan(
        children: [
          for (final (i, p) in parts.indexed) ...[
            if (i > 0)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: SettingsKeys(keys),
                ),
              ),
            TextSpan(text: p),
          ],
        ],
      ),
      style: style,
    );
  }
}

/// 小标签（原型 `.mini`）。
class SettingsMini extends StatelessWidget {
  const SettingsMini(this.text, {super.key, this.tone = UiMiniTone.plain});
  final String text;
  final UiMiniTone tone;

  @override
  Widget build(BuildContext context) => UiMini(text, tone: tone);
}

enum SettingsBtnTone { normal, primary, ghost, danger }

/// 按钮（原型 `.btn` / `.btn.sm`）：30 高、左右 12、圆角 7；小号 26 高、左右 9、圆角 6。
/// [trailingChevron] 时图标放在文字后面（“去设置 ›”这种跳转）。
class SettingsBtn extends StatelessWidget {
  const SettingsBtn({
    super.key,
    required this.label,
    this.glyph,
    this.onTap,
    this.small = false,
    this.tone = SettingsBtnTone.normal,
    this.trailingChevron = false,
    this.tooltip,
  });

  final String label;
  final String? glyph;
  final VoidCallback? onTap;
  final bool small;
  final SettingsBtnTone tone;
  final bool trailingChevron;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final h = small ? 26.0 : 30.0;
    final btn = UiPressable(
      onTap: onTap,
      builder: (context, hover) {
        final (bg, border, fg) = switch (tone) {
          SettingsBtnTone.primary => (
            hover ? Color.lerp(c.brand, Colors.black, .08)! : c.brand,
            c.brand,
            c.onBrand,
          ),
          SettingsBtnTone.ghost => (
            hover ? c.hover : Colors.transparent,
            Colors.transparent,
            hover ? c.ink : c.muted,
          ),
          SettingsBtnTone.danger => (
            hover ? c.hover : c.card,
            Color.lerp(c.border, c.error, .35)!,
            c.error,
          ),
          SettingsBtnTone.normal => (hover ? c.hover : c.card, c.border, c.ink),
        };
        final icon = glyph == null && !trailingChevron
            ? null
            : UiGlyph(
                trailingChevron ? UiGlyphs.chevronRight : glyph!,
                size: trailingChevron ? 13 : 14,
                color: fg,
              );
        return Container(
          height: h,
          padding: EdgeInsets.symmetric(horizontal: small ? 9 : 12),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(small ? 6 : 7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: trailingChevron ? 2 : 6,
            children: [
              if (icon != null && !trailingChevron) icon,
              Text(
                label,
                maxLines: 1,
                style: UiText.sans(
                  small ? 12 : 12.5,
                  weight: FontWeight.w500,
                  color: fg,
                  height: 1.2,
                ),
              ),
              if (icon != null && trailingChevron) icon,
            ],
          ),
        );
      },
    );
    final shown = onTap == null ? Opacity(opacity: .45, child: btn) : btn;
    return tooltip == null ? shown : Tooltip(message: tooltip, child: shown);
  }
}

/// 26 × 26 透明图标按钮（原型 `.ib`）。
class SettingsIconBtn extends StatelessWidget {
  const SettingsIconBtn({
    super.key,
    required this.glyph,
    required this.tooltip,
    this.onTap,
    this.size = 26,
    this.glyphSize = 14,
  });

  final String glyph;
  final String tooltip;
  final VoidCallback? onTap;
  final double size;
  final double glyphSize;

  @override
  Widget build(BuildContext context) => UiIconBox(
    glyph: glyph,
    tooltip: tooltip,
    onTap: onTap,
    size: size,
    glyphSize: glyphSize,
  );
}

/// 开关（原型 `.sw`）：30 × 18。
class SettingsSwitch extends StatelessWidget {
  const SettingsSwitch({super.key, required this.value, this.onChanged});
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: value,
    child: UiPressable(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      builder: (context, _) => UiSwitch(value: value, width: 30, height: 18),
    ),
  );
}

/// 胶囊（原型 `.chip`）：26 高、圆角 13、控件底；选中强调色浅底。
class SettingsChip extends StatelessWidget {
  const SettingsChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.count,
    this.onRemove,
    this.mono = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final int? count;
  final VoidCallback? onRemove;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) {
        final fg = selected ? c.accent : c.ink;
        return Container(
          height: 26,
          padding: EdgeInsets.only(left: 10, right: onRemove == null ? 10 : 6),
          decoration: BoxDecoration(
            color: selected
                ? Color.alphaBlend(c.accent.withValues(alpha: .12), c.card)
                : (hover ? c.hover : c.control),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Text(
                label,
                maxLines: 1,
                style: mono
                    ? UiText.mono(11.5, color: fg, height: 1.2)
                    : UiText.sans(
                        12,
                        weight: selected ? FontWeight.w500 : FontWeight.w400,
                        color: fg,
                        height: 1.2,
                      ),
              ),
              if (count != null)
                Text(
                  '$count',
                  style: UiText.mono(
                    11,
                    color: fg.withValues(alpha: .6),
                    height: 1.2,
                  ),
                ),
              if (onRemove != null)
                UiPressable(
                  onTap: onRemove,
                  builder: (context, h) => UiGlyph(
                    UiGlyphs.close,
                    size: 11,
                    color: h ? c.ink : c.faint,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// 进度条（原型 `.bar`）：6 高、圆角 3。
class SettingsBar extends StatelessWidget {
  const SettingsBar({
    super.key,
    required this.value,
    this.color,
    this.height = 6,
    this.width,
  });

  final double value;
  final Color? color;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: c.control),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value.clamp(0, 1),
              child: ColoredBox(color: color ?? c.accent),
            ),
          ],
        ),
      ),
    );
  }
}

/// 只截头部、保留尾部的单行文字（路径显示最后几级）。
class SettingsTailText extends StatelessWidget {
  const SettingsTailText(this.text, {super.key, required this.style});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final dir = Directionality.of(context);
      final scale = MediaQuery.textScalerOf(context);
      bool fits(String s) {
        final tp = TextPainter(
          text: TextSpan(text: s, style: style),
          textDirection: dir,
          textScaler: scale,
          maxLines: 1,
        )..layout();
        return tp.width <= constraints.maxWidth;
      }

      var shown = text;
      if (constraints.hasBoundedWidth && !fits(text)) {
        var lo = 0, hi = text.length;
        while (lo < hi) {
          final mid = (lo + hi) ~/ 2;
          if (fits('…${text.substring(mid)}')) {
            hi = mid;
          } else {
            lo = mid + 1;
          }
        }
        shown = '…${text.substring(math.min(lo, text.length))}';
      }
      return Text(shown, maxLines: 1, softWrap: false, style: style);
    },
  );
}

/// 路径框（原型 `.path`）：30 高、下沉底、Geist Mono 12，尾部按钮 26。
class SettingsPathBox extends StatelessWidget {
  const SettingsPathBox({
    super.key,
    required this.path,
    this.tag,
    this.actions = const [],
  });

  final String path;
  final String? tag;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      height: 30,
      padding: const EdgeInsets.only(left: 10, right: 4),
      decoration: BoxDecoration(
        color: c.sunk,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        spacing: 6,
        children: [
          Expanded(
            child: SettingsTailText(
              path,
              style: UiText.mono(12, color: c.ink, height: 1.2),
            ),
          ),
          if (tag != null)
            Text(tag!, style: UiText.sans(11, color: c.faint, height: 1.2)),
          ...actions,
        ],
      ),
    );
  }
}

/// 表单输入框（原型 `.inp`）：30 高、圆角 7、卡片底；聚焦时强调色描边 + 3px 浅环。
class SettingsInput extends StatefulWidget {
  const SettingsInput({
    super.key,
    required this.value,
    this.onSubmitted,
    this.hint,
    this.mono = false,
    this.width,
    this.obscure = false,
    this.leading,
    this.onChanged,
  });

  final String value;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final bool mono;
  final double? width;
  final bool obscure;
  final Widget? leading;

  @override
  State<SettingsInput> createState() => _SettingsInputState();
}

class _SettingsInputState extends State<SettingsInput> {
  late final _ctrl = TextEditingController(text: widget.value);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      setState(() {});
      if (!_focus.hasFocus && _ctrl.text != widget.value) {
        widget.onSubmitted?.call(_ctrl.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant SettingsInput old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value && !_focus.hasFocus) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final on = _focus.hasFocus;
    final style = widget.mono
        ? UiText.mono(12, color: c.ink, height: 1.2)
        : UiText.sans(12.5, color: c.ink, height: 1.2);
    return Container(
      width: widget.width,
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: on ? c.accent : c.border),
        boxShadow: on
            ? [
                BoxShadow(
                  color: c.accent.withValues(alpha: .16),
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      child: Row(
        spacing: 8,
        children: [
          ?widget.leading,
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              obscureText: widget.obscure,
              style: style,
              cursorColor: c.accent,
              cursorHeight: 14,
              decoration: uiBareDecoration(
                hintText: widget.hint,
                hintStyle: style.copyWith(color: c.faint),
              ),
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
            ),
          ),
        ],
      ),
    );
  }
}

/// 数值框（原型 `.num`）：− 值 +；点数值可以直接输入。
class SettingsStepper extends StatefulWidget {
  const SettingsStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    this.step = 1,
    this.unit,
    this.decimals = 0,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final double step;
  final String? unit;
  final int decimals;

  @override
  State<SettingsStepper> createState() => _SettingsStepperState();
}

class _SettingsStepperState extends State<SettingsStepper> {
  var _editing = false;
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _editing) _commit();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _fmt(double v) => v.toStringAsFixed(widget.decimals);

  void _set(double v) {
    final clamped = v.clamp(widget.min, widget.max).toDouble();
    if (clamped != widget.value) widget.onChanged(clamped);
  }

  void _commit() {
    final v = double.tryParse(_ctrl.text.trim());
    setState(() => _editing = false);
    if (v != null) _set(v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    Widget side(String glyph, double delta, bool enabled) => UiPressable(
      onTap: enabled ? () => _set(widget.value + delta) : null,
      builder: (context, hover) => Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        color: hover ? c.hover : null,
        child: UiGlyph(glyph, size: 13, color: enabled ? c.muted : c.strong),
      ),
    );
    final valueStyle = UiText.mono(
      12.5,
      weight: FontWeight.w500,
      color: c.ink,
      height: 1.2,
    );
    return Container(
      height: 30,
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(7),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            side(UiGlyphs.minus, -widget.step, widget.value > widget.min),
            Container(
              constraints: const BoxConstraints(minWidth: 58),
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                border: Border.symmetric(vertical: BorderSide(color: c.border)),
              ),
              alignment: Alignment.center,
              child: _editing
                  ? SizedBox(
                      width: 50,
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        style: valueStyle,
                        cursorColor: c.accent,
                        cursorHeight: 14,
                        decoration: uiBareDecoration(),
                        onSubmitted: (_) => _commit(),
                      ),
                    )
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() {
                        _editing = true;
                        _ctrl.text = _fmt(widget.value);
                        _ctrl.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _ctrl.text.length,
                        );
                      }),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 4,
                        children: [
                          Text(_fmt(widget.value), style: valueStyle),
                          if (widget.unit != null)
                            Text(
                              widget.unit!,
                              style: UiText.sans(
                                11,
                                color: c.faint,
                                height: 1.2,
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            side(UiGlyphs.plus, widget.step, widget.value < widget.max),
          ],
        ),
      ),
    );
  }
}

/// 滑块（原型 `.sld`）：4 高的轨道、14 的白色圆钮、可选刻度，右侧 Geist Mono 读数。
/// 拖动时只改显示，松手才回调（自动保存不刷屏）。
class SettingsSlider extends StatefulWidget {
  const SettingsSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.label,
    this.width = 160,
    this.step,
    this.ticks = 0,
  });

  final double value;
  final double min;
  final double max;
  final double? step;
  final ValueChanged<double> onChanged;
  final String Function(double v) label;
  final double width;
  final int ticks;

  @override
  State<SettingsSlider> createState() => _SettingsSliderState();
}

class _SettingsSliderState extends State<SettingsSlider> {
  double? _drag;

  double _snap(double v) {
    final s = widget.step;
    final x = v.clamp(widget.min, widget.max).toDouble();
    if (s == null || s <= 0) return x;
    return (widget.min + ((x - widget.min) / s).round() * s)
        .clamp(widget.min, widget.max)
        .toDouble();
  }

  double _at(double dx) =>
      _snap(widget.min + (dx / widget.width) * (widget.max - widget.min));

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final v = _drag ?? widget.value;
    final t = widget.max == widget.min
        ? 0.0
        : ((v - widget.min) / (widget.max - widget.min)).clamp(0.0, 1.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => widget.onChanged(_at(d.localPosition.dx)),
            onHorizontalDragUpdate: (d) =>
                setState(() => _drag = _at(d.localPosition.dx)),
            onHorizontalDragEnd: (_) {
              final x = _drag;
              setState(() => _drag = null);
              if (x != null && x != widget.value) widget.onChanged(x);
            },
            child: SizedBox(
              width: widget.width,
              height: 18,
              child: CustomPaint(
                painter: _SliderPainter(
                  t: t,
                  ticks: widget.ticks,
                  track: c.control,
                  fill: c.accent,
                  tick: c.strong,
                  knobBorder: c.strong,
                ),
              ),
            ),
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 40),
          child: Text(
            widget.label(v),
            textAlign: TextAlign.right,
            style: UiText.mono(
              12,
              weight: FontWeight.w500,
              color: c.ink,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

class _SliderPainter extends CustomPainter {
  _SliderPainter({
    required this.t,
    required this.ticks,
    required this.track,
    required this.fill,
    required this.tick,
    required this.knobBorder,
  });

  final double t;
  final int ticks;
  final Color track;
  final Color fill;
  final Color tick;
  final Color knobBorder;

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final r = RRect.fromLTRBR(
      0,
      cy - 2,
      size.width,
      cy + 2,
      const Radius.circular(2),
    );
    canvas.drawRRect(r, Paint()..color = track);
    canvas.drawRRect(
      RRect.fromLTRBR(
        0,
        cy - 2,
        size.width * t,
        cy + 2,
        const Radius.circular(2),
      ),
      Paint()..color = fill,
    );
    if (ticks > 0) {
      final p = Paint()..color = tick;
      for (var i = 0; i <= ticks; i++) {
        final x = size.width * i / ticks;
        canvas.drawRect(Rect.fromLTWH(x, cy + 6, 1, 4), p);
      }
    }
    final k = Offset(size.width * t, cy);
    canvas.drawCircle(
      k + const Offset(0, 1),
      7.5,
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5),
    );
    canvas.drawCircle(k, 7, Paint()..color = Colors.white);
    canvas.drawCircle(
      k,
      6.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = knobBorder,
    );
  }

  @override
  bool shouldRepaint(_SliderPainter o) =>
      o.t != t || o.ticks != ticks || o.track != track || o.fill != fill;
}

/// 下拉框（原型 `.sel`）：30 高、圆角 7、描边；点开是菜单。
class SettingsSelect extends StatefulWidget {
  const SettingsSelect({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.width = 180,
    this.leading,
    this.menuWidth,
  });

  final String label;
  final List<SettingsOption> options;
  final String? selected;
  final ValueChanged<String> onSelected;
  final double width;
  final Widget? leading;
  final double? menuWidth;

  @override
  State<SettingsSelect> createState() => _SettingsSelectState();
}

class _SettingsSelectState extends State<SettingsSelect> {
  UiPopoverAnchor? _anchor;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPopover(
      anchor: _anchor,
      onDismiss: () => setState(() => _anchor = null),
      builder: (context) => UiMenu(
        width: widget.menuWidth ?? math.max(widget.width, 200),
        onClose: () => setState(() => _anchor = null),
        items: [
          for (final o in widget.options)
            UiMenuItem(
              key: Key('settings-option-${o.value}'),
              label: o.label,
              trailing: o.detail,
              checked: o.value == widget.selected,
              onTap: () => widget.onSelected(o.value),
            ),
        ],
      ),
      child: Builder(
        builder: (context) => UiPressable(
          onTap: widget.options.isEmpty
              ? null
              : () {
                  final box = context.findRenderObject()! as RenderBox;
                  setState(
                    () => _anchor = UiPopoverAnchor(
                      box.localToGlobal(Offset(0, box.size.height + 4)),
                    ),
                  );
                },
          builder: (context, hover) => Container(
            width: widget.width,
            height: 30,
            padding: const EdgeInsets.only(left: 11, right: 9),
            decoration: BoxDecoration(
              color: hover ? c.hover : c.card,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              spacing: 8,
              children: [
                ?widget.leading,
                Expanded(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: UiText.sans(12.5, color: c.ink, height: 1.2),
                  ),
                ),
                UiGlyph(UiGlyphs.chevronDown, size: 14, color: c.faint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [open] 时在 [child] 右下方弹出菜单（右对齐）。
class SettingsPopupMenu extends StatefulWidget {
  const SettingsPopupMenu({
    super.key,
    required this.open,
    required this.onClose,
    required this.items,
    required this.child,
  });

  final bool open;
  final VoidCallback onClose;

  /// (文字, 点击, 是否危险)。
  final List<(String, VoidCallback, bool)> items;
  final Widget child;

  @override
  State<SettingsPopupMenu> createState() => _SettingsPopupMenuState();
}

class _SettingsPopupMenuState extends State<SettingsPopupMenu> {
  final _key = GlobalKey();

  UiPopoverAnchor? get _anchor {
    if (!widget.open) return null;
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return null;
    return UiPopoverAnchor(
      box.localToGlobal(box.size.bottomRight(const Offset(0, 4))),
      alignRight: true,
    );
  }

  @override
  Widget build(BuildContext context) => UiPopover(
    anchor: _anchor,
    onDismiss: widget.onClose,
    builder: (context) => UiMenu(
      width: 184,
      onClose: widget.onClose,
      items: [
        for (final (i, (label, onTap, danger)) in widget.items.indexed)
          UiMenuItem(
            key: Key('menu-$label'),
            label: label,
            danger: danger,
            divider: danger && i > 0,
            onTap: onTap,
          ),
      ],
    ),
    child: KeyedSubtree(key: _key, child: widget.child),
  );
}

/// 小节（原型 `.sec`）：标题 13.5 / 600 + 一句说明，下面一张卡片；节与节之间 30。
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    this.subtitle,
    this.badge,
    this.trailing,
    required this.children,
    this.bare = false,
  });

  final String title;
  final String? subtitle;
  final Widget? badge;
  final Widget? trailing;
  final List<Widget> children;

  /// 不包卡片（内容自己是卡片）。
  final bool bare;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        spacing: 6,
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: UiText.sans(
                                13.5,
                                weight: FontWeight.w600,
                                color: c.ink,
                              ),
                            ),
                          ),
                          ?badge,
                        ],
                      ),
                      if (subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            subtitle!,
                            style: UiText.sans(12, color: c.muted, height: 1.5),
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              ],
            ),
          ),
          if (bare) ...children else SettingsCard(children: children),
        ],
      ),
    );
  }
}

/// 卡片（原型 `.card`）：卡片底、1px 描边、圆角 11；子项之间画淡分隔线。
class SettingsCard extends StatelessWidget {
  const SettingsCard({super.key, required this.children, this.divided = true});
  final List<Widget> children;
  final bool divided;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, w) in children.indexed) ...[
            if (i > 0 && divided) Container(height: 1, color: c.rowLine),
            w,
          ],
        ],
      ),
    );
  }
}

/// 卡片里的一块自由内容（原型 `.blk`）：内边距 16 18。
class SettingsBlock extends StatelessWidget {
  const SettingsBlock({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding ?? const EdgeInsets.fromLTRB(18, 16, 18, 16),
    child: child,
  );
}

/// 设置行（原型 `.rw`）：左标题 + 说明，右控件；最低 58。
/// [sub] 是挂在上一行下面的子项（左缩进 46、细线连到父项）。[anchor] 用于搜索跳转高亮。
class SettingsRow extends StatefulWidget {
  const SettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.control,
    this.leading,
    this.badges = const [],
    this.sub = false,
    this.disabled = false,
    this.modified = false,
    this.onReset,
    this.anchor,
    this.titleStyle,
    this.minHeight,
    this.alignTop = false,
    this.below,
    this.belowSpacing = 10,
    this.titleLead,
    this.padding,
    this.titleWidget,
    this.subtitleWidget,
  });

  /// 标题下面整宽的内容（选项卡片、进度条……）。
  final Widget? below;
  final double belowSpacing;

  /// 标题文字前的小件（状态点）。
  final Widget? titleLead;
  final EdgeInsets? padding;

  final String title;
  final String? subtitle;

  /// 代替 [title] / [subtitle] 文字（搜索结果的高亮）。
  final Widget? titleWidget;
  final Widget? subtitleWidget;
  final Widget? control;
  final Widget? leading;
  final List<Widget> badges;
  final bool sub;
  final bool disabled;
  final bool modified;
  final VoidCallback? onReset;
  final String? anchor;
  final TextStyle? titleStyle;
  final double? minHeight;
  final bool alignTop;

  @override
  State<SettingsRow> createState() => _SettingsRowState();
}

class _SettingsRowState extends State<SettingsRow> {
  var _hover = false;
  var _jumped = false;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final scope = SettingsScope.maybeOf(context);
    final lit = widget.anchor != null && scope?.highlight == widget.anchor;
    if (lit && !_jumped) {
      _jumped = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Scrollable.ensureVisible(
          context,
          alignment: .3,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 260),
        );
      });
    } else if (!lit) {
      _jumped = false;
    }
    final title = Row(
      key: const Key('settings-row-title'),
      spacing: 7,
      children: [
        ?widget.titleLead,
        Flexible(
          child:
              widget.titleWidget ??
              Text(
                widget.title,
                style:
                    widget.titleStyle ??
                    UiText.sans(13, weight: FontWeight.w500, color: c.ink),
              ),
        ),
        if (widget.modified) const _ModDot(),
        ...widget.badges,
      ],
    );
    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        title,
        if (widget.subtitleWidget != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: widget.subtitleWidget,
          )
        else if (widget.subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              widget.subtitle!,
              style: UiText.sans(12, color: c.muted, height: 1.55),
            ),
          ),
        if (widget.below != null) ...[
          SizedBox(height: widget.belowSpacing),
          widget.below!,
        ],
      ],
    );
    final reset = widget.modified && widget.onReset != null
        ? AnimatedOpacity(
            opacity: _hover ? 1 : 0,
            duration: const Duration(milliseconds: 120),
            child: SettingsIconBtn(
              glyph: SettingsGlyphs.undo,
              tooltip: l.set_resetDefault,
              onTap: widget.onReset,
            ),
          )
        : null;
    Widget body = LayoutBuilder(
      builder: (context, constraints) {
        final stack = widget.control != null && constraints.maxWidth < 520;
        final control = widget.control == null
            ? null
            : IgnorePointer(
                ignoring: widget.disabled,
                child: Opacity(
                  opacity: widget.disabled ? .45 : 1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [?reset, widget.control!],
                  ),
                ),
              );
        final dimLabel = Opacity(
          opacity: widget.disabled ? .45 : 1,
          child: label,
        );
        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Row(
                children: [
                  ?widget.leading,
                  Expanded(child: dimLabel),
                ],
              ),
              Align(alignment: Alignment.centerRight, child: control),
            ],
          );
        }
        return Row(
          crossAxisAlignment: widget.alignTop
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          spacing: 24,
          children: [
            if (widget.leading != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 0,
                children: [widget.leading!],
              ),
            Expanded(child: dimLabel),
            ?control,
          ],
        );
      },
    );
    body = Container(
      constraints: BoxConstraints(
        minHeight: widget.minHeight ?? (widget.sub ? 50 : 58),
      ),
      padding:
          widget.padding ??
          EdgeInsets.fromLTRB(widget.sub ? 46 : 18, 13, 18, 13),
      alignment: Alignment.centerLeft,
      child: body,
    );
    if (widget.sub) {
      body = CustomPaint(painter: _SubLinePainter(c.border), child: body);
    }
    if (lit) {
      body = TweenAnimationBuilder<double>(
        key: ValueKey('hl-${widget.anchor}'),
        tween: Tween(begin: 1, end: 0),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 2200),
        curve: const Interval(.3, 1),
        builder: (context, t, child) => ColoredBox(
          color: c.accent.withValues(
            alpha: .10 * (MediaQuery.disableAnimationsOf(context) ? 1 : t),
          ),
          child: child,
        ),
        child: body,
      );
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: KeyedSubtree(
        key: widget.anchor == null
            ? null
            : Key('settings-row-${widget.anchor}'),
        child: body,
      ),
    );
  }
}

class _ModDot extends StatelessWidget {
  const _ModDot();

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('settings-modified-dot'),
    width: 6,
    height: 6,
    decoration: BoxDecoration(color: context.ui.accent, shape: BoxShape.circle),
  );
}

/// 在标签末尾以 7px 间距显示“已修改”蓝点，空间不足时允许文字换行。
class SettingsModMark extends StatelessWidget {
  const SettingsModMark({super.key, required this.on, required this.child});
  final bool on;
  final Widget child;

  @override
  Widget build(BuildContext context) => !on
      ? child
      : Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 7,
          children: [
            Flexible(child: child),
            const _ModDot(),
          ],
        );
}

/// 子项左侧连到父项的 L 形细线（原型 `.rw.sub::before`）。
class _SubLinePainter extends CustomPainter {
  _SubLinePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final mid = size.height / 2;
    final path = Path()
      ..moveTo(26.75, -1)
      ..lineTo(26.75, mid - 6)
      ..arcToPoint(
        Offset(32.75, mid - .75),
        radius: const Radius.circular(6),
        clockwise: false,
      )
      ..lineTo(36.75, mid - .75);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_SubLinePainter o) => o.color != color;
}

/// 侧注卡片（原型 `.ac`）：内边距 14 16；标题 12 / 600，右侧弱色说明。
class SettingsAsideCard extends StatelessWidget {
  const SettingsAsideCard({
    super.key,
    required this.title,
    this.trailing,
    this.badge,
    this.minTitleHeight = 0,
    required this.child,
  });

  final String title;
  final String? trailing;
  final Widget? badge;

  /// 保留原有标题行高度，移除标签时侧卡正文不挪动。
  final double minTitleHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minTitleHeight),
              child: Row(
                spacing: 6,
                children: [
                  Text(
                    title,
                    style: UiText.sans(
                      12,
                      weight: FontWeight.w600,
                      color: c.ink,
                    ),
                  ),
                  ?badge,
                  const Spacer(),
                  if (trailing != null)
                    Text(trailing!, style: UiText.sans(11, color: c.faint)),
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// 侧注里的一行（原型 `.al`）：上下 6、虚线分隔。
class SettingsAsideList extends StatelessWidget {
  const SettingsAsideList({super.key, required this.rows, this.padding = 6});
  final List<Widget> rows;

  /// 每行上下内边距。
  final double padding;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, r) in rows.indexed) ...[
          if (i > 0)
            CustomPaint(
              size: const Size(double.infinity, 1),
              painter: _DashPainter(c.rowLine),
            ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: padding),
            child: r,
          ),
        ],
      ],
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (double x = 0; x < size.width; x += 6) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 3, 1), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter o) => o.color != color;
}

/// 提示框（原型 `.hint`）：下沉底、圆角 9、图标 14、12 号字行高 1.6。
class SettingsHint extends StatelessWidget {
  const SettingsHint({
    super.key,
    required this.child,
    this.glyph = UiGlyphs.infoCircle,
  });
  final Widget child;
  final String glyph;

  static Widget text(
    BuildContext context,
    String text, {
    String glyph = UiGlyphs.infoCircle,
  }) => SettingsHint(
    glyph: glyph,
    child: Text(
      text,
      style: UiText.sans(12, color: context.ui.muted, height: 1.6),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: BoxDecoration(
        color: c.sunk,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 9,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: UiGlyph(glyph, size: 14, color: c.faint),
          ),
          Expanded(
            child: DefaultTextStyle.merge(
              style: UiText.sans(12, color: c.muted, height: 1.6),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// 选项卡片（原型 `.opt`）：圆角 10、内边距 10；选中强调色描边 + 3px 浅环。
class SettingsOptionCard extends StatelessWidget {
  const SettingsOptionCard({
    super.key,
    required this.selected,
    required this.preview,
    required this.label,
    this.description,
    this.badge,
    this.onTap,
  });

  final bool selected;
  final Widget preview;
  final String label;
  final String? description;
  final Widget? badge;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: c.card,
          border: Border.all(
            color: selected ? c.accent : (hover ? c.strong : c.border),
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: c.accent.withValues(alpha: .13),
                    spreadRadius: 3,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            preview,
            const SizedBox(height: 10),
            Row(
              spacing: 8,
              children: [
                UiRadio(value: selected),
                Flexible(
                  child: Text(
                    label,
                    style: UiText.sans(
                      12.5,
                      weight: FontWeight.w500,
                      color: c.ink,
                    ),
                  ),
                ),
                ?badge,
              ],
            ),
            if (description != null)
              Padding(
                padding: const EdgeInsets.only(left: 24, top: 3),
                child: Text(
                  description!,
                  style: UiText.sans(11.5, color: c.muted, height: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 页头（原型 `.eb` + `h1` + `.pd`）。
class SettingsPageTitle extends StatelessWidget {
  const SettingsPageTitle({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            spacing: 8,
            children: [
              Container(width: 14, height: 1, color: c.strong),
              Text(
                eyebrow.toUpperCase(),
                style: UiText.mono(
                  11,
                  weight: FontWeight.w500,
                  color: c.faint,
                  letterSpacing: 1.54,
                  height: 14 / 11,
                ),
              ),
            ],
          ),
        ),
        Text(
          title,
          style: UiText.sans(
            24,
            weight: FontWeight.w600,
            color: c.ink,
            height: 1.25,
            letterSpacing: -.24,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              description,
              style: UiText.sans(13, color: c.muted, height: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}

/// 页面框架：正文与侧注整体居中；正文最宽 780、侧注 292、间距 40。
/// 窄时侧注移到正文下面。
class SettingsPageFrame extends StatelessWidget {
  const SettingsPageFrame({
    super.key,
    required this.title,
    required this.children,
    this.aside = const [],
    this.top = const [],
    this.wide = false,
  });

  final Widget title;
  final List<Widget> top;
  final List<Widget> children;
  final List<Widget> aside;

  /// 不要侧注，内容最宽 1112（模型页、搜索结果）。
  final bool wide;

  static const asideWidth = 292.0;
  static const contentMax = 780.0;
  static const gap = 40.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 1000;
      final pad = narrow ? 24.0 : 48.0;
      final inner = constraints.maxWidth - pad * 2;
      final side = !wide && aside.isNotEmpty && inner >= 560 + gap + asideWidth;
      final contentWidth = wide
          ? math.min(inner, contentMax + gap + asideWidth)
          : side
          ? math.min(contentMax, inner - gap - asideWidth)
          : math.min(contentMax, inner);
      final content = SizedBox(
        width: contentWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [title, ...top, ...children],
        ),
      );
      final asideCol = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: aside,
      );
      return SingleChildScrollView(
        key: const Key('settings-scroll'),
        padding: EdgeInsets.fromLTRB(pad, 34, pad, 120),
        child: Align(
          alignment: Alignment.topCenter,
          child: side
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    content,
                    const SizedBox(width: gap),
                    SizedBox(width: asideWidth, child: asideCol),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    content,
                    if (!wide && aside.isNotEmpty)
                      SizedBox(width: contentWidth, child: asideCol),
                  ],
                ),
        ),
      );
    },
  );
}

/// 等宽网格：[columns] 列、间距 12；窄时减列。
class SettingsGrid extends StatelessWidget {
  const SettingsGrid({
    super.key,
    required this.columns,
    required this.children,
    this.gap = 12,
    this.minItem = 150,
  });
  final int columns;
  final List<Widget> children;
  final double gap;
  final double minItem;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      var n = columns;
      while (n > 1 && (constraints.maxWidth - gap * (n - 1)) / n < minItem) {
        n--;
      }
      final w = (constraints.maxWidth - gap * (n - 1)) / n;
      final rows = <Widget>[];
      for (var i = 0; i < children.length; i += n) {
        rows.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: gap,
              children: [
                for (var j = i; j < math.min(i + n, children.length); j++)
                  SizedBox(width: w, child: children[j]),
              ],
            ),
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: gap,
        children: rows,
      );
    },
  );
}
