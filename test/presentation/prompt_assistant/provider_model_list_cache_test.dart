import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_model_list_cache.dart';

import '../screens/settings/model_management_section_test.dart' as harness;

class _FailingSettings extends harness.MemorySettings {
  bool fail = true;

  @override
  Future<void> setSetting<T>(String key, T value) async {
    if (fail) {
      fail = false;
      throw StateError('offline write failure');
    }
    await super.setSetting(key, value);
  }
}

void main() {
  final provider = harness.sampleConfig.providers.first;
  const key = 'synthetic-secret-key';
  const headers = {'X-Test': 'synthetic-private-header'};
  final connection = ProviderModelListCache.fingerprint(provider, key, headers);

  test(
    'full discovery survives recreation without storing connection secrets',
    () async {
      final storage = harness.MemorySettings();
      final cache = ProviderModelListCache(storage);
      expect(cache.modelsFor(provider.id, connection), isNull);
      expect(
        await cache.save(provider.id, connection, [
          'selected',
          'unselected',
          ' selected ',
          '',
        ]),
        isTrue,
      );
      final recreated = ProviderModelListCache(storage);
      expect(recreated.modelsFor(provider.id, connection), [
        'selected',
        'unselected',
      ]);
      final raw =
          storage.values[StorageKeys.providerModelListCacheV1] as String;
      for (final secret in [key, headers.values.single, provider.baseUrl]) {
        expect(raw, isNot(contains(secret)));
      }
      expect(recreated.modelsFor(provider.id, 'other-connection'), isNull);
      expect(await recreated.save(provider.id, connection, []), isTrue);
      expect(recreated.modelsFor(provider.id, connection), isEmpty);
      await recreated.remove(provider.id);
      expect(recreated.modelsFor(provider.id, connection), isNull);
    },
  );

  test(
    'connection digest distinguishes route, protocol, vendor, auth and headers',
    () {
      expect(
        ProviderModelListCache.fingerprint(
          provider.copyWith(baseUrl: '${provider.baseUrl}/'),
          ' $key ',
          headers,
        ),
        connection,
      );
      expect(
        ProviderModelListCache.fingerprint(provider, key, {'B': '2', 'A': '1'}),
        ProviderModelListCache.fingerprint(provider, key, {'A': '1', 'B': '2'}),
      );
      for (final changed in [
        ProviderModelListCache.fingerprint(
          provider.copyWith(baseUrl: 'https://offline.test/v1'),
          key,
          headers,
        ),
        ProviderModelListCache.fingerprint(
          provider.copyWith(protocol: ProviderProtocol.openaiResponses),
          key,
          headers,
        ),
        ProviderModelListCache.fingerprint(
          provider.copyWith(preset: ProviderPreset.mistral),
          key,
          headers,
        ),
        ProviderModelListCache.fingerprint(provider, 'different-key', headers),
        ProviderModelListCache.fingerprint(provider, key, {
          'X-Test': 'different-value',
        }),
      ]) {
        expect(changed, isNot(connection));
      }
    },
  );

  test('malformed and incompatible cache records are ignored', () {
    final storage = harness.MemorySettings();
    final cache = ProviderModelListCache(storage);
    for (final raw in [
      'broken',
      jsonEncode({'version': 2, 'providers': {}}),
      jsonEncode({
        'version': 1,
        'providers': {
          provider.id: {
            'connection': connection,
            'models': ['ok', 1],
          },
        },
      }),
      jsonEncode({
        'version': 1,
        'providers': {
          provider.id: {
            'connection': connection,
            'models': [''],
          },
        },
      }),
    ]) {
      storage.values[StorageKeys.providerModelListCacheV1] = raw;
      expect(cache.modelsFor(provider.id, connection), isNull);
    }
  });

  test(
    'queued writes retain independent services and recover from storage failure',
    () async {
      final storage = _FailingSettings();
      final cache = ProviderModelListCache(storage);
      expect(await cache.save('failed', connection, ['old']), isFalse);
      expect(
        await Future.wait([
          cache.save('a', connection, ['first']),
          cache.save('b', connection, ['second']),
          cache.save('a', connection, ['updated']),
        ]),
        [true, true, true],
      );
      expect(cache.modelsFor('a', connection), ['updated']);
      expect(cache.modelsFor('b', connection), ['second']);
      expect(cache.modelsFor('failed', connection), isNull);
    },
  );
}
