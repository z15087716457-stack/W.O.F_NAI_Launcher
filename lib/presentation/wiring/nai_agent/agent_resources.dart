import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:isolate';

import 'package:image/image.dart' as img;

import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;

import '../../../core/nai_agent/attachment_image.dart';
import '../../../core/nai_agent/prompt_set_tools.dart';
import '../../../core/utils/nai_resolution_adapter.dart';
import '../../../data/services/nai_agent/agent_workspace_files.dart';
import '../../../data/services/nai_agent/agent_workspace_store.dart' as store;

/// Local, bounded resources only. Never lets a model-written artifact/backup
/// path bypass the workspace/symlink checks. Failures are cached, not retried
/// on every streaming frame.
class AgentResources {
  AgentResources(this.changed);
  final void Function() changed;

  /// Injected native gallery loader, not a model/image_read invocation.
  Future<Uint8List?> Function(String id)? galleryLoader;
  final _gallery = <String, MemoryImage?>{};
  Future<void> _galleryTail = Future.value();
  final _images = <String, MemoryImage?>{};
  final _promptSets = <String, Map<String, dynamic>?>{};
  final _setRevisions = <String, int>{};
  final _setWatchers = <String, StreamSubscription<FileSystemEvent>>{};
  final _snapshots = <String, Map<String, dynamic>?>{};
  final _rules = <String, String>{};
  final _files = <String, (String, int)?>{};
  final _pending = <String, Future<void>>{};
  bool _disposed = false;
  int revision = 0;

  void dispose() {
    _disposed = true;
    for (final watcher in _setWatchers.values) {
      unawaited(watcher.cancel());
    }
  }

  void refreshPromptSets() {
    revision++;
    _promptSets.clear();
  }

  Map<String, dynamic>? promptSet(
    store.AgentWorkspace workspace,
    String setId, {
    int? revision,
  }) {
    if (!NaiAgentPromptSets.idPattern.hasMatch(setId)) return null;
    final key = '${workspace.agentDirectory.path}/prompt-sets/$setId.json';
    if (revision != null && _setRevisions[key] != revision) {
      _setRevisions[key] = revision;
      _promptSets.remove(key);
    }
    if (!_promptSets.containsKey(key)) {
      _promptSets[key] = null;
      _load('set/$key', () async {
        _promptSets[key] = await NaiAgentPromptSets(
          workspace.agentDirectory,
        ).read(setId);
        // null was cached before loading; revision changes invalidate it.
        final dir = Directory(p.dirname(key));
        if (!_setWatchers.containsKey(dir.path) &&
            await dir.exists() &&
            !_disposed) {
          _setWatchers[dir.path] = dir.watch().listen(
            (event) {
              if (!event.path.endsWith('.json') &&
                  !(event is FileSystemMoveEvent &&
                      (event.destination?.endsWith('.json') ?? false))) {
                return;
              }
              _promptSets.clear();
              if (!_disposed) changed();
            },
            onError: (Object _) {
              /* Explicit tool/action refresh remains available. */
            },
          );
        }
      });
    }
    return _promptSets[key];
  }

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
          revision++;
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

  MemoryImage? gallery(String id) {
    if (!RegExp(r'^gallery:[1-9]\d*$').hasMatch(id) || galleryLoader == null) {
      return null;
    }
    if (!_gallery.containsKey(id)) {
      // A conversation can reference arbitrarily many images. Keep at most 64
      // small previews (including failed lookups) and avoid streaming reloads.
      if (_gallery.length >= 64) return null;
      _gallery[id] = null;
      final loader = galleryLoader!;
      _load('gallery/$id', () {
        final task = _galleryTail.then((_) async {
          if (_disposed) return;
          final bytes = await loader(id);
          if (bytes == null || bytes.length > 64 * 1024 * 1024) return;
          final size = NaiResolutionAdapter.readImageSize(bytes);
          if (size == null || size.$1 * size.$2 > agentAttachmentMaxPixels) {
            return;
          }
          final preview = await _galleryVisual(bytes);
          if (preview != null) _gallery[id] = MemoryImage(preview);
        });
        _galleryTail = task.catchError((Object _) {});
        return task;
      });
    }
    return _gallery[id];
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

  (String, int)? file(store.AgentWorkspace workspace, String path) {
    final key = '${workspace.directory.path}/file/$path';
    if (!_files.containsKey(key)) {
      _files[key] = null;
      _load(key, () async {
        final root = await workspace.directory.resolveSymbolicLinks();
        final candidate = p.isAbsolute(path) ? path : p.join(root, path);
        final canonical = await File(candidate).resolveSymbolicLinks();
        if (!p.isWithin(root, canonical)) return;
        final file = File(canonical);
        if (!await file.exists()) return;
        _files[key] = (p.relative(canonical, from: root), await file.length());
      });
    }
    return _files[key];
  }

  /// Refresh on returning from settings (instructions.md may have been edited).
  void refreshRules() => _rules.clear();

  // Static boundary keeps the resource cache and its pending Futures out of
  // the isolate closure's captured context.
  static Future<Uint8List?> _galleryVisual(Uint8List bytes) => Isolate.run(() {
    final decoded = img.decodeImage(bytes, frame: 0);
    if (decoded == null) return null;
    final small = decoded.width <= 320 && decoded.height <= 320
        ? decoded
        : img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? 320 : null,
            height: decoded.height > decoded.width ? 320 : null,
          );
    return Uint8List.fromList(img.encodePng(small));
  });

  static Future<MemoryImage> visual(Uint8List bytes) async {
    final size = NaiResolutionAdapter.readImageSize(bytes);
    final mime = agentImageMime(bytes);
    if (mime == null ||
        bytes.length > agentAttachmentMaxBytes ||
        size == null ||
        size.$1 * size.$2 > agentAttachmentMaxPixels) {
      throw const FormatException('Invalid or oversized Agent image');
    }
    // Validate the full payload before the UI's zoom viewer (which deliberately
    // has no provider/error handling). A valid header alone is not an image.
    final valid = await Isolate.run(
      () => img.decodeImage(bytes, frame: 0) != null,
    );
    if (!valid) throw const FormatException('Corrupt Agent image');
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
