import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart' show uiBareDecoration;
import '../kit/ui_svg_icon.dart';
import '../kit/ui_text.dart';
import '../settings/settings_contract.dart' show SettingsTone;
import '../settings/settings_format.dart';
import '../settings/settings_kit.dart';
import 'model_providers_contract.dart';

/// 服务商页用到、原型里新增的图标（照抄 `.devin/mockups/model-providers/app.js`）。
abstract final class ProvidersGlyphs {
  static const tool =
      'M14.7 6.3a4 4 0 00-5.4 5.4L4 17l3 3 5.3-5.3a4 4 0 005.4-5.4l-2.5 2.5-2.4-.6-.6-2.4z';
  static const braces =
      'M8 4H7a2 2 0 00-2 2v3a2 2 0 01-2 2 2 2 0 012 2v3a2 2 0 002 2h1M16 4h1a2 2 0 012 2v3a2 2 0 002 2 2 2 0 00-2 2v3a2 2 0 01-2 2h-1';
  static const bulb =
      'M9 18h6M10 21h4M12 3a6 6 0 00-3.6 10.8c.4.3.6.8.6 1.3V16h6v-.9c0-.5.2-1 .6-1.3A6 6 0 0012 3z';
  static const layers = 'M12 3l9 5-9 5-9-5zM3 13l9 5 9-5';
  static const alert = 'M12 21a9 9 0 100-18 9 9 0 000 18zM12 8v5M12 16h.01';
  static const image = 'M4 5h16v14H4zM4 16l5-5 4 4 3-3 4 4M15.5 9.5h.01';
  static const info = 'M12 21a9 9 0 100-18 9 9 0 000 18zM12 11v6M12 7.5h.01';
  static const eye =
      'M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12zM12 15a3 3 0 100-6 3 3 0 000 6z';
  static const trash = 'M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13';
  static const more = 'M5 12h.01M12 12h.01M19 12h.01';

  static String capability(ProviderCapability c) => switch (c) {
    ProviderCapability.vision => image,
    ProviderCapability.tools => tool,
    ProviderCapability.search => SettingsGlyphs.globe,
  };
}

/// 能力名。
String providerCapabilityLabel(BuildContext context, ProviderCapability c) {
  final l = context.l10n;
  return switch (c) {
    ProviderCapability.vision => l.mp_capVision,
    ProviderCapability.tools => l.mp_capTools,
    ProviderCapability.search => l.mp_capSearch,
  };
}

/// 思考档位名（`none` → 关闭 …）。
String providerLevelLabel(BuildContext context, String? id) {
  final l = context.l10n;
  return switch (id) {
    null => l.mp_followService,
    'none' || 'off' => l.modelReasoning_off,
    'minimal' => l.modelReasoning_minimal,
    'low' => l.modelReasoning_low,
    'medium' => l.modelReasoning_medium,
    'high' => l.modelReasoning_high,
    'xhigh' => l.modelReasoning_xhigh,
    'max' => l.modelReasoning_max,
    _ => id,
  };
}

/// token 数：128000 → 128K，1000000 → 1M。
String providerTokens(int? v) {
  if (v == null) return '—';
  String trim(double x) {
    final s = x.toStringAsFixed(x == x.roundToDouble() ? 0 : 1);
    return s;
  }

  if (v >= 1000000) return '${trim(v / 1000000)}M';
  if (v >= 1000) return '${trim(v / 1000)}K';
  return '$v';
}

/// “128k” / “1.5M” / “32000” → token 数。
int? providerParseTokens(String s) {
  final m = RegExp(r'^\s*(\d+(?:\.\d+)?)\s*([kKmM]?)\s*$').firstMatch(s);
  if (m == null) return null;
  final n = double.parse(m[1]!);
  final mul = switch (m[2]!.toLowerCase()) {
    'k' => 1000,
    'm' => 1000000,
    _ => 1,
  };
  final v = (n * mul).round();
  return v > 0 ? v : null;
}

/// 服务商图标：品牌 SVG 放在下沉底的圆角块里（单色跟随前景）；自定义端点画字母块。
class ProviderLogo extends StatelessWidget {
  const ProviderLogo({
    super.key,
    this.logoAsset,
    this.mark,
    this.color = 0xFF7C5CFF,
    this.size = 28,
    this.dashed = false,
  });

  final String? logoAsset;
  final String? mark;
  final int color;
  final double size;

