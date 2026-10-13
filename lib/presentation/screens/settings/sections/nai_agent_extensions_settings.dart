import 'package:file_picker/file_picker.dart';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../../core/utils/localization_extension.dart';
import '../../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../../widgets/nai_agent/nai_agent_shared.dart';

class NaiAgentExtensionsSettings extends ConsumerWidget {
  const NaiAgentExtensionsSettings({super.key});

  Future<void> _add(BuildContext context, WidgetRef ref, bool directory) async {
    final controller = ref.read(naiAgentControllerProvider);
    final path = directory
        ? await FilePicker.platform.getDirectoryPath()
        : (await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['ts', 'js', 'mjs', 'cjs'],
          ))?.files.single.path;
    if (path == null || !context.mounted) return;
    await agentUiAction(context, () => controller.configureExtension(path));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(naiAgentControllerProvider), l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: ExpansionTile(
            key: const Key('nai-agent-builtin-extension'),
            leading: const Icon(Icons.extension_outlined, size: 20),
            title: Text(l.naiAgent_interactionExtension),
            subtitle: Text(
              l.naiAgent_extensionRequired,
              style: const TextStyle(fontSize: 12),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.naiAgent_interactionExtensionHint,
                  style: const TextStyle(fontSize: 12, height: 1.6),
                ),
              ),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'studio_context · ask_user',
                  style: TextStyle(fontSize: 12, fontFamily: 'Geist Mono'),
                ),
              ),
            ],
          ),
        ),
        for (final extension in controller.settings.extensions)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.extension_outlined, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.basename(extension.path),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Tooltip(
                            message: extension.path,
                            child: Text(
                              extension.path,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: extension.enabled,
                      onChanged: (enabled) => agentUiAction(
                        context,
                        () => controller.configureExtension(
                          extension.path,
                          enabled: enabled,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l.common_delete,
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => agentUiAction(
                        context,
                        () => controller.configureExtension(
                          extension.path,
                          remove: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: Text(l.naiAgent_extensionAddFile),
              onPressed: () => _add(context, ref, false),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.folder_open, size: 16),
              label: Text(l.naiAgent_extensionAddFolder),
              onPressed: () => _add(context, ref, true),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l.naiAgent_extensionsHint,
          style: TextStyle(
            fontSize: 12,
            height: 1.6,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l.naiAgent_extensionCompatibility,
          style: TextStyle(
            fontSize: 12,
            height: 1.6,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
