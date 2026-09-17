import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nai_launcher/core/utils/localization_extension.dart';
import 'package:nai_launcher/presentation/providers/image_generation_provider.dart';
import 'package:nai_launcher/presentation/widgets/common/themed_button.dart';
import 'package:nai_launcher/presentation/widgets/common/anlas_cost_badge.dart';
import 'generate_button_copy.dart';

/// 集成价格徽章的生成按钮
class GenerateButtonWithCost extends ConsumerWidget {
  final bool isGenerating;
  final bool showCancel;
  final ImageGenerationState generationState;
  final int cooldownRemainingSeconds;
  final VoidCallback onGenerate;
  final VoidCallback onCancel;
  final VoidCallback onSkipCurrent;
  final int? costOverride;

  /// 按钮高度（紧凑布局可压低）
  final double height;

  /// 本次点击生成的总张数（请求次数 × 每次张数），用于文案池选句
  final int imageCount;

  /// 文案种子：由外层在总数变化 / 一次生成结束时推进
  final int copySeed;

  const GenerateButtonWithCost({
    super.key,
    required this.isGenerating,
    required this.showCancel,
    required this.generationState,
    this.cooldownRemainingSeconds = 0,
    required this.onGenerate,
    required this.onCancel,
    required this.onSkipCurrent,
    this.costOverride,
    this.height = 48,
    this.imageCount = 1,
    this.copySeed = 0,
  });

  bool get _canSkipCurrentBatch =>
      showCancel &&
      generationState.currentImage > 0 &&
      generationState.totalImages > generationState.currentImage;

  String _progressText() =>
      '${generationState.currentImage}/${generationState.totalImages}';

  String _generateLabelText(BuildContext context) {
    if (isGenerating) {
      return generationState.totalImages > 1
          ? _progressText()
          : context.l10n.generation_generating;
    }
    if (cooldownRemainingSeconds > 0) {
      return context.l10n.generation_cooldownRemaining(
        cooldownRemainingSeconds,
      );
    }
    return GenerateButtonCopy.pick(
      seed: copySeed,
      count: imageCount,
      languageCode: Localizations.localeOf(context).languageCode,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (showCancel) {
      return SizedBox(
        height: height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_canSkipCurrentBatch) ...[
              ThemedButton(
                onPressed: onSkipCurrent,
                icon: const Icon(Icons.skip_next),
                label: Text(
                  '${context.l10n.generation_skipCurrentBatch} ${_progressText()}',
                ),
                style: ThemedButtonStyle.outlined,
              ),
              const SizedBox(width: 8),
            ],
            ThemedButton(
              onPressed: onCancel,
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(context.l10n.generation_stopAllGeneration),
              style: ThemedButtonStyle.outlined,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: height,
      child: ThemedButton(
        onPressed: isGenerating || cooldownRemainingSeconds > 0
            ? null
            : onGenerate,
        icon: isGenerating
            ? null
            : cooldownRemainingSeconds > 0
            ? const Icon(Icons.hourglass_bottom_outlined)
            : null,
        isLoading: isGenerating,
        // Flexible 使 label Row 成为 ThemedButton 内容 Row 的 flex 子项，
        // 从而拿到有界宽度；内部 Expanded 文本才能左对齐撑满。
        label: Flexible(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _generateLabelText(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AnlasCostBadge(
                isGenerating: isGenerating,
                costOverride: costOverride,
              ),
            ],
          ),
        ),
        style: ThemedButtonStyle.filled,
      ),
    );
  }
}
