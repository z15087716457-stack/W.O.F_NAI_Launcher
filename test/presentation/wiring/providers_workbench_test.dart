import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/constants/storage_keys.dart';
import 'package:nai_launcher/core/storage/local_storage_service.dart';
import 'package:nai_launcher/core/storage/secure_storage_service.dart';
import 'package:nai_launcher/data/services/nai_agent/agent_workspace_store.dart';
import 'package:nai_launcher/l10n/app_localizations.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/model_catalog_entry.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/model_request_overrides.dart';
import 'package:nai_launcher/presentation/prompt_assistant/models/prompt_assistant_models.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/prompt_assistant_config_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/providers/provider_connection_health_provider.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/model_catalog_repository.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/prompt_assistant_service.dart';
import 'package:nai_launcher/presentation/prompt_assistant/services/provider_model_list_cache.dart';
import 'package:nai_launcher/presentation/providers/nai_agent/nai_agent_workspace_provider.dart';
import 'package:nai_launcher/presentation/ui/model_providers/model_providers_contract.dart';
import 'package:nai_launcher/presentation/ui/model_providers/model_providers_controller.dart';
import 'package:nai_launcher/presentation/ui/model_providers/model_providers_page.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_contract.dart';
import 'package:nai_launcher/presentation/ui/settings/settings_fixture.dart';
import 'package:nai_launcher/presentation/wiring/settings/providers_projection.dart';
import 'package:nai_launcher/presentation/wiring/settings/providers_workbench.dart';
import 'package:nai_launcher/presentation/wiring/settings/settings_models.dart';

import '../../helpers/studio_capture_fonts.dart';
import '../screens/settings/model_management_section_test.dart'
    show MemorySettings, MemorySecrets;
import '../ui/settings/settings_test_harness.dart';

class _Service extends Mock implements PromptAssistantService {}

class _Local extends MemorySettings {
  int configWrites = 0;
  bool fail = false;
  @override
  Future<void> setSetting<T>(String key, T value) async {
    if (key == StorageKeys.promptAssistantConfigJson) {
      configWrites++;
      if (fail) {
        fail = false;
        throw StateError('offline failure');
      }
    }
    return super.setSetting(key, value);
  }
}

class _Secure extends MemorySecrets {
  Completer<void>? entered, release;
  @override
  Future<String?> getPromptAssistantHeaders(String id) async {
    if (entered != null) {
      final signal = entered!;
      entered = null;
      signal.complete();
      await release!.future;
    }
    return super.getPromptAssistantHeaders(id);
  }
}

const _provider = ProviderConfig(
  id: 'p',
  name: 'Endpoint',
  baseUrl: 'https://example.invalid/v1',
);
const _model = ModelConfig(
  providerId: 'p',
  name: 'm',
  displayName: 'm',
  isDefault: true,
  reasoningEffort: 'high',
  reasoningFormat: 'legacy-format',
  customFields: {'reasoningEffort', 'reasoningProtocol'},
  hasRequestOverrides: true,
);

class _Harness {
  final local = _Local();
  final secure = _Secure();
  final service = _Service();
  late ProviderContainer container;
  late ProvidersWorkbench backend;
  late Directory directory;
  PromptAssistantConfigNotifier get controller =>
      container.read(promptAssistantConfigProvider.notifier);
  PromptAssistantConfigState get config =>
      container.read(promptAssistantConfigProvider);
  ProvidersWorkbenchState get state =>
      container.read(providersWorkbenchProvider);
  ProvidersViewData get view => providersViewData(
    config,
    state,
    container.read(providerConnectionHealthProvider),
    lookupAppLocalizations(const Locale('en')),
  );

