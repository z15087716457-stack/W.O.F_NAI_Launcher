import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/prompt_assistant_models.dart';

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
  }

  final Ref _ref;

  LocalStorageService get _local => _ref.read(localStorageServiceProvider);
  SecureStorageService get _secure => _ref.read(secureStorageServiceProvider);

  Future<void> _load() async {
    final raw = _local.getSetting<String>(
      StorageKeys.promptAssistantConfigJson,
    );
    if (raw != null && raw.isNotEmpty) {
      try {
        state = PromptAssistantConfigState.decode(raw);
      } catch (_) {
        state = PromptAssistantConfigState.defaults();
      }
    }

    final keyMap = <String, bool>{};
    for (final provider in state.providers) {
      final key = await _secure.getPromptAssistantApiKey(provider.id);
      keyMap[provider.id] = key != null && key.isNotEmpty;
    }
    state = state.copyWith(providerHasApiKey: keyMap);
  }

  Future<void> _save() async {
    await _local.setSetting(
      StorageKeys.promptAssistantConfigJson,
      state.encode(),
    );
  }

  Future<String?> getProviderApiKey(String providerId) async {
    return _secure.getPromptAssistantApiKey(providerId);
  }

  Future<void> setProviderApiKey(String providerId, String apiKey) async {
    final trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      await _secure.deletePromptAssistantApiKey(providerId);
    } else {
      await _secure.savePromptAssistantApiKey(providerId, trimmed);
    }
    final next = Map<String, bool>.from(state.providerHasApiKey)
      ..[providerId] = trimmed.isNotEmpty;
    state = state.copyWith(providerHasApiKey: next);
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
    final providers = state.providers.where((p) => p.id != providerId).toList();
    final models = state.models
        .where((m) => m.providerId != providerId)
        .toList();
    final interfaces = Map<LauncherInterface, InterfaceSlotConfig>.from(
      state.interfaces,
    )..removeWhere((_, slot) => slot.providerId == providerId);
    final keys = Map<String, bool>.from(state.providerHasApiKey)
      ..remove(providerId);
    state = state.copyWith(
      providers: providers,
      models: models,
      interfaces: interfaces,
      providerHasApiKey: keys,
    );
    await _secure.deletePromptAssistantApiKey(providerId);
    await _save();
  }

  Future<void> upsertModel(ModelConfig model) async {
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
          ModelConfig(
            providerId: providerId,
            name: name,
            displayName: name,
            source: ModelSource.api,
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

    state = state.copyWith(models: models, interfaces: interfaces);
    await _save();
    return removed.toList();
  }

  Future<void> deleteModel(ModelConfig model) async {
    final models = [...state.models]
      ..removeWhere(
        (m) => m.providerId == model.providerId && m.name == model.name,
      );
    state = state.copyWith(models: models);
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
      InterfaceSlotConfig(providerId: providerId, model: firstReal?.name ?? ''),
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
      InterfaceSlotConfig(providerId: providerId, model: model),
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
    if (slot.isConfigured) {
      interfaces[interface] = slot;
    } else {
      interfaces.remove(interface);
    }
    state = state.copyWith(interfaces: interfaces);
  }
}