  /// 虚线加号块（“自定义端点”）。
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final r = BorderRadius.circular((size * .28).roundToDouble());
    if (logoAsset == null && mark != null && !dashed) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Color(color), borderRadius: r),
        child: Text(
          mark!,
          style: UiText.sans(
            (size * .4).roundToDouble(),
            weight: FontWeight.w700,
            color: Colors.white,
            height: 1,
          ),
        ),
      );
    }
    final inner = (size * .58).roundToDouble();
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.sunk,
        borderRadius: r,
        border: Border.all(color: dashed ? c.strong : c.border),
      ),
      child: logoAsset != null
          ? UiSvgIcon.asset(
              'assets/icons/providers/$logoAsset.svg',
              size: inner,
              colorFilter: ColorFilter.mode(c.ink, BlendMode.srcIn),
              excludeFromSemantics: true,
            )
          : UiGlyph(
              dashed ? UiGlyphs.plus : SettingsGlyphs.hub,
              size: dashed ? 15 : inner,
              color: c.muted,
            ),
    );
  }

  static ProviderLogo of(ProviderItem p, {double size = 28}) => ProviderLogo(
    logoAsset: p.logoAsset,
    mark: p.mark,
    color: p.color,
    size: size,
  );
}

/// 状态胶囊：26 高、圆角 13；成功 “● 96 ms · 刚刚”，失败 / 受限用状态色底。
class ProviderStatusPill extends StatelessWidget {
  const ProviderStatusPill({super.key, required this.item, required this.now});
  final ProviderItem item;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    final p = item;
    final tone = p.enabled ? p.status : SettingsTone.idle;
    final (bg, border) = switch (tone) {
      SettingsTone.error => (
        Color.alphaBlend(c.error.withValues(alpha: .07), c.card),
        Color.lerp(c.border, c.error, .28)!,
      ),
      SettingsTone.warn => (
        Color.alphaBlend(c.warn.withValues(alpha: .08), c.card),
        Color.lerp(c.border, c.warn, .30)!,
      ),
      _ => (c.sunk, c.border),
    };
    final children = <InlineSpan>[];
    if (!p.enabled) {
      children.add(
        TextSpan(
          text: l.set_mdDisabled,
          style: TextStyle(color: c.faint),
        ),
      );
    } else if (p.testing) {
      children.add(
        TextSpan(
          text: l.mp_testing,
          style: TextStyle(color: c.muted),
        ),
      );
    } else if (tone == SettingsTone.ok) {
      children.addAll([
        TextSpan(
          text: p.latencyMs == null ? '—' : SettingsFormat.ms(p.latencyMs!),
          style: UiText.mono(12, color: c.ok, height: 1.2),
        ),
        if (p.checkedAt != null)
          TextSpan(
            text: ' · ${SettingsFormat.ago(context, p.checkedAt!, now)}',
            style: TextStyle(color: c.faint),
          ),
      ]);
    } else if (tone == SettingsTone.idle) {
      children.add(
        TextSpan(
          text: l.mp_notChecked,
          style: TextStyle(color: c.faint),
        ),
      );
    } else {
      children.add(
        TextSpan(
          text: p.error.isEmpty ? l.set_mdUnreachable : p.error,
          style: TextStyle(
            color: tone == SettingsTone.error ? c.error : c.warn,
          ),
        ),
      );
    }
    return Container(
      key: const Key('mp-status'),
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          if (p.testing) const UiSpinner(size: 10) else SettingsDot(tone),
          Flexible(
            child: Text.rich(
              TextSpan(children: children),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: UiText.sans(12, color: c.muted, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}

/// 表单字段（原型 `.fld`）：上面 11.5 号标签（可带 ⓘ 悬停说明），下面控件，间距 6。
class ProviderField extends StatelessWidget {
  const ProviderField({
    super.key,
    required this.label,
    required this.child,
    this.help,
    this.error,
  });
  final String label;
  final Widget child;
  final String? help;

  /// 控件下方的红字。
  final String? error;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 4,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: UiText.sans(11.5, color: c.muted),
              ),
            ),
            if (help != null)
              Tooltip(
                message: help,
                child: UiGlyph(ProvidersGlyphs.info, size: 12, color: c.faint),
              ),
          ],
        ),
        child,
        if (error != null)
          Text(error!, style: UiText.sans(11, color: c.error, height: 1.3)),
      ],
    );
  }
}

/// 输入框（原型 `.inp`）：30 高、圆角 7；可带尾部按钮、错误描边。输入即回调 [onChanged]。
/// [ghost] 是未聚焦时显示的占位（例如已保存 Key 的掩码），用正文色而不是弱色。
class ProviderInput extends StatefulWidget {
  const ProviderInput({
    super.key,
    required this.value,
    this.onChanged,
    this.onSubmitted,
    this.hint,
    this.ghost,
    this.mono = false,
    this.error = false,
    this.trailing = const [],
    this.autofocus = false,
    this.height = 30,
    this.obscure = false,
  });

