import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/localization_extension.dart';
import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../../prompt_assistant/services/prompt_assistant_service.dart';
import '../widgets/ai_service_editor_dialog.dart';

/// Default task models and the services that provide them.
class PromptAssistantSettingsSection extends ConsumerWidget {
  const PromptAssistantSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(promptAssistantConfigProvider);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.settings_modelsAndInterfaces,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            '先添加服务并选定可用模型，再为翻译功能指定模型。',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 28),
          Text('默认模型', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          for (final task in LauncherInterface.values) ...[
            _RouteCard(
              task: task,
              config: config,
              onTap: () => _chooseRoute(context, ref, task),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Text('AI 服务', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 8),
              Text(
                '${config.providers.length}',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => showAiServiceEditor(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('添加服务'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (config.providers.isEmpty)
            OutlinedButton.icon(
              onPressed: () => showAiServiceEditor(context, ref),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 28),
              ),
              icon: const Icon(Icons.hub_outlined),
              label: const Text('还没有 AI 服务，点击添加'),
            )
          else
            for (final provider in config.providers) ...[
              _ServiceRow(provider: provider, config: config),
              const SizedBox(height: 8),
            ],
          const SizedBox(height: 12),
          Text(
            '模型目录按需读取；只保存选中的模型。中转服务若不提供目录，可以手动添加模型 ID。',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Future<void> _chooseRoute(
    BuildContext context,
    WidgetRef ref,
    LauncherInterface task,
  ) async {
    final config = ref.read(promptAssistantConfigProvider);
    final choices = [
      for (final provider in config.providers.where((p) => p.enabled))
        for (final model in config.modelsForProvider(providerId: provider.id))
          if (!model.isPlaceholder) (provider: provider, model: model),
    ];
    if (choices.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先添加并启用服务，再选定至少一个模型。')));
      return;
    }
    final selected = await showDialog<({String providerId, String model})>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          task == LauncherInterface.translate ? '选择提示词翻译模型' : '选择标签翻译模型',
        ),
        content: SizedBox(
          width: 540,
          height: (choices.length * 58.0).clamp(120.0, 480.0),
          child: ListView.builder(
            itemCount: choices.length,
            itemBuilder: (context, index) {
              final choice = choices[index];
              final slot = config.interfaceFor(task);
              return ListTile(
                dense: true,
                title: Text(choice.model.displayName),
                subtitle: Text(
                  '${choice.provider.name} · ${choice.model.name}',
                ),
                trailing:
                    slot.providerId == choice.provider.id &&
                        slot.model == choice.model.name
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () => Navigator.pop(dialogContext, (
                  providerId: choice.provider.id,
                  model: choice.model.name,
                )),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
        ],
      ),
    );
    if (selected != null) {
      await ref
          .read(promptAssistantConfigProvider.notifier)
          .setInterfaceModel(task, selected.providerId, selected.model);
    }
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.task,
    required this.config,
    required this.onTap,
  });
  final LauncherInterface task;
  final PromptAssistantConfigState config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final slot = config.interfaceFor(task);
    final provider = config.providers
        .where((p) => p.id == slot.providerId)
        .firstOrNull;
    final model = config
        .modelsForProvider(providerId: slot.providerId)
        .where((m) => m.name == slot.model && !m.isPlaceholder)
        .firstOrNull;
    final available = provider != null && provider.enabled && model != null;
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                color: colors.primary,
                size: 21,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task == LauncherInterface.translate ? '提示词翻译' : '标签翻译',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      available
                          ? '${provider.name} · ${model.displayName}'
                          : (slot.isConfigured
                                ? '原选择不可用，请重新指定'
                                : task == LauncherInterface.tagTranslate
                                ? '未指定时自动选用首个可用服务和模型'
                                : '尚未指定模型'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                available ? '更改' : '选择模型',
                style: TextStyle(color: colors.primary, fontSize: 12),
              ),
              Icon(Icons.chevron_right, size: 18, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceRow extends ConsumerWidget {
  const _ServiceRow({required this.provider, required this.config});
  final ProviderConfig provider;
  final PromptAssistantConfigState config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final modelCount = config
        .modelsForProvider(providerId: provider.id)
        .where((m) => !m.isPlaceholder)
        .length;
    final hasKey = config.providerHasApiKey[provider.id] ?? false;
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => showAiServiceEditor(context, ref, provider: provider),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: colors.surface,
                child: Text(
                  provider.name.isEmpty ? '?' : provider.name[0].toUpperCase(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            provider.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (config
                                .interfaceFor(LauncherInterface.translate)
                                .providerId ==
                            provider.id)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              '提示词',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.primary,
                              ),
                            ),
                          ),
                        if (config
                                .interfaceFor(LauncherInterface.tagTranslate)
                                .providerId ==
                            provider.id)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              '标签',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      '${provider.protocol.label} · $modelCount 个模型 · '
                      '${provider.baseUrl.isEmpty ? '未填接口地址' : provider.baseUrl}'
                      '${hasKey ? ' · 已配置密钥' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: provider.enabled,
                onChanged: (value) => unawaited(
                  ref
                      .read(promptAssistantConfigProvider.notifier)
                      .upsertProvider(provider.copyWith(enabled: value)),
                ),
              ),
              PopupMenuButton<String>(
                tooltip: '服务操作',
                onSelected: (action) => _handleAction(context, ref, action),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('编辑服务')),
                  PopupMenuItem(value: 'test', child: Text('测试目录连接')),
                  PopupMenuItem(value: 'duplicate', child: Text('复制配置')),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 'delete', child: Text('删除服务')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final notifier = ref.read(promptAssistantConfigProvider.notifier);
    if (action == 'edit') {
      await showAiServiceEditor(context, ref, provider: provider);
    } else if (action == 'test') {
      try {
        final names = await ref
            .read(promptAssistantServiceProvider)
            .fetchAvailableModels(provider.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('模型目录连接成功，读取到 ${names.length} 个模型。')),
          );
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('模型目录不可用：$error。仍可手动添加模型 ID。')),
          );
        }
      }
    } else if (action == 'duplicate') {
      final state = ref.read(promptAssistantConfigProvider);
      var id = '${provider.id}_copy';
      var suffix = 2;
      while (state.providers.any((p) => p.id == id)) {
        id = '${provider.id}_copy${suffix++}';
      }
      await notifier.upsertProvider(
        provider.copyWith(id: id, name: '${provider.name} 副本', enabled: false),
      );
      for (final model in state.modelsForProvider(providerId: provider.id)) {
        if (!model.isPlaceholder) {
          await notifier.upsertModel(model.copyWith(providerId: id));
        }
      }
      final key = await notifier.getProviderApiKey(provider.id);
      if (key != null && key.isNotEmpty) {
        await notifier.setProviderApiKey(id, key);
      }
      await notifier.setProviderHeaders(
        id,
        await notifier.getProviderHeaders(provider.id),
      );
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('删除服务？'),
          content: Text('“${provider.name}”及其已选模型会删除，关联的翻译模型选择也会清除。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('删除'),
            ),
          ],
        ),
      );
      if (confirmed == true) await notifier.deleteProvider(provider.id);
    }
  }
}
