import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../utils/nai_api_utils.dart';

class GenerationFailure implements Exception {
  const GenerationFailure(
    this.message, {
    this.statusCode,
    this.retryAfter,
    this.network = false,
  });

  factory GenerationFailure.stream(String message, {int? statusCode}) =>
      GenerationFailure(
        message,
        statusCode:
            statusCode ??
            int.tryParse(_wireStatus.firstMatch(message)?.group(1) ?? ''),
      );

  factory GenerationFailure.from(Object error, {String? message}) {
    if (error is GenerationFailure) return error;
    if (error is DioException) {
      final header = error.response?.headers['retry-after']?.firstOrNull;
      return GenerationFailure(
        message ?? NAIApiUtils.formatDioError(error),
        statusCode: error.response?.statusCode,
        retryAfter: header == null ? null : _retryAfter(header),
        network: switch (error.type) {
          DioExceptionType.connectionTimeout ||
          DioExceptionType.sendTimeout ||
          DioExceptionType.receiveTimeout ||
          DioExceptionType.connectionError => true,
          DioExceptionType.unknown =>
            error.error is SocketException || error.error is TimeoutException,
          _ => false,
        },
      );
    }
    return GenerationFailure(
      message ?? error.toString(),
      network: error is SocketException || error is TimeoutException,
    );
  }

  static const missingImages = GenerationFailure(
    'No final image received from stream',
    network: true,
  );
  static final _wireStatus = RegExp(r'^API_ERROR_(?:HTTP_)?(\d{3})(?:\||$)');

  final String message;
  final int? statusCode;
  final Duration? retryAfter;
  final bool network;

  bool get isTransient =>
      network ||
      statusCode == 408 ||
      ((statusCode ?? 0) >= 500 && statusCode! < 600);
  bool get stopsRun =>
      statusCode == 401 || statusCode == 402 || statusCode == 429;
  bool get canRetry => isTransient || statusCode == 402 || statusCode == 429;

  static Duration? _retryAfter(String header) {
    final value = header.trim();
    final seconds = int.tryParse(value);
    if (seconds != null) {
      return seconds < 0 ? null : Duration(seconds: seconds.clamp(0, 91));
    }
    try {
      final delay = HttpDate.parse(value).difference(DateTime.now());
      return delay.isNegative ? Duration.zero : delay;
    } on FormatException {
      return null;
    }
  }

  @override
  String toString() => message;
}
