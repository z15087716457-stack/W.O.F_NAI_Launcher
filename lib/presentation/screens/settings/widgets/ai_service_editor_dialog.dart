import 'settings_tile.dart';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'provider_logo.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../../prompt_assistant/services/prompt_assistant_service.dart';
import '../../../prompt_assistant/models/prompt_task_definitions.dart';
import 'model_parameter_fields.dart';

part 'ai_service_overview.dart';

Future<void> showAiServiceEditor(
  BuildContext context,
  WidgetRef ref, {
  ProviderConfig? provider,
}) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => AiServiceEditorDialog(provider: provider),
);

class AiServiceEditorDialog extends ConsumerStatefulWidget {
  const AiServiceEditorDialog({
    super.key,
    this.provider,
    this.initialPreset,
    this.embedded = false,
    this.onSaved,
    this.onDirtyChanged,
    this.onTaskSelected,
  });
  final ProviderConfig? provider;
  final ProviderPreset? initialPreset;
  final bool embedded;
  final ValueChanged<String>? onSaved;
  final ValueChanged<bool>? onDirtyChanged;
  final ValueChanged<LauncherInterface>? onTaskSelected;

  @override
  ConsumerState<AiServiceEditorDialog> createState() =>
      _AiServiceEditorDialogState();
}

class _AiServiceEditorDialogState extends ConsumerState<AiServiceEditorDialog> {
  late ProviderPreset _preset;
  late ProviderProtocol _protocol;
  late final TextEditingController _name;
  late final TextEditingController _baseUrl;
  late final TextEditingController _apiKey;
  late final TextEditingController _catalogSearch;
  late final TextEditingController _selectedSearch;
  late final TextEditingController _manualId;
  late final LinkedHashMap<String, ModelConfig> _selected;
  Map<String, String> _headers = {};
  List<String> _catalog = [];
  String? _expandedModel;
  String? _error;
  String? _catalogMessage;
  bool _busy = false;
  bool _headersLoaded = false;
  bool _headersLoadFailed = false;
  bool _clearKey = false;
  bool _allowImageInput = false;
  int _timeoutSeconds = 120;
  int _maxConcurrentRequests = 5;
  int _retryAttempts = 0;
  bool _editingConnection = false;
  bool _manualVisible = false;
  bool _catalogVisible = false;
  bool _advancedExpanded = false;
  bool _enabled = true;
  late String _initialDraft;
  String _initialHeaders = '{}';
  bool _lastDirty = false;
  late String _observedService;

  String _serviceSnapshot() {
    final config = ref.read(promptAssistantConfigProvider);
    final id = widget.provider?.id;
    return jsonEncode({
      'provider': config.providers
          .where((item) => item.id == id)
          .firstOrNull
          ?.toJson(),
      'models': config
          .modelsForProvider(providerId: id ?? '')
          .map((item) => item.toJson())
          .toList(),
    });
  }

  @override
  void initState() {
    super.initState();
    final provider = widget.provider;
    _editingConnection = provider == null;
    _preset =
        provider?.preset ??
        widget.initialPreset ??
        ProviderPreset.openaiCompatibleChat;
    _protocol = provider?.protocol ?? _preset.defaultProtocol;
    _name = TextEditingController(
      text: provider?.name ?? widget.initialPreset?.label ?? '',
    );
    _baseUrl = TextEditingController(
      text: provider?.baseUrl ?? _preset.defaultBaseUrl,
    );
    _apiKey = TextEditingController();
    _catalogSearch = TextEditingController()..addListener(_refresh);
    _selectedSearch = TextEditingController()..addListener(_refresh);
    _manualId = TextEditingController();
    _allowImageInput =
        provider?.allowImageInput ?? _preset.defaultAllowImageInput;
    _timeoutSeconds = provider?.timeoutSeconds ?? 120;
    _maxConcurrentRequests = provider?.maxConcurrentRequests ?? 5;
    _retryAttempts = provider?.retryAttempts ?? 0;
    _enabled = provider?.enabled ?? true;
    final saved = ref.read(promptAssistantConfigProvider);
    _selected = LinkedHashMap.fromEntries([
      if (provider != null)
        for (final model in saved.modelsForProvider(providerId: provider.id))
          if (!model.isPlaceholder) MapEntry(model.name, model),
      if (provider == null && widget.initialPreset != null)
        for (final name in _preset.defaultModelNames)
          MapEntry(
            name,
            ModelConfig(providerId: 'draft', name: name, displayName: name),
          ),
    ]);
    _initialDraft = _fingerprint;
    _observedService = _serviceSnapshot();
    for (final controller in [_name, _baseUrl, _apiKey]) {
      controller.addListener(_refresh);
    }
    _loadHeaders();
  }

