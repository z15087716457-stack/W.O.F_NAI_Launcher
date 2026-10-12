import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_keycap.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_slider.dart';
import '../kit/ui_text.dart';
import 'tools_contract.dart';
import 'tools_editor.dart';
import 'tools_format.dart';
import 'tools_parts.dart';

/// 工具选项条（原型 `.ed-opt`）：44 高、左右 14、间距 12、底分隔线；当前工具的全部选项横排，
/// 放不下时横向滚动。扩展边缘、聚焦区域各有自己的一条。
class ToolsOptionsBar extends StatelessWidget {
  const ToolsOptionsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsEditorScope.of(context);
    final d = scope.data;
    final items = d.inpainting && d.expanding
        ? _expand(context, scope)
        : d.inpainting && d.tool == ToolsTool.focus
        ? _focus(context, scope)
        : d.inpainting
        ? _mask(context, scope)
        : _edit(context, scope);
    // Spacer 前面的一组靠左（放不下时横向滚动），后面的一组钉在右端。
    final split = items.indexWhere((w) => w is Spacer);
    final left = split < 0 ? items : items.sublist(0, split);
    final right = split < 0 ? const <Widget>[] : items.sublist(split + 1);
    return Container(
      key: const Key('tools-editor-options'),
      height: ToolsEditorPage.optionsHeight,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        spacing: 12,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(spacing: 12, children: left),
            ),
          ),
          ...right,
        ],
      ),
    );
  }

  /// 选项条左端：图标 + 工具名（12 / w600）。
  static Widget _title(BuildContext context, String icon, String label) {
    final c = context.ui;
    return Row(
      key: const Key('tools-options-title'),
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        if (icon.startsWith('g:'))
          UiGlyph(icon.substring(2), size: 16, color: c.ink)
        else
          ToolsIcon(icon, size: 16, color: c.ink),
        Text(
          label,
          style: UiText.sans(12, weight: FontWeight.w600, color: c.ink),
        ),
      ],
    );
  }

  static Widget _label(BuildContext context, String text) =>
      Text(text, style: UiText.sans(12, color: context.ui.muted));

  static Widget _hint(BuildContext context, String text) =>
      Text(text, maxLines: 1, style: UiText.sans(12, color: context.ui.muted));

  static String _icon(ToolsTool t) => switch (t) {
    ToolsTool.brush => 'inpaint_brush',
    ToolsTool.eraser => 'inpaint_eraser',
    ToolsTool.fill => 'inpaint_fill',
    ToolsTool.focus => 'inpaint_inpaint_focus',
    ToolsTool.blur => 'g:${ToolsGlyphs.blur}',
    ToolsTool.stamp => 'g:${ToolsGlyphs.stamp}',
    ToolsTool.select => 'g:${ToolsGlyphs.rect}',
    ToolsTool.lasso => 'g:${ToolsGlyphs.lasso}',
    ToolsTool.picker => 'g:${ToolsGlyphs.drop}',
  };

  /// 大小：滑杆 + “18 px”。
  static List<Widget> _size(
    BuildContext context,
    ToolsEditorScope scope, {
    double width = 170,
    bool brackets = false,
  }) {
    final l = context.l10n;
    final o = scope.data.options;
    return [
      _label(context, l.tools_size),
      ToolsSlider(
        key: const Key('tools-opt-size'),
        width: width,
        value: o.size!,
        min: o.minSize,
        max: o.maxSize,
        decimals: 0,
        display: brackets ? null : (v) => '${v.round()} px',
        onChanged: (v) => scope.actions.onOptions(o.copyWith(size: v)),
      ),
      if (brackets) const UiKeycaps(['[', ']'], gap: 4),
    ];
  }

  List<Widget> _edit(BuildContext context, ToolsEditorScope scope) {
    final d = scope.data;
    final o = d.options;
    final a = scope.actions;
    final l = context.l10n;
    final paints = d.tool == ToolsTool.brush || d.tool == ToolsTool.fill;
    return [
      _title(
        context,
        _icon(d.tool),
        ToolsFormat.toolLabel(l, d.tool, inpaint: false),
      ),
      const ToolsVDiv(),
      if (paints || d.tool == ToolsTool.picker) ...[
        const _Swatches(),
        if (paints) const UiKeycap('X'),
        const ToolsVDiv(),
      ],
      if (o.size != null) ..._size(context, scope),
      if (o.opacity != null) ...[
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: _label(context, l.tools_opacity),
        ),
        ToolsSlider(
          key: const Key('tools-opt-opacity'),
          width: 110,
          value: o.opacity!,
          display: (v) => '${(v * 100).round()}%',
          onChanged: (v) => a.onOptions(o.copyWith(opacity: v)),
        ),
      ],
      if (o.intensity != null) ...[
        _label(context, l.tools_intensity),
        ToolsSlider(
          key: const Key('tools-opt-intensity'),
          width: 110,
          value: o.intensity!,
          display: (v) => '${(v * 100).round()}%',
          onChanged: (v) => a.onOptions(o.copyWith(intensity: v)),
        ),
      ],
      if (o.tolerance != null) ...[
        _label(context, l.tools_tolerance),
        ToolsSlider(
          key: const Key('tools-opt-tolerance'),
          width: 150,
          value: o.tolerance!.toDouble(),
          max: 100,
          decimals: 0,
          display: (v) => '${v.round()}',
          onChanged: (v) => a.onOptions(o.copyWith(tolerance: v.round())),
        ),
      ],
      if (o.tip != null) ...[
        const ToolsVDiv(),
        _label(context, l.tools_tip),
        ToolsSeg<ToolsBrushTip>(
          key: const Key('tools-opt-tip'),
          height: 28,
          values: ToolsBrushTip.values,
          selected: o.tip,
          keyOf: (t) => Key('tools-tip-${t.name}'),
          onChanged: (t) => a.onOptions(o.copyWith(tip: t)),
          label: (context, t, on) => Text(switch (t) {
            ToolsBrushTip.hard => l.tools_tipHard,
            ToolsBrushTip.soft => l.tools_tipSoft,
            ToolsBrushTip.square => l.tools_tipSquare,
          }),
        ),
      ],
      if (o.pressure != null)
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: ToolsSwitchLabel(
            key: const Key('tools-opt-pressure'),
            value: o.pressure!,
            label: l.tools_pressure,
            onChanged: (v) => a.onOptions(o.copyWith(pressure: v)),
          ),
        ),
      if (d.tool == ToolsTool.stamp) _hint(context, l.tools_hintStamp),
      if (d.tool == ToolsTool.select || d.tool == ToolsTool.lasso)
        _hint(context, l.tools_hintSelect),
      if (d.tool == ToolsTool.picker) _hint(context, l.tools_hintPicker),
    ];
  }

  List<Widget> _mask(BuildContext context, ToolsEditorScope scope) {
    final d = scope.data;
    final o = d.options;
    final a = scope.actions;
    final l = context.l10n;
    return [
      _title(
        context,
        _icon(d.tool),
        ToolsFormat.toolLabel(l, d.tool, inpaint: true),
      ),
      const ToolsVDiv(),
      if (o.size != null) ..._size(context, scope, width: 200, brackets: true),
      if (o.square != null) ...[
        const ToolsVDiv(),
        ToolsSwitchLabel(
          key: const Key('tools-opt-square'),
          value: o.square!,
          label: l.tools_squareBrush,
          onChanged: (v) => a.onOptions(o.copyWith(square: v)),
        ),
      ],
      if (o.tolerance != null) ...[
        _label(context, l.tools_tolerance),
        ToolsSlider(
          key: const Key('tools-opt-tolerance'),
          width: 150,
          value: o.tolerance!.toDouble(),
          max: 100,
          decimals: 0,
          display: (v) => '${v.round()}',
          onChanged: (v) => a.onOptions(o.copyWith(tolerance: v.round())),
        ),
        _hint(context, l.tools_hintMaskFill),
      ],
      const Spacer(),
      const _MaskLook(),
    ];
  }

  List<Widget> _focus(BuildContext context, ToolsEditorScope scope) {
    final d = scope.data;
    final a = scope.actions;
    final l = context.l10n;
    return [
      _title(context, 'inpaint_inpaint_focus', l.tools_toolFocus),
      const ToolsVDiv(),
      _label(context, l.tools_focusContext),
      ToolsSlider(
        key: const Key('tools-opt-context'),
        width: 180,
        value: d.inpaint.focusContext.toDouble(),
        max: d.inpaint.maxFocusContext.toDouble(),
        decimals: 0,
        display: (v) => '${v.round()}',
        onChanged: (v) => a.onFocusContext(v.round()),
      ),
      const ToolsVDiv(),
      _hint(context, l.tools_hintFocus),
      const Spacer(),
      ToolsButton(
        key: const Key('tools-focus-clear'),
        small: true,
        onTap: d.inpaint.hasFocus ? a.onClearFocus : null,
        children: [Text(l.tools_clearFocus), const UiKeycap('Esc')],
      ),
    ];
  }

  List<Widget> _expand(BuildContext context, ToolsEditorScope scope) {
    final c = context.ui;
    final d = scope.data;
    final a = scope.actions;
    final l = context.l10n;
    final e = d.expand;
    Widget edge(
      String label,
      String key,
      int value,
      ToolsExpand Function(int) set,
    ) => Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        _label(context, label),
        UiNumBox(
          key: Key('tools-expand-$key'),
          value: value.toDouble(),
          max: e.max.toDouble(),
          decimals: 0,
          onSubmitted: (v) {
            final snapped = (v / e.step).round() * e.step;
            a.onExpand(set(snapped.clamp(0, e.max)));
          },
        ),
      ],
    );
    return [
      _title(context, 'inpaint_shift', l.tools_expand),
      const ToolsVDiv(),
      edge(l.tools_edgeTop, 'top', e.top, (v) => e.copyWith(top: v)),
      edge(
        l.tools_edgeBottom,
        'bottom',
        e.bottom,
        (v) => e.copyWith(bottom: v),
      ),
      edge(l.tools_edgeLeft, 'left', e.left, (v) => e.copyWith(left: v)),
      edge(l.tools_edgeRight, 'right', e.right, (v) => e.copyWith(right: v)),
      const ToolsVDiv(),
      _hint(context, l.tools_hintExpand(e.step)),
      const Spacer(),
      Text(
        '${ToolsFormat.tight(d.width, d.height)} → ${ToolsFormat.tight(d.outWidth, d.outHeight)}',
        key: const Key('tools-expand-out'),
        style: UiText.mono(12, color: c.muted),
      ),
      ToolsButton(
        key: const Key('tools-expand-reset'),
        small: true,
        onTap: e.isZero
            ? null
            : () =>
                  a.onExpand(e.copyWith(top: 0, bottom: 0, left: 0, right: 0)),
        children: [Text(l.tools_reset)],
      ),
      ToolsButton(
        key: const Key('tools-expand-done'),
        small: true,
        tone: ToolsButtonTone.primary,
        onTap: () => a.onExpanding(false),
        children: [Text(l.tools_done)],
      ),
    ];
  }
}

