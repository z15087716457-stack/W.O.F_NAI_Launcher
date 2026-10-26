import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/nai_auth_transport.dart';
import '../../../presentation/providers/proxy_settings_provider.dart';
import '../../../core/network/nai_api_endpoint.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/localization_extension.dart';

part 'nai_auth_api_service.g.dart';

/// NovelAI Authentication API 服务
class NAIAuthApiService {
  static const Duration _timeout = Duration(seconds: 30);
  static final RegExp _bearerPrefixRegex = RegExp(
    r'^Bearer\s+',
    caseSensitive: false,
  );
  static final RegExp _allWhitespaceRegex = RegExp(r'\s+');

  final Dio? _dio;

  NAIAuthApiService(Dio dio) : _dio = dio, _transport = null;

  NAIAuthApiService.withTransport(NaiAuthTransport transport)
    : _transport = transport,
      _dio = null;

  final NaiAuthTransport? _transport;
  Future<T> _send<T>(
    CancelToken? cancel,
    Future<T> Function(Dio) request,
  ) async {
    if (_transport case final transport?) {
      return transport.send(cancel, request);
    }
    try {
      return await request(_dio!);
    } on DioException catch (error) {
      logAuthNetworkFailure(_dio!, error);
      rethrow;
    }
  }

  /// 验证 API Token 是否有效
  Future<Map<String, dynamic>> validateToken(
    String token, {
    NaiApiEndpointConfig endpoint = NaiApiEndpointConfig.official,
    bool allowAnyTokenFormat = false,
    CancelToken? cancelToken,
  }) async {
    final normalizedToken = _normalizeToken(token);

    if (normalizedToken.isEmpty) {
      throw ArgumentError(currentL10n.auth_tokenEmpty);
    }

    if (!allowAnyTokenFormat && !_isSupportedTokenFormat(normalizedToken)) {
      throw ArgumentError(currentL10n.auth_tokenFormatInvalid);
    }

    // 所有 token 都使用 Bearer 前缀（与 NAI-Generator-Flutter 保持一致）
    final authHeader = 'Bearer $normalizedToken';

    // 详细的日志记录用于诊断登录问题
    final tokenFormat = normalizedToken.startsWith('pst-') ? 'pst' : 'jwt';
    AppLogger.i(
      'Validating token: format=$tokenFormat, length=${normalizedToken.length}',
      'NAIAuth',
    );
    AppLogger.d(
      'Auth header prepared: length=${authHeader.length}, tokenFormat=$tokenFormat',
      'NAIAuth',
    );

    try {
      final response = await _send(
        cancelToken,
        (dio) => dio.get(
          endpoint.userUrl(ApiConstants.userSubscriptionEndpoint),
          cancelToken: cancelToken,
          options: Options(
            headers: {'Authorization': authHeader},
            receiveTimeout: _timeout,
            sendTimeout: _timeout,
          ),
        ),
      );

      AppLogger.i('Token validation successful', 'NAIAuth');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        final responseData = e.response?.data;
        final message = responseData is Map ? responseData['message'] : null;
        AppLogger.e(
          'Token validation failed (400), authHeader format=$tokenFormat',
          'NAIAuth',
        );
        // 添加更详细的错误信息
        if (message?.toString().contains('Invalid Authorization header') ??
            false) {
          throw DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            type: e.type,
            error: currentL10n.auth_tokenInvalidOrExpired,
          );
        }
      }
      rethrow;
    }
  }

  /// 使用 Access Key 登录
  Future<Map<String, dynamic>> loginWithKey(
    String accessKey, {
    NaiApiEndpointConfig endpoint = NaiApiEndpointConfig.official,
    CancelToken? cancelToken,
  }) async {
    AppLogger.d('Attempting login with access key', 'NAIAuth');

    final response = await _send(
      cancelToken,
      (dio) => dio.post(
        endpoint.userUrl(ApiConstants.loginEndpoint),
        data: {'key': accessKey},
        cancelToken: cancelToken,
        options: Options(receiveTimeout: _timeout, sendTimeout: _timeout),
      ),
    );
    return response.data as Map<String, dynamic>;
  }

  /// 检查 Token 格式是否有效 (pst-xxxx)
  /// NovelAI Persistent Token 格式: pst- 前缀 + 64位十六进制字符
  static bool isValidTokenFormat(String token) {
    if (!token.startsWith('pst-')) return false;
    // pst- 前缀 (4字符) + 至少 10 字符的 token 内容
    if (token.length < 14) return false;
    // 检查是否包含非法字符（Persistent Token 应该是十六进制格式）
    final tokenBody = token.substring(4); // 去掉 'pst-'
    // 允许字母、数字、下划线和横线
    final validPattern = RegExp(r'^[a-zA-Z0-9_-]+$');
    return validPattern.hasMatch(tokenBody);
  }

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

  bool _isSupportedTokenFormat(String token) {
    if (token.startsWith('pst-')) {
      return token.length > 10;
    }

    // JWT 基础格式：header.payload.signature
    final parts = token.split('.');
    return parts.length == 3 &&
        parts.every((part) => part.isNotEmpty) &&
        !token.contains(' ');
  }
}

/// NAIAuthApiService Provider
@Riverpod(keepAlive: true)
NAIAuthApiService naiAuthApiService(Ref ref) {
  final transport = NaiAuthTransport(
    resolveProxy: () =>
        ref.read(proxySettingsNotifierProvider).effectiveProxyAddress,
  );
  ref.onDispose(transport.close);
  return NAIAuthApiService.withTransport(transport);
}
