/// 工作流模板 & 槽位定义
///
/// 一个工作流模板由两部分组成：
/// 1. workflow_api.json — ComfyUI 可执行的节点图
/// 2. manifest（WorkflowTemplate）— 描述模板元信息和可注入槽位
library;

/// 槽位方向
enum SlotDirection {
  /// 启动器 → ComfyUI（输入图像/蒙版）
  input,

  /// 用户可调参数（数值/文本/枚举）
  parameter,

  /// ComfyUI → 启动器（输出图像）
  output,
}

/// 槽位数据类型
enum SlotDataType { image, mask, string, number, integer, choice, boolean }

/// 输出获取方式
enum OutputMethod {
  /// 通过 /history + /view 获取（SaveImage 节点）
  httpHistory,

  /// 通过 WebSocket 二进制帧获取（SaveImageWebsocket 节点）
  websocket,
}

/// 单个槽位定义
class WorkflowSlot {
  final String id;
  final SlotDirection direction;
  final SlotDataType dataType;

  /// 目标节点 ID（对应 workflow_api.json 中的 key）
  final String nodeId;

  /// 目标节点输入字段名（direction 为 input/parameter 时必填）
  final String? field;

  /// UI 显示标签
  final String label;

  /// 是否必填
  final bool required;

  /// 默认值（parameter 槽位使用）
  final dynamic defaultValue;

  /// 数值约束（number/integer 类型使用）
  final double? min;
  final double? max;
  final double? step;

  /// 枚举选项（choice 类型使用）
  final List<String>? choices;

  /// 输出方式（output 槽位使用）
  final OutputMethod? outputMethod;

  /// 目标节点 class_type（output 槽位用于识别）
  final String? nodeClass;

  const WorkflowSlot({
    required this.id,
    required this.direction,
    required this.dataType,
    required this.nodeId,
    this.field,
    required this.label,
    this.required = false,
    this.defaultValue,
    this.min,
    this.max,
    this.step,
    this.choices,
    this.outputMethod,
    this.nodeClass,
  });

  factory WorkflowSlot.fromJson(Map<String, dynamic> json) {
    return WorkflowSlot(
      id: json['id'] as String,
      direction: SlotDirection.values.firstWhere(
        (e) => e.name == json['direction'],
      ),
      dataType: SlotDataType.values.firstWhere((e) => e.name == json['type']),
      nodeId: json['node_id'] as String,
      field: json['field'] as String?,
      label: json['label'] as String,
      required: json['required'] as bool? ?? false,
      defaultValue: json['default'],
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      step: (json['step'] as num?)?.toDouble(),
      choices: (json['choices'] as List?)?.cast<String>(),
      outputMethod: json['output_method'] != null
          ? OutputMethod.values.firstWhere(
              (e) => e.name == json['output_method'],
            )
          : null,
      nodeClass: json['node_class'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'direction': direction.name,
    'type': dataType.name,
    'node_id': nodeId,
    if (field != null) 'field': field,
    'label': label,
    if (required) 'required': required,
    if (defaultValue != null) 'default': defaultValue,
    if (min != null) 'min': min,
    if (max != null) 'max': max,
    if (step != null) 'step': step,
    if (choices != null) 'choices': choices,
    if (outputMethod != null) 'output_method': outputMethod!.name,
    if (nodeClass != null) 'node_class': nodeClass,
  };
}

/// 工作流模板分类
enum WorkflowCategory { enhance, img2img, inpaint, txt2img, custom }

/// 工作流模板
class WorkflowTemplate {
  final String id;
  final String name;
  final String description;
  final String version;
  final String author;
  final WorkflowCategory category;
  final bool requiresInputImage;
  final bool requiresMask;
  final List<WorkflowSlot> slots;

  /// 原始 workflow_api.json 数据
  final Map<String, dynamic> workflowJson;

  /// 是否为内置模板
  final bool isBuiltin;

  const WorkflowTemplate({
    required this.id,
    required this.name,
    required this.description,
    this.version = '1.0.0',
    this.author = '',
    this.category = WorkflowCategory.custom,
    this.requiresInputImage = false,
    this.requiresMask = false,
    required this.slots,
    required this.workflowJson,
    this.isBuiltin = false,
  });

  /// 获取所有输入槽位
  List<WorkflowSlot> get inputSlots =>
      slots.where((s) => s.direction == SlotDirection.input).toList();

  /// 获取所有参数槽位
  List<WorkflowSlot> get parameterSlots =>
      slots.where((s) => s.direction == SlotDirection.parameter).toList();

  /// 获取所有输出槽位
  List<WorkflowSlot> get outputSlots =>
      slots.where((s) => s.direction == SlotDirection.output).toList();

  /// 是否使用 WebSocket 输出
  bool get usesWebSocketOutput =>
      outputSlots.any((s) => s.outputMethod == OutputMethod.websocket);

  factory WorkflowTemplate.fromJson(
    Map<String, dynamic> manifest,
    Map<String, dynamic> workflowJson, {
    bool isBuiltin = false,
  }) {
    return WorkflowTemplate(
      id: manifest['id'] as String,
      name: manifest['name'] as String,
      description: manifest['description'] as String? ?? '',
      version: manifest['version'] as String? ?? '1.0.0',
      author: manifest['author'] as String? ?? '',
      category: WorkflowCategory.values.firstWhere(
        (e) => e.name == manifest['category'],
        orElse: () => WorkflowCategory.custom,
      ),
      requiresInputImage: manifest['requires_input_image'] as bool? ?? false,
      requiresMask: manifest['requires_mask'] as bool? ?? false,
      slots: (manifest['slots'] as List)
          .map((s) => WorkflowSlot.fromJson(s as Map<String, dynamic>))
          .toList(),
      workflowJson: workflowJson,
      isBuiltin: isBuiltin,
    );
  }

  /// 序列化 manifest 部分（不含 workflowJson）
  Map<String, dynamic> toManifestJson() => {
    'id': id,
    'name': name,
    'description': description,
    'version': version,
    'author': author,
    'category': category.name,
    'requires_input_image': requiresInputImage,
    'requires_mask': requiresMask,
    'slots': slots.map((s) => s.toJson()).toList(),
  };

  /// 创建副本并替换部分属性
  WorkflowTemplate copyWith({
    String? name,
    String? description,
    WorkflowCategory? category,
    List<WorkflowSlot>? slots,
    bool? requiresInputImage,
    bool? requiresMask,
  }) {
    return WorkflowTemplate(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      version: version,
      author: author,
      category: category ?? this.category,
      requiresInputImage: requiresInputImage ?? this.requiresInputImage,
      requiresMask: requiresMask ?? this.requiresMask,
      slots: slots ?? this.slots,
      workflowJson: workflowJson,
      isBuiltin: isBuiltin,
    );
  }
}
