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

/// Kept by the application scope, not a route or persisted preferences. A new
/// launch gets a new notice; remounting the canvas never rearms this one.
final canvasChannelEntryNoticeProvider = Provider(
  (ref) => CanvasChannelEntryNotice(),
);

class CanvasChannelEntryNotice {
  bool _shown = false;

  bool claim() {
    if (_shown) return false;
    _shown = true;
    return true;
  }
}

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
      final pool = {
        for (final theme in ChannelTheme.values)
          if (value['pool'] is List &&
              (value['pool'] as List).contains(theme.name))
            theme,
        // v1 只认识前六个主题：旧随机池里没有后来加的主题，并入后新主题才会出现
        if (value['version'] == 1) ..._addedAfterV1,
      };
      return ChannelSettings(
        mode: _named(ChannelMode.values, value['mode'], ChannelMode.random),
        fixed: _named(ChannelTheme.values, value['fixed'], ChannelTheme.stars),
        pool: Set.unmodifiable(
          pool.length >= 2 ? pool : ChannelSettings.allThemes,
        ),
        level: _named(
          ChannelLevel.values,
          value['level'],
          ChannelLevel.standard,
        ),
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

const _version = 2;

/// 存储 v1 之后新增的主题。
const _addedAfterV1 = [
  ChannelTheme.caliber,
  ChannelTheme.strata,
  ChannelTheme.metro,
  ChannelTheme.score,
  ChannelTheme.luna,
];

T _named<T extends Enum>(List<T> values, Object? name, T fallback) =>
    values.where((value) => value.name == name).firstOrNull ?? fallback;
