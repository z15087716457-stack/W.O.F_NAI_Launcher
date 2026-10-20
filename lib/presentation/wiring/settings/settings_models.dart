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
import 'providers_workbench.dart';
import '../../screens/settings/widgets/model_preset_editor.dart';
import '../../screens/settings/widgets/model_request_details_dialog.dart';
import '../../ui/settings/settings_contract.dart';
import 'settings_dialogs.dart';

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
  final workbench = ref.watch(providersWorkbenchProvider);
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
    workbench: providersViewData(config, workbench, health, context.l10n),
    providers: [
      for (final provider in config.providers)
        SettingsProvider(
          id: provider.id,
          name: provider.name,
          protocol: provider.protocol.label,
          mark: providerUsesMark(provider)
              ? provider.name.characters.take(2).toString().toUpperCase()
              : null,
          logoAsset: provider.preset?.logoAsset,
          color: 0xff266eff,
          enabled: provider.enabled,
          local:
              provider.preset?.isLocal ??
              (provider.type == ProviderType.ollama),
          baseUrl: provider.baseUrl,
          apiKeyMasked: config.providerHasApiKey[provider.id] == true
              ? '••••••••'
              : '',
          status: connectionTone(
            workbench.connections[provider.id]?.result ??
                health.resultFor(provider.id),
          ),
          latencyMs: workbench.connections[provider.id]?.latencyMs,
          checkedAt:
              (workbench.connections[provider.id]?.result ??
                      health.resultFor(provider.id))
                  .checkedAt,
          testing: workbench.connections[provider.id]?.testing ?? false,
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
