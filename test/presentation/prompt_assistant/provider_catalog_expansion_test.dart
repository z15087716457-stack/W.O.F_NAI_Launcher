import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_api_client.dart';

void main() {
  test(
    'expanded presets round-trip without changing saved connection choices',
    () {
      const menu = ProviderPresetDefaults.selectable;
      expect(menu.length, 40);
      expect(menu.first, ProviderPreset.openaiCompatibleChat);
      expect(menu.map((p) => p.defaultId).toSet().length, menu.length);
      for (final preset in ProviderPreset.values) {
        final saved = preset
            .createConfig(id: 'saved-${preset.name}')
            .copyWith(
              name: 'My service',
              baseUrl: 'https://relay.example/explicit/v1',
              protocol: ProviderProtocol.openaiResponses,
            );
        final restored = ProviderConfig.fromJson(saved.toJson());
        expect(restored.toJson(), saved.toJson());
      }
      for (final preset in menu.skip(1)) {
        expect(preset.isLocal, !preset.requiresApiKey);
        if (preset.index > ProviderPreset.openrouter.index) {
          expect(preset.defaultModelNames, isEmpty);
        }
      }
    },
  );

  test(
    'new presets discover only returned IDs through existing wire adapters',
    () async {
      final requests = <RequestOptions>[];
      final dio = Dio()
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) {
              requests.add(request);
              handler.resolve(
                Response(
                  requestOptions: request,
                  data: {
                    'data': [
                      {'id': 'account-visible-id'},
                    ],
                  },
                ),
              );
            },
          ),
        );
      addTearDown(dio.close);
      final api = PromptAssistantApiClient(dio: dio);
      for (final preset in ProviderPresetDefaults.selectable.where(
        (p) => p.index > ProviderPreset.openrouter.index,
      )) {
        final provider = preset.createConfig();
        final models = await api.fetchModels(
          provider: provider,
          apiKey: 'offline-test-key',
        );
        expect(models, ['account-visible-id']);
        final request = requests.last;
        expect(request.uri.host, Uri.parse(provider.baseUrl).host);
        expect(request.uri.path, endsWith('/models'));
        expect(request.uri.path, isNot(contains('/v1/v1/')));
        if (provider.protocol == ProviderProtocol.anthropicMessages) {
          expect(request.headers['x-api-key'], 'offline-test-key');
        } else {
          expect(request.headers['Authorization'], 'Bearer offline-test-key');
        }
        expect(request.uri.path, contains(Uri.parse(provider.baseUrl).path));
      }
      expect(requests.length, 20);
    },
  );

  test(
    'regional and plan presets resolve facts from their own catalog platform',
    () {
      final catalog = ModelCatalogRepository.decode(
        File('assets/data/model_catalog.json').readAsStringSync(),
      );
      for (final preset in [
        ProviderPreset.minimaxChinaChat,
        ProviderPreset.minimaxChinaMessages,
        ProviderPreset.minimaxInternationalMessages,
        ProviderPreset.zhipuCodingPlan,
        ProviderPreset.zaiCodingPlan,
        ProviderPreset.qwenTokenPlanChina,
        ProviderPreset.kimiCoding,
      ]) {
        final names = catalog.namesFor(preset);
        expect(names, isNotEmpty, reason: preset.name);
        final facts = catalog.lookup(preset, names.first)!;
        expect(facts.id, startsWith('${preset.catalogProviderKey}/'));
      }
    },
  );
}
