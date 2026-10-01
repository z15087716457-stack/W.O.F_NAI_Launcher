import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/network/nai_api_endpoint.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/data/datasources/remote/nai_auth_api_service.dart';
import 'package:nai_launcher/data/models/auth/saved_account.dart';
import 'package:nai_launcher/presentation/providers/account_manager_provider.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';

class _Accounts extends AccountManagerNotifier {
  String? token = 'old-fixture';
  @override
  AccountManagerState build() => AccountManagerState(
    accounts: [
      SavedAccount(id: 'account', email: 'fixture', createdAt: DateTime(2026)),
    ],
  );
  @override
  Future<String?> getAccountToken(String accountId) async => token;
  @override
  Future<void> updateAccountToken(String accountId, String newToken) async {
    token = newToken;
  }

  void remove() => state = const AccountManagerState();
}

class _Auth extends AuthNotifier {
  @override
  AuthState build() =>
      const AuthState(status: AuthStatus.authenticated, accountId: 'account');
  void switchSession() => state = const AuthState(
    status: AuthStatus.authenticated,
    accountId: 'other',
  );
}

class _Secure extends SecureStorageService {
  String token = 'old-global';
  @override
  Future<void> saveAccessToken(String value) async {
    token = value;
  }
}

class _Api extends NAIAuthApiService {
  _Api() : super(Dio());
  final response = Completer<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> validateToken(
    String token, {
    NaiApiEndpointConfig endpoint = NaiApiEndpointConfig.official,
    bool allowAnyTokenFormat = false,
  }) => response.future;
}

void main() {
  late _Accounts accounts;
  late _Auth auth;
  late _Secure secure;
  late _Api api;
  late ProviderContainer container;
  setUp(() {
    accounts = _Accounts();
    auth = _Auth();
    secure = _Secure();
    api = _Api();
    container = ProviderContainer(
      overrides: [
        accountManagerNotifierProvider.overrideWith(() => accounts),
        authNotifierProvider.overrideWith(() => auth),
        secureStorageServiceProvider.overrideWithValue(secure),
        naiAuthApiServiceProvider.overrideWithValue(api),
      ],
    );
    container.read(accountManagerNotifierProvider);
    container.read(authNotifierProvider);
  });
  tearDown(() => container.dispose());
  test(
    'valid replacement updates existing ID and active session without adding accounts',
    () async {
      final task = auth.replaceSavedAccountCredential('account', 'new-fixture');
      api.response.complete({'tier': 2});
      await task;
      expect(accounts.token, 'new-fixture');
      expect(secure.token, 'new-fixture');
      expect(
        container.read(accountManagerNotifierProvider).accounts.single.id,
        'account',
      );
      expect(container.read(authNotifierProvider).subscriptionInfo, {
        'tier': 2,
      });
    },
  );
  test('invalid credentials retain saved token and current session', () async {
    final before = container.read(authNotifierProvider);
    final task = auth.replaceSavedAccountCredential('account', 'new-fixture');
    await Future<void>.delayed(Duration.zero);
    api.response.completeError(StateError('invalid fixture'));
    await expectLater(task, throwsStateError);
    expect(accounts.token, 'old-fixture');
    expect(secure.token, 'old-global');
    expect(container.read(authNotifierProvider), same(before));
  });
  test(
    'late validation cannot overwrite a switched session or newer saved token',
    () async {
      final task = auth.replaceSavedAccountCredential('account', 'new-fixture');
      await Future<void>.delayed(Duration.zero);
      auth.switchSession();
      accounts.token = 'newer-fixture';
      api.response.complete({});
      await expectLater(task, throwsStateError);
      expect(accounts.token, 'newer-fixture');
      expect(secure.token, 'old-global');
    },
  );
  test('deleted target cannot be resurrected by late validation', () async {
    final task = auth.replaceSavedAccountCredential('account', 'new-fixture');
    await Future<void>.delayed(Duration.zero);
    accounts.remove();
    api.response.complete({});
    await expectLater(task, throwsStateError);
    expect(container.read(accountManagerNotifierProvider).accounts, isEmpty);
    expect(secure.token, 'old-global');
  });
}
