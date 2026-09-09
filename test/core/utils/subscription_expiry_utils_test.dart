import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/subscription_expiry_utils.dart';

void main() {
  group('getSubscriptionExpiryInfo pure function boundary tests', () {
    // 固定当前时间基准: 2026-09-09 12:00:00 (UTC/本地一致测试)
    final baseline = DateTime(2026, 9, 9, 12, 0, 0);

    test('未到期正常状态：恰好 8 天后到期 (normal, daysLeft == 8)', () {
      final expiry = DateTime(2026, 9, 17, 12, 0, 0);
      final expiresAt = expiry.millisecondsSinceEpoch ~/ 1000;

      final info = getSubscriptionExpiryInfo(expiresAt, now: baseline);

      expect(info.status, SubscriptionExpiryStatus.normal);
      expect(info.isExpired, isFalse);
      expect(info.isExpiringSoon, isFalse);
      expect(info.daysLeft, 8);
      expect(info.formattedDate, '2026-09-17');
    });

    test('临期边界测试：恰好 7 天后到期 (expiringSoon, daysLeft == 7)', () {
      final expiry = DateTime(2026, 9, 16, 12, 0, 0);
      final expiresAt = expiry.millisecondsSinceEpoch ~/ 1000;

      final info = getSubscriptionExpiryInfo(expiresAt, now: baseline);

      expect(info.status, SubscriptionExpiryStatus.expiringSoon);
      expect(info.isExpired, isFalse);
      expect(info.isExpiringSoon, isTrue);
      expect(info.daysLeft, 7);
      expect(info.formattedDate, '2026-09-16');
    });

    test('临期测试：1 天后到期 (expiringSoon, daysLeft == 1)', () {
      final expiry = DateTime(2026, 9, 10, 12, 0, 0);
      final expiresAt = expiry.millisecondsSinceEpoch ~/ 1000;

      final info = getSubscriptionExpiryInfo(expiresAt, now: baseline);

      expect(info.status, SubscriptionExpiryStatus.expiringSoon);
      expect(info.daysLeft, 1);
      expect(info.formattedDate, '2026-09-10');
    });

    test('裁决行为测试：今天之内尚未过点到期 (expiringSoon, daysLeft == 0)', () {
      // 设定在同一天下午 18:00 到期，当前为 12:00
      final expiry = DateTime(2026, 9, 9, 18, 0, 0);
      final expiresAt = expiry.millisecondsSinceEpoch ~/ 1000;

      final info = getSubscriptionExpiryInfo(expiresAt, now: baseline);

      // 尚未到达时刻，不判定为已过期，而是剩 0 天临期告警
      expect(info.status, SubscriptionExpiryStatus.expiringSoon);
      expect(info.isExpired, isFalse);
      expect(info.isExpiringSoon, isTrue);
      expect(info.daysLeft, 0);
      expect(info.formattedDate, '2026-09-09');
    });

    test('已过期：达到或超过到期时刻 (expired, daysLeft == 0)', () {
      // 1. 同一天稍早时刻（上午 10:00）
      final earlierToday = DateTime(2026, 9, 9, 10, 0, 0);
      final infoEarlier = getSubscriptionExpiryInfo(
        earlierToday.millisecondsSinceEpoch ~/ 1000,
        now: baseline,
      );
      expect(infoEarlier.status, SubscriptionExpiryStatus.expired);
      expect(infoEarlier.isExpired, isTrue);
      expect(infoEarlier.daysLeft, 0);
      expect(infoEarlier.formattedDate, '2026-09-09');

      // 2. 昨天到期
      final yesterday = DateTime(2026, 9, 8, 12, 0, 0);
      final infoYesterday = getSubscriptionExpiryInfo(
        yesterday.millisecondsSinceEpoch ~/ 1000,
        now: baseline,
      );
      expect(infoYesterday.status, SubscriptionExpiryStatus.expired);
      expect(infoYesterday.isExpired, isTrue);
      expect(infoYesterday.daysLeft, 0);
      expect(infoYesterday.formattedDate, '2026-09-08');
    });

    test('日期格式化补零正确 (yyyy-MM-dd)', () {
      final singleDigitDate = DateTime(2026, 1, 5, 12, 0, 0);
      final expiresAt = singleDigitDate.millisecondsSinceEpoch ~/ 1000;

      final info = getSubscriptionExpiryInfo(
        expiresAt,
        now: DateTime(2025, 12, 1),
      );

      expect(info.formattedDate, '2026-01-05');
    });
  });
}
