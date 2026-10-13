import 'dart:math' as math;
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../screens/generation/widgets/resize_handle.dart';
import 'nai_agent_panel.dart';
import 'nai_agent_shared.dart';
import '../../providers/nai_agent/nai_agent_window_controller.dart';

class NaiAgentDock extends ConsumerStatefulWidget {
  const NaiAgentDock({
    super.key,
    required this.maxWidth,
    this.resizable = true,
  });
  final double maxWidth;
  final bool resizable;
  @override
  ConsumerState<NaiAgentDock> createState() => _DockState();
}

class _DockState extends ConsumerState<NaiAgentDock> {
  double? _dragWidth;
  @override
  Widget build(BuildContext context) {
    final preference = ref.watch(
      naiAgentUiPreferencesProvider.select((c) => c.settings.panelWidth),
    );
    final cap = math.min(720.0, widget.maxWidth);
    final width = (_dragWidth ?? preference)
        .clamp(math.min(320.0, cap), cap)
        .toDouble();
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.resizable)
          ResizeHandle(
            key: const Key('nai-agent-resize'),
            onDragStart: () => setState(() => _dragWidth = width),
            onDrag: (dx) => setState(
              () => _dragWidth = (width - dx)
                  .clamp(math.min(320.0, cap), cap)
                  .toDouble(),
            ),
            onDragEnd: () => agentUiAction(context, () async {
              final preferred = _dragWidth ?? width;
              await ref
                  .read(naiAgentWindowControllerProvider)
                  .resizeDock(preferred);
              await ref.read(naiAgentControllerProvider).updateSettings({
                'panelWidth': preferred,
              });
              if (mounted) setState(() => _dragWidth = null);
            }),
          ),
        SizedBox(
          width: width,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: const NaiAgentPanel(),
          ),
        ),
      ],
    );
  }
}
