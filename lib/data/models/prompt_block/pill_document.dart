/// 药丸编辑器数据模型（P0 原型）。
///
/// 与旧的段式 `PromptBlockDocument` 平行存在：底层是单个字符串，
/// 块实例 = 字符串中的 1 个私有区字符（U+E000 起），**字符本身即实例 ID**。
/// 手写不可变类（不走 freezed/build_runner），原型期减少再生成链路。
library;

/// 单个块实例：引用库中的块 + 启用态。
class PillInstance {
  const PillInstance({required this.blockId, this.enabled = true});

  final String blockId;
  final bool enabled;

  PillInstance copyWith({String? blockId, bool? enabled}) {
    return PillInstance(
      blockId: blockId ?? this.blockId,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {'blockId': blockId, 'enabled': enabled};

  factory PillInstance.fromJson(Map<String, dynamic> json) {
    return PillInstance(
      blockId: json['blockId'] as String? ?? '',
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PillInstance &&
      other.blockId == blockId &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(blockId, enabled);
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
