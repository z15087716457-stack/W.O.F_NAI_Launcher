import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/app_logger.dart';

const Object _unset = Object();

/// 个人点数计数器状态（合租账本）
///
/// 订阅点：每月重置日自动补回 [subscriptionQuota]（用不用完都补回，不累积）。
/// 购买点：手动充值，永不重置。
/// 扣减顺序：先扣订阅、再扣购买；允许扣成负数（UI 红字提示超支）。
/// 只统计本机生图消耗（UI 生成 + 桥接生成），与账户 API 余额无关，
/// 因此不会被合租朋友的消耗污染。
class PersonalAnlasState {
  /// 订阅点剩余
  final int subscriptionRemaining;

  /// 购买点剩余
  final int purchasedRemaining;

  /// 订阅点每月配额（重置时补回到这个值）
  final int subscriptionQuota;

  /// 每月重置日（1-31；0 = 未设置，将从订阅到期时间自动推断）
  final int resetDay;

  /// 上次重置时间（用于判断是否已重置过当前周期）
  final DateTime? lastResetAt;

  /// 我在合租里占的 Opus 额度份额（0-1）。默认 0.5＝两人平分。
  ///
  /// V5 起 Opus 的免费生成额度是一个账号级共享池（服务端以百分比下发），
  /// 合租时所有人共用。份额只影响本地账本的可用上限，不改变服务端行为。
  final double opusShareRatio;

  /// 我剩余的免费额度（百分点，可为负＝已超用自己的份额）
  final double opusAllowance;

  /// 池子涨额度时，我认领的比例（0-1）。默认 0.5＝新增砍一半归我。
  ///
  /// 与 [opusShareRatio] 分开是因为两者用途不同：份额决定我能攒到的上限，
  /// 这个比例决定每次新增怎么分。想「按份额同比例分」就设成与份额相同。
  final double opusRefillShare;

  /// 上次观测到的服务端额度百分比（共享池），null＝尚未观测过。
  ///
  /// 单张耗多少额度、每小时回充多少，官方都没公开，也无从推算，因此一律不估：
  /// 只对比这个值的真实变化——跌了按实测扣，涨了按 [opusRefillShare] 分成入账。
  final double? lastObservedPoolPercent;

  /// 本机生成正在进行中的笔数。
  ///
  /// 大于 0 时，池子的下跌算我的消耗；等于 0 时下跌视为合租朋友所为，不记账。
  final int pendingOpusGenerations;

  const PersonalAnlasState({
    required this.subscriptionRemaining,
    required this.purchasedRemaining,
    required this.subscriptionQuota,
    required this.resetDay,
    this.lastResetAt,
    this.opusShareRatio = 0.5,
    this.opusAllowance = 50,
    this.opusRefillShare = 0.5,
    this.lastObservedPoolPercent,
    this.pendingOpusGenerations = 0,
  });

  factory PersonalAnlasState.initial() => const PersonalAnlasState(
        subscriptionRemaining: 5000,
        purchasedRemaining: 0,
        subscriptionQuota: 5000,
        resetDay: 0,
      );

  int get totalRemaining => subscriptionRemaining + purchasedRemaining;

  bool get isOverdrawn => subscriptionRemaining < 0 || purchasedRemaining < 0;

  /// 我的额度上限（百分点）＝总池 × 份额
  double get opusAllowanceCap => (100 * opusShareRatio).clamp(0, 100).toDouble();

  /// 我的份额是否已用尽（不足 0.01 个百分点视为耗尽，避免浮点残渣）
  bool get isOpusAllowanceExhausted => opusAllowance < 0.01;

  PersonalAnlasState copyWith({
    int? subscriptionRemaining,
    int? purchasedRemaining,
    int? subscriptionQuota,
    int? resetDay,
    Object? lastResetAt = _unset,
    double? opusShareRatio,
    double? opusAllowance,
    double? opusRefillShare,
    Object? lastObservedPoolPercent = _unset,
    int? pendingOpusGenerations,
  }) {
    return PersonalAnlasState(
      subscriptionRemaining:
          subscriptionRemaining ?? this.subscriptionRemaining,
      purchasedRemaining: purchasedRemaining ?? this.purchasedRemaining,
      subscriptionQuota: subscriptionQuota ?? this.subscriptionQuota,
      resetDay: resetDay ?? this.resetDay,
      lastResetAt: identical(lastResetAt, _unset)
          ? this.lastResetAt
          : lastResetAt as DateTime?,
      opusShareRatio: opusShareRatio ?? this.opusShareRatio,
      opusAllowance: opusAllowance ?? this.opusAllowance,
      opusRefillShare: opusRefillShare ?? this.opusRefillShare,
      lastObservedPoolPercent: identical(lastObservedPoolPercent, _unset)
          ? this.lastObservedPoolPercent
          : lastObservedPoolPercent as double?,
      pendingOpusGenerations:
          pendingOpusGenerations ?? this.pendingOpusGenerations,
    );
  }

