import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/core/utils/pill_document_editor.dart';
import 'package:nai_launcher/core/utils/prompt_block_legacy_converter.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_segment.dart';

void main() {
  const markerA = '\uE000';
  const markerB = '\uE001';

  PromptBlockDocument legacy(List<PromptBlockSegment> segments) {
    return PromptBlockDocument(
      documentId: 'legacy-doc',
      segments: segments,
      updatedAt: DateTime.utc(2026, 8, 31),
    );
  }

  PromptBlockSegment blockSegment(
    String id, {
    String? sourceBlockId,
    String content = 'snapshot content',
    bool enabled = true,
  }) {
    return PromptBlockSegment.block(
      id: id,
      sourceBlockId: sourceBlockId,
      titleSnapshot: '标题$id',
      colorSnapshot: '#FF123456',
      contentSnapshot: content,
      enabled: enabled,
    );
  }

  group('PromptBlockLegacyConverter', () {
    test('text segments are concatenated verbatim', () {
      final document = PromptBlockLegacyConverter.convert(
        legacy([
          const PromptBlockSegment.text(id: 't1', text: '1girl, '),
          const PromptBlockSegment.text(id: 't2', text: '{masterpiece:1.2}\n'),
          const PromptBlockSegment.text(id: 't3', text: ' tail'),
        ]),
      );

      expect(document.text, '1girl, {masterpiece:1.2}\n tail');
      expect(document.instances, isEmpty);
    });

    test(
      'block with sourceBlockId becomes a live instance at its position',
      () {
        final document = PromptBlockLegacyConverter.convert(
          legacy([
            const PromptBlockSegment.text(id: 't1', text: 'before '),
            blockSegment('b1', sourceBlockId: 'block-1'),
            const PromptBlockSegment.text(id: 't2', text: ' after'),
          ]),
        );

        expect(document.text, 'before $markerA after');
        final instance = document.instances[markerA];
        expect(instance, isNotNull);
        expect(instance!.blockId, 'block-1');
        expect(instance.enabled, isTrue);
        expect(instance.settings, PillInstanceSettings.fixedDefault);
        expect(instance.currentRoll, isNull);
      },
    );

    test('disabled block keeps enabled=false', () {
      final document = PromptBlockLegacyConverter.convert(
        legacy([blockSegment('b1', sourceBlockId: 'block-1', enabled: false)]),
      );

      expect(document.text, markerA);
      expect(document.instances[markerA]!.enabled, isFalse);
    });

    test(
      'deleted library block keeps marker+instance (renders as missing pill)',
      () {
        // 转换器不查库：实例带着库中已不存在的 blockId 建活，投影时自然
        // 落空为空串、渲染层显示失效药丸（既有 missing 语义）。
        final document = PromptBlockLegacyConverter.convert(
          legacy([blockSegment('b1', sourceBlockId: 'no-such-block')]),
        );

        expect(document.text, markerA);
        expect(document.instances[markerA]!.blockId, 'no-such-block');
        final projection = PillDocumentEditor.project(
          document,
          (instance) => null, // 模拟库中查不到
        );
        expect(projection, '');
      },
    );

    test('block without sourceBlockId flattens contentSnapshot as text', () {
      final document = PromptBlockLegacyConverter.convert(
        legacy([
          const PromptBlockSegment.text(id: 't1', text: 'head, '),
          blockSegment('b1', content: 'flattened content'),
          const PromptBlockSegment.text(id: 't2', text: ', tail'),
        ]),
      );

      expect(document.text, 'head, flattened content, tail');
      expect(document.instances, isEmpty);
    });

    test('markers are allocated sequentially from U+E000', () {
      final document = PromptBlockLegacyConverter.convert(
        legacy([
          blockSegment('b1', sourceBlockId: 'block-1'),
          blockSegment('b2', sourceBlockId: 'block-2'),
        ]),
      );

      expect(document.text, '$markerA$markerB');
      expect(document.instances.keys, [markerA, markerB]);
    });

    test('empty document converts to empty pill document', () {
      final document = PromptBlockLegacyConverter.convert(legacy(const []));

      expect(document.text, '');
      expect(document.instances, isEmpty);
      expect(document, PillDocument.empty());
    });
  });
}
