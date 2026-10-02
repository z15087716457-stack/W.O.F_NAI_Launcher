import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../prompt_assistant/models/model_catalog_entry.dart';
import '../../../prompt_assistant/models/prompt_task_definitions.dart';
import '../../../prompt_assistant/models/prompt_assistant_models.dart';
import '../../../prompt_assistant/providers/prompt_assistant_config_provider.dart';
import '../../../prompt_assistant/services/model_catalog_repository.dart';
import '../../../prompt_assistant/services/provider_model_list_cache.dart';
import '../../../prompt_assistant/services/prompt_assistant_service.dart';
import 'compact_service_connection.dart';
import 'model_configuration_card.dart';
import 'model_draft_save_controller.dart';
import 'model_management_widgets.dart' show interfaceIcon;
import 'model_request_overrides_editor.dart';
import 'provider_logo.dart';
import 'provider_picker.dart';
import 'service_request_controls.dart';
import 'settings_tile.dart';
import 'settings_ui_theme.dart';

part 'ai_service_overview.dart';
part 'ai_service_model_panels.dart';

enum _ServiceOperation { discover, test, save }

class AiServiceEditor extends ConsumerStatefulWidget {
  const AiServiceEditor({
    super.key,
    this.provider,
    this.initialPreset,
    required this.onSaved,
    this.onDelete,
    this.onDirtyChanged,
    this.onTaskSelected,
    this.saveController,
  });
  final ProviderConfig? provider;
  final ProviderPreset? initialPreset;
  final ValueChanged<String> onSaved;
  final VoidCallback? onDelete;
  final ValueChanged<bool>? onDirtyChanged;
  final ValueChanged<LauncherInterface>? onTaskSelected;
  final ModelDraftSaveController? saveController;

  @override
  ConsumerState<AiServiceEditor> createState() => _AiServiceEditorState();
}

