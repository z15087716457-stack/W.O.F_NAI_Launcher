import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// FEAT-23 内置一体标题栏：命中区上报服务。
///
/// 把自绘标题栏的几何参数（栏高 + 右侧按钮保留宽，均为逻辑像素）
/// 经 `com.nailauncher/titlebar` MethodChannel 推给 runner 侧
/// `titlebar_region`，由原生 `WM_NCHITTEST` 对命中区返回
/// `HTCAPTION`，恢复原生拖拽 / 双击最大化 / Aero Snap。
///
/// 仅 Windows 生效；其他平台与测试环境（通道未注册）静默降级。
class TitleBarRegionService {
  TitleBarRegionService._();

  static const MethodChannel _channel =
      MethodChannel('com.nailauncher/titlebar');

  /// 活跃标题栏实例计数。
  ///
  /// `MaterialApp.router` 的 builder 在 provider 就绪时会重建整棵子树，
  /// `_TitleBar` 会被「mount → mount → unmount」走一遍，实际时序里
  /// 旧实例的 dispose 晚于新实例的 initState，若 dispose 里直接 clear
  /// 会把新实例刚上报的命中区抹掉。改用引用计数：initState `retain()`、
  /// dispose `release()`，计数归零才真正下发 clear。
  static int _activeBars = 0;

  /// 平台通道是否可用（Windows 桌面端才有对应原生实现）。
  static bool get isSupported => !kIsWeb && Platform.isWindows;

  /// 标题栏实例挂载时调用：计数 +1。
  static void retain() {
    _activeBars++;
  }

  /// 标题栏实例卸载时调用：计数 -1；归零时清除原生命中区。
  static void release() {
    if (_activeBars > 0) _activeBars--;
    if (_activeBars == 0) {
      unawaited(_invokeClear());
    }
  }

  /// 上报标题栏命中区。
  ///
  /// [barHeight] 自绘标题栏高度（逻辑像素）。
  /// [reservedRight] 右侧不响应拖拽的保留宽（最小化/最大化/关闭
  /// 按钮区，逻辑像素）；该区内保持 `HTCLIENT`，按钮点击走
  /// Flutter 手势路径。
  static Future<void> setRegion({
    required double barHeight,
    required double reservedRight,
  }) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('setRegion', <String, double>{
        'barHeight': barHeight,
        'reservedRight': reservedRight,
      });
    } on MissingPluginException {
      // 测试环境 / 原生侧未注册通道时静默降级。
    } on PlatformException {
      // 原生侧拒绝时静默降级，不影响窗口行为。
    }
  }

  /// 清除命中区（标题栏卸载或禁用时恢复默认命中）。
  ///
  /// 外部调用走 [release] 计数路径；真正卸载（计数归零）才下发。
  static Future<void> _invokeClear() async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>('clear');
    } on MissingPluginException {
      // 同上，静默降级。
    } on PlatformException {
      // 同上，静默降级。
    }
  }
}
