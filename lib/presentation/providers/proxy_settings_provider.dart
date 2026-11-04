import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/storage_keys.dart';
import '../../core/network/system_proxy_reader.dart';
import '../../core/storage/local_storage_service.dart';
import '../../data/models/settings/proxy_settings.dart';

part 'proxy_settings_provider.g.dart';

/// 代理设置状态 Notifier
@riverpod
class ProxySettingsNotifier extends _$ProxySettingsNotifier {
  @override
  ProxySettings build() {
    final storage = ref.read(localStorageServiceProvider);

    // 从本地存储读取代理设置
    final enabled = storage.getSetting<bool>(StorageKeys.proxyEnabled) ?? true;
    final modeStr = storage.getSetting<String>(StorageKeys.proxyMode) ?? 'auto';
    final manualHost = storage.getSetting<String>(StorageKeys.proxyManualHost);
    final manualPort = storage.getSetting<int>(StorageKeys.proxyManualPort);

    // 解析模式
    ProxyMode mode;
    try {
      mode = ProxyMode.values.byName(modeStr);
    } catch (_) {
      mode = ProxyMode.auto;
    }

    return ProxySettings(
      enabled: enabled,
      mode: mode,
      manualHost: manualHost,
      manualPort: manualPort,
    );
  }

  /// 设置是否启用代理
  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    final storage = ref.read(localStorageServiceProvider);
    await storage.setSetting(StorageKeys.proxyEnabled, value);

    // 触发 Dio 客户端重建
    ref.invalidateSelf();
  }

  /// 设置代理模式
  Future<void> setMode(ProxyMode mode) async {
    state = state.copyWith(mode: mode);
    final storage = ref.read(localStorageServiceProvider);
    await storage.setSetting(StorageKeys.proxyMode, mode.name);

    // 触发 Dio 客户端重建
    ref.invalidateSelf();
  }

  /// 设置手动代理地址
  Future<void> setManualProxy(String host, int port) async {
    state = state.copyWith(manualHost: host, manualPort: port);
    final storage = ref.read(localStorageServiceProvider);
    await storage.setSetting(StorageKeys.proxyManualHost, host);
    await storage.setSetting(StorageKeys.proxyManualPort, port);

    // 触发 Dio 客户端重建
    ref.invalidateSelf();
  }

  /// 清除手动代理设置
  Future<void> setManualFields({String? host, int? port}) async {
    final storage = ref.read(localStorageServiceProvider);
    if (host == null) {
      await storage.deleteSetting(StorageKeys.proxyManualHost);
    } else {
      await storage.setSetting(StorageKeys.proxyManualHost, host);
    }
    if (port == null) {
      await storage.deleteSetting(StorageKeys.proxyManualPort);
    } else {
      await storage.setSetting(StorageKeys.proxyManualPort, port);
    }
    ref.invalidateSelf();
  }

  /// 清除手动代理设置
  Future<void> clearManualProxy() async {
    state = state.copyWith(manualHost: null, manualPort: null);
    final storage = ref.read(localStorageServiceProvider);
    await storage.deleteSetting(StorageKeys.proxyManualHost);
    await storage.deleteSetting(StorageKeys.proxyManualPort);

    ref.invalidateSelf();
  }
}

/// 当前有效的代理地址
///
/// 供其他组件订阅，用于判断是否需要使用代理
@riverpod
String? currentProxyAddress(Ref ref) {
  final settings = ref.watch(proxySettingsNotifierProvider);
  return settings.effectiveProxyAddress;
}

/// 设置页读系统代理用的读取器：读这台机器自己的系统设置（见 [SystemProxyPlatform.host]）。
final systemProxyReaderProvider = Provider<SystemProxyReader>(
  (ref) => SystemProxyReader(),
);

/// 设置页显示系统代理用的缓存，设置页关了也留着：30 秒内再打开不用重读。
@Riverpod(keepAlive: true)
SystemProxyCache systemProxyCache(Ref ref) =>
    SystemProxyCache(ref.watch(systemProxyReaderProvider).read);

/// 检测到的系统代理地址
///
/// 用于在 UI 中显示当前系统代理配置。读取不占界面线程（见 [SystemProxyReader]），读完之前没有值；
/// 30 秒内读过就直接用上次的结果，代理设置一改就重读（见 [SystemProxyCache]）。
@riverpod
FutureOr<String?> detectedSystemProxy(Ref ref) {
  final settings = ref.watch(proxySettingsNotifierProvider);
  return ref.watch(systemProxyCacheProvider).read(scope: settings);
}
