import 'dart:async';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/network/dio_client.dart';
import 'package:nai_launcher/core/network/error_mappers/api_error_mapper.dart';
import 'package:nai_launcher/data/models/image/image_stream_chunk.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/providers/generation/generation_retry_policy.dart';
import 'package:nai_launcher/presentation/providers/locale_provider.dart';

import '../../../helpers/app_logger_test_isolation.dart';

DioException _status(int code, {Map<String, List<String>> headers = const {}}) {
  final options = RequestOptions(path: '/ai/generate-image');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<void>(
      requestOptions: options,
      statusCode: code,
      headers: Headers.fromMap(headers),
    ),
  );
}

DioException _type(DioExceptionType type, {Object? error}) => DioException(
  requestOptions: RequestOptions(path: '/ai/generate-image'),
  type: type,
  error: error,
);

/// What a stream request leaves behind once the batch loop wraps it.
String _streamText(DioException error) =>
    'Exception: ${ApiErrorMapper.formatDioError(error)}';

class _Locale extends LocaleNotifier {
  _Locale(this.locale);
  final Locale locale;
  @override
  Locale build() => locale;
}

class _Passed extends ErrorInterceptorHandler {
  DioException? error;
  @override
  void next(DioException err) => error = err;
}

/// A non-stream request rejected with [code]; it asks for bytes, so the
/// body is never a map.
DioException _rejectedBytes(int code) {
  final options = RequestOptions(path: '/ai/generate-image');
  return DioException.badResponse(
    statusCode: code,
    requestOptions: options,
    response: Response<Uint8List>(
      requestOptions: options,
      statusCode: code,
      data: Uint8List(0),
    ),
  );
}

/// What a failed non-stream request leaves in `errorMessage`: dio's error as
/// the app's error interceptor hands it on, worded in the app's language.
String _nonStream(DioException error, Locale locale) {
  final container = ProviderContainer(
    overrides: [localeNotifierProvider.overrideWith(() => _Locale(locale))],
  );
  addTearDown(container.dispose);
  final handler = _Passed();
  container
      .read(Provider((ref) => ErrorInterceptor(ref)))
      .onError(error, handler);
  return handler.error!.toString();
}

/// The network failures each desktop OS actually reports.
final _networkFailures = <String, List<Object>>{
  'macOS': [
    const SocketException(
      'Connection refused',
      osError: OSError('Connection refused', 61),
    ),
    const SocketException(
      'Connection reset by peer',
      osError: OSError('Connection reset by peer', 54),
    ),
    const SocketException(
      'Operation timed out',
      osError: OSError('Operation timed out', 60),
    ),
  ],
  'Windows': [
    const SocketException(
      'The remote computer refused the network connection.',
      osError: OSError(
        'The remote computer refused the network connection.',
        1225,
      ),
    ),
    const SocketException(
      'An existing connection was forcibly closed by the remote host.',
      osError: OSError(
        'An existing connection was forcibly closed by the remote host.',
        10054,
      ),
    ),
    const SocketException('信号灯超时时间已到', osError: OSError('信号灯超时时间已到', 121)),
  ],
};

