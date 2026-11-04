import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/pill_document_editor.dart';
import 'package:nai_launcher/core/utils/prompt_translation_document.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';

void main() {
  for (final merged in [false, true]) {
    test('formatted translation preserves separators, merged=$merged', () {
      const original = PillDocument(
        text: 'girl, red hair, QA alpha',
        instances: {},
      );
      final batch = PromptTranslationBatch.prepare({'main': original});
      final ids = batch.segments['main']!.map((s) => s.id).toList();
      final groups = batch.parseGroups(
        jsonEncode({
          'fields': [
            {
              'id': 'main',
              'groups': [
                if (merged)
                  {'ids': ids.take(2).toList(), 'zh': '人物'}
                else ...[
                  {
                    'ids': [ids[0]],
                    'zh': '人物',
                  },
                  {
                    'ids': [ids[1]],
                    'zh': '发色',
                  },
                ],
                {
                  'ids': [ids[2]],
                  'zh': '测试',
                },
              ],
            },
          ],
        }),
      );
      final translated = batch.buildFromGroups(
        groups,
        autoFormat: true,
      )['main']!;
      final restored = PillDocument.fromJson(translated.toJson());
      expect(
        PillDocumentEditor.project(restored, (_) => null),
        'girl, red hair, QA alpha',
      );
      expect(
        PillDocumentEditor.unwrapAllTranslations(restored).text,
        'girl, red hair, QA alpha',
      );
    });
  }

  test('formatting a weighted fragment preserves the next line boundary', () {
    const original = PillDocument(
      text: '1::blue eyes::,\n1.3::red dress::, QA alpha',
      instances: {},
    );
    final batch = PromptTranslationBatch.prepare({'main': original});
    final groups = {
      'main': [
        for (final segment in batch.segments['main']!)
          (
            start: segment.start,
            end: segment.end,
            zh: '测试',
            marks: const <TranslationTagMark>[],
          ),
      ],
    };
    final translated = batch.buildFromGroups(groups, autoFormat: true)['main']!;
    expect(
      PillDocumentEditor.project(translated, (_) => null),
      'blue eyes,\n1.3::red dress::, QA alpha',
    );
    expect(
      PillDocumentEditor.unwrapAllTranslations(translated).text,
      'blue eyes,\n1.3::red dress::, QA alpha',
    );
  });

  test(
    'translation keeps separators adjacent to an existing library block',
    () {
      const marker = '\uE000';
      const original = PillDocument(
        text: 'girl, $marker red hair, QA alpha',
        instances: {marker: PillInstance(blockId: 'existing')},
      );
      final batch = PromptTranslationBatch.prepare({'main': original});
      final groups = {
        'main': [
          for (final segment in batch.segments['main']!)
            (
              start: segment.start,
              end: segment.end,
              zh: '测试',
              marks: const <TranslationTagMark>[],
            ),
        ],
      };
      final translated = batch.buildFromGroups(
        groups,
        autoFormat: true,
      )['main']!;
      expect(
        PillDocumentEditor.project(translated, (_) => 'BLOCK'),
        'girl, BLOCK red hair, QA alpha',
      );
      expect(PillDocumentEditor.unwrapAllTranslations(translated), original);
    },
  );
}
