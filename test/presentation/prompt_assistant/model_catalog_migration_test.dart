import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_task_definitions.dart';

void main() {
  test('provider retry defaults apply only when no saved value exists', () {
    const fresh = ProviderConfig(
      id: 'retry-default',
      name: 'Retry default',
      baseUrl: 'https://example.test',
    );
    final legacy = fresh.toJson()..remove('retryAttempts');
    expect(fresh.retryAttempts, 1);
    expect(ProviderConfig.fromJson(legacy).retryAttempts, 1);
    for (final retries in [0, 1, 2, 3]) {
      final saved = fresh.copyWith(retryAttempts: retries);
      expect(ProviderConfig.fromJson(saved.toJson()).retryAttempts, retries);
    }
    for (final preset in ProviderPreset.values) {
      expect(preset.createConfig().retryAttempts, 1);
    }
  });

  test('old task and preset overrides cannot replace model request values', () {
    final old = {
      'schemaVersion': 3,
      'providers': [
        {
          'id': 'saved',
          'name': 'My endpoint',
          'baseUrl': 'https://example.test/custom/v1',
          'preset': 'openaiCompatibleResponses',
          'protocol': 'openaiResponses',
        },
      ],
      'models': [
        {
          'providerId': 'saved',
          'name': 'custom-model-id',
          'displayName': '我的模型',
          'temperature': .4,
          'maxOutputTokens': 8192,
          'source': 'manual',
        },
      ],
      'interfaces': {
        'translate': {
          'providerId': 'saved',
          'model': 'custom-model-id',
          'presetId': 'user:one',
          'targetLanguage': 'zh',
          'parameters': {'temperature': 1.5, 'maxOutputTokens': 20},
        },
      },
      'presets': [
        {
          'id': 'user:one',
          'name': '我的翻译',
          'task': 'translate',
          'prompt': '保留的提示词',
          'parameters': {'temperature': 1.7},
        },
      ],
    };
    final decoded = PromptAssistantConfigState.decode(jsonEncode(old));
    final selected = effectiveTaskModel(
      decoded,
      LauncherInterface.translate,
      decoded.models.single,
    );
    expect(selected.temperature, .4);
    expect(selected.maxOutputTokens, 8192);
    expect(decoded.presets.single.prompt, '保留的提示词');
    expect(
      decoded.interfaces[LauncherInterface.translate]!.presetId,
      'user:one',
    );
    final restored = PromptAssistantConfigState.decode(decoded.encode());
    expect(restored.providers.single.baseUrl, 'https://example.test/custom/v1');
    expect(
      restored.providers.single.protocol,
      ProviderProtocol.openaiResponses,
    );
    expect(
      restored.providers.single.preset,
      ProviderPreset.openaiCompatibleResponses,
    );
    expect(restored.models.single.name, 'custom-model-id');
    expect(restored.models.single.source, ModelSource.manual);
    expect(
      decoded.interfaces[LauncherInterface.translate]!.toJson(),
      isNot(contains('parameters')),
    );
    expect(decoded.presets.single.toJson(), isNot(contains('parameters')));
  });

  test(
    'unknown capabilities stay unknown and explicit false survives round trip',
    () {
      const unknown = ModelConfig(
        providerId: 'test',
        name: 'custom',
        displayName: 'Custom',
      );
      final decoded = ModelConfig.fromJson(unknown.toJson());
      expect(decoded.supportsVision, isNull);
      expect(decoded.supportsTools, isNull);
      final confirmed = decoded.copyWith(
        supportsVision: false,
        supportsTools: true,
        supportsStructuredOutput: false,
      );
      final restored = ModelConfig.fromJson(confirmed.toJson());
      expect(restored.supportsVision, isFalse);
      expect(restored.supportsTools, isTrue);
      expect(restored.supportsStructuredOutput, isFalse);
      expect(restored.copyWith(clearSupportsTools: true).supportsTools, isNull);
    },
  );

  test(
    'vendor menu has one entry per vendor while legacy protocols still decode',
    () {
      const menu = ProviderPresetDefaults.selectable;
      expect(menu.map((p) => p.vendor).toSet().length, menu.length);
      expect(menu.map((p) => p.label), isNot(contains('OpenAI Responses')));
      expect(
        menu.map((p) => p.label),
        isNot(contains('OpenAI Chat Completions')),
      );
      for (final legacy in [
        ProviderPreset.openaiChat,
        ProviderPreset.lmStudioResponses,
      ]) {
        final saved = legacy.createConfig().copyWith(
          baseUrl: 'http://localhost:9876/v1',
        );
        final restored = ProviderConfig.fromJson(saved.toJson());
        expect(restored.protocol, legacy.defaultProtocol);
        expect(restored.baseUrl, saved.baseUrl);
      }
    },
  );
}
