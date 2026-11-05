import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import '../utils/app_logger.dart';
import 'windows_proxy_helper.dart';
import '../utils/localization_extension.dart';

/// 代理测试结果
class ProxyTestResult {
  final bool success;
  final String? errorMessage;
  final int? latencyMs;

  const ProxyTestResult({
    required this.success,
    this.errorMessage,
    this.latencyMs,
  });

  factory ProxyTestResult.success(int latencyMs) =>
      ProxyTestResult(success: true, latencyMs: latencyMs);

  factory ProxyTestResult.failure(String error) =>
      ProxyTestResult(success: false, errorMessage: error);
}

/// 系统代理服务
///
/// 负责：
/// - 读取系统代理配置（Windows）
/// - 提供统一的代理配置接口
/// - 测试代理连接
class ProxyService {
  ProxyService._();

  /// 获取系统代理地址
  ///
  /// 返回格式: "host:port" 或 null（未检测到代理）
  static String? getSystemProxyAddress() {
    try {
      if (Platform.isWindows) {
        return _getWindowsProxy();
      }
      if (Platform.isMacOS) {
        final result = Process.runSync('/usr/sbin/scutil', ['--proxy']);
        if (result.exitCode == 0) return parseMacProxy(result.stdout as String);
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.e('Failed to get system proxy: $e', 'PROXY', stackTrace);
      return null;
    }
  }

  /// Read static HTTP(S) settings. PAC scripts are handled by native apps.
  static String? parseMacProxy(String output) {
    final fields = <String, String>{
      for (final line in output.split('\n'))
        if (RegExp(
              r'^\s*(HTTPS?(?:Enable|Proxy|Port))\s*:\s*(.+)$',
            ).firstMatch(line)
            case final match?)
          match[1]!: match[2]!.trim(),
    };
    for (final kind in ['HTTPS', 'HTTP']) {
      final host = fields['${kind}Proxy'];
      final port = int.tryParse(fields['${kind}Port'] ?? '');
      if (fields['${kind}Enable'] != '1' ||
          host == null ||
          host.isEmpty ||
          port == null ||
          port < 1 ||
          port > 65535) {
        continue;
      }
      return host.contains(':') && !host.startsWith('[')
          ? '[$host]:$port'
          : '$host:$port';
    }
    return null;
  }

  /// Runs the settings page's system read off the UI isolate.
  static Future<String?> readSystemProxyAddress() =>
      Isolate.run(getSystemProxyAddress);

  /// Windows: 通过注册表读取代理
  static String? _getWindowsProxy() {
    final proxyString = WindowsProxyHelper.getSystemProxy();
    if (proxyString == null || proxyString == 'DIRECT') {
      return null;
    }
    // WindowsProxyHelper 返回 "PROXY host:port"，需要提取 host:port
    if (proxyString.startsWith('PROXY ')) {
      return proxyString.substring(6);
    }
    return proxyString;
  }

  /// 创建测试用的 Dio 实例
  static Dio _createTestDio({String? proxyAddress, Duration? timeout}) {
    final dio = Dio(
      BaseOptions(
        connectTimeout: timeout ?? const Duration(seconds: 10),
        receiveTimeout: timeout ?? const Duration(seconds: 10),
        followRedirects: true,
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (proxyAddress != null && proxyAddress.isNotEmpty) {
      dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient();
          client.findProxy = (uri) => 'PROXY $proxyAddress';
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );
    }

    return dio;
  }

  static String _getErrorMessage(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout => currentL10n.proxy_connectTimeout,
      DioExceptionType.connectionError => currentL10n.proxy_cannotConnect,
      _ => e.message ?? currentL10n.proxy_connectFailed,
    };
  }

  /// 获取代理字符串（用于 HttpClient.findProxy）
  static String getProxyString(String? proxyAddress) {
    if (proxyAddress == null || proxyAddress.isEmpty) {
      return 'DIRECT';
    }
    return 'PROXY $proxyAddress';
  }

  /// 测试代理连接
  static Future<ProxyTestResult> testProxyConnection(
    String proxyAddress,
  ) async {
    final stopwatch = Stopwatch()..start();
    final dio = _createTestDio(proxyAddress: proxyAddress);

    try {
      final testUrls = [
        'https://www.google.com/generate_204',
        'https://www.gstatic.com/generate_204',
        'https://api.github.com',
      ];

      for (final url in testUrls) {
        try {
          final response = await dio.get(url);
          if (response.statusCode == 200 || response.statusCode == 204) {
            return ProxyTestResult.success(stopwatch.elapsedMilliseconds);
          }
        } catch (e) {
          AppLogger.d('Proxy test URL failed ($url): $e', 'ProxyService');
        }
      }
      return ProxyTestResult.failure(currentL10n.proxy_testServerUnreachable);
    } on DioException catch (e) {
      return ProxyTestResult.failure(_getErrorMessage(e));
    } catch (e) {
      return ProxyTestResult.failure(currentL10n.proxy_testFailed('$e'));
    } finally {
      dio.close();
    }
  }

  /// 测试 NovelAI 连接
  static Future<ProxyTestResult> testNovelAIConnection({
    String? proxyAddress,
    Duration? timeout,
  }) async {
    final stopwatch = Stopwatch()..start();
    final dio = _createTestDio(
      proxyAddress: proxyAddress,
      timeout: timeout ?? const Duration(seconds: 5),
    );

    try {
      final response = await dio.get('https://novelai.net');
      if (response.statusCode == 200 ||
          response.statusCode == 307 ||
          response.statusCode == 302) {
        return ProxyTestResult.success(stopwatch.elapsedMilliseconds);
      }
      return ProxyTestResult.failure('HTTP ${response.statusCode}');
    } on DioException catch (e) {
      return ProxyTestResult.failure(_getErrorMessage(e));
    } catch (e) {
      return ProxyTestResult.failure(currentL10n.proxy_testFailed('$e'));
    } finally {
      dio.close();
    }
  }
}
