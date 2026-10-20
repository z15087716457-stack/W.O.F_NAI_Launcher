import 'package:path/path.dart' as p;

import '../../ui/agent/agent_contract.dart';

class AgentGalleryRestore {
  const AgentGalleryRestore(this.id, this.arguments, this.details);
  final String id;
  final Map<String, dynamic> arguments, details;

  AgentGalleryAction? get action => switch (arguments['action'] ??
      details['action']) {
    'update'
        when (arguments['changes'] as Map?)?.containsKey('favorite') == true =>
      (arguments['changes'] as Map)['favorite'] == true
          ? AgentGalleryAction.favorite
          : AgentGalleryAction.unfavorite,
    'update' when (arguments['changes'] as Map?)?.containsKey('tags') == true =>
      AgentGalleryAction.tags,
    'delete' => AgentGalleryAction.delete,
    'restore' => AgentGalleryAction.restore,
    'move_file' => AgentGalleryAction.move,
    'copy_file' => AgentGalleryAction.copy,
    'collection_add' => AgentGalleryAction.collectionAdd,
    'collection_remove' => AgentGalleryAction.collectionRemove,
    'export' => AgentGalleryAction.export,
    _ => null,
  };

  List<String> get imageIds => {
    if (details['image_ids'] is List)
      ...(details['image_ids'] as List).whereType<String>(),
    if (details['image_id'] is String) details['image_id'] as String,
    if (details['image_ids'] == null &&
        details['image_id'] == null &&
        arguments['image_ids'] is List)
      ...(arguments['image_ids'] as List).whereType<String>(),
    if (details['image_id'] == null && arguments['image_id'] is String)
      arguments['image_id'] as String,
  }.toList();

  String? get target {
    if (details['collection_name'] is String) {
      return details['collection_name'] as String;
    }
    if (action != AgentGalleryAction.move &&
        action != AgentGalleryAction.copy) {
      return null;
    }
    final path = arguments['target_folder'] ?? details['target_folder'];
    if (path is String) return p.basename(p.normalize(path));
    final file = details['file_path'];
    return file is String ? p.basename(p.dirname(file)) : null;
  }

  bool get undoable {
    if (details['unchanged'] == true) return false;
    switch (action) {
      case AgentGalleryAction.favorite:
      case AgentGalleryAction.unfavorite:
      case AgentGalleryAction.tags:
        final before = details['before'];
        final changes = arguments['changes'];
        return details['image_version'] is String &&
            before is Map &&
            changes is Map &&
            changes.keys.every(before.containsKey);
      case AgentGalleryAction.delete:
      case AgentGalleryAction.restore:
        return details['scope'] == 'library' &&
            details['image_version'] is String;
      case AgentGalleryAction.move:
        return details['image_version'] is String &&
            details['source_path'] is String;
      case AgentGalleryAction.collectionAdd:
      case AgentGalleryAction.collectionRemove:
        return imageIds.isNotEmpty &&
            details['collection_version'] is String &&
            details['before'] is Map &&
            details['image_versions'] is Map &&
            imageIds.every(
              (id) =>
                  (details['before'] as Map).containsKey(id) &&
                  (details['image_versions'] as Map)[id] is String,
            );
      default:
        return false;
    }
  }
}
