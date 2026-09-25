import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../providers/cost_estimate_provider.dart';
import '../../providers/subscription_provider.dart';

/// Anlas 成本徽章
///
/// 生成按钮右端的页面底色小框，内容为「数字 + Anlas 图标」。
/// 消耗为 0 时也照常显示；余额不足时整框换警示色。
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

    // 生成中不显示（按钮此时通常已切到取消/进度形态）
    if (isGenerating) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final balance = ref.watch(anlasBalanceProvider);
    final isInsufficient = costOverride == null
        ? ref.watch(isBalanceInsufficientProvider)
        : balance != null && balance < cost;

    // 页面底色小框：浅色白底黑字黑钻石、深色炭黑底白字白钻石，
    // 数字与图标同色；余额不足时整框换 error
    final Color badgeColor = isInsufficient
        ? theme.colorScheme.error
        : theme.colorScheme.surface;
    final Color inkColor = isInsufficient
        ? theme.colorScheme.onError
        : theme.colorScheme.onSurface;

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$cost',
            style: TextStyle(
              color: inkColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 3),
          SvgPicture.asset(
            'assets/icons/nai-icon-anlas.svg',
            height: 12,
            colorFilter: ColorFilter.mode(inkColor, BlendMode.srcIn),
          ),
        ],
      ),
    );
  }
}