  Future<void> init({PromptAssistantConfigState? initial}) async {
    directory = await Directory.systemTemp.createTemp('mp-wiring-');
    local.values[StorageKeys.promptAssistantConfigJson] =
        (initial ??
                const PromptAssistantConfigState(
                  providers: [_provider],
                  models: [_model],
                  interfaces: {
                    LauncherInterface.translate: InterfaceSlotConfig(
                      providerId: 'p',
                      model: 'm',
                    ),
                  },
                  providerHasApiKey: {},
                ))
            .encode();
    secure.keys['p'] = 'sk-original-key';
    secure.headers['p'] = jsonEncode({'X-Client': 'original'});
    secure.headers['model/p/m'] = const ModelRequestOverrides(
      headers: {'X-Model': 'secret'},
      body: {
        'custom': {'old': true},
      },
    ).encode();
    container = ProviderContainer(
      overrides: [
        localStorageServiceProvider.overrideWithValue(local),
        secureStorageServiceProvider.overrideWithValue(secure),
        promptAssistantServiceProvider.overrideWithValue(service),
        naiAgentWorkspaceStoreProvider.overrideWithValue(
          AgentWorkspaceStore(directory),
        ),
      ],
    );
    container.read(promptAssistantConfigProvider);
    await Future<void>.delayed(Duration.zero);
    backend = container.read(providersWorkbenchProvider.notifier);
    await backend.refresh();
    await Future<void>.delayed(Duration.zero);
    addTearDown(() async {
      container.dispose();
      await directory.delete(recursive: true);
    });
  }