  Map<String, dynamic> toJson() => {
        'subscriptionRemaining': subscriptionRemaining,
        'purchasedRemaining': purchasedRemaining,
        'subscriptionQuota': subscriptionQuota,
        'resetDay': resetDay,
        'lastResetAt': lastResetAt?.toIso8601String(),
        'opusShareRatio': opusShareRatio,
        'opusAllowance': opusAllowance,
        'opusRefillShare': opusRefillShare,
        'lastObservedPoolPercent': lastObservedPoolPercent,
      };

  /// 反序列化。缺失的额度字段回退到默认值（旧存档平滑升级）。
  factory PersonalAnlasState.fromJson(Map<String, dynamic> json) {
    int readInt(String key, int fallback) {
      final v = json[key];
      return v is num ? v.toInt() : fallback;
    }

    double readDouble(String key, double fallback) {
      final v = json[key];
      return v is num ? v.toDouble() : fallback;
    }

    DateTime? readDate(String key) {
      final v = json[key];
      return v is String ? DateTime.tryParse(v) : null;
    }

    final shareRatio = readDouble('opusShareRatio', 0.5).clamp(0.0, 1.0);

    return PersonalAnlasState(
      subscriptionRemaining: readInt('subscriptionRemaining', 5000),
      purchasedRemaining: readInt('purchasedRemaining', 0),
      subscriptionQuota: readInt('subscriptionQuota', 5000),
      resetDay: readInt('resetDay', 0),
      lastResetAt: readDate('lastResetAt'),
      opusShareRatio: shareRatio.toDouble(),
      opusAllowance: readDouble('opusAllowance', 100 * shareRatio),
      opusRefillShare: readDouble('opusRefillShare', 0.5).clamp(0.0, 1.0),
      lastObservedPoolPercent: json['lastObservedPoolPercent'] is num
          ? (json['lastObservedPoolPercent'] as num).toDouble()
          : null,
      // pendingOpusGenerations 是进程内瞬态，不持久化：重启后没有在途生成
    );
  }
}

/// 个人点数计数器
///
/// 手写 NotifierProvider（不走 riverpod codegen，避免 build_runner）。
/// SharedPreferences 持久化，重启不丢。
class PersonalAnlasCounter extends Notifier<PersonalAnlasState> {
  static const String _storageKey = 'personal_anlas_counter_v1';
  static const String _logTag = 'PersonalAnlas';

  SharedPreferences? _prefs;
  Future<void>? _ready;

  @override
  PersonalAnlasState build() {
    _ready = _load();
    return PersonalAnlasState.initial();
  }

