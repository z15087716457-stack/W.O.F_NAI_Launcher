import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/pill_document_editor.dart';
import 'package:nai_launcher/core/utils/prompt_translation_document.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';

void main() {
  test(
    'semantic groups retain exact original projection and block position',
    () {
      const marker = '\uE000';
      const original = PillDocument(
        text: '1girl, blue eyes, $marker夕焼けの街',
        instances: {marker: PillInstance(blockId: 'library-block')},
      );
      final batch = PromptTranslationBatch.prepare({'main': original});
      final items = batch.segments['main']!;
      expect(items.map((item) => item.source), [
        '1girl,',
        ' blue eyes,',
        '夕焼けの街',
      ]);
      expect(items.map((item) => item.run), [0, 0, 1]);

      final converted = batch.parseAndBuild(
        jsonEncode({
          'fields': [
            {
              'id': 'main',
              'groups': [
                {
                  'ids': [items[0].id, items[1].id],
                  'zh': '一名蓝眼睛女孩',
                },
                {
                  'ids': [items[2].id],
                  'zh': '夕阳下的城市',
                },
              ],
            },
          ],
        }),
      )['main']!;
      expect(converted.text.contains(marker), isTrue);
      expect(converted.instances[marker]?.blockId, 'library-block');
      expect(
        PillDocumentEditor.project(converted, (instance) => 'BLOCK'),
        '1girl, blue eyes, BLOCK夕焼けの街',
      );
      expect(PillDocument.fromJson(converted.toJson()), converted);
      expect(PillDocumentEditor.unwrapAllTranslations(converted), original);
    },
  );

  test('existing translation and library blocks are not sent again', () {
    const translationMarker = '\uE000';
    const libraryMarker = '\uE001';
    const document = PillDocument(
      text: 'new text$translationMarker$libraryMarker more text',
      instances: {
        translationMarker: PillInstance(
          blockId: '',
          translation: TranslationPill(source: 'old', zh: '旧'),
        ),
        libraryMarker: PillInstance(blockId: 'block'),
      },
    );
    final batch = PromptTranslationBatch.prepare({'main': document});
    expect(batch.segments['main']!.map((item) => item.source), [
      'new text',
      ' more text',
    ]);
    expect(batch.requestJson(const []), isNot(contains('old')));
    expect(batch.requestJson(const []), isNot(contains('block')));
  });

  test('new translation sources follow the auto format gate', () {
    const original = PillDocument(
      text: '1::blue eyes::, 1.3::red dress::',
      instances: {},
    );
    final batch = PromptTranslationBatch.prepare({'main': original});
    final group = <String, List<PromptTranslationGroup>>{
      'main': [
        (
          start: 0,
          end: original.text.length,
          zh: '蓝眼睛，红裙子',
          marks: const <TranslationTagMark>[],
        ),
      ],
    };
    final formatted = batch.buildFromGroups(group, autoFormat: true)['main']!;
    final untouched = batch.buildFromGroups(group)['main']!;
    expect(
      formatted.instances.values.single.translation!.source,
      'blue eyes, 1.3::red dress::',
    );
    expect(
      untouched.instances.values.single.translation!.source,
      original.text,
    );
  });

  test('rejects missing IDs and grouping across an inserted block', () {
    const marker = '\uE000';
    final batch = PromptTranslationBatch.prepare({
      'main': const PillDocument(
        text: 'a,$marker b',
        instances: {marker: PillInstance(blockId: 'block')},
      ),
    });
    final ids = batch.segments['main']!.map((item) => item.id).toList();
    expect(
      () => batch.parseAndBuild(
        jsonEncode({
          'fields': [
            {
              'id': 'main',
              'groups': [
                {
                  'ids': [ids.first],
                  'zh': '甲',
                },
              ],
            },
          ],
        }),
      ),
      throwsFormatException,
    );
    expect(
      () => batch.parseAndBuild(
        jsonEncode({
          'fields': [
            {
              'id': 'main',
              'groups': [
                {'ids': ids, 'zh': '甲乙'},
              ],
            },
          ],
        }),
      ),
      throwsFormatException,
    );
  });

  test('display and review flags never change generation text', () {
    const marker = '\uE000';
    const pill = TranslationPill(source: 'blue eyes', zh: '蓝眼睛');
    const first = PillDocument(
      text: marker,
      instances: {marker: PillInstance(blockId: '', translation: pill)},
    );
    final second = first.copyWith(
      instances: {
        marker: PillInstance(
          blockId: '',
          translation: pill.copyWith(showOriginal: true, needsReview: true),
        ),
      },
    );
    expect(PillDocumentEditor.project(first, (_) => null), 'blue eyes');
    expect(PillDocumentEditor.project(second, (_) => null), 'blue eyes');
  });

  test('long requests partition without losing any segment or source', () {
    final source = List.filled(20, 'blue eyes, ').join();
    final batch = PromptTranslationBatch.prepare({
      'main': PillDocument(text: source, instances: const {}),
    });
    final parts = batch.partitions(maxSourceChars: 35);
    expect(parts.length, greaterThan(1));
    expect(
      parts
          .expand((part) => part.segments['main'] ?? const [])
          .map((s) => s.id),
      batch.segments['main']!.map((s) => s.id),
    );
    final groups = <String, List<PromptTranslationGroup>>{};
    for (final part in parts) {
      final ids = part.segments['main']!.map((s) => s.id).toList();
      final parsed = part.parseGroups(
        jsonEncode({
          'fields': [
            {
              'id': 'main',
              'groups': [
                {'ids': ids, 'zh': '蓝眼睛'},
              ],
            },
          ],
        }),
      );
      groups.putIfAbsent('main', () => []).addAll(parsed['main']!);
    }
    final converted = batch.buildFromGroups(groups)['main']!;
    expect(PillDocumentEditor.project(converted, (_) => null), source);
  });

  test('saved translation block keeps its reading and visual skin', () {
    final block = PromptBlock.create(
      title: '蓝眼睛',
      content: 'blue eyes',
      readingTranslationZh: '蓝眼睛',
      readingTranslationNeedsReview: true,
      appearance: 'translation',
    );
    final restored = PromptBlock.fromJson(block.toJson());
    expect(restored.content, 'blue eyes');
    expect(restored.readingTranslationZh, '蓝眼睛');
    expect(restored.readingTranslationNeedsReview, isTrue);
    expect(restored.appearance, 'translation');
  });

  test('verified icon IDs become reading-only tag marks', () {
    final batch = PromptTranslationBatch.prepare({
      'main': const PillDocument(
        text: '1.4::blue eyes::, artist:asteroid_ill,',
        instances: {},
      ),
    });
    final ids = batch.segments['main']!.map((item) => item.id).toList();
    final glossary = [
      {'tag': 'blue_eyes', 'zh': '蓝眼睛', 'icon_id': 'general'},
      {'tag': 'artist:asteroid_ill', 'zh': '画师', 'icon_id': 'artist'},
    ];
    final converted = batch.parseAndBuild(
      jsonEncode({
        'fields': [
          {
            'id': 'main',
            'groups': [
              {
                'ids': ids,
                'zh': '1.4::蓝眼睛::，画师：asteroid_ill',
                'parts': [
                  {'text': '1.4::'},
                  {'text': '蓝眼睛', 'tag': 'blue_eyes', 'icon_id': 'general'},
                  {'text': '::，'},
                  {
                    'text': '画师：asteroid_ill',
                    'tag': 'artist:asteroid_ill',
                    'icon_id': 'artist',
                  },
                ],
              },
            ],
          },
        ],
      }),
      glossary: glossary,
    )['main']!;
    final pill = converted.instances.values.single.translation!;
    expect(pill.marks, [
      const TranslationTagMark(
        start: 5,
        end: 8,
        tag: 'blue_eyes',
        iconId: 'general',
      ),
      TranslationTagMark(
        start: pill.zh.indexOf('画师'),
        end: pill.zh.length,
        tag: 'artist:asteroid_ill',
        iconId: 'artist',
      ),
    ]);
    expect(PillDocument.fromJson(converted.toJson()), converted);
    expect(
      PillDocumentEditor.project(converted, (_) => null),
      '1.4::blue eyes::, artist:asteroid_ill,',
    );
  });

  test('invented or mismatched icon IDs are ignored without losing zh', () {
    final batch = PromptTranslationBatch.prepare({
      'main': const PillDocument(text: 'blue eyes', instances: {}),
    });
    final id = batch.segments['main']!.single.id;
    final response = jsonEncode({
      'fields': [
        {
          'id': 'main',
          'groups': [
            {
              'ids': [id],
              'zh': '蓝眼睛',
              'parts': [
                {'text': '蓝眼睛', 'tag': 'blue_eyes', 'icon_id': 'artist'},
              ],
            },
          ],
        },
      ],
    });
    final pill = batch
        .parseAndBuild(
          response,
          glossary: [
            {'tag': 'blue_eyes', 'icon_id': 'general'},
          ],
        )['main']!
        .instances
        .values
        .single
        .translation!;
    expect(pill.zh, '蓝眼睛');
    expect(pill.marks, isEmpty);
  });
}
