import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/services/token_refresh_service.dart';
import '../../l10n/app_localizations.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/locale_provider.dart';
import '../../presentation/providers/proxy_settings_provider.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import '../utils/app_logger.dart';

part 'dio_client.g.dart';

/// Dio 客户端 Provider
///
/// 根据代理设置动态选择 HTTP 适配器：
/// - 有代理时：使用 HTTP/1.1 适配器，显式应用本次解析的代理
/// - 无代理时：使用 HTTP/2 适配器（提升并发性能）
@Riverpod(keepAlive: true)
Dio dioClient(Ref ref) {
  // 监听设置而非已缓存的代理地址，每次重建都重新解析系统代理。
  final proxyAddress = ref
      .watch(proxySettingsNotifierProvider)
      .effectiveProxyAddress;

  final dio = Dio(
    BaseOptions(
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: ApiConstants.defaultHeaders,
    ),
  );

  // 添加认证拦截器
  dio.interceptors.add(AuthInterceptor(ref));

  // 添加错误处理拦截器
  dio.interceptors.add(ErrorInterceptor(ref));

  // 根据代理设置选择适配器
  if (proxyAddress != null && proxyAddress.isNotEmpty) {
    // 不沿用进程启动时 HttpOverrides 缓存的代理。
    AppLogger.i(
      'Dio using HTTP proxy host=${Uri.tryParse('http://$proxyAddress')?.host} (h1)',
      'NETWORK',
    );
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.findProxy = (_) => 'PROXY $proxyAddress';
        return client;
      },
    );
  } else {
    // 无代理时：使用 HTTP/2 适配器以提升并发性能
    AppLogger.d('Dio using HTTP/2 adapter (no proxy)', 'NETWORK');
    dio.httpClientAdapter = Http2Adapter(
      ConnectionManager(idleTimeout: const Duration(seconds: 15)),
    );
  }

  // 注意：不要在 dispose 时关闭 Dio，因为 Provider 可能会被重建
  // ref.onDispose(dio.close);

  return dio;
}

/// 图像生成专用 Dio Provider
///
/// 始终使用默认 HTTP/1.1 适配器，不用 HTTP/2：
/// Http2Adapter 在响应到达前取消请求时不会终止 HTTP/2 流
/// （上游在 2.5.2 移除了 client stream termination），
/// NovelAI 收不到中止信号会继续生成并占用账号并发额度，
/// 导致取消后的新请求全部立即 429。
/// 默认适配器通过 HttpClientRequest.abort() 在任意阶段真正中断请求。
@Riverpod(keepAlive: true)
Dio imageGenerationDioClient(Ref ref) {
  // 监听代理设置变化触发重建：默认适配器在创建 HttpClient 时
  // 才读取 HttpOverrides.global，代理变更后需要新实例
  ref.watch(currentProxyAddressProvider);

  final dio = Dio(
    BaseOptions(
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: ApiConstants.defaultHeaders,
    ),
  );

  dio.interceptors.add(AuthInterceptor(ref));
  dio.interceptors.add(ErrorInterceptor(ref));

  AppLogger.d(
    'Image generation Dio using HTTP/1.1 adapter (abortable)',
    'NETWORK',
  );

  return dio;
}

/// 认证拦截器 - 自动添加 Bearer Token 并支持 401 自动刷新
class AuthInterceptor extends Interceptor {
  final Ref _ref;
  static const _sessionRevisionKey = 'nai.authSessionRevision';

  /// 是否正在刷新中（防止并发刷新）
  bool _isRefreshing = false;

  static final RegExp _bearerPrefixRegex = RegExp(
    r'^Bearer\s+',
    caseSensitive: false,
  );
  static final RegExp _allWhitespaceRegex = RegExp(r'\s+');

  AuthInterceptor(this._ref);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    AppLogger.d('Request to: ${options.path}', 'DIO');
    options.extra.remove(_sessionRevisionKey);

    // 登录接口不需要 Token
    if (options.path.contains('/user/login')) {
      AppLogger.d('Skipping auth for login endpoint', 'DIO');
      handler.next(options);
      return;
    }

    // 检查请求是否已经有 Authorization header（如 validateToken 自己设置的）
    final existingAuth = options.headers['Authorization'];
    if (existingAuth != null && existingAuth.toString().isNotEmpty) {
      // 规范化并确保使用 Bearer 前缀
      final normalizedExisting = _normalizeToken(existingAuth.toString());
      final authHeader = 'Bearer $normalizedExisting';
      options.headers['Authorization'] = authHeader;
      AppLogger.d(
        'Using existing auth header: normalized_length=${normalizedExisting.length}',
        'DIO',
      );
      handler.next(options);
      return;
    }

    // 获取存储的 Token
    final storage = _ref.read(secureStorageServiceProvider);
    final revision = storage.authRevision;
    final token = await storage.getAccessToken();

