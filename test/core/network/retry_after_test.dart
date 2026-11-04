import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/network/retry_after.dart';

void main() {
  group('parseRetryAfter', () {
    final now = DateTime.utc(2026, 10, 30, 12);

    test('reads delay seconds', () {
      expect(parseRetryAfter('7', now: now), const Duration(seconds: 7));
      expect(parseRetryAfter(' 45 ', now: now), const Duration(seconds: 45));
      expect(parseRetryAfter('0', now: now), Duration.zero);
    });

    test('reads an HTTP date relative to now', () {
      expect(
        parseRetryAfter('Fri, 30 Oct 2026 12:00:20 GMT', now: now),
        const Duration(seconds: 20),
      );
    });

    test('a date in the past means no wait', () {
      expect(
        parseRetryAfter('Fri, 30 Oct 2026 11:59:00 GMT', now: now),
        Duration.zero,
      );
    });

    test('missing, negative or garbled values are ignored', () {
      expect(parseRetryAfter(null, now: now), isNull);
      expect(parseRetryAfter('', now: now), isNull);
      expect(parseRetryAfter('-5', now: now), isNull);
      expect(parseRetryAfter('soon', now: now), isNull);
    });
  });

  group('retryAfterOf', () {
    DioException rejected(Map<String, List<String>> headers) => DioException(
      requestOptions: RequestOptions(path: '/ai/generate-image-stream'),
      type: DioExceptionType.badResponse,
      response: Response<void>(
        requestOptions: RequestOptions(path: '/ai/generate-image-stream'),
        statusCode: 429,
        headers: Headers.fromMap(headers),
      ),
    );

    test('reads the header whatever its case', () {
      expect(
        retryAfterOf(
          rejected({
            'Retry-After': ['12'],
          }),
        ),
        const Duration(seconds: 12),
      );
    });

    test('no header or no response gives null', () {
      expect(retryAfterOf(rejected({})), isNull);
      expect(
        retryAfterOf(
          DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.connectionError,
          ),
        ),
        isNull,
      );
    });
  });
}
