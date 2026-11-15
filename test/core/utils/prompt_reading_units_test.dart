import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/prompt_reading_units.dart';
import 'package:nai_launcher/core/utils/prompt_translation_document.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_reading.dart';

void main() {
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
    'inline request sends clean per-ID units and rejects merged responses',
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
        ['1girl', 'blue eyes'],
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
            'zh': '4::1个女孩::,',
          },
          {
            'ids': [ids[1]],
            'zh': '{蓝眼},',
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
