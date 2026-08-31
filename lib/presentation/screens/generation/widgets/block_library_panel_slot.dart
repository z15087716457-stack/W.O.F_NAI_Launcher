import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/layout_state_provider.dart';
import '../../../providers/pill_workspace_provider.dart';
import 'block_library_panel.dart';
import 'resize_handle.dart';

/// 块库面板插槽（经典布局与官网式布局共用）
///
/// 自管理拖拽宽度与动画状态；面板收起时渲染为空。
class BlockLibraryPanelSlot extends ConsumerStatefulWidget {
  const BlockLibraryPanelSlot({
    super.key,
    this.fallbackScope = PillScopes.main,
  });

  /// 透传给 [BlockLibraryPanel] 的点击插入回退 lane。
  final String fallbackScope;

  @override
  ConsumerState<BlockLibraryPanelSlot> createState() =>
      _BlockLibraryPanelSlotState();
}

class _BlockLibraryPanelSlotState extends ConsumerState<BlockLibraryPanelSlot> {
  static const double _minWidth = 260;
  static const double _maxWidth = 480;

  bool _isResizing = false;

  @override
  Widget build(BuildContext context) {
    final layoutState = ref.watch(layoutStateNotifierProvider);
    if (!layoutState.blockLibraryPanelExpanded) {
      return const SizedBox.shrink();
    }

    final width = layoutState.blockLibraryPanelWidth;
    final decoration = BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
    );
    final child = BlockLibraryPanel(fallbackScope: widget.fallbackScope);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_isResizing)
          Container(width: width, decoration: decoration, child: child)
        else
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: width,
            decoration: decoration,
            child: child,
          ),
        ResizeHandle(
          onDragStart: () => setState(() => _isResizing = true),
          onDragEnd: () => setState(() => _isResizing = false),
          onDrag: (dx) {
            final currentWidth = ref
                .read(layoutStateNotifierProvider)
                .blockLibraryPanelWidth;
            final newWidth = (currentWidth + dx).clamp(_minWidth, _maxWidth);
            ref
                .read(layoutStateNotifierProvider.notifier)
                .setBlockLibraryPanelWidth(newWidth.toDouble());
          },
        ),
      ],
    );
  }
}