  Future<void> _loadHeaders() async {
    if (widget.provider != null) {
      try {
        _headers = await ref
            .read(promptAssistantConfigProvider.notifier)
            .getProviderHeaders(widget.provider!.id);
        _initialHeaders = jsonEncode(_headers);
      } catch (error) {
        _headersLoadFailed = true;
        _error = '读取高级请求头失败：$error';
      }
    }
    if (mounted) setState(() => _headersLoaded = true);
  }

  String get _fingerprint => jsonEncode([
    _name.text,
    _baseUrl.text,
    _apiKey.text,
    _preset.name,
    _protocol.name,
    _enabled,
    _clearKey,
    _allowImageInput,
    _timeoutSeconds,
    _maxConcurrentRequests,
    _retryAttempts,
    _selected.values.map((m) => m.toJson()).toList(),
  ]);

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _name.dispose();
    _baseUrl.dispose();
    _apiKey.dispose();
    _catalogSearch.dispose();
    _selectedSearch.dispose();
    _manualId.dispose();
    super.dispose();
  }

  String _uniqueId() {
    if (widget.provider != null) return widget.provider!.id;
    final normalized = _name.text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    final base = normalized.isEmpty ? _preset.defaultId : normalized;
    final saved = ref.read(promptAssistantConfigProvider);
    var id = base;
    var index = 2;
    while (saved.providers.any((p) => p.id == id)) {
      id = '${base}_${index++}';
    }
    return id;
  }

  ProviderConfig _draft({String? id}) => ProviderConfig(
    id: id ?? widget.provider?.id ?? 'draft',
    name: _name.text.trim(),
    type: _preset.legacyType,
    protocol: _protocol,
    preset: _preset,
    baseUrl: _baseUrl.text.trim(),
    enabled: _enabled,
    allowImageInput: _allowImageInput,
    timeoutSeconds: _timeoutSeconds,
    maxConcurrentRequests: _maxConcurrentRequests,
    retryAttempts: _retryAttempts,
    requestHeaders: _headers,
  );

  final _modelInputErrors = <String, String?>{};

  bool _validate() {
    final url = Uri.tryParse(_baseUrl.text.trim());
    final name = _name.text.trim();
    setState(() {
      _error = _timeoutSeconds < 10 || _timeoutSeconds > 600
          ? '请求超时应在 10–600 秒之间。'
          : name.isEmpty
          ? '请输入服务名称。'
          : url == null ||
                !url.hasAuthority ||
                (url.scheme != 'http' && url.scheme != 'https')
          ? '接口地址必须是完整的 http:// 或 https:// URL。'
          : null;
    });
    for (final model in _selected.values) {
      final validation =
          _modelInputErrors[model.name] ??
          _modelInputErrors['context:${model.name}'] ??
          RequestParameters.fromModel(model).validateFor(_protocol) ??
          (model.contextWindow != null && model.contextWindow! <= 0
              ? '上下文窗口必须大于 0。'
              : null);
      if (validation != null) {
        setState(() {
          _error = '${model.displayName}：$validation';
          _expandedModel = model.name;
        });
        return false;
      }
    }
    return _error == null;
  }

  Future<String?> _effectiveKey() async {
    if (_clearKey) return null;
    final entered = _apiKey.text.trim();
    if (entered.isNotEmpty) return entered;
    if (widget.provider == null) return null;
    return ref
        .read(promptAssistantConfigProvider.notifier)
        .getProviderApiKey(widget.provider!.id);
  }

  Future<void> _fetchCatalog() async {
    if (!_validate()) return;
    setState(() {
      _busy = true;
      _catalogMessage = '正在读取模型目录…';
    });
    try {
      final names = await ref
          .read(promptAssistantServiceProvider)
          .fetchModelsForDraft(_draft(), await _effectiveKey(), _headers);
      if (!mounted) return;
      setState(() {
        _catalog = names;
        _catalogMessage = '目录返回 ${names.length} 个模型。勾选需要使用的模型。';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _catalogMessage = '目录不可用：$error。可以手动添加模型 ID。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _testModel() async {
    if (!_validate()) return;
    if (_selected.isEmpty) {
      setState(() => _error = '请先选中一个模型。');
      return;
    }
    setState(() {
      _busy = true;
      _catalogMessage = '正在测试模型请求…';
    });
    try {
      final model = _selected[_expandedModel] ?? _selected.values.first;
      final reply = await ref
          .read(promptAssistantServiceProvider)
          .testModelForDraft(_draft(), model, await _effectiveKey(), _headers);
      if (mounted) {
        setState(
          () => _catalogMessage =
              '模型请求成功：${reply.length > 90 ? '${reply.substring(0, 90)}…' : reply}',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _catalogMessage = '模型请求失败：$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_headersLoaded || _headersLoadFailed || !_validate()) return;
    for (final model in _selected.values) {
      if ((model.contextWindow != null && model.contextWindow! <= 0) ||
          (model.maxOutputTokens != null && model.maxOutputTokens! <= 0)) {
        setState(() => _error = '模型“${model.name}”的 token 数量必须大于 0。');
        return;
      }
    }
    setState(() => _busy = true);
    try {
      final id = _uniqueId();
      final notifier = ref.read(promptAssistantConfigProvider.notifier);
      if (widget.provider != null) {
        final latestHeaders = await notifier.getProviderHeaders(id);
        if (!mounted) return;
        if (_serviceSnapshot() != _observedService ||
            jsonEncode(latestHeaders) != _initialHeaders) {
          throw StateError('服务配置已在别处修改，请重新打开后编辑。');
        }
      }
      await notifier.upsertProvider(
        _draft(id: id).copyWith(requestHeaders: const {}),
      );
      if (_clearKey) {
        await notifier.setProviderApiKey(id, '');
      } else if (_apiKey.text.trim().isNotEmpty) {
        await notifier.setProviderApiKey(id, _apiKey.text);
      }
      await notifier.setProviderHeaders(id, _headers);
      await notifier.replaceProviderModels(id, [
        for (final model in _selected.values)
          model.copyWith(
            providerId: id,
            displayName: model.displayName.trim().isEmpty
                ? model.name
                : model.displayName.trim(),
          ),
      ]);
      if (mounted) {
        if (widget.embedded) {
          _initialDraft = _fingerprint;
          _observedService = _serviceSnapshot();
          _initialHeaders = jsonEncode(_headers);
          widget.onDirtyChanged?.call(false);
          widget.onSaved?.call(id);
        } else {
          Navigator.pop(context);
        }
      }
    } catch (error) {
      if (mounted) setState(() => _error = '保存失败：$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _changePreset(ProviderPreset next) {
    final previous = _preset;
    final oldName = _name.text.trim();
    final oldUrl = _baseUrl.text.trim();
    setState(() {
      _preset = next;
      _setProtocol(next.defaultProtocol);
      if (oldName.isEmpty || oldName == previous.defaultName) {
        _name.text = next.defaultName;
      }
      if (oldUrl.isEmpty || oldUrl == previous.defaultBaseUrl) {
        _baseUrl.text = next.defaultBaseUrl;
      }
      _allowImageInput = next.defaultAllowImageInput;
    });
  }

  List<String> _reasoningOptions(ProviderProtocol protocol, String modelName) {
    switch (protocol) {
      case ProviderProtocol.openaiChatCompletions:
      case ProviderProtocol.openaiResponses:
        return const ['none', 'minimal', 'low', 'medium', 'high', 'xhigh'];
      case ProviderProtocol.anthropicMessages:
        return const ['low', 'medium', 'high'];
      case ProviderProtocol.geminiGenerateContent:
        return modelName.startsWith('gemini-3')
            ? const ['minimal', 'low', 'medium', 'high']
            : const [];
      case ProviderProtocol.ollamaChatCompletions:
        return const [];
    }
  }

  void _setProtocol(ProviderProtocol protocol) {
    _protocol = protocol;
    for (final entry in _selected.entries.toList()) {
      final effort = entry.value.reasoningEffort;
      if (effort != null &&
          !_reasoningOptions(protocol, entry.key).contains(effort)) {
        _selected[entry.key] = entry.value.copyWith(clearReasoningEffort: true);
      }
    }
  }

  void _toggleModel(String name, bool selected) {
    setState(() {
      if (selected) {
        _selected.putIfAbsent(
          name,
          () => ModelConfig(
            providerId: widget.provider?.id ?? 'draft',
            name: name,
            displayName: name,
            source: ModelSource.api,
          ),
        );
      } else {
        _selected.remove(name);
        if (_expandedModel == name) _expandedModel = null;
      }
    });
  }

  void _addManual() {
    final id = _manualId.text.trim();
    if (id.isEmpty) return;
    setState(() {
      _selected.putIfAbsent(
        id,
        () => ModelConfig(
          providerId: widget.provider?.id ?? 'draft',
          name: id,
          displayName: id,
          source: ModelSource.manual,
        ),
      );
      _expandedModel = id;
      _manualId.clear();
    });
  }

  void _updateModel(
    ModelConfig model, {
    String? displayName,
    int? contextWindow,
    int? maxOutputTokens,
    String? reasoningEffort,
  }) {
    setState(
      () => _selected[model.name] = ModelConfig(
        providerId: model.providerId,
        name: model.name,
        displayName: displayName ?? model.displayName,
        isDefault: model.isDefault,
        source: model.source,
        temperature: model.temperature,
        topP: model.topP,
        contextWindow: contextWindow,
        maxOutputTokens: maxOutputTokens,
        reasoningEffort: reasoningEffort,
      ),
    );
  }

  Future<void> _showAdvanced() async {
    final result = await showDialog<_AdvancedResult>(
      context: context,
      builder: (_) => _AdvancedSettingsDialog(
        headers: _headers,
        timeoutSeconds: _timeoutSeconds,
        allowImageInput: _allowImageInput,
        imageSupported: _protocol.supportsImagePayload,
      ),
    );
    if (result != null) {
      setState(() {
        _headers = result.headers;
        _timeoutSeconds = result.timeoutSeconds;
        _allowImageInput = result.allowImageInput;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _buildEmbedded(context);
    final viewport = MediaQuery.sizeOf(context);
    final width = (viewport.width - 48).clamp(320.0, 1080.0);
    final height = (viewport.height - 48).clamp(420.0, 800.0);
    final twoColumns = width > 750;
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 14, 18, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.provider == null ? '添加 AI 服务' : '编辑 AI 服务',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _showAdvanced,
                    child: const Text('高级设置'),
                  ),
                  if (width > 950) ...[
                    TextButton(
                      onPressed: _busy ? null : _fetchCatalog,
                      child: const Text('读取目录'),
                    ),
                    TextButton(
                      onPressed: _busy ? null : _testModel,
                      child: const Text('测试模型请求'),
                    ),
                  ] else
                    PopupMenuButton<String>(
                      enabled: !_busy,
                      tooltip: '连接与模型测试',
                      icon: const Icon(Icons.network_check),
                      onSelected: (action) {
                        if (action == 'catalog') {
                          _fetchCatalog();
                        } else {
                          _testModel();
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'catalog', child: Text('读取模型目录')),
                        PopupMenuItem(
                          value: 'model',
                          child: Text('测试模型请求（消耗少量 token）'),
                        ),
                      ],
                    ),
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                  FilledButton(
                    onPressed: _busy || !_headersLoaded || _headersLoadFailed
                        ? null
                        : _save,
                    child: const Text('保存服务'),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _connectionFields(),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (_catalogMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _catalogMessage!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (twoColumns)
                      SizedBox(
                        height: 330,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: _availablePanel()),
                            const SizedBox(width: 12),
                            Expanded(child: _selectedPanel()),
                          ],
                        ),
                      )
                    else ...[
                      SizedBox(height: 260, child: _availablePanel()),
                      const SizedBox(height: 12),
                      SizedBox(height: 360, child: _selectedPanel()),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _updateOverview(VoidCallback action) => setState(action);

  Widget _buildEmbedded(BuildContext context) {
    final dirty =
        _fingerprint != _initialDraft ||
        jsonEncode(_headers) != _initialHeaders ||
        _modelInputErrors.values.any((error) => error != null);
    if (dirty != _lastDirty) {
      _lastDirty = dirty;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onDirtyChanged?.call(dirty);
      });
    }
    return _buildServiceOverview(context, dirty);
  }

  Widget _connectionFields() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.embedded) ...[
          Text('服务连接', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
        ],
        DropdownButtonFormField<ProviderPreset>(
          isExpanded: true,
          initialValue: _preset,
          decoration: const InputDecoration(labelText: '服务类型', isDense: true),
          items: [
            for (final preset in ProviderPreset.values)
              DropdownMenuItem(
                value: preset,
                child: Row(
                  children: [
                    ProviderLogo(preset, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(preset.label)),
                  ],
                ),
              ),
          ],
          onChanged: (value) {
            if (value != null) _changePreset(value);
          },
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final fields = [
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: '名称',
                  hintText: '例如：自用中转',
                  isDense: true,
                ),
              ),
              TextField(
                controller: _baseUrl,
                decoration: const InputDecoration(
                  labelText: '接口地址',
                  hintText: 'https://example.com/v1',
                  isDense: true,
                ),
              ),
            ];
            return constraints.maxWidth > 600
                ? Row(
                    children: [
                      Expanded(child: fields[0]),
                      const SizedBox(width: 10),
                      Expanded(child: fields[1]),
                    ],
                  )
                : Column(
                    children: [
                      fields[0],
                      const SizedBox(height: 10),
                      fields[1],
                    ],
                  );
          },
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final key = TextField(
              controller: _apiKey,
              obscureText: true,
              enabled: !_clearKey,
              decoration: InputDecoration(
                labelText: 'API 密钥',
                isDense: true,
                hintText: widget.provider == null
                    ? '输入密钥；本地服务可留空'
                    : '已保存的密钥不会显示；留空保持原值',
              ),
            );
            final protocol = DropdownButtonFormField<ProviderProtocol>(
              key: ValueKey('service-protocol-${_protocol.name}'),
              isExpanded: true,
              initialValue: _protocol,
              decoration: const InputDecoration(
                labelText: '接口格式',
                isDense: true,
              ),
              items: [
                for (final item in ProviderProtocol.values)
                  DropdownMenuItem(value: item, child: Text(item.label)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _setProtocol(value));
              },
            );
            return constraints.maxWidth > 600
                ? Row(
                    children: [
                      Expanded(child: key),
                      const SizedBox(width: 10),
                      Expanded(child: protocol),
                    ],
                  )
                : Column(children: [key, const SizedBox(height: 10), protocol]);
          },
        ),
        if (widget.provider != null)
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('清除已保存的 API 密钥'),
            value: _clearKey,
            onChanged: (value) => setState(() => _clearKey = value ?? false),
          ),
      ],
    );
  }

  Widget _availablePanel() {
    final colors = Theme.of(context).colorScheme;
    final query = _catalogSearch.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? _catalog
        : _catalog.where((id) => id.toLowerCase().contains(query)).toList();
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('服务模型目录', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Text(
                  '${_catalog.length}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                IconButton(
                  tooltip: '刷新目录',
                  onPressed: _busy ? null : _fetchCatalog,
                  icon: const Icon(Icons.refresh, size: 18),
                ),
              ],
            ),
            TextField(
              controller: _catalogSearch,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 18),
                hintText: '搜索模型 ID',
                isDense: true,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        _catalog.isEmpty ? '点击刷新获取目录，也可手动添加模型 ID。' : '没有匹配的模型',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemExtent: 42,
                      itemBuilder: (context, index) {
                        final id = filtered[index];
                        return CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          value: _selected.containsKey(id),
                          onChanged: (value) =>
                              _toggleModel(id, value ?? false),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selectedPanel() {
    final colors = Theme.of(context).colorScheme;
    final query = _selectedSearch.text.trim().toLowerCase();
    final models = _selected.values
        .where(
          (model) =>
              query.isEmpty ||
              model.name.toLowerCase().contains(query) ||
              model.displayName.toLowerCase().contains(query),
        )
        .toList();
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('已选模型', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(width: 6),
              Text(
                '${_selected.length}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const Spacer(),
              if (_selected.isNotEmpty)
                TextButton(
                  onPressed: () => setState(() {
                    _selected.clear();
                    _expandedModel = null;
                  }),
                  child: const Text('清空'),
                ),
            ],
          ),
          TextField(
            controller: _selectedSearch,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search, size: 18),
              hintText: '搜索已选模型',
              isDense: true,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('ai-service-manual-model-id'),
                  controller: _manualId,
                  onSubmitted: (_) => _addManual(),
                  decoration: const InputDecoration(
                    labelText: '手动添加模型 ID',
                    hintText: '例如 my-model-v2',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: '添加自定义模型',
                onPressed: _addManual,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          const Divider(height: 12),
          Expanded(
            child: models.isEmpty
                ? Center(
                    child: Text(
                      '从左侧勾选模型，或在上方输入模型 ID。',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    itemCount: models.length,
                    itemBuilder: (context, index) =>
                        _selectedTile(models[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _selectedTile(ModelConfig model) {
    final expanded = _expandedModel == model.name;
    if (widget.embedded) {
      return _overviewModelRow(model, _modelParameters(model));
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 5),
      elevation: 0,
      child: Column(
        children: [
          ListTile(
            dense: true,
            contentPadding: const EdgeInsets.only(left: 10, right: 2),
            title: Text(
              model.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: model.displayName == model.name
                ? null
                : Text(
                    model.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            onTap: () =>
                setState(() => _expandedModel = expanded ? null : model.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 17),
                  tooltip: '移除模型',
                  onPressed: () => _toggleModel(model.name, false),
                ),
              ],
            ),
          ),
          if (expanded) _modelParameters(model),
        ],
      ),
    );
  }

  Widget _modelParameters(ModelConfig model) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '模型 ID：${model.name}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: ValueKey('alias-${model.name}'),
          initialValue: model.displayName,
          decoration: const InputDecoration(
            labelText: '显示名称 / 别名',
            isDense: true,
          ),
          onChanged: (value) => _updateModel(
            _selected[model.name]!,
            displayName: value,
            contextWindow: _selected[model.name]!.contextWindow,
            maxOutputTokens: _selected[model.name]!.maxOutputTokens,
            reasoningEffort: _selected[model.name]!.reasoningEffort,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: ValueKey('context-${model.name}'),
          initialValue: model.contextWindow?.toString() ?? '',
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '上下文窗口（参考）',
            isDense: true,
          ),
          onChanged: (value) => setState(() {
            final number = int.tryParse(value);
            _modelInputErrors['context:${model.name}'] =
                value.trim().isNotEmpty && (number == null || number <= 0)
                ? '上下文窗口应为正整数。'
                : null;
            _selected[model.name] = _selected[model.name]!.copyWith(
              contextWindow: number,
              clearContextWindow: number == null,
            );
          }),
        ),
        const SizedBox(height: 18),
        ModelParameterFields(
          key: ValueKey('model-parameters-${model.name}-${_protocol.name}'),
          value: RequestParameters.fromModel(model),
          protocol: _protocol,
          onValidationChanged: (error) => _modelInputErrors[model.name] = error,
          onChanged: (value) => setState(() {
            _selected[model.name] = _selected[model.name]!.copyWith(
              temperature: value.temperature,
              clearTemperature: value.temperature == null,
              topP: value.topP,
              clearTopP: value.topP == null,
              maxOutputTokens: value.maxOutputTokens,
              clearMaxOutputTokens: value.maxOutputTokens == null,
              reasoningEffort: value.reasoningEffort,
              clearReasoningEffort: value.reasoningEffort == null,
            );
          }),
        ),
        const SizedBox(height: 5),
        Text(
          '上下文窗口只作参考；参数会发送给接口，留空使用服务默认。',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

typedef _AdvancedResult = ({
  Map<String, String> headers,
  int timeoutSeconds,
  bool allowImageInput,
});

class _AdvancedSettingsDialog extends StatefulWidget {
  const _AdvancedSettingsDialog({
    required this.headers,
    required this.timeoutSeconds,
    required this.allowImageInput,
    required this.imageSupported,
  });
  final Map<String, String> headers;
  final int timeoutSeconds;
  final bool allowImageInput;
  final bool imageSupported;

  @override
  State<_AdvancedSettingsDialog> createState() =>
      _AdvancedSettingsDialogState();
}

class _AdvancedSettingsDialogState extends State<_AdvancedSettingsDialog> {
  late final List<_HeaderDraft> _headers;
  final List<_HeaderDraft> _ownedHeaders = [];
  late final TextEditingController _timeout;
  late bool _allowImageInput;
  String? _error;

  @override
  void initState() {
    super.initState();
    _headers = [
      for (final entry in widget.headers.entries)
        _HeaderDraft(entry.key, entry.value),
    ];
    _ownedHeaders.addAll(_headers);
    _timeout = TextEditingController(text: '${widget.timeoutSeconds}');
    _allowImageInput = widget.allowImageInput;
  }

  @override
  void dispose() {
    for (final row in _ownedHeaders) {
      row.name.dispose();
      row.value.dispose();
    }
    _timeout.dispose();
    super.dispose();
  }

  Future<void> _importJson() async {
    var input = '';
    final raw = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('导入请求头 JSON'),
        content: SizedBox(
          width: 500,
          child: TextField(
            onChanged: (value) => input = value,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: '{"X-Project": "example"}',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, input),
            child: const Text('导入'),
          ),
        ],
      ),
    );
    if (raw == null) return;
    try {
      final parsed = jsonDecode(raw);
      if (parsed is! Map ||
          parsed.entries.any(
            (entry) => entry.key is! String || entry.value is! String,
          )) {
        throw const FormatException('请求头 JSON 必须是字符串键值对象。');
      }
      setState(() {
        _headers.clear();
        for (final entry in parsed.entries) {
          final row = _HeaderDraft(entry.key, entry.value);
          _headers.add(row);
          _ownedHeaders.add(row);
        }
        _error = null;
      });
    } catch (error) {
      setState(() => _error = '导入失败：$error');
    }
  }

  void _save() {
    final timeout = int.tryParse(_timeout.text.trim());
    if (timeout == null || timeout < 10 || timeout > 600) {
      setState(() => _error = '请求超时须为 10～600 秒。');
      return;
    }
    final headers = <String, String>{};
    final names = <String>{};
    final validName = RegExp(r'^[!#\$%&\x27*+.^_`|~0-9A-Za-z-]+$');
    for (final row in _headers) {
      final name = row.name.text.trim();
      final value = row.value.text.trim();
      if (name.isEmpty && value.isEmpty) continue;
      if (!validName.hasMatch(name) ||
          !names.add(name.toLowerCase()) ||
          value.contains(RegExp(r'[\r\n]'))) {
        setState(() => _error = '请求头名称无效或重复；值不能换行。');
        return;
      }
      headers[name] = value;
    }
    Navigator.pop(context, (
      headers: headers,
      timeoutSeconds: timeout,
      allowImageInput: _allowImageInput,
    ));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('高级设置'),
    content: SizedBox(
      width: 580,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _timeout,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '请求超时（秒）',
                helperText: '10～600；用于模型目录与翻译请求',
              ),
            ),
            SettingsSwitchTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('服务支持图像输入'),
              subtitle: Text(
                widget.imageSupported ? '记录服务能力；当前提示词翻译只发送文本' : '当前接口格式不支持图像载荷',
              ),
              value: _allowImageInput,
              onChanged: widget.imageSupported
                  ? (value) => setState(() => _allowImageInput = value)
                  : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('自定义请求头', style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                TextButton(
                  onPressed: _importJson,
                  child: const Text('导入 JSON'),
                ),
                TextButton(
                  onPressed: () => Clipboard.setData(
                    ClipboardData(
                      text: jsonEncode({
                        for (final row in _headers)
                          if (row.name.text.trim().isNotEmpty)
                            row.name.text.trim(): row.value.text,
                      }),
                    ),
                  ),
                  child: const Text('复制 JSON'),
                ),
              ],
            ),
            Text(
              '请求头可覆盖默认认证字段，并保存在系统安全存储中。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 6),
            for (var index = 0; index < _headers.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: ValueKey('ai-header-name-$index'),
                        controller: _headers[index].name,
                        decoration: const InputDecoration(
                          hintText: 'Header 名称',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        key: ValueKey('ai-header-value-$index'),
                        controller: _headers[index].value,
                        decoration: const InputDecoration(
                          hintText: '值',
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: '删除请求头',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() {
                        _headers.removeAt(index);
                      }),
                    ),
                  ],
                ),
              ),
            TextButton.icon(
              onPressed: () => setState(() {
                final row = _HeaderDraft('', '');
                _headers.add(row);
                _ownedHeaders.add(row);
              }),
              icon: const Icon(Icons.add, size: 17),
              label: const Text('添加请求头'),
            ),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('取消'),
      ),
      FilledButton(onPressed: _save, child: const Text('应用')),
    ],
  );
}

class _HeaderDraft {
  _HeaderDraft(String name, String value)
    : name = TextEditingController(text: name),
      value = TextEditingController(text: value);
  final TextEditingController name;
  final TextEditingController value;
}
