import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/autocomplete/tag_catalog_repository.dart';
import 'package:nai_launcher/core/autocomplete/unified_tag_repository.dart';
import 'package:nai_launcher/core/tag_expansion/local_tag_expansion_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  final path = File('assets/databases/tag_catalog.db').absolute.path;
  final catalog = TagCatalogRepository(path: () async => path);
  final tags = UnifiedTagRepository(
    catalog: catalog,
    runtime: () async => throw UnimplementedError(),
    unionDatabase: ({required includeWiki}) => databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
    ),
  );
  final service = LocalTagExpansionService(
    catalog: catalog,
    relatedTags: catalog,
    substringSearch: catalog.searchContains,
    popularSearch: catalog.popular,
    spellingSearch: tags.spellingSuggestions,
  );
  tearDownAll(catalog.dispose);
  for (final (input, canonical) in [
    ('bule eyes', 'blue_eyes'),
    ('long hiar', 'long_hair'),
    ('silvre hair', 'grey_hair'),
    ('ble eyes', 'blue_eyes'),
    ('blue eyess', 'blue_eyes'),
    ('blue  eyes', 'blue_eyes'),
    ('blxe eyes', 'blue_eyes'),
  ]) {
    test('bundled catalog completes $input as $canonical', () async {
      final hits = await service.search(
        input,
        locale: 'en',
        suggestSpelling: true,
      );
      final corrections = hits.where(
        (c) => c.matchKind == CompletionMatchKind.spelling,
      );
      expect(corrections.length, inInclusiveRange(1, 3));
      expect(hits.first.canonicalTag, canonical);
      expect(hits.first.matchKind, CompletionMatchKind.spelling);
      expect(hits.where((c) => c.canonicalTag == canonical), hasLength(1));
      if (input == 'silvre hair') {
        expect(hits.first.matchedAlias, 'silver_hair');
      }
      if (input == 'ble eyes') {
        expect(hits.length, greaterThan(corrections.length));
      }
    });
  }
  test('normal names, prefixes and aliases keep ordinary completion', () async {
    for (final input in ['blue e', 'blue eyes', 'silver hair', 'silver hai']) {
      final hits = await service.search(
        input,
        locale: 'en',
        suggestSpelling: true,
      );
      expect(hits, isNotEmpty, reason: input);
      expect(
        hits.any((c) => c.matchKind == CompletionMatchKind.spelling),
        false,
        reason: input,
      );
    }
  });
  test('explicit tag search and unsupported input skip spelling', () async {
    final hits = await service.search('bule eyes', locale: 'en');
    expect(hits.any((c) => c.matchKind == CompletionMatchKind.spelling), false);
    for (final token in ['xyz', '蓝眼睛', '1234', 'unmatched/word', 'word' * 13]) {
      expect(await tags.spellingSuggestions(token), isEmpty, reason: token);
    }
  });
}
