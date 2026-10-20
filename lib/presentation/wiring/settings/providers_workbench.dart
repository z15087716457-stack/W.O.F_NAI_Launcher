import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/app_logger.dart';
import '../../../core/utils/localization_extension.dart';
import '../../../l10n/app_localizations.dart';
import '../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../prompt_assistant/providers/provider_connection_health_provider.dart';
import '../../prompt_assistant/services/model_catalog_repository.dart';
import '../../prompt_assistant/services/prompt_assistant_service.dart';
import '../../prompt_assistant/services/provider_model_list_cache.dart';
import '../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../ui/model_providers/model_providers_contract.dart';
import '../../ui/settings/settings_contract.dart';
import 'providers_projection.dart';
import 'settings_models.dart' show settingsTaskKind;

class WorkbenchConnectionTest {
  const WorkbenchConnectionTest({
    this.testing = false,
    this.result = const ProviderConnectionResult(),
    this.latencyMs,
  });
  final bool testing;
  final ProviderConnectionResult result;
  final int? latencyMs;
}

class WorkbenchModelTest {
  const WorkbenchModelTest({this.testing = false, this.lastTest});
  final bool testing;
  final ProviderTestResult? lastTest;
}

class ProvidersWorkbenchState {
  const ProvidersWorkbenchState({
    this.settings = const {},
    this.masked = const {},
    this.connections = const {},
    this.models = const {},
    this.catalogs = const {},
  });
  final Map<String, ProviderSettings> settings;
  final Map<String, String> masked;
  final Map<String, WorkbenchConnectionTest> connections;
  final Map<(String, String), WorkbenchModelTest> models;
  final Map<String, ProviderCatalog> catalogs;
}

final providersWorkbenchProvider =
    StateNotifierProvider<ProvidersWorkbench, ProvidersWorkbenchState>((ref) {
      final workbench = ProvidersWorkbench(ref);
      ref.listen(
        promptAssistantConfigProvider,
        (_, __) => workbench.scheduleRefresh(),
      );
      workbench.scheduleRefresh();
      return workbench;
    });

/// In-memory UI facts only. Plaintext credentials are never retained here.
class ProvidersWorkbench extends StateNotifier<ProvidersWorkbenchState> {
  ProvidersWorkbench(this.ref) : super(const ProvidersWorkbenchState());
  final Ref ref;
  final _fingerprints = <String, String>{};
  Future<void> _pendingRefresh = Future.value();
  final _testSequence = <(String, String?), int>{};
  final _catalogSequence = <String, int>{};

  PromptAssistantConfigNotifier get controller =>
      ref.read(promptAssistantConfigProvider.notifier);
  ProviderConfig provider(String id) => ref
      .read(promptAssistantConfigProvider)
      .providers
      .firstWhere((p) => p.id == id);

  void scheduleRefresh() {
    // Do not publish state while Riverpod is creating / notifying providers.
    unawaited(
      Future<void>.microtask(refresh).catchError((Object _) {
        if (!mounted) return;
        AppLogger.w(
          'Workbench secure projection could not be loaded.',
          'PromptAssistant',
        );
      }),
    );
  }

