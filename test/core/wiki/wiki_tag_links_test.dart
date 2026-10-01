import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/chinese_term_matcher.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/wiki/wiki_tag_links.dart';

CompletionCandidate tag(
  String name, {
  TagCategory category = TagCategory.general,
}) => CompletionCandidate(
  canonicalTag: name,
  category: category,
  postCount: 1,
  matchKind: CompletionMatchKind.englishExact,
  sources: const {CompletionSourceKind.base},
);

void main() {
  WikiTagLinks matcher(
    Map<String, CompletionCandidate> entries, {
    List<ChineseTermHit> hits = const [],
  }) => WikiTagLinks(
    exactLookup: (names) async => {
      for (final name in names)
        if (entries[name] case final item?) name: item,
    },
    chineseLookup: (_) async => hits,
  );
  test(
    'dictionary hits in prose never create links or load a dictionary',
    () async {
      final links = WikiTagLinks(
        exactLookup: (_) async => throw StateError('must not query'),
        chineseLookup: (_) async => throw StateError('must not scan'),
      );
      const body = '帽子以及 visor。帽子是戴在头上的一种衣物。blue_eyes';
      final result = await links.resolve(body);
      expect(result.markdown, body);
      expect(result.targets, isEmpty);
      expect(result.links, isEmpty);
    },
  );
  test(
    'model choices repeat in examples and lists without article-wide deduplication',
    () async {
      const body =
          '[帽子](wof-tag:hat) 是戴在头上的衣物，帽子以及 visor 都不需要再次标记。\n\n'
          '示例\n- [帽子](wof-tag:hat)\n- [蓝眼睛](wof-tag:blue_eyes)\n\n'
          '新章节：[帽子](wof-tag:hat)';
      final result = await matcher({
        'hat': tag('hat'),
        'blue_eyes': tag('blue_eyes'),
        'visor': tag('visor'),
      }).resolve(body);
      expect(result.markdown, body);
      expect(result.links.map((hit) => hit.candidate.canonicalTag), [
        'hat',
        'hat',
        'blue_eyes',
        'hat',
      ]);
      expect(result.targets.keys, ['hat', 'blue_eyes']);
    },
  );
  test(
    'unknown and malformed model links lose only the link; outside-glossary tags work',
    () async {
      final result = await matcher({'saber_(fate)': tag('saber_(fate)')}).resolve(
        '[未知](wof-tag:unknown) [破损](wof-tag:%ZZ) [完整角色名](wof-tag:saber_%28fate%29)',
      );
      expect(result.markdown, '未知 破损 [完整角色名](wof-tag:saber_%28fate%29)');
      expect(result.targets.keys, ['saber_(fate)']);
    },
  );
  test(
    'raw canonical parentheses and aliases resolve to the canonical target',
    () async {
      final result = await matcher({
        'old_name': tag('new_name'),
        'saber_(fate)': tag('saber_(fate)'),
      }).resolve('[旧名](wof-tag:old_name) [角色](wof-tag:saber_(fate))');
      expect(
        result.markdown,
        '[旧名](wof-tag:new_name) [角色](wof-tag:saber_%28fate%29)',
      );
      expect(result.targets.keys, ['new_name', 'saber_(fate)']);
    },
  );
  test(
    'code and images are not links; escaped labels and external URLs stay readable',
    () async {
      const body =
          r'`[code](wof-tag:blue_eyes)` ![image](wof-tag:blue_eyes) [蓝\]眼](wof-tag:blue_eyes) [site](https://example.test/blue_eyes)';
      final result = await matcher({
        'blue_eyes': tag('blue_eyes'),
      }).resolve(body);
      expect(result.links, hasLength(1));
      expect(result.markdown, body);
    },
  );
  test(
    'official source links navigate locally after verification, others stay external',
    () async {
      final result = await matcher({'blue_eyes': tag('blue_eyes')}).resolve(
        '[蓝眼](https://danbooru.donmai.us/wiki_pages/blue_eyes) [unknown](https://danbooru.donmai.us/wiki_pages/not_a_tag)',
      );
      expect(result.markdown, contains('[蓝眼](wof-tag:blue_eyes)'));
      expect(
        result.markdown,
        contains('https://danbooru.donmai.us/wiki_pages/not_a_tag'),
      );
      expect(result.targets.keys, ['blue_eyes']);
    },
  );
  test(
    'failed catalog validation leaves selected local text plain and keeps external URLs',
    () async {
      final result = await WikiTagLinks(
        exactLookup: (_) async => throw StateError('unavailable'),
        chineseLookup: (_) async => [],
      ).resolve('[蓝眼](wof-tag:blue_eyes) [site](https://example.test)');
      expect(result.markdown, '蓝眼 [site](https://example.test)');
      expect(result.targets, isEmpty);
    },
  );
  test(
    'reference-style and automatic internal links are also validated',
    () async {
      const body = '''[帽子][hat] [帽子][hat] [缺失][missing] <wof-tag:hat>

[hat]: wof-tag:hat
[missing]: wof-tag:missing''';
      final result = await matcher({'hat': tag('hat')}).resolve(body);
      expect(result.links, hasLength(3));
      expect(
        result.markdown,
        startsWith(
          '[帽子](wof-tag:hat) [帽子](wof-tag:hat) 缺失 [wof-tag:hat](wof-tag:hat)',
        ),
      );
      expect(result.targets.keys, ['hat']);
    },
  );
  test('session cache deduplicates target validation', () async {
    var calls = 0;
    final links = WikiTagLinks(
      exactLookup: (_) async {
        calls++;
        return {'blue_eyes': tag('blue_eyes')};
      },
      chineseLookup: (_) async => [],
    );
    final first = links.resolve('[蓝眼](wof-tag:blue_eyes)');
    expect(identical(first, links.resolve('[蓝眼](wof-tag:blue_eyes)')), isTrue);
    expect((await first).links, hasLength(1));
    expect(calls, 1);
  });
  test(
    'candidate material keeps complete names, categories, readings and matching fragments',
    () async {
      final entries = {
        'blue_eyes': tag('blue_eyes'),
        'eyes': tag('eyes'),
        'giant': tag('giant'),
        'fate_testarossa_(blaze_form)': tag(
          'fate_testarossa_(blaze_form)',
          category: TagCategory.character,
        ),
      };
      final links = WikiTagLinks(
        exactLookup: (names) async => {
          for (final name in names)
            if (entries[name] case final item?) name: item,
        },
        chineseLookup: (_) async => [],
        readingsLookup: (_) async => {'blue_eyes': '蓝眼睛'},
      );
      final glossary = await links.glossaryFor(
        'Blue eyes, fate_testarossa_(blaze_form), giants. (giant)',
      );
      final byTag = {for (final item in glossary) item['tag']: item};
      expect(byTag.keys, containsAll(entries.keys));
      expect(byTag['blue_eyes']!['zh'], '蓝眼睛');
      expect(byTag['blue_eyes']!['matched_texts'], ['Blue eyes']);
      expect(byTag['fate_testarossa_(blaze_form)']!['category'], 'character');
      expect(byTag['giant']!['matched_texts'], ['giant']);
      expect(glossary.first['tag'], 'fate_testarossa_(blaze_form)');
      expect((await links.resolve('Blue eyes')).links, isEmpty);
    },
  );
  test(
    'ambiguous Chinese definitions are reference options, not automatic links',
    () async {
      final entries = {
        'blue_eyes': tag('blue_eyes'),
        'solo': tag('solo'),
        'single': tag('single'),
      };
      final links = matcher(
        entries,
        hits: [
          ChineseTermHit(0, 2, tag('blue_eyes')),
          ChineseTermHit(3, 5, tag('solo')),
          ChineseTermHit(3, 5, tag('single')),
          ChineseTermHit(6, 8, tag('missing')),
        ],
      );
      final glossary = await links.glossaryFor('蓝眼 单人 未知');
      expect(glossary.map((item) => item['tag']), [
        'blue_eyes',
        'solo',
        'single',
      ]);
      expect((await links.resolve('蓝眼 单人 未知')).links, isEmpty);
    },
  );
  test(
    'glossary is bounded and optional dictionary errors do not block English candidates',
    () async {
      final entries = {for (var i = 0; i < 80; i++) 'tag_$i': tag('tag_$i')};
      final links = WikiTagLinks(
        exactLookup: (names) async => {
          for (final name in names)
            if (entries[name] case final item?) name: item,
        },
        chineseLookup: (_) async => throw StateError('missing'),
        readingsLookup: (_) async => throw StateError('missing'),
      );
      final glossary = await links.glossaryFor(entries.keys.join(', '));
      expect(glossary, hasLength(64));
      expect(await links.glossaryFor('tag_1', limit: 0), isEmpty);
    },
  );
}
