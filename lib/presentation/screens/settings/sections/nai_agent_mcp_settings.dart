import 'dart:convert';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/nai_agent/mcp_config.dart';
import '../../../../core/nai_agent/tool_catalog.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/localization_extension.dart';
import '../../../providers/nai_agent/nai_agent_workspace_provider.dart';
import '../../../widgets/nai_agent/nai_agent_shared.dart';
import '../../../ui/settings/settings_dialog_kit.dart';
import '../../../ui/settings/settings_kit.dart';

class NaiAgentMcpSettings extends ConsumerWidget {
  const NaiAgentMcpSettings({super.key});

  Future<void> edit(
    BuildContext context,
    WidgetRef ref, [
    AgentMcpServer? server,
  ]) async {
    final secure = ref.read(secureStorageServiceProvider);
    final existing = server == null
        ? null
        : await secure.readAgentMcpConfig(server.configId);
    if (server != null && existing == null) {
      throw StateError('MCP configuration missing: ${server.name}');
    }
    if (!context.mounted) return;
    final value = await showSettingsDialog<(String, Map<String, dynamic>)>(
      context,
      (_) => _McpEditor(server: server, existing: existing),
    );
    if (value == null || !context.mounted) return;
    await agentUiAction(context, () async {
      final controller = ref.read(naiAgentControllerProvider);
      final name = value.$1, config = value.$2;
      if (controller.settings.mcpServers.any(
        (item) =>
            item.configId != server?.configId &&
            item.name.replaceAll('-', '_') == name.replaceAll('-', '_'),
      )) {
        throw const FormatException('Duplicate MCP server name');
      }
      final id = const Uuid().v4();
      await secure.saveAgentMcpConfig(id, jsonEncode(config));
      final item = AgentMcpServer(
        name: name,
        configId: id,
        transport: config.containsKey('url') ? 'http' : 'stdio',
        enabled: config['enabled'] != false,
        exposure: config['exposure'] as String? ?? 'codemode',
      );
      try {
        await controller.updateSettings({
          'mcpServers': [
            for (final entry in controller.settings.mcpServers)
              if (entry.configId != server?.configId) entry.toJson(),
            item.toJson(),
          ],
        });
      } catch (_) {
        await secure.deleteAgentMcpConfig(id);
        rethrow;
      }
      if (server != null) await secure.deleteAgentMcpConfig(server.configId);
    });
  }

  Future<void> _patch(
    BuildContext context,
    WidgetRef ref,
    AgentMcpServer server,
    Map<String, dynamic>? patch,
  ) => agentUiAction(context, () async {
    final controller = ref.read(naiAgentControllerProvider);
    await controller.updateSettings({
      'mcpServers': [
        for (final item in controller.settings.mcpServers)
          if (item.configId != server.configId)
            item.toJson()
          else if (patch != null)
            {...item.toJson(), ...patch},
      ],
    });
    if (patch == null) {
      await ref
          .read(secureStorageServiceProvider)
          .deleteAgentMcpConfig(server.configId);
    }
  });

