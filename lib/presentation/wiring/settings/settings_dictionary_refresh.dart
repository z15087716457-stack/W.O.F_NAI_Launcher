import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/app_visibility.dart';
import 'settings_caches.dart';
import 'settings_inventory.dart';

/// 设置「词库」页的统计什么时候重算。
///
/// - 随包的只读库（标签目录、Wiki、共现）运行中不会变：「自动刷新」开着时每次进页查一次，
///   停在页上不再定时重查；关着时和以前一样，只在第一次显示时查，之后进页都用那次的结果。
///   检查更新、下载新库完成后由 `SettingsDictionaryUpdater` 自己让它重算。
/// - 会变的缓存统计在「自动刷新」开着时每 10 秒重算一次；窗口看不见时暂停，
///   重新看得见时先补一次，再按间隔继续。
class SettingsDictionaryRefresh {
  SettingsDictionaryRefresh._(this._onOpen, this._onTick) {
    _visibility.addListener(_visibilityChanged);
  }

  /// 接到设置页的三份数据上：进页重查只读库，定时只重算缓存统计。
  factory SettingsDictionaryRefresh.forSettings(WidgetRef ref) =>
      SettingsDictionaryRefresh._(
        () {
          // 还没查过（页面读它时就会查）或者正在查（刚离开又回来、更新刚完成），就用那一轮。
          if (ref.exists(settingsDictionaryDataProvider) &&
              !ref.read(settingsDictionaryDataProvider).isLoading) {
            ref.invalidate(settingsDictionaryDataProvider);
          }
        },
        () {
          ref.invalidate(settingsCacheStatsProvider);
          ref.invalidate(settingsCacheFootprintProvider);
        },
      );

  /// 「已更新」那行按秒显示，间隔拉长就看得出来，所以保持原来的 10 秒。
  static const _interval = Duration(seconds: 10);

  final void Function() _onOpen;
  final void Function() _onTick;
  final _visibility = AppVisibility.instance;
  bool _open = false;
  bool _autoRefresh = false;
  bool _disposed = false;
  Timer? _timer;

  bool get _wanted => _open && _autoRefresh && _visibility.isVisible;

  /// 设置页每次构建时调用：[open] 是现在显示的是不是「词库」页，[autoRefresh] 是「自动刷新」开关。
  void update({required bool open, required bool autoRefresh}) {
    if (_disposed) return;
    final entered = open && !_open;
    _open = open;
    _autoRefresh = autoRefresh;
    if (entered && autoRefresh) _onOpen();
    _sync();
  }

  void _visibilityChanged() {
    if (_disposed) return;
    if (_timer == null && _wanted) _onTick();
    _sync();
  }

  void _sync() {
    if (_wanted) {
      _timer ??= Timer.periodic(_interval, (_) => _onTick());
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  void dispose() {
    _disposed = true;
    _visibility.removeListener(_visibilityChanged);
    _timer?.cancel();
    _timer = null;
  }
}
