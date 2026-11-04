import 'dart:io';

import 'package:win32_registry/win32_registry.dart';

import '../utils/app_logger.dart';

/// 注册表 Internet Settings 下的两项：ProxyEnable（REG_DWORD）和 ProxyServer（REG_SZ）。
/// ProxyEnable 不是 1 时不读 ProxyServer，为 null。
typedef WindowsProxyRegistryValues = ({int? enable, String? server});

/// 读 [WindowsProxyRegistryValues]。只查注册表、不写日志，能放到后台 isolate 里跑。
typedef WindowsProxyRegistryRead = WindowsProxyRegistryValues Function();

/// Windows 系统代理辅助类
/// 用于读取 Windows 注册表中的代理设置
class WindowsProxyHelper {
  /// 注册表路径
  static const String _registryPath =
      r'Software\Microsoft\Windows\CurrentVersion\Internet Settings';

  /// 代理启用键名
  static const String _proxyEnableKey = 'ProxyEnable';

  /// 代理服务器键名
  static const String _proxyServerKey = 'ProxyServer';

  /// 获取当前系统代理配置
  ///
  /// 返回格式：
  /// - "PROXY host:port" 如果代理已启用
  /// - "DIRECT" 如果代理未启用或获取失败
  static String? getSystemProxy() {
    // 仅在 Windows 平台执行
    if (!Platform.isWindows) {
      return null;
    }

    try {
      return proxyFromRegistryValues(readRegistryValues());
    } catch (e, stackTrace) {
      logReadFailure(e, stackTrace);
      return 'DIRECT';
    }
  }

  /// 读注册表里的 ProxyEnable 和 ProxyServer（见 [WindowsProxyRegistryValues]）。
  ///
  /// 只调 Win32、不写日志：`SystemProxyReader` 在后台 isolate 里调它，界面线程不用等注册表。
  static WindowsProxyRegistryValues readRegistryValues() {
    // 打开注册表项
    final key = Registry.openPath(
      RegistryHive.currentUser,
      path: _registryPath,
    );
    try {
      // 读取代理启用状态 (REG_DWORD)
      final proxyEnableData = key.getValue(_proxyEnableKey)?.data;
      final proxyEnable = proxyEnableData is int ? proxyEnableData : null;
      // 代理未启用时不读服务器地址
      if (proxyEnable != 1) return (enable: proxyEnable, server: null);

      // 读取代理服务器地址 (REG_SZ)
      final proxyServerData = key.getValue(_proxyServerKey)?.data;
      return (
        enable: proxyEnable,
        server: proxyServerData is String ? proxyServerData : null,
      );
    } finally {
      key.close();
    }
  }

  /// 由 [readRegistryValues] 读到的两项得出 "PROXY host:port"；代理未启用或格式不对时是 "DIRECT"。
  static String proxyFromRegistryValues(WindowsProxyRegistryValues values) {
    final proxyEnable = values.enable;
    AppLogger.d(
      'Windows Proxy Enable: $proxyEnable (type: ${proxyEnable?.runtimeType})',
      'PROXY',
    );

    // 如果代理未启用，返回 DIRECT
    if (proxyEnable != 1) {
      AppLogger.d('Proxy disabled, using DIRECT', 'PROXY');
      return 'DIRECT';
    }

    final proxyServer = values.server;
    AppLogger.d('Raw Proxy Server string: "$proxyServer"', 'PROXY');

    // 解析代理服务器字符串
    final parsedProxy = _parseProxyServer(proxyServer);

    if (parsedProxy != null) {
      AppLogger.d('Parsed proxy: $parsedProxy', 'PROXY');
      return 'PROXY $parsedProxy';
    } else {
      AppLogger.d('Invalid proxy format, using DIRECT', 'PROXY');
      return 'DIRECT';
    }
  }

  /// 读注册表出错时记的日志，同步、异步两条路记的一样。
  static void logReadFailure(Object error, StackTrace stackTrace) {
    AppLogger.e(
      'Failed to read Windows proxy settings: $error',
      'PROXY',
      stackTrace,
    );
  }

  /// 解析代理服务器字符串
  ///
  /// Windows 注册表中的格式可能是：
  /// - 简单格式: "127.0.0.1:7890"
  /// - 复杂格式: "http=127.0.0.1:7890;https=127.0.0.1:7890"
  /// - SOCKS 格式: "socks=127.0.0.1:1080"
  static String? _parseProxyServer(String? proxyServer) {
    if (proxyServer == null || proxyServer.isEmpty) {
      return null;
    }

    // 去除首尾空格
    proxyServer = proxyServer.trim();

    // 如果包含等号（复杂格式），尝试解析
    if (proxyServer.contains('=')) {
      // 尝试获取 http 或 https 代理
      // 格式: "http=host:port;https=host:port"
      final parts = proxyServer.split(';');
      for (final part in parts) {
        final kv = part.split('=');
        if (kv.length == 2) {
          final protocol = kv[0].trim().toLowerCase();
          final hostPort = kv[1].trim();

          // 优先使用 http，其次 https
          if ((protocol == 'http' || protocol == 'https') &&
              hostPort.isNotEmpty) {
            return hostPort;
          }
        }
      }

      // 如果没找到 http/https，尝试获取 socks
      for (final part in parts) {
        final kv = part.split('=');
        if (kv.length == 2) {
          final protocol = kv[0].trim().toLowerCase();
          final hostPort = kv[1].trim();

          if (protocol == 'socks' && hostPort.isNotEmpty) {
            AppLogger.w(
              'SOCKS proxy detected but Dart HttpClient has limited SOCKS support',
              'PROXY',
            );
            return hostPort;
          }
        }
      }

      return null;
    }

    // 简单格式：直接返回
    return proxyServer;
  }
}
