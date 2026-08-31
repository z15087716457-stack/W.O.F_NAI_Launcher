import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/core/utils/prompt_block_composer.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_segment.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_workspace_provider.dart';

void main() {
  test('build creates isolated empty plain-text documents for both lanes', () {
    final container = _container();
    addTearDown(container.dispose);

    final state = container.read(promptBlockWorkspaceNotifierProvider);
    final notifier = container.read(
      promptBlockWorkspaceNotifierProvider.notifier,
    );

    expect(state.positiveDocument.segments, hasLength(1));
    expect(state.negativeDocument.segments, hasLength(1));
    expect(
      state.positiveDocument.documentId,
      isNot(state.negativeDocument.documentId),
    );
    expect(
      state.positiveDocument.segments.single.id,
      isNot(state.negativeDocument.segments.single.id),
    );
    expect(notifier.plainTextFor(PromptBlockLane.positive), '');
    expect(notifier.plainTextFor(PromptBlockLane.negative), '');
  });

  test('legacy plain string fallback replaces only the selected lane', () {
    final container = _container();
    addTearDown(container.dispose);
    final notifier = container.read(
      promptBlockWorkspaceNotifierProvider.notifier,
    );
    final initial = container.read(promptBlockWorkspaceNotifierProvider);
    final negativeBefore = initial.negativeDocument;
    const legacy = '  old,\r\n{prompt}, no trim  ';

    notifier.replacePlainText(PromptBlockLane.positive, legacy);

    final current = container.read(promptBlockWorkspaceNotifierProvider);
    expect(current.negativeDocument, same(negativeBefore));
    expect(current.positiveDocument.segments, hasLength(1));
    expect(notifier.plainTextFor(PromptBlockLane.positive), legacy);
    expect(notifier.plainTextFor(PromptBlockLane.negative), '');
  });

  test('replaceDocument and edits remain lane-local', () {
    final container = _container();
    addTearDown(container.dispose);
    final notifier = container.read(
      promptBlockWorkspaceNotifierProvider.notifier,
    );
    final positiveBefore = container
        .read(promptBlockWorkspaceNotifierProvider)
        .positiveDocument;
    final replacement = PromptBlockDocument(
      documentId: 'negative-external',
      segments: const [
        PromptBlockSegment.text(id: 'negative-text', text: 'negative raw'),
      ],
      updatedAt: DateTime.utc(2026, 8, 30),
    );

    notifier.replaceDocument(PromptBlockLane.negative, replacement);
    notifier.updateText(
      PromptBlockLane.negative,
      segmentId: 'negative-text',
      text: 'negative changed',
    );

    final current = container.read(promptBlockWorkspaceNotifierProvider);
    expect(current.positiveDocument, same(positiveBefore));
    expect(notifier.plainTextFor(PromptBlockLane.positive), '');
    expect(notifier.plainTextFor(PromptBlockLane.negative), 'negative changed');
  });

  test('provider exposes insert, toggle, reorder, expand, and remove', () {
    final container = _container();
    addTearDown(container.dispose);
    final notifier = container.read(
      promptBlockWorkspaceNotifierProvider.notifier,
    );
    notifier.replacePlainText(PromptBlockLane.positive, 'LR');
    final textId = container
        .read(promptBlockWorkspaceNotifierProvider)
        .positiveDocument
        .segments
        .single
        .id;

    notifier.insertBlockAtTextOffset(
      PromptBlockLane.positive,
      textSegmentId: textId,
      offset: 1,
      block: _block(content: 'B'),
    );
    var document = container
        .read(promptBlockWorkspaceNotifierProvider)
        .positiveDocument;
    final beforeId = document.segments[0].id;
    final blockId = document.segments[1].id;
    final afterId = document.segments[2].id;
    expect(notifier.plainTextFor(PromptBlockLane.positive), 'LBR');

    notifier.toggleBlockEnabled(PromptBlockLane.positive, segmentId: blockId);
    expect(notifier.plainTextFor(PromptBlockLane.positive), 'LR');
    notifier.toggleBlockEnabled(PromptBlockLane.positive, segmentId: blockId);

    notifier.reorderSegments(PromptBlockLane.positive, [
      afterId,
      blockId,
      beforeId,
    ]);
    expect(notifier.plainTextFor(PromptBlockLane.positive), 'RBL');

    notifier.expandBlock(PromptBlockLane.positive, segmentId: blockId);
    document = container
        .read(promptBlockWorkspaceNotifierProvider)
        .positiveDocument;
    expect(document.segments[1], isA<TextSegment>());
    expect(document.segments[1].id, blockId);
    expect(notifier.plainTextFor(PromptBlockLane.positive), 'RBL');

    notifier.removeSegment(PromptBlockLane.positive, segmentId: blockId);
    expect(notifier.plainTextFor(PromptBlockLane.positive), 'RL');

    notifier.insertBlock(
      PromptBlockLane.negative,
      index: 1,
      block: _block(content: 'N'),
    );
    expect(notifier.plainTextFor(PromptBlockLane.negative), 'N');
    expect(notifier.plainTextFor(PromptBlockLane.positive), 'RL');
  });
}

ProviderContainer _container() {
  var nextId = 0;
  final composer = PromptBlockComposer(
    uuidGenerator: () => 'provider-id-${nextId++}',
    clock: () => DateTime.utc(2026, 8, 30, 12),
  );
  return ProviderContainer(
    overrides: [promptBlockComposerProvider.overrideWithValue(composer)],
  );
}

PromptBlock _block({required String content}) {
  return PromptBlock(
    id: 'source-block',
    title: '标题',
    content: content,
    color: '#FF123456',
    createdAt: DateTime.utc(2026, 8, 30),
    updatedAt: DateTime.utc(2026, 8, 30),
  );
}
