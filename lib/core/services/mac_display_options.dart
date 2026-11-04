import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 系统「辅助功能 → 显示」里和动画、透明有关的两项（目前只接了 macOS）。
@immutable
class SystemDisplayOptions {
  const SystemDisplayOptions({
    this.reduceMotion = false,
    this.reduceTransparency = false,
  });

  /// 减少动态效果。
  final bool reduceMotion;

  /// 降低透明度：磨砂改成实底。
  final bool reduceTransparency;

  static SystemDisplayOptions _fromNative(Object? raw) {
    if (raw is! Map) return const SystemDisplayOptions();
    return SystemDisplayOptions(
      reduceMotion: raw['reduceMotion'] == true,
      reduceTransparency: raw['reduceTransparency'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is SystemDisplayOptions &&
      other.reduceMotion == reduceMotion &&
      other.reduceTransparency == reduceTransparency;

  @override
  int get hashCode => Object.hash(reduceMotion, reduceTransparency);

  @override
  String toString() =>
      'SystemDisplayOptions(reduceMotion: $reduceMotion, '
      'reduceTransparency: $reduceTransparency)';
}

/// macOS 的「减少动态效果」「降低透明度」。
///
/// Flutter 的 macOS 引擎不读这两项（Windows 引擎会把系统的“动画效果”报成
/// `MediaQuery.disableAnimations`），所以由 Runner 读 NSWorkspace 的
/// `accessibilityDisplayShouldReduceMotion` / `ReduceTransparency`，监听变化后经
/// [channel] 告诉 Dart（`macos/Runner/MainFlutterWindow.swift`）。其他平台一直是默认值。
class MacDisplayOptions extends ValueNotifier<SystemDisplayOptions> {
  /// [platform] 默认取 [defaultTargetPlatform]；组件测试默认不是 macOS，不碰通道。
  MacDisplayOptions({TargetPlatform? platform})
    : _platform = platform,
      super(const SystemDisplayOptions());

  /// 应用里用的那一份；根部的 `SystemDisplayOptionsScope` 接上它。
  static final MacDisplayOptions instance = MacDisplayOptions();

  /// Dart 调 `getDisplayOptions` 取当前值；系统设置变了原生调 `displayOptionsChanged`。
  /// 两者的参数都是 `{reduceMotion: bool, reduceTransparency: bool}`。
  static const channel = MethodChannel('com.nailauncher/accessibility');

  final TargetPlatform? _platform;
  bool _attached = false;

  bool get _mac => (_platform ?? defaultTargetPlatform) == TargetPlatform.macOS;

  /// 只在 macOS 上接通道；重复调用没有副作用。
  void attach() {
    if (_attached || !_mac) return;
    _attached = true;
    channel.setMethodCallHandler((call) async {
      if (call.method == 'displayOptionsChanged') {
        value = SystemDisplayOptions._fromNative(call.arguments);
      }
      return null;
    });
    unawaited(_query());
  }

  /// 测试用：断开通道，回到默认值。
  @visibleForTesting
  void detach() {
    if (_attached) channel.setMethodCallHandler(null);
    _attached = false;
    value = const SystemDisplayOptions();
  }

  Future<void> _query() async {
    try {
      final raw = await channel.invokeMethod<Object?>('getDisplayOptions');
      if (_attached) value = SystemDisplayOptions._fromNative(raw);
    } on MissingPluginException {
      // 没有原生实现（旧 Runner）：照旧不跟系统。
    } on PlatformException {
      // 同上。
    }
  }
}
