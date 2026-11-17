import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/prompt_reading_units.dart';
import 'package:nai_launcher/core/utils/nai_prompt_syntax.dart';
import 'package:nai_launcher/core/utils/prompt_translation_document.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_reading.dart';

void main() {
  test(
    'standalone library aliases and quoted markup retain literal readings',
    () {
      const source = '<library_alias>, "literal <style>", blue eyes';
      expect(PromptReadingUnit.parse(source).map((u) => u.text), [
        '<library_alias>',
        '"literal <style>"',
        'blue eyes',
      ]);
      expect(PromptReadingUnit.isSyntaxOnly('<library_alias>'), isFalse);
      expect(PromptReadingUnit.isSingleSection('<library_alias>'), isTrue);
      final batch = PromptTranslationBatch.prepare({
        'main': const PillDocument(text: source, instances: {}),
      }, mode: PromptTranslationMode.inline);
      expect(
        () => batch.parseGroups(
          jsonEncode({
            'fields': [
              {
                'id': 'main',
                'groups': [
                  {
                    'ids': batch.segments['main']!.map((s) => s.id).toList(),
                    'readings': [
                      {'source': '"literal <style>"', 'zh': '字面文字'},
                      {'source': 'blue eyes', 'zh': '蓝眼'},
                    ],
                  },
                ],
              },
            ],
          }),
        ),
        throwsFormatException,
      );
      expect(
        PromptReadingUnit.parse(
          '<scene mood="calm">blue eyes, silver hair</scene>',
        ).map((u) => u.text),
        ['blue eyes', 'silver hair'],
      );
    },
  );
  test(
    'commas inside weighting groups delimit independent exact source ranges',
    () {
      const source =
          '4::1girl, 1boy::, {silver hair, blue eyes}, [[soft lighting]],';
      final units = PromptReadingUnit.parse(source);
      expect(units.map((unit) => unit.text), [
        '1girl',
        '1boy',
        'silver hair',
        'blue eyes',
        'soft lighting',
      ]);
      expect(
        units.map((unit) => source.substring(unit.start, unit.end)).join(),
        source,
      );
      expect(
        units.map((unit) => source.substring(unit.textStart, unit.textEnd)),
        ['1girl', '1boy', 'silver hair', 'blue eyes', 'soft lighting'],
      );
    },
  );
  test(
    'literals, names, counts, emoji and explicit line breaks remain meaningful',
    () {
      const source =
          'artist:name (series, artist), "a,b", escaped\\,comma, 2girls,\n\n山と空, 😀';
      expect(PromptReadingUnit.parse(source).map((unit) => unit.text), [
        'artist:name (series, artist)',
        '"a,b"',
        r'escaped\,comma',
        '2girls',
        '山と空',
        '😀',
      ]);
      expect(PromptReadingUnit.clean('1.4::2个女孩::,'), '2个女孩');
    },
  );
  test(
    'incremental slices retain boundaries while removing unmatched weighting wrappers',
    () {
      expect(PromptReadingUnit.parse('{green hair,').single.text, 'green hair');
      expect(
        PromptReadingUnit.parse('blue eyes}, solo').map((unit) => unit.text),
        ['blue eyes', 'solo'],
      );
    },
  );
  test(
    'inline request preserves source and resolves semantic readings by exact anchors',
    () {
      const source = '{1girl, blue eyes},';
      final batch = PromptTranslationBatch.prepare({
        'main': const PillDocument(text: source, instances: {}),
      }, mode: PromptTranslationMode.inline);
      final request = jsonDecode(batch.requestJson(const [])) as Map;
      expect(request['mode'], 'inline');
      expect(
        (request['fields'][0]['segments'] as List).map(
          (item) => item['source'],
        ),
        ['{1girl,', ' blue eyes},'],
      );
      final ids = batch.segments['main']!.map((item) => item.id).toList();
      String response(List<Map<String, Object>> groups) => jsonEncode({
        'fields': [
          {'id': 'main', 'groups': groups},
        ],
      });
      expect(
        () => batch.parseGroups(
          response([
            {'ids': ids, 'zh': '蓝眼女孩'},
          ]),
        ),
        throwsFormatException,
      );
      final groups = batch.parseGroups(
        response([
          {
            'ids': [ids[0]],
            'readings': [
              {'source': '1girl', 'zh': '4::1个女孩::,'},
            ],
          },
          {
            'ids': [ids[1]],
            'readings': [
              {'source': 'blue eyes', 'zh': '{蓝眼},'},
            ],
          },
        ]),
      );
      expect(groups['main']!.map((group) => group.zh), ['1个女孩', '蓝眼']);
      final document = batch.buildFromGroups(
        groups,
        mode: PromptTranslationMode.inline,
      )['main']!;
      expect(document.text, source);
      expect(document.readings.every((item) => item.perSegment), isTrue);
      expect(
        PillDocument.fromJson(document.toJson()).readings,
        document.readings,
      );
    },
  );
  test(
    'XML boundaries remain local to readings and preserve glossary hints',
    () {
      const source =
          '<artist>\n1.3::artist:alpha::, artist:beta\n</artist>, <style>\n'
          'masterpiece, soft lighting\n</style>, blue eyes';
      final units = PromptReadingUnit.parse(source);
      expect(units.map((u) => u.text), [
        'artist:alpha',
        'artist:beta',
        'masterpiece',
        'soft lighting',
        'blue eyes',
      ]);
      expect(units[0].section, units[1].section);
      expect(units[1].section, isNot(units[2].section));
      expect(units[3].section, isNot(units[4].section));
      expect(
        NaiPromptSyntax.scan(source).single.kind,
        NaiPromptTokenKind.opaque,
      );
      final batch = PromptTranslationBatch.prepare({
        'main': const PillDocument(text: source, instances: {}),
      }, mode: PromptTranslationMode.inline);
      expect(batch.segments['main']!.map((s) => s.source).join(), source);
      expect(
        batch.tagCandidates,
        containsAll(['artist:alpha', 'soft_lighting']),
      );
      expect(batch.segments['main']![0].run, batch.segments['main']![1].run);
      expect(
        batch.segments['main']![1].run,
        isNot(batch.segments['main']![2].run),
      );
    },
  );

  test(
    'semantic fragments split fields and combine prose without changing source',
    () {
      const source =
          '<scene>Subject: a girl; Lighting: warm</scene>\n'
          'She opens a book, then looks left.';
      final batch = PromptTranslationBatch.prepare({
        'main': const PillDocument(text: source, instances: {}),
      }, mode: PromptTranslationMode.inline);
      final items = batch.segments['main']!;
      final groups = batch.parseGroups(
        jsonEncode({
          'fields': [
            {
              'id': 'main',
              'groups': [
                {
                  'ids': [items[0].id],
                  'readings': [
                    {'source': 'Subject: a girl', 'zh': '主体：一个女孩'},
                    {'source': 'Lighting: warm', 'zh': '光照：暖色'},
                  ],
                },
                {
                  'ids': [items[1].id, items[2].id],
                  'readings': [
                    {
                      'source': 'She opens a book, then looks left.',
                      'zh': '她翻开书，然后看向左侧',
                    },
                  ],
                },
              ],
            },
          ],
        }),
      );
      final result = batch.buildFromGroups(
        groups,
        mode: PromptTranslationMode.inline,
      )['main']!;
      expect(result.text, source);
      expect(result.readings.map((r) => r.source), [
        'Subject: a girl',
        'Lighting: warm',
        'She opens a book, then looks left.',
      ]);
      expect(
        PromptTranslationBatch.prepare(
          {'main': result},
          mode: PromptTranslationMode.inline,
          skipReadings: true,
        ).isEmpty,
        isTrue,
      );
    },
  );

  for (final source in [
    'blue  eyes\tand soft light',
    '1.3::blue eyes:: and soft light',
  ]) {
    test('inline anchors tolerate source formatting: $source', () {
      final before = PillDocument(text: source, instances: const {});
      final batch = PromptTranslationBatch.prepare({
        'main': before,
      }, mode: PromptTranslationMode.inline);
      final raw = jsonEncode({
        'fields': [
          {
            'id': 'main',
            'groups': [
              {
                'ids': batch.segments['main']!.map((s) => s.id).toList(),
                'readings': [
                  {'source': 'blue eyes and soft light', 'zh': '蓝眼睛与柔光'},
                ],
              },
            ],
          },
        ],
      });
      final after = batch.buildFromGroups(
        batch.parseGroups(raw),
        mode: PromptTranslationMode.inline,
      )['main']!;
      expect(after.text, source);
      expect(after.instances, before.instances);
      final reading = after.readings.single;
      expect(reading.translation, '蓝眼睛与柔光');
      expect(reading.source, source.substring(source.indexOf('blue')));
    });
  }

  test('normalized repeated anchors stay on their own source occurrence', () {
    const source = 'blue  eyes, blue eyes';
    final batch = PromptTranslationBatch.prepare({
      'main': const PillDocument(text: source, instances: {}),
    }, mode: PromptTranslationMode.inline);
    final groups = batch.parseGroups(
      jsonEncode({
        'fields': [
          {
            'id': 'main',
            'groups': [
              {
                'ids': batch.segments['main']!.map((s) => s.id).toList(),
                'readings': [
                  {'source': 'blue eyes', 'zh': '蓝眼'},
                  {'source': 'blue eyes', 'zh': '蓝眼'},
                ],
              },
            ],
          },
        ],
      }),
    )['main']!;
    expect(groups.map((g) => source.substring(g.start, g.end)), [
      'blue  eyes',
      'blue eyes',
    ]);
  });

  for (final anchors in [
    ['blue eyes'], // Omitted meaningful source.
    ['green hair', 'blue eyes'], // Invented source.
    ['blue eyes', 'silver hair'], // Reordered source.
    ['silver hair', 'silver hair', 'blue eyes'], // Duplicate source.
  ]) {
    test('invalid semantic anchors are rejected: $anchors', () {
      final batch = PromptTranslationBatch.prepare({
        'main': const PillDocument(
          text: 'silver hair, blue eyes',
          instances: {},
        ),
      }, mode: PromptTranslationMode.inline);
      expect(
        () => batch.parseGroups(
          jsonEncode({
            'fields': [
              {
                'id': 'main',
                'groups': [
                  {
                    'ids': batch.segments['main']!.map((s) => s.id).toList(),
                    'readings': [
                      for (final anchor in anchors)
                        {'source': anchor, 'zh': '译文'},
                    ],
                  },
                ],
              },
            ],
          }),
        ),
        throwsFormatException,
      );
    });
  }

  test(
    'repeated source anchors resolve sequentially and never cross structural runs',
    () {
      const source = '<scene>blue eyes, blue eyes</scene>\nsoft lighting';
      final batch = PromptTranslationBatch.prepare({
        'main': const PillDocument(text: source, instances: {}),
      }, mode: PromptTranslationMode.inline);
      final ids = batch.segments['main']!.map((s) => s.id).toList();
      final response = {
        'fields': [
          {
            'id': 'main',
            'groups': [
              {
                'ids': ids.take(2).toList(),
                'readings': [
                  {'source': 'blue eyes', 'zh': '蓝眼一'},
                  {'source': 'blue eyes', 'zh': '蓝眼二'},
                ],
              },
              {
                'ids': [ids.last],
                'readings': [
                  {'source': 'soft lighting', 'zh': '柔和光线'},
                ],
              },
            ],
          },
        ],
      };
      final groups = batch.parseGroups(jsonEncode(response))['main']!;
      expect(groups[0].start, source.indexOf('blue eyes'));
      expect(groups[1].start, source.lastIndexOf('blue eyes'));
      expect(
        () => batch.parseGroups(
          jsonEncode({
            'fields': [
              {
                'id': 'main',
                'groups': [
                  {
                    'ids': ids,
                    'readings': [
                      {'source': source, 'zh': '错误合并'},
                    ],
                  },
                ],
              },
            ],
          }),
        ),
        throwsFormatException,
      );
    },
  );

  test('old whole-XML annotations are eligible for retranslation', () {
    const source = '<scene>silver hair, blue eyes</scene>';
    const reading = PromptReading(
      start: 0,
      end: source.length,
      source: source,
      translation: '整篇旧译文',
      perSegment: true,
    );
    final batch = PromptTranslationBatch.prepare(
      {
        'main': const PillDocument(
          text: source,
          instances: {},
          readings: [reading],
        ),
      },
      mode: PromptTranslationMode.inline,
      skipReadings: true,
    );
    // A whole container must be repaired even if it contains only one line.
    expect(batch.isEmpty, isFalse);
  });
  test(
    'legacy grouped readings are retranslated while current units remain incremental',
    () {
      const source = 'silver hair, blue eyes,';
      const old = PromptReading(
        start: 0,
        end: source.length,
        source: source,
        translation: '银发蓝眼',
      );
      final legacy = PromptTranslationBatch.prepare(
        {
          'main': const PillDocument(
            text: source,
            instances: {},
            readings: [old],
          ),
        },
        mode: PromptTranslationMode.inline,
        skipReadings: true,
      );
      expect(legacy.segments['main']!.length, 2);
      const current = PromptReading(
        start: 0,
        end: 12,
        source: 'silver hair,',
        translation: '银发',
        perSegment: true,
      );
      final incremental = PromptTranslationBatch.prepare(
        {
          'main': const PillDocument(
            text: source,
            instances: {},
            readings: [current],
          ),
        },
        mode: PromptTranslationMode.inline,
        skipReadings: true,
      );
      expect(incremental.segments['main']!.single.reading, 'blue eyes');
      final shifted = PromptReading.rebase(
        const [current],
        source,
        'new, $source',
      );
      expect(shifted.single.perSegment, isTrue);
    },
  );
}
