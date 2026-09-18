import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/prompt_token_counter_service.dart';
import '../../../core/utils/localization_extension.dart';

class PromptTokenCountAsyncBar extends StatelessWidget {
  const PromptTokenCountAsyncBar({super.key, required this.usage});

  final AsyncValue<PromptTokenUsage?> usage;

  @override
  Widget build(BuildContext context) {
    return usage.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      data: (usage) => usage == null
          ? const SizedBox.shrink()
          : PromptTokenCountBar(usage: usage),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class PromptTokenCountBar extends StatelessWidget {
  const PromptTokenCountBar({super.key, required this.usage});

  final PromptTokenUsage usage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = usage.isOverLimit
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    final tokenText = '${usage.usedTokens} / ${usage.limit}';
    final label = Text(
      tokenText,
      style: theme.textTheme.bodySmall?.copyWith(
        color: color,
        fontWeight: usage.isOverLimit ? FontWeight.w600 : FontWeight.w500,
        fontSize: 11,
      ),
    );

    // 官网式横向长条：满宽细进度条 + 右端计数；超额整条转 error 色。
    // 窄宽（面板被挤压/探索页小窗）时计数退位，只留细条，避免溢出。
    final fill = (usage.usedTokens / usage.limit).clamp(0.0, 1.0).toDouble();
    final progress = ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: fill,
        minHeight: 3,
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(
          usage.isOverLimit
              ? theme.colorScheme.error
              : theme.colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
    );
    final bar = LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxWidth.isFinite || constraints.maxWidth >= 96) {
          return Row(
            children: [
              Expanded(child: progress),
              const SizedBox(width: 8),
              label,
            ],
          );
        }
        return progress;
      },
    );

    return usage.breakdown.isEmpty
        ? bar
        : Tooltip(
            message: _buildTooltipMessage(context),
            waitDuration: const Duration(milliseconds: 250),
            child: bar,
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
