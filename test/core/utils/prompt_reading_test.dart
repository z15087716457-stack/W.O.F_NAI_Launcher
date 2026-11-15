import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/core/utils/pill_document_editor.dart';
import 'package:nai_launcher/core/utils/prompt_translation_document.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_reading.dart';

PillDocument translate(String text) {
  final batch = PromptTranslationBatch.prepare({
    'main': PillDocument(text: text, instances: const {}),
  });
  return batch.buildFromGroups({
    'main': [
      for (final item in batch.segments['main']!)
        (
          start: item.start,
          end: item.end,
          zh: '译文 ${item.id}',
          marks: const <TranslationTagMark>[],
        ),
    ],
  }, mode: PromptTranslationMode.inline)['main']!;
}

void main() {
  test(
    'extending a phrase invalidates it, while appending a tag preserves it',
    () {
      final doc = translate('silver hair');
      final extended = doc.copyWith(text: 'silver hair style');
      expect(extended.readings.single.needsReview, isTrue);
      expect(extended.readings.single.source, 'silver hair style');
      final appended = doc.copyWith(text: 'silver hair, blue eyes');
      expect(appended.readings.single.needsReview, isFalse);
      expect(
        PromptTranslationBatch.prepare({
          'main': appended,
        }, skipReadings: true).segments['main']!.map((s) => s.source),
        [' blue eyes'],
      );
    },
  );
  test(
    'readings round-trip independently and never change source projection',
    () {
      const source = '1girl, 1.2::blue eyes::,\nA girl holds a book.';
      final doc = translate(source).copyWith(readingsVisible: false);
      expect(doc.text, source);
      expect(doc.instances, isEmpty);
      expect(PillDocumentEditor.project(doc, (_) => null), source);
      expect(
        PillDocument.fromJson(
          jsonDecode(jsonEncode(doc.toJson())) as Map<String, dynamic>,
        ),
        doc,
      );
      expect(
        PillDocument.fromJson({'text': source, 'instances': {}}).readings,
        isEmpty,
      );
    },
  );
  test(
    'edits anchor repeated text by position and preserve untouched readings',
    () {
      final doc = translate('blue eyes, blue eyes, silver hair');
      final changed = PillDocumentEditor.reconcile(
        doc,
        'green eyes, blue eyes, silver hair',
      );
      expect(changed.readings[0].needsReview, isTrue);
      expect(changed.readings[0].source, 'green eyes,');
      expect(changed.readings[1].needsReview, isFalse);
      expect(changed.readings[1].source, ' blue eyes,');
      expect(changed.readings[1].start, doc.readings[1].start + 1);
      final batch = PromptTranslationBatch.prepare({
        'main': changed,
      }, skipReadings: true);
      expect(batch.segments['main']!.map((s) => s.source), ['green eyes,']);
    },
  );
  test(
    'inserting, deleting and replacing spans does not retain wrong translations',
    () {
      final doc = translate('blue eyes, silver hair, solo');
      final inserted = doc.copyWith(text: 'new, blue eyes, silver hair, solo');
      expect(inserted.readings.every((r) => !r.needsReview), isTrue);
      expect(inserted.readings.first.start, 5);
      final removed = doc.copyWith(text: 'solo');
      expect(removed.readings.length, 1);
      expect(removed.readings.single.source, 'solo');
      final replaced = doc.copyWith(text: 'green eyes');
      expect(replaced.readings.length, 1);
      expect(replaced.readings.single.needsReview, isTrue);
    },
  );
  test(
    'a new block splits plain annotation ranges without changing the block',
    () {
      final doc = translate('silver hair');
      final withBlock = PillDocumentEditor.insertBlock(
        doc,
        offset: 6,
        blockId: 'library',
      );
      expect(withBlock.readings, isEmpty);
      expect(withBlock.instances.values.single.blockId, 'library');
      final batch = PromptTranslationBatch.prepare({
        'main': withBlock,
      }, skipReadings: true);
      final result = batch.buildFromGroups({
        'main': [
          for (final item in batch.segments['main']!)
            (
              start: item.start,
              end: item.end,
              zh: '阅读',
              marks: const <TranslationTagMark>[],
            ),
        ],
      }, mode: PromptTranslationMode.inline)['main']!;
      expect(result.instances, withBlock.instances);
      expect(result.text, withBlock.text);
    },
  );
  test('invalid saved annotations do not discard a valid source document', () {
    final doc = PillDocument.fromJson({
      'text': 'source',
      'instances': {},
      'readings': [
        {'start': 0, 'end': 6, 'source': 'wrong', 'translation': '错误'},
        {'start': -1, 'end': 9, 'source': 'source', 'translation': '错误'},
      ],
    });
    expect(doc.text, 'source');
    expect(doc.readings, isEmpty);
  });
}
