import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/storage/mac_credential_store.dart';
import 'package:nai_launcher/core/storage/sandbox_credential_store.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';

class _Platform extends Mock implements FlutterSecureStorage {}

class _Vault extends MacCredentialStore {
  final entries = <String, String>{};
  @override
  Future<String?> read(String key) async => entries[key];
  @override
  Future<Map<String, String?>> update(
    Map<String, String?> changes, {
    Map<String, String?>? expected,
  }) async {
    final prior = <String, String?>{
      for (final key in changes.keys) key: entries[key],
    };
    for (final change in changes.entries) {
      if (change.value == null) {
        entries.remove(change.key);
      } else {
        entries[change.key] = change.value!;
      }
    }
    return prior;
  }

  @override
  Future<void> clear() async => entries.clear();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'every Mac credential family uses local storage including bulk deletion',
    () async {
      final platform = _Platform(), vault = _Vault();
      final service = SecureStorageService(storage: platform, macStore: vault);
      await service.clearAll();
      await service.savePromptAssistantApiKey('llm', 'fixture-llm');
      await service.savePromptAssistantHeaders('llm', 'fixture-headers');
      await service.saveDanbooruCredentials('fixture-danbooru');
      await service.saveGelbooruCredentials('fixture-gelbooru');
      await service.saveAgentMcpConfig('server', 'fixture-agent');
      await service.saveAccountToken('account', 'fixture-account-token');
      await service.saveAccountAccessKey('account', 'fixture-access-key');
      await service.saveAuth(
        accessToken: 'fixture-current',
        expiry: DateTime(2035),
        email: 'fixture-mail',
      );
      expect(
        vault.entries.values,
        containsAll([
          'fixture-llm',
          'fixture-headers',
          'fixture-danbooru',
          'fixture-gelbooru',
          'fixture-agent',
          'fixture-account-token',
          'fixture-access-key',
          'fixture-current',
          'fixture-mail',
        ]),
      );
      await service.clearAuth();
      expect(vault.entries.values, isNot(contains('fixture-current')));
      expect(vault.entries.values, contains('fixture-account-token'));
      await service.clearAll();
      expect(vault.entries, isEmpty);
      verifyZeroInteractions(platform);
    },
    skip: Platform.environment['NAI_STUDIO_SANDBOX'] != null
        ? 'Normal-profile adapter test.'
        : false,
  );
  test(
    'an isolated Mac profile stays in memory and does not touch either real store',
    () async {
      final platform = _Platform(), vault = _Vault();
      final isolated = SandboxCredentialStore(
        sandbox: 'unique-test-profile',
        storage: platform,
        macStore: vault,
      );
      await isolated.write(key: 'fixture', value: 'isolated');
      expect(await isolated.read(key: 'fixture'), 'isolated');
      await isolated.deleteAll();
      expect(vault.entries, isEmpty);
      verifyZeroInteractions(platform);
    },
  );
}
