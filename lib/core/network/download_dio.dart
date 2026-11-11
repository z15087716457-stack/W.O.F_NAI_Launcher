import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'proxy_service.dart';

/// Public file downloads use the current app proxy without API interceptors.
Dio createDownloadDio({
  required Duration receiveTimeout,
  String? Function()? resolveProxy,
}) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: receiveTimeout,
    ),
  );
  if (resolveProxy != null) {
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () =>
          HttpClient()
            ..findProxy = (_) => ProxyService.getProxyString(resolveProxy()),
    );
  }
  return dio;
}
