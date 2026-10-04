import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/network/error_mappers/api_error_mapper.dart';

void main() {
  test(
    'HTTP gateway errors retain the status without showing an HTML page',
    () {
      final request = RequestOptions(path: '/ai/generate-image-stream');
      expect(
        ApiErrorMapper.formatDioError(
          DioException(
            requestOptions: request,
            response: Response(
              requestOptions: request,
              statusCode: 504,
              statusMessage: 'Gateway Time-out',
              data: '<!DOCTYPE html><html><body>proxy failure</body></html>',
            ),
          ),
        ),
        'API_ERROR_HTTP_504|Gateway Time-out',
      );
    },
  );

  test('a socket reset without Dio message retains its network cause', () {
    final error = DioException(
      requestOptions: RequestOptions(path: '/ai/generate-image-stream'),
      error: const SocketException('connection reset by peer'),
    );
    expect(
      ApiErrorMapper.formatDioError(error),
      'API_ERROR_NETWORK|SocketException: connection reset by peer',
    );
  });

  test('server status takes precedence over a nested socket failure', () {
    final request = RequestOptions(path: '/ai/generate-image-stream');
    expect(
      ApiErrorMapper.formatDioError(
        DioException(
          requestOptions: request,
          response: Response(
            requestOptions: request,
            statusCode: 503,
            data: {'message': 'temporarily unavailable'},
          ),
          error: const SocketException('connection reset'),
        ),
      ),
      'API_ERROR_503|temporarily unavailable',
    );
  });

  test('an unknown non-network exception remains available for diagnosis', () {
    expect(
      ApiErrorMapper.formatDioError(
        DioException(
          requestOptions: RequestOptions(path: '/ai/generate-image-stream'),
          error: const FormatException('invalid response'),
        ),
      ),
      'API_ERROR_UNKNOWN|FormatException: invalid response',
    );
  });
}
