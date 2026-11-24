import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/utils/app_logger.dart';
import '../ui/channel/channel_contract.dart';

/// One seed per provider scope/process, independent of page mount/unmount.
final canvasChannelSeedProvider = Provider<int>(
  (ref) => Random().nextInt(1 << 31),
);

final canvasChannelNotifierProvider =
    NotifierProvider<CanvasChannelNotifier, ChannelSettings>(
      CanvasChannelNotifier.new,
    );

class CanvasChannelNotifier extends Notifier<ChannelSettings> {
  Future<void> _writes = Future.value();

  @override
  ChannelSettings build() {
    final seed = ref.read(canvasChannelSeedProvider);
    try {
      final raw = ref
          .read(localStorageServiceProvider)
          .getSetting<Object>(StorageKeys.canvasChannelPreferences);
      final value = raw is String ? jsonDecode(raw) : raw;
      if (value is! Map) return ChannelSettings(seed: seed);
      final storedVersion = value['version'];
      final isLegacy = storedVersion is! int || storedVersion < _version;

      final ChannelTheme fixed;
      final Set<ChannelTheme> pool;
      final ChannelLevel level;

      if (isLegacy) {
        // v1 / v2 旧矢量主题平滑迁移到 v3 新 5 套字符艺术主题
        fixed = _migrateLegacyTheme(value['fixed']);
        pool = ChannelSettings.allThemes;
        final storedLevel = value['level'];
        // 若用户显式调过「淡」则保留；旧默认「标准」或缺失值平滑升级为新默认「浓」
        level = storedLevel == ChannelLevel.soft.name
            ? ChannelLevel.soft
            : ChannelLevel.strong;
      } else {
        fixed = _parseTheme(value['fixed']) ?? ChannelTheme.pelagic;
        final parsedPool = <ChannelTheme>{};
        if (value['pool'] is List) {
          for (final item in value['pool'] as List) {
            final parsed = _parseTheme(item);
            if (parsed != null) parsedPool.add(parsed);
          }
        }
        pool = Set.unmodifiable(
          parsedPool.length >= 2 ? parsedPool : ChannelSettings.allThemes,
        );
        level = _named(
          ChannelLevel.values,
          value['level'],
          ChannelLevel.strong,
        );
      }

      final rawSide = value['sideTransparency'];
      final sideTransparency = rawSide is num && rawSide.isFinite
          ? (rawSide.toDouble().clamp(0.0, 1.0) * 100).round() / 100.0
          : ChannelSettings.defaultSideTransparency;

      return ChannelSettings(
        mode: _named(ChannelMode.values, value['mode'], ChannelMode.random),
        fixed: fixed,
        pool: pool,
        level: level,
        sideTransparency: sideTransparency,
        ruler: value['ruler'] is bool ? value['ruler'] as bool : true,
        motion: value['motion'] is bool ? value['motion'] as bool : true,
        seed: seed,
      );
    } catch (error, stack) {
      AppLogger.e(
        'Failed to read canvas channel preferences',
        error,
        stack,
        'CanvasChannel',
      );
      return ChannelSettings(seed: seed);
    }
  }

  /// State changes synchronously; serial writes preserve the latest UI choice.
  /// The transient seed is deliberately absent from the stored payload.
  Future<void> set(ChannelSettings value) {
    final next = value.copyWith(
      pool: Set.unmodifiable(
        value.pool.length >= 2 ? value.pool : ChannelSettings.allThemes,
      ),
      sideTransparency:
          (value.sideTransparency.clamp(0.0, 1.0) * 100).round() / 100.0,
    );
    state = next;
    final payload = jsonEncode({
      'version': _version,
      'mode': next.mode.name,
      'fixed': next.fixed.name,
      'pool': [
        for (final theme in ChannelTheme.values)
          if (next.pool.contains(theme)) theme.name,
      ],
      'level': next.level.name,
      'sideTransparency': next.sideTransparency,
      'ruler': next.ruler,
      'motion': next.motion,
    });
    final storage = ref.read(localStorageServiceProvider);
    return _writes = _writes.then((_) async {
      try {
        await storage.setSetting(StorageKeys.canvasChannelPreferences, payload);
      } catch (error, stack) {
        AppLogger.e(
          'Failed to save canvas channel preferences',
          error,
          stack,
          'CanvasChannel',
        );
      }
    });
  }
}

const _version = 3;

ChannelTheme? _parseTheme(Object? raw) => switch (raw) {
  'pelagic' => ChannelTheme.pelagic,
  'nimbus' => ChannelTheme.nimbus,
  'cumulus' => ChannelTheme.cumulus,
  'aurora' || 'singularity' => ChannelTheme.aurora,
  'strata' => ChannelTheme.strata,
  _ => null,
};

ChannelTheme _migrateLegacyTheme(Object? raw) => switch (raw) {
  'pelagic' || 'abyss' || 'wave' => ChannelTheme.pelagic,
  'nimbus' || 'herb' || 'score' => ChannelTheme.nimbus,
  'cumulus' || 'circuit' || 'arcade' || 'caliber' || 'metro' =>
    ChannelTheme.cumulus,
  'aurora' || 'singularity' || 'stars' || 'luna' => ChannelTheme.aurora,
  'strata' => ChannelTheme.strata,
  _ => ChannelTheme.pelagic,
};

T _named<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.where((value) => value.name == name).firstOrNull ?? fallback;
