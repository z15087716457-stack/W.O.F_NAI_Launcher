import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:csv/csv.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' show sqfliteFfiInit;

import 'dictionary_data_store.dart';

Future<Map<String, int>> buildDictionaryInBackground(
  Map<String, Object> args,
) => Isolate.run(() => buildDictionary(args));

void checkDictionaryCancellation(String flag) {
  if (File(flag).existsSync()) throw StateError('dictionary_cancelled');
}

/// Runs in an isolate. The input is already pinned, sized and SHA256-verified.
Future<Map<String, int>> buildDictionary(Map<String, Object> args) async {
  sqfliteFfiInit();
  final kind = DictionaryKind.values.byName(args['kind'] as String);
  final input = args['input'] as String;
  final output = args['output'] as String;
  final flag = args['cancel'] as String;
  final progress = args['progress'] as SendPort;
  checkDictionaryCancellation(flag);
  await File(args['seed'] as String).copy(output);
  final db = sqlite3.open(output);
  final table = kind == DictionaryKind.tags ? 'tags' : 'wiki_pages';
  int count() =>
      db.select('SELECT COUNT(*) AS n FROM $table').first['n'] as int;
  final before = count();
  var processed = 0, accepted = 0, updated = 0;
  final statements = <PreparedStatement>[];
  PreparedStatement prepare(String sql) {
    final result = db.prepare(sql);
    statements.add(result);
    return result;
  }

  Future<void> tick() async {
    if (++processed % 1000 != 0) return;
    progress.send(processed);
    await Future<void>.delayed(Duration.zero);
    checkDictionaryCancellation(flag);
  }

  try {
    db.execute('PRAGMA journal_mode=DELETE');
    db.execute('BEGIN IMMEDIATE');
    if (kind == DictionaryKind.tags) {
      final insert = prepare(
        'INSERT INTO tags(name,category,post_count) VALUES(?,?,?) '
        'ON CONFLICT(name) DO UPDATE SET post_count=MAX(tags.post_count,excluded.post_count)',
      );
      final find = prepare('SELECT id,post_count FROM tags WHERE name=?');
      final alias = prepare(
        'INSERT OR IGNORE INTO aliases(tag_id,alias) VALUES(?,?)',
      );
      final rows = const CsvToListConverter(
        shouldParseNumbers: false,
        eol: '\n',
      ).convert(await File(input).readAsString());
      for (final row in rows) {
        await tick();
        if (row.length != 4) throw const FormatException('dictionary_schema');
        final name = '${row[0]}'.trim().toLowerCase();
        final category = int.tryParse('${row[1]}');
        final uses = int.tryParse('${row[2]}');
        if (!_validTag(name) ||
            !const {0, 1, 3, 4, 5}.contains(category) ||
            uses == null ||
            uses < 0) {
          throw const FormatException('dictionary_schema');
        }
        final previous = find.select([name]);
        var changed =
            previous.isNotEmpty && uses > (previous.first['post_count'] as int);
        insert.execute([name, category, uses]);
        final id = find.select([name]).first['id'];
        for (final term in '${row[3]}'.split(',')) {
          final normalized = term.trim().toLowerCase();
          if (normalized != name && _validTag(normalized)) {
            alias.execute([id, normalized]);
            if (db.updatedRows > 0) changed = true;
          }
        }
        if (previous.isNotEmpty && changed) updated++;
        accepted++;
      }
      checkDictionaryCancellation(flag);
      // Rebuild from all tags and aliases, retaining existing e621 categories.
      db.execute('DELETE FROM tag_search');
      db.execute(
        "INSERT INTO tag_search(term,search_key,tag_id,kind) "
        "SELECT name,replace(name,'_',' '),id,0 FROM tags",
      );
      db.execute(
        "INSERT INTO tag_search(term,search_key,tag_id,kind) "
        "SELECT alias,replace(alias,'_',' '),tag_id,1 FROM aliases",
      );
      db.execute("INSERT INTO tag_search(tag_search) VALUES('optimize')");
    } else {
      final previous = prepare(
        'SELECT body,source_url FROM wiki_pages WHERE tag=?',
      );
      final insert = prepare(
        'INSERT INTO wiki_pages(tag,body,source_url) VALUES(?,?,?) '
        'ON CONFLICT(tag) DO UPDATE SET body=excluded.body,source_url=excluded.source_url '
        'WHERE wiki_pages.body!=excluded.body OR wiki_pages.source_url!=excluded.source_url',
      );
      final seen = <String, ({DateTime? at, bool existed})>{};
      final changedArticles = <String>{};
      await for (final line in File(
        input,
      ).openRead().transform(utf8.decoder).transform(const LineSplitter())) {
        await tick();
        if (line.trim().isEmpty) continue;
        if (line.length > 2 * 1024 * 1024) {
          throw const FormatException('dictionary_schema');
        }
        final value = jsonDecode(line);
        if (value is! Map || value['is_deleted'] is! bool) {
          throw const FormatException('dictionary_schema');
        }
        if (value['is_deleted'] == true) continue;
        if (value['title'] is! String || value['body'] is! String) {
          throw const FormatException('dictionary_schema');
        }
        final name = (value['title'] as String).trim().toLowerCase().replaceAll(
          ' ',
          '_',
        );
        final body = (value['body'] as String).trim();
        if (name.isEmpty ||
            name.length > 255 ||
            name.contains(RegExp(r'[\x00-\x1f]')) ||
            body.isEmpty) {
          continue;
        }
        final stamp = value['updated_at'] is String
            ? DateTime.tryParse(value['updated_at'] as String)
            : null;
        final prior = seen[name];
        // Public snapshots can repeat normalized titles. Prefer
        // the newest dated article; equal/unknown dates retain the first row.
        if (prior != null &&
            (stamp == null ||
                (prior.at != null && !stamp.isAfter(prior.at!)))) {
          continue;
        }
        final url =
            'https://danbooru.donmai.us/wiki_pages/${Uri.encodeComponent(name)}';
        final old = previous.select([name]);
        final existed = prior?.existed ?? old.isNotEmpty;
        seen[name] = (at: stamp, existed: existed);
        if (existed &&
            old.isNotEmpty &&
            (old.first['body'] != body || old.first['source_url'] != url)) {
          changedArticles.add(name);
        }
        insert.execute([name, body, url]);
        accepted++;
      }
      updated = changedArticles.length;
    }
    checkDictionaryCancellation(flag);
    if (accepted == 0) throw const FormatException('dictionary_empty');
    final total = count();
    db.execute('INSERT OR REPLACE INTO metadata(key,value) VALUES(?,?)', [
      'data_version',
      args['version'],
    ]);
    if (kind == DictionaryKind.tags) {
      db.execute('INSERT OR REPLACE INTO metadata(key,value) VALUES(?,?)', [
        'tag_count',
        '$total',
      ]);
      final aliases = db.select('SELECT COUNT(*) AS n FROM aliases').first['n'];
      db.execute('INSERT OR REPLACE INTO metadata(key,value) VALUES(?,?)', [
        'alias_count',
        '$aliases',
      ]);
    }
    db.execute('COMMIT');
    checkDictionaryCancellation(flag);
    return {
      'count': total,
      'added': total - before,
      'updated': updated,
      'processed': processed,
    };
  } catch (_) {
    try {
      db.execute('ROLLBACK');
    } catch (_) {}
    rethrow;
  } finally {
    for (final statement in statements) {
      statement.dispose();
    }
    db.dispose();
  }
}

bool _validTag(String value) =>
    value.isNotEmpty &&
    value.length <= 255 &&
    !value.contains(RegExp(r'[\u0000-\u001f,]'));
