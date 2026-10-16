import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/localization_extension.dart';
import '../../../l10n/app_localizations.dart';
import '../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../prompt_assistant/models/prompt_task_definitions.dart';
import '../../prompt_assistant/providers/model_request_history_provider.dart';
import '../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../prompt_assistant/providers/provider_connection_health_provider.dart';
import '../../prompt_assistant/services/prompt_assistant_service.dart';
import '../../prompt_assistant/services/provider_model_list_cache.dart';
import '../../screens/settings/widgets/ai_service_editor.dart';
import '../../screens/settings/widgets/model_preset_editor.dart';
import '../../screens/settings/widgets/model_request_details_dialog.dart';
import '../../screens/settings/widgets/provider_picker.dart';
import '../../ui/settings/settings_contract.dart';
import 'settings_dialogs.dart';

final settingsBusyProvider = StateProvider<Set<String>>((ref) => {});
final settingsProviderLatencies = StateProvider<Map<String, int>>((ref) => {});

LauncherInterface? settingsHistoryTask(String title) => LauncherInterface.values
    .where(
      (task) => AppLocalizations.supportedLocales.any(
        (locale) => task.titleIn(lookupAppLocalizations(locale)) == title,
      ),
    )
    .firstOrNull;

LauncherInterface settingsTask(SettingsModelTask task) => switch (task) {
  SettingsModelTask.promptTranslate => LauncherInterface.translate,
  SettingsModelTask.promptReverse => LauncherInterface.promptReverse,
  SettingsModelTask.tagTranslate => LauncherInterface.tagTranslate,
  SettingsModelTask.wikiTranslate => LauncherInterface.wikiTranslate,
};
SettingsModelTask settingsTaskKind(LauncherInterface task) => switch (task) {
  LauncherInterface.translate => SettingsModelTask.promptTranslate,
  LauncherInterface.promptReverse => SettingsModelTask.promptReverse,
  LauncherInterface.tagTranslate => SettingsModelTask.tagTranslate,
  LauncherInterface.wikiTranslate => SettingsModelTask.wikiTranslate,
};

SettingsModelsData settingsModelsData(BuildContext context, WidgetRef ref) {
  final config = ref.watch(promptAssistantConfigProvider);
  final health = ref.watch(providerConnectionHealthProvider);
  final busy = ref.watch(settingsBusyProvider);
  final latencies = ref.watch(settingsProviderLatencies);
  final history = ref.watch(modelRequestHistoryProvider).records;
  final assignments = [
    for (final task in LauncherInterface.values)
      SettingsTaskAssignment(
        task: settingsTaskKind(task),
        providerId: config.interfaceFor(task).providerId,
        modelId: config.interfaceFor(task).model,
        presetId: presetFor(config, task).id,
        fallback: !config.interfaceFor(task).isConfigured,
        reasoningEffort: config.interfaceFor(task).reasoningEffort,
      ),
  ];
  return SettingsModelsData(
    providers: [
      for (final provider in config.providers)
        SettingsProvider(
          id: provider.id,
          name: provider.name,
          protocol: provider.protocol.label,
          mark:
              provider.preset == null ||
                  provider.preset == ProviderPreset.openaiCompatibleChat ||
                  provider.preset == ProviderPreset.openaiCompatibleResponses
              ? provider.name.characters.take(2).toString().toUpperCase()
              : null,
          logoAsset: provider.preset?.logoAsset,
          color: 0xff266eff,
          enabled: provider.enabled,
          local: provider.type == ProviderType.ollama,
          baseUrl: provider.baseUrl,
          apiKeyMasked: config.providerHasApiKey[provider.id] == true
              ? '••••••••'
              : '',
          status: switch (health.resultFor(provider.id).status) {
            ProviderConnectionStatus.healthy => SettingsTone.ok,
            ProviderConnectionStatus.limited => SettingsTone.warn,
            ProviderConnectionStatus.failed => SettingsTone.error,
            _ => SettingsTone.idle,
          },
          latencyMs: latencies[provider.id],
          checkedAt: health.resultFor(provider.id).checkedAt,
          testing: busy.contains('test:${provider.id}'),
          models: [
            for (final model in config.modelsForProvider(
              providerId: provider.id,
            ))
              if (!model.isPlaceholder)
                SettingsModel(
                  id: model.name,
                  reasoningEfforts:
                      model.reasoningEfforts == null &&
                          model.availableReasoningEfforts.isEmpty
                      ? null
                      : model.availableReasoningEfforts,
                  defaultReasoningEffort: model.reasoningEffort,
                  detail: model.displayName == model.name
                      ? ''
                      : model.displayName,
                  capabilities: {
                    if ((model.supportsTools ??
                            model.catalogEntry?.supportsToolCalling) ==
                        true)
                      SettingsModelCapability.tools,
                    if ((model.supportsVision ??
                            model.catalogEntry?.supportsVision) ==
                        true)
                      SettingsModelCapability.vision,
                    if (model.availableReasoningEfforts.isNotEmpty ||
                        model.catalogEntry?.supportsReasoning == true)
                      SettingsModelCapability.reasoning,
                  },
                  usedFor: {
                    for (final assignment in assignments)
                      if (assignment.providerId == provider.id &&
                          assignment.modelId == model.name)
                        assignment.task,
                  },
                  retired:
                      model.catalogEntry?.status == 'deprecated' ||
                      model.catalogEntry?.status == 'retired',
                ),
          ],
        ),
    ],
    assignments: assignments,
    presets: [
      for (final task in LauncherInterface.values)
        SettingsPreset(
          id: task.builtinPreset.id,
          name: task.titleIn(context.l10n),
          task: settingsTaskKind(task),
          builtin: true,
        ),
      for (final preset in config.presets)
        SettingsPreset(
          id: preset.id,
          name: preset.name,
          task: settingsTaskKind(preset.task),
        ),
    ],
    // This contract lists functional requests. Connection-test transcripts
    // remain in the existing editor, rather than mislabelling them as a task.
    requests: [
      for (final record in history)
        for (final task in LauncherInterface.values)
          if (settingsHistoryTask(record.task) == task)
            SettingsRequestLog(
              id: record.id,
              at: record.time,
              task: settingsTaskKind(task),
              provider: record.provider,
              model: record.model,
              ok: record.status == ModelRequestStatus.success,
              latencyMs: record.elapsedMs,
            ),
    ],
    requestTotal: history
        .where(
          (record) => LauncherInterface.values.any(
            (task) => settingsHistoryTask(record.task) == task,
          ),
        )
        .length,
  );
}

