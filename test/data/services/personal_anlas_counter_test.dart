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

  group('PersonalAnlasCounter · V5 Opus 免费额度份额', () {
    test('默认两人平分：份额 50%，上限 50%', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await bootCounter(c);
      final s = c.read(personalAnlasCounterProvider);
      expect(s.opusShareRatio, 0.5);
      expect(s.opusRefillShare, 0.5);
      expect(s.opusAllowance, 50);
      expect(s.opusAllowanceCap, 50);
      expect(s.isOpusAllowanceExhausted, isFalse);
    });

    test('免费生成先挂在途，按服务端池子的真实跌幅落账', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = await bootCounter(c);

      // 首次观测只记基线，不产生扣减
      await n.observeOpusUsage(poolPercent: 80);
      expect(c.read(personalAnlasCounterProvider).opusAllowance, 50);

      // 本机发起 2 笔免费生成：单价未知，只登记在途，不猜
      await n.recordOpusUsage(count: 2);
      final pendingState = c.read(personalAnlasCounterProvider);
      expect(pendingState.opusAllowance, 50);
      expect(pendingState.pendingOpusGenerations, 2);

      // 池子 80 → 76.5，这 3.5% 是我花的，按实测数值扣
      await n.observeOpusUsage(poolPercent: 76.5);
      final s = c.read(personalAnlasCounterProvider);
      expect(s.opusAllowance, closeTo(46.5, 1e-9));
      expect(s.pendingOpusGenerations, 0);
      // 额度账本与点数账本互不干扰
      expect(s.subscriptionRemaining, 5000);
    });

    test('没有在途生成时的跌幅算朋友消耗，不记我的账', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = await bootCounter(c);

      await n.observeOpusUsage(poolPercent: 80);
      await n.observeOpusUsage(poolPercent: 60);
      expect(c.read(personalAnlasCounterProvider).opusAllowance, 50);
    });

    test('份额耗尽后 isOpusAllowanceExhausted 为真', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = await bootCounter(c);
      await n.updateOpusSettings(allowance: 0);
      expect(
        c.read(personalAnlasCounterProvider).isOpusAllowanceExhausted,
        isTrue,
      );
    });

    test('splitOpusAllowance(4)：份额与回充分成都变 25%，超额剩余被压到上限', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = await bootCounter(c);

      await n.splitOpusAllowance(4);
      final s = c.read(personalAnlasCounterProvider);
      expect(s.opusShareRatio, 0.25);
      expect(s.opusRefillShare, 0.25);
      expect(s.opusAllowanceCap, 25);
      // 原剩余 50 > 新上限 25，必须压到 25
      expect(s.opusAllowance, 25);
    });

    test('独占（1 人）＝整池归我，上限 100%', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = await bootCounter(c);
      await n.splitOpusAllowance(1);
      final s = c.read(personalAnlasCounterProvider);
      expect(s.opusShareRatio, 1.0);
      expect(s.opusAllowanceCap, 100);
    });

    /// 造一份带既有基线的存档，用于验证「池子涨了按分成入账」。
    /// 走真实存档路径，不给生产代码开测试专用后门。
    void seedWithPoolBaseline({
      required double allowance,
      required double poolPercent,
      double shareRatio = 0.5,
    }) {
      SharedPreferences.setMockInitialValues({
        'personal_anlas_counter_v1': jsonEncode({
          'subscriptionRemaining': 5000,
          'purchasedRemaining': 0,
          'subscriptionQuota': 5000,
          'resetDay': 0,
          'opusShareRatio': shareRatio,
          'opusAllowance': allowance,
          'opusRefillShare': shareRatio,
          'lastObservedPoolPercent': poolPercent,
        }),
      });
    }

    test('池子涨额度按新增分成入账：+20% × 50% = +10%', () async {
      seedWithPoolBaseline(allowance: 10, poolPercent: 60);
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = await bootCounter(c);

      await n.observeOpusUsage(poolPercent: 80);
      final s = c.read(personalAnlasCounterProvider);
      expect(s.opusAllowance, closeTo(20, 1e-9));
      expect(s.lastObservedPoolPercent, 80);
    });

    test('新增分成不越过份额上限（不吃朋友的份）', () async {
      seedWithPoolBaseline(allowance: 48, poolPercent: 10);
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = await bootCounter(c);

      // 48 + (100-10) × 0.5 = 93，必须封在上限 50
      await n.observeOpusUsage(poolPercent: 100);
      expect(c.read(personalAnlasCounterProvider).opusAllowance, 50);
    });

    test('池子没变化时额度不动', () async {
      seedWithPoolBaseline(allowance: 12, poolPercent: 55);
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = await bootCounter(c);

      await n.observeOpusUsage(poolPercent: 55);
      expect(c.read(personalAnlasCounterProvider).opusAllowance, 12);
    });

    test('不带 poolPercent 的观测结不了账，在途继续挂着', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = await bootCounter(c);

      await n.recordOpusUsage(count: 10);

      await n.observeOpusUsage();
      final s = c.read(personalAnlasCounterProvider);
      expect(s.opusAllowance, closeTo(50, 1e-9));
      // 没有观测值就结不了账，在途笔数继续挂着
      expect(s.pendingOpusGenerations, 10);
    });

    test('小数额度按原样结算，不取整', () async {
      seedWithPoolBaseline(allowance: 50, poolPercent: 82.4);
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = await bootCounter(c);

      await n.recordOpusUsage(count: 1);
      await n.observeOpusUsage(poolPercent: 81.7);
      expect(
        c.read(personalAnlasCounterProvider).opusAllowance,
        closeTo(49.3, 1e-9),
      );
    });

    test('refillOpusAllowanceNow 直接补满到上限', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      final n = await bootCounter(c);
      await n.updateOpusSettings(allowance: 3);
      await n.refillOpusAllowanceNow();
      expect(c.read(personalAnlasCounterProvider).opusAllowance, 50);
    });

    test('额度字段持久化并能回读', () async {
      SharedPreferences.setMockInitialValues({});
      final c1 = ProviderContainer();
      final n1 = await bootCounter(c1);
      await n1.splitOpusAllowance(3);
      await n1.recordOpusUsage(count: 2);
      final saved = c1.read(personalAnlasCounterProvider).opusAllowance;
      c1.dispose();

      // 复用同一份 mock 存储重建容器
      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      await bootCounter(c2);
      final s = c2.read(personalAnlasCounterProvider);
      expect(s.opusShareRatio, closeTo(1 / 3, 0.001));
      expect(s.opusAllowance, closeTo(saved, 0.001));
    });

    test('旧存档（无额度字段）按份额默认值补齐，不炸', () async {
      SharedPreferences.setMockInitialValues({
        'personal_anlas_counter_v1': jsonEncode({
          'subscriptionRemaining': 1234,
          'purchasedRemaining': 56,
          'subscriptionQuota': 5000,
          'resetDay': 7,
        }),
      });
      final c = ProviderContainer();
      addTearDown(c.dispose);
      await bootCounter(c);
      final s = c.read(personalAnlasCounterProvider);
      expect(s.subscriptionRemaining, 1234);
      expect(s.purchasedRemaining, 56);
      expect(s.opusShareRatio, 0.5);
      expect(s.opusAllowance, 50);
      expect(s.pendingOpusGenerations, 0);
      expect(s.lastObservedPoolPercent, isNull);
    });
  });
}
