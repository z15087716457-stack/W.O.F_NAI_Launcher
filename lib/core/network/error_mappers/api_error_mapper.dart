import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../utils/app_logger.dart';

class ApiErrorMapper {
  const ApiErrorMapper._();

  static String formatDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final serverMessage = _extractServerMessage(e.response?.data);

    final statusCodeError = switch (statusCode) {
      400 => 'API_ERROR_400|${serverMessage ?? "Bad request"}',
      429 => 'API_ERROR_429|${serverMessage ?? "Too many requests"}',
      401 => 'API_ERROR_401|${serverMessage ?? "Unauthorized"}',
      402 => 'API_ERROR_402|${serverMessage ?? "Payment required"}',
      500 => 'API_ERROR_500|${serverMessage ?? "Server error"}',
      503 => 'API_ERROR_503|${serverMessage ?? "Service unavailable"}',
      _ => null,
    };

    if (statusCodeError != null) {
      return statusCodeError;
    }

    final detail = e.message ?? e.error?.toString();
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'API_ERROR_TIMEOUT|${e.message ?? "Timeout"}',
      DioExceptionType.connectionError =>
        'API_ERROR_NETWORK|${e.message ?? "Connection error"}',
      DioExceptionType.unknown
          when e.error is SocketException ||
              e.error is HttpException ||
              e.error is HandshakeException =>
        'API_ERROR_NETWORK|${detail ?? "Connection error"}',
      _ when statusCode != null =>
        'API_ERROR_HTTP_$statusCode|${serverMessage ?? e.response?.statusMessage ?? "HTTP $statusCode"}',
      _ => 'API_ERROR_UNKNOWN|${detail ?? "Unknown error"}',
    };
  }

  static String? _extractServerMessage(dynamic data) {
    try {
      return switch (data) {
        Map() => data['message']?.toString() ?? data['error']?.toString(),
        String() when data.isNotEmpty => _plainServerMessage(data),
        Uint8List() => _extractServerMessageFromBytes(data),
        List<int>() => _extractServerMessageFromBytes(Uint8List.fromList(data)),
        _ => null,
      };
    } catch (error) {
      AppLogger.w(
        'Failed to extract error message from response: $error',
        'Utils',
      );
      return null;
    }
  }

  static String? _plainServerMessage(String text) {
    final start = text.trimLeft().toLowerCase();
    if (start.startsWith('<!doctype html') || start.startsWith('<html')) {
      return null;
    }
    return text;
  }

  static String? _extractServerMessageFromBytes(Uint8List bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    try {
      final json = jsonDecode(text);
      if (json is Map) {
        return json['message']?.toString() ?? json['error']?.toString() ?? text;
      }
      return _plainServerMessage(text);
    } catch (jsonError) {
      AppLogger.w('Failed to parse error response JSON: $jsonError', 'Utils');
      return _plainServerMessage(text);
    }
  }
}