  final String value;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? hint;
  final String? ghost;
  final bool mono;
  final bool error;
  final List<Widget> trailing;
  final bool autofocus;
  final double height;
  final bool obscure;

  @override
  State<ProviderInput> createState() => _ProviderInputState();
}

class _ProviderInputState extends State<ProviderInput> {
  late final _ctrl = TextEditingController(text: widget.value);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!mounted) return;
      setState(() {});
      if (_focus.hasFocus) return;
      widget.onSubmitted?.call(_ctrl.text);
      // 编辑期间外面的值变了（例如放弃草稿）而这一帧没再重建：失焦后补一次同步。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focus.hasFocus && widget.value != _ctrl.text) {
          setState(() => _ctrl.text = widget.value);
        }
      });
    });
  }

  @override
  void didUpdateWidget(covariant ProviderInput old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text && !_focus.hasFocus) {
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
    final ghost = widget.ghost != null && !on;
    return Container(
      height: widget.height,
      padding: EdgeInsets.only(
        left: 10,
        right: widget.trailing.isEmpty ? 10 : 4,
      ),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: widget.error
              ? Color.lerp(c.border, c.error, .55)!
              : on
              ? c.accent
              : c.border,
        ),
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
        spacing: 2,
        children: [
          Expanded(
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              autofocus: widget.autofocus,
              obscureText: widget.obscure,
              style: style,
              cursorColor: c.accent,
              cursorHeight: 14,
              decoration: uiBareDecoration(
                hintText: ghost ? widget.ghost : widget.hint,
                hintStyle: style.copyWith(color: ghost ? c.ink : c.faint),
              ),
              onChanged: (v) {
                setState(() {});
                widget.onChanged?.call(v);
              },
              onSubmitted: widget.onSubmitted,
            ),
          ),
          ...widget.trailing,
        ],
      ),
    );
  }
}

/// 22 × 22 小图标按钮（输入框尾部、键值行删除）。
class ProviderTinyBtn extends StatelessWidget {
  const ProviderTinyBtn({
    super.key,
    required this.glyph,
    required this.tooltip,
    this.onTap,
    this.glyphSize = 14,
  });
  final String glyph;
  final String tooltip;
  final VoidCallback? onTap;
  final double glyphSize;

  @override
  Widget build(BuildContext context) => SettingsIconBtn(
    glyph: glyph,
    tooltip: tooltip,
    onTap: onTap,
    size: 22,
    glyphSize: glyphSize,
  );
}

/// 数值框（原型 `.num.sm`）：28 高，− 值 +；点数值可直接输入。[format] / [parse] 决定显示和解析（token 用 128K）。
class ProviderNumBox extends StatefulWidget {
  const ProviderNumBox({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1 << 31,
    this.step,
    this.unit,
    this.valueWidth = 46,
    this.format,
    this.parse,
    this.error = false,
  });

  /// null = 未标注（显示 —）。
  final int? value;
  final ValueChanged<int?> onChanged;
  final int min;
  final int max;

  /// null = 按“倍增 / 减半”步进（token）。
  final int? step;
  final String? unit;
  final double valueWidth;
  final String Function(int? v)? format;
  final int? Function(String s)? parse;
  final bool error;

  @override
  State<ProviderNumBox> createState() => _ProviderNumBoxState();
}

class _ProviderNumBoxState extends State<ProviderNumBox> {
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

  String _fmt(int? v) => widget.format?.call(v) ?? (v == null ? '—' : '$v');

  void _set(int v) {
    final x = v.clamp(widget.min, widget.max);
    if (x != widget.value) widget.onChanged(x);
  }

  void _commit() {
    final t = _ctrl.text.trim();
    setState(() => _editing = false);
    if (t.isEmpty) return widget.onChanged(null);
    final v = widget.parse?.call(t) ?? int.tryParse(t);
    if (v != null) _set(v);
  }

