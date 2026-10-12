import 'package:flutter/material.dart';

import '../../../core/utils/localization_extension.dart';
import '../kit/ui_colors.dart';
import '../kit/ui_controls.dart';
import '../kit/ui_glyph.dart';
import '../kit/ui_lib_controls.dart';
import '../kit/ui_menu.dart';
import '../kit/ui_popover.dart';
import '../kit/ui_text.dart';
import 'tools_contract.dart';
import 'tools_editor.dart';
import 'tools_format.dart';
import 'tools_parts.dart';

/// 编辑器右栏（原型 `.ed-side`，宽 280）。
/// 编辑图像：图层（撑满）│ 调整颜色（当前图层）│ 画布尺寸。
/// 局部重绘：重绘设置 │ 图层（撑满）│ 一句结果说明。
class ToolsEditorSide extends StatelessWidget {
  const ToolsEditorSide({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsEditorScope.of(context);
    final d = scope.data;
    return Container(
      key: const Key('tools-editor-side'),
      width: ToolsEditorPage.sideWidth,
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(left: BorderSide(color: c.line)),
      ),
      child: d.inpainting
          ? const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InpaintSettings(),
                Expanded(child: _Layers()),
                _ResultNote(),
              ],
            )
          : const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _Layers()),
                _Adjust(),
                _CanvasSize(),
              ],
            ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.children, this.top = 8});
  final String label;
  final List<Widget> children;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: top),
    child: Row(
      spacing: 8,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            maxLines: 1,
            style: UiText.sans(12, color: context.ui.muted),
          ),
        ),
        ...children,
      ],
    ),
  );
}

/// 重绘设置：重绘强度（和左栏同步）、蒙版占比、聚焦区域、输出尺寸。
class _InpaintSettings extends StatelessWidget {
  const _InpaintSettings();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsEditorScope.of(context);
    final d = scope.data;
    final i = d.inpaint;
    final l = context.l10n;
    final mono = UiText.mono(12, color: c.ink);
    final faint = UiText.sans(12, color: c.faint);
    return ToolsPanelSection(
      key: const Key('tools-inpaint-settings'),
      title: l.tools_inpaintSettings,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: 10,
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  l.tools_inpaintStrength,
                  maxLines: 1,
                  style: UiText.sans(12, color: c.muted),
                ),
              ),
              Expanded(
                child: ToolsSlider(
                  key: const Key('tools-inpaint-strength'),
                  value: i.strength,
                  onChanged: scope.actions.onInpaintStrength,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 70, top: 6),
            child: Text(
              l.tools_inpaintStrengthHint,
              style: UiText.sans(11, color: c.faint),
            ),
          ),
          _Row(
            top: 12,
            label: l.tools_mask,
            children: [
              Text('${(i.coverage * 100).round()}%', style: mono),
              Flexible(
                child: Text(
                  l.tools_maskCoverage(i.regions),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: faint,
                ),
              ),
            ],
          ),
          _Row(
            label: l.tools_toolFocus,
            children: i.hasFocus
                ? [
                    Text(
                      ToolsFormat.size(i.focusWidth!, i.focusHeight!),
                      key: const Key('tools-inpaint-focus-size'),
                      style: mono,
                    ),
                    Flexible(
                      child: Text(
                        l.tools_focusContextShort(i.focusContext),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: faint,
                      ),
                    ),
                  ]
                : [Text(l.tools_focusNone, style: faint)],
          ),
          _Row(
            label: l.tools_output,
            children: [
              Text(
                ToolsFormat.size(d.outWidth, d.outHeight),
                key: const Key('tools-inpaint-output'),
                style: mono,
              ),
              if (!d.expand.isZero) UiMini(l.tools_expandTag),
            ],
          ),
        ],
      ),
    );
  }
}

