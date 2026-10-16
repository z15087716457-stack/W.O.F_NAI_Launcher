import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show sqfliteFfiInit;

enum DictionaryKind { tags, wiki }

/// Immutable databases and commit records live outside bundled asset installs.
/// Publishing a unique commit file is the only activation step; failed jobs
/// never modify a database already used by readers.
class DictionaryDataStore {
  DictionaryDataStore(this.root);
  final Directory root;
  final _active = <DictionaryKind, Map<String, dynamic>>{};
  String? activePath(DictionaryKind kind) => _active[kind]?['path'] as String?;
  Map<String, dynamic>? record(DictionaryKind kind) => _active[kind];

  Future<String> resolve(DictionaryKind kind, String bundled) async {
    if (!await root.exists()) return bundled;
    final commits = await root
        .list()
        .where(
          (e) =>
              e is File &&
              p.basename(e.path).startsWith('commit-${kind.name}-') &&
              e.path.endsWith('.json'),
        )
        .cast<File>()
        .toList();
    commits.sort((a, b) => b.path.compareTo(a.path));
    for (final commit in commits) {
      try {
        final data =
            jsonDecode(await commit.readAsString()) as Map<String, dynamic>;
        final hash = data['sha256'] as String;
        if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(hash) ||
            data['kind'] != kind.name) {
          continue;
        }
        final file = File(p.join(root.path, '$hash.db'));
        if (await file.length() != data['bytes'] ||
            (await sha256.bind(file.openRead()).first).toString() != hash) {
          continue;
        }
        final count = await validateDictionaryInBackground(file.path, kind);
        if (count != data['count']) continue;
        _active[kind] = {...data, 'path': file.path};
        return file.path;
      } catch (_) {
        // A corrupt or interrupted newest revision falls back to an older one.
      }
    }
    _active.remove(kind);
    return bundled;
  }

  Future<void> publish(
    DictionaryKind kind,
    File staged,
    Map<String, dynamic> metadata, {
    required String? expectedPath,
  }) async {
    if (activePath(kind) != expectedPath) {
      throw StateError('dictionary_changed');
    }
    final count = await validateDictionaryInBackground(staged.path, kind);
    if (count != metadata['count']) throw StateError('dictionary_integrity');
    final hash = (await sha256.bind(staged.openRead()).first).toString();
    await root.create(recursive: true);
    final target = File(p.join(root.path, '$hash.db'));
    if (await target.exists()) {
      if ((await sha256.bind(target.openRead()).first).toString() != hash) {
        throw StateError('dictionary_integrity');
      }
      await staged.delete();
    } else {
      await staged.rename(target.path);
    }
    final data = {
      ...metadata,
      'kind': kind.name,
      'sha256': hash,
      'bytes': await target.length(),
    };
    final name =
        'commit-${kind.name}-${DateTime.now().toUtc().microsecondsSinceEpoch}';
    final pending = File(p.join(root.path, '$name.pending'));
    await pending.writeAsString(jsonEncode(data), flush: true);
    if (activePath(kind) != expectedPath) {
      await pending.delete();
      throw StateError('dictionary_changed');
    }
    await pending.rename(p.join(root.path, '$name.json'));
    _active[kind] = {...data, 'path': target.path};
  }
}

Future<int> validateDictionaryInBackground(String path, DictionaryKind kind) =>
    Isolate.run(() => validateDictionary(path, kind));

int validateDictionary(String path, DictionaryKind kind) {
  sqfliteFfiInit();
  final db = sqlite3.open(path, mode: OpenMode.readOnly);
  try {
    if (db.select('PRAGMA quick_check').first.values.first != 'ok') {
      throw StateError('dictionary_integrity');
    }
    final required = kind == DictionaryKind.tags
        ? {
            'tags': {'id', 'name', 'category', 'post_count'},
            'aliases': {'tag_id', 'alias'},
            'tag_search': {'term', 'search_key', 'tag_id', 'kind'},
          }
        : {
            'wiki_pages': {'tag', 'body', 'source_url'},
          };
    for (final entry in required.entries) {
      final columns = db
          .select('PRAGMA table_info("${entry.key}")')
          .map((r) => r['name'] as String)
          .toSet();
      if (!columns.containsAll(entry.value)) {
        throw StateError('dictionary_schema');
      }
    }
    final table = kind == DictionaryKind.tags ? 'tags' : 'wiki_pages';
    return db.select('SELECT COUNT(*) AS n FROM $table').first['n'] as int;
  } finally {
    db.dispose();
  }
}
