import 'package:flutter/foundation.dart';

import '../channel/channel_contract.dart';
import '../model_providers/model_providers_contract.dart';

/// 设置页（新界面）的唯一契约。界面只吃 [SettingsViewData]、只调 [SettingsActions]。
///
/// 两类设置：
/// - **标量设置**（开关、单选、数值、路径、短文本）统一用 [SettingKey] 寻址：值在 [SettingsViewData.values]，
///   改动走 [SettingsActions.onChanged]。界面据此统一画控件、画“已修改”蓝点、做单项恢复默认、搜索结果里直接改。
///   每个键的类型、取值范围、默认值、是否需重启见 [SettingSpec.of]；接线方按键映射到现有 provider。
/// - **集合与状态**（账号、服务商、MCP、来源进度、快捷键……）各页一个数据类，配专门的回调。
///
/// 页面切换由接线方持有（[SettingsViewData.page] + [SettingsActions.onOpenPage]），以便旧的设置深链
/// （例如“打开模型管理”）直接映射到页面；搜索词、模型页选中的服务商、录制中的快捷键、
/// 未保存的 Agent 指令草稿等纯界面状态由界面自己管。

/// 17 个页面；顺序 = 目录顺序。
enum SettingsPageId {
  overview,
  account,
  appearance,
  canvas,
  shortcuts,
  generation,
  storage,
  dictionaries,
  models,
  agent,
  rag,
  upscale,
  bridges,
  network,
  privacy,
  backup,
  about,
}

/// 目录分组。
enum SettingsGroup { none, personal, create, intelligence, connect, system }

extension SettingsPageIdGroup on SettingsPageId {
  SettingsGroup get group => switch (this) {
    SettingsPageId.overview => SettingsGroup.none,
    SettingsPageId.account ||
    SettingsPageId.appearance ||
    SettingsPageId.canvas ||
    SettingsPageId.shortcuts => SettingsGroup.personal,
    SettingsPageId.generation ||
    SettingsPageId.storage ||
    SettingsPageId.dictionaries => SettingsGroup.create,
    SettingsPageId.models ||
    SettingsPageId.agent ||
    SettingsPageId.rag ||
    SettingsPageId.upscale => SettingsGroup.intelligence,
    SettingsPageId.bridges || SettingsPageId.network => SettingsGroup.connect,
    SettingsPageId.privacy ||
    SettingsPageId.backup ||
    SettingsPageId.about => SettingsGroup.system,
  };
}

// ───────────────────────────── 标量设置 ─────────────────────────────

/// 所有标量设置。名字后的注释是现有实现里的大致对应，接线方以源码为准。
enum SettingKey {
  // 外观
  themeMode, // light / dark / system（system 是新增：跟随 Windows）
  fontFamily, // 选项由 [SettingsViewData.options] 给
  settingsFontScale, // 设置页与对话框字号 0.8–1.5
  language, // zh / zh_TW / en / ja / ko
  reduceMotion, // 现有画布“减少动态效果”（也让视觉通道停微动）
  completionSound,
  completionSoundFile, // 路径，null = 内置音效
  // 画布与浏览
  historyClick, // openDetail / linkedPreview
  outputViewer, // canvas / simple
  canvasLockCamera,
  canvasZoomToFill,
  // 快捷键显示
  shortcutsEnabled,
  shortcutsInTooltips,
  shortcutsInMenus,
  navNumberBadges,
  // 生成与额度
  costWarning,
  costThreshold, // Anlas
  intervalLimit,
  intervalSeconds,
  intervalJitter, // 0–50（%）
  wheelWeight,
  wheelModifier, // alt / ctrl / shift / none
  relatedTags,
  // 存储与图库
  imageSavePath,
  autoSave,
  vibePath,
  galleryQuality, // high / standard
  appDataPath, // Hive 目录，改后需重启
  // 词库与缓存
  cacheStatsAutoRefresh,
  // Agent
  agentModel, // 选项由 options 给
  agentEnterToSend,
  agentMaxRequests, // 1–200
  // 语义检索
  ragEnabled,
  ragContext, // beforeCursor / around
  ragDevice, // auto / cuda / cpu
  ragEmbedPath,
  ragRerankPath,
  ragPythonPath, // python.exe；null = 自动安装的独立环境
  // 本地放大
  upscaleDefault, // 新增：工具条“本地放大”的默认方式；选项由 options 给
  seedVramMode, // recommended / low：由 seedCpuOffload 推出（> 0 = low），不单独存
  seedCpuOffload, // 0–32 / 36 层，按当前模型
  seedVaeTiling,
  seedVaeTile, // 512 / 768 / 1024（现有实现允许 128–4096，其他值三档都不选中）
  seedInputNoise, // 0–1
  seedLatentNoise, // 0–1
  // 桥接
  kritaBridge,
  comfyEnabled,
  comfyUrl,
  // 网络
  proxyEnabled,
  proxyMode, // system / manual（system = 现有 ProxyMode.auto）
  proxyHost,
  proxyPort,
  // 隐私与保护
  stripMetadata,
  confirmExternalSend,
  confirmDangerous,
  noOverwrite,
  blacklistAutoSync,
  // 关于
  includePrerelease,
  logToFile,
  // 账号
  defaultAccount, // 选项由 options 给（账号 id）
  autoLogin,
}

enum SettingKind { toggle, choice, number, path, text }

/// 一个标量设置的类型与约束。界面按它画控件、做校验；接线方按它存取。
@immutable
class SettingSpec {
  const SettingSpec._(
    this.kind,
    this.page, {
    this.choices = const [],
    this.min = 0,
    this.max = 0,
    this.step = 1,
    this.defaultValue,
    this.restart = false,
  });

  final SettingKind kind;

  /// 这个设置所在的页面（搜索跳转、“恢复本页默认”用）。
  final SettingsPageId page;

  /// 单选的固定取值；空表示取值由 [SettingsViewData.options] 动态给。
  final List<String> choices;
  final double min;
  final double max;
  final double step;

  /// 默认值：bool / String / double / null（路径为 null 表示“默认位置”）。
  /// 只用于界面兜底显示；是否“已修改”以 [SettingsViewData.modified] 为准。
  final Object? defaultValue;

  /// 改了要重启才生效：行尾显示“需重启”，改动后页顶出重启提示条。
  final bool restart;

  static SettingSpec of(SettingKey key) => _specs[key]!;

  static const _t = SettingKind.toggle;
  static const _c = SettingKind.choice;
  static const _n = SettingKind.number;
  static const _p = SettingKind.path;
  static const _x = SettingKind.text;
  static const _ap = SettingsPageId.appearance;
  static const _cv = SettingsPageId.canvas;
  static const _sc = SettingsPageId.shortcuts;
  static const _ge = SettingsPageId.generation;
  static const _st = SettingsPageId.storage;
  static const _dc = SettingsPageId.dictionaries;
  static const _ag = SettingsPageId.agent;
  static const _rg = SettingsPageId.rag;
  static const _up = SettingsPageId.upscale;
  static const _br = SettingsPageId.bridges;
  static const _nw = SettingsPageId.network;
  static const _pv = SettingsPageId.privacy;
  static const _ab = SettingsPageId.about;
  static const _ac = SettingsPageId.account;

