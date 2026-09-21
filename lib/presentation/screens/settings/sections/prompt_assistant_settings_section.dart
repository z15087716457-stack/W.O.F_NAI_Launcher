import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../../prompt_assistant/services/prompt_assistant_service.dart';
import '../widgets/settings_card.dart';

class PromptAssistantSettingsSection extends ConsumerWidget {
  const PromptAssistantSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(promptAssistantConfigProvider);
    final notifier = ref.read(promptAssistantConfigProvider.notifier);

    return SettingsCard(
      title: context.l10n.settings_modelsAndInterfaces,
      icon: Icons.auto_awesome,
      child: Column(
        children: [
          _buildProviders(context, ref, state, notifier),
          const Divider(),
          _buildInterfaces(context, state, notifier),
        ],
      ),
    );
  }

  Widget _buildInterfaces(
    BuildContext context,
    PromptAssistantConfigState state,
    PromptAssistantConfigNotifier notifier,
  ) {
    final enabledProviders = state.providers
        .where((provider) => provider.enabled)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: Text(context.l10n.promptAssistant_launcherInterfaces),
          subtitle: Text(
            context.l10n.promptAssistant_launcherInterfacesSubtitle,
          ),
        ),
        if (enabledProviders.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              context.l10n.promptAssistant_noEnabledProviders,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final twoCols = constraints.maxWidth > 860;
              final cards = LauncherInterface.values
                  .map(
                    (interface) => _buildInterfaceCard(
                      context: context,
                      state: state,
                      notifier: notifier,
                      interface: interface,
                    ),
                  )
                  .toList();

              if (twoCols) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: cards
                      .map(
                        (card) => SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: card,
                        ),
                      )
                      .toList(),
                );
              }

              return Column(
                children: [
                  for (var i = 0; i < cards.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    cards[i],
                  ],
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildInterfaceCard({
    required BuildContext context,
    required PromptAssistantConfigState state,
    required PromptAssistantConfigNotifier notifier,
    required LauncherInterface interface,
  }) {
    final slot = state.interfaceFor(interface);
    final enabledProviders = state.providers
        .where((provider) => provider.enabled)
        .toList();
    final providerItems = enabledProviders
        .map(
          (provider) =>
              DropdownMenuItem(value: provider.id, child: Text(provider.name)),
        )
        .toList();
    final providerValue =
        enabledProviders.any((provider) => provider.id == slot.providerId)
        ? slot.providerId
        : null;
    final models = providerValue == null
        ? const <ModelConfig>[]
        : state.modelsForProvider(providerId: providerValue);
    final modelItems = models
        .map(
          (model) => DropdownMenuItem(
            value: model.name,
            child: Text(model.displayName),
          ),
        )
        .toList();
    final modelValue = models.any((model) => model.name == slot.model)
        ? slot.model
        : null;

    return _buildTaskRouteCard(
      context: context,
      title: _interfaceLabel(context, interface),
      providerValue: providerValue,
      providerItems: providerItems,
      onProviderChanged: (value) {
        if (value == null) return;
        unawaited(notifier.setInterfaceProvider(interface, value));
      },
      modelValue: modelValue,
      modelItems: modelItems,
      onModelChanged: modelItems.isEmpty || providerValue == null
          ? null
          : (value) {
              if (value == null) return;
              unawaited(
                notifier.setInterfaceModel(interface, providerValue, value),
              );
            },
    );
  }

  String _interfaceLabel(BuildContext context, LauncherInterface interface) {
    switch (interface) {
      case LauncherInterface.translate:
        return context.l10n.promptAssistant_interfaceTranslate;
      case LauncherInterface.tagTranslate:
        return context.l10n.promptAssistant_interfaceTagTranslate;
    }
  }

  Widget _buildTaskRouteCard({
    required BuildContext context,
    required String title,
    required String? providerValue,
    required List<DropdownMenuItem<String>> providerItems,
    required ValueChanged<String?> onProviderChanged,
    required String? modelValue,
    required List<DropdownMenuItem<String>> modelItems,
    required ValueChanged<String?>? onModelChanged,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: providerValue,
              isExpanded: true,
              items: providerItems,
              onChanged: onProviderChanged,
              decoration: InputDecoration(
                labelText: context.l10n.promptAssistant_provider,
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: modelValue,
              isExpanded: true,
              hint: Text(context.l10n.promptAssistant_noModelsPullFirst),
              items: modelItems,
              onChanged: onModelChanged,
              decoration: InputDecoration(
                labelText: context.l10n.promptAssistant_model,
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviders(
    BuildContext context,
    WidgetRef ref,
    PromptAssistantConfigState state,
    PromptAssistantConfigNotifier notifier,
  ) {
    return Column(
      children: [
        ListTile(
          title: Text(context.l10n.promptAssistant_providerManagement),
          subtitle: Text(
            context.l10n.promptAssistant_providerManagementSubtitle,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showProviderDialog(context, notifier, state),
          ),
        ),
        ...state.providers.map((provider) {
          final hasApiKey = state.providerHasApiKey[provider.id] ?? false;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Switch(
                  value: provider.enabled,
                  onChanged: (value) {
                    notifier.upsertProvider(provider.copyWith(enabled: value));
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        provider.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${provider.protocol.label}  ${provider.baseUrl}',
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          hasApiKey
                              ? context.l10n.promptAssistant_apiKeyConfigured
                              : context
                                    .l10n
                                    .promptAssistant_apiKeyNotConfigured,
                          provider.allowImageInput
                              ? context.l10n.promptAssistant_supportsImageInput
                              : context.l10n.promptAssistant_textOnly,
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 240,
                    maxWidth: 360,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showConnectionDialog(
                            context,
                            notifier,
                            provider: provider,
                          ),
                          icon: const Icon(Icons.link, size: 16),
                          label: Text(
                            context.l10n.promptAssistant_connectionConfig,
                          ),
                        ),
                        Icon(hasApiKey ? Icons.key : Icons.key_off, size: 18),
                        IconButton(
                          icon: const Icon(Icons.download_for_offline_outlined),
                          tooltip: context.l10n.promptAssistant_pullModelList,
                          onPressed: () => _pullProviderModels(
                            context,
                            ref,
                            notifier,
                            provider.id,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: context.l10n.promptAssistant_editProvider,
                          onPressed: () => _showProviderDialog(
                            context,
                            notifier,
                            state,
                            provider: provider,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: context.l10n.promptAssistant_deleteProvider,
                          onPressed: () => notifier.deleteProvider(provider.id),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Future<void> _pullProviderModels(
    BuildContext context,
    WidgetRef ref,
    PromptAssistantConfigNotifier notifier,
    String providerId,
  ) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(content: Text(l10n.promptAssistant_pullingModels)),
    );

    try {
      final service = ref.read(promptAssistantServiceProvider);
      final modelNames = await service.fetchAvailableModels(providerId);
      if (modelNames.isEmpty) {
        throw StateError(l10n.promptAssistant_emptyModelList);
      }

      // 以接口返回的最新列表为准同步：新增缺失模型、清理已弃用的 API 模型、
      // 保留手动/默认模型，并把失效的接口槽模型回落为“首个模型”。
      await notifier.syncProviderModels(providerId, modelNames);

      messenger?.showSnackBar(
        SnackBar(
          content: Text(l10n.promptAssistant_modelsSynced(modelNames.length)),
        ),
      );
    } catch (e) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.promptAssistant_pullModelsFailed('$e'))),
      );
    }
  }

  Future<void> _showProviderDialog(
    BuildContext context,
    PromptAssistantConfigNotifier notifier,
    PromptAssistantConfigState state, {
    ProviderConfig? provider,
  }) async {
    final nameController = TextEditingController(text: provider?.name ?? '');
    final baseController = TextEditingController(text: provider?.baseUrl ?? '');
    final keyController = TextEditingController();
    var preset =
        provider?.preset ??
        (provider == null
            ? ProviderPreset.openaiChat
            : provider.protocol == ProviderProtocol.openaiResponses
            ? ProviderPreset.openaiCompatibleResponses
            : ProviderPreset.openaiCompatibleChat);
    var allowImageInput =
        provider?.allowImageInput ?? preset.defaultAllowImageInput;

    void applyProtocol(ProviderPreset value) {
      final previousPreset = preset;
      final currentName = nameController.text.trim();
      final currentBaseUrl = baseController.text.trim();
      preset = value;
      allowImageInput = value.defaultAllowImageInput;
      if (provider == null) {
        nameController.text = value.defaultName;
        baseController.text = value.defaultBaseUrl;
        return;
      }
      if (currentName.isEmpty || currentName == previousPreset.defaultName) {
        nameController.text = value.defaultName;
      }
      if (currentBaseUrl.isEmpty ||
          currentBaseUrl == previousPreset.defaultBaseUrl) {
        baseController.text = value.defaultBaseUrl;
      }
    }

    if (provider == null) {
      applyProtocol(preset);
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                provider == null
                    ? context.l10n.promptAssistant_addProvider
                    : context.l10n.promptAssistant_editProviderTitle,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: context.l10n.promptAssistant_name,
                      ),
                    ),
                    DropdownButtonFormField<ProviderPreset>(
                      initialValue: preset,
                      items: ProviderPreset.values
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => applyProtocol(value));
                        }
                      },
                      decoration: InputDecoration(
                        labelText: context.l10n.promptAssistant_protocol,
                      ),
                    ),
                    TextField(
                      controller: baseController,
                      decoration: const InputDecoration(labelText: 'Base URL'),
                    ),
                    SwitchListTile(
                      value: allowImageInput,
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.l10n.promptAssistant_allowImageInput),
                      subtitle: Text(
                        context.l10n.promptAssistant_allowImageInputSubtitle,
                      ),
                      onChanged: (value) {
                        setState(() => allowImageInput = value);
                      },
                    ),
                    TextField(
                      controller: keyController,
                      decoration: InputDecoration(
                        labelText:
                            context.l10n.promptAssistant_apiKeyLeaveEmpty,
                      ),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(context.l10n.common_cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(context.l10n.common_save),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    final resolvedName = nameController.text.trim().isEmpty
        ? preset.defaultName
        : nameController.text.trim();
    final resolvedId =
        provider?.id ??
        _uniqueProviderId(
          state,
          _providerIdFromName(resolvedName, fallback: preset.defaultId),
        );
    final next = ProviderConfig(
      id: resolvedId,
      name: resolvedName,
      type: preset.legacyType,
      protocol: preset.defaultProtocol,
      preset: preset,
      baseUrl: baseController.text.trim(),
      enabled: provider?.enabled ?? true,
      allowImageInput: allowImageInput,
    );

    await notifier.upsertProvider(next);

    if (keyController.text.trim().isNotEmpty) {
      await notifier.setProviderApiKey(resolvedId, keyController.text);
    }

    final hasModel = state.models.any(
      (model) => model.providerId == resolvedId,
    );
    if (!hasModel) {
      final defaultModels = next.preset?.defaultModelNames ?? const [];
      final modelName = defaultModels.isNotEmpty
          ? defaultModels.first
          : 'default-model';
      await notifier.upsertModel(
        ModelConfig(
          providerId: resolvedId,
          name: modelName,
          displayName: modelName,
          isDefault: true,
        ),
      );
    }
  }

  String _uniqueProviderId(PromptAssistantConfigState state, String baseId) {
    if (!state.providers.any((provider) => provider.id == baseId)) {
      return baseId;
    }
    var index = 2;
    while (state.providers.any(
      (provider) => provider.id == '${baseId}_$index',
    )) {
      index++;
    }
    return '${baseId}_$index';
  }

  String _providerIdFromName(String name, {required String fallback}) {
    final normalized = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return normalized.isEmpty ? fallback : normalized;
  }

  Future<void> _showConnectionDialog(
    BuildContext context,
    PromptAssistantConfigNotifier notifier, {
    required ProviderConfig provider,
  }) async {
    final baseController = TextEditingController(text: provider.baseUrl);
    final keyController = TextEditingController();
    var clearApiKey = false;
    var allowImageInput = provider.allowImageInput;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                context.l10n.promptAssistant_connectionTitle(provider.name),
              ),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: baseController,
                      decoration: InputDecoration(
                        labelText: 'Base URL',
                        hintText: context.l10n.promptAssistant_baseUrlHint,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: keyController,
                      decoration: InputDecoration(
                        labelText:
                            context.l10n.promptAssistant_apiKeyLeaveEmpty,
                      ),
                      obscureText: true,
                    ),
                    CheckboxListTile(
                      value: clearApiKey,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        context.l10n.promptAssistant_clearCurrentApiKey,
                      ),
                      onChanged: (value) {
                        setState(() => clearApiKey = value ?? false);
                      },
                    ),
                    SwitchListTile(
                      value: allowImageInput,
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.l10n.promptAssistant_allowImageInput),
                      subtitle: Text(
                        provider.protocol.supportsImagePayload
                            ? context
                                  .l10n
                                  .promptAssistant_protocolSupportsImagePayload
                            : context
                                  .l10n
                                  .promptAssistant_protocolTextOnlyWarning,
                      ),
                      onChanged: (value) {
                        setState(() => allowImageInput = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(context.l10n.common_cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(context.l10n.common_save),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    await notifier.upsertProvider(
      provider.copyWith(
        baseUrl: baseController.text.trim(),
        allowImageInput: allowImageInput,
      ),
    );

    if (clearApiKey) {
      await notifier.setProviderApiKey(provider.id, '');
      return;
    }

    if (keyController.text.trim().isNotEmpty) {
      await notifier.setProviderApiKey(provider.id, keyController.text);
    }
  }
}
