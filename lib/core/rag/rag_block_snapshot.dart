import 'dart:convert';
import 'package:collection/collection.dart';
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
          'tags': _tagNames(block),
          if (_reading(block) case final reading?) 'reading': reading,
        },
    ],
  });
}

/// Whether [encodeRagBlocks] gives [a] and [b] the same snapshot, found
/// without encoding either: only the fields above count, so a use count,
/// favourite, folder, collection or order change leaves it the same.
bool sameRagBlocks(Iterable<PromptBlock> a, Iterable<PromptBlock> b) {
  final before = {
    for (final block in a)
      if (!block.isArchived) block.id: block,
  };
  for (final block in b) {
    if (block.isArchived) continue;
    final previous = before.remove(block.id);
    if (previous == null || !_sameText(previous, block)) return false;
  }
  return before.isEmpty;
}

bool _sameText(PromptBlock a, PromptBlock b) =>
    identical(a, b) ||
    (a.title == b.title &&
        a.content == b.content &&
        a.negativeContent == b.negativeContent &&
        _reading(a) == _reading(b) &&
        (identical(a.tags, b.tags) ||
            const ListEquality<String>().equals(_tagNames(a), _tagNames(b))));

List<String> _tagNames(PromptBlock block) =>
    block.tags.map((t) => t.name).toList()..sort();

/// Only a reviewed, non-empty reading is indexed.
String? _reading(PromptBlock block) =>
    !block.readingTranslationNeedsReview &&
        block.readingTranslationZh?.trim().isNotEmpty == true
    ? block.readingTranslationZh
    : null;
