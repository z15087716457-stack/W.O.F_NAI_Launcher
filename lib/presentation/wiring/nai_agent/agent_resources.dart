import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;

import '../../../core/nai_agent/attachment_image.dart';
import '../../../core/utils/nai_resolution_adapter.dart';
import '../../../data/services/nai_agent/agent_workspace_files.dart';
import '../../../data/services/nai_agent/agent_workspace_store.dart' as store;

/// Local, bounded resources only. Never lets a model-written artifact/backup
/// path bypass the workspace/symlink checks. Failures are cached, not retried
/// on every streaming frame.
class AgentResources {
  AgentResources(this.changed);
  final void Function() changed;
  final _images = <String, MemoryImage?>{};
  final _snapshots = <String, Map<String, dynamic>?>{};
  final _rules = <String, String>{};
  final _pending = <String, Future<void>>{};
  bool _disposed = false;

  void dispose() => _disposed = true;

  Future<void> settle() async {
    while (_pending.isNotEmpty) {
      await Future.wait(_pending.values.toList());
    }
  }

  void _load(String key, Future<void> Function() action) {
    if (_pending.containsKey(key) || _disposed) return;
    _pending[key] = Future<void>.microtask(action)
        .catchError((Object _) {
          // Corrupt/missing resources must not take down an entire conversation.
        })
        .whenComplete(() {
          _pending.remove(key);
          if (!_disposed) changed();
        });
  }

  MemoryImage? image(store.AgentWorkspace workspace, String relative) {
    final key = '${workspace.directory.path}/$relative';
    if (!_images.containsKey(key)) {
      _images[key] = null;
      _load(key, () async {
        _images[key] = await visual(
          await AgentWorkspaceFiles(workspace.directory).read(relative),
        );
      });
    }
    return _images[key];
  }

  MemoryImage? attachment(
    store.AgentWorkspaceStore storage,
    store.AgentWorkspace workspace,
    store.AgentAttachment attachment,
  ) {
    final key = '${workspace.id}/attachment/${attachment.id}';
    if (!_images.containsKey(key)) {
      _images[key] = null;
      _load(key, () async {
        _images[key] = await visual(
          await storage.readAttachment(workspace.id, attachment),
        );
      });
    }
    return _images[key];
  }

  MemoryImage? inline(String id, String data) {
    final key = 'inline/$id/$data';
    if (!_images.containsKey(key)) {
      _images[key] = null;
      _load(key, () async {
        if (data.length > agentAttachmentMaxBytes * 4 ~/ 3 + 4) return;
        _images[key] = await visual(base64Decode(data));
      });
    }
    return _images[key];
  }

  Map<String, dynamic>? snapshot(store.AgentWorkspace workspace, String path) {
    final key = '${workspace.directory.path}/backup/$path';
    if (!_snapshots.containsKey(key)) {
      _snapshots[key] = null;
      _load(key, () async {
        _snapshots[key] = await readAgentDraftBackup(workspace, path);
      });
    }
    return _snapshots[key];
  }

  String rules(store.AgentWorkspace workspace) {
    final key = '${workspace.directory.path}/instructions.md';
    if (!_rules.containsKey(key)) {
      _rules[key] = '';
      _load(key, () async {
        final bytes = await AgentWorkspaceFiles(
          workspace.directory,
        ).read('instructions.md');
        _rules[key] = utf8.decode(bytes);
      });
    }
    return _rules[key]!;
  }

  /// Refresh on returning from settings (instructions.md may have been edited).
  void refreshRules() => _rules.clear();

  static Future<MemoryImage> visual(Uint8List bytes) async {
    final size = NaiResolutionAdapter.readImageSize(bytes);
    final mime = agentImageMime(bytes);
    if (mime == null ||
        bytes.length > agentAttachmentMaxBytes ||
        size == null ||
        size.$1 * size.$2 > agentAttachmentMaxPixels) {
      throw const FormatException('Invalid or oversized Agent image');
    }
    return MemoryImage(await agentAttachmentVisualBytes(bytes, mime));
  }
}

Future<Map<String, dynamic>> readAgentDraftBackup(
  store.AgentWorkspace workspace,
  String path,
) async {
  final candidate = p.normalize(p.absolute(path));
  final roots = [
    p.join(workspace.agentDirectory.path, 'draft-backups'),
    p.join(workspace.directory.path, 'draft-backups'),
  ];
  for (final root in roots) {
    if (!p.isWithin(p.normalize(p.absolute(root)), candidate)) continue;
    final canonicalRoot = await Directory(root).resolveSymbolicLinks();
    final canonicalFile = await File(candidate).resolveSymbolicLinks();
    final workspaceRoot = await workspace.directory.resolveSymbolicLinks();
    if (!p.isWithin(workspaceRoot, canonicalRoot) ||
        !p.isWithin(canonicalRoot, canonicalFile)) {
      break;
    }
    final value = jsonDecode(
      utf8.decode(await AgentWorkspaceFiles.readBounded(File(canonicalFile))),
    );
    if (value is Map<String, dynamic> && value['fields'] is Map) return value;
    throw const FormatException('Invalid draft backup');
  }
  throw const FileSystemException('Draft backup leaves workspace');
}
