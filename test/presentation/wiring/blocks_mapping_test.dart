import 'package:flutter_test/flutter_test.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_folder.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
import 'package:nai_launcher/presentation/providers/prompt_block_library_provider.dart';
import 'package:nai_launcher/presentation/ui/blocks/blocks_contract.dart';
import 'package:nai_launcher/presentation/wiring/blocks_mapping.dart';
import 'package:nai_launcher/presentation/wiring/blocks_preferences.dart';

void main() {
  final now = DateTime(2026, 10, 12);
  PromptBlock block(String id, {String? folder, bool favorite = false}) =>
      PromptBlock.create(
        id: id,
        title: id,
        content: 'white_dress, 0.5::a, b::',
        folderId: folder,
        isFavorite: favorite,
        createdAt: now,
      );
  final library = PromptBlockLibraryState(
    blocks: [
      block('a', folder: 'child', favorite: true),
      block('b'),
    ],
    folders: [
      PromptBlockFolder.create(id: 'parent', name: 'Parent'),
      PromptBlockFolder.create(id: 'child', name: 'Child', parentId: 'parent'),
    ],
  );

  test('filtered wall keeps whole library and recursive folder counts', () {
    final data = mapBlocksLibrary(
      library,
      preferences: const BlocksPreferences(scope: BlocksScope.folder('parent')),
      query: 'white dress',
    );
    expect(data.blocks.map((b) => b.id), ['a']);
    expect(data.counts.all, 2);
    expect(data.counts.favorites, 1);
    expect(data.folders.map((f) => f.id), ['parent', 'child']);
    expect(data.folders.map((f) => f.depth), [0, 1]);
    expect(data.folders.first.count, 1);
  });

  test('mapping preserves explicit atoms and paired negative content', () {
    final b = block('x').copyWith(
      atoms: ['a, b', 'c'],
      negativeContent: '0.5::d, e::, f',
      thumbnail: 'C:/sample.png',
    );
    final data = blockDataOf(b, library);
    expect(data.atoms, ['a, b', 'c']);
    expect(data.negativeAtoms, ['0.5::d, e::', 'f']);
    expect(data.thumb, isNotNull);
  });

  test('quick filters intersect without changing counts', () {
    final data = mapBlocksLibrary(
      library,
      quick: {BlocksQuick.image, BlocksQuick.negative},
    );
    expect(data.blocks, isEmpty);
    expect(data.counts.all, 2);
  });

  test(
    'semantic additions cannot bypass folder, favorites or quick filters',
    () {
      final scoped = mapBlocksLibrary(
        library,
        preferences: const BlocksPreferences(
          scope: BlocksScope.folder('parent'),
        ),
        query: 'rain',
        semanticIds: ['b', 'deleted', 'a'],
      );
      expect(scoped.blocks.map((b) => b.id), ['a']);
      final favorites = mapBlocksLibrary(
        library,
        preferences: const BlocksPreferences(scope: BlocksScope.favorites()),
        query: 'rain',
        semanticIds: ['b', 'a'],
      );
      expect(favorites.blocks.map((b) => b.id), ['a']);
      expect(
        mapBlocksLibrary(
          library,
          query: 'rain',
          semanticIds: ['a'],
          quick: {BlocksQuick.image},
        ).blocks,
        isEmpty,
      );
    },
  );
  test(
    'literal matches stay ahead of semantic additions and semantic rank is retained',
    () {
      final data = PromptBlockLibraryState(
        blocks: [
          block('z').copyWith(title: 'rain'),
          block('a').copyWith(title: 'rain coat'),
          block('b'),
          block('c'),
        ],
        folders: [],
      );
      final result = mapBlocksLibrary(
        data,
        query: 'rain',
        semanticIds: ['c', 'b', 'z'],
      );
      expect(result.blocks.map((b) => b.id), ['z', 'a', 'c', 'b']);
      expect(
        mapBlocksLibrary(data, query: '', semanticIds: ['c']).blocks.length,
        4,
      );
    },
  );

  test('recent IDs resolve unique live blocks in stored order', () {
    final data = mapBlocksLibrary(
      library,
      preferences: const BlocksPreferences(
        scope: BlocksScope.recent(),
        recentIds: ['deleted', 'b', 'a', 'b'],
      ),
    );
    expect(data.blocks.map((b) => b.id), ['b', 'a']);
    expect(data.counts.recent, 2);
  });

  test('deleted scope falls back and filtered selection clears', () {
    final data = mapBlocksLibrary(
      library,
      preferences: const BlocksPreferences(scope: BlocksScope.folder('gone')),
      query: 'nothing',
      selectedId: 'a',
    );
    expect(data.scope, const BlocksScope.all());
    expect(data.selectedId, isNull);
  });

  test('tag counts count each block once and preserve first color', () {
    final tagged = PromptBlockLibraryState(
      blocks: [
        block('a').copyWith(
          tags: const [
            PromptBlockTag(name: 'tag'),
            PromptBlockTag(name: 'tag'),
          ],
        ),
        block('b').copyWith(
          tags: const [PromptBlockTag(name: 'tag', color: '#FFFF0000')],
        ),
      ],
      folders: const [],
    );
    final data = mapBlocksLibrary(tagged);
    expect(data.tags.single.count, 2);
    expect(data.tags.single.tag.color.toARGB32(), 0xFF607D8B);
  });

  test(
    'all roll settings round trip without changing probability or weights',
    () {
      const settings = PillInstanceSettings(
        mode: PillRollMode.sequential,
        countMin: 2,
        countMax: 4,
        order: PillRollOrder.original,
        weightEnabled: true,
        weightMin: -2,
        weightMax: 2.5,
        weightAverage: -.8,
        leftDispersion: .15,
        rightDispersion: .85,
        softBalance: false,
        softBalanceStrength: .3,
        triggerProbability: .2,
      );
      expect(toPillSettings(toBlockRollSettings(settings)), settings);
    },
  );
}