  Future<void> refresh() {
    final operation = _pendingRefresh.then((_) => _refresh());
    _pendingRefresh = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final config = ref.read(promptAssistantConfigProvider);
    final settings = <String, ProviderSettings>{}, masked = <String, String>{};
    final fingerprints = <String, String>{};
    final cached = <String, ProviderCatalog>{};
    final catalog = ModelCatalogRepository.cached;
    for (final p in config.providers) {
      final key = await controller.getProviderApiKey(p.id);
      final headers = await controller.getProviderHeaders(p.id);
      final models = <ModelConfig>[];
      for (final m in config.modelsForProvider(providerId: p.id)) {
        models.add(
          await controller.loadModelRequestOverrides(
            m.copyWith(clearRequestOverrides: true),
          ),
        );
      }
      settings[p.id] = projectProviderSettings(p, models, headers);
      masked[p.id] = maskProviderKey(key);
      final fingerprint = ProviderModelListCache.fingerprint(p, key, headers);
      fingerprints[p.id] = fingerprint;
      final names = ref
          .read(providerModelListCacheProvider)
          .modelsFor(p.id, fingerprint);
      if (names != null) {
        cached[p.id] = ProviderCatalog(
          state: ProviderCatalogState.ready,
          entries: catalogEntries(p, names, catalog),
        );
      }
    }
    if (!mounted) return;
    if (!identical(config, ref.read(promptAssistantConfigProvider))) {
      return _refresh();
    }
    bool unchanged(String id) =>
        fingerprints.containsKey(id) && fingerprints[id] == _fingerprints[id];
    for (final id in _fingerprints.keys) {
      if (unchanged(id)) continue;
      for (final key in _testSequence.keys.where((k) => k.$1 == id).toList()) {
        _testSequence[key] = _testSequence[key]! + 1;
      }
      _catalogSequence[id] = (_catalogSequence[id] ?? 0) + 1;
    }
    for (final key in _testSequence.keys.toList()) {
      if (key.$2 != null && settings[key.$1]?.model(key.$2!) == null) {
        _testSequence[key] = _testSequence[key]! + 1;
      }
    }
    state = ProvidersWorkbenchState(
      settings: settings,
      masked: masked,
      connections: {
        for (final e in state.connections.entries)
          if (unchanged(e.key)) e.key: e.value,
      },
      models: {
        for (final e in state.models.entries)
          if (unchanged(e.key.$1) &&
              settings[e.key.$1]?.model(e.key.$2) != null)
            e.key: e.value,
      },
      catalogs: {
        ...cached,
        for (final e in state.catalogs.entries)
          if (unchanged(e.key)) e.key: e.value,
      },
    );
    _fingerprints
      ..clear()
      ..addAll(fingerprints);
  }

  Future<ProviderSettings> readSettings(String id) async {
    final p = provider(id);
    final headers = await controller.getProviderHeaders(id);
    final models = <ModelConfig>[];
    for (final m
        in ref
            .read(promptAssistantConfigProvider)
            .modelsForProvider(providerId: id)) {
      models.add(
        await controller.loadModelRequestOverrides(
          m.copyWith(clearRequestOverrides: true),
        ),
      );
    }
    return projectProviderSettings(p, models, headers);
  }

  Future<ProvidersSaveResult> save({
    required String providerId,
    required ProviderSettings base,
    required ProviderSettings edited,
    String? apiKey,
  }) async {
    try {
      final observed = ref.read(promptAssistantConfigProvider);
      if (!observed.providers.any((p) => p.id == providerId)) {
        await refresh();
        return ProvidersSaveResult.conflict;
      }
      final latest = await readSettings(providerId);
      if (!identical(observed, ref.read(promptAssistantConfigProvider)) ||
          latest != base) {
        await refresh();
        return ProvidersSaveResult.conflict;
      }
      // Membership and order are instantaneous actions, not editable draft fields.
      if (!listEquals(
        edited.models.map((m) => m.id).toList(),
        latest.models.map((m) => m.id).toList(),
      )) {
        await refresh();
        return ProvidersSaveResult.conflict;
      }
      final p = mergeProviderSettings(provider(providerId), edited);
      final models = [
        for (final m in observed.modelsForProvider(providerId: providerId))
          if (m.isPlaceholder)
            m
          else
            mergeProviderModel(m, base.model(m.name)!, edited.model(m.name)!),
      ];
      validateProviderDraft(p, models);
      await controller.saveServiceDraft(
        provider: p,
        models: models,
        headers: providerHeaders(edited.headers),
        apiKey: apiKey,
        enrichModels: false,
      );
      await refresh();
      return ProvidersSaveResult.saved;
    } catch (_) {
      try {
        await refresh();
      } catch (_) {
        AppLogger.w(
          'Workbench secure projection could not be loaded.',
          'PromptAssistant',
        );
      }
      return ProvidersSaveResult.failed;
    }
  }

