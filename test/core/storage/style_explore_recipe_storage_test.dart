import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';

import 'package:nai_launcher/core/storage/style_explore_recipe_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_document.dart';
import 'package:nai_launcher/data/models/prompt_block/prompt_block_segment.dart';
import 'package:nai_launcher/data/models/style_explore/style_explore_recipe.dart';

void main() {
  late Directory hiveDirectory;
  late StyleExploreRecipeStorage storage;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'style_explore_recipe_storage_test_',
    );
    Hive.init(hiveDirectory.path);
    storage = StyleExploreRecipeStorage();
    await storage.init();
  });

  setUp(() async {
    await storage.clear();
  });

  tearDownAll(() async {
    await storage.close();
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  PromptBlockDocument document(String id, String text) {
    return PromptBlockDocument(
      documentId: id,
      segments: [PromptBlockSegment.text(id: '$id-text', text: text)],
      updatedAt: DateTime.utc(2026, 8, 31),
    );
  }

  StyleExploreRecipe recipe(String id, String name, {DateTime? updatedAt}) {
    return StyleExploreRecipe(
      id: id,
      name: name,
      positiveDocument: document('$id-positive', 'soft lighting, $name'),
      negativeDocument: document('$id-negative', 'lowres'),
      createdAt: DateTime.utc(2026, 8, 30),
      updatedAt: updatedAt ?? DateTime.utc(2026, 8, 31),
    );
  }

  test('JSON round-trip preserves embedded documents and syntax', () async {
    final complex = StyleExploreRecipe(
      id: 'complex',
      name: '多行,权重 {test}',
      positiveDocument: PromptBlockDocument(
        documentId: 'doc-1',
        segments: [
          const PromptBlockSegment.text(
            id: 'text-1',
            text: '1girl, {custom:1.3},\nline 2',
          ),
          const PromptBlockSegment.block(
            id: 'block-1',
            sourceBlockId: 'source-1',
            titleSnapshot: '标题块',
            colorSnapshot: '#FF123456',
            contentSnapshot: 'artist:x, (style:1.2)',
          ),
          const PromptBlockSegment.text(id: 'text-2', text: ' tail'),
        ],
        updatedAt: DateTime.utc(2026, 8, 31, 8),
      ),
      negativeDocument: document('doc-neg', 'bad'),
      createdAt: DateTime.utc(2026, 8, 30),
      updatedAt: DateTime.utc(2026, 8, 31),
    );

    await storage.putRecipe(complex);
    final restored = await storage.getRecipe('complex');

    expect(restored, complex);
    expect(
      restored!.positiveDocument.segments[1],
      isA<BlockSegment>().having(
        (segment) => segment.contentSnapshot,
        'contentSnapshot',
        'artist:x, (style:1.2)',
      ),
    );
  });

  test('getRecipes sorts by updatedAt newest first', () async {
    await storage.putRecipe(
      recipe('old', '旧', updatedAt: DateTime.utc(2026, 1, 1)),
    );
    await storage.putRecipe(
      recipe('new', '新', updatedAt: DateTime.utc(2026, 8, 31)),
    );
    await storage.putRecipe(
      recipe('mid', '中', updatedAt: DateTime.utc(2026, 5, 1)),
    );

    final recipes = await storage.getRecipes();
    expect(recipes.map((item) => item.id), ['new', 'mid', 'old']);
  });

  test('corrupt records are skipped without affecting others', () async {
    await storage.putRecipe(recipe('good', '好'));
    final box = Hive.box<String>(StyleExploreRecipeStorage.boxName);
    await box.put(
      StyleExploreRecipeStorage.recipeKey('corrupt'),
      'not a json {{{',
    );

    final recipes = await storage.getRecipes();
    expect(recipes.map((item) => item.id), ['good']);
    expect(await storage.getRecipe('corrupt'), isNull);
    expect(await storage.getRecipe('good'), isNotNull);
  });

  test('delete is idempotent and schema version stays readable', () async {
    expect(await storage.getSchemaVersion(), 1);

    await storage.putRecipe(recipe('doomed', '删我'));
    await storage.deleteRecipe('doomed');
    await storage.deleteRecipe('doomed');

    expect(await storage.getRecipe('doomed'), isNull);
    expect(await storage.getRecipes(), isEmpty);
    expect(await storage.getSchemaVersion(), 1);

    final box = Hive.box<String>(StyleExploreRecipeStorage.boxName);
    final schema =
        jsonDecode(box.get(StyleExploreRecipeStorage.schemaKey)!)
            as Map<String, dynamic>;
    expect(schema['schemaVersion'], 1);
  });

  test('empty displayName fallback reports unnamed recipe', () {
    final unnamed = recipe('unnamed', '');
    expect(unnamed.displayName, '未命名配方');
    final named = recipe('named', '有效名');
    expect(named.displayName, '有效名');
  });
}
