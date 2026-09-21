import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/localization_extension.dart';
import '../../providers/layout_state_provider.dart';

/// 块库面板开关按钮（生成页提示词顶栏）。
///
/// 切换页面级右侧块库 dock（[BlockLibraryPanelSlot]），选中态高亮。
class BlockLibraryPanelToggleButton extends ConsumerWidget {
  const BlockLibraryPanelToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expanded = ref.watch(
      layoutStateNotifierProvider.select((s) => s.blockLibraryPanelExpanded),
    );
    final theme = Theme.of(context);

    return Tooltip(
      message: context.l10n.promptBlockEditor_library,
      waitDuration: const Duration(milliseconds: 300),
      child: IconButton(
        key: const Key('block-library-panel-toggle'),
        iconSize: 18,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: expanded
              ? theme.colorScheme.primaryContainer
              : Colors.transparent,
          foregroundColor: expanded
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurfaceVariant,
        ),
        onPressed: () => ref
            .read(layoutStateNotifierProvider.notifier)
            .toggleBlockLibraryPanel(),
        icon: const Icon(Icons.view_module_outlined),
      ),
    );
  }
}
