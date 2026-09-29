import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';

void main() {
  const provider = ProviderConfig(
    id: 'custom',
    name: '自定义服务商',
    baseUrl: 'https://example.test/v1',
  );
  const model = ModelConfig(
    providerId: 'custom',
    name: 'model-a',
    displayName: 'Model A',
  );

  test('prompt translation needs an explicit enabled provider and model', () {
    PromptAssistantConfigState config({
      ProviderConfig routeProvider = provider,
      String modelName = 'model-a',
      bool configured = true,
    }) => PromptAssistantConfigState(
      providers: [routeProvider],
      models: const [model],
      interfaces: configured
          ? {
              LauncherInterface.translate: InterfaceSlotConfig(
                providerId: routeProvider.id,
                model: modelName,
              ),
            }
          : const {},
      providerHasApiKey: const {},
    );

    expect(config(configured: false).promptTranslationRoute, isNull);
    expect(config(modelName: '').promptTranslationRoute, isNull);
    expect(config(modelName: 'other').promptTranslationRoute, isNull);
    expect(
      config(
        routeProvider: provider.copyWith(enabled: false),
      ).promptTranslationRoute,
      isNull,
    );
    final selected = config().promptTranslationRoute;
    expect(selected?.provider.id, 'custom');
    expect(selected?.model.name, 'model-a');
  });
}
