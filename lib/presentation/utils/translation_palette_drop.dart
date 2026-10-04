import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/prompt_block/pill_document.dart';
import '../../data/models/prompt_block/prompt_block.dart';

import '../providers/prompt_block_library_provider.dart';
import '../providers/prompt_block_palette_provider.dart';
import '../widgets/prompt/blocks/prompt_block_drag_data.dart';

Future<PromptBlock> saveTranslationToBlockLibrary(
  WidgetRef ref,
  TranslationPill translation,
) => ref
    .read(promptBlockLibraryNotifierProvider.notifier)
    .createBlock(
      title: _translationTitle(translation),
      content: translation.source,
      readingTranslationZh: translation.zh,
      readingTranslationMarks: [
        for (final mark in translation.marks) mark.toJson(),
      ],
      readingTranslationNeedsReview: translation.needsReview,
      readingTranslationLanguageCode: translation.languageCode,
      readingTranslationEdited: translation.translationEdited,
      appearance: 'translation',
      color: '#FF7187BD',
    );

String _translationTitle(TranslationPill translation) {
  final title = translation.zh.trim().isEmpty
      ? translation.source.trim()
      : translation.zh.trim();
  return title.length > 60 ? '${title.substring(0, 60)}…' : title;
}

Future<void> acceptPaletteDrag(
  WidgetRef ref,
  PromptBlockDragData data, {
  int? index,
}) async {
  final palette = ref.read(promptBlockPaletteNotifierProvider.notifier);
  var blockId = data.blockId;
  if (data.translation case final translation?) {
    final block = await saveTranslationToBlockLibrary(ref, translation);
    blockId = block.id;
  }
  if (index == null) {
    await palette.addBlock(blockId);
  } else {
    await palette.insertBlock(blockId, index);
  }
}
