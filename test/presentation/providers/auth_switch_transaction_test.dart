import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/network/nai_api_endpoint.dart';
import 'package:nai_launcher/core/network/nai_api_endpoint_service.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/data/datasources/remote/nai_auth_api_service.dart';
import 'package:nai_launcher/data/models/auth/saved_account.dart';
import 'package:nai_launcher/presentation/providers/account_manager_provider.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/app_logger_test_isolation.dart';

const tokenA = 'pst-offline-fixture-A';
const tokenB = 'pst-offline-fixture-B';
const tokenC = 'pst-offline-fixture-C';
const customEndpoint = NaiApiEndpointConfig(
  mainBaseUrl: 'https://fixture.invalid',
  imageBaseUrl: 'https://fixture.invalid',
);

class _Disk extends Mock implements FlutterSecureStorage {}

class _Accounts extends AccountManagerNotifier {
  bool custom = false;
  @override
  AccountManagerState build() => AccountManagerState(
    accounts: [
      for (final id in ['A', 'B'])
        SavedAccount(id: id, email: '$id fixture', createdAt: DateTime(2026)),
    ],
  );
  @override
  NaiApiEndpointConfig getAccountApiEndpoint(String id) =>
      custom && id == 'A' ? customEndpoint : NaiApiEndpointConfig.official;
  @override
  Future<void> updateLastUsed(String id) async {}
  @override
  Future<String?> getAccountToken(String id) async =>
      id == 'A' ? tokenA : tokenB;
}

