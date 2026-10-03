import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

void main() {
  test(
    'local article lookup normalizes the display name and preserves text',
    () async {
      final dir = await Directory.systemTemp.createTemp('tag_wiki_test_');
      addTearDown(() => dir.delete(recursive: true));
      final path = p.join(dir.path, 'wiki.db');
      final db = sqlite3.open(path);
      db.execute(
        'CREATE TABLE wiki_pages(tag TEXT PRIMARY KEY, body TEXT, source_url TEXT)',
      );
      db.execute(
        "INSERT INTO wiki_pages VALUES ('blue_hair', 'Blue hair description.', 'https://example.com')",
      );
      db.dispose();
      final wiki = AssetTagWikiRepository(() async => path);

      final entry = await wiki.find(' Blue Hair ');
      expect(entry?.tag, 'blue_hair');
      expect(entry?.body, 'Blue hair description.');
      expect(entry?.sourceUrl, 'https://example.com');
      expect(await wiki.find('not_in_wiki'), isNull);
      final batch = await wiki.findAll([' Blue Hair ', 'blue_hair', 'missing']);
      expect(batch.keys, ['blue_hair']);
      expect(batch['blue_hair']?.body, entry?.body);
    },
  );
}
