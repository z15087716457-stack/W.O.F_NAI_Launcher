import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';

import 'package:nai_launcher/core/storage/style_explore_recipe_storage.dart';
import 'package:nai_launcher/data/models/prompt_block/pill_document.dart';
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

  PillDocument document(String text) {
    return PillDocument(text: text, instances: const {});
  }

  StyleExploreRecipe recipe(String id, String name, {DateTime? updatedAt}) {
    return StyleExploreRecipe(
      id: id,
      name: name,
      positiveDocument: document('soft lighting, $name'),
      negativeDocument: document('lowres'),
      createdAt: DateTime.utc(2026, 8, 30),
      updatedAt: updatedAt ?? DateTime.utc(2026, 8, 31),
    );
  }

  test('JSON round-trip preserves embedded documents and instances', () async {
    const marker = '\uE000';
    final complex = StyleExploreRecipe(
      id: 'complex',
      name: '多行,权重 {test}',
      positiveDocument: const PillDocument(
        text: '1girl, {custom:1.3},\nline 2\uE000 tail',
        instances: {marker: PillInstance(blockId: 'source-1', enabled: false)},
      ),
      negativeDocument: document('bad'),
      createdAt: DateTime.utc(2026, 8, 30),
      updatedAt: DateTime.utc(2026, 8, 31),
    );

    await storage.putRecipe(complex);
    final restored = await storage.getRecipe('complex');

    expect(restored, complex);
    expect(restored!.positiveDocument.instances[marker]!.blockId, 'source-1');
    expect(restored.positiveDocument.instances[marker]!.enabled, isFalse);
  });

  test(
    'legacy segment-format record migrates to pill document on read',
    () async {
      final legacyJson = jsonEncode({
        'id': 'legacy',
        'name': '旧格式',
        'positiveDocument': {
          'documentId': 'doc-1',
          'segments': [
            {'type': 'text', 'id': 'text-1', 'text': '1girl, '},
            {
              'type': 'block',
              'id': 'block-1',
              'sourceBlockId': 'source-1',
              'titleSnapshot': '标题块',
              'colorSnapshot': '#FF123456',
              'contentSnapshot': 'artist:x, (style:1.2)',
              'enabled': false,
            },
            {'type': 'text', 'id': 'text-2', 'text': ' tail'},
            {
              'type': 'block',
              'id': 'block-2',
              'titleSnapshot': '无来源块',
              'colorSnapshot': '#FF123456',
              'contentSnapshot': 'flattened',
            },
          ],
          'updatedAt': '2026-08-31T08:00:00.000Z',
        },
        'negativeDocument': {
          'documentId': 'doc-neg',
          'segments': [
            {'type': 'text', 'id': 'text-n', 'text': 'lowres'},
          ],
          'updatedAt': '2026-08-31T08:00:00.000Z',
        },
        'createdAt': '2026-08-30T00:00:00.000Z',
        'updatedAt': '2026-08-31T00:00:00.000Z',
      });
      final box = Hive.box<String>(StyleExploreRecipeStorage.boxName);
      await box.put(StyleExploreRecipeStorage.recipeKey('legacy'), legacyJson);

      final restored = await storage.getRecipe('legacy');

      expect(restored, isNotNull);
      const marker = '\uE000';
      // 活引用块 → 标记+实例（enabled 保留）；无来源块 → 拍平文本。
      expect(restored!.positiveDocument.text, '1girl, $marker tailflattened');
      final instance = restored.positiveDocument.instances[marker];
      expect(instance, isNotNull);
      expect(instance!.blockId, 'source-1');
      expect(instance.enabled, isFalse);
      expect(restored.negativeDocument.text, 'lowres');
      expect(restored.negativeDocument.instances, isEmpty);

      // 迁移后的 Recipe 可按新格式原样再落盘、再读回。
      await storage.putRecipe(restored);
      expect(await storage.getRecipe('legacy'), restored);
    },
  );

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
