import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/core/utils/prompt_block_composer.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_segment.dart';

void main() {
  group('PromptBlockComposer', () {
    test('creates one lossless text segment for complex and empty strings', () {
      final ids = _IdSequence();
      final composer = _composer(ids);
      const complex = '  <style>\r\n5::{tag}, "quoted"::\n</style>  ';

      final complexDocument = composer.createDocumentFromPlainText(complex);
      final emptyDocument = composer.createDocumentFromPlainText('');

      expect(complexDocument.documentId, 'id-0');
      expect(complexDocument.segments.single.id, 'id-1');
      expect(composer.composePlainText(complexDocument), complex);
      expect(composer.composePlainText(emptyDocument), '');
      expect((emptyDocument.segments.single as TextSegment).text, '');
    });

    test(
      'block snapshots are isolated and same source has distinct instances',
      () {
        final ids = _IdSequence();
        final composer = _composer(ids);
        final source = _block(
          title: '原始标题',
          content: 'raw,\ncontent',
          color: '#FF010203',
        );
        final document = composer.createDocumentFromPlainText('prefix');
        final first = composer.insertBlock(document, index: 1, block: source);
        final second = composer.insertBlock(first, index: 2, block: source);
        final changedSource = source.copyWith(
          title: '后来修改',
          content: 'changed',
          color: '#FFFFFFFF',
        );
        final firstSnapshot = first.segments[1] as BlockSegment;
        final secondSnapshot = second.segments[2] as BlockSegment;

        expect(firstSnapshot.sourceBlockId, source.id);
        expect(secondSnapshot.sourceBlockId, source.id);
        expect(firstSnapshot.id, isNot(secondSnapshot.id));
        expect(firstSnapshot.titleSnapshot, '原始标题');
        expect(firstSnapshot.contentSnapshot, 'raw,\ncontent');
        expect(firstSnapshot.colorSnapshot, '#FF010203');
        expect(changedSource.content, 'changed');
        expect(
          (first.segments[1] as BlockSegment).contentSnapshot,
          'raw,\ncontent',
        );
        expect(document.segments, hasLength(1));
        expect(first.segments, hasLength(2));
        expect(second.segments, hasLength(3));
      },
    );

    test(
      'projection preserves order and excludes disabled block display data',
      () {
        final ids = _IdSequence();
        final composer = _composer(ids);
        final source = _block(
          title: 'TITLE_MUST_NOT_APPEAR',
          content: '<BLOCK>',
          color: 'COLOR_MUST_NOT_APPEAR',
        );
        final original = composer.createDocumentFromPlainText('AB');
        final split = composer.insertBlockAtTextOffset(
          original,
          textSegmentId: original.segments.single.id,
          offset: 1,
          block: source,
        );
        final blockId = split.segments[1].id;

        expect(composer.composePlainText(split), 'A<BLOCK>B');
        expect(composer.composePlainText(split), isNot(contains(source.title)));
        expect(composer.composePlainText(split), isNot(contains(source.color)));

        final disabled = composer.setBlockEnabled(
          split,
          segmentId: blockId,
          enabled: false,
        );
        expect(composer.composePlainText(disabled), 'AB');
        expect((split.segments[1] as BlockSegment).enabled, isTrue);
        expect((disabled.segments[1] as BlockSegment).enabled, isFalse);
      },
    );

    test(
      'offset insertion keeps before, block, and after including empty text',
      () {
        final ids = _IdSequence();
        final composer = _composer(ids);
        final source = _block(content: 'X');
        final document = composer.createDocumentFromPlainText('left-right');
        final textId = document.segments.single.id;

        final split = composer.insertBlockAtTextOffset(
          document,
          textSegmentId: textId,
          offset: 4,
          block: source,
        );

        expect(split.segments, hasLength(3));
        expect(split.segments[0], const TextSegment(id: 'id-1', text: 'left'));
        expect(split.segments[1], isA<BlockSegment>());
        expect(
          split.segments[2],
          const TextSegment(id: 'id-3', text: '-right'),
        );
        expect(composer.composePlainText(split), 'leftX-right');
        expect(composer.composePlainText(document), 'left-right');

        final empty = composer.createDocumentFromPlainText('');
        final emptySplit = composer.insertBlockAtTextOffset(
          empty,
          textSegmentId: empty.segments.single.id,
          offset: 0,
          block: source,
        );
        expect(emptySplit.segments, hasLength(3));
        expect((emptySplit.segments.first as TextSegment).text, '');
        expect((emptySplit.segments.last as TextSegment).text, '');
        expect(composer.composePlainText(emptySplit), 'X');
      },
    );

    test('expand is one-way, preserves segment ID, and keeps raw content', () {
      final ids = _IdSequence();
      final composer = _composer(ids);
      final document = composer.createDocumentFromPlainText('A');
      final inserted = composer.insertBlock(
        document,
        index: 1,
        block: _block(content: '  raw,\ntext  '),
      );
      final blockId = inserted.segments[1].id;

      final expanded = composer.expandBlock(inserted, segmentId: blockId);

      expect(expanded.segments[1], isA<TextSegment>());
      expect(expanded.segments[1].id, blockId);
      expect((expanded.segments[1] as TextSegment).text, '  raw,\ntext  ');
      expect(composer.composePlainText(expanded), 'A  raw,\ntext  ');
      expect(
        () => composer.expandBlock(expanded, segmentId: blockId),
        throwsStateError,
      );
    });

    test('reorders by a complete ID list and rejects invalid lists', () {
      final ids = _IdSequence();
      final composer = _composer(ids);
      final document = composer.createDocumentFromPlainText('AB');
      final split = composer.insertBlockAtTextOffset(
        document,
        textSegmentId: document.segments.single.id,
        offset: 1,
        block: _block(content: 'X'),
      );
      final beforeId = split.segments[0].id;
      final blockId = split.segments[1].id;
      final afterId = split.segments[2].id;

      final reordered = composer.reorderSegments(split, [
        afterId,
        blockId,
        beforeId,
      ]);
      expect(composer.composePlainText(reordered), 'BXA');
      expect(composer.composePlainText(split), 'AXB');

      expect(
        () => composer.reorderSegments(split, [beforeId, blockId]),
        throwsArgumentError,
      );
      expect(
        () => composer.reorderSegments(split, [beforeId, beforeId, afterId]),
        throwsArgumentError,
      );
      expect(
        () => composer.reorderSegments(split, [beforeId, blockId, 'unknown']),
        throwsArgumentError,
      );
    });

    test('updates and removes immutably with explicit validation errors', () {
      final ids = _IdSequence();
      final composer = _composer(ids);
      final document = composer.createDocumentFromPlainText('old');
      final textId = document.segments.single.id;
      final updated = composer.updateText(
        document,
        segmentId: textId,
        text: 'new',
      );
      final inserted = composer.insertBlock(
        updated,
        index: 1,
        block: _block(content: 'X'),
      );
      final blockId = inserted.segments[1].id;
      final removed = composer.removeSegment(inserted, segmentId: textId);

      expect(composer.composePlainText(document), 'old');
      expect(composer.composePlainText(updated), 'new');
      expect(composer.composePlainText(removed), 'X');
      expect(
        () => composer.insertBlock(document, index: 2, block: _block()),
        throwsRangeError,
      );
      expect(
        () => composer.updateText(inserted, segmentId: blockId, text: 'bad'),
        throwsStateError,
      );
      expect(
        () => composer.toggleBlockEnabled(inserted, segmentId: textId),
        throwsStateError,
      );
      expect(
        () => composer.insertBlockAtTextOffset(
          inserted,
          textSegmentId: blockId,
          offset: 0,
          block: _block(),
        ),
        throwsStateError,
      );
      expect(
        () => composer.insertBlockAtTextOffset(
          document,
          textSegmentId: textId,
          offset: 4,
          block: _block(),
        ),
        throwsRangeError,
      );
      expect(
        () => composer.removeSegment(document, segmentId: 'missing'),
        throwsArgumentError,
      );
    });
  });
}

PromptBlockComposer _composer(_IdSequence ids) {
  return PromptBlockComposer(
    uuidGenerator: ids.next,
    clock: () => DateTime.utc(2026, 8, 30, 12),
  );
}

PromptBlock _block({
  String title = '块',
  String content = 'content',
  String color = '#FF607D8B',
}) {
  return PromptBlock(
    id: 'source-block',
    title: title,
    content: content,
    color: color,
    createdAt: DateTime.utc(2026, 8, 30),
    updatedAt: DateTime.utc(2026, 8, 30),
  );
}

class _IdSequence {
  int _value = 0;

  String next() => 'id-${_value++}';
}