  int _delta(bool up) {
    final v = widget.value;
    if (widget.step case final s?) return (v ?? widget.min) + (up ? s : -s);
    final base = v ?? 8000;
    return up ? base * 2 : (base / 2).round();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final v = widget.value;
    Widget side(String glyph, bool up) {
      final enabled = up
          ? (v ?? widget.min) < widget.max
          : v != null && v > widget.min;
      return UiPressable(
        onTap: enabled ? () => _set(_delta(up)) : null,
        builder: (context, hover) => Container(
          width: 24,
          height: 26,
          alignment: Alignment.center,
          color: hover ? c.hover : null,
          child: UiGlyph(glyph, size: 12, color: enabled ? c.muted : c.strong),
        ),
      );
    }

    final valueStyle = UiText.mono(
      12,
      weight: FontWeight.w500,
      color: v == null ? c.faint : c.ink,
      height: 1.2,
    );
    return Container(
      height: 28,
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(
          color: widget.error ? Color.lerp(c.border, c.error, .55)! : c.border,
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            side(UiGlyphs.minus, false),
            Container(
              constraints: BoxConstraints(minWidth: widget.valueWidth),
              height: 26,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                border: Border.symmetric(vertical: BorderSide(color: c.border)),
              ),
              alignment: Alignment.center,
              child: _editing
                  ? SizedBox(
                      width: widget.valueWidth,
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focus,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        style: valueStyle.copyWith(color: c.ink),
                        cursorColor: c.accent,
                        cursorHeight: 13,
                        decoration: uiBareDecoration(),
                        onSubmitted: (_) => _commit(),
                      ),
                    )
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() {
                        _editing = true;
                        _ctrl.text = v == null ? '' : _fmt(v);
                        _ctrl.selection = TextSelection(
                          baseOffset: 0,
                          extentOffset: _ctrl.text.length,
                        );
                      }),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 3,
                        children: [
                          Text(_fmt(v), style: valueStyle),
                          if (widget.unit != null && widget.unit!.isNotEmpty)
                            Text(
                              widget.unit!,
                              style: UiText.sans(
                                10.5,
                                color: c.faint,
                                height: 1.2,
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
            side(UiGlyphs.plus, true),
          ],
        ),
      ),
    );
  }
}