  Future<void> _load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs!.getString(_storageKey);
      if (raw != null) {
        state = PersonalAnlasState.fromJson(
          jsonDecode(raw) as Map<String, dynamic>,
        );
      }
      _applyResetIfDue();
    } catch (e) {
      AppLogger.e('个人点数状态加载失败: $e', _logTag);
    }
  }

  Future<void> _persist() async {
    try {
      await _prefs?.setString(_storageKey, jsonEncode(state.toJson()));
    } catch (e) {
      AppLogger.e('个人点数状态保存失败: $e', _logTag);
    }
  }

  static int _daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// 最近一个已到达的重置边界（日期精度）
  DateTime? _latestBoundary(DateTime now) {
    final d = state.resetDay;
    if (d < 1 || d > 31) return null;
    final thisMonthDay = math.min(d, _daysInMonth(now.year, now.month));
    var boundary = DateTime(now.year, now.month, thisMonthDay);
    if (now.isBefore(boundary)) {
      final prev = DateTime(now.year, now.month - 1, 1);
      final prevDay = math.min(d, _daysInMonth(prev.year, prev.month));
      boundary = DateTime(prev.year, prev.month, prevDay);
    }
    return boundary;
  }

  /// 下一个重置日（UI 展示用）
  DateTime? nextResetDate() {
    final d = state.resetDay;
    if (d < 1 || d > 31) return null;
    final now = DateTime.now();
    final thisMonthDay = math.min(d, _daysInMonth(now.year, now.month));
    final candidate = DateTime(now.year, now.month, thisMonthDay);
    if (now.isBefore(candidate)) return candidate;
    final next = DateTime(now.year, now.month + 1, 1);
    final nextDay = math.min(d, _daysInMonth(next.year, next.month));
    return DateTime(next.year, next.month, nextDay);
  }

  /// 到达重置周期就把订阅点补回配额（补回制，不累积）
  void _applyResetIfDue() {
    final now = DateTime.now();
    final boundary = _latestBoundary(now);
    if (boundary == null) return;
    final last = state.lastResetAt;
    if (last == null) {
      // 首次运行：以最近边界为基线，不触发重置（初始剩余由用户校准）
      state = state.copyWith(lastResetAt: boundary);
      unawaited(_persist());
      return;
    }
    if (!last.isBefore(boundary)) return; // 本周期已重置
    state = state.copyWith(
      subscriptionRemaining: state.subscriptionQuota,
      lastResetAt: boundary,
    );
    unawaited(_persist());
    AppLogger.i(
      '订阅点已按月重置为 ${state.subscriptionQuota}（购买点不变）',
      _logTag,
    );
  }

  /// 记录一次本机生图消耗：先扣订阅、再扣购买
  Future<void> recordCost(int cost) async {
    if (cost <= 0) return;
    await _ready;
    _applyResetIfDue();
    var sub = state.subscriptionRemaining;
    var pur = state.purchasedRemaining;
    final fromSub = cost <= sub ? cost : (sub > 0 ? sub : 0);
    sub -= fromSub;
    pur -= cost - fromSub;
    state = state.copyWith(
      subscriptionRemaining: sub,
      purchasedRemaining: pur,
    );
    await _persist();
    AppLogger.i(
      '个人点数扣减 $cost（订阅剩 $sub，购买剩 $pur）',
      _logTag,
    );
  }

  /// 手动充值购买点（给朋友钱冲点时自己加）
  Future<void> addPurchased(int amount) async {
    if (amount == 0) return;
    await _ready;
    state = state.copyWith(
      purchasedRemaining: state.purchasedRemaining + amount,
    );
    await _persist();
    AppLogger.i(
      '购买点充值 $amount（剩 ${state.purchasedRemaining}）',
      _logTag,
    );
  }

  /// 手动校准/设置。传入的字段才会被修改。
  /// 修改重置日会重建重置基线（不会因此吞掉已有剩余）。
  Future<void> updateSettings({
    int? subscriptionRemaining,
    int? purchasedRemaining,
    int? subscriptionQuota,
    int? resetDay,
  }) async {
    await _ready;
    final resetDayChanged = resetDay != null && resetDay != state.resetDay;
    state = state.copyWith(
      subscriptionRemaining: subscriptionRemaining,
      purchasedRemaining: purchasedRemaining,
      subscriptionQuota: subscriptionQuota,
      resetDay: resetDay,
      lastResetAt: resetDayChanged ? null : _unset,
    );
    await _persist();
    if (resetDayChanged) _applyResetIfDue();
  }

  /// 立即把订阅点补回配额（手动重置）
  Future<void> resetSubscriptionNow() async {
    await _ready;
    state = state.copyWith(
      subscriptionRemaining: state.subscriptionQuota,
      lastResetAt: DateTime.now(),
    );
    await _persist();
    AppLogger.i('订阅点已手动补满 ${state.subscriptionQuota}', _logTag);
  }

  /// 标记本机发起了 [count] 笔走免费额度的生成。
  ///
  /// 单张消耗多少额度官方未公开，这里不做任何估算：只把这些生成登记为"在途"，
  /// 等 [observeOpusUsage] 观测到服务端池子的真实跌幅时再落账。
  ///
  /// 只在生成确实走了 Opus 免费额度（Anlas 消耗为 0）时调用；
  /// 花 Anlas 的生成走 [recordCost]，两本账互不重叠。
  Future<void> recordOpusUsage({int count = 1}) async {
    if (count <= 0) return;
    await _ready;
    state = state.copyWith(
      pendingOpusGenerations: state.pendingOpusGenerations + count,
    );
    AppLogger.i('本机免费生成 $count 笔在途，等服务端额度回报后落账', _logTag);
  }

  /// 观测服务端额度，按池子的真实变化结算我的份额。
  ///
  /// 服务端 `percent` 是全账号共享池，合租时也含朋友的消耗，所以不能直接覆盖
  /// 本地份额。跌幅只认**有本机生成在途时**的那部分（我花的，按实测数值扣，
  /// 不猜单价）；涨幅按 [PersonalAnlasState.opusRefillShare] 分成入账。
  ///
  /// 回充速度、单张单价都是黑盒，一概不推算——只跟着池子的实际数字走。
  Future<void> observeOpusUsage({double? poolPercent}) async {
    await _ready;
    if (poolPercent == null) return;
    await _settleObservedPool(poolPercent);
  }

  /// 用服务端池子的真实变化结算份额：跌了扣我的在途消耗，涨了按分成入账。
  Future<void> _settleObservedPool(double poolPercent) async {
    final previous = state.lastObservedPoolPercent;
    final pending = state.pendingOpusGenerations;

    // 首次观测只记基线，不追认历史变化
    if (previous == null) {
      state = state.copyWith(lastObservedPoolPercent: poolPercent);
      await _persist();
      return;
    }

    final delta = poolPercent - previous;

    // 池子上涨（回充/月度重置）：按分成砍一部分给我，封顶在份额上限
    if (delta > 0) {
      final cap = state.opusAllowanceCap;
      final gained = delta * state.opusRefillShare;
      final next = math.min(state.opusAllowance + gained, cap);
      state = state.copyWith(
        opusAllowance: math.max(next, state.opusAllowance),
        lastObservedPoolPercent: poolPercent,
      );
      await _persist();
      AppLogger.i(
        '账号额度 +${delta.toStringAsFixed(2)}%，按分成入账 '
        '${gained.toStringAsFixed(2)}%（我的份额剩 '
        '${state.opusAllowance.toStringAsFixed(2)}%）',
        _logTag,
      );
      return;
    }

    final dropped = -delta;
    if (dropped <= 0 || pending <= 0) {
      state = state.copyWith(
        lastObservedPoolPercent: poolPercent,
        // 池子没跌却有在途笔数：生成没走额度或已被别的观测结清，清掉避免挂死
        pendingOpusGenerations: dropped <= 0 ? 0 : pending,
      );
      await _persist();
      return;
    }

    state = state.copyWith(
      opusAllowance: state.opusAllowance - dropped,
      lastObservedPoolPercent: poolPercent,
      pendingOpusGenerations: 0,
    );
    await _persist();
    AppLogger.i(
      '免费额度按服务端实测扣减 ${dropped.toStringAsFixed(2)}%'
      '（$pending 笔在途，我的份额剩 ${state.opusAllowance.toStringAsFixed(2)}%）',
      _logTag,
    );
  }

  /// 按合租人数平分额度：份额与新增分成都设为 1/人数，并把余额按新上限裁剪。
  Future<void> splitOpusAllowance(int peopleCount) async {
    if (peopleCount < 1) return;
    await _ready;
    final ratio = 1 / peopleCount;
    state = state.copyWith(
      opusShareRatio: ratio,
      opusRefillShare: ratio,
      opusAllowance: math.min(state.opusAllowance, 100 * ratio),
    );
    await _persist();
    AppLogger.i(
      '额度按 $peopleCount 人平分：每人 ${(ratio * 100).toStringAsFixed(1)}%',
      _logTag,
    );
  }

  /// 手动调整额度设置。传入的字段才会被修改。
  Future<void> updateOpusSettings({
    double? shareRatio,
    double? allowance,
    double? refillShare,
  }) async {
    await _ready;
    state = state.copyWith(
      opusShareRatio: shareRatio?.clamp(0.0, 1.0).toDouble(),
      opusRefillShare: refillShare?.clamp(0.0, 1.0).toDouble(),
      opusAllowance: allowance,
    );
    await _persist();
  }

  /// 立即把额度补满到我的份额上限
  Future<void> refillOpusAllowanceNow() async {
    await _ready;
    state = state.copyWith(opusAllowance: state.opusAllowanceCap);
    await _persist();
    AppLogger.i(
      '免费额度已补满至 ${state.opusAllowanceCap.toStringAsFixed(1)}%',
      _logTag,
    );
  }

  /// 观测订阅信息：重置日未设置时，从订阅到期时间推断每月重置日
  Future<void> observeSubscription(int? expiresAtSeconds) async {
    if (expiresAtSeconds == null) return;
    await _ready;
    if (state.resetDay != 0) return; // 已设置（自动推断过或手动改过）
    final dt = DateTime.fromMillisecondsSinceEpoch(
      expiresAtSeconds * 1000,
      isUtc: true,
    ).toLocal();
    if (dt.day < 1 || dt.day > 31) return;
    state = state.copyWith(resetDay: dt.day);
    await _persist();
    _applyResetIfDue();
    AppLogger.i('从订阅到期时间推断重置日为每月 ${dt.day} 号', _logTag);
  }
}

/// 个人点数计数器 Provider（常驻，不随页面销毁）
final personalAnlasCounterProvider =
    NotifierProvider<PersonalAnlasCounter, PersonalAnlasState>(
  PersonalAnlasCounter.new,
);
