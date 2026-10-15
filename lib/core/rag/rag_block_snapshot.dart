import 'dart:convert';
import '../../data/models/prompt_block/prompt_block.dart';

/// Saved active text only. Never export images, file paths, generation settings,
/// draft instances, use counts or credentials to the retrieval collection.
String encodeRagBlocks(Iterable<PromptBlock> blocks) {
  final active = blocks.where((b) => !b.isArchived).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  return jsonEncode({
    'version': 1,
    'blocks': [
      for (final block in active)
        {
          'id': block.id,
          'title': block.title,
          'positive': block.content,
          'negative': block.negativeContent,
          'tags': block.tags.map((t) => t.name).toList()..sort(),
          if (!block.readingTranslationNeedsReview &&
              block.readingTranslationZh?.trim().isNotEmpty == true)
            'reading': block.readingTranslationZh,
        },
    ],
  });
}