  static const _specs = <SettingKey, SettingSpec>{
    SettingKey.themeMode: SettingSpec._(
      _c,
      _ap,
      choices: ['system', 'light', 'dark'],
      defaultValue: 'system',
    ),
    SettingKey.fontFamily: SettingSpec._(_c, _ap, defaultValue: 'system'),
    SettingKey.settingsFontScale: SettingSpec._(
      _n,
      _ap,
      min: .8,
      max: 1.5,
      step: .1,
      defaultValue: 1.0,
    ),
    SettingKey.language: SettingSpec._(
      _c,
      _ap,
      choices: ['zh', 'zh_TW', 'en', 'ja', 'ko'],
      defaultValue: 'zh',
    ),
    SettingKey.reduceMotion: SettingSpec._(_t, _ap, defaultValue: false),
    SettingKey.completionSound: SettingSpec._(_t, _ap, defaultValue: true),
    SettingKey.completionSoundFile: SettingSpec._(_p, _ap),
    SettingKey.historyClick: SettingSpec._(
      _c,
      _cv,
      choices: ['openDetail', 'linkedPreview'],
      defaultValue: 'openDetail',
    ),
    SettingKey.outputViewer: SettingSpec._(
      _c,
      _cv,
      choices: ['canvas', 'simple'],
      defaultValue: 'canvas',
    ),
    SettingKey.canvasLockCamera: SettingSpec._(_t, _cv, defaultValue: false),
    SettingKey.canvasZoomToFill: SettingSpec._(_t, _cv, defaultValue: false),
    SettingKey.shortcutsEnabled: SettingSpec._(_t, _sc, defaultValue: true),
    SettingKey.shortcutsInTooltips: SettingSpec._(_t, _sc, defaultValue: true),
    SettingKey.shortcutsInMenus: SettingSpec._(_t, _sc, defaultValue: false),
    SettingKey.navNumberBadges: SettingSpec._(_t, _sc, defaultValue: true),
    SettingKey.costWarning: SettingSpec._(_t, _ge, defaultValue: false),
    SettingKey.costThreshold: SettingSpec._(
      _n,
      _ge,
      min: 1,
      max: 9999,
      step: 5,
      defaultValue: 50.0,
    ),
    SettingKey.intervalLimit: SettingSpec._(_t, _ge, defaultValue: false),
    SettingKey.intervalSeconds: SettingSpec._(
      _n,
      _ge,
      min: 1,
      max: 3600,
      defaultValue: 5.0,
    ),
    SettingKey.intervalJitter: SettingSpec._(
      _n,
      _ge,
      max: 50,
      step: 5,
      defaultValue: 0.0,
    ),
    SettingKey.wheelWeight: SettingSpec._(_t, _ge, defaultValue: true),
    SettingKey.wheelModifier: SettingSpec._(
      _c,
      _ge,
      choices: ['alt', 'ctrl', 'shift', 'none'],
      defaultValue: 'alt',
    ),
    SettingKey.relatedTags: SettingSpec._(_t, _ge, defaultValue: true),
    SettingKey.imageSavePath: SettingSpec._(_p, _st),
    SettingKey.autoSave: SettingSpec._(_t, _st, defaultValue: true),
    SettingKey.vibePath: SettingSpec._(_p, _st),
    SettingKey.galleryQuality: SettingSpec._(
      _c,
      _st,
      choices: ['high', 'standard'],
      defaultValue: 'high',
    ),
    SettingKey.appDataPath: SettingSpec._(_p, _st, restart: true),
    SettingKey.cacheStatsAutoRefresh: SettingSpec._(
      _t,
      _dc,
      defaultValue: true,
    ),
    SettingKey.agentModel: SettingSpec._(_c, _ag),
    SettingKey.agentEnterToSend: SettingSpec._(_t, _ag, defaultValue: true),
    SettingKey.agentMaxRequests: SettingSpec._(
      _n,
      _ag,
      min: 1,
      max: 200,
      defaultValue: 32.0,
    ),
    SettingKey.ragEnabled: SettingSpec._(_t, _rg, defaultValue: false),
    SettingKey.ragContext: SettingSpec._(
      _c,
      _rg,
      choices: ['beforeCursor', 'around'],
      defaultValue: 'around',
    ),
    SettingKey.ragDevice: SettingSpec._(
      _c,
      _rg,
      choices: ['auto', 'cuda', 'cpu'],
      defaultValue: 'auto',
    ),
    SettingKey.ragEmbedPath: SettingSpec._(_p, _rg),
    SettingKey.ragRerankPath: SettingSpec._(_p, _rg),
    SettingKey.ragPythonPath: SettingSpec._(_p, _rg),
    SettingKey.upscaleDefault: SettingSpec._(_c, _up),
    SettingKey.seedVramMode: SettingSpec._(
      _c,
      _up,
      choices: ['recommended', 'low'],
      defaultValue: 'recommended',
    ),
    SettingKey.seedCpuOffload: SettingSpec._(
      _n,
      _up,
      max: 36,
      defaultValue: 0.0,
    ),
    SettingKey.seedVaeTiling: SettingSpec._(_t, _up, defaultValue: true),
    SettingKey.seedVaeTile: SettingSpec._(
      _c,
      _up,
      choices: ['512', '768', '1024'],
      defaultValue: '1024',
    ),
    SettingKey.seedInputNoise: SettingSpec._(
      _n,
      _up,
      max: 1,
      step: .05,
      defaultValue: 0.0,
    ),
    SettingKey.seedLatentNoise: SettingSpec._(
      _n,
      _up,
      max: 1,
      step: .05,
      defaultValue: 0.0,
    ),
    SettingKey.kritaBridge: SettingSpec._(_t, _br, defaultValue: false),
    SettingKey.comfyEnabled: SettingSpec._(_t, _br, defaultValue: false),
    SettingKey.comfyUrl: SettingSpec._(
      _x,
      _br,
      defaultValue: 'http://127.0.0.1:8188',
    ),
    SettingKey.proxyEnabled: SettingSpec._(
      _t,
      _nw,
      defaultValue: true,
      restart: true,
    ),
    SettingKey.proxyMode: SettingSpec._(
      _c,
      _nw,
      choices: ['system', 'manual'],
      defaultValue: 'system',
      restart: true,
    ),
    SettingKey.proxyHost: SettingSpec._(_x, _nw, restart: true),
    SettingKey.proxyPort: SettingSpec._(_x, _nw, restart: true),
    SettingKey.stripMetadata: SettingSpec._(_t, _pv, defaultValue: false),
    SettingKey.confirmExternalSend: SettingSpec._(_t, _pv, defaultValue: true),
    SettingKey.confirmDangerous: SettingSpec._(_t, _pv, defaultValue: true),
    SettingKey.noOverwrite: SettingSpec._(_t, _pv, defaultValue: true),
    SettingKey.blacklistAutoSync: SettingSpec._(_t, _pv, defaultValue: true),
    SettingKey.includePrerelease: SettingSpec._(_t, _ab, defaultValue: false),
    SettingKey.logToFile: SettingSpec._(_t, _ab, defaultValue: false),
    SettingKey.defaultAccount: SettingSpec._(_c, _ac),
    SettingKey.autoLogin: SettingSpec._(_t, _ac, defaultValue: true),
  };
}

/// 动态选项（字体、Agent 模型、默认放大方式、默认账号）。
@immutable
class SettingsOption {
  const SettingsOption({
    required this.value,
    required this.label,
    this.detail,
    this.mark,
    this.color,
  });
  final String value;
  final String label;

  /// 弱色补充，例如服务商名、显存要求。
  final String? detail;

  /// 服务商小图标（Agent 模型下拉框里显示）：1–2 个字母 + 底色（ARGB）。
  final String? mark;
  final int? color;
}

/// 标量设置的当前值：bool / String / double / null（路径为 null = 默认位置）。
@immutable
class SettingsValues {
  const SettingsValues(this._map);
  final Map<SettingKey, Object?> _map;

  Object? operator [](SettingKey key) =>
      _map.containsKey(key) ? _map[key] : SettingSpec.of(key).defaultValue;

  bool flag(SettingKey key) => this[key] == true;
  String? text(SettingKey key) => this[key] as String?;
  double number(SettingKey key) => (this[key] as num?)?.toDouble() ?? 0;

  SettingsValues copyWith(SettingKey key, Object? value) =>
      SettingsValues({..._map, key: value});
}

/// 最近一次或历史上的一次修改（自动保存后底部出“已保存 · 撤销”；概览列出最近几条）。
@immutable
class SettingsChange {
  const SettingsChange({
    required this.id,
    required this.title,
    required this.from,
    required this.to,
    required this.at,
    this.undoable = true,
  });

  /// 每次修改唯一；界面在 id 变化时弹一次底部提示。
  final String id;

  /// 已本地化的设置名（例如“高消耗提醒阈值”），接线方按键查界面同名文案或自己拼。
  final String title;
  final String from;
  final String to;
  final DateTime at;
  final bool undoable;
}

// ───────────────────────────── 视图数据 ─────────────────────────────

@immutable
class SettingsViewData {
  const SettingsViewData({
    required this.page,
    required this.values,
    required this.now,
    required this.version,
    this.modified = const {},
    this.options = const {},
    this.lastChange,
    this.recent = const [],
    this.restartPending = false,
    this.attention = const [],
    required this.account,
    required this.canvas,
    required this.shortcuts,
    required this.generation,
    required this.storage,
    required this.dictionaries,
    required this.models,
    required this.agent,
    required this.rag,
    required this.upscale,
    required this.bridges,
    required this.network,
    required this.privacy,
    required this.backup,
    required this.about,
  });

  final SettingsPageId page;
  final SettingsValues values;

  /// 和默认值不同的标量设置：标题前画蓝点，悬停出“恢复默认”。
  final Set<SettingKey> modified;
  final Map<SettingKey, List<SettingsOption>> options;

  /// 用来算“3 分钟前”这类相对时间；测试里固定。
  final DateTime now;

  /// 例如 `2.0 Preview r8`，目录底部显示。
  final String version;

  /// 最近一次自动保存的修改；id 变化时底部弹“已保存 · 撤销”约 4 秒。
  final SettingsChange? lastChange;

  /// 概览“最近修改”，新的在前，最多显示 5 条。
  final List<SettingsChange> recent;

