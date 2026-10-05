import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/utils/localization_extension.dart';
import '../../core/editor_state.dart';
import '../../tools/blur_tool.dart';
import '../../tools/tool_base.dart';
import '../../tools/fill_tool.dart';
import 'inpaint_controls.dart';
import 'edit_color_picker.dart';

const officialEditToolIds = [
  'brush',
  'eraser',
  'fill',
  'rect_selection',
  'lasso_selection',
  'color_picker',
  'blur',
  'clone_stamp',
];
String editToolGlyph(String id) => switch (id) {
  'rect_selection' => 'select',
  'lasso_selection' => 'lasso',
  'color_picker' => 'picker',
  'clone_stamp' => 'clone',
  _ => id,
};
String editToolLabel(BuildContext context, String id) {
  final l = context.l10n;
  return switch (id) {
    'brush' => l.editor_draw,
    'eraser' => l.editor_erase,
    'fill' => l.editor_toolFill,
    'rect_selection' => l.editor_select,
    'lasso_selection' => l.editor_lasso,
    'color_picker' => l.editor_toolColorPicker,
    'blur' => l.editor_toolBlur,
    'clone_stamp' => l.editor_toolCloneStamp,
    _ => id,
  };
}

class EditGlyph extends StatelessWidget {
  const EditGlyph(this.name, {super.key, this.size = 16, this.color});
  final String name;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: SvgPicture.asset(
      'assets/icons/editor_$name.svg',
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(
        color ?? Theme.of(context).colorScheme.onSurface,
        BlendMode.srcIn,
      ),
      excludeFromSemantics: true,
    ),
  );
}

class EditButton extends StatelessWidget {
  const EditButton({
    super.key,
    required this.tooltip,
    this.glyph,
    this.child,
    this.onPressed,
    this.selected = false,
    this.bordered = false,
    this.size = 44,
  });
  final String tooltip;
  final String? glyph;
  final Widget? child;
  final VoidCallback? onPressed;
  final bool selected, bordered;
  final double size;
  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final color = onPressed == null
        ? s.onSurface.withValues(alpha: .3)
        : selected
        ? s.onPrimaryContainer
        : s.onSurface;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        selected: selected,
        enabled: onPressed != null,
        child: Material(
          color: selected
              ? s.primaryContainer
              : bordered
              ? s.surfaceContainerLowest
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3),
            side: bordered
                ? BorderSide(color: s.outlineVariant)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(3),
            child: SizedBox.square(
              dimension: size,
              child: Center(child: child ?? EditGlyph(glyph!, color: color)),
            ),
          ),
        ),
      ),
    );
  }
}

