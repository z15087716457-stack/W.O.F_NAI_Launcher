import 'settings_tile.dart';
import 'dart:collection';
import '../../../themes/studio_typography.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'provider_logo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../../prompt_assistant/services/prompt_assistant_service.dart';
import '../../../prompt_assistant/models/prompt_task_definitions.dart';
import 'model_configuration_card.dart';
import 'model_parameter_fields.dart' show reasoningChoices;
import 'provider_picker.dart';
import 'compact_service_connection.dart';
import 'model_management_widgets.dart' show interfaceIcon;
import '../../../prompt_assistant/models/model_catalog_entry.dart';
import '../../../prompt_assistant/services/model_catalog_repository.dart';
import 'model_draft_save_controller.dart';
import 'model_request_overrides_editor.dart';
import 'service_request_controls.dart';

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
    this.onDelete,
    this.onDirtyChanged,
    this.onTaskSelected,
    this.saveController,
  });
  final ProviderConfig? provider;
  final ProviderPreset? initialPreset;
  final bool embedded;
  final ValueChanged<String>? onSaved;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onDirtyChanged;
  final ValueChanged<LauncherInterface>? onTaskSelected;
  final ModelDraftSaveController? saveController;

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
  final _selectedScroll = ScrollController();
  final _selectedRowKeys = <String, GlobalKey>{};
  late final LinkedHashMap<String, ModelConfig> _selected;
  Map<String, String> _headers = {};
  final _initialModelOverrides = <String, String>{};
  final _requestDrafts = <String, ModelRequestDraft>{};
  final _requestInputErrors = <String, String?>{};
  List<String> _catalog = [];
  ModelCatalogRepository _localCatalog =
      ModelCatalogRepository.cached ?? ModelCatalogRepository.empty;
  ModelCatalogEntry? _catalogDetails(String id) =>
      _localCatalog.lookup(_preset, id);
  ModelConfig _enrich(ModelConfig model) =>
      _localCatalog.enrich(model, _preset, protocol: _protocol);
  ModelConfig _newModel(String name, ModelSource source) => _enrich(
    ModelConfig(
      providerId: _providerId ?? 'draft',
      name: name,
      displayName: name,
      source: source,
      customFields: const {},
    ),
  );
  bool _catalogFromApi = false;
  String? _fetchedConnection;
  String? _expandedModel;
  String? _error;
  String? _catalogMessage;
  bool _busy = false;
  bool _saving = false;
  String? _savedProviderId;
  String? get _providerId => _savedProviderId ?? widget.provider?.id;
  bool _headersLoaded = false;
  bool _headersLoadFailed = false;
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
    final id = _providerId;
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
    ]);
    for (final entry in _selected.entries.toList()) {
      _selected[entry.key] = _enrich(entry.value);
    }
    _initialDraft = _fingerprint;
    _observedService = _serviceSnapshot();
    widget.saveController?.attach(this, _save);
    for (final controller in [_name, _baseUrl, _apiKey]) {
      controller.addListener(_refresh);
    }
    _loadHeaders();
    _loadLocalCatalog();
  }

  Future<void> _loadLocalCatalog() async {
    if (ModelCatalogRepository.cached != null) return;
    try {
      final catalog = await ModelCatalogRepository.load();
      if (!mounted) return;
      final wasClean = _fingerprint == _initialDraft;
      setState(() {
        _localCatalog = catalog;
        for (final entry in _selected.entries.toList()) {
          _selected[entry.key] = _enrich(entry.value);
        }
        if (wasClean) _initialDraft = _fingerprint;
        if (wasClean) _observedService = _serviceSnapshot();
      });
    } catch (_) {
      // API model IDs and manual settings remain usable without local facts.
    }
  }

  Future<void> _loadHeaders() async {
    final loaded = <String, ModelConfig>{};
    if (widget.provider != null) {
      try {
        final notifier = ref.read(promptAssistantConfigProvider.notifier);
        _headers = await notifier.getProviderHeaders(widget.provider!.id);
        if (!mounted) return;
        _initialHeaders = jsonEncode(_headers);
        for (final model in _selected.values.toList()) {
          final value = await notifier.loadModelRequestOverrides(model);
          if (!mounted) return;
          loaded[model.name] = value;
          _initialModelOverrides[model.name] = value.requestOverrides!.encode();
        }
      } catch (error) {
        _headersLoadFailed = true;
        _error = '读取自定义请求设置失败：$error';
      }
    }
    if (mounted) {
      setState(() {
        final clean = _fingerprint == _initialDraft;
        for (final entry in loaded.entries) {
          if (_selected[entry.key] case final current?) {
            _selected[entry.key] = current.copyWith(
              requestOverrides: entry.value.requestOverrides,
            );
          }
        }
        _headersLoaded = true;
        if (clean) _initialDraft = _fingerprint;
      });
    }
  }

  String get _fingerprint => jsonEncode([
    _name.text,
    _baseUrl.text,
    _apiKey.text,
    _preset.name,
    _protocol.name,
    _enabled,
    _allowImageInput,
    _timeoutSeconds,
    _maxConcurrentRequests,
    _retryAttempts,
    _selected.values.map((m) => m.toJson()).toList(),
    _selected.values.map((m) => m.requestOverrides?.toJson()).toList(),
    {
      for (final e in _requestDrafts.entries)
        if (_selected.containsKey(e.key)) e.key: e.value.fingerprint,
    },
  ]);

  void _refresh() {
    if (mounted) setState(_invalidateFetchedCatalog);
  }

  String get _catalogConnection => jsonEncode([
    _preset.name,
    _protocol.name,
    _baseUrl.text.trim(),
    _apiKey.text.trim(),
    _vendorChanged,
    [
      for (final name in _headers.keys.toList()..sort()) [name, _headers[name]],
    ],
  ]);

  void _invalidateFetchedCatalog() {
    if (_fetchedConnection != null &&
        _fetchedConnection != _catalogConnection) {
      _catalog = [];
      _catalogFromApi = false;
      _catalogMessage = null;
      _fetchedConnection = null;
    }
  }

  @override
  void dispose() {
    widget.saveController?.detach(this);
    _name.dispose();
    _baseUrl.dispose();
    _apiKey.dispose();
    _catalogSearch.dispose();
    _selectedSearch.dispose();
    _manualId.dispose();
    _selectedScroll.dispose();
    super.dispose();
  }

  String _uniqueId() {
    if (_providerId case final id?) return id;
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
    id: id ?? _providerId ?? 'draft',
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
          : _maxConcurrentRequests < 1 || _maxConcurrentRequests > 20
          ? '最大并发数量应在 1–20 个之间。'
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
          _requestInputErrors[model.name] ??
          model.requestOverrides?.validate(model.name) ??
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
    final entered = _apiKey.text.trim();
    if (entered.isNotEmpty) return entered;
    if (_vendorChanged) return null;
    if (_providerId == null) return null;
    return ref
        .read(promptAssistantConfigProvider.notifier)
        .getProviderApiKey(_providerId!);
  }

  Future<void> _fetchCatalog() async {
    if (!_validate()) return;
    final connection = _catalogConnection;
    setState(() {
      _busy = true;
      _catalogMessage = '正在读取模型目录…';
    });
    try {
      final names = await ref
          .read(promptAssistantServiceProvider)
          .fetchModelsForDraft(_draft(), await _effectiveKey(), _headers);
      if (!mounted || connection != _catalogConnection) return;
      setState(() {
        _catalog = names;
        _catalogFromApi = true;
        _fetchedConnection = connection;
        _catalogMessage = '目录返回 ${names.length} 个模型。勾选需要使用的模型。';
      });
    } catch (error) {
      if (!mounted || connection != _catalogConnection) return;
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

  Future<bool> _save() async {
    if (_busy || !_headersLoaded || _headersLoadFailed || !_validate()) {
      return false;
    }
    for (final model in _selected.values) {
      if ((model.contextWindow != null && model.contextWindow! <= 0) ||
          (model.maxOutputTokens != null && model.maxOutputTokens! <= 0)) {
        setState(() => _error = '模型“${model.name}”的 token 数量必须大于 0。');
        return false;
      }
    }
    setState(() {
      _busy = true;
      _saving = true;
    });
    try {
      final id = _uniqueId();
      final notifier = ref.read(promptAssistantConfigProvider.notifier);
      if (_providerId != null) {
        final latestHeaders = await notifier.getProviderHeaders(id);
        if (!mounted) return false;
        if (_serviceSnapshot() != _observedService ||
            jsonEncode(latestHeaders) != _initialHeaders) {
          throw StateError('服务配置已在别处修改，请重新打开后编辑。');
        }
        for (final entry in _initialModelOverrides.entries) {
          final current = await notifier.loadModelRequestOverrides(
            ModelConfig(
              providerId: id,
              name: entry.key,
              displayName: entry.key,
              hasRequestOverrides: true,
            ),
          );
          if (!mounted) return false;
          if (current.requestOverrides!.encode() != entry.value) {
            throw StateError('模型请求设置已在别处修改，请重新打开后编辑。');
          }
        }
      }
      await notifier.saveServiceDraft(
        provider: _draft(id: id),
        headers: _headers,
        apiKey: _vendorChanged && _apiKey.text.trim().isEmpty
            ? ''
            : _apiKey.text.trim().isNotEmpty
            ? _apiKey.text
            : null,
        models: [
          for (final model in _selected.values)
            model.copyWith(
              providerId: id,
              displayName: model.displayName.trim().isEmpty
                  ? model.name
                  : model.displayName.trim(),
            ),
        ],
      );
      // Committing the entered key does not change the effective connection.
      // Keep explicit discovery results when the same editor becomes saved.
      final retainCatalog = _fetchedConnection == _catalogConnection;
      _savedProviderId = id;
      _vendorChanged = false;
      _apiKey.removeListener(_refresh);
      _apiKey.clear();
      _apiKey.addListener(_refresh);
      if (retainCatalog) _fetchedConnection = _catalogConnection;
      for (final entry in _selected.entries.toList()) {
        _selected[entry.key] = entry.value.copyWith(providerId: id);
      }
      if (mounted) {
        if (widget.embedded) {
          _editingConnection = false;
          _advancedExpanded = false;
          _initialDraft = _fingerprint;
          _observedService = _serviceSnapshot();
          _initialHeaders = jsonEncode(_headers);
          _initialModelOverrides
            ..clear()
            ..addAll({
              for (final model in _selected.values)
                if (model.requestOverrides != null)
                  model.name: model.requestOverrides!.encode(),
            });
          widget.onDirtyChanged?.call(false);
          widget.onSaved?.call(id);
        } else {
          Navigator.pop(context);
        }
      }
      return true;
    } catch (error) {
      if (mounted) setState(() => _error = '保存失败：$error');
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _saving = false;
        });
      }
    }
  }

  void _changePreset(ProviderPreset next) {
    final previous = _preset;
    final oldName = _name.text.trim();
    final oldUrl = _baseUrl.text.trim();
    setState(() {
      _preset = next;
      if (previous.vendor != next.vendor) {
        _vendorChanged = _providerId != null;
        _apiKey.clear();
        _headers = {};
        _selected.clear();
        _modelInputErrors.clear();
        _requestDrafts.clear();
        _requestInputErrors.clear();
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
      _catalog = [];
      _catalogFromApi = false;
      _fetchedConnection = null;
      _catalogMessage = null;
      _catalogSearch.clear();
    });
  }

  void _setProtocol(ProviderProtocol protocol) {
    _protocol = protocol;
    _invalidateFetchedCatalog();
    final allowed = reasoningChoices(protocol);
    for (final models in [_selected]) {
      for (final entry in models.entries.toList()) {
        models[entry.key] = _enrich(entry.value).copyWith(
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
          () => _newModel(
            name,
            _catalogFromApi ? ModelSource.api : ModelSource.manual,
          ),
        );
      } else {
        _selected.remove(name);
        _modelInputErrors.remove(name);
        _modelInputErrors.remove('context:$name');
        _requestInputErrors.remove(name);
        _requestDrafts.remove(name);
        if (_expandedModel == name) _expandedModel = null;
      }
    });
  }

  void _toggleAdvanced(String name) {
    final opening = _expandedModel != name;
    _updateOverview(() => _expandedModel = opening ? name : null);
    if (!opening) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _expandedModel != name) return;
      final row = _selectedRowKeys[name]?.currentContext;
      final box = row?.findRenderObject();
      final inner = row == null ? null : Scrollable.maybeOf(row);
      if (inner == null || box is! RenderBox) return;
      final before = inner.position.pixels;
      _revealAdvancedRow(inner, box, box);
      void revealOuter() {
        if (!mounted || _expandedModel != name || !box.attached) return;
        final outer = Scrollable.maybeOf(inner.context);
        final anchor = inner.context.findRenderObject();
        if (outer != null && anchor != null) {
          _revealAdvancedRow(outer, anchor, box);
        }
      }

      if (inner.position.pixels == before) {
        revealOuter();
      } else {
        // Read the outer coordinates after the inner viewport has laid out.
        WidgetsBinding.instance.addPostFrameCallback((_) => revealOuter());
        WidgetsBinding.instance.ensureVisualUpdate();
      }
    });
  }

  void _revealAdvancedRow(
    ScrollableState scrollable,
    RenderObject anchor,
    RenderBox row,
  ) {
    final viewport = RenderAbstractViewport.maybeOf(anchor);
    if (viewport is! RenderBox) return;
    final top = row.localToGlobal(Offset.zero, ancestor: viewport).dy;
    final height = scrollable.position.viewportDimension;
    final policy = top < 0 || row.size.height > height
        ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
        : top + row.size.height > height
        ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
        : null;
    if (policy != null) {
      scrollable.position.ensureVisible(
        anchor,
        targetRenderObject: row,
        alignmentPolicy: policy,
      );
    }
  }

  void _addManual() {
    final id = _manualId.text.trim();
    if (id.isEmpty) return;
    setState(() {
      _selected.putIfAbsent(id, () => _newModel(id, ModelSource.manual));
      _expandedModel = id;
      _manualId.clear();
      _selectedSearch.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _selectedScroll.hasClients) {
        _selectedScroll.animateTo(
          _selectedScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
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
                  _saveButton(),
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
                            Expanded(flex: 51, child: _availablePanel()),
                            const SizedBox(width: 12),
                            Expanded(flex: 49, child: _selectedPanel()),
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

  void _updateOverview(VoidCallback action) => setState(() {
    action();
    _invalidateFetchedCatalog();
  });

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

  Widget _connectionFields() => CompactServiceConnection(
    preset: _preset,
    protocol: _protocol,
    name: _name,
    url: _baseUrl,
    apiKey: _apiKey,
    enabled: !_busy && _headersLoaded,
    keyHint: _providerId == null
        ? '输入 Key；本地服务可留空'
        : _vendorChanged
        ? '输入此服务商的 Key'
        : '已保存；留空保持原值',
    onProtocolChanged: (value) => _updateOverview(() => _setProtocol(value)),
    onChooseProvider: () async {
      final next = await showProviderPicker(context, _preset);
      if (mounted && next != null) _changePreset(next);
    },
  );

  Widget _availablePanel() {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final query = _catalogSearch.text.trim().toLowerCase();
    final filtered = _catalog
        .where(
          (id) => '$id ${_catalogDetails(id)?.name ?? ''}'
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
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, size: 14),
        hintText: '搜索模型 ID…',
        isDense: true,
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: .45),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 27,
          minHeight: 27,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
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
            activeColor: colors.onSurface,
            checkColor: colors.surface,
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
                  constraints.maxWidth < 380 * scale
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        controls,
                        const SizedBox(height: 7),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(width: 165 * scale, child: search),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        controls,
                        const Spacer(),
                        SizedBox(width: 165 * scale, child: search),
                      ],
                    ),
            ),
            const SizedBox(height: 7),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        _catalog.isEmpty
                            ? '点击“获取列表”读取此服务的模型，\n或在右侧手动添加模型 ID。'
                            : '没有匹配的模型',
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
                            metadata = _catalogDetails(id);
                        final alias = metadata?.name ?? id;
                        final capacity =
                            metadata?.contextLimit != null ||
                            metadata?.outputLimit != null;
                        String tokens(int? n) =>
                            n == null ? '—' : modelTokenLabel(n);
                        return Semantics(
                          selected: selected,
                          child: Material(
                            color: selected
                                ? colors.onSurface.withValues(alpha: .075)
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
                                        activeColor: colors.onSurface,
                                        checkColor: colors.surface,
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
                                              flex: 2,
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
                                          message: '目录上限：上下文 / 最大输出',
                                          child: Text(
                                            '${tokens(metadata!.contextLimit)} · ${tokens(metadata.outputLimit)}',
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

  void _reorderModels(List<ModelConfig> visible, int from, int to) {
    final ordered = [...visible];
    ordered.insert(to, ordered.removeAt(from));
    final visibleIds = visible.map((m) => m.name).toSet();
    var index = 0;
    final entries = [
      for (final model in _selected.values)
        if (visibleIds.contains(model.name))
          MapEntry(ordered[index].name, ordered[index++])
        else
          MapEntry(model.name, model),
    ];
    setState(() {
      _selected
        ..clear()
        ..addEntries(entries);
    });
  }

  Widget _selectedPanel() {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final query = _selectedSearch.text.trim().toLowerCase();
    final models = _selected.values
        .where(
          (model) =>
              query.isEmpty ||
              model.name.toLowerCase().contains(query) ||
              model.displayName.toLowerCase().contains(query),
        )
        .toList();
    final search = TextField(
      key: const Key('service-selected-search'),
      controller: _selectedSearch,
      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search, size: 14),
        hintText: '搜索已添加模型…',
        isDense: true,
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: .45),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 27,
          minHeight: 27,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide.none,
        ),
      ),
    );
    final title = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '模型设置',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            '${_selected.length}',
            style: theme.textTheme.labelSmall?.copyWith(fontSize: 10),
          ),
        ),
      ],
    );
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, c) => c.maxWidth < 290 * scale
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        title,
                        const SizedBox(height: 5),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(width: 165 * scale, child: search),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        title,
                        const Spacer(),
                        SizedBox(width: 165 * scale, child: search),
                      ],
                    ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: models.isEmpty
                  ? Center(
                      child: Text(
                        query.isEmpty ? '从左侧勾选，或在下方添加模型' : '没有匹配的模型',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      key: const Key('service-selected-list'),
                      scrollController: _selectedScroll,
                      buildDefaultDragHandles: false,
                      itemCount: models.length,
                      onReorderItem: (from, to) =>
                          _reorderModels(models, from, to),
                      proxyDecorator: (child, index, animation) => Material(
                        elevation: 3,
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(7),
                        child: child,
                      ),
                      itemBuilder: (context, index) => KeyedSubtree(
                        key: ValueKey('selected-model-${models[index].name}'),
                        child: _overviewModelRow(
                          models[index],
                          _modelParameters(models[index]),
                          index,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, c) {
                final input = TextField(
                  key: const Key('ai-service-manual-model-id'),
                  controller: _manualId,
                  enabled: !_busy,
                  onSubmitted: (_) => _addManual(),
                  style: theme.textTheme.bodySmall,
                  decoration: InputDecoration(
                    hintText: '自定义模型 ID',
                    prefixIcon: Tooltip(
                      message: '添加模型目录无法拉取到的模型',
                      triggerMode: TooltipTriggerMode.tap,
                      child: Icon(
                        Icons.help_outline,
                        size: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 28,
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: colors.surfaceContainerHighest.withValues(
                      alpha: .6,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide.none,
                    ),
                  ),
                );
                final add = TextButton.icon(
                  key: const Key('service-add-custom-model'),
                  onPressed: _busy ? null : _addManual,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.onSurface,
                    backgroundColor: colors.surfaceContainerHighest.withValues(
                      alpha: .6,
                    ),
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 9,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                    ),
                    textStyle: theme.textTheme.bodySmall,
                  ),
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('添加自定义模型'),
                );
                return c.maxWidth < 340 * scale
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          input,
                          const SizedBox(height: 5),
                          Align(alignment: Alignment.centerRight, child: add),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: input),
                          const SizedBox(width: 8),
                          add,
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _modelParameters(ModelConfig model) => ModelConfigurationCard(
    key: ValueKey('model-parameters-${model.name}-${_protocol.name}'),
    value: model,
    protocol: _protocol,
    enabled: !_busy && _headersLoaded && !_headersLoadFailed,
    requestDraft: _requestDrafts[model.name],
    onRequestDraftChanged: (draft) =>
        setState(() => _requestDrafts[model.name] = draft),
    onRequestValidationChanged: (error) =>
        _requestInputErrors[model.name] = error,
    onValidationChanged: (error) => _modelInputErrors[model.name] = error,
    onChanged: (value) => setState(() {
      _selected[model.name] = value;
    }),
  );
}
