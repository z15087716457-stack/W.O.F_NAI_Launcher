import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/cost_estimate_provider.dart';
import '../../providers/subscription_provider.dart';

/// Anlas 成本徽章
///
/// 显示当前生成配置的预计 Anlas 消耗
/// 根据余额状态显示不同颜色
class AnlasCostBadge extends ConsumerWidget {
  final bool isGenerating;
  final int? costOverride;

  const AnlasCostBadge({
    super.key,
    required this.isGenerating,
    this.costOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int cost = costOverride ?? ref.watch(estimatedCostProvider) ?? 0;
    final isFree = cost == 0;

    // 生成中或免费时不显示
    if (isGenerating || isFree) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final balance = ref.watch(anlasBalanceProvider);
    final isInsufficient = costOverride == null
        ? ref.watch(isBalanceInsufficientProvider)
        : balance != null && balance < cost;

    // 价格徽章颜色
    Color badgeColor;
    Color badgeTextColor;

    if (isInsufficient) {
      badgeColor = theme.colorScheme.error;
      badgeTextColor = Colors.white;
    } else {
      badgeColor = theme.colorScheme.primaryContainer;
      badgeTextColor = theme.colorScheme.onPrimaryContainer;
    }

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$cost',
        style: TextStyle(
          color: badgeTextColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