  /// 有需重启的修改还没生效：页顶出“立即重启 / 稍后”提示条（只在相关页显示）。
  final bool restartPending;

  /// 概览“需要处理”，按重要程度排好。
  final List<SettingsAttention> attention;

  final SettingsAccountData account;
  final SettingsCanvasData canvas;
  final SettingsShortcutsData shortcuts;
  final SettingsGenerationData generation;
  final SettingsStorageData storage;
  final SettingsDictionaryData dictionaries;
  final SettingsModelsData models;
  final SettingsAgentData agent;
  final SettingsRagData rag;
  final SettingsUpscaleData upscale;
  final SettingsBridgesData bridges;
  final SettingsNetworkData network;
  final SettingsPrivacyData privacy;
  final SettingsBackupData backup;
  final SettingsAboutData about;

  /// Model-specific bounds apply both on the page and in editable search hits.
  double numberMax(SettingKey key) => key == SettingKey.seedCpuOffload
      ? upscale.seedOffloadMaxBlocks.toDouble()
      : SettingSpec.of(key).max;

  SettingsViewData copyWith({
    SettingsPageId? page,
    SettingsValues? values,
    Set<SettingKey>? modified,
    SettingsChange? lastChange,
    List<SettingsChange>? recent,
    bool? restartPending,
    SettingsCanvasData? canvas,
    SettingsShortcutsData? shortcuts,
    SettingsPrivacyData? privacy,
    SettingsModelsData? models,
    SettingsAgentData? agent,
    SettingsAccountData? account,
    SettingsRagData? rag,
    SettingsUpscaleData? upscale,
    SettingsDictionaryData? dictionaries,
  }) => SettingsViewData(
    page: page ?? this.page,
    values: values ?? this.values,
    now: now,
    version: version,
    modified: modified ?? this.modified,
    options: options,
    lastChange: lastChange ?? this.lastChange,
    recent: recent ?? this.recent,
    restartPending: restartPending ?? this.restartPending,
    attention: attention,
    account: account ?? this.account,
    canvas: canvas ?? this.canvas,
    shortcuts: shortcuts ?? this.shortcuts,
    generation: generation,
    storage: storage,
    dictionaries: dictionaries ?? this.dictionaries,
    models: models ?? this.models,
    agent: agent ?? this.agent,
    rag: rag ?? this.rag,
    upscale: upscale ?? this.upscale,
    bridges: bridges,
    network: network,
    privacy: privacy ?? this.privacy,
    backup: backup,
    about: about,
  );
}

/// 概览“需要处理”的一条。文案由界面按 [kind] 和参数拼，接线方只给事实。
enum SettingsAttentionKind {
  /// [subject] = 新版本号，[detail] = 一句更新要点，[bytes] = 安装包大小。
  update,

  /// 语义检索某来源暂停：[subject] = 来源（[SettingsRagSourceKind.name]），[done]/[total]。
  ragPaused,

  /// 桥接无响应：[subject] = 'comfyui' / 'krita'，[detail] = 地址，[at] = 检测时间。
  bridgeDown,

  /// 账号凭据过期：[subject] = 账号名。
  credentialExpired,

  /// 磁盘空间不足：[subject] = 盘符，[bytes] = 剩余。
  diskLow,

  /// 模型服务连不上：[subject] = 服务商名。
  providerDown,
}

enum SettingsTone { ok, warn, error, idle }

@immutable
class SettingsAttention {
  const SettingsAttention({
    required this.kind,
    required this.tone,
    this.subject = '',
    this.detail = '',
    this.done = 0,
    this.total = 0,
    this.bytes = 0,
    this.at,
  });

  final SettingsAttentionKind kind;
  final SettingsTone tone;
  final String subject;
  final String detail;
  final int done;
  final int total;
  final int bytes;
  final DateTime? at;
}

// ── 账号

enum SettingsTier { none, tablet, scroll, opus }

enum SettingsLoginKind { email, token }

@immutable
class SettingsAccount {
  const SettingsAccount({
    required this.id,
    required this.name,
    required this.tier,
    required this.anlas,
    required this.loginKind,
    required this.maskedId,
    this.renewsAt,
    this.lastUsedAt,
    this.current = false,
    this.isDefault = false,
    this.expired = false,
    this.color,
  });

  final String id;
  final String name;

  /// null = 还没读取到（非当前账号不会为此自动登录查询），界面显示“未读取”；
  /// [SettingsTier.none] 才是确实没有订阅。
  final SettingsTier? tier;

  /// null = 还没读取到，界面显示“未读取”；0 是真实余额。
  final int? anlas;
  final SettingsLoginKind loginKind;

  /// 脱敏后的邮箱或令牌前缀，例如 `pelican@****.com`、`pst-****a91f`。
  final String maskedId;
  final DateTime? renewsAt;
  final DateTime? lastUsedAt;
  final bool current;
  final bool isDefault;

  /// 凭据过期：显示“更新凭据”。
  final bool expired;

  /// 头像底色（ARGB）；null 用品牌蓝。
  final int? color;
}

@immutable
class SettingsAccountData {
  const SettingsAccountData({
    this.accounts = const [],
    this.monthlyAnlas = 0,
    this.todayUsed = 0,
  });

  final List<SettingsAccount> accounts;

  /// 当前订阅每月固定额度（Opus 10000）。
  final int monthlyAnlas;

  /// 今天已用（统计数据），概览和生成页侧注显示。
  final int todayUsed;

  SettingsAccount? get current {
    for (final a in accounts) {
      if (a.current) return a;
    }
    return null;
  }
}

// ── 画布

@immutable
class SettingsCanvasData {
  const SettingsCanvasData({required this.channel});

  /// 视觉通道设置，与生图页画布齿轮里的同一份（见 `channel_contract.dart`）。
  final ChannelSettings channel;
}

// ── 快捷键

@immutable
class SettingsShortcutContext {
  const SettingsShortcutContext({required this.id, required this.label});

  /// 现有快捷键系统的上下文 id（global、generation、gallery、viewer、vibe、input、settings……）。
  final String id;

  /// 已本地化的名字（现有 ARB 里有）。
  final String label;
}

@immutable
class SettingsShortcut {
  const SettingsShortcut({
    required this.id,
    required this.context,
    required this.label,
    required this.keys,
    required this.defaultKeys,
    this.conflictWith,
  });

  final String id;

  /// [SettingsShortcutContext.id]。
  final String context;

  /// 已本地化的动作名。
  final String label;

  /// 当前组合，例如 `['Ctrl', 'Enter']`；空 = 未设置。修饰键在前，按 Ctrl、Shift、Alt 的顺序。
  final List<String> keys;
  final List<String> defaultKeys;

  /// 同一上下文里和它冲突的另一个动作 id（接线方算好）。
  final String? conflictWith;

  bool get changed => !listEquals(keys, defaultKeys);
}

@immutable
class SettingsShortcutsData {
  const SettingsShortcutsData({
    this.contexts = const [],
    this.shortcuts = const [],
  });

  final List<SettingsShortcutContext> contexts;
  final List<SettingsShortcut> shortcuts;
}

// ── 生成与额度

@immutable
class SettingsCostEstimate {
  const SettingsCostEstimate({
    required this.model,
    required this.width,
    required this.height,
    required this.steps,
    required this.images,
    required this.cost,
  });

  /// 模型简称，例如 `V4.5`。
  final String model;
  final int width;
  final int height;
  final int steps;

  /// 每次请求的张数。
  final int images;

  /// 这一次实际要扣的 Anlas（已考虑 Opus 免费规则），走现有计费 provider。
  final int cost;
}

@immutable
class SettingsGenerationData {
  const SettingsGenerationData({
    this.estimate,
    this.hourlyUsage = const [],
    this.warningsToday = 0,
    this.maxSingleToday = 0,
    this.translationModel,
    this.ragTagsReady = false,
  });

  /// 按当前生图参数估算一次的消耗；null = 拿不到（不显示那一行）。
  final SettingsCostEstimate? estimate;

  /// 今天每小时的 Anlas 消耗（从 0 点或第一次使用起，最多 24 个）。
  final List<int> hourlyUsage;
  final int warningsToday;
  final int maxSingleToday;

  /// 提示词翻译当前用的模型显示名；null = 未配置。
  final String? translationModel;
  final bool ragTagsReady;
}

// ── 存储与图库

enum SettingsStorageKind {
  images,
  upscaleModels,
  vibes,
  thumbnails,
  ragIndex,
  dictionaries,
  agent,
}

@immutable
class SettingsStorageSlice {
  const SettingsStorageSlice(this.kind, this.bytes);
  final SettingsStorageKind kind;
  final int bytes;
}

@immutable
class SettingsGalleryRoot {
  const SettingsGalleryRoot({
    required this.id,
    required this.path,
    required this.images,
    this.primary = false,
  });

