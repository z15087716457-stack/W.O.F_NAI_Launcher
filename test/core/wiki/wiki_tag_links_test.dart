import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/autocomplete/chinese_term_matcher.dart';
import 'package:nai_launcher/core/autocomplete/completion_models.dart';
import 'package:nai_launcher/core/wiki/wiki_tag_links.dart';

CompletionCandidate tag(String name) => CompletionCandidate(
  canonicalTag: name,
  category: TagCategory.general,
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
    'complete English phrases and canonical punctuation; longest wins',
    () async {
      final entries = {
        for (final name in [
          'blue_eyes',
          'eyes',
          'fate_testarossa_(blaze_form)',
          'giant',
        ])
          name: tag(name),
      };
      const body = 'Blue eyes, fate_testarossa_(blaze_form), giants. (giant)';
      final result = await matcher(entries).resolve(body);
      expect(result.links.map((hit) => hit.candidate.canonicalTag), [
        'blue_eyes',
        'fate_testarossa_(blaze_form)',
        'giant',
      ]);
      expect(result.links.map((hit) => body.substring(hit.start, hit.end)), [
        'Blue eyes',
        'fate_testarossa_(blaze_form)',
        'giant',
      ]);
      expect(result.markdown, contains('giants.'));
    },
  );

  test('exact aliases use canonical destination', () async {
    final result = await matcher({
      'old_name': tag('new_name'),
    }).resolve('old_name');
    expect(result.targets.keys, ['new_name']);
    expect(result.markdown, contains('wof-tag:new_name'));
  });

  test(
    'unique Chinese definition links but ambiguous or missing does not',
    () async {
      final entries = {
        'blue_eyes': tag('blue_eyes'),
        'solo': tag('solo'),
        'single': tag('single'),
      };
      final result = await matcher(
        entries,
        hits: [
          ChineseTermHit(0, 2, tag('blue_eyes')),
          ChineseTermHit(3, 5, tag('solo')),
          ChineseTermHit(3, 5, tag('single')),
          ChineseTermHit(6, 8, tag('missing')),
        ],
      ).resolve('蓝眼 单人 未知');
      expect(result.links.length, 1);
      expect(result.links.single.candidate.canonicalTag, 'blue_eyes');
    },
  );

  test(
    'existing Markdown links, URLs and code never acquire nested links',
    () async {
      const body =
          'blue_eyes `blue_eyes` [site](https://example.test/blue_eyes) https://example.test/blue_eyes';
      final result = await matcher({
        'blue_eyes': tag('blue_eyes'),
      }).resolve(body);
      expect(result.links.length, 1);
      expect(
        result.markdown,
        contains('[site](https://example.test/blue_eyes)'),
      );
      expect(result.markdown, contains('`blue_eyes`'));
    },
  );

  test(
    'cache deduplicates lookup and missing dictionary is optional',
    () async {
      var calls = 0;
      final links = WikiTagLinks(
        exactLookup: (_) async {
          calls++;
          return {'blue_eyes': tag('blue_eyes')};
        },
        chineseLookup: (_) async => throw StateError('not installed'),
      );
      final first = links.resolve('blue_eyes');
      expect(identical(first, links.resolve('blue_eyes')), isTrue);
      expect((await first).links.length, 1);
      expect(calls, 1);
    },
  );

  test('official Wiki links navigate locally after exact validation', () async {
    final result = await matcher({'blue_eyes': tag('blue_eyes')}).resolve(
      '[蓝眼](https://danbooru.donmai.us/wiki_pages/blue_eyes) [unknown](https://danbooru.donmai.us/wiki_pages/not_a_tag)',
    );
    expect(result.markdown, contains('[蓝眼](wof-tag:blue_eyes)'));
    expect(
      result.markdown,
      contains('https://danbooru.donmai.us/wiki_pages/not_a_tag'),
    );
    expect(result.targets.keys, ['blue_eyes']);
  });

  test('lookup failure preserves readable source', () async {
    final result = await WikiTagLinks(
      exactLookup: (_) async => throw StateError('unavailable'),
      chineseLookup: (_) async => [],
    ).resolve('plain body');
    expect(result.markdown, 'plain body');
    expect(result.targets, isEmpty);
  });
}
