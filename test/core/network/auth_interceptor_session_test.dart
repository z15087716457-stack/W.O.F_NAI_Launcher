import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/network/dio_client.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/data/services/token_refresh_service.dart';

import '../../helpers/app_logger_test_isolation.dart';

class SessionStorage extends SecureStorageService {
  String? token = 'old.jwt.token';
  int revision = 0;
  @override
  int get authRevision => revision;
  @override
  Future<String?> getAccessToken() async => token;
  @override
  Future<void> saveAccessToken(String value) async {
    token = value;
    revision++;
  }
}

class SessionAuth extends AuthNotifier {
  int logouts = 0;
  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.authenticated, accountId: 'A');
  void publishB() =>
      state = const AuthState(status: AuthStatus.authenticated, accountId: 'B');
  @override
  Future<void> logout({AuthErrorCode? errorCode, int? httpStatusCode}) async {
    logouts++;
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

class Refresh extends TokenRefreshService {
  Refresh(this.run);
  final Future<bool> Function() run;
  int calls = 0;
  @override
  void build() {}
  @override
  Future<bool> refreshCurrentToken() {
    calls++;
    return run();
  }
}

class CapturedRequest extends RequestInterceptorHandler {
  final done = Completer<RequestOptions>();
  @override
  void next(RequestOptions options) => done.complete(options);
}

class CapturedError extends ErrorInterceptorHandler {
  final done = Completer<Object>();
  @override
  void next(DioException error) => done.complete(error);
  @override
  void resolve(Response response) => done.complete(response);
}

class LocalHttp extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late SessionStorage storage;
  late SessionAuth auth;
  late Refresh refresh;
  late ProviderContainer container;
  late AuthInterceptor interceptor;
  Future<bool> Function()? performRefresh;
  setUp(() {
    storage = SessionStorage();
    auth = SessionAuth();
    performRefresh = null;
    refresh = Refresh(() => performRefresh?.call() ?? Future.value(false));
    container = ProviderContainer(
      overrides: [
        secureStorageServiceProvider.overrideWithValue(storage),
        authNotifierProvider.overrideWith(() => auth),
        tokenRefreshServiceProvider.overrideWith(() => refresh),
      ],
    );
    interceptor = container.read(Provider((ref) => AuthInterceptor(ref)));
    container.read(authNotifierProvider);
  });
  tearDown(() => container.dispose());
  Future<RequestOptions> request(String url, {String? explicitToken}) {
    final options = RequestOptions(
      path: url,
      headers: {
        if (explicitToken != null) 'Authorization': 'Bearer $explicitToken',
      },
    );
    final handler = CapturedRequest();
    interceptor.onRequest(options, handler);
    return handler.done.future;
  }

  Future<Object> unauthorized(RequestOptions request) {
    final handler = CapturedError();
    interceptor.onError(
      DioException(
        requestOptions: request,
        response: Response(requestOptions: request, statusCode: 401),
      ),
      handler,
    );
    return handler.done.future;
  }

  for (final sameToken in [false, true]) {
    test(
      'old request cannot invalidate a newer session: sameToken=$sameToken',
      () async {
        final options = await request(
          'https://fixture.invalid/user/subscription',
        );
        await storage.saveAccessToken(
          sameToken ? 'old.jwt.token' : 'account-B-token',
        );
        if (!sameToken) {
          auth.publishB();
        }
        expect(await unauthorized(options), isA<DioException>());
        expect(auth.logouts, 0);
        expect(refresh.calls, 0);
      },
    );
  }
  test(
    'explicit credential validation does not manage the active session',
    () async {
      final options = await request(
        'https://fixture.invalid/user/subscription',
        explicitToken: 'invalid-candidate',
      );
      await unauthorized(options);
      expect(auth.logouts, 0);
      expect(refresh.calls, 0);
    },
  );
  test(
    'switch during failed refresh preserves the newly active account',
    () async {
      final gate = Completer<bool>(), arrived = Completer<void>();
      performRefresh = () {
        arrived.complete();
        return gate.future;
      };
      final options = await request(
        'https://fixture.invalid/user/subscription',
      );
      final outcome = unauthorized(options);
      await arrived.future;
      await storage.saveAccessToken('account-B-token');
      auth.publishB();
      gate.complete(false);
      await outcome;
      expect(auth.logouts, 0);
      expect(storage.token, 'account-B-token');
    },
  );
  test(
    'failed refresh of the unchanged current session logs out once',
    () async {
      final options = await request(
        'https://fixture.invalid/user/subscription',
      );
      await unauthorized(options);
      expect(refresh.calls, 1);
      expect(auth.logouts, 1);
    },
  );
  test('retry connection failure retains refreshed authentication', () async {
    await HttpOverrides.runWithHttpOverrides(() async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final url = 'http://127.0.0.1:${server.port}/user/subscription';
      await server.close(force: true);
      performRefresh = () async {
        await storage.saveAccessToken('new.jwt.token');
        return true;
      };
      final outcome = await unauthorized(await request(url));
      expect((outcome as DioException).response, isNull);
      expect(auth.logouts, 0);
      expect(storage.token, 'new.jwt.token');
    }, LocalHttp());
  });
  for (final status in [200, 401, 503]) {
    test(
      'refreshed retry handles HTTP $status without misclassifying auth',
      () async {
        await HttpOverrides.runWithHttpOverrides(() async {
          final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
          var hits = 0;
          final authorization = <String?>[];
          server.listen((req) async {
            hits++;
            authorization.add(req.headers.value('Authorization'));
            req.response.statusCode = status;
            req.response.headers.contentType = ContentType.json;
            req.response.write('{}');
            await req.response.close();
          });
          try {
            performRefresh = () async {
              await storage.saveAccessToken('new.jwt.token');
              return true;
            };
            final options = await request(
              'http://127.0.0.1:${server.port}/user/subscription',
            );
            final outcome = await unauthorized(options);
            expect(hits, 1);
            expect(authorization, ['Bearer new.jwt.token']);
            expect(auth.logouts, status == 401 ? 1 : 0);
            if (status == 200) {
              expect(outcome, isA<Response>());
            } else {
              expect((outcome as DioException).response?.statusCode, status);
            }
          } finally {
            await server.close(force: true);
          }
        }, LocalHttp());
      },
    );
  }
}
