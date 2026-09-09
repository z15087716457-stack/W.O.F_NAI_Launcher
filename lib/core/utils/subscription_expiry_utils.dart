/// 订阅到期状态
enum SubscriptionExpiryStatus {
  /// 未到期（正常状态，剩余天数 > 7 天）
  normal,

  /// 临期（剩余天数 ≤ 7 天，且尚未到达过期时刻）
  expiringSoon,

  /// 已过期（到达或超过过期时刻）
  expired,
}

/// 订阅到期展示信息
class SubscriptionExpiryInfo {
  /// 到期状态
  final SubscriptionExpiryStatus status;

  /// 到期 DateTime 对象
  final DateTime expiryDate;

  /// 格式化后的到期日期 (yyyy-MM-dd)
  final String formattedDate;

  /// 剩余天数（按整天计算；已过期时为 0）
  final int daysLeft;

  const SubscriptionExpiryInfo({
    required this.status,
    required this.expiryDate,
    required this.formattedDate,
    required this.daysLeft,
  });

  /// 是否已过期
  bool get isExpired => status == SubscriptionExpiryStatus.expired;

  /// 是否临期（≤ 7 天）
  bool get isExpiringSoon => status == SubscriptionExpiryStatus.expiringSoon;
}

/// 计算并返回订阅到期信息。
///
/// [expiresAtInSeconds] Unix 时间戳（秒）。
/// [now] 可选的当前时间基准，便于单元测试精准注入；默认为 [DateTime.now]。
SubscriptionExpiryInfo getSubscriptionExpiryInfo(
  int expiresAtInSeconds, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final expiry = DateTime.fromMillisecondsSinceEpoch(expiresAtInSeconds * 1000);
  final formattedDate =
      '${expiry.year}-${expiry.month.toString().padLeft(2, '0')}-${expiry.day.toString().padLeft(2, '0')}';

  // 1. 若当前时刻已经达到或超过过期时刻，判定为已过期
  if (current.millisecondsSinceEpoch >= expiresAtInSeconds * 1000) {
    return SubscriptionExpiryInfo(
      status: SubscriptionExpiryStatus.expired,
      expiryDate: expiry,
      formattedDate: formattedDate,
      daysLeft: 0,
    );
  }

  // 2. 尚未到达过期时刻，按自然日整天计算剩余天数
  final currentDay = DateTime(current.year, current.month, current.day);
  final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
  final diffDays = expiryDay.difference(currentDay).inDays;

  // 今天之内到期（diffDays 为 0），按「剩 0 天」（未过期、临期告警）处理
  final daysLeft = diffDays < 0 ? 0 : diffDays;
  final status = daysLeft <= 7
      ? SubscriptionExpiryStatus.expiringSoon
      : SubscriptionExpiryStatus.normal;

  return SubscriptionExpiryInfo(
    status: status,
    expiryDate: expiry,
    formattedDate: formattedDate,
    daysLeft: daysLeft,
  );
}
