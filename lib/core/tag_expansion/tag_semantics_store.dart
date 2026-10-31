import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../utils/app_support_directory.dart';
import '../utils/tag_normalizer.dart';

final tagSemanticsStoreProvider = Provider<TagSemanticsStore>((ref) {
  final store = TagSemanticsStore();
  ref.onDispose(() => unawaited(store.close()));
  return store;
});

/// Durable reference data, deliberately outside the disposable translation cache.
/// Only field-level supplements are stored; bundled profiles stay read-only.
class TagSemanticsStore {
  TagSemanticsStore({Future<String> Function()? databasePath})
    : databasePath = databasePath ?? defaultPath;

  final Future<String> Function() databasePath;
  Database? _db;
  Future<Database>? _opening;

  static Future<String> defaultPath() async {
    final support = await getApplicationSupportDirectory();
    final folder = Directory(p.join(support.path, 'tag_semantics'));
    await folder.create(recursive: true);
    return p.join(folder.path, 'supplements.db');
  }

  Future<Database> _open() {
    if (_db case final db?) return Future.value(db);
    return _opening ??=
        () async {
          final db = await databaseFactoryFfi.openDatabase(
            await databasePath(),
            options: OpenDatabaseOptions(
              version: 1,
              onConfigure: (db) async {
                await db.rawQuery('PRAGMA journal_mode=WAL');
                await db.execute('PRAGMA busy_timeout=2000');
              },
              onCreate: (db, _) async {
                await db.execute('''CREATE TABLE tag_semantics(
              tag TEXT PRIMARY KEY, core_zh TEXT NOT NULL,
              synonyms_zh TEXT NOT NULL, summary_zh TEXT NOT NULL,
              wiki_hash TEXT NOT NULL, summary_hash TEXT NOT NULL, prompt_version INTEGER NOT NULL,
              provenance TEXT NOT NULL, updated_at INTEGER NOT NULL)''');
                await db.execute(
                  'CREATE TABLE semantic_state(revision INTEGER NOT NULL)',
                );
                await db.execute('INSERT INTO semantic_state VALUES(0)');
                await db.execute(
                  'CREATE TABLE semantic_changes(tag TEXT PRIMARY KEY, revision INTEGER NOT NULL)',
                );
                await db.execute(
                  '''CREATE TRIGGER semantic_insert AFTER INSERT ON tag_semantics
              WHEN NEW.core_zh!='' OR NEW.synonyms_zh!='[]' OR NEW.summary_zh!='' BEGIN
              UPDATE semantic_state SET revision=revision+1;
              UPDATE semantic_changes SET revision=(SELECT revision FROM semantic_state) WHERE tag=NEW.tag;
              INSERT INTO semantic_changes SELECT NEW.tag,revision FROM semantic_state WHERE NOT EXISTS (SELECT 1 FROM semantic_changes WHERE tag=NEW.tag); END''',
                );
                await db.execute(
                  '''CREATE TRIGGER semantic_update AFTER UPDATE ON tag_semantics
              WHEN OLD.core_zh IS NOT NEW.core_zh OR OLD.synonyms_zh IS NOT NEW.synonyms_zh
                OR OLD.summary_zh IS NOT NEW.summary_zh OR OLD.summary_hash IS NOT NEW.summary_hash BEGIN
              UPDATE semantic_state SET revision=revision+1;
              UPDATE semantic_changes SET revision=(SELECT revision FROM semantic_state) WHERE tag=NEW.tag;
              INSERT INTO semantic_changes SELECT NEW.tag,revision FROM semantic_state WHERE NOT EXISTS (SELECT 1 FROM semantic_changes WHERE tag=NEW.tag); END''',
                );
              },
            ),
          );
          return _db = db;
        }().whenComplete(() {
          _opening = null;
        });
  }

  Future<String> readyPath() async {
    await _open();
    return databasePath();
  }

  static Future<void> _write(
    DatabaseExecutor db,
    Map<String, Object?> row,
  ) async {
    final fields = row.keys.toList();
    await db.rawInsert(
      'INSERT INTO tag_semantics (${fields.join(',')}) VALUES (${List.filled(fields.length, '?').join(',')}) '
      'ON CONFLICT(tag) DO UPDATE SET ${fields.where((k) => k != 'tag').map((k) => '$k=excluded.$k').join(',')}',
      [for (final field in fields) row[field]],
    );
  }

  Future<Map<String, Map<String, Object?>>> findAll(
    Iterable<String> tags,
  ) async {
    final names = tags
        .map(TagNormalizer.normalize)
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList();
    if (names.isEmpty) return const {};
    final db = await _open();
    final result = <String, Map<String, Object?>>{};
    for (var offset = 0; offset < names.length; offset += 400) {
      final batch = names.skip(offset).take(400).toList();
      for (final row in await db.query(
        'tag_semantics',
        where: 'tag IN (${List.filled(batch.length, '?').join(',')})',
        whereArgs: batch,
      )) {
        result[row['tag'] as String] = row;
      }
    }
    return result;
  }

  static Map<String, Object?> validate(Map<String, Object?> value) {
    final tag = value['tag'];
    final core = value['core_zh'];
    final terms = value['synonyms_zh'];
    final summary = value['summary_zh'];
    bool plain(Object? text, int max) =>
        text is String &&
        text.runes.length <= max &&
        !text.contains(RegExp(r'[\r\n\x00]'));
    if (tag is! String ||
        tag.isEmpty ||
        tag.length > 512 ||
        TagNormalizer.normalize(tag) != tag ||
        !plain(core, 64) ||
        !plain(summary, 240) ||
        terms is! List ||
        terms.length > 16 ||
        terms.any((t) => !plain(t, 64) || (t as String).trim().isEmpty)) {
      throw const FormatException('Invalid tag semantic profile');
    }
    final words = <String>{
      if ((core as String).trim().isNotEmpty) core.trim(),
      ...terms.cast<String>().map((t) => t.trim()),
    }.toList();
    if (words.length > 16) {
      throw const FormatException('Too many Chinese synonyms');
    }
    return {
      'tag': tag,
      'core_zh': core.trim(),
      'synonyms_zh': jsonEncode(words),
      'summary_zh': (summary as String).trim(),
    };
  }

