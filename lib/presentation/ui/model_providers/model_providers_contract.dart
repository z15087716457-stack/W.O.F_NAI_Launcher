// 服务商工作台（设置 → 模型与接口 → 服务商）的契约。
//
// 界面只吃这里的数据、只调这里的回调；接线方读现有 PromptAssistant 配置组装
// [ProvidersViewData]，把 [ProvidersActions] 接到现有 controller / service。
// 原型：.devin/mockups/model-providers/mock.html#b（方案 B · 三栏检查器）。
import 'package:flutter/foundation.dart';

import '../settings/settings_contract.dart'
    show SettingsModelTask, SettingsTone;

// ───────────────────────────── 可编辑部分 ─────────────────────────────

/// 一行键值：请求头（值是纯文本）或请求体字段（值是 JSON 文本，例如 `{"type":"json_object"}`、`0.3`、`"x"`）。
@immutable
class ProviderKeyValue {
  const ProviderKeyValue(this.key, this.value);
  final String key;
  final String value;

  @override
  bool operator ==(Object other) =>
      other is ProviderKeyValue && other.key == key && other.value == value;

  @override
  int get hashCode => Object.hash(key, value);

  @override
  String toString() => '$key=$value';
}

/// 模型的可确认能力。界面上是四个开关；未勾选 = 用户未确认支持。
enum ProviderCapability {
  /// 图片输入（反推等功能要把图片发给模型）。对应 `ModelConfig.supportsVision`。
  vision,

  /// 工具调用。对应 `supportsTools`。
  tools,

  /// 原生联网搜索。对应 `supportsNativeSearch`。
  search,
}

/// 一个模型的全部可编辑参数（原来藏在“高级请求参数”里的模型项）。
@immutable
class ProviderModelSettings {
  const ProviderModelSettings({
    required this.id,
    this.alias = '',
    this.contextWindow,
    this.maxOutput,
    this.reasoningLevels,
    this.defaultLevel,
    this.adaptiveReasoning = false,
    this.capabilities = const {},
    this.body = const [],
    this.headers = const [],
  });

  /// 模型 ID（请求里用的名字），也是这一项的主键，不可在界面上改。
  final String id;

  /// 显示别名（`ModelConfig.displayName`）；空 = 显示 ID。
  final String alias;

  /// token 数；null = 未标注。界面不截断输入，只作参考与校验。
  final int? contextWindow;
  final int? maxOutput;

  /// 用户确认可用的思考档位（`ModelConfig.reasoningEfforts`），取值是协议档位 id
  /// （`none` `minimal` `low` `medium` `high` `xhigh` `max`）。null = 未确认；空列表 = 明确不支持。
  final List<String>? reasoningLevels;

  /// 默认思考档位（`ModelConfig.reasoningEffort`）；null = 跟随服务默认。
  final String? defaultLevel;

  /// 思考协议：false = 标准，true = 自适应（`ModelReasoningProtocol.adaptive`）。
  final bool adaptiveReasoning;

  final Set<ProviderCapability> capabilities;

  /// 自定义请求体字段 / 请求头（`ModelRequestOverrides`，存安全存储）。
  final List<ProviderKeyValue> body;
  final List<ProviderKeyValue> headers;

  /// 默认档位必须在可用档位里；不在时界面按“跟随服务”显示。
  String? get effectiveDefault =>
      defaultLevel != null &&
          (reasoningLevels ?? const []).contains(defaultLevel)
      ? defaultLevel
      : null;

  ProviderModelSettings copyWith({
    String? alias,
    int? contextWindow,
    bool clearContextWindow = false,
    int? maxOutput,
    bool clearMaxOutput = false,
    List<String>? reasoningLevels,
    bool clearReasoningLevels = false,
    String? defaultLevel,
    bool clearDefaultLevel = false,
    bool? adaptiveReasoning,
    Set<ProviderCapability>? capabilities,
    List<ProviderKeyValue>? body,
    List<ProviderKeyValue>? headers,
  }) => ProviderModelSettings(
    id: id,
    alias: alias ?? this.alias,
    contextWindow: clearContextWindow
        ? null
        : contextWindow ?? this.contextWindow,
    maxOutput: clearMaxOutput ? null : maxOutput ?? this.maxOutput,
    reasoningLevels: clearReasoningLevels
        ? null
        : reasoningLevels ?? this.reasoningLevels,
    defaultLevel: clearDefaultLevel ? null : defaultLevel ?? this.defaultLevel,
    adaptiveReasoning: adaptiveReasoning ?? this.adaptiveReasoning,
    capabilities: capabilities ?? this.capabilities,
    body: body ?? this.body,
    headers: headers ?? this.headers,
  );

