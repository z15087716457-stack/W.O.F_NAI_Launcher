import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/prompt_block_library_provider.dart';
import '../providers/prompt_block_palette_provider.dart';
import '../widgets/prompt/blocks/prompt_block_drag_data.dart';

Future<void> acceptPaletteDrag(
  WidgetRef ref,
  PromptBlockDragData data, {
  int? index,
}) async {
  final library = ref.read(promptBlockLibraryNotifierProvider.notifier);
  final palette = ref.read(promptBlockPaletteNotifierProvider.notifier);
  var blockId = data.blockId;
  if (data.translation case final translation?) {
    final title = translation.zh.trim().isEmpty
        ? translation.source.trim()
        : translation.zh.trim();
    final block = await library.createBlock(
      title: title.length > 60 ? '${title.substring(0, 60)}…' : title,
      content: translation.source,
      readingTranslationZh: translation.zh,
      readingTranslationNeedsReview: translation.needsReview,
      appearance: 'translation',
      color: '#FF7187BD',
    );
    blockId = block.id;
  }
  if (index == null) {
    await palette.addBlock(blockId);
  } else {
    await palette.insertBlock(blockId, index);
  }
}
