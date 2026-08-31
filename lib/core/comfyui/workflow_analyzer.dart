import 'workflow_template.dart';

/// 工作流 JSON 分析器
///
/// 解析 workflow_api.json，自动识别输入/输出节点和可调参数，
/// 生成候选的 [WorkflowSlot] 列表供用户确认。
class WorkflowAnalyzer {
  /// 已知的输入图像节点类型
  static const Set<String> _imageInputNodeTypes = {
    'LoadImage',
    'LoadImageMask',
    'VHS_LoadImages',
    'LoadImageFromUrl',
  };

  /// 已知的输出节点类型
  static const Set<String> _outputNodeTypes = {
    'SaveImage',
    'PreviewImage',
    'SaveImageWebsocket',
    'VHS_VideoCombine',
  };

  /// 不应暴露给用户调整的内部参数
  static const Set<String> _hiddenFields = {
    'model',
    'clip',
    'vae',
    'positive',
    'negative',
    'latent_image',
    'samples',
    'images',
    'image',
    'mask',
    'conditioning',
    'control_net',
    'pixels',
  };

  /// 分析工作流 JSON，返回分析结果
  static WorkflowAnalysisResult analyze(Map<String, dynamic> workflowJson) {
    final inputSlots = <WorkflowSlot>[];
    final outputSlots = <WorkflowSlot>[];
    final parameterSlots = <WorkflowSlot>[];
    final nodeInfos = <AnalyzedNode>[];

    for (final entry in workflowJson.entries) {
      final nodeId = entry.key;
      final nodeData = entry.value as Map<String, dynamic>;
      final classType = nodeData['class_type'] as String? ?? '';
      final meta = nodeData['_meta'] as Map<String, dynamic>?;
      final title = meta?['title'] as String? ?? classType;
      final inputs = nodeData['inputs'] as Map<String, dynamic>? ?? {};

      nodeInfos.add(
        AnalyzedNode(nodeId: nodeId, classType: classType, title: title),
      );

      // 识别输入图像节点
      if (_imageInputNodeTypes.contains(classType)) {
        final imageField = inputs.containsKey('image') ? 'image' : null;
        if (imageField != null) {
          final existing = inputs[imageField];
          if (existing is! List) {
            inputSlots.add(
              WorkflowSlot(
                id: 'input_${nodeId}_image',
                direction: SlotDirection.input,
                dataType: classType.contains('Mask')
                    ? SlotDataType.mask
                    : SlotDataType.image,
                nodeId: nodeId,
                field: imageField,
                label: '$title (Node $nodeId)',
                required: true,
              ),
            );
          }
        }
      }

      // 识别输出节点
      if (_outputNodeTypes.contains(classType)) {
        final method = classType == 'SaveImageWebsocket'
            ? OutputMethod.websocket
            : OutputMethod.httpHistory;
        outputSlots.add(
          WorkflowSlot(
            id: 'output_$nodeId',
            direction: SlotDirection.output,
            dataType: SlotDataType.image,
            nodeId: nodeId,
            field: null,
            label: '$title (Node $nodeId)',
            outputMethod: method,
            nodeClass: classType,
          ),
        );
      }

      // 识别可调参数：扫描所有纯值（非连线）输入
      for (final inputEntry in inputs.entries) {
        final field = inputEntry.key;
        final value = inputEntry.value;

        if (value is List) continue;
        if (_hiddenFields.contains(field)) continue;

        final slotType = _inferDataType(value);
        if (slotType == null) continue;

        parameterSlots.add(
          WorkflowSlot(
            id: 'param_${nodeId}_$field',
            direction: SlotDirection.parameter,
            dataType: slotType,
            nodeId: nodeId,
            field: field,
            label: '$field ($title)',
            defaultValue: value,
          ),
        );
      }
    }

    return WorkflowAnalysisResult(
      inputSlots: inputSlots,
      outputSlots: outputSlots,
      parameterSlots: parameterSlots,
      nodes: nodeInfos,
      requiresInputImage: inputSlots.isNotEmpty,
      requiresMask: inputSlots.any((s) => s.dataType == SlotDataType.mask),
    );
  }

  static SlotDataType? _inferDataType(dynamic value) {
    if (value is int) return SlotDataType.integer;
    if (value is double) return SlotDataType.number;
    if (value is bool) return SlotDataType.boolean;
    if (value is String) {
      if (value.isEmpty) return null;
      if (double.tryParse(value) != null) return SlotDataType.string;
      return SlotDataType.string;
    }
    return null;
  }
}

/// 分析结果
class WorkflowAnalysisResult {
  final List<WorkflowSlot> inputSlots;
  final List<WorkflowSlot> outputSlots;
  final List<WorkflowSlot> parameterSlots;
  final List<AnalyzedNode> nodes;
  final bool requiresInputImage;
  final bool requiresMask;

  const WorkflowAnalysisResult({
    required this.inputSlots,
    required this.outputSlots,
    required this.parameterSlots,
    required this.nodes,
    required this.requiresInputImage,
    required this.requiresMask,
  });

  /// 所有自动识别的槽位合并
  List<WorkflowSlot> get allSlots => [
    ...inputSlots,
    ...parameterSlots,
    ...outputSlots,
  ];
}

/// 分析出的节点信息
class AnalyzedNode {
  final String nodeId;
  final String classType;
  final String title;

  const AnalyzedNode({
    required this.nodeId,
    required this.classType,
    required this.title,
  });
}
