/// 药丸编辑器数据模型（P0 原型）。
///
/// 与旧的段式 `PromptBlockDocument` 平行存在：底层是单个字符串，
/// 块实例 = 字符串中的 1 个私有区字符（U+E000 起），**字符本身即实例 ID**。
/// 手写不可变类（不走 freezed/build_runner），原型期减少再生成链路。
library;

/// 实例随机模式（P2.5）：固定 = 投影恒为块内容；随机抽取 = 投影为物化的
/// `currentRoll`（roll 时机：参数变更/手动骰子/生成入队后）。
enum PillRollMode { fixed, random }

/// 随机抽取的输出顺序：抽中序 / 按原序（质量词类块用后者）。
enum PillRollOrder { drawn, original }

/// 块实例的随机参数集（P2.5，挂实例不挂块定义——同一块两实例可不同设置）。
///
/// 权重语义对齐 PromptCard Split-Beta：最小/最大/平均（=众数，0.1 步进、
/// -3.0~3.0）+ 左右离散（0~1，Beta(1, 12-11d) 距离分布）+ 软平衡
/// （整串均值向「平均」回拉 strength 比例）。离散预设（集中/均衡/发散）
/// 只是 UI 快捷写左右离散，不落库。
class PillInstanceSettings {
  const PillInstanceSettings({
    this.mode = PillRollMode.fixed,
    this.countMin = 1,
    this.countMax = 1,
    this.order = PillRollOrder.drawn,
    this.weightEnabled = false,
    this.weightMin = 0.1,
    this.weightMax = 2.0,
    this.weightAverage = 0.8,
    this.leftDispersion = 0.4,
    this.rightDispersion = 0.4,
    this.softBalance = true,
    this.softBalanceStrength = 1.0,
    this.triggerProbability = 1.0,
  });

  /// 固定模式默认实例（也是旧存档缺键时的兜底）。
  static const PillInstanceSettings fixedDefault = PillInstanceSettings();

  static const double weightFloor = -3.0;
  static const double weightCeiling = 3.0;

  final PillRollMode mode;
  final int countMin;
  final int countMax;
  final PillRollOrder order;
  final bool weightEnabled;
  final double weightMin;
  final double weightMax;
  final double weightAverage;
  final double leftDispersion;
  final double rightDispersion;
  final bool softBalance;
  final double softBalanceStrength;
  final double triggerProbability;

  bool get isRandom => mode == PillRollMode.random;

  PillInstanceSettings copyWith({
    PillRollMode? mode,
    int? countMin,
    int? countMax,
    PillRollOrder? order,
    bool? weightEnabled,
    double? weightMin,
    double? weightMax,
    double? weightAverage,
    double? leftDispersion,
    double? rightDispersion,
    bool? softBalance,
    double? softBalanceStrength,
    double? triggerProbability,
  }) {
    return PillInstanceSettings(
      mode: mode ?? this.mode,
      countMin: countMin ?? this.countMin,
      countMax: countMax ?? this.countMax,
      order: order ?? this.order,
      weightEnabled: weightEnabled ?? this.weightEnabled,
      weightMin: weightMin ?? this.weightMin,
      weightMax: weightMax ?? this.weightMax,
      weightAverage: weightAverage ?? this.weightAverage,
      leftDispersion: leftDispersion ?? this.leftDispersion,
      rightDispersion: rightDispersion ?? this.rightDispersion,
      softBalance: softBalance ?? this.softBalance,
      softBalanceStrength: softBalanceStrength ?? this.softBalanceStrength,
      triggerProbability: triggerProbability ?? this.triggerProbability,
    );
  }

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'countMin': countMin,
    'countMax': countMax,
    'order': order.name,
    'weightEnabled': weightEnabled,
    'weightMin': weightMin,
    'weightMax': weightMax,
    'weightAverage': weightAverage,
    'leftDispersion': leftDispersion,
    'rightDispersion': rightDispersion,
    'softBalance': softBalance,
    'softBalanceStrength': softBalanceStrength,
    'triggerProbability': triggerProbability,
  };

  /// 容错反序列化：缺键/越界一律落默认，旧存档零迁移。
  factory PillInstanceSettings.fromJson(Map<String, dynamic> json) {
    const defaults = fixedDefault;
    return PillInstanceSettings(
      mode: PillRollMode.values.asNameMap()[json['mode']] ?? defaults.mode,
      countMin: _intAt(json['countMin'], defaults.countMin).clamp(0, 9999),
      countMax: _intAt(json['countMax'], defaults.countMax).clamp(0, 9999),
      order: PillRollOrder.values.asNameMap()[json['order']] ?? defaults.order,
      weightEnabled: json['weightEnabled'] as bool? ?? defaults.weightEnabled,
      weightMin: _weightAt(json['weightMin'], defaults.weightMin),
      weightMax: _weightAt(json['weightMax'], defaults.weightMax),
      weightAverage: _weightAt(json['weightAverage'], defaults.weightAverage),
      leftDispersion: _unitAt(json['leftDispersion'], defaults.leftDispersion),
      rightDispersion: _unitAt(
        json['rightDispersion'],
        defaults.rightDispersion,
      ),
      softBalance: json['softBalance'] as bool? ?? defaults.softBalance,
      softBalanceStrength: _unitAt(
        json['softBalanceStrength'],
        defaults.softBalanceStrength,
      ),
      triggerProbability: _unitAt(
        json['triggerProbability'],
        defaults.triggerProbability,
      ),
    );
  }

  static int _intAt(Object? value, int fallback) =>
      value is num ? value.toInt() : fallback;

  static double _weightAt(Object? value, double fallback) {
    if (value is! num || !value.isFinite) return fallback;
    return value.toDouble().clamp(weightFloor, weightCeiling);
  }

  static double _unitAt(Object? value, double fallback) {
    if (value is! num || !value.isFinite) return fallback;
    return value.toDouble().clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) =>
      other is PillInstanceSettings &&
      other.mode == mode &&
      other.countMin == countMin &&
      other.countMax == countMax &&
      other.order == order &&
      other.weightEnabled == weightEnabled &&
      other.weightMin == weightMin &&
      other.weightMax == weightMax &&
      other.weightAverage == weightAverage &&
      other.leftDispersion == leftDispersion &&
      other.rightDispersion == rightDispersion &&
      other.softBalance == softBalance &&
      other.softBalanceStrength == softBalanceStrength &&
      other.triggerProbability == triggerProbability;

  @override
  int get hashCode => Object.hash(
    mode,
    countMin,
    countMax,
    order,
    weightEnabled,
    weightMin,
    weightMax,
    weightAverage,
    leftDispersion,
    rightDispersion,
    softBalance,
    softBalanceStrength,
    triggerProbability,
  );
}

