import '../../core/storage/style_explore_recipe_storage.dart';
import '../../data/models/prompt_block/prompt_block_document.dart';
import '../models/style_explore/style_explore_recipe.dart';

/// 画风探索 Recipe Repository。
///
/// Recipe 持有的是保存时刻的文档快照；这里只做持久化编排，
/// 不展开、不校验文档内容、不触碰公共块库。
class StyleExploreRecipeRepository {
  StyleExploreRecipeRepository(this._storage);

  final StyleExploreRecipeStorage _storage;

  /// 读取全部 Recipe，按更新时间新→旧排列。
  Future<List<StyleExploreRecipe>> load() => _storage.getRecipes();

  Future<StyleExploreRecipe?> getRecipe(String id) => _storage.getRecipe(id);

  /// 从工作区文档快照创建新 Recipe。
  Future<StyleExploreRecipe> create({
    required String name,
    required PromptBlockDocument positiveDocument,
    required PromptBlockDocument negativeDocument,
  }) async {
    final recipe = StyleExploreRecipe.create(
      name: name,
      positiveDocument: positiveDocument,
      negativeDocument: negativeDocument,
    );
    await _storage.putRecipe(recipe);
    return recipe;
  }

  /// 覆盖保存：以新的文档快照更新既有 Recipe 的内容与时间戳。
  Future<StyleExploreRecipe> overwrite(StyleExploreRecipe recipe) async {
    final existing = await _storage.getRecipe(recipe.id);
    if (existing == null) {
      throw StateError('Style explore recipe does not exist: ${recipe.id}');
    }
    final updated = recipe.copyWith(updatedAt: DateTime.now());
    await _storage.putRecipe(updated);
    return updated;
  }

  /// 重命名。
  Future<StyleExploreRecipe> rename(String id, String name) async {
    final recipe = await _storage.getRecipe(id);
    if (recipe == null) {
      throw StateError('Style explore recipe does not exist: $id');
    }
    final updated = recipe.copyWith(
      name: name.trim(),
      updatedAt: DateTime.now(),
    );
    await _storage.putRecipe(updated);
    return updated;
  }

  /// 以既有 Recipe 为蓝本另存一份新 Recipe。
  Future<StyleExploreRecipe> duplicate(String id, {String? name}) async {
    final recipe = await _storage.getRecipe(id);
    if (recipe == null) {
      throw StateError('Style explore recipe does not exist: $id');
    }
    final copy = StyleExploreRecipe.create(
      name: name ?? recipe.name,
      positiveDocument: recipe.positiveDocument,
      negativeDocument: recipe.negativeDocument,
    );
    await _storage.putRecipe(copy);
    return copy;
  }

  /// 删除 Recipe；不存在时保持幂等。
  Future<void> delete(String id) => _storage.deleteRecipe(id);
}