  final String id;
  final String path;
  final int images;

  /// 主目录（= 图片保存位置）不能移除。
  final bool primary;
}

/// “打开文件夹”侧注里的几个目录。
enum SettingsFolder { images, vibes, thumbnails, appData, logs, agent }

@immutable
class SettingsStorageData {
  const SettingsStorageData({
    this.slices = const [],
    this.diskLabel = '',
    this.diskFree,
    this.computing = false,
    this.roots = const [],
    this.imageCount = 0,
    this.lastScanAt,
    this.scanning = false,
    this.thumbnailBytes = 0,
    this.thumbnailLimit = 0,
    this.folderNames = const {},
  });

  /// 占用分类（新增：后台统计各目录大小，可缓存）；空 = 还没统计。
  final List<SettingsStorageSlice> slices;

  /// 图片保存位置所在盘，例如 `E:`。
  final String diskLabel;
  final int? diskFree;
  final bool computing;
  final List<SettingsGalleryRoot> roots;
  final int imageCount;
  final DateTime? lastScanAt;
  final bool scanning;
  final int thumbnailBytes;
  final int thumbnailLimit;

  /// 侧注里每个目录的末级名（`outputs`、`vibes`……）。
  final Map<SettingsFolder, String> folderNames;

  int get totalBytes => slices.fold(0, (s, e) => s + e.bytes);
}

// ── 词库与缓存

enum SettingsCacheKind { danbooru, translation }

@immutable
class SettingsCacheStat {
  const SettingsCacheStat({
    required this.hitRate,
    required this.entries,
    this.images = false,
  });

  /// 0–1；null 表示该层没有独立命中率计量。
  final double? hitRate;
  final int entries;

  /// 计数单位是图片（L3）而不是条目。
  final bool images;
}

@immutable
class SettingsDictionaryData {
  const SettingsDictionaryData({
    this.tagCount = 0,
    this.dataVersion = '',
    this.wikiCount,
    this.update,
    this.cooccurrence = 0,
    this.translationModel,
    this.caches = const {},
    this.l1,
    this.l2,
    this.l3,
    this.statsUpdatedAt,
  });

  final int tagCount;
  final String dataVersion;
  final int? wikiCount;
  final SettingsDictionaryUpdate? update;
  final int cooccurrence;
  final String? translationModel;

  /// 每种缓存的（条目数, 字节）。
  final Map<SettingsCacheKind, (int, int)> caches;
  final SettingsCacheStat? l1;
  final SettingsCacheStat? l2;
  final SettingsCacheStat? l3;
  final DateTime? statsUpdatedAt;
}

enum SettingsDictionaryKind { tags, wiki }

enum SettingsDictionaryPhase {
  idle,
  downloading,
  verifying,
  importing,
  publishing,
  done,
  cancelled,
  failed,
}

@immutable
class SettingsDictionaryUpdate {
  const SettingsDictionaryUpdate({
    this.kind,
    this.phase = SettingsDictionaryPhase.idle,
    this.received = 0,
    this.total = 0,
    this.rows = 0,
    this.added = 0,
    this.updated = 0,
    this.cancelling = false,
    this.tagInstalled = false,
    this.wikiInstalled = false,
    this.tagDate = '',
    this.wikiDate = '',
    this.tagSource = '',
    this.wikiSource = '',
    this.tagBytes = 5602650,
    this.wikiBytes = 137932215,
    this.checking = false,
    this.checkFailed = false,
    this.checkedAt,
    this.wikiNeedsRefresh = false,
    this.tagInstalledDate = '',
    this.wikiInstalledDate = '',
  });
  final SettingsDictionaryKind? kind;
  final SettingsDictionaryPhase phase;
  final int received, total, rows, added, updated, tagBytes, wikiBytes;
  final bool cancelling, tagInstalled, wikiInstalled;
  final bool checking, checkFailed, wikiNeedsRefresh;
  final DateTime? checkedAt;
  final String tagDate, wikiDate, tagSource, wikiSource;
  final String tagInstalledDate, wikiInstalledDate;
  bool get busy => const {
    SettingsDictionaryPhase.downloading,
    SettingsDictionaryPhase.verifying,
    SettingsDictionaryPhase.importing,
    SettingsDictionaryPhase.publishing,
  }.contains(phase);
}

// ── 模型与接口

enum SettingsModelCapability { tools, vision, reasoning }

/// 用到模型的四个功能。
enum SettingsModelTask {
  promptTranslate,
  promptReverse,
  tagTranslate,
  wikiTranslate,
}

@immutable
class SettingsModel {
  const SettingsModel({
    required this.id,
    this.detail = '',
    this.capabilities = const {},
    this.usedFor = const {},
    this.retired = false,
    this.reasoningEfforts,
    this.defaultReasoningEffort,
  });

  /// 模型 id，例如 `deepseek-chat`。
  final String id;

  /// 例如 `V3 · 64K`。
  final String detail;
  final Set<SettingsModelCapability> capabilities;
  final Set<SettingsModelTask> usedFor;

  /// 服务商已下线。
  final bool retired;

  /// null = 档位未知；空列表 = 不支持调节。只展示模型实际登记的档位。
  final List<String>? reasoningEfforts;
  final String? defaultReasoningEffort;
}

@immutable
class SettingsProvider {
  const SettingsProvider({
    required this.id,
    required this.name,
    required this.protocol,
    required this.mark,
    required this.color,
    this.logoAsset,
    this.enabled = true,
    this.local = false,
    this.baseUrl = '',
    this.apiKeyMasked = '',
    this.status = SettingsTone.idle,
    this.latencyMs,
    this.checkedAt,
    this.testing = false,
    this.models = const [],
  });

  final String id;
  final String name;

  /// 已本地化的协议说明，例如“OpenAI Chat Completions 兼容”。
  final String protocol;

  /// 自定义端点的 1–2 个字母；已知厂商为 null。
  final String? mark;

  /// 随包厂商 SVG 的资源名；缺少品牌资源时显示通用服务图标。
  final String? logoAsset;

  /// 图标底色（ARGB）。
  final int color;
  final bool enabled;

  /// 本机服务（Ollama）。
  final bool local;
  final String baseUrl;

  /// 例如 `sk-••••3f9a`；空 = 未填。
  final String apiKeyMasked;
  final SettingsTone status;
  final int? latencyMs;
  final DateTime? checkedAt;
  final bool testing;
  final List<SettingsModel> models;
}

@immutable
class SettingsTaskAssignment {
  const SettingsTaskAssignment({
    required this.task,
    this.providerId,
    this.modelId,
    this.presetId,
    this.fallback = false,
    this.reasoningEffort,
  });

  final SettingsModelTask task;
  final String? providerId;
  final String? modelId;
  final String? presetId;

  /// 没选模型，实际回落到第一个可用服务商。
  final bool fallback;

  /// null = 跟随模型默认；具体档位仅覆盖本功能。
  final String? reasoningEffort;
}

@immutable
class SettingsPreset {
  const SettingsPreset({
    required this.id,
    required this.name,
    required this.task,
    this.builtin = false,
  });

  final String id;
  final String name;
  final SettingsModelTask task;
  final bool builtin;
}

@immutable
class SettingsRequestLog {
  const SettingsRequestLog({
    this.id,
    required this.at,
    required this.task,
    required this.provider,
    required this.model,
    required this.ok,
    this.latencyMs,
    this.tokens,
  });

  /// Stable history identity; null for summaries without an inspectable record.
  final String? id;
  final DateTime at;
  final SettingsModelTask task;
  final String provider;
  final String model;
  final bool ok;
  final int? latencyMs;
  final int? tokens;
}

@immutable
class SettingsModelsData {
  const SettingsModelsData({
    this.providers = const [],
    this.assignments = const [],
    this.presets = const [],
    this.requests = const [],
    this.requestTotal = 0,
    this.workbench,
  });

  final List<SettingsProvider> providers;

  /// 新服务商工作台（`ui/model_providers/`）。非 null 时“服务商”标签显示新界面，
  /// 回调走 [SettingsActions.providers]；null 时仍显示旧列表（接线切换前的兼容）。
  final ProvidersViewData? workbench;
  final List<SettingsTaskAssignment> assignments;
  final List<SettingsPreset> presets;

  /// 最近的请求记录（新的在前，界面最多显示 50 条）。
  final List<SettingsRequestLog> requests;
  final int requestTotal;
}

// ── NAI Agent

enum SettingsMcpMode { codemode, deferred, direct, hidden }

/// [unchecked] = 已启用但还没连过（Agent 未启动等），灰点“未检测”；不要为渲染设置去启动 Agent / MCP。
enum SettingsMcpState {
  connected,
  connecting,
  needsLogin,
  error,
  disabled,
  unchecked,
}

