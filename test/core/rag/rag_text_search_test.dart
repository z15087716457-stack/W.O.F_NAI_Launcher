import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/rag/rag_block_snapshot.dart';
import 'package:nai_launcher/core/rag/rag_settings.dart';
import 'package:nai_launcher/core/rag/rag_text_search.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';

void main() {
  test('legacy preferences leave new collections opt-in', () {
    final settings = RagSettings.fromJson({
      'version': 1,
      'enabled': true,
      'tagsEnabled': false,
    });
    expect(settings.enabledFor(RagSource.tags), isFalse);
    expect(settings.wikiEnabled, isFalse);
    expect(settings.blocksEnabled, isFalse);
    expect(settings.galleryEnabled, isFalse);
    final updated = settings.copyWith(
      wikiEnabled: true,
      blocksEnabled: true,
      galleryEnabled: true,
    );
    final restored = RagSettings.fromJson(updated.toJson());
    expect(restored.enabledFor(RagSource.wiki), isTrue);
    expect(restored.enabledFor(RagSource.blocks), isTrue);
    expect(restored.enabledFor(RagSource.gallery), isTrue);
    expect(settings.connectionKey, isNot(updated.connectionKey));
  });
  test('query identity includes the source and the actual scope', () {
    final a = RagTextQuery(
      source: RagSource.blocks,
      query: 'rain',
      allowed: ['b', 'a', 'a'],
    );
    final b = RagTextQuery(
      source: RagSource.blocks,
      query: 'rain',
      allowed: ['a', 'b'],
    );
    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(
      a,
      isNot(
        RagTextQuery(
          source: RagSource.wiki,
          query: 'rain',
          allowed: ['a', 'b'],
        ),
      ),
    );
    expect(
      RagTextQuery(source: RagSource.blocks, query: 'rain', allowed: []),
      isNot(RagTextQuery(source: RagSource.blocks, query: 'rain')),
    );
  });
  test(
    'snapshot includes saved text and excludes private paths, images and archived records',
    () {
      final block = PromptBlock.create(
        id: 'saved',
        title: 'Storm',
        content: 'rain',
        negativeContent: 'sunlight',
        thumbnail: 'C:/private/photo.png',
        sourcePath: 'C:/private/source.txt',
        readingTranslationZh: '雨景',
        tags: const [PromptBlockTag(name: 'weather')],
      );
      final raw = encodeRagBlocks([
        block,
        block.copyWith(id: 'archived', isArchived: true),
      ]);
      final rows = (jsonDecode(raw) as Map)['blocks'] as List;
      expect(rows.length, 1);
      expect(rows.single['positive'], 'rain');
      expect(rows.single['negative'], 'sunlight');
      expect(rows.single['reading'], '雨景');
      expect(raw, isNot(contains('C:/private')));
      expect(raw, isNot(contains('archived')));
      expect(
        encodeRagBlocks([block.copyWith(useCount: 100, isFavorite: true)]),
        raw,
      );
      expect(encodeRagBlocks([block.copyWith(content: 'night')]), isNot(raw));
      final stale =
          jsonDecode(
                encodeRagBlocks([
                  block.copyWith(readingTranslationNeedsReview: true),
                ]),
              )
              as Map;
      expect((stale['blocks'] as List).single.containsKey('reading'), isFalse);
    },
  );
}
