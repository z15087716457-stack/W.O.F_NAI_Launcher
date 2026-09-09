import 'package:flutter/material.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/subscription_expiry_utils.dart';

/// 订阅到期展示文本（各账号切换/详情表面共用）
///
/// 输出形如「到期 yyyy-MM-dd · 剩 X 天」，按状态着色：
/// 正常=onSurfaceVariant、临期（≤7 天）=橙、已过期=error。
class SubscriptionExpiryText extends StatelessWidget {
  /// 订阅到期时间（Unix 时间戳秒）
  final int expiresAt;

  /// 字号（默认 11，与各账号列表小字行一致）
  final double fontSize;

  /// 是否带「到期 yyyy-MM-dd」前缀（详情行等已有标签的场景可关闭）
  final bool includeDate;

  const SubscriptionExpiryText({
    super.key,
    required this.expiresAt,
    this.fontSize = 11,
    this.includeDate = true,
  });

  /// 状态对应颜色（供行值等着色场景复用）
  static Color statusColor(
    BuildContext context,
    SubscriptionExpiryStatus status,
  ) {
    final theme = Theme.of(context);
    return switch (status) {
      SubscriptionExpiryStatus.expired => theme.colorScheme.error,
      SubscriptionExpiryStatus.expiringSoon => Colors.orange,
      SubscriptionExpiryStatus.normal => theme.colorScheme.onSurfaceVariant,
    };
  }

  /// 状态文案（剩 X 天 / 已过期）
  static String statusTextOf(
    BuildContext context,
    SubscriptionExpiryInfo info,
  ) {
    return switch (info.status) {
      SubscriptionExpiryStatus.expired => context.l10n.subscriptionExpired,
      _ => context.l10n.subscriptionDaysLeft(info.daysLeft),
    };
  }

  @override
  Widget build(BuildContext context) {
    final info = getSubscriptionExpiryInfo(expiresAt);
    final statusText = statusTextOf(context, info);
    final displayText = includeDate
        ? '${context.l10n.subscriptionExpiresOn(info.formattedDate)} · $statusText'
        : statusText;

    return Text(
      displayText,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: statusColor(context, info.status),
        fontSize: fontSize,
      ),
    );
  }
}