@immutable
class SettingsMcpServer {
  const SettingsMcpServer({
    required this.id,
    required this.name,
    required this.transport,
    required this.state,
    required this.mode,
    this.tools = 0,
    this.enabled = true,
    this.builtin = false,
  });

  final String id;
  final String name;

  /// 例如 `stdio · npx @modelcontextprotocol/server-filesystem`。
  final String transport;
  final SettingsMcpState state;
  final SettingsMcpMode mode;
  final int tools;
  final bool enabled;

  /// NAI Studio 内置工具组：不能删，只能开关和换模式。
  final bool builtin;
}

@immutable
class SettingsExtension {
  const SettingsExtension({
    required this.id,
    required this.name,
    this.path = '',
    this.builtin = false,
    this.enabled = true,
  });

  final String id;
  final String name;
  final String path;
  final bool builtin;
  final bool enabled;
}

enum SettingsSkillSource { builtin, global, workspace }

/// [active] 生效；[shadowed] 被更高优先级的同名 Skill 替代；[disabled] 用户关掉；[error] 读不进来。
enum SettingsSkillState { active, shadowed, disabled, error }

/// [description] 缺描述；[name] 名称不合规或与文件夹名不一致；[missing] 文件夹里没有 SKILL.md；[parse] 头部无法解析。
enum SettingsSkillError { description, name, missing, parse }

@immutable
class SettingsSkill {
  const SettingsSkill({
    required this.id,
    required this.name,
    required this.source,
    this.description = '',
    this.path = '',
    this.state = SettingsSkillState.active,
    this.enabled = true,
    this.manual = false,
    this.error,
  });

  /// `<source>/<name>`，回调都用它。
  final String id;
  final String name;
  final SettingsSkillSource source;
  final String description;

  /// SKILL.md 所在文件夹。
  final String path;
  final SettingsSkillState state;
  final bool enabled;

  /// 仅手动：不进提示词目录，只能 `/skill:名称` 调用。
  final bool manual;
  final SettingsSkillError? error;
  bool get builtin => source == SettingsSkillSource.builtin;
}

/// 常驻上下文的估算（字符 / 4）；null = 还没算出来，不显示这一块。
@immutable
class SettingsAgentContext {
  const SettingsAgentContext({
    required this.promptTokens,
    required this.skillTokens,
    required this.skillCount,
    required this.toolTokens,
    required this.toolCount,
  });
  final int promptTokens, skillTokens, skillCount, toolTokens, toolCount;
}

enum SettingsPromptScope { global, workspace }

/// 基础提示词（旧设置“内置提示词”里可编辑的那层，拼在系统前缀之后、全局指令之前）。
/// 全局和当前工作区分开存，互不混写；也不和 [SettingsAgentData.globalInstructions] /
/// [SettingsAgentData.systemPrefix] 混写。
@immutable
class SettingsSystemPrompt {
  const SettingsSystemPrompt({
    required this.builtin,
    this.global,
    this.workspaceId = '',
    this.workspaceName = '',
    this.workspace,
    this.saving = false,
  });

  /// 内置默认提示词（`naiAgentDefaultSystemPrompt`）。全局没自定义时显示它，也是编辑起点。
  final String builtin;

  /// 全局自定义（`AgentSettings.customSystemPrompt`）；null = 用内置。
  final String? global;

  /// 当前工作区（`AgentWorkspace.id` / `name`）；id 为空 = 没有工作区，只出“全局”。
  final String workspaceId;
  final String workspaceName;

  /// 当前工作区单独的提示词（`AgentWorkspace.customSystemPrompt`）；null = 沿用全局。
  final String? workspace;

  /// 保存中：保存、范围切换和“恢复内置”都不可点。
  final bool saving;

  /// 全局实际生效的基础提示词。
  String get effectiveGlobal => global ?? builtin;
}

@immutable
class SettingsAgentData {
  const SettingsAgentData({
    this.globalInstructions = '',
    this.workspaceRulesPath,
    this.systemPrefix = '',
    this.systemPrompt,
    this.extensions = const [],
    this.skills = const [],
    this.skillFolders = const [],
    this.context,
    this.mcp = const [],
    this.tools = const [],
    this.dataPath = '',
    this.workspaces = 0,
    this.sessions = 0,
  });

  /// 已保存的内容；界面里编辑的是草稿，点“保存”才回调。
  final String globalInstructions;
  final String? workspaceRulesPath;
  final String systemPrefix;

  /// 基础提示词编辑；null = 不显示这一行（Agent 未初始化时）。
  final SettingsSystemPrompt? systemPrompt;
  final List<SettingsExtension> extensions;

  /// 内置在前，再按全局、工作区排；同名的每个副本都单独一行。
  final List<SettingsSkill> skills;

  /// (来源, 文件夹路径)：全局一定有，工作区在有当前工作区时出现。
  final List<(SettingsSkillSource, String)> skillFolders;
  final SettingsAgentContext? context;
  final List<SettingsMcpServer> mcp;

  /// Agent 可用的工具名（只读展示）。
  final List<String> tools;
  final String dataPath;
  final int workspaces;
  final int sessions;

  SettingsAgentData copyWith({
    String? globalInstructions,
    String? systemPrefix,
    SettingsSystemPrompt? systemPrompt,
  }) => SettingsAgentData(
    globalInstructions: globalInstructions ?? this.globalInstructions,
    systemPrefix: systemPrefix ?? this.systemPrefix,
    workspaceRulesPath: workspaceRulesPath,
    systemPrompt: systemPrompt ?? this.systemPrompt,
    extensions: extensions,
    skills: skills,
    skillFolders: skillFolders,
    context: context,
    mcp: mcp,
    tools: tools,
    dataPath: dataPath,
    workspaces: workspaces,
    sessions: sessions,
  );
}

// ── 语义检索

enum SettingsRagSourceKind { tags, wiki, blocks, gallery }

/// [empty] = 还没建过库（出“建立索引”）；[ready] 且 done < total = 部分完成（出“继续建立”）。
enum SettingsRagState { empty, ready, building, paused, error, off, loading }

@immutable
class SettingsRagSource {
  const SettingsRagSource({
    required this.kind,
    required this.state,
    this.enabled = true,
    this.done = 0,
    this.total = 0,
    this.secondary,
    this.known = true,
    this.skipped = 0,
    this.error,
  });

  final SettingsRagSourceKind kind;
  final SettingsRagState state;

  /// False until the worker has returned an authoritative index status.
  final bool known;
  final bool enabled;
  final int done;
  final int total;

  /// 图库来源的第二个计数：参数文字索引段数。
  final int? secondary;

  /// 图库来源跳过的图片数（读不出来、格式不支持）。
  final int skipped;

  /// 这个来源最近一次失败的原因（原样显示，一行）。
  final String? error;

  double get fraction => total == 0 ? 0 : done / total;
}

/// 两个模型权重（下载 / 选目录）。
enum SettingsRagModel { embedder, reranker }

/// 模型下载进度（同一时间只下一个）。
@immutable
class SettingsRagDownload {
  const SettingsRagDownload({
    required this.model,
    this.received = 0,
    this.total = 0,
    this.verifying = false,
  });

  final SettingsRagModel model;
  final int received;

  /// 0 = 大小未知（进度条走不定态）。
  final int total;

  /// 下载完在校验文件。
  final bool verifying;
}

/// 安装运行环境的阶段（对应现有 `installPhase`）。
enum SettingsRagInstallPhase {
  existing,
  download,
  create,
  cuda,
  packages,
  check,
}

@immutable
class SettingsRagInstall {
  const SettingsRagInstall({
    required this.phase,
    this.elapsed = Duration.zero,
    this.detail = '',
  });

  final SettingsRagInstallPhase phase;

  /// 当前阶段已用时间。
  final Duration elapsed;

  /// 安装器最后一行输出（等宽弱色显示，最多两行）。
  final String detail;
}

/// 建库计划：点“建立索引 / 重建”后由接线方先统计，界面在来源下方原地确认。
@immutable
class SettingsRagPlan {
  const SettingsRagPlan({
    required this.kind,
    this.rebuild = false,
    this.loading = false,
    this.total = 0,
    this.documents = 0,
    this.images = 0,
    this.roots = const [],
  });

  final SettingsRagSourceKind kind;
  final bool rebuild;

  /// 还在统计（显示“正在统计…”，“开始”不可点）。
  final bool loading;

  /// 标签：标签数；Wiki / 块：文字片段数；图库：参数片段数。
  final int total;

  /// Wiki / 块：资料份数。
  final int documents;

  /// 图库：图片张数。
  final int images;

  /// 图库：要收录的图库目录。
  final List<String> roots;
}

@immutable
class SettingsRagStep {
  const SettingsRagStep({
    required this.value,
    this.detail = '',
    this.tone = SettingsTone.ok,
  });

