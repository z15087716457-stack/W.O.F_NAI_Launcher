import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/network/nai_api_endpoint.dart';
import 'package:nai_launcher/core/storage/mac_credential_store.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/data/datasources/remote/nai_auth_api_service.dart';
import 'package:nai_launcher/data/models/auth/saved_account.dart';
import 'package:nai_launcher/presentation/providers/account_manager_provider.dart';
import 'package:nai_launcher/presentation/providers/auth_provider.dart';
import 'package:nai_launcher/presentation/router/app_router.dart';

class _Store extends Mock implements FlutterSecureStorage {}

class _Api extends NAIAuthApiService {
  _Api() : super(Dio());
  int calls = 0;
  @override
  Future<Map<String, dynamic>> validateToken(
    String token, {
    NaiApiEndpointConfig endpoint = NaiApiEndpointConfig.official,
    bool allowAnyTokenFormat = false,
    CancelToken? cancelToken,
  }) async {
    calls++;
    return {'tier': 3};
  }
}

class _Accounts extends AccountManagerNotifier {
  int saves = 0;
  int updates = 0;
  SavedAccount? existing;
  @override
  Future<void> updateAccountToken(String id, String token) async {
    expect(id, existing!.id);
    updates++;
  }

  bool lockedAccount = false;
  @override
  AccountManagerState build() => AccountManagerState(
    accounts: [if (existing case final account?) account],
  );
  @override
  Future<SavedAccount> addAccount({
    required String identifier,
    required String token,
    required String nickname,
    bool setAsDefault = false,
    AccountType accountType = AccountType.token,
    NaiApiEndpointConfig apiEndpoint = NaiApiEndpointConfig.official,
  }) async {
    if (lockedAccount) throw const LocalCredentialStoreException();
    saves++;
    return SavedAccount(
      id: 'fixture',
      email: identifier,
      nickname: nickname,
      createdAt: DateTime(2026),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const ch = MethodChannel('com.wof.naiStudio/local_credentials');
  const entered = 'pst-entered-fixture-123',
      previous = 'pst-previous-fixture-567';
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final code in ['local_credential_corrupt', 'local_credential_storage']) {
    test(
      'the native error $code gates credential reset on the normal login path',
      () async {
        SharedPreferences.setMockInitialValues({});
        final storage = SecureStorageService(
          storage: _Store(),
          macStore: const MacCredentialStore(),
        );
        var resets = 0;
        messenger.setMockMethodCallHandler(ch, (call) async {
          if (call.method == 'clear') return null;
          if (call.method == 'resetCorrupt') {
            resets++;
            return true;
          }
          throw PlatformException(code: code);
        });
        addTearDown(() => messenger.setMockMethodCallHandler(ch, null));
        await storage.clearAll();
        final container = ProviderContainer(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(storage),
            accountManagerNotifierProvider.overrideWith(_Accounts.new),
            naiAuthApiServiceProvider.overrideWithValue(_Api()),
          ],
        );
        addTearDown(container.dispose);
        final auth = container.read(authNotifierProvider.notifier);
        final recovery = code == 'local_credential_corrupt';
        for (
          var i = 0;
          i < 50 && container.read(authNotifierProvider).isLoading;
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        expect(
          container.read(authNotifierProvider).errorCode,
          recovery
              ? AuthErrorCode.credentialStorageCorrupt
              : AuthErrorCode.credentialStorageUnavailable,
        );
        expect(resets, 0);
        await auth.resetCorruptLocalCredentials();
        expect(resets, recovery ? 1 : 0);
        if (recovery) {
          expect(
            container.read(authNotifierProvider).status,
            AuthStatus.unauthenticated,
          );
        }
      },
      skip: Platform.environment['NAI_STUDIO_SANDBOX'] != null,
    );
  }
  for (final refusal in ['fresh', 'reenter', 'none', 'write', 'account']) {
    final denied = refusal == 'write' || refusal == 'account';
    test(
      'manual verified token validates once with refusal at $refusal',
      () async {
        SharedPreferences.setMockInitialValues(
          refusal == 'fresh' ? {} : {'auto_login': false},
        );
        final disk = _Store(), api = _Api(), accounts = _Accounts();
        accounts.lockedAccount = refusal == 'account';
        if (refusal == 'reenter') {
          accounts.existing = SavedAccount(
            id: 'old-local-id',
            email: 'fixture account',
            nickname: 'QA',
            createdAt: DateTime(2026),
          );
        }
        final storage = SecureStorageService(
          storage: disk,
          macStore: const MacCredentialStore(),
        );
        final stored = <String, String>{};
        messenger.setMockMethodCallHandler(ch, (call) async {
          if (call.method == 'clear') {
            stored.clear();
            return null;
          }
          final args = Map<Object?, Object?>.from(call.arguments as Map);
          if (call.method == 'read') return stored[args['key']];
          if (call.method != 'update') throw UnsupportedError(call.method);
          if (refusal == 'write') {
            throw PlatformException(code: 'local_credential_storage');
          }
          final changes = Map<String, String?>.from(args['changes'] as Map);
          final expected = args['expected'] as Map?;
          if (expected != null &&
              !expected.entries.every((e) => stored[e.key] == e.value)) {
            throw PlatformException(code: 'local_credential_storage');
          }
          final previous = <String, String?>{};
          for (final entry in changes.entries) {
            previous[entry.key] = stored[entry.key];
            if (entry.value == null) {
              stored.remove(entry.key);
            } else {
              stored[entry.key] = entry.value!;
            }
          }
          return previous;
        });
        await storage.clearAll();
        if (refusal != 'fresh') stored[StorageKeys.accessToken] = previous;
        final c = ProviderContainer(
          overrides: [
            secureStorageServiceProvider.overrideWithValue(storage),
            naiAuthApiServiceProvider.overrideWithValue(api),
            accountManagerNotifierProvider.overrideWith(() => accounts),
          ],
        );
        addTearDown(() async {
          c.dispose();
          await storage.clearAll();
          messenger.setMockMethodCallHandler(ch, null);
        });
        final auth = c.read(authNotifierProvider.notifier);
        for (var i = 0; i < 50 && c.read(authNotifierProvider).isLoading; i++) {
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        if (refusal == 'fresh') {
          expect(c.read(authNotifierProvider).isAuthenticated, isFalse);
          expect(stored, isEmpty);
          expect(api.calls, 0);
          verifyZeroInteractions(disk);
        }
        final originalRevision = storage.authRevision;
        final signedIn = await auth.signInWithEnteredToken(
          entered,
          nickname: 'QA',
          existingAccountId: accounts.existing?.id,
        );
        expect(signedIn, !denied);
        final state = c.read(authNotifierProvider);
        expect(api.calls, 1);
        expect(state.isAuthenticated, !denied);
        expect(accounts.saves, denied || refusal == 'reenter' ? 0 : 1);
        expect(accounts.updates, refusal == 'reenter' ? 1 : 0);
        verifyZeroInteractions(disk);
        if (denied) {
          expect(state.errorCode, AuthErrorCode.credentialStorageUnavailable);
          expect(state.accountId, isNull);
          expect(
            appAuthRedirect(
              authStatus: state.status,
              isAuthenticated: false,
              isGuest: false,
              matchedLocation: AppRoutes.home,
            ),
            AppRoutes.login,
          );
          expect(state.subscriptionInfo, isNull);
          expect(storage.authRevision, originalRevision);
          expect(stored, {StorageKeys.accessToken: previous});
          expect(await storage.getAccessToken(), isNot(entered));
          expect(
            (await SharedPreferences.getInstance()).getBool('auto_login'),
            false,
          );
        } else {
          expect(stored[StorageKeys.accessToken], entered);
          expect(await storage.getAccessToken(), entered);
          expect(state.accountId, accounts.existing?.id ?? 'fixture');
        }
      },
      skip: Platform.environment['NAI_STUDIO_SANDBOX'] != null
          ? 'This test exercises the normal-profile local-file channel.'
          : false,
    );
  }
}