  Future<String> create(String presetId) async {
    final preset = ProviderPreset.values.byName(presetId);
    final normalized = preset.defaultName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final base = normalized.isEmpty ? preset.defaultId : normalized;
    var id = base, index = 2;
    while (ref
        .read(promptAssistantConfigProvider)
        .providers
        .any((p) => p.id == id)) {
      id = '${base}_${index++}';
    }
    await controller.upsertProvider(preset.createConfig(id: id));
    await refresh();
    return id;
  }

  Future<void> enabled(String id, bool value) async {
    await controller.upsertProvider(provider(id).copyWith(enabled: value));
    await refresh();
  }

  Future<void> addModels(
    String id,
    List<String> ids, {
    bool manual = false,
  }) async {
    await controller.addProviderModels(id, ids, manual: manual);
    await refresh();
  }

  Future<void> reorder(String id, List<String> ids) async {
    await controller.reorderProviderModels(id, ids);
    await refresh();
  }

  Future<void> removeModel(String id, String modelId) async {
    final model = ref
        .read(promptAssistantConfigProvider)
        .models
        .where((m) => m.providerId == id && m.name == modelId)
        .firstOrNull;
    if (model != null) await controller.deleteModel(model);
    await _clearAgentSelection(id, modelId);
    await refresh();
  }

  Future<void> delete(String id) async {
    await controller.deleteProvider(id);
    await _clearAgentSelection(id, null);
    await refresh();
  }

  Future<void> _clearAgentSelection(String id, String? modelId) async {
    // Patch the existing store without creating a workspace or starting Agent.
    final store = ref.read(naiAgentWorkspaceStoreProvider);
    final settings = await store.readSettings();
    if (settings.providerId != id ||
        (modelId != null && settings.modelId != modelId)) {
      return;
    }
    final expected = {'providerId': id, 'modelId': settings.modelId};
    final changes = {'providerId': '', 'modelId': ''};
    if (ref.exists(naiAgentControllerProvider)) {
      await ref
          .read(naiAgentControllerProvider)
          .updateSettings(changes, expected: expected);
    } else {
      final updated = await store.patchSettingsChecked(
        changes,
        expected: expected,
      );
      if (ref.exists(naiAgentUiPreferencesProvider)) {
        ref.read(naiAgentUiPreferencesProvider).replace(updated);
      }
    }
  }