class SettingsModelActions {
  SettingsModelActions(this.context, this.ref);
  final BuildContext context;
  final WidgetRef ref;

  Future<void> requestDetails(String id) => showDialog<void>(
    context: context,
    builder: (_) => ModelRequestDetailsDialog(recordId: id),
  );
  PromptAssistantConfigNotifier get controller =>
      ref.read(promptAssistantConfigProvider.notifier);
  ProviderConfig provider(String id) => ref
      .read(promptAssistantConfigProvider)
      .providers
      .firstWhere((p) => p.id == id);

  Future<void> _busy(String id, Future<void> Function() action) async {
    final busy = ref.read(settingsBusyProvider.notifier);
    if (busy.state.contains(id)) return;
    busy.state = {...busy.state, id};
    try {
      await action();
    } finally {
      if (busy.mounted) busy.state = {...busy.state}..remove(id);
    }
  }

  Future<void> field(
    String id,
    SettingsProviderField field,
    String value,
  ) async {
    final current = provider(id);
    if (field == SettingsProviderField.apiKey) {
      if (value == '••••••••') return;
      await controller.setProviderApiKey(id, value);
    } else {
      await controller.upsertProvider(
        field == SettingsProviderField.name
            ? current.copyWith(name: value.trim())
            : current.copyWith(baseUrl: value.trim()),
      );
    }
  }

  Future<void> enabled(String id, bool value) =>
      controller.upsertProvider(provider(id).copyWith(enabled: value));
  Future<void> delete(String id) => controller.deleteProvider(id);

  Future<void> edit([String? id]) async {
    final preset = id == null ? await showProviderPicker(context) : null;
    if (!context.mounted || id == null && preset == null) return;
    final selected = id == null ? null : provider(id);
    await showSettingsEditor(
      context,
      (dialog, dirty, saved, save) => AiServiceEditor(
        provider: selected,
        initialPreset: preset,
        onSaved: saved,
        onDirtyChanged: dirty,
        saveController: save,
      ),
    );
  }

  Future<void> addModel(String id) async {
    final name = await settingsTextInput(
      context,
      title: context.l10n.set_mdAddModel,
    );
    if (name == null || name.isEmpty || !context.mounted) return;
    provider(id);
    await controller.upsertModel(
      ModelConfig(providerId: id, name: name, displayName: name),
    );
  }

  Future<void> removeModel(String id, String model) async {
    final selected = ref
        .read(promptAssistantConfigProvider)
        .models
        .where((m) => m.providerId == id && m.name == model)
        .firstOrNull;
    if (selected != null) await controller.deleteModel(selected);
  }

