import 'dart:convert';
import 'package:nai_launcher/presentation/widgets/common/studio_material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/nai_agent/agent_tool.dart';
import '../../../providers/nai_agent/nai_agent_management.dart';
import '../../../ui/model_providers/model_providers_contract.dart';
import '../../../ui/model_providers/model_providers_kit.dart';
import '../../../ui/kit/ui_colors.dart';
import '../../../ui/kit/ui_glyph.dart';
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
    await agentUiAction(
      context,
      () => ref
          .read(naiAgentManagementProvider)
          .saveMcp(value.$1, value.$2, replacing: server?.configId),
    );
  }

  Future<void> _patch(
    BuildContext context,
    WidgetRef ref,
    AgentMcpServer server,
    Map<String, dynamic>? patch,
  ) => agentUiAction(
    context,
    () => ref
        .read(naiAgentManagementProvider)
        .configureMcp(
          server.configId,
          enabled: patch?['enabled'] as bool?,
          exposure: patch?['exposure'] as String?,
          remove: patch == null,
        ),
  );

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

class _McpEditor extends ConsumerStatefulWidget {
  const _McpEditor({this.server, this.existing});
  final AgentMcpServer? server;
  final String? existing;
  @override
  ConsumerState<_McpEditor> createState() => _McpEditorState();
}

class _McpEditorState extends ConsumerState<_McpEditor> {
  late final _name = TextEditingController(text: widget.server?.name ?? '');
  final _json = TextEditingController();
  final _url = TextEditingController(), _command = TextEditingController();
  final _args = TextEditingController(), _cwd = TextEditingController();
  final _oauth = TextEditingController();
  late Map<String, dynamic> _draft;
  List<ProviderKeyValue> _headers = [], _env = [];
  bool _http = true, _jsonMode = false, _advanced = false, _busy = false;
  String? _error;
  Map<String, dynamic>? _result;
  NaiAgentCancellation? _testing;

  void _edited() {
    _testing?.cancel();
    _testing = null;
    setState(() {
      _busy = false;
      _result = null;
      _error = null;
    });
  }

  @override
  void initState() {
    super.initState();
    _load(
      widget.existing == null
          ? {'url': '', 'exposure': 'codemode'}
          : {
              ...Map<String, dynamic>.from(jsonDecode(widget.existing!) as Map),
              'enabled': widget.server!.enabled,
              'exposure': widget.server!.exposure,
            },
    );
  }

  void _load(Map<String, dynamic> value) {
    _draft = value;
    _http = value.containsKey('url');
    _url.text = value['url'] as String? ?? '';
    _command.text = value['command'] as String? ?? '';
    _args.text = (value['args'] as List? ?? []).join('\n');
    _cwd.text = value['cwd'] as String? ?? '';
    _oauth.text = value['oauth'] == null
        ? ''
        : const JsonEncoder.withIndent('  ').convert(value['oauth']);
    _headers = [
      for (final e in (value['headers'] as Map? ?? {}).entries)
        ProviderKeyValue(e.key as String, e.value as String),
    ];
    _env = [
      for (final e in (value['env'] as Map? ?? {}).entries)
        ProviderKeyValue(e.key as String, e.value as String),
    ];
  }

  Map<String, dynamic> _configuration({bool validate = true}) {
    if (_jsonMode) {
      final raw = Map<String, dynamic>.from(jsonDecode(_json.text) as Map);
      if (raw['mcpServers'] case final Map servers) {
        if (servers.length != 1) {
          throw FormatException(context.l10n.set_agMcpJsonOne);
        }
        _name.text = servers.keys.single as String;
        return parseAgentMcpConfig(
          _name.text.trim(),
          jsonEncode(servers.values.single),
        );
      }
      return parseAgentMcpConfig(_name.text.trim(), _json.text);
    }
    final value = {..._draft, 'type': _http ? 'http' : 'stdio'};
    if (_http) {
      value.remove('command');
      value.remove('args');
      value.remove('env');
      value.remove('cwd');
      value['url'] = _url.text.trim();
      value['headers'] = {
        for (final h in _headers)
          if (h.key.trim().isNotEmpty) h.key.trim(): h.value,
      };
      if (_oauth.text.trim().isEmpty) {
        value.remove('oauth');
      } else {
        value['oauth'] = jsonDecode(_oauth.text);
      }
    } else {
      value.remove('url');
      value.remove('headers');
      value.remove('oauth');
      value['command'] = _command.text.trim();
      value['args'] = _args.text
          .split('\n')
          .where((s) => s.isNotEmpty)
          .toList();
      value['env'] = {
        for (final h in _env)
          if (h.key.trim().isNotEmpty) h.key.trim(): h.value,
      };
      if (_cwd.text.trim().isEmpty) {
        value.remove('cwd');
      } else {
        value['cwd'] = _cwd.text.trim();
      }
    }
    return validate
        ? parseAgentMcpConfig(_name.text.trim(), jsonEncode(value))
        : value;
  }