  Future<void> test(
    String id,
    ProviderSettings edited,
    String? apiKey, {
    String? modelId,
  }) async {
    final testId = (id, modelId);
    final sequence = (_testSequence[testId] ?? 0) + 1;
    _testSequence[testId] = sequence;
    void publish(WorkbenchConnectionTest connection, WorkbenchModelTest model) {
      if (!mounted ||
          _testSequence[testId] != sequence ||
          !ref
              .read(promptAssistantConfigProvider)
              .providers
              .any((p) => p.id == id)) {
        return;
      }
      state = ProvidersWorkbenchState(
        settings: state.settings,
        masked: state.masked,
        catalogs: state.catalogs,
        connections: {
          ...state.connections,
          if (modelId == null) id: connection,
        },
        models: {...state.models, if (modelId != null) (id, modelId): model},
      );
    }

    publish(
      const WorkbenchConnectionTest(testing: true),
      WorkbenchModelTest(
        testing: true,
        lastTest: state.models[(id, modelId)]?.lastTest,
      ),
    );
    final clock = Stopwatch()..start();
    ProviderConnectionProbe? probe;
    final health = ref.read(providerConnectionHealthProvider);
    try {
      final savedSettings = await readSettings(id);
      final p = mergeProviderSettings(provider(id), edited);
      final key = apiKey ?? await controller.getProviderApiKey(id);
      final headers = providerHeaders(edited.headers);
      final savedFingerprint = await _savedFingerprint(id);
      if (savedFingerprint ==
          ProviderModelListCache.fingerprint(p, key, headers)) {
        probe = health.begin(p);
      }
      final service = ref.read(promptAssistantServiceProvider);
      final selectedId = modelId ?? edited.models.firstOrNull?.id;
      var reply = '';
      if (selectedId == null) {
        await service.fetchModelsForDraft(p, key, headers);
      } else {
        final saved = ref
            .read(promptAssistantConfigProvider)
            .models
            .firstWhere((m) => m.providerId == id && m.name == selectedId);
        final model = mergeProviderModel(
          saved,
          savedSettings.model(selectedId)!,
          edited.model(selectedId)!,
        );
        validateProviderDraft(p, [model]);
        reply = await service.testModelForDraft(p, model, key, headers);
      }
      health.succeeded(probe);
      final at = DateTime.now();
      publish(
        WorkbenchConnectionTest(
          result: ProviderConnectionResult(
            status: ProviderConnectionStatus.healthy,
            checkedAt: at,
          ),
          latencyMs: clock.elapsedMilliseconds,
        ),
        WorkbenchModelTest(
          lastTest: ProviderTestResult(
            ok: true,
            latencyMs: clock.elapsedMilliseconds,
            message: reply.characters.take(120).toString(),
            at: at,
          ),
        ),
      );
    } catch (error) {
      health.failed(probe, error);
      final result = connectionFailure(error);
      publish(
        WorkbenchConnectionTest(
          result: result,
          latencyMs: clock.elapsedMilliseconds,
        ),
        WorkbenchModelTest(
          lastTest: ProviderTestResult(
            ok: false,
            message: connectionError(result, currentL10n),
            at: result.checkedAt,
            latencyMs: clock.elapsedMilliseconds,
          ),
        ),
      );
      rethrow;
    }
  }

  Future<String> _savedFingerprint(String id) async {
    final p = provider(id);
    return ProviderModelListCache.fingerprint(
      p,
      await controller.getProviderApiKey(id),
      await controller.getProviderHeaders(id),
    );
  }

  Future<void> fetchCatalog(String id) async {
    final sequence = (_catalogSequence[id] ?? 0) + 1;
    _catalogSequence[id] = sequence;
    final old = state.catalogs[id] ?? const ProviderCatalog();
    void publish(ProviderCatalog catalog) {
      if (!mounted ||
          _catalogSequence[id] != sequence ||
          !ref
              .read(promptAssistantConfigProvider)
              .providers
              .any((p) => p.id == id)) {
        return;
      }
      state = ProvidersWorkbenchState(
        settings: state.settings,
        masked: state.masked,
        connections: state.connections,
        models: state.models,
        catalogs: {...state.catalogs, id: catalog},
      );
    }

    publish(
      ProviderCatalog(
        state: ProviderCatalogState.loading,
        entries: old.entries,
        fetchedAt: old.fetchedAt,
      ),
    );
    try {
      final p = provider(id);
      final key = await controller.getProviderApiKey(id);
      final headers = await controller.getProviderHeaders(id);
      final fingerprint = ProviderModelListCache.fingerprint(p, key, headers);
      final names = await ref
          .read(promptAssistantServiceProvider)
          .fetchModelsForDraft(p, key, headers);
      if (fingerprint != await _savedFingerprint(id)) {
        throw StateError(currentL10n.modelConfig_changedSaveAgain);
      }
      if (_catalogSequence[id] != sequence) return;
      final catalog =
          ModelCatalogRepository.cached ?? await ModelCatalogRepository.load();
      final stored = await ref
          .read(providerModelListCacheProvider)
          .save(id, fingerprint, names);
      if (!stored) throw StateError(currentL10n.mp_catalogCacheFailed);
      if (fingerprint != await _savedFingerprint(id)) return;
      publish(
        ProviderCatalog(
          state: ProviderCatalogState.ready,
          entries: catalogEntries(p, names, catalog),
          fetchedAt: DateTime.now(),
        ),
      );
    } catch (error) {
      publish(
        ProviderCatalog(
          state: ProviderCatalogState.failed,
          entries: old.entries,
          fetchedAt: old.fetchedAt,
          error: connectionError(connectionFailure(error), currentL10n),
        ),
      );
      rethrow;
    }
  }
}