  /// 例如 `CUDA 12.4`、`EmbeddingGemma 2`。
  final String value;
  final String detail;
  final SettingsTone tone;
}

@immutable
class SettingsRagData {
  const SettingsRagData({
    this.runtime = const SettingsRagStep(value: ''),
    this.embedder = const SettingsRagStep(value: ''),
    this.reranker = const SettingsRagStep(value: ''),
    this.device = const SettingsRagStep(value: ''),
    this.sources = const [],
    this.indexBytes = 0,
    this.checking = false,
    this.runtimeReady = false,
    this.runtimeCuda = false,
    this.runtimePython = '',
    this.pythonPending = false,
    this.install,
    this.download,
    this.modelsMissing = false,
    this.plan,
    this.preparing,
    this.initializing = false,
    this.initializationPhase = '',
    this.initializationProcessed = 0,
    this.initializationTotal = 0,
    this.error,
  });

  final SettingsRagStep runtime;
  final SettingsRagStep embedder;
  final SettingsRagStep reranker;
  final SettingsRagStep device;
  final List<SettingsRagSource> sources;
  final int indexBytes;

  /// 正在检测运行环境。
  final bool checking;

  /// 运行环境可用（false = 显示“安装”）。
  final bool runtimeReady;

  /// 当前环境是 CUDA 版（“使用此解释器”重装时沿用）。
  final bool runtimeCuda;

  /// 当前环境实际用的 python.exe；[SettingKey.ragPythonPath] 为 null 时显示它。
  final String runtimePython;

  /// 用户选的解释器和当前环境不是同一个：出“使用此解释器”。
  final bool pythonPending;

  /// 正在安装运行环境；null = 没在装。
  final SettingsRagInstall? install;

  /// 正在下载模型；null = 没在下。
  final SettingsRagDownload? download;

  /// 上次“查找本地模型”没找到。
  final bool modelsMissing;

  /// 待确认的建库计划；null = 没有。
  final SettingsRagPlan? plan;

  /// A user-requested index preview/start/resume is awaiting the local worker.
  final SettingsRagSourceKind? preparing;
  final bool initializing;
  final String initializationPhase;
  final int initializationProcessed, initializationTotal;
  bool get progressKnown =>
      sources.where((s) => s.enabled).every((s) => s.known);

  /// 最近一次安装 / 下载失败的原因（原样显示在状态卡里）。
  final String? error;

  /// 安装、下载、建库任一在进行：别的重活按钮都不可点。
  bool get busy =>
      initializing ||
      preparing != null ||
      install != null ||
      download != null ||
      sources.any((s) => s.state == SettingsRagState.building);

  /// 0–1，按来源条数平均（未启用的不算）。
  double get overall {
    final on = sources.where((s) => s.enabled && s.total > 0).toList();
    if (on.isEmpty) return 0;
    return on.fold<double>(0, (s, e) => s + e.fraction) / on.length;
  }
}

// ── 本地放大

enum SettingsGpuCap { vulkan, cuda, int8, rtxVideo }

enum SettingsInstallState {
  builtin,
  installed,
  notInstalled,
  downloading,
  failed,
}

@immutable
class SettingsUpscaleModel {
  const SettingsUpscaleModel({
    required this.id,
    required this.state,
    required this.bytes,
    this.file = '',
    this.vramGb,
    this.received = 0,
    this.total = 0,
    this.speed = 0,
    this.isDefault = false,
  });

  /// 常规模型：animeQuality / animeFast / general；SeedVR2：seed3b / seed7b / seed7bSharp；
  /// RTX Video：rtxVideo。名称和说明由界面按 id 给。
  final String id;
  final SettingsInstallState state;

  /// Fixed model size, excluding shared runtimes and download archives.
  final int bytes;

  /// 模型文件名（常规模型显示）。
  final String file;
  final int? vramGb;

  /// 下载中：已下载字节、传输总字节（可能为 0）、每秒字节。
  final int received;
  final int total;
  final int speed;
  final bool isDefault;
}

@immutable
class SettingsUpscaleData {
  const SettingsUpscaleData({
    this.gpuName,
    this.vramGb = 0,
    this.caps = const {},
    this.cudaVersion = '',
    this.esrgan = const [],
    this.seed = const [],
    this.rtx,
    this.seedOffloadMaxBlocks = 32,
  });

  /// 显卡检测（新增）；null = 没检测到独显。
  final String? gpuName;
  final int vramGb;
  final Set<SettingsGpuCap> caps;
  final String cudaVersion;
  final List<SettingsUpscaleModel> esrgan;
  final List<SettingsUpscaleModel> seed;
  final SettingsUpscaleModel? rtx;

  /// Upper bound of the currently edited SeedVR2 model: 3B = 32, 7B = 36.
  /// Wiring supplies Seedvr2Options.maxBlocks for the selected model.
  final int seedOffloadMaxBlocks;
}

// ── 桥接与集成

@immutable
class SettingsBridgeActivity {
  const SettingsBridgeActivity({
    required this.client,
    required this.action,
    required this.at,
    this.tone = SettingsTone.ok,
  });

  /// 例如 `Claude Code`。
  final String client;

  /// 已本地化的一句，例如“修改参数 · 正面提示词”。
  final String action;
  final DateTime at;
  final SettingsTone tone;
}

@immutable
class SettingsBridgesData {
  const SettingsBridgesData({
    this.kritaConnected = false,
    this.kritaClient = '',
    this.kritaEndpoint = '',
    this.kritaDiscovery = '',
    this.agentClients = 0,
    this.activity = const [],
    this.comfyTone = SettingsTone.idle,
    this.comfyMessage = '',
    this.comfyCheckedAt,
    this.comfyTesting = false,
  });

  final bool kritaConnected;

  /// 例如 `Krita 5.2.6 · krita-ai-diffusion 1.24`。
  final String kritaClient;
  final String kritaEndpoint;
  final String kritaDiscovery;
  final int agentClients;
  final List<SettingsBridgeActivity> activity;
  final SettingsTone comfyTone;

  /// 失败原因（已本地化）。
  final String comfyMessage;
  final DateTime? comfyCheckedAt;
  final bool comfyTesting;
}

// ── 网络

enum SettingsEndpointKind { naiImage, naiApi, danbooru, update, provider }

@immutable
class SettingsEndpoint {
  const SettingsEndpoint({
    required this.kind,
    required this.host,
    this.name = '',
    this.latencyMs,
    this.tone = SettingsTone.idle,
  });

  final SettingsEndpointKind kind;
  final String host;

  /// [SettingsEndpointKind.provider] 时的服务商名。
  final String name;
  final int? latencyMs;
  final SettingsTone tone;
}

@immutable
class SettingsNetworkData {
  const SettingsNetworkData({
    this.systemProxy,
    this.endpoints = const [],
    this.checking = false,
    this.checkedAt,
  });

  /// 检测到的系统代理，例如 `127.0.0.1:7897`。
  final String? systemProxy;
  final List<SettingsEndpoint> endpoints;
  final bool checking;
  final DateTime? checkedAt;
}

// ── 隐私

@immutable
class SettingsPrivacyData {
  const SettingsPrivacyData({
    this.blacklist = const [],
    this.danbooruUser,
    this.lastSyncAt,
    this.syncing = false,
  });

  final List<String> blacklist;

  /// 已登录的 Danbooru 用户名；null = 未登录（同步按钮换成登录）。
  final String? danbooruUser;
  final DateTime? lastSyncAt;
  final bool syncing;
}

// ── 备份

enum SettingsResetScope { appearance, input, protection, shortcuts }

enum SettingsBackupKind { import, reset, upgrade }

@immutable
class SettingsBackup {
  const SettingsBackup({
    required this.id,
    required this.kind,
    required this.at,
  });
  final String id;
  final SettingsBackupKind kind;
  final DateTime at;
}

@immutable
class SettingsBackupData {
  const SettingsBackupData({
    this.lastImportAt,
    this.backups = const [],
    this.shortcutsCustomized = 0,
  });

  /// 有值时“撤销上次导入”可用。
  final DateTime? lastImportAt;

  /// 自动备份（新增：保留最近 5 份）。
  final List<SettingsBackup> backups;
  final int shortcutsCustomized;
}

// ── 关于

enum SettingsUpdateState { upToDate, available, checking, downloading, failed }

@immutable
class SettingsAboutData {
  const SettingsAboutData({
    this.build = '',
    this.platform = '',
    this.update = SettingsUpdateState.upToDate,
    this.latest = '',
    this.releasedAt,
    this.updateBytes = 0,
    this.notes = const [],
    this.progress = 0,
    this.checkedAt,
    this.system = const [],
  });

  final String build;
  final String platform;
  final SettingsUpdateState update;
  final String latest;
  final DateTime? releasedAt;
  final int updateBytes;