  Future<void> put({
    required String tag,
    required String coreZh,
    required List<String> synonymsZh,
    required String summaryZh,
    required String wikiHash,
    required int promptVersion,
    required String provenance,
    bool replace = false,
  }) async {
    final fields = validate({
      'tag': tag,
      'core_zh': coreZh,
      'synonyms_zh': synonymsZh,
      'summary_zh': summaryZh,
    });
    fields['summary_hash'] = summaryZh.isEmpty ? '' : wikiHash;
    final db = await _open();
    await db.transaction((txn) async {
      final old = await txn.query(
        'tag_semantics',
        where: 'tag=?',
        whereArgs: [tag],
        limit: 1,
      );
      if (!replace && old.isNotEmpty) {
        for (final key in ['core_zh', 'synonyms_zh', 'summary_zh']) {
          final prior = old.single[key] as String;
          if (key == 'synonyms_zh') {
            fields[key] = jsonEncode(
              <String>{
                ...(jsonDecode(prior) as List).cast<String>(),
                ...(jsonDecode(fields[key] as String) as List).cast<String>(),
              }.take(16).toList(),
            );
            continue;
          }
          if (key == 'summary_zh' && prior.isNotEmpty) {
            if (fields[key] == '' || old.single['summary_hash'] == wikiHash) {
              fields[key] = prior;
              fields['summary_hash'] = old.single['summary_hash'];
            }
            continue;
          }
          if (prior.isNotEmpty && prior != '[]') fields[key] = prior;
        }
      }
      await _write(txn, {
        ...fields,
        'wiki_hash': wikiHash,
        'prompt_version': promptVersion,
        'provenance': provenance,
        'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
      });
    });
  }

  Future<bool> attempted(String tag, String wikiHash, int promptVersion) async {
    final row = (await findAll([tag]))[tag];
    return row?['wiki_hash'] == wikiHash &&
        row?['prompt_version'] == promptVersion;
  }

  Future<String> exportJson() async {
    final rows = await (await _open()).query('tag_semantics', orderBy: 'tag');
    return jsonEncode({
      'schema': 'wof.tag-semantics',
      'version': 1,
      'profiles': [
        for (final row in rows)
          {...row, 'synonyms_zh': jsonDecode(row['synonyms_zh'] as String)},
      ],
    });
  }

  /// Validate the whole file before a transaction; imports fill gaps and never
  /// overwrite a newer local field. Keep a durable pre-import snapshot.
  Future<void> importJson(String raw) async {
    if (raw.length > 32 * 1024 * 1024) {
      throw const FormatException('Semantic supplement is too large');
    }
    final value = jsonDecode(raw);
    if (value is! Map ||
        value['schema'] != 'wof.tag-semantics' ||
        value['version'] != 1 ||
        value['profiles'] is! List) {
      throw const FormatException('Unsupported semantic supplement');
    }
    final rows = <Map<String, Object?>>[];
    for (final item in value['profiles'] as List) {
      final row = Map<String, Object?>.from(item as Map);
      final hash = row['wiki_hash'];
      final version = row['prompt_version'];
      final summaryHash = row['summary_hash'] ?? hash;
      if (hash is! String ||
          !RegExp(r'^(?:[a-f0-9]{64})?$').hasMatch(hash) ||
          summaryHash is! String ||
          !RegExp(r'^(?:[a-f0-9]{64})?$').hasMatch(summaryHash) ||
          version is! int ||
          version < 0) {
        throw const FormatException('Invalid semantic provenance');
      }
      rows.add({
        ...validate(row),
        'wiki_hash': hash,
        'summary_hash': summaryHash,
        'prompt_version': version,
      });
    }
    final db = await _open();
    final backup = File(
      '${await databasePath()}.before-import-${DateTime.now().microsecondsSinceEpoch}.json',
    );
    await backup.writeAsString(await exportJson(), flush: true);
    await db.transaction((txn) async {
      for (final row in rows) {
        final old = await txn.query(
          'tag_semantics',
          where: 'tag=?',
          whereArgs: [row['tag']],
          limit: 1,
        );
        if (old.isNotEmpty) {
          for (final field in ['core_zh', 'synonyms_zh', 'summary_zh']) {
            if (field == 'synonyms_zh') {
              row[field] = jsonEncode(
                <String>{
                  ...(jsonDecode(old.single[field] as String) as List)
                      .cast<String>(),
                  ...(jsonDecode(row[field] as String) as List).cast<String>(),
                }.take(16).toList(),
              );
              continue;
            }
            if (old.single[field] != '' && old.single[field] != '[]') {
              row[field] = old.single[field];
              if (field == 'summary_zh') {
                row['summary_hash'] = old.single['summary_hash'];
              }
            }
          }
        }
        await _write(txn, {
          ...row,
          'wiki_hash': old.firstOrNull?['wiki_hash'] ?? row['wiki_hash'],
          'prompt_version':
              old.firstOrNull?['prompt_version'] ?? row['prompt_version'],
          'provenance': 'import',
          'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
        });
      }
    });
  }

  Future<void> close() async {
    if (_opening case final pending?) await pending;
    await _db?.close();
    _db = null;
  }
}
