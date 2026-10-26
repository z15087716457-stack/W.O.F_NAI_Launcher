import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:dio_http2_adapter/dio_http2_adapter.dart';

import '../constants/api_constants.dart';
import '../utils/app_logger.dart';

/// Each authentication request owns an abortable HTTP/1.1 client. Http2Adapter
/// cannot cancel pending TLS handshakes or response streams by closing its pool.
/// Per-request ownership also isolates login from concurrent token refreshes.
class NaiAuthTransport {
  NaiAuthTransport({required this.resolveProxy});
  final String? Function() resolveProxy;
  final _active = <Dio>{};

  Future<T> send<T>(
    CancelToken? cancel,
    Future<T> Function(Dio) request,
  ) async {
    if (cancel?.cancelError case final error?) throw error;
    // Resolve settings anew, including the registry in system mode. Explicit
    // DIRECT must override a proxy cached by process-start HttpOverrides.
    final proxy = resolveProxy();
    final dio = Dio(
      BaseOptions(
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: ApiConstants.defaultHeaders,
      ),
    );
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final http = HttpClient();
        http.findProxy = (_) =>
            proxy == null || proxy.isEmpty ? 'DIRECT' : 'PROXY $proxy';
        return http;
      },
    );
    _active.add(dio);
    // Dio's adapter only installs request.abort after openUrl completes. Closing
    // the owned client also interrupts TCP/TLS/CONNECT while openUrl is pending.
    final weak = WeakReference(dio);
    cancel?.whenCancel.then((_) => weak.target?.close(force: true));
    try {
      return await request(dio);
    } on DioException catch (error) {
      logAuthNetworkFailure(dio, error, proxy: proxy);
      rethrow;
    } finally {
      _active.remove(dio);
      dio.close(force: true);
    }
  }

  void close() {
    for (final dio in _active) {
      dio.close(force: true);
    }
    _active.clear();
  }
}

/// Never log response bodies, headers, URI query/userinfo, or exception text.
void logAuthNetworkFailure(Dio client, DioException error, {String? proxy}) =>
    AppLogger.w(
      authNetworkFailureDescription(client, error, proxy: proxy),
      'NAIAuth',
    );

String authNetworkFailureDescription(
  Dio client,
  DioException error, {
  String? proxy,
}) {
  final proxyUri = proxy == null ? null : Uri.tryParse('http://$proxy');
  final raw = '${error.error} ${error.message}'.toLowerCase();
  final stage = error.response?.statusCode != null
      ? 'HTTP ${error.response!.statusCode}'
      : error.error is HandshakeException ||
            error.type == DioExceptionType.badCertificate
      ? 'TLS'
      : raw.contains('failed host lookup') || raw.contains('name resolution')
      ? 'DNS'
      : raw.contains('proxy') &&
            (raw.contains('connect') || raw.contains('tunnel'))
      ? 'proxy CONNECT'
      : error.type == DioExceptionType.cancel
      ? 'cancel/timeout'
      : error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout
      ? 'timeout (connection/TLS/response not established)'
      : 'connection';
  return 'Login failed: proxy=${proxy == null ? 'DIRECT' : 'HTTP ${proxyUri?.host ?? 'unknown'}'} '
      'adapter=${client.httpClientAdapter is Http2Adapter ? 'h2' : 'h1'} '
      'target=${error.requestOptions.uri.host} stage=$stage '
      'exception=${error.type.name}/${error.error.runtimeType}';
}