  Future<void> test(String id) => _busy('test:$id', () async {
    final current = provider(id);
    final config = ref.read(promptAssistantConfigProvider);
    final model = config
        .modelsForProvider(providerId: id)
        .where((m) => !m.isPlaceholder)
        .firstOrNull;
    final key = await controller.getProviderApiKey(id);
    final headers = await controller.getProviderHeaders(id);
    final clock = Stopwatch()..start();
    final service = ref.read(promptAssistantServiceProvider);
    if (model == null) {
      await service.fetchModelsForDraft(current, key, headers);
    } else {
      await service.testModelForDraft(current, model, key, headers);
    }
    if (context.mounted) {
      ref.read(settingsProviderLatencies.notifier).state = {
        ...ref.read(settingsProviderLatencies),
        id: clock.elapsedMilliseconds,
      };
    }
  });
  Future<void> refresh(String id) => _busy('refresh:$id', () async {
    final current = provider(id);
    final key = await controller.getProviderApiKey(id);
    final headers = await controller.getProviderHeaders(id);
    final fingerprint = ProviderModelListCache.fingerprint(
      current,
      key,
      headers,
    );
    final names = await ref
        .read(promptAssistantServiceProvider)
        .fetchModelsForDraft(current, key, headers);
    if (!context.mounted) return;
    final latest = provider(id);
    if (ProviderModelListCache.fingerprint(
          latest,
          await controller.getProviderApiKey(id),
          await controller.getProviderHeaders(id),
        ) !=
        fingerprint) {
      throw StateError('Connection changed while discovering models');
    }
    await ref.read(providerModelListCacheProvider).save(id, fingerprint, names);
    // Discovery refreshes the catalog only, never auto-selects remote models.
  });

  Future<void> assign(
    SettingsModelTask kind, {
    String? providerId,
    String? modelId,
    String? presetId,
    String? reasoningEffort,
    bool clearReasoningEffort = false,
  }) async {
    final task = settingsTask(kind);
    final current = ref.read(promptAssistantConfigProvider).interfaceFor(task);
    final selectedProvider = providerId ?? current.providerId;
    final selectedModel =
        modelId ??
        (providerId != null && providerId != current.providerId
            ? ref
                      .read(promptAssistantConfigProvider)
                      .modelsForProvider(providerId: providerId)
                      .where((m) => !m.isPlaceholder)
                      .firstOrNull
                      ?.name ??
                  ''
            : current.model);
    final sameRoute =
        selectedProvider == current.providerId &&
        selectedModel == current.model;
    if ((reasoningEffort != null || clearReasoningEffort) &&
        (!sameRoute || !current.isConfigured)) {
      throw StateError(context.l10n.modelConfig_modelChanged);
    }
    await controller.saveInterface(
      task,
      InterfaceSlotConfig(
        providerId: selectedProvider,
        model: selectedModel,
        presetId: presetId ?? current.presetId,
        targetLanguage: current.targetLanguage,
        reasoningEffort: clearReasoningEffort
            ? null
            : reasoningEffort ?? (sameRoute ? current.reasoningEffort : null),
      ),
    );
  }

  Future<void> editPreset(String? id) async {
    if (id == null) {
      final task = await showDialog<LauncherInterface>(
        context: context,
        builder: (dialog) => SimpleDialog(
          title: Text(context.l10n.modelSettings_tabPresets),
          children: [
            for (final task in LauncherInterface.values)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(dialog, task),
                child: Text(task.titleIn(context.l10n)),
              ),
          ],
        ),
      );
      if (task != null && context.mounted) await editPresetFor(task);
      return;
    }
    final config = ref.read(promptAssistantConfigProvider);
    final preset = [
      ...LauncherInterface.values.map((task) => task.builtinPreset),
      ...config.presets,
    ].firstWhere((p) => p.id == id);
    await showSettingsEditor(
      context,
      (dialog, dirty, saved, save) => ModelPresetEditor(
        preset: preset,
        onDirtyChanged: dirty,
        onSaved: saved,
        onCreate: editPresetFor,
        saveController: save,
      ),
    );
  }

  Future<void> editPresetFor(LauncherInterface task) => showSettingsEditor(
    context,
    (dialog, dirty, saved, save) => ModelPresetEditor(
      preset: TaskPresetConfig(
        id: 'preset-${DateTime.now().microsecondsSinceEpoch}',
        name: task.titleIn(context.l10n),
        task: task,
        prompt: task.builtinPrompt,
      ),
      onDirtyChanged: dirty,
      onSaved: saved,
      onCreate: editPresetFor,
      saveController: save,
    ),
  );
  Future<void> deletePreset(String id) => controller.deletePreset(id);
  Future<void> copy() => Clipboard.setData(
    ClipboardData(
      text: const JsonEncoder.withIndent(
        '  ',
      ).convert(ref.read(promptAssistantConfigProvider).toJson()),
    ),
  );
  Future<void> importConfig() async {
    final raw = await settingsTextInput(
      context,
      title: context.l10n.modelSettings_importConfig,
      maxLines: 12,
    );
    if (raw == null || raw.isEmpty || !context.mounted) return;
    PromptAssistantConfigState.decode(raw); // Validate before the confirmation.
    if (!await settingsConfirm(
          context,
          context.l10n.modelSettings_importConfig,
          context.l10n.modelSettings_importConfigHint,
        ) ||
        !context.mounted) {
      return;
    }
    await controller.importConfiguration(raw);
  }
}
