import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/layout_state_provider.dart';
import '../../../providers/pill_workspace_provider.dart';
import 'block_library_panel.dart';
import 'resize_handle.dart';

/// 块库面板插槽（经典布局与官网式布局共用）
///
/// 自管理拖拽宽度；面板收起时渲染为空。
class BlockLibraryPanelSlot extends ConsumerStatefulWidget {
  const BlockLibraryPanelSlot({
    super.key,
    this.fallbackScope = PillScopes.main,
    this.rightDock = false,
    this.overlay = false,
  });

  /// 透传给 [BlockLibraryPanel] 的点击插入回退 lane。
  final String fallbackScope;

  /// 是否作为右侧 dock 渲染：分隔条位于面板左侧，拖动方向与右侧面板一致。
  final bool rightDock;

  /// Floats over the exploration stage; the generation dock keeps its default.
  final bool overlay;

  @override
  ConsumerState<BlockLibraryPanelSlot> createState() =>
      _BlockLibraryPanelSlotState();
}

class _BlockLibraryPanelSlotState extends ConsumerState<BlockLibraryPanelSlot> {
  @override
  Widget build(BuildContext context) {
    final layoutState = ref.watch(layoutStateNotifierProvider);
    if (!layoutState.blockLibraryPanelExpanded) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = layoutState.blockLibraryPanelWidth
            .clamp(
              0.0,
              widget.overlay
                  ? (constraints.maxWidth - 8).clamp(0.0, double.infinity)
                  : double.infinity,
            )
            .toDouble();
        final theme = Theme.of(context);
        final decoration = BoxDecoration(
          boxShadow: widget.overlay
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.4 : 0.14,
                    ),
                    offset: const Offset(0, 12),
                    blurRadius: 40,
                  ),
                ]
              : null,
          color: theme.colorScheme.surface,
          border: Border(
            left: (widget.rightDock && !widget.overlay)
                ? BorderSide(color: theme.dividerColor)
                : BorderSide.none,
            right: (widget.rightDock && !widget.overlay)
                ? BorderSide.none
                : BorderSide(color: theme.dividerColor),
          ),
        );
        final panel = Container(
          width: width,
          decoration: decoration,
          child: widget.overlay
              ? ClipRect(
                  child: BlockLibraryPanel(fallbackScope: widget.fallbackScope),
                )
              : BlockLibraryPanel(fallbackScope: widget.fallbackScope),
        );
        final resizeHandle = ResizeHandle(
          key: const Key('block-library-panel-resize-handle'),
          onDrag: (dx) {
            final currentWidth = ref
                .read(layoutStateNotifierProvider)
                .blockLibraryPanelWidth;
            final effectiveWidth = widget.overlay
                ? currentWidth.clamp(
                    0.0,
                    (constraints.maxWidth - 8).clamp(0.0, double.infinity),
                  )
                : currentWidth;
            final newWidth =
                effectiveWidth +
                (widget.rightDock && !widget.overlay ? -dx : dx);
            ref
                .read(layoutStateNotifierProvider.notifier)
                .setBlockLibraryPanelWidth(newWidth);
          },
        );

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.overlay
              ? [panel, resizeHandle]
              : widget.rightDock
              ? [resizeHandle, ClipRect(child: panel)]
              : [ClipRect(child: panel), resizeHandle],
        );
      },
    );
  }
}