void main() {
  group('classifyGenerationFailure', () {
    test('client errors are not retried', () {
      for (final code in [400, 401, 402, 403, 404, 409, 413, 422]) {
        expect(
          classifyGenerationFailure(_status(code)),
          GenerationFailureKind.permanent,
          reason: 'HTTP $code (non-stream)',
        );
        expect(
          classifyGenerationFailure(_streamText(_status(code))),
          GenerationFailureKind.permanent,
          reason: 'HTTP $code (stream)',
        );
      }
    });

    test('5xx is retried', () {
      for (final code in [500, 502, 503, 504, 520]) {
        expect(
          classifyGenerationFailure(_status(code)),
          GenerationFailureKind.transient,
          reason: 'HTTP $code (non-stream)',
        );
        expect(
          classifyGenerationFailure(_streamText(_status(code))),
          GenerationFailureKind.transient,
          reason: 'HTTP $code (stream)',
        );
      }
    });

    test('429 waits for the concurrency slot', () {
      expect(
        classifyGenerationFailure(_status(429)),
        GenerationFailureKind.concurrencyLimited,
      );
      expect(
        classifyGenerationFailure(_streamText(_status(429))),
        GenerationFailureKind.concurrencyLimited,
      );
      expect(
        classifyGenerationFailure(
          'API_ERROR_429|A previous request is still being processed',
        ),
        GenerationFailureKind.concurrencyLimited,
      );
      expect(
        classifyGenerationFailure(
          const GenerationStreamError('API_ERROR_429|Too many requests'),
        ),
        GenerationFailureKind.concurrencyLimited,
      );
    });

    test('timeouts and lost connections are retried', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        expect(
          classifyGenerationFailure(_type(type)),
          GenerationFailureKind.transient,
          reason: '$type (non-stream)',
        );
        expect(
          classifyGenerationFailure(_streamText(_type(type))),
          GenerationFailureKind.transient,
          reason: '$type (stream)',
        );
      }
      expect(
        classifyGenerationFailure(_type(DioExceptionType.transformTimeout)),
        GenerationFailureKind.transient,
      );
      expect(
        classifyGenerationFailure(TimeoutException('no answer')),
        GenerationFailureKind.transient,
      );
      expect(
        classifyGenerationFailure(
          const HttpException('Connection closed while receiving data'),
        ),
        GenerationFailureKind.transient,
      );
    });

    test('a stream cut off mid-body is retried, as the service words it', () {
      // dio hands the socket read error to the stream as it is; the service
      // yields its text and the batch wraps it (GenerationStreamError).
      final stream = Uri.parse(
        'https://image.novelai.net/ai/generate-image-stream',
      );
      for (final failure in <Object>[
        HttpException('Connection closed while receiving data', uri: stream),
        const HandshakeException('Connection terminated during handshake'),
        TimeoutException('No stream event', const Duration(seconds: 30)),
      ]) {
        for (final text in [
          '$failure',
          'Exception: $failure',
          '${GenerationStreamError('$failure')}',
        ]) {
          expect(
            classifyGenerationFailure(text),
            GenerationFailureKind.transient,
            reason: text,
          );
        }
        expect(
          classifyGenerationFailure(GenerationStreamError('$failure')),
          GenerationFailureKind.transient,
          reason: 'stream error: $failure',
        );
      }
    });

    for (final platform in _networkFailures.keys) {
      test('$platform network errors are retried', () {
        debugDefaultTargetPlatformOverride = platform == 'macOS'
            ? TargetPlatform.macOS
            : TargetPlatform.windows;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        for (final failure in _networkFailures[platform]!) {
          expect(
            classifyGenerationFailure(failure),
            GenerationFailureKind.transient,
            reason: '$failure',
          );
          // The stream service passes a dropped body through as text.
          expect(
            classifyGenerationFailure(
              GenerationStreamError(failure.toString()),
            ),
            GenerationFailureKind.transient,
            reason: 'stream: $failure',
          );
          final wrapped = _type(DioExceptionType.unknown, error: failure);
          expect(
            classifyGenerationFailure(wrapped),
            GenerationFailureKind.transient,
            reason: 'dio: $failure',
          );
          expect(
            classifyGenerationFailure(_streamText(wrapped)),
            GenerationFailureKind.transient,
            reason: 'dio stream: $failure',
          );
        }
      });
    }

    test('a server error event in the stream, without a code, is retried', () {
      for (final message in [
        'Stream generation failed',
        'Internal error while sampling',
        'API_ERROR_UNKNOWN|Unknown error',
      ]) {
        expect(
          classifyGenerationFailure(
            GenerationStreamError(
              message,
              source: ImageStreamErrorSource.serverEvent,
            ),
          ),
          GenerationFailureKind.transient,
          reason: message,
        );
      }
    });

    test('a stream that ends without a final image is retried', () {
      expect(
        classifyGenerationFailure(
          const GenerationStreamError(
            'No final image received from stream',
            source: ImageStreamErrorSource.noFinalImage,
          ),
        ),
        GenerationFailureKind.transient,
      );
    });

    test('a server error event with a code goes by the code', () {
      GenerationFailureKind event(int code) => classifyGenerationFailure(
        GenerationStreamError(
          ApiErrorMapper.formatDioError(_status(code)),
          source: ImageStreamErrorSource.serverEvent,
        ),
      );
      for (final code in [400, 401, 402, 403, 404, 409]) {
        expect(event(code), GenerationFailureKind.permanent, reason: '$code');
      }
      expect(event(429), GenerationFailureKind.concurrencyLimited);
      for (final code in [500, 502, 503, 504]) {
        expect(event(code), GenerationFailureKind.transient, reason: '$code');
      }
      expect(
        stopsGenerationRun(
          const GenerationStreamError(
            'API_ERROR_402|Insufficient Anlas',
            source: ImageStreamErrorSource.serverEvent,
          ),
        ),
        isTrue,
      );
    });

    test('other stream errors still go by their text', () {
      for (final message in [
        'No final image received from stream',
        'Failed to parse response',
        'Stream generation failed',
      ]) {
        expect(
          classifyGenerationFailure(GenerationStreamError(message)),
          GenerationFailureKind.permanent,
          reason: message,
        );
      }
    });

    test('everything else fails at once', () {
      for (final failure in <Object>[
        _type(DioExceptionType.badCertificate),
        _type(DioExceptionType.unknown, error: const FormatException('x')),
        'API_ERROR_UNKNOWN|Unknown error',
        'Exception: No final image received from stream',
        'Exception: Failed to parse response',
        StateError('bad state'),
      ]) {
        expect(
          classifyGenerationFailure(failure),
          GenerationFailureKind.permanent,
          reason: '$failure',
        );
      }
    });
  });

  group('GenerationConcurrencyBackoff', () {
    test('backs off 3, 6, 12, 24, 30 s and stops after 90 s in all', () {
      final backoff = GenerationConcurrencyBackoff();
      final delays = <Duration>[];
      for (
        var delay = backoff.nextDelay();
        delay != null;
        delay = backoff.nextDelay()
      ) {
        delays.add(delay);
      }
      expect(delays, const [
        Duration(seconds: 3),
        Duration(seconds: 6),
        Duration(seconds: 12),
        Duration(seconds: 24),
        Duration(seconds: 30),
        Duration(seconds: 15),
      ]);
      expect(backoff.waited, const Duration(seconds: 90));
      expect(backoff.nextDelay(), isNull);
    });

    test('a single wait never exceeds 30 s', () {
      final backoff = GenerationConcurrencyBackoff();
      for (
        var delay = backoff.nextDelay();
        delay != null;
        delay = backoff.nextDelay()
      ) {
        expect(delay, lessThanOrEqualTo(const Duration(seconds: 30)));
      }
    });

    test('Retry-After is followed as given', () {
      final backoff = GenerationConcurrencyBackoff();
      expect(
        backoff.nextDelay(retryAfter: const Duration(seconds: 7)),
        const Duration(seconds: 7),
      );
      expect(
        backoff.nextDelay(retryAfter: const Duration(seconds: 45)),
        const Duration(seconds: 45),
      );
      expect(backoff.waited, const Duration(seconds: 52));
    });

    test('Retry-After of zero still waits a second', () {
      final backoff = GenerationConcurrencyBackoff();
      expect(
        backoff.nextDelay(retryAfter: Duration.zero),
        const Duration(seconds: 1),
      );
    });

    test('Retry-After past the remaining budget stops at once', () {
      final backoff = GenerationConcurrencyBackoff();
      expect(
        backoff.nextDelay(retryAfter: const Duration(seconds: 80)),
        const Duration(seconds: 80),
      );
      expect(
        backoff.nextDelay(retryAfter: const Duration(seconds: 11)),
        isNull,
      );
      expect(backoff.waited, const Duration(seconds: 80));
      expect(
        GenerationConcurrencyBackoff().nextDelay(
          retryAfter: const Duration(seconds: 120),
        ),
        isNull,
      );
    });

    test('the total never passes 90 s whatever the mix', () {
      final backoff = GenerationConcurrencyBackoff();
      var total = Duration.zero;
      for (var i = 0; i < 100; i++) {
        final delay = backoff.nextDelay(
          retryAfter: i.isEven ? const Duration(seconds: 2) : null,
        );
        if (delay == null) break;
        total += delay;
      }
      expect(total, lessThanOrEqualTo(const Duration(seconds: 90)));
      expect(total, backoff.waited);
    });

    test('a success starts the backoff over but keeps the spent budget', () {
      final backoff = GenerationConcurrencyBackoff()
        ..nextDelay()
        ..nextDelay();
      backoff.reset();
      expect(backoff.nextDelay(), const Duration(seconds: 3));
      expect(backoff.waited, const Duration(seconds: 12));
    });
  });

  group('generationRetryAfterOf', () {
    test('reads the header of a rejected request', () {
      expect(
        generationRetryAfterOf(
          _status(
            429,
            headers: {
              'retry-after': ['9'],
            },
          ),
        ),
        const Duration(seconds: 9),
      );
    });

    test('reads what the stream error carried', () {
      expect(
        generationRetryAfterOf(
          const GenerationStreamError(
            'API_ERROR_429|Too many requests',
            retryAfter: Duration(seconds: 4),
          ),
        ),
        const Duration(seconds: 4),
      );
    });

    test('other errors carry none', () {
      expect(generationRetryAfterOf(_status(429)), isNull);
      expect(generationRetryAfterOf('API_ERROR_429|x'), isNull);
    });
  });

  group('stopped run', () {
    test('Copy details text leaves out only the stop marker', () {
      for (final (message, copy) in [
        (
          generationConcurrencyStoppedError(
            const GenerationStreamError('API_ERROR_429|Concurrent generation'),
          ),
          'API_ERROR_429|Concurrent generation',
        ),
        (
          generationStatusStoppedError(_status(402)),
          'API_ERROR_402|Payment required',
        ),
        // What follows the marker stays as it is, wrapper and lines too.
        (
          generationStatusStoppedError('Exception: API_ERROR_400|bad\nmore'),
          'Exception: API_ERROR_400|bad\nmore',
        ),
        // Not stopped: as it is.
        (
          'Exception: API_ERROR_402|Payment required',
          'Exception: API_ERROR_402|Payment required',
        ),
        ('API_ERROR_429|busy', 'API_ERROR_429|busy'),
        ('', ''),
      ]) {
        expect(
          generationErrorWithoutStopMarker(message),
          copy,
          reason: message,
        );
      }
    });

    test('keeps the last error as detail', () {
      final stopped = generationConcurrencyStoppedError(
        const GenerationStreamError('API_ERROR_429|Concurrent generation'),
      );
      expect(isGenerationConcurrencyStopped(stopped), isTrue);
      expect(stopped, endsWith('API_ERROR_429|Concurrent generation'));
      expect(
        generationConcurrencyStoppedError(_status(429)),
        endsWith('API_ERROR_429|Too many requests'),
      );
    });

    test('is told apart from ordinary errors', () {
      expect(isGenerationConcurrencyStopped(null), isFalse);
      expect(isGenerationConcurrencyStopped('API_ERROR_429|busy'), isFalse);
      expect(isGenerationConcurrencyStopped('API_ERROR_402|x'), isFalse);
    });

    test('a stopped run is not mistaken for a fresh 429', () {
      expect(
        classifyGenerationFailure(
          generationConcurrencyStoppedError(_status(429)),
        ),
        GenerationFailureKind.permanent,
      );
    });

    test('the stream error reads like the plain exception did', () {
      expect(
        const GenerationStreamError(
          'API_ERROR_402|Payment required',
        ).toString(),
        Exception('API_ERROR_402|Payment required').toString(),
      );
    });
  });

  group('400, 401, 402, 403 and 404 stop the run', () {
    test('in both shapes', () {
      for (final code in [400, 401, 402, 403, 404]) {
        expect(
          stopsGenerationRun(_status(code)),
          isTrue,
          reason: 'HTTP $code (non-stream)',
        );
        expect(
          stopsGenerationRun(
            GenerationStreamError(ApiErrorMapper.formatDioError(_status(code))),
          ),
          isTrue,
          reason: 'HTTP $code (stream error)',
        );
        expect(
          stopsGenerationRun(_streamText(_status(code))),
          isTrue,
          reason: 'HTTP $code (stream text)',
        );
      }
    });

    test('a style explore lets 400 fail only that candidate', () {
      for (final failure in <Object>[
        _status(400),
        _streamText(_status(400)),
        GenerationStreamError(ApiErrorMapper.formatDioError(_status(400))),
      ]) {
        expect(
          stopsGenerationRun(failure, badRequestStopsRun: false),
          isFalse,
          reason: '$failure',
        );
      }
      for (final code in [401, 402, 403, 404]) {
        for (final failure in <Object>[
          _status(code),
          _streamText(_status(code)),
        ]) {
          expect(
            stopsGenerationRun(failure, badRequestStopsRun: false),
            isTrue,
            reason: '$failure',
          );
        }
      }
    });

    test('other failures leave the run going', () {
      for (final failure in <Object>[
        for (final code in [405, 409, 413, 422, 429, 500, 503]) ...[
          _status(code),
          _streamText(_status(code)),
        ],
        _type(DioExceptionType.connectionTimeout),
        _type(DioExceptionType.connectionError),
        'Exception: No final image received from stream',
        'API_ERROR_UNKNOWN|Unknown error',
        StateError('bad state'),
      ]) {
        expect(stopsGenerationRun(failure), isFalse, reason: '$failure');
      }
    });

    test('the status is read from either shape', () {
      expect(generationFailureStatus(_status(402)), 402);
      expect(generationFailureStatus(_streamText(_status(401))), 401);
      expect(generationFailureStatus(_streamText(_status(403))), 403);
      expect(
        generationFailureStatus(const GenerationStreamError('API_ERROR_402|x')),
        402,
      );
      expect(generationFailureStatus('API_ERROR_HTTP_504|Gateway'), 504);
      expect(
        generationFailureStatus(_type(DioExceptionType.sendTimeout)),
        null,
      );
      expect(generationFailureStatus('API_ERROR_NETWORK|down'), null);
      expect(generationFailureStatus('No final image received'), null);
    });

    test('the stop keeps the error, and which one it was', () {
      for (final code in [400, 401, 402, 403, 404]) {
        final streamed = ApiErrorMapper.formatDioError(_status(code));
        for (final error in <Object>[
          _status(code),
          GenerationStreamError(streamed),
        ]) {
          final stopped = generationStatusStoppedError(error);
          // 400 and 404 are no account trouble: the marker names the status.
          expect(stopped, startsWith('GENERATION_STATUS_STOPPED|'));
          expect(isGenerationStatusStopped(stopped), isTrue, reason: stopped);
          expect(isGenerationRunStopped(stopped), isTrue, reason: stopped);
          expect(isGenerationConcurrencyStopped(stopped), isFalse);
          expect(stopped, endsWith(streamed));
          expect(generationFailureStatus(stopped), code, reason: stopped);
        }
      }
    });

    test('a 429 stop is a stopped run as well', () {
      final stopped = generationConcurrencyStoppedError(_status(429));
      expect(isGenerationRunStopped(stopped), isTrue);
      expect(isGenerationStatusStopped(stopped), isFalse);
      expect(generationFailureStatus(stopped), 429);
    });

    test('ordinary errors are not stopped runs', () {
      for (final message in [
        null,
        'API_ERROR_402|Payment required',
        'Exception: API_ERROR_401|Unauthorized',
      ]) {
        expect(isGenerationRunStopped(message), isFalse, reason: message);
        expect(isGenerationStatusStopped(message), isFalse, reason: message);
      }
    });

    test('a stopped run is never retried', () {
      expect(
        classifyGenerationFailure(generationStatusStoppedError(_status(402))),
        GenerationFailureKind.permanent,
      );
    });
  });

  group('a non-stream failure kept as text', () {
    setUpAll(AppLoggerTestIsolation.setUp);
    tearDownAll(AppLoggerTestIsolation.tearDown);

    const statuses = [400, 401, 402, 403, 404, 409, 429, 500, 502, 503, 504];

    test('gives its status, whatever language it was worded in', () {
      for (final locale in AppLocalizations.supportedLocales) {
        for (final code in statuses) {
          final message = _nonStream(_rejectedBytes(code), locale);
          expect(message, startsWith('DioException [bad response]: '));
          expect(generationFailureStatus(message), code, reason: message);
          expect(
            generationFailureStatus('Exception: $message'),
            code,
            reason: message,
          );
          final stopped = generationStatusStoppedError(message);
          expect(generationFailureStatus(stopped), code, reason: stopped);
        }
      }
    });

    test('in dio\'s own wording too', () {
      for (final code in statuses) {
        final message = _rejectedBytes(code).toString();
        expect(message, contains('status code of $code'));
        expect(generationFailureStatus(message), code, reason: message);
      }
    });

    test('stops the run at 400 to 404 only', () {
      for (final locale in AppLocalizations.supportedLocales) {
        for (final code in statuses) {
          final message = _nonStream(_rejectedBytes(code), locale);
          expect(
            stopsGenerationRun(message),
            code >= 400 && code <= 404,
            reason: message,
          );
        }
      }
    });

    test('a network error or a timeout has no status', () {
      final options = RequestOptions(path: '/ai/generate-image');
      for (final locale in AppLocalizations.supportedLocales) {
        for (final error in [
          DioException.connectionError(
            requestOptions: options,
            reason: 'Connection refused',
          ),
          DioException.connectionTimeout(
            timeout: const Duration(seconds: 30),
            requestOptions: options,
          ),
          DioException.receiveTimeout(
            timeout: const Duration(seconds: 30),
            requestOptions: options,
          ),
        ]) {
          final message = _nonStream(error, locale);
          expect(generationFailureStatus(message), isNull, reason: message);
          expect(stopsGenerationRun(message), isFalse, reason: message);
        }
      }
    });
  });

  group('waitBeforeGenerationRetry', () {
    // testWidgets runs on a fake clock and fails a test that leaves a timer
    // pending, so a wait that keeps its timer after a cancel fails here.
    testWidgets('waits the whole delay when nothing cancels it', (
      tester,
    ) async {
      var done = false;
      unawaited(
        waitBeforeGenerationRetry(
          const Duration(seconds: 30),
          Completer<void>().future,
        ).then((_) => done = true),
      );
      await tester.pump(const Duration(seconds: 29, milliseconds: 999));
      expect(done, isFalse);
      await tester.pump(const Duration(milliseconds: 1));
      expect(done, isTrue);
    });

    testWidgets('a cancel ends it at once and lets go of its timer', (
      tester,
    ) async {
      final cancel = Completer<void>();
      var done = false;
      unawaited(
        waitBeforeGenerationRetry(
          const Duration(seconds: 30),
          cancel.future,
        ).then((_) => done = true),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(done, isFalse);
      cancel.complete();
      await tester.pump();
      expect(done, isTrue);
    });
  });
}