  /// 新版本要点，每条一行。
  final List<String> notes;

  /// 下载进度 0–1。
  final double progress;
  final DateTime? checkedAt;

  /// 侧注“系统”：(名称, 值)，名称已本地化。
  final List<(String, String)> system;
}

// ───────────────────────────── 回调 ─────────────────────────────

/// 所有回调。默认空实现，接线方只覆盖接好的部分；没接的按钮界面照样显示。
@immutable
class SettingsActions {
  const SettingsActions({
    this.onOpenPage = _noPage,
    this.onChanged = _noChange,
    this.onReset = _noKey,
    this.onResetPage = _noPage,
    this.onUndo = _noId,
    this.onPickPath = _noKey,
    this.onOpenPath = _noKey,
    this.onRestart = _none,
    this.onPreviewSound = _none,
    this.onPreviewNotification = _none,
    // 账号
    this.onSwitchAccount = _noId,
    this.onAddAccount = _none,
    this.onEditAccount = _noId,
    this.onUpdateCredentials = _noId,
    this.onSetDefaultAccount = _noId,
    this.onDeleteAccount = _noId,
    this.onOpenAccountPortal = _none,
    // 画布
    this.onChannelChanged = _noChannel,
    // 快捷键
    this.onShortcutRecorded = _noShortcut,
    this.onShortcutCleared = _noId,
    this.onShortcutReset = _noId,
    this.onShortcutsResetAll = _none,
    this.onShortcutsImport = _none,
    this.onShortcutsExport = _none,
    this.onShowShortcutHelp = _none,
    // 存储
    this.onRecomputeStorage = _none,
    this.onAddGalleryRoot = _none,
    this.onRemoveGalleryRoot = _noId,
    this.onOpenGalleryRoot = _noId,
    this.onImportTagIndex = _none,
    this.onRescanGallery = _none,
    this.onCleanThumbnails = _none,
    this.onOpenFolder = _noFolder,
    // 词库
    this.onClearCache = _noCache,
    this.onResetCacheStats = _none,
    this.onUpdateDictionary = _noDictionary,
    this.onCheckDictionaryUpdates = _none,
    this.onCancelDictionaryUpdate = _none,
    this.onExportTagSemantics = _none,
    this.onImportTagSemantics = _none,
    // 模型
    this.onAddProvider = _none,
    this.onImportModelConfig = _none,
    this.onCopyModelConfig = _none,
    this.onTestProvider = _noId,
    this.onProviderEnabled = _noIdBool,
    this.onProviderField = _noField,
    this.onRefreshModels = _noId,
    this.onAddModel = _noId,
    this.onRemoveModel = _noIdId,
    this.onProviderAdvanced = _noId,
    this.onDeleteProvider = _noId,
    this.onAssign = _noAssign,
    this.onEditPreset = _noIdOpt,
    this.onDeletePreset = _noId,
    this.onRequestDetails = _noId,
    // Agent
    this.onSaveInstructions = _noInstructions,
    this.onEditWorkspaceRules = _none,
    this.onSaveSystemPrompt = _noSystemPrompt,
    this.onViewBuiltinPrompt = _none,
    this.onViewFinalPrompt = _none,
    this.onExtensionEnabled = _noIdBool,
    this.onRemoveExtension = _noId,
    this.onAddExtension = _noBool,
    this.onSkillEnabled = _noIdBool,
    this.onSkillManual = _noIdBool,
    this.onViewSkill = _noId,
    this.onOpenSkillFolder = _noId,
    this.onRemoveSkill = _noId,
    this.onAddSkill = _none,
    this.onNewSkill = _none,
    this.onOpenSkillRoot = _noSkillSource,
    this.onMcpEnabled = _noIdBool,
    this.onMcpMode = _noMcpMode,
    this.onMcpLogin = _noId,
    this.onEditMcp = _noIdOpt,
    this.onRemoveMcp = _noId,
    this.onOpenAgent = _none,
    // 语义检索
    this.onRagSourceEnabled = _noRagBool,
    this.onRagPause = _noRag,
    this.onRagResume = _noRag,
    this.onRagBuild = _noRag,
    this.onRagRebuild = _noRag,
    this.onRagStartPlan = _none,
    this.onRagCancelPlan = _none,
    this.onRagClear = _noRag,
    this.onRagRefresh = _none,
    this.onRagCheckRuntime = _none,
    this.onRagInstallRuntime = _noRagInstall,
    this.onRagCancelInstall = _none,
    this.onRagUsePython = _none,
    this.onRagDownload = _noRagModel,
    this.onRagCancelDownload = _none,
    this.onRagDiscoverModels = _none,
    // 本地放大
    this.onUpscaleInstall = _noId,
    this.onUpscaleCancel = _noId,
    this.onUpscaleRemove = _noId,
    this.onUpscaleImport = _none,
    // 桥接
    this.onCopyKritaEndpoint = _none,
    this.onRegenerateKritaSession = _none,
    this.onOpenKritaDiscovery = _none,
    this.onCopyAgentTakeover = _none,
    this.onEndAgentConnections = _none,
    this.onTestComfy = _none,
    // 网络
    this.onCheckEndpoints = _none,
    // 隐私
    this.onAddBlacklistTag = _noText,
    this.onRemoveBlacklistTag = _noText,
    this.onSyncBlacklist = _none,
    this.onDanbooruLogin = _none,
    // 备份
    this.onExportPreferences = _none,
    this.onImportPreferences = _none,
    this.onUndoImport = _none,
    this.onResetScopes = _noScopes,
    this.onRestoreBackup = _noId,
    // 关于
    this.onCheckUpdate = _none,
    this.onInstallUpdate = _none,
    this.onOpenChangelog = _none,
    this.onCopyDiagnostics = _none,
    this.onOpenRepository = _none,
    this.onOpenUpstream = _none,
    this.onOpenLicenses = _none,
    this.providers = const ProvidersActions(),
  });

  /// 新服务商工作台的回调（见 [SettingsModelsData.workbench]）。
  final ProvidersActions providers;

  static const none = SettingsActions();

  final ValueChanged<SettingsPageId> onOpenPage;

  /// 标量设置改了：值类型见 [SettingSpec]（bool / String / double）。接线方写入后应更新
  /// [SettingsViewData.values]、[SettingsViewData.modified] 和 [SettingsViewData.lastChange]。
  final void Function(SettingKey key, Object? value) onChanged;
  final ValueChanged<SettingKey> onReset;
  final ValueChanged<SettingsPageId> onResetPage;

  /// 撤销某次修改（[SettingsChange.id]）。
  final ValueChanged<String> onUndo;

  /// 路径设置：选择文件 / 文件夹（音效文件选文件，其余选文件夹），在资源管理器中打开。
  /// 清除路径（恢复默认位置）走 [onReset]。
  final ValueChanged<SettingKey> onPickPath;
  final ValueChanged<SettingKey> onOpenPath;
  final VoidCallback onRestart;
  final VoidCallback onPreviewSound;
  final VoidCallback onPreviewNotification;

  final ValueChanged<String> onSwitchAccount;
  final VoidCallback onAddAccount;
  final ValueChanged<String> onEditAccount;
  final ValueChanged<String> onUpdateCredentials;
  final ValueChanged<String> onSetDefaultAccount;

  /// 界面已确认过。
  final ValueChanged<String> onDeleteAccount;
  final VoidCallback onOpenAccountPortal;

  final ValueChanged<ChannelSettings> onChannelChanged;

  /// 录到新组合（界面已规范化成 `['Ctrl', 'Shift', 'K']` 这种顺序）。
  final void Function(String id, List<String> keys) onShortcutRecorded;
  final ValueChanged<String> onShortcutCleared;
  final ValueChanged<String> onShortcutReset;

  /// 界面已确认过。
  final VoidCallback onShortcutsResetAll;
  final VoidCallback onShortcutsImport;
  final VoidCallback onShortcutsExport;
  final VoidCallback onShowShortcutHelp;

  final VoidCallback onRecomputeStorage;
  final VoidCallback onAddGalleryRoot;
  final ValueChanged<String> onRemoveGalleryRoot;
  final ValueChanged<String> onOpenGalleryRoot;
  final VoidCallback onImportTagIndex;
  final VoidCallback onRescanGallery;

  /// 界面已确认过。
  final VoidCallback onCleanThumbnails;
  final ValueChanged<SettingsFolder> onOpenFolder;

  /// 界面已确认过。
  final ValueChanged<SettingsCacheKind> onClearCache;
  final VoidCallback onResetCacheStats;
  final ValueChanged<SettingsDictionaryKind> onUpdateDictionary;
  final VoidCallback onCheckDictionaryUpdates;
  final VoidCallback onCancelDictionaryUpdate;
  final VoidCallback onExportTagSemantics, onImportTagSemantics;

