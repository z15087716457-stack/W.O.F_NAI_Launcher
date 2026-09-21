import 'package:nai_launcher/presentation/widgets/common/studio_icon.dart';
import 'package:flutter/material.dart';
import '../../../../../core/utils/localization_extension.dart';
import '../../core/editor_state.dart';
import '../../tools/tool_base.dart';
import '../toolbar/editor_overlay_toolbar.dart';

/// The frequent brush controls stay compact; presets and detailed settings
/// remain available from the adjacent menu.
class EditorQuickSettings extends StatelessWidget {
  const EditorQuickSettings({
    super.key,
    required this.state,
    required this.tool,
    required this.inpaint,
    required this.onDetails,
  });
  final EditorState state;
  final EditorTool tool;
  final bool inpaint;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) => EditorOverlayCard(
      width: 252,
      padding: const EdgeInsets.all(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 54,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StudioIcon(tool.icon, size: 18),
                const SizedBox(height: 5),
                Text(
                  tool.id == 'eraser'
                      ? context.l10n.editor_toolEraser
                      : inpaint
                      ? context.l10n.img2img_inpaint
                      : context.l10n.editor_toolBrush,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11),
                ),
                EditorOverlayIconButton(
                  icon: Icons.more_horiz,
                  tooltip: context.l10n.img2img_moreActions,
                  size: 24,
                  iconSize: 15,
                  onPressed: onDetails,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.editor_size,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    SizedBox(
                      width: 48,
                      height: 28,
                      child: TextFormField(
                        key: ValueKey('${tool.id}:${state.brushSize.round()}'),
                        initialValue: '${state.brushSize.round()}',
                        textAlign: TextAlign.end,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.all(4),
                          border: InputBorder.none,
                        ),
                        onFieldSubmitted: (value) {
                          final size = double.tryParse(value);
                          if (size != null) state.setBrushSize(size);
                        },
                      ),
                    ),
                  ],
                ),
                _slider(
                  context,
                  state.brushSize.clamp(1, 500),
                  1,
                  500,
                  state.setBrushSize,
                ),
                if (!inpaint && tool.id == 'brush') ...[
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.l10n.editor_opacity,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      Text(
                        '${(state.brushOpacity * 100).round()}%',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  _slider(
                    context,
                    state.brushOpacity,
                    0,
                    1,
                    state.setBrushOpacity,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _slider(
    BuildContext context,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) => SizedBox(
    height: 26,
    child: SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
      ),
      child: Slider(value: value, min: min, max: max, onChanged: onChanged),
    ),
  );
}
