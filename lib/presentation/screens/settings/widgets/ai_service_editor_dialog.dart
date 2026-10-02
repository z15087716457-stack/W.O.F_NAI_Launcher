import 'settings_tile.dart';
import 'dart:collection';
import '../../../themes/studio_typography.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'provider_logo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../../prompt_assistant/services/prompt_assistant_service.dart';
import '../../../prompt_assistant/models/prompt_task_definitions.dart';
import 'model_configuration_card.dart';
import 'model_parameter_fields.dart' show reasoningChoices;
import 'provider_picker.dart';

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
  final _catalogDetails = <String, ModelConfig>{};
  bool _catalogFromApi = false;
  String? _expandedModel;
  String? _error;
  String? _catalogMessage;
  bool _busy = false;
  bool _headersLoaded = false;
  bool _headersLoadFailed = false;
  bool _clearKey = false;
  bool _vendorChanged = false;
  bool _allowImageInput = false;
  int _timeoutSeconds = 120;
  int _maxConcurrentRequests = 5;
  int _retryAttempts = 0;
  bool _editingConnection = false;
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
    _catalogDetails.addAll(_selected);
    _catalog = {..._preset.defaultModelNames, ..._selected.keys}.toList();
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
    if (_vendorChanged) return null;
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
        _catalogFromApi = true;
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
      if (_clearKey || (_vendorChanged && _apiKey.text.trim().isEmpty)) {
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
      _vendorChanged = false;
      _clearKey = false;
      _apiKey.clear();
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
      if (previous.vendor != next.vendor) {
        _vendorChanged = widget.provider != null;
        _apiKey.clear();
        _clearKey = false;
        _headers = {};
        _selected.clear();
        _catalogDetails.clear();
        _modelInputErrors.clear();
        _expandedModel = null;
      }
      _setProtocol(next.defaultProtocol);
      if (oldName.isEmpty || oldName == previous.defaultName) {
        _name.text = next.defaultName;
      }
      if (oldUrl.isEmpty ||
          oldUrl == previous.defaultBaseUrl ||
          previous.vendor != next.vendor) {
        _baseUrl.text = next.defaultBaseUrl;
      }
      _allowImageInput = next.defaultAllowImageInput;
      _catalog = List.of(next.defaultModelNames);
      _catalogFromApi = false;
      _catalogMessage = null;
      _catalogSearch.clear();
      if (_selected.isEmpty) {
        for (final name in next.defaultModelNames) {
          _selected[name] = ModelConfig(
            providerId: 'draft',
            name: name,
            displayName: name,
          );
        }
      }
    });
  }

  void _setProtocol(ProviderProtocol protocol) {
    _protocol = protocol;
    final allowed = reasoningChoices(protocol);
    for (final models in [_selected, _catalogDetails]) {
      for (final entry in models.entries.toList()) {
        models[entry.key] = entry.value.copyWith(
          reasoningEfforts: entry.value.reasoningEfforts
              ?.where(allowed.contains)
              .toList(),
          clearReasoningEffort:
              entry.value.reasoningEffort != null &&
              !allowed.contains(entry.value.reasoningEffort),
        );
      }
    }
  }

  void _toggleModel(String name, bool selected) {
    setState(() {
      if (selected) {
        _selected.putIfAbsent(
          name,
          () =>
              _catalogDetails[name] ??
              ModelConfig(
                providerId: widget.provider?.id ?? 'draft',
                name: name,
                displayName: name,
                source: _catalogFromApi ? ModelSource.api : ModelSource.manual,
              ),
        );
      } else {
        _selected.remove(name);
        _modelInputErrors.remove(name);
        _modelInputErrors.remove('context:$name');
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
                    onPressed: _busy
                        ? null
                        : () => _updateOverview(
                            () => _advancedExpanded = !_advancedExpanded,
                          ),
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
                    const SizedBox(height: 18),
                    _advancedOverview(context),
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
        InkWell(
          key: const Key('service-provider-picker'),
          borderRadius: BorderRadius.circular(8),
          onTap: _busy || !_headersLoaded
              ? null
              : () async {
                  final next = await showProviderPicker(context, _preset);
                  if (mounted && next != null) _changePreset(next);
                },
          child: InputDecorator(
            decoration: const InputDecoration(labelText: '服务商'),
            child: Row(
              children: [
                ProviderLogo(_preset, size: 22),
                const SizedBox(width: 10),
                Expanded(child: Text(_preset.label)),
                const Icon(Icons.unfold_more_rounded, size: 18),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(_preset.connectionHint, style: theme.textTheme.bodySmall),
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
                    : _vendorChanged
                    ? '请输入此服务商的 Key；旧 Key 不会发往新厂商'
                    : '已保存的密钥不会显示；留空保持原值',
              ),
            );
            return key;
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<ProviderProtocol>(
          key: ValueKey('service-protocol-${_protocol.name}'),
          initialValue: _protocol,
          isExpanded: true,
          decoration: const InputDecoration(labelText: '接口协议', isDense: true),
          items: [
            for (final protocol in ProviderProtocol.values)
              DropdownMenuItem(value: protocol, child: Text(protocol.label)),
          ],
          onChanged: _busy
              ? null
              : (value) {
                  if (value != null) _updateOverview(() => _setProtocol(value));
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
    final theme = Theme.of(context), colors = theme.colorScheme;
    final query = _catalogSearch.text.trim().toLowerCase();
    final filtered = _catalog
        .where(
          (id) => '$id ${_catalogDetails[id]?.displayName ?? ''}'
              .toLowerCase()
              .contains(query),
        )
        .toList();
    final selectedCount = filtered.where(_selected.containsKey).length;
    final bool? allSelected = selectedCount == 0
        ? false
        : selectedCount == filtered.length
        ? true
        : null;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final search = TextField(
      key: const Key('service-catalog-search'),
      controller: _catalogSearch,
      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search, size: 14),
        hintText: '搜索模型 ID…',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        prefixIconConstraints: BoxConstraints(minWidth: 28, minHeight: 28),
      ),
    );
    final controls = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 20,
          height: 28 * scale,
          child: Checkbox(
            key: const Key('service-catalog-select-all'),
            value: allSelected,
            tristate: true,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: _busy || filtered.isEmpty
                ? null
                : (_) {
                    final select = allSelected != true;
                    for (final id in filtered) {
                      _toggleModel(id, select);
                    }
                  },
          ),
        ),
        const SizedBox(width: 7),
        Text(
          '该服务的模型',
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurface,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 7),
        TextButton.icon(
          key: const Key('service-fetch-catalog'),
          onPressed: _busy ? null : _fetchCatalog,
          style: TextButton.styleFrom(
            foregroundColor: colors.onSurfaceVariant,
            backgroundColor: colors.surfaceContainerHighest.withValues(
              alpha: .45,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
            minimumSize: const Size(0, 28),
            visualDensity: VisualDensity.compact,
            textStyle: theme.textTheme.labelSmall,
          ),
          icon: const Icon(Icons.refresh, size: 13),
          label: const Text('获取列表'),
        ),
      ],
    );
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) =>
                  constraints.maxWidth < 350 * scale
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [controls, const SizedBox(height: 7), search],
                    )
                  : Row(
                      children: [
                        controls,
                        const SizedBox(width: 12),
                        Expanded(child: search),
                      ],
                    ),
            ),
            const SizedBox(height: 7),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        _catalog.isEmpty ? '获取模型列表，或在右侧手动添加模型 ID。' : '没有匹配的模型',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      key: const Key('service-catalog-list'),
                      itemCount: filtered.length,
                      itemExtent: 30 * scale,
                      itemBuilder: (context, index) {
                        final id = filtered[index],
                            selected = _selected.containsKey(id),
                            metadata = _catalogDetails[id];
                        final alias = metadata?.displayName ?? id;
                        final capacity =
                            metadata?.contextWindow != null ||
                            metadata?.maxOutputTokens != null;
                        String tokens(int? n) => n == null
                            ? '—'
                            : n >= 1000000
                            ? '${(n / 1000000).toStringAsFixed(n % 1000000 == 0 ? 0 : 1)}M'
                            : n >= 1000
                            ? '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}K'
                            : '$n';
                        return Semantics(
                          selected: selected,
                          child: Material(
                            color: selected
                                ? colors.primary.withValues(alpha: .065)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(5),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              key: ValueKey('catalog-model-$id'),
                              onTap: _busy
                                  ? null
                                  : () => _toggleModel(id, !selected),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                ),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      child: Checkbox(
                                        value: selected,
                                        onChanged: _busy
                                            ? null
                                            : (value) => _toggleModel(
                                                id,
                                                value ?? false,
                                              ),
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 9),
                                    Expanded(
                                      child: Tooltip(
                                        message: alias == id
                                            ? id
                                            : '$id · $alias',
                                        child: Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                id,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      fontFamily:
                                                          StudioTypography.mono,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                              ),
                                            ),
                                            if (alias != id &&
                                                alias.isNotEmpty) ...[
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  alias,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: colors
                                                            .onSurfaceVariant,
                                                        fontSize: 11,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (capacity) ...[
                                      const SizedBox(width: 8),
                                      SizedBox(
                                        width: 84 * scale,
                                        child: Tooltip(
                                          message: '上下文 / 最大输出',
                                          child: Text(
                                            '${tokens(metadata!.contextWindow)} · ${tokens(metadata.maxOutputTokens)}',
                                            textAlign: TextAlign.right,
                                            maxLines: 1,
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color: colors.onSurfaceVariant
                                                      .withValues(alpha: .8),
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
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
                    _catalogDetails.clear();
                    _expandedModel = null;
                    _modelInputErrors.clear();
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
          const Divider(height: 16),
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

  Widget _modelParameters(ModelConfig model) => ModelConfigurationCard(
    key: ValueKey('model-parameters-${model.name}-${_protocol.name}'),
    value: model,
    protocol: _protocol,
    enabled: !_busy,
    onValidationChanged: (error) => _modelInputErrors[model.name] = error,
    onChanged: (value) => setState(() {
      _selected[model.name] = value;
      _catalogDetails[model.name] = value;
    }),
  );
}