  /// 和 [other] 不同的字段数（未保存条上的“N 项修改”）。
  int differences(ProviderModelSettings other) => [
    alias != other.alias,
    contextWindow != other.contextWindow,
    maxOutput != other.maxOutput,
    !_nullableListEquals(reasoningLevels, other.reasoningLevels),
    defaultLevel != other.defaultLevel,
    adaptiveReasoning != other.adaptiveReasoning,
    !setEquals(capabilities, other.capabilities),
    !listEquals(body, other.body),
    !listEquals(headers, other.headers),
  ].where((x) => x).length;

  /// 三方合并：[edited] 相对 [base] 改过的字段取 [edited]，其余取 [latest]。
  static ProviderModelSettings merge(
    ProviderModelSettings base,
    ProviderModelSettings edited,
    ProviderModelSettings latest,
  ) {
    T pick<T>(T b, T e, T l, [bool Function(T, T)? eq]) =>
        (eq ?? (x, y) => x == y)(b, e) ? l : e;
    return ProviderModelSettings(
      id: latest.id,
      alias: pick(base.alias, edited.alias, latest.alias),
      contextWindow: pick(
        base.contextWindow,
        edited.contextWindow,
        latest.contextWindow,
      ),
      maxOutput: pick(base.maxOutput, edited.maxOutput, latest.maxOutput),
      reasoningLevels: pick(
        base.reasoningLevels,
        edited.reasoningLevels,
        latest.reasoningLevels,
        _nullableListEquals,
      ),
      defaultLevel: pick(
        base.defaultLevel,
        edited.defaultLevel,
        latest.defaultLevel,
      ),
      adaptiveReasoning: pick(
        base.adaptiveReasoning,
        edited.adaptiveReasoning,
        latest.adaptiveReasoning,
      ),
      capabilities: pick(
        base.capabilities,
        edited.capabilities,
        latest.capabilities,
        setEquals,
      ),
      body: pick(base.body, edited.body, latest.body, listEquals),
      headers: pick(base.headers, edited.headers, latest.headers, listEquals),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProviderModelSettings &&
      other.id == id &&
      differences(other) == 0;

  @override
  int get hashCode => Object.hash(
    id,
    alias,
    contextWindow,
    maxOutput,
    reasoningLevels == null ? null : Object.hashAll(reasoningLevels!),
    defaultLevel,
    adaptiveReasoning,
    Object.hashAllUnordered(capabilities),
    Object.hashAll(body),
    Object.hashAll(headers),
  );
}

/// 一个服务商的全部可编辑参数（连接 + 请求 + 模型）。API Key 不在这里，单独走 [ProvidersActions.onSave] 的 `apiKey`。
@immutable
class ProviderSettings {
  const ProviderSettings({
    required this.name,
    required this.baseUrl,
    required this.protocolId,
    this.timeoutSeconds = 120,
    this.maxConcurrency = 5,
    this.retryAttempts = 1,
    this.headers = const [],
    this.models = const [],
  });

  final String name;
  final String baseUrl;

  /// [ProvidersProtocol.id]（`ProviderProtocol.name`）。
  final String protocolId;

  /// 请求超时 10–600 秒（[timeoutRange]）。
  final int timeoutSeconds;

  /// 最大并发 1–20（[concurrencyRange]）。
  final int maxConcurrency;

  /// 失败重试 0–3 次；0 = 关闭。
  final int retryAttempts;

  /// 服务商级自定义请求头（`ProviderConfig.requestHeaders`，存安全存储）。
  final List<ProviderKeyValue> headers;

  /// 已添加的模型，顺序即用户排序（拖动后经 [ProvidersActions.onReorderModels] 落盘）。
  final List<ProviderModelSettings> models;

  static const timeoutRange = (min: 10, max: 600);
  static const concurrencyRange = (min: 1, max: 20);
  static const retryMax = 3;

  ProviderModelSettings? model(String id) =>
      models.where((m) => m.id == id).firstOrNull;

  ProviderSettings copyWith({
    String? name,
    String? baseUrl,
    String? protocolId,
    int? timeoutSeconds,
    int? maxConcurrency,
    int? retryAttempts,
    List<ProviderKeyValue>? headers,
    List<ProviderModelSettings>? models,
  }) => ProviderSettings(
    name: name ?? this.name,
    baseUrl: baseUrl ?? this.baseUrl,
    protocolId: protocolId ?? this.protocolId,
    timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
    maxConcurrency: maxConcurrency ?? this.maxConcurrency,
    retryAttempts: retryAttempts ?? this.retryAttempts,
    headers: headers ?? this.headers,
    models: models ?? this.models,
  );

  ProviderSettings withModel(ProviderModelSettings m) =>
      copyWith(models: [for (final x in models) x.id == m.id ? m : x]);

  /// 和 [other] 不同的字段数（服务商级每项算 1，模型按 [ProviderModelSettings.differences] 累加；
  /// 模型增删、排序不算——它们是即时操作）。
  int differences(ProviderSettings other) {
    var n = [
      name != other.name,
      baseUrl != other.baseUrl,
      protocolId != other.protocolId,
      timeoutSeconds != other.timeoutSeconds,
      maxConcurrency != other.maxConcurrency,
      retryAttempts != other.retryAttempts,
      !listEquals(headers, other.headers),
    ].where((x) => x).length;
    for (final m in models) {
      final o = other.model(m.id);
      if (o != null) n += m.differences(o);
    }
    return n;
  }

  /// 三方合并（界面草稿的显示值）：[edited] 相对 [base] 改过的字段保留，其余跟 [latest] 走。
  /// 模型按 ID 对齐：列表和顺序以 [latest] 为准（别处添加的出现，删除的消失），
  /// 两边都有的模型逐字段合并。
  static ProviderSettings merge(
    ProviderSettings base,
    ProviderSettings edited,
    ProviderSettings latest,
  ) {
    T pick<T>(T b, T e, T l) => b == e ? l : e;
    return ProviderSettings(
      name: pick(base.name, edited.name, latest.name),
      baseUrl: pick(base.baseUrl, edited.baseUrl, latest.baseUrl),
      protocolId: pick(base.protocolId, edited.protocolId, latest.protocolId),
      timeoutSeconds: pick(
        base.timeoutSeconds,
        edited.timeoutSeconds,
        latest.timeoutSeconds,
      ),
      maxConcurrency: pick(
        base.maxConcurrency,
        edited.maxConcurrency,
        latest.maxConcurrency,
      ),
      retryAttempts: pick(
        base.retryAttempts,
        edited.retryAttempts,
        latest.retryAttempts,
      ),
      headers: listEquals(base.headers, edited.headers)
          ? latest.headers
          : edited.headers,
      models: [
        for (final l in latest.models)
          switch ((base.model(l.id), edited.model(l.id))) {
            (final b?, final e?) => ProviderModelSettings.merge(b, e, l),
            _ => l,
          },
      ],
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ProviderSettings &&
      differences(other) == 0 &&
      listEquals(
        [for (final m in models) m.id],
        [for (final m in other.models) m.id],
      );

  @override
  int get hashCode => Object.hash(
    name,
    baseUrl,
    protocolId,
    timeoutSeconds,
    maxConcurrency,
    retryAttempts,
    Object.hashAll(headers),
    Object.hashAll(models),
  );
}

bool _nullableListEquals<T>(List<T>? a, List<T>? b) =>
    a == null || b == null ? a == b : listEquals(a, b);

// ───────────────────────────── 只读事实 ─────────────────────────────

/// 预设所在分组（添加服务商弹窗分组 / 筛选）。现有 `_VendorDefaults.group` 的
/// “国内厂商 / 国际厂商 / 聚合平台 / 本地与自定义”。
enum ProviderGroup { domestic, international, aggregator, local }

/// 一次测试的结果。
@immutable
class ProviderTestResult {
  const ProviderTestResult({
    required this.ok,
    this.latencyMs,
    this.message = '',
    this.at,
  });
  final bool ok;
  final int? latencyMs;

  /// 成功时是模型回复的前几十个字；失败时是一句原因（例如“401 · API Key 无效”）。
  final String message;
  final DateTime? at;
}

/// 模型的只读信息（不进草稿）。
@immutable
class ProviderModelInfo {
  const ProviderModelInfo({
    this.detail = '',
    this.usedFor = const {},
    this.retired = false,
    this.testing = false,
    this.lastTest,
  });

  /// 目录里的显示名，例如 `DeepSeek V4 Pro`；别名为空时作副标题。
  final String detail;

  /// 功能分配里用到它的功能。
  final Set<SettingsModelTask> usedFor;

  /// 服务商已下线（目录 status deprecated / retired）。
  final bool retired;

  /// “测试此模型”进行中。
  final bool testing;
  final ProviderTestResult? lastTest;
}

/// 接口协议选项。
@immutable
class ProvidersProtocol {
  const ProvidersProtocol({
    required this.id,
    required this.label,
    this.reasoningLevels = const [],
  });

  /// `ProviderProtocol.name`。
  final String id;

  /// `ProviderProtocol.label`（专有名词，不翻译）。
  final String label;

  /// 协议支持的全部思考档位（`supportedReasoningEfforts`），按从低到高；空 = 协议不支持思考调节。
  final List<String> reasoningLevels;
}

/// 一个已配置的服务商。
@immutable
class ProviderItem {
  const ProviderItem({
    required this.id,
    required this.settings,
    this.presetId,
    this.group = ProviderGroup.local,
    this.logoAsset,
    this.mark,
    this.color = 0xFF7C5CFF,
    this.enabled = true,
    this.local = false,
    this.apiKeyMasked = '',
    this.status = SettingsTone.idle,
    this.latencyMs,
    this.checkedAt,
    this.error = '',
    this.testing = false,
    this.hint = '',
    this.models = const {},
  });

  final String id;

  /// 已保存的配置（草稿的起点）。
  final ProviderSettings settings;

  /// [ProviderPresetItem.id]；自定义端点为 null。
  final String? presetId;
  final ProviderGroup group;

  /// `assets/icons/providers/<logoAsset>.svg`；null 时画 [mark] 字母块。
  final String? logoAsset;

  /// 自定义端点的 1–2 个字；null 且无 logo 时画通用图标。
  final String? mark;

  /// [mark] 字母块底色（ARGB）。
  final int color;

  /// 启用开关（即时生效，不进草稿）。
  final bool enabled;

  /// 本机服务（Ollama / LM Studio）：Key 可留空。
  final bool local;

  /// 例如 `sk-••••3f9a`；空 = 未填。
  final String apiKeyMasked;

  /// 上次连接测试：ok = 可用，warn = 受限 / 本机服务未启动，error = 失败，idle = 未检测。
  final SettingsTone status;
  final int? latencyMs;
  final DateTime? checkedAt;

  /// [status] 为 warn / error 时的一句原因。
  final String error;

  /// 连接测试进行中。
  final bool testing;

  /// 预设的连接提示（`ProviderPreset.connectionHintIn`，已本地化）；空 = 不显示。
  final String hint;

  /// 按模型 ID 的只读信息；缺的按空信息处理。
  final Map<String, ProviderModelInfo> models;

  ProviderModelInfo info(String modelId) =>
      models[modelId] ?? const ProviderModelInfo();
}

/// 服务商目录（“获取列表”的结果）里的一项。
@immutable
class ProviderCatalogEntry {
  const ProviderCatalogEntry({
    required this.id,
    this.contextWindow,
    this.price,
    this.retired = false,
  });
  final String id;
  final int? contextWindow;

  /// 已格式化的价格，例如 `$3 / $15`（输入 / 输出，每百万 token）；null = 未知。
  final String? price;
  final bool retired;
}

enum ProviderCatalogState { idle, loading, ready, failed }

@immutable
class ProviderCatalog {
  const ProviderCatalog({
    this.state = ProviderCatalogState.idle,
    this.entries = const [],
    this.fetchedAt,
    this.error = '',
  });

  /// idle = 从没获取过（也没有缓存）。有缓存时是 ready + [fetchedAt]。
  final ProviderCatalogState state;
  final List<ProviderCatalogEntry> entries;
  final DateTime? fetchedAt;
  final String error;
}

/// 添加服务商弹窗里的一个预设。
@immutable
class ProviderPresetItem {
  const ProviderPresetItem({
    required this.id,
    required this.name,
    required this.group,
    this.host = '',
    this.logoAsset,
    this.custom = false,
  });

  /// `ProviderPreset.name`。
  final String id;
  final String name;
  final ProviderGroup group;

  /// 预填地址的主机部分，例如 `api.deepseek.com`。
  final String host;
  final String? logoAsset;

  /// 自定义端点（OpenAI 兼容）：卡片画虚线加号。
  final bool custom;
}

@immutable
class ProvidersViewData {
  const ProvidersViewData({
    this.providers = const [],
    this.protocols = const [],
    this.presets = const [],
    this.catalogs = const {},
  });

  /// 已配置的服务商，按配置顺序。
  final List<ProviderItem> providers;
  final List<ProvidersProtocol> protocols;
  final List<ProviderPresetItem> presets;

  /// 按服务商 ID。缺的按 [ProviderCatalogState.idle]。
  final Map<String, ProviderCatalog> catalogs;

  ProvidersProtocol? protocol(String id) =>
      protocols.where((p) => p.id == id).firstOrNull;

  ProviderCatalog catalog(String providerId) =>
      catalogs[providerId] ?? const ProviderCatalog();
}

// ───────────────────────────── 回调 ─────────────────────────────

enum ProvidersSaveResult {
  /// 已写入；Future 完成前应已刷新 [ProviderItem.settings]。
  saved,

  /// 存储里的配置和 `base` 不一致（别处刚改过）：未写入。界面保留草稿并合并最新值，用户确认后再存。
  conflict,

  /// 写入失败或校验不过：界面保留草稿并提示重试。
  failed,
}

/// 草稿外的操作都是即时的；只有 [onSave] 写入草稿。
@immutable
class ProvidersActions {
  const ProvidersActions({
    this.onCreate = _noCreate,
    this.onEnabled = _noBool,
    this.onTest = _noTest,
    this.onTestModel = _noTestModel,
    this.onSave = _noSave,
    this.onRevealApiKey = _noReveal,
    this.onFetchCatalog = _noId,
    this.onAddModels = _noAdd,
    this.onRemoveModel = _noIdId,
    this.onReorderModels = _noOrder,
    this.onDelete = _noId,
  });

  /// 用预设新建一个服务商（地址、协议按预设预填，Key 为空）。返回新服务商 ID，界面选中它并聚焦 Key；null = 取消 / 失败。
  final Future<String?> Function(String presetId) onCreate;

  /// 启用 / 停用（即时）。
  final void Function(String providerId, bool enabled) onEnabled;

  /// 测试连接：用 [edited]（含未保存草稿）和 [apiKey]（null = 用已保存的 Key）发一次请求，
  /// 结果回写 [ProviderItem.status] / [ProviderItem.latencyMs] / [ProviderItem.error]，期间 [ProviderItem.testing]。
  final void Function(
    String providerId,
    ProviderSettings edited,
    String? apiKey,
  )
  onTest;

  /// 测试此模型：用草稿里这个模型的参数（思考档位、温度、请求体）发一句短请求，
  /// 结果回写 [ProviderModelInfo.lastTest]，期间 [ProviderModelInfo.testing]。
  final void Function(
    String providerId,
    String modelId,
    ProviderSettings edited,
    String? apiKey,
  )
  onTestModel;

  /// 保存草稿。[base] 是界面认为的已保存配置（`ProviderItem.settings`），[edited] 是要写入的完整配置；
  /// 存储与 [base] 不一致时返回 [ProvidersSaveResult.conflict] 且不写。
  /// [apiKey]：null = 不改；空串 = 清除；其他 = 新 Key。
  final Future<ProvidersSaveResult> Function({
    required String providerId,
    required ProviderSettings base,
    required ProviderSettings edited,
    String? apiKey,
  })
  onSave;

  /// 点“显示”读出已保存的 Key 明文；null = 不可读 / 用户拒绝。界面只在本次显示，不缓存。
  final Future<String?> Function(String providerId) onRevealApiKey;

  /// 读取 / 刷新服务商目录（用已保存的连接）。结果写进 [ProvidersViewData.catalogs]，期间 loading。
  final ValueChanged<String> onFetchCatalog;

  /// 添加模型（即时）。[manual] = 手动输入的 ID（`ModelSource.manual`），否则来自目录（能力 / 上下文 / 档位按目录预填）。
  final void Function(String providerId, List<String> modelIds, {bool manual})
  onAddModels;

  /// 移除模型（即时，界面已确认）。
  final void Function(String providerId, String modelId) onRemoveModel;

  /// 拖动排序后的新顺序（即时）。
  final void Function(String providerId, List<String> modelIds) onReorderModels;

  /// 删除服务商（即时，界面已确认）。
  final ValueChanged<String> onDelete;

  static Future<String?> _noCreate(String _) async => null;
  static void _noBool(String _, bool _) {}
  static void _noTest(String _, ProviderSettings _, String? _) {}
  static void _noTestModel(String _, String _, ProviderSettings _, String? _) {}
  static Future<ProvidersSaveResult> _noSave({
    required String providerId,
    required ProviderSettings base,
    required ProviderSettings edited,
    String? apiKey,
  }) async => ProvidersSaveResult.saved;
  static Future<String?> _noReveal(String _) async => null;
  static void _noId(String _) {}
  static void _noAdd(String _, List<String> _, {bool manual = false}) {}
  static void _noIdId(String _, String _) {}
  static void _noOrder(String _, List<String> _) {}
}