class _Api extends NAIAuthApiService {
  _Api() : super(Dio());
  final response = Completer<Map<String, dynamic>>();
  final started = Completer<void>();
  bool holdAutomatic = false;
  final automaticStarted = Completer<void>();
  final automaticResponse = Completer<Map<String, dynamic>>();
  NaiApiEndpointConfig? requestedEndpoint;
  @override
  Future<Map<String, dynamic>> validateToken(
    String token, {
    NaiApiEndpointConfig endpoint = NaiApiEndpointConfig.official,
    bool allowAnyTokenFormat = false,
  }) async {
    if (token == tokenA) {
      if (holdAutomatic) {
        automaticStarted.complete();
        return automaticResponse.future;
      }
      return {'tier': 2};
    }
    if (token == tokenC) return {'tier': 3};
    requestedEndpoint = endpoint;
    started.complete();
    return response.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(AppLoggerTestIsolation.setUp);
  tearDownAll(AppLoggerTestIsolation.tearDown);
  late SecureStorageService storage;
  late ProviderContainer container;
  late AuthNotifier auth;
  late _Api api;
  late _Accounts accounts;
  var disposed = false;
  setUp(() async {
    disposed = false;
    SharedPreferences.setMockInitialValues({'auto_login': false});
    final disk = _Disk();
    final values = <String, String?>{};
    when(
      () => disk.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((call) async {
      values[call.namedArguments[#key] as String] =
          call.namedArguments[#value] as String?;
    });
    when(
      () => disk.read(key: any(named: 'key')),
    ).thenAnswer((call) async => values[call.namedArguments[#key]]);
    when(() => disk.delete(key: any(named: 'key'))).thenAnswer((call) async {
      values.remove(call.namedArguments[#key]);
    });
    when(disk.deleteAll).thenAnswer((_) async {
      values.clear();
    });
    storage = SecureStorageService(storage: disk);
    await storage.clearAll();
    api = _Api();
    accounts = _Accounts();
    container = ProviderContainer(
      overrides: [
        secureStorageServiceProvider.overrideWithValue(storage),
        naiAuthApiServiceProvider.overrideWithValue(api),
        accountManagerNotifierProvider.overrideWith(() => accounts),
      ],
    );
    auth = container.read(authNotifierProvider.notifier);
    final ready = Completer<void>();
    final sub = container.listen(authNotifierProvider, (_, state) {
      if (state.status == AuthStatus.unauthenticated && !ready.isCompleted) {
        ready.complete();
      }
    }, fireImmediately: true);
    await ready.future.timeout(const Duration(seconds: 2));
    sub.close();
  });
  tearDown(() async {
    if (!disposed) container.dispose();
    await storage.clearAll();
  });
  Future<void> loginA(bool custom) async {
    accounts.custom = custom;
    expect(
      await auth.switchAccount(
        'A',
        tokenA,
        displayName: 'A fixture',
        accountType: AccountType.token,
      ),
      isTrue,
    );
  }

  for (final custom in [false, true]) {
    for (final status in [null, 401, 503]) {
      test(
        'failed official token switch retains A credentials and endpoint; custom=$custom status=$status',
        () async {
          await loginA(custom);
          final endpoint = container
              .read(naiApiEndpointServiceProvider)
              .current;
          final revision = storage.authRevision;
          final operation = auth.switchAccount(
            'B',
            tokenB,
            displayName: 'B fixture',
            accountType: AccountType.token,
          );
          await api.started.future;
          final duringToken = await storage.getAccessToken();
          final duringEndpoint = container
              .read(naiApiEndpointServiceProvider)
              .current;
          final request = RequestOptions(path: '/offline-fixture');
          api.response.completeError(
            DioException(
              requestOptions: request,
              type: status == null
                  ? DioExceptionType.connectionError
                  : DioExceptionType.badResponse,
              response: status == null
                  ? null
                  : Response(requestOptions: request, statusCode: status),
            ),
          );
          expect(await operation, isFalse);
          expect(duringToken, tokenA);
          expect(duringEndpoint, endpoint);
          expect(await storage.getAccessToken(), tokenA);
          expect(storage.authRevision, revision);
          expect(
            container.read(naiApiEndpointServiceProvider).current,
            endpoint,
          );
          final state = container.read(authNotifierProvider);
          expect(state.isAuthenticated, isTrue);
          expect(state.accountId, 'A');
          expect(state.subscriptionInfo, {'tier': 2});
          expect(state.errorCode, isNotNull);
          expect(api.requestedEndpoint, NaiApiEndpointConfig.official);
        },
      );
    }
    test(
      'successful switch commits credentials and endpoint after validation; custom=$custom',
      () async {
        await loginA(custom);
        final previousEndpoint = container
            .read(naiApiEndpointServiceProvider)
            .current;
        final operation = auth.switchAccount(
          'B',
          tokenB,
          displayName: 'B fixture',
          accountType: AccountType.token,
        );
        await api.started.future;
        final duringToken = await storage.getAccessToken();
        final duringEndpoint = container
            .read(naiApiEndpointServiceProvider)
            .current;
        api.response.complete({'tier': 3});
        expect(await operation, isTrue);
        expect(duringToken, tokenA);
        expect(duringEndpoint, previousEndpoint);
        expect(await storage.getAccessToken(), tokenB);
        expect(
          container.read(naiApiEndpointServiceProvider).current,
          NaiApiEndpointConfig.official,
        );
        expect(container.read(authNotifierProvider).accountId, 'B');
      },
    );
  }
  for (final branch in ['pst', 'credentials', 'third-party']) {
    for (final failure in [false, true]) {
      test(
        'late $branch validation cannot replace newer C, failure=$failure',
        () async {
          await loginA(false);
          final old = branch == 'third-party'
              ? auth.loginWithThirdPartyToken(
                  tokenB,
                  apiEndpoint: customEndpoint,
                  accountId: 'B',
                )
              : auth.switchAccount(
                  'B',
                  tokenB,
                  accountType: branch == 'credentials'
                      ? AccountType.credentials
                      : AccountType.token,
                );
          await api.started.future;
          expect(
            await auth.loginWithThirdPartyToken(
              tokenC,
              apiEndpoint: customEndpoint,
              accountId: 'C',
            ),
            isTrue,
          );
          final revision = storage.authRevision;
          if (failure) {
            api.response.completeError(StateError('late rejected fixture'));
          } else {
            api.response.complete({'tier': 1});
          }
          expect(await old, isFalse);
          expect(await storage.getAccessToken(), tokenC);
          expect(storage.authRevision, revision);
          expect(container.read(authNotifierProvider).accountId, 'C');
          expect(container.read(authNotifierProvider).subscriptionInfo, {
            'tier': 3,
          });
          expect(
            container.read(naiApiEndpointServiceProvider).current,
            customEndpoint,
          );
        },
      );
    }
  }
  test('logout cancels a pending validation instead of restoring it', () async {
    await loginA(false);
    final operation = auth.switchAccount(
      'B',
      tokenB,
      accountType: AccountType.token,
    );
    await api.started.future;
    await auth.logout();
    api.response.complete({'tier': 3});
    expect(await operation, isFalse);
    expect(await storage.getAccessToken(), isNull);
    expect(container.read(authNotifierProvider).isAuthenticated, isFalse);
  });
  test('logout also cancels a delayed automatic retry', () async {
    await loginA(false);
    await auth.logout();
    final retry = auth.retryAutoLogin();
    await auth.logout();
    await retry;
    expect(await storage.getAccessToken(), isNull);
    expect(container.read(authNotifierProvider).isAuthenticated, isFalse);
  });
  test(
    'a newer failed switch restores A and cancels the older pending switch',
    () async {
      await loginA(false);
      final old = auth.switchAccount(
        'B',
        tokenB,
        accountType: AccountType.token,
      );
      await api.started.future;
      expect(
        await auth.loginWithToken('invalid fixture', accountId: 'C'),
        isFalse,
      );
      api.response.complete({'tier': 1});
      expect(await old, isFalse);
      expect(await storage.getAccessToken(), tokenA);
      expect(container.read(authNotifierProvider).isAuthenticated, isTrue);
      expect(container.read(authNotifierProvider).accountId, 'A');
    },
  );
  test('disposed notifier cannot commit a late validation', () async {
    await loginA(false);
    final old = auth.switchAccount('B', tokenB, accountType: AccountType.token);
    await api.started.future;
    final revision = storage.authRevision;
    container.dispose();
    disposed = true;
    api.response.complete({'tier': 1});
    expect(await old, isFalse);
    expect(await storage.getAccessToken(), tokenA);
    expect(storage.authRevision, revision);
  });
  for (final failure in [false, true]) {
    test(
      'late startup auto-login cannot replace a manual session, failure=$failure',
      () async {
        container.dispose();
        SharedPreferences.setMockInitialValues({'auto_login': true});
        await storage.saveAuth(
          accessToken: tokenA,
          expiry: DateTime(2030),
          email: 'A fixture',
        );
        api.holdAutomatic = true;
        container = ProviderContainer(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(storage),
            naiAuthApiServiceProvider.overrideWithValue(api),
            accountManagerNotifierProvider.overrideWith(() => accounts),
          ],
        );
        auth = container.read(authNotifierProvider.notifier);
        await api.automaticStarted.future;
        expect(
          await auth.loginWithThirdPartyToken(
            tokenC,
            apiEndpoint: customEndpoint,
            accountId: 'C',
          ),
          isTrue,
        );
        if (failure) {
          api.automaticResponse.completeError(
            StateError('late automatic failure'),
          );
        } else {
          api.automaticResponse.complete({'tier': 1});
        }
        await Future<void>.delayed(Duration.zero);
        expect(await storage.getAccessToken(), tokenC);
        expect(container.read(authNotifierProvider).accountId, 'C');
        expect(
          container.read(naiApiEndpointServiceProvider).current,
          customEndpoint,
        );
      },
    );
  }
  test('invalid token syntax keeps the existing session untouched', () async {
    await loginA(true);
    final revision = storage.authRevision;
    expect(
      await auth.loginWithToken('invalid fixture', accountId: 'B'),
      isFalse,
    );
    expect(await storage.getAccessToken(), tokenA);
    expect(storage.authRevision, revision);
    expect(
      container.read(naiApiEndpointServiceProvider).current,
      customEndpoint,
    );
    expect(api.started.isCompleted, isFalse);
  });
}
