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

  /// 带可拨动假时钟的容器：测回充节拍结算需要控制观测间隔
  ProviderContainer clockContainer(DateTime Function() clock) {
    return ProviderContainer(
      overrides: [
        personalAnlasCounterProvider.overrideWith(
          () => PersonalAnlasCounter(clock: clock),
        ),
      ],
    );
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
      expect(s.lastObservedAt, isNull);
      expect(s.lastSecondsToNextPercent, 0);
      expect(s.poolCeilingPercent, 100);
    });
  });

  group('PersonalAnlasCounter · 回充时钟结算（timeUntilNextPercent 为主）', () {
    test('朋友消耗掩盖回充：回充仍按分成入账', () async {
      var fakeNow = DateTime(2026, 8, 23, 12, 0, 0);
      SharedPreferences.setMockInitialValues({});
      final c = clockContainer(() => fakeNow);
      addTearDown(c.dispose);
      final n = await bootCounter(c);
      await n.updateOpusSettings(allowance: 10);

      // 基线：池 40%，官方倒计时 60 秒回充 1%
      await n.observeOpusUsage(poolPercent: 40, secondsToNextPercent: 60);
      expect(c.read(personalAnlasCounterProvider).opusAllowance, 10);

      // 2 分钟后：官方节拍回充 2 点，朋友同窗耗掉 2 点 → 池子仍 40；
      // 回充照常入账 2 × 50% = 1
      fakeNow = fakeNow.add(const Duration(minutes: 2));
      await n.observeOpusUsage(poolPercent: 40, secondsToNextPercent: 60);

      final s = c.read(personalAnlasCounterProvider);
      expect(s.opusAllowance, closeTo(11, 1e-9));
      expect(s.lastObservedPoolPercent, 40);
      expect(s.lastSecondsToNextPercent, 60);
    });

    test('回充与我的在途消耗同窗：分成入账 + 按缺口扣', () async {
      var fakeNow = DateTime(2026, 8, 23, 12, 0, 0);
      SharedPreferences.setMockInitialValues({});
      final c = clockContainer(() => fakeNow);
      addTearDown(c.dispose);
      final n = await bootCounter(c);
      await n.updateOpusSettings(allowance: 10);

      await n.observeOpusUsage(poolPercent: 40, secondsToNextPercent: 60);
      await n.recordOpusUsage(count: 2);

      // 2 分钟后：回充 2 点，我耗 1 点 → 池子 41。
      // 回充入账 +1，消耗扣 1，净值不变——两条流分开记
      fakeNow = fakeNow.add(const Duration(minutes: 2));
      await n.observeOpusUsage(poolPercent: 41, secondsToNextPercent: 60);

      final s = c.read(personalAnlasCounterProvider);
      expect(s.opusAllowance, closeTo(10, 1e-9));
      expect(s.pendingOpusGenerations, 0);
    });

    test('NAI 全员 +100% 跳变：按分成入账并抬高池顶与上限', () async {
      var fakeNow = DateTime(2026, 8, 23, 12, 0, 0);
      SharedPreferences.setMockInitialValues({});
      final c = clockContainer(() => fakeNow);
      addTearDown(c.dispose);
      final n = await bootCounter(c);
      await n.updateOpusSettings(allowance: 10);

      // 池 99、不回充（阈值之上倒计时为 0）；30 秒后官方全员 +100%
      await n.observeOpusUsage(poolPercent: 99, secondsToNextPercent: 0);
      fakeNow = fakeNow.add(const Duration(seconds: 30));
      await n.observeOpusUsage(poolPercent: 199, secondsToNextPercent: 0);

      final s = c.read(personalAnlasCounterProvider);
      expect(s.poolCeilingPercent, 199);
      expect(s.opusAllowanceCap, closeTo(99.5, 1e-9));
      // +100 × 50% = +50，未到新上限 99.5
      expect(s.opusAllowance, closeTo(60, 1e-9));

      // 补满按钮现在能补到新上限
      await n.refillOpusAllowanceNow();
      expect(
        c.read(personalAnlasCounterProvider).opusAllowance,
        closeTo(99.5, 1e-9),
      );
    });

    test('回充量以池顶封顶：池顶之上不再计点', () async {
      var fakeNow = DateTime(2026, 8, 23, 12, 0, 0);
      SharedPreferences.setMockInitialValues({});
      final c = clockContainer(() => fakeNow);
      addTearDown(c.dispose);
      final n = await bootCounter(c);
      await n.updateOpusSettings(allowance: 10);

      // 池 99、倒计时 60 秒：池顶 100，回充值最多 1 点
      await n.observeOpusUsage(poolPercent: 99, secondsToNextPercent: 60);
      fakeNow = fakeNow.add(const Duration(minutes: 5));
      await n.observeOpusUsage(poolPercent: 100, secondsToNextPercent: 0);

      // 只入账 1 × 50% = 0.5（按池顶封顶）
      expect(
        c.read(personalAnlasCounterProvider).opusAllowance,
        closeTo(10.5, 1e-9),
      );
    });

    test('离线超 10 分钟：回充时钟不可信，回退纯实测结算', () async {
      var fakeNow = DateTime(2026, 8, 23, 12, 0, 0);
      SharedPreferences.setMockInitialValues({});
      final c = clockContainer(() => fakeNow);
      addTearDown(c.dispose);
      final n = await bootCounter(c);
      await n.updateOpusSettings(allowance: 10);

      await n.observeOpusUsage(poolPercent: 60, secondsToNextPercent: 60);

      // 2 小时后再看：不按倒计时推算，只按实测涨幅 20 × 50% = +10 结算
      fakeNow = fakeNow.add(const Duration(hours: 2));
      await n.observeOpusUsage(poolPercent: 80, secondsToNextPercent: 60);

      expect(
        c.read(personalAnlasCounterProvider).opusAllowance,
        closeTo(20, 1e-9),
      );
    });

    test('回充字段持久化并能回读', () async {
      final fakeNow = DateTime(2026, 8, 23, 12, 0, 0);
      SharedPreferences.setMockInitialValues({});
      final c1 = clockContainer(() => fakeNow);
      final n1 = await bootCounter(c1);
      await n1.updateOpusSettings(allowance: 10);
      await n1.observeOpusUsage(poolPercent: 150, secondsToNextPercent: 300);
      c1.dispose();

      // 复用同一份 mock 存储重建容器（真实时钟）
      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      await bootCounter(c2);
      final s = c2.read(personalAnlasCounterProvider);
      expect(s.poolCeilingPercent, 150);
      expect(s.lastSecondsToNextPercent, 300);
      expect(s.lastObservedAt, fakeNow);
      expect(s.lastObservedPoolPercent, 150);
    });
  });
}
