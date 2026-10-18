import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/prompt_assistant_models.dart';
import '../models/model_request_overrides.dart';
import '../models/prompt_task_definitions.dart';
import '../services/model_catalog_repository.dart';
import '../services/provider_model_list_cache.dart';
import 'provider_connection_health_provider.dart';
import '../../../core/utils/localization_extension.dart';

final promptAssistantConfigProvider =
    StateNotifierProvider<
      PromptAssistantConfigNotifier,
      PromptAssistantConfigState
    >((ref) => PromptAssistantConfigNotifier(ref));

class PromptAssistantConfigNotifier
    extends StateNotifier<PromptAssistantConfigState> {
  PromptAssistantConfigNotifier(this._ref)
    : super(PromptAssistantConfigState.defaults()) {
    _load();
    // Health stays independent of config so credential writes can invalidate it.
    addListener((config) {
      _ref
          .read(providerConnectionHealthProvider)
          .updateProviders(config.providers);
    });
  }

  final Ref _ref;
  ModelCatalogRepository? _catalog;
  Future<void> _pendingServiceChange = Future.value();

  LocalStorageService get _local => _ref.read(localStorageServiceProvider);
  SecureStorageService get _secure => _ref.read(secureStorageServiceProvider);

  Future<void> _load() async {
    var loaded = state;
    final raw = _local.getSetting<String>(
      StorageKeys.promptAssistantConfigJson,
    );
    if (raw != null && raw.isNotEmpty) {
      try {
        loaded = PromptAssistantConfigState.decode(raw);
      } catch (_) {
        loaded = PromptAssistantConfigState.defaults();
      }
    }

    state = loaded;
    try {
      _catalog =
          ModelCatalogRepository.cached ?? await ModelCatalogRepository.load();
    } catch (error) {
      AppLogger.w('Local model catalog unavailable: $error', 'PromptAssistant');
    }
    if (!mounted) return;
    final current = state;
    state = current.copyWith(
      models: [
        for (final model in current.models) _enrich(model, current.providers),
      ],
    );

    final observed = state;
    final keyMap = <String, bool>{};
    for (final provider in observed.providers) {
      final key = await _secure.getPromptAssistantApiKey(provider.id);
      if (!mounted) return;
      keyMap[provider.id] = key != null && key.isNotEmpty;
    }
    if (mounted && identical(state, observed)) {
      state = state.copyWith(providerHasApiKey: keyMap);
    }
  }

  ModelConfig _enrich(ModelConfig model, [List<ProviderConfig>? providers]) {
    final provider = (providers ?? state.providers)
        .where((p) => p.id == model.providerId)
        .firstOrNull;
    return _catalog?.enrich(
          model,
          provider?.preset,
          protocol: provider?.protocol,
        ) ??
        model;
  }

  Future<void> _save() async {
    await _local.setSetting(
      StorageKeys.promptAssistantConfigJson,
      state.encode(),
    );
  }

  Future<void> _persistDraft(PromptAssistantConfigState next) async {
    final observed = state;
    try {
      await _local.setSetting(
        StorageKeys.promptAssistantConfigJson,
        next.encode(),
      );
    } catch (_) {
      if (mounted) {
        try {
          await _save();
        } catch (_) {
          AppLogger.w('Configuration rollback failed.', 'PromptAssistant');
        }
      }
      rethrow;
    }
    if (!identical(state, observed)) {
      await _local.setSetting(
        StorageKeys.promptAssistantConfigJson,
        state.encode(),
      );
      throw StateError(currentL10n.modelConfig_changedSaveAgain);
    }
    if (mounted) state = next;
  }

  Future<String?> getProviderApiKey(String providerId) async {
    return _secure.getPromptAssistantApiKey(providerId);
  }

  Future<Map<String, String>> getProviderHeaders(String providerId) async {
    final raw = await _secure.getPromptAssistantHeaders(providerId);
    if (raw == null || raw.isEmpty) return const {};
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return const {};
    return decoded.map((key, value) => MapEntry('$key', '$value'));
  }

  Future<void> setProviderHeaders(
    String providerId,
    Map<String, String> headers,
  ) async {
    final previous = await _secure.getPromptAssistantHeaders(providerId);
    if (headers.isEmpty) {
      await _secure.deletePromptAssistantHeaders(providerId);
    } else {
      await _secure.savePromptAssistantHeaders(providerId, jsonEncode(headers));
    }
    if (previous != (headers.isEmpty ? null : jsonEncode(headers))) {
      await _invalidateConnection(providerId);
    }
  }

  String _modelOptionsKey(ModelConfig model) =>
      'model/${Uri.encodeComponent(model.providerId)}/${Uri.encodeComponent(model.name)}';

  Future<ModelConfig> loadModelRequestOverrides(ModelConfig model) async {
    if (model.requestOverrides != null) return model;
    final raw = model.hasRequestOverrides
        ? await _secure.getPromptAssistantHeaders(_modelOptionsKey(model))
        : null;
    return model.copyWith(
      requestOverrides: raw == null || raw.isEmpty
          ? ModelRequestOverrides.empty
          : ModelRequestOverrides.decode(raw),
    );
  }

  Future<void> _writeOptions(String key, String? raw) => raw == null
      ? _secure.deletePromptAssistantHeaders(key)
      : _secure.savePromptAssistantHeaders(key, raw);

  Future<void> _saveModelOptions(ModelConfig model) async {
    final options = model.requestOverrides;
    if (options == null) return;
    final error = options.validate(model.name);
    if (error != null) throw FormatException(error);
    await _writeOptions(
      _modelOptionsKey(model),
      options.isEmpty ? null : options.encode(),
    );
  }

  /// Publish the draft only after configuration and secure values are written.
  /// A failed save keeps both the previous service and the editable draft.
  Future<void> saveServiceDraft({
    required ProviderConfig provider,
    required List<ModelConfig> models,
    required Map<String, String> headers,
    String? apiKey,
    // Workbench drafts are merged onto the latest enriched models already;
    // re-enriching here would overwrite hidden fields the contract cannot edit.
    bool enrichModels = true,
  }) async {
    final observed = state;
    final providers = [...observed.providers];
    final index = providers.indexWhere((p) => p.id == provider.id);
    if (index < 0) {
      providers.add(provider.copyWith(requestHeaders: const {}));
    } else {
      providers[index] = provider.copyWith(requestHeaders: const {});
    }
    final selected = [
      for (final m in models) enrichModels ? _enrich(m, providers) : m,
    ];
    final names = selected.map((m) => m.name).toSet();
    for (final m in selected) {
      final error =
          m.requestOverrides?.validate(m.name) ??
          RequestParameters.fromModel(m).validateFor(provider.protocol);
      if (error != null) throw FormatException(error);
    }
    final next = observed.copyWith(
      providers: providers,
      models: [
        for (final m in observed.models)
          if (m.providerId != provider.id) m,
        ...selected,
      ],
      interfaces: {
        for (final e in observed.interfaces.entries)
          e.key:
              e.value.providerId == provider.id &&
                  e.value.model.isNotEmpty &&
                  !names.contains(e.value.model)
              ? e.value.copyWith(providerId: '', model: '')
              : e.value,
      },
      providerHasApiKey: {
        ...observed.providerHasApiKey,
        if (apiKey != null) provider.id: apiKey.trim().isNotEmpty,
      },
    );
    final writes = <String, String?>{
      provider.id: headers.isEmpty ? null : jsonEncode(headers),
      for (final m in selected)
        if (m.requestOverrides != null)
          _modelOptionsKey(m): m.requestOverrides!.isEmpty
              ? null
              : m.requestOverrides!.encode(),
      for (final m in observed.models)
        if (m.providerId == provider.id &&
            m.hasRequestOverrides &&
            !names.contains(m.name))
          _modelOptionsKey(m): null,
    };
    await _commitServiceChange(
      observed: observed,
      next: next,
      providerId: provider.id,
      options: writes,
      apiKey: apiKey,
    );
  }

  /// Serialize service writes so a stale save cannot roll back a newer save's
  /// credentials. Publish only after both secure values and config succeed.
  Future<void> _commitServiceChange({
    required PromptAssistantConfigState observed,
    required PromptAssistantConfigState next,
    required String providerId,
    required Map<String, String?> options,
    String? apiKey,
  }) {
    final operation = _pendingServiceChange.then<void>((_) async {
      void checkCurrent() {
        if (!mounted || !identical(state, observed)) {
          throw StateError(currentL10n.modelConfig_changedSaveAgain);
        }
      }

      checkCurrent();
      final before = <String, String?>{};
      for (final key in options.keys) {
        before[key] = await _secure.getPromptAssistantHeaders(key);
      }
      final oldKey = apiKey == null
          ? null
          : await _secure.getPromptAssistantApiKey(providerId);
      checkCurrent();
      final attempted = <String>[];
      var keyAttempted = false;
      try {
        for (final entry in options.entries) {
          attempted.add(entry.key);
          await _writeOptions(entry.key, entry.value);
        }
        if (apiKey != null) {
          keyAttempted = true;
          await _writeApiKey(providerId, apiKey.trim());
        }
        checkCurrent();
        await _persistDraft(next);
        if (mounted &&
            (before[providerId] != options[providerId] ||
                (apiKey != null && apiKey.trim() != (oldKey?.trim() ?? '')) ||
                _connectionRoute(observed.providers, providerId) !=
                    _connectionRoute(next.providers, providerId))) {
          await _invalidateConnection(providerId);
        }
      } catch (_) {
        // A storage call may throw after writing. Restore every attempted key,
        // and keep restoring the rest if one rollback call also fails.
        for (final key in attempted.reversed) {
          try {
            await _writeOptions(key, before[key]);
          } catch (_) {
            AppLogger.w('Service options rollback failed.', 'PromptAssistant');
          }
        }
        if (keyAttempted) {
          try {
            await _writeApiKey(providerId, oldKey);
          } catch (_) {
            AppLogger.w('Service key rollback failed.', 'PromptAssistant');
          }
        }
        rethrow;
      }
    });
    _pendingServiceChange = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> _writeApiKey(String providerId, String? value) =>
      value == null || value.isEmpty
      ? _secure.deletePromptAssistantApiKey(providerId)
      : _secure.savePromptAssistantApiKey(providerId, value);

  String _connectionRoute(List<ProviderConfig> providers, String id) {
    final provider = providers.where((item) => item.id == id).firstOrNull;
    return jsonEncode(
      provider == null
          ? null
          : [
              (provider.preset ?? ProviderPreset.openaiCompatibleChat).name,
              provider.protocol.name,
              provider.baseUrl.trim(),
            ],
    );
  }

  Future<void> _invalidateConnection(String providerId) async {
    if (!mounted) return;
    _ref.read(providerConnectionHealthProvider).invalidate(providerId);
    await _ref.read(providerModelListCacheProvider).remove(providerId);
  }

  Future<void> setProviderApiKey(String providerId, String apiKey) async {
    final trimmed = apiKey.trim();
    final previous = await _secure.getPromptAssistantApiKey(providerId);
    await _writeApiKey(providerId, trimmed);
    final next = Map<String, bool>.from(state.providerHasApiKey)
      ..[providerId] = trimmed.isNotEmpty;
    state = state.copyWith(providerHasApiKey: next);
    if (trimmed != (previous?.trim() ?? '')) {
      await _invalidateConnection(providerId);
    }
  }

  Future<void> upsertProvider(ProviderConfig provider) async {
    final previousRoute = _connectionRoute(state.providers, provider.id);
    final providers = [...state.providers];
    final idx = providers.indexWhere((p) => p.id == provider.id);
    if (idx >= 0) {
      providers[idx] = provider;
    } else {
      providers.add(provider);
    }
    state = state.copyWith(providers: providers);
    await _save();
    if (previousRoute != _connectionRoute(state.providers, provider.id)) {
      await _invalidateConnection(provider.id);
    }
  }

  Future<void> deleteProvider(String providerId) async {
    final observed = state;
    final keys = Map<String, bool>.from(observed.providerHasApiKey)
      ..remove(providerId);
    await _commitServiceChange(
      observed: observed,
      providerId: providerId,
      apiKey: '',
      options: {
        for (final model in observed.models)
          if (model.providerId == providerId && model.hasRequestOverrides)
            _modelOptionsKey(model): null,
        providerId: null,
      },
      next: observed.copyWith(
        providers: observed.providers.where((p) => p.id != providerId).toList(),
        models: observed.models
            .where((m) => m.providerId != providerId)
            .toList(),
        interfaces: {
          for (final entry in observed.interfaces.entries)
            entry.key: entry.value.providerId == providerId
                ? entry.value.copyWith(providerId: '', model: '')
                : entry.value,
        },
        providerHasApiKey: keys,
      ),
    );
  }

  /// Persist only models explicitly selected by the user. The remote catalog
  /// cache must never silently populate selected-model configuration.
  Future<void> replaceProviderModels(
    String providerId,
    List<ModelConfig> selected,
  ) async {
    for (final model in selected) {
      await _saveModelOptions(model);
    }
    for (final old in state.models) {
      if (old.providerId == providerId &&
          old.hasRequestOverrides &&
          !selected.any((m) => m.name == old.name)) {
        await _writeOptions(_modelOptionsKey(old), null);
      }
    }
    final names = <String>{};
    final models = [
      for (final model in state.models)
        if (model.providerId != providerId) model,
      for (final model in selected)
        if (model.providerId == providerId &&
            !model.isPlaceholder &&
            names.add(model.name))
          _enrich(model),
    ];
    final interfaces = Map<LauncherInterface, InterfaceSlotConfig>.from(
      state.interfaces,
    );
    for (final entry in interfaces.entries.toList()) {
      final slot = entry.value;
      if (slot.providerId == providerId &&
          slot.model.isNotEmpty &&
          !names.contains(slot.model)) {
        interfaces[entry.key] = slot.copyWith(providerId: '', model: '');
      }
    }
    state = state.copyWith(models: models, interfaces: interfaces);
    await _save();
  }

  /// Batch discovery is additive; it never removes selected models or writes
  /// their secure overrides. Load catalog facts before enriching new IDs.
  Future<void> addProviderModels(
    String providerId,
    List<String> ids, {
    bool manual = false,
  }) async {
    _catalog ??=
        ModelCatalogRepository.cached ?? await ModelCatalogRepository.load();
    if (!mounted) return;
    if (!state.providers.any((p) => p.id == providerId)) {
      throw StateError(currentL10n.modelConfig_modelChanged);
    }
    final models = [...state.models];
    final names = {
      for (final m in models)
        if (m.providerId == providerId) m.name,
    };
    for (final raw in ids) {
      final id = raw.trim();
      if (id.isEmpty || id == 'default-model' || !names.add(id)) continue;
      models.add(
        _enrich(
          ModelConfig(
            providerId: providerId,
            name: id,
            displayName: id,
            source: manual ? ModelSource.manual : ModelSource.api,
          ),
        ),
      );
    }
    state = state.copyWith(models: models);
    await _save();
  }

  /// Only real-model slots move. Placeholders, other providers, model metadata
  /// and secure request overrides retain their exact values.
  Future<void> reorderProviderModels(
    String providerId,
    List<String> ids,
  ) async {
    final selected = {
      for (final m in state.models)
        if (m.providerId == providerId && !m.isPlaceholder) m.name: m,
    };
    final ordered = <ModelConfig>[];
    for (final id in ids) {
      final model = selected.remove(id);
      if (model != null) ordered.add(model);
    }
    ordered.addAll(selected.values);
    var index = 0;
    state = state.copyWith(
      models: [
        for (final m in state.models)
          if (m.providerId == providerId && !m.isPlaceholder)
            ordered[index++]
          else
            m,
      ],
    );
    await _save();
  }

  Future<void> upsertModel(ModelConfig model) async {
    model = _enrich(model);
    await _saveModelOptions(model);
    final models = [...state.models];
    final idx = models.indexWhere(
      (m) => m.providerId == model.providerId && m.name == model.name,
    );
    if (idx >= 0) {
      models[idx] = model;
    } else {
      models.add(model);
    }
    state = state.copyWith(models: models);
    await _save();
  }

  /// 以供应商接口返回的 [modelNames] 为准，同步某供应商的模型列表：
  /// - 新增接口里出现、但本地缺失的模型（标记为 [ModelSource.api]）；
  /// - 删除本地 [ModelSource.api] 来源、但已不在接口列表里的“弃用”模型；
  /// - 保留所有 [ModelSource.manual]（手动/默认/占位）模型；
  /// - 指向被清理模型的接口槽恢复为“使用该服务商首个模型”。
  ///
  /// 返回被清理掉的弃用模型名（去重），便于 UI 反馈。
  Future<List<String>> syncProviderModels(
    String providerId,
    List<String> modelNames,
  ) async {
    final incoming = <String>[
      for (final name in modelNames)
        if (name.trim().isNotEmpty) name.trim(),
    ];
    if (incoming.isEmpty) return const [];
    final incomingSet = incoming.toSet();

    final removed = <String>{};
    final models = <ModelConfig>[];
    for (final model in state.models) {
      if (model.providerId != providerId) {
        models.add(model);
        continue;
      }
      final isStaleApiModel =
          model.source == ModelSource.api &&
          !model.isPlaceholder &&
          !incomingSet.contains(model.name);
      if (isStaleApiModel) {
        removed.add(model.name);
        continue;
      }
      models.add(model);
    }

    for (final name in incoming) {
      final exists = models.any(
        (m) => m.providerId == providerId && m.name == name,
      );
      if (!exists) {
        models.add(
          _enrich(
            ModelConfig(
              providerId: providerId,
              name: name,
              displayName: name,
              source: ModelSource.api,
            ),
          ),
        );
      }
    }

    final interfaces = Map<LauncherInterface, InterfaceSlotConfig>.from(
      state.interfaces,
    );
    for (final entry in interfaces.entries.toList()) {
      final slot = entry.value;
      if (slot.providerId != providerId || slot.model.isEmpty) continue;
      final stillExists = models.any(
        (m) => m.providerId == providerId && m.name == slot.model,
      );
      if (!stillExists) {
        interfaces[entry.key] = slot.copyWith(model: '');
      }
    }

    for (final old in state.models) {
      if (old.providerId == providerId &&
          removed.contains(old.name) &&
          old.hasRequestOverrides) {
        await _writeOptions(_modelOptionsKey(old), null);
      }
    }
    state = state.copyWith(models: models, interfaces: interfaces);
    await _save();
    return removed.toList();
  }

  Future<void> deleteModel(ModelConfig model) async {
    if (model.hasRequestOverrides) {
      await _writeOptions(_modelOptionsKey(model), null);
    }
    final models = [...state.models]
      ..removeWhere(
        (m) => m.providerId == model.providerId && m.name == model.name,
      );
    final interfaces = {
      for (final entry in state.interfaces.entries)
        entry.key:
            entry.value.providerId == model.providerId &&
                entry.value.model == model.name
            ? entry.value.copyWith(model: '')
            : entry.value,
    };
    state = state.copyWith(models: models, interfaces: interfaces);
    await _save();
  }

  /// 设置接口槽的服务商；模型自动落到该服务商的首个可用模型
  /// （无可用模型时记空串 = 执行端按“首个模型”语义回落）。
  Future<void> setInterfaceProvider(
    LauncherInterface interface,
    String providerId,
  ) async {
    final models = state.modelsForProvider(providerId: providerId);
    final firstReal = models.cast<ModelConfig?>().firstWhere(
      (model) => model != null && !model.isPlaceholder,
      orElse: () => null,
    );
    _setInterfaceSlot(
      interface,
      state
          .interfaceFor(interface)
          .copyWith(providerId: providerId, model: firstReal?.name ?? ''),
    );
    await _save();
  }

  Future<void> setInterfaceModel(
    LauncherInterface interface,
    String providerId,
    String model,
  ) async {
    _setInterfaceSlot(
      interface,
      state
          .interfaceFor(interface)
          .copyWith(providerId: providerId, model: model),
    );
    await _save();
  }

  void _setInterfaceSlot(
    LauncherInterface interface,
    InterfaceSlotConfig slot,
  ) {
    final interfaces = Map<LauncherInterface, InterfaceSlotConfig>.from(
      state.interfaces,
    );
    interfaces[interface] = slot;
    state = state.copyWith(interfaces: interfaces);
  }

  Future<void> saveInterface(
    LauncherInterface task,
    InterfaceSlotConfig slot,
  ) async {
    final preset = presetFor(
      state.copyWith(interfaces: {...state.interfaces, task: slot}),
      task,
    );
    if (slot.presetId != null && preset.id != slot.presetId) {
      throw StateError(currentL10n.modelConfig_presetChanged);
    }
    final provider = state.providers
        .where((item) => item.id == slot.providerId && item.enabled)
        .firstOrNull;
    if (slot.isConfigured && provider == null) {
      throw StateError(currentL10n.modelConfig_serviceDisabled);
    }
    if (slot.isConfigured &&
        !state.models.any(
          (model) =>
              model.providerId == slot.providerId &&
              model.name == slot.model &&
              !model.isPlaceholder,
        )) {
      throw StateError(currentL10n.modelConfig_modelChanged);
    }
    if (provider != null) {
      final model = state.models.firstWhere(
        (item) => item.providerId == provider.id && item.name == slot.model,
      );
      if (slot.reasoningEffort != null &&
          !model.availableReasoningEfforts.contains(slot.reasoningEffort)) {
        throw StateError(currentL10n.modelConfig_reasoningChanged);
      }
      final error = RequestParameters.fromModel(
        model,
      ).validateFor(provider.protocol);
      if (error != null) throw FormatException(error);
    }
    await _persistDraft(
      state.copyWith(interfaces: {...state.interfaces, task: slot}),
    );
  }

  Future<void> savePreset(
    TaskPresetConfig preset, {
    bool applyToInterface = false,
  }) async {
    if (preset.id.trim().isEmpty) {
      throw FormatException(currentL10n.modelConfig_presetIdRequired);
    }
    if (preset.id.startsWith('builtin:')) {
      throw StateError(currentL10n.modelConfig_saveBuiltinAsCustom);
    }
    if (preset.name.trim().isEmpty || preset.prompt.trim().isEmpty) {
      throw FormatException(currentL10n.modelConfig_namePromptRequired);
    }
    final next = state.copyWith(
      interfaces: applyToInterface
          ? {
              ...state.interfaces,
              preset.task: state
                  .interfaceFor(preset.task)
                  .copyWith(presetId: preset.id),
            }
          : state.interfaces,
      presets: [
        for (final item in state.presets)
          if (item.id != preset.id) item,
        preset,
      ],
    );
    await _persistDraft(next);
  }

  Future<void> deletePreset(String id) async {
    if (id.startsWith('builtin:')) {
      throw StateError(currentL10n.modelConfig_builtinNotDeletable);
    }
    final interfaces = {
      for (final entry in state.interfaces.entries)
        entry.key: entry.value.presetId == id
            ? entry.value.copyWith(presetId: 'builtin:${entry.key.name}')
            : entry.value,
    };
    await _persistDraft(
      state.copyWith(
        presets: state.presets.where((item) => item.id != id).toList(),
        interfaces: interfaces,
      ),
    );
  }

  Future<void> importConfiguration(String raw) async {
    final observed = state;
    final data = jsonDecode(raw);
    if (data is! Map || data['providers'] is! List || data['models'] is! List) {
      throw FormatException(currentL10n.modelConfig_pasteFullJson);
    }
    if (data['presets'] case final List presets) {
      if (presets.any(
        (preset) => preset is Map && '${preset['id']}'.startsWith('builtin:'),
      )) {
        throw FormatException(currentL10n.modelConfig_builtinNotOverwritable);
      }
    }
    final imported = PromptAssistantConfigState.decode(raw);
    final ids = <String>{};
    for (final provider in imported.providers) {
      final uri = Uri.tryParse(provider.baseUrl);
      if (provider.id.trim().isEmpty ||
          !ids.add(provider.id) ||
          provider.name.trim().isEmpty ||
          uri == null ||
          !uri.hasAuthority ||
          !['http', 'https'].contains(uri.scheme)) {
        throw FormatException(currentL10n.modelConfig_invalidProvider);
      }
    }
    for (final model in imported.models) {
      if (!ids.contains(model.providerId)) {
        throw FormatException(currentL10n.modelConfig_missingProvider);
      }
      final provider = imported.providers.firstWhere(
        (item) => item.id == model.providerId,
      );
      if (RequestParameters.fromModel(model).validateFor(provider.protocol)
          case final error?) {
        throw FormatException(error);
      }
    }
    final presetIds = <String>{};
    for (final preset in imported.presets) {
      if (preset.id.trim().isEmpty ||
          !presetIds.add(preset.id) ||
          preset.id.startsWith('builtin:') ||
          preset.name.trim().isEmpty ||
          preset.prompt.trim().isEmpty) {
        throw FormatException(currentL10n.modelConfig_invalidCustomPreset);
      }
    }
    final keys = <String, bool>{};
    for (final provider in imported.providers) {
      final key = await _secure.getPromptAssistantApiKey(provider.id);
      keys[provider.id] = key != null && key.isNotEmpty;
    }
    if (!identical(state, observed)) {
      throw StateError(currentL10n.modelConfig_changedImportAgain);
    }
    await _local.setSetting(
      '${StorageKeys.promptAssistantConfigJson}_before_import',
      observed.encode(),
    );
    if (!identical(state, observed)) {
      throw StateError(currentL10n.modelConfig_changedImportAgain);
    }
    await _persistDraft(
      imported.copyWith(
        providerHasApiKey: keys,
        models: [
          for (final model in imported.models)
            _enrich(model, imported.providers),
        ],
      ),
    );
  }
}
