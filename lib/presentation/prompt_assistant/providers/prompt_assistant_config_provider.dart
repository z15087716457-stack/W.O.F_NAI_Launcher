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
import 'provider_connection_health_provider.dart';

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
    await _local.setSetting(
      StorageKeys.promptAssistantConfigJson,
      next.encode(),
    );
    if (!identical(state, observed)) {
      await _local.setSetting(
        StorageKeys.promptAssistantConfigJson,
        state.encode(),
      );
      throw StateError('配置已变化，请重新保存。');
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
      _ref.read(providerConnectionHealthProvider).invalidate(providerId);
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
  }) async {
    final observed = state;
    final providers = [...observed.providers];
    final index = providers.indexWhere((p) => p.id == provider.id);
    if (index < 0) {
      providers.add(provider.copyWith(requestHeaders: const {}));
    } else {
      providers[index] = provider.copyWith(requestHeaders: const {});
    }
    final selected = [for (final m in models) _enrich(m, providers)];
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
    final before = <String, String?>{};
    for (final key in writes.keys) {
      before[key] = await _secure.getPromptAssistantHeaders(key);
    }
    final oldKey = apiKey == null
        ? null
        : await _secure.getPromptAssistantApiKey(provider.id);
    if (!identical(state, observed)) throw StateError('配置已变化，请重新保存。');
    final completed = <String>[];
    var keyWritten = false;
    try {
      for (final entry in writes.entries) {
        await _writeOptions(entry.key, entry.value);
        completed.add(entry.key);
      }
      if (apiKey != null) {
        if (apiKey.trim().isEmpty) {
          await _secure.deletePromptAssistantApiKey(provider.id);
        } else {
          await _secure.savePromptAssistantApiKey(provider.id, apiKey.trim());
        }
        keyWritten = true;
      }
      if (!identical(state, observed)) throw StateError('配置已变化，请重新保存。');
      await _local.setSetting(
        StorageKeys.promptAssistantConfigJson,
        next.encode(),
      );
      if (!identical(state, observed)) {
        await _local.setSetting(
          StorageKeys.promptAssistantConfigJson,
          state.encode(),
        );
        throw StateError('配置已变化，请重新保存。');
      }
      if (!mounted) return;
      state = next;
      if (before[provider.id] !=
              (headers.isEmpty ? null : jsonEncode(headers)) ||
          (apiKey != null && apiKey.trim() != (oldKey?.trim() ?? ''))) {
        _ref.read(providerConnectionHealthProvider).invalidate(provider.id);
      }
    } catch (_) {
      for (final key in completed.reversed) {
        await _writeOptions(key, before[key]);
      }
      if (keyWritten) {
        if (oldKey == null || oldKey.isEmpty) {
          await _secure.deletePromptAssistantApiKey(provider.id);
        } else {
          await _secure.savePromptAssistantApiKey(provider.id, oldKey);
        }
      }
      rethrow;
    }
  }

  Future<void> setProviderApiKey(String providerId, String apiKey) async {
    final trimmed = apiKey.trim();
    final previous = await _secure.getPromptAssistantApiKey(providerId);
    if (trimmed.isEmpty) {
      await _secure.deletePromptAssistantApiKey(providerId);
    } else {
      await _secure.savePromptAssistantApiKey(providerId, trimmed);
    }
    final next = Map<String, bool>.from(state.providerHasApiKey)
      ..[providerId] = trimmed.isNotEmpty;
    state = state.copyWith(providerHasApiKey: next);
    if (trimmed != (previous?.trim() ?? '')) {
      _ref.read(providerConnectionHealthProvider).invalidate(providerId);
    }
  }

  Future<void> upsertProvider(ProviderConfig provider) async {
    final providers = [...state.providers];
    final idx = providers.indexWhere((p) => p.id == provider.id);
    if (idx >= 0) {
      providers[idx] = provider;
    } else {
      providers.add(provider);
    }
    state = state.copyWith(providers: providers);
    await _save();
  }

  Future<void> deleteProvider(String providerId) async {
    for (final model in state.models.where((m) => m.providerId == providerId)) {
      if (model.hasRequestOverrides) {
        await _writeOptions(_modelOptionsKey(model), null);
      }
    }
    final providers = state.providers.where((p) => p.id != providerId).toList();
    final models = state.models
        .where((m) => m.providerId != providerId)
        .toList();
    final interfaces = Map<LauncherInterface, InterfaceSlotConfig>.from(
      state.interfaces,
    );
    for (final entry in interfaces.entries.toList()) {
      if (entry.value.providerId == providerId) {
        interfaces[entry.key] = entry.value.copyWith(providerId: '', model: '');
      }
    }
    final keys = Map<String, bool>.from(state.providerHasApiKey)
      ..remove(providerId);
    state = state.copyWith(
      providers: providers,
      models: models,
      interfaces: interfaces,
      providerHasApiKey: keys,
    );
    await _secure.deletePromptAssistantApiKey(providerId);
    try {
      await _secure.deletePromptAssistantHeaders(providerId);
    } catch (error) {
      AppLogger.w(
        'Failed to delete prompt assistant headers: $error',
        'PromptAssistant',
      );
    }
    await _save();
  }

  /// Persist only models explicitly selected by the user. The remote catalog
  /// is ephemeral and must never silently populate local configuration.
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
      throw StateError('所选预设已变化，请重新选择。');
    }
    final provider = state.providers
        .where((item) => item.id == slot.providerId && item.enabled)
        .firstOrNull;
    if (slot.isConfigured && provider == null) {
      throw StateError('所选服务已停用，请重新选择。');
    }
    if (slot.isConfigured &&
        !state.models.any(
          (model) =>
              model.providerId == slot.providerId &&
              model.name == slot.model &&
              !model.isPlaceholder,
        )) {
      throw StateError('所选模型已变化，请重新选择。');
    }
    if (provider != null) {
      final model = state.models.firstWhere(
        (item) => item.providerId == provider.id && item.name == slot.model,
      );
      if (slot.reasoningEffort != null &&
          !model.availableReasoningEfforts.contains(slot.reasoningEffort)) {
        throw StateError('模型支持的思考档位已变化，请重新选择或跟随模型。');
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
    if (preset.id.trim().isEmpty) throw const FormatException('预设 ID 不能为空。');
    if (preset.id.startsWith('builtin:')) throw StateError('请将内置方案另存为自定义预设。');
    if (preset.name.trim().isEmpty || preset.prompt.trim().isEmpty) {
      throw const FormatException('名称和提示词不能为空。');
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
    if (id.startsWith('builtin:')) throw StateError('内置规则不可删除。');
    final interfaces = {
      for (final entry in state.interfaces.entries)
        entry.key: entry.value.presetId == id
            ? entry.value.copyWith(presetId: 'builtin:${entry.key.name}')
            : entry.value,
    };
    state = state.copyWith(
      presets: state.presets.where((item) => item.id != id).toList(),
      interfaces: interfaces,
    );
    await _save();
  }

  Future<void> importConfiguration(String raw) async {
    final observed = state;
    final data = jsonDecode(raw);
    if (data is! Map || data['providers'] is! List || data['models'] is! List) {
      throw const FormatException('请粘贴完整的模型配置 JSON。');
    }
    if (data['presets'] case final List presets) {
      if (presets.any(
        (preset) => preset is Map && '${preset['id']}'.startsWith('builtin:'),
      )) {
        throw const FormatException('内置方案不可覆盖，请复制为自定义预设。');
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
        throw const FormatException('服务商 ID、名称或地址无效。');
      }
    }
    for (final model in imported.models) {
      if (!ids.contains(model.providerId)) {
        throw const FormatException('模型对应的服务商不存在。');
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
        throw const FormatException('自定义预设的 ID、名称或提示词无效。');
      }
    }
    final keys = <String, bool>{};
    for (final provider in imported.providers) {
      final key = await _secure.getPromptAssistantApiKey(provider.id);
      keys[provider.id] = key != null && key.isNotEmpty;
    }
    if (!identical(state, observed)) throw StateError('配置已变化，请重新导入。');
    await _local.setSetting(
      '${StorageKeys.promptAssistantConfigJson}_before_import',
      observed.encode(),
    );
    if (!identical(state, observed)) throw StateError('配置已变化，请重新导入。');
    state = imported.copyWith(
      providerHasApiKey: keys,
      models: [
        for (final model in imported.models) _enrich(model, imported.providers),
      ],
    );
    await _save();
  }
}
