import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../core/storage/style_explore_recipe_storage.dart';
import '../../data/models/prompt_block/pill_document.dart';
import '../../data/models/style_explore/style_explore_recipe.dart';
import '../../data/repositories/style_explore_recipe_repository.dart';
import 'pill_workspace_provider.dart';

part 'style_explore_provider.freezed.dart';

final styleExploreRecipeStorageProvider = Provider<StyleExploreRecipeStorage>(
  (ref) => StyleExploreRecipeStorage(),
);

final styleExploreRecipeRepositoryProvider =
    Provider<StyleExploreRecipeRepository>(
      (ref) => StyleExploreRecipeRepository(
        ref.watch(styleExploreRecipeStorageProvider),
      ),
    );

/// Recipe 列表只读快照，按更新时间新→旧排列。
class StyleExploreRecipeListState {
  StyleExploreRecipeListState({required List<StyleExploreRecipe> recipes})
    : recipes = List.unmodifiable(recipes);

  final List<StyleExploreRecipe> recipes;

  StyleExploreRecipe? recipeById(String id) {
    for (final recipe in recipes) {
      if (recipe.id == id) return recipe;
    }
    return null;
  }
}

/// Recipe 列表管理。
class StyleExploreRecipeListNotifier
    extends AsyncNotifier<StyleExploreRecipeListState> {
  @override
  Future<StyleExploreRecipeListState> build() async {
    final recipes = await ref
        .watch(styleExploreRecipeRepositoryProvider)
        .load();
    return StyleExploreRecipeListState(recipes: recipes);
  }

  Future<void> refresh() async {
    final repository = ref.read(styleExploreRecipeRepositoryProvider);
    state = const AsyncLoading();
    try {
      state = AsyncData(
        StyleExploreRecipeListState(recipes: await repository.load()),
      );
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<StyleExploreRecipe> create({
    required String name,
    required PillDocument positiveDocument,
    required PillDocument negativeDocument,
  }) {
    return _mutate(
      (repository) => repository.create(
        name: name,
        positiveDocument: positiveDocument,
        negativeDocument: negativeDocument,
      ),
    );
  }

  Future<StyleExploreRecipe> overwrite(StyleExploreRecipe recipe) =>
      _mutate((repository) => repository.overwrite(recipe));

  Future<StyleExploreRecipe> rename(String id, String name) =>
      _mutate((repository) => repository.rename(id, name));

  Future<StyleExploreRecipe> duplicate(String id, {String? name}) =>
      _mutate((repository) => repository.duplicate(id, name: name));

  Future<void> delete(String id) =>
      _mutate((repository) => repository.delete(id));

  Future<T> _mutate<T>(
    Future<T> Function(StyleExploreRecipeRepository repository) action,
  ) async {
    final repository = ref.read(styleExploreRecipeRepositoryProvider);
    try {
      final result = await action(repository);
      state = AsyncData(
        StyleExploreRecipeListState(recipes: await repository.load()),
      );
      return result;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final styleExploreRecipeListNotifierProvider =
    AsyncNotifierProvider<
      StyleExploreRecipeListNotifier,
      StyleExploreRecipeListState
    >(StyleExploreRecipeListNotifier.new);

/// 探索会话状态：当前与工作区关联的 Recipe。
@freezed
class StyleExploreSessionState with _$StyleExploreSessionState {
  const factory StyleExploreSessionState({String? activeRecipeId}) =
      _StyleExploreSessionState;
}

/// 探索会话：药丸工作区（main/negative lane）与 Recipe 快照之间的
/// 载入/保存协调。
///
/// Recipe = 主提示词模板库：载入把 Recipe 文档快照灌进主双 lane
/// （[PillWorkspaceNotifier.restoreDocument]，与 lane 启动恢复同一物化
/// 语义）；保存把主 lane 当前文档写回 Recipe。两者都只搬运不可变快照，
/// 不触碰公共块库。旧 Recipe 数据（PillDocument 快照）天然兼容。
class StyleExploreSessionNotifier extends Notifier<StyleExploreSessionState> {
  @override
  StyleExploreSessionState build() =>
      const StyleExploreSessionState(activeRecipeId: null);

  PillWorkspaceNotifier get _positiveLane =>
      ref.read(pillWorkspaceProvider(PillScopes.main).notifier);

  PillWorkspaceNotifier get _negativeLane =>
      ref.read(pillWorkspaceProvider(PillScopes.negative).notifier);

  /// 把 Recipe 快照载入主双 lane。
  ///
  /// Recipe 不存在时返回 false 且不改动工作区。
  Future<bool> loadRecipe(String recipeId) async {
    final recipe = await ref
        .read(styleExploreRecipeRepositoryProvider)
        .getRecipe(recipeId);
    if (recipe == null) return false;

    _positiveLane.restoreDocument(recipe.positiveDocument);
    _negativeLane.restoreDocument(recipe.negativeDocument);
    state = StyleExploreSessionState(activeRecipeId: recipe.id);
    return true;
  }

  /// 从空白文档开始新的探索；不关联任何 Recipe。
  void startNew() {
    _positiveLane.replaceWithPlainText('');
    _negativeLane.replaceWithPlainText('');
    state = const StyleExploreSessionState(activeRecipeId: null);
  }

  /// 把主双 lane 当前文档快照保存回关联的 Recipe。
  ///
  /// 返回更新后的 Recipe；无关联或 Recipe 已被删除时返回 null。
  Future<StyleExploreRecipe?> saveActive() async {
    final activeId = state.activeRecipeId;
    if (activeId == null) return null;

    final list = ref.read(styleExploreRecipeListNotifierProvider).valueOrNull;
    final recipe = list?.recipeById(activeId);
    if (recipe == null) return null;

    return ref
        .read(styleExploreRecipeListNotifierProvider.notifier)
        .overwrite(
          recipe.copyWith(
            positiveDocument: ref
                .read(pillWorkspaceProvider(PillScopes.main))
                .document,
            negativeDocument: ref
                .read(pillWorkspaceProvider(PillScopes.negative))
                .document,
          ),
        );
  }

  /// 把主双 lane 当前文档另存为新 Recipe 并切换关联。
  Future<StyleExploreRecipe> saveAsNew(String name) async {
    final created = await ref
        .read(styleExploreRecipeListNotifierProvider.notifier)
        .create(
          name: name,
          positiveDocument: ref
              .read(pillWorkspaceProvider(PillScopes.main))
              .document,
          negativeDocument: ref
              .read(pillWorkspaceProvider(PillScopes.negative))
              .document,
        );
    state = StyleExploreSessionState(activeRecipeId: created.id);
    return created;
  }

  /// Recipe 被删除时的联动：若是当前关联，解除关联但保留工作区内容，
  /// 让用户有机会另存。
  void handleRecipeDeleted(String recipeId) {
    if (state.activeRecipeId != recipeId) return;
    state = const StyleExploreSessionState(activeRecipeId: null);
  }
}

final styleExploreSessionNotifierProvider =
    NotifierProvider<StyleExploreSessionNotifier, StyleExploreSessionState>(
      StyleExploreSessionNotifier.new,
    );

/// 工作区相对关联 Recipe 是否有未保存修改。
///
/// 无关联 Recipe 或列表尚未就绪时视为不脏；比较按 [PillDocument] 全等
/// （文本 + 实例逐键值），Recipe 里的 createdAt/updatedAt 不参与。
final styleExploreDirtyProvider = Provider<bool>((ref) {
  final session = ref.watch(styleExploreSessionNotifierProvider);
  final activeId = session.activeRecipeId;
  if (activeId == null) return false;

  final recipe = ref
      .watch(styleExploreRecipeListNotifierProvider)
      .valueOrNull
      ?.recipeById(activeId);
  if (recipe == null) return false;

  final positive = ref.watch(pillWorkspaceProvider(PillScopes.main));
  final negative = ref.watch(pillWorkspaceProvider(PillScopes.negative));
  return recipe.positiveDocument != positive.document ||
      recipe.negativeDocument != negative.document;
});

/// 载入 Recipe/快照前是否需要覆盖确认（Recipe 已升级为主提示词模板库，
/// 载入即覆盖主双 lane）：
/// - 有未保存修改（相对关联 Recipe）→ 确认；
/// - 无关联 Recipe 且主/负 lane 任一非空（内容未备份，覆盖即丢）→ 确认。
final styleExploreNeedsOverwriteConfirmProvider = Provider<bool>((ref) {
  if (ref.watch(styleExploreDirtyProvider)) return true;
  final activeId = ref.watch(
    styleExploreSessionNotifierProvider.select((s) => s.activeRecipeId),
  );
  if (activeId != null) return false;
  final positive = ref.watch(pillWorkspaceProvider(PillScopes.main));
  final negative = ref.watch(pillWorkspaceProvider(PillScopes.negative));
  return positive.document.text.isNotEmpty ||
      positive.document.instances.isNotEmpty ||
      negative.document.text.isNotEmpty ||
      negative.document.instances.isNotEmpty;
});

/// 当前关联的 Recipe（可能为 null：未关联或列表未就绪）。
final styleExploreActiveRecipeProvider = Provider<StyleExploreRecipe?>((ref) {
  final activeId = ref.watch(
    styleExploreSessionNotifierProvider.select((s) => s.activeRecipeId),
  );
  if (activeId == null) return null;
  return ref
      .watch(styleExploreRecipeListNotifierProvider)
      .valueOrNull
      ?.recipeById(activeId);
});
