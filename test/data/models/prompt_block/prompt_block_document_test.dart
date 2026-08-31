import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/data/models/prompt_block/prompt_block_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_segment.dart';

void main() {
  test('document JSON round trip preserves stable tagged segments', () {
    const complexText =
        '<style>\r\n5::best quality, {masterpiece}::\n"quoted"\\path, α😀\n</style>';
    final document = PromptBlockDocument(
      documentId: 'document-1',
      segments: const [
        PromptBlockSegment.text(id: 'text-1', text: complexText),
        PromptBlockSegment.block(
          id: 'block-1',
          sourceBlockId: 'source-1',
          titleSnapshot: '画风标题',
          colorSnapshot: '#FFAABBCC',
          contentSnapshot: '\n<block>, {{raw}}',
        ),
        PromptBlockSegment.block(
          id: 'block-2',
          titleSnapshot: '',
          colorSnapshot: '',
          contentSnapshot: '',
          enabled: false,
        ),
      ],
      updatedAt: DateTime.utc(2026, 8, 30, 12, 34, 56),
    );

    final json =
        jsonDecode(jsonEncode(document.toJson())) as Map<String, dynamic>;
    final restored = PromptBlockDocument.fromJson(json);

    expect(restored, document);
    expect(restored.segments.first, isA<TextSegment>());
    expect(restored.segments[1], isA<BlockSegment>());
    expect((json['segments'] as List)[0]['type'], 'text');
    expect((json['segments'] as List)[1]['type'], 'block');
    expect((restored.segments.first as TextSegment).text, complexText);
    expect((restored.segments[2] as BlockSegment).enabled, isFalse);
  });

  test('empty text is lossless and segments list is unmodifiable', () {
    final document = PromptBlockDocument(
      documentId: 'document-empty',
      segments: const [PromptBlockSegment.text(id: 'text-empty', text: '')],
      updatedAt: DateTime.utc(2026, 8, 30),
    );

    final restored = PromptBlockDocument.fromJson(
      jsonDecode(jsonEncode(document.toJson())) as Map<String, dynamic>,
    );

    expect((restored.segments.single as TextSegment).text, '');
    expect(
      () => restored.segments.add(
        const PromptBlockSegment.text(id: 'other', text: 'other'),
      ),
      throwsUnsupportedError,
    );
  });
}
