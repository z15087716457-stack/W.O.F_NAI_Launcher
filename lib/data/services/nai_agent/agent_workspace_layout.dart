import 'dart:io';
import 'package:path/path.dart' as p;

const agentWorkspaceDataName = '.W.O.F';
const agentWorkspaceManagedNames = {
  'attachments',
  'outputs',
  'notes',
  'skills',
  'sessions',
  'snapshots',
  'ui',
  'instructions.md',
  'workspace.json',
};

Directory agentWorkspaceData(Directory workspace) =>
    Directory(p.join(workspace.path, agentWorkspaceDataName));

/// Convert known launcher references, never arbitrary project paths.
String agentWorkspaceReference(String relative) {
  if (p.isAbsolute(relative)) return relative;
  final normalized = p.normalize(relative);
  final parts = p.split(normalized);
  if (parts.first == '.agent') {
    return p.joinAll([agentWorkspaceDataName, ...parts.skip(1)]);
  }
  if (parts.length >= 2 && parts[0] == '.pi' && parts[1] == 'prompts') {
    return p.joinAll([agentWorkspaceDataName, ...parts.skip(1)]);
  }
  if (agentWorkspaceManagedNames.contains(parts.first)) {
    return p.join(agentWorkspaceDataName, normalized);
  }
  return normalized;
}

/// Old conversation text remains untouched. Existing project paths win;
/// only missing legacy paths may resolve inside the launcher directory.
Future<File> agentWorkspaceReadFile(Directory workspace, String path) async {
  final root = await workspace.resolveSymbolicLinks();
  final original = File(p.normalize(p.join(root, path)));
  if (await original.exists() || !p.isWithin(root, original.path)) {
    return original;
  }
  final relative = p.relative(original.path, from: root);
  final migrated = agentWorkspaceReference(relative);
  if (relative == migrated) return original;
  final candidate = File(p.join(root, migrated));
  if (!await candidate.exists()) return original;
  final resolved = await candidate.resolveSymbolicLinks();
  if (!p.isWithin(root, resolved)) {
    throw const FormatException('Workspace reference leaves project');
  }
  return File(resolved);
}