/// 图层：加图层 / 加 3D 图层；每行缩略图 + 名字 + 一行说明 + 显隐；右键菜单（上移、下移、复制、向下合并、删除）。
class _Layers extends StatelessWidget {
  const _Layers();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsEditorScope.of(context);
    final d = scope.data;
    final a = scope.actions;
    final l = context.l10n;
    return ToolsPanelSection(
      key: const Key('tools-layers'),
      title: l.tools_layers,
      border: d.inpainting,
      padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
      titleInset: 8,
      expand: true,
      trailing: [
        ToolsIb(
          key: const Key('tools-layer-add'),
          glyph: UiGlyphs.plus,
          size: 26,
          glyphSize: 15,
          tooltip: l.tools_addLayer,
          onTap: a.onAddLayer,
        ),
        ToolsIb(
          key: const Key('tools-layer-add3d'),
          icon: 'inpaint_cube',
          size: 26,
          glyphSize: 15,
          tooltip: l.tools_add3dLayer,
          onTap: a.onAdd3dLayer,
        ),
      ],
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          for (final layer in d.layers) _LayerRow(layer: layer),
          if (!d.inpainting)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                spacing: 6,
                children: [
                  UiGlyph(ToolsGlyphs.kbd, size: 13, color: c.faint),
                  Expanded(
                    child: Text(
                      l.tools_layerHint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.sans(11, color: c.faint),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LayerRow extends StatelessWidget {
  const _LayerRow({required this.layer});
  final ToolsLayer layer;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsEditorScope.of(context);
    final d = scope.data;
    final a = scope.actions;
    final l = context.l10n;
    final on = layer.id == d.layer;
    void menu(Offset at) {
      final i = d.layers.indexOf(layer);
      scope.controller.openPopover(
        UiPopoverAnchor(at),
        (_) => UiMenu(
          width: 180,
          onClose: scope.controller.closePopover,
          items: [
            UiMenuItem(
              label: l.tools_layerUp,
              glyph: UiGlyphs.chevronUp,
              enabled: !layer.locked && i > 0,
              onTap: () => a.onLayerAction(layer.id, ToolsLayerAction.up),
            ),
            UiMenuItem(
              label: l.tools_layerDown,
              glyph: UiGlyphs.chevronDown,
              enabled:
                  !layer.locked &&
                  i < d.layers.length - 1 &&
                  !d.layers[i + 1].locked,
              onTap: () => a.onLayerAction(layer.id, ToolsLayerAction.down),
            ),
            UiMenuItem(
              label: l.tools_layerDuplicate,
              glyph: UiGlyphs.copy,
              enabled: layer.kind != ToolsLayerKind.mask,
              onTap: () =>
                  a.onLayerAction(layer.id, ToolsLayerAction.duplicate),
            ),
            UiMenuItem(
              label: l.tools_layerMerge,
              glyph: UiGlyphs.merge,
              enabled: !layer.locked && i < d.layers.length - 1,
              onTap: () => a.onLayerAction(layer.id, ToolsLayerAction.merge),
            ),
            UiMenuItem(
              key: const Key('tools-layer-delete'),
              label: l.tools_layerDelete,
              glyph: UiGlyphs.trash,
              danger: true,
              divider: true,
              enabled: !layer.locked,
              onTap: () => a.onLayerAction(layer.id, ToolsLayerAction.delete),
            ),
          ],
        ),
        tag: #layer,
      );
    }

    return GestureDetector(
      onSecondaryTapUp: (e) => menu(e.globalPosition),
      child: UiPressable(
        key: Key('tools-layer-${layer.id}'),
        onTap: on ? null : () => a.onSelectLayer(layer.id),
        builder: (context, hover) => Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: on
                ? c.accent.withValues(alpha: .09)
                : (hover ? c.control : null),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            spacing: 10,
            children: [
              _LayerThumb(layer: layer, mask: d.mask.color),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      layer.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: UiText.sans(
                        12,
                        weight: on ? FontWeight.w600 : FontWeight.w400,
                        color: layer.visible ? c.ink : c.faint,
                      ),
                    ),
                    if (layer.detail != null)
                      Text(
                        layer.detail!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: UiText.sans(11, color: c.faint),
                      ),
                  ],
                ),
              ),
              ToolsIb(
                key: Key('tools-layer-eye-${layer.id}'),
                glyph: layer.visible ? ToolsGlyphs.eye : UiGlyphs.eyeOff,
                size: 26,
                glyphSize: 15,
                tooltip: layer.visible ? l.tools_hideLayer : l.tools_showLayer,
                onTap: () => a.onLayerVisible(layer.id, !layer.visible),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 图层缩略图：34 方、圆角 5、描边；蒙版层画斜纹，底图带锁。
class _LayerThumb extends StatelessWidget {
  const _LayerThumb({required this.layer, required this.mask});
  final ToolsLayer layer;
  final Color mask;

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    return Container(
      width: 34,
      height: 34,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: layer.kind == ToolsLayerKind.paint ? c.raised : c.control,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: c.line),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (layer.thumb != null)
            Image(image: layer.thumb!, fit: BoxFit.cover)
          else if (layer.kind == ToolsLayerKind.mask)
            CustomPaint(painter: _Stripes(mask))
          else if (layer.kind == ToolsLayerKind.model3d)
            Center(child: ToolsIcon('inpaint_cube', size: 16, color: c.muted)),
          if (layer.locked)
            const Positioned(
              right: 2,
              bottom: 2,
              child: UiGlyph(UiGlyphs.lock, size: 10, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class _Stripes extends CustomPainter {
  const _Stripes(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 3;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var x = -size.height; x < size.width; x += 7) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Stripes old) => old.color != color;
}

/// 调整颜色（当前图层）：色相 / 饱和度 / 亮度，拖动实时预览；重置 / 应用。
class _Adjust extends StatelessWidget {
  const _Adjust();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsEditorScope.of(context);
    final d = scope.data;
    final a = scope.actions;
    final l = context.l10n;
    final adj = d.adjust;
    // 第一行紧跟标题（原型标题下边距 10 和行上边距 8 折叠成 10）。
    Widget row(
      String key,
      String label,
      int value,
      int min,
      int max,
      ToolsAdjust Function(int) set,
    ) => Padding(
      padding: EdgeInsets.only(top: key == 'hue' ? 0 : 8),
      child: Row(
        spacing: 10,
        children: [
          SizedBox(
            width: 44,
            child: Text(label, style: UiText.sans(12, color: c.muted)),
          ),
          Expanded(
            child: ToolsSlider(
              key: Key('tools-adjust-$key'),
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              decimals: 0,
              live: true,
              display: (v) => ToolsFormat.signed(v.round()),
              onChanged: (v) => a.onAdjust(set(v.round())),
            ),
          ),
        ],
      ),
    );
    return ToolsPanelSection(
      key: const Key('tools-adjust'),
      title: l.tools_adjust,
      badge: UiMini(l.tools_currentLayer),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row(
            'hue',
            l.tools_hue,
            adj.hue,
            -180,
            180,
            (v) => adj.copyWith(hue: v),
          ),
          row(
            'saturation',
            l.tools_saturation,
            adj.saturation,
            -100,
            100,
            (v) => adj.copyWith(saturation: v),
          ),
          row(
            'brightness',
            l.tools_brightness,
            adj.brightness,
            -100,
            100,
            (v) => adj.copyWith(brightness: v),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ToolsButton(
                key: const Key('tools-adjust-reset'),
                small: true,
                onTap: adj.isZero ? null : a.onAdjustReset,
                children: [Text(l.tools_reset)],
              ),
              const Spacer(),
              ToolsButton(
                key: const Key('tools-adjust-apply'),
                small: true,
                onTap: adj.isZero ? null : a.onAdjustApply,
                children: [Text(l.tools_apply)],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 画布：尺寸 + 更改尺寸（接现有画布尺寸弹窗）。
class _CanvasSize extends StatelessWidget {
  const _CanvasSize();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final scope = ToolsEditorScope.of(context);
    final d = scope.data;
    final l = context.l10n;
    return ToolsPanelSection(
      key: const Key('tools-canvas-size'),
      title: l.tools_canvas,
      border: false,
      child: Row(
        spacing: 8,
        children: [
          Text(
            ToolsFormat.size(d.width, d.height),
            style: UiText.mono(12, color: c.ink),
          ),
          const Spacer(),
          ToolsButton(
            key: const Key('tools-canvas-resize'),
            small: true,
            onTap: scope.actions.onResizeCanvas,
            children: [
              UiGlyph(ToolsGlyphs.crop, size: 13, color: c.ink),
              Text(l.tools_resizeCanvas),
            ],
          ),
        ],
      ),
    );
  }
}

/// 局部重绘右栏底部：应用后去哪。
class _ResultNote extends StatelessWidget {
  const _ResultNote();

  @override
  Widget build(BuildContext context) {
    final c = context.ui;
    final l = context.l10n;
    return Container(
      key: const Key('tools-inpaint-note'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      color: c.panel,
      child: Text.rich(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: UiGlyph(ToolsGlyphs.info, size: 13, color: c.muted),
              ),
            ),
            TextSpan(text: l.tools_inpaintNote),
          ],
        ),
        style: UiText.sans(11, color: c.muted, height: 1.6),
      ),
    );
  }
}
