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
}
