import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../../core/utils/localization_extension.dart';
import '../../core/editor_state.dart';

/// Mask editing has its own controls. Ordinary painting presets and export
/// settings must never leak into this surface.
class InpaintPanel extends StatelessWidget {
  const InpaintPanel({super.key, required this.child, this.width});
  final Widget child;
  final double? width;
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surfaceContainer,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(2),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
    ),
    clipBehavior: Clip.antiAlias,
    child: SizedBox(width: width, child: child),
  );
}

class InpaintGlyph extends StatelessWidget {
  const InpaintGlyph(this.name, {super.key, this.color, this.size = 18});
  final String name;
  final Color? color;
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    // The SVG renderer derives width from height for non-square source assets.
    // Tight bounds keep the official undo and ordering arrows inside their slots.
    child: SvgPicture.asset(
      'assets/icons/inpaint_$name.svg',
      width: size,
      height: size,
      fit: BoxFit.contain,
      colorFilter: ColorFilter.mode(
        color ?? Theme.of(context).colorScheme.onSurface,
        BlendMode.srcIn,
      ),
      excludeFromSemantics: true,
    ),
  );
}

class InpaintButton extends StatelessWidget {
  const InpaintButton({
    super.key,
    required this.glyph,
    required this.tooltip,
    this.onPressed,
    this.selected = false,
    this.size = 44,
    this.glyphSize = 16,
  });
  final String tooltip;
  final VoidCallback? onPressed;
  final bool selected;
  final double size;
  final String glyph;
  final double glyphSize;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        button: true,
        selected: selected,
        enabled: onPressed != null,
        child: Material(
          color: selected ? scheme.primaryContainer : Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: SizedBox(
              width: size,
              height: size,
              child: Center(
                child: InpaintGlyph(
                  glyph,
                  size: glyphSize,
                  color: onPressed == null
                      ? scheme.onSurface.withValues(alpha: .3)
                      : selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class InpaintToolSettings extends StatelessWidget {
  const InpaintToolSettings({super.key, required this.state});
  final EditorState state;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([state, state.toolChangeNotifier]),
    builder: (context, _) {
      final tool = state.currentTool;
      if (tool == null || tool.id == 'fill') return const SizedBox.shrink();
      final focus = tool.id == 'inpaint_focus';
      final label = focus
          ? context.l10n.editor_focusedArea
          : tool.id == 'eraser'
          ? context.l10n.editor_eraseMask
          : context.l10n.editor_drawMask;
      final value = focus ? state.inpaintContextSize : state.brushSize / 8;
      void update(double v) => focus
          ? state.setInpaintContextSize(v)
          : state.setBrushSize(v.roundToDouble().clamp(1, double.infinity) * 8);
      return InpaintPanel(
        width: focus ? 278 : 246,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: focus ? 86 : 76,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InpaintGlyph(tool.id, size: 20),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              focus
                                  ? context.l10n.editor_minimumContext
                                  : context.l10n.editor_penSize,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 42,
                            height: 26,
                            child: TextFormField(
                              key: ValueKey('${tool.id}:$value'),
                              initialValue: '${value.round()}',
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontSize: 11),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.all(3),
                                border: InputBorder.none,
                              ),
                              onFieldSubmitted: (text) {
                                final v = double.tryParse(text);
                                if (v != null && v.isFinite) update(v);
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 20,
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 8,
                            padding: EdgeInsets.zero,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 5,
                            ),
                            overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 8,
                            ),
                          ),
                          child: Slider(
                            value: value.clamp(focus ? 32 : 4, focus ? 96 : 50),
                            min: focus ? 32 : 4,
                            max: focus ? 96 : 50,
                            divisions: focus ? 8 : 46,
                            onChanged: update,
                          ),
                        ),
                      ),
                      if (!focus)
                        SizedBox(
                          height: 30,
                          child: InkWell(
                            key: const Key('inpaint_square_brush'),
                            onTap: () =>
                                state.setSquareBrush(!state.squareBrush),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Checkbox(
                                    value: state.squareBrush,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    onChanged: (v) =>
                                        state.setSquareBrush(v ?? false),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    context.l10n.editor_squareBrush,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class InpaintToolbar extends StatefulWidget {
  const InpaintToolbar({
    super.key,
    required this.state,
    required this.width,
    required this.onClear,
    required this.onShiftEdges,
  });
  final EditorState state;
  final double width;
  final VoidCallback onClear;
  final VoidCallback onShiftEdges;
  @override
  State<InpaintToolbar> createState() => _InpaintToolbarState();
}

class _InpaintToolbarState extends State<InpaintToolbar> {
  final _appearanceController = OverlayPortalController();
  final _toolbarKey = GlobalKey();
  bool _appearanceOpen = false;

  void _closeAppearance() {
    _appearanceController.hide();
    setState(() => _appearanceOpen = false);
  }

  void _toggleAppearance() {
    if (_appearanceOpen) {
      _closeAppearance();
    } else {
      _appearanceController.show();
      setState(() => _appearanceOpen = true);
    }
  }

  Widget _buildAppearanceOverlay(BuildContext context) {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final toolbar = _toolbarKey.currentContext!.findRenderObject() as RenderBox;
    final origin = toolbar.localToGlobal(Offset.zero, ancestor: overlay);
    final left = (origin.dx + toolbar.size.width - 290).clamp(
      10.0,
      (overlay.size.width - 300).clamp(10.0, double.infinity),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          key: const Key('inpaint_appearance_dismiss'),
          behavior: HitTestBehavior.opaque,
          onTap: _closeAppearance,
          child: const SizedBox.expand(),
        ),
        Positioned(
          left: left,
          bottom: overlay.size.height - origin.dy + 12,
          child: InpaintMaskAppearance(state: widget.state),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      widget.state.toolNotifier,
      widget.state.historyManager,
      widget.state.layerManager,
    ]),
    builder: (context, _) {
      final state = widget.state;
      final l10n = context.l10n;
      final size = widget.width < 320
          ? 30.0
          : widget.width < 540
          ? 34.0
          : 44.0;
      return SizedBox(
        width: widget.width,
        child: OverlayPortal(
          controller: _appearanceController,
          overlayChildBuilder: _buildAppearanceOverlay,
          child: InpaintPanel(
            key: _toolbarKey,
            child: Row(
              children: [
                for (final tool in state.tools)
                  InpaintButton(
                    glyph: tool.id,
                    size: size,
                    tooltip: switch (tool.id) {
                      'brush' => l10n.editor_drawMask,
                      'eraser' => l10n.editor_eraseMask,
                      'fill' => l10n.editor_toolFill,
                      _ => l10n.editor_focusedArea,
                    },
                    selected: state.currentTool?.id == tool.id,
                    onPressed: () => state.setTool(tool),
                  ),
                const Spacer(),
                InpaintButton(
                  key: const Key('inpaint_palette'),
                  glyph: 'palette',
                  size: size,
                  tooltip: l10n.editor_maskAppearance,
                  selected: _appearanceOpen,
                  onPressed: _toggleAppearance,
                ),
                InpaintButton(
                  key: const Key('inpaint_clear'),
                  glyph: 'clear',
                  size: size,
                  tooltip: l10n.editor_resetMask,
                  onPressed: widget.onClear,
                ),
                InpaintButton(
                  key: const Key('inpaint_shift'),
                  glyph: 'shift',
                  size: size,
                  tooltip: l10n.editor_shiftEdges,
                  onPressed: widget.onShiftEdges,
                ),
                InpaintButton(
                  key: const Key('inpaint_undo'),
                  glyph: 'undo',
                  size: size,
                  tooltip: l10n.editor_undo,
                  onPressed: state.canUndo ? state.undo : null,
                ),
                InpaintButton(
                  key: const Key('inpaint_redo'),
                  glyph: 'redo',
                  size: size,
                  tooltip: l10n.editor_redo,
                  onPressed: state.canRedo ? state.redo : null,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class InpaintMaskAppearance extends StatelessWidget {
  const InpaintMaskAppearance({super.key, required this.state});
  final EditorState state;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) => InpaintPanel(
      width: 290,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.editor_maskColor,
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final color in const [
                  Color(0xFF6464C8),
                  Color(0xFFE5C546),
                  Color(0xFFC64BB5),
                  Color(0xFF39B9BC),
                  Color(0xFFD84B45),
                  Color(0xFF4BBB4D),
                  Color(0xFFB865CD),
                  Color(0xFFCF8635),
                  Color(0xFF4388BA),
                  Color(0xFFBBC53E),
                ])
                  InkWell(
                    onTap: () => state.setMaskAppearance(color: color),
                    child: Container(
                      width: 23,
                      height: 23,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: state.maskDisplayColor == color
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${context.l10n.editor_maskOpacity}: ${(state.maskDisplayOpacity * 100).round()}%',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            SizedBox(
              height: 28,
              child: Slider(
                value: state.maskDisplayOpacity,
                min: 0,
                max: 1,
                onChanged: (value) => state.setMaskAppearance(opacity: value),
              ),
            ),
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: state.maskDisplayBorder,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onChanged: (value) =>
                        state.setMaskAppearance(border: value),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.editor_maskBorder,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final pattern in MaskDisplayPattern.values)
                  InpaintButton(
                    size: 34,
                    selected: state.maskDisplayPattern == pattern,
                    onPressed: () => state.setMaskAppearance(pattern: pattern),
                    glyph: 'pattern_${pattern.name}',
                    glyphSize: 20,
                    tooltip: switch (pattern) {
                      MaskDisplayPattern.solid =>
                        context.l10n.editor_patternSolid,
                      MaskDisplayPattern.lines =>
                        context.l10n.editor_patternLines,
                      MaskDisplayPattern.crosshatch =>
                        context.l10n.editor_patternCrosshatch,
                      MaskDisplayPattern.dots =>
                        context.l10n.editor_patternDots,
                      MaskDisplayPattern.grid =>
                        context.l10n.editor_patternGrid,
                      MaskDisplayPattern.checker =>
                        context.l10n.editor_patternChecker,
                      MaskDisplayPattern.hearts =>
                        context.l10n.editor_patternHearts,
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
