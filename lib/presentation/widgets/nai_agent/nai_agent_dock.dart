import 'package:flutter/material.dart';
import '../../../core/nai_agent/panel_layout.dart';
import '../../screens/generation/widgets/resize_handle.dart';
import 'nai_agent_panel.dart';

/// A fixed content viewport: the host clips the reveal instead of squeezing
/// text through every intermediate opening width.
class NaiAgentDock extends StatelessWidget {
  const NaiAgentDock({
    super.key,
    required this.width,
    required this.onDrag,
    this.onDragStart,
    this.onDragEnd,
    this.onDragCancel,
  });
  final double width;
  final ValueChanged<double> onDrag;
  final VoidCallback? onDragStart, onDragEnd, onDragCancel;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ResizeHandle(
        key: const Key('nai-agent-resize'),
        width: AgentPanelLayout.handle,
        onDrag: onDrag,
        onDragStart: onDragStart,
        onDragEnd: onDragEnd,
        onDragCancel: onDragCancel,
      ),
      SizedBox(
        width: width,
        child: ClipRect(
          child: DecoratedBox(
            key: const Key('nai-agent-divider'),
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: const RepaintBoundary(child: NaiAgentPanel()),
          ),
        ),
      ),
    ],
  );
}
