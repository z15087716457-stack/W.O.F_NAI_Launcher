import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_task_definitions.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_models.dart';

import '../screens/settings/model_management_section_test.dart'
    show MemorySettings, MemorySecrets;

class _Storage extends MemorySettings {
  bool fail = false;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    if (fail && key == StorageKeys.promptAssistantConfigJson) {
      fail = false;
      throw StateError('fixture write failure');
    }
    await super.setSetting(key, value);
  }
}

const _model = ModelConfig(
  providerId: 'p',
  name: 'fixture-model',
  displayName: 'Fixture',
  reasoningEffort: 'medium',
  reasoningEfforts: ['none', 'low', 'medium'],
  temperature: .25,
  maxOutputTokens: 1024,
);

void main() {
  late ProviderContainer container;
  late _Storage storage;
  late SettingsModelActions actions;
  late SettingsModelsData view;
  late ModelCatalogRepository? previousCatalog;

  setUp(() {
    previousCatalog = ModelCatalogRepository.cached;
    ModelCatalogRepository.cached = ModelCatalogRepository.empty;
    storage = _Storage();
    storage.values[StorageKeys.promptAssistantConfigJson] =
        PromptAssistantConfigState(
          providerHasApiKey: const {},
          providers: const [
            ProviderConfig(
              id: 'p',
              name: 'Fixture',
              baseUrl: 'https://example.invalid/v1',
            ),
          ],
          models: [
            _model,
            _model.copyWith(name: 'other-model'),
          ],
          interfaces: {
            for (final task in LauncherInterface.values)
              task: InterfaceSlotConfig(
                providerId: 'p',
                model: _model.name,
                presetId: task.builtinId,
                targetLanguage: 'ja',
                reasoningEffort: task == LauncherInterface.tagTranslate
                    ? 'none'
                    : null,
              ),
          },
          presets: const [],
        ).encode();
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(storage),
        secureStorageServiceProvider.overrideWithValue(MemorySecrets()),
      ],
    );
  });
  tearDown(() {
    container.dispose();
    ModelCatalogRepository.cached = previousCatalog;
  });

  Future<void> mount(WidgetTester t) async {
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('zh'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Consumer(
            builder: (context, ref, _) {
              actions = SettingsModelActions(context, ref);
              view = settingsModelsData(context, ref);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  PromptAssistantConfigState getState() =>
      container.read(promptAssistantConfigProvider);
  PromptAssistantConfigNotifier controller() =>
      container.read(promptAssistantConfigProvider.notifier);
  InterfaceSlotConfig slot() =>
      getState().interfaceFor(LauncherInterface.translate);

  testWidgets(
    'projection exposes the registered choices, model default and per-task override',
    (t) async {
      await mount(t);
      expect(view.providers.single.models.first.reasoningEfforts, [
        'none',
        'low',
        'medium',
      ]);
      expect(
        view.providers.single.models.first.defaultReasoningEffort,
        'medium',
      );
      expect(
        view.assignments
            .firstWhere((a) => a.task == SettingsModelTask.tagTranslate)
            .reasoningEffort,
        'none',
      );
    },
  );

  testWidgets(
    'selection persists and reaches effective request parameters without changing other interfaces or the model',
    (t) async {
      await mount(t);
      final other = getState()
          .interfaceFor(LauncherInterface.tagTranslate)
          .toJson();
      await actions.assign(
        SettingsModelTask.promptTranslate,
        providerId: 'p',
        modelId: _model.name,
        reasoningEffort: 'low',
      );
      expect(slot().reasoningEffort, 'low');
      expect(slot().presetId, LauncherInterface.translate.builtinId);
      expect(slot().targetLanguage, 'ja');
      expect(
        getState().interfaceFor(LauncherInterface.tagTranslate).toJson(),
        other,
      );
      final effective = effectiveTaskModel(
        getState(),
        LauncherInterface.translate,
        getState().models.first,
      );
      expect(effective.reasoningEffort, 'low');
      expect(effective.temperature, .25);
      expect(effective.maxOutputTokens, 1024);
      expect(getState().models.first.reasoningEffort, 'medium');
      final saved = PromptAssistantConfigState.decode(
        storage.values[StorageKeys.promptAssistantConfigJson] as String,
      );
      expect(
        saved.interfaceFor(LauncherInterface.translate).reasoningEffort,
        'low',
      );
      await t.pump();
      expect(view.assignments.first.reasoningEffort, 'low');
    },
  );

  testWidgets(
    'off differs from inherit; changing models drops the old override while presets preserve it',
    (t) async {
      await mount(t);
      await actions.assign(
        SettingsModelTask.promptTranslate,
        reasoningEffort: 'none',
      );
      expect(
        effectiveTaskModel(
          getState(),
          LauncherInterface.translate,
          _model,
        ).reasoningEffort,
        'none',
      );
      await actions.assign(
        SettingsModelTask.promptTranslate,
        presetId: LauncherInterface.translate.builtinId,
      );
      expect(slot().reasoningEffort, 'none');
      await actions.assign(
        SettingsModelTask.promptTranslate,
        clearReasoningEffort: true,
      );
      expect(slot().reasoningEffort, isNull);
      expect(
        effectiveTaskModel(
          getState(),
          LauncherInterface.translate,
          _model,
        ).reasoningEffort,
        'medium',
      );
      await actions.assign(
        SettingsModelTask.promptTranslate,
        reasoningEffort: 'low',
      );
      await actions.assign(
        SettingsModelTask.promptTranslate,
        modelId: 'other-model',
      );
      expect(slot().reasoningEffort, isNull);
    },
  );

  testWidgets(
    'unknown choices and stale dropdown routes cannot overwrite current settings',
    (t) async {
      await mount(t);
      final before = slot().toJson();
      await expectLater(
        actions.assign(
          SettingsModelTask.promptTranslate,
          reasoningEffort: 'max',
        ),
        throwsStateError,
      );
      expect(slot().toJson(), before);
      await actions.assign(
        SettingsModelTask.promptTranslate,
        modelId: 'other-model',
      );
      await expectLater(
        actions.assign(
          SettingsModelTask.promptTranslate,
          providerId: 'p',
          modelId: _model.name,
          reasoningEffort: 'low',
        ),
        throwsStateError,
      );
      expect(slot().model, 'other-model');
      expect(slot().reasoningEffort, isNull);
    },
  );

  testWidgets(
    'failed writes leave the saved and projected reasoning setting intact',
    (t) async {
      await mount(t);
      final persisted = getState().encode();
      storage.fail = true;
      await expectLater(
        actions.assign(
          SettingsModelTask.promptTranslate,
          reasoningEffort: 'low',
        ),
        throwsStateError,
      );
      expect(slot().reasoningEffort, isNull);
      expect(storage.values[StorageKeys.promptAssistantConfigJson], persisted);
    },
  );

  testWidgets(
    'capability removal and unconfigured interfaces cannot accept an obsolete choice',
    (t) async {
      await mount(t);
      await controller().upsertModel(
        _model.copyWith(reasoningEfforts: [], clearReasoningEffort: true),
      );
      await expectLater(
        actions.assign(
          SettingsModelTask.promptTranslate,
          reasoningEffort: 'low',
        ),
        throwsStateError,
      );
      await controller().saveInterface(
        LauncherInterface.translate,
        const InterfaceSlotConfig(),
      );
      await expectLater(
        actions.assign(
          SettingsModelTask.promptTranslate,
          reasoningEffort: 'low',
        ),
        throwsStateError,
      );
      expect(slot().isConfigured, isFalse);
    },
  );
}