/// 色板常用色（取色器“更多颜色”接现有取色器）。
const toolsPalette = [
  Color(0xFF000000),
  Color(0xFFFFFFFF),
  Color(0xFF7F7F7F),
  Color(0xFFE94B6A),
  Color(0xFFFF8A3D),
  Color(0xFFFFD21F),
  Color(0xFF3DD68C),
  Color(0xFF2BB3C0),
  Color(0xFF4F8CFF),
  Color(0xFF6E56CF),
  Color(0xFFF2B8C6),
  Color(0xFF8B5A3C),
];

/// 前景 / 背景色两块叠放（原型 `.swatch`）：点前景开色板，点背景开色板改背景色。
class _Swatches extends StatelessWidget {
  const _Swatches();

  @override
  Widget build(BuildContext context) {
    final scope = ToolsEditorScope.of(context);
    final d = scope.data;
    return SizedBox(
      key: const Key('tools-swatches'),
      width: 34,
      height: 32,
      child: Stack(
        children: [
          Positioned(
            left: 12,
            top: 15,
            child: Builder(
              builder: (ctx) => _Swatch(
                key: const Key('tools-swatch-secondary'),
                color: d.secondary,
                size: 16,
                onTap: () => _palette(ctx, scope, secondary: true),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 5,
            child: Builder(
              builder: (ctx) => _Swatch(
                key: const Key('tools-swatch-primary'),
                color: d.primary,
                size: 22,
                onTap: () => _palette(ctx, scope, secondary: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _palette(
    BuildContext ctx,
    ToolsEditorScope scope, {
    required bool secondary,
  }) {
    final box = ctx.findRenderObject()! as RenderBox;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    scope.controller.openPopover(
      UiPopoverAnchor(rect.bottomLeft + const Offset(0, 8)),
      (_) => _Palette(secondary: secondary, anchor: rect),
      tag: #palette,
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    super.key,
    required this.color,
    required this.size,
    this.onTap,
  });
  final Color color;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return UiPressable(
      onTap: onTap,
      builder: (context, hover) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(size > 18 ? 6 : 5),
          border: Border.all(color: c.raised, width: 2),
          boxShadow: [
            BoxShadow(color: hover ? c.ink : c.strong, spreadRadius: 1),
          ],
        ),
      ),
    );
  }
}

class _Palette extends StatelessWidget {
  const _Palette({required this.secondary, required this.anchor});
  final bool secondary;
  final Rect anchor;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsEditorScope.of(context);
    final l = context.l10n;
    final current = secondary ? scope.data.secondary : scope.data.primary;
    return UiPopoverSurface(
      key: const Key('tools-palette'),
      width: 212,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            secondary ? l.tools_colorSecondary : l.tools_colorPrimary,
            style: UiText.sans(11.5, weight: FontWeight.w500, color: c.faint),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (i, color) in toolsPalette.indexed)
                UiPressable(
                  key: Key('tools-palette-$i'),
                  onTap: () {
                    scope.controller.closePopover();
                    scope.actions.onColor(color, secondary: secondary);
                  },
                  builder: (context, hover) => Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: color == current ? c.accent : c.line,
                        width: color == current ? 2 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ToolsButton(
            key: const Key('tools-palette-more'),
            small: true,
            onTap: () {
              scope.controller.closePopover();
              scope.actions.onMoreColors(anchor);
            },
            children: [Text(l.tools_moreColors)],
          ),
        ],
      ),
    );
  }
}

/// 蒙版外观（原型选项条右端）：颜色块 │ 花纹下拉 │ 不透明度下拉。
class _MaskLook extends StatelessWidget {
  const _MaskLook();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsEditorScope.of(context);
    final m = scope.data.mask;
    final a = scope.actions;
    final l = context.l10n;
    UiPopoverAnchor below(BuildContext ctx) {
      final box = ctx.findRenderObject()! as RenderBox;
      return UiPopoverAnchor(
        box.localToGlobal(Offset(box.size.width, box.size.height + 8)),
        alignRight: true,
      );
    }

    return Row(
      key: const Key('tools-mask-look'),
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Text(l.tools_maskLook, style: UiText.sans(12, color: c.muted)),
        Builder(
          builder: (ctx) => _Swatch(
            key: const Key('tools-mask-color'),
            color: m.color,
            size: 18,
            onTap: () => scope.controller.openPopover(
              below(ctx),
              (_) => UiPopoverSurface(
                width: 180,
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (i, color) in _maskColors.indexed)
                      UiPressable(
                        key: Key('tools-mask-color-$i'),
                        onTap: () {
                          scope.controller.closePopover();
                          a.onMaskLook(m.copyWith(color: color));
                        },
                        builder: (context, hover) => Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: color == m.color ? c.ink : c.line,
                              width: color == m.color ? 2 : 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              tag: #maskColor,
            ),
          ),
        ),
        Builder(
          builder: (ctx) => ToolsChip(
            key: const Key('tools-mask-pattern'),
            onTap: () => scope.controller.openPopover(
              below(ctx),
              (_) => UiMenu(
                width: 180,
                onClose: scope.controller.closePopover,
                items: [
                  for (final p in ToolsMaskPattern.values)
                    UiMenuItem(
                      key: Key('tools-pattern-${p.name}'),
                      label: ToolsFormat.pattern(l, p),
                      checked: p == m.pattern,
                      onTap: () => a.onMaskLook(m.copyWith(pattern: p)),
                    ),
                  UiMenuItem(
                    key: const Key('tools-mask-border'),
                    label: l.tools_maskBorder,
                    divider: true,
                    checked: m.border,
                    onTap: () => a.onMaskLook(m.copyWith(border: !m.border)),
                  ),
                ],
              ),
              tag: #maskPattern,
            ),
            children: [
              Text(ToolsFormat.pattern(l, m.pattern)),
              UiGlyph(UiGlyphs.chevronDown, size: 12, color: c.ink),
            ],
          ),
        ),
        Builder(
          builder: (ctx) => ToolsChip(
            key: const Key('tools-mask-opacity'),
            mono: true,
            onTap: () => scope.controller.openPopover(
              below(ctx),
              (_) => UiMenu(
                width: 120,
                onClose: scope.controller.closePopover,
                items: [
                  for (final v in const [.25, .4, .55, .7, .85, 1.0])
                    UiMenuItem(
                      label: '${(v * 100).round()}%',
                      checked: (v - m.opacity).abs() < .01,
                      onTap: () => a.onMaskLook(m.copyWith(opacity: v)),
                    ),
                ],
              ),
              tag: #maskOpacity,
            ),
            children: [Text('${(m.opacity * 100).round()}%')],
          ),
        ),
      ],
    );
  }

  static const _maskColors = [
    Color(0xFF4F8CFF),
    Color(0xFF3DD68C),
    Color(0xFFE94B6A),
    Color(0xFFFFD21F),
    Color(0xFF6E56CF),
    Color(0xFF000000),
    Color(0xFFFFFFFF),
    Color(0xFFFF8A3D),
  ];
}