  Future<ProvidersSaveResult> save(
    ProviderSettings base,
    ProviderSettings edited, {
    String? key,
  }) => backend.save(providerId: 'p', base: base, edited: edited, apiKey: key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadStudioCaptureFonts();
    registerFallbackValue(_provider);
    registerFallbackValue(_model);
  });
  setUp(() {
    final previous = ModelCatalogRepository.cached;
    ModelCatalogRepository.cached = ModelCatalogRepository.empty;
    addTearDown(() => ModelCatalogRepository.cached = previous);
  });

  test(
    'projection loads secure values, masks key and preserves legacy unknowns',
    () async {
      final h = _Harness();
      await h.init();
      final p = h.view.providers.single,
          m = h.state.settings['p']!.models.single;
      expect(p.apiKeyMasked, 'sk-••••-key');
      expect(p.models['m']!.usedFor, {
        SettingsModelTask.promptTranslate,
        SettingsModelTask.promptReverse,
      });
      expect(m.reasoningLevels, ['high']);
      expect(m.capabilities, isEmpty);
      expect(m.body.single.value, '{"old":true}');
      expect(m.headers.single.value, 'secret');
      expect(
        h.view.presets.map((p) => p.id),
        ProviderPresetDefaults.selectable.map((p) => p.name),
      );
      expect(h.view.presets.singleWhere((p) => p.custom).host, '');
      expect(maskProviderKey('short'), '••••••••');
      expect(maskProviderKey(null), '');
      expect(h.state.toString(), isNot(contains('sk-original-key')));
    },
  );

  for (final key in <String?>[null, '', 'sk-new-value']) {
    test(
      'save persists provider/models/secure overrides and apiKey=$key',
      () async {
        final h = _Harness();
        await h.init();
        final base = h.state.settings['p']!;
        final edited = base.copyWith(
          name: 'Renamed',
          timeoutSeconds: 145,
          maxConcurrency: 8,
          retryAttempts: 3,
          headers: const [ProviderKeyValue('X-New', 'private')],
          models: [
            base.models.single.copyWith(
              alias: 'Alias',
              body: const [ProviderKeyValue('custom', '{"new":[1,true]}')],
              headers: const [ProviderKeyValue('X-Model', 'new')],
            ),
          ],
        );
        expect(await h.save(base, edited, key: key), ProvidersSaveResult.saved);
        expect(h.state.settings['p'], edited);
        expect(
          h.secure.keys['p'],
          key == null
              ? 'sk-original-key'
              : key.isEmpty
              ? isNull
              : key,
        );
        expect(h.secure.headers['p'], '{"X-New":"private"}');
        expect(jsonDecode(h.secure.headers['model/p/m']!)['body'], {
          'custom': {
            'new': [1, true],
          },
        });
        final m = h.config.models.single;
        expect(m.isDefault, isTrue);
        expect(m.reasoningFormat, 'legacy-format');
        expect(m.reasoningEfforts, isNull);
        expect(m.supportsVision, isNull);
        expect(m.supportsTools, isNull);
        expect(
          m.customFields,
          containsAll(['reasoningEffort', 'reasoningProtocol', 'displayName']),
        );
        expect(m.customFields, isNot(contains('supportsVision')));
        expect(h.config.encode(), isNot(contains('private')));
        expect(h.config.encode(), isNot(contains('sk-new-value')));
        expect(
          await h.backend.controller.getProviderApiKey('p'),
          key == null
              ? 'sk-original-key'
              : key.isEmpty
              ? isNull
              : key,
        );
      },
    );
  }

  test(
    'secure changes and model order changes conflict without writing',
    () async {
      final h = _Harness();
      await h.init();
      final base = h.state.settings['p']!;
      h.secure.headers['model/p/m'] = const ModelRequestOverrides(
        body: {'new': 4},
      ).encode();
      expect(
        await h.save(base, base.copyWith(name: 'stale')),
        ProvidersSaveResult.conflict,
      );
      expect(h.local.configWrites, 0);
      expect(h.config.providers.single.name, 'Endpoint');
      final latest = await h.backend.readSettings('p');
      await h.controller.addProviderModels('p', ['other']);
      expect(await h.save(latest, latest), ProvidersSaveResult.conflict);
      expect(h.config.models.map((m) => m.name), ['m', 'other']);
    },
  );

  test('configuration changing during secure read is conflict', () async {
    final h = _Harness();
    await h.init();
    final base = h.state.settings['p']!;
    final entered = h.secure.entered = Completer<void>();
    h.secure.release = Completer<void>();
    final pending = h.save(base, base.copyWith(name: 'stale'));
    await entered.future;
    await h.controller.upsertProvider(_provider.copyWith(name: 'newer'));
    h.secure.release!.complete();
    expect(await pending, ProvidersSaveResult.conflict);
    expect(h.config.providers.single.name, 'newer');
  });

  test(
    'storage failure rolls back provider headers, key and model overrides',
    () async {
      final h = _Harness();
      await h.init();
      final base = h.state.settings['p']!;
      final before = Map.of(h.secure.headers);
      h.local.fail = true;
      expect(
        await h.save(
          base,
          base.copyWith(
            name: 'lost',
            headers: const [ProviderKeyValue('X-New', 'new')],
          ),
          key: 'replacement',
        ),
        ProvidersSaveResult.failed,
      );
      expect(h.secure.headers, before);
      expect(h.secure.keys['p'], 'sk-original-key');
      expect(h.config.providers.single.name, 'Endpoint');
      expect(h.state.settings['p'], base);
    },
  );

  final invalid = <String, ProviderSettings Function(ProviderSettings)>{
    'provider duplicate header': (s) => s.copyWith(
      headers: const [
        ProviderKeyValue('X-A', '1'),
        ProviderKeyValue('x-a', '2'),
      ],
    ),
    'model duplicate header': (s) => s.withModel(
      s.models.single.copyWith(
        headers: const [
          ProviderKeyValue('X-A', '1'),
          ProviderKeyValue('x-a', '2'),
        ],
      ),
    ),
    'duplicate body': (s) => s.withModel(
      s.models.single.copyWith(
        body: const [ProviderKeyValue('a', '1'), ProviderKeyValue('a', '2')],
      ),
    ),
    'invalid json': (s) => s.withModel(
      s.models.single.copyWith(body: const [ProviderKeyValue('a', '{')]),
    ),
    'model override mismatch': (s) => s.withModel(
      s.models.single.copyWith(
        body: const [ProviderKeyValue('model', '"other"')],
      ),
    ),
    'stream override': (s) => s.withModel(
      s.models.single.copyWith(
        body: const [ProviderKeyValue('stream', 'true')],
      ),
    ),
    'header controls': (s) =>
        s.copyWith(headers: const [ProviderKeyValue('X-A', 'line\nline')]),
    'timeout': (s) => s.copyWith(timeoutSeconds: 1),
    'concurrency': (s) => s.copyWith(maxConcurrency: 21),
    'retries': (s) => s.copyWith(retryAttempts: 4),
    'name': (s) => s.copyWith(name: ''),
    'url': (s) => s.copyWith(baseUrl: 'file:///private'),
    'context': (s) => s.withModel(s.models.single.copyWith(contextWindow: -1)),
    'output': (s) => s.withModel(s.models.single.copyWith(maxOutput: 0)),
    'output > context': (s) =>
        s.withModel(s.models.single.copyWith(maxOutput: 11, contextWindow: 10)),
  };
  for (final entry in invalid.entries) {
    test('validation fails without any writes: ${entry.key}', () async {
      final h = _Harness();
      await h.init();
      final base = h.state.settings['p']!;
      final before = Map.of(h.secure.headers);
      expect(await h.save(base, entry.value(base)), ProvidersSaveResult.failed);
      expect(h.local.configWrites, 0);
      expect(h.secure.headers, before);
    });
  }

  for (final flag in [true, false]) {
    test(
      'projection save preserves hidden provider image flag=$flag and legacy sampling',
      () {
        final provider = _provider.copyWith(allowImageInput: flag);
        const model = ModelConfig(
          providerId: 'p',
          name: 'legacy',
          displayName: 'legacy',
          temperature: 3,
          topP: 0,
        );
        final base = projectProviderSettings(provider, [model], {});
        final merged = mergeProviderSettings(
          provider,
          base.copyWith(name: 'Renamed'),
        );
        final next = mergeProviderModel(
          model,
          base.models.single,
          base.models.single.copyWith(alias: 'Alias'),
        );
        expect(merged.toJson()['allowImageInput'], flag);
        expect(next.toJson()['temperature'], 3);
        expect(next.toJson()['topP'], 0);
        expect(
          () => validateProviderDraft(
            merged.copyWith(protocol: ProviderProtocol.anthropicMessages),
            [next],
          ),
          returnsNormally,
        );
      },
    );
  }

  test(
    'empty baseUrl remains a valid intermediate saved configuration',
    () async {
      final h = _Harness();
      await h.init();
      final base = h.state.settings['p']!;
      expect(
        await h.save(base, base.copyWith(baseUrl: '')),
        ProvidersSaveResult.saved,
      );
      expect(h.state.settings['p']!.baseUrl, '');
    },
  );

  test(
    'changed reasoning and capability fields alone become custom fields',
    () async {
      final h = _Harness();
      await h.init();
      final base = h.state.settings['p']!;
      final edited = base.withModel(
        base.models.single.copyWith(
          reasoningLevels: [],
          clearDefaultLevel: true,
          capabilities: {ProviderCapability.tools},
        ),
      );
      expect(await h.save(base, edited), ProvidersSaveResult.saved);
      final model = h.config.models.single;
      expect(model.reasoningEfforts, isEmpty);
      expect(model.reasoningEffort, isNull);
      expect(model.supportsTools, true);
      expect(model.supportsVision, isNull);
      expect(
        model.customFields,
        containsAll(['reasoningEfforts', 'supportsTools']),
      );
    },
  );

  test(
    'clear nullable parameters and secure overrides without changing hidden fields',
    () async {
      final h = _Harness();
      await h.init();
      await h.controller.upsertModel(
        h.config.models.single.copyWith(
          contextWindow: 100,
          maxOutputTokens: 50,
          temperature: .5,
          topP: .8,
        ),
      );
      await h.backend.refresh();
      final base = h.state.settings['p']!;
      final edited = base.withModel(
        base.models.single.copyWith(
          clearContextWindow: true,
          clearMaxOutput: true,
          body: [],
          headers: [],
        ),
      );
      expect(await h.save(base, edited), ProvidersSaveResult.saved);
      final m = h.config.models.single;
      expect(m.contextWindow, isNull);
      expect(m.maxOutputTokens, isNull);
      // Hidden legacy values survive unrelated UI saves unchanged.
      expect(m.temperature, .5);
      expect(m.topP, .8);
      expect(h.config.providers.single.allowImageInput, false);
      expect(m.isDefault, isTrue);
      expect(m.reasoningFormat, 'legacy-format');
      expect(m.hasRequestOverrides, false);
      expect(h.secure.headers.containsKey('model/p/m'), false);
    },
  );

  test(
    'hidden-only external changes are inherited rather than clobbered',
    () async {
      final h = _Harness();
      await h.init();
      final base = h.state.settings['p']!;
      await h.controller.upsertModel(
        h.config.models.single.copyWith(
          isDefault: false,
          source: ModelSource.api,
          reasoningFormat: 'new-format',
        ),
      );
      expect(
        await h.save(base, base.copyWith(name: 'Changed')),
        ProvidersSaveResult.saved,
      );
      expect(h.config.models.single.isDefault, false);
      expect(h.config.models.single.source, ModelSource.api);
      expect(h.config.models.single.reasoningFormat, 'new-format');
    },
  );

  test(
    'catalog limits reject invalid capacities before any secure writes',
    () async {
      final h = _Harness();
      await h.init();
      await h.controller.upsertModel(
        h.config.models.single.copyWith(
          catalogEntry: const ModelCatalogEntry(
            id: 'm',
            vendor: 'fixture',
            name: 'M',
            contextLimit: 100,
            outputLimit: 20,
          ),
        ),
      );
      await h.backend.refresh();
      final base = h.state.settings['p']!;
      expect(
        await h.save(
          base,
          base.withModel(base.models.single.copyWith(contextWindow: 101)),
        ),
        ProvidersSaveResult.failed,
      );
      expect(
        await h.save(
          base,
          base.withModel(base.models.single.copyWith(maxOutput: 21)),
        ),
        ProvidersSaveResult.failed,
      );
    },
  );

  test(
    'saving with a live catalog preserves hidden fields and null capabilities',
    () async {
      ModelCatalogRepository.cached = ModelCatalogRepository.decode(
        jsonEncode({
          'models': [
            {
              'id': 'new',
              'vendor': 'fixture',
              'name': 'Catalog',
              'vision': true,
              'reasoningFormat': 'catalog-format',
            },
          ],
          'bindings': {},
          'providers': {},
        }),
      );
      final h = _Harness();
      await h.init();
      await h.backend.addModels('p', ['new']);
      final selected = h.config.models.firstWhere((m) => m.name == 'new');
      await h.controller.upsertModel(
        selected.copyWith(reasoningFormat: 'runtime-hidden-format'),
      );
      final latest = h.config.models.firstWhere((m) => m.name == 'new');
      final raw = latest.copyWith(
        clearSupportsVision: true,
        reasoningFormat: 'legacy-hidden',
        customFields: {'supportsVision'},
      );
      await h.controller.saveServiceDraft(
        provider: h.config.providers.single,
        models: [h.config.models.first, raw],
        headers: await h.controller.getProviderHeaders('p'),
        enrichModels: false,
      );
      await h.backend.refresh();
      final base = h.state.settings['p']!;
      expect(
        base.model('new')!.capabilities,
        contains(ProviderCapability.vision),
      );
      expect(
        await h.save(base, base.copyWith(name: 'New name')),
        ProvidersSaveResult.saved,
      );
      final saved = h.config.models.firstWhere((m) => m.name == 'new');
      expect(saved.supportsVision, isNull);
      expect(saved.reasoningFormat, 'legacy-hidden');
    },
  );

  test('create IDs are unique and enabling is immediate', () async {
    final h = _Harness();
    await h.init();
    final a = await h.backend.create('deepseek'),
        b = await h.backend.create('deepseek');
    expect(b, '${a}_2');
    expect(h.config.providers.length, 3);
    await h.backend.enabled(b, false);
    expect(h.config.providers.last.enabled, false);
  });

  test(
    'batch addition enriches catalog, skips duplicates, saves once; reorder leaves placeholders and secure options intact',
    () async {
      ModelCatalogRepository.cached = ModelCatalogRepository.decode(
        jsonEncode({
          'models': [
            {
              'id': 'new',
              'vendor': 'fixture',
              'name': 'Catalog Name',
              'context': 1000,
              'output': 200,
              'efforts': ['low', 'high'],
              'defaultEffort': 'low',
              'vision': true,
              'toolCall': true,
            },
          ],
          'bindings': {},
          'providers': {},
        }),
      );
      final h = _Harness();
      await h.init();
      await h.controller.upsertModel(
        const ModelConfig(
          providerId: 'p',
          name: 'default-model',
          displayName: 'placeholder',
        ),
      );
      final writes = h.local.configWrites, before = Map.of(h.secure.headers);
      await h.backend.addModels('p', ['new', 'new', 'm']);
      expect(h.local.configWrites, writes + 1);
      final added = h.config.models.firstWhere((m) => m.name == 'new');
      expect(added.displayName, 'Catalog Name');
      expect(added.contextWindow, 1000);
      expect(added.reasoningEfforts, ['low', 'high']);
      expect(added.source, ModelSource.api);
      expect(
        projectProviderModel(added).capabilities,
        containsAll([ProviderCapability.vision, ProviderCapability.tools]),
      );
      final placeholderIndex = h.config.models.indexWhere(
        (m) => m.isPlaceholder,
      );
      await h.backend.reorder('p', ['new', 'm']);
      expect(
        h.config.models.where((m) => !m.isPlaceholder).map((m) => m.name),
        ['new', 'm'],
      );
      expect(
        h.config.models.indexWhere((m) => m.isPlaceholder),
        placeholderIndex,
      );
      expect(h.secure.headers, before);
      await h.backend.addModels('p', ['manual'], manual: true);
      expect(h.config.models.last.source, ModelSource.manual);
    },
  );

  test(
    'remove model clears functional slot and Agent selection; delete clears secrets and provider slot',
    () async {
      final h = _Harness();
      await h.init();
      final store = h.container.read(naiAgentWorkspaceStoreProvider);
      await store.patchSettings({'providerId': 'p', 'modelId': 'm'});
      await h.backend.removeModel('p', 'm');
      expect(
        h.config.interfaceFor(LauncherInterface.translate).providerId,
        'p',
      );
      expect(h.config.interfaceFor(LauncherInterface.translate).model, '');
      expect((await store.readSettings()).providerId, '');
      expect((await store.readSettings()).modelId, '');
      expect(h.secure.headers.containsKey('model/p/m'), false);
      expect(h.container.exists(naiAgentControllerProvider), false);
      await h.backend.delete('p');
      expect(h.config.providers, isEmpty);
      expect(h.secure.keys, isEmpty);
      expect(h.secure.headers, isEmpty);
      expect(h.config.interfaceFor(LauncherInterface.translate).providerId, '');
    },
  );

  test(
    'draft tests use temporary connection/model parameters and do not save or pollute saved health',
    () async {
      final h = _Harness();
      await h.init();
      final base = h.state.settings['p']!;
      final edited = base
          .copyWith(
            baseUrl: 'https://draft.invalid',
            headers: const [ProviderKeyValue('X-Draft', 'yes')],
          )
          .withModel(
            base.models.single.copyWith(
              maxOutput: 42,
              body: const [ProviderKeyValue('custom', '42')],
            ),
          );
      final result = Completer<String>();
      when(
        () => h.service.testModelForDraft(any(), any(), any(), any()),
      ).thenAnswer((_) => result.future);
      final pending = h.backend.test('p', edited, 'temporary', modelId: 'm');
      expect(h.state.models[('p', 'm')]!.testing, true);
      await Future<void>.delayed(Duration.zero);
      result.complete('OK');
      await pending;
      final captured = verify(
        () => h.service.testModelForDraft(
          captureAny(),
          captureAny(),
          'temporary',
          {'X-Draft': 'yes'},
        ),
      ).captured;
      expect((captured[0] as ProviderConfig).baseUrl, 'https://draft.invalid');
      expect((captured[1] as ModelConfig).maxOutputTokens, 42);
      expect((captured[1] as ModelConfig).requestOverrides!.body, {
        'custom': 42,
      });
      expect(h.state.models[('p', 'm')]!.lastTest!.ok, true);
      expect(h.state.models[('p', 'm')]!.testing, false);
      expect(h.config.providers.single.baseUrl, _provider.baseUrl);
      expect(h.secure.keys['p'], 'sk-original-key');
      expect(h.local.configWrites, 0);
      expect(
        h.container
            .read(providerConnectionHealthProvider)
            .resultFor('p')
            .status,
        ProviderConnectionStatus.unverified,
      );
    },
  );

  test(
    'connection test without selected models uses draft discovery and temporary key',
    () async {
      final h = _Harness();
      await h.init();
      await h.backend.removeModel('p', 'm');
      final base = h.state.settings['p']!;
      final response = Completer<List<String>>();
      when(
        () => h.service.fetchModelsForDraft(any(), any(), any()),
      ).thenAnswer((_) => response.future);
      final pending = h.backend.test(
        'p',
        base.copyWith(baseUrl: 'https://draft.invalid'),
        'temporary',
      );
      expect(h.state.connections['p']!.testing, true);
      await Future<void>.delayed(Duration.zero);
      response.complete([]);
      await pending;
      expect(h.view.providers.single.status, SettingsTone.ok);
      expect(h.view.providers.single.latencyMs, isNotNull);
      expect(h.config.providers.single.baseUrl, _provider.baseUrl);
      verify(
        () => h.service.fetchModelsForDraft(any(), 'temporary', {
          'X-Client': 'original',
        }),
      ).called(1);
      verifyNever(
        () => h.service.testModelForDraft(any(), any(), any(), any()),
      );
    },
  );

  test('late model test result cannot revive a removed model', () async {
    final h = _Harness();
    await h.init();
    final base = h.state.settings['p']!;
    final response = Completer<String>();
    when(
      () => h.service.testModelForDraft(any(), any(), any(), any()),
    ).thenAnswer((_) => response.future);
    final pending = h.backend.test('p', base, null, modelId: 'm');
    await Future<void>.delayed(Duration.zero);
    await h.backend.removeModel('p', 'm');
    response.complete('OK');
    await pending;
    expect(h.state.models.containsKey(('p', 'm')), false);
  });

  test(
    'all public callbacks delegate with awaiting save and action-runner errors',
    () async {
      final h = _Harness();
      await h.init();
      Future<void>? pending;
      final errors = <Object>[];
      final actions = workbenchActions(h.backend, (action) {
        pending = Future<void>.sync(action).catchError((Object error) {
          errors.add(error);
        });
      });
      expect(await actions.onRevealApiKey('p'), 'sk-original-key');
      final id = await actions.onCreate('deepseek');
      expect(id, isNotNull);
      actions.onEnabled(id!, false);
      await pending;
      expect(h.config.providers.last.enabled, false);
      actions.onAddModels('p', ['second'], manual: true);
      await pending;
      actions.onReorderModels('p', ['second', 'm']);
      await pending;
      expect(h.config.models.first.name, 'second');
      actions.onRemoveModel('p', 'second');
      await pending;
      expect(h.config.models.map((m) => m.name), ['m']);
      final base = h.state.settings['p']!;
      expect(
        await actions.onSave(
          providerId: 'p',
          base: base,
          edited: base.copyWith(timeoutSeconds: 152),
        ),
        ProvidersSaveResult.saved,
      );
      actions.onDelete(id);
      await pending;
      expect(h.config.providers.length, 1);
      expect(await actions.onCreate('missing'), isNull);
      await pending;
      expect(errors, hasLength(1));
    },
  );

  test(
    'saved-connection test writes health and short failure status; errors reach the action runner',
    () async {
      final h = _Harness();
      await h.init();
      final base = h.state.settings['p']!;
      when(
        () => h.service.testModelForDraft(any(), any(), any(), any()),
      ).thenAnswer((_) async => 'OK');
      await h.backend.test('p', base, null);
      expect(
        h.state.connections['p']!.result.status,
        ProviderConnectionStatus.healthy,
      );
      expect(
        h.container
            .read(providerConnectionHealthProvider)
            .resultFor('p')
            .status,
        ProviderConnectionStatus.healthy,
      );
      final request = RequestOptions(path: '/offline');
      when(
        () => h.service.testModelForDraft(any(), any(), any(), any()),
      ).thenThrow(
        DioException(
          requestOptions: request,
          response: Response(requestOptions: request, statusCode: 401),
        ),
      );
      final errors = <Object>[];
      Future<void>? running;
      final actions = workbenchActions(h.backend, (action) {
        running = Future<void>.sync(action).catchError((Object error) {
          errors.add(error);
        });
      });
      actions.onTest('p', base, null);
      await running;
      expect(errors, hasLength(1));
      expect(h.view.providers.single.error, '401 · Invalid API key');
      expect(h.view.providers.single.testing, false);
      await h.container.read(providerConnectionHealthProvider).whenPersisted;
    },
  );

  test(
    'catalog uses saved connection, caches independently and keeps entries after failure',
    () async {
      final h = _Harness();
      await h.init();
      final response = Completer<List<String>>();
      when(
        () => h.service.fetchModelsForDraft(any(), any(), any()),
      ).thenAnswer((_) => response.future);
      final pending = h.backend.fetchCatalog('p');
      expect(h.state.catalogs['p']!.state, ProviderCatalogState.loading);
      response.complete(['new', 'm']);
      await pending;
      expect(h.state.catalogs['p']!.state, ProviderCatalogState.ready);
      expect(h.state.catalogs['p']!.fetchedAt, isNotNull);
      expect(h.config.models.map((m) => m.name), ['m']);
      verify(
        () => h.service.fetchModelsForDraft(any(), 'sk-original-key', {
          'X-Client': 'original',
        }),
      ).called(1);
      when(
        () => h.service.fetchModelsForDraft(any(), any(), any()),
      ).thenThrow(StateError('offline'));
      await expectLater(h.backend.fetchCatalog('p'), throwsStateError);
      expect(h.state.catalogs['p']!.state, ProviderCatalogState.failed);
      expect(h.state.catalogs['p']!.entries, hasLength(2));
      h.container.invalidate(providersWorkbenchProvider);
      h.backend = h.container.read(providersWorkbenchProvider.notifier);
      await h.backend.refresh();
      expect(h.state.catalogs['p']!.state, ProviderCatalogState.ready);
      expect(h.state.catalogs['p']!.fetchedAt, isNull);
      final fingerprint = ProviderModelListCache.fingerprint(
        _provider,
        'sk-original-key',
        {'X-Client': 'original'},
      );
      expect(
        h.container
            .read(providerModelListCacheProvider)
            .modelsFor('p', fingerprint),
        ['new', 'm'],
      );
    },
  );

  test('stale catalog cannot replace the current connection cache', () async {
    final h = _Harness();
    await h.init();
    final response = Completer<List<String>>();
    when(
      () => h.service.fetchModelsForDraft(any(), any(), any()),
    ).thenAnswer((_) => response.future);
    final pending = h.backend.fetchCatalog('p');
    await Future<void>.delayed(Duration.zero);
    await h.controller.upsertProvider(
      _provider.copyWith(baseUrl: 'https://changed.invalid'),
    );
    response.complete(['stale']);
    await expectLater(pending, throwsStateError);
    expect(h.state.catalogs['p']?.entries ?? [], isEmpty);
  });

  test(
    'prices need input and output keys; regional preset groups stay distinct',
    () {
      expect(
        providerCatalogPrice(
          const ModelCatalogEntry(
            id: 'x',
            vendor: '',
            name: '',
            cost: {'input': 0, 'output': 1.5, 'input_audio': 999},
          ),
        ),
        r'$0 / $1.5',
      );
      expect(
        providerCatalogPrice(
          const ModelCatalogEntry(
            id: 'x',
            vendor: '',
            name: '',
            cost: {'input': 0},
          ),
        ),
        isNull,
      );
      expect(providerGroup(ProviderPreset.moonshot), ProviderGroup.domestic);
      expect(
        providerGroup(ProviderPreset.moonshotInternational),
        ProviderGroup.aggregator,
      );
    },
  );

  test(
    'UI draft survives immediate addition, reorder and removal before saving',
    () async {
      final h = _Harness();
      await h.init();
      final draft = ProvidersController();
      addTearDown(draft.dispose);
      final original = h.view.providers.single;
      draft.edit(original, (s) => s.copyWith(name: 'Draft name'));
      await h.backend.addModels('p', ['second']);
      await h.backend.reorder('p', ['second', 'm']);
      final latest = h.view.providers.single;
      draft.sync(h.view);
      expect(
        draft.draft('p')!.display(latest.settings).models.map((m) => m.id),
        ['second', 'm'],
      );
      expect(
        await draft.save(latest, workbenchActions(h.backend, (_) {})),
        ProvidersSaveResult.saved,
      );
      expect(h.state.settings['p']!.name, 'Draft name');
      draft.edit(
        h.view.providers.single,
        (s) => s.copyWith(timeoutSeconds: 150),
      );
      await h.backend.removeModel('p', 'm');
      draft.sync(h.view);
      expect(
        await draft.save(
          h.view.providers.single,
          workbenchActions(h.backend, (_) {}),
        ),
        ProvidersSaveResult.saved,
      );
      expect(h.config.models.map((m) => m.name), ['second']);
      expect(h.state.settings['p']!.timeoutSeconds, 150);
    },
  );

  testWidgets(
    'real settings projection activates the locked workbench and save refreshes displayed data',
    (tester) async {
      final h = _Harness();
      await tester.runAsync(h.init);
      late SettingsModelsData projected;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: h.container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Consumer(
              builder: (context, ref, _) {
                projected = settingsModelsData(context, ref);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(projected.workbench, isNotNull);
      expect(projected.providers.single.id, 'p');
      await pumpSettings(
        tester,
        data: SettingsFixture.view(
          page: SettingsPageId.models,
        ).copyWith(models: projected),
      );
      expect(find.byType(ModelProvidersPanel), findsOneWidget);
      expect(find.byKey(const Key('mp-provider-p')), findsOneWidget);
      final base = h.state.settings['p']!;
      await tester.runAsync(() async {
        expect(
          await h.save(base, base.copyWith(name: 'Updated')),
          ProvidersSaveResult.saved,
        );
      });
      expect(h.state.settings['p']!.name, 'Updated');
      expect(tester.takeException(), isNull);
    },
  );
}
