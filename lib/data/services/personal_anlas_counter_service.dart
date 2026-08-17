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

  const PersonalAnlasState({
    required this.subscriptionRemaining,
    required this.purchasedRemaining,
    required this.subscriptionQuota,
    required this.resetDay,
    this.lastResetAt,
  });

  factory PersonalAnlasState.initial() => const PersonalAnlasState(
        subscriptionRemaining: 5000,
        purchasedRemaining: 0,
        subscriptionQuota: 5000,
        resetDay: 0,
      );

  int get totalRemaining => subscriptionRemaining + purchasedRemaining;

  bool get isOverdrawn => subscriptionRemaining < 0 || purchasedRemaining < 0;

  PersonalAnlasState copyWith({
    int? subscriptionRemaining,
    int? purchasedRemaining,
    int? subscriptionQuota,
    int? resetDay,
    Object? lastResetAt = _unset,
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
    );
  }

  Map<String, dynamic> toJson() => {
        'subscriptionRemaining': subscriptionRemaining,
        'purchasedRemaining': purchasedRemaining,
        'subscriptionQuota': subscriptionQuota,
        'resetDay': resetDay,
        'lastResetAt': lastResetAt?.toIso8601String(),
      };

  factory PersonalAnlasState.fromJson(Map<String, dynamic> json) {
    int readInt(String key, int fallback) {
      final v = json[key];
      return v is num ? v.toInt() : fallback;
    }

    return PersonalAnlasState(
      subscriptionRemaining: readInt('subscriptionRemaining', 5000),
      purchasedRemaining: readInt('purchasedRemaining', 0),
      subscriptionQuota: readInt('subscriptionQuota', 5000),
      resetDay: readInt('resetDay', 0),
      lastResetAt: json['lastResetAt'] is String
          ? DateTime.tryParse(json['lastResetAt'] as String)
          : null,
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
