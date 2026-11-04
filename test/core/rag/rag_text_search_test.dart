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
  test('blocks compare the same exactly when their snapshot is the same', () {
    final block = PromptBlock.create(
      id: 'saved',
      title: 'Storm',
      content: 'rain',
      negativeContent: 'sunlight',
      readingTranslationZh: '雨景',
      tags: const [
        PromptBlockTag(name: 'weather'),
        PromptBlockTag(name: 'night'),
      ],
    );
    final other = PromptBlock.create(id: 'other', title: 'Snow', content: '');
    final library = [block, other];
    // Same snapshot: what the snapshot leaves out.
    final same = <String, List<PromptBlock>>{
      'use count': [block.copyWith(useCount: 7), other],
      'favourite': [block.copyWith(isFavorite: true), other],
      'folder and order': [
        other.copyWith(sortOrder: 3),
        block.copyWith(folderId: 'weather', sortOrder: 9),
      ],
      'looks': [
        block.copyWith(color: '#FF000000', iconName: 'star', thumbnail: 'a'),
        other,
      ],
      'tag colours and order': [
        block.copyWith(
          tags: const [
            PromptBlockTag(name: 'night', color: '#FFFFFFFF'),
            PromptBlockTag(name: 'weather'),
          ],
        ),
        other,
      ],
      'times and import': [
        block.copyWith(updatedAt: DateTime(2030), sourcePath: 'a.txt'),
        other,
      ],
      'atoms and settings': [
        block.copyWith(
          atoms: const ['rain'],
          generationSettings: const PromptBlockGenerationSettings(steps: 9),
        ),
        other,
      ],
      'an archived block': [
        ...library,
        block.copyWith(id: 'gone', isArchived: true),
      ],
      'copies of the same blocks': [
        for (final b in library) PromptBlock.fromJson(b.toJson()),
      ],
    };
    // Another snapshot: each field it holds.
    final different = <String, List<PromptBlock>>{
      'title': [block.copyWith(title: 'Storms'), other],
      'positive text': [block.copyWith(content: 'rain at night'), other],
      'negative text': [block.copyWith(negativeContent: 'sun'), other],
      'a tag name': [
        block.copyWith(tags: const [PromptBlockTag(name: 'weather')]),
        other,
      ],
      'the reading': [block.copyWith(readingTranslationZh: '夜雨'), other],
      'the reading now needs review': [
        block.copyWith(readingTranslationNeedsReview: true),
        other,
      ],
      'a block added': [
        ...library,
        PromptBlock.create(id: 'fog', title: 'Fog', content: 'fog'),
      ],
      'a block removed': [block],
      'a block archived': [block, other.copyWith(isArchived: true)],
      'a block twice': [...library, other],
    };
    // A reading waiting for review is left out, so editing it changes nothing.
    final unreviewed = [
      block.copyWith(readingTranslationNeedsReview: true),
      other,
    ];
    final edited = [
      unreviewed.first.copyWith(readingTranslationZh: '夜雨'),
      other,
    ];
    expect(encodeRagBlocks(edited), encodeRagBlocks(unreviewed));
    expect(sameRagBlocks(unreviewed, edited), isTrue);
    for (final (expected, cases) in [(true, same), (false, different)]) {
      for (final MapEntry(key: change, value: changed) in cases.entries) {
        expect(
          encodeRagBlocks(changed) == encodeRagBlocks(library),
          expected,
          reason: '$change: the snapshot',
        );
        expect(sameRagBlocks(library, changed), expected, reason: change);
      }
    }
  });
}
