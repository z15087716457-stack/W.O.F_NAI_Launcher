import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Self-contained, explicitly saved configuration files. Listing reads small
/// sidecars rather than decoding all source/reference images in every snapshot.
class AgentSnapshotFiles {
  AgentSnapshotFiles(this.workspace);
  final Directory workspace;
  static const maxBytes = 256 * 1024 * 1024;
  static final _idPattern = RegExp(r'^[0-9a-fA-F-]{36}$');

  Future<Directory> _directory(String name) async {
    final root = await workspace.resolveSymbolicLinks();
    final directory = Directory(p.join(root, name));
    var ancestor = directory;
    while (!await ancestor.exists()) {
      ancestor = ancestor.parent;
    }
    final existing = await ancestor.resolveSymbolicLinks();
    if (existing != root && !p.isWithin(root, existing)) {
      throw const FormatException('Snapshot directory leaves workspace');
    }
    await directory.create(recursive: true);
    final target = await directory.resolveSymbolicLinks();
    if (!p.isWithin(root, target)) {
      throw const FormatException('Snapshot directory leaves workspace');
    }
    return Directory(target);
  }

  Future<Map<String, dynamic>> save(
    String name,
    Map<String, dynamic> snapshot, {
    bool backup = false,
  }) async {
    if (name.trim().isEmpty || name.length > 200) {
      throw const FormatException(
        'Snapshot name must contain 1 to 200 characters',
      );
    }
    final dir = await _directory(
      backup ? '.agent/snapshot-backups' : 'snapshots',
    );
    final id = const Uuid().v4();
    final metadata = {
      'id': id,
      'name': name.trim(),
      'created_at': DateTime.now().toIso8601String(),
      'schema': 2,
    };
    final text = await Isolate.run(
      () => jsonEncode({...metadata, 'generation': snapshot}),
    );
    if (utf8.encode(text).length > maxBytes) {
      throw const FormatException('Snapshot exceeds 256 MiB');
    }
    final file = File(p.join(dir.path, '$id.json'));
    await _atomic(file, text);
    if (!backup) {
      await _atomic(
        File(p.join(dir.path, '$id.meta.json')),
        jsonEncode(metadata),
      );
    }
    return {...metadata, 'path': file.path};
  }

  Future<List<Map<String, dynamic>>> list({
    int offset = 0,
    int limit = 20,
  }) async {
    final directory = await _directory('snapshots');
    final entries = (await directory.list(followLinks: false).toList())
        .whereType<File>()
        .where((f) => f.path.endsWith('.meta.json'))
        .toList();
    final found = <Map<String, dynamic>>[];
    for (final file in entries) {
      if (await file.length() > 16384) continue;
      try {
        final value = Map<String, dynamic>.from(
          jsonDecode(await file.readAsString()) as Map,
        );
        if (value['schema'] == 2 &&
            value['id'] is String &&
            value['name'] is String &&
            value['created_at'] is String &&
            DateTime.tryParse(value['created_at'] as String) != null &&
            _idPattern.hasMatch(value['id'] as String) &&
            p.basename(file.path) == '${value['id']}.meta.json') {
          found.add(value);
        }
      } on FormatException {
        /* A damaged sidecar does not hide other snapshots. */
      } on TypeError {
        /* A malformed JSON shape is also a damaged sidecar. */
      }
    }
    found.sort(
      (a, b) =>
          (b['created_at'] as String).compareTo(a['created_at'] as String),
    );
    return found.skip(offset).take(limit).toList();
  }

  Future<Map<String, dynamic>> read(String id) async {
    if (!_idPattern.hasMatch(id)) {
      throw const FormatException('Invalid snapshot ID');
    }
    final directory = await _directory('snapshots');
    final file = File(p.join(directory.path, '$id.json'));
    final path = await file.resolveSymbolicLinks();
    if (!p.isWithin(directory.path, path)) {
      throw const FormatException('Snapshot leaves workspace');
    }
    if (await File(path).length() > maxBytes) {
      throw const FormatException('Snapshot exceeds 256 MiB');
    }
    final text = await File(path).readAsString();
    final value = await Isolate.run(
      () => Map<String, dynamic>.from(jsonDecode(text) as Map),
    );
    if (value['schema'] != 2 ||
        value['id'] != id ||
        value['generation'] is! Map) {
      throw const FormatException('Invalid generation snapshot');
    }
    return value;
  }

  Future<void> _atomic(File file, String text) async {
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(text, flush: true);
    await temporary.rename(file.path);
  }
}