  Widget _exposure(
    BuildContext context,
    String value,
    ValueChanged<String> changed,
  ) => DropdownButton<String>(
    value: value,
    items: [
      for (final mode in naiAgentMcpExposures)
        DropdownMenuItem(
          value: mode,
          child: Text(mode, style: const TextStyle(fontSize: 12)),
        ),
    ],
    onChanged: (mode) {
      if (mode != null) changed(mode);
    },
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(naiAgentControllerProvider), l = context.l10n;
    final settings = controller.settings;
    final idle =
        controller.selected != null &&
        !controller.selected!.running &&
        !controller.selected!.starting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: ExpansionTile(
            key: const Key('nai-agent-studio-mcp'),
            leading: const Icon(Icons.handyman_outlined, size: 20),
            title: Text(l.naiAgent_mcpBuiltin),
            subtitle: Text(
              settings.studioMcpExposure,
              style: const TextStyle(fontSize: 12),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Switch(
                      value: settings.studioMcpEnabled,
                      onChanged: (value) => agentUiAction(
                        context,
                        () => controller.updateSettings({
                          'studioMcpEnabled': value,
                        }),
                      ),
                    ),
                    _exposure(
                      context,
                      settings.studioMcpExposure,
                      (mode) => agentUiAction(
                        context,
                        () => controller.updateSettings({
                          'studioMcpExposure': mode,
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.naiAgent_mcpBuiltinHint,
                  style: const TextStyle(fontSize: 12, height: 1.6),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final name in naiAgentToolNames.where(
                    (name) => !naiAgentDefaultToolNames.contains(name),
                  ))
                    Chip(
                      label: Text(name, style: const TextStyle(fontSize: 11)),
                    ),
                ],
              ),
            ],
          ),
        ),
        for (final server in settings.mcpServers)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.dns_outlined, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            server.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Switch(
                          value: server.enabled,
                          onChanged: (value) =>
                              _patch(context, ref, server, {'enabled': value}),
                        ),
                        IconButton(
                          tooltip: l.common_edit,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => agentUiAction(
                            context,
                            () => edit(context, ref, server),
                          ),
                        ),
                        IconButton(
                          tooltip: l.common_delete,
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => _patch(context, ref, server, null),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          server.transport == 'stdio'
                              ? 'stdio'
                              : 'Streamable HTTP',
                          style: const TextStyle(fontSize: 12),
                        ),
                        _exposure(
                          context,
                          server.exposure,
                          (mode) =>
                              _patch(context, ref, server, {'exposure': mode}),
                        ),
                        for (final action in ['reconnect', 'login', 'logout'])
                          TextButton(
                            onPressed: idle && server.enabled
                                ? () => agentUiAction(
                                    context,
                                    () => controller.mcpCommand(
                                      action,
                                      name: server.name,
                                    ),
                                  )
                                : null,
                            child: Text(switch (action) {
                              'login' => l.naiAgent_mcpLogin,
                              'logout' => l.naiAgent_mcpLogout,
                              _ => l.naiAgent_mcpReconnect,
                            }),
                          ),
                      ],
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
              label: Text(l.naiAgent_mcpAdd),
              onPressed: () => agentUiAction(context, () => edit(context, ref)),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh, size: 16),
              label: Text(l.naiAgent_mcpStatus),
              onPressed: idle
                  ? () => agentUiAction(
                      context,
                      () => controller.mcpCommand('status'),
                    )
                  : null,
            ),
          ],
        ),
        if (controller.selected?.mcpStatus.isNotEmpty == true)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SelectableText(
              controller.selected!.mcpStatus,
              style: const TextStyle(fontSize: 12, height: 1.6),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          l.naiAgent_mcpHint,
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

class _McpEditor extends StatefulWidget {
  const _McpEditor({this.server, this.existing});
  final AgentMcpServer? server;
  final String? existing;
  @override
  State<_McpEditor> createState() => _McpEditorState();
}

class _McpEditorState extends State<_McpEditor> {
  late final _name = TextEditingController(text: widget.server?.name ?? '');
  late final _json = TextEditingController(
    text: widget.existing == null
        ? '{\n  "command": "npx",\n  "args": ["-y", "your-mcp-package"],\n  "exposure": "codemode"\n}'
        : const JsonEncoder.withIndent('  ').convert({
            ...jsonDecode(widget.existing!) as Map,
            'enabled': widget.server!.enabled,
            'exposure': widget.server!.exposure,
          }),
  );
  String? _error;
  @override
  void dispose() {
    _name.dispose();
    _json.dispose();
    super.dispose();
  }

  void _save() {
    try {
      final name = _name.text.trim();
      Navigator.pop(context, (name, parseAgentMcpConfig(name, _json.text)));
    } catch (error) {
      setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SettingsDialogFrame(
      key: const Key('nai-mcp-editor'),
      width: 600,
      glyph: SettingsGlyphs.hub,
      title: widget.server == null ? l.naiAgent_mcpAdd : l.set_agMcpEditTitle,
      subtitle: Text(l.naiAgent_mcpConfigHint),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            SettingsField(
              label: l.naiAgent_mcpName,
              child: SettingsTextArea(
                key: const Key('nai-mcp-name'),
                controller: _name,
                autofocus: widget.server == null,
                hint: 'my-server',
                mono: true,
              ),
            ),
            SettingsField(
              label: l.naiAgent_mcpConfig,
              error: _error,
              child: SettingsTextArea(
                key: const Key('nai-mcp-config'),
                controller: _json,
                minLines: 9,
                maxLines: 18,
                mono: true,
                error: _error != null,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        SettingsBtn(label: l.set_cancel, onTap: () => Navigator.pop(context)),
        SettingsBtn(
          key: const Key('nai-mcp-save'),
          label: l.set_save,
          tone: SettingsBtnTone.primary,
          onTap: _save,
        ),
      ],
    );
  }
}