class EditToolSettings extends StatelessWidget {
  const EditToolSettings({
    super.key,
    required this.state,
    required this.maxWidth,
  });
  final EditorState state;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([state, state.toolChangeNotifier]),
    builder: (context, _) {
      final tool = state.currentTool;
      if (tool == null) return const SizedBox.shrink();
      final l = context.l10n;
      final paint = tool.id == 'brush' || tool.id == 'eraser',
          fill = tool is FillTool,
          blur = tool is BlurTool,
          clone = tool.id == 'clone_stamp';
      final settings = <Widget>[
        if (tool.id == 'brush' || fill) EditColorControl(state: state),
        if (paint || blur || clone)
          EditNumberSlider(
            label: l.editor_penSize,
            value: state.brushSize,
            min: 5,
            max: 100,
            step: 5,
            uncapped: true,
            onChanged: state.setBrushSize,
          ),
        if (fill)
          EditNumberSlider(
            label: l.editor_tolerance,
            value: tool.tolerance.toDouble(),
            min: 0,
            max: 100,
            onChanged: (v) {
              tool.setTolerance(v.round());
              state.requestUiUpdate();
            },
          ),
        if (blur)
          EditNumberSlider(
            label: l.editor_intensity,
            value: tool.intensity * 100,
            min: 1,
            max: 100,
            onChanged: (v) {
              tool.setIntensity(v / 100);
              state.requestUiUpdate();
            },
          ),
        if (paint || blur || clone)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (paint) ...[
                Row(
                  key: const Key('edit_tips'),
                  mainAxisSize: MainAxisSize.min,
                  spacing: 2,
                  children: [
                    for (final tip in EditorBrushTip.values)
                      EditButton(
                        key: Key('edit_tip_${tip.name}'),
                        tooltip: switch (tip) {
                          EditorBrushTip.round => l.editor_roundTip,
                          EditorBrushTip.softRound => l.editor_softRoundTip,
                          EditorBrushTip.square => l.editor_squareTip,
                        },
                        selected: state.brushTip == tip,
                        bordered: true,
                        onPressed: () => state.setBrushTip(tip),
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: tip == EditorBrushTip.square
                                ? BoxShape.rectangle
                                : BoxShape.circle,
                            color: tip == EditorBrushTip.softRound
                                ? null
                                : Theme.of(context).colorScheme.onSurface,
                            gradient: tip == EditorBrushTip.softRound
                                ? RadialGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.onSurface,
                                      Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0),
                                    ],
                                  )
                                : null,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 6),
              ],
              EditButton(
                key: const Key('edit_pressure'),
                tooltip: l.editor_pressureSensitivity,
                glyph: 'pressure',
                selected: state.pressureSensitivity,
                bordered: true,
                onPressed: () =>
                    state.setPressureSensitivity(!state.pressureSensitivity),
              ),
            ],
          ),
        if (clone)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              l.editor_cloneSourceHint,
              style: const TextStyle(fontSize: 11),
            ),
          ),
      ];
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: InpaintPanel(
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: IntrinsicHeight(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    key: const Key('edit_tool_label'),
                    width: 62,
                    constraints: const BoxConstraints(minHeight: 64),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        EditGlyph(editToolGlyph(tool.id)),
                        const SizedBox(height: 4),
                        Text(
                          editToolLabel(context, tool.id),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  if (settings.isNotEmpty) ...[
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    Flexible(
                      child: Padding(
                        key: const Key('edit_settings_body'),
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 10,
                        ),
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 10,
                          runSpacing: 10,
                          children: settings,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class EditNumberSlider extends StatelessWidget {
  const EditNumberSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
    this.uncapped = false,
    this.width = 140,
  });
  final String label;
  final double value, min, max, step, width;
  final bool uncapped;
  final ValueChanged<double> onChanged;
  void _submit(String text) {
    final n = double.tryParse(text);
    if (n != null && n.isFinite) {
      onChanged(uncapped ? n.clamp(1, double.infinity) : n.clamp(min, max));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = DefaultTextStyle.of(
      context,
    ).style.copyWith(fontSize: 14, height: 1.5, fontWeight: FontWeight.w600);
    final number = '${value.round()}';
    final painter = TextPainter(
      text: TextSpan(text: number, style: style),
      textDirection: Directionality.of(context),
    )..layout();
    final numberWidth = painter.width.ceilToDouble() + 4;
    painter.dispose();
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 21,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    '$label:',
                    overflow: TextOverflow.ellipsis,
                    style: style,
                  ),
                ),
                const SizedBox(width: 3),
                SizedBox(
                  width: numberWidth,
                  child: TextFormField(
                    key: ValueKey('$label:$value'),
                    initialValue: number,
                    textAlign: TextAlign.start,
                    style: style,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      isCollapsed: true,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      contentPadding: EdgeInsets.only(left: 2),
                    ),
                    onFieldSubmitted: _submit,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 12,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                padding: EdgeInsets.zero,
                trackHeight: 12,
                trackShape: const _EditSliderTrack(),
                thumbShape: const _EditSliderThumb(),
                overlayShape: SliderComponentShape.noOverlay,
                tickMarkShape: SliderTickMarkShape.noTickMark,
                showValueIndicator: ShowValueIndicator.never,
                activeTrackColor: scheme.onSurface.withValues(alpha: .08),
                inactiveTrackColor: scheme.onSurface.withValues(alpha: .08),
                thumbColor: scheme.outline,
                overlayColor: scheme.primary,
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: ((max - min) / step).round(),
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(height: 3.2),
        ],
      ),
    );
  }
}

/// Web range geometry: a uniform rail and a rectangular thumb, without ticks.
class _EditSliderTrack extends SliderTrackShape {
  const _EditSliderTrack();
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) => Rect.fromLTWH(
    offset.dx + 6,
    offset.dy + (parentBox.size.height - 12) / 2,
    math.max(0, parentBox.size.width - 12),
    12,
  );

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
  }) {
    final rect = Rect.fromLTWH(
      offset.dx,
      offset.dy + (parentBox.size.height - 12) / 2,
      parentBox.size.width,
      12,
    );
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = sliderTheme.inactiveTrackColor!,
    );
  }
}

