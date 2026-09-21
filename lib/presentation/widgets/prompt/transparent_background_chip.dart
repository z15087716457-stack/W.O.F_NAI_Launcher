import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/model_spec.dart';
import '../../../core/utils/localization_extension.dart';
import '../../providers/generation/generation_params_notifier.dart';

/// V5 透明背景片（官方 Transparent BG）
///
/// 仅 transparency 能力位开启的模型显示；点击切换
/// [ImageParams.transparentBackground]，开启后等效提示词追加
/// `transparent background` 并随请求发送 `tag_hint_transparent_background`。
/// Compact checkerboard toggle; its name is exposed on hover and to semantics.
class TransparentBackgroundChip extends ConsumerWidget {
  const TransparentBackgroundChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    final isDark = theme.brightness == Brightness.dark;
    final contentColor = enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.45);

    return Tooltip(
      message:
          '${context.l10n.prompt_transparentBg}\n${context.l10n.transparentBackground_tooltip}',
      preferBelow: true,
      verticalOffset: 20,
      waitDuration: const Duration(milliseconds: 300),
      child: Semantics(
        label: context.l10n.prompt_transparentBg,
        toggled: enabled,
        button: true,
        child: InkWell(
          onTap: () => ref
              .read(generationParamsNotifierProvider.notifier)
              .updateTransparentBackground(!enabled),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 官方棋盘格（深浅主题各一版，自带配色不再着色）
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SvgPicture.asset(
                    isDark
                        ? 'assets/icons/nai-icon-checkerboard-dark.svg'
                        : 'assets/icons/nai-icon-checkerboard-light.svg',
                    width: 14,
                    height: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  enabled ? Icons.check : Icons.close,
                  size: 12,
                  color: contentColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
