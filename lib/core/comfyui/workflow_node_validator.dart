// Utilities for checking whether a ComfyUI workflow can run in the connected
// server before submitting it to `/prompt`.
Set<String> extractWorkflowNodeTypes(Map<String, dynamic> workflow) {
  final nodeTypes = <String>{};
  for (final node in workflow.values) {
    if (node is! Map) continue;
    final classType = node['class_type'];
    if (classType is String && classType.trim().isNotEmpty) {
      nodeTypes.add(classType.trim());
    }
  }
  return nodeTypes;
}

List<String> findMissingWorkflowNodeTypes({
  required Map<String, dynamic> workflow,
  required Map<String, dynamic> objectInfo,
}) {
  final availableTypes = objectInfo.keys
      .map((key) => key.trim())
      .where((key) => key.isNotEmpty)
      .toSet();
  final missing = extractWorkflowNodeTypes(
    workflow,
  ).where((nodeType) => !availableTypes.contains(nodeType)).toList();
  missing.sort();
  return missing;
}

String formatMissingWorkflowNodeTypesMessage(List<String> missingNodeTypes) {
  final joined = missingNodeTypes.join(', ');
  return '缺少 ComfyUI 节点: $joined。请在 ComfyUI 中安装或启用对应自定义节点后重启 ComfyUI。';
}
