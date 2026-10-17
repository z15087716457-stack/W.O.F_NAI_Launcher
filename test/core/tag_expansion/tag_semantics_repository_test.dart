import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/tag_expansion/tag_semantics_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() {
  test(
    'reads imported Chinese synonyms and summary without changing the asset',
    () async {
      final file = File('assets/databases/tag_semantics.db');
      final before = sha256.convert(await file.readAsBytes());
      final repository = TagSemanticsRepository(() async => file.absolute.path);
      final grass = await repository.find(' Grass ');
      expect(grass?.tag, 'grass');
      expect(grass?.coreZh, '草地');
      expect(grass?.synonymsZh, ['草地', '草', '户外', '自然']);
      expect(grass?.summaryZh, contains('植物'));
      expect(grass?.sourceCategory, 0);
      expect(await repository.find('tag_not_in_this_supplement'), isNull);
      expect(await repository.find('22/7 音乐的时间'), isNull);
      expect(await repository.find('7月22日'), isNull);
      expect(sha256.convert(await file.readAsBytes()), before);
    },
  );

  test('missing upstream summary is left empty', () async {
    final repository = TagSemanticsRepository(
      () async => File('assets/databases/tag_semantics.db').absolute.path,
    );
    final profile = await repository.find(
      'agnes_digital_(fanatic_jiangshi)_(umamusume)',
    );
    expect(profile?.synonymsZh, isNotEmpty);
    expect(profile?.summaryZh, isEmpty);
  });

  test('empty lookup does not initialize databases', () async {
    final repository = TagSemanticsRepository(
      () async => throw StateError('opened'),
    );
    expect(await repository.findAll([' ', '']), isEmpty);
  });

  test(
    'batch lookup crosses SQLite parameter budgets and treats input as data',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'tag_semantics_test_',
      );
      addTearDown(() => directory.delete(recursive: true));
      final path = p.join(directory.path, 'profiles.db');
      final db = sqlite3.open(path);
      db.execute('''CREATE TABLE tag_semantics(
      tag TEXT PRIMARY KEY, synonyms_zh TEXT, core_zh TEXT, summary_zh TEXT,
      category INTEGER, source_post_count INTEGER
    )''');
      final statement = db.prepare(
        'INSERT INTO tag_semantics VALUES(?,?,?,?,?,?)',
      );
      for (var i = 0; i < 1001; i++) {
        statement.execute(['tag_$i', '["示例"]', '示例', '示例说明', 0, i]);
      }
      statement.dispose();
      db.dispose();
      final file = File(path);
      final before = sha256.convert(await file.readAsBytes());
      final repository = TagSemanticsRepository(() async => path);
      final profiles = await repository.findAll([
        for (var i = 0; i < 1001; i++) 'tag_$i',
        'TAG_1000',
        "' OR 1=1 --",
      ]);
      expect(profiles.length, 1001);
      expect(profiles['tag_1000']?.sourcePostCount, 1000);
      expect(sha256.convert(await file.readAsBytes()), before);
    },
  );
}