class _AiServiceEditorState extends ConsumerState<AiServiceEditor> {
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
  String? _catalogFingerprint;
  String? _expandedModel;
  String? _error;
  String? _catalogMessage;
  _ServiceOperation? _operation;
  bool get _busy => _operation != null;
  bool get _saving => _operation == _ServiceOperation.save;
  String? _savedProviderId;
  String? get _providerId => _savedProviderId ?? widget.provider?.id;
  bool _headersLoaded = false;
  bool _headersLoadFailed = false;
  bool get _canOperate => !_busy && _headersLoaded && !_headersLoadFailed;
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
      await _restoreCatalog();
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
      _catalogFingerprint = null;
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
    if (!_canOperate || !_validate()) return;
    final connection = _catalogConnection;
    setState(() {
      _operation = _ServiceOperation.discover;
      _catalogMessage = '正在读取模型目录…';
    });
    try {
      final provider = _draft();
      final headers = Map<String, String>.from(_headers);
      final key = await _effectiveKey();
      if (!mounted || connection != _catalogConnection) return;
      final names = await ref
          .read(promptAssistantServiceProvider)
          .fetchModelsForDraft(provider, key, headers);
      if (!mounted || connection != _catalogConnection) return;
      setState(() {
        _catalog = names;
        _catalogFromApi = true;
        _fetchedConnection = connection;
        _catalogFingerprint = ProviderModelListCache.fingerprint(
          provider,
          key,
          headers,
        );
        _catalogMessage = '目录返回 ${names.length} 个模型。勾选需要使用的模型。';
      });
      await _persistCatalog();
    } catch (error) {
      if (!mounted || connection != _catalogConnection) return;
      setState(() => _catalogMessage = '目录不可用：$error。可以手动添加模型 ID。');
    } finally {
      if (mounted) setState(() => _operation = null);
    }
  }

  Future<void> _restoreCatalog() async {
    try {
      final id = _providerId;
      if (id == null ||
          !_headersLoaded ||
          _headersLoadFailed ||
          _catalogFromApi) {
        return;
      }
      final connection = _catalogConnection;
      final key = await _effectiveKey();
      if (!mounted || connection != _catalogConnection || _catalogFromApi) {
        return;
      }
      final fingerprint = ProviderModelListCache.fingerprint(
        _draft(),
        key,
        _headers,
      );
      final names = ref
          .read(providerModelListCacheProvider)
          .modelsFor(id, fingerprint);
      if (names == null) return;
      setState(() {
        _catalog = names;
        _catalogFromApi = true;
        _fetchedConnection = connection;
        _catalogFingerprint = fingerprint;
        _catalogMessage = '已载入上次获取的 ${names.length} 个模型。点击“获取列表”可刷新。';
      });
    } catch (_) {
      AppLogger.w('Model list cache read failed.', 'PromptAssistant');
    }
  }

  Future<void> _persistCatalog() async {
    try {
      final id = _providerId;
      final fingerprint = _catalogFingerprint;
      if (id == null || fingerprint == null || !_catalogFromApi) return;
      final names = List<String>.from(_catalog);
      final provider = ref
          .read(promptAssistantConfigProvider)
          .providers
          .where((item) => item.id == id)
          .firstOrNull;
      if (provider == null) return;
      final cache = ref.read(providerModelListCacheProvider);
      final notifier = ref.read(promptAssistantConfigProvider.notifier);
      final key = await notifier.getProviderApiKey(id);
      final headers = await notifier.getProviderHeaders(id);
      if (!mounted) return;
      final latestProvider = ref
          .read(promptAssistantConfigProvider)
          .providers
          .where((item) => item.id == id)
          .firstOrNull;
      if (latestProvider == null ||
          _fetchedConnection != _catalogConnection ||
          fingerprint != _catalogFingerprint ||
          fingerprint !=
              ProviderModelListCache.fingerprint(
                latestProvider,
                key,
                headers,
              )) {
        return;
      }
      final saved = await cache.save(id, fingerprint, names);
      if (!saved) _cacheSaveFailed();
    } catch (_) {
      AppLogger.w('Model list cache save failed.', 'PromptAssistant');
      _cacheSaveFailed();
    }
  }

  void _cacheSaveFailed() {
    if (mounted) setState(() => _catalogMessage = '模型列表已获取，但本地缓存保存失败，下次需重新获取。');
  }

  Future<void> _testModel() async {
    if (!_canOperate || !_validate()) return;
    if (_selected.isEmpty) {
      setState(() => _error = '请先选中一个模型。');
      return;
    }
    setState(() {
      _operation = _ServiceOperation.test;
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
      if (mounted) setState(() => _operation = null);
    }
  }

  Future<bool> _save() async {
    if (!_canOperate || !_validate()) {
      return false;
    }
    for (final model in _selected.values) {
      if ((model.contextWindow != null && model.contextWindow! <= 0) ||
          (model.maxOutputTokens != null && model.maxOutputTokens! <= 0)) {
        setState(() => _error = '模型“${model.name}”的 token 数量必须大于 0。');
        return false;
      }
    }
    setState(() => _operation = _ServiceOperation.save);
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
      if (!mounted) return true;
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
      await _persistCatalog();
      if (!mounted) return true;
      widget.onSaved(id);
      return true;
    } catch (error) {
      if (mounted) setState(() => _error = '保存失败：$error');
      return false;
    } finally {
      if (mounted) {
        setState(() => _operation = null);
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
      _catalogFingerprint = null;
      _catalogMessage = null;
      _catalogSearch.clear();
    });
  }

  void _setProtocol(ProviderProtocol protocol) {
    _protocol = protocol;
    _invalidateFetchedCatalog();
    final allowed = protocol.supportedReasoningEfforts;
    for (final entry in _selected.entries.toList()) {
      _selected[entry.key] = _enrich(entry.value).copyWith(
        reasoningEfforts: entry.value.reasoningEfforts
            ?.where(allowed.contains)
            .toList(),
        clearReasoningEffort:
            entry.value.reasoningEffort != null &&
            !allowed.contains(entry.value.reasoningEffort),
      );
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

  void _updateOverview(VoidCallback action) => setState(() {
    action();
    _invalidateFetchedCatalog();
  });

  @override
  Widget build(BuildContext context) {
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
}
