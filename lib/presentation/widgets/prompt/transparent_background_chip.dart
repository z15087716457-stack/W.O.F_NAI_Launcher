import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/model_spec.dart';
import '../../../core/utils/localization_extension.dart';
import '../../providers/generation/generation_params_notifier.dart';

/// V5 透明背景开关（官方 Transparent BG）
///
/// 仅 transparency 能力位开启的模型显示；点击切换
/// [ImageParams.transparentBackground]，开启后等效提示词追加
/// `transparent background` 并随请求发送 `tag_hint_transparent_background`。
class TransparentBackgroundChip extends ConsumerStatefulWidget {
  const TransparentBackgroundChip({super.key});

  @override
  ConsumerState<TransparentBackgroundChip> createState() =>
      _TransparentBackgroundChipState();
}

class _TransparentBackgroundChipState
    extends ConsumerState<TransparentBackgroundChip> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final model = ref.watch(
      generationParamsNotifierProvider.select((params) => params.model),
    );
    if (!ModelSpecs.of(model).transparency) {
      return const SizedBox.shrink();
    }
    final enabled = ref.watch(
      generationParamsNotifierProvider.select(
        (params) => params.transparentBackground,
      ),
    );
    final accent = Colors.teal;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: context.l10n.transparentBackground_tooltip,
        preferBelow: true,
        verticalOffset: 20,
        waitDuration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: () => ref
              .read(generationParamsNotifierProvider.notifier)
              .updateTransparentBackground(!enabled),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: enabled
                  ? (_isHovering
                        ? accent.withValues(alpha: 0.25)
                        : accent.withValues(alpha: 0.12))
                  : (_isHovering
                        ? theme.colorScheme.surfaceContainerHighest
                        : Colors.transparent),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: enabled
                    ? accent.withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.opacity,
                  size: 14,
                  color: enabled
                      ? accent.shade700
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 4),
                Text(
                  context.l10n.transparentBackground_label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: enabled ? FontWeight.w600 : FontWeight.w500,
                    color: enabled
                        ? accent.shade700
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
