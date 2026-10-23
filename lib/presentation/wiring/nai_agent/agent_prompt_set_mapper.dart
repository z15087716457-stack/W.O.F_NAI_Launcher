import 'dart:ui' show Offset;
import '../../../data/services/nai_agent/agent_workspace_store.dart';
import 'package:path/path.dart' as p;
import '../../ui/agent/agent_contract.dart';
import 'agent_resources.dart';

AgentPromptSet agentPromptSetData(
  Map<String, dynamic> value,
  AgentWorkspace workspace,
  AgentResources resources,
  Map<String, AgentImage> registry, {
  int? unitAnlas,
  int? importedIndex,
  bool canUndoImport = false,
  int? busyIndex,
  double? aspect,
}) {
  List<Offset?> positions(Map source) => [
    for (final entry in source['positions'] as List? ?? const [])
      entry == null
          ? null
          : Offset(
              (entry['x'] as num).toDouble(),
              (entry['y'] as num).toDouble(),
            ),
  ];
  final shared = value['shared'] as Map;
  final images = <int, List<AgentImage>>{};
  for (final entry in (value['images'] as Map? ?? {}).entries) {
    final index = int.tryParse(entry.key.toString());
    if (index == null) continue;
    images[index] = [];
    for (final (j, raw) in (entry.value as List).indexed) {
      final image = raw as Map;
      final path = image['path'] as String?;
      if (path == null) continue;
      final preview = resources.image(workspace, path);
      if (preview == null) continue;
      final id = 'prompt-set/${value['set_id']}/$index/$j';
      final data = AgentImage(
        id: id,
        image: preview,
        width: image['width'] as int?,
        height: image['height'] as int?,
        historyId: image['image_id'] as String?,
        path: resources.file(workspace, path) == null
            ? null
            : p.normalize(p.absolute(workspace.directory.path, path)),
        source: AgentImageSource.generated,
      );
      registry[id] = data;
      images[index]!.add(data);
    }
  }
  return AgentPromptSet(
    setId: value['set_id'] as String,
    revision: value['revision'] as int,
    kind: value['kind'] as String,
    kindIcon: value['kind_icon'] as String,
    title: value['title'] as String,
    unit: value['unit'] as String,
    ordered: value['ordered'] as bool,
    shared: AgentPromptSetShared(
      main: shared['main'] as String? ?? '',
      negative: shared['negative'] as String? ?? '',
      characters: (shared['characters'] as List? ?? []).cast<String>(),
      positions: positions(shared),
    ),
    items: [
      for (final item in value['items'] as List)
        AgentPromptSetItem(
          icon: item['icon'] as String,
          title: item['title'] as String,
          note: item['note'] as String? ?? '',
          main: item['main'] as String? ?? '',
          characters: (item['characters'] as List? ?? []).cast<String>(),
          positions: positions(item as Map),
        ),
    ],
    changedItems: (value['changed_items'] as List? ?? []).cast<int>(),
    images: images,
    unitAnlas: unitAnlas,
    importedIndex:
        importedIndex != null && importedIndex < (value['items'] as List).length
        ? importedIndex
        : null,
    canUndoImport: canUndoImport,
    busyIndex: busyIndex,
    aspect: aspect,
  );
}
