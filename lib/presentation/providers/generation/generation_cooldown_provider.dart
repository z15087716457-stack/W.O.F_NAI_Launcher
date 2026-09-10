import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/utils/app_logger.dart';
import '../share_image_settings_provider.dart';

class GenerationCooldownState {
  const GenerationCooldownState({this.availableAt, this.remainingSeconds = 0});

  final DateTime? availableAt;
  final int remainingSeconds;

  bool get isActive => remainingSeconds > 0;
}

final generationCooldownClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// 冷却抖动的随机源，返回 [0, 1)。独立成 provider 便于测试注入定值。
final generationCooldownJitterRandomProvider = Provider<double Function()>(
  (ref) => Random().nextDouble,
);

final generationCooldownProvider =
    NotifierProvider<GenerationCooldownNotifier, GenerationCooldownState>(
      GenerationCooldownNotifier.new,
    );

class GenerationCooldownNotifier extends Notifier<GenerationCooldownState> {
  static const _tickInterval = Duration(milliseconds: 250);

  Timer? _ticker;
  DateTime? _lastGenerationStartedAt;

  /// 本次冷却已抽取的实际间隔（毫秒）。
  ///
  /// 每次开始生图时按「基础间隔 ± 抖动百分比」重新抽取并锁定，
  /// 保证倒计时展示与真实解锁时刻一致；跨重启恢复时该值丢失，
  /// 回退按固定基础间隔计算（仍在抖动取值范围内，无需持久化）。
  int? _activeIntervalMs;

  LocalStorageService get _storage => ref.read(localStorageServiceProvider);
  DateTime get _now => ref.read(generationCooldownClockProvider)();
  int get _intervalSeconds =>
      ref.read(shareImageSettingsProvider).effectiveGenerationIntervalSeconds;

  @override
  GenerationCooldownState build() {
    final storedTimestamp = _storage.getSetting<int>(
      StorageKeys.protectionLastGenerationStartedAt,
    );
    _lastGenerationStartedAt = storedTimestamp == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(storedTimestamp, isUtc: true);
    if (_lastGenerationStartedAt?.isAfter(_now) ?? false) {
      _lastGenerationStartedAt = _now;
    }

    ref.listen<ShareImageSettings>(shareImageSettingsProvider, (_, __) {
      _refresh();
    });
    ref.onDispose(() => _ticker?.cancel());

    final initialState = _calculateState();
    if (initialState.isActive) {
      _startTicker();
    }
    return initialState;
  }

  bool tryStartGeneration() {
    _refresh();
    if (state.isActive) {
      return false;
    }

    if (_intervalSeconds <= 0) {
      return true;
    }

    _lastGenerationStartedAt = _now;
    _activeIntervalMs = _drawIntervalMs();
    _refresh();
    unawaited(_persistLastGenerationStartedAt());
    return true;
  }

  /// 在「基础间隔 ± 抖动百分比」内均匀抽取本次冷却的实际间隔。
  ///
  /// 抖动为 0 时返回固定基础间隔。抖动上限 50%（设置层钳制）保证
  /// 实际间隔恒为正且不低于基础间隔的一半。
  int _drawIntervalMs() {
    final baseMs = _intervalSeconds * 1000;
    final jitterPercent = ref
        .read(shareImageSettingsProvider)
        .effectiveGenerationIntervalJitterPercent;
    if (jitterPercent <= 0) {
      return baseMs;
    }

    final unit = ref.read(generationCooldownJitterRandomProvider)();
    final factor = 1 + (unit * 2 - 1) * jitterPercent / 100;
    return (baseMs * factor).round();
  }

  Future<void> _persistLastGenerationStartedAt() async {
    try {
      await _storage.setSetting(
        StorageKeys.protectionLastGenerationStartedAt,
        _lastGenerationStartedAt!.toUtc().millisecondsSinceEpoch,
      );
    } catch (error) {
      AppLogger.w(
        'Failed to persist generation cooldown timestamp: $error',
        'GenerationCooldown',
      );
    }
  }

  Future<void> waitUntilAvailable() async {
    while (true) {
      _refresh();
      if (!state.isActive) {
        return;
      }
      await Future<void>.delayed(_tickInterval);
    }
  }

  GenerationCooldownState _calculateState() {
    final intervalSeconds = _intervalSeconds;
    final startedAt = _lastGenerationStartedAt;
    if (intervalSeconds <= 0 || startedAt == null) {
      return const GenerationCooldownState();
    }

    final intervalMs = _activeIntervalMs ?? intervalSeconds * 1000;
    final availableAt = startedAt.add(Duration(milliseconds: intervalMs));
    final remainingMilliseconds = availableAt.difference(_now).inMilliseconds;
    if (remainingMilliseconds <= 0) {
      return const GenerationCooldownState();
    }

    return GenerationCooldownState(
      availableAt: availableAt,
      remainingSeconds: (remainingMilliseconds / 1000).ceil(),
    );
  }

  void _refresh() {
    final nextState = _calculateState();
    if (state.availableAt != nextState.availableAt ||
        state.remainingSeconds != nextState.remainingSeconds) {
      state = nextState;
    }

    if (nextState.isActive) {
      _startTicker();
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  void _startTicker() {
    if (_ticker?.isActive ?? false) {
      return;
    }
    _ticker = Timer.periodic(_tickInterval, (_) => _refresh());
  }
}
