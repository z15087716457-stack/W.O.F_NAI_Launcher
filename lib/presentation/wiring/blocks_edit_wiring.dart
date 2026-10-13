import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/prompt_block/prompt_block.dart';
import '../providers/prompt_block_library_provider.dart';
import '../ui/blocks/blocks_contract.dart';
import 'blocks_actions.dart';
import 'blocks_platform.dart';

abstract final class BlocksEditWiring {
  static Future<PromptBlock?> createWithDialog(
    BuildContext context,
    WidgetRef ref, {
    String? initialTitle,
    String? initialContent,
    Uint8List? initialImageBytes,
    String? initialFolderId,
  }) async {
    final platform = ref.read(blocksPlatformProvider);
    await ref.read(promptBlockLibraryNotifierProvider.future);
    if (!context.mounted) return null;
    final picked = initialImageBytes == null
        ? null
        : platform.prepareThumbnail(initialImageBytes);
    try {
      return await BlocksActions(ref, context, () => context.mounted).edit(
        initialDraft: BlockDraft(
          title: initialTitle ?? '',
          atoms: initialContent == null ? const [] : null,
          text: initialContent,
          folderId: initialFolderId,
          thumb: picked == null ? null : BlockThumb(picked.image),
          thumbToken: picked?.token,
        ),
      );
    } finally {
      if (picked != null) platform.releaseThumbnail(picked.token);
    }
  }
}
