import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/localization_extension.dart';
import '../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../router/app_router.dart';
import '../common/app_toast.dart';

// Shared by the legacy settings sections and the generation host. The sidebar
// itself is provider-free and uses AgentActions through AgentWiring.
Future<void> agentUiAction(
  BuildContext context,
  Future<void> Function() action,
) async {
  try {
    await action();
  } catch (_) {
    if (context.mounted) AppToast.error(context, context.l10n.naiAgent_error);
  }
}

/// Retained for the legacy settings section, not the sidebar composer.
class NaiAgentModelPicker extends ConsumerWidget {
  const NaiAgentModelPicker({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(naiAgentControllerProvider);
    final config = ref.watch(promptAssistantConfigProvider);
    final model = config.models
        .where(
          (m) =>
              m.providerId == c.settings.providerId &&
              m.name == c.settings.modelId,
        )
        .firstOrNull;
    return PopupMenuButton<(String, String)>(
      tooltip: context.l10n.naiAgent_chooseModel,
      constraints: const BoxConstraints(maxWidth: 410, maxHeight: 480),
      onSelected: (choice) => agentUiAction(context, () async {
        if (choice.$1 == '__settings__') {
          context.go('${AppRoutes.settings}?section=models');
          return;
        }
        await c.updateSettings({'providerId': choice.$1, 'modelId': choice.$2});
      }),
      itemBuilder: (_) => [
        for (final p in config.providers.where((p) => p.enabled))
          for (final m in config.models.where(
            (m) =>
                m.providerId == p.id &&
                !m.isPlaceholder &&
                m.supportsTools != false,
          ))
            PopupMenuItem(
              value: (p.id, m.name),
              child: Text('${p.name} · ${m.displayName}'),
            ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: ('__settings__', ''),
          child: Text(context.l10n.ag_modelSettings),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                model?.displayName ?? context.l10n.naiAgent_chooseModel,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 15),
          ],
        ),
      ),
    );
  }
}