String maskProviderKey(String? key) {
  if (key == null || key.isEmpty) return '';
  // Short keys must not accidentally be exposed in full by overlapping ends.
  return key.length <= 7
      ? '••••••••'
      : '${key.substring(0, 3)}••••${key.substring(key.length - 4)}';
}

SettingsTone connectionTone(ProviderConnectionResult result) =>
    switch (result.status) {
      ProviderConnectionStatus.healthy => SettingsTone.ok,
      ProviderConnectionStatus.limited => SettingsTone.warn,
      ProviderConnectionStatus.failed => SettingsTone.error,
      _ => SettingsTone.idle,
    };

ProviderConnectionResult connectionFailure(Object error) {
  final code = error is DioException ? error.response?.statusCode : null;
  final type = error is DioException ? error.type : null;
  return ProviderConnectionResult(
    status: code == 429
        ? ProviderConnectionStatus.limited
        : ProviderConnectionStatus.failed,
    checkedAt: DateTime.now(),
    statusCode: code,
    issue: code == 401
        ? ProviderConnectionIssue.authentication
        : code == 403
        ? ProviderConnectionIssue.permission
        : {
            DioExceptionType.connectionTimeout,
            DioExceptionType.sendTimeout,
            DioExceptionType.receiveTimeout,
          }.contains(type)
        ? ProviderConnectionIssue.timeout
        : {
            DioExceptionType.connectionError,
            DioExceptionType.badCertificate,
          }.contains(type)
        ? ProviderConnectionIssue.network
        : code != null
        ? ProviderConnectionIssue.httpError
        : ProviderConnectionIssue.invalidResponse,
  );
}

String connectionError(ProviderConnectionResult result, AppLocalizations l) {
  if (result.status == ProviderConnectionStatus.healthy ||
      result.status == ProviderConnectionStatus.unverified) {
    return '';
  }
  if (result.statusCode == null) return result.descriptionIn(l);
  final reason = result.statusCode == 429
      ? l.mp_errorRateLimit
      : switch (result.issue) {
          ProviderConnectionIssue.authentication => l.mp_errorAuthentication,
          ProviderConnectionIssue.permission => l.mp_errorPermission,
          ProviderConnectionIssue.timeout => l.mp_errorTimeout,
          ProviderConnectionIssue.network => l.mp_errorNetwork,
          ProviderConnectionIssue.invalidResponse => l.mp_errorResponse,
          _ => l.mp_errorHttp,
        };
  return '${result.statusCode} · $reason';
}

List<ProviderCatalogEntry> catalogEntries(
  ProviderConfig p,
  List<String> ids,
  ModelCatalogRepository? catalog,
) => [
  for (final id in ids.toSet())
    ProviderCatalogEntry(
      id: id,
      contextWindow: catalog?.lookup(p.preset, id)?.contextLimit,
      price: providerCatalogPrice(catalog?.lookup(p.preset, id)),
      retired: {
        'deprecated',
        'retired',
      }.contains(catalog?.lookup(p.preset, id)?.status),
    ),
];

