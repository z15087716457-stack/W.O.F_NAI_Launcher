import 'package:flutter_test/flutter_test.dart';

import 'package:nai_launcher/data/models/prompt_block/prompt_block.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_folder.dart';

void main() {
  test(
    'PromptBlock JSON round trip preserves raw content and display fields',
    () {
      final createdAt = DateTime.utc(2026, 8, 30, 1, 2, 3);
      final updatedAt = DateTime.utc(2026, 8, 30, 4, 5, 6);
      const content = '<style>\n5::best quality, {masterpiece}::\n</style>, α';
      final block = PromptBlock.create(
        id: 'block-1',
        title: '  画风块  ',
        content: content,
        folderId: 'folder-1',
        color: '#FFFF0000',
        sortOrder: 7,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final restored = PromptBlock.fromJson(block.toJson());

      expect(restored, block);
      expect(restored.title, '画风块');
      expect(restored.content, content);
      expect(restored.color, '#FFFF0000');
      expect(restored.folderId, 'folder-1');
    },
  );

  test(
    'PromptBlockFolder JSON round trip preserves hierarchy and timestamps',
    () {
      final folder = PromptBlockFolder.create(
        id: 'folder-1',
        name: '画风',
        parentId: 'folder-root',
        sortOrder: 2,
        createdAt: DateTime.utc(2026, 8, 30),
        updatedAt: DateTime.utc(2026, 8, 30, 1),
      );

      expect(PromptBlockFolder.fromJson(folder.toJson()), folder);
    },
  );

  test('folder cycle detection rejects self and descendants', () {
    final root = PromptBlockFolder.create(id: 'root', name: 'root');
    final child = PromptBlockFolder.create(
      id: 'child',
      name: 'child',
      parentId: root.id,
    );
    final folders = [root, child];

    expect(folders.wouldCreateCycle(root.id, root.id), isTrue);
    expect(folders.wouldCreateCycle(root.id, child.id), isTrue);
    expect(folders.wouldCreateCycle(child.id, null), isFalse);
    expect(folders.getDescendantIds(root.id), {child.id});
  });

  test('source provenance round trips and stays absent for manual blocks', () {
    final imported = PromptBlock.create(
      id: 'block-src',
      title: '画师池',
      content: 'artist-a, artist-b',
      createdAt: DateTime.utc(2026, 8, 31),
      updatedAt: DateTime.utc(2026, 8, 31),
      sourcePath: r'E:\curation\pool.txt',
      sourceHash: 'deadbeef',
      importedAt: DateTime.utc(2026, 8, 31, 5, 6, 7),
    );

    final restored = PromptBlock.fromJson(imported.toJson());
    expect(restored.sourcePath, r'E:\curation\pool.txt');
    expect(restored.sourceHash, 'deadbeef');
    expect(restored.importedAt, DateTime.utc(2026, 8, 31, 5, 6, 7));

    // 旧版本 JSON 不携带来源键时反序列化为 null，编辑不改写来源字段。
    final legacy = PromptBlock.fromJson({
      'id': 'block-old',
      'title': '旧块',
      'content': 'legacy',
      'color': '#FF607D8B',
      'sortOrder': 0,
      'createdAt': '2026-08-01T00:00:00.000Z',
      'updatedAt': '2026-08-01T00:00:00.000Z',
    });
    expect(legacy.sourcePath, isNull);
    expect(legacy.sourceHash, isNull);
    expect(legacy.importedAt, isNull);
    expect(
      legacy.copyWith(updatedAt: DateTime.utc(2026, 8, 31)).sourcePath,
      isNull,
    );

    // 手动块的 JSON 不携带来源键。
    final manual = PromptBlock.create(
      id: 'block-manual',
      title: '手动',
      content: 'manual',
    );
    expect(manual.toJson().containsKey('sourcePath'), isFalse);
  });
}
