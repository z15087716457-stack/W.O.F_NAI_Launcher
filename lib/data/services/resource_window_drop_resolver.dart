import '../../core/utils/resource_window_drag.dart';
import '../models/precise_ref/precise_ref_library_entry.dart';
import '../models/prompt_block/prompt_block.dart';
import '../models/vibe/vibe_library_entry.dart';
import '../repositories/prompt_block_repository.dart';
import 'precise_ref_library_storage_service.dart';
import 'vibe_library_storage_service.dart';

/// Main-engine-only boundary. The drag body is never a source of truth and
/// lookup does not mutate the current draft. Missing/deleted ids are rejected.
class ResourceWindowDropResolver {
  ResourceWindowDropResolver({
    required this.blocks,
    required this.vibes,
    required this.preciseRefs,
  });

  final PromptBlockRepository blocks;
  final VibeLibraryStorageService vibes;
  final PreciseRefLibraryStorageService preciseRefs;

  Future<bool> resolve(
    ResourceDragReference reference, {
    required Future<void> Function(PromptBlock) onBlock,
    required Future<void> Function(VibeLibraryEntry) onVibe,
    required Future<void> Function(PreciseRefLibraryEntry) onPrecise,
  }) async {
    switch (reference.kind) {
      case ResourceDragKind.block:
        final entry = await blocks.getBlock(reference.id);
        if (entry == null) return false;
        await onBlock(entry);
      case ResourceDragKind.vibe:
        // Resolve full current data lazily only after drop, not a display cache.
        final entry = await vibes.getEntry(reference.id);
        if (entry == null) return false;
        await onVibe(entry);
      case ResourceDragKind.precise:
        final entries = await preciseRefs.getAllEntries();
        final matches = entries.where((entry) => entry.id == reference.id);
        if (matches.isEmpty) return false;
        await onPrecise(matches.first);
    }
    return true;
  }
}