class _EditSliderThumb extends SliderComponentShape {
  const _EditSliderThumb();
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(12, 18);
  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final color = Color.lerp(
      sliderTheme.thumbColor,
      sliderTheme.overlayColor,
      activationAnimation.value,
    )!;
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 12, height: 18),
        const Radius.circular(3),
      ),
      Paint()..color = color,
    );
  }
}

class EditImageToolbar extends StatefulWidget {
  const EditImageToolbar({
    super.key,
    required this.state,
    required this.width,
    required this.onHsv,
    required this.onClear,
    required this.onResize,
  });
  final EditorState state;
  final double width;
  final VoidCallback onHsv, onClear, onResize;
  @override
  State<EditImageToolbar> createState() => _EditImageToolbarState();
}

class _EditImageToolbarState extends State<EditImageToolbar> {
  final _overlay = OverlayPortalController();
  final _anchor = GlobalKey();
  Offset _position = Offset.zero;
  void _toggle() {
    if (_overlay.isShowing) {
      _overlay.hide();
      return;
    }
    final box = _anchor.currentContext!.findRenderObject()! as RenderBox;
    final root = Overlay.of(context).context.findRenderObject()! as RenderBox;
    _position = root.globalToLocal(box.localToGlobal(Offset.zero));
    _overlay.show();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      widget.state,
      widget.state.toolChangeNotifier,
      widget.state.historyManager,
    ]),
    builder: (context, _) {
      final state = widget.state, l = context.l10n;
      final tools = state.tools;
      final visible = math.max(
        0,
        math.min(tools.length, ((widget.width - 6 - 5 * 44) / 44).floor() - 1),
      );
      final allFit = widget.width >= 6 + (tools.length + 5) * 44;
      final shown = allFit ? tools : tools.take(visible).toList(),
          extra = allFit ? const <EditorTool>[] : tools.skip(visible).toList();
      Widget button(EditorTool tool) => EditButton(
        key: Key('edit_tool_${tool.id}'),
        tooltip: editToolLabel(context, tool.id),
        glyph: editToolGlyph(tool.id),
        selected: tool == state.currentTool,
        onPressed: () {
          state.setTool(tool);
          _overlay.hide();
        },
      );
      return InpaintPanel(
        width: widget.width,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Row(
            children: [
              ...shown.map(button),
              if (extra.isNotEmpty)
                OverlayPortal(
                  controller: _overlay,
                  overlayChildBuilder: (context) => Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _overlay.hide,
                        ),
                      ),
                      Positioned(
                        left: _position.dx.clamp(
                          10,
                          math.max(
                            10,
                            MediaQuery.sizeOf(context).width -
                                math.min(352, extra.length * 44 + 6) -
                                10,
                          ),
                        ),
                        bottom:
                            MediaQuery.sizeOf(context).height -
                            _position.dy +
                            8,
                        child: InpaintPanel(
                          width: math.min(352, extra.length * 44 + 6),
                          child: Wrap(children: extra.map(button).toList()),
                        ),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    key: _anchor,
                    child: EditButton(
                      tooltip: l.img2img_moreActions,
                      onPressed: _toggle,
                      glyph: extra.contains(state.currentTool)
                          ? editToolGlyph(state.currentTool!.id)
                          : 'more',
                      selected: extra.contains(state.currentTool),
                    ),
                  ),
                ),
              const Spacer(),
              EditButton(
                tooltip: l.editor_hsvAdjustment,
                glyph: 'hsv',
                onPressed: widget.onHsv,
              ),
              EditButton(
                tooltip: l.editor_clearLayer,
                glyph: 'clear',
                onPressed: widget.onClear,
              ),
              EditButton(
                tooltip: l.editor_changeCanvasSize,
                glyph: 'shift',
                onPressed: widget.onResize,
              ),
              EditButton(
                tooltip: l.editor_undo,
                glyph: 'undo',
                onPressed: state.canUndo ? state.undo : null,
              ),
              EditButton(
                tooltip: l.editor_redo,
                glyph: 'redo',
                onPressed: state.canRedo ? state.redo : null,
              ),
            ],
          ),
        ),
      );
    },
  );
}
