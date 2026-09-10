import 'package:flutter/material.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../../core/utils/subscription_expiry_utils.dart';

/// 订阅到期展示文本（各账号切换/详情表面共用）
///
/// 输出形如「到期 yyyy-MM-dd · 剩 X 天」，按状态着色：
/// 正常=onSurfaceVariant、临期（≤7 天）=橙、已过期=error。
/// 到期时间戳无效（服务端哨兵值）时不显示日期，只留状态文案
/// （见 [SubscriptionExpiryInfo.displayDate]）。
class SubscriptionExpiryText extends StatelessWidget {
  /// 订阅到期时间（Unix 时间戳秒）
  final int expiresAt;

  /// 字号（默认 11，与各账号列表小字行一致）
  final double fontSize;

  /// 是否显示「到期 yyyy-MM-dd」日期（详情行等已有独立标签的场景可关闭）
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

  /// 组合「日期 · 状态」文案；时间戳不可信时只返回状态文案。
  ///
  /// [withExpiresOnLabel] 为真时日期带「到期」前缀，供已有独立标签的详情行关闭。
  static String dateStatusTextOf(
    BuildContext context,
    SubscriptionExpiryInfo info, {
    bool withExpiresOnLabel = false,
  }) {
    final statusText = statusTextOf(context, info);
    final date = info.displayDate;
    if (date == null) return statusText;

    return '${withExpiresOnLabel ? context.l10n.subscriptionExpiresOn(date) : date}'
        ' · $statusText';
  }

  @override
  Widget build(BuildContext context) {
    final info = getSubscriptionExpiryInfo(expiresAt);
    final displayText = includeDate
        ? dateStatusTextOf(context, info, withExpiresOnLabel: true)
        : statusTextOf(context, info);

    return Text(
      displayText,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: statusColor(context, info.status),
        fontSize: fontSize,
      ),
    );
  }
}
