import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nai_launcher/core/utils/resource_window_drag.dart';
import 'package:nai_launcher/data/models/precise_ref/precise_ref_library_entry.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/vibe/vibe_library_entry.dart';
import 'package:nai_launcher/data/repositories/prompt_block_repository.dart';
import 'package:nai_launcher/data/services/precise_ref_library_storage_service.dart';
import 'package:nai_launcher/data/services/resource_window_drop_resolver.dart';
import 'package:nai_launcher/data/services/vibe_library_storage_service.dart';

class _Blocks extends Mock implements PromptBlockRepository {}

class _Vibes extends Mock implements VibeLibraryStorageService {}

class _Precise extends Mock implements PreciseRefLibraryStorageService {}

void main() {
  for (final kind in ResourceDragKind.values) {
    test(
      '$kind resolves the current main library value; deleted ids do nothing',
      () async {
        final blocks = _Blocks();
        final vibes = _Vibes();
        final precise = _Precise();
        final resolver = ResourceWindowDropResolver(
          blocks: blocks,
          vibes: vibes,
          preciseRefs: precise,
        );
        const id = 'same-id';
        final block = PromptBlock.create(
          title: 'latest',
          content: 'updated text',
        ).copyWith(id: id);
        final vibe = VibeLibraryEntry(
          id: id,
          name: 'latest',
          vibeDisplayName: 'latest',
          vibeEncoding: 'latest encoding',
          createdAt: DateTime(2026),
        );
        final ref = PreciseRefLibraryEntry(
          id: id,
          name: 'latest',
          imagePath: 'synthetic.png',
          strength: 0.42,
          createdAt: DateTime(2026),
        );
        PromptBlock? currentBlock;
        VibeLibraryEntry? currentVibe;
        PreciseRefLibraryEntry? currentRef;
        when(() => blocks.getBlock(id)).thenAnswer((_) async => currentBlock);
        when(() => vibes.getEntry(id)).thenAnswer((_) async => currentVibe);
        when(
          () => precise.getAllEntries(),
        ).thenAnswer((_) async => [if (currentRef != null) currentRef]);
        final results = <Object>[];
        Future<bool> drop() => resolver.resolve(
          ResourceDragReference(kind, id),
          onBlock: (entry) async => results.add(entry),
          onVibe: (entry) async => results.add(entry),
          onPrecise: (entry) async => results.add(entry),
        );
        currentBlock = block;
        currentVibe = vibe;
        currentRef = ref;
        expect(await drop(), true);
        expect(
          results.single,
          same(switch (kind) {
            ResourceDragKind.block => block,
            ResourceDragKind.vibe => vibe,
            ResourceDragKind.precise => ref,
          }),
        );
        currentBlock = null;
        currentVibe = null;
        currentRef = null;
        expect(await drop(), false);
        expect(results, hasLength(1));
        switch (kind) {
          case ResourceDragKind.block:
            verifyZeroInteractions(vibes);
            verifyZeroInteractions(precise);
          case ResourceDragKind.vibe:
            verifyZeroInteractions(blocks);
            verifyZeroInteractions(precise);
          case ResourceDragKind.precise:
            verifyZeroInteractions(blocks);
            verifyZeroInteractions(vibes);
        }
      },
    );
  }
}