    if (token != null && token.isNotEmpty) {
      final normalizedToken = _normalizeToken(token);
      if (normalizedToken.isEmpty) {
        AppLogger.w('Stored token is empty after normalization', 'DIO');
        handler.next(options);
        return;
      }

      // 所有 token 都使用 Bearer 前缀（与 NAI-Generator-Flutter 保持一致）
      final authHeader = 'Bearer $normalizedToken';

      options.headers['Authorization'] = authHeader;
      options.extra[_sessionRevisionKey] = revision;
      AppLogger.d(
        'Added auth header from storage, token length: ${normalizedToken.length}',
        'DIO',
      );
    } else {
      AppLogger.w(
        'No token available for request! Token is ${token == null ? "null" : "empty"}',
        'DIO',
      );
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final revision = err.requestOptions.extra[_sessionRevisionKey];
    if (err.response?.statusCode != 401 ||
        err.requestOptions.path.contains(ApiConstants.loginEndpoint) ||
        revision is! int ||
        _isRefreshing) {
      handler.next(err);
      return;
    }
    final session = _ref.read(authNotifierProvider);
    if (!session.isAuthenticated || !_ownsSession(revision, session)) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;
    try {
      final refreshed = await _ref
          .read(tokenRefreshServiceProvider.notifier)
          .refreshCurrentToken();
      if (!refreshed) {
        if (_ownsSession(revision, session)) {
          await _ref
              .read(authNotifierProvider.notifier)
              .logout(errorCode: AuthErrorCode.authFailed, httpStatusCode: 401);
        }
        handler.next(err);
        return;
      }

      final storage = _ref.read(secureStorageServiceProvider);
      final retryRevision = storage.authRevision;
      final token = await storage.getAccessToken();
      if (!_ownsSession(retryRevision, session) ||
          token == null ||
          token.isEmpty) {
        handler.next(err);
        return;
      }
      err.requestOptions.headers['Authorization'] =
          'Bearer ${_normalizeToken(token)}';
      // 不安装认证拦截器，重试只执行一次，并原样返回服务端／网络错误。
      final retry = Dio();
      try {
        handler.resolve(await retry.fetch(err.requestOptions));
      } on DioException catch (retryError) {
        if (retryError.response?.statusCode == 401 &&
            _ownsSession(retryRevision, session)) {
          await _ref
              .read(authNotifierProvider.notifier)
              .logout(errorCode: AuthErrorCode.authFailed, httpStatusCode: 401);
        }
        handler.next(retryError);
      } finally {
        retry.close(force: true);
      }
    } catch (error, stack) {
      AppLogger.e('Token refresh error', error, stack, 'DIO');
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  bool _ownsSession(int revision, AuthState session) =>
      _ref.read(secureStorageServiceProvider).authRevision == revision &&
      identical(_ref.read(authNotifierProvider), session);

  String _normalizeToken(String token) {
    final trimmedToken = token.trim();
    final unquotedToken = _stripWrappingQuotes(trimmedToken);

    // 循环移除所有 Bearer 前缀（处理重复添加的情况）
    var normalizedToken = unquotedToken;
    var previousToken = '';
    while (normalizedToken != previousToken) {
      previousToken = normalizedToken;
      normalizedToken = normalizedToken
          .replaceFirst(_bearerPrefixRegex, '')
          .trim();
    }

    // 移除所有空白字符
    return normalizedToken.replaceAll(_allWhitespaceRegex, '');
  }

  String _stripWrappingQuotes(String value) {
    if (value.length >= 2) {
      final first = value[0];
      final last = value[value.length - 1];
      if ((first == '"' && last == '"') || (first == '\'' && last == '\'')) {
        return value.substring(1, value.length - 1);
      }
    }
    return value;
  }
}

/// 错误处理拦截器
class ErrorInterceptor extends Interceptor {
  ErrorInterceptor(this._ref);

  final Ref _ref;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final message =
        'DIO Error: ${err.type.name}\n'
        'Status: ${err.response?.statusCode}\n'
        'URL: ${err.requestOptions.uri}\n'
        'Response Data: ${err.response?.data}';

    // 非致命网络抖动降级为 warning，避免错误日志噪音
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.cancel) {
      AppLogger.w(message, 'DIO');
    } else {
      AppLogger.e(message, null, null, 'DIO');
    }

    // 统一错误处理
    final error = _mapError(err);
    handler.next(error);
  }

  DioException _mapError(DioException err) {
    final l10n = lookupAppLocalizations(_ref.read(localeNotifierProvider));
    final message = switch (err.type) {
      DioExceptionType.connectionTimeout => l10n.networkError_connectionTimeout,
      DioExceptionType.sendTimeout => l10n.networkError_sendTimeout,
      DioExceptionType.receiveTimeout => l10n.networkError_receiveTimeout,
      DioExceptionType.badResponse => _parseResponseError(err.response, l10n),
      DioExceptionType.cancel => l10n.networkError_requestCancelled,
      DioExceptionType.connectionError => l10n.networkError_connection,
      _ => err.message ?? l10n.networkError_unknown,
    };

    return DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: err.error,
      message: message,
    );
  }

  String _parseResponseError(Response? response, AppLocalizations l10n) {
    if (response == null) return l10n.networkError_noResponse;

    // 尝试从响应中提取错误信息
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }

    // 根据状态码返回错误信息
    return switch (response.statusCode) {
      400 => l10n.networkError_badRequest,
      401 => l10n.networkError_authFailed,
      402 => l10n.networkError_insufficientAnlas,
      403 => l10n.networkError_forbidden,
      404 => l10n.networkError_notFound,
      409 => l10n.networkError_conflict,
      429 => l10n.networkError_rateLimited,
      500 => l10n.networkError_serverInternal,
      502 => l10n.networkError_badGateway,
      503 => l10n.networkError_unavailable,
      final code => l10n.networkError_requestFailed(code ?? 0),
    };
  }
}
