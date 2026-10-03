import 'dart:io';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/autocomplete_providers.dart';
import 'package:nai_launcher/core/autocomplete/zh_dictionary_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/sqlite3.dart' as native;

void main() {
  late Directory temp;
  late ZhDictionaryService service;

  setUp(() async {
    sqfliteFfiInit();
    temp = await Directory.systemTemp.createTemp('zh_dictionary_test_');
    service = ZhDictionaryService();
  });

  tearDown(() async {
    service.dispose();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('validates the upstream tags schema and quick_check', () async {
    final file = _createDictionary('${temp.path}/valid.sqlite', rows: 1000);

    expect(await service.validateDatabaseFile(file.path), 1000);
  });

  test(
    'concurrent cold lookup waits for installed dictionary and remove clears phrase cache',
    () async {
      final folder = Directory(p.join(temp.path, 'autocomplete', 'ffdkj'));
      await folder.create(recursive: true);
      final file = _createDictionary(
        p.join(folder.path, 'tag.sqlite'),
        rows: 1000,
      );
      final db = native.sqlite3.open(file.path);
      db.execute("UPDATE tags SET cn_name = '长发；长头发' WHERE name = 'tag_1'");
      db.dispose();
      final previous = PathProviderPlatform.instance;
      final gate = Completer<String>();
      PathProviderPlatform.instance = _Paths(gate);
      addTearDown(() => PathProviderPlatform.instance = previous);
      final loading = service.initialize();
      final lookup = service.matchInText('把她改成长头发');
      gate.complete(temp.path);
      await loading;
      final hits = await lookup;
      expect(hits.single.candidate.canonicalTag, 'tag_1');
      expect(hits.single.start, 4);
      expect(
        (await service.matchInText('长发')).single.candidate.canonicalTag,
        'tag_1',
      );
      await service.remove();
      expect(await service.matchInText('长发'), isEmpty);
    },
  );

  test(
    'background provider initialization failure is logged and retried later',
    () async {
      final previous = PathProviderPlatform.instance;
      PathProviderPlatform.instance = _FailingPaths();
      addTearDown(() => PathProviderPlatform.instance = previous);
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final provided = container.read(zhDictionaryServiceProvider);
      await pumpEventQueue();
      expect(provided.state.isInstalled, isFalse);
      PathProviderPlatform.instance = _Paths(
        Completer<String>()..complete(temp.path),
      );
      await provided.initialize();
      expect(
        await Directory(p.join(temp.path, 'autocomplete', 'ffdkj')).exists(),
        isTrue,
      );
    },
  );

  test('rejects a corrupt SQLite file', () async {
    final file = File('${temp.path}/corrupt.sqlite');
    await file.writeAsString('not a sqlite database');

    expect(() => service.validateDatabaseFile(file.path), throwsStateError);
  });

  test(
    'rejects a dictionary with an incompatible schema or too few rows',
    () async {
      final wrongSchema = File(p.join(temp.path, 'wrong.sqlite'));
      final db = native.sqlite3.open(wrongSchema.path);
      db.execute('CREATE TABLE tags(name TEXT, cn_name TEXT)');
      db.dispose();
      final tooSmall = _createDictionary('${temp.path}/small.sqlite', rows: 10);

      expect(
        () => service.validateDatabaseFile(wrongSchema.path),
        throwsStateError,
      );
      expect(
        () => service.validateDatabaseFile(tooSmall.path),
        throwsStateError,
      );
    },
  );
}

File _createDictionary(String path, {required int rows}) {
  final db = native.sqlite3.open(path);
  db.execute('''
    CREATE TABLE tags(
      name TEXT PRIMARY KEY,
      category INTEGER,
      cn_name TEXT,
      post_count INTEGER
    )
  ''');
  final statement = db.prepare(
    'INSERT INTO tags(name, category, cn_name, post_count) VALUES (?, ?, ?, ?)',
  );
  db.execute('BEGIN');
  for (var index = 0; index < rows; index++) {
    statement.execute(['tag_$index', 0, '标签$index', rows - index]);
  }
  db.execute('COMMIT');
  statement.dispose();
  db.dispose();
  return File(path);
}

class _Paths extends PathProviderPlatform {
  _Paths(this.gate);
  final Completer<String> gate;
  @override
  Future<String?> getApplicationSupportPath() => gate.future;
}

class _FailingPaths extends PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async =>
      throw StateError('application support directory unavailable');
}