/// 可切换小片（原型 `.tgl` / `.lv`）：开 = 正文色 + 控件底；[accent] 时开 = 强调色浅底描边。
/// [badge] 画在右上角（“默认”）。
class ProviderToggle extends StatelessWidget {
  const ProviderToggle({
    super.key,
    required this.label,
    required this.on,
    this.onTap,
    this.glyph,
    this.accent = false,
    this.badge,
    this.height = 26,
  });
  final String label;
  final bool on;
  final VoidCallback? onTap;
  final String? glyph;
  final bool accent;
  final String? badge;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) {
        final (bg, border, fg) = on
            ? accent
                  ? (
                      Color.alphaBlend(c.accent.withValues(alpha: .08), c.card),
                      Color.lerp(c.border, c.accent, .45)!,
                      c.ink,
                    )
                  : (c.control, c.strong, c.ink)
            : (hover ? c.hover : c.card, c.border, hover ? c.muted : c.faint);
        final chip = Container(
          height: height,
          padding: EdgeInsets.only(left: glyph == null ? 10 : 8, right: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(height <= 24 ? 6 : 7),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              if (glyph != null) UiGlyph(glyph!, size: 13, color: fg),
              Text(
                label,
                maxLines: 1,
                style: UiText.sans(
                  12,
                  weight: on && !accent ? FontWeight.w500 : FontWeight.w400,
                  color: fg,
                  height: 1.2,
                ),
              ),
            ],
          ),
        );
        if (badge == null) return chip;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            chip,
            Positioned(
              top: -7,
              right: -5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  badge!,
                  style: UiText.sans(9, color: c.onAccent, height: 13 / 9),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 一组能力图标（列表行里）：22 × 22，开 = 控件底正文色，关 = 虚线框弱色。
class ProviderCapIcons extends StatelessWidget {
  const ProviderCapIcons(this.caps, {super.key});
  final Set<ProviderCapability> caps;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 3,
      children: [
        for (final k in ProviderCapability.values)
          Tooltip(
            message: providerCapabilityLabel(context, k),
            child: caps.contains(k)
                ? Container(
                    key: Key('mp-cap-${k.name}-on'),
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.control,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: UiGlyph(
                      ProvidersGlyphs.capability(k),
                      size: 13,
                      color: c.ink,
                    ),
                  )
                : CustomPaint(
                    painter: _DashedBox(c.strong.withValues(alpha: .6)),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: Center(
                        child: UiGlyph(
                          ProvidersGlyphs.capability(k),
                          size: 13,
                          color: c.faint.withValues(alpha: .45),
                        ),
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}

class _DashedBox extends CustomPainter {
  _DashedBox(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(.5),
      const Radius.circular(6),
    );
    final path = Path()..addRRect(r);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 5) {
        canvas.drawPath(m.extractPath(d, d + 2.5), p);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBox o) => o.color != color;
}

/// 虚线分隔（原型 `border-top:1px dashed var(--line)`）。
class ProviderDashLine extends StatelessWidget {
  const ProviderDashLine({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 1,
    width: double.infinity,
    child: CustomPaint(painter: _HDash(context.ui.rowLine)),
  );
}

class _HDash extends CustomPainter {
  _HDash(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (double x = 0; x < size.width; x += 6) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 3, 1), p);
    }
  }

  @override
  bool shouldRepaint(_HDash o) => o.color != color;
}

/// 键值列表（原型 `.kvs`）：下沉底、圆角 8；每行“键 | 值 | ×”，可直接改。
class ProviderKeyValues extends StatelessWidget {
  const ProviderKeyValues({
    super.key,
    required this.items,
    required this.onChanged,
    this.json = false,
    this.errors = const {},
    this.keyPrefix = 'kv',
    this.tag,
  });

  final List<ProviderKeyValue> items;

  /// 行首小标（“请求体” / “请求头”），同一处混放两种时用来区分；null 不显示。
  final String? tag;
  final ValueChanged<List<ProviderKeyValue>> onChanged;

  /// 值是 JSON（请求体）。
  final bool json;

  /// 出错的行号。
  final Set<int> errors;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.sunk,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, kv) in items.indexed) ...[
            if (i > 0) Container(height: 1, color: c.rowLine),
            Padding(
              key: Key('$keyPrefix-$i'),
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
              child: Row(
                spacing: 6,
                children: [
                  if (tag != null)
                    Container(
                      key: Key('$keyPrefix-$i-tag'),
                      height: 18,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      margin: const EdgeInsets.only(left: 2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: (json ? c.accent : c.ok).withValues(alpha: .10),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag!,
                        style: UiText.sans(
                          10.5,
                          weight: FontWeight.w600,
                          color: json ? c.accent : c.ok,
                          height: 1.2,
                        ),
                      ),
                    ),
                  Expanded(
                    flex: 4,
                    child: _Bare(
                      key: Key('$keyPrefix-$i-key'),
                      value: kv.key,
                      hint: json ? l.modelOverrides_fieldName : l.mp_headerName,
                      bold: true,
                      error: errors.contains(i),
                      onChanged: (v) => onChanged([
                        for (final (j, x) in items.indexed)
                          j == i ? ProviderKeyValue(v, x.value) : x,
                      ]),
                    ),
                  ),
                  Expanded(
                    flex: 7,
                    child: _Bare(
                      key: Key('$keyPrefix-$i-value'),
                      value: kv.value,
                      hint: json ? l.modelOverrides_valueJson : l.mp_value,
                      error: errors.contains(i),
                      onChanged: (v) => onChanged([
                        for (final (j, x) in items.indexed)
                          j == i ? ProviderKeyValue(x.key, v) : x,
                      ]),
                    ),
                  ),
                  ProviderTinyBtn(
                    key: Key('$keyPrefix-$i-remove'),
                    glyph: UiGlyphs.close,
                    glyphSize: 12,
                    tooltip: l.modelOverrides_removeItem,
                    onTap: () => onChanged([...items]..removeAt(i)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 键值行里的无框输入：26 高，聚焦时才出描边。
class _Bare extends StatefulWidget {
  const _Bare({
    super.key,
    required this.value,
    required this.onChanged,
    this.hint,
    this.bold = false,
    this.error = false,
  });
  final String value;
  final ValueChanged<String> onChanged;
  final String? hint;
  final bool bold;
  final bool error;

  @override
  State<_Bare> createState() => _BareState();
}

class _BareState extends State<_Bare> {
  late final _ctrl = TextEditingController(text: widget.value);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant _Bare old) {
    super.didUpdateWidget(old);
    if (widget.value != _ctrl.text && !_focus.hasFocus) {
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
    final style = UiText.mono(
      12,
      weight: widget.bold ? FontWeight.w500 : FontWeight.w400,
      color: widget.bold ? c.ink : c.muted,
      height: 1.2,
    );
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      // 文字垂直居中（以前贴顶，整行看着偏上）。
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: _focus.hasFocus ? c.card : null,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: widget.error
              ? Color.lerp(c.border, c.error, .6)!
              : _focus.hasFocus
              ? c.accent
              : Colors.transparent,
        ),
      ),
      child: TextField(
        controller: _ctrl,
        focusNode: _focus,
        style: style,
        cursorColor: c.accent,
        cursorHeight: 13,
        textAlignVertical: TextAlignVertical.center,
        decoration: uiBareDecoration(
          hintText: widget.hint,
          hintStyle: style.copyWith(color: c.faint),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

/// 复制到剪贴板。
Future<void> providersCopy(String text) =>
    Clipboard.setData(ClipboardData(text: text));
