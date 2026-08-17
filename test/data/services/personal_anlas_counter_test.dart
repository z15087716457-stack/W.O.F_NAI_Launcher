import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nai_launcher/data/services/personal_anlas_counter_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<PersonalAnlasCounter> bootCounter(ProviderContainer c) async {
    final notifier = c.read(personalAnlasCounterProvider.notifier);
    // 等待 SharedPreferences 异步加载完成
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return notifier;
  }

  group('PersonalAnlasCounter', () {
    test('初始状态 5000/0，配额 5000，重置日未设置', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await bootCounter(c);
      final s = c.read(personalAnlasCounterProvider);
      expect(s.subscriptionRemaining, 5000);
      expect(s.purchasedRemaining, 0);
      expect(s.subscriptionQuota, 5000);
      expect(s.resetDay, 0);
      expect(s.isOverdrawn, isFalse);
    });

    test('扣减顺序：先扣订阅，不足溢出到购买（允许负数=超支）', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = await bootCounter(c);

      await n.recordCost(200);
      var s = c.read(personalAnlasCounterProvider);
      expect(s.subscriptionRemaining, 4800);
      expect(s.purchasedRemaining, 0);

      await n.updateSettings(subscriptionRemaining: 100);
      await n.recordCost(150);
      s = c.read(personalAnlasCounterProvider);
      expect(s.subscriptionRemaining, 0);
      expect(s.purchasedRemaining, -50);
      expect(s.isOverdrawn, isTrue);
    });

    test('购买点手动充值累加', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = await bootCounter(c);
      await n.addPurchased(1000);
      await n.addPurchased(500);
      expect(c.read(personalAnlasCounterProvider).purchasedRemaining, 1500);
    });

    test('JSON 持久化可完整还原', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = await bootCounter(c);
      await n.recordCost(200);
      await n.addPurchased(300);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('personal_anlas_counter_v1');
      expect(raw, isNotNull);
      final restored = PersonalAnlasState.fromJson(
        jsonDecode(raw!) as Map<String, dynamic>,
      );
      expect(restored.subscriptionRemaining, 4800);
      expect(restored.purchasedRemaining, 300);
      expect(restored.subscriptionQuota, 5000);
    });

    test('到达重置周期：订阅补回配额、购买不变（补回制不累积）', () async {
      final now = DateTime.now();
      final resetDay = now.subtract(const Duration(days: 5)).day;
      SharedPreferences.setMockInitialValues({
        'personal_anlas_counter_v1': jsonEncode({
          'subscriptionRemaining': 123,
          'purchasedRemaining': 7,
          'subscriptionQuota': 5000,
          'resetDay': resetDay,
          'lastResetAt':
              now.subtract(const Duration(days: 40)).toIso8601String(),
        }),
      });
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await bootCounter(c);
      final s = c.read(personalAnlasCounterProvider);
      expect(s.subscriptionRemaining, 5000);
      expect(s.purchasedRemaining, 7);
      expect(s.lastResetAt, isNotNull);
    });

    test('首次运行只建重置基线、不动剩余', () async {
      final now = DateTime.now();
      final resetDay = now.subtract(const Duration(days: 5)).day;
      SharedPreferences.setMockInitialValues({
        'personal_anlas_counter_v1': jsonEncode({
          'subscriptionRemaining': 123,
          'purchasedRemaining': 7,
          'subscriptionQuota': 5000,
          'resetDay': resetDay,
        }),
      });
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await bootCounter(c);
      final s = c.read(personalAnlasCounterProvider);
      expect(s.subscriptionRemaining, 123);
      expect(s.purchasedRemaining, 7);
      expect(s.lastResetAt, isNotNull);
    });

    test('observeSubscription 从到期时间推断重置日，且不覆盖已设置值', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = await bootCounter(c);

      final expires = DateTime.utc(2026, 9, 15).millisecondsSinceEpoch ~/ 1000;
      await n.observeSubscription(expires);
      expect(c.read(personalAnlasCounterProvider).resetDay, 15);

      // 再次观测（不同日期）不覆盖
      await n.observeSubscription(
        DateTime.utc(2026, 9, 20).millisecondsSinceEpoch ~/ 1000,
      );
      expect(c.read(personalAnlasCounterProvider).resetDay, 15);

      // null 安全
      await n.observeSubscription(null);
      expect(c.read(personalAnlasCounterProvider).resetDay, 15);
    });

    test('手动补满订阅点', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = await bootCounter(c);
      await n.recordCost(1000);
      expect(c.read(personalAnlasCounterProvider).subscriptionRemaining, 4000);
      await n.resetSubscriptionNow();
      expect(c.read(personalAnlasCounterProvider).subscriptionRemaining, 5000);
    });

    test('修改重置日重建基线但不吞剩余', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = await bootCounter(c);
      await n.recordCost(500);
      await n.updateSettings(resetDay: 15);
      final s = c.read(personalAnlasCounterProvider);
      expect(s.subscriptionRemaining, 4500);
      expect(s.resetDay, 15);
      expect(n.nextResetDate(), isNotNull);
    });

    test('无效消耗（0/负数）不记账', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = await bootCounter(c);
      await n.recordCost(0);
      await n.recordCost(-10);
      final s = c.read(personalAnlasCounterProvider);
      expect(s.subscriptionRemaining, 5000);
      expect(s.purchasedRemaining, 0);
    });
  });
}