  final VoidCallback onAddProvider;
  final VoidCallback onImportModelConfig;
  final VoidCallback onCopyModelConfig;
  final ValueChanged<String> onTestProvider;
  final void Function(String id, bool enabled) onProviderEnabled;

  /// 服务商的名称 / 地址 / Key 编辑完（失焦或回车）。Key 传明文，接线方负责安全存储。
  final void Function(String id, SettingsProviderField field, String value)
  onProviderField;
  final ValueChanged<String> onRefreshModels;

  /// 手动添加模型（接线方弹现有的输入框）。
  final ValueChanged<String> onAddModel;
  final void Function(String providerId, String modelId) onRemoveModel;

  /// 高级请求参数（接线方打开现有编辑器）。
  final ValueChanged<String> onProviderAdvanced;

  /// 界面已确认过。
  final ValueChanged<String> onDeleteProvider;
  final void Function(
    SettingsModelTask task, {
    String? providerId,
    String? modelId,
    String? presetId,
    String? reasoningEffort,
    bool clearReasoningEffort,
  })
  onAssign;

  /// 打开预设编辑器；null = 新建。
  final ValueChanged<String?> onEditPreset;
  final ValueChanged<String> onDeletePreset;

  /// Open the existing, redacted HTTP transcript for this history record.
  final ValueChanged<String> onRequestDetails;

  /// Await the write acknowledgement. False (including a stale-value rejection)
  /// keeps the submitted draft and the navigation guard active.
  final Future<bool> Function({
    required String global,
    required String prefix,
    required String expectedGlobal,
    required String expectedPrefix,
  })
  onSaveInstructions;

  /// 保存基础提示词 [SettingsAgentData.systemPrompt]。[text] = null：全局恢复内置（界面已确认过）/
  /// 工作区改回沿用全局。[workspaceId] 是开始编辑时的工作区：scope 为 workspace 时接线方须核对它
  /// 仍是当前工作区再写。工作区已变或写入失败返回 false，界面保留草稿并提示。
  final Future<bool> Function({
    required SettingsPromptScope scope,
    required String? text,
    required String workspaceId,
    required String? expectedText,
  })
  onSaveSystemPrompt;
  final VoidCallback onEditWorkspaceRules;
  final VoidCallback onViewBuiltinPrompt;
  final VoidCallback onViewFinalPrompt;
  final void Function(String id, bool enabled) onExtensionEnabled;
  final ValueChanged<String> onRemoveExtension;

  /// true = 选目录，false = 选文件。
  final ValueChanged<bool> onAddExtension;

  /// 用户 Skill 开关；内置 Skill 没有开关。
  final void Function(String id, bool enabled) onSkillEnabled;

  /// true = 仅手动，false = 自动。
  final void Function(String id, bool manual) onSkillManual;

  /// 查看 SKILL.md（内置为只读，带“复制为我的 Skill”）。
  final ValueChanged<String> onViewSkill;
  final ValueChanged<String> onOpenSkillFolder;

  /// 接线方先确认，再把文件夹移到 skill-trash。
  final ValueChanged<String> onRemoveSkill;

  /// 选文件夹 → 选位置 / 调用方式 → 复制进来。
  final VoidCallback onAddSkill;
  final VoidCallback onNewSkill;
  final ValueChanged<SettingsSkillSource> onOpenSkillRoot;
  final void Function(String id, bool enabled) onMcpEnabled;
  final void Function(String id, SettingsMcpMode mode) onMcpMode;
  final ValueChanged<String> onMcpLogin;

  /// 编辑 MCP 服务器；null = 新建（接线方打开现有表单）。
  final ValueChanged<String?> onEditMcp;
  final ValueChanged<String> onRemoveMcp;
  final VoidCallback onOpenAgent;

  final void Function(SettingsRagSourceKind kind, bool enabled)
  onRagSourceEnabled;
  final ValueChanged<SettingsRagSourceKind> onRagPause;
  final ValueChanged<SettingsRagSourceKind> onRagResume;

  /// “建立索引 / 继续建立”：先统计，把结果填进 [SettingsRagData.plan]（统计中 `loading: true`），不直接开始。
  final ValueChanged<SettingsRagSourceKind> onRagBuild;

  /// “重建 / 重试”：同 [onRagBuild]，计划带 `rebuild: true`。
  final ValueChanged<SettingsRagSourceKind> onRagRebuild;

  /// 用户在计划卡上点了“开始”：按当前 [SettingsRagData.plan] 开始建库，然后清掉 plan。
  final VoidCallback onRagStartPlan;
  final VoidCallback onRagCancelPlan;

  /// 界面已确认过。
  final ValueChanged<SettingsRagSourceKind> onRagClear;
  final VoidCallback onRagRefresh;
  final VoidCallback onRagCheckRuntime;

  /// 安装 / 重新安装运行环境；界面已让用户在原地选好 CPU 或 CUDA。
  final void Function({required bool cuda}) onRagInstallRuntime;
  final VoidCallback onRagCancelInstall;

  /// 改用 [SettingKey.ragPythonPath] 选的解释器（现有“使用已有环境”：沿用当前 CPU / CUDA 重新装依赖）。
  final VoidCallback onRagUsePython;

  /// 下载模型权重到默认位置，完成后自动填好对应目录。
  final ValueChanged<SettingsRagModel> onRagDownload;
  final VoidCallback onRagCancelDownload;

  /// 在工作区 `04_工具/models` 查找两个模型；没找到把 [SettingsRagData.modelsMissing] 置真。
  final VoidCallback onRagDiscoverModels;

  /// 下载 / 安装 [SettingsUpscaleModel.id]（下载都需要用户点）。
  final ValueChanged<String> onUpscaleInstall;
  final ValueChanged<String> onUpscaleCancel;

  /// 界面已确认过。
  final ValueChanged<String> onUpscaleRemove;
  final VoidCallback onUpscaleImport;

  final VoidCallback onCopyKritaEndpoint;
  final VoidCallback onRegenerateKritaSession;
  final VoidCallback onOpenKritaDiscovery;
  final VoidCallback onCopyAgentTakeover;
  final VoidCallback onEndAgentConnections;
  final VoidCallback onTestComfy;

  final VoidCallback onCheckEndpoints;

  final ValueChanged<String> onAddBlacklistTag;
  final ValueChanged<String> onRemoveBlacklistTag;
  final VoidCallback onSyncBlacklist;
  final VoidCallback onDanbooruLogin;

  final VoidCallback onExportPreferences;
  final VoidCallback onImportPreferences;
  final VoidCallback onUndoImport;

  /// 界面已确认过；接线方先自动备份再重置。
  final ValueChanged<Set<SettingsResetScope>> onResetScopes;
  final ValueChanged<String> onRestoreBackup;

  final VoidCallback onCheckUpdate;
  final VoidCallback onInstallUpdate;
  final VoidCallback onOpenChangelog;
  final VoidCallback onCopyDiagnostics;
  final VoidCallback onOpenRepository;
  final VoidCallback onOpenUpstream;
  final VoidCallback onOpenLicenses;

  static void _none() {}
  static void _noPage(SettingsPageId _) {}
  static void _noChange(SettingKey _, Object? _) {}
  static void _noKey(SettingKey _) {}
  static void _noId(String _) {}
  static void _noIdOpt(String? _) {}
  static void _noIdId(String _, String _) {}
  static void _noIdBool(String _, bool _) {}
  static void _noBool(bool _) {}
  static void _noSkillSource(SettingsSkillSource _) {}
  static void _noText(String _) {}
  static void _noChannel(ChannelSettings _) {}
  static void _noShortcut(String _, List<String> _) {}
  static void _noFolder(SettingsFolder _) {}
  static void _noCache(SettingsCacheKind _) {}
  static void _noDictionary(SettingsDictionaryKind _) {}
  static void _noField(String _, SettingsProviderField _, String _) {}
  static void _noAssign(
    SettingsModelTask _, {
    String? providerId,
    String? modelId,
    String? presetId,
    String? reasoningEffort,
    bool clearReasoningEffort = false,
  }) {}
  static Future<bool> _noInstructions({
    required String global,
    required String prefix,
    required String expectedGlobal,
    required String expectedPrefix,
  }) async => false;
  static Future<bool> _noSystemPrompt({
    required SettingsPromptScope scope,
    required String? text,
    required String workspaceId,
    required String? expectedText,
  }) async => true;
  static void _noMcpMode(String _, SettingsMcpMode _) {}
  static void _noRag(SettingsRagSourceKind _) {}
  static void _noRagBool(SettingsRagSourceKind _, bool _) {}
  static void _noRagModel(SettingsRagModel _) {}
  static void _noRagInstall({required bool cuda}) {}
  static void _noScopes(Set<SettingsResetScope> _) {}
}

enum SettingsProviderField { name, baseUrl, apiKey }
