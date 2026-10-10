import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/prompt_token_counter_service.dart';
import '../../../core/utils/localization_extension.dart';

class PromptTokenCountAsyncBar extends StatelessWidget {
  const PromptTokenCountAsyncBar({
    super.key,
    required this.usage,
    this.totalTokens,
  });

  final AsyncValue<PromptTokenUsage?> usage;
  final int? totalTokens;

  @override
  Widget build(BuildContext context) {
    return usage.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      data: (usage) => usage == null
          ? const SizedBox.shrink()
          : PromptTokenCountBar(usage: usage, totalTokens: totalTokens),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class PromptTokenCountBar extends StatelessWidget {
  const PromptTokenCountBar({
    super.key,
    required this.usage,
    this.totalTokens,
    this.referenceLimit = false,
  });

  final PromptTokenUsage usage;
  final int? totalTokens;
  final bool referenceLimit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final referenceFull =
        referenceLimit && usage.limit > 0 && usage.usedTokens >= usage.limit;
    final overLimit = (totalTokens ?? usage.usedTokens) > usage.limit;
    final color = overLimit
        ? theme.colorScheme.error
        : theme.colorScheme.onSurface;
    final fill = usage.limit > 0
        ? (usage.usedTokens / usage.limit).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final summary = totalTokens == null
        ? context.l10n.promptToken_usage(usage.usedTokens, usage.limit)
        : context.l10n.promptToken_promptShare(
            usage.usedTokens,
            totalTokens!,
            usage.limit,
          );
    final breakdown = _buildTooltipMessage(context);
    final details = [
      if (breakdown.isNotEmpty) breakdown,
      if (referenceLimit) context.l10n.promptToken_blockReferenceHint,
    ];
    final message = [summary, ...details].join('\n');
    return Tooltip(
      message: message,
      waitDuration: const Duration(milliseconds: 250),
      child: Semantics(
        label: referenceLimit
            ? '$summary. ${context.l10n.promptToken_blockReferenceHint}'
            : summary,
        child: SizedBox(
          height: 14,
          // Keep the hover target comfortable without making the line thicker.
          child: Center(
            child: referenceFull
                ? const SizedBox(
                    key: Key('prompt-token-reference-stripes'),
                    width: double.infinity,
                    height: 5,
                    child: CustomPaint(painter: _ReferenceStripePainter()),
                  )
                : LinearProgressIndicator(
                    value: fill,
                    minHeight: 3,
                    borderRadius: BorderRadius.zero,
                    trackGap: 0,
                    stopIndicatorRadius: 0,
                    backgroundColor: theme.colorScheme.onSurface.withValues(
                      alpha: 0.08,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
          ),
        ),
      ),
    );
  }

  String _buildTooltipMessage(BuildContext context) {
    final displayBreakdown = usage.breakdown.toList(growable: false);
    if (displayBreakdown.isNotEmpty) {
      final breakdownTotal = displayBreakdown.fold<int>(
        0,
        (sum, entry) => sum + entry.tokens,
      );
      final adjustment = usage.usedTokens - breakdownTotal;
      if (adjustment != 0) {
        final targetEntry = displayBreakdown[0];
        displayBreakdown[0] = PromptTokenBreakdownEntry(
          label: targetEntry.label,
          tokens: targetEntry.tokens + adjustment,
        );
      }
    }
    return displayBreakdown
        .map(
          (entry) =>
              '${_localizedBreakdownLabel(context, entry.label)} ${entry.tokens}',
        )
        .join('\n');
  }

  String _localizedBreakdownLabel(BuildContext context, String label) {
    return switch (label) {
      '网页端校准' => context.l10n.promptToken_webCalibration,
      '提示词' => context.l10n.promptToken_prompt,
      '质量预设' => context.l10n.promptToken_qualityPreset,
      '角色' => context.l10n.promptToken_character,
      '负面提示词' => context.l10n.promptToken_negativePrompt,
      '负面预设' => context.l10n.promptToken_negativePreset,
      '角色负面' => context.l10n.promptToken_characterNegative,
      _ => label,
    };
  }
}

class _ReferenceStripePainter extends CustomPainter {
  const _ReferenceStripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.clipRect(bounds);
    canvas.drawRect(bounds, Paint()..color = const Color(0xFFF2C94C));
    final stripe = Paint()
      ..color = const Color(0xFF302A1B)
      ..strokeWidth = 3;
    for (var x = -size.height; x < size.width + size.height; x += 9) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripe,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ReferenceStripePainter oldDelegate) => false;
}