ProvidersViewData providersViewData(
  PromptAssistantConfigState config,
  ProvidersWorkbenchState state,
  ProviderConnectionHealth health,
  AppLocalizations l,
) => ProvidersViewData(
  providers: [
    for (final p in config.providers)
      ProviderItem(
        id: p.id,
        settings:
            state.settings[p.id] ??
            projectProviderSettings(
              p,
              config.modelsForProvider(providerId: p.id),
              const {},
            ),
        presetId: p.preset?.name,
        group: providerGroup(p.preset),
        logoAsset: p.preset?.logoAsset,
        mark: providerUsesMark(p)
            ? p.name.characters.take(2).toString().toUpperCase()
            : null,
        color: 0xff266eff,
        enabled: p.enabled,
        local: p.preset?.isLocal ?? (p.type == ProviderType.ollama),
        apiKeyMasked:
            state.masked[p.id] ??
            (config.providerHasApiKey[p.id] == true ? '••••••••' : ''),
        status: connectionTone(
          state.connections[p.id]?.result ?? health.resultFor(p.id),
        ),
        latencyMs: state.connections[p.id]?.latencyMs,
        checkedAt: (state.connections[p.id]?.result ?? health.resultFor(p.id))
            .checkedAt,
        testing: state.connections[p.id]?.testing ?? false,
        error: connectionError(
          state.connections[p.id]?.result ?? health.resultFor(p.id),
          l,
        ),
        hint: p.preset?.connectionHintIn(l) ?? '',
        models: {
          for (final m in config.modelsForProvider(providerId: p.id))
            if (!m.isPlaceholder)
              m.name: ProviderModelInfo(
                detail:
                    m.catalogEntry?.name ??
                    (m.displayName == m.name ? '' : m.displayName),
                retired: {
                  'deprecated',
                  'retired',
                }.contains(m.catalogEntry?.status),
                usedFor: {
                  for (final task in LauncherInterface.values)
                    if (config.interfaceFor(task).providerId == p.id &&
                        config.interfaceFor(task).model == m.name)
                      settingsTaskKind(task),
                },
                testing: state.models[(p.id, m.name)]?.testing ?? false,
                lastTest: state.models[(p.id, m.name)]?.lastTest,
              ),
        },
      ),
  ],
  protocols: [
    for (final p in ProviderProtocol.values)
      ProvidersProtocol(
        id: p.name,
        label: p.label,
        reasoningLevels: p.supportedReasoningEfforts,
      ),
  ],
  presets: [
    for (final p in ProviderPresetDefaults.selectable)
      ProviderPresetItem(
        id: p.name,
        name: p.labelIn(l),
        group: providerGroup(p),
        host: p == ProviderPreset.openaiCompatibleChat
            ? ''
            : Uri.tryParse(p.defaultBaseUrl)?.host ?? '',
        logoAsset: p.logoAsset,
        custom: p == ProviderPreset.openaiCompatibleChat,
      ),
  ],
  catalogs: state.catalogs,
);

ProvidersActions workbenchActions(
  ProvidersWorkbench backend,
  void Function(FutureOr<void> Function()) run,
) => ProvidersActions(
  onCreate: (preset) async {
    try {
      return await backend.create(preset);
    } catch (_) {
      run(() => throw StateError(currentL10n.styleExplore_operationFailed));
      return null;
    }
  },
  onEnabled: (id, value) => run(() => backend.enabled(id, value)),
  onTest: (id, edited, key) => run(() => backend.test(id, edited, key)),
  onTestModel: (id, model, edited, key) =>
      run(() => backend.test(id, edited, key, modelId: model)),
  onSave: backend.save,
  onRevealApiKey: (id) async {
    try {
      return await backend.controller.getProviderApiKey(id);
    } catch (_) {
      run(() => throw StateError(currentL10n.styleExplore_operationFailed));
      return null;
    }
  },
  onFetchCatalog: (id) => run(() => backend.fetchCatalog(id)),
  onAddModels: (id, ids, {manual = false}) =>
      run(() => backend.addModels(id, ids, manual: manual)),
  onRemoveModel: (id, model) => run(() => backend.removeModel(id, model)),
  onReorderModels: (id, ids) => run(() => backend.reorder(id, ids)),
  onDelete: (id) => run(() => backend.delete(id)),
);
