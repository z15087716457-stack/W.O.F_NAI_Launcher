import 'dart:io';
import 'package:path/path.dart' as p;
import 'agent_tool.dart';

enum ExternalToolAccess { read, edit, confirmation, danger }

/// Same business-tool policy as the internal Pi permissions extension.
ExternalToolAccess externalToolAccess(String name, Map<String, dynamic> args) {
  const reads = {
    'studio_context',
    'studio_search',
    'image_read',
    'wiki_query',
    'tag_query',
    'tag_related',
    'block_query',
    'settings_read',
    'generation_prepare',
    'gallery_query',
    'generation_cancel',
    'ask_user',
  };
  const actions = {
    'prompt_set': {'read'},
    'snapshot': {'list', 'read'},
    'reference_manage': {'list'},
    'reference_library': {'query', 'read', 'categories'},
    'gallery_manage': {
      'read',
      'trash',
      'collections',
      'collection_members',
      'folders',
    },
    'image_tool': {'list', 'status', 'cancel', 'prepare'},
    'image_generate': {'prepare', 'status', 'cancel'},
    'explore_manage': {'list', 'read', 'status', 'prepare', 'pause', 'cancel'},
  };
  final action = args['action'];
  if (reads.contains(name) || (actions[name]?.contains(action) ?? false)) {
    return ExternalToolAccess.read;
  }
  if (name == 'generation_run' ||
      const {'image_generate', 'image_tool', 'explore_manage'}.contains(name) &&
          action == 'run') {
    return ExternalToolAccess.confirmation;
  }
  if (action is String &&
      RegExp(
        r'(?:^|_)(?:delete|delete_empty|move|move_file|remove)(?:$|_)',
      ).hasMatch(action)) {
    return ExternalToolAccess.danger;
  }
  return ExternalToolAccess.edit;
}

/// Skill references may be read, but the skill endpoint is not a file tool.
Future<String> readExternalSkill(String directory, String relative) async {
  if (p.isAbsolute(relative) || relative.isEmpty) {
    throw const NaiAgentToolError('invalid_path', 'Use a skill-relative path');
  }
  final root = await Directory(directory).resolveSymbolicLinks();
  final target = await File(p.join(root, relative)).resolveSymbolicLinks();
  if (!p.isWithin(root, target)) {
    throw const NaiAgentToolError(
      'invalid_path',
      'Path leaves the enabled skill',
    );
  }
  return File(target).readAsString();
}
