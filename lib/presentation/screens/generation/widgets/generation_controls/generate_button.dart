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
  final String? labelOverride;

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
    this.labelOverride,
    this.height = 48,
    this.imageCount = 1,
    this.copySeed = 0,
  });

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
    if (labelOverride != null) return labelOverride!;
    return GenerateButtonCopy.pick(
      seed: copySeed,
      count: imageCount,
      languageCode: Localizations.localeOf(context).languageCode,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (showCancel) {
      return GenerationCancelButtons(
        height: height,
        generationState: generationState,
        onCancel: onCancel,
        onSkipCurrent: onSkipCurrent,
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

/// Stop always occupies the same full-width slot as Generate. A separate
/// secondary row keeps batch skipping available without shrinking Stop.
class GenerationCancelButtons extends StatelessWidget {
  const GenerationCancelButtons({
    super.key,
    required this.generationState,
    required this.onCancel,
    required this.onSkipCurrent,
    this.height = 48,
  });

  final ImageGenerationState generationState;
  final VoidCallback onCancel;
  final VoidCallback onSkipCurrent;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const yellow = Color(0xffe2c35b);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (generationState.currentImage > 0 &&
            generationState.totalImages > generationState.currentImage)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const ValueKey('skip-current-generation'),
              onPressed: onSkipCurrent,
              icon: const Icon(Icons.skip_next, size: 16),
              label: Text(
                '${context.l10n.generation_skipCurrentBatch} '
                '${generationState.currentImage}/${generationState.totalImages}',
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
            ),
          ),
        SizedBox(
          key: const ValueKey('stop-all-generation'),
          width: double.infinity,
          height: height,
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              border: Border.all(color: yellow.withValues(alpha: .6)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: CustomPaint(
                painter: const _StopStripesPainter(),
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: onCancel,
                    hoverColor: yellow.withValues(alpha: .12),
                    focusColor: yellow.withValues(alpha: .12),
                    highlightColor: yellow.withValues(alpha: .2),
                    splashFactory: NoSplash.splashFactory,
                    child: Semantics(
                      button: true,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.stop_circle_outlined,
                              size: 18,
                              color: yellow,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.l10n.generation_stopAllGeneration,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: yellow,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StopStripesPainter extends CustomPainter {
  const _StopStripesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xff202019),
    );
    final paint = Paint()..color = const Color(0xff363322);
    for (double x = -size.height; x < size.width + size.height; x += 28) {
      canvas.drawPath(
        Path()
          ..moveTo(x, size.height)
          ..lineTo(x + size.height, 0)
          ..lineTo(x + size.height + 14, 0)
          ..lineTo(x + 14, size.height)
          ..close(),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StopStripesPainter oldDelegate) => false;
}
