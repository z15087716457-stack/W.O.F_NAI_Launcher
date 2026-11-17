import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/api_constants.dart';
import 'package:nai_launcher/core/network/nai_api_endpoint.dart';
import 'package:nai_launcher/core/network/nai_api_endpoint_service.dart';
import 'package:nai_launcher/data/datasources/remote/nai_auth_api_service.dart';
import 'package:nai_launcher/data/datasources/remote/nai_user_info_api_service.dart';
import 'package:nai_launcher/data/datasources/remote/nai_subscription_response.dart';

void main() {
  group('third-party native API discovery', () {
    final subscription = {
      'tier': 0,
      'active': false,
      'trainingStepsLeft': null,
    };
    ResponseBody jsonResponse(Object value, [int status = 200]) =>
        ResponseBody.fromString(
          jsonEncode(value),
          status,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
    ResponseBody consolePage() => ResponseBody.fromString(
      '<html><title>New API</title></html>',
      200,
      headers: {
        Headers.contentTypeHeader: ['text/html'],
      },
    );
    for (final prefix in ['/v1', '/v1/novelai']) {
      test(
        'root console resolves $prefix and retains both service paths',
        () async {
          final adapter = _RecordingDioAdapter(
            reply: (request) => request.uri.path == '$prefix/user/subscription'
                ? jsonResponse(subscription)
                : consolePage(),
          );
          final service = NAIAuthApiService(Dio()..httpClientAdapter = adapter);
          final result = await service.validateConnection(
            'sk-offline-fixture',
            allowAnyTokenFormat: true,
            endpoint: NaiApiEndpointConfig.fromInput(
              mainBaseUrl: 'https://gateway.invalid',
            ),
          );
          expect(result.endpoint.mainBaseUrl, 'https://gateway.invalid$prefix');
          expect(result.endpoint.imageBaseUrl, result.endpoint.mainBaseUrl);
          expect(
            result.endpoint.imageUrl(ApiConstants.generateImageEndpoint),
            'https://gateway.invalid$prefix/ai/generate-image',
          );
          expect(
            result.endpoint.imageUrl(ApiConstants.generateImageStreamEndpoint),
            'https://gateway.invalid$prefix/ai/generate-image-stream',
          );
          expect(result.subscription['trainingStepsLeft'], isNull);
          expect(result.subscription['usesExternalBilling'], isTrue);
          expect(
            adapter.requests.every(
              (r) =>
                  r.method == 'GET' &&
                  r.uri.host == 'gateway.invalid' &&
                  r.headers['Authorization'] == 'Bearer sk-offline-fixture',
            ),
            isTrue,
          );
        },
      );
    }
    test(
      'v1 input can resolve nested native prefix without duplicating v1',
      () async {
        final adapter = _RecordingDioAdapter(
          reply: (r) => r.uri.path == '/v1/user/subscription'
              ? jsonResponse({'error': 'unknown route'}, 404)
              : jsonResponse(subscription),
        );
        final result =
            await NAIAuthApiService(
              Dio()..httpClientAdapter = adapter,
            ).validateConnection(
              'fixture',
              allowAnyTokenFormat: true,
              endpoint: NaiApiEndpointConfig.fromInput(
                mainBaseUrl: 'https://gateway.invalid/v1',
              ),
            );
        expect(
          result.endpoint.mainBaseUrl,
          'https://gateway.invalid/v1/novelai',
        );
        expect(adapter.requests, hasLength(2));
      },
    );
    test(
      'separate image base is preserved when account prefix resolves',
      () async {
        final adapter = _RecordingDioAdapter(
          reply: (r) => r.uri.path == '/user/subscription'
              ? consolePage()
              : jsonResponse(subscription),
        );
        final result =
            await NAIAuthApiService(
              Dio()..httpClientAdapter = adapter,
            ).validateConnection(
              'fixture',
              allowAnyTokenFormat: true,
              endpoint: NaiApiEndpointConfig.fromInput(
                mainBaseUrl: 'https://gateway.invalid',
                imageBaseUrl: 'https://images.invalid/native',
              ),
            );
        expect(result.endpoint.imageBaseUrl, 'https://images.invalid/native');
      },
    );
    for (final status in [401, 403, 429, 500]) {
      test(
        'HTTP $status stops discovery without masking the failure',
        () async {
          final adapter = _RecordingDioAdapter(
            reply: (_) => jsonResponse({'error': 'denied'}, status),
          );
          await expectLater(
            NAIAuthApiService(
              Dio()..httpClientAdapter = adapter,
            ).validateConnection(
              'fixture',
              allowAnyTokenFormat: true,
              endpoint: NaiApiEndpointConfig.fromInput(
                mainBaseUrl: 'https://gateway.invalid',
              ),
            ),
            throwsA(
              isA<DioException>().having(
                (e) => e.response?.statusCode,
                'status',
                status,
              ),
            ),
          );
          expect(adapter.requests, hasLength(1));
        },
      );
    }
    for (final body in ['console', 'empty json', 'wrong schema', 'not found']) {
      test(
        '$body is an incompatible API, not an authenticated session',
        () async {
          final adapter = _RecordingDioAdapter(
            reply: (_) => switch (body) {
              'console' => consolePage(),
              'empty json' => jsonResponse({}),
              'wrong schema' => jsonResponse({'tier': '3', 'active': true}),
              _ => jsonResponse({'error': 'not found'}, 404),
            },
          );
          await expectLater(
            NAIAuthApiService(
              Dio()..httpClientAdapter = adapter,
            ).validateConnection(
              'fixture',
              allowAnyTokenFormat: true,
              endpoint: NaiApiEndpointConfig.fromInput(
                mainBaseUrl: 'https://gateway.invalid',
              ),
            ),
            throwsA(isA<NaiApiCompatibilityException>()),
          );
          expect(adapter.requests, hasLength(3));
        },
      );
    }
    test('explicit custom path is checked once and not rewritten', () async {
      final adapter = _RecordingDioAdapter(reply: (_) => consolePage());
      await expectLater(
        NAIAuthApiService(
          Dio()..httpClientAdapter = adapter,
        ).validateConnection(
          'fixture',
          allowAnyTokenFormat: true,
          endpoint: NaiApiEndpointConfig.fromInput(
            mainBaseUrl: 'https://gateway.invalid/custom',
          ),
        ),
        throwsA(isA<NaiApiCompatibilityException>()),
      );
      expect(adapter.requests, hasLength(1));
    });
    test('refresh retains external billing and rejects console HTML', () async {
      final adapter = _RecordingDioAdapter(
        reply: (_) => jsonResponse(subscription),
      );
      final endpoints = NaiApiEndpointService()
        ..setCurrent(
          NaiApiEndpointConfig.fromInput(
            mainBaseUrl: 'https://gateway.invalid/v1',
          ),
        );
      final service = NAIUserInfoApiService(
        Dio()..httpClientAdapter = adapter,
        endpoints,
      );
      expect(
        (await service.getUserSubscription())['usesExternalBilling'],
        isTrue,
      );
      final html = _RecordingDioAdapter(reply: (_) => consolePage());
      await expectLater(
        NAIUserInfoApiService(
          Dio()..httpClientAdapter = html,
          endpoints,
        ).getUserSubscription(),
        throwsA(isA<NaiApiCompatibilityException>()),
      );
    });
  });

  group('NAI user endpoint routing', () {
    test('validateToken uses the official image user endpoint', () async {
      final adapter = _RecordingDioAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final service = NAIAuthApiService(dio);

      final result = await service.validateToken(
        'pst-validTokenForEndpointRouting',
        endpoint: NaiApiEndpointConfig.official,
      );

      expect(result['tier'], 3);
      expect(adapter.requests, hasLength(1));
      expect(
        adapter.requests.single.uri.toString(),
        '${ApiConstants.imageBaseUrl}${ApiConstants.userSubscriptionEndpoint}',
      );
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer pst-validTokenForEndpointRouting',
      );
    });

    test(
      'validateToken keeps third-party user endpoints on main host',
      () async {
        final adapter = _RecordingDioAdapter();
        final dio = Dio()..httpClientAdapter = adapter;
        final service = NAIAuthApiService(dio);
        final endpoint = NaiApiEndpointConfig.fromInput(
          mainBaseUrl: 'https://compatible.example',
          imageBaseUrl: 'https://images.compatible.example',
        );

        await service.validateToken(
          'compatible-token',
          endpoint: endpoint,
          allowAnyTokenFormat: true,
        );

        expect(
          adapter.requests.single.uri.toString(),
          'https://compatible.example${ApiConstants.userSubscriptionEndpoint}',
        );
        expect(
          adapter.requests.single.headers['Authorization'],
          'Bearer compatible-token',
        );
      },
    );

    test('getUserSubscription uses the current official image host', () async {
      final adapter = _RecordingDioAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final endpointService = NaiApiEndpointService();
      final service = NAIUserInfoApiService(dio, endpointService);

      await service.getUserSubscription();

      expect(
        adapter.requests.single.uri.toString(),
        '${ApiConstants.imageBaseUrl}${ApiConstants.userSubscriptionEndpoint}',
      );
    });

    test('routes official login requests through the image host', () async {
      final adapter = _RecordingDioAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final service = NAIAuthApiService(dio);

      final result = await service.loginWithKey(
        'access-key',
        endpoint: NaiApiEndpointConfig.official,
      );

      expect(result['accessToken'], 'jwt-token');
      expect(adapter.requests, hasLength(1));
      expect(
        adapter.requests.single.uri.toString(),
        '${ApiConstants.imageBaseUrl}${ApiConstants.loginEndpoint}',
      );
    });

    test('keeps third-party login requests on the main host', () async {
      final adapter = _RecordingDioAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      final service = NAIAuthApiService(dio);
      final endpoint = NaiApiEndpointConfig.fromInput(
        mainBaseUrl: 'https://compatible.example',
        imageBaseUrl: 'https://images.compatible.example',
      );

      await service.loginWithKey('access-key', endpoint: endpoint);

      expect(
        adapter.requests.single.uri.toString(),
        'https://compatible.example${ApiConstants.loginEndpoint}',
      );
    });
  });
}

class _RecordingDioAdapter implements HttpClientAdapter {
  _RecordingDioAdapter({this.reply});
  final ResponseBody Function(RequestOptions)? reply;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (reply case final respond?) return respond(options);

    final response = options.path.endsWith(ApiConstants.loginEndpoint)
        ? {'accessToken': 'jwt-token'}
        : {
            'tier': 3,
            'active': true,
            'trainingStepsLeft': {
              'fixedTrainingStepsLeft': 100,
              'purchasedTrainingSteps': 20,
            },
          };

    return ResponseBody.fromString(
      jsonEncode(response),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
