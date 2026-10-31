import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../../../core/nai_agent/agent_tool.dart';
import 'agent_workspace_layout.dart';

/// Domain imports/exports stay in the same workspace as Pi's file tools.
class AgentWorkspaceFiles {
  AgentWorkspaceFiles(this.workspace);
  final Directory workspace;
  static const maxBytes = 64 * 1024 * 1024;

  Future<Uint8List> read(String relative) async {
    if (relative.isEmpty || p.isAbsolute(relative)) {
      throw const NaiAgentToolError(
        'path_outside_workspace',
        'Expected a workspace-relative file',
      );
    }
    final root = await workspace.resolveSymbolicLinks();
    final candidate = p.normalize(p.join(root, relative));
    if (!p.isWithin(root, candidate)) {
      throw const NaiAgentToolError(
        'path_outside_workspace',
        'File leaves this workspace',
      );
    }
    final target = await (await agentWorkspaceReadFile(
      Directory(root),
      relative,
    )).resolveSymbolicLinks();
    if (!p.isWithin(root, target)) {
      throw const NaiAgentToolError(
        'path_outside_workspace',
        'File leaves this workspace',
      );
    }
    return readBounded(File(target));
  }

  static Future<Uint8List> readBounded(File file) async {
    if (await file.length() > maxBytes) {
      throw const NaiAgentToolError('file_too_large', 'File exceeds 64 MiB');
    }
    final bytes = await file.readAsBytes();
    if (bytes.length > maxBytes) {
      throw const NaiAgentToolError('file_too_large', 'File exceeds 64 MiB');
    }
    return bytes;
  }

  Future<String> export(
    String name,
    Uint8List bytes,
    void Function() check, {
    Map<String, Uint8List> companions = const {},
  }) async {
    if (name.isEmpty ||
        p.basename(name) != name ||
        name.contains('\\') ||
        name.length > 200 ||
        bytes.length > maxBytes ||
        companions.length > 4 ||
        companions.entries.any(
          (entry) =>
              entry.key == name ||
              entry.key.isEmpty ||
              p.basename(entry.key) != entry.key ||
              entry.key.contains('\\') ||
              entry.key.length > 200 ||
              entry.value.length > maxBytes,
        )) {
      throw const NaiAgentToolError(
        'invalid_export',
        'Invalid export name or file size',
      );
    }
    final root = await workspace.resolveSymbolicLinks();
    final data = agentWorkspaceData(Directory(root));
    if (await FileSystemEntity.type(data.path, followLinks: false) !=
            FileSystemEntityType.notFound &&
        !p.isWithin(root, await data.resolveSymbolicLinks())) {
      throw const NaiAgentToolError(
        'path_outside_workspace',
        'Launcher directory leaves workspace',
      );
    }
    final parent = Directory(p.join(data.path, 'outputs'));
    if ((await parent.exists() ||
            await FileSystemEntity.type(parent.path, followLinks: false) ==
                FileSystemEntityType.link) &&
        !p.isWithin(root, await parent.resolveSymbolicLinks())) {
      throw const NaiAgentToolError(
        'path_outside_workspace',
        'Output directory leaves workspace',
      );
    }
    await parent.create(recursive: true);
    final resolved = await parent.resolveSymbolicLinks();
    if (!p.isWithin(root, resolved)) {
      throw const NaiAgentToolError(
        'path_outside_workspace',
        'Output directory leaves workspace',
      );
    }
    check();
    final directory = Directory(
      p.join(resolved, 'reference-${const Uuid().v4()}'),
    );
    await directory.create();
    final target = await directory.resolveSymbolicLinks();
    if (!p.isWithin(root, target)) {
      throw const NaiAgentToolError(
        'path_outside_workspace',
        'Export leaves workspace',
      );
    }
    check();
    final file = File(p.join(target, name));
    await file.writeAsBytes(bytes, flush: true);
    for (final companion in companions.entries) {
      check();
      await File(
        p.join(target, companion.key),
      ).writeAsBytes(companion.value, flush: true);
    }
    return p.relative(file.path, from: root);
  }
}
