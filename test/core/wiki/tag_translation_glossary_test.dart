import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/wiki/tag_translation_glossary.dart';
import 'package:nai_launcher/core/wiki/tag_wiki_repository.dart';
import 'package:nai_launcher/core/wiki/visible_tag_translation_cache.dart';

class _Wiki implements TagWikiRepository {
  _Wiki(this.bodies, {this.fail = false});
  final Map<String, String> bodies;
  final bool fail;
  @override
  Future<TagWikiEntry?> find(String tag) async {
    if (fail) throw StateError('wiki unavailable');
    final body = bodies[tag];
    return body == null
        ? null
        : TagWikiEntry(
            tag: tag,
            body: body,
            sourceUrl: 'https://example.test/$tag',
          );
  }
}

class _Cache extends VisibleTagTranslationCache {
  _Cache(this.records, {this.fail = false});
  final Map<String, CachedVisibleTagTranslation> records;
  final bool fail;
  @override
  Future<Map<String, CachedVisibleTagTranslation>> chineseTerms(
    Iterable<String> tags,
  ) async {
    if (fail) throw StateError('cache unavailable');
    return {
      for (final tag in tags)
        if (records[tag] case final term?) tag: term,
    };
  }
}

void main() {
  const source =
      'The star at the center of our solar system. Light and heat. See also moon.';
  test(
    'glossary includes canonical lookup, Chinese label and source-grounded cached definition',
    () async {
      final terms = TagTranslationGlossary(
        wiki: _Wiki({'sun': source}),
        cache: _Cache({
          'sun': CachedVisibleTagTranslation(
            nameZh: '太阳',
            definition: '太阳系中心的恒星，发出光和热。',
            wikiHash: sha256.convert(utf8.encode(source)).toString(),
            definitionLanguage: 'zh',
          ),
        }),
      );
      expect(await terms.termsFor([' Sun ', 'sun']), {
        'sun': {
          'zh': '太阳',
          'definition': '太阳系中心的恒星，发出光和热。',
          'definition_language': 'zh',
        },
      });
    },
  );

  test(
    'stale or non-Chinese definitions fall back to source while retaining the Chinese label',
    () async {
      for (final (hash, language) in [
        ('old', 'zh'),
        (sha256.convert(utf8.encode(source)).toString(), 'ja'),
      ]) {
        final terms = TagTranslationGlossary(
          wiki: _Wiki({'sun': source}),
          cache: _Cache({
            'sun': CachedVisibleTagTranslation(
              nameZh: '太阳',
              definition: '错误释义',
              wikiHash: hash,
              definitionLanguage: language,
            ),
          }),
        );
        expect((await terms.termsFor(['sun']))['sun'], {
          'zh': '太阳',
          'definition': 'The star at the center of our solar system.',
          'definition_language': 'source',
        });
      }
    },
  );

  test(
    'missing or failed cache supplies source meaning without guessing a Chinese name',
    () async {
      for (final fail in [false, true]) {
        final terms = TagTranslationGlossary(
          wiki: _Wiki({'sun': source}),
          cache: _Cache({}, fail: fail),
        );
        final term = (await terms.termsFor(['sun']))['sun']!;
        expect(
          term['definition'],
          'The star at the center of our solar system.',
        );
        expect(term.containsKey('zh'), isFalse);
      }
    },
  );

  test(
    'missing/404 wiki has no invented definition; failed wiki keeps available Chinese name',
    () async {
      final terms = TagTranslationGlossary(
        wiki: _Wiki({'chakapi': 'None(404)'}),
        cache: _Cache({}),
      );
      expect(await terms.termsFor(['chakapi', 'missing']), {
        'chakapi': <String, String>{},
        'missing': <String, String>{},
      });
      final failed = TagTranslationGlossary(
        wiki: _Wiki({}, fail: true),
        cache: _Cache({
          'sun': const CachedVisibleTagTranslation(
            nameZh: '太阳',
            definition: '旧定义',
          ),
        }),
      );
      expect((await failed.termsFor(['sun']))['sun'], {'zh': '太阳'});
    },
  );

  test(
    'source fallback strips presentation, avoids lists, bounds Unicode safely and handles empty input',
    () async {
      expect(
        TagTranslationGlossary.sourceDefinition(
          '## Definition\nA [star](wof-tag:star) emits **light**.\n\nExamples unrelated items',
        ),
        'A star emits light.',
      );
      final text = TagTranslationGlossary.sourceDefinition('😀' * 400)!;
      expect(text.runes.length, 320);
      expect(text.contains('\uFFFD'), isFalse);
      expect(text.endsWith('…'), isTrue);
      expect(
        TagTranslationGlossary.sourceDefinition('太阳系中心的恒星。后面是其他内容。'),
        '太阳系中心的恒星。',
      );
      expect(
        await TagTranslationGlossary(
          wiki: _Wiki({}, fail: true),
          cache: _Cache({}, fail: true),
        ).termsFor([]),
        isEmpty,
      );
    },
  );
}