/// 单个块实例：引用库中的块 + 启用态 + 随机参数 + 物化 roll 结果。
class PillInstance {
  const PillInstance({
    required this.blockId,
    this.enabled = true,
    this.settings = PillInstanceSettings.fixedDefault,
    this.currentRoll,
  });

  final String blockId;
  final bool enabled;
  final PillInstanceSettings settings;

  /// 随机模式下的物化提示词串：L1 卡显示 = 生成发送 = token 计数三者同源。
  /// null = 尚未 roll（投影前由工作区兜底物化）。
  final String? currentRoll;

  PillInstance copyWith({
    String? blockId,
    bool? enabled,
    PillInstanceSettings? settings,
    String? currentRoll,
  }) {
    return PillInstance(
      blockId: blockId ?? this.blockId,
      enabled: enabled ?? this.enabled,
      settings: settings ?? this.settings,
      currentRoll: currentRoll ?? this.currentRoll,
    );
  }

  Map<String, dynamic> toJson() => {
    'blockId': blockId,
    'enabled': enabled,
    'settings': settings.toJson(),
    if (currentRoll != null) 'currentRoll': currentRoll,
  };

  factory PillInstance.fromJson(Map<String, dynamic> json) {
    final rawSettings = json['settings'];
    return PillInstance(
      blockId: json['blockId'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
      settings: rawSettings is Map
          ? PillInstanceSettings.fromJson(
              Map<String, dynamic>.from(rawSettings),
            )
          : PillInstanceSettings.fixedDefault,
      currentRoll: json['currentRoll'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PillInstance &&
      other.blockId == blockId &&
      other.enabled == enabled &&
      other.settings == settings &&
      other.currentRoll == currentRoll;

  @override
  int get hashCode => Object.hash(blockId, enabled, settings, currentRoll);
}

/// 药丸工作区文档：文本（含标记字符）+ 实例表。
class PillDocument {
  const PillDocument({required this.text, required this.instances});

  factory PillDocument.empty() => const PillDocument(text: '', instances: {});

  /// 含块标记字符的原始文本。
  final String text;

  /// 标记字符 → 实例。键恒为单个字符（字符串）。
  final Map<String, PillInstance> instances;

  PillDocument copyWith({String? text, Map<String, PillInstance>? instances}) {
    return PillDocument(
      text: text ?? this.text,
      instances: instances ?? this.instances,
    );
  }

  Map<String, dynamic> toJson() => {
    'text': text,
    'instances': instances.map((key, value) => MapEntry(key, value.toJson())),
  };

  factory PillDocument.fromJson(Map<String, dynamic> json) {
    final rawInstances = json['instances'];
    final instances = <String, PillInstance>{};
    if (rawInstances is Map) {
      for (final entry in rawInstances.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String && key.length == 1 && value is Map) {
          instances[key] = PillInstance.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      }
    }
    return PillDocument(
      text: json['text'] as String? ?? '',
      instances: instances,
    );
  }

  @override
  bool operator ==(Object other) {
    if (other is! PillDocument || other.text != text) return false;
    if (other.instances.length != instances.length) return false;
    for (final entry in instances.entries) {
      if (other.instances[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    text,
    Object.hashAll(
      instances.entries.map((entry) => Object.hash(entry.key, entry.value)),
    ),
  );
}