  void _toggleJson() {
    try {
      if (_jsonMode) {
        _load(_configuration());
      } else {
        _json.text = const JsonEncoder.withIndent(
          '  ',
        ).convert(_configuration(validate: false));
      }
      setState(() {
        _jsonMode = !_jsonMode;
        _error = null;
        _result = null;
      });
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  void _save() {
    try {
      final config = _configuration();
      Navigator.pop(context, (_name.text.trim(), config));
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  Future<void> _test([String action = 'test']) async {
    final token = _testing = NaiAgentCancellation();
    try {
      final config = _configuration();
      setState(() {
        _busy = true;
        _error = null;
        _result = null;
      });
      final c = ref.read(naiAgentControllerProvider);
      await c.ready;
      token.check();
      final result = await ref
          .read(naiAgentManagementProvider)
          .inspectMcp(
            _name.text.trim(),
            config,
            c.selectedWorkspace!,
            action: action,
            cancellation: token,
          );
      if (mounted && identical(_testing, token)) {
        setState(() => _result = result);
      }
    } catch (e) {
      if (mounted && identical(_testing, token)) {
        setState(() => _error = '$e');
      }
    } finally {
      if (mounted && identical(_testing, token)) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  void dispose() {
    _testing?.cancel();
    for (final c in [_name, _json, _url, _command, _args, _cwd, _oauth]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget field(
      String key,
      String label,
      TextEditingController controller, {
      int lines = 1,
      String? hint,
    }) => SettingsField(
      label: label,
      child: SettingsTextArea(
        key: Key(key),
        controller: controller,
        minLines: lines,
        maxLines: lines == 1
            ? 1
            : lines > 6
            ? 18
            : 6,
        mono: true,
        hint: hint,
        onChanged: (_) => _edited(),
      ),
    );
    Widget pairs(
      String key,
      String label,
      List<ProviderKeyValue> values,
      ValueChanged<List<ProviderKeyValue>> changed,
    ) => SettingsField(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          if (values.isNotEmpty)
            ProviderKeyValues(
              key: Key(key),
              keyPrefix: key,
              items: values,
              onChanged: changed,
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: SettingsBtn(
              label: l.common_add,
              glyph: UiGlyphs.plus,
              small: true,
              onTap: () => changed([...values, const ProviderKeyValue('', '')]),
            ),
          ),
        ],
      ),
    );
    return SettingsDialogFrame(
      key: const Key('nai-mcp-editor'),
      width: 600,
      glyph: SettingsGlyphs.hub,
      title: widget.server == null ? l.naiAgent_mcpAdd : l.set_agMcpEditTitle,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            field('nai-mcp-name', l.naiAgent_mcpName, _name, hint: 'my-server'),
            Row(
              spacing: 8,
              children: [
                if (!_jsonMode) ...[
                  SettingsBtn(
                    key: const Key('nai-mcp-http'),
                    label: 'HTTP',
                    small: true,
                    tone: _http
                        ? SettingsBtnTone.primary
                        : SettingsBtnTone.ghost,
                    onTap: () {
                      _http = true;
                      _edited();
                    },
                  ),
                  SettingsBtn(
                    key: const Key('nai-mcp-stdio'),
                    label: l.set_agMcpStdio,
                    small: true,
                    tone: !_http
                        ? SettingsBtnTone.primary
                        : SettingsBtnTone.ghost,
                    onTap: () {
                      _http = false;
                      _edited();
                    },
                  ),
                ],
                const Spacer(),
                SettingsBtn(
                  key: const Key('nai-mcp-json'),
                  label: _jsonMode ? l.set_agMcpForm : l.set_agMcpJson,
                  small: true,
                  tone: SettingsBtnTone.ghost,
                  onTap: _busy ? null : _toggleJson,
                ),
              ],
            ),
            if (_jsonMode)
              field('nai-mcp-config', l.naiAgent_mcpConfig, _json, lines: 9)
            else ...[
              if (_http) ...[
                field(
                  'nai-mcp-url',
                  l.set_agMcpAddress,
                  _url,
                  hint: 'https://mcp.example.com/mcp',
                ),
                pairs('nai-mcp-headers', l.set_agMcpHeaders, _headers, (v) {
                  _headers = v;
                  _edited();
                }),
              ] else ...[
                field(
                  'nai-mcp-command',
                  l.set_agMcpCommand,
                  _command,
                  hint: 'npx',
                ),
                field('nai-mcp-args', l.set_agMcpArgs, _args, lines: 2),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: SettingsBtn(
                  key: const Key('nai-mcp-advanced'),
                  label: l.set_agMcpAdvanced,
                  small: true,
                  tone: SettingsBtnTone.ghost,
                  glyph: _advanced ? UiGlyphs.chevronUp : UiGlyphs.chevronDown,
                  onTap: () => setState(() => _advanced = !_advanced),
                ),
              ),
              if (_advanced && _http)
                field('nai-mcp-oauth', 'OAuth (JSON)', _oauth, lines: 2),
              if (_advanced && !_http) ...[
                field('nai-mcp-cwd', l.set_agMcpCwd, _cwd),
                pairs('nai-mcp-env', l.set_agMcpEnv, _env, (v) {
                  _env = v;
                  _edited();
                }),
              ],
            ],
            if (_result != null)
              Text(
                _result!['state'] == 'connected'
                    ? l.set_agConnected('${_result!['tools']}')
                    : (_result!['error'] as String? ?? l.set_agNeedsLogin),
                style: TextStyle(
                  color: _result!['state'] == 'connected'
                      ? context.ui.ok
                      : context.ui.warn,
                ),
              ),
            if (_error != null)
              Text(_error!, style: TextStyle(color: context.ui.error)),
          ],
        ),
      ),
      footerLeading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SettingsBtn(
            key: const Key('nai-mcp-test'),
            label: l.set_agMcpTest,
            onTap: _busy ? null : _test,
          ),
          if (_result?['state'] == 'needs-auth')
            SettingsBtn(
              label: l.set_login,
              onTap: _busy ? null : () => _test('login'),
            ),
        ],
      ),
      actions: [
        SettingsBtn(label: l.set_cancel, onTap: () => Navigator.pop(context)),
        SettingsBtn(
          key: const Key('nai-mcp-save'),
          label: l.set_save,
          tone: SettingsBtnTone.primary,
          onTap: _busy ? null : _save,
        ),
      ],
    );
  }
}
