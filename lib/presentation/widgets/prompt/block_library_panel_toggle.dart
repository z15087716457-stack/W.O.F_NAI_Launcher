import 'package:nai_launcher/presentation/widgets/common/studio_animated_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_icons.dart';

import '../../../core/utils/localization_extension.dart';
import '../../providers/layout_state_provider.dart';

/// 块库面板开关按钮（生成页提示词顶栏）。
///
/// 切换页面级右侧块库 dock，打开状态由面板本身表示。
class BlockLibraryPanelToggleButton extends ConsumerStatefulWidget {
  const BlockLibraryPanelToggleButton({super.key});

  @override
  ConsumerState<BlockLibraryPanelToggleButton> createState() =>
      _BlockLibraryPanelToggleButtonState();
}

class _BlockLibraryPanelToggleButtonState
    extends ConsumerState<BlockLibraryPanelToggleButton> {
  int _motionTrigger = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: context.l10n.promptBlockEditor_library,
      waitDuration: const Duration(milliseconds: 300),
      child: IconButton(
        key: const Key('block-library-panel-toggle'),
        iconSize: 18,
        visualDensity: VisualDensity.compact,
        style: IconButton.styleFrom(
          backgroundColor: Colors.transparent,
          hoverColor: Colors.transparent,
          foregroundColor: theme.colorScheme.onSurfaceVariant,
        ),
        onPressed: () {
          setState(() => _motionTrigger++);
          ref
              .read(layoutStateNotifierProvider.notifier)
              .toggleBlockLibraryPanel();
        },
        icon: StudioAnimatedIcon(
          icon: StudioIcons.promptBlocks,
          trigger: _motionTrigger,
        ),
      ),
    );
  }
}
